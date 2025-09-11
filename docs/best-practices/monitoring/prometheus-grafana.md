# Prometheus and Grafana Best Practices

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

### Prometheus
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Prometheus Configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)
- [PromQL Query Language](https://prometheus.io/docs/prometheus/latest/querying/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)

### Grafana
- [Grafana Documentation](https://grafana.com/docs/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Grafana Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)
- [Grafana Alerting](https://grafana.com/docs/grafana/latest/alerting/)

## Core Concepts

### Prometheus Architecture
- **Prometheus Server**: Scrapes and stores time series data
- **Time Series Database**: Stores metrics with timestamps
- **Service Discovery**: Automatically discovers targets to scrape
- **Exporters**: Expose metrics from third-party systems
- **Pushgateway**: Accepts metrics pushed from batch jobs
- **Alertmanager**: Handles alerts sent by Prometheus

### Key Components
- **Metrics**: Numerical measurements over time
- **Labels**: Key-value pairs for dimensional data
- **Targets**: Endpoints that Prometheus scrapes
- **Jobs**: Collections of targets with the same purpose
- **Rules**: Recording and alerting rules

### Grafana Components
- **Data Sources**: Backend services (Prometheus, InfluxDB, etc.)
- **Dashboards**: Visual representations of metrics
- **Panels**: Individual visualizations within dashboards
- **Variables**: Dynamic values for dashboard customization
- **Annotations**: Event markers on time series

## Project Structure Examples

### Basic Monitoring Stack Structure
```
monitoring/
├── prometheus/
│   ├── prometheus.yml
│   ├── rules/
│   │   ├── alerts.yml
│   │   └── recording-rules.yml
│   ├── targets/
│   │   ├── node-exporter.yml
│   │   └── application.yml
│   └── Dockerfile
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   │   └── prometheus.yml
│   │   ├── dashboards/
│   │   │   └── dashboard-config.yml
│   │   └── notifiers/
│   │       └── slack.yml
│   ├── dashboards/
│   │   ├── system-metrics.json
│   │   ├── application-metrics.json
│   │   └── business-metrics.json
│   └── Dockerfile
├── exporters/
│   ├── node-exporter/
│   ├── blackbox-exporter/
│   └── custom-exporter/
├── alertmanager/
│   ├── alertmanager.yml
│   └── templates/
│       └── slack.tmpl
├── docker-compose.yml
└── README.md
```

### Advanced Multi-Environment Structure
```
monitoring-infrastructure/
├── environments/
│   ├── production/
│   │   ├── prometheus/
│   │   │   ├── prometheus.yml
│   │   │   └── values.yml
│   │   ├── grafana/
│   │   │   └── values.yml
│   │   └── alertmanager/
│   │       └── config.yml
│   ├── staging/
│   └── development/
├── shared/
│   ├── rules/
│   │   ├── infrastructure.yml
│   │   ├── application.yml
│   │   └── business.yml
│   ├── dashboards/
│   │   ├── infrastructure/
│   │   ├── application/
│   │   └── business/
│   └── exporters/
├── helm/
│   ├── prometheus/
│   ├── grafana/
│   └── alertmanager/
└── scripts/
    ├── deploy.sh
    └── backup.sh
```

## Configuration Examples

### Prometheus Configuration (prometheus.yml)
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'production'
    region: 'us-west-2'

rule_files:
  - "rules/*.yml"

scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
    scrape_interval: 5s
    metrics_path: /metrics

  # Node Exporter
  - job_name: 'node-exporter'
    static_configs:
      - targets:
        - 'node1:9100'
        - 'node2:9100'
        - 'node3:9100'
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        regex: '([^:]+):\d+'

  # Application metrics
  - job_name: 'web-app'
    static_configs:
      - targets: ['app1:8080', 'app2:8080']
    metrics_path: /actuator/prometheus
    scrape_interval: 30s
    scrape_timeout: 10s

  # Service Discovery (Kubernetes)
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
    - role: pod
    relabel_configs:
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
      action: keep
      regex: true
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
      action: replace
      target_label: __metrics_path__
      regex: (.+)

  # Blackbox Exporter
  - job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - https://example.com
        - https://api.example.com
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

remote_write:
  - url: "https://prometheus-remote-storage.example.com/api/v1/write"
    basic_auth:
      username: "user"
      password: "password"
```

### Alert Rules (rules/alerts.yml)
```yaml
groups:
- name: infrastructure.rules
  interval: 30s
  rules:
  - alert: InstanceDown
    expr: up == 0
    for: 5m
    labels:
      severity: critical
      team: infrastructure
    annotations:
      summary: "Instance {{ $labels.instance }} down"
      description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes."

  - alert: HighCPUUsage
    expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
    for: 10m
    labels:
      severity: warning
      team: infrastructure
    annotations:
      summary: "High CPU usage on {{ $labels.instance }}"
      description: "CPU usage is above 80% for more than 10 minutes on {{ $labels.instance }}"

  - alert: HighMemoryUsage
    expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.9
    for: 10m
    labels:
      severity: critical
      team: infrastructure
    annotations:
      summary: "High memory usage on {{ $labels.instance }}"
      description: "Memory usage is above 90% for more than 10 minutes on {{ $labels.instance }}"

  - alert: DiskSpaceUsage
    expr: (node_filesystem_size_bytes{fstype!="tmpfs"} - node_filesystem_free_bytes{fstype!="tmpfs"}) / node_filesystem_size_bytes{fstype!="tmpfs"} > 0.8
    for: 5m
    labels:
      severity: warning
      team: infrastructure
    annotations:
      summary: "High disk usage on {{ $labels.instance }}"
      description: "Disk usage is above 80% on {{ $labels.instance }} for filesystem {{ $labels.mountpoint }}"

- name: application.rules
  rules:
  - alert: HighErrorRate
    expr: sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) > 0.1
    for: 5m
    labels:
      severity: critical
      team: backend
    annotations:
      summary: "High error rate detected"
      description: "Error rate is above 10% for the last 5 minutes"

  - alert: HighResponseTime
    expr: histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)) > 1
    for: 10m
    labels:
      severity: warning
      team: backend
    annotations:
      summary: "High response time detected"
      description: "95th percentile response time is above 1 second for 10 minutes"
