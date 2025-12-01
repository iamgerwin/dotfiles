# Apache Kafka Best Practices

## Official Documentation
- **Apache Kafka Documentation**: https://kafka.apache.org/documentation/
- **Kafka Quickstart**: https://kafka.apache.org/quickstart
- **Confluent Platform**: https://docs.confluent.io/
- **Kafka Streams**: https://kafka.apache.org/documentation/streams/

## Architecture Overview
```
Producers
    ↓
Kafka Cluster
    ├── Broker 1
    │   ├── Topic A (Partition 0, 1)
    │   └── Topic B (Partition 0)
    ├── Broker 2
    │   ├── Topic A (Partition 2, 3)
    │   └── Topic B (Partition 1)
    └── Broker 3 (replicas)
    ↓
Consumers (Consumer Groups)
    ├── Consumer Group 1
    │   ├── Consumer 1 → Partition 0, 1
    │   └── Consumer 2 → Partition 2, 3
    └── Consumer Group 2
        └── Consumer 1 → All Partitions
```

### Key Concepts
- **Topic**: Logical channel for publishing messages
- **Partition**: Physical subdivision of a topic for parallelism
- **Offset**: Unique sequential ID for messages within a partition
- **Consumer Group**: Group of consumers sharing message processing
- **Broker**: Kafka server instance
- **Replication Factor**: Number of copies of data across brokers

## Core Best Practices

### 1. Producer Configuration

```python
# Python with confluent-kafka
from confluent_kafka import Producer
import json

producer_config = {
    'bootstrap.servers': 'localhost:9092,localhost:9093,localhost:9094',
    'client.id': 'my-application',

    # Reliability settings
    'acks': 'all',                    # Wait for all replicas
    'retries': 3,                     # Retry on failure
    'retry.backoff.ms': 100,
    'enable.idempotence': True,       # Exactly-once semantics

    # Performance settings
    'batch.size': 16384,              # Batch size in bytes
    'linger.ms': 5,                   # Wait for more messages
    'compression.type': 'snappy',     # Compress messages
    'buffer.memory': 33554432,        # 32MB buffer

    # Timeout settings
    'request.timeout.ms': 30000,
    'delivery.timeout.ms': 120000
}

producer = Producer(producer_config)

def delivery_callback(err, msg):
    if err:
        print(f'Message delivery failed: {err}')
    else:
        print(f'Message delivered to {msg.topic()} [{msg.partition()}] @ {msg.offset()}')

def send_message(topic, key, value):
    producer.produce(
        topic=topic,
        key=key.encode('utf-8') if key else None,
        value=json.dumps(value).encode('utf-8'),
        callback=delivery_callback
    )
    producer.poll(0)  # Trigger callbacks

# Flush on shutdown
producer.flush()
```

```javascript
// Node.js with kafkajs
const { Kafka, Partitioners } = require('kafkajs');

const kafka = new Kafka({
    clientId: 'my-application',
    brokers: ['localhost:9092', 'localhost:9093', 'localhost:9094'],
    connectionTimeout: 3000,
    requestTimeout: 25000,
    retry: {
        initialRetryTime: 100,
        retries: 8
    }
});

const producer = kafka.producer({
    createPartitioner: Partitioners.DefaultPartitioner,
    allowAutoTopicCreation: false,
    idempotent: true,
    maxInFlightRequests: 5,
    transactionTimeout: 60000
});

async function sendMessage(topic, key, value) {
    await producer.connect();

    await producer.send({
        topic,
        messages: [{
            key: key,
            value: JSON.stringify(value),
            headers: {
                'correlation-id': uuid(),
                'timestamp': Date.now().toString()
            }
        }],
        acks: -1,  // Wait for all replicas
        timeout: 30000,
        compression: CompressionTypes.Snappy
    });
}

// Batch sending for better performance
async function sendBatch(topic, messages) {
    await producer.sendBatch({
        topicMessages: [{
            topic,
            messages: messages.map(m => ({
                key: m.key,
                value: JSON.stringify(m.value)
            }))
        }]
    });
}
```

