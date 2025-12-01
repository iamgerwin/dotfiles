# RabbitMQ Best Practices

## Official Documentation
- **RabbitMQ Documentation**: https://www.rabbitmq.com/documentation.html
- **RabbitMQ Tutorials**: https://www.rabbitmq.com/getstarted.html
- **AMQP Concepts**: https://www.rabbitmq.com/tutorials/amqp-concepts.html
- **Management UI**: https://www.rabbitmq.com/management.html

## Architecture Overview
```
Publishers
    ↓
Exchange (routing logic)
    ├── Direct Exchange → Queue 1 (exact routing key match)
    ├── Fanout Exchange → Queue 2, Queue 3 (broadcast)
    ├── Topic Exchange → Queue 4 (pattern matching)
    └── Headers Exchange → Queue 5 (header matching)
    ↓
Queues (message storage)
    ↓
Consumers
    ├── Consumer 1 ← Queue 1
    ├── Consumer 2 ← Queue 2
    └── Consumer 3 ← Queue 3 (competing consumers)
```

### Key Concepts
- **Exchange**: Receives messages and routes to queues based on rules
- **Queue**: Buffer that stores messages
- **Binding**: Rule linking exchange to queue
- **Routing Key**: Address used for routing decisions
- **Virtual Host (vhost)**: Logical grouping for isolation
- **Channel**: Virtual connection inside a connection
- **Consumer**: Application receiving messages
- **Acknowledgment**: Confirmation of message processing

## Core Best Practices

### 1. Connection and Channel Management

```python
# Python with pika
import pika
from pika.exchange_type import ExchangeType
import json

# Connection with retry and heartbeat
connection_params = pika.ConnectionParameters(
    host='localhost',
    port=5672,
    virtual_host='/',
    credentials=pika.PlainCredentials('guest', 'guest'),
    heartbeat=600,                    # Heartbeat interval
    blocked_connection_timeout=300,   # Timeout for blocked connections
    connection_attempts=3,            # Retry attempts
    retry_delay=5,                    # Delay between retries
    socket_timeout=10
)

connection = pika.BlockingConnection(connection_params)
channel = connection.channel()

# Enable publisher confirms for reliability
channel.confirm_delivery()

# Declare exchange and queue with durability
channel.exchange_declare(
    exchange='orders',
    exchange_type=ExchangeType.topic,
    durable=True
)

channel.queue_declare(
    queue='order-processing',
    durable=True,
    arguments={
        'x-message-ttl': 86400000,     # 24 hour TTL
        'x-max-length': 100000,         # Max queue length
        'x-overflow': 'reject-publish', # Reject when full
        'x-dead-letter-exchange': 'dlx',
        'x-dead-letter-routing-key': 'order-processing.dlq'
    }
)

channel.queue_bind(
    queue='order-processing',
    exchange='orders',
    routing_key='order.#'
)
```

```javascript
// Node.js with amqplib
const amqp = require('amqplib');

class RabbitMQConnection {
    constructor() {
        this.connection = null;
        this.channel = null;
    }

    async connect() {
        const config = {
            protocol: 'amqp',
            hostname: 'localhost',
            port: 5672,
            username: 'guest',
            password: 'guest',
            vhost: '/',
            heartbeat: 60
        };

        this.connection = await amqp.connect(config);

        // Handle connection events
        this.connection.on('error', (err) => {
            console.error('Connection error:', err);
            this.reconnect();
        });

        this.connection.on('close', () => {
            console.log('Connection closed, reconnecting...');
            this.reconnect();
        });

        this.channel = await this.connection.createConfirmChannel();

        // Enable publisher confirms
        await this.channel.waitForConfirms();

        return this.channel;
    }

    async reconnect() {
        setTimeout(async () => {
            try {
                await this.connect();
            } catch (err) {
                console.error('Reconnection failed:', err);
                this.reconnect();
            }
        }, 5000);
    }

    async setupQueue(queueName, options = {}) {
        const defaultOptions = {
            durable: true,
            arguments: {
                'x-message-ttl': 86400000,
                'x-dead-letter-exchange': 'dlx'
            }
        };

        await this.channel.assertQueue(queueName, { ...defaultOptions, ...options });
    }
}

const rabbit = new RabbitMQConnection();
await rabbit.connect();
```

