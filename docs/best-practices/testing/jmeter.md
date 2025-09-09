# JMeter Best Practices

## Official Documentation
- **Apache JMeter**: https://jmeter.apache.org
- **User Manual**: https://jmeter.apache.org/usermanual/index.html
- **Best Practices**: https://jmeter.apache.org/usermanual/best-practices.html
- **Component Reference**: https://jmeter.apache.org/usermanual/component_reference.html

## Installation and Setup

### Installation Options
```bash
# Install via package manager (macOS)
brew install jmeter

# Install via package manager (Ubuntu)
sudo apt install jmeter

# Manual installation
wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.6.2.tgz
tar -xzf apache-jmeter-5.6.2.tgz
cd apache-jmeter-5.6.2/bin
./jmeter

# GUI mode (development)
./jmeter.sh

# Non-GUI mode (production)
./jmeter.sh -n -t test-plan.jmx -l results.jtl -e -o report/
```

### JVM Configuration
```bash
# Edit jmeter.sh or jmeter.bat
export HEAP="-Xms1g -Xmx4g -XX:MaxMetaspaceSize=256m"
export GC_ALGO="-XX:+UseG1GC"
export JAVA_OPTS="-server $HEAP $GC_ALGO -Djava.security.egd=file:/dev/urandom"

# For large tests
export HEAP="-Xms4g -Xmx8g -XX:MaxMetaspaceSize=512m"
```

### JMeter Properties Configuration
```properties
# jmeter.properties

# HTTP settings
httpclient.timeout=60000
httpclient.reset_state_on_thread_group_iteration=true
httpclient.retry_count=1

# Performance settings
jmeter.save.saveservice.output_format=xml
jmeter.save.saveservice.response_data=false
jmeter.save.saveservice.samplerData=false
jmeter.save.saveservice.requestHeaders=false
jmeter.save.saveservice.responseHeaders=false

# Thread settings
jmeterengine.force.system.exit=true
jmeter.exit.check.pause=2000

# Memory optimization
java.awt.headless=true
jmeter.reportgenerator.overall_granularity=60000

# Logging
log_level.jmeter=INFO
log_level.jmeter.engine=INFO
log_level.jmeter.threads=INFO
```

## Test Plan Structure

### Basic Test Plan Components
```xml
<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2">
  <hashTree>
    <!-- Test Plan -->
    <TestPlan guiclass="TestPlanGui" testclass="TestPlan" testname="API Performance Test">
      <stringProp name="TestPlan.comments">API performance testing for user service</stringProp>
      <boolProp name="TestPlan.functional_mode">false</boolProp>
      <boolProp name="TestPlan.tearDown_on_shutdown">true</boolProp>
      <boolProp name="TestPlan.serialize_threadgroups">false</boolProp>
      <elementProp name="TestPlan.arguments" elementType="Arguments">
        <collectionProp name="Arguments.arguments"/>
      </elementProp>
      <stringProp name="TestPlan.user_define_classpath"></stringProp>
    </TestPlan>
    <hashTree>
      
      <!-- User Defined Variables -->
      <Arguments guiclass="ArgumentsPanel" testclass="Arguments" testname="User Defined Variables">
        <collectionProp name="Arguments.arguments">
          <elementProp name="BASE_URL" elementType="Argument">
            <stringProp name="Argument.name">BASE_URL</stringProp>
            <stringProp name="Argument.value">https://api.example.com</stringProp>
          </elementProp>
          <elementProp name="API_VERSION" elementType="Argument">
            <stringProp name="Argument.name">API_VERSION</stringProp>
            <stringProp name="Argument.value">v1</stringProp>
          </elementProp>
          <elementProp name="USERS_COUNT" elementType="Argument">
            <stringProp name="Argument.name">USERS_COUNT</stringProp>
            <stringProp name="Argument.value">100</stringProp>
          </elementProp>
          <elementProp name="RAMP_UP_TIME" elementType="Argument">
            <stringProp name="Argument.name">RAMP_UP_TIME</stringProp>
            <stringProp name="Argument.value">60</stringProp>
          </elementProp>
        </collectionProp>
      </Arguments>
      
      <!-- Configuration Elements -->
      <ConfigTestElement guiclass="HttpDefaultsGui" testclass="ConfigTestElement" testname="HTTP Request Defaults">
        <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
          <collectionProp name="Arguments.arguments"/>
        </elementProp>
        <stringProp name="HTTPSampler.domain">${BASE_URL}</stringProp>
        <stringProp name="HTTPSampler.port"></stringProp>
        <stringProp name="HTTPSampler.protocol">https</stringProp>
        <stringProp name="HTTPSampler.contentEncoding">UTF-8</stringProp>
        <stringProp name="HTTPSampler.path"></stringProp>
        <boolProp name="HTTPSampler.image_parser">false</boolProp>
        <boolProp name="HTTPSampler.concurrentDwn">false</boolProp>
        <stringProp name="HTTPSampler.implementation">HttpClient4</stringProp>
      </ConfigTestElement>
      
      <!-- Thread Group -->
      <ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="API Load Test">
        <stringProp name="ThreadGroup.on_sample_error">continue</stringProp>
        <elementProp name="ThreadGroup.main_controller" elementType="LoopController">
          <boolProp name="LoopController.continue_forever">false</boolProp>
          <stringProp name="LoopController.loops">10</stringProp>
        </elementProp>
        <stringProp name="ThreadGroup.num_threads">${USERS_COUNT}</stringProp>
        <stringProp name="ThreadGroup.ramp_time">${RAMP_UP_TIME}</stringProp>
        <boolProp name="ThreadGroup.scheduler">false</boolProp>
        <longProp name="ThreadGroup.duration">0</longProp>
        <longProp name="ThreadGroup.delay">0</longProp>
      </ThreadGroup>
      
    </hashTree>
  </hashTree>
</jmeterTestPlan>
```

