import json
import os
import time
from kafka import KafkaProducer
from kafka.errors import NoBrokersAvailable

_producer = None

def get_producer():
    global _producer

    if _producer:
        return _producer

    retries = 10
    for i in range(retries):
        try:
            _producer = KafkaProducer(
                bootstrap_servers=os.getenv("KAFKA_BOOTSTRAP_SERVERS"),
                value_serializer=lambda v: json.dumps(v).encode("utf-8"),
                api_version_auto_timeout_ms=3000
            )
            print("Kafka producer connected")
            return _producer
        except NoBrokersAvailable:
            print(f"Kafka not ready, retrying ({i+1}/{retries})...")
            time.sleep(3)

    raise Exception("Kafka not available after retries")


def send_iot_data(data: dict):
    producer = get_producer()
    producer.send("iot-data", value=data)
    producer.flush()
