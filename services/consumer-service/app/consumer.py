import json
import time
import os
import threading
from kafka import KafkaConsumer, KafkaProducer, errors
from app.metrics import iot_messages_consumed, start_metrics_server

# ======================
# Configuration
# ======================
BOOTSTRAP_SERVERS = os.environ.get("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092")

STATUS_TOPIC = "iot-data"
ALERT_TOPIC = "device-alerts"

DEVICE_TIMEOUT = 120        # seconds
CHECK_INTERVAL = 5          # seconds

# ======================
# In-memory State
# ======================
last_seen = {}              # device_id -> last timestamp
device_state = {}           # device_id -> UP | DOWN
state_lock = threading.Lock()

# ======================
# Metrics Server
# ======================
threading.Thread(target=start_metrics_server, daemon=True).start()

# ======================
# Kafka Consumer (Retry)
# ======================
def create_consumer():
    while True:
        try:
            consumer = KafkaConsumer(
                STATUS_TOPIC,
                bootstrap_servers=BOOTSTRAP_SERVERS,
                value_deserializer=lambda v: json.loads(v.decode("utf-8")),
                group_id="iot-status-consumer",
                auto_offset_reset="earliest",
                enable_auto_commit=True
            )
            print("✅ Status consumer connected to Kafka")
            return consumer
        except errors.NoBrokersAvailable:
            print("⏳ Kafka not available, retrying in 3s...")
            time.sleep(3)

def create_producer():
    while True:
        try:
            producer = KafkaProducer(
                bootstrap_servers=BOOTSTRAP_SERVERS,
                value_serializer=lambda v: json.dumps(v).encode("utf-8"),
                retries=5,
                linger_ms=10,
                request_timeout_ms=10000,
                api_version_auto_timeout_ms=10000
            )
            print("✅ Kafka producer connected")
            return producer
        except errors.NoBrokersAvailable:
            print("⏳ Kafka not available for producer, retrying in 3s...")
            time.sleep(3)
# ======================
# Kafka Producer
# ======================
producer =create_producer()

# ======================
# Alert Helpers
# ======================
def send_alert(event):
    producer.send(ALERT_TOPIC, value=event)
    producer.flush()
    print(f"🚨 Alert sent → {event['alert_type']} for {event['device_id']}")

def utc_now():
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

# ======================
# Device Timeout Checker
# ======================
def monitor_device_timeouts():
    while True:
        now = time.time()
        with state_lock:
            for device_id, ts in list(last_seen.items()):
                if now - ts > DEVICE_TIMEOUT:
                    if device_state.get(device_id) != "DOWN":
                        device_state[device_id] = "DOWN"

                        send_alert({
                            "device_id": device_id,
                            "alert_type": "DEVICE_DOWN",
                            "severity": "CRITICAL",
                            "timestamp": utc_now(),
                            "message": f"Device {device_id} is DOWN"
                        })

        time.sleep(CHECK_INTERVAL)

# ======================
# Consumer Loop
# ======================
def consume_status_events():
    consumer = create_consumer()
    print("🚀 Status consumer running")

    for msg in consumer:
        data = msg.value
        iot_messages_consumed.inc()

        device_id = data["device_id"]
        now = time.time()

        with state_lock:
            last_seen[device_id] = now

            # Recovery detection
            if device_state.get(device_id) == "DOWN":
                device_state[device_id] = "UP"

                send_alert({
                    "device_id": device_id,
                    "alert_type": "DEVICE_RECOVERED",
                    "severity": "INFO",
                    "message": f"Device {device_id} recovered"
                })

        print(f"📩 Status received from {device_id}")

# ======================
# Startup
# ======================
if __name__ == "__main__":
    threading.Thread(
        target=monitor_device_timeouts,
        daemon=True
    ).start()

    consume_status_events()