### HTTP Request Configuration
```xml
<!-- HTTP Request Sampler -->
<HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="Get Users">
  <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
    <collectionProp name="Arguments.arguments">
      <elementProp name="page" elementType="HTTPArgument">
        <boolProp name="HTTPArgument.always_encode">false</boolProp>
        <stringProp name="Argument.value">1</stringProp>
        <stringProp name="Argument.metadata">=</stringProp>
        <boolProp name="HTTPArgument.use_equals">true</boolProp>
        <stringProp name="Argument.name">page</stringProp>
      </elementProp>
      <elementProp name="limit" elementType="HTTPArgument">
        <boolProp name="HTTPArgument.always_encode">false</boolProp>
        <stringProp name="Argument.value">20</stringProp>
        <stringProp name="Argument.metadata">=</stringProp>
        <boolProp name="HTTPArgument.use_equals">true</boolProp>
        <stringProp name="Argument.name">limit</stringProp>
      </elementProp>
    </collectionProp>
  </elementProp>
  <stringProp name="HTTPSampler.domain"></stringProp>
  <stringProp name="HTTPSampler.port"></stringProp>
  <stringProp name="HTTPSampler.protocol"></stringProp>
  <stringProp name="HTTPSampler.contentEncoding"></stringProp>
  <stringProp name="HTTPSampler.path">/api/${API_VERSION}/users</stringProp>
  <stringProp name="HTTPSampler.method">GET</stringProp>
  <boolProp name="HTTPSampler.follow_redirects">true</boolProp>
  <boolProp name="HTTPSampler.auto_redirects">false</boolProp>
  <boolProp name="HTTPSampler.use_keepalive">true</boolProp>
  <boolProp name="HTTPSampler.DO_MULTIPART_POST">false</boolProp>
  <stringProp name="HTTPSampler.embedded_url_re"></stringProp>
  <stringProp name="HTTPSampler.connect_timeout">10000</stringProp>
  <stringProp name="HTTPSampler.response_timeout">30000</stringProp>
</HTTPSamplerProxy>
```

## Authentication and Headers