### 2. Exchange Types and Routing

#### Direct Exchange
```python
# Direct exchange - exact routing key match
channel.exchange_declare(exchange='direct_logs', exchange_type='direct', durable=True)

# Bind queues with specific routing keys
channel.queue_declare(queue='error_logs', durable=True)
channel.queue_bind(exchange='direct_logs', queue='error_logs', routing_key='error')

channel.queue_declare(queue='info_logs', durable=True)
channel.queue_bind(exchange='direct_logs', queue='info_logs', routing_key='info')

# Publish to specific queue
channel.basic_publish(
    exchange='direct_logs',
    routing_key='error',  # Goes to error_logs queue
    body=json.dumps({'message': 'Error occurred'}),
    properties=pika.BasicProperties(
        delivery_mode=2,  # Persistent
        content_type='application/json'
    )
)
```

#### Fanout Exchange
```python
# Fanout exchange - broadcast to all bound queues
channel.exchange_declare(exchange='notifications', exchange_type='fanout', durable=True)

# All bound queues receive all messages
channel.queue_declare(queue='email_notifications', durable=True)
channel.queue_bind(exchange='notifications', queue='email_notifications')

channel.queue_declare(queue='sms_notifications', durable=True)
channel.queue_bind(exchange='notifications', queue='sms_notifications')

channel.queue_declare(queue='push_notifications', durable=True)
channel.queue_bind(exchange='notifications', queue='push_notifications')

# This message goes to ALL bound queues
channel.basic_publish(
    exchange='notifications',
    routing_key='',  # Ignored for fanout
    body=json.dumps({'event': 'user_signup', 'user_id': 123})
)
```

#### Topic Exchange
```python
# Topic exchange - pattern matching with wildcards
# * matches exactly one word
# # matches zero or more words

channel.exchange_declare(exchange='events', exchange_type='topic', durable=True)

# Bind with patterns
channel.queue_declare(queue='all_orders', durable=True)
channel.queue_bind(exchange='events', queue='all_orders', routing_key='order.#')

channel.queue_declare(queue='order_created', durable=True)
channel.queue_bind(exchange='events', queue='order_created', routing_key='order.created')

channel.queue_declare(queue='usa_orders', durable=True)
channel.queue_bind(exchange='events', queue='usa_orders', routing_key='order.*.usa')

# Publishing examples
channel.basic_publish(exchange='events', routing_key='order.created', body='...')      # → all_orders, order_created
channel.basic_publish(exchange='events', routing_key='order.shipped', body='...')      # → all_orders
channel.basic_publish(exchange='events', routing_key='order.created.usa', body='...')  # → all_orders, usa_orders
```

#### Headers Exchange
```python
# Headers exchange - match on message headers
channel.exchange_declare(exchange='headers_ex', exchange_type='headers', durable=True)

# x-match: all = all headers must match
# x-match: any = at least one header must match
channel.queue_declare(queue='pdf_reports', durable=True)
channel.queue_bind(
    exchange='headers_ex',
    queue='pdf_reports',
    arguments={'x-match': 'all', 'format': 'pdf', 'type': 'report'}
)

# Publish with headers
channel.basic_publish(
    exchange='headers_ex',
    routing_key='',
    body=report_data,
    properties=pika.BasicProperties(
        headers={'format': 'pdf', 'type': 'report'}
    )
)
```

### 3. Message Publishing with Reliability

