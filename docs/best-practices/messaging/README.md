# Messaging Systems Comparison Guide

## Overview

This guide compares three popular messaging technologies - **Apache Kafka**, **RabbitMQ**, and **Redis** (Pub/Sub & Streams) - to help you choose the right tool for your use case.

## Quick Comparison Table

| Feature | Kafka | RabbitMQ | Redis |
|---------|-------|----------|-------|
| **Primary Use** | Event streaming | Message queuing | Caching + messaging |
| **Message Retention** | Long-term (configurable) | Until consumed | Ephemeral (Pub/Sub) / Configurable (Streams) |
| **Throughput** | Very High (millions/sec) | Medium (tens of thousands/sec) | Very High (hundreds of thousands/sec) |
| **Latency** | Low-Medium (ms) | Very Low (sub-ms) | Ultra-Low (sub-ms) |
| **Message Ordering** | Per partition | Per queue | Per stream/channel |
| **Message Replay** | Yes (native) | No (without plugins) | Yes (Streams only) |
| **Protocol** | Custom (Kafka Protocol) | AMQP, MQTT, STOMP | RESP |
| **Clustering** | Native | Native (Quorum Queues) | Cluster mode |
| **Learning Curve** | Steep | Moderate | Easy |

## Detailed Comparison

### Message Delivery Semantics

```
┌─────────────────┬───────────────────┬───────────────────┬──────────────────┐
│                 │       Kafka       │     RabbitMQ      │      Redis       │
├─────────────────┼───────────────────┼───────────────────┼──────────────────┤
│ At-most-once    │ acks=0            │ auto-ack=true     │ Pub/Sub default  │
│ At-least-once   │ acks=1, acks=all  │ manual ack        │ Streams + ack    │
│ Exactly-once    │ Transactions +    │ Not native        │ Not supported    │
│                 │ idempotent        │ (app-level dedup) │                  │
└─────────────────┴───────────────────┴───────────────────┴──────────────────┘
```

### Architecture Patterns

```
KAFKA (Log-based)
─────────────────
Producer → Topic (Partitions) → Consumer Groups
           [P0][P1][P2][P3]     ├── Group A: Consumer 1, 2
                                └── Group B: Consumer 3

- Messages retained for configured period
- Multiple consumer groups can read same data
- Consumers track their own offset


RABBITMQ (Queue-based)
──────────────────────
Publisher → Exchange → Queue → Consumer
                 ↓
            Routing Rules (direct, topic, fanout, headers)

- Messages removed after acknowledgment
- Complex routing capabilities
- Single consumer per message (unless fanout)


REDIS (In-memory)
─────────────────
Pub/Sub: Publisher → Channel → Subscribers (no persistence)

Streams:  Producer → Stream → Consumer Groups
                     [Entry 1][Entry 2][Entry 3]
                     ├── Group A: Consumer 1
                     └── Group B: Consumer 2

- Pub/Sub: Fire-and-forget, no persistence
- Streams: Persistent, similar to Kafka but simpler
```

## When to Use Each

### Choose Kafka When:

1. **High-throughput event streaming**
   - Processing millions of events per second
   - Real-time analytics pipelines
   - Log aggregation at scale

2. **Event sourcing / CQRS**
   - Need complete audit trail
   - Must replay events to rebuild state
   - Event-driven architecture

3. **Long-term message storage**
   - Messages need to persist for days/weeks
   - Multiple consumers need same data at different times
   - Data lake ingestion

4. **Stream processing**
   - Real-time data transformations
   - Windowed aggregations
   - Complex event processing

```python
# Kafka example: Real-time analytics pipeline
from confluent_kafka import Consumer, Producer

# Produce clickstream events
producer.produce('clickstream', key=user_id, value=json.dumps({
    'event': 'page_view',
    'page': '/products/123',
    'timestamp': datetime.now().isoformat()
}))

# Multiple consumer groups process same data
# Analytics group: Calculate real-time metrics
# ML group: Train recommendation models
# Archive group: Store to data lake
```

### Choose RabbitMQ When:

1. **Complex routing requirements**
   - Route messages based on multiple criteria
   - Different consumers need different message subsets
   - Header-based routing

2. **Request-reply patterns (RPC)**
   - Synchronous-style communication over async transport
   - Service-to-service communication with response
   - Command execution with confirmation

3. **Task queues with priorities**
   - Background job processing
   - Priority-based task execution
   - Rate limiting with prefetch

4. **Multi-protocol support**
   - MQTT for IoT devices
   - STOMP for web clients
   - AMQP for enterprise systems

