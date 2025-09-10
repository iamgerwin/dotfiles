# DuckDB Best Practices

## Official Documentation
- **DuckDB Documentation**: https://duckdb.org/docs/
- **DuckDB GitHub**: https://github.com/duckdb/duckdb
- **DuckDB Blog**: https://duckdb.org/news/
- **SQL Reference**: https://duckdb.org/docs/sql/introduction

## Overview
DuckDB is an in-process SQL OLAP database management system designed for analytical workloads. Think of it as "SQLite for analytics" - it's embedded, requires no server, and is optimized for analytical queries.

## Core Best Practices

### 1. Installation and Setup

#### Python
```python
import duckdb

# In-memory database
con = duckdb.connect()

# Persistent database
con = duckdb.connect('analytics.duckdb')

# Read-only mode
con = duckdb.connect('analytics.duckdb', read_only=True)

# Configuration options
con = duckdb.connect(config={
    'max_memory': '4GB',
    'threads': 4,
    'default_order': 'ASC'
})
```

#### Node.js
```javascript
const duckdb = require('duckdb');

// Create database
const db = new duckdb.Database(':memory:');
// or
const db = new duckdb.Database('analytics.duckdb');

// Create connection
const connection = db.connect();

// Async operations
connection.all('SELECT * FROM users', (err, res) => {
  if (err) throw err;
  console.log(res);
});
```

### 2. Data Import and Export

#### CSV Files
```sql
-- Import CSV
CREATE TABLE sales AS 
SELECT * FROM read_csv_auto('sales_data.csv');

-- With options
CREATE TABLE customers AS 
SELECT * FROM read_csv_auto('customers.csv', 
    header=true,
    delimiter=',',
    quote='"',
    escape='"',
    dateformat='%Y-%m-%d'
);

-- Export to CSV
COPY sales TO 'output.csv' (HEADER, DELIMITER ',');

-- Direct query from CSV
SELECT * FROM 'data.csv' WHERE amount > 1000;
```

#### Parquet Files
```sql
-- Read Parquet
CREATE TABLE events AS 
SELECT * FROM read_parquet('events.parquet');

-- Query multiple Parquet files
SELECT * FROM read_parquet('data/*.parquet')
WHERE date >= '2024-01-01';

-- Export to Parquet
COPY sales TO 'sales.parquet' (FORMAT PARQUET, COMPRESSION SNAPPY);
```

#### JSON Files
```sql
-- Read JSON
CREATE TABLE users AS 
SELECT * FROM read_json_auto('users.json');

-- Read JSON Lines
SELECT * FROM read_ndjson_auto('events.jsonl');

-- Export to JSON
COPY users TO 'output.json' (FORMAT JSON);
```

### 3. Working with DataFrames

#### Python Integration
```python
import duckdb
import pandas as pd
import polars as pl

con = duckdb.connect()

# Pandas DataFrame
df_pandas = pd.DataFrame({
    'id': [1, 2, 3],
    'name': ['Alice', 'Bob', 'Charlie'],
    'score': [95, 87, 92]
})

# Query Pandas directly
result = con.execute("SELECT * FROM df_pandas WHERE score > 90").fetchdf()

# Register DataFrame as table
con.register('students', df_pandas)
con.execute("CREATE TABLE students_copy AS SELECT * FROM students")

# Polars DataFrame
df_polars = pl.DataFrame({
    'id': [1, 2, 3],
    'value': [100, 200, 300]
})

# Query Polars directly
result = con.execute("SELECT * FROM df_polars").pl()

# Arrow tables
import pyarrow as pa
arrow_table = pa.table({'col1': [1, 2, 3]})
result = con.execute("SELECT * FROM arrow_table").fetch_arrow_table()
```

### 4. Advanced SQL Features

#### Window Functions
```sql
-- Running totals
SELECT 
    date,
    amount,
    SUM(amount) OVER (ORDER BY date) as running_total,
    AVG(amount) OVER (
        ORDER BY date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as moving_avg_7_days
FROM sales;

-- Ranking
SELECT 
    product_id,
    sale_date,
    amount,
    ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY amount DESC) as rank_in_product,
    DENSE_RANK() OVER (ORDER BY amount DESC) as overall_rank,
    PERCENT_RANK() OVER (ORDER BY amount) as percentile
FROM sales;

-- Lead/Lag
SELECT 
    date,
    value,
    LAG(value, 1) OVER (ORDER BY date) as previous_value,
    LEAD(value, 1) OVER (ORDER BY date) as next_value,
    value - LAG(value, 1) OVER (ORDER BY date) as change
FROM metrics;
```

