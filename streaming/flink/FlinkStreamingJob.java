package com.mysql.streaming.flink;

import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.functions.AggregateFunction;
import org.apache.flink.api.common.functions.MapFunction;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.api.common.state.*;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.api.java.tuple.Tuple3;
import org.apache.flink.cep.CEP;
import org.apache.flink.cep.PatternStream;
import org.apache.flink.cep.pattern.Pattern;
import org.apache.flink.cep.pattern.conditions.SimpleCondition;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.connector.jdbc.JdbcConnectionOptions;
import org.apache.flink.connector.jdbc.JdbcExecutionOptions;
import org.apache.flink.connector.jdbc.JdbcSink;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.formats.json.JsonDeserializationSchema;
import org.apache.flink.ml.feature.standardscaler.StandardScaler;
import org.apache.flink.ml.linalg.DenseVector;
import org.apache.flink.ml.linalg.Vectors;
import org.apache.flink.runtime.state.FunctionInitializationContext;
import org.apache.flink.runtime.state.FunctionSnapshotContext;
import org.apache.flink.streaming.api.CheckpointingMode;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.datastream.KeyedStream;
import org.apache.flink.streaming.api.datastream.SingleOutputStreamOperator;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.KeyedProcessFunction;
import org.apache.flink.streaming.api.functions.ProcessFunction;
import org.apache.flink.streaming.api.functions.co.CoProcessFunction;
import org.apache.flink.streaming.api.functions.sink.filesystem.StreamingFileSink;
import org.apache.flink.streaming.api.functions.windowing.ProcessWindowFunction;
import org.apache.flink.streaming.api.windowing.assigners.TumblingEventTimeWindows;
import org.apache.flink.streaming.api.windowing.time.Time;
import org.apache.flink.streaming.api.windowing.windows.TimeWindow;
import org.apache.flink.table.api.Table;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;
import org.apache.flink.util.Collector;
import org.apache.flink.util.OutputTag;

import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.TimeUnit;

/**
 * Advanced Apache Flink streaming job for real-time MySQL CDC processing
 * Implements complex event processing, ML-based anomaly detection, and CQRS patterns
 */
public class FlinkStreamingJob {

    private static final String KAFKA_BOOTSTRAP_SERVERS = "localhost:9092";
    private static final String CHECKPOINT_PATH = "file:///tmp/flink-checkpoints";

    // Output tags for side outputs
    private static final OutputTag<AnomalyEvent> ANOMALY_TAG =
        new OutputTag<AnomalyEvent>("anomalies"){};
    private static final OutputTag<AlertEvent> ALERT_TAG =
        new OutputTag<AlertEvent>("alerts"){};