```python
# RabbitMQ example: Task queue with priorities
channel.queue_declare(queue='tasks', arguments={'x-max-priority': 10})

# High priority task
channel.basic_publish(
    exchange='',
    routing_key='tasks',
    body=json.dumps({'task': 'send_alert'}),
    properties=pika.BasicProperties(priority=10)
)

# Normal priority task
channel.basic_publish(
    exchange='',
    routing_key='tasks',
    body=json.dumps({'task': 'generate_report'}),
    properties=pika.BasicProperties(priority=5)
)
```

### Choose Redis When:

1. **Simple pub/sub notifications**
   - Real-time updates to connected clients
   - Cache invalidation signals
   - Live dashboards

2. **High-speed message passing**
   - Inter-service communication in same datacenter
   - Temporary work queues
   - Session events

3. **Already using Redis for caching**
   - Reduce infrastructure complexity
   - Simple messaging needs
   - Lightweight event bus

4. **Redis Streams for lightweight event sourcing**
   - Need Kafka-like features at smaller scale
   - Already have Redis infrastructure
   - Simpler operational model

```python
# Redis Pub/Sub: Real-time notifications
import redis

r = redis.Redis()

# Publisher: Notify about cache invalidation
r.publish('cache:invalidate', json.dumps({
    'key': 'user:123',
    'reason': 'profile_updated'
}))

# Subscriber: Invalidate local cache
pubsub = r.pubsub()
pubsub.subscribe('cache:invalidate')

for message in pubsub.listen():
    if message['type'] == 'message':
        data = json.loads(message['data'])
        local_cache.delete(data['key'])
```

```python
# Redis Streams: Lightweight event log
import redis

r = redis.Redis()

# Add events to stream
r.xadd('orders', {
    'order_id': '123',
    'customer': 'john',
    'status': 'created'
})

# Create consumer group
r.xgroup_create('orders', 'order-processors', id='0', mkstream=True)

# Process events
events = r.xreadgroup('order-processors', 'worker-1', {'orders': '>'}, count=10)
for stream, messages in events:
    for msg_id, data in messages:
        process_order(data)
        r.xack('orders', 'order-processors', msg_id)
```

## Decision Flowchart

```
                            Start
                              │
                              ▼
              ┌───────────────────────────────┐
              │ Need message replay/retention │
              │      for days/weeks?          │
              └───────────────┬───────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                   YES                  NO
                    │                   │
                    ▼                   ▼
              ┌───────────┐    ┌────────────────────┐
              │   KAFKA   │    │ Need complex       │
              └───────────┘    │ routing logic?     │
                               └─────────┬──────────┘
                                         │
                               ┌─────────┴─────────┐
                               │                   │
                              YES                  NO
                               │                   │
                               ▼                   ▼
                         ┌──────────┐    ┌────────────────────┐
                         │ RABBITMQ │    │ Need < 1ms latency │
                         └──────────┘    │ or already have    │
                                         │ Redis?             │
                                         └─────────┬──────────┘
                                                   │
                                         ┌─────────┴─────────┐
                                         │                   │
                                        YES                  NO
                                         │                   │
                                         ▼                   ▼
                                   ┌─────────┐         ┌──────────┐
                                   │  REDIS  │         │ RABBITMQ │
                                   └─────────┘         └──────────┘
```

## Performance Benchmarks (Typical)

### Throughput (messages/second)

| System | Single Producer | Single Consumer | E2E Latency (p99) |
|--------|----------------|-----------------|-------------------|
| Kafka | 1,000,000+ | 1,000,000+ | 5-20ms |
| RabbitMQ | 20,000-50,000 | 20,000-50,000 | 1-5ms |
| Redis Pub/Sub | 500,000+ | 500,000+ | < 1ms |
| Redis Streams | 100,000+ | 100,000+ | 1-2ms |

*Note: Actual performance varies based on message size, persistence settings, network, and hardware.*

### Resource Usage

| System | Memory | Disk | CPU |
|--------|--------|------|-----|
| Kafka | Medium | High (log retention) | Medium |
| RabbitMQ | High (queues) | Medium | Low-Medium |
| Redis | Very High (in-memory) | Low-Medium | Low |

## Migration Patterns

### From RabbitMQ to Kafka