### Bearer Token Authentication
```xml
<!-- HTTP Header Manager -->
<HeaderManager guiclass="HeaderPanel" testclass="HeaderManager" testname="HTTP Header Manager">
  <collectionProp name="HeaderManager.headers">
    <elementProp name="" elementType="Header">
      <stringProp name="Header.name">Authorization</stringProp>
      <stringProp name="Header.value">Bearer ${AUTH_TOKEN}</stringProp>
    </elementProp>
    <elementProp name="" elementType="Header">
      <stringProp name="Header.name">Content-Type</stringProp>
      <stringProp name="Header.value">application/json</stringProp>
    </elementProp>
    <elementProp name="" elementType="Header">
      <stringProp name="Header.name">Accept</stringProp>
      <stringProp name="Header.value">application/json</stringProp>
    </elementProp>
    <elementProp name="" elementType="Header">
      <stringProp name="Header.name">User-Agent</stringProp>
      <stringProp name="Header.value">JMeter/${__jmeterVersion()}</stringProp>
    </elementProp>
  </collectionProp>
</HeaderManager>

<!-- Login Request to Get Token -->
<HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="Login">
  <boolProp name="HTTPSampler.postBodyRaw">true</boolProp>
  <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
    <collectionProp name="Arguments.arguments">
      <elementProp name="" elementType="HTTPArgument">
        <boolProp name="HTTPArgument.always_encode">false</boolProp>
        <stringProp name="Argument.value">{
  "email": "${USERNAME}",
  "password": "${PASSWORD}"
}</stringProp>
        <stringProp name="Argument.metadata">=</stringProp>
      </elementProp>
    </collectionProp>
  </elementProp>
  <stringProp name="HTTPSampler.path">/api/${API_VERSION}/auth/login</stringProp>
  <stringProp name="HTTPSampler.method">POST</stringProp>
</HTTPSamplerProxy>

<!-- Extract Token from Response -->
<RegexExtractor guiclass="RegexExtractorGui" testclass="RegexExtractor" testname="Extract Auth Token">
  <stringProp name="RegexExtractor.useHeaders">false</stringProp>
  <stringProp name="RegexExtractor.refname">AUTH_TOKEN</stringProp>
  <stringProp name="RegexExtractor.regex">"accessToken":"([^"]+)"</stringProp>
  <stringProp name="RegexExtractor.template">$1$</stringProp>
  <stringProp name="RegexExtractor.default">TOKEN_NOT_FOUND</stringProp>
  <stringProp name="RegexExtractor.match_number">1</stringProp>
</RegexExtractor>
```

### Cookie Management
```xml
<!-- HTTP Cookie Manager -->
<CookieManager guiclass="CookiePanel" testclass="CookieManager" testname="HTTP Cookie Manager">
  <collectionProp name="CookieManager.cookies"/>
  <boolProp name="CookieManager.clearEachIteration">false</boolProp>
  <boolProp name="CookieManager.controlledByThreadGroup">false</boolProp>
</CookieManager>
```

## Data Management

### CSV Data Source
```csv
# users.csv
user_id,username,email,first_name,last_name
1,john_doe,john.doe@example.com,John,Doe
2,jane_smith,jane.smith@example.com,Jane,Smith
3,bob_johnson,bob.johnson@example.com,Bob,Johnson
```

```xml
<!-- CSV Data Set Config -->
<CSVDataSet guiclass="TestBeanGUI" testclass="CSVDataSet" testname="User Data">
  <stringProp name="delimiter">,</stringProp>
  <stringProp name="fileEncoding">UTF-8</stringProp>
  <stringProp name="filename">./data/users.csv</stringProp>
  <boolProp name="ignoreFirstLine">true</boolProp>
  <boolProp name="quotedData">false</boolProp>
  <boolProp name="recycle">true</boolProp>
  <stringProp name="shareMode">shareMode.all</stringProp>
  <boolProp name="stopThread">false</boolProp>
  <stringProp name="variableNames">user_id,username,email,first_name,last_name</stringProp>
</CSVDataSet>
```

### Random Data Generation
```xml
<!-- Random Variable -->
<RandomVariableConfig guiclass="TestBeanGUI" testclass="RandomVariableConfig" testname="Random User ID">
  <stringProp name="maximumValue">1000</stringProp>
  <stringProp name="minimumValue">1</stringProp>
  <stringProp name="outputFormat">000</stringProp>
  <boolProp name="perThread">true</boolProp>
  <stringProp name="randomSeed"></stringProp>
  <stringProp name="variableName">RANDOM_USER_ID</stringProp>
</RandomVariableConfig>

<!-- Counter -->
<CounterConfig guiclass="CounterConfigGui" testclass="CounterConfig" testname="Counter">
  <stringProp name="CounterConfig.start">1</stringProp>
  <stringProp name="CounterConfig.end">999999</stringProp>
  <stringProp name="CounterConfig.incr">1</stringProp>
  <stringProp name="CounterConfig.name">COUNTER</stringProp>
  <stringProp name="CounterConfig.format">000000</stringProp>
  <boolProp name="CounterConfig.per_user">false</boolProp>
</CounterConfig>
```

## Load Testing Patterns

