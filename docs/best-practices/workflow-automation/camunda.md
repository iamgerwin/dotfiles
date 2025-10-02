# Camunda Best Practices

## Official Documentation
- **Camunda Platform**: https://camunda.com
- **Documentation**: https://docs.camunda.io
- **Camunda 8 Docs**: https://docs.camunda.io/docs/components/
- **Camunda 7 Docs**: https://docs.camunda.org/manual/latest/
- **Best Practices**: https://camunda.com/best-practices/
- **Community Forum**: https://forum.camunda.io
- **GitHub**: https://github.com/camunda
- **Camunda Academy**: https://academy.camunda.com

## Introduction

Camunda is a comprehensive workflow and decision automation platform that enables organizations to orchestrate complex business processes. It provides tools for designing, executing, and monitoring BPMN workflows and DMN decisions across distributed systems.

### When to Use Camunda

**Ideal Scenarios:**
- Long-running business processes spanning days, weeks, or months
- Complex workflows requiring human task management and approvals
- Processes that need visual modeling and business-technical collaboration
- Systems requiring process monitoring, analytics, and optimization
- Microservices orchestration with saga patterns
- Legacy system integration and modernization
- Regulatory compliance requiring audit trails and process documentation

**When to Avoid:**
- Simple request-response APIs without state management
- Real-time event processing requiring sub-millisecond latency
- Purely technical workflows better suited to scripting
- Projects where BPMN modeling overhead exceeds complexity benefits
- Small teams without process modeling expertise

### Camunda 8 vs Camunda 7

```plaintext
Camunda 8 (Cloud-Native):
✓ Built for cloud and Kubernetes
✓ Zeebe workflow engine (horizontal scaling)
✓ Kafka-based event streaming
✓ Multi-tenancy support
✓ Stateless workers
✗ Breaking changes from v7
✗ Fewer community plugins

Camunda 7 (Spring Boot):
✓ Mature ecosystem
✓ Spring Boot integration
✓ Extensive plugin ecosystem
✓ On-premise deployment
✓ BPMN, CMMN, DMN support
✗ Limited horizontal scaling
✗ Legacy architecture patterns
```

## Core Concepts

### Process Engine Architecture

```plaintext
┌─────────────────────────────────────────────────┐
│              Application Layer                   │
│  (REST API, Web Apps, External Task Workers)    │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│          Camunda Process Engine                  │
│  ┌──────────────────────────────────────────┐  │
│  │     BPMN Execution Engine                │  │
│  │  (Parse, Execute, Manage Process State)  │  │
│  └──────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────┐  │
│  │     DMN Decision Engine                  │  │
│  │  (Evaluate Business Rules)               │  │
│  └──────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────┐  │
│  │     Job Executor / External Tasks        │  │
│  │  (Async Job Processing)                  │  │
│  └──────────────────────────────────────────┘  │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│          Process Engine Database                 │
│  (PostgreSQL, MySQL, Oracle, H2)                │
│  - Process Definitions                           │
│  - Process Instances                             │
│  - Task State                                    │
│  - Variables                                     │
│  - History                                       │
└──────────────────────────────────────────────────┘
```

### Process Instance Lifecycle

```plaintext
1. Deployment
   └─> Process Definition (BPMN XML) → Engine

2. Instantiation
   └─> Start Event → Process Instance Created

3. Execution
   └─> Token Flow → Activities → Service Tasks → User Tasks

4. State Persistence
   └─> Variables → Database → Resume After Restart

5. Completion
   └─> End Event → Instance Archived → History

6. Monitoring
   └─> Cockpit → Analytics → Optimize
```

## Best Practices

### Process Design

