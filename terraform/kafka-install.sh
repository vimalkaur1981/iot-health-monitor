sudo bash << 'EOF'
set -e

KAFKA_VERSION="3.8.1"
SCALA_VERSION="2.13"
KAFKA_HOME="/opt/kafka"
KAFKA_PORT=9092

echo "Installing Java..."
yum install -y java-11-amazon-corretto wget net-tools

echo "Downloading Kafka ${KAFKA_VERSION}..."
cd /opt
wget https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
tar -xzf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
mv kafka_${SCALA_VERSION}-${KAFKA_VERSION} kafka
rm kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz

PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

echo "Configuring Kafka..."
cat > $KAFKA_HOME/config/server.properties << PROPS
broker.id=1
listeners=PLAINTEXT://0.0.0.0:${KAFKA_PORT}
advertised.listeners=PLAINTEXT://${PRIVATE_IP}:${KAFKA_PORT}
num.partitions=1
log.dirs=/tmp/kafka-logs
zookeeper.connect=localhost:2181
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
PROPS

mkdir -p /var/log/kafka

echo "Starting Zookeeper..."
nohup $KAFKA_HOME/bin/zookeeper-server-start.sh \
  $KAFKA_HOME/config/zookeeper.properties > /var/log/zookeeper.log 2>&1 &

echo "Waiting for Zookeeper..."
for i in {1..30}; do
  if netstat -tuln 2>/dev/null | grep -q 2181; then
    echo "Zookeeper is ready!"
    break
  fi
  sleep 2
done

echo "Starting Kafka..."
nohup $KAFKA_HOME/bin/kafka-server-start.sh \
  $KAFKA_HOME/config/server.properties > /var/log/kafka.log 2>&1 &

echo "export PATH=\$PATH:$KAFKA_HOME/bin" >> /etc/profile

echo "Installation complete! Waiting for Kafka to start..."
sleep 15
echo "Done!"
EOF