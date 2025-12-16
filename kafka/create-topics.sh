#!/bin/bash
set -e

TOPIC_NAME="${KAFKA_TOPIC:-iot-data}"
BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVERS:-kafka:9092}"
PARTITIONS="${KAFKA_PARTITIONS:-3}"
REPLICATION_FACTOR="${KAFKA_REPLICATION_FACTOR:-1}"

echo "Waiting for Kafka to be ready on ${BOOTSTRAP_SERVER}..."

until kafka-topics --bootstrap-server "$BOOTSTRAP_SERVER" --list >/dev/null 2>&1; do
  echo "Kafka not ready, retrying in 3 seconds..."
  sleep 3
done

echo "Kafka is ready. Creating topic '${TOPIC_NAME}' if it does not exist..."

kafka-topics \
  --bootstrap-server "$BOOTSTRAP_SERVER" \
  --create \
  --if-not-exists \
  --topic "$TOPIC_NAME" \
  --partitions "$PARTITIONS" \
  --replication-factor "$REPLICATION_FACTOR"

echo "Topic '${TOPIC_NAME}' is ready."