```python
import pika
from pika.exceptions import UnroutableError, NackError

class ReliablePublisher:
    def __init__(self, connection_params):
        self.connection = pika.BlockingConnection(connection_params)
        self.channel = self.connection.channel()
        self.channel.confirm_delivery()

    def publish(self, exchange, routing_key, body, properties=None):
        if properties is None:
            properties = pika.BasicProperties(
                delivery_mode=2,           # Persistent message
                content_type='application/json',
                message_id=str(uuid.uuid4()),
                timestamp=int(time.time()),
                app_id='my-application'
            )

        try:
            self.channel.basic_publish(
                exchange=exchange,
                routing_key=routing_key,
                body=json.dumps(body) if isinstance(body, dict) else body,
                properties=properties,
                mandatory=True  # Return if unroutable
            )
            return True
        except UnroutableError:
            print(f'Message was returned - no queue bound for routing key: {routing_key}')
            return False
        except NackError:
            print('Message was nacked by broker')
            return False

    def publish_batch(self, messages):
        """Publish multiple messages in a batch"""
        results = []
        for msg in messages:
            result = self.publish(
                msg['exchange'],
                msg['routing_key'],
                msg['body']
            )
            results.append(result)
        return results

    def close(self):
        if self.connection and not self.connection.is_closed:
            self.connection.close()
```

```javascript
// Node.js reliable publisher
class ReliablePublisher {
    constructor(channel) {
        this.channel = channel;
    }

    async publish(exchange, routingKey, message, options = {}) {
        const defaultOptions = {
            persistent: true,
            contentType: 'application/json',
            messageId: uuid(),
            timestamp: Date.now(),
            mandatory: true
        };

        const finalOptions = { ...defaultOptions, ...options };
        const content = Buffer.from(JSON.stringify(message));

        return new Promise((resolve, reject) => {
            this.channel.publish(
                exchange,
                routingKey,
                content,
                finalOptions,
                (err) => {
                    if (err) {
                        reject(err);
                    } else {
                        resolve(true);
                    }
                }
            );
        });
    }

    async publishWithRetry(exchange, routingKey, message, maxRetries = 3) {
        let lastError;

        for (let attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                await this.publish(exchange, routingKey, message);
                return true;
            } catch (err) {
                lastError = err;
                console.error(`Publish attempt ${attempt} failed:`, err);
                await new Promise(r => setTimeout(r, 1000 * attempt));
            }
        }

        throw lastError;
    }
}
```

### 4. Consumer Implementation

```python
# Reliable consumer with manual acknowledgment
class ReliableConsumer:
    def __init__(self, connection_params, queue_name, prefetch_count=10):
        self.connection = pika.BlockingConnection(connection_params)
        self.channel = self.connection.channel()
        self.queue_name = queue_name

        # Set prefetch for fair dispatch
        self.channel.basic_qos(prefetch_count=prefetch_count)

    def start_consuming(self, callback):
        def wrapper(ch, method, properties, body):
            try:
                message = json.loads(body)
                callback(message, properties)

                # Acknowledge after successful processing
                ch.basic_ack(delivery_tag=method.delivery_tag)

            except json.JSONDecodeError as e:
                # Reject malformed messages without requeue
                ch.basic_reject(delivery_tag=method.delivery_tag, requeue=False)
                print(f'Invalid JSON: {e}')

            except RetryableError as e:
                # Requeue for retry
                ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)
                print(f'Retryable error: {e}')

            except Exception as e:
                # Send to DLQ (reject without requeue)
                ch.basic_reject(delivery_tag=method.delivery_tag, requeue=False)
                print(f'Processing error: {e}')

        self.channel.basic_consume(
            queue=self.queue_name,
            on_message_callback=wrapper,
            auto_ack=False  # Manual acknowledgment
        )

        print(f'Waiting for messages on {self.queue_name}...')
        self.channel.start_consuming()

    def stop_consuming(self):
        self.channel.stop_consuming()
        self.connection.close()


# Usage
def process_order(message, properties):
    print(f'Processing order: {message["order_id"]}')
    # Process the order...

consumer = ReliableConsumer(connection_params, 'order-processing')
consumer.start_consuming(process_order)
```

