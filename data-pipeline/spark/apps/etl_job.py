#!/usr/bin/env python3
"""
Spark ETL Job for MySQL Schema Data Warehouse
Processes data from Kafka and loads into data warehouse
"""

import os
import sys
from datetime import datetime, timedelta
from typing import Dict, Any

from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.functions import (
    col,
    from_json,
    to_timestamp,
    window,
    sum as spark_sum,
    count,
    avg,
    max as spark_max,
    min as spark_min,
    when,
    coalesce,
    struct,
    to_json,
    collect_list,
    year,
    month,
    dayofmonth,
    hour,
    weekofyear,
    lag,
    lead,
    row_number,
    rank,
    dense_rank,
    stddev,
    variance,
    percentile_approx,
    udf,
    pandas_udf,
    expr,
)
from pyspark.sql.types import (
    StructType,
    StructField,
    StringType,
    IntegerType,
    FloatType,
    TimestampType,
    ArrayType,
    MapType,
    DecimalType,
    BooleanType,
)
from pyspark.sql.window import Window
import pyspark.sql.functions as F

# Configuration
KAFKA_BROKERS = os.getenv("KAFKA_BROKERS", "localhost:9092")
CLICKHOUSE_HOST = os.getenv("CLICKHOUSE_HOST", "localhost")
CLICKHOUSE_PORT = os.getenv("CLICKHOUSE_PORT", "8123")
S3_BUCKET = os.getenv("S3_BUCKET", "mysql-schema-data")
CHECKPOINT_LOCATION = os.getenv("CHECKPOINT_LOCATION", "/tmp/spark-checkpoints")


# Initialize Spark Session
def create_spark_session(app_name: str) -> SparkSession:
    """Create Spark session with optimized configuration"""
    return (
        SparkSession.builder.appName(app_name)
        .config("spark.sql.adaptive.enabled", "true")
        .config("spark.sql.adaptive.coalescePartitions.enabled", "true")
        .config("spark.sql.adaptive.skewJoin.enabled", "true")
        .config("spark.sql.streaming.checkpointLocation", CHECKPOINT_LOCATION)
        .config("spark.sql.shuffle.partitions", "200")
        .config("spark.sql.execution.arrow.pyspark.enabled", "true")
        .config(
            "spark.jars.packages",
            "org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0,"
            "ru.yandex.clickhouse:clickhouse-jdbc:0.3.2,"
            "org.apache.hadoop:hadoop-aws:3.3.4",
        )
        .getOrCreate()
    )


# ==================== Schemas ====================


def get_cdc_schema() -> StructType:
    """Schema for CDC events from Debezium"""
    return StructType(
        [
            StructField("database", StringType(), True),
            StructField("table", StringType(), True),
            StructField("operation", StringType(), True),
            StructField("timestamp", TimestampType(), True),
            StructField("before", MapType(StringType(), StringType()), True),
            StructField("after", MapType(StringType(), StringType()), True),
            StructField("transaction_id", StringType(), True),
        ]
    )


def get_patient_schema() -> StructType:
    """Schema for patient data"""
    return StructType(
        [
            StructField("patient_id", IntegerType(), False),
            StructField("name", StringType(), True),
            StructField("date_of_birth", TimestampType(), True),
            StructField("gender", StringType(), True),
            StructField("phone", StringType(), True),
            StructField("email", StringType(), True),
            StructField("address", StringType(), True),
            StructField("insurance_provider", StringType(), True),
            StructField("created_at", TimestampType(), True),
            StructField("updated_at", TimestampType(), True),
        ]
    )


def get_order_schema() -> StructType:
    """Schema for e-commerce orders"""
    return StructType(
        [
            StructField("order_id", IntegerType(), False),
            StructField("customer_id", IntegerType(), True),
            StructField("order_date", TimestampType(), True),
            StructField("status", StringType(), True),
            StructField("total_amount", DecimalType(10, 2), True),
            StructField("shipping_address", StringType(), True),
            StructField("payment_method", StringType(), True),
            StructField(
                "items",
                ArrayType(
                    StructType(
                        [
                            StructField("product_id", IntegerType(), True),
                            StructField("quantity", IntegerType(), True),
                            StructField("price", DecimalType(10, 2), True),
                        ]
                    )
                ),
                True,
            ),
        ]
    )


