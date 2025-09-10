# Java Best Practices

## Overview
Java is a robust, object-oriented, platform-independent programming language widely used for enterprise applications, Android development, and large-scale systems.

## Documentation
- [Official Documentation](https://docs.oracle.com/en/java/)
- [Java SE Documentation](https://docs.oracle.com/javase/8/docs/)
- [OpenJDK](https://openjdk.org/)
- [Java Language Specification](https://docs.oracle.com/javase/specs/)

## Project Structure

### Standard Maven Project
```
project-root/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── example/
│   │   │           ├── controller/
│   │   │           ├── service/
│   │   │           ├── repository/
│   │   │           ├── model/
│   │   │           ├── dto/
│   │   │           ├── config/
│   │   │           ├── exception/
│   │   │           ├── util/
│   │   │           └── Application.java
│   │   └── resources/
│   │       ├── application.properties
│   │       ├── application.yml
│   │       └── static/
│   └── test/
│       ├── java/
│       └── resources/
├── target/
├── pom.xml
└── README.md
```

### Gradle Project Structure
```
project-root/
├── src/
│   ├── main/
│   │   ├── java/
│   │   └── resources/
│   └── test/
│       ├── java/
│       └── resources/
├── build/
├── gradle/
├── build.gradle
├── settings.gradle
└── gradlew
```

## Core Best Practices

### 1. Code Organization

```java
package com.example.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {
    
    private final UserRepository userRepository;
    private final EmailService emailService;
    
    @Transactional
    public User createUser(UserDto userDto) {
        log.debug("Creating user with email: {}", userDto.getEmail());
        
        User user = User.builder()
            .email(userDto.getEmail())
            .name(userDto.getName())
            .createdAt(LocalDateTime.now())
            .build();
            
        User savedUser = userRepository.save(user);
        emailService.sendWelcomeEmail(savedUser);
        
        return savedUser;
    }
}
```

### 2. Exception Handling

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleResourceNotFound(
            ResourceNotFoundException ex, 
            HttpServletRequest request) {
        
        ErrorResponse error = ErrorResponse.builder()
            .timestamp(LocalDateTime.now())
            .status(HttpStatus.NOT_FOUND.value())
            .error("Resource Not Found")
            .message(ex.getMessage())
            .path(request.getRequestURI())
            .build();
            
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }
    
    @ExceptionHandler(ValidationException.class)
    public ResponseEntity<ErrorResponse> handleValidation(
            ValidationException ex) {
        
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error ->
            errors.put(error.getField(), error.getDefaultMessage())
        );
        
        ErrorResponse error = ErrorResponse.builder()
            .timestamp(LocalDateTime.now())
            .status(HttpStatus.BAD_REQUEST.value())
            .error("Validation Failed")
            .validationErrors(errors)
            .build();
            
        return ResponseEntity.badRequest().body(error);
    }
}
```

### 3. Design Patterns

#### Singleton Pattern
```java
public class DatabaseConnection {
    
    private static volatile DatabaseConnection instance;
    private Connection connection;
    
    private DatabaseConnection() {
        // Private constructor
    }
    
    public static DatabaseConnection getInstance() {
        if (instance == null) {
            synchronized (DatabaseConnection.class) {
                if (instance == null) {
                    instance = new DatabaseConnection();
                }
            }
        }
        return instance;
    }
}
```

#### Builder Pattern
```java
@Builder
@Getter
public class Product {
    private final String id;
    private final String name;
    private final BigDecimal price;
    private final String description;
    private final Category category;
    private final LocalDateTime createdAt;
    
    public static class ProductBuilder {
        // Lombok generates this
    }
}
```

#### Factory Pattern
```java
public interface PaymentProcessor {
    void processPayment(BigDecimal amount);
}

public class PaymentProcessorFactory {
    
    public PaymentProcessor createProcessor(PaymentType type) {
        return switch (type) {
            case CREDIT_CARD -> new CreditCardProcessor();
            case PAYPAL -> new PayPalProcessor();
            case STRIPE -> new StripeProcessor();
            default -> throw new IllegalArgumentException("Unknown payment type");
        };
    }
}
```

### 4. Stream API and Functional Programming

```java
public class DataProcessor {
    
    public List<ProductDto> getActiveProducts(List<Product> products) {
        return products.stream()
            .filter(Product::isActive)
            .filter(p -> p.getPrice().compareTo(BigDecimal.ZERO) > 0)
            .sorted(Comparator.comparing(Product::getName))
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }
    
    public Map<Category, List<Product>> groupByCategory(List<Product> products) {
        return products.stream()
            .collect(Collectors.groupingBy(Product::getCategory));
    }
    
    public Optional<Product> findMostExpensive(List<Product> products) {
        return products.stream()
            .max(Comparator.comparing(Product::getPrice));
    }
    
    public BigDecimal calculateTotalPrice(List<Product> products) {
        return products.stream()
            .map(Product::getPrice)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}
```

### 5. Concurrency and Multithreading

```java
@Component
public class AsyncService {
    
    private final ExecutorService executorService = 
        Executors.newFixedThreadPool(10);
    
    @Async
    public CompletableFuture<String> processAsync(String data) {
        return CompletableFuture.supplyAsync(() -> {
            // Simulate long-running task
            try {
                Thread.sleep(2000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            return "Processed: " + data;
        }, executorService);
    }
    
    public void processWithThreadPool(List<Task> tasks) {
        List<CompletableFuture<Result>> futures = tasks.stream()
            .map(task -> CompletableFuture.supplyAsync(
                () -> processTask(task), 
                executorService
            ))
            .collect(Collectors.toList());
            
        CompletableFuture.allOf(
            futures.toArray(new CompletableFuture[0])
        ).join();
    }
    
    @PreDestroy
    public void shutdown() {
        executorService.shutdown();
        try {
            if (!executorService.awaitTermination(60, TimeUnit.SECONDS)) {
                executorService.shutdownNow();
            }
        } catch (InterruptedException e) {
            executorService.shutdownNow();
        }
    }
}
```

### 6. Database Access with JPA

```java
@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(unique = true, nullable = false)
    private String email;
    
    @Column(nullable = false)
    private String name;
    
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<Order> orders = new ArrayList<>();
    
    @ManyToMany
    @JoinTable(
        name = "user_roles",
        joinColumns = @JoinColumn(name = "user_id"),
        inverseJoinColumns = @JoinColumn(name = "role_id")
    )
    private Set<Role> roles = new HashSet<>();
    
    @CreationTimestamp
    private LocalDateTime createdAt;
    
    @UpdateTimestamp
    private LocalDateTime updatedAt;
}

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    
    Optional<User> findByEmail(String email);
    
    @Query("SELECT u FROM User u LEFT JOIN FETCH u.roles WHERE u.id = :id")
    Optional<User> findByIdWithRoles(@Param("id") Long id);
    
    @Modifying
    @Query("UPDATE User u SET u.lastLogin = :lastLogin WHERE u.id = :id")
    void updateLastLogin(@Param("id") Long id, @Param("lastLogin") LocalDateTime lastLogin);
    
    Page<User> findByNameContainingIgnoreCase(String name, Pageable pageable);
}
```

### 7. REST API Design

```java
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Validated
public class UserController {
    
    private final UserService userService;
    
    @GetMapping
    public ResponseEntity<Page<UserDto>> getUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sortBy) {
        
        Pageable pageable = PageRequest.of(page, size, Sort.by(sortBy));
        Page<UserDto> users = userService.findAll(pageable);
        
        return ResponseEntity.ok(users);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<UserDto> getUser(@PathVariable Long id) {
        return userService.findById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }
    
    @PostMapping
    public ResponseEntity<UserDto> createUser(
            @Valid @RequestBody UserCreateDto dto) {
        
        UserDto created = userService.create(dto);
        URI location = ServletUriComponentsBuilder
            .fromCurrentRequest()
            .path("/{id}")
            .buildAndExpand(created.getId())
            .toUri();
            
        return ResponseEntity.created(location).body(created);
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<UserDto> updateUser(
            @PathVariable Long id,
            @Valid @RequestBody UserUpdateDto dto) {
        
        return userService.update(id, dto)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }
    
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteUser(@PathVariable Long id) {
        userService.delete(id);
    }
}
```

### 8. Testing

```java
@SpringBootTest
@AutoConfigureMockMvc
class UserControllerTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @MockBean
    private UserService userService;
    
    @Test
    void shouldGetUserById() throws Exception {
        UserDto user = UserDto.builder()
            .id(1L)
            .name("John Doe")
            .email("john@example.com")
            .build();
            
        when(userService.findById(1L)).thenReturn(Optional.of(user));
        
        mockMvc.perform(get("/api/v1/users/1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(1))
            .andExpect(jsonPath("$.name").value("John Doe"))
            .andExpect(jsonPath("$.email").value("john@example.com"));
    }
    
    @Test
    void shouldCreateUser() throws Exception {
        UserCreateDto createDto = new UserCreateDto("John", "john@example.com");
        UserDto created = UserDto.builder()
            .id(1L)
            .name("John")
            .email("john@example.com")
            .build();
            
        when(userService.create(any())).thenReturn(created);
        
        mockMvc.perform(post("/api/v1/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(createDto)))
            .andExpect(status().isCreated())
            .andExpect(header().exists("Location"));
    }
}

@DataJpaTest
class UserRepositoryTest {
    
    @Autowired
    private TestEntityManager entityManager;
    
    @Autowired
    private UserRepository userRepository;
    
    @Test
    void shouldFindByEmail() {
        User user = User.builder()
            .name("John Doe")
            .email("john@example.com")
            .build();
            
        entityManager.persistAndFlush(user);
        
        Optional<User> found = userRepository.findByEmail("john@example.com");
        
        assertThat(found).isPresent();
        assertThat(found.get().getName()).isEqualTo("John Doe");
    }
}
```

## Modern Java Features (Java 8+)

### 1. Records (Java 14+)
```java
public record UserDto(
    Long id,
    String name,
    String email,
    LocalDateTime createdAt
) {}
```

### 2. Pattern Matching (Java 17+)
```java
public String processObject(Object obj) {
    return switch (obj) {
        case Integer i -> "Integer: " + i;
        case String s && s.length() > 5 -> "Long string: " + s;
        case String s -> "Short string: " + s;
        case null -> "Null value";
        default -> "Unknown type";
    };
}
```

### 3. Text Blocks (Java 15+)
```java
String json = """
    {
        "name": "John Doe",
        "email": "john@example.com",
        "age": 30
    }
    """;
```

### 4. Sealed Classes (Java 17+)
```java
public sealed interface Shape
    permits Circle, Rectangle, Triangle {
}

public final class Circle implements Shape {
    private final double radius;
}

public final class Rectangle implements Shape {
    private final double width, height;
}
```

## Performance Optimization

1. **Use StringBuilder for string concatenation in loops**
2. **Prefer primitives over wrapper classes**
3. **Use lazy initialization for expensive objects**
4. **Implement proper equals() and hashCode()**
5. **Use appropriate collection types**
6. **Enable JVM optimizations with proper flags**
7. **Profile before optimizing**

## Security Best Practices

1. **Input validation**: Always validate and sanitize input
2. **SQL injection prevention**: Use prepared statements
3. **Secure password storage**: Use BCrypt or Argon2
4. **HTTPS enforcement**: Always use TLS/SSL
5. **Dependency management**: Keep dependencies updated
6. **Least privilege principle**: Minimize permissions
7. **Secure session management**: Use proper timeout and invalidation

## Common Pitfalls

1. **Memory leaks**: Not closing resources properly
2. **Null pointer exceptions**: Not checking for null
3. **Thread safety issues**: Improper synchronization
4. **Resource exhaustion**: Not using connection pools
5. **Improper exception handling**: Swallowing exceptions
6. **String comparison with ==**: Use equals() instead

## Build Tools

### Maven Configuration
```xml
<project>
    <groupId>com.example</groupId>
    <artifactId>my-app</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <properties>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <spring.boot.version>3.1.0</spring.boot.version>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
    </dependencies>
</project>
```

### Gradle Configuration
```gradle
plugins {
    id 'java'
    id 'org.springframework.boot' version '3.1.0'
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
}
```

## Useful Libraries

- **Spring Boot**: Application framework
- **Lombok**: Boilerplate code reduction
- **MapStruct**: Object mapping
- **Jackson**: JSON processing
- **Hibernate**: ORM framework
- **JUnit 5**: Testing framework
- **Mockito**: Mocking framework
- **AssertJ**: Fluent assertions
- **Slf4j + Logback**: Logging
- **Apache Commons**: Utility libraries
- **Guava**: Google's core libraries
- **Vavr**: Functional programming