```javascript
// Node.js consumer with error handling
class Consumer {
    constructor(channel, queueName, options = {}) {
        this.channel = channel;
        this.queueName = queueName;
        this.prefetch = options.prefetch || 10;
    }

    async start(handler) {
        await this.channel.prefetch(this.prefetch);

        await this.channel.consume(this.queueName, async (msg) => {
            if (!msg) return;

            try {
                const content = JSON.parse(msg.content.toString());
                await handler(content, msg.properties);

                // Acknowledge on success
                this.channel.ack(msg);

            } catch (error) {
                console.error('Processing error:', error);

                if (this.isRetryable(error)) {
                    // Requeue for retry
                    this.channel.nack(msg, false, true);
                } else {
                    // Send to DLQ
                    this.channel.reject(msg, false);
                }
            }
        }, { noAck: false });
    }

    isRetryable(error) {
        return error.code === 'ETIMEOUT' ||
               error.code === 'ECONNRESET' ||
               error.message.includes('temporarily unavailable');
    }
}
```

### 5. Dead Letter Queue (DLQ) Pattern

```python
# Setup DLQ infrastructure
def setup_dlq(channel):
    # Dead letter exchange
    channel.exchange_declare(
        exchange='dlx',
        exchange_type='direct',
        durable=True
    )

    # Dead letter queue
    channel.queue_declare(
        queue='dead-letter-queue',
        durable=True,
        arguments={
            'x-message-ttl': 604800000  # 7 days retention
        }
    )

    channel.queue_bind(
        exchange='dlx',
        queue='dead-letter-queue',
        routing_key='#'  # Catch all
    )

    # Main queue with DLQ configuration
    channel.queue_declare(
        queue='main-queue',
        durable=True,
        arguments={
            'x-dead-letter-exchange': 'dlx',
            'x-dead-letter-routing-key': 'main-queue.dlq'
        }
    )


# DLQ consumer for monitoring and reprocessing
class DLQHandler:
    def __init__(self, channel):
        self.channel = channel

    def process_dlq(self):
        method, properties, body = self.channel.basic_get('dead-letter-queue')

        if method:
            message = json.loads(body)
            original_exchange = properties.headers.get('x-first-death-exchange')
            original_queue = properties.headers.get('x-first-death-queue')
            death_reason = properties.headers.get('x-first-death-reason')

            print(f'Dead letter from {original_queue}')
            print(f'Reason: {death_reason}')
            print(f'Message: {message}')

            # Decide: fix and republish, or discard
            return {
                'message': message,
                'original_queue': original_queue,
                'reason': death_reason,
                'delivery_tag': method.delivery_tag
            }
        return None

    def reprocess(self, delivery_tag, exchange, routing_key, body):
        """Republish to original destination"""
        self.channel.basic_publish(
            exchange=exchange,
            routing_key=routing_key,
            body=body
        )
        self.channel.basic_ack(delivery_tag=delivery_tag)
```

### 6. Request-Reply Pattern (RPC)

