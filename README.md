# **Real-Time CDC Pipeline: PostgreSQL to ClickHouse via Kafka Connect**

This project demonstrates a real-time Change Data Capture (CDC) pipeline that streams data modifications from a PostgreSQL database to a ClickHouse data warehouse. The entire environment is orchestrated using Docker Compose, making it easy to set up and explore.

The core of this pipeline is **Kafka Connect** and **Debezium**. Debezium, running as a source connector within Kafka Connect, monitors the PostgreSQL database's write-ahead log (WAL). It captures row-level changes (INSERTs, UPDATEs, DELETEs) and publishes them as events to a Kafka topic. A ClickHouse sink connector then consumes these events from Kafka and writes them into a ClickHouse table, effectively replicating the data in near real-time.

This setup is a powerful pattern for various use cases, including real-time analytics, data warehousing, auditing, and synchronizing microservices.

## **Table of Contents**

* [Architecture](https://www.google.com/search?q=%23architecture)  
* [Prerequisites](https://www.google.com/search?q=%23prerequisites)  
* [Getting Started](https://www.google.com/search?q=%23getting-started)  
* [How It Works](https://www.google.com/search?q=%23how-it-works)  
* [Testing the Pipeline](https://www.google.com/search?q=%23testing-the-pipeline)  
* [Project Structure](https://www.google.com/search?q=%23project-structure)  
* [Managing Kafka Connect Plugins](https://www.google.com/search?q=%23managing-kafka-connect-plugins)  
* [Configuration Details](https://www.google.com/search?q=%23configuration-details)

## **Architecture**

The entire pipeline runs in a set of Docker containers defined in the `docker-compose.yml` file:

* **`postgres`**: The source relational database. It's configured for logical replication, which is a prerequisite for Debezium to capture changes.  
* **`kafka`**: The messaging broker that acts as the central nervous system of the pipeline. It decouples the data source from the data sink.  
* **`connect`**: A Kafka Connect worker that runs the necessary connectors. It hosts the Debezium connector for PostgreSQL (source) and the ClickHouse Sink connector.  
* **`clickhouse`**: The target columnar data warehouse, optimized for analytical queries.  
* **`init-connectors`**: A utility container that waits for the Kafka Connect service to be ready and then uses a script to post the connector configurations via the Connect REST API.

## **Prerequisites**

* [Docker](https://docs.docker.com/get-docker/)  
* [Docker Compose](https://docs.docker.com/compose/install/)

## **Getting Started**

1. **Clone the repository:**

```
git clone https://github.com/CezaryPukownik/kafka-connect-cdc-pipeline
cd kafka-connect-cdc-pipeline
```

2. **Start the environment:**

```
docker-compose up -d

```

4.   
   This command will build and start all the services in the background. It will automatically:  
   * Initialize the PostgreSQL database (`shop`) with a `customer_addresses` table and some sample data.  
   * Initialize the ClickHouse database (`shop`) with a target table `cdc__shop__customer_addresses`.  
   * Start Kafka and Kafka Connect.  
   * Deploy and configure the Debezium and ClickHouse connectors.  
5. **Check the status:** You can check the logs of the services to ensure everything started correctly:

```
docker-compose logs -f connect

```

7.   
   You should see logs indicating that the connectors have been created successfully.

## **How It Works**

1. **Initial State**: When the `docker-compose up` command is executed, the `postgres` service starts and runs `psql_init.sql`. This script creates a `shop` database and a `customer_addresses` table, populating it with initial data. Simultaneously, the `clickhouse` service runs `clickhouse_init.sql` to create the target database and table.  
2. **Connector Initialization**: The `init-connectors` service waits for the `connect` service's REST API to become available. Once it's up, the `init-connectors.sh` script posts the configurations from `debezium-connector.json` and `clickhouse-connector.json` to the API.  
3. **Debezium in Action (Source)**:  
   * The Debezium connector (`debezium-connector`) connects to the PostgreSQL database.  
   * It performs an initial consistent snapshot of the `customer_addresses` table. All existing rows are read and published as `INSERT` events to the Kafka topic `shop.public.customer_addresses`.  
   * After the snapshot, Debezium starts streaming changes from the PostgreSQL Write-Ahead Log (WAL). Any `INSERT`, `UPDATE`, or `DELETE` operation on the `customer_addresses` table is captured and sent to the same Kafka topic.  
4. **ClickHouse in Action (Sink)**:  
   * The ClickHouse sink connector (`clickhouse-connector`) subscribes to the `shop.public.customer_addresses` topic.  
   * It consumes the change event messages produced by Debezium.  
   * It then writes these messages as new rows into the `cdc__shop__customer_addresses` table in ClickHouse.

## **Testing the Pipeline**

You can see the CDC pipeline in action by making changes to the data in the PostgreSQL database.

1. **Connect to PostgreSQL:**

```
docker-compose exec -u postgres postgres psql -d shop
```

2.   
   **Insert a new record:**

```
INSERT INTO customer_addresses (first_name, last_name, email, country) VALUES ('John', 'Doe', 'john.doe@example.com', 'USA');
```

3.   
   **Update a record:**

```
UPDATE customer_addresses SET country = 'Canada' WHERE email = 'john.doe@example.com';
```

4.   
   **Delete a record:**

```
DELETE FROM customer_addresses WHERE email = 'john.doe@example.com';
```

5.   
   **Query ClickHouse to see the changes:** Connect to the ClickHouse command-line client:

```
docker-compose exec clickhouse clickhouse-client -d shop

```

7.   
   Now, query the target table. You will see a record for each change you made.

```
SELECT op, after_first_name, after_last_name, after_country FROM cdc__shop__customer_addresses WHERE after_email = 'john.doe@example.com';

```

* `op = 'c'` for create (insert)  
* `op = 'u'` for update  
* `op = 'd'` for delete

## **Project Structure**

```
.
├── clickhouse
│   └── clickhouse_init.sql       # DDL for the target ClickHouse table
├── connect
│   ├── connectors
│   │   ├── clickhouse-connector.json # Config for the ClickHouse sink
│   │   ├── debezium-connector.json   # Config for the Debezium source
│   │   └── init-connectors.sh      # Script to deploy connectors
│   └── plugins                     # Kafka Connect plugin JARs
├── docker-compose.yml              # Main Docker Compose file
└── postgres
    ├── postgresql.conf             # PostgreSQL config for replication
    └── psql_init.sql               # DDL and initial data for Postgres

```

## **Managing Kafka Connect Plugins**

Kafka Connect is a modular framework that loads connectors and other components as plugins. This project is configured to make adding new plugins straightforward.

### **How it Works**

In the `docker-compose.yml` file, the `connect` service is configured with two key settings:

* An environment variable `CONNECT_PLUGIN_PATH: /opt/kafka/plugins` tells Kafka Connect where to look for plugins inside the container.  
* A volume mapping `volumes: [./connect/plugins:/opt/kafka/plugins]` mounts the local `connect/plugins` directory from your project into the container at that exact path.

This means any connector you place in the local `./connect/plugins` directory on your machine will be automatically detected by the Kafka Connect worker upon startup. This project already includes the Debezium and ClickHouse connectors in that directory.

### **How to Add a New Connector**

1. **Download the Connector**: Find the connector you want to use (e.g., from Confluent Hub) and download its ZIP or TAR archive.  
2. **Extract the Plugin**: Create a new subdirectory inside the local `./connect/plugins` directory and extract the contents of the archive into it. Each plugin must be in its own folder.  
3. **Restart Kafka Connect**: Restart the service to make it load the new plugin's JAR files.

```
docker-compose restart connect
```

4.   
   Your new connector class will now be available to be configured and deployed via the REST API.

## **Configuration Details**

### **PostgreSQL (`postgresql.conf`)**

The key setting for Debezium is `wal_level = logical`. This configures PostgreSQL to write enough information to the WAL to allow for logical decoding of changes, which is what Debezium uses.

### **Debezium Connector (`debezium-connector.json`)**

* `"connector.class": "io.debezium.connector.postgresql.PostgresConnector"`: Specifies the Java class for the connector.  
* `"database.hostname": "postgres"`: The service name of the PostgreSQL container.  
* `"plugin.name": "pgoutput"`: The logical decoding plugin to use.  
* `"database.server.name": "shop-server"`: A logical name for the source server, which becomes the prefix for Kafka topics.  
* `"topic.prefix": "shop"`: Overrides the default topic prefix. The final topic name becomes `{prefix}.{schema}.{table}`.  
* `"transforms": "flatten"`: This applies a Single Message Transform (SMT) to flatten the complex Debezium event structure, making it easier to consume.

### **ClickHouse Connector (`clickhouse-connector.json`)**

* `"connector.class": "com.clickhouse.kafka.connect.ClickHouseSinkConnector"`: Specifies the sink connector class.  
* `"topics": "shop.public.customer_addresses"`: The Kafka topic to consume from.  
* `"topic2TableMap": "shop.public.customer_addresses=cdc__shop__customer_addresses"`: Maps the Kafka topic to the specific table name in ClickHouse.  
* `"hostname": "clickhouse"`: The service name of the ClickHouse container.  
* `"database": "shop"`: The target database in ClickHouse.

