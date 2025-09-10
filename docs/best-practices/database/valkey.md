# Valkey Best Practices

## Overview

Valkey is an open-source, high-performance key-value store that originated as a fork of Redis 7.2.4. It maintains full compatibility with Redis APIs while being community-driven and licensed under BSD-3. Valkey serves as a drop-in replacement for Redis with enhanced features and community governance.

## Official Documentation
- [Valkey Official Website](https://valkey.io/)
- [Valkey GitHub Repository](https://github.com/valkey-io/valkey)
- [Valkey Documentation](https://valkey.io/docs/)
- [Migration from Redis](https://valkey.io/docs/migration/)

## Key Features
- **Redis Compatible**: Full API compatibility with Redis 7.2.4+
- **High Performance**: In-memory data store with optional persistence
- **Data Structures**: Strings, hashes, lists, sets, sorted sets, streams, HyperLogLog
- **Clustering**: Built-in clustering for horizontal scaling
- **Replication**: Master-replica architecture for high availability
- **Pub/Sub**: Real-time messaging capabilities
- **Transactions**: MULTI/EXEC command support
- **Lua Scripting**: Server-side scripting for complex operations
- **Community-Driven**: Open governance model with Linux Foundation support

## Installation

### Docker
```bash
# Run Valkey container
docker run -d --name valkey -p 6379:6379 valkey/valkey:latest

# Run with persistence
docker run -d --name valkey \
  -p 6379:6379 \
  -v valkey-data:/data \
  valkey/valkey:latest valkey-server --save 60 1 --loglevel warning
```

### Package Managers
```bash
# macOS (Homebrew)
brew tap valkey-io/valkey
brew install valkey

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install valkey

# From source
git clone https://github.com/valkey-io/valkey.git
cd valkey
make
make install
```

## Connection Management

### Node.js Client
```javascript
// Using ioredis (fully compatible with Valkey)
const Redis = require('ioredis');

class ValkeyClient {
  constructor(config = {}) {
    this.client = new Redis({
      host: config.host || 'localhost',
      port: config.port || 6379,
      password: config.password,
      db: config.db || 0,
      retryStrategy: (times) => {
        const delay = Math.min(times * 50, 2000);
        return delay;
      },
      reconnectOnError: (err) => {
        const targetError = 'READONLY';
        if (err.message.includes(targetError)) {
          return true;
        }
        return false;
      }
    });

    this.client.on('error', (err) => {
      console.error('Valkey Client Error:', err);
    });

    this.client.on('connect', () => {
      console.log('Connected to Valkey');
    });
  }

  async get(key) {
    return await this.client.get(key);
  }

  async set(key, value, ttl = null) {
    if (ttl) {
      return await this.client.set(key, value, 'EX', ttl);
    }
    return await this.client.set(key, value);
  }

  async del(key) {
    return await this.client.del(key);
  }

  async exists(key) {
    return await this.client.exists(key);
  }

  async expire(key, seconds) {
    return await this.client.expire(key, seconds);
  }

  async close() {
    await this.client.quit();
  }
}

// Connection pool for production
class ValkeyPool {
  constructor(config = {}) {
    this.pool = new Redis.Cluster([
      {
        host: config.host || 'localhost',
        port: config.port || 6379
      }
    ], {
      redisOptions: {
        password: config.password,
        tls: config.tls || {}
      },
      clusterRetryStrategy: (times) => {
        return Math.min(100 * times, 2000);
      }
    });
  }

  async execute(command, ...args) {
    return await this.pool[command](...args);
  }
}
```

### Python Client
```python
# Using redis-py (fully compatible with Valkey)
import redis
from redis import ConnectionPool
from redis.sentinel import Sentinel
import json
from typing import Optional, Any, Dict, List
from datetime import timedelta

class ValkeyClient:
    """Production-ready Valkey client with connection pooling"""
    
    def __init__(self, host='localhost', port=6379, 
                 password=None, db=0, max_connections=50):
        self.pool = ConnectionPool(
            host=host,
            port=port,
            password=password,
            db=db,
            max_connections=max_connections,
            socket_keepalive=True,
            socket_keepalive_options={
                1: 1,  # TCP_KEEPIDLE
                2: 3,  # TCP_KEEPINTVL
                3: 5   # TCP_KEEPCNT
            }
        )
        self.client = redis.Redis(connection_pool=self.pool)
    
    def get(self, key: str) -> Optional[str]:
        """Get value by key"""
        value = self.client.get(key)
        return value.decode('utf-8') if value else None
    
    def set(self, key: str, value: Any, 
            ttl: Optional[int] = None) -> bool:
        """Set key-value with optional TTL"""
        if isinstance(value, (dict, list)):
            value = json.dumps(value)
        
        if ttl:
            return self.client.setex(key, ttl, value)
        return self.client.set(key, value)
    
    def get_json(self, key: str) -> Optional[Dict]:
        """Get and deserialize JSON value"""
        value = self.get(key)
        return json.loads(value) if value else None
    
    def set_json(self, key: str, value: Dict, 
                 ttl: Optional[int] = None) -> bool:
        """Serialize and set JSON value"""
        return self.set(key, json.dumps(value), ttl)
    
    def delete(self, *keys: str) -> int:
        """Delete one or more keys"""
        return self.client.delete(*keys)
    
    def exists(self, *keys: str) -> int:
        """Check if keys exist"""
        return self.client.exists(*keys)
    
    def expire(self, key: str, seconds: int) -> bool:
        """Set expiration on key"""
        return self.client.expire(key, seconds)
    
    def ttl(self, key: str) -> int:
        """Get time to live for key"""
        return self.client.ttl(key)
    
    def incr(self, key: str, amount: int = 1) -> int:
        """Increment counter"""
        return self.client.incr(key, amount)
    
    def decr(self, key: str, amount: int = 1) -> int:
        """Decrement counter"""
        return self.client.decr(key, amount)
    
    # Hash operations
    def hset(self, name: str, key: str, value: Any) -> int:
        """Set hash field"""
        if isinstance(value, (dict, list)):
            value = json.dumps(value)
        return self.client.hset(name, key, value)
    
    def hget(self, name: str, key: str) -> Optional[str]:
        """Get hash field"""
        value = self.client.hget(name, key)
        return value.decode('utf-8') if value else None
    
    def hgetall(self, name: str) -> Dict[str, str]:
        """Get all hash fields"""
        return {k.decode('utf-8'): v.decode('utf-8') 
                for k, v in self.client.hgetall(name).items()}
    
    # List operations
    def lpush(self, key: str, *values: Any) -> int:
        """Push values to list head"""
        return self.client.lpush(key, *values)
    
    def rpush(self, key: str, *values: Any) -> int:
        """Push values to list tail"""
        return self.client.rpush(key, *values)
    
    def lpop(self, key: str) -> Optional[str]:
        """Pop from list head"""
        value = self.client.lpop(key)
        return value.decode('utf-8') if value else None
    
    def lrange(self, key: str, start: int, end: int) -> List[str]:
        """Get list range"""
        return [v.decode('utf-8') for v in 
                self.client.lrange(key, start, end)]
    
    # Set operations
    def sadd(self, key: str, *values: Any) -> int:
        """Add members to set"""
        return self.client.sadd(key, *values)
    
    def srem(self, key: str, *values: Any) -> int:
        """Remove members from set"""
        return self.client.srem(key, *values)
    
    def smembers(self, key: str) -> set:
        """Get all set members"""
        return {v.decode('utf-8') for v in self.client.smembers(key)}
    
    def sismember(self, key: str, value: Any) -> bool:
        """Check if value is in set"""
        return self.client.sismember(key, value)
    
    # Sorted set operations
    def zadd(self, key: str, mapping: Dict[str, float]) -> int:
        """Add members to sorted set"""
        return self.client.zadd(key, mapping)
    
    def zrange(self, key: str, start: int, end: int, 
               withscores: bool = False) -> List:
        """Get sorted set range"""
        return self.client.zrange(key, start, end, withscores=withscores)
    
    def zrem(self, key: str, *values: Any) -> int:
        """Remove members from sorted set"""
        return self.client.zrem(key, *values)
    
    # Pub/Sub
    def publish(self, channel: str, message: Any) -> int:
        """Publish message to channel"""
        if isinstance(message, (dict, list)):
            message = json.dumps(message)
        return self.client.publish(channel, message)
    
    def subscribe(self, *channels: str):
        """Subscribe to channels"""
        pubsub = self.client.pubsub()
        pubsub.subscribe(*channels)
        return pubsub
    
    # Transactions
    def pipeline(self, transaction: bool = True):
        """Create pipeline for batch operations"""
        return self.client.pipeline(transaction=transaction)
    
    def close(self):
        """Close connection pool"""
        self.pool.disconnect()

# Sentinel support for high availability
class ValkeySentinel:
    """Valkey with Sentinel for automatic failover"""
    
    def __init__(self, sentinels: List[tuple], service_name: str,
                 password: Optional[str] = None):
        self.sentinel = Sentinel(sentinels, socket_timeout=0.1)
        self.service_name = service_name
        self.password = password
    
    def get_master(self):
        """Get master connection"""
        return self.sentinel.master_for(
            self.service_name,
            socket_timeout=0.1,
            password=self.password
        )
    
    def get_slave(self):
        """Get slave connection for read operations"""
        return self.sentinel.slave_for(
            self.service_name,
            socket_timeout=0.1,
            password=self.password
        )
```

## Caching Patterns

### Cache-Aside Pattern
```python
class CacheAsidePattern:
    """Lazy loading cache pattern"""
    
    def __init__(self, valkey_client, database):
        self.cache = valkey_client
        self.db = database
        self.default_ttl = 3600  # 1 hour
    
    async def get_user(self, user_id: str):
        # Try cache first
        cache_key = f"user:{user_id}"
        cached = self.cache.get_json(cache_key)
        
        if cached:
            print(f"Cache hit for {cache_key}")
            return cached
        
        # Cache miss - fetch from database
        print(f"Cache miss for {cache_key}")
        user = await self.db.get_user(user_id)
        
        if user:
            # Store in cache
            self.cache.set_json(cache_key, user, self.default_ttl)
        
        return user
    
    async def update_user(self, user_id: str, data: dict):
        # Update database
        await self.db.update_user(user_id, data)
        
        # Invalidate cache
        cache_key = f"user:{user_id}"
        self.cache.delete(cache_key)
        
        return True
```

### Write-Through Pattern
```python
class WriteThroughPattern:
    """Write to cache and database simultaneously"""
    
    def __init__(self, valkey_client, database):
        self.cache = valkey_client
        self.db = database
        self.default_ttl = 3600
    
    async def save_data(self, key: str, data: dict):
        # Write to database
        await self.db.save(key, data)
        
        # Write to cache
        cache_key = f"data:{key}"
        self.cache.set_json(cache_key, data, self.default_ttl)
        
        return True
    
    async def get_data(self, key: str):
        cache_key = f"data:{key}"
        
        # Try cache first
        cached = self.cache.get_json(cache_key)
        if cached:
            return cached
        
        # Fallback to database
        data = await self.db.get(key)
        if data:
            self.cache.set_json(cache_key, data, self.default_ttl)
        
        return data
```

### Cache Warming
```python
class CacheWarmer:
    """Preload frequently accessed data"""
    
    def __init__(self, valkey_client, database):
        self.cache = valkey_client
        self.db = database
    
    async def warm_cache(self):
        """Preload hot data into cache"""
        # Get frequently accessed items
        hot_items = await self.db.get_hot_items(limit=1000)
        
        pipeline = self.cache.pipeline()
        
        for item in hot_items:
            cache_key = f"item:{item['id']}"
            pipeline.set(cache_key, json.dumps(item), ex=7200)
        
        # Execute all commands at once
        pipeline.execute()
        
        print(f"Warmed cache with {len(hot_items)} items")
```

## Session Management

### Session Store Implementation
```javascript
class SessionStore {
  constructor(valkeyClient) {
    this.client = valkeyClient;
    this.prefix = 'session:';
    this.ttl = 3600; // 1 hour default
  }

  async create(userId, data = {}) {
    const sessionId = this.generateSessionId();
    const sessionData = {
      userId,
      createdAt: Date.now(),
      lastActivity: Date.now(),
      ...data
    };

    const key = `${this.prefix}${sessionId}`;
    await this.client.set(
      key,
      JSON.stringify(sessionData),
      this.ttl
    );

    return sessionId;
  }

  async get(sessionId) {
    const key = `${this.prefix}${sessionId}`;
    const data = await this.client.get(key);

    if (!data) {
      return null;
    }

    const session = JSON.parse(data);
    
    // Update last activity
    session.lastActivity = Date.now();
    await this.client.set(
      key,
      JSON.stringify(session),
      this.ttl
    );

    return session;
  }

  async destroy(sessionId) {
    const key = `${this.prefix}${sessionId}`;
    return await this.client.del(key);
  }

  async extend(sessionId, additionalTime = 3600) {
    const key = `${this.prefix}${sessionId}`;
    return await this.client.expire(key, this.ttl + additionalTime);
  }

  generateSessionId() {
    return require('crypto')
      .randomBytes(32)
      .toString('hex');
  }
}

// Express middleware
function valkeySession(valkeyClient) {
  const store = new SessionStore(valkeyClient);

  return async (req, res, next) => {
    const sessionId = req.cookies.sessionId;

    if (sessionId) {
      req.session = await store.get(sessionId);
    }

    if (!req.session) {
      const newSessionId = await store.create(null);
      res.cookie('sessionId', newSessionId, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 3600000 // 1 hour
      });
      req.session = { sessionId: newSessionId };
    }

    next();
  };
}
```

## Rate Limiting

### Token Bucket Algorithm
```python
class RateLimiter:
    """Token bucket rate limiting with Valkey"""
    
    def __init__(self, valkey_client, max_tokens=10, 
                 refill_rate=1, refill_interval=1):
        self.cache = valkey_client
        self.max_tokens = max_tokens
        self.refill_rate = refill_rate
        self.refill_interval = refill_interval
    
    def is_allowed(self, identifier: str) -> bool:
        """Check if request is allowed"""
        key = f"rate_limit:{identifier}"
        
        # Lua script for atomic operation
        lua_script = """
        local key = KEYS[1]
        local max_tokens = tonumber(ARGV[1])
        local refill_rate = tonumber(ARGV[2])
        local refill_interval = tonumber(ARGV[3])
        local now = tonumber(ARGV[4])
        
        local bucket = redis.call('HMGET', key, 'tokens', 'last_refill')
        local tokens = tonumber(bucket[1]) or max_tokens
        local last_refill = tonumber(bucket[2]) or now
        
        -- Calculate tokens to add
        local elapsed = now - last_refill
        local tokens_to_add = math.floor(elapsed / refill_interval) * refill_rate
        tokens = math.min(tokens + tokens_to_add, max_tokens)
        
        if tokens >= 1 then
            tokens = tokens - 1
            redis.call('HMSET', key, 
                'tokens', tokens,
                'last_refill', now)
            redis.call('EXPIRE', key, 3600)
            return 1
        else
            return 0
        end
        """
        
        result = self.cache.client.eval(
            lua_script,
            1,
            key,
            self.max_tokens,
            self.refill_rate,
            self.refill_interval,
            int(time.time())
        )
        
        return bool(result)

# Sliding window rate limiter
class SlidingWindowRateLimiter:
    """Sliding window rate limiting"""
    
    def __init__(self, valkey_client, window_size=60, max_requests=100):
        self.cache = valkey_client
        self.window_size = window_size  # seconds
        self.max_requests = max_requests
    
    def is_allowed(self, identifier: str) -> tuple[bool, dict]:
        """Check if request is allowed and return stats"""
        key = f"sliding_window:{identifier}"
        now = time.time()
        window_start = now - self.window_size
        
        pipeline = self.cache.pipeline()
        
        # Remove old entries
        pipeline.zremrangebyscore(key, 0, window_start)
        
        # Count requests in window
        pipeline.zcard(key)
        
        # Add current request
        pipeline.zadd(key, {str(uuid.uuid4()): now})
        
        # Set expiration
        pipeline.expire(key, self.window_size + 1)
        
        results = pipeline.execute()
        request_count = results[1]
        
        allowed = request_count < self.max_requests
        
        return allowed, {
            'allowed': allowed,
            'requests': request_count,
            'limit': self.max_requests,
            'remaining': max(0, self.max_requests - request_count),
            'reset_at': int(now + self.window_size)
        }
```

## Pub/Sub Messaging

### Real-time Notifications
```javascript
class NotificationService {
  constructor(valkeyClient) {
    this.publisher = valkeyClient;
    this.subscriber = valkeyClient.duplicate();
    this.handlers = new Map();
  }

  async subscribe(channel, handler) {
    if (!this.handlers.has(channel)) {
      this.handlers.set(channel, new Set());
      await this.subscriber.subscribe(channel);
    }
    
    this.handlers.get(channel).add(handler);

    this.subscriber.on('message', (receivedChannel, message) => {
      if (receivedChannel === channel) {
        const handlers = this.handlers.get(channel);
        if (handlers) {
          const data = JSON.parse(message);
          handlers.forEach(handler => handler(data));
        }
      }
    });
  }

  async unsubscribe(channel, handler) {
    const handlers = this.handlers.get(channel);
    if (handlers) {
      handlers.delete(handler);
      if (handlers.size === 0) {
        this.handlers.delete(channel);
        await this.subscriber.unsubscribe(channel);
      }
    }
  }

  async publish(channel, data) {
    const message = JSON.stringify(data);
    return await this.publisher.publish(channel, message);
  }

  async broadcast(event, data) {
    const channel = `broadcast:${event}`;
    return await this.publish(channel, {
      event,
      data,
      timestamp: Date.now()
    });
  }
}

// Usage example
const notifications = new NotificationService(valkeyClient);

// Subscribe to user notifications
await notifications.subscribe('user:123:notifications', (data) => {
  console.log('Received notification:', data);
});

// Publish notification
await notifications.publish('user:123:notifications', {
  type: 'message',
  from: 'user:456',
  content: 'Hello!'
});
```

## Distributed Locking

### Redlock Algorithm Implementation
```python
import time
import uuid
from typing import Optional, List

class DistributedLock:
    """Distributed locking with Valkey"""
    
    def __init__(self, valkey_clients: List, resource: str, 
                 ttl: int = 10000):
        self.clients = valkey_clients
        self.resource = resource
        self.ttl = ttl  # milliseconds
        self.lock_id = str(uuid.uuid4())
        self.quorum = len(clients) // 2 + 1
    
    def acquire(self, retry_times: int = 3, 
                retry_delay: float = 0.2) -> bool:
        """Acquire distributed lock"""
        for attempt in range(retry_times):
            start_time = time.time() * 1000
            locked_count = 0
            
            # Try to acquire lock on all instances
            for client in self.clients:
                if self._acquire_single(client):
                    locked_count += 1
            
            # Calculate elapsed time
            elapsed = (time.time() * 1000) - start_time
            validity_time = self.ttl - elapsed
            
            # Check if we have quorum and time
            if locked_count >= self.quorum and validity_time > 0:
                return True
            else:
                # Release all locks and retry
                self._release_all()
                time.sleep(retry_delay)
        
        return False
    
    def _acquire_single(self, client) -> bool:
        """Acquire lock on single instance"""
        try:
            result = client.set(
                f"lock:{self.resource}",
                self.lock_id,
                nx=True,
                px=self.ttl
            )
            return result is True
        except Exception:
            return False
    
    def release(self) -> bool:
        """Release distributed lock"""
        return self._release_all()
    
    def _release_all(self) -> bool:
        """Release lock on all instances"""
        lua_script = """
        if redis.call("get", KEYS[1]) == ARGV[1] then
            return redis.call("del", KEYS[1])
        else
            return 0
        end
        """
        
        released_count = 0
        for client in self.clients:
            try:
                result = client.eval(
                    lua_script,
                    1,
                    f"lock:{self.resource}",
                    self.lock_id
                )
                if result:
                    released_count += 1
            except Exception:
                pass
        
        return released_count >= self.quorum
    
    def __enter__(self):
        if not self.acquire():
            raise Exception("Failed to acquire lock")
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.release()

# Usage with context manager
with DistributedLock(valkey_clients, "critical_resource"):
    # Critical section
    perform_critical_operation()
```

## Data Structures Best Practices

### HyperLogLog for Cardinality
```python
class UniqueVisitorCounter:
    """Count unique visitors using HyperLogLog"""
    
    def __init__(self, valkey_client):
        self.cache = valkey_client
    
    def add_visitor(self, page: str, visitor_id: str):
        """Add visitor to page counter"""
        key = f"visitors:{page}:{datetime.now().strftime('%Y-%m-%d')}"
        return self.cache.client.pfadd(key, visitor_id)
    
    def get_unique_count(self, page: str, date: str = None):
        """Get unique visitor count"""
        if not date:
            date = datetime.now().strftime('%Y-%m-%d')
        
        key = f"visitors:{page}:{date}"
        return self.cache.client.pfcount(key)
    
    def merge_counts(self, pages: List[str], date: str):
        """Merge counts from multiple pages"""
        keys = [f"visitors:{page}:{date}" for page in pages]
        dest_key = f"visitors:merged:{date}"
        
        self.cache.client.pfmerge(dest_key, *keys)
        return self.cache.client.pfcount(dest_key)
```

### Streams for Event Sourcing
```javascript
class EventStream {
  constructor(valkeyClient, streamName) {
    this.client = valkeyClient;
    this.streamName = streamName;
  }

  async append(eventType, data) {
    const event = {
      type: eventType,
      data: JSON.stringify(data),
      timestamp: Date.now()
    };

    return await this.client.xadd(
      this.streamName,
      '*',
      ...Object.entries(event).flat()
    );
  }

  async read(lastId = '0', count = 100) {
    const entries = await this.client.xrange(
      this.streamName,
      lastId,
      '+',
      'COUNT',
      count
    );

    return entries.map(([id, fields]) => ({
      id,
      type: fields[1],
      data: JSON.parse(fields[3]),
      timestamp: parseInt(fields[5])
    }));
  }

  async consume(consumerGroup, consumer, callback) {
    // Create consumer group
    try {
      await this.client.xgroup(
        'CREATE',
        this.streamName,
        consumerGroup,
        '$',
        'MKSTREAM'
      );
    } catch (err) {
      // Group already exists
    }

    // Consume messages
    while (true) {
      const messages = await this.client.xreadgroup(
        'GROUP',
        consumerGroup,
        consumer,
        'BLOCK',
        1000,
        'COUNT',
        10,
        'STREAMS',
        this.streamName,
        '>'
      );

      if (messages) {
        for (const [stream, entries] of messages) {
          for (const [id, fields] of entries) {
            const event = {
              id,
              type: fields[1],
              data: JSON.parse(fields[3]),
              timestamp: parseInt(fields[5])
            };

            await callback(event);
            
            // Acknowledge message
            await this.client.xack(
              this.streamName,
              consumerGroup,
              id
            );
          }
        }
      }
    }
  }
}
```

## Performance Optimization

### Pipeline for Batch Operations
```python
def batch_operations_example(valkey_client):
    """Optimize multiple operations with pipelining"""
    
    # Without pipeline - multiple round trips
    # DON'T DO THIS
    for i in range(1000):
        valkey_client.set(f"key:{i}", f"value:{i}")
    
    # With pipeline - single round trip
    # DO THIS INSTEAD
    pipeline = valkey_client.pipeline()
    for i in range(1000):
        pipeline.set(f"key:{i}", f"value:{i}")
    pipeline.execute()
    
    # Pipeline with transaction
    pipeline = valkey_client.pipeline(transaction=True)
    pipeline.multi()
    pipeline.incr('counter')
    pipeline.incr('counter')
    pipeline.incr('counter')
    results = pipeline.execute()
```

### Memory Optimization
```python
class MemoryOptimizedCache:
    """Memory-efficient caching strategies"""
    
    def __init__(self, valkey_client):
        self.cache = valkey_client
    
    def set_with_compression(self, key: str, data: dict):
        """Compress large values"""
        import zlib
        import pickle
        
        serialized = pickle.dumps(data)
        
        # Compress if larger than 1KB
        if len(serialized) > 1024:
            compressed = zlib.compress(serialized)
            self.cache.client.set(f"{key}:compressed", compressed)
            self.cache.client.set(f"{key}:meta", "compressed")
        else:
            self.cache.set(key, serialized)
    
    def get_with_decompression(self, key: str):
        """Decompress values if needed"""
        import zlib
        import pickle
        
        meta = self.cache.get(f"{key}:meta")
        
        if meta == "compressed":
            compressed = self.cache.client.get(f"{key}:compressed")
            if compressed:
                serialized = zlib.decompress(compressed)
                return pickle.loads(serialized)
        else:
            serialized = self.cache.client.get(key)
            if serialized:
                return pickle.loads(serialized)
        
        return None
    
    def implement_lru_eviction(self):
        """Configure LRU eviction policy"""
        # Set in valkey.conf or via CONFIG SET
        self.cache.client.config_set('maxmemory', '1gb')
        self.cache.client.config_set('maxmemory-policy', 'allkeys-lru')
```

## Clustering and High Availability

### Cluster Configuration
```python
class ValkeyCluster:
    """Valkey cluster management"""
    
    def __init__(self, startup_nodes):
        from rediscluster import RedisCluster
        
        self.cluster = RedisCluster(
            startup_nodes=startup_nodes,
            decode_responses=True,
            skip_full_coverage_check=True,
            max_connections_per_node=50
        )
    
    def get_node_info(self):
        """Get cluster node information"""
        return self.cluster.cluster_info()
    
    def get_slots_distribution(self):
        """Get slot distribution across nodes"""
        return self.cluster.cluster_slots()
    
    def resharding_safe_operation(self, operation, *args, **kwargs):
        """Execute operation safely during resharding"""
        max_retries = 3
        retry_delay = 0.1
        
        for attempt in range(max_retries):
            try:
                return operation(*args, **kwargs)
            except Exception as e:
                if "MOVED" in str(e) or "ASK" in str(e):
                    time.sleep(retry_delay)
                    continue
                raise
        
        raise Exception("Operation failed after retries")
```

## Monitoring and Debugging

### Performance Monitoring
```python
class ValkeyMonitor:
    """Monitor Valkey performance and health"""
    
    def __init__(self, valkey_client):
        self.client = valkey_client
    
    def get_info(self, section: Optional[str] = None):
        """Get server information"""
        return self.client.client.info(section)
    
    def get_memory_stats(self):
        """Get memory usage statistics"""
        info = self.get_info('memory')
        return {
            'used_memory': info.get('used_memory_human'),
            'used_memory_rss': info.get('used_memory_rss_human'),
            'used_memory_peak': info.get('used_memory_peak_human'),
            'mem_fragmentation_ratio': info.get('mem_fragmentation_ratio'),
            'maxmemory': info.get('maxmemory_human')
        }
    
    def get_performance_stats(self):
        """Get performance metrics"""
        info = self.get_info('stats')
        return {
            'total_connections': info.get('total_connections_received'),
            'total_commands': info.get('total_commands_processed'),
            'ops_per_sec': info.get('instantaneous_ops_per_sec'),
            'keyspace_hits': info.get('keyspace_hits'),
            'keyspace_misses': info.get('keyspace_misses'),
            'hit_rate': self._calculate_hit_rate(info)
        }
    
    def _calculate_hit_rate(self, stats):
        """Calculate cache hit rate"""
        hits = stats.get('keyspace_hits', 0)
        misses = stats.get('keyspace_misses', 0)
        total = hits + misses
        
        if total == 0:
            return 0
        
        return round((hits / total) * 100, 2)
    
    def slow_log(self, count: int = 10):
        """Get slow queries log"""
        return self.client.client.slowlog_get(count)
    
    def monitor_commands(self, duration: int = 10):
        """Monitor commands in real-time"""
        import threading
        
        commands = []
        
        def capture():
            pubsub = self.client.client.pubsub()
            pubsub.psubscribe('__key*__:*')
            
            start_time = time.time()
            while time.time() - start_time < duration:
                message = pubsub.get_message(timeout=1)
                if message and message['type'] == 'pmessage':
                    commands.append({
                        'time': time.time(),
                        'channel': message['channel'],
                        'data': message['data']
                    })
        
        thread = threading.Thread(target=capture)
        thread.start()
        thread.join()
        
        return commands
```

## Security Best Practices

### Authentication and ACL
```python
class SecureValkeyClient:
    """Secure Valkey configuration"""
    
    def __init__(self, host='localhost', port=6379):
        import ssl
        
        # TLS/SSL configuration
        ssl_keyfile = '/path/to/client-key.pem'
        ssl_certfile = '/path/to/client-cert.pem'
        ssl_ca_certs = '/path/to/ca-cert.pem'
        
        self.client = redis.Redis(
            host=host,
            port=port,
            ssl=True,
            ssl_keyfile=ssl_keyfile,
            ssl_certfile=ssl_certfile,
            ssl_cert_reqs='required',
            ssl_ca_certs=ssl_ca_certs,
            ssl_check_hostname=False,
            password='strong_password_here',
            decode_responses=True
        )
    
    def create_user(self, username: str, password: str, 
                   permissions: List[str]):
        """Create user with ACL"""
        acl_rules = [
            f'on',  # Enable user
            f'+{perm}' for perm in permissions
        ]
        
        self.client.acl_setuser(
            username,
            passwords=[f'+{password}'],
            categories=acl_rules
        )
    
    def rotate_password(self, username: str, 
                       old_password: str, new_password: str):
        """Rotate user password"""
        # Remove old password
        self.client.acl_setuser(
            username,
            passwords=[f'-{old_password}']
        )
        
        # Add new password
        self.client.acl_setuser(
            username,
            passwords=[f'+{new_password}']
        )
```

## Migration from Redis

### Compatibility Check
```bash
# Check Redis version compatibility
valkey-cli INFO server | grep redis_version

# Test existing Redis applications
# Simply change connection string from Redis to Valkey
# No code changes required for Redis 7.2.4 compatible apps
```

### Data Migration
```python
class RedisToValkeyMigrator:
    """Migrate data from Redis to Valkey"""
    
    def __init__(self, redis_client, valkey_client):
        self.source = redis_client
        self.target = valkey_client
    
    def migrate_all(self, batch_size=1000):
        """Migrate all keys"""
        cursor = 0
        migrated = 0
        
        while True:
            cursor, keys = self.source.scan(
                cursor, 
                count=batch_size
            )
            
            if keys:
                self._migrate_batch(keys)
                migrated += len(keys)
                print(f"Migrated {migrated} keys")
            
            if cursor == 0:
                break
        
        return migrated
    
    def _migrate_batch(self, keys):
        """Migrate batch of keys"""
        source_pipe = self.source.pipeline()
        target_pipe = self.target.pipeline()
        
        # Get all values and TTLs
        for key in keys:
            source_pipe.dump(key)
            source_pipe.ttl(key)
        
        results = source_pipe.execute()
        
        # Restore in target
        for i in range(0, len(results), 2):
            key = keys[i // 2]
            value = results[i]
            ttl = results[i + 1]
            
            if value:
                # Convert TTL to milliseconds
                ttl_ms = ttl * 1000 if ttl > 0 else 0
                target_pipe.restore(key, ttl_ms, value)
        
        target_pipe.execute()
```

## Common Pitfalls

1. **Connection Pool Exhaustion**: Always use connection pooling
2. **Missing Error Handling**: Implement retry logic and circuit breakers
3. **No TTL on Keys**: Set appropriate expiration times
4. **Blocking Operations**: Use async operations for long-running commands
5. **Large Values**: Compress or chunk large data
6. **Hot Keys**: Distribute load across multiple keys
7. **No Monitoring**: Implement comprehensive monitoring
8. **Ignoring Persistence**: Configure AOF or RDB based on requirements
9. **Single Point of Failure**: Use clustering or sentinel for HA
10. **No Rate Limiting**: Implement rate limiting for public APIs

## Production Checklist

- [ ] Connection pooling configured
- [ ] Authentication and ACL enabled
- [ ] TLS/SSL encryption enabled
- [ ] Persistence strategy defined (AOF/RDB)
- [ ] Memory limits and eviction policy set
- [ ] Monitoring and alerting configured
- [ ] Backup and recovery procedures documented
- [ ] Rate limiting implemented
- [ ] Circuit breaker pattern implemented
- [ ] Load testing performed
- [ ] Clustering or Sentinel configured for HA
- [ ] Security hardening applied
- [ ] Performance tuning completed
- [ ] Documentation updated