```java
// Java with kafka-clients
import org.apache.kafka.clients.producer.*;
import java.util.Properties;

Properties props = new Properties();
props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
props.put(ProducerConfig.CLIENT_ID_CONFIG, "my-application");
props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());

// Reliability
props.put(ProducerConfig.ACKS_CONFIG, "all");
props.put(ProducerConfig.RETRIES_CONFIG, 3);
props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);

// Performance
props.put(ProducerConfig.BATCH_SIZE_CONFIG, 16384);
props.put(ProducerConfig.LINGER_MS_CONFIG, 5);
props.put(ProducerConfig.COMPRESSION_TYPE_CONFIG, "snappy");

KafkaProducer<String, String> producer = new KafkaProducer<>(props);

ProducerRecord<String, String> record = new ProducerRecord<>(
    "my-topic",
    "key",
    "value"
);

producer.send(record, (metadata, exception) -> {
    if (exception != null) {
        exception.printStackTrace();
    } else {
        System.out.printf("Sent to partition %d, offset %d%n",
            metadata.partition(), metadata.offset());
    }
});

producer.close();
```

### 2. Consumer Configuration

```python
# Python consumer with manual commit
from confluent_kafka import Consumer, KafkaError
import json

consumer_config = {
    'bootstrap.servers': 'localhost:9092',
    'group.id': 'my-consumer-group',
    'client.id': 'consumer-1',

    # Offset management
    'auto.offset.reset': 'earliest',      # Start from beginning if no offset
    'enable.auto.commit': False,          # Manual commit for reliability

    # Performance settings
    'fetch.min.bytes': 1,
    'fetch.max.wait.ms': 500,
    'max.poll.records': 500,
    'max.partition.fetch.bytes': 1048576,

    # Session management
    'session.timeout.ms': 30000,
    'heartbeat.interval.ms': 10000,
    'max.poll.interval.ms': 300000
}

consumer = Consumer(consumer_config)
consumer.subscribe(['my-topic'])

try:
    while True:
        msg = consumer.poll(timeout=1.0)

        if msg is None:
            continue

        if msg.error():
            if msg.error().code() == KafkaError._PARTITION_EOF:
                continue
            else:
                print(f'Error: {msg.error()}')
                break

        # Process message
        key = msg.key().decode('utf-8') if msg.key() else None
        value = json.loads(msg.value().decode('utf-8'))

        try:
            process_message(key, value)
            # Commit after successful processing
            consumer.commit(asynchronous=False)
        except Exception as e:
            # Handle processing error
            handle_error(msg, e)

finally:
    consumer.close()
```

```javascript
// Node.js consumer with kafkajs
const consumer = kafka.consumer({
    groupId: 'my-consumer-group',
    sessionTimeout: 30000,
    heartbeatInterval: 3000,
    maxBytesPerPartition: 1048576,
    minBytes: 1,
    maxBytes: 10485760,
    maxWaitTimeInMs: 5000,
    retry: {
        initialRetryTime: 100,
        retries: 8
    }
});

async function startConsumer() {
    await consumer.connect();
    await consumer.subscribe({
        topics: ['my-topic'],
        fromBeginning: false
    });

    await consumer.run({
        eachBatchAutoResolve: false,
        eachBatch: async ({ batch, resolveOffset, heartbeat, commitOffsetsIfNecessary }) => {
            for (let message of batch.messages) {
                const key = message.key?.toString();
                const value = JSON.parse(message.value.toString());

                try {
                    await processMessage(key, value);
                    resolveOffset(message.offset);
                    await heartbeat();
                } catch (error) {
                    // Handle error - maybe send to DLQ
                    await sendToDeadLetterQueue(message, error);
                    resolveOffset(message.offset);
                }
            }

            await commitOffsetsIfNecessary();
        }
    });
}

// Graceful shutdown
const errorTypes = ['unhandledRejection', 'uncaughtException'];
const signalTraps = ['SIGTERM', 'SIGINT', 'SIGUSR2'];

errorTypes.forEach(type => {
    process.on(type, async () => {
        try {
            await consumer.disconnect();
            process.exit(0);
        } catch (_) {
            process.exit(1);
        }
    });
});

signalTraps.forEach(type => {
    process.once(type, async () => {
        try {
            await consumer.disconnect();
        } finally {
            process.kill(process.pid, type);
        }
    });
});
```

### 3. Topic Design and Partitioning

