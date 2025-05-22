from dagster import AssetExecutionContext, op, asset
from dagster_dbt import DbtCliResource, dbt_assets

from .project import pipeline_project


@dbt_assets(manifest=pipeline_project.manifest_path)
def pipeline_dbt_assets(context: AssetExecutionContext, dbt: DbtCliResource):
    # Chạy các bước dbt theo thứ tự bronze, silver, gold
    context.log.info("Chạy dbt cho bronze layer")
    yield from dbt.cli(["run", "--select", "tag:bronze"], context=context).stream()
    
    context.log.info("Chạy dbt cho silver layer")
    yield from dbt.cli(["run", "--select", "tag:silver -stg_clickstream"], context=context).stream()
    
    context.log.info("Chạy dbt cho gold layer")
    yield from dbt.cli(["run", "--select", "tag:gold -fact_clickstream"], context=context).stream()
    
    context.log.info("Chạy dbt cho clickstream silver")
    yield from dbt.cli(["run", "--select", "stg_clickstream"], context=context).stream()
    
    context.log.info("Chạy dbt cho clickstream gold")
    yield from dbt.cli(["run", "--select", "fact_clickstream"], context=context).stream()

@op(required_resource_keys={"pyspark"})
def initialize_customer_spark(context):
    return "Spark session initialized"

@op(required_resource_keys={"pyspark"})
def run_customer_segmentation(context):
    spark = context.resources.pyspark.spark_session
    config = {
        "app_name": "PredictCustomerSegmentation",
        "model_path": "f:/KLTN/data-lakehouse/src/models/kmeans_rfm_model",
        "analysis_date": "2017-09-30",
        "analysis_timestamp": "2017-09-30 23:38:00.000",
        "table_names": {
            "fact_sales": "lakehouse.gold.fact_sales",
            "dim_customer": "lakehouse.gold.dim_customer"
        },
        "output_table": "lakehouse.gold.customer_rfm_segments"
    }
    from src.script.customer_segment import (
        create_output_table, load_data, preprocess_sales_data,
        join_sales_with_customer, calculate_rfm, apply_feature_engineering,
        predict_segments, apply_scd_type2
    )
    create_output_table(spark, config["output_table"])
    fact_sales, dim_customer = load_data(spark, config["table_names"])
    fact_sales = preprocess_sales_data(fact_sales)
    sales_data = join_sales_with_customer(fact_sales, dim_customer)
    rfm_df = calculate_rfm(sales_data, config["analysis_date"], config["analysis_timestamp"])
    features_df = apply_feature_engineering(rfm_df)
    prediction_df = predict_segments(config["model_path"], features_df)
    apply_scd_type2(spark, prediction_df, config["output_table"], config["analysis_timestamp"])
    context.log.info("Hoàn thành phân khúc khách hàng")
    return "Customer segmentation completed"

@asset(required_resource_keys={"pyspark"}, deps=[["gold", "fact_sales"], ["gold", "dim_customer"]])
def customer_segmentation_asset(context: AssetExecutionContext):
    init = initialize_customer_spark()
    result = run_customer_segmentation()
    context.log.info("Pipeline phân khúc khách hàng đã hoàn thành")
    return result