def get_iot_schema() -> StructType:
    """Schema for IoT readings"""
    return StructType(
        [
            StructField("device_id", StringType(), False),
            StructField("sensor_type", StringType(), True),
            StructField("value", FloatType(), True),
            StructField("unit", StringType(), True),
            StructField("timestamp", TimestampType(), True),
            StructField("location_lat", FloatType(), True),
            StructField("location_lon", FloatType(), True),
            StructField("metadata", MapType(StringType(), StringType()), True),
        ]
    )


# ==================== ETL Functions ====================


def read_kafka_stream(spark: SparkSession, topic: str, schema: StructType) -> DataFrame:
    """Read streaming data from Kafka"""
    return (
        spark.readStream.format("kafka")
        .option("kafka.bootstrap.servers", KAFKA_BROKERS)
        .option("subscribe", topic)
        .option("startingOffsets", "latest")
        .option("failOnDataLoss", "false")
        .load()
        .select(
            col("key").cast("string").alias("key"),
            from_json(col("value").cast("string"), schema).alias("data"),
            col("timestamp").alias("kafka_timestamp"),
        )
        .select("key", "data.*", "kafka_timestamp")
    )


def process_patient_data(df: DataFrame) -> DataFrame:
    """Process and enrich patient data"""
    # Calculate age
    df = df.withColumn(
        "age", F.floor(F.datediff(F.current_date(), col("date_of_birth")) / 365.25)
    )

    # Add age groups
    df = df.withColumn(
        "age_group",
        when(col("age") < 18, "Child")
        .when(col("age") < 30, "Young Adult")
        .when(col("age") < 50, "Adult")
        .when(col("age") < 65, "Middle Age")
        .otherwise("Senior"),
    )

    # Add registration metrics
    df = (
        df.withColumn("registration_year", year("created_at"))
        .withColumn("registration_month", month("created_at"))
        .withColumn("registration_week", weekofyear("created_at"))
    )

    return df


def process_order_data(df: DataFrame) -> DataFrame:
    """Process and enrich e-commerce order data"""
    # Calculate order metrics
    df = df.withColumn("items_count", F.size(col("items")))

    # Extract item details
    df = df.withColumn(
        "total_items_quantity",
        F.expr("aggregate(items, 0, (acc, x) -> acc + x.quantity)"),
    )

    # Add time-based features
    df = (
        df.withColumn("order_year", year("order_date"))
        .withColumn("order_month", month("order_date"))
        .withColumn("order_day", dayofmonth("order_date"))
        .withColumn("order_hour", hour("order_date"))
        .withColumn("order_weekday", F.dayofweek("order_date"))
    )

    # Add order value categories
    df = df.withColumn(
        "order_value_category",
        when(col("total_amount") < 50, "Low")
        .when(col("total_amount") < 200, "Medium")
        .when(col("total_amount") < 500, "High")
        .otherwise("Premium"),
    )

    return df


def process_iot_data(df: DataFrame) -> DataFrame:
    """Process and enrich IoT sensor data"""
    # Add statistical features using window functions
    window_spec = (
        Window.partitionBy("device_id", "sensor_type")
        .orderBy("timestamp")
        .rowsBetween(-10, 0)
    )

    df = (
        df.withColumn("moving_avg", avg("value").over(window_spec))
        .withColumn("moving_std", stddev("value").over(window_spec))
        .withColumn("moving_min", spark_min("value").over(window_spec))
        .withColumn("moving_max", spark_max("value").over(window_spec))
    )

    # Detect anomalies
    df = df.withColumn(
        "is_anomaly",
        when(
            (col("value") > col("moving_avg") + 2 * col("moving_std"))
            | (col("value") < col("moving_avg") - 2 * col("moving_std")),
            True,
        ).otherwise(False),
    )

    # Add time features
    df = df.withColumn("reading_hour", hour("timestamp")).withColumn(
        "reading_date", F.to_date("timestamp")
    )

    return df