#### Token-Based Execution Model
```xml
<!-- Good: Clear token flow with explicit gateways -->
<bpmn:process id="order-process">
  <bpmn:startEvent id="start" />
  <bpmn:sequenceFlow sourceRef="start" targetRef="validate" />

  <bpmn:serviceTask id="validate" name="Validate Order" />
  <bpmn:sequenceFlow sourceRef="validate" targetRef="gateway" />

  <bpmn:exclusiveGateway id="gateway" name="Valid?">
    <bpmn:sequenceFlow targetRef="approve"
      name="Yes">
      <bpmn:conditionExpression>${valid}</bpmn:conditionExpression>
    </bpmn:sequenceFlow>
    <bpmn:sequenceFlow targetRef="reject" name="No" />
  </bpmn:exclusiveGateway>

  <bpmn:userTask id="approve" name="Manual Approval" />
  <bpmn:serviceTask id="reject" name="Send Rejection" />
</bpmn:process>
```

#### Process Versioning Strategy
```java
// Deploy new version without breaking running instances
@Component
public class ProcessDeployer {

    @Autowired
    private RepositoryService repositoryService;

    public void deployNewVersion() {
        repositoryService.createDeployment()
            .addClasspathResource("processes/order-v2.bpmn")
            .name("Order Process v2")
            .enableDuplicateFiltering(true)  // Only deploy if changed
            .deploy();

        // Old instances continue with v1
        // New instances use v2
        // No migration needed
    }

    // Migrate existing instances when necessary
    public void migrateInstances(String sourceProcessKey,
                                  String targetProcessKey) {
        ProcessDefinition source = repositoryService
            .createProcessDefinitionQuery()
            .processDefinitionKey(sourceProcessKey)
            .latestVersion()
            .singleResult();

        ProcessDefinition target = repositoryService
            .createProcessDefinitionQuery()
            .processDefinitionKey(targetProcessKey)
            .latestVersion()
            .singleResult();

        MigrationPlan plan = runtimeService
            .createMigrationPlan(source.getId(), target.getId())
            .mapEqualActivities()
            .mapActivities("oldTaskId", "newTaskId")
            .build();

        runtimeService.newMigration(plan)
            .processInstanceQuery(
                runtimeService.createProcessInstanceQuery()
                    .processDefinitionKey(sourceProcessKey)
            )
            .executeAsync();
    }
}
```

### External Task Pattern (Microservices)

```java
// Worker Service (Separate Microservice)
@Service
public class PaymentWorker {

    private static final String TOPIC = "payment-processing";

    @Autowired
    private ExternalTaskService externalTaskService;

    @Autowired
    private PaymentService paymentService;

    @PostConstruct
    public void startWorker() {
        externalTaskService.subscribe(TOPIC)
            .lockDuration(30000)  // 30 seconds
            .handler((externalTask, externalTaskService) -> {
                try {
                    String orderId = externalTask.getVariable("orderId");
                    BigDecimal amount = externalTask.getVariable("amount");

                    PaymentResult result = paymentService
                        .processPayment(orderId, amount);

                    Map<String, Object> variables = new HashMap<>();
                    variables.put("paymentId", result.getPaymentId());
                    variables.put("status", result.getStatus());

                    externalTaskService.complete(
                        externalTask,
                        variables
                    );

                } catch (PaymentException e) {
                    externalTaskService.handleBpmnError(
                        externalTask,
                        "PAYMENT_FAILED",
                        e.getMessage()
                    );

                } catch (Exception e) {
                    externalTaskService.handleFailure(
                        externalTask,
                        e.getMessage(),
                        e.getStackTrace().toString(),
                        3,  // Retries
                        10000  // Retry timeout
                    );
                }
            })
            .open();
    }
}
```

```xml
<!-- BPMN Process Definition -->
<bpmn:serviceTask id="processPayment"
                  name="Process Payment"
                  camunda:type="external"
                  camunda:topic="payment-processing">
  <bpmn:extensionElements>
    <camunda:inputOutput>
      <camunda:inputParameter name="orderId">${orderId}</camunda:inputParameter>
      <camunda:inputParameter name="amount">${orderAmount}</camunda:inputParameter>
    </camunda:inputOutput>
  </bpmn:extensionElements>
</bpmn:serviceTask>

<bpmn:boundaryEvent id="paymentError"
                    attachedToRef="processPayment">
  <bpmn:errorEventDefinition errorRef="PAYMENT_FAILED" />
</bpmn:boundaryEvent>
```