```python
# Topic creation with proper configuration
from confluent_kafka.admin import AdminClient, NewTopic

admin = AdminClient({'bootstrap.servers': 'localhost:9092'})

# Create topic with proper partitioning
new_topic = NewTopic(
    topic='orders',
    num_partitions=12,        # Based on throughput needs
    replication_factor=3,     # For high availability
    config={
        'retention.ms': '604800000',      # 7 days
        'retention.bytes': '-1',           # Unlimited
        'cleanup.policy': 'delete',
        'min.insync.replicas': '2',        # Require 2 replicas for writes
        'compression.type': 'snappy',
        'max.message.bytes': '1048576'     # 1MB max message
    }
)

fs = admin.create_topics([new_topic])

for topic, f in fs.items():
    try:
        f.result()
        print(f"Topic {topic} created")
    except Exception as e:
        print(f"Failed to create topic {topic}: {e}")
```

### Partitioning Strategies

```python
# Custom partitioner for consistent routing
class OrderPartitioner:
    def __init__(self, num_partitions):
        self.num_partitions = num_partitions

    def partition(self, key):
        # Route by customer_id for order locality
        if key:
            return hash(key) % self.num_partitions
        return 0

# Key-based partitioning for ordering guarantees
def send_order_event(order):
    # Use customer_id as key to ensure order for same customer
    # goes to same partition
    producer.produce(
        topic='orders',
        key=str(order['customer_id']),
        value=json.dumps(order)
    )
```

### 4. Error Handling and Dead Letter Queue

```python
class KafkaMessageHandler:
    def __init__(self, producer, consumer):
        self.producer = producer
        self.consumer = consumer
        self.max_retries = 3

    def process_with_retry(self, msg):
        retries = int(msg.headers().get('retry_count', 0)) if msg.headers() else 0

        try:
            value = json.loads(msg.value().decode('utf-8'))
            self.process_message(value)
            return True
        except RetryableError as e:
            if retries < self.max_retries:
                self.send_to_retry_topic(msg, retries + 1)
            else:
                self.send_to_dlq(msg, str(e))
            return False
        except NonRetryableError as e:
            self.send_to_dlq(msg, str(e))
            return False

    def send_to_retry_topic(self, msg, retry_count):
        headers = [
            ('retry_count', str(retry_count).encode()),
            ('original_topic', msg.topic().encode()),
            ('original_partition', str(msg.partition()).encode())
        ]

        self.producer.produce(
            topic=f'{msg.topic()}.retry',
            key=msg.key(),
            value=msg.value(),
            headers=headers
        )

    def send_to_dlq(self, msg, error_reason):
        headers = [
            ('original_topic', msg.topic().encode()),
            ('error_reason', error_reason.encode()),
            ('failed_at', datetime.now().isoformat().encode())
        ]

        self.producer.produce(
            topic='dead-letter-queue',
            key=msg.key(),
            value=msg.value(),
            headers=headers
        )
```

### 5. Exactly-Once Semantics (Transactions)

```python
# Transactional producer for exactly-once
from confluent_kafka import Producer

producer_config = {
    'bootstrap.servers': 'localhost:9092',
    'transactional.id': 'my-transaction-id',
    'enable.idempotence': True,
    'acks': 'all',
    'retries': 2147483647,
    'max.in.flight.requests.per.connection': 5
}

producer = Producer(producer_config)
producer.init_transactions()

try:
    producer.begin_transaction()

    # Send multiple messages atomically
    producer.produce('topic-a', key='key1', value='value1')
    producer.produce('topic-b', key='key2', value='value2')

    # Commit consumer offsets within transaction
    producer.send_offsets_to_transaction(
        consumer.position(consumer.assignment()),
        consumer.consumer_group_metadata()
    )

    producer.commit_transaction()
except Exception as e:
    producer.abort_transaction()
    raise e
```

### 6. Kafka Streams (Stream Processing)

