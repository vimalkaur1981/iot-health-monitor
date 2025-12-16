from prometheus_client import Counter, start_http_server
import threading

# ======================
# Metrics Counters
# ======================
iot_messages_consumed = Counter(
    "iot_messages_consumed_total",
    "Total number of IoT messages consumed from Kafka"
)

iot_messages_sent = Counter(
    "iot_messages_sent_total",
    "Total number of IoT messages produced to Kafka"
)

# ======================
# Metrics Server
# ======================
def start_metrics_server(port: int = 8002):
    """
    Start a Prometheus metrics HTTP server in a background thread
    """
    def run_server():
        start_http_server(port)
        print(f"[{port}] Prometheus metrics server running")

    threading.Thread(target=run_server, daemon=True).start()
