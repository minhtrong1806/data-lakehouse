import logging
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, expr, regexp_extract, url_decode, when, lit, pandas_udf
from pyspark.sql.types import StringType
import geoip2.database
import pandas as pd

# Đường dẫn đến database GeoLite2
GEOIP_DB_PATH = "/src/data/GeoLite2-Country.mmdb"

@pandas_udf(StringType())
def get_country_udf(ip_series: pd.Series) -> pd.Series:
    """Hàm pandas UDF lấy tên quốc gia từ địa chỉ IP"""
    reader = geoip2.database.Reader(GEOIP_DB_PATH)
    results = []

    for ip in ip_series:
        try:
            response = reader.country(ip)
            results.append(response.country.name)
        except:
            results.append(None)

    reader.close()
    return pd.Series(results)

# Thiết lập logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger("SparkJob")

def create_spark_session(app_name):
    logger.info("Initializing Spark Session...")
    return SparkSession.builder.appName(app_name).getOrCreate()

def create_bronze_table(spark):
    logger.info("Creating Bronze namespace and raw_clickstream table if not exists...")
    spark.sql("CREATE NAMESPACE IF NOT EXISTS bronze")
    spark.sql("""
        CREATE TABLE IF NOT EXISTS lakehouse.bronze.raw_clickstream (
            event_id STRING,
            ts TIMESTAMP_NTZ,
            ip STRING,
            url STRING,
            department STRING,
            category STRING,
            product STRING,
            add_to_cart INT,
            country STRING
        )
        USING iceberg
        LOCATION 's3://lakehouse/bronze/raw_clickstream'
    """)


def parse_clickstream(df):
    """Phân tích URL thành các thành phần cấu trúc"""
    return df.withColumn("url", url_decode(col("url"))) \
            .withColumn("department", regexp_extract(col("url"), r"/department/([^/]+)", 1)) \
            .withColumn("category", regexp_extract(col("url"), r"/category/([^/]+)", 1)) \
            .withColumn("product", regexp_extract(col("url"), r"/product/([^/]+)", 1)) \
            .withColumn("add_to_cart", when(col("url").rlike(r"/add_to_cart$"), lit(1)).otherwise(lit(0))) \
            .withColumn("country", get_country_udf(col("ip")))


def load_and_write_data(spark, input_path, table_name):
    logger.info(f"Reading data from {input_path}...")

    df = (spark.read.option("header", "true")
                 .option("inferSchema", "true")
                 .csv(input_path))

    logger.info("Processing clickstream data...")
    df = parse_clickstream(df)

    logger.info(f"Writing data to {table_name}...")
    df.write.format("iceberg").mode("overwrite").save(table_name)
    logger.info("Data write completed.")


def main():
    try:
        spark = create_spark_session("InsertLogs2017")
        create_bronze_table(spark)
        load_and_write_data(spark, "/src/data/logs_2017.csv", "lakehouse.bronze.raw_clickstream")
        logger.info("Job completed successfully.")
    except Exception as e:
        logger.error(f"Job failed due to: {e}", exc_info=True)
    finally:
        spark.stop()
        logger.info("Spark Session stopped.")

if __name__ == "__main__":
    main()