```java
// Java Kafka Streams application
import org.apache.kafka.streams.*;
import org.apache.kafka.streams.kstream.*;

Properties props = new Properties();
props.put(StreamsConfig.APPLICATION_ID_CONFIG, "order-processing");
props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
props.put(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.String().getClass());
props.put(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG, Serdes.String().getClass());
props.put(StreamsConfig.PROCESSING_GUARANTEE_CONFIG, StreamsConfig.EXACTLY_ONCE_V2);

StreamsBuilder builder = new StreamsBuilder();

// Read from input topic
KStream<String, String> orders = builder.stream("orders");

// Transform and filter
KStream<String, String> validOrders = orders
    .filter((key, value) -> isValidOrder(value))
    .mapValues(value -> enrichOrder(value));

// Branch based on order type
KStream<String, String>[] branches = validOrders.branch(
    (key, value) -> isHighPriority(value),
    (key, value) -> true
);

branches[0].to("high-priority-orders");
branches[1].to("regular-orders");

// Aggregation example
KTable<String, Long> orderCounts = orders
    .groupByKey()
    .count(Materialized.as("order-counts-store"));

// Join streams
KStream<String, String> enrichedOrders = orders.join(
    customerTable,
    (order, customer) -> enrichWithCustomer(order, customer),
    Joined.with(Serdes.String(), Serdes.String(), Serdes.String())
);

KafkaStreams streams = new KafkaStreams(builder.build(), props);
streams.start();

// Graceful shutdown
Runtime.getRuntime().addShutdownHook(new Thread(streams::close));
```

## Advanced Patterns

### 1. Event Sourcing with Kafka

```python
class EventStore:
    def __init__(self, producer, consumer):
        self.producer = producer
        self.consumer = consumer

    def append_event(self, aggregate_id, event_type, event_data):
        event = {
            'aggregate_id': aggregate_id,
            'event_type': event_type,
            'data': event_data,
            'timestamp': datetime.now().isoformat(),
            'version': self._get_next_version(aggregate_id)
        }

        self.producer.produce(
            topic=f'events.{aggregate_id.split(":")[0]}',
            key=aggregate_id,
            value=json.dumps(event)
        )
        self.producer.flush()

    def get_events(self, aggregate_id):
        # Read all events for an aggregate
        topic = f'events.{aggregate_id.split(":")[0]}'
        events = []

        # Use consumer with specific partition assignment
        partition = self._get_partition(aggregate_id)
        self.consumer.assign([TopicPartition(topic, partition)])
        self.consumer.seek_to_beginning()

        while True:
            msg = self.consumer.poll(timeout=1.0)
            if msg is None:
                break
            if msg.key().decode() == aggregate_id:
                events.append(json.loads(msg.value()))

        return events

    def rebuild_state(self, aggregate_id, apply_event_fn):
        events = self.get_events(aggregate_id)
        state = {}

        for event in events:
            state = apply_event_fn(state, event)

        return state
```

### 2. CQRS Pattern

```python
# Command side - writes to Kafka
class OrderCommandHandler:
    def __init__(self, producer):
        self.producer = producer

    def handle_create_order(self, command):
        event = {
            'event_type': 'OrderCreated',
            'order_id': command['order_id'],
            'customer_id': command['customer_id'],
            'items': command['items'],
            'timestamp': datetime.now().isoformat()
        }

        self.producer.produce(
            topic='order-events',
            key=command['order_id'],
            value=json.dumps(event)
        )

# Query side - consumes from Kafka, updates read model
class OrderProjection:
    def __init__(self, consumer, read_db):
        self.consumer = consumer
        self.read_db = read_db

    def start(self):
        self.consumer.subscribe(['order-events'])

        while True:
            msg = self.consumer.poll(timeout=1.0)
            if msg is None:
                continue

            event = json.loads(msg.value())
            self.apply_event(event)
            self.consumer.commit()

    def apply_event(self, event):
        if event['event_type'] == 'OrderCreated':
            self.read_db.insert_order({
                'order_id': event['order_id'],
                'customer_id': event['customer_id'],
                'status': 'created',
                'items': event['items']
            })
        elif event['event_type'] == 'OrderShipped':
            self.read_db.update_order_status(
                event['order_id'],
                'shipped'
            )
```

### 3. Saga Pattern for Distributed Transactions