### Variable Management

```java
@Component
public class VariablesBestPractices {

    @Autowired
    private RuntimeService runtimeService;

    // Use typed variables for type safety
    public void setTypedVariables(String processInstanceId) {
        runtimeService.setVariable(
            processInstanceId,
            "customer",
            Variables.objectValue(new Customer())
                .serializationDataFormat("application/json")
                .create()
        );

        // Use transient variables for sensitive data
        runtimeService.setVariable(
            processInstanceId,
            "creditCard",
            Variables.stringValue("4111-1111-1111-1111")
                .isTransient()  // Not persisted to database
                .create()
        );
    }

    // Avoid large variables - use references instead
    public void handleLargeData(String processInstanceId) {
        // Bad: Storing entire file
        // byte[] largeFile = loadFile();
        // runtimeService.setVariable(processInstanceId, "document", largeFile);

        // Good: Store reference
        String documentId = documentService.upload(loadFile());
        runtimeService.setVariable(processInstanceId, "documentId", documentId);
    }

    // Use local variables for task-specific data
    public void useLocalVariables(String taskId) {
        TaskService taskService = processEngine.getTaskService();

        // Local to task, not visible to parent process
        taskService.setVariableLocal(taskId, "tempData", "value");
    }
}
```

### Error Handling and Compensation

```xml
<!-- Error Boundary Event -->
<bpmn:serviceTask id="chargeCustomer" name="Charge Customer" />

<bpmn:boundaryEvent id="paymentError"
                    attachedToRef="chargeCustomer">
  <bpmn:errorEventDefinition errorRef="PAYMENT_ERROR" />
</bpmn:boundaryEvent>

<bpmn:sequenceFlow sourceRef="paymentError" targetRef="notifyFailure" />

<!-- Compensation for Rollback -->
<bpmn:serviceTask id="reserveInventory"
                  name="Reserve Inventory"
                  isForCompensation="false" />

<bpmn:boundaryEvent id="compensateReservation"
                    attachedToRef="reserveInventory">
  <bpmn:compensateEventDefinition />
</bpmn:boundaryEvent>

<bpmn:serviceTask id="releaseInventory"
                  name="Release Inventory"
                  isForCompensation="true" />

<bpmn:association associationDirection="One"
                  sourceRef="compensateReservation"
                  targetRef="releaseInventory" />
```

```java
// Compensation Handler
@Component("releaseInventoryDelegate")
public class ReleaseInventoryDelegate implements JavaDelegate {

    @Autowired
    private InventoryService inventoryService;

    @Override
    public void execute(DelegateExecution execution) {
        String orderId = (String) execution.getVariable("orderId");
        inventoryService.releaseReservation(orderId);

        log.info("Compensated inventory reservation for order: {}", orderId);
    }
}
```

### Performance Optimization

```java
@Configuration
public class CamundaPerformanceConfig {

    // Configure async job executor
    @Bean
    public ProcessEngineConfiguration processEngineConfiguration() {
        return ProcessEngineConfiguration
            .createStandaloneProcessEngineConfiguration()
            .setJobExecutorActivate(true)
            .setJobExecutorCorePoolSize(3)
            .setJobExecutorMaxPoolSize(10)
            .setJobExecutorQueueSize(100)
            .setJobExecutorMaxJobsPerAcquisition(5)
            .setJobExecutorWaitTimeInMillis(5000)
            .setJobExecutorLockTimeInMillis(300000);  // 5 minutes
    }

    // Batch operations for bulk processing
    public void batchComplete(List<String> taskIds) {
        TaskService taskService = processEngine.getTaskService();

        Batch batch = taskService.createBatch(
            taskIds,
            "complete-tasks"
        );

        // Monitor batch progress
        ManagementService managementService = processEngine.getManagementService();
        batch = managementService.createBatchQuery()
            .batchId(batch.getId())
            .singleResult();

        log.info("Batch progress: {}/{}",
            batch.getJobsCreated() - batch.getBatchJobsPerSeed(),
            batch.getTotalJobs()
        );
    }

    // Use process instance modification for repairs
    public void modifyProcessInstance(String processInstanceId) {
        runtimeService.createProcessInstanceModification(processInstanceId)
            .cancelActivityInstance("activityInstanceId")
            .startBeforeActivity("newActivityId")
            .execute();
    }
}
```

