# Kafka Connect Application

### Startup the application
docker compose up

### Add message directly to topic
echo "message directly added to topic" | kcat -b localhost:9092 -t file-stream-topic -P

### Add message to source file
echo "This is a new line added in real-time." >> data/source.txt

### Listen to sink file
tail -f data/sink.txt

### Investigae the topic messages
kcat -b localhost:9092 -t file-stream-topic -P

Source for debezium:
https://www.redpanda.com/blog/change-data-capture-postgres-debezium-kafka-connect
