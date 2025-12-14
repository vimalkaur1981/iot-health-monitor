from prometheus_client import Counter, start_http_server

# Counter for number of messages consumed
iot_messages_consumed = Counter(
    "iot_messages_consumed_total",
    "Total number of IoT messages consumed from Kafka"
)

def start_metrics_server(port: int = 8002):
    """
    Start a Prometheus metrics HTTP server
    """
    start_http_server(port)
    print(f"Consumer Prometheus metrics server running on port {port}")