    public static void main(String[] args) throws Exception {
        // Set up the streaming execution environment
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        StreamTableEnvironment tableEnv = StreamTableEnvironment.create(env);

        // Configure checkpointing for exactly-once processing
        env.enableCheckpointing(10000, CheckpointingMode.EXACTLY_ONCE);
        env.getCheckpointConfig().setCheckpointTimeout(60000);
        env.getCheckpointConfig().setMinPauseBetweenCheckpoints(5000);
        env.getCheckpointConfig().setMaxConcurrentCheckpoints(1);
        env.getCheckpointConfig().setCheckpointStorage(CHECKPOINT_PATH);

        // Configure state backend
        env.setStateBackend(new org.apache.flink.runtime.state.hashmap.HashMapStateBackend());

        // Create Kafka source for CDC events
        KafkaSource<CDCEvent> cdcSource = KafkaSource.<CDCEvent>builder()
            .setBootstrapServers(KAFKA_BOOTSTRAP_SERVERS)
            .setTopics("cdc.clinic.patients", "cdc.clinic.appointments",
                      "cdc.iot.sensor_readings", "cdc.ecommerce.orders")
            .setGroupId("flink-streaming-group")
            .setStartingOffsets(OffsetsInitializer.earliest())
            .setValueOnlyDeserializer(new JsonDeserializationSchema<>(CDCEvent.class))
            .build();

        // Main CDC event stream
        DataStream<CDCEvent> cdcStream = env.fromSource(
            cdcSource,
            WatermarkStrategy.<CDCEvent>forBoundedOutOfOrderness(Duration.ofSeconds(20))
                .withTimestampAssigner((event, timestamp) -> event.getTimestamp()),
            "CDC Source"
        ).name("CDC Events");

        // =====================================================
        // 1. Complex Event Processing for Pattern Detection
        // =====================================================

        DataStream<PatternMatchResult> patternResults = detectComplexPatterns(cdcStream);

        // =====================================================
        // 2. Real-time Aggregations and Analytics
        // =====================================================

        // Appointment statistics per doctor
        DataStream<DoctorStatistics> doctorStats = cdcStream
            .filter(event -> "appointments".equals(event.getTable()))
            .keyBy(event -> event.getAfter().get("doctor_id").toString())
            .window(TumblingEventTimeWindows.of(Time.hours(1)))
            .aggregate(new AppointmentAggregator(), new DoctorStatisticsProcessor());

        // IoT sensor anomaly detection using ML
        SingleOutputStreamOperator<SensorReading> sensorReadings = cdcStream
            .filter(event -> "sensor_readings".equals(event.getTable()))
            .map(new SensorReadingMapper())
            .process(new AnomalyDetectionProcessor())
            .name("Anomaly Detection");

        // Extract side outputs
        DataStream<AnomalyEvent> anomalies = sensorReadings.getSideOutput(ANOMALY_TAG);
        DataStream<AlertEvent> alerts = sensorReadings.getSideOutput(ALERT_TAG);

        // =====================================================
        // 3. Event Sourcing and CQRS Implementation
        // =====================================================

        // Write events to event store
        cdcStream.addSink(new EventStoreSink())
            .name("Event Store Sink");

        // Build materialized views for queries
        DataStream<MaterializedView> materializedViews = buildMaterializedViews(cdcStream);

        // =====================================================
        // 4. Stream-Table Join for Enrichment
        // =====================================================

        // Register streams as tables
        tableEnv.createTemporaryView("appointments", cdcStream
            .filter(e -> "appointments".equals(e.getTable()))
            .map(e -> e.getAfter()));

        tableEnv.createTemporaryView("patients", cdcStream
            .filter(e -> "patients".equals(e.getTable()))
            .map(e -> e.getAfter()));

        // SQL query for enriched appointments
        Table enrichedAppointments = tableEnv.sqlQuery(
            "SELECT " +
            "  a.appointment_id, " +
            "  a.appointment_date, " +
            "  p.patient_name, " +
            "  p.insurance_provider, " +
            "  a.doctor_id, " +
            "  a.status " +
            "FROM appointments a " +
            "JOIN patients p ON a.patient_id = p.patient_id"
        );

        // Convert back to DataStream
        DataStream<EnrichedAppointment> enrichedStream = tableEnv
            .toDataStream(enrichedAppointments, EnrichedAppointment.class);

        // =====================================================
        // 5. Multi-Stream Processing with Co-Process Function
        // =====================================================

        DataStream<OrderEvent> orders = cdcStream
            .filter(e -> "orders".equals(e.getTable()))
            .map(new OrderEventMapper());

        DataStream<PaymentEvent> payments = cdcStream
            .filter(e -> "payments".equals(e.getTable()))
            .map(new PaymentEventMapper());

        // Join order and payment streams
        DataStream<OrderPaymentJoin> orderPaymentJoins = orders
            .keyBy(OrderEvent::getOrderId)
            .connect(payments.keyBy(PaymentEvent::getOrderId))
            .process(new OrderPaymentCoProcessor())
            .name("Order-Payment Join");

        // =====================================================
        // 6. Advanced Window Operations
        // =====================================================

        // Session windows for user activity
        DataStream<UserSession> userSessions = cdcStream
            .filter(e -> "user_activities".equals(e.getTable()))
            .map(new UserActivityMapper())
            .keyBy(UserActivity::getUserId)
            .window(EventTimeSessionWindows.withGap(Time.minutes(30)))
            .process(new UserSessionProcessor());

        // =====================================================
        // 7. State Management and Custom Operators
        // =====================================================

        DataStream<StateUpdateResult> stateUpdates = cdcStream
            .keyBy(CDCEvent::getKey)
            .process(new StatefulCDCProcessor())
            .name("Stateful Processing");

        // =====================================================
        // 8. Output Sinks
        // =====================================================

        // Sink to MySQL for materialized views
        materializedViews.addSink(
            JdbcSink.sink(
                "INSERT INTO materialized_views (view_id, view_data, updated_at) " +
                "VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE view_data = ?, updated_at = ?",
                (ps, view) -> {
                    ps.setString(1, view.getId());
                    ps.setString(2, view.getData());
                    ps.setTimestamp(3, view.getUpdatedAt());
                    ps.setString(4, view.getData());
                    ps.setTimestamp(5, view.getUpdatedAt());
                },
                JdbcExecutionOptions.builder()
                    .withBatchSize(100)
                    .withBatchIntervalMs(200)
                    .withMaxRetries(3)
                    .build(),
                new JdbcConnectionOptions.JdbcConnectionOptionsBuilder()
                    .withUrl("jdbc:mysql://localhost:3306/analytics")
                    .withDriverName("com.mysql.cj.jdbc.Driver")
                    .withUsername("flink_user")
                    .withPassword("flink_pass")
                    .build()
            )
        ).name("MySQL Sink");

        // Sink to Elasticsearch for search
        anomalies.addSink(new ElasticsearchSink<>())
            .name("Elasticsearch Sink");

        // Sink to Kafka for downstream processing
        alerts.map(AlertEvent::toJson)
            .sinkTo(KafkaSink.<String>builder()
                .setBootstrapServers(KAFKA_BOOTSTRAP_SERVERS)
                .setRecordSerializer(KafkaRecordSerializationSchema.builder()
                    .setTopic("alerts")
                    .setValueSerializationSchema(new SimpleStringSchema())
                    .build())
                .setDeliveryGuarantee(DeliveryGuarantee.EXACTLY_ONCE)
                .build())
            .name("Kafka Alert Sink");

        // Sink to S3 for archival
        DataStream<String> archiveStream = cdcStream
            .map(CDCEvent::toJson);

        StreamingFileSink<String> s3Sink = StreamingFileSink
            .forRowFormat(new Path("s3://mysql-cdc-archive/"), new SimpleStringEncoder<String>("UTF-8"))
            .withRollingPolicy(
                DefaultRollingPolicy.builder()
                    .withRolloverInterval(TimeUnit.MINUTES.toMillis(15))
                    .withInactivityInterval(TimeUnit.MINUTES.toMillis(5))
                    .withMaxPartSize(1024 * 1024 * 128) // 128 MB
                    .build())
            .build();

        archiveStream.addSink(s3Sink).name("S3 Archive Sink");

        // =====================================================
        // Execute the job
        // =====================================================

        env.execute("Advanced MySQL CDC Streaming Analytics");
    }

