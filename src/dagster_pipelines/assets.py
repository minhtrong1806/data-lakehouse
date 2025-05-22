from dagster import asset, Output, AssetIn
from dagster_dbt import DbtCliResource

# Cấu hình tài nguyên dbt
dbt_resource = DbtCliResource(
    project_dir="f:/KLTN/data-lakehouse/src/pipeline",  
    profiles_dir="f:/KLTN/data-lakehouse/src/pipeline", 
    target="dev"
)

# Định nghĩa các asset dựa trên các job dbt trong jobs.py
@asset
def bronze_tables(context):
    """Asset đại diện cho các bảng ở tầng Bronze được tạo bởi job dbt_transformation_pipeline."""
    result = context.resources.dbt.cli(["run", "--select", "tag:bronze"]).wait()
    return Output(value=None, metadata={"status": "completed" if result.success else "failed"})

@asset(ins={"bronze_tables": AssetIn()})
def silver_tables(context, bronze_tables):
    """Asset đại diện cho các bảng ở tầng Silver được tạo bởi job dbt_transformation_pipeline."""
    result = context.resources.dbt.cli(["run", "--select", "tag:silver -stg_clickstream"]).wait()
    return Output(value=None, metadata={"status": "completed" if result.success else "failed"})

@asset(ins={"silver_tables": AssetIn()})
def gold_tables(context, silver_tables):
    """Asset đại diện cho các bảng ở tầng Gold được tạo bởi job dbt_transformation_pipeline."""
    result = context.resources.dbt.cli(["run", "--select", "tag:gold -fact_clickstream"]).wait()
    return Output(value=None, metadata={"status": "completed" if result.success else "failed"})

@asset
def clickstream_silver(context):
    """Asset đại diện cho bảng stg_clickstream ở tầng Silver được tạo bởi job dbt_clickstream_pipeline."""
    result = context.resources.dbt.cli(["run", "--select", "stg_clickstream"]).wait()
    return Output(value=None, metadata={"status": "completed" if result.success else "failed"})

@asset(ins={"clickstream_silver": AssetIn()})
def clickstream_gold(context, clickstream_silver):
    """Asset đại diện cho bảng fact_clickstream ở tầng Gold được tạo bởi job dbt_clickstream_pipeline."""
    result = context.resources.dbt.cli(["run", "--select", "fact_clickstream"]).wait()
    return Output(value=None, metadata={"status": "completed" if result.success else "failed"})

# Định nghĩa asset dựa trên job customer_segmentation_pipeline
@asset(ins={"gold_tables": AssetIn()})
def customer_rfm_segments(context, gold_tables):
    """Asset đại diện cho bảng customer_rfm_segments được tạo bởi job customer_segmentation_pipeline."""
    # Giả lập kết quả từ job PySpark, thực tế sẽ cần tích hợp với PySpark resource
    return Output(value=None, metadata={"status": "completed", "description": "Customer RFM segments calculated"})