def aggregate_patient_metrics(df: DataFrame) -> DataFrame:
    """Aggregate patient metrics for analytics"""
    return (
        df.groupBy(
            window(col("created_at"), "1 hour"),
            "gender",
            "age_group",
            "insurance_provider",
        )
        .agg(
            count("*").alias("patient_count"),
            avg("age").alias("avg_age"),
            spark_min("age").alias("min_age"),
            spark_max("age").alias("max_age"),
        )
        .select(
            col("window.start").alias("window_start"),
            col("window.end").alias("window_end"),
            "*",
        )
        .drop("window")
    )


def aggregate_order_metrics(df: DataFrame) -> DataFrame:
    """Aggregate order metrics for analytics"""
    return (
        df.groupBy(
            window(col("order_date"), "1 hour"),
            "status",
            "payment_method",
            "order_value_category",
        )
        .agg(
            count("*").alias("order_count"),
            spark_sum("total_amount").alias("total_revenue"),
            avg("total_amount").alias("avg_order_value"),
            spark_sum("items_count").alias("total_items_sold"),
            avg("items_count").alias("avg_items_per_order"),
        )
        .select(
            col("window.start").alias("window_start"),
            col("window.end").alias("window_end"),
            "*",
        )
        .drop("window")
    )


def aggregate_iot_metrics(df: DataFrame) -> DataFrame:
    """Aggregate IoT metrics for analytics"""
    return (
        df.groupBy(window(col("timestamp"), "5 minutes"), "device_id", "sensor_type")
        .agg(
            count("*").alias("reading_count"),
            avg("value").alias("avg_value"),
            spark_min("value").alias("min_value"),
            spark_max("value").alias("max_value"),
            stddev("value").alias("std_value"),
            spark_sum(when(col("is_anomaly"), 1).otherwise(0)).alias("anomaly_count"),
        )
        .select(
            col("window.start").alias("window_start"),
            col("window.end").alias("window_end"),
            "*",
        )
        .drop("window")
    )


# ==================== Data Quality Checks ====================


def check_data_quality(df: DataFrame, table_name: str) -> DataFrame:
    """Perform data quality checks"""
    quality_metrics = {}

    # Check for nulls
    null_counts = (
        df.select([spark_sum(col(c).isNull().cast("int")).alias(c) for c in df.columns])
        .collect()[0]
        .asDict()
    )

    quality_metrics["null_counts"] = null_counts

    # Check for duplicates
    duplicate_count = df.count() - df.dropDuplicates().count()
    quality_metrics["duplicate_count"] = duplicate_count

    # Log quality metrics
    print(f"Data quality metrics for {table_name}:")
    print(f"  Null counts: {null_counts}")
    print(f"  Duplicate count: {duplicate_count}")

    return df


# ==================== Write Functions ====================


def write_to_clickhouse(df: DataFrame, table: str, mode: str = "append"):
    """Write DataFrame to ClickHouse"""
    df.write.mode(mode).format("jdbc").option(
        "url", f"jdbc:clickhouse://{CLICKHOUSE_HOST}:{CLICKHOUSE_PORT}/analytics"
    ).option("dbtable", table).option("user", "default").option(
        "driver", "ru.yandex.clickhouse.ClickHouseDriver"
    ).option(
        "batchsize", 10000
    ).option(
        "isolationLevel", "NONE"
    ).save()


def write_to_s3_parquet(df: DataFrame, path: str, mode: str = "append"):
    """Write DataFrame to S3 in Parquet format"""
    df.write.mode(mode).partitionBy("year", "month", "day").parquet(
        f"s3a://{S3_BUCKET}/{path}"
    )


def write_stream_to_console(df: DataFrame, output_mode: str = "append"):
    """Write streaming DataFrame to console for debugging"""
    return (
        df.writeStream.outputMode(output_mode)
        .format("console")
        .trigger(processingTime="10 seconds")
        .start()
    )


def write_stream_to_kafka(df: DataFrame, topic: str, checkpoint: str):
    """Write streaming DataFrame back to Kafka"""
    return (
        df.selectExpr("to_json(struct(*)) AS value")
        .writeStream.format("kafka")
        .option("kafka.bootstrap.servers", KAFKA_BROKERS)
        .option("topic", topic)
        .option("checkpointLocation", f"{CHECKPOINT_LOCATION}/{checkpoint}")
        .trigger(processingTime="10 seconds")
        .start()
    )