## Project Structure

### Camunda 7 Spring Boot Project

```plaintext
camunda-order-service/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/order/
│   │   │       ├── OrderServiceApplication.java
│   │   │       ├── config/
│   │   │       │   ├── CamundaConfig.java
│   │   │       │   └── SecurityConfig.java
│   │   │       ├── delegate/           # Service task delegates
│   │   │       │   ├── ValidateOrderDelegate.java
│   │   │       │   ├── ChargePaymentDelegate.java
│   │   │       │   └── SendNotificationDelegate.java
│   │   │       ├── listener/           # Execution/task listeners
│   │   │       │   ├── OrderStartListener.java
│   │   │       │   └── OrderCompletionListener.java
│   │   │       ├── rest/               # REST controllers
│   │   │       │   ├── OrderController.java
│   │   │       │   └── ProcessController.java
│   │   │       ├── service/
│   │   │       │   ├── OrderService.java
│   │   │       │   ├── PaymentService.java
│   │   │       │   └── NotificationService.java
│   │   │       └── worker/             # External task workers
│   │   │           └── PaymentWorker.java
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── processes/              # BPMN files
│   │       │   ├── order-process.bpmn
│   │       │   └── refund-process.bpmn
│   │       ├── dmn/                    # DMN files
│   │       │   └── pricing-rules.dmn
│   │       └── forms/                  # User task forms
│   │           └── approve-order.html
│   └── test/
│       └── java/
│           └── com/example/order/
│               ├── OrderProcessTest.java
│               └── PaymentDelegateTest.java
├── pom.xml
└── README.md
```

### Camunda 8 (Zeebe) Project

```plaintext
zeebe-order-service/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/order/
│   │   │       ├── ZeebeApplication.java
│   │   │       ├── config/
│   │   │       │   └── ZeebeClientConfig.java
│   │   │       ├── worker/             # Job workers
│   │   │       │   ├── ValidateOrderWorker.java
│   │   │       │   ├── PaymentWorker.java
│   │   │       │   └── NotificationWorker.java
│   │   │       ├── client/             # Process client
│   │   │       │   └── OrderProcessClient.java
│   │   │       └── service/
│   │   │           └── OrderService.java
│   │   └── resources/
│   │       ├── application.yml
│   │       └── processes/
│   │           └── order-process.bpmn
│   └── test/
│       └── java/
│           └── com/example/order/
│               └── OrderProcessTest.java
├── docker-compose.yml              # Zeebe broker + Operate
└── pom.xml
```

## Security and Safety

### Authentication and Authorization

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
            .csrf().ignoringAntMatchers("/api/**")
            .and()
            .authorizeRequests()
                .antMatchers("/api/public/**").permitAll()
                .antMatchers("/camunda/app/**").authenticated()
                .antMatchers("/api/admin/**").hasRole("ADMIN")
            .and()
            .httpBasic();
    }

    // Configure Camunda admin user
    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
        auth.inMemoryAuthentication()
            .withUser("admin")
            .password(passwordEncoder().encode("admin"))
            .authorities("ROLE_ADMIN");
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}

// Task-level authorization
@Component
public class TaskSecurityService {

    @Autowired
    private TaskService taskService;

    @Autowired
    private IdentityService identityService;

    public void assignTaskWithAuthorization(String taskId, String userId) {
        // Check if user has permission
        identityService.setAuthenticatedUserId(userId);

        Task task = taskService.createTaskQuery()
            .taskId(taskId)
            .taskCandidateUser(userId)
            .singleResult();

        if (task == null) {
            throw new AccessDeniedException("User not authorized for task");
        }

        taskService.claim(taskId, userId);
    }
}
```

### Data Privacy and Compliance

```java
@Component
public class DataPrivacyService {

    @Autowired
    private HistoryService historyService;