```python
class OrderSagaOrchestrator:
    def __init__(self, producer, consumer):
        self.producer = producer
        self.consumer = consumer
        self.saga_states = {}

    def start_saga(self, order):
        saga_id = str(uuid.uuid4())
        self.saga_states[saga_id] = {
            'order': order,
            'step': 'reserve_inventory',
            'compensations': []
        }

        # Step 1: Reserve inventory
        self.producer.produce(
            topic='inventory.commands',
            key=saga_id,
            value=json.dumps({
                'command': 'reserve',
                'saga_id': saga_id,
                'items': order['items']
            })
        )

    def handle_response(self, saga_id, response):
        saga = self.saga_states.get(saga_id)
        if not saga:
            return

        if response['status'] == 'success':
            self._advance_saga(saga_id, saga, response)
        else:
            self._rollback_saga(saga_id, saga)

    def _advance_saga(self, saga_id, saga, response):
        saga['compensations'].append(response.get('compensation'))

        if saga['step'] == 'reserve_inventory':
            saga['step'] = 'process_payment'
            self.producer.produce(
                topic='payment.commands',
                key=saga_id,
                value=json.dumps({
                    'command': 'charge',
                    'saga_id': saga_id,
                    'amount': saga['order']['total']
                })
            )
        elif saga['step'] == 'process_payment':
            saga['step'] = 'complete'
            self.producer.produce(
                topic='orders.events',
                key=saga['order']['order_id'],
                value=json.dumps({
                    'event': 'OrderCompleted',
                    'order': saga['order']
                })
            )

    def _rollback_saga(self, saga_id, saga):
        # Execute compensations in reverse order
        for compensation in reversed(saga['compensations']):
            if compensation:
                self.producer.produce(
                    topic=compensation['topic'],
                    key=saga_id,
                    value=json.dumps(compensation['command'])
                )
```

## Performance Optimization

### 1. Producer Tuning

```python
# High-throughput producer settings
high_throughput_config = {
    'bootstrap.servers': 'localhost:9092',
    'acks': '1',                      # Don't wait for all replicas
    'batch.size': 65536,              # Larger batches
    'linger.ms': 20,                  # Wait longer for batching
    'compression.type': 'lz4',        # Fast compression
    'buffer.memory': 67108864,        # 64MB buffer
    'max.in.flight.requests.per.connection': 5
}

# Low-latency producer settings
low_latency_config = {
    'bootstrap.servers': 'localhost:9092',
    'acks': '1',
    'batch.size': 0,                  # No batching
    'linger.ms': 0,                   # Send immediately
    'compression.type': 'none'
}
```

### 2. Consumer Tuning

```python
# High-throughput consumer
high_throughput_consumer = {
    'bootstrap.servers': 'localhost:9092',
    'group.id': 'high-throughput-group',
    'fetch.min.bytes': 50000,         # Wait for more data
    'fetch.max.wait.ms': 500,
    'max.partition.fetch.bytes': 10485760,  # 10MB per partition
    'max.poll.records': 1000
}

# Low-latency consumer
low_latency_consumer = {
    'bootstrap.servers': 'localhost:9092',
    'group.id': 'low-latency-group',
    'fetch.min.bytes': 1,
    'fetch.max.wait.ms': 100,
    'max.poll.records': 100
}
```

### 3. Broker Configuration

```properties
# server.properties

# Replication
default.replication.factor=3
min.insync.replicas=2

# Performance
num.network.threads=8
num.io.threads=16
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600

# Log settings
num.partitions=12
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000

# Compression
compression.type=producer

# ZooKeeper (legacy) / KRaft settings
zookeeper.session.timeout.ms=18000
```

## Monitoring and Observability

### Key Metrics to Monitor

```python
# Producer metrics
producer_metrics = [
    'record-send-rate',           # Messages/sec
    'record-error-rate',          # Errors/sec
    'record-retry-rate',          # Retries/sec
    'request-latency-avg',        # Avg request latency
    'batch-size-avg',             # Avg batch size
    'buffer-available-bytes',     # Buffer space
    'waiting-threads'             # Blocked threads
]

# Consumer metrics
consumer_metrics = [
    'records-consumed-rate',      # Messages/sec
    'records-lag',                # Consumer lag
    'fetch-rate',                 # Fetch requests/sec
    'fetch-latency-avg',          # Avg fetch latency
    'commit-rate',                # Commits/sec
    'rebalance-rate-per-hour'     # Rebalance frequency
]

# Monitor consumer lag
from confluent_kafka.admin import AdminClient

def get_consumer_lag(admin, group_id, topic):
    # Get committed offsets
    committed = admin.list_consumer_group_offsets([group_id])

    # Get end offsets
    consumer = Consumer({'bootstrap.servers': 'localhost:9092', 'group.id': 'temp'})
    end_offsets = consumer.get_watermark_offsets(TopicPartition(topic, 0))

    lag = end_offsets[1] - committed[group_id][TopicPartition(topic, 0)].offset
    return lag
```

