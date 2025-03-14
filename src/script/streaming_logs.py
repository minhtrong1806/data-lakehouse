import logging
import time
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, from_json
from pyspark.sql.types import StructType, StructField, StringType, TimestampType
from pyspark.sql.utils import AnalysisException
import os

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger("ClickstreamConsumer")

def create_spark_session():
    """Tạo SparkSession với cấu hình cần thiết"""
    return SparkSession.builder.appName("ClickstreamConsumer").getOrCreate()

def define_schema():
    """Định nghĩa schema cho dữ liệu clickstream"""
    return StructType([
        StructField("event_id", StringType(), True),
        StructField("ts", TimestampType(), True),
        StructField("ip", StringType(), True),
        StructField("url", StringType(), True)
    ])

def read_from_kafka(spark, topic):
    """Đọc dữ liệu từ Kafka topic, chờ nếu topic chưa tồn tại"""
    max_retries = 10  # Số lần thử kết nối tối đa
    retry_interval = 10  # Khoảng thời gian giữa các lần thử (giây)
    attempt = 0
    
    while attempt < max_retries:
        try:
            logger.info(f"Kết nối đến Kafka topic: {topic} (thử lần {attempt + 1})")
            return spark.readStream \
                .format("kafka") \
                .option("kafka.bootstrap.servers", "kafka:9092") \
                .option("subscribe", topic) \
                .option("startingOffsets", "earliest") \
                .load()
        except AnalysisException as e:
            if "Topic not present in metadata" in str(e):
                logger.warning(f"Không tìm thấy topic {topic}, sẽ thử lại sau {retry_interval} giây...")
                time.sleep(retry_interval)
                attempt += 1
            else:
                logger.error(f"Lỗi khác khi kết nối Kafka: {str(e)}")
                raise
    
    logger.error(f"Không thể kết nối đến Kafka topic {topic} sau {max_retries} lần thử")
    raise RuntimeError("Kafka topic không khả dụng")

def process_stream(df, schema):
    """Chuyển đổi dữ liệu Kafka thành DataFrame với schema đã định nghĩa"""
    logger.info("Đang chuyển đổi dữ liệu từ Kafka")
    return df.selectExpr("CAST(value AS STRING)") \
        .select(from_json(col("value"), schema).alias("data")) \
        .select("data.*")

def write_to_iceberg(df, table_name, checkpoint_path):
    """Ghi dữ liệu vào Iceberg table với kiểm tra tránh chạy trùng job"""
    logger.info(f"Bắt đầu ghi dữ liệu vào {table_name}")
    
    # Định danh duy nhất cho job tránh chạy trùng
    query_name = "clickstream_query"
    return df.writeStream \
        .format("iceberg") \
        .option("checkpointLocation", checkpoint_path) \
        .option("queryName", query_name) \
        .outputMode("append") \
        .start(table_name)

if __name__ == "__main__":
    try:
        logger.info("Khởi tạo Spark Session")
        spark = create_spark_session()
        schema = define_schema()

        kafka_topic = "clickstream"
        iceberg_table = "lakehouse.bronze.raw_clickstream"
        checkpoint_path = "s3a://lakehouse/checkpoints/"

        kafka_df = read_from_kafka(spark, kafka_topic)
        clickstream_df = process_stream(kafka_df, schema)

        query = write_to_iceberg(clickstream_df, iceberg_table, checkpoint_path)
        logger.info("Streaming đã bắt đầu")

        query.awaitTermination()
    except Exception as e:
        logger.error(f"Lỗi trong quá trình xử lý: {str(e)}", exc_info=True)