#### Common Table Expressions (CTEs)
```sql
WITH RECURSIVE 
-- Regular CTE
monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', order_date) as month,
        SUM(amount) as total
    FROM orders
    GROUP BY 1
),
-- Recursive CTE for hierarchy
org_hierarchy AS (
    -- Anchor: top-level employees
    SELECT employee_id, name, manager_id, 0 as level
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive: employees under managers
    SELECT e.employee_id, e.name, e.manager_id, h.level + 1
    FROM employees e
    JOIN org_hierarchy h ON e.manager_id = h.employee_id
)
SELECT * FROM org_hierarchy ORDER BY level, name;
```

#### PIVOT and UNPIVOT
```sql
-- PIVOT: rows to columns
PIVOT sales
ON product_category
USING SUM(amount) as total, COUNT(*) as count
GROUP BY year, month;

-- Manual pivot with CASE
SELECT 
    year,
    SUM(CASE WHEN month = 1 THEN amount END) as jan,
    SUM(CASE WHEN month = 2 THEN amount END) as feb,
    SUM(CASE WHEN month = 3 THEN amount END) as mar
FROM sales
GROUP BY year;

-- UNPIVOT: columns to rows
UNPIVOT monthly_data
ON jan, feb, mar, apr, may, jun
INTO
    NAME month
    VALUE revenue;
```

### 5. Performance Optimization

#### Indexes
```sql
-- Create index
CREATE INDEX idx_user_email ON users(email);

-- Composite index
CREATE INDEX idx_order_customer_date ON orders(customer_id, order_date);

-- Unique index
CREATE UNIQUE INDEX idx_product_sku ON products(sku);

-- Check indexes
SELECT * FROM duckdb_indexes;

-- Analyze table for statistics
ANALYZE users;
```

#### Query Optimization
```python
# Use prepared statements
con.execute("PREPARE query AS SELECT * FROM users WHERE id = $1")
result = con.execute("EXECUTE query(123)").fetchall()

# Batch operations
con.executemany(
    "INSERT INTO users (name, email) VALUES (?, ?)",
    [("Alice", "alice@example.com"), ("Bob", "bob@example.com")]
)

# Enable profiling
con.execute("PRAGMA enable_profiling")
con.execute("PRAGMA profiling_output='profile.json'")

# Your query
con.execute("SELECT * FROM large_table")

# Examine query plan
explain = con.execute("EXPLAIN SELECT * FROM users WHERE age > 25").fetchall()
```

### 6. Data Types and Functions

#### Working with Dates
```sql
-- Date arithmetic
SELECT 
    current_date,
    current_date + INTERVAL '7 days',
    current_date - INTERVAL '1 month',
    DATE_DIFF('day', '2024-01-01', current_date) as days_since_year_start,
    DATE_TRUNC('month', current_date) as month_start,
    EXTRACT(dow FROM current_date) as day_of_week
FROM users;

-- Date generation
SELECT * FROM generate_series(
    DATE '2024-01-01',
    DATE '2024-12-31',
    INTERVAL '1 day'
) as date;
```

#### String Functions
```sql
-- String manipulation
SELECT 
    CONCAT(first_name, ' ', last_name) as full_name,
    UPPER(email) as email_upper,
    SUBSTRING(phone FROM 1 FOR 3) as area_code,
    REGEXP_MATCHES(email, '([^@]+)@([^.]+)') as email_parts,
    STRING_AGG(tag, ', ' ORDER BY tag) as tags
FROM users
GROUP BY user_id;

-- Pattern matching
SELECT * FROM products
WHERE name SIMILAR TO '%(phone|tablet)%'
   OR description ~* 'wireless';  -- Case-insensitive regex
```

#### Arrays and Lists
```sql
-- Array operations
SELECT 
    LIST_VALUE(1, 2, 3) as numbers,
    ['a', 'b', 'c'] as letters,
    ARRAY_LENGTH([1, 2, 3, 4]) as len,
    LIST_CONTAINS([1, 2, 3], 2) as has_two,
    LIST_EXTRACT([10, 20, 30], 2) as second_element,
    LIST_AGG(product_id) as product_ids
FROM orders
GROUP BY customer_id;

-- Unnesting arrays
SELECT 
    user_id,
    UNNEST(tags) as tag
FROM users;
```

### 7. Integration Patterns

