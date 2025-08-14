from pathlib import Path

from dagster_dbt import DbtProject

pipeline_project = DbtProject(
    # project_dir=Path(__file__).joinpath("..", "..", "..", "dbt").resolve(),
    # profiles_dir=Path(__file__).joinpath("..", "..", "..", "dbt", "profiles").resolve(),
    project_dir="/src/dbt"
    
)

pipeline_project.prepare_if_dev()