# Redis Best Practices

## Official Documentation
- **Redis Documentation**: https://redis.io/documentation
- **Redis Commands**: https://redis.io/commands
- **Redis University**: https://university.redis.com/
- **Redis Stack**: https://redis.io/docs/stack/

## Architecture Overview
```
Application Layer
    ↓
Redis Client (redis-py, node-redis, Jedis)
    ↓
Connection Pool / Sentinel / Cluster
    ↓
Redis Server(s)
    ├── Primary (Master)
    └── Replicas (Slaves)
```

## Core Best Practices

### 1. Connection Management
```python
# Python with redis-py
import redis
from redis import ConnectionPool

# Connection pool for better performance
pool = ConnectionPool(
    host='localhost',
    port=6379,
    db=0,
    max_connections=50,
    decode_responses=True
)

redis_client = redis.Redis(connection_pool=pool)

# With retry and backoff
from redis.backoff import ExponentialBackoff
from redis.retry import Retry

retry = Retry(ExponentialBackoff(), 3)
redis_client = redis.Redis(
    host='localhost',
    port=6379,
    retry=retry,
    retry_on_error=[ConnectionError, TimeoutError]
)
```

```javascript
// Node.js with node-redis
import { createClient } from 'redis';

const client = createClient({
    url: 'redis://localhost:6379',
    socket: {
        connectTimeout: 5000,
        reconnectStrategy: (retries) => {
            if (retries > 10) return new Error('Too many retries');
            return Math.min(retries * 100, 3000);
        }
    }
});

client.on('error', (err) => console.error('Redis Client Error', err));
client.on('connect', () => console.log('Redis Connected'));
client.on('ready', () => console.log('Redis Ready'));

await client.connect();
```

### 2. Key Naming Conventions
```python
# Use consistent naming patterns
# pattern: object-type:id:field

# Good practices
user_key = "user:1000:profile"
session_key = "session:abc123:data"
cache_key = "cache:products:page:1"
temp_key = "temp:upload:xyz789"

# Namespace separation
namespace = "myapp"
key = f"{namespace}:user:{user_id}"

# Use colons for hierarchy
organization_key = "org:123:dept:456:employee:789"

# Avoid spaces and special characters
# Bad: "user data 123"
# Good: "user:data:123"
```

### 3. Data Structures Usage

#### Strings
```python
# Simple key-value
redis_client.set("user:1:name", "John Doe")
redis_client.get("user:1:name")

# With expiration
redis_client.setex("cache:page:home", 3600, html_content)

# Atomic operations
redis_client.incr("counter:pageviews")
redis_client.incrby("counter:downloads", 5)

# Set if not exists
redis_client.setnx("lock:resource", "locked")

# Multiple operations
redis_client.mset({
    "user:1:name": "John",
    "user:1:email": "john@example.com"
})
```

#### Lists
```python
# Queue implementation
redis_client.lpush("queue:tasks", task_data)
task = redis_client.brpop("queue:tasks", timeout=5)

# Recent items
redis_client.lpush("recent:posts", post_id)
redis_client.ltrim("recent:posts", 0, 99)  # Keep only 100 items

# Message queue with blocking
redis_client.blpop("queue:high", "queue:low", timeout=10)
```

#### Sets
```python
# Unique items
redis_client.sadd("tags:post:123", "python", "redis", "database")
tags = redis_client.smembers("tags:post:123")

# Set operations
redis_client.sinter("users:online", "users:premium")  # Intersection
redis_client.sunion("skills:user:1", "skills:user:2")  # Union
redis_client.sdiff("all:users", "banned:users")  # Difference

# Random selection
winner = redis_client.srandmember("raffle:participants")
```

#### Sorted Sets
```python
# Leaderboard
redis_client.zadd("leaderboard:global", {"player1": 1000, "player2": 950})
top_players = redis_client.zrevrange("leaderboard:global", 0, 9, withscores=True)

# Time-series data
timestamp = int(time.time())
redis_client.zadd("events:user:123", {event_data: timestamp})

# Range queries
redis_client.zrangebyscore("prices", 10, 50)
```

