from fastapi import FastAPI
from app.kafka_producer import send_iot_data
from app.metrics import iot_messages_sent, start_metrics_server
import threading

app = FastAPI(title="IoT Producer Service")

# Start metrics server on ECS startup
@app.on_event("startup")
def start_background_services():
    threading.Thread(target=start_metrics_server, daemon=True).start()

@app.post("/iot-data", status_code=202)
def ingest(payload: dict):
    """Endpoint to receive IoT data via curl"""
    send_iot_data(payload)
    iot_messages_sent.inc()  # Prometheus metric
    return {"status": "sent"}

@app.get("/health")
def health():
    return {"status": "ok"}
