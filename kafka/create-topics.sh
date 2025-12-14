#!/bin/bash

echo "Waiting for Kafka to be ready..."

until kafka-topics --bootstrap-server kafka:9092 --list >/dev/null 2>&1; do
  sleep 3
done

echo "Kafka is ready. Creating topics..."

kafka-topics \
  --bootstrap-server kafka:9092 \
  --create \
  --if-not-exists \
  --topic iot-data \
  --partitions 3 \
  --replication-factor 1
