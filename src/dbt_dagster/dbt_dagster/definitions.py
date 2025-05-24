from dagster import Definitions
from dagster_dbt import DbtCliResource
from dagster_pyspark import pyspark_resource
from .assets import pipeline_dbt_assets, customer_segmentation_asset
from .project import pipeline_project
from .schedules import schedules

from dagster import define_asset_job

defs = Definitions(
    assets=[pipeline_dbt_assets, customer_segmentation_asset],
    schedules=schedules,
    jobs=[
        define_asset_job("customer_segmentation_job", selection=["customer_segmentation_asset"])
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