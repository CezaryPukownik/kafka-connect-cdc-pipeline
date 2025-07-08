-- This DDL is generated based on the provided JSON schema.
-- The table name is derived from the 'name' field in the schema.
-- JSON types are mapped to corresponding ClickHouse data types.
-- Optional fields are created as Nullable columns.
-- A MergeTree engine is used for demonstration purposes, which is suitable for a wide range of use cases.
-- You might want to adjust the ORDER BY clause based on your query patterns.
CREATE DATABASE shop;

CREATE TABLE shop.cdc__shop__customer_addresses
(
    -- Columns from the 'before' object
    `before_id` Nullable(Int32),
    `before_first_name` Nullable(String),
    `before_last_name` Nullable(String),
    `before_email` Nullable(String),
    `before_res_address` Nullable(String),
    `before_work_address` Nullable(String),
    `before_country` Nullable(String),
    `before_state` Nullable(String),
    `before_phone_1` Nullable(String),
    `before_phone_2` Nullable(String),

    -- Columns from the 'after' object
    `after_id` Nullable(Int32),
    `after_first_name` Nullable(String),
    `after_last_name` Nullable(String),
    `after_email` Nullable(String),
    `after_res_address` Nullable(String),
    `after_work_address` Nullable(String),
    `after_country` Nullable(String),
    `after_state` Nullable(String),
    `after_phone_1` Nullable(String),
    `after_phone_2` Nullable(String),

    -- Columns from the 'source' object
    `source_version` String,
    `source_connector` String,
    `source_name` String,
    `source_ts_ms` Int64,
    `source_snapshot` Nullable(String),
    `source_db` String,
    `source_sequence` Nullable(String),
    `source_ts_us` Nullable(Int64),
    `source_ts_ns` Nullable(Int64),
    `source_schema` String,
    `source_table` String,
    `source_txId` Nullable(Int64),
    `source_lsn` Nullable(Int64),
    `source_xmin` Nullable(Int64),

    -- Columns from the 'transaction' object
    `transaction_id` Nullable(String),
    `transaction_total_order` Nullable(Int64),
    `transaction_data_collection_order` Nullable(Int64),

    -- Root level columns
    `op` String,
    `ts_ms` Nullable(Int64),
    `ts_us` Nullable(Int64),
    `ts_ns` Nullable(Int64)
)
ENGINE = MergeTree()
ORDER BY (source_ts_ms);