    // GDPR: Delete personal data
    public void deleteUserData(String userId) {
        // Find all process instances for user
        List<HistoricProcessInstance> instances = historyService
            .createHistoricProcessInstanceQuery()
            .variableValueEquals("userId", userId)
            .list();

        instances.forEach(instance -> {
            // Delete history
            historyService.deleteHistoricProcessInstance(
                instance.getId()
            );
        });

        log.info("Deleted data for user: {}", userId);
    }

    // Anonymize sensitive variables
    public void anonymizeProcessData(String processInstanceId) {
        Map<String, Object> anonymized = new HashMap<>();
        anonymized.put("customerEmail", "***@***.***");
        anonymized.put("phoneNumber", "***-***-****");
        anonymized.put("ssn", "***-**-****");

        runtimeService.setVariables(processInstanceId, anonymized);
    }

    // Configure history cleanup
    @Bean
    public ProcessEngineConfiguration historyCleanupConfig() {
        return ProcessEngineConfiguration.createStandaloneProcessEngineConfiguration()
            .setHistoryCleanupBatchWindowStartTime("01:00")
            .setHistoryCleanupBatchWindowEndTime("05:00")
            .setHistoryCleanupDegreeOfParallelism(4)
            .setHistoryTimeToLive("P180D");  // 180 days
    }
}
```

## Common Vulnerabilities

### Injection Attacks in Expressions

```java
// VULNERABLE: Script injection via user input
public void vulnerableProcess(String userInput) {
    runtimeService.startProcessInstanceByKey(
        "process",
        Collections.singletonMap("input", userInput)
    );
}

// BPMN with vulnerable expression
// <conditionExpression>${execution.getVariable(input) == 'admin'}</conditionExpression>
// User could inject: "' || '1'=='1"

// SECURE: Validate and sanitize input
public void secureProcess(String userInput) {
    String sanitized = StringUtils.deleteWhitespace(userInput)
        .replaceAll("[^a-zA-Z0-9]", "");

    if (!isValidInput(sanitized)) {
        throw new IllegalArgumentException("Invalid input");
    }

    runtimeService.startProcessInstanceByKey(
        "process",
        Collections.singletonMap("input", sanitized)
    );
}

// Use typed variables and Java delegates instead of expressions
@Component("secureValidator")
public class SecureValidatorDelegate implements JavaDelegate {
    @Override
    public void execute(DelegateExecution execution) {
        String input = (String) execution.getVariable("input");
        boolean isValid = validateSecurely(input);
        execution.setVariable("isValid", isValid);
    }
}
```

### Information Disclosure

```java
// VULNERABLE: Exposing sensitive data in process variables
Map<String, Object> variables = new HashMap<>();
variables.put("creditCard", "4111111111111111");
variables.put("password", "plaintextPassword");
runtimeService.startProcessInstanceByKey("payment", variables);

// SECURE: Use transient variables and encryption
@Component
public class SecureVariableService {

    @Autowired
    private EncryptionService encryptionService;

    public void startSecureProcess(PaymentData data) {
        VariableMap variables = Variables.createVariables()
            .putValueTyped(
                "creditCard",
                Variables.stringValue(
                    encryptionService.encrypt(data.getCreditCard())
                ).isTransient()  // Not stored in DB
            )
            .putValue("paymentReference", data.getReference());

        runtimeService.startProcessInstanceByKey("payment", variables);
    }
}
```

## Common Pitfalls

### 1. Synchronous Service Tasks Blocking
```java
// BAD: Blocking the job executor thread
@Component("externalApiCall")
public class BlockingDelegate implements JavaDelegate {
    @Override
    public void execute(DelegateExecution execution) {
        // Blocks for 30 seconds
        String result = restTemplate.getForObject(
            "https://slow-api.com/data",
            String.class
        );
        execution.setVariable("result", result);
    }
}

// GOOD: Use external tasks or async continuation
// Option 1: External task pattern (recommended)
<bpmn:serviceTask id="apiCall"
                  camunda:type="external"
                  camunda:topic="api-calls" />

