from pyspark.sql import SparkSession, functions as F, types as T, DataFrame
from pyspark.sql.window import Window
from pyspark.ml.feature import VectorAssembler, StandardScaler 
from pyspark.ml.clustering import KMeansModel
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def init_spark_session(app_name: str) -> SparkSession:
    try:
        return SparkSession.builder \
            .appName(app_name) \
            .config("spark.sql.iceberg.vectorization.enabled", "false") \
            .getOrCreate()
    except Exception as e:
        logger.error(f"Không thể khởi tạo SparkSession: {e}")
        raise

def load_data(spark: SparkSession, table_names: dict) -> tuple:
    try:
        fact_sales = spark.read.table(table_names["fact_sales"])
        dim_customer = spark.read.table(table_names["dim_customer"])
        return fact_sales, dim_customer
    except Exception as e:
        logger.error(f"Lỗi khi tải dữ liệu từ bảng: {e}")
        raise

def preprocess_sales_data(fact_sales: DataFrame) -> DataFrame:
    return fact_sales.withColumn(
        "order_date",
        F.to_date(F.col("order_date_key").cast("string"), "yyyyMMdd")
    )

def join_sales_with_customer(fact_sales: DataFrame, dim_customer: DataFrame) -> DataFrame:
    return fact_sales.join(
        dim_customer,
        on=(
            (fact_sales.customer_sk == dim_customer.customer_sk) &
            (fact_sales.order_date_key.cast("int") >= F.date_format(dim_customer.effective_date, "yyyyMMdd").cast("int")) &
            (fact_sales.order_date_key.cast("int") <= F.when(
                dim_customer.expiration_date.isNotNull(),
                F.date_format(dim_customer.expiration_date, "yyyyMMdd").cast("int")
            ).otherwise(99991231))
        ),
        how="inner"
    ).select(
        fact_sales.customer_sk,
        fact_sales.order_id,
        fact_sales.order_date,
        dim_customer.sales_per_customer
    )

def calculate_rfm(df: DataFrame, analysis_date: str, analysis_timestamp: str) -> DataFrame:
    return df.groupBy("customer_sk").agg(
        F.datediff(F.lit(analysis_date).cast("date"), F.max("order_date")).alias("recency"),
        F.countDistinct("order_id").alias("frequency"),
        F.max("sales_per_customer").alias("monetary"),
        F.lit(analysis_timestamp).cast("timestamp").alias("effective_date")
    )

def apply_feature_engineering(df: DataFrame) -> DataFrame:
    try:
        assembler = VectorAssembler(inputCols=["recency", "frequency", "monetary"], outputCol="rfm_features")
        scaler = StandardScaler(inputCol="rfm_features", outputCol="scaled_features", withMean=True, withStd=True)
        assembled_df = assembler.transform(df)
        return scaler.fit(assembled_df).transform(assembled_df)
    except Exception as e:
        logger.error(f"Lỗi xử lý đặc trưng: {e}")
        raise

def predict_segments(model_path: str, df: DataFrame) -> DataFrame:
    try:
        model = KMeansModel.load(model_path)
        return model.transform(df).withColumn(
            "customer_segment",
            F.when(F.col("prediction") == 0, "New & Unengaged")
             .when(F.col("prediction") == 1, "Loyal VIPs")
             .when(F.col("prediction") == 2, "At Risk Regulars")
             .otherwise("Unknown")
        )
    except Exception as e:
        logger.error(f"Lỗi dự đoán phân khúc: {e}")
        raise

def create_output_table(spark: SparkSession, table_name: str):
    try:
        spark.sql(f"""
            CREATE TABLE IF NOT EXISTS {table_name} (
                surrogate_key BIGINT,
                customer_sk BIGINT,
                recency INT,
                frequency INT,
                monetary DOUBLE,
                customer_segment STRING,
                effective_date TIMESTAMP,
                expiration_date TIMESTAMP,
                is_active BOOLEAN
            )
            USING iceberg
        """)
        logger.info(f"Đã tạo hoặc kiểm tra bảng: {table_name}")
    except Exception as e:
        logger.error(f"Lỗi tạo bảng: {e}")
        raise