```python
# RPC Server
class RPCServer:
    def __init__(self, channel, queue_name):
        self.channel = channel
        self.queue_name = queue_name

        channel.queue_declare(queue=queue_name, durable=True)
        channel.basic_qos(prefetch_count=1)

    def start(self, handler):
        def on_request(ch, method, props, body):
            request = json.loads(body)

            try:
                response = handler(request)
                status = 'success'
            except Exception as e:
                response = {'error': str(e)}
                status = 'error'

            # Send response
            ch.basic_publish(
                exchange='',
                routing_key=props.reply_to,
                properties=pika.BasicProperties(
                    correlation_id=props.correlation_id,
                    content_type='application/json',
                    headers={'status': status}
                ),
                body=json.dumps(response)
            )
            ch.basic_ack(delivery_tag=method.delivery_tag)

        self.channel.basic_consume(
            queue=self.queue_name,
            on_message_callback=on_request
        )
        self.channel.start_consuming()


# RPC Client
class RPCClient:
    def __init__(self, channel):
        self.channel = channel
        self.callback_queue = None
        self.responses = {}

        # Create exclusive callback queue
        result = channel.queue_declare(queue='', exclusive=True)
        self.callback_queue = result.method.queue

        channel.basic_consume(
            queue=self.callback_queue,
            on_message_callback=self._on_response,
            auto_ack=True
        )

    def _on_response(self, ch, method, props, body):
        self.responses[props.correlation_id] = json.loads(body)

    def call(self, queue, request, timeout=30):
        correlation_id = str(uuid.uuid4())
        self.responses[correlation_id] = None

        self.channel.basic_publish(
            exchange='',
            routing_key=queue,
            properties=pika.BasicProperties(
                reply_to=self.callback_queue,
                correlation_id=correlation_id,
                content_type='application/json',
                expiration=str(timeout * 1000)
            ),
            body=json.dumps(request)
        )

        # Wait for response
        start_time = time.time()
        while self.responses[correlation_id] is None:
            self.channel.connection.process_data_events(time_limit=1)
            if time.time() - start_time > timeout:
                raise TimeoutError('RPC call timed out')

        return self.responses.pop(correlation_id)


# Usage
# Server
def calculate(request):
    return {'result': request['a'] + request['b']}

server = RPCServer(channel, 'calculator')
server.start(calculate)

# Client
client = RPCClient(channel)
result = client.call('calculator', {'a': 5, 'b': 3})
print(result)  # {'result': 8}
```

### 7. Priority Queues

```python
# Queue with priority support
channel.queue_declare(
    queue='priority-tasks',
    durable=True,
    arguments={
        'x-max-priority': 10  # Priority levels 0-10
    }
)

# Publish with priority
def publish_with_priority(channel, queue, message, priority):
    channel.basic_publish(
        exchange='',
        routing_key=queue,
        body=json.dumps(message),
        properties=pika.BasicProperties(
            delivery_mode=2,
            priority=priority  # Higher = more important
        )
    )

# Example usage
publish_with_priority(channel, 'priority-tasks', {'task': 'urgent'}, priority=10)
publish_with_priority(channel, 'priority-tasks', {'task': 'normal'}, priority=5)
publish_with_priority(channel, 'priority-tasks', {'task': 'low'}, priority=1)
```

### 8. Delayed Messages

```python
# Using rabbitmq_delayed_message_exchange plugin
channel.exchange_declare(
    exchange='delayed_exchange',
    exchange_type='x-delayed-message',
    arguments={'x-delayed-type': 'direct'}
)

def publish_delayed(channel, routing_key, message, delay_ms):
    channel.basic_publish(
        exchange='delayed_exchange',
        routing_key=routing_key,
        body=json.dumps(message),
        properties=pika.BasicProperties(
            headers={'x-delay': delay_ms}
        )
    )

# Schedule message for 5 minutes later
publish_delayed(channel, 'scheduled-tasks', {'task': 'send_reminder'}, 300000)


# Alternative: TTL + DLX pattern (no plugin needed)
def setup_delayed_queue(channel, delay_ms):
    # Holding queue with TTL
    channel.queue_declare(
        queue=f'delay-{delay_ms}ms',
        durable=True,
        arguments={
            'x-message-ttl': delay_ms,
            'x-dead-letter-exchange': '',
            'x-dead-letter-routing-key': 'destination-queue'
        }
    )

    # Destination queue
    channel.queue_declare(queue='destination-queue', durable=True)

# Messages sent to delay queue will appear in destination after TTL
```

## Advanced Patterns

### 1. Competing Consumers (Work Queue)

```python
# Multiple consumers share work from single queue
class WorkerPool:
    def __init__(self, connection_params, queue_name, num_workers=4):
        self.workers = []
        self.queue_name = queue_name

        for i in range(num_workers):
            conn = pika.BlockingConnection(connection_params)
            channel = conn.channel()
            channel.basic_qos(prefetch_count=1)  # Fair dispatch
            self.workers.append((conn, channel))

    def start(self, handler):
        import threading

        def worker_thread(channel, worker_id):
            def callback(ch, method, props, body):
                try:
                    handler(json.loads(body), worker_id)
                    ch.basic_ack(delivery_tag=method.delivery_tag)
                except Exception as e:
                    ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)

            channel.basic_consume(
                queue=self.queue_name,
                on_message_callback=callback
            )
            channel.start_consuming()

        for i, (conn, channel) in enumerate(self.workers):
            t = threading.Thread(target=worker_thread, args=(channel, i))
            t.daemon = True
            t.start()
```

