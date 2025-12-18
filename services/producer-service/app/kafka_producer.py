import json
import os
import time
from kafka import KafkaProducer
from kafka.errors import NoBrokersAvailable, KafkaTimeoutError

_producer = None

# Cloud-safe environment variables
KAFKA_BOOTSTRAP_SERVERS = os.environ.get("KAFKA_BOOTSTRAP_SERVERS")
KAFKA_TOPIC = os.environ.get("KAFKA_TOPIC", "iot-data")

def get_producer():
    global _producer

    if _producer:
        return _producer

    if not KAFKA_BOOTSTRAP_SERVERS:
        raise RuntimeError("KAFKA_BOOTSTRAP_SERVERS environment variable is not set")

    retries = 10
    for i in range(retries):
        try:
            _producer = KafkaProducer(
                bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
                value_serializer=lambda v: json.dumps(v).encode("utf-8"),
                acks="all",
                retries=5,
                linger_ms=10,
                request_timeout_ms=30000,
                api_version_auto_timeout_ms=3000,
            )
            print("Kafka producer connected")
            return _producer
        except NoBrokersAvailable:
            print(f"Kafka not ready, retrying ({i + 1}/{retries})...")
            time.sleep(3)

    raise RuntimeError("Kafka not available after retries")

def send_iot_data(data: dict):
    producer = get_producer()
    try:
        producer.send(KAFKA_TOPIC, value=data)
        #producer.flush()
    except KafkaTimeoutError as e:
        print(f"Failed to send message to Kafka: {e}")