def apply_scd_type2(spark, new_df, target_table, analysis_ts):
    from pyspark.sql.functions import col, lit, monotonically_increasing_id
    from pyspark.sql.utils import AnalysisException

    new_df_enriched = new_df.withColumn("effective_date", lit(analysis_ts).cast("timestamp")) \
                            .withColumn("expiration_date", lit(None).cast("timestamp")) \
                            .withColumn("is_active", lit(True)) \
                            .withColumn("surrogate_key", monotonically_increasing_id()) \
                            .select("surrogate_key", "customer_sk", "recency", "frequency", "monetary", 
                                    "customer_segment", "effective_date", "expiration_date", "is_active")

    try:
        existing_df = spark.read.format("iceberg").load(target_table)
        if existing_df.rdd.isEmpty():
            raise ValueError("Table exists but is empty. Treat as first run.")

        join_expr = new_df_enriched["customer_sk"] == existing_df["customer_sk"]
        joined_df = new_df_enriched.alias("new").join(
            existing_df.alias("old"), join_expr, how="left_outer"
        )

        changed_df = joined_df.filter(
            (col("old.is_active") == True) & (
                (col("new.recency") != col("old.recency")) |
                (col("new.frequency") != col("old.frequency")) |
                (col("new.monetary") != col("old.monetary")) |
                (col("new.customer_segment") != col("old.customer_segment"))
            )
        )

        expired_df = changed_df.select(
            col("old.surrogate_key").alias("surrogate_key"),
            col("old.customer_sk"),
            col("old.recency"),
            col("old.frequency"),
            col("old.monetary"),
            col("old.customer_segment"),
            col("old.effective_date"),
            lit(analysis_ts).cast("timestamp").alias("expiration_date"),
            lit(False).alias("is_active")
        )

        new_changes = changed_df.select(
            col("new.surrogate_key"),
            col("new.customer_sk"),
            col("new.recency"),
            col("new.frequency"),
            col("new.monetary"),
            col("new.customer_segment"),
            col("new.effective_date"),
            col("new.expiration_date"),
            col("new.is_active")
        )

        unchanged_df = existing_df.filter(col("is_active") == True).join(
            changed_df.select("old.customer_sk"), "customer_sk", "left_anti"
        ).select(existing_df.columns)

        final_df = unchanged_df.unionByName(expired_df).unionByName(new_changes)

    except (AnalysisException, ValueError):
        # Trường hợp bảng chưa tồn tại hoặc trống ⇒ Lần đầu chạy
        final_df = new_df_enriched

    # Append vào Iceberg
    final_df.writeTo(target_table).append()



def main():
    config = {
        "app_name": "PredictCustomerSegmentation",
        "model_path": "/src/models/kmeans_rfm_model",
        "analysis_date": "2018-01-31",
        "analysis_timestamp": "2018-01-31 23:38:00.000",
        "table_names": {
            "fact_sales": "lakehouse.gold.fact_sales",
            "dim_customer": "lakehouse.gold.dim_customer"
        },
        "output_table": "lakehouse.gold.customer_rfm_segments"
    }

    spark = init_spark_session(config["app_name"])
    try:
        create_output_table(spark, config["output_table"])

        fact_sales, dim_customer = load_data(spark, config["table_names"])
        fact_sales = preprocess_sales_data(fact_sales)
        sales_data = join_sales_with_customer(fact_sales, dim_customer)

        rfm_df = calculate_rfm(sales_data, config["analysis_date"], config["analysis_timestamp"])
        features_df = apply_feature_engineering(rfm_df)
        prediction_df = predict_segments(config["model_path"], features_df)

        apply_scd_type2(spark, prediction_df, config["output_table"], config["analysis_timestamp"])
    finally:
        spark.stop()
        logger.info("SparkSession đã được dừng.")

if __name__ == "__main__":
    main()