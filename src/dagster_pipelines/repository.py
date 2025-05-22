"""
Dagster repository definition to orchestrate dbt models and PySpark jobs.
This file serves as the entry point for Dagster to recognize assets, jobs, and schedules.
"""

from dagster import repository
from src.dagster_pipelines.jobs import dbt_transformation_pipeline, dbt_clickstream_pipeline, customer_segmentation_pipeline
from src.dagster_pipelines.schedules import clickstream_schedule, transformation_schedule, customer_segmentation_schedule

@repository
def data_lakehouse_repository():
    """
    The main repository definition for Dagster.
    Includes all jobs and schedules for data transformation and processing.
    Note: dbt_assets are not included due to compatibility issues with the current version of dagster_dbt.
    """
    return [
        dbt_transformation_pipeline,
        dbt_clickstream_pipeline,
        customer_segmentation_pipeline,
        clickstream_schedule,
        transformation_schedule,
        customer_segmentation_schedule
    ]