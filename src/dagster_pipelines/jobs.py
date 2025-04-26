"""
Dagster job definitions for orchestrating dbt models and PySpark jobs.
This file defines the jobs to run dbt models and PySpark processing in sequence.
"""

from dagster import job, op
from dagster_dbt import dbt_cli_resource, dbt_run_op
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
dbt_resource = dbt_cli_resource.configured({
    "project_dir": "f:/KLTN/data-lakehouse/src/pipeline",  # Directory containing dbt project
    "profiles_dir": "f:/KLTN/data-lakehouse/src/pipeline",  # Directory containing profiles.yml
    "target": "dev"  # Target environment, adjust as needed
})

# Configuration for PySpark resource
spark_resource = pyspark_resource.configured({
    "spark_conf": {
        "spark.master": "local[*]",  # Can be adjusted for cluster mode
        "spark.sql.iceberg.vectorization.enabled": "false",
    }
})

# Define dbt run operations for each layer
dbt_run_bronze = dbt_run_op.configured(
    {"select": "tag:bronze"},
    name="run_dbt_bronze"
)

dbt_run_silver = dbt_run_op.configured(
    {"select": "tag:silver -stg_clickstream"},
    name="run_dbt_silver"
)

dbt_run_gold = dbt_run_op.configured(
    {"select": "tag:gold -fact_clickstream"},
    name="run_dbt_gold"
)

dbt_run_clickstream_silver = dbt_run_op.configured(
    {"select": "stg_clickstream"},
    name="run_dbt_clickstream_silver"
)

dbt_run_clickstream_gold = dbt_run_op.configured(
    {"select": "fact_clickstream"},
    name="run_dbt_clickstream_gold"
)

# Define PySpark operations for customer segmentation
@op(required_resource_keys={"pyspark"})
def initialize_customer_spark(context):
    spark = context.resources.pyspark.spark_session
    return spark

@op
def run_customer_segmentation(spark):
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
    create_output_table(spark, config["output_table"])
    fact_sales, dim_customer = load_data(spark, config["table_names"])
    fact_sales = preprocess_sales_data(fact_sales)
    sales_data = join_sales_with_customer(fact_sales, dim_customer)
    rfm_df = calculate_rfm(sales_data, config["analysis_date"], config["analysis_timestamp"])
    features_df = apply_feature_engineering(rfm_df)
    prediction_df = predict_segments(config["model_path"], features_df)
    apply_scd_type2(spark, prediction_df, config["output_table"], config["analysis_timestamp"])
    return "Customer segmentation completed"

# Define a job to run dbt models in sequence for non-streaming data
@job(resource_defs={"dbt": dbt_resource})
def dbt_transformation_pipeline():
    """
    A Dagster job to run dbt models for data transformation.
    Executes bronze, silver, and gold layer models in sequence for non-streaming data.
    """
    bronze_result = dbt_run_bronze()
    silver_result = dbt_run_silver.after(bronze_result)
    dbt_run_gold.after(silver_result)

# Define a separate job for clickstream streaming data (dbt)
@job(resource_defs={"dbt": dbt_resource})
def dbt_clickstream_pipeline():
    """
    A Dagster job to run dbt models specifically for clickstream streaming data.
    Executes stg_clickstream (silver) and fact_clickstream (gold) in sequence.
    """
    silver_result = dbt_run_clickstream_silver()
    dbt_run_clickstream_gold.after(silver_result)

# Define a job for customer segmentation using PySpark
@job(resource_defs={"pyspark": spark_resource})
def customer_segmentation_pipeline():
    """
    A Dagster job to run PySpark processing for customer segmentation based on RFM metrics.
    """
    spark = initialize_customer_spark()
    run_customer_segmentation(spark)