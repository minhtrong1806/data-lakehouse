from dagster import Definitions
from dagster_dbt import DbtCliResource
from dagster_pyspark import pyspark_resource
from .assets import pipeline_dbt_assets, customer_segmentation_asset
from .project import pipeline_project
from .schedules import schedules

from dagster import define_asset_job
from dagster_dbt import build_dbt_assets_job

defs = Definitions(
    assets=[pipeline_dbt_assets, customer_segmentation_asset],
    schedules=schedules,
    jobs=[
        define_asset_job("customer_segmentation_job", selection=["customer_segmentation_asset"]),
        build_dbt_assets_job("dbt_clickstream_job", dbt_assets=[pipeline_dbt_assets], select="stg_clickstream fact_clickstream"),
        build_dbt_assets_job("dbt_transformation_job", dbt_assets=[pipeline_dbt_assets], select="tag:bronze tag:silver tag:gold -stg_clickstream -fact_clickstream")
    ],
    resources={
        "dbt": DbtCliResource(project_dir=pipeline_project),
        "pyspark": pyspark_resource.configured({
            "spark_conf": {
                "spark.master": "local[*]",
                "spark.sql.iceberg.vectorization.enabled": "false",
            }
        })
    },
)