#!/bin/sh

# This script dynamically configures Kafka Connect connectors
# by reading all .json configuration files from the /scripts/ directory.

# Wait for the Kafka Connect REST API to be available
echo "Waiting for Kafka Connect to start..."
# Loop until a successful HTTP response is received from the connect service
until $(curl --output /dev/null --silent --head --fail http://connect:8083/); do
  printf '.'
  sleep 5
done
echo -e "\nKafka Connect is up and running!"

# --- Main Logic: Iterate over all JSON files in the /scripts/ directory ---
echo "Scanning for connector configuration files in /scripts/..."

for config_file in /scripts/*.json; do
  # Check if the file exists to handle cases where no .json files are found
  [ -e "$config_file" ] || continue

  # Extract the connector name from the filename.
  # For example, from "/scripts/shop-connector.json", this gets "shop-connector".
  connector_name=$(basename "$config_file" .json)

  echo "--- Processing connector: ${connector_name} ---"

  # Delete the connector if it already exists to ensure a clean start.
  echo "Attempting to delete existing connector '${connector_name}'..."
  curl -X DELETE "http://connect:8083/connectors/${connector_name}"
  echo -e "\n" # Add a newline for better log readability

  # Create the connector using its JSON configuration file.
  echo "Creating connector '${connector_name}' using ${config_file}..."
  curl -X POST -H "Content-Type: application/json" \
    --data "@${config_file}" \
    http://connect:8083/connectors
  echo -e "\n" # Add a newline

  echo "Connector '${connector_name}' processed."
done

echo "All connector configurations have been processed successfully."