    /**
     * Complex Event Processing for Pattern Detection
     */
    private static DataStream<PatternMatchResult> detectComplexPatterns(DataStream<CDCEvent> stream) {
        // Define pattern: Multiple failed login attempts followed by successful login
        Pattern<CDCEvent, ?> suspiciousLoginPattern = Pattern.<CDCEvent>begin("failed")
            .where(new SimpleCondition<CDCEvent>() {
                @Override
                public boolean filter(CDCEvent event) {
                    return "login_attempts".equals(event.getTable()) &&
                           "failed".equals(event.getAfter().get("status"));
                }
            })
            .times(3, 5)
            .within(Time.minutes(5))
            .followedBy("success")
            .where(new SimpleCondition<CDCEvent>() {
                @Override
                public boolean filter(CDCEvent event) {
                    return "login_attempts".equals(event.getTable()) &&
                           "success".equals(event.getAfter().get("status"));
                }
            });

        PatternStream<CDCEvent> patternStream = CEP.pattern(
            stream.keyBy(e -> e.getAfter().get("user_id").toString()),
            suspiciousLoginPattern
        );

        return patternStream.process(new PatternMatchProcessor());
    }

    /**
     * Build materialized views for CQRS read model
     */
    private static DataStream<MaterializedView> buildMaterializedViews(DataStream<CDCEvent> stream) {
        return stream
            .keyBy(CDCEvent::getAggregateId)
            .process(new MaterializedViewBuilder())
            .name("Materialized View Builder");
    }

