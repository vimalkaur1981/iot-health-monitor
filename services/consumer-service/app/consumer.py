import time
from kafka import KafkaConsumer, errors
import os
import json
import threading
from app.metrics import iot_messages_consumed, start_metrics_server

# Start metrics server
threading.Thread(target=start_metrics_server, daemon=True).start()

# Retry loop
while True:
    try:
        consumer = KafkaConsumer(
            "iot-data",
            bootstrap_servers=os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092"),
            value_deserializer=lambda v: json.loads(v.decode("utf-8")),
            group_id="iot-consumer-group",
            auto_offset_reset="earliest"
        )
        print("Consumer connected to Kafka")
        break
    except errors.NoBrokersAvailable:
        print("Kafka not available, retrying in 3s...")
        time.sleep(3)

# Consume messages
for msg in consumer:
    print(f"Received: {msg.value}")
    iot_messages_consumed.inc()