### Load Testing Configuration
```xml
<!-- Constant Load -->
<ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="Constant Load">
  <stringProp name="ThreadGroup.num_threads">50</stringProp>
  <stringProp name="ThreadGroup.ramp_time">300</stringProp> <!-- 5 minutes -->
  <boolProp name="ThreadGroup.scheduler">true</boolProp>
  <stringProp name="ThreadGroup.duration">1800</stringProp> <!-- 30 minutes -->
  <stringProp name="ThreadGroup.delay">0</stringProp>
  <elementProp name="ThreadGroup.main_controller" elementType="LoopController">
    <boolProp name="LoopController.continue_forever">true</boolProp>
    <intProp name="LoopController.loops">-1</intProp>
  </elementProp>
</ThreadGroup>

<!-- Spike Testing -->
<ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="Spike Test">
  <stringProp name="ThreadGroup.num_threads">200</stringProp>
  <stringProp name="ThreadGroup.ramp_time">60</stringProp> <!-- 1 minute -->
  <boolProp name="ThreadGroup.scheduler">true</boolProp>
  <stringProp name="ThreadGroup.duration">300</stringProp> <!-- 5 minutes -->
</ThreadGroup>
```

### Stepping Thread Group
```xml
<!-- Install via Plugin Manager -->
<kg.apc.jmeter.threads.SteppingThreadGroup guiclass="kg.apc.jmeter.threads.SteppingThreadGroupGui" testclass="kg.apc.jmeter.threads.SteppingThreadGroup" testname="Stepping Thread Group">
  <stringProp name="Threads initial delay">0</stringProp>
  <stringProp name="Start users count">5</stringProp>
  <stringProp name="Start users period">30</stringProp>
  <stringProp name="Stop users count">5</stringProp>
  <stringProp name="Stop users period">30</stringProp>
  <stringProp name="flighttime">300</stringProp>
  <stringProp name="rampUp">10</stringProp>
</kg.apc.jmeter.threads.SteppingThreadGroup>
```

## Assertions and Validations

### Response Assertions
```xml
<!-- Response Assertion -->
<ResponseAssertion guiclass="AssertionGui" testclass="ResponseAssertion" testname="Response Assertion">
  <collectionProp name="Asserion.test_strings">
    <stringProp name="1068579942">200</stringProp>
  </collectionProp>
  <stringProp name="Assertion.custom_message">HTTP status code should be 200</stringProp>
  <stringProp name="Assertion.test_field">Assertion.response_code</stringProp>
  <boolProp name="Assertion.assume_success">false</boolProp>
  <intProp name="Assertion.test_type">1</intProp>
</ResponseAssertion>

<!-- JSON Assertion -->
<JSONPathAssertion guiclass="JSONPathAssertionGui" testclass="JSONPathAssertion" testname="JSON Assertion">
  <stringProp name="JSON_PATH">$.data.id</stringProp>
  <stringProp name="EXPECTED_VALUE">${user_id}</stringProp>
  <boolProp name="JSONVALIDATION">true</boolProp>
  <boolProp name="EXPECT_NULL">false</boolProp>
  <boolProp name="INVERT">false</boolProp>
  <boolProp name="ISREGEX">false</boolProp>
</JSONPathAssertion>

<!-- Duration Assertion -->
<DurationAssertion guiclass="DurationAssertionGui" testclass="DurationAssertion" testname="Duration Assertion">
  <stringProp name="DurationAssertion.duration">2000</stringProp>
</DurationAssertion>

<!-- Size Assertion -->
<SizeAssertion guiclass="SizeAssertionGui" testclass="SizeAssertion" testname="Size Assertion">
  <stringProp name="Assertion.test_field">SizeAssertion.response_network_size</stringProp>
  <stringProp name="SizeAssertion.size">1000</stringProp>
  <intProp name="SizeAssertion.operator">2</intProp> <!-- Greater than -->
</SizeAssertion>
```

### Custom Assertions with BeanShell
```javascript
// BeanShell Assertion
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;

try {
    String response = new String(ResponseData);
    JSONParser parser = new JSONParser();
    JSONObject json = (JSONObject) parser.parse(response);
    
    // Check if response contains required fields
    if (json.get("data") == null) {
        Failure = true;
        FailureMessage = "Response missing 'data' field";
    }
    
    // Validate data structure
    JSONObject data = (JSONObject) json.get("data");
    if (data.get("id") == null || data.get("email") == null) {
        Failure = true;
        FailureMessage = "User data is incomplete";
    }
    
    // Custom business logic validation
    String email = (String) data.get("email");
    if (!email.contains("@")) {
        Failure = true;
        FailureMessage = "Invalid email format: " + email;
    }
    
} catch (Exception e) {
    Failure = true;
    FailureMessage = "Error parsing response: " + e.getMessage();
}
```

## Performance Monitoring