```python
# Before: RabbitMQ
channel.basic_publish(
    exchange='orders',
    routing_key='order.created',
    body=json.dumps(order)
)

# After: Kafka
# Use order_id as key for partition locality
producer.produce(
    topic='orders',
    key=str(order['customer_id']),  # Ensures order for same customer
    value=json.dumps({'type': 'created', **order})
)

# Migration strategy:
# 1. Dual-write to both systems
# 2. Verify message delivery in Kafka
# 3. Migrate consumers one by one
# 4. Disable RabbitMQ publishing
```

### From Redis Pub/Sub to Streams

```python
# Before: Redis Pub/Sub (fire and forget)
redis.publish('events', json.dumps(event))

# After: Redis Streams (persistent, replayable)
redis.xadd('events', event, maxlen=100000)

# Benefits:
# - Message persistence
# - Consumer groups
# - Message acknowledgment
# - Replay capability
```

## Hybrid Architecture Example

Use multiple messaging systems for their strengths:

```
┌─────────────────────────────────────────────────────────────────┐
│                        Application Layer                         │
└───────────────────────────────┬─────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐     ┌─────────────────┐     ┌───────────────┐
│     Kafka     │     │    RabbitMQ     │     │     Redis     │
│               │     │                 │     │               │
│ • Event logs  │     │ • Task queues   │     │ • Cache       │
│ • Analytics   │     │ • RPC calls     │     │ • Sessions    │
│ • Audit trail │     │ • Notifications │     │ • Pub/Sub     │
└───────────────┘     └─────────────────┘     └───────────────┘
```

```python
class MessagingFacade:
    def __init__(self, kafka, rabbitmq, redis):
        self.kafka = kafka
        self.rabbitmq = rabbitmq
        self.redis = redis

    def log_event(self, event_type, data):
        """Long-term event storage → Kafka"""
        self.kafka.produce('events', value=json.dumps({
            'type': event_type,
            'data': data,
            'timestamp': datetime.now().isoformat()
        }))

    def enqueue_task(self, task, priority=5):
        """Background job processing → RabbitMQ"""
        self.rabbitmq.publish(
            exchange='tasks',
            routing_key=task['type'],
            body=json.dumps(task),
            properties={'priority': priority}
        )

    def notify_realtime(self, channel, message):
        """Real-time updates → Redis Pub/Sub"""
        self.redis.publish(channel, json.dumps(message))

    def invalidate_cache(self, keys):
        """Cache coordination → Redis"""
        for key in keys:
            self.redis.delete(key)
            self.redis.publish('cache:invalidate', key)


# Usage
messaging = MessagingFacade(kafka, rabbitmq, redis)

# Order placed
messaging.log_event('order.created', order)           # Kafka: audit trail
messaging.enqueue_task({'type': 'send_email', 'order': order})  # RabbitMQ: async task
messaging.notify_realtime(f'user:{user_id}', {'event': 'order_confirmed'})  # Redis: real-time
messaging.invalidate_cache([f'user:{user_id}:orders'])  # Redis: cache
```

## Operational Considerations

### Monitoring Essentials

| System | Key Metrics |
|--------|-------------|
| Kafka | Consumer lag, under-replicated partitions, request latency |
| RabbitMQ | Queue depth, message rates, connection count, memory usage |
| Redis | Memory usage, keyspace hits/misses, connected clients |

### Backup & Recovery

| System | Strategy |
|--------|----------|
| Kafka | Retention-based (messages persist), MirrorMaker for DR |
| RabbitMQ | Shovel/Federation for replication, definition export |
| Redis | RDB snapshots, AOF persistence, Redis Sentinel/Cluster |

### Scaling

| System | Horizontal Scaling |
|--------|-------------------|
| Kafka | Add partitions + brokers, rebalance consumers |
| RabbitMQ | Add nodes to cluster, use quorum queues |
| Redis | Cluster mode with hash slots, read replicas |

## Summary Recommendations

| Scenario | Recommendation |
|----------|----------------|
| High-volume event streaming | **Kafka** |
| Event sourcing / CQRS | **Kafka** |
| Background job processing | **RabbitMQ** |
| Complex message routing | **RabbitMQ** |
| Request-reply (RPC) | **RabbitMQ** |
| Real-time notifications | **Redis Pub/Sub** |
| Simple queue + cache | **Redis** |
| IoT / MQTT support | **RabbitMQ** |
| Analytics pipeline | **Kafka** |
| Microservices (general) | **RabbitMQ** or **Kafka** (based on scale) |

## Further Reading

- [Kafka Documentation](kafka.md) - Detailed Kafka best practices
- [RabbitMQ Documentation](rabbitmq.md) - Detailed RabbitMQ best practices
- [Redis Documentation](../database/redis.md) - Redis best practices including Pub/Sub and Streams