#### Hashes
```python
# User profile
redis_client.hset("user:1000", mapping={
    "name": "John Doe",
    "email": "john@example.com",
    "age": "30"
})

user = redis_client.hgetall("user:1000")

# Incremental updates
redis_client.hincrby("stats:page:home", "views", 1)
```

#### Streams
```python
# Add to stream
redis_client.xadd("mystream", {"temperature": 25, "humidity": 60})

# Read from stream
messages = redis_client.xread({"mystream": "$"}, block=1000)

# Consumer groups
redis_client.xgroup_create("mystream", "mygroup", id="0")
messages = redis_client.xreadgroup(
    "mygroup", "consumer1", 
    {"mystream": ">"}, 
    count=10
)
```

### 4. Caching Patterns

#### Cache-Aside (Lazy Loading)
```python
def get_user(user_id):
    # Try cache first
    cached = redis_client.get(f"user:{user_id}")
    if cached:
        return json.loads(cached)
    
    # Load from database
    user = db.get_user(user_id)
    
    # Store in cache
    redis_client.setex(
        f"user:{user_id}", 
        3600,  # 1 hour TTL
        json.dumps(user)
    )
    
    return user
```

#### Write-Through
```python
def update_user(user_id, data):
    # Update database
    db.update_user(user_id, data)
    
    # Update cache
    redis_client.setex(
        f"user:{user_id}",
        3600,
        json.dumps(data)
    )
```

#### Write-Behind (Async)
```python
def update_user_async(user_id, data):
    # Update cache immediately
    redis_client.setex(f"user:{user_id}", 3600, json.dumps(data))
    
    # Queue database update
    redis_client.lpush("queue:db:updates", json.dumps({
        "action": "update_user",
        "user_id": user_id,
        "data": data
    }))
```

### 5. Pub/Sub Pattern
```python
# Publisher
def publish_event(channel, message):
    redis_client.publish(channel, json.dumps(message))

# Subscriber
def subscribe_to_events():
    pubsub = redis_client.pubsub()
    pubsub.subscribe("events:user:*")
    
    for message in pubsub.listen():
        if message['type'] == 'message':
            data = json.loads(message['data'])
            process_event(data)
```

### 6. Transactions and Pipelines

#### Transactions
```python
def transfer_points(from_user, to_user, amount):
    with redis_client.pipeline() as pipe:
        while True:
            try:
                # Watch for changes
                pipe.watch(f"points:{from_user}")
                
                current = int(pipe.get(f"points:{from_user}") or 0)
                if current < amount:
                    raise ValueError("Insufficient points")
                
                # Start transaction
                pipe.multi()
                pipe.decrby(f"points:{from_user}", amount)
                pipe.incrby(f"points:{to_user}", amount)
                pipe.execute()
                break
            except redis.WatchError:
                continue
```

#### Pipelining for Performance
```python
def bulk_insert(items):
    with redis_client.pipeline() as pipe:
        for item in items:
            pipe.set(f"item:{item['id']}", json.dumps(item))
            pipe.expire(f"item:{item['id']}", 3600)
        
        pipe.execute()
```

### 7. Lua Scripting
```lua
-- rate_limit.lua
local key = KEYS[1]
local limit = tonumber(ARGV[1])
local window = tonumber(ARGV[2])

local current = redis.call('GET', key)
if current == false then
    redis.call('SET', key, 1)
    redis.call('EXPIRE', key, window)
    return 1
elseif tonumber(current) < limit then
    return redis.call('INCR', key)
else
    return 0
end
```