```

### Recording Rules (rules/recording-rules.yml)
```yaml
groups:
- name: recording.rules
  interval: 30s
  rules:
  - record: instance:node_cpu:rate5m
    expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

  - record: instance:node_filesystem_usage:ratio
    expr: (node_filesystem_size_bytes{fstype!="tmpfs"} - node_filesystem_free_bytes{fstype!="tmpfs"}) / node_filesystem_size_bytes{fstype!="tmpfs"}

  - record: instance:node_memory_usage:ratio
    expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes

  - record: job:http_requests:rate5m
    expr: sum(rate(http_requests_total[5m])) by (job)

  - record: job:http_request_duration:p95
    expr: histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (job, le))
```

### Grafana Data Source Configuration
```yaml
# provisioning/datasources/prometheus.yml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
    jsonData:
      timeInterval: "5s"
      queryTimeout: "300s"
      httpMethod: POST
    secureJsonData:
      basicAuthPassword: "password"

  - name: Prometheus-Alertmanager
    type: alertmanager
    access: proxy
    url: http://alertmanager:9093
    editable: true
    jsonData:
      implementation: prometheus
```

### Grafana Dashboard Provisioning
```yaml
# provisioning/dashboards/dashboard-config.yml
apiVersion: 1

providers:
  - name: 'Infrastructure Dashboards'
    orgId: 1
    folder: 'Infrastructure'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards/infrastructure

  - name: 'Application Dashboards'
    orgId: 1
    folder: 'Applications'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards/applications
```

### Alertmanager Configuration
```yaml
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alertmanager@example.com'
  slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'

templates:
  - '/etc/alertmanager/templates/*.tmpl'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'
  routes:
  - match:
      severity: critical
    receiver: 'critical-alerts'
    continue: true
  - match:
      team: infrastructure
    receiver: 'infra-team'
  - match:
      team: backend
    receiver: 'backend-team'

receivers:
- name: 'web.hook'
  webhook_configs:
  - url: 'http://127.0.0.1:5001/'

- name: 'critical-alerts'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/CRITICAL/ALERTS/WEBHOOK'
    channel: '#critical-alerts'
    title: 'Critical Alert'
    text: 'Alert: {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'

- name: 'infra-team'
  email_configs:
  - to: 'infra-team@example.com'
    subject: '[ALERT] {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      {{ end }}

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'cluster', 'service']
```

## Best Practices

### Metric Design
1. **Naming Convention**: Use consistent metric naming (service_feature_unit)
2. **Label Cardinality**: Keep label cardinality low to avoid performance issues
3. **Use Histograms**: For latency and size measurements
4. **Avoid High Cardinality Labels**: Don't use user IDs, request IDs as labels
5. **Instrument at Boundaries**: Measure at service boundaries (HTTP requests, DB queries)

### Data Retention and Storage
1. **Retention Policies**: Set appropriate retention based on storage capacity
2. **Downsampling**: Use recording rules for long-term storage
3. **Remote Storage**: Consider remote storage for long-term retention
4. **Backup Strategy**: Implement regular backup procedures
5. **Storage Sizing**: Plan storage based on metrics volume and retention

### Alerting Strategy
1. **Alert on Symptoms**: Alert on user-visible symptoms, not causes
2. **Severity Levels**: Use appropriate severity levels (critical, warning, info)
3. **Alert Fatigue**: Avoid too many alerts to prevent alert fatigue
4. **Runbooks**: Create runbooks for each alert
5. **SLO-based Alerting**: Alert based on Service Level Objectives

### Dashboard Design
1. **Hierarchy**: Organize dashboards by service/component hierarchy
2. **USE Method**: Utilization, Saturation, Errors for resources
3. **RED Method**: Rate, Errors, Duration for services
4. **Consistent Layout**: Use consistent layouts across dashboards
5. **Variable Usage**: Use variables for dynamic filtering

## Common Patterns

### Service Level Indicators (SLI) Queries
```promql
# Availability SLI
sum(rate(http_requests_total{status!~"5.."}[5m])) / sum(rate(http_requests_total[5m]))