// Option 2: Async before/after
<bpmn:serviceTask id="apiCall"
                  camunda:asyncBefore="true"
                  camunda:delegateExpression="${externalApiCall}" />
```

### 2. Large Variable Serialization
```java
// BAD: Storing large objects
Map<String, Object> variables = new HashMap<>();
variables.put("largeReport", generateHugeReport());  // 10MB object

// GOOD: Store reference
String reportId = documentStore.save(generateHugeReport());
variables.put("reportId", reportId);
```

### 3. Missing Error Handling
```xml
<!-- BAD: No error boundary event -->
<bpmn:serviceTask id="payment" />

<!-- GOOD: Proper error handling -->
<bpmn:serviceTask id="payment" />
<bpmn:boundaryEvent id="paymentError" attachedToRef="payment">
  <bpmn:errorEventDefinition errorRef="PAYMENT_FAILED" />
</bpmn:boundaryEvent>
<bpmn:sequenceFlow sourceRef="paymentError" targetRef="handleError" />
```

### 4. Forgetting Process Instance Cleanup
```java
// Configure TTL for process instances
@Bean
public ProcessEngineConfiguration cleanupConfig() {
    return ProcessEngineConfiguration
        .createStandaloneProcessEngineConfiguration()
        .setHistoryTimeToLive("P30D")  // 30 days
        .setHistoryCleanupEnabled(true);
}
```

## Testing Strategies

### Unit Testing with Process Engine

```java
@RunWith(SpringRunner.class)
@SpringBootTest
public class OrderProcessTest {

    @Autowired
    private RuntimeService runtimeService;

    @Autowired
    private TaskService taskService;

    @Autowired
    @Rule
    public ProcessEngineRule processEngineRule;

    @Test
    @Deployment(resources = "processes/order-process.bpmn")
    public void testHappyPath() {
        // Start process
        Map<String, Object> variables = new HashMap<>();
        variables.put("orderAmount", 100.0);
        variables.put("customerId", "CUST123");

        ProcessInstance processInstance = runtimeService
            .startProcessInstanceByKey("order-process", variables);

        assertThat(processInstance).isNotNull();
        assertThat(processInstance).isStarted();

        // Assert task is created
        Task task = taskService.createTaskQuery()
            .processInstanceId(processInstance.getId())
            .singleResult();

        assertThat(task.getName()).isEqualTo("Approve Order");

        // Complete task
        taskService.complete(task.getId());

        // Assert process completed
        assertThat(processInstance).isEnded();
    }

