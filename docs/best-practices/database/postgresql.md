# PostgreSQL Best Practices

## Official Documentation
- **PostgreSQL Documentation**: https://www.postgresql.org/docs
- **PostgreSQL Wiki**: https://wiki.postgresql.org
- **PostgreSQL Tutorial**: https://www.postgresqltutorial.com
- **Performance Tuning**: https://wiki.postgresql.org/wiki/Performance_Optimization

## Database Structure

```
database/
├── migrations/
│   ├── 001_create_users_table.sql
│   ├── 002_create_products_table.sql
│   └── 003_add_indexes.sql
├── seeds/
│   ├── users.sql
│   └── products.sql
├── functions/
│   ├── triggers.sql
│   └── stored_procedures.sql
├── views/
│   └── reporting_views.sql
└── backups/
    └── backup_script.sh
```

## Core Best Practices

### 1. Database Design Principles

```sql
-- Use appropriate data types
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    metadata JSONB,
    search_vector TSVECTOR
);

-- Use constraints for data integrity
ALTER TABLE users
    ADD CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'),
    ADD CONSTRAINT username_length CHECK (LENGTH(username) >= 3);

-- Create appropriate indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at DESC);
CREATE INDEX idx_users_metadata ON users USING GIN(metadata);
CREATE INDEX idx_users_search ON users USING GIN(search_vector);
```

### 2. Normalization and Denormalization

```sql
-- Normalized design (3NF)
CREATE TABLE authors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE
);

CREATE TABLE books (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    isbn VARCHAR(13) UNIQUE,
    published_date DATE,
    author_id INTEGER REFERENCES authors(id)
);

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE book_categories (
    book_id INTEGER REFERENCES books(id),
    category_id INTEGER REFERENCES categories(id),
    PRIMARY KEY (book_id, category_id)
);

-- Denormalized view for performance
CREATE MATERIALIZED VIEW book_details AS
SELECT 
    b.id,
    b.title,
    b.isbn,
    b.published_date,
    a.name AS author_name,
    a.email AS author_email,
    ARRAY_AGG(c.name) AS categories
FROM books b
JOIN authors a ON b.author_id = a.id
LEFT JOIN book_categories bc ON b.id = bc.book_id
LEFT JOIN categories c ON bc.category_id = c.category_id
GROUP BY b.id, b.title, b.isbn, b.published_date, a.name, a.email;

CREATE UNIQUE INDEX ON book_details(id);
```

### 3. Indexing Strategies

```sql
-- B-tree indexes (default) for equality and range queries
CREATE INDEX idx_users_created_at ON users(created_at);

-- Partial indexes for filtered queries
CREATE INDEX idx_active_users ON users(email) WHERE is_active = true;

-- Composite indexes for multi-column queries
CREATE INDEX idx_users_status_created ON users(is_active, created_at DESC);

-- GIN indexes for JSONB
CREATE INDEX idx_users_metadata_gin ON users USING GIN(metadata);

-- GiST indexes for geometric/geographic data
CREATE INDEX idx_locations_point ON locations USING GIST(point);

-- BRIN indexes for large tables with natural ordering
CREATE INDEX idx_logs_created_at_brin ON logs USING BRIN(created_at);

-- Expression indexes
CREATE INDEX idx_users_lower_email ON users(LOWER(email));

-- Covering indexes (PostgreSQL 11+)
CREATE INDEX idx_orders_user_date ON orders(user_id, order_date) 
INCLUDE (total_amount, status);
```

### 4. Query Optimization