#### ETL Pipeline
```python
import duckdb
import pandas as pd
from datetime import datetime

class DataPipeline:
    def __init__(self, db_path=':memory:'):
        self.con = duckdb.connect(db_path)
        
    def extract_from_csv(self, file_path):
        """Extract data from CSV files"""
        return self.con.execute(f"""
            SELECT * FROM read_csv_auto('{file_path}')
        """).fetchdf()
    
    def transform_data(self, df):
        """Transform data using DuckDB SQL"""
        self.con.register('raw_data', df)
        
        return self.con.execute("""
            SELECT 
                customer_id,
                DATE_TRUNC('month', order_date) as month,
                SUM(amount) as monthly_total,
                COUNT(*) as order_count,
                AVG(amount) as avg_order_value
            FROM raw_data
            WHERE order_date >= '2024-01-01'
            GROUP BY customer_id, month
        """).fetchdf()
    
    def load_to_parquet(self, df, output_path):
        """Load transformed data to Parquet"""
        self.con.register('transformed', df)
        self.con.execute(f"""
            COPY transformed 
            TO '{output_path}' 
            (FORMAT PARQUET, COMPRESSION SNAPPY)
        """)

# Usage
pipeline = DataPipeline()
raw_data = pipeline.extract_from_csv('sales.csv')
transformed = pipeline.transform_data(raw_data)
pipeline.load_to_parquet(transformed, 'output/monthly_sales.parquet')
```

#### Real-time Analytics
```python
import duckdb
from datetime import datetime, timedelta
import threading
import time

class RealTimeAnalytics:
    def __init__(self):
        self.con = duckdb.connect(':memory:')
        self.setup_tables()
        
    def setup_tables(self):
        self.con.execute("""
            CREATE TABLE events (
                timestamp TIMESTAMP,
                user_id INTEGER,
                event_type VARCHAR,
                value DOUBLE
            )
        """)
        
    def ingest_event(self, event):
        """Ingest single event"""
        self.con.execute("""
            INSERT INTO events VALUES (?, ?, ?, ?)
        """, [event['timestamp'], event['user_id'], 
              event['event_type'], event['value']])
        
    def get_metrics(self, window_minutes=5):
        """Get real-time metrics"""
        cutoff = datetime.now() - timedelta(minutes=window_minutes)
        
        return self.con.execute(f"""
            SELECT 
                event_type,
                COUNT(*) as count,
                AVG(value) as avg_value,
                MIN(value) as min_value,
                MAX(value) as max_value,
                PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY value) as median
            FROM events
            WHERE timestamp >= '{cutoff}'
            GROUP BY event_type
        """).fetchdf()
```

### 8. Database Management

#### Backup and Restore
```python
# Export entire database
con.execute("EXPORT DATABASE 'backup_directory' (FORMAT PARQUET)")

# Import database
con.execute("IMPORT DATABASE 'backup_directory'")

# Table-specific backup
con.execute("COPY users TO 'users_backup.parquet' (FORMAT PARQUET)")

# Incremental backup with timestamp
from datetime import datetime
timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
con.execute(f"COPY users TO 'backups/users_{timestamp}.parquet' (FORMAT PARQUET)")
```

#### Schema Management
```sql
-- Create schema
CREATE SCHEMA analytics;

-- Use schema
SET search_path TO analytics;

-- Create tables in schema
CREATE TABLE analytics.daily_metrics (
    date DATE PRIMARY KEY,
    revenue DECIMAL(10,2),
    users INTEGER,
    conversion_rate DOUBLE
);

-- View schemas
SELECT * FROM information_schema.schemata;

-- View tables
SELECT * FROM information_schema.tables;

-- View columns
SELECT * FROM information_schema.columns 
WHERE table_name = 'users';
```

## Advanced Use Cases

### 1. Time Series Analysis
```sql
-- Generate time series with gaps filled
WITH RECURSIVE dates AS (
    SELECT DATE '2024-01-01' as date
    UNION ALL
    SELECT date + INTERVAL '1 day'
    FROM dates
    WHERE date < DATE '2024-12-31'
),
daily_sales AS (
    SELECT 
        DATE_TRUNC('day', order_date) as date,
        SUM(amount) as total
    FROM orders
    GROUP BY 1
)
SELECT 
    d.date,
    COALESCE(s.total, 0) as sales,
    AVG(COALESCE(s.total, 0)) OVER (
        ORDER BY d.date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as moving_avg_7d
FROM dates d
LEFT JOIN daily_sales s ON d.date = s.date;
```

