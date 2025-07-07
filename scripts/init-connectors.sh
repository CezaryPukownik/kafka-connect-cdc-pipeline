#!/bin/sh

# Wait for the Kafka Connect REST API to be available
echo "Waiting for Kafka Connect to start..."
until $(curl --output /dev/null --silent --head --fail http://connect:8083/); do
  printf '.'
  sleep 5
done
echo -e "\nKafka Connect is up and running!"

# Delete the connectors if exists already
curl -X DELETE http://connect:8083/connectors/shop-connector

# Create a postgres debezium connector
echo "Creating io.debezium.connector.postgresql.PostgresConnector..."
curl -X POST -H "Content-Type: application/json" \
  --data @/scripts/shop-connector.json \
  http://connect:8083/connectors

echo "Connectors configured successfully."