```sql
-- Use EXPLAIN ANALYZE to understand query plans
EXPLAIN (ANALYZE, BUFFERS) 
SELECT u.*, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.created_at >= '2024-01-01'
GROUP BY u.id;

-- Optimize JOIN queries
-- Good: Join on indexed columns
SELECT o.*, u.name
FROM orders o
INNER JOIN users u ON o.user_id = u.id
WHERE o.status = 'pending';

-- Use CTEs for complex queries
WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        SUM(total_amount) AS total_sales,
        COUNT(*) AS order_count
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY DATE_TRUNC('month', order_date)
),
average_sales AS (
    SELECT AVG(total_sales) AS avg_monthly_sales
    FROM monthly_sales
)
SELECT 
    ms.*,
    ms.total_sales - av.avg_monthly_sales AS variance_from_avg
FROM monthly_sales ms
CROSS JOIN average_sales av
ORDER BY ms.month DESC;

-- Use window functions for analytics
SELECT 
    user_id,
    order_date,
    total_amount,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_date DESC) AS order_rank,
    SUM(total_amount) OVER (PARTITION BY user_id ORDER BY order_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
    LAG(total_amount, 1) OVER (PARTITION BY user_id ORDER BY order_date) AS previous_order_amount
FROM orders;
```

### 5. Partitioning for Large Tables

```sql
-- Range partitioning by date
CREATE TABLE orders (
    id BIGSERIAL,
    user_id INTEGER,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10, 2),
    status VARCHAR(20)
) PARTITION BY RANGE (order_date);

-- Create partitions
CREATE TABLE orders_2024_q1 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE orders_2024_q2 PARTITION OF orders
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

-- Automatic partition creation with pg_partman
CREATE TABLE orders_template (LIKE orders INCLUDING ALL);

SELECT partman.create_parent(
    p_parent_table => 'public.orders',
    p_control => 'order_date',
    p_type => 'range',
    p_interval => 'monthly'
);
```

### 6. Transaction Management

```sql
-- Use transactions for data consistency
BEGIN;

UPDATE accounts 
SET balance = balance - 100 
WHERE id = 1;

UPDATE accounts 
SET balance = balance + 100 
WHERE id = 2;

-- Check constraint
IF (SELECT balance FROM accounts WHERE id = 1) < 0 THEN
    ROLLBACK;
ELSE
    COMMIT;
END IF;

-- Use savepoints for partial rollbacks
BEGIN;
UPDATE users SET email = 'new@email.com' WHERE id = 1;
SAVEPOINT sp1;
UPDATE users SET status = 'inactive' WHERE id = 1;
-- If second update fails, rollback to savepoint
ROLLBACK TO sp1;
COMMIT;

-- Set appropriate isolation levels
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN;
-- Your queries here
COMMIT;
```

### 7. Stored Procedures and Functions

```sql
-- Function for business logic
CREATE OR REPLACE FUNCTION calculate_order_total(order_id INTEGER)
RETURNS DECIMAL AS $$
DECLARE
    subtotal DECIMAL;
    tax_rate DECIMAL := 0.08;
    shipping DECIMAL := 10.00;
BEGIN
    SELECT SUM(quantity * unit_price) INTO subtotal
    FROM order_items
    WHERE order_id = calculate_order_total.order_id;
    
    RETURN subtotal + (subtotal * tax_rate) + shipping;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for audit logging
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (
        table_name,
        operation,
        user_name,
        changed_at,
        old_data,
        new_data
    ) VALUES (
        TG_TABLE_NAME,
        TG_OP,
        current_user,
        CURRENT_TIMESTAMP,
        to_jsonb(OLD),
        to_jsonb(NEW)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
```

### 8. Performance Tuning

```sql
-- Configuration parameters (postgresql.conf)
-- Memory settings
shared_buffers = 256MB  # 25% of RAM
effective_cache_size = 1GB  # 50-75% of RAM
work_mem = 4MB  # RAM / (max_connections * 2)
maintenance_work_mem = 64MB

-- Connection pooling
max_connections = 100
max_prepared_transactions = 0

-- Write performance
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100

-- Query planning
random_page_cost = 1.1  # For SSD
effective_io_concurrency = 200  # For SSD

-- Monitoring slow queries
log_min_duration_statement = 1000  # Log queries slower than 1 second
```

### 9. Backup and Recovery