### Prometheus Integration

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'kafka'
    static_configs:
      - targets: ['kafka-1:9308', 'kafka-2:9308', 'kafka-3:9308']

  - job_name: 'kafka-exporter'
    static_configs:
      - targets: ['kafka-exporter:9308']
```

## Common Pitfalls to Avoid

1. **Not Setting Proper Replication**: Always use replication factor >= 3 for production
2. **Ignoring Consumer Lag**: Monitor and alert on growing lag
3. **Too Many Partitions**: Start small, partitions are expensive
4. **Not Handling Rebalancing**: Implement proper shutdown and commit handling
5. **Storing Large Messages**: Keep messages under 1MB, use external storage for large data
6. **Ignoring Offset Management**: Use manual commits for critical processing
7. **No Dead Letter Queue**: Always have a DLQ for failed messages
8. **Insufficient Retention**: Plan retention based on recovery needs
9. **Skipping Exactly-Once Setup**: Configure idempotence for critical data
10. **Not Monitoring Broker Health**: Watch for under-replicated partitions

## Security Best Practices

```properties
# Kafka server security configuration
# SSL/TLS
listeners=SASL_SSL://0.0.0.0:9093
ssl.keystore.location=/var/private/ssl/kafka.server.keystore.jks
ssl.keystore.password=keystore_password
ssl.key.password=key_password
ssl.truststore.location=/var/private/ssl/kafka.server.truststore.jks
ssl.truststore.password=truststore_password

# SASL Authentication
sasl.enabled.mechanisms=SCRAM-SHA-512
sasl.mechanism.inter.broker.protocol=SCRAM-SHA-512

# Authorization
authorizer.class.name=kafka.security.authorizer.AclAuthorizer
super.users=User:admin

# Network
ssl.client.auth=required
security.inter.broker.protocol=SASL_SSL
```

```python
# Secure client configuration
secure_config = {
    'bootstrap.servers': 'kafka:9093',
    'security.protocol': 'SASL_SSL',
    'sasl.mechanism': 'SCRAM-SHA-512',
    'sasl.username': 'your-username',
    'sasl.password': 'your-password',
    'ssl.ca.location': '/path/to/ca-cert.pem',
    'ssl.certificate.location': '/path/to/client-cert.pem',
    'ssl.key.location': '/path/to/client-key.pem'
}
```

## Use Cases

### When to Use Kafka
- **High-throughput event streaming**: Millions of events/second
- **Event sourcing**: Complete audit trail of all changes
- **Log aggregation**: Centralized logging from distributed systems
- **Stream processing**: Real-time analytics and transformations
- **Microservices communication**: Decoupled, async messaging
- **Data integration**: Connect disparate systems
- **Metrics collection**: Time-series data ingestion
- **Replay capability**: Need to reprocess historical data

### When NOT to Use Kafka
- Simple request-response patterns (use HTTP/gRPC)
- Small-scale applications with low throughput
- When you need strict message ordering across all messages
- Simple job queues (consider Redis or RabbitMQ)
- When you need complex routing logic (consider RabbitMQ)

## Useful Tools and Libraries

- **confluent-kafka-python**: Official Python client
- **kafka-python**: Pure Python client
- **kafkajs**: Node.js client
- **kafka-clients**: Java client
- **librdkafka**: C/C++ client (used by many wrappers)
- **Kafka Connect**: Data integration framework
- **Kafka Streams**: Stream processing library
- **ksqlDB**: Streaming SQL engine
- **Schema Registry**: Schema management
- **Kafka UI**: Web interface for Kafka
- **Conduktor**: Desktop GUI for Kafka
- **Burrow**: Consumer lag monitoring
- **Cruise Control**: Automated rebalancing