```python
# Load and execute script
script = """
local key = KEYS[1]
local limit = tonumber(ARGV[1])
local window = tonumber(ARGV[2])

local current = redis.call('GET', key)
if current == false then
    redis.call('SET', key, 1)
    redis.call('EXPIRE', key, window)
    return 1
elseif tonumber(current) < limit then
    return redis.call('INCR', key)
else
    return 0
end
"""

rate_limit = redis_client.register_script(script)
allowed = rate_limit(keys=["rate:user:123"], args=[10, 60])
```

## Advanced Patterns

### 1. Distributed Locking
```python
import time
import uuid

class RedisLock:
    def __init__(self, client, key, timeout=10):
        self.client = client
        self.key = key
        self.timeout = timeout
        self.identifier = str(uuid.uuid4())
    
    def acquire(self):
        end = time.time() + self.timeout
        while time.time() < end:
            if self.client.set(self.key, self.identifier, nx=True, ex=self.timeout):
                return True
            time.sleep(0.001)
        return False
    
    def release(self):
        pipe = self.client.pipeline(True)
        while True:
            try:
                pipe.watch(self.key)
                if pipe.get(self.key) == self.identifier:
                    pipe.multi()
                    pipe.delete(self.key)
                    pipe.execute()
                    return True
                pipe.unwatch()
                break
            except redis.WatchError:
                pass
        return False

# Usage
lock = RedisLock(redis_client, "lock:resource:123")
if lock.acquire():
    try:
        # Critical section
        perform_operation()
    finally:
        lock.release()
```

### 2. Session Management
```python
class SessionManager:
    def __init__(self, redis_client, ttl=1800):
        self.redis = redis_client
        self.ttl = ttl
    
    def create_session(self, user_id, data):
        session_id = str(uuid.uuid4())
        session_key = f"session:{session_id}"
        
        session_data = {
            "user_id": user_id,
            "created_at": time.time(),
            **data
        }
        
        self.redis.hset(session_key, mapping=session_data)
        self.redis.expire(session_key, self.ttl)
        
        # Track user sessions
        self.redis.sadd(f"user:sessions:{user_id}", session_id)
        
        return session_id
    
    def get_session(self, session_id):
        session_key = f"session:{session_id}"
        session = self.redis.hgetall(session_key)
        
        if session:
            # Extend TTL on access
            self.redis.expire(session_key, self.ttl)
        
        return session
    
    def destroy_session(self, session_id):
        session_key = f"session:{session_id}"
        session = self.redis.hgetall(session_key)
        
        if session and "user_id" in session:
            self.redis.srem(f"user:sessions:{session['user_id']}", session_id)
        
        self.redis.delete(session_key)
```

### 3. Real-time Analytics
```python
class Analytics:
    def __init__(self, redis_client):
        self.redis = redis_client
    
    def track_event(self, event_type, user_id=None):
        now = datetime.now()
        
        # Hourly counts
        hour_key = f"stats:{event_type}:hour:{now.strftime('%Y%m%d%H')}"
        self.redis.incr(hour_key)
        self.redis.expire(hour_key, 3600 * 25)  # Keep for 25 hours
        
        # Daily unique users
        if user_id:
            day_key = f"stats:{event_type}:users:{now.strftime('%Y%m%d')}"
            self.redis.sadd(day_key, user_id)
            self.redis.expire(day_key, 86400 * 8)  # Keep for 8 days
        
        # Real-time counter
        self.redis.incr(f"stats:{event_type}:total")
    
    def get_stats(self, event_type, date):
        day_key = f"stats:{event_type}:users:{date.strftime('%Y%m%d')}"
        unique_users = self.redis.scard(day_key)
        
        total = self.redis.get(f"stats:{event_type}:total") or 0
        
        return {
            "unique_users": unique_users,
            "total_events": int(total)
        }
```

## Clustering and High Availability

### Redis Sentinel
```python
from redis.sentinel import Sentinel

# Connect to Sentinel
sentinel = Sentinel([
    ('localhost', 26379),
    ('localhost', 26380),
    ('localhost', 26381)
], socket_timeout=0.1)

# Discover master and slaves
master = sentinel.master_for('mymaster', socket_timeout=0.1)
slave = sentinel.slave_for('mymaster', socket_timeout=0.1)

# Automatic failover handled by Sentinel
master.set('key', 'value')
value = slave.get('key')
```

