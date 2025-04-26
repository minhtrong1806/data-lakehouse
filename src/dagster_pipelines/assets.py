"""
Dagster asset definitions for dbt models.
This file defines the assets (data outputs) that dbt models produce.
"""

from dagster_dbt import load_assets_from_dbt_project

# Configuration for dbt project
DBT_PROJECT_DIR = "f:/KLTN/data-lakehouse/src/pipeline"
DBT_PROFILES_DIR = "f:/KLTN/data-lakehouse/src/pipeline"

# Load dbt assets for bronze, silver, gold, and clickstream
dbt_assets = load_assets_from_dbt_project(
    project_dir=DBT_PROJECT_DIR,
    profiles_dir=DBT_PROFILES_DIR,
    target="dev",  # Target environment, adjust as needed
    select="tag:bronze tag:silver tag:gold stg_clickstream fact_clickstream"
)