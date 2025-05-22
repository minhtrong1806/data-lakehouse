from dagster import ScheduleDefinition
from src.dagster_pipelines.jobs import dbt_transformation_pipeline, dbt_clickstream_pipeline, customer_segmentation_pipeline

# Schedule for clickstream pipeline (dbt only) to run frequently due to streaming nature
clickstream_schedule = ScheduleDefinition(
    job=dbt_clickstream_pipeline,
    cron_schedule="*/5 * * * *",  # Runs every 5 minutes
    execution_timezone="Asia/Saigon"
)

# Schedule for regular transformation pipeline (dbt, non-streaming) to run daily
transformation_schedule = ScheduleDefinition(
    job=dbt_transformation_pipeline,
    cron_schedule="0 2 * * *",  # Runs daily at 2 AM
    execution_timezone="Asia/Saigon"
)

# Schedule for customer segmentation pipeline (PySpark) to run weekly
customer_segmentation_schedule = ScheduleDefinition(
    job=customer_segmentation_pipeline,
    cron_schedule="0 3 * * 0",  # Runs every Sunday at 3 AM
    execution_timezone="Asia/Saigon"
)