### Listeners Configuration
```xml
<!-- Aggregate Report -->
<ResultCollector guiclass="StatGraphVisualizer" testclass="ResultCollector" testname="Aggregate Graph">
  <boolProp name="ResultCollector.error_logging">false</boolProp>
  <objProp>
    <name>saveConfig</name>
    <value class="SampleSaveConfiguration">
      <time>true</time>
      <latency>true</latency>
      <timestamp>true</timestamp>
      <success>true</success>
      <label>true</label>
      <code>true</code>
      <message>true</message>
      <threadName>true</threadName>
      <dataType>true</dataType>
      <encoding>false</encoding>
      <assertions>true</assertions>
      <subresults>true</subresults>
      <responseData>false</responseData>
      <samplerData>false</samplerData>
      <xml>false</xml>
      <fieldNames>true</fieldNames>
      <responseHeaders>false</responseHeaders>
      <requestHeaders>false</requestHeaders>
      <responseDataOnError>false</responseDataOnError>
      <saveAssertionResultsFailureMessage>true</saveAssertionResultsFailureMessage>
      <assertionsResultsToSave>0</assertionsResultsToSave>
      <bytes>true</bytes>
      <sentBytes>true</sentBytes>
      <url>true</url>
      <threadCounts>true</threadCounts>
      <idleTime>true</idleTime>
      <connectTime>true</connectTime>
    </value>
  </objProp>
  <stringProp name="filename">./results/results.jtl</stringProp>
</ResultCollector>

<!-- Response Time Graph -->
<kg.apc.jmeter.vizualizers.CorrectedResultCollector guiclass="kg.apc.jmeter.vizualizers.ResponseTimesOverTimeGui" testclass="kg.apc.jmeter.vizualizers.CorrectedResultCollector" testname="Response Times Over Time">
  <boolProp name="ResultCollector.error_logging">false</boolProp>
  <objProp>
    <name>saveConfig</name>
    <value class="SampleSaveConfiguration">
      <time>true</time>
      <latency>true</latency>
      <timestamp>true</timestamp>
      <success>true</success>
      <label>true</label>
      <code>true</code>
      <message>true</message>
      <threadName>true</threadName>
      <dataType>true</dataType>
      <encoding>false</encoding>
      <assertions>true</assertions>
      <subresults>true</subresults>
      <responseData>false</responseData>
      <samplerData>false</samplerData>
      <xml>false</xml>
      <fieldNames>true</fieldNames>
      <responseHeaders>false</responseHeaders>
      <requestHeaders>false</requestHeaders>
      <responseDataOnError>false</responseDataOnError>
      <saveAssertionResultsFailureMessage>true</saveAssertionResultsFailureMessage>
      <assertionsResultsToSave>0</assertionsResultsToSave>
      <bytes>true</bytes>
      <sentBytes>true</sentBytes>
      <url>true</url>
      <threadCounts>true</threadCounts>
      <idleTime>true</idleTime>
      <connectTime>true</connectTime>
    </value>
  </objProp>
  <stringProp name="filename">./results/response-times.jtl</stringProp>
  <longProp name="interval_grouping">1000</longProp>
  <boolProp name="graph_aggregated">false</boolProp>
  <stringProp name="include_sample_labels"></stringProp>
  <stringProp name="exclude_sample_labels"></stringProp>
  <stringProp name="start_offset"></stringProp>
  <stringProp name="end_offset"></stringProp>
</kg.apc.jmeter.vizualizers.CorrectedResultCollector>
```

