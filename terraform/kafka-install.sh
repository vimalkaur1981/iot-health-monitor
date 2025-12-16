#!/bin/bash
set -e

# ================================
# Kafka install for Amazon Linux 2
# ================================

KAFKA_VERSION="3.6.1"
SCALA_VERSION="2.13"
KAFKA_HOME="/opt/kafka"
KAFKA_PORT=9092

yum update -y

# Install Java
amazon-linux-extras enable java-openjdk11
yum install -y java-11-openjdk wget

# Download Kafka
cd /opt
wget https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
tar -xzf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
mv kafka_${SCALA_VERSION}-${KAFKA_VERSION} kafka

# Get private IP for Kafka advertising
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Kafka config
cat <<EOF > $KAFKA_HOME/config/server.properties
broker.id=1
listeners=PLAINTEXT://0.0.0.0:${KAFKA_PORT}
advertised.listeners=PLAINTEXT://${PRIVATE_IP}:${KAFKA_PORT}
num.partitions=1
log.dirs=/tmp/kafka-logs
zookeeper.connect=localhost:2181
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
EOF

# Start Zookeeper
nohup $KAFKA_HOME/bin/zookeeper-server-start.sh \
  $KAFKA_HOME/config/zookeeper.properties > /var/log/zookeeper.log 2>&1 &

sleep 10

# Start Kafka
nohup $KAFKA_HOME/bin/kafka-server-start.sh \
  $KAFKA_HOME/config/server.properties > /var/log/kafka.log 2>&1 &

# Add Kafka to PATH
echo "export PATH=\$PATH:$KAFKA_HOME/bin" >> /etc/profile

echo "Kafka installation completed"
