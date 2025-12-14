from fastapi import FastAPI
from app.kafka_producer import send_iot_data
from app.metrics import iot_messages_sent, start_metrics_server
import threading

app = FastAPI()

# Start metrics server in a separate thread
threading.Thread(target=start_metrics_server, daemon=True).start()

@app.post("/iot/data")
def ingest(payload: dict):
    send_iot_data(payload)
    iot_messages_sent.inc()  # increment Prometheus counter
    return {"status": "sent"}

@app.get("/health")
def health():
    return {"status": "ok"}

