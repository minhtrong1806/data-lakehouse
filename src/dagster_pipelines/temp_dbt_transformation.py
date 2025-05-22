"""
Dagster job definition for dbt transformation pipeline.
"""

from dagster import job, op
from dagster_dbt import DbtCliResource

# Configuration for dbt resource
dbt_resource = DbtCliResource(
    project_dir="f:/KLTN/data-lakehouse/src/pipeline",  # Directory containing dbt project
    profiles_dir="f:/KLTN/data-lakehouse/src/pipeline",  # Directory containing profiles.yml
    target="dev"  # Target environment, adjust as needed
)

# Define dbt run operations for each layer
@op(required_resource_keys={"dbt"})
def run_dbt_bronze(context):
    context.resources.dbt.cli(["run", "--select", "tag:bronze"])

@op(required_resource_keys={"dbt"})
def run_dbt_silver(context):
    context.resources.dbt.cli(["run", "--select", "tag:silver -stg_clickstream"])

@op(required_resource_keys={"dbt"})
def run_dbt_gold(context):
    context.resources.dbt.cli(["run", "--select", "tag:gold -fact_clickstream"])

# Define a job to run dbt models in sequence for non-streaming data
@job(resource_defs={"dbt": dbt_resource})
def dbt_transformation_pipeline():
    """
    A Dagster job to run dbt models for data transformation.
    Executes bronze, silver, and gold layer models in sequence for non-streaming data.
    """
    run_dbt_bronze()
    run_dbt_silver()
    run_dbt_gold()