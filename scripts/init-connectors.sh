#!/bin/sh

# Wait for the Kafka Connect REST API to be available
echo "Waiting for Kafka Connect to start..."
until $(curl --output /dev/null --silent --head --fail http://connect:8083/); do
  printf '.'
  sleep 5
done
echo -e "\nKafka Connect is up and running!"

# Delete the connectors if exists already
curl -X DELETE http://connect:8083/connectors/debezium-postgres-source-connector
curl -X DELETE http://connect:8083/connectors/json-file-sink-connector

# Create a postgres debezium connector
echo "Creating FileStreamSourceConnector..."
curl -X POST -H "Content-Type: application/json" --data @/scripts/debezium-postgres-source-connector.json http://connect:8083/connectors

# Create a sink connector (to file)
echo "Creating FileStreamSinkConnector..."
curl -X POST -H "Content-Type: application/json" --data @/scripts/sink-connector.json http://connect:8083/connectors

echo "Connectors configured successfully."
