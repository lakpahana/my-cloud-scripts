#!/bin/bash
# Kafka installation script for Ubuntu

# Exit immediately if a command exits with a non-zero status
set -e

# https://www.apache.org/dyn/closer.cgi?path=/kafka/4.1.0/kafka_2.13-4.1.0.tgz

KAFKA_VERSION="4.1.0"
SCALA_VERSION="2.13"
KAFKA_DIR="/opt/kafka"

echo "=== Updating system ==="
sudo apt update -y
sudo apt upgrade -y

echo "=== Installing dependencies (Java, wget, tar) ==="
sudo apt install -y openjdk-17-jdk wget tar

echo "=== Creating Kafka directory ==="
sudo mkdir -p $KAFKA_DIR
cd /tmp

echo "=== Downloading Kafka $KAFKA_VERSION ==="
wget https://dlcdn.apache.org/kafka/4.1.0/kafka_2.13-4.1.0.tgz

echo "=== Extracting Kafka ==="
tar -xvzf kafka_2.13-4.1.0.tgz
sudo mv kafka_2.13-4.1.0/* $KAFKA_DIR
rm -rf kafka_2.13-4.1.0*

echo "=== Creating systemd services for Zookeeper and Kafka ==="

# Zookeeper service
cat <<EOF | sudo tee /etc/systemd/system/zookeeper.service
[Unit]
Description=Apache Zookeeper server
After=network.target

[Service]
Type=simple
ExecStart=$KAFKA_DIR/bin/zookeeper-server-start.sh $KAFKA_DIR/config/zookeeper.properties
ExecStop=$KAFKA_DIR/bin/zookeeper-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

# Kafka service
cat <<EOF | sudo tee /etc/systemd/system/kafka.service
[Unit]
Description=Apache Kafka server
Requires=zookeeper.service
After=zookeeper.service

[Service]
Type=simple
ExecStart=$KAFKA_DIR/bin/kafka-server-start.sh $KAFKA_DIR/config/server.properties
ExecStop=$KAFKA_DIR/bin/kafka-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

echo "=== Reloading systemd and enabling services ==="
sudo systemctl daemon-reexec
sudo systemctl enable zookeeper
sudo systemctl enable kafka

echo "=== Starting Zookeeper and Kafka ==="
sudo systemctl start zookeeper
sudo systemctl start kafka

echo "=== Installation complete! ==="
echo "Use the following commands to check status:"
echo "  sudo systemctl status zookeeper"
echo "  sudo systemctl status kafka"
