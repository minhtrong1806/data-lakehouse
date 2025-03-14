import logging
import time
import csv
import json
from datetime import datetime
from kafka.admin import KafkaAdminClient, NewTopic
from kafka import KafkaProducer, KafkaConsumer
from trino.dbapi import connect

# Cấu hình logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# Kafka & Trino Config
BOOTSTRAP_SERVERS = "kafka:9092"
CSV_FILE = "/src/data/logs_2018.csv"
TOPIC_NAME = "clickstream"
TIMESTAMP_COL = "ts"
TIME_FORMAT = "%Y-%m-%d %H:%M:%S"
TRINO_HOST = "trino"
TRINO_PORT = 8060
TRINO_CATALOG = "lakehouse"
TRINO_SCHEMA = "bronze"

def create_topic():
    """Tạo topic Kafka nếu chưa tồn tại."""
    admin_client = KafkaAdminClient(bootstrap_servers=BOOTSTRAP_SERVERS, client_id="clickstream_admin")
    topic_list = [NewTopic(name=TOPIC_NAME, num_partitions=1, replication_factor=1)]
    try:
        admin_client.create_topics(new_topics=topic_list, validate_only=False)
        logging.info(f"Topic '{TOPIC_NAME}' đã được tạo thành công!")
    except Exception as e:
        logging.warning(f"Không thể tạo topic '{TOPIC_NAME}' (có thể đã tồn tại): {e}")
    finally:
        admin_client.close()

def init_producer():
    """Khởi tạo Kafka Producer với JSON serializer."""
    return KafkaProducer(
        bootstrap_servers=BOOTSTRAP_SERVERS,
        value_serializer=lambda v: json.dumps(v).encode("utf-8")  # Serialize JSON đúng chuẩn
    )

def init_consumer():
    """Khởi tạo Kafka Consumer để lấy event_id từ Kafka."""
    def safe_json_deserializer(message):
        try:
            return json.loads(message.decode("utf-8"))
        except json.JSONDecodeError as e:
            logging.error(f"Lỗi giải mã JSON: {e}, dữ liệu nhận được: {message}")
            return None

    return KafkaConsumer(
        TOPIC_NAME,
        bootstrap_servers=BOOTSTRAP_SERVERS,
        auto_offset_reset="earliest",
        enable_auto_commit=False,
        value_deserializer=safe_json_deserializer
    )

def get_existing_event_ids():
    """Lấy event_id từ bảng raw_clickstream trong năm 2018."""
    logging.info("Đang lấy danh sách event_id từ Trino...")
    conn = connect(
        host=TRINO_HOST,
        port=TRINO_PORT,
        user='admin',  # Trino yêu cầu user, có thể là 'admin'
        catalog=TRINO_CATALOG,
        schema=TRINO_SCHEMA
    )
    cursor = conn.cursor()

    query = """
    SELECT event_id
    FROM lakehouse.bronze.raw_clickstream
    WHERE EXTRACT(YEAR FROM ts) = 2018
    """
    cursor.execute(query)
    result = cursor.fetchall()
    conn.close()

    existing_event_ids = {row[0] for row in result}
    logging.info(f"Đã lấy {len(existing_event_ids)} event_id từ Trino.")
    return existing_event_ids

def get_sent_event_ids():
    """Lấy event_id của những message đã gửi lên Kafka."""
    logging.info("Đang lấy danh sách event_id từ Kafka...")
    consumer = init_consumer()
    sent_event_ids = set()

    timeout_seconds = 5
    end_time = time.time() + timeout_seconds
    while time.time() < end_time:
        msg_pack = consumer.poll(timeout_ms=500)
        if not msg_pack:
            break
        for tp, messages in msg_pack.items():
            for message in messages:
                if message.value and "event_id" in message.value:
                    sent_event_ids.add(message.value["event_id"])
    consumer.close()
    logging.info(f"Đã lấy {len(sent_event_ids)} event_id từ Kafka.")
    return sent_event_ids


def send_messages(producer):
    """Đọc dữ liệu từ CSV và gửi lên Kafka sau khi loại bỏ các event_id đã tồn tại."""
    existing_event_ids = get_existing_event_ids()
    sent_event_ids = get_sent_event_ids()

    with open(CSV_FILE, mode="r", encoding="utf-8") as file:
        csv_reader = csv.DictReader(file)
        prev_time = None
        
        for row in csv_reader:
            try:
                current_time = datetime.strptime(row[TIMESTAMP_COL], TIME_FORMAT)
                
                # Kiểm tra nếu event_id đã tồn tại thì bỏ qua
                event_id = row["event_id"]
                if event_id in existing_event_ids or event_id in sent_event_ids:
                    continue
                
                # Delay
                if prev_time is not None:
                    delay = (current_time - prev_time).total_seconds() * 0.1
                    if delay > 0:
                        time.sleep(delay)
                
                # Gửi message
                producer.send(TOPIC_NAME, value=row)
                logging.info(f"Đã gửi record: {row}")
                
                prev_time = current_time
            except Exception as e:
                logging.error(f"Lỗi khi xử lý record {row}: {e}")
    
    producer.flush()
    producer.close()
    logging.info("Đã gửi xong tất cả dữ liệu!")

if __name__ == "__main__":
    create_topic()
    producer = init_producer()
    send_messages(producer)