### Custom Metrics with Backend Listener
```xml
<!-- Backend Listener for InfluxDB -->
<BackendListener guiclass="BackendListenerGui" testclass="BackendListener" testname="Backend Listener">
  <elementProp name="arguments" elementType="Arguments">
    <collectionProp name="Arguments.arguments">
      <elementProp name="influxdbMetricsSender" elementType="Argument">
        <stringProp name="Argument.name">influxdbMetricsSender</stringProp>
        <stringProp name="Argument.value">org.apache.jmeter.visualizers.backend.influxdb.HttpMetricsSender</stringProp>
      </elementProp>
      <elementProp name="influxdbUrl" elementType="Argument">
        <stringProp name="Argument.name">influxdbUrl</stringProp>
        <stringProp name="Argument.value">http://localhost:8086/write?db=jmeter</stringProp>
      </elementProp>
      <elementProp name="application" elementType="Argument">
        <stringProp name="Argument.name">application</stringProp>
        <stringProp name="Argument.value">MyApp</stringProp>
      </elementProp>
      <elementProp name="measurement" elementType="Argument">
        <stringProp name="Argument.name">measurement</stringProp>
        <stringProp name="Argument.value">jmeter</stringProp>
      </elementProp>
      <elementProp name="summaryOnly" elementType="Argument">
        <stringProp name="Argument.name">summaryOnly</stringProp>
        <stringProp name="Argument.value">false</stringProp>
      </elementProp>
      <elementProp name="samplersRegex" elementType="Argument">
        <stringProp name="Argument.name">samplersRegex</stringProp>
        <stringProp name="Argument.value">.*</stringProp>
      </elementProp>
      <elementProp name="percentiles" elementType="Argument">
        <stringProp name="Argument.name">percentiles</stringProp>
        <stringProp name="Argument.value">90;95;99</stringProp>
      </elementProp>
      <elementProp name="testTitle" elementType="Argument">
        <stringProp name="Argument.name">testTitle</stringProp>
        <stringProp name="Argument.value">API Load Test</stringProp>
      </elementProp>
    </collectionProp>
  </elementProp>
  <stringProp name="classname">org.apache.jmeter.visualizers.backend.influxdb.InfluxdbBackendListenerClient</stringProp>
</BackendListener>
```

## Advanced Features

### Distributed Testing
```bash
# Master node
./jmeter -n -t test-plan.jmx -R slave1.example.com,slave2.example.com -l results.jtl

# Slave nodes
./jmeter-server -Djava.rmi.server.hostname=192.168.1.100

# With specific properties
./jmeter -n -t test-plan.jmx -R slave1,slave2 -Gthreads=50 -Grampup=300 -l results.jtl
```

### Dynamic Test Control
```xml
<!-- Ultimate Thread Group -->
<kg.apc.jmeter.threads.UltimateThreadGroup guiclass="kg.apc.jmeter.threads.UltimateThreadGroupGui" testclass="kg.apc.jmeter.threads.UltimateThreadGroup" testname="Ultimate Thread Group">
  <collectionProp name="ultimatethreadgroupdata">
    <collectionProp name="1800748445">
      <stringProp name="1567">10</stringProp>  <!-- Start Threads Count -->
      <stringProp name="0">0</stringProp>     <!-- Initial Delay -->
      <stringProp name="1722">300</stringProp> <!-- Startup Time -->
      <stringProp name="1800">1800</stringProp> <!-- Hold Load For -->
      <stringProp name="1567">60</stringProp>   <!-- Shutdown Time -->
    </collectionProp>
    <collectionProp name="1800748446">
      <stringProp name="1567">20</stringProp>
      <stringProp name="1800">300</stringProp>
      <stringProp name="1722">300</stringProp>
      <stringProp name="1800">1800</stringProp>
      <stringProp name="1567">60</stringProp>
    </collectionProp>
  </collectionProp>
</kg.apc.jmeter.threads.UltimateThreadGroup>

<!-- Throughput Shaping Timer -->
<kg.apc.jmeter.timers.VariableThroughputTimer guiclass="kg.apc.jmeter.timers.VariableThroughputTimerGui" testclass="kg.apc.jmeter.timers.VariableThroughputTimer" testname="Throughput Shaping Timer">
  <collectionProp name="load_profile">
    <collectionProp name="-1629046972">
      <stringProp name="1567">10</stringProp>  <!-- Start RPS -->
      <stringProp name="1567">10</stringProp>  <!-- End RPS -->
      <stringProp name="1800">300</stringProp> <!-- Duration -->
    </collectionProp>
    <collectionProp name="-1629046971">
      <stringProp name="1567">10</stringProp>
      <stringProp name="1722">50</stringProp>
      <stringProp name="1800">600</stringProp>
    </collectionProp>
    <collectionProp name="-1629046970">
      <stringProp name="1722">50</stringProp>
      <stringProp name="1722">50</stringProp>
      <stringProp name="1800">900</stringProp>
    </collectionProp>
  </collectionProp>
</kg.apc.jmeter.timers.VariableThroughputTimer>
```

