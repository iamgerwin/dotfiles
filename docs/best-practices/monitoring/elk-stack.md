# ELK Stack (Elasticsearch, Logstash, Kibana) Best Practices

## Table of Contents
- [Official Documentation](#official-documentation)
- [Core Concepts](#core-concepts)
- [Project Structure Examples](#project-structure-examples)
- [Configuration Examples](#configuration-examples)
- [Best Practices](#best-practices)
- [Common Patterns](#common-patterns)
- [Do's and Don'ts](#dos-and-donts)
- [Additional Resources](#additional-resources)

## Official Documentation

### Elasticsearch
- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Elasticsearch Best Practices](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-best-practices.html)
- [Mapping and Analysis](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html)

### Logstash
- [Logstash Documentation](https://www.elastic.co/guide/en/logstash/current/index.html)
- [Logstash Configuration](https://www.elastic.co/guide/en/logstash/current/configuration.html)
- [Logstash Plugins](https://www.elastic.co/guide/en/logstash/current/plugins-inputs.html)

### Kibana
- [Kibana Documentation](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Kibana Visualizations](https://www.elastic.co/guide/en/kibana/current/dashboard.html)
- [Kibana Canvas](https://www.elastic.co/guide/en/kibana/current/canvas.html)

### Beats
- [Beats Documentation](https://www.elastic.co/guide/en/beats/libbeat/current/index.html)
- [Filebeat](https://www.elastic.co/guide/en/beats/filebeat/current/index.html)
- [Metricbeat](https://www.elastic.co/guide/en/beats/metricbeat/current/index.html)

## Core Concepts

### Elasticsearch
- **Index**: Collection of documents with similar characteristics
- **Document**: Basic unit of information that can be indexed
- **Mapping**: Schema definition for documents in an index
- **Shard**: Horizontal subdivision of an index
- **Replica**: Copy of a shard for high availability
- **Node**: Single instance of Elasticsearch
- **Cluster**: Collection of nodes working together

### Logstash
- **Input**: Data source (files, network, databases)
- **Filter**: Processing and transformation of data
- **Output**: Destination for processed data
- **Pipeline**: Data processing workflow
- **Codec**: Format for encoding/decoding data

### Kibana
- **Index Pattern**: Definition of which Elasticsearch indices to explore
- **Discover**: Interface for exploring data
- **Visualize**: Create charts and graphs
- **Dashboard**: Collection of visualizations
- **Canvas**: Pixel-perfect data presentation

## Project Structure Examples

### Basic ELK Stack Structure
```
elk-stack/
├── elasticsearch/
│   ├── config/
│   │   ├── elasticsearch.yml
│   │   ├── jvm.options
│   │   └── log4j2.properties
│   ├── data/
│   ├── logs/
│   └── plugins/
├── logstash/
│   ├── config/
│   │   ├── logstash.yml
│   │   ├── jvm.options
│   │   └── log4j2.properties
│   ├── pipeline/
│   │   ├── logstash.conf
│   │   ├── input.conf
│   │   ├── filter.conf
│   │   └── output.conf
│   └── patterns/
│       └── custom-patterns
├── kibana/
│   ├── config/
│   │   └── kibana.yml
│   ├── data/
│   └── plugins/
├── beats/
│   ├── filebeat/
│   │   └── filebeat.yml
│   ├── metricbeat/
│   │   └── metricbeat.yml
│   └── heartbeat/
│       └── heartbeat.yml
├── docker-compose.yml
└── README.md
```

### Production-Ready Structure
```
elk-infrastructure/
├── environments/
│   ├── production/
│   │   ├── elasticsearch/
│   │   │   ├── master.yml
│   │   │   ├── data.yml
│   │   │   └── client.yml
│   │   ├── logstash/
│   │   │   ├── logstash.yml
│   │   │   └── pipelines.yml
│   │   ├── kibana/
│   │   │   └── kibana.yml
│   │   └── beats/
│   ├── staging/
│   └── development/
├── templates/
│   ├── index-templates/
│   ├── component-templates/
│   └── lifecycle-policies/
├── pipelines/
│   ├── application-logs/
│   ├── system-logs/
│   ├── security-logs/
│   └── metrics/
├── dashboards/
│   ├── infrastructure/
│   ├── application/
│   ├── security/
│   └── business/
├── scripts/
│   ├── backup.sh
│   ├── restore.sh
│   ├── reindex.sh
│   └── cleanup.sh
├── monitoring/
│   ├── elasticsearch-exporter/
│   └── logstash-exporter/
└── helm/
    ├── elasticsearch/
    ├── logstash/
    └── kibana/
```

## Configuration Examples

### Elasticsearch Configuration (elasticsearch.yml)
```yaml
# Cluster Configuration
cluster.name: production-elk
node.name: ${HOSTNAME}
node.roles: ["master", "data", "ingest"]

# Network Configuration
network.host: 0.0.0.0
http.port: 9200
transport.port: 9300

# Discovery Configuration
discovery.seed_hosts: ["es-master-1", "es-master-2", "es-master-3"]
cluster.initial_master_nodes: ["es-master-1", "es-master-2", "es-master-3"]

# Path Configuration
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch

# Memory Configuration
bootstrap.memory_lock: true

# Security Configuration
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.client_authentication: required
xpack.security.transport.ssl.keystore.path: elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: elastic-certificates.p12

# HTTP SSL Configuration
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: elastic-certificates.p12

# License Configuration
xpack.license.self_generated.type: basic

# Monitoring Configuration
xpack.monitoring.collection.enabled: true

# Index Lifecycle Management
xpack.ilm.enabled: true
```

### Logstash Configuration (logstash.yml)
```yaml
node.name: logstash-${HOSTNAME}
path.data: /var/lib/logstash
path.logs: /var/log/logstash
path.settings: /etc/logstash

pipeline.workers: 4
pipeline.batch.size: 125
pipeline.batch.delay: 50

queue.type: persisted
queue.max_bytes: 1gb
queue.checkpoint.writes: 1024

dead_letter_queue.enable: true
dead_letter_queue.max_bytes: 1gb

log.level: info
log.format: plain

xpack.monitoring.enabled: true
xpack.monitoring.elasticsearch.hosts: ["http://elasticsearch:9200"]
xpack.monitoring.elasticsearch.username: logstash_system
xpack.monitoring.elasticsearch.password: password

config.reload.automatic: true
config.reload.interval: 3s

pipeline.plugin_classloaders: true
```

### Logstash Pipeline Configuration
```ruby
# input.conf
input {
  beats {
    port => 5044
  }
  
  http {
    port => 8080
    codec => json
  }
  
  tcp {
    port => 5000
    codec => json_lines
  }
  
  file {
    path => "/var/log/application/*.log"
    start_position => "beginning"
    sincedb_path => "/dev/null"
    codec => multiline {
      pattern => "^\d{4}-\d{2}-\d{2}"
      negate => true
      what => "previous"
    }
  }
}

# filter.conf
filter {
  if [fields][log_type] == "nginx" {
    grok {
      match => { 
        "message" => "%{COMBINEDAPACHELOG}" 
      }
    }
    
    date {
      match => [ "timestamp" , "dd/MMM/yyyy:HH:mm:ss Z" ]
    }
    
    mutate {
      convert => { "response" => "integer" }
      convert => { "bytes" => "integer" }
    }
  }
  
  if [fields][log_type] == "application" {
    json {
      source => "message"
    }
    
    date {
      match => [ "timestamp", "ISO8601" ]
    }
    
    if [level] {
      mutate {
        uppercase => [ "level" ]
      }
    }
  }
  
  # Parse Java stack traces
  if [message] =~ /^\s+at / {
    mutate {
      add_tag => [ "stacktrace" ]
    }
  }
  
  # GeoIP enrichment
  if [clientip] {
    geoip {
      source => "clientip"
      target => "geoip"
    }
  }
  
  # User agent parsing
  if [agent] {
    useragent {
      source => "agent"
      target => "useragent"
    }
  }
  
  # Add metadata
  mutate {
    add_field => { 
      "[@metadata][index_name]" => "%{[fields][log_type]}-%{+YYYY.MM.dd}"
    }
  }
}

# output.conf
output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "%{[@metadata][index_name]}"
    template_name => "%{[fields][log_type]}"
    template_pattern => "%{[fields][log_type]}-*"
    template_overwrite => true
  }
  
  # Dead letter queue for failed documents
  if "_grokparsefailure" in [tags] {
    elasticsearch {
      hosts => ["elasticsearch:9200"]
      index => "parse-failures-%{+YYYY.MM.dd}"
    }
  }
  
  # Debug output (remove in production)
  stdout { 
    codec => rubydebug 
  }
}
```

### Kibana Configuration (kibana.yml)
```yaml
server.port: 5601
server.host: "0.0.0.0"
server.name: kibana

elasticsearch.hosts: ["http://elasticsearch:9200"]
elasticsearch.username: kibana_system
elasticsearch.password: password

kibana.index: ".kibana"

logging.dest: /var/log/kibana/kibana.log
logging.level: info

xpack.security.enabled: true
xpack.security.encryptionKey: "something_at_least_32_characters"
xpack.security.session.idleTimeout: "1h"
xpack.security.session.lifespan: "30d"

xpack.monitoring.enabled: true
xpack.monitoring.kibana.collection.enabled: true

server.ssl.enabled: true
server.ssl.certificate: /path/to/certificate.crt
server.ssl.key: /path/to/private.key

elasticsearch.ssl.certificateAuthorities: ["/path/to/ca.crt"]
elasticsearch.ssl.verificationMode: certificate

newsfeed.enabled: false
telemetry.enabled: false
```

### Filebeat Configuration (filebeat.yml)
```yaml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/nginx/*.log
  fields:
    log_type: nginx
    environment: production
  fields_under_root: true
  multiline.pattern: '^\d{4}-\d{2}-\d{2}'
  multiline.negate: true
  multiline.match: after

- type: log
  enabled: true
  paths:
    - /var/log/app/*.log
  fields:
    log_type: application
    environment: production
  fields_under_root: true
  json.keys_under_root: true
  json.add_error_key: true

processors:
- add_host_metadata:
    when.not.contains.tags: forwarded
- add_cloud_metadata: ~
- add_docker_metadata: ~

output.logstash:
  hosts: ["logstash:5044"]
  compression_level: 3
  bulk_max_size: 2048

logging.level: info
logging.to_files: true
logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
  permissions: 0644
```

### Index Template Example
```json
{
  "index_patterns": ["application-*"],
  "template": {
    "settings": {
      "number_of_shards": 3,
      "number_of_replicas": 1,
      "index.refresh_interval": "30s",
      "index.lifecycle.name": "application-logs-policy",
      "index.lifecycle.rollover_alias": "application-logs"
    },
    "mappings": {
      "properties": {
        "@timestamp": {
          "type": "date"
        },
        "level": {
          "type": "keyword"
        },
        "message": {
          "type": "text",
          "analyzer": "standard"
        },
        "logger": {
          "type": "keyword"
        },
        "thread": {
          "type": "keyword"
        },
        "response_time": {
          "type": "float"
        },
        "status_code": {
          "type": "integer"
        },
        "user_id": {
          "type": "keyword"
        },
        "ip": {
          "type": "ip"
        }
      }
    }
  },
  "priority": 200,
  "version": 1
}
```

## Best Practices

### Elasticsearch
1. **Index Management**: Use Index Lifecycle Management (ILM) for automated index management
2. **Sharding Strategy**: Plan sharding based on data volume and query patterns
3. **Mapping Design**: Define explicit mappings to avoid dynamic mapping issues
4. **Query Optimization**: Use filters instead of queries when possible
5. **Monitoring**: Monitor cluster health, performance, and resource usage

### Logstash
1. **Pipeline Design**: Use multiple pipelines for different data types
2. **Performance Tuning**: Adjust workers, batch size, and memory settings
3. **Error Handling**: Implement proper error handling and dead letter queues
4. **Data Validation**: Validate and sanitize incoming data
5. **Resource Management**: Monitor CPU and memory usage

### Kibana
1. **Index Patterns**: Create appropriate index patterns for your data
2. **Dashboard Design**: Design dashboards for specific audiences and use cases
3. **Security**: Implement role-based access control
4. **Performance**: Optimize queries and visualizations
5. **Backup**: Regular backup of Kibana configurations

### General Stack
1. **Security**: Enable X-Pack security features
2. **Monitoring**: Monitor the entire stack with Metricbeat and logs
3. **Capacity Planning**: Plan for data growth and performance requirements
4. **Backup Strategy**: Implement comprehensive backup and recovery procedures
5. **Version Management**: Keep all components in sync with compatible versions

## Common Patterns

### Log Processing Pipeline
```ruby
# Multi-stage processing
filter {
  # Stage 1: Parse basic structure
  grok {
    match => { "message" => "%{TIMESTAMP_ISO8601:timestamp} \[%{LOGLEVEL:level}\] %{GREEDYDATA:log_message}" }
  }
  
  # Stage 2: Extract structured data
  if [log_message] =~ /user_id=/ {
    grok {
      match => { "log_message" => "user_id=%{WORD:user_id}" }
    }
  }
  
  # Stage 3: Enrich data
  if [user_id] {
    elasticsearch {
      hosts => ["elasticsearch:9200"]
      index => "users"
      query => "user_id:%{user_id}"
      fields => { "name" => "user_name", "role" => "user_role" }
    }
  }
  
  # Stage 4: Transform and clean
  mutate {
    remove_field => [ "log_message" ]
    strip => [ "user_name" ]
  }
}
```

### Index Lifecycle Policy
```json
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_size": "50gb",
            "max_age": "7d"
          },
          "set_priority": {
            "priority": 100
          }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "set_priority": {
            "priority": 50
          },
          "allocate": {
            "number_of_replicas": 0
          },
          "forcemerge": {
            "max_num_segments": 1
          }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "set_priority": {
            "priority": 0
          },
          "allocate": {
            "number_of_replicas": 0
          }
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

### Kibana Dashboard Automation
```json
{
  "version": "7.10.0",
  "objects": [
    {
      "id": "application-overview",
      "type": "dashboard",
      "attributes": {
        "title": "Application Overview",
        "description": "Overview dashboard for application logs",
        "panelsJSON": "[{\"version\":\"7.10.0\",\"panelIndex\":\"1\",\"gridData\":{\"x\":0,\"y\":0,\"w\":24,\"h\":15,\"i\":\"1\"},\"panelRefName\":\"panel_1\"}]",
        "timeRestore": false,
        "kibanaSavedObjectMeta": {
          "searchSourceJSON": "{\"query\":{\"match_all\":{}},\"filter\":[]}"
        }
      }
    }
  ]
}
```

## Do's and Don'ts

### Do's
✅ **Plan your index strategy** before ingesting data
✅ **Use explicit mappings** to control field types
✅ **Implement ILM policies** for automated index management
✅ **Monitor cluster health** and performance regularly
✅ **Use appropriate shard sizes** (20-40GB per shard)
✅ **Implement proper security** with authentication and authorization
✅ **Create index templates** for consistent mapping
✅ **Use aliases** for zero-downtime index operations
✅ **Backup your data** regularly
✅ **Test your configurations** in non-production environments

### Don'ts
❌ **Don't ignore cluster yellow/red status**
❌ **Don't create too many small indices** or too few large indices
❌ **Don't use default mappings** for production data
❌ **Don't forget to set up monitoring** for the entire stack
❌ **Don't ignore log parsing errors** in Logstash
❌ **Don't store sensitive data** without proper encryption
❌ **Don't use wildcard queries** on large datasets without filters
❌ **Don't forget to clean up** old indices and snapshots
❌ **Don't run single-node clusters** in production
❌ **Don't mix different data types** in the same index

## Additional Resources

### Tools and Extensions
- [Curator](https://github.com/elastic/curator) - Index management tool
- [Elasticdump](https://github.com/elasticsearch-dump/elasticsearch-dump) - Import/export tool
- [Cerebro](https://github.com/lmenezes/cerebro) - Elasticsearch web admin tool
- [ElastAlert](https://github.com/Yelp/elastalert) - Alerting framework

### Monitoring and Performance
- [Elastic Stack Monitoring](https://www.elastic.co/guide/en/elastic-stack-overview/current/monitoring-stack.html)
- [Elasticsearch Performance Tuning](https://www.elastic.co/guide/en/elasticsearch/reference/current/tune-for-indexing-speed.html)
- [Logstash Performance Tuning](https://www.elastic.co/guide/en/logstash/current/tuning-logstash.html)

### Learning Resources
- [Elastic Stack Documentation](https://www.elastic.co/guide/index.html)
- [Elastic Training](https://www.elastic.co/training/) - Official training courses
- [Elastic Community](https://discuss.elastic.co/) - Community forum
- [Elastic Webinars](https://www.elastic.co/webinars/) - Regular webinars

### Community Resources
- [Elastic GitHub](https://github.com/elastic/) - Official repositories
- [Reddit r/elasticsearch](https://www.reddit.com/r/elasticsearch/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/elasticsearch)
- [Elastic Blog](https://www.elastic.co/blog/) - Official blog

### Alternative and Complementary Tools
- [Fluentd](https://www.fluentd.org/) - Alternative to Logstash
- [Vector](https://vector.dev/) - Modern observability data pipeline
- [OpenSearch](https://opensearch.org/) - Open-source fork of Elasticsearch
- [Grafana Loki](https://grafana.com/oss/loki/) - Log aggregation system