# Latency SLI (95th percentile)
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))

# Error Rate SLI
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))

# Throughput
sum(rate(http_requests_total[5m]))
```

### Infrastructure Monitoring Queries
```promql
# CPU Usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory Usage
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Disk Usage
(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100

# Network IO
rate(node_network_receive_bytes_total[5m])
rate(node_network_transmit_bytes_total[5m])

# Load Average
node_load1 / count(node_cpu_seconds_total{mode="idle"}) by (instance)
```

### Kubernetes Monitoring Queries
```promql
# Pod CPU Usage
sum(rate(container_cpu_usage_seconds_total{container!="POD"}[5m])) by (pod, namespace)

# Pod Memory Usage
sum(container_memory_usage_bytes{container!="POD"}) by (pod, namespace)

# Pod Restart Count
increase(kube_pod_container_status_restarts_total[1h])

# Node Capacity
kube_node_status_capacity{resource="cpu"} * 1000
kube_node_status_capacity{resource="memory"}

# Deployment Replicas
kube_deployment_status_replicas_available / kube_deployment_spec_replicas
```

### Multi-Environment Grafana Variables
```json
{
  "templating": {
    "list": [
      {
        "name": "environment",
        "type": "query",
        "query": "label_values(environment)",
        "refresh": 1
      },
      {
        "name": "instance",
        "type": "query",
        "query": "label_values(up{environment=\"$environment\"}, instance)",
        "refresh": 1
      },
      {
        "name": "service",
        "type": "query",
        "query": "label_values(http_requests_total{environment=\"$environment\"}, job)",
        "refresh": 1
      }
    ]
  }
}
```

## Do's and Don'ts

### Do's
✅ **Use consistent labeling** across all metrics
✅ **Monitor the golden signals** (latency, traffic, errors, saturation)
✅ **Set up proper retention policies** for different metric types
✅ **Use recording rules** for frequently accessed queries
✅ **Implement proper alerting** with clear escalation procedures
✅ **Create comprehensive dashboards** for different audiences
✅ **Use service discovery** for dynamic environments
✅ **Document your metrics** and their meanings
✅ **Test your alerts** regularly to ensure they work
✅ **Monitor Prometheus itself** and set up high availability

### Don'ts
❌ **Don't use high cardinality labels** (user IDs, request IDs)
❌ **Don't ignore storage requirements** and retention planning
❌ **Don't create too many alerts** that cause alert fatigue
❌ **Don't hardcode values** in queries and alerts
❌ **Don't ignore security** for Prometheus and Grafana access
❌ **Don't forget to monitor** the monitoring infrastructure
❌ **Don't use Prometheus for logs** or events
❌ **Don't create dashboards** without considering the audience
❌ **Don't ignore query performance** for complex PromQL queries
❌ **Don't forget to backup** important dashboards and configurations

## Additional Resources

### Prometheus Tools and Exporters
- [Node Exporter](https://github.com/prometheus/node_exporter) - Hardware and OS metrics
- [Blackbox Exporter](https://github.com/prometheus/blackbox_exporter) - Network probing
- [CAdvisor](https://github.com/google/cadvisor) - Container metrics
- [Pushgateway](https://github.com/prometheus/pushgateway) - Batch job metrics

### Grafana Plugins and Extensions
- [Grafana Image Renderer](https://grafana.com/grafana/plugins/grafana-image-renderer/) - PDF reports
- [Grafana Piechart Panel](https://grafana.com/grafana/plugins/grafana-piechart-panel/)
- [Grafana Worldmap Panel](https://grafana.com/grafana/plugins/grafana-worldmap-panel/)
- [Grafana Stat Panel](https://grafana.com/grafana/plugins/stat-panel/)

### Learning Resources
- [Prometheus Up & Running](https://www.oreilly.com/library/view/prometheus-up/9781492034131/) - Book
- [Grafana Fundamentals](https://grafana.com/tutorials/) - Official tutorials
- [PromLabs](https://promlabs.com/) - Prometheus training and consulting
- [Robust Perception](https://www.robustperception.io/blog/) - Prometheus blog

### Community Resources
- [Prometheus Community](https://prometheus.io/community/)
- [Grafana Community](https://community.grafana.com/)
- [CNCF Slack #prometheus](https://cloud-native.slack.com/)
- [Reddit r/PrometheusMonitoring](https://www.reddit.com/r/PrometheusMonitoring/)

### Monitoring Methodologies
- [Google SRE Book](https://sre.google/sre-book/table-of-contents/) - SRE principles
- [USE Method](http://www.brendangregg.com/usemethod.html) - Brendan Gregg
- [RED Method](https://grafana.com/blog/2018/08/02/the-red-method-how-to-instrument-your-services/) - Grafana
- [Four Golden Signals](https://sre.google/sre-book/monitoring-distributed-systems/) - Google SRE