    @Test
    @Deployment(resources = "processes/order-process.bpmn")
    public void testPaymentFailure() {
        // Mock payment failure
        Map<String, Object> variables = new HashMap<>();
        variables.put("orderAmount", -1.0);  // Invalid amount

        ProcessInstance processInstance = runtimeService
            .startProcessInstanceByKey("order-process", variables);

        // Assert error path taken
        assertThat(processInstance).isWaitingAt("handlePaymentError");
    }
}
```

### Integration Testing with Testcontainers

```java
@SpringBootTest
@Testcontainers
public class OrderProcessIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:14")
        .withDatabaseName("camunda")
        .withUsername("camunda")
        .withPassword("camunda");

    @DynamicPropertySource
    static void properties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Test
    public void testEndToEndOrder() {
        // Full integration test with real database
        // Test code here
    }
}
```

## Pros and Cons

### Pros
✓ **Enterprise-grade workflow orchestration** for complex business processes
✓ **BPMN 2.0 standard** ensures vendor independence and portability
✓ **Visual process modeling** bridges gap between business and technical teams
✓ **Long-running process support** with state persistence and recovery
✓ **Mature ecosystem** with extensive documentation and community support
✓ **Horizontal scaling** (Camunda 8/Zeebe) for high-throughput scenarios
✓ **Comprehensive monitoring** with Cockpit and Optimize tools
✓ **Multi-language support** via REST API and client libraries
✓ **Built-in human task management** with forms and user assignments

### Cons
✗ **Steep learning curve** for BPMN modeling and process engine concepts
✗ **Infrastructure overhead** requires database and process engine deployment
✗ **Performance overhead** for simple workflows compared to direct code
✗ **Vendor-specific extensions** reduce portability despite BPMN standard
✗ **Debugging complexity** for runtime issues in distributed environments
✗ **License costs** for enterprise features (Optimize, multi-tenancy)
✗ **Limited real-time processing** compared to event streaming platforms
✗ **Breaking changes** between Camunda 7 and 8 versions

## Practical Examples

### Saga Pattern for Distributed Transactions

```xml
<bpmn:process id="order-saga" name="Order Saga">
  <bpmn:startEvent id="start" />

  <!-- Reserve Inventory -->
  <bpmn:serviceTask id="reserveInventory"
                    name="Reserve Inventory"
                    camunda:type="external"
                    camunda:topic="inventory-reservation" />

  <!-- Charge Payment -->
  <bpmn:serviceTask id="chargePayment"
                    name="Charge Payment"
                    camunda:type="external"
                    camunda:topic="payment-processing" />

  <!-- Ship Order -->
  <bpmn:serviceTask id="shipOrder"
                    name="Ship Order"
                    camunda:type="external"
                    camunda:topic="shipping" />

  <!-- Compensation Handlers -->
  <bpmn:boundaryEvent id="compensate" attachedToRef="shipOrder">
    <bpmn:compensateEventDefinition />
  </bpmn:boundaryEvent>

  <bpmn:serviceTask id="refundPayment"
                    name="Refund Payment"
                    isForCompensation="true"
                    camunda:type="external"
                    camunda:topic="payment-refund" />

  <bpmn:serviceTask id="releaseInventory"
                    name="Release Inventory"
                    isForCompensation="true"
                    camunda:type="external"
                    camunda:topic="inventory-release" />

  <bpmn:endEvent id="end" />
</bpmn:process>
```

## Summary

**Key Takeaways:**
- Use Camunda for long-running, stateful business processes requiring orchestration
- Choose Camunda 8 for cloud-native microservices, Camunda 7 for monolithic Spring Boot apps
- Implement external task pattern for microservices architecture
- Design processes with proper error handling, compensation, and retry mechanisms
- Avoid large variables; use references to external storage
- Configure async execution for long-running service tasks
- Implement proper security controls at process, task, and API levels
- Use process versioning to evolve workflows without breaking running instances
- Monitor and optimize with Cockpit and Optimize tools
- Test processes with embedded engine and Testcontainers

**Quick Reference Checklist:**
- [ ] Process definitions use meaningful IDs and names
- [ ] All service tasks have error boundary events
- [ ] Long-running tasks configured with async continuation
- [ ] Variables are typed and validated
- [ ] External tasks have proper retry configuration
- [ ] Process versioning strategy documented
- [ ] History cleanup configured
- [ ] Security and authorization implemented
- [ ] Monitoring and alerts configured
- [ ] Unit and integration tests cover critical paths

## Conclusion

Camunda excels at orchestrating complex, long-running business processes that span multiple systems and require human interaction. Its BPMN-based approach provides a common language for business and technical teams while offering enterprise-grade features like state persistence, error handling, and process monitoring. However, it introduces architectural complexity and requires teams to understand workflow patterns and BPMN modeling.

Choose Camunda when process visibility, auditability, and orchestration capabilities outweigh the overhead of running a dedicated workflow engine. For simpler workflows or high-throughput event processing, consider lighter alternatives like state machines or event-driven architectures.

## Resources

- **Official Camunda Best Practices**: https://camunda.com/best-practices/
- **Camunda Blog**: https://camunda.com/blog/
- **GitHub Examples**: https://github.com/camunda/camunda-bpm-examples
- **Community Forum**: https://forum.camunda.io
- **Camunda Academy** (Free Training): https://academy.camunda.com
- **BPMN 2.0 Tutorial**: https://camunda.com/bpmn/
- **DMN Tutorial**: https://camunda.com/dmn/
- **Camunda YouTube Channel**: https://www.youtube.com/c/Camunda