### Database Testing
```xml
<!-- JDBC Connection Configuration -->
<JDBCDataSource guiclass="TestBeanGUI" testclass="JDBCDataSource" testname="JDBC Connection Configuration">
  <boolProp name="autocommit">true</boolProp>
  <stringProp name="checkQuery">SELECT 1</stringProp>
  <stringProp name="connectionAge">5000</stringProp>
  <stringProp name="connectionProperties"></stringProp>
  <stringProp name="dataSource">postgres</stringProp>
  <stringProp name="dbUrl">jdbc:postgresql://localhost:5432/testdb</stringProp>
  <stringProp name="driver">org.postgresql.Driver</stringProp>
  <stringProp name="password">password</stringProp>
  <stringProp name="poolMax">10</stringProp>
  <stringProp name="timeout">10000</stringProp>
  <stringProp name="transactionIsolation">DEFAULT</stringProp>
  <boolProp name="trimInterval">60000</boolProp>
  <stringProp name="username">testuser</stringProp>
</JDBCDataSource>

<!-- JDBC Request -->
<JDBCSampler guiclass="TestBeanGUI" testclass="JDBCSampler" testname="Select Users">
  <stringProp name="dataSource">postgres</stringProp>
  <stringProp name="query">SELECT id, email, first_name, last_name FROM users WHERE created_at > ? LIMIT ?</stringProp>
  <stringProp name="queryArguments">${__timeShift(yyyy-MM-dd HH:mm:ss,,-1,d,)},20</stringProp>
  <stringProp name="queryArgumentsTypes">VARCHAR,INTEGER</stringProp>
  <stringProp name="queryTimeout"></stringProp>
  <stringProp name="queryType">Select Statement</stringProp>
  <stringProp name="resultVariable">users</stringProp>
  <stringProp name="variableNames">user_id,user_email,user_firstname,user_lastname</stringProp>
</JDBCSampler>
```

## CI/CD Integration

### Command Line Execution
```bash
#!/bin/bash

# Performance test script
TEST_PLAN="test-plan.jmx"
RESULTS_DIR="results/$(date +%Y%m%d_%H%M%S)"
REPORT_DIR="$RESULTS_DIR/report"

mkdir -p "$RESULTS_DIR"

# Run JMeter test
jmeter -n -t "$TEST_PLAN" \
  -l "$RESULTS_DIR/results.jtl" \
  -j "$RESULTS_DIR/jmeter.log" \
  -e -o "$REPORT_DIR" \
  -Jusers=100 \
  -Jrampup=300 \
  -Jduration=1800 \
  -Jbase_url=https://api.example.com

# Check exit code
if [ $? -ne 0 ]; then
    echo "JMeter test failed"
    exit 1
fi

# Parse results
ERROR_RATE=$(awk -F',' 'NR>1 && $8=="false" {errors++} NR>1 {total++} END {print (errors/total)*100}' "$RESULTS_DIR/results.jtl")
AVG_RESPONSE_TIME=$(awk -F',' 'NR>1 {sum+=$2; count++} END {print sum/count}' "$RESULTS_DIR/results.jtl")

echo "Error Rate: $ERROR_RATE%"
echo "Average Response Time: ${AVG_RESPONSE_TIME}ms"

# Performance thresholds
if (( $(echo "$ERROR_RATE > 1.0" | bc -l) )); then
    echo "Error rate threshold exceeded"
    exit 1
fi

if (( $(echo "$AVG_RESPONSE_TIME > 2000" | bc -l) )); then
    echo "Response time threshold exceeded"
    exit 1
fi

echo "Performance tests passed"
```

### Jenkins Pipeline
```groovy
pipeline {
    agent any
    
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['staging', 'production'], description: 'Target environment')
        string(name: 'USERS', defaultValue: '50', description: 'Number of concurrent users')
        string(name: 'DURATION', defaultValue: '300', description: 'Test duration in seconds')
    }
    
    environment {
        JMETER_HOME = '/opt/jmeter'
        TEST_PLAN = 'performance-tests/api-load-test.jmx'
        RESULTS_DIR = "results/${BUILD_NUMBER}"
    }
    
    stages {
        stage('Prepare Environment') {
            steps {
                script {
                    def baseUrl = params.ENVIRONMENT == 'production' 
                        ? 'https://api.example.com' 
                        : 'https://staging-api.example.com'
                    env.BASE_URL = baseUrl
                }
                
                sh "mkdir -p ${RESULTS_DIR}/reports"
            }
        }
        
        stage('Run Performance Tests') {
            steps {
                sh """
                    ${JMETER_HOME}/bin/jmeter -n \
                        -t ${TEST_PLAN} \
                        -l ${RESULTS_DIR}/results.jtl \
                        -j ${RESULTS_DIR}/jmeter.log \
                        -e -o ${RESULTS_DIR}/reports \
                        -Jusers=${params.USERS} \
                        -Jduration=${params.DURATION} \
                        -Jbase_url=${BASE_URL}
                """
            }
        }
        
        stage('Analyze Results') {
            steps {
                script {
                    def results = sh(
                        script: """
                            python3 scripts/analyze_results.py ${RESULTS_DIR}/results.jtl
                        """,
                        returnStdout: true
                    ).trim()
                    
                    def metrics = readJSON text: results
                    
                    // Check performance thresholds
                    if (metrics.errorRate > 1.0) {
                        error("Error rate ${metrics.errorRate}% exceeds threshold of 1%")
                    }
                    
                    if (metrics.avgResponseTime > 2000) {
                        error("Average response time ${metrics.avgResponseTime}ms exceeds threshold of 2000ms")
                    }
                    
                    // Publish results
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: "${RESULTS_DIR}/reports",
                        reportFiles: 'index.html',
                        reportName: 'Performance Test Report'
                    ])
                }
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: "${RESULTS_DIR}/**/*", fingerprint: true
        }
        
        failure {
            emailext (
                subject: "Performance Test Failed - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Performance test failed. Check the results at ${env.BUILD_URL}",
                to: "${env.CHANGE_AUTHOR_EMAIL}, performance-team@example.com"
            )
        }
        
        success {
            slackSend(
                color: 'good',
                message: "Performance test passed for ${params.ENVIRONMENT} environment. Report: ${env.BUILD_URL}Performance_Test_Report/"
            )
        }
    }
}
```

