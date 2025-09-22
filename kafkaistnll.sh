#!/bin/bash
# Kafka installation script for Ubuntu (KRaft mode, no ZooKeeper)

set -e

KAFKA_DIR="/opt/kafka"
KAFKA_CONFIG_DIR="$KAFKA_DIR/config/kraft"
KAFKA_CONFIG_FILE="$KAFKA_CONFIG_DIR/server.properties"
KAFKA_DATA_DIR="/var/lib/kafka/data"
KAFKA_VERSION="4.1.0"
SCALA_VERSION="2.13"

echo "=== Updating system ==="
sudo apt update -y
sudo apt upgrade -y

echo "=== Installing dependencies (Java, wget, tar) ==="
sudo apt install -y openjdk-17-jdk wget tar

echo "=== Creating Kafka directory ==="
sudo mkdir -p $KAFKA_DIR
cd /tmp

echo "=== Downloading Kafka $KAFKA_VERSION ==="
wget https://dlcdn.apache.org/kafka/$KAFKA_VERSION/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz

echo "=== Extracting Kafka ==="
tar -xvzf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
sudo mv kafka_${SCALA_VERSION}-${KAFKA_VERSION}/* $KAFKA_DIR
rm -rf kafka_${SCALA_VERSION}-${KAFKA_VERSION}*

echo "=== Creating KRaft config directory and server.properties ==="
sudo mkdir -p $KAFKA_CONFIG_DIR
sudo mkdir -p $KAFKA_DATA_DIR

sudo tee $KAFKA_CONFIG_FILE > /dev/null <<EOF
# Unique node ID for this broker
node.id=1

# Run both broker and controller
process.roles=broker,controller

# Listeners: broker on 9092, controller on 9093
listeners=PLAINTEXT://:9092,CONTROLLER://:9093
advertised.listeners=PLAINTEXT://localhost:9092

# Controller quorum (single node)
controller.listener.names=CONTROLLER
controller.quorum.voters=1@localhost:9093

# Data directory
log.dirs=$KAFKA_DATA_DIR
EOF

echo "=== Generating cluster ID ==="
CLUSTER_ID=$($KAFKA_DIR/bin/kafka-storage.sh random-uuid)
echo "Cluster ID: $CLUSTER_ID"

echo "=== Formatting Kafka storage ==="
sudo $KAFKA_DIR/bin/kafka-storage.sh format \
  -t $CLUSTER_ID \
  -c $KAFKA_CONFIG_FILE

echo "=== Creating systemd service for Kafka ==="
sudo tee /etc/systemd/system/kafka.service > /dev/null <<EOF
[Unit]
Description=Apache Kafka (KRaft mode)
After=network.target

[Service]
Type=simple
ExecStart=$KAFKA_DIR/bin/kafka-server-start.sh $KAFKA_CONFIG_FILE
ExecStop=$KAFKA_DIR/bin/kafka-server-stop.sh
Restart=on-abnormal
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "=== Reloading systemd and enabling Kafka service ==="
sudo systemctl daemon-reexec
sudo systemctl enable kafka

echo "=== Starting Kafka ==="
sudo systemctl start kafka

echo "=== Installation complete! ==="
echo "Check Kafka status with: sudo systemctl status kafka"
echo "Kafka is listening on port 9092 (PLAINTEXT)"