### 2. Publish/Subscribe with Filtering

```python
class EventBus:
    def __init__(self, channel):
        self.channel = channel
        self.exchange = 'event-bus'

        channel.exchange_declare(
            exchange=self.exchange,
            exchange_type='topic',
            durable=True
        )

    def publish(self, event_type, payload):
        """Publish event with type as routing key"""
        self.channel.basic_publish(
            exchange=self.exchange,
            routing_key=event_type,
            body=json.dumps({
                'type': event_type,
                'payload': payload,
                'timestamp': datetime.now().isoformat()
            }),
            properties=pika.BasicProperties(delivery_mode=2)
        )

    def subscribe(self, patterns, handler, queue_name=None):
        """Subscribe to events matching patterns"""
        if queue_name is None:
            queue_name = f'subscriber-{uuid.uuid4()}'

        self.channel.queue_declare(queue=queue_name, durable=True)

        for pattern in patterns:
            self.channel.queue_bind(
                exchange=self.exchange,
                queue=queue_name,
                routing_key=pattern
            )

        def callback(ch, method, props, body):
            event = json.loads(body)
            handler(event)
            ch.basic_ack(delivery_tag=method.delivery_tag)

        self.channel.basic_consume(
            queue=queue_name,
            on_message_callback=callback
        )


# Usage
bus = EventBus(channel)

# Publisher
bus.publish('order.created', {'order_id': 123})
bus.publish('order.shipped', {'order_id': 123})
bus.publish('user.registered', {'user_id': 456})

# Subscriber - all order events
bus.subscribe(['order.*'], handle_order_events, 'order-handler')

# Subscriber - specific events
bus.subscribe(['order.created', 'user.registered'], handle_new_entities)
```

### 3. Message Deduplication

```python
class DeduplicatingPublisher:
    def __init__(self, channel, redis_client, ttl=3600):
        self.channel = channel
        self.redis = redis_client
        self.ttl = ttl

    def publish(self, exchange, routing_key, message, dedup_key=None):
        if dedup_key is None:
            dedup_key = hashlib.md5(
                json.dumps(message, sort_keys=True).encode()
            ).hexdigest()

        redis_key = f'dedup:{exchange}:{routing_key}:{dedup_key}'

        # Check if already published
        if self.redis.exists(redis_key):
            return False  # Duplicate

        # Publish and mark as sent
        self.channel.basic_publish(
            exchange=exchange,
            routing_key=routing_key,
            body=json.dumps(message),
            properties=pika.BasicProperties(
                delivery_mode=2,
                message_id=dedup_key
            )
        )

        self.redis.setex(redis_key, self.ttl, '1')
        return True


class DeduplicatingConsumer:
    def __init__(self, channel, redis_client, ttl=86400):
        self.channel = channel
        self.redis = redis_client
        self.ttl = ttl

    def consume(self, queue, handler):
        def callback(ch, method, props, body):
            message_id = props.message_id or hashlib.md5(body).hexdigest()
            redis_key = f'processed:{queue}:{message_id}'

            # Check if already processed
            if self.redis.exists(redis_key):
                ch.basic_ack(delivery_tag=method.delivery_tag)
                return

            try:
                handler(json.loads(body))
                self.redis.setex(redis_key, self.ttl, '1')
                ch.basic_ack(delivery_tag=method.delivery_tag)
            except Exception as e:
                ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)

        self.channel.basic_consume(queue=queue, on_message_callback=callback)
```

## High Availability Setup

### Clustering

