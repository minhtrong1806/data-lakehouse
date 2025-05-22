from dagster import job, op
from dagster_dbt import DbtCliResource
from dagster_pyspark import pyspark_resource
from src.script.customer_segment import (
    init_spark_session as customer_spark_init,
    load_data,
    preprocess_sales_data,
    join_sales_with_customer,
    calculate_rfm,
    apply_feature_engineering,
    predict_segments,
    create_output_table,
    apply_scd_type2
)

# Configuration for dbt resource
dbt_resource = DbtCliResource(
    project_dir="f:/KLTN/data-lakehouse/src/pipeline",  
    profiles_dir="f:/KLTN/data-lakehouse/src/pipeline", 
    # project_dir="/src/pipeline",  # Directory containing dbt project
    # profiles_dir="/src/pipeline",  # Directory containing profiles.yml
    target="dev"
)

spark_resource = pyspark_resource.configured({
    "spark_conf": {
        "spark.master": "local[*]",  # Can be adjusted for cluster mode
        "spark.sql.iceberg.vectorization.enabled": "false",
    }
})


@op(required_resource_keys={"dbt"})
def run_dbt_bronze(context):
    context.resources.dbt.cli(["run", "--select", "tag:bronze"])

@op(required_resource_keys={"dbt"})
def run_dbt_silver(context):
    context.resources.dbt.cli(["run", "--select", "tag:silver -stg_clickstream"])

@op(required_resource_keys={"dbt"})
def run_dbt_gold(context):
    context.resources.dbt.cli(["run", "--select", "tag:gold -fact_clickstream"])

@op(required_resource_keys={"dbt"})
def run_dbt_clickstream_silver(context):
    context.resources.dbt.cli(["run", "--select", "stg_clickstream"])

@op(required_resource_keys={"dbt"})
def run_dbt_clickstream_gold(context):
    context.resources.dbt.cli(["run", "--select", "fact_clickstream"])

# Define PySpark operations for customer segmentation
@op(required_resource_keys={"pyspark"})
def initialize_customer_spark(context):
    # Không trả về SparkSession vì nó không thể được serialize
    return "Spark session initialized"

@op(required_resource_keys={"pyspark"})
def run_customer_segmentation(context):
    spark = context.resources.pyspark.spark_session
    config = {
        "app_name": "PredictCustomerSegmentation",
        # "model_path": "/src/models/kmeans_rfm_model",
        "model_path": "f:/KLTN/data-lakehouse/src/models/kmeans_rfm_model",
        "analysis_date": "2017-09-30",
        "analysis_timestamp": "2017-09-30 23:38:00.000",
        "table_names": {
            "fact_sales": "lakehouse.gold.fact_sales",
            "dim_customer": "lakehouse.gold.dim_customer"
        },
        "output_table": "lakehouse.gold.customer_rfm_segments"
    }
    create_output_table(spark, config["output_table"])
    fact_sales, dim_customer = load_data(spark, config["table_names"])
    fact_sales = preprocess_sales_data(fact_sales)
    sales_data = join_sales_with_customer(fact_sales, dim_customer)
    rfm_df = calculate_rfm(sales_data, config["analysis_date"], config["analysis_timestamp"])
    features_df = apply_feature_engineering(rfm_df)
    prediction_df = predict_segments(config["model_path"], features_df)
    apply_scd_type2(spark, prediction_df, config["output_table"], config["analysis_timestamp"])
    return "Customer segmentation completed"

@job(resource_defs={"dbt": dbt_resource})
def dbt_transformation_pipeline():

    run_dbt_bronze()
    run_dbt_silver()
    run_dbt_gold()


@job(resource_defs={"dbt": dbt_resource})
def dbt_clickstream_pipeline():

    run_dbt_clickstream_silver()
    run_dbt_clickstream_gold()


@job(resource_defs={"pyspark": spark_resource})
def customer_segmentation_pipeline():

    initialize_customer_spark()
    run_customer_segmentation()