### Results Analysis Script
```python
#!/usr/bin/env python3
import csv
import json
import sys
from datetime import datetime
import statistics

def analyze_jmeter_results(jtl_file):
    results = {
        'total_requests': 0,
        'successful_requests': 0,
        'failed_requests': 0,
        'error_rate': 0.0,
        'avg_response_time': 0.0,
        'median_response_time': 0.0,
        'p90_response_time': 0.0,
        'p95_response_time': 0.0,
        'p99_response_time': 0.0,
        'min_response_time': float('inf'),
        'max_response_time': 0.0,
        'throughput': 0.0,
        'start_time': None,
        'end_time': None
    }
    
    response_times = []
    timestamps = []
    
    with open(jtl_file, 'r') as f:
        reader = csv.DictReader(f)
        
        for row in reader:
            results['total_requests'] += 1
            
            # Parse response time and timestamp
            response_time = int(row['elapsed'])
            timestamp = int(row['timeStamp'])
            success = row['success'] == 'true'
            
            response_times.append(response_time)
            timestamps.append(timestamp)
            
            if success:
                results['successful_requests'] += 1
            else:
                results['failed_requests'] += 1
            
            # Update min/max response times
            results['min_response_time'] = min(results['min_response_time'], response_time)
            results['max_response_time'] = max(results['max_response_time'], response_time)
    
    if results['total_requests'] > 0:
        results['error_rate'] = (results['failed_requests'] / results['total_requests']) * 100
        
        # Calculate response time statistics
        results['avg_response_time'] = statistics.mean(response_times)
        results['median_response_time'] = statistics.median(response_times)
        
        # Calculate percentiles
        response_times.sort()
        results['p90_response_time'] = response_times[int(0.90 * len(response_times))]
        results['p95_response_time'] = response_times[int(0.95 * len(response_times))]
        results['p99_response_time'] = response_times[int(0.99 * len(response_times))]
        
        # Calculate throughput (requests per second)
        if timestamps:
            duration_seconds = (max(timestamps) - min(timestamps)) / 1000
            if duration_seconds > 0:
                results['throughput'] = results['total_requests'] / duration_seconds
                
            results['start_time'] = datetime.fromtimestamp(min(timestamps) / 1000).isoformat()
            results['end_time'] = datetime.fromtimestamp(max(timestamps) / 1000).isoformat()
    
    return results

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python3 analyze_results.py <jtl_file>")
        sys.exit(1)
    
    jtl_file = sys.argv[1]
    results = analyze_jmeter_results(jtl_file)
    
    print(json.dumps(results, indent=2))
```

## Common Pitfalls

1. **Running GUI mode in production**: Always use non-GUI mode for actual testing
2. **Not configuring JVM properly**: Insufficient heap size causes OutOfMemory errors
3. **Saving unnecessary data**: Disable response data saving for large tests
4. **No ramp-up period**: Sudden load spikes give unrealistic results
5. **Testing from single machine**: Use distributed testing for high loads
6. **Ignoring warm-up**: Include warm-up period to stabilize application
7. **Not validating responses**: Check response content, not just status codes
8. **Fixed test data**: Use parameterization and data sources
9. **No think time**: Add realistic pauses between requests
10. **Insufficient monitoring**: Monitor both client and server resources during tests