# ==================== Main ETL Pipeline ====================


def run_batch_etl():
    """Run batch ETL pipeline"""
    spark = create_spark_session("MySQL Schema Batch ETL")

    try:
        # Read historical data from Kafka (batch mode)
        patient_df = (
            spark.read.format("kafka")
            .option("kafka.bootstrap.servers", KAFKA_BROKERS)
            .option("subscribe", "clinic_db.patients")
            .option("startingOffsets", "earliest")
            .load()
            .select(
                from_json(col("value").cast("string"), get_patient_schema()).alias(
                    "data"
                )
            )
            .select("data.*")
        )

        order_df = (
            spark.read.format("kafka")
            .option("kafka.bootstrap.servers", KAFKA_BROKERS)
            .option("subscribe", "ecommerce_db.orders")
            .option("startingOffsets", "earliest")
            .load()
            .select(
                from_json(col("value").cast("string"), get_order_schema()).alias("data")
            )
            .select("data.*")
        )

        iot_df = (
            spark.read.format("kafka")
            .option("kafka.bootstrap.servers", KAFKA_BROKERS)
            .option("subscribe", "iot_db.readings")
            .option("startingOffsets", "earliest")
            .load()
            .select(
                from_json(col("value").cast("string"), get_iot_schema()).alias("data")
            )
            .select("data.*")
        )

        # Process data
        patient_df = process_patient_data(patient_df)
        order_df = process_order_data(order_df)
        iot_df = process_iot_data(iot_df)

        # Data quality checks
        patient_df = check_data_quality(patient_df, "patients")
        order_df = check_data_quality(order_df, "orders")
        iot_df = check_data_quality(iot_df, "iot_readings")

        # Aggregate metrics
        patient_metrics = aggregate_patient_metrics(patient_df)
        order_metrics = aggregate_order_metrics(order_df)
        iot_metrics = aggregate_iot_metrics(iot_df)

        # Write to data warehouse
        write_to_clickhouse(patient_df, "patients_fact")
        write_to_clickhouse(order_df, "orders_fact")
        write_to_clickhouse(iot_df, "iot_readings_fact")

        write_to_clickhouse(patient_metrics, "patient_metrics_hourly")
        write_to_clickhouse(order_metrics, "order_metrics_hourly")
        write_to_clickhouse(iot_metrics, "iot_metrics_5min")

        # Write to S3 for long-term storage
        write_to_s3_parquet(patient_df, "warehouse/patients")
        write_to_s3_parquet(order_df, "warehouse/orders")
        write_to_s3_parquet(iot_df, "warehouse/iot_readings")

        print("Batch ETL completed successfully")

    except Exception as e:
        print(f"Error in batch ETL: {e}")
        raise
    finally:
        spark.stop()


def run_streaming_etl():
    """Run streaming ETL pipeline"""
    spark = create_spark_session("MySQL Schema Streaming ETL")

    try:
        # Read streaming data
        patient_stream = read_kafka_stream(
            spark, "clinic_db.patients", get_patient_schema()
        )
        order_stream = read_kafka_stream(
            spark, "ecommerce_db.orders", get_order_schema()
        )
        iot_stream = read_kafka_stream(spark, "iot_db.readings", get_iot_schema())

        # Process streaming data
        patient_stream = process_patient_data(patient_stream)
        order_stream = process_order_data(order_stream)
        iot_stream = process_iot_data(iot_stream)

        # Write processed streams back to Kafka
        patient_query = write_stream_to_kafka(
            patient_stream, "processed.patients", "patients_checkpoint"
        )

        order_query = write_stream_to_kafka(
            order_stream, "processed.orders", "orders_checkpoint"
        )

        iot_query = write_stream_to_kafka(iot_stream, "processed.iot", "iot_checkpoint")

        # Wait for termination
        spark.streams.awaitAnyTermination()

    except Exception as e:
        print(f"Error in streaming ETL: {e}")
        raise
    finally:
        spark.stop()


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "streaming":
        print("Starting streaming ETL pipeline...")
        run_streaming_etl()
    else:
        print("Starting batch ETL pipeline...")
        run_batch_etl()