```bash
# rabbitmq.conf on each node
cluster_formation.peer_discovery_backend = rabbit_peer_discovery_classic_config
cluster_formation.classic_config.nodes.1 = rabbit@node1
cluster_formation.classic_config.nodes.2 = rabbit@node2
cluster_formation.classic_config.nodes.3 = rabbit@node3

# Cluster name
cluster_name = production-cluster
```

### Quorum Queues (Recommended for HA)

```python
# Quorum queues for high availability
channel.queue_declare(
    queue='ha-queue',
    durable=True,
    arguments={
        'x-queue-type': 'quorum',
        'x-quorum-initial-group-size': 3,  # Replicas
        'x-delivery-limit': 5               # Max redeliveries
    }
)
```

### Mirrored Queues (Legacy)

```python
# Classic mirrored queue (legacy, use quorum queues instead)
channel.queue_declare(
    queue='mirrored-queue',
    durable=True,
    arguments={
        'x-ha-policy': 'all',  # Mirror to all nodes
        'x-ha-sync-mode': 'automatic'
    }
)
```

## Performance Optimization

### 1. Connection Pooling

```python
from queue import Queue
import threading

class ConnectionPool:
    def __init__(self, params, size=10):
        self.params = params
        self.pool = Queue(maxsize=size)
        self.lock = threading.Lock()

        for _ in range(size):
            conn = pika.BlockingConnection(params)
            self.pool.put(conn)

    def get_connection(self):
        return self.pool.get()

    def return_connection(self, conn):
        if conn.is_open:
            self.pool.put(conn)
        else:
            # Replace broken connection
            new_conn = pika.BlockingConnection(self.params)
            self.pool.put(new_conn)

    def __enter__(self):
        self.conn = self.get_connection()
        return self.conn

    def __exit__(self, *args):
        self.return_connection(self.conn)


# Usage
pool = ConnectionPool(connection_params, size=10)

with pool as conn:
    channel = conn.channel()
    channel.basic_publish(...)
```

### 2. Batch Publishing

```python
def publish_batch(channel, exchange, routing_key, messages):
    """Publish multiple messages efficiently"""
    for message in messages:
        channel.basic_publish(
            exchange=exchange,
            routing_key=routing_key,
            body=json.dumps(message),
            properties=pika.BasicProperties(delivery_mode=2)
        )

    # Single flush for all messages
    channel.connection.process_data_events()
```

### 3. Prefetch Tuning

```python
# Low prefetch for slow consumers (fair distribution)
channel.basic_qos(prefetch_count=1)

# Higher prefetch for fast consumers (better throughput)
channel.basic_qos(prefetch_count=50)

# Global prefetch (across all consumers on channel)
channel.basic_qos(prefetch_count=100, global_qos=True)
```

## Monitoring

### Key Metrics

```python
import requests

def get_rabbitmq_metrics(host='localhost', port=15672, user='guest', password='guest'):
    base_url = f'http://{host}:{port}/api'
    auth = (user, password)

    # Overview
    overview = requests.get(f'{base_url}/overview', auth=auth).json()

    # Queue metrics
    queues = requests.get(f'{base_url}/queues', auth=auth).json()

    metrics = {
        'cluster_name': overview['cluster_name'],
        'rabbitmq_version': overview['rabbitmq_version'],
        'message_stats': {
            'publish_rate': overview.get('message_stats', {}).get('publish_details', {}).get('rate', 0),
            'deliver_rate': overview.get('message_stats', {}).get('deliver_details', {}).get('rate', 0),
            'ack_rate': overview.get('message_stats', {}).get('ack_details', {}).get('rate', 0)
        },
        'queues': [{
            'name': q['name'],
            'messages': q['messages'],
            'messages_ready': q['messages_ready'],
            'messages_unacked': q['messages_unacknowledged'],
            'consumers': q['consumers'],
            'memory': q['memory']
        } for q in queues]
    }

    return metrics
```

### Health Checks

