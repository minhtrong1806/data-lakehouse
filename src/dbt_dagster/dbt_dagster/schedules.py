from dagster import ScheduleDefinition
from dagster_dbt import build_schedule_from_dbt_selection
from .assets import pipeline_dbt_assets, customer_segmentation_asset

clickstream_schedule = build_schedule_from_dbt_selection(
    [pipeline_dbt_assets],
    job_name="materialize_dbt_clickstream",
    cron_schedule="*/5 * * * *",  # Runs every 5 minutes
    dbt_select="stg_clickstream fact_clickstream",
    execution_timezone="Asia/Saigon"
)

transformation_schedule = build_schedule_from_dbt_selection(
    [pipeline_dbt_assets],
    job_name="materialize_dbt_transformation",
    cron_schedule="0 2 * * *",  # Runs daily at 2 AM
    dbt_select="raw_categories raw_customers raw_order_items raw_orders raw_products raw_shipping raw_stores stg_categories stg_customers stg_order_items stg_orders stg_products stg_shipping stg_stores dim_category dim_customer dim_date dim_delivery_status dim_geography dim_order_status dim_payment_type dim_product dim_shipping_mode dim_store fact_sales",
    execution_timezone="Asia/Saigon"
)

customer_segmentation_schedule = ScheduleDefinition(
    job_name="customer_segmentation_job",
    cron_schedule="0 3 * * 0",  # Runs every Sunday at 3 AM
    execution_timezone="Asia/Saigon"
)

schedules = [
    clickstream_schedule,
    transformation_schedule,
    customer_segmentation_schedule
]