### 2. Geospatial Queries
```sql
-- Install spatial extension
INSTALL spatial;
LOAD spatial;

-- Create points
SELECT ST_Point(longitude, latitude) as location
FROM locations;

-- Distance calculations
SELECT 
    a.name as from_location,
    b.name as to_location,
    ST_Distance(
        ST_Point(a.lon, a.lat),
        ST_Point(b.lon, b.lat)
    ) as distance
FROM locations a, locations b
WHERE a.id != b.id;

-- Find points within radius
SELECT * FROM locations
WHERE ST_DWithin(
    ST_Point(longitude, latitude),
    ST_Point(-73.935242, 40.730610),  -- NYC coordinates
    1000  -- 1km radius
);
```

### 3. Machine Learning Integration
```python
import duckdb
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor

con = duckdb.connect()

# Prepare features
features_df = con.execute("""
    SELECT 
        customer_age,
        total_purchases,
        avg_order_value,
        days_since_registration,
        category_preferences,
        lifetime_value as target
    FROM customer_features
""").fetchdf()

# Train model
X = features_df.drop('target', axis=1)
y = features_df['target']
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

model = RandomForestRegressor()
model.fit(X_train, y_train)

# Score new data
new_customers = con.execute("SELECT * FROM new_customers").fetchdf()
predictions = model.predict(new_customers)

# Store predictions
results_df = new_customers.copy()
results_df['predicted_ltv'] = predictions
con.register('predictions', results_df)
con.execute("CREATE TABLE customer_predictions AS SELECT * FROM predictions")
```

## Performance Tips

### 1. Memory Management
```python
# Set memory limit
con = duckdb.connect(config={'max_memory': '8GB'})

# Monitor memory usage
memory_info = con.execute("SELECT * FROM pragma_database_size()").fetchall()

# Clear cache
con.execute("PRAGMA memory_limit='1GB'")
con.execute("PRAGMA threads=4")
```

### 2. Parallel Processing
```python
# Enable parallel execution
con.execute("SET threads TO 8")

# Parallel CSV reading
con.execute("""
    CREATE TABLE large_dataset AS
    SELECT * FROM read_csv_auto('data/*.csv', parallel=true)
""")

# Parallel query execution
con.execute("SET enable_parallel_hash_join=true")
```

### 3. Query Optimization
```sql
-- Use column statistics
ANALYZE TABLE sales;

-- Avoid SELECT *
-- Bad
SELECT * FROM large_table;

-- Good
SELECT col1, col2, col3 FROM large_table;

-- Push down filters
-- Bad
SELECT * FROM (
    SELECT * FROM large_table
) WHERE category = 'electronics';

-- Good
SELECT * FROM large_table
WHERE category = 'electronics';

-- Use appropriate JOIN types
EXPLAIN ANALYZE
SELECT * FROM orders o
INNER JOIN customers c ON o.customer_id = c.id
WHERE c.country = 'USA';
```

## Common Pitfalls to Avoid

1. **Not Using Column Store**: Leverage DuckDB's columnar storage
2. **Loading All Data**: Use filters and projections early
3. **Ignoring Data Types**: Use appropriate types for better compression
4. **Not Using Prepared Statements**: Prepare frequently used queries
5. **Excessive Memory**: Set appropriate memory limits
6. **Not Using Transactions**: Batch operations in transactions
7. **Ignoring Statistics**: Run ANALYZE on tables
8. **Not Using Extensions**: Install relevant extensions
9. **String Comparisons**: Use appropriate collations
10. **Not Closing Connections**: Properly close connections

## Useful Extensions

```sql
-- Install extensions
INSTALL httpfs;  -- Read from S3/HTTP
INSTALL json;    -- JSON functions
INSTALL spatial; -- Geospatial functions
INSTALL tpch;    -- TPC-H benchmark
INSTALL tpcds;   -- TPC-DS benchmark
INSTALL excel;   -- Excel file support
INSTALL aws;     -- AWS integration
INSTALL azure;   -- Azure integration

-- Load extensions
LOAD httpfs;
LOAD json;

-- Use extensions
SELECT * FROM read_parquet('s3://bucket/file.parquet');
```

## Integration Libraries

- **duckdb**: Official Python package
- **duckdb-node**: Official Node.js package
- **duckdb-r**: R package
- **duckdb-java**: Java JDBC driver
- **duckdb-rust**: Rust bindings
- **duckdb-go**: Go driver
- **duckdb-julia**: Julia package
- **duckdb-wasm**: WebAssembly version