```python
def rabbitmq_health_check(channel):
    checks = {
        'connection': False,
        'channel': False,
        'can_publish': False,
        'can_consume': False
    }

    try:
        # Check connection
        checks['connection'] = channel.connection.is_open

        # Check channel
        checks['channel'] = channel.is_open

        # Test publish
        test_queue = 'health-check-queue'
        channel.queue_declare(queue=test_queue, auto_delete=True)
        channel.basic_publish(
            exchange='',
            routing_key=test_queue,
            body='health-check'
        )
        checks['can_publish'] = True

        # Test consume
        method, _, body = channel.basic_get(test_queue)
        if body == b'health-check':
            checks['can_consume'] = True
            channel.basic_ack(method.delivery_tag)

    except Exception as e:
        print(f'Health check failed: {e}')

    return checks
```

## Common Pitfalls to Avoid

1. **Not Using Acknowledgments**: Always use manual acks for reliable processing
2. **Ignoring Connection Recovery**: Implement automatic reconnection logic
3. **Single Connection Bottleneck**: Use connection pooling for high throughput
4. **Unbounded Queues**: Set `x-max-length` and `x-overflow` policies
5. **Missing DLQ**: Always configure dead letter handling
6. **Not Setting Prefetch**: Without prefetch, one consumer may hog all messages
7. **Forgetting Message Persistence**: Use `delivery_mode=2` for durability
8. **Too Many Queues**: Each queue has memory overhead
9. **Not Monitoring Queue Depth**: Alert on growing queues
10. **Blocking in Callbacks**: Process messages asynchronously for throughput

## Security Best Practices

```ini
# rabbitmq.conf

# Disable guest user remote access
loopback_users.guest = true

# TLS configuration
listeners.ssl.default = 5671
ssl_options.cacertfile = /path/to/ca_certificate.pem
ssl_options.certfile = /path/to/server_certificate.pem
ssl_options.keyfile = /path/to/server_key.pem
ssl_options.verify = verify_peer
ssl_options.fail_if_no_peer_cert = true

# Strong ciphers only
ssl_options.versions.1 = tlsv1.2
ssl_options.versions.2 = tlsv1.3

# Authentication backend
auth_backends.1 = rabbit_auth_backend_internal

# Limits
channel_max = 128
connection_max = 1000
```

```python
# Secure client connection
ssl_context = ssl.create_default_context(cafile='/path/to/ca_certificate.pem')
ssl_context.load_cert_chain(
    '/path/to/client_certificate.pem',
    '/path/to/client_key.pem'
)

connection_params = pika.ConnectionParameters(
    host='rabbitmq.example.com',
    port=5671,
    credentials=pika.PlainCredentials('app_user', 'secure_password'),
    ssl_options=pika.SSLOptions(ssl_context)
)
```

## Use Cases

### When to Use RabbitMQ
- **Task queues**: Background job processing
- **Request-reply patterns**: RPC over messaging
- **Complex routing**: Topic/header-based message routing
- **Priority processing**: Messages with different priorities
- **Delayed messages**: Scheduled task execution
- **Microservices communication**: Service decoupling
- **Load leveling**: Buffer between fast producers and slow consumers
- **Multi-protocol support**: AMQP, MQTT, STOMP

### When NOT to Use RabbitMQ
- High-throughput event streaming (consider Kafka)
- Long-term message storage (consider Kafka)
- Simple pub/sub without routing (consider Redis)
- When you need message replay (consider Kafka)
- Real-time analytics on streams (consider Kafka)

## Useful Tools and Libraries

- **pika**: Python client (official)
- **amqplib**: Node.js client
- **RabbitMQ Java Client**: Java client
- **Bunny**: Ruby client
- **php-amqplib**: PHP client
- **RabbitMQ Management Plugin**: Web UI
- **rabbitmqctl**: CLI management tool
- **rabbitmq-perf-test**: Performance testing
- **Shovel Plugin**: Message transfer between brokers
- **Federation Plugin**: Cross-datacenter replication
- **Delayed Message Plugin**: Native delayed messaging
