from dagster import AssetExecutionContext, op, asset
from dagster_dbt import DbtCliResource, dbt_assets
from dagster import graph

from .project import pipeline_project


@dbt_assets(manifest=pipeline_project.manifest_path)
def pipeline_dbt_assets(context: AssetExecutionContext, dbt: DbtCliResource):
    # Chạy dbt theo thứ tự bronze, silver, gold
    context.log.info("Chạy dbt cho tất cả các layer")
    yield from dbt.cli(["run", "--select", "tag:bronze tag:silver tag:gold"], context=context).stream()

import traceback

@asset(required_resource_keys={"pyspark"}, deps=[["gold", "fact_sales"], ["gold", "dim_customer"]])
def customer_segmentation_asset(context: AssetExecutionContext):
    try:
        spark = context.resources.pyspark.spark_session
        config = {
            "app_name": "PredictCustomerSegmentation",
            "model_path": "/src/models/kmeans_rfm_model",
            "analysis_date": "2017-09-30",
            "analysis_timestamp": "2017-09-30 23:38:00.000",
            "table_names": {
                "fact_sales": "lakehouse.gold.fact_sales",
                "dim_customer": "lakehouse.gold.dim_customer"
            },
            "output_table": "lakehouse.gold.customer_rfm_segments"
        }

        import sys
        import os
        sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../')))
        from src.script.customer_segment import (
            create_output_table, load_data, preprocess_sales_data,
            join_sales_with_customer, calculate_rfm, apply_feature_engineering,
            predict_segments, apply_scd_type2
        )

        context.log.info("Khởi tạo Spark session cho phân khúc khách hàng")
        create_output_table(spark, config["output_table"])
        fact_sales, dim_customer = load_data(spark, config["table_names"])
        fact_sales = preprocess_sales_data(fact_sales)
        sales_data = join_sales_with_customer(fact_sales, dim_customer)
        rfm_df = calculate_rfm(sales_data, config["analysis_date"], config["analysis_timestamp"])
        features_df = apply_feature_engineering(rfm_df)
        prediction_df = predict_segments(config["model_path"], features_df)
        apply_scd_type2(spark, prediction_df, config["output_table"], config["analysis_timestamp"])

        context.log.info("Pipeline phân khúc khách hàng đã hoàn thành")
        return "Customer segmentation completed"
    
    except Exception as e:
        context.log.error("Lỗi xảy ra trong asset customer_segmentation_asset: " + str(e))
        context.log.error(traceback.format_exc())
        raise e
