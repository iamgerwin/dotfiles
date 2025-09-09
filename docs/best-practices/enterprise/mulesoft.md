# MuleSoft Best Practices

Comprehensive guide for building robust, scalable integration solutions with MuleSoft Anypoint Platform.

## 📚 Official Documentation
- [MuleSoft Documentation](https://docs.mulesoft.com/)
- [Anypoint Platform](https://docs.mulesoft.com/general/)
- [Mule Runtime Engine](https://docs.mulesoft.com/mule-runtime/4.4/)
- [DataWeave Documentation](https://docs.mulesoft.com/dataweave/2.4/)

## 🏗️ Project Structure

```
mule-project/
├── src/main/
│   ├── mule/
│   │   ├── global.xml              # Global configurations
│   │   ├── api/
│   │   │   ├── customers-api.xml   # API implementations
│   │   │   └── orders-api.xml
│   │   ├── flows/
│   │   │   ├── customer-flows.xml  # Business flows
│   │   │   └── order-flows.xml
│   │   └── common/
│   │       ├── error-handlers.xml  # Error handling
│   │       └── transformations.xml # Data transformations
│   └── resources/
│       ├── application.yaml        # Configuration properties
│       ├── log4j2.xml             # Logging configuration
│       └── schemas/               # JSON/XML schemas
├── pom.xml                        # Maven dependencies
└── exchange.json                  # Anypoint Exchange metadata
```

## 🎯 Core Best Practices

### 1. Configuration Management

```xml
<!-- application.yaml -->
http:
  port: "${http.port}"
  host: "0.0.0.0"

database:
  host: "${db.host}"
  port: "${db.port}"
  user: "${secure::db.user}"
  password: "${secure::db.password}"

api:
  base-path: "/api/v1"
  timeout: "${api.timeout}"
```

### 2. Flow Design Patterns

```xml
<!-- Customer API Flow -->
<flow name="get-customer-flow" doc:name="Get Customer Flow">
    <http:listener doc:name="HTTP Listener" 
                   config-ref="HTTP_Listener_config" 
                   path="/customers/{customerId}"/>
    
    <validation:is-not-empty doc:name="Validate Customer ID" 
                            value="#[attributes.uriParams.customerId]"
                            message="Customer ID is required"/>
    
    <flow-ref doc:name="Transform Request" flowName="transform-customer-request"/>
    
    <try doc:name="Try">
        <db:select doc:name="Get Customer" config-ref="Database_Config">
            <db:sql>SELECT * FROM customers WHERE id = :customerId</db:sql>
            <db:input-parameters>
                <db:input-parameter key="customerId" value="#[attributes.uriParams.customerId]"/>
            </db:input-parameters>
        </db:select>
        
        <flow-ref doc:name="Transform Response" flowName="transform-customer-response"/>
        
        <error-handler>
            <on-error-propagate enableNotifications="true" logException="true" 
                               doc:name="Database Error" type="DB:CONNECTIVITY">
                <flow-ref doc:name="Database Error Handler" flowName="database-error-handler"/>
            </on-error-propagate>
        </error-handler>
    </try>
</flow>
```

### 3. DataWeave Transformations

```dataweave
%dw 2.0
output application/json
---
{
    customer: {
        id: payload.CUSTOMER_ID,
        name: {
            first: payload.FIRST_NAME,
            last: payload.LAST_NAME
        },
        email: payload.EMAIL,
        phone: payload.PHONE,
        address: {
            street: payload.STREET,
            city: payload.CITY,
            state: payload.STATE,
            zipCode: payload.ZIP_CODE
        },
        orders: payload.ORDERS map (order) -> {
            orderId: order.ORDER_ID,
            orderDate: order.ORDER_DATE as Date {format: "yyyy-MM-dd"},
            total: order.TOTAL as Number {format: "#.##"},
            status: order.STATUS
        },
        metadata: {
            createdAt: now(),
            version: "1.0"
        }
    }
}
```

### 4. Error Handling Strategy

```xml
<!-- Global Error Handler -->
<error-handler name="global-error-handler" doc:name="Global Error Handler">
    <on-error-propagate enableNotifications="true" logException="true" 
                       doc:name="Validation Error" type="VALIDATION:INVALID_VALUE">
        <set-variable value="400" doc:name="Set Status Code" variableName="httpStatus"/>
        <set-payload value='#[%dw 2.0
output application/json
---
{
    error: {
        code: "VALIDATION_ERROR",
        message: error.description,
        timestamp: now(),
        path: attributes.requestPath
    }
}]' doc:name="Set Error Response"/>
    </on-error-propagate>
    
    <on-error-propagate enableNotifications="true" logException="true" 
                       doc:name="Database Error" type="DB:CONNECTIVITY">
        <set-variable value="503" doc:name="Set Status Code" variableName="httpStatus"/>
        <set-payload value='#[%dw 2.0
output application/json
---
{
    error: {
        code: "SERVICE_UNAVAILABLE",
        message: "Database service temporarily unavailable",
        timestamp: now()
    }
}]' doc:name="Set Error Response"/>
    </on-error-propagate>
</error-handler>
```

## 🛠️ Useful Connectors & Components

### Popular Connectors
- **Database Connector**: MySQL, PostgreSQL, Oracle
- **HTTP/HTTPS Connector**: REST API calls
- **Salesforce Connector**: CRM integration
- **File Connector**: File system operations
- **JMS Connector**: Message queuing
- **Email Connector**: SMTP/IMAP operations

### DataWeave Functions
```dataweave
// String manipulation
payload.name splitBy " " joinBy "-"
upper(payload.status)
payload.email matches /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/

// Date operations
now() as String {format: "yyyy-MM-dd HH:mm:ss"}
payload.birthDate as Date {format: "MM/dd/yyyy"}

// Array operations
payload filter ($.status == "active")
payload map ($ ++ {timestamp: now()})
payload reduce ((item, accumulator = 0) -> accumulator + item.amount)
```

## ⚠️ Common Pitfalls to Avoid

### 1. Poor Flow Design
```xml
<!-- ❌ Bad - Monolithic flow -->
<flow name="customer-processing-flow">
    <http:listener.../>
    <!-- 50+ components in one flow -->
</flow>

<!-- ✅ Good - Modular flows -->
<flow name="customer-api-flow">
    <http:listener.../>
    <flow-ref flowName="validate-customer-request"/>
    <flow-ref flowName="process-customer"/>
    <flow-ref flowName="transform-customer-response"/>
</flow>
```

### 2. Hardcoded Values
```xml
<!-- ❌ Bad -->
<http:request url="http://api.example.com/customers"/>

<!-- ✅ Good -->
<http:request url="${api.base.url}/customers"/>
```

### 3. Missing Error Handling
```xml
<!-- ❌ Bad - No error handling -->
<db:select config-ref="Database_Config">
    <db:sql>SELECT * FROM customers</db:sql>
</db:select>

<!-- ✅ Good - Proper error handling -->
<try>
    <db:select config-ref="Database_Config">
        <db:sql>SELECT * FROM customers</db:sql>
    </db:select>
    <error-handler>
        <on-error-propagate type="DB:CONNECTIVITY">
            <flow-ref flowName="database-error-handler"/>
        </on-error-propagate>
    </error-handler>
</try>
```

## 📊 Performance Optimization

### 1. Streaming Strategy
```xml
<!-- For large datasets -->
<flow name="process-large-file">
    <file:listener config-ref="File_Config" directory="input" 
                   moveToDirectory="processed">
        <scheduling-strategy>
            <fixed-frequency frequency="30000"/>
        </scheduling-strategy>
    </file:listener>
    
    <file:read config-ref="File_Config" 
               streamingStrategy="REPEATABLE_IN_MEMORY_STREAM"/>
</flow>
```

### 2. Connection Pooling
```xml
<db:config name="Database_Config" doc:name="Database Config">
    <db:my-sql-connection host="${db.host}" port="${db.port}" 
                         user="${db.user}" password="${db.password}"
                         database="${db.name}">
        <db:pooling-profile maxPoolSize="10" minPoolSize="1" 
                           acquireIncrement="1" maxWait="30000"/>
    </db:my-sql-connection>
</db:config>
```

### 3. Caching Strategy
```xml
<os:config name="ObjectStore_Config" doc:name="ObjectStore Config">
    <os:connection />
</os:config>

<flow name="cached-lookup">
    <os:retrieve key="#[attributes.uriParams.customerId]" 
                 config-ref="ObjectStore_Config" 
                 target="cachedCustomer"/>
    <choice>
        <when expression="#[vars.cachedCustomer != null]">
            <set-payload value="#[vars.cachedCustomer]"/>
        </when>
        <otherwise>
            <flow-ref flowName="fetch-customer-from-db"/>
            <os:store key="#[attributes.uriParams.customerId]" 
                      config-ref="ObjectStore_Config" 
                      value="#[payload]"/>
        </otherwise>
    </choice>
</flow>
```

## 🧪 Testing Strategies

### MUnit Testing
```xml
<munit:test name="test-get-customer-success" doc:name="Test Get Customer Success">
    <munit:behavior>
        <munit-tools:mock-when doc:name="Mock Database">
            <munit-tools:with-attributes>
                <munit-tools:with-attribute whereValue="get-customer-db" attributeName="doc:name"/>
            </munit-tools:with-attributes>
            <munit-tools:then-return>
                <munit-tools:payload value='#[{
                    "CUSTOMER_ID": "123",
                    "FIRST_NAME": "John",
                    "LAST_NAME": "Doe",
                    "EMAIL": "john.doe@example.com"
                }]'/>
            </munit-tools:then-return>
        </munit-tools:mock-when>
    </munit:behavior>
    
    <munit:execution>
        <flow-ref doc:name="Flow-ref" flowName="get-customer-flow"/>
    </munit:execution>
    
    <munit:validation>
        <munit-tools:assert-that doc:name="Assert Payload" 
                                expression="#[payload.customer.id]" 
                                is="#[MunitTools::equalTo('123')]"/>
    </munit:validation>
</munit:test>
```

## 🚀 Deployment Best Practices

### CI/CD Pipeline
```yaml
# Jenkins/GitLab CI configuration
stages:
  - validate
  - test
  - package
  - deploy

validate:
  script:
    - mvn validate

test:
  script:
    - mvn clean test

package:
  script:
    - mvn clean package

deploy-to-dev:
  script:
    - anypoint-cli runtime-mgr application deploy --target CloudHub-DEV
```

### Environment Configuration
```yaml
# dev.yaml
http:
  port: "8081"
database:
  host: "dev-db.company.com"

# prod.yaml  
http:
  port: "8080"
database:
  host: "prod-db.company.com"
```

## 📈 Advanced Patterns

### Scatter-Gather Pattern
```xml
<scatter-gather doc:name="Scatter-Gather">
    <route>
        <flow-ref doc:name="Get Customer Info" flowName="get-customer-info"/>
    </route>
    <route>
        <flow-ref doc:name="Get Order History" flowName="get-order-history"/>
    </route>
    <route>
        <flow-ref doc:name="Get Preferences" flowName="get-customer-preferences"/>
    </route>
</scatter-gather>
```

### Batch Processing
```xml
<batch:job jobName="customer-batch-job">
    <batch:input>
        <file:read config-ref="File_Config" path="customers.csv"/>
        <dataweave:transform>
            <dataweave:set-payload>
                <![CDATA[%dw 2.0
                output application/java
                ---
                payload splitBy "\n"]]>
            </dataweave:set-payload>
        </dataweave:transform>
    </batch:input>
    
    <batch:process-records>
        <batch:step name="validate-customer">
            <batch:aggregator doc:name="Batch Aggregator" size="10">
                <flow-ref flowName="process-customer-batch"/>
            </batch:aggregator>
        </batch:step>
    </batch:process-records>
</batch:job>
```

## 🔒 Security Best Practices

### API Security
- Use HTTPS for all API endpoints
- Implement OAuth 2.0 for authentication
- Validate all input parameters
- Use rate limiting to prevent abuse
- Encrypt sensitive data in transit and at rest

### Secure Property Configuration
```yaml
# Use Anypoint Platform secure properties
database:
  password: "${secure::db.password}"
api:
  key: "${secure::api.key}"
```

## 📋 Code Review Checklist

- [ ] Proper error handling implemented
- [ ] DataWeave transformations are efficient
- [ ] Configuration externalized
- [ ] Security measures in place
- [ ] Unit tests included
- [ ] Logging implemented appropriately
- [ ] Performance considerations addressed
- [ ] Code follows naming conventions

Remember: Design for scalability, maintainability, and monitoring. Use Anypoint Platform capabilities effectively and follow MuleSoft's recommended practices for enterprise integration patterns.