```bash
#!/bin/bash
# backup.sh - Automated backup script

DB_NAME="production"
BACKUP_DIR="/backups/postgresql"
DATE=$(date +%Y%m%d_%H%M%S)

# Full backup
pg_dump -h localhost -U postgres -d $DB_NAME -F custom -f "$BACKUP_DIR/full_$DATE.dump"

# Backup with compression
pg_dump -h localhost -U postgres -d $DB_NAME | gzip > "$BACKUP_DIR/full_$DATE.sql.gz"

# Backup specific tables
pg_dump -h localhost -U postgres -d $DB_NAME -t users -t orders -f "$BACKUP_DIR/partial_$DATE.sql"

# Point-in-time recovery setup
# In postgresql.conf:
# wal_level = replica
# archive_mode = on
# archive_command = 'cp %p /archive/%f'

# Restore from backup
pg_restore -h localhost -U postgres -d $DB_NAME -F custom "$BACKUP_DIR/full_$DATE.dump"
```

### 10. Security Best Practices

```sql
-- Role-based access control
CREATE ROLE app_read_only;
GRANT CONNECT ON DATABASE production TO app_read_only;
GRANT USAGE ON SCHEMA public TO app_read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_read_only;

CREATE ROLE app_write;
GRANT CONNECT ON DATABASE production TO app_write;
GRANT USAGE ON SCHEMA public TO app_write;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_write;

-- Row-level security
CREATE POLICY user_isolation ON users
    FOR ALL
    TO application
    USING (user_id = current_setting('app.current_user_id')::INT);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Encrypt sensitive data
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Store encrypted password
INSERT INTO users (email, password_hash)
VALUES ('user@example.com', crypt('password123', gen_salt('bf')));

-- Verify password
SELECT * FROM users 
WHERE email = 'user@example.com' 
AND password_hash = crypt('password123', password_hash);
```

### 11. JSON/JSONB Operations

```sql
-- JSONB storage and queries
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    attributes JSONB
);

-- Insert JSON data
INSERT INTO products (name, attributes) VALUES 
    ('Laptop', '{"brand": "Dell", "ram": "16GB", "storage": {"type": "SSD", "size": "512GB"}}');

-- Query JSON data
SELECT * FROM products 
WHERE attributes @> '{"brand": "Dell"}';

SELECT * FROM products 
WHERE attributes ->> 'ram' = '16GB';

-- Update JSON fields
UPDATE products 
SET attributes = jsonb_set(attributes, '{storage,size}', '"1TB"')
WHERE id = 1;

-- Aggregate JSON data
SELECT jsonb_agg(attributes) 
FROM products 
WHERE attributes ? 'brand';
```

### 12. Full-Text Search

```sql
-- Create text search configuration
CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    title TEXT,
    content TEXT,
    search_vector TSVECTOR
);

-- Create trigger to update search vector
CREATE FUNCTION articles_search_trigger() RETURNS trigger AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.content, '')), 'B');
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER articles_search_update
    BEFORE INSERT OR UPDATE ON articles
    FOR EACH ROW EXECUTE FUNCTION articles_search_trigger();

-- Create GIN index
CREATE INDEX idx_articles_search ON articles USING GIN(search_vector);

-- Perform full-text search
SELECT id, title, 
       ts_rank(search_vector, query) AS rank
FROM articles,
     plainto_tsquery('english', 'postgresql best practices') query
WHERE search_vector @@ query
ORDER BY rank DESC;
```

### Common Pitfalls to Avoid

1. **Not using indexes on foreign keys**
2. **Using SELECT * in production**
3. **Not setting up proper backups**
4. **Ignoring VACUUM and ANALYZE**
5. **Not monitoring slow queries**
6. **Using wrong data types**
7. **Not using connection pooling**
8. **Ignoring transaction isolation levels**
9. **Not planning for scaling**
10. **Storing large BLOBs in database**

### Useful Tools

- **pgAdmin**: GUI administration tool
- **psql**: Command-line interface
- **pg_stat_statements**: Query performance monitoring
- **pgBadger**: Log analyzer
- **pgpool-II**: Connection pooling and load balancing
- **Barman**: Backup and recovery manager
- **pg_repack**: Online table reorganization
- **PostGIS**: Geographic data support