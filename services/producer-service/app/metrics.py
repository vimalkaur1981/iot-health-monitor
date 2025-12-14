from prometheus_client import Counter, start_http_server

# Counter for number of messages sent
iot_messages_sent = Counter(
    "iot_messages_sent_total",
    "Total number of IoT messages sent to Kafka"
)

def start_metrics_server(port: int = 8001):
    """
    Start a Prometheus HTTP metrics server
    """
    start_http_server(port)
    print(f"Prometheus metrics server running on port {port}")