    /**
     * Stateful CDC Processor with ValueState, ListState, and MapState
     */
    public static class StatefulCDCProcessor
        extends KeyedProcessFunction<String, CDCEvent, StateUpdateResult> {

        private ValueState<Long> lastProcessedTimestamp;
        private ListState<CDCEvent> eventBuffer;
        private MapState<String, Integer> eventCounts;

        @Override
        public void open(Configuration parameters) {
            ValueStateDescriptor<Long> timestampDescriptor =
                new ValueStateDescriptor<>("lastTimestamp", Long.class);
            lastProcessedTimestamp = getRuntimeContext().getState(timestampDescriptor);

            ListStateDescriptor<CDCEvent> bufferDescriptor =
                new ListStateDescriptor<>("eventBuffer", CDCEvent.class);
            eventBuffer = getRuntimeContext().getListState(bufferDescriptor);

            MapStateDescriptor<String, Integer> countDescriptor =
                new MapStateDescriptor<>("eventCounts", String.class, Integer.class);
            eventCounts = getRuntimeContext().getMapState(countDescriptor);
        }

        @Override
        public void processElement(CDCEvent event, Context ctx, Collector<StateUpdateResult> out)
            throws Exception {

            // Update state
            long currentTimestamp = event.getTimestamp();
            Long lastTimestamp = lastProcessedTimestamp.value();

            if (lastTimestamp == null || currentTimestamp > lastTimestamp) {
                lastProcessedTimestamp.update(currentTimestamp);

                // Buffer events
                eventBuffer.add(event);

                // Update counts
                String operation = event.getOperation();
                Integer count = eventCounts.get(operation);
                eventCounts.put(operation, count == null ? 1 : count + 1);

                // Process buffered events when threshold reached
                int bufferSize = 0;
                for (CDCEvent e : eventBuffer.get()) {
                    bufferSize++;
                }

                if (bufferSize >= 100) {
                    StateUpdateResult result = processBufferedEvents();
                    out.collect(result);
                    eventBuffer.clear();
                }

                // Set timer for time-based processing
                ctx.timerService().registerEventTimeTimer(currentTimestamp + 60000);
            }
        }

        @Override
        public void onTimer(long timestamp, OnTimerContext ctx, Collector<StateUpdateResult> out)
            throws Exception {
            // Process any remaining buffered events
            StateUpdateResult result = processBufferedEvents();
            if (result != null) {
                out.collect(result);
                eventBuffer.clear();
            }
        }

        private StateUpdateResult processBufferedEvents() throws Exception {
            List<CDCEvent> events = new ArrayList<>();
            for (CDCEvent e : eventBuffer.get()) {
                events.add(e);
            }

            if (events.isEmpty()) {
                return null;
            }

            // Aggregate and process events
            Map<String, Integer> summary = new HashMap<>();
            for (Map.Entry<String, Integer> entry : eventCounts.entries()) {
                summary.put(entry.getKey(), entry.getValue());
            }

            return new StateUpdateResult(events, summary, System.currentTimeMillis());
        }
    }

    /**
     * Anomaly Detection using Online Machine Learning
     */
    public static class AnomalyDetectionProcessor
        extends ProcessFunction<SensorReading, SensorReading> {

        private transient StandardScaler scaler;
        private transient IsolationForest isolationForest;

        @Override
        public void open(Configuration parameters) {
            // Initialize ML models
            scaler = new StandardScaler();
            isolationForest = new IsolationForest(100, 256);
        }

        @Override
        public void processElement(SensorReading reading, Context ctx, Collector<SensorReading> out) {
            // Extract features
            DenseVector features = Vectors.dense(
                reading.getFillLevel(),
                reading.getTemperature(),
                reading.getBatteryLevel(),
                reading.getHumidity()
            );

            // Scale features
            DenseVector scaledFeatures = scaler.transform(features);

            // Detect anomalies
            double anomalyScore = isolationForest.predict(scaledFeatures);

            if (anomalyScore > 0.7) {
                // Emit to anomaly side output
                AnomalyEvent anomaly = new AnomalyEvent(
                    reading.getBinId(),
                    reading.getTimestamp(),
                    anomalyScore,
                    "Sensor reading anomaly detected"
                );
                ctx.output(ANOMALY_TAG, anomaly);

                // Generate alert if critical
                if (anomalyScore > 0.9) {
                    AlertEvent alert = new AlertEvent(
                        UUID.randomUUID().toString(),
                        "CRITICAL",
                        "Critical anomaly in bin " + reading.getBinId(),
                        reading.getTimestamp()
                    );
                    ctx.output(ALERT_TAG, alert);
                }
            }

            // Always emit the reading
            out.collect(reading);
        }
    }
}

// Supporting classes

class CDCEvent {
    private String database;
    private String table;
    private String operation;
    private Map<String, Object> before;
    private Map<String, Object> after;
    private String key;
    private long timestamp;

    // Getters, setters, and utility methods
    public String getAggregateId() {
        return database + "." + table + "." + key;
    }

    public String toJson() {
        // Convert to JSON string
        return "{}"; // Simplified
    }
}

class AnomalyEvent {
    private String entityId;
    private long timestamp;
    private double score;
    private String description;

    // Constructor and methods
}

class AlertEvent {
    private String id;
    private String severity;
    private String message;
    private long timestamp;

    public String toJson() {
        return "{}"; // Simplified
    }
}