### Redis Cluster
```python
from rediscluster import RedisCluster

startup_nodes = [
    {"host": "127.0.0.1", "port": "7000"},
    {"host": "127.0.0.1", "port": "7001"},
    {"host": "127.0.0.1", "port": "7002"}
]

rc = RedisCluster(
    startup_nodes=startup_nodes,
    decode_responses=True,
    skip_full_coverage_check=True
)

# Cluster automatically handles sharding
rc.set("key", "value")
```

## Performance Optimization

### 1. Memory Optimization
```bash
# redis.conf settings
maxmemory 2gb
maxmemory-policy allkeys-lru

# Enable compression
list-compress-depth 1
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
```

### 2. Persistence Configuration
```bash
# RDB snapshots
save 900 1      # After 900 sec if at least 1 key changed
save 300 10     # After 300 sec if at least 10 keys changed
save 60 10000   # After 60 sec if at least 10000 keys changed

# AOF (Append Only File)
appendonly yes
appendfsync everysec  # Sync every second
```

### 3. Connection Pooling
```python
# Configure appropriate pool size
pool = ConnectionPool(
    host='localhost',
    port=6379,
    max_connections=100,  # Adjust based on load
    socket_keepalive=True,
    socket_keepalive_options={
        1: 1,  # TCP_KEEPIDLE
        2: 3,  # TCP_KEEPINTVL  
        3: 5   # TCP_KEEPCNT
    }
)
```

## Monitoring and Debugging

### Key Metrics
```python
def get_redis_metrics():
    info = redis_client.info()
    
    return {
        "used_memory": info["used_memory_human"],
        "connected_clients": info["connected_clients"],
        "commands_processed": info["total_commands_processed"],
        "keyspace_hits": info["keyspace_hits"],
        "keyspace_misses": info["keyspace_misses"],
        "evicted_keys": info["evicted_keys"],
        "expired_keys": info["expired_keys"]
    }
```

### Slow Query Log
```python
# Get slow queries
slow_queries = redis_client.slowlog_get(10)

for query in slow_queries:
    print(f"Duration: {query['duration']}μs")
    print(f"Command: {' '.join(query['command'])}")
```

## Common Pitfalls to Avoid

1. **Not Setting TTL**: Always set expiration for cache keys
2. **Large Values**: Avoid storing values larger than 512MB
3. **Hot Keys**: Distribute load across multiple keys
4. **Blocking Operations**: Use async operations in production
5. **Not Using Pipelining**: Batch operations for better performance
6. **Wrong Data Structure**: Choose appropriate structure for use case
7. **Not Monitoring Memory**: Track memory usage and eviction
8. **Single Point of Failure**: Use replication or clustering
9. **Not Handling Connection Errors**: Implement retry logic
10. **Using KEYS Command**: Use SCAN instead in production

## Security Best Practices

```bash
# redis.conf
requirepass your_strong_password
bind 127.0.0.1 ::1  # Bind to specific interfaces
protected-mode yes
port 0  # Disable TCP, use Unix socket
unixsocket /var/run/redis/redis.sock
unixsocketperm 770

# Disable dangerous commands
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG "CONFIG_e8f9c6d5a2b3"
```

## Useful Tools and Libraries

- **redis-py**: Python client
- **node-redis**: Node.js client
- **Jedis/Lettuce**: Java clients
- **go-redis**: Go client
- **RedisInsight**: GUI for Redis
- **redis-commander**: Web-based Redis management
- **redis-benchmark**: Performance testing
- **redis-cli**: Command-line interface
- **RediSearch**: Full-text search
- **RedisJSON**: JSON document store
- **RedisTimeSeries**: Time-series data
- **RedisGraph**: Graph database
- **RedisBloom**: Probabilistic data structures