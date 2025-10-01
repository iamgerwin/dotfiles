# RestAssured Best Practices

## Official Documentation
- **RestAssured**: https://rest-assured.io
- **GitHub Repository**: https://github.com/rest-assured/rest-assured
- **User Guide**: https://github.com/rest-assured/rest-assured/wiki/Usage
- **API Documentation**: https://javadoc.io/doc/io.rest-assured/rest-assured/latest/index.html
- **Getting Started**: https://rest-assured.io/#get-started

## Installation and Setup

### Maven Configuration
```xml
<!-- pom.xml -->
<dependencies>
    <!-- RestAssured -->
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>rest-assured</artifactId>
        <version>5.5.0</version>
        <scope>test</scope>
    </dependency>

    <!-- JSON Schema Validation -->
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>json-schema-validator</artifactId>
        <version>5.5.0</version>
        <scope>test</scope>
    </dependency>

    <!-- XML Path -->
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>xml-path</artifactId>
        <version>5.5.0</version>
        <scope>test</scope>
    </dependency>

    <!-- JUnit 5 -->
    <dependency>
        <groupId>org.junit.jupiter</groupId>
        <artifactId>junit-jupiter</artifactId>
        <version>5.10.1</version>
        <scope>test</scope>
    </dependency>

    <!-- Hamcrest Matchers -->
    <dependency>
        <groupId>org.hamcrest</groupId>
        <artifactId>hamcrest</artifactId>
        <version>2.2</version>
        <scope>test</scope>
    </dependency>

    <!-- JSON Path -->
    <dependency>
        <groupId>com.jayway.jsonpath</groupId>
        <artifactId>json-path</artifactId>
        <version>2.9.0</version>
    </dependency>

    <!-- Lombok (Optional) -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <version>1.18.30</version>
        <scope>provided</scope>
    </dependency>

    <!-- AssertJ (Optional) -->
    <dependency>
        <groupId>org.assertj</groupId>
        <artifactId>assertj-core</artifactId>
        <version>3.25.1</version>
        <scope>test</scope>
    </dependency>
</dependencies>

<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-plugin</artifactId>
            <version>3.2.3</version>
            <configuration>
                <includes>
                    <include>**/*Test.java</include>
                    <include>**/*Tests.java</include>
                </includes>
            </configuration>
        </plugin>
    </plugins>
</build>
```

### Gradle Configuration
```groovy
// build.gradle
plugins {
    id 'java'
}

group = 'com.example'
version = '1.0.0'
sourceCompatibility = '17'

repositories {
    mavenCentral()
}

dependencies {
    // RestAssured
    testImplementation 'io.rest-assured:rest-assured:5.5.0'
    testImplementation 'io.rest-assured:json-schema-validator:5.5.0'
    testImplementation 'io.rest-assured:xml-path:5.5.0'

    // JUnit 5
    testImplementation 'org.junit.jupiter:junit-jupiter:5.10.1'

    // Hamcrest Matchers
    testImplementation 'org.hamcrest:hamcrest:2.2'

    // JSON Path
    testImplementation 'com.jayway.jsonpath:json-path:2.9.0'

    // Lombok (Optional)
    compileOnly 'org.projectlombok:lombok:1.18.30'
    annotationProcessor 'org.projectlombok:lombok:1.18.30'

    // AssertJ (Optional)
    testImplementation 'org.assertj:assertj-core:3.25.1'
}

test {
    useJUnitPlatform()

    testLogging {
        events "passed", "skipped", "failed"
        showStandardStreams = false
    }

    systemProperty 'base.url', System.getProperty('base.url', 'https://api.example.com')
    systemProperty 'api.version', System.getProperty('api.version', 'v1')
}
```

## Project Structure and Configuration

### Recommended Directory Structure
```
src/
├── main/
│   └── java/
│       └── com/
│           └── example/
│               └── api/
│                   ├── models/
│                   │   ├── User.java
│                   │   ├── Product.java
│                   │   └── Order.java
│                   └── utils/
│                       ├── ConfigReader.java
│                       └── DataGenerator.java
└── test/
    ├── java/
    │   └── com/
    │       └── example/
    │           └── api/
    │               ├── tests/
    │               │   ├── UserTests.java
    │               │   ├── ProductTests.java
    │               │   └── OrderTests.java
    │               ├── specs/
    │               │   ├── RequestSpecs.java
    │               │   └── ResponseSpecs.java
    │               ├── base/
    │               │   └── BaseTest.java
    │               └── utils/
    │                   ├── TestUtils.java
    │                   └── AuthHelper.java
    └── resources/
        ├── config/
        │   ├── dev.properties
        │   ├── staging.properties
        │   └── production.properties
        ├── schemas/
        │   ├── user-schema.json
        │   ├── product-schema.json
        │   └── order-schema.json
        ├── testdata/
        │   ├── users.json
        │   └── products.csv
        └── log4j2.xml
```

### Base Test Configuration
```java
// src/test/java/com/example/api/base/BaseTest.java
package com.example.api.base;

import io.restassured.RestAssured;
import io.restassured.builder.RequestSpecBuilder;
import io.restassured.builder.ResponseSpecBuilder;
import io.restassured.filter.log.RequestLoggingFilter;
import io.restassured.filter.log.ResponseLoggingFilter;
import io.restassured.http.ContentType;
import io.restassured.specification.RequestSpecification;
import io.restassured.specification.ResponseSpecification;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

public class BaseTest {

    protected static String BASE_URL;
    protected static String API_VERSION;
    protected static RequestSpecification requestSpec;
    protected static ResponseSpecification responseSpec;
    protected String authToken;

    @BeforeAll
    public static void globalSetup() {
        loadConfiguration();
        configureRestAssured();
        setupRequestSpecification();
        setupResponseSpecification();
    }

    @BeforeEach
    public void testSetup() {
        // Reset base URI for each test
        RestAssured.baseURI = BASE_URL;
    }

    private static void loadConfiguration() {
        Properties properties = new Properties();
        String env = System.getProperty("env", "dev");

        try (FileInputStream fis = new FileInputStream(
                "src/test/resources/config/" + env + ".properties")) {
            properties.load(fis);
            BASE_URL = properties.getProperty("base.url");
            API_VERSION = properties.getProperty("api.version");
        } catch (IOException e) {
            throw new RuntimeException("Failed to load configuration", e);
        }
    }

    private static void configureRestAssured() {
        RestAssured.baseURI = BASE_URL;
        RestAssured.basePath = "/api/" + API_VERSION;
        RestAssured.enableLoggingOfRequestAndResponseIfValidationFails();

        // Connection and read timeout
        RestAssured.config = RestAssured.config()
                .httpClient(io.restassured.config.HttpClientConfig.httpClientConfig()
                        .setParam("http.connection.timeout", 10000)
                        .setParam("http.socket.timeout", 30000));
    }

    private static void setupRequestSpecification() {
        RequestSpecBuilder builder = new RequestSpecBuilder();
        builder.setContentType(ContentType.JSON);
        builder.setAccept(ContentType.JSON);
        builder.addHeader("User-Agent", "RestAssured/5.5.0");
        builder.addHeader("Accept-Language", "en-US");

        // Add logging filters for debugging
        if (Boolean.parseBoolean(System.getProperty("enable.logging", "false"))) {
            builder.addFilter(new RequestLoggingFilter());
            builder.addFilter(new ResponseLoggingFilter());
        }

        requestSpec = builder.build();
    }

    private static void setupResponseSpecification() {
        ResponseSpecBuilder builder = new ResponseSpecBuilder();
        builder.expectResponseTime(org.hamcrest.Matchers.lessThan(5000L));
        builder.expectContentType(ContentType.JSON);

        responseSpec = builder.build();
    }

    protected void setAuthToken(String token) {
        this.authToken = token;
    }
}
```

### Configuration Properties
```properties
# src/test/resources/config/dev.properties
base.url=http://localhost:8080
api.version=v1
auth.username=test@example.com
auth.password=Test123!
default.timeout=30000
connection.timeout=10000
enable.logging=true
```

```properties
# src/test/resources/config/staging.properties
base.url=https://staging-api.example.com
api.version=v1
auth.username=staging@example.com
auth.password=StagingPass123!
default.timeout=30000
connection.timeout=10000
enable.logging=false
```

```properties
# src/test/resources/config/production.properties
base.url=https://api.example.com
api.version=v1
auth.username=prod@example.com
auth.password=ProdPass123!
default.timeout=30000
connection.timeout=10000
enable.logging=false
```

## Core Concepts

### Given-When-Then Syntax
RestAssured follows the BDD (Behavior-Driven Development) pattern with a fluent API that reads naturally:

```java
package com.example.api.tests;

import io.restassured.response.Response;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;

public class BasicSyntaxExamples {

    @Test
    public void basicGetRequest() {
        // Given-When-Then pattern
        given()
            .baseUri("https://api.example.com")
            .basePath("/api/v1")
            .header("Content-Type", "application/json")
        .when()
            .get("/users/1")
        .then()
            .statusCode(200)
            .body("id", equalTo(1))
            .body("email", notNullValue());
    }

    @Test
    public void postRequestWithBody() {
        String requestBody = """
            {
                "name": "John Doe",
                "email": "john.doe@example.com",
                "age": 30
            }
            """;

        given()
            .contentType("application/json")
            .body(requestBody)
        .when()
            .post("https://api.example.com/api/v1/users")
        .then()
            .statusCode(201)
            .body("name", equalTo("John Doe"))
            .body("email", equalTo("john.doe@example.com"))
            .body("id", notNullValue());
    }

    @Test
    public void extractResponseData() {
        Response response =
            given()
                .contentType("application/json")
            .when()
                .get("https://api.example.com/api/v1/users/1")
            .then()
                .statusCode(200)
                .extract()
                .response();

        // Extract specific values
        String email = response.path("email");
        int id = response.path("id");

        System.out.println("User ID: " + id);
        System.out.println("User Email: " + email);
    }

    @Test
    public void queryParameters() {
        given()
            .queryParam("page", 1)
            .queryParam("limit", 20)
            .queryParam("sort", "name")
        .when()
            .get("https://api.example.com/api/v1/users")
        .then()
            .statusCode(200)
            .body("data.size()", lessThanOrEqualTo(20));
    }

    @Test
    public void pathParameters() {
        int userId = 42;

        given()
            .pathParam("userId", userId)
        .when()
            .get("https://api.example.com/api/v1/users/{userId}")
        .then()
            .statusCode(200)
            .body("id", equalTo(userId));
    }
}
```

### Request and Response Specifications
Specifications allow you to reuse common request/response configurations across tests:

```java
// src/test/java/com/example/api/specs/RequestSpecs.java
package com.example.api.specs;

import io.restassured.builder.RequestSpecBuilder;
import io.restassured.http.ContentType;
import io.restassured.specification.RequestSpecification;

public class RequestSpecs {

    public static RequestSpecification jsonRequestSpec() {
        return new RequestSpecBuilder()
                .setBaseUri("https://api.example.com")
                .setBasePath("/api/v1")
                .setContentType(ContentType.JSON)
                .setAccept(ContentType.JSON)
                .addHeader("User-Agent", "RestAssured/5.5.0")
                .build();
    }

    public static RequestSpecification authenticatedSpec(String token) {
        return new RequestSpecBuilder()
                .addRequestSpecification(jsonRequestSpec())
                .addHeader("Authorization", "Bearer " + token)
                .build();
    }

    public static RequestSpecification adminSpec(String token) {
        return new RequestSpecBuilder()
                .addRequestSpecification(authenticatedSpec(token))
                .addHeader("X-User-Role", "admin")
                .build();
    }

    public static RequestSpecification multipartSpec() {
        return new RequestSpecBuilder()
                .setBaseUri("https://api.example.com")
                .setBasePath("/api/v1")
                .setContentType(ContentType.MULTIPART)
                .build();
    }
}
```

```java
// src/test/java/com/example/api/specs/ResponseSpecs.java
package com.example.api.specs;

import io.restassured.builder.ResponseSpecBuilder;
import io.restassured.http.ContentType;
import io.restassured.specification.ResponseSpecification;
import static org.hamcrest.Matchers.*;

public class ResponseSpecs {

    public static ResponseSpecification successResponseSpec() {
        return new ResponseSpecBuilder()
                .expectStatusCode(200)
                .expectContentType(ContentType.JSON)
                .expectResponseTime(lessThan(3000L))
                .build();
    }

    public static ResponseSpecification createdResponseSpec() {
        return new ResponseSpecBuilder()
                .expectStatusCode(201)
                .expectContentType(ContentType.JSON)
                .expectHeader("Location", notNullValue())
                .expectResponseTime(lessThan(3000L))
                .build();
    }

    public static ResponseSpecification noContentResponseSpec() {
        return new ResponseSpecBuilder()
                .expectStatusCode(204)
                .build();
    }

    public static ResponseSpecification validationErrorSpec() {
        return new ResponseSpecBuilder()
                .expectStatusCode(400)
                .expectContentType(ContentType.JSON)
                .expectBody("message", notNullValue())
                .expectBody("errors", notNullValue())
                .build();
    }

    public static ResponseSpecification unauthorizedSpec() {
        return new ResponseSpecBuilder()
                .expectStatusCode(401)
                .expectBody("message", containsString("Unauthorized"))
                .build();
    }
}
```

### Using Specifications in Tests
```java
package com.example.api.tests;

import com.example.api.specs.RequestSpecs;
import com.example.api.specs.ResponseSpecs;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.*;

public class SpecificationUsageTests {

    @Test
    public void getUserWithSpecs() {
        given()
            .spec(RequestSpecs.jsonRequestSpec())
        .when()
            .get("/users/1")
        .then()
            .spec(ResponseSpecs.successResponseSpec());
    }

    @Test
    public void createUserWithSpecs() {
        String requestBody = """
            {
                "name": "Jane Smith",
                "email": "jane.smith@example.com"
            }
            """;

        given()
            .spec(RequestSpecs.jsonRequestSpec())
            .body(requestBody)
        .when()
            .post("/users")
        .then()
            .spec(ResponseSpecs.createdResponseSpec());
    }

    @Test
    public void deleteUserWithSpecs() {
        String token = "your-auth-token";

        given()
            .spec(RequestSpecs.authenticatedSpec(token))
        .when()
            .delete("/users/1")
        .then()
            .spec(ResponseSpecs.noContentResponseSpec());
    }
}
```

## Authentication Examples

### Basic Authentication
```java
package com.example.api.tests;

import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.*;

public class BasicAuthTests {

    @Test
    public void basicAuthPreemptive() {
        given()
            .auth()
            .preemptive()
            .basic("username", "password")
        .when()
            .get("https://api.example.com/api/v1/protected")
        .then()
            .statusCode(200);
    }

    @Test
    public void basicAuthChallenge() {
        // Only sends credentials after receiving 401
        given()
            .auth()
            .basic("username", "password")
        .when()
            .get("https://api.example.com/api/v1/protected")
        .then()
            .statusCode(200);
    }

    @Test
    public void basicAuthWithHeader() {
        String credentials = java.util.Base64.getEncoder()
                .encodeToString("username:password".getBytes());

        given()
            .header("Authorization", "Basic " + credentials)
        .when()
            .get("https://api.example.com/api/v1/protected")
        .then()
            .statusCode(200);
    }
}
```

### Bearer Token Authentication
```java
package com.example.api.tests;

import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;

public class BearerAuthTests {

    private static String authToken;

    @BeforeAll
    public static void login() {
        String credentials = """
            {
                "email": "user@example.com",
                "password": "SecurePass123!"
            }
            """;

        Response response =
            given()
                .contentType("application/json")
                .body(credentials)
            .when()
                .post("https://api.example.com/api/v1/auth/login")
            .then()
                .statusCode(200)
                .body("accessToken", notNullValue())
                .extract()
                .response();

        authToken = response.path("accessToken");
    }

    @Test
    public void accessProtectedResourceWithToken() {
        given()
            .header("Authorization", "Bearer " + authToken)
        .when()
            .get("https://api.example.com/api/v1/users/me")
        .then()
            .statusCode(200)
            .body("email", equalTo("user@example.com"));
    }

    @Test
    public void accessProtectedResourceWithAuth() {
        given()
            .auth()
            .oauth2(authToken)
        .when()
            .get("https://api.example.com/api/v1/users/me")
        .then()
            .statusCode(200);
    }

    @Test
    public void refreshToken() {
        Response loginResponse =
            given()
                .contentType("application/json")
                .body("""
                    {
                        "email": "user@example.com",
                        "password": "SecurePass123!"
                    }
                    """)
            .when()
                .post("https://api.example.com/api/v1/auth/login")
            .then()
                .extract()
                .response();

        String refreshToken = loginResponse.path("refreshToken");

        given()
            .contentType("application/json")
            .body(String.format("{\"refreshToken\": \"%s\"}", refreshToken))
        .when()
            .post("https://api.example.com/api/v1/auth/refresh")
        .then()
            .statusCode(200)
            .body("accessToken", notNullValue());
    }
}
```

### OAuth 2.0 Authentication
```java
package com.example.api.tests;

import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;

public class OAuth2Tests {

    private static String accessToken;

    @BeforeAll
    public static void obtainAccessToken() {
        // Client Credentials Flow
        Response response =
            given()
                .contentType("application/x-www-form-urlencoded")
                .formParam("grant_type", "client_credentials")
                .formParam("client_id", "your-client-id")
                .formParam("client_secret", "your-client-secret")
                .formParam("scope", "read write")
            .when()
                .post("https://oauth.example.com/oauth/token")
            .then()
                .statusCode(200)
                .body("access_token", notNullValue())
                .body("token_type", equalTo("Bearer"))
                .extract()
                .response();

        accessToken = response.path("access_token");
    }

    @Test
    public void useOAuthToken() {
        given()
            .auth()
            .oauth2(accessToken)
        .when()
            .get("https://api.example.com/api/v1/protected/resource")
        .then()
            .statusCode(200);
    }

    @Test
    public void passwordGrantFlow() {
        Response response =
            given()
                .contentType("application/x-www-form-urlencoded")
                .formParam("grant_type", "password")
                .formParam("username", "user@example.com")
                .formParam("password", "UserPassword123!")
                .formParam("client_id", "your-client-id")
                .formParam("client_secret", "your-client-secret")
            .when()
                .post("https://oauth.example.com/oauth/token")
            .then()
                .statusCode(200)
                .body("access_token", notNullValue())
                .extract()
                .response();

        String token = response.path("access_token");

        given()
            .auth()
            .oauth2(token)
        .when()
            .get("https://api.example.com/api/v1/users/me")
        .then()
            .statusCode(200);
    }
}
```

### API Key Authentication
```java
package com.example.api.tests;

import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.*;

public class ApiKeyAuthTests {

    private static final String API_KEY = "your-api-key-here";

    @Test
    public void apiKeyInHeader() {
        given()
            .header("X-API-Key", API_KEY)
        .when()
            .get("https://api.example.com/api/v1/data")
        .then()
            .statusCode(200);
    }

    @Test
    public void apiKeyInQueryParam() {
        given()
            .queryParam("api_key", API_KEY)
        .when()
            .get("https://api.example.com/api/v1/data")
        .then()
            .statusCode(200);
    }

    @Test
    public void customAuthHeader() {
        given()
            .header("Authorization", "ApiKey " + API_KEY)
        .when()
            .get("https://api.example.com/api/v1/data")
        .then()
            .statusCode(200);
    }
}
```

## Request and Response Validation

### Request Body Validation
```java
package com.example.api.tests;

import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;
import java.util.Map;
import java.util.HashMap;

public class RequestValidationTests {

    @Test
    public void validateRequestWithString() {
        String requestBody = """
            {
                "name": "John Doe",
                "email": "john@example.com",
                "age": 30
            }
            """;

        given()
            .contentType("application/json")
            .body(requestBody)
        .when()
            .post("https://api.example.com/api/v1/users")
        .then()
            .statusCode(201);
    }

    @Test
    public void validateRequestWithMap() {
        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("name", "Jane Smith");
        requestBody.put("email", "jane@example.com");
        requestBody.put("age", 28);

        given()
            .contentType("application/json")
            .body(requestBody)
        .when()
            .post("https://api.example.com/api/v1/users")
        .then()
            .statusCode(201)
            .body("name", equalTo("Jane Smith"));
    }

    @Test
    public void validateRequestWithPOJO() {
        User user = new User("Bob Johnson", "bob@example.com", 35);

        given()
            .contentType("application/json")
            .body(user)
        .when()
            .post("https://api.example.com/api/v1/users")
        .then()
            .statusCode(201)
            .body("name", equalTo(user.getName()));
    }

    // User POJO
    static class User {
        private String name;
        private String email;
        private int age;

        public User(String name, String email, int age) {
            this.name = name;
            this.email = email;
            this.age = age;
        }

        public String getName() { return name; }
        public String getEmail() { return email; }
        public int getAge() { return age; }
    }
}
```

### Response Validation
```java
package com.example.api.tests;

import io.restassured.response.Response;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;
import static org.assertj.core.api.Assertions.*;

public class ResponseValidationTests {

    @Test
    public void validateStatusCode() {
        given()
            .get("https://api.example.com/api/v1/users/1")
        .then()
            .statusCode(200)
            .statusLine(containsString("OK"));
    }

    @Test
    public void validateHeaders() {
        given()
            .get("https://api.example.com/api/v1/users/1")
        .then()
            .header("Content-Type", "application/json")
            .header("X-RateLimit-Limit", notNullValue())
            .header("Cache-Control", containsString("no-cache"));
    }

    @Test
    public void validateResponseBody() {
        given()
            .get("https://api.example.com/api/v1/users/1")
        .then()
            .body("id", equalTo(1))
            .body("name", notNullValue())
            .body("email", endsWith("@example.com"))
            .body("age", greaterThan(0))
            .body("isActive", equalTo(true));
    }

    @Test
    public void validateNestedFields() {
        given()
            .get("https://api.example.com/api/v1/users/1")
        .then()
            .body("address.street", notNullValue())
            .body("address.city", equalTo("New York"))
            .body("address.zipCode", matchesPattern("\\d{5}"))
            .body("contacts.phone", notNullValue())
            .body("contacts.email", endsWith("@example.com"));
    }

    @Test
    public void validateArrays() {
        given()
            .get("https://api.example.com/api/v1/users")
        .then()
            .body("data.size()", greaterThan(0))
            .body("data[0].id", notNullValue())
            .body("data[0].name", notNullValue())
            .body("data.findAll { it.age > 18 }.size()", greaterThan(0));
    }

    @Test
    public void validateWithAssertJ() {
        Response response =
            given()
                .get("https://api.example.com/api/v1/users/1")
            .then()
                .statusCode(200)
                .extract()
                .response();

        String name = response.path("name");
        int age = response.path("age");

        assertThat(name).isNotNull().contains("Doe");
        assertThat(age).isGreaterThan(18).isLessThan(100);
    }

    @Test
    public void validateResponseTime() {
        given()
            .get("https://api.example.com/api/v1/users/1")
        .then()
            .time(lessThan(2000L)); // milliseconds
    }

    @Test
    public void extractAndValidate() {
        String email =
            given()
                .get("https://api.example.com/api/v1/users/1")
            .then()
                .statusCode(200)
                .extract()
                .path("email");

        assertThat(email).isNotNull().endsWith("@example.com");
    }
}
```

## JSON and XML Path Assertions

### JSON Path Examples
```java
package com.example.api.tests;

import io.restassured.path.json.JsonPath;
import io.restassured.response.Response;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;
import static org.assertj.core.api.Assertions.*;
import java.util.List;
import java.util.Map;

public class JsonPathTests {

    @Test
    public void basicJsonPathAssertions() {
        given()
            .get("https://api.example.com/api/v1/users/1")
        .then()
            .body("id", equalTo(1))
            .body("name", notNullValue())
            .body("email", containsString("@"))
            .body("address.city", equalTo("New York"))
            .body("roles[0]", equalTo("user"))
            .body("roles", hasItem("admin"));
    }

    @Test
    public void advancedJsonPathQueries() {
        given()
            .get("https://api.example.com/api/v1/users")
        .then()
            // Find all users with age > 25
            .body("data.findAll { it.age > 25 }.name", hasItem("John Doe"))
            // Get the first user's email
            .body("data[0].email", notNullValue())
            // Check if any user is admin
            .body("data.roles.flatten()", hasItem("admin"))
            // Count active users
            .body("data.findAll { it.isActive == true }.size()", greaterThan(0))
            // Sum all ages
            .body("data.age.sum()", greaterThan(0));
    }

    @Test
    public void extractJsonPathValues() {
        Response response =
            given()
                .get("https://api.example.com/api/v1/users")
            .then()
                .statusCode(200)
                .extract()
                .response();

        JsonPath jsonPath = response.jsonPath();

        // Extract single values
        String firstName = jsonPath.getString("data[0].name");
        int firstUserId = jsonPath.getInt("data[0].id");

        // Extract lists
        List<String> allNames = jsonPath.getList("data.name");
        List<Integer> allIds = jsonPath.getList("data.id", Integer.class);

        // Extract filtered lists
        List<String> adminEmails = jsonPath.getList(
            "data.findAll { it.roles.contains('admin') }.email"
        );

        // Extract nested objects
        Map<String, Object> firstUser = jsonPath.getMap("data[0]");

        assertThat(allNames).isNotEmpty().contains(firstName);
        assertThat(allIds).contains(firstUserId);
        assertThat(firstUser).containsKeys("id", "name", "email");
    }

    @Test
    public void complexJsonPathScenarios() {
        String jsonResponse = """
            {
                "users": [
                    {
                        "id": 1,
                        "name": "John",
                        "orders": [
                            {"id": 101, "total": 150.00, "status": "completed"},
                            {"id": 102, "total": 200.00, "status": "pending"}
                        ]
                    },
                    {
                        "id": 2,
                        "name": "Jane",
                        "orders": [
                            {"id": 103, "total": 300.00, "status": "completed"}
                        ]
                    }
                ]
            }
            """;

        JsonPath jsonPath = new JsonPath(jsonResponse);

        // Get all completed orders
        List<Map<String, Object>> completedOrders = jsonPath.getList(
            "users.orders.flatten().findAll { it.status == 'completed' }"
        );

        // Calculate total revenue from completed orders
        double totalRevenue = jsonPath.getDouble(
            "users.orders.flatten().findAll { it.status == 'completed' }.total.sum()"
        );

        // Get users with pending orders
        List<String> usersWithPending = jsonPath.getList(
            "users.findAll { it.orders.any { order -> order.status == 'pending' } }.name"
        );

        assertThat(completedOrders).hasSize(2);
        assertThat(totalRevenue).isEqualTo(450.00);
        assertThat(usersWithPending).contains("John");
    }
}
```

### XML Path Examples
```java
package com.example.api.tests;

import io.restassured.path.xml.XmlPath;
import io.restassured.response.Response;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;
import static org.assertj.core.api.Assertions.*;
import java.util.List;

public class XmlPathTests {

    @Test
    public void basicXmlPathAssertions() {
        given()
            .accept("application/xml")
        .when()
            .get("https://api.example.com/api/v1/users/1")
        .then()
            .body("user.id", equalTo("1"))
            .body("user.name", notNullValue())
            .body("user.email", containsString("@"))
            .body("user.address.city", equalTo("New York"));
    }

    @Test
    public void extractXmlPathValues() {
        Response response =
            given()
                .accept("application/xml")
            .when()
                .get("https://api.example.com/api/v1/users")
            .then()
                .statusCode(200)
                .extract()
                .response();

        XmlPath xmlPath = response.xmlPath();

        // Extract single values
        String firstName = xmlPath.getString("users.user[0].name");
        int firstUserId = xmlPath.getInt("users.user[0].id");

        // Extract lists
        List<String> allNames = xmlPath.getList("users.user.name");
        List<Integer> allIds = xmlPath.getList("users.user.id", Integer.class);

        // Extract with attributes
        String userType = xmlPath.getString("users.user[0].@type");

        assertThat(allNames).isNotEmpty();
        assertThat(allIds).contains(firstUserId);
    }

    @Test
    public void xmlPathWithNamespaces() {
        String xmlWithNamespace = """
            <?xml version="1.0" encoding="UTF-8"?>
            <ns:users xmlns:ns="http://example.com/users">
                <ns:user id="1">
                    <ns:name>John Doe</ns:name>
                    <ns:email>john@example.com</ns:email>
                </ns:user>
            </ns:users>
            """;

        XmlPath xmlPath = new XmlPath(xmlWithNamespace)
                .using(XmlPath.CompatibilityMode.HTML);

        String name = xmlPath.getString("users.user.name");
        String email = xmlPath.getString("users.user.email");

        assertThat(name).isEqualTo("John Doe");
        assertThat(email).isEqualTo("john@example.com");
    }

    @Test
    public void complexXmlPathQueries() {
        given()
            .accept("application/xml")
        .when()
            .get("https://api.example.com/api/v1/users")
        .then()
            // Find users by attribute
            .body("users.user.find { it.@status == 'active' }.name", notNullValue())
            // Count elements
            .body("users.user.size()", greaterThan(0))
            // Filter and extract
            .body("users.user.findAll { it.age > 25 }.name", hasItem("John"));
    }
}
```

## Schema Validation

### JSON Schema Validation
```json
// src/test/resources/schemas/user-schema.json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "User",
  "type": "object",
  "required": ["id", "name", "email"],
  "properties": {
    "id": {
      "type": "integer",
      "minimum": 1
    },
    "name": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "email": {
      "type": "string",
      "format": "email"
    },
    "age": {
      "type": "integer",
      "minimum": 0,
      "maximum": 150
    },
    "isActive": {
      "type": "boolean"
    },
    "address": {
      "type": "object",
      "properties": {
        "street": { "type": "string" },
        "city": { "type": "string" },
        "state": { "type": "string" },
        "zipCode": {
          "type": "string",
          "pattern": "^\\d{5}(-\\d{4})?$"
        }
      },
      "required": ["city", "state"]
    },
    "roles": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["user", "admin", "moderator"]
      },
      "minItems": 1
    },
    "createdAt": {
      "type": "string",
      "format": "date-time"
    }
  }
}
```

```json
// src/test/resources/schemas/users-list-schema.json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "UsersList",
  "type": "object",
  "required": ["data", "total", "page"],
  "properties": {
    "data": {
      "type": "array",
      "items": {
        "$ref": "user-schema.json"
      }
    },
    "total": {
      "type": "integer",
      "minimum": 0
    },
    "page": {
      "type": "integer",
      "minimum": 1
    },
    "limit": {
      "type": "integer",
      "minimum": 1,
      "maximum": 100
    }
  }
}
```

### Schema Validation Tests
```java
package com.example.api.tests;

import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.*;
import static io.restassured.module.jsv.JsonSchemaValidator.*;
import static org.hamcrest.Matchers.*;

public class SchemaValidationTests {

    @Test
    public void validateUserSchema() {
        given()
            .get("https://api.example.com/api/v1/users/1")
        .then()
            .statusCode(200)
            .body(matchesJsonSchemaInClasspath("schemas/user-schema.json"));
    }

    @Test
    public void validateUsersListSchema() {
        given()
            .get("https://api.example.com/api/v1/users")
        .then()
            .statusCode(200)
            .body(matchesJsonSchemaInClasspath("schemas/users-list-schema.json"));
    }

    @Test
    public void validateSchemaWithSettings() {
        given()
            .get("https://api.example.com/api/v1/users/1")
        .then()
            .statusCode(200)
            .body(matchesJsonSchemaInClasspath("schemas/user-schema.json")
                    .using(jsonSchemaFactory ->
                        jsonSchemaFactory.setValidationEnabled(true)));
    }

    @Test
    public void validateInlineSchema() {
        String schema = """
            {
                "type": "object",
                "required": ["id", "name", "email"],
                "properties": {
                    "id": { "type": "integer" },
                    "name": { "type": "string" },
                    "email": { "type": "string", "format": "email" }
                }
            }
            """;

        given()
            .get("https://api.example.com/api/v1/users/1")
        .then()
            .statusCode(200)
            .body(matchesJsonSchema(schema));
    }

    @Test
    public void validateSchemaStrictMode() {
        // Strict mode will fail if response has extra fields not in schema
        given()
            .get("https://api.example.com/api/v1/users/1")
        .then()
            .statusCode(200)
            .body(matchesJsonSchemaInClasspath("schemas/user-schema.json")
                    .using(settings -> settings.with().checkedValidation(false)));
    }
}
```

## Data-Driven Testing

### Using External Data Files
```json
// src/test/resources/testdata/users.json
[
  {
    "name": "John Doe",
    "email": "john.doe@example.com",
    "age": 30
  },
  {
    "name": "Jane Smith",
    "email": "jane.smith@example.com",
    "age": 28
  },
  {
    "name": "Bob Johnson",
    "email": "bob.johnson@example.com",
    "age": 35
  }
]
```

```csv
# src/test/resources/testdata/products.csv
name,price,category,inStock
Laptop,999.99,Electronics,true
Mouse,29.99,Electronics,true
Desk,299.99,Furniture,false
Chair,199.99,Furniture,true
Monitor,449.99,Electronics,true
```

### Data-Driven Test Implementation
```java
package com.example.api.tests;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvFileSource;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.ValueSource;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;

import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;

public class DataDrivenTests {

    @ParameterizedTest
    @ValueSource(ints = {1, 2, 3, 4, 5})
    public void testMultipleUserIds(int userId) {
        given()
            .pathParam("userId", userId)
        .when()
            .get("https://api.example.com/api/v1/users/{userId}")
        .then()
            .statusCode(200)
            .body("id", equalTo(userId));
    }

    @ParameterizedTest
    @CsvFileSource(resources = "/testdata/products.csv", numLinesToSkip = 1)
    public void testProductCreation(String name, double price, String category, boolean inStock) {
        Map<String, Object> product = Map.of(
            "name", name,
            "price", price,
            "category", category,
            "inStock", inStock
        );

        given()
            .contentType("application/json")
            .body(product)
        .when()
            .post("https://api.example.com/api/v1/products")
        .then()
            .statusCode(201)
            .body("name", equalTo(name))
            .body("price", equalTo((float) price))
            .body("category", equalTo(category));
    }

    @ParameterizedTest
    @MethodSource("provideUserData")
    public void testUserCreationFromJson(Map<String, Object> userData) {
        given()
            .contentType("application/json")
            .body(userData)
        .when()
            .post("https://api.example.com/api/v1/users")
        .then()
            .statusCode(201)
            .body("name", equalTo(userData.get("name")))
            .body("email", equalTo(userData.get("email")));
    }

    static Stream<Map<String, Object>> provideUserData() throws IOException {
        ObjectMapper mapper = new ObjectMapper();
        List<Map<String, Object>> users = mapper.readValue(
            new File("src/test/resources/testdata/users.json"),
            new TypeReference<List<Map<String, Object>>>() {}
        );
        return users.stream();
    }

    @Test
    public void bulkOperationWithTestData() throws IOException {
        ObjectMapper mapper = new ObjectMapper();
        List<Map<String, Object>> users = mapper.readValue(
            new File("src/test/resources/testdata/users.json"),
            new TypeReference<List<Map<String, Object>>>() {}
        );

        for (Map<String, Object> user : users) {
            given()
                .contentType("application/json")
                .body(user)
            .when()
                .post("https://api.example.com/api/v1/users")
            .then()
                .statusCode(201)
                .body("email", equalTo(user.get("email")));
        }
    }
}
```

## CI/CD Integration

### Maven Surefire Configuration
```xml
<!-- pom.xml -->
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-plugin</artifactId>
            <version>3.2.3</version>
            <configuration>
                <includes>
                    <include>**/*Test.java</include>
                    <include>**/*Tests.java</include>
                </includes>
                <systemPropertyVariables>
                    <env>${env}</env>
                    <base.url>${base.url}</base.url>
                    <api.version>${api.version}</api.version>
                </systemPropertyVariables>
                <parallel>methods</parallel>
                <threadCount>4</threadCount>
                <argLine>-Xmx1024m</argLine>
            </configuration>
        </plugin>

        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-report-plugin</artifactId>
            <version>3.2.3</version>
            <executions>
                <execution>
                    <phase>test</phase>
                    <goals>
                        <goal>report</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

### Command Line Execution
```bash
#!/bin/bash

# Run tests with specific environment
mvn clean test -Denv=staging

# Run tests with custom properties
mvn clean test \
  -Dbase.url=https://api.example.com \
  -Dapi.version=v2 \
  -Dparallel=classes \
  -DthreadCount=8

# Run specific test class
mvn test -Dtest=UserTests

# Run specific test method
mvn test -Dtest=UserTests#testCreateUser

# Run tests matching pattern
mvn test -Dtest=*IntegrationTest

# Generate test report
mvn surefire-report:report

# Run with different profiles
mvn test -P integration-tests
mvn test -P smoke-tests
```

### Jenkins Pipeline
```groovy
// Jenkinsfile
pipeline {
    agent any

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'production'],
            description: 'Target environment for testing'
        )
        choice(
            name: 'TEST_SUITE',
            choices: ['all', 'smoke', 'regression', 'integration'],
            description: 'Test suite to execute'
        )
        string(
            name: 'THREAD_COUNT',
            defaultValue: '4',
            description: 'Number of parallel threads'
        )
    }

    tools {
        maven 'Maven 3.9'
        jdk 'JDK 17'
    }

    environment {
        MAVEN_OPTS = '-Xmx1024m'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Compile') {
            steps {
                sh 'mvn clean compile'
            }
        }

        stage('Run API Tests') {
            steps {
                script {
                    def testCommand = "mvn test -Denv=${params.ENVIRONMENT}"

                    if (params.TEST_SUITE != 'all') {
                        testCommand += " -Dgroups=${params.TEST_SUITE}"
                    }

                    testCommand += " -DthreadCount=${params.THREAD_COUNT}"
                    testCommand += " -Dparallel=methods"

                    sh testCommand
                }
            }
        }

        stage('Generate Reports') {
            steps {
                sh 'mvn surefire-report:report'
            }
        }
    }

    post {
        always {
            junit '**/target/surefire-reports/*.xml'

            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'target/site',
                reportFiles: 'surefire-report.html',
                reportName: 'Test Report'
            ])
        }

        failure {
            emailext(
                subject: "API Tests Failed - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    API Tests failed for ${params.ENVIRONMENT} environment.

                    Build URL: ${env.BUILD_URL}
                    Test Report: ${env.BUILD_URL}Test_Report/
                """,
                to: '${DEFAULT_RECIPIENTS}'
            )
        }

        success {
            echo "All tests passed successfully!"
        }
    }
}
```

### GitHub Actions Workflow
```yaml
# .github/workflows/api-tests.yml
name: API Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
  schedule:
    - cron: '0 2 * * *'  # Run daily at 2 AM
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to test'
        required: true
        default: 'staging'
        type: choice
        options:
          - dev
          - staging
          - production

jobs:
  api-tests:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        java-version: [17, 21]

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up JDK ${{ matrix.java-version }}
        uses: actions/setup-java@v4
        with:
          java-version: ${{ matrix.java-version }}
          distribution: 'temurin'
          cache: maven

      - name: Run API Tests
        run: |
          mvn clean test \
            -Denv=${{ github.event.inputs.environment || 'staging' }} \
            -DthreadCount=4 \
            -Dparallel=methods
        env:
          API_USERNAME: ${{ secrets.API_USERNAME }}
          API_PASSWORD: ${{ secrets.API_PASSWORD }}

      - name: Generate Test Report
        if: always()
        run: mvn surefire-report:report

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results-jdk-${{ matrix.java-version }}
          path: target/surefire-reports/

      - name: Upload Test Report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-report-jdk-${{ matrix.java-version }}
          path: target/site/

      - name: Publish Test Results
        if: always()
        uses: dorny/test-reporter@v1
        with:
          name: API Test Results (JDK ${{ matrix.java-version }})
          path: 'target/surefire-reports/*.xml'
          reporter: java-junit

      - name: Comment PR with Results
        if: github.event_name == 'pull_request' && always()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const testResults = fs.readFileSync('target/surefire-reports/TEST-*.xml', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: 'API Test Results for JDK ${{ matrix.java-version }}: Check artifacts for details'
            })
```

### GitLab CI Configuration
```yaml
# .gitlab-ci.yml
stages:
  - test
  - report

variables:
  MAVEN_OPTS: "-Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository"
  MAVEN_CLI_OPTS: "--batch-mode --errors --fail-at-end --show-version"

cache:
  paths:
    - .m2/repository/
    - target/

.test_template: &test_template
  image: maven:3.9-eclipse-temurin-17
  before_script:
    - echo "Running tests against $ENVIRONMENT environment"

api_tests_dev:
  <<: *test_template
  stage: test
  variables:
    ENVIRONMENT: dev
  script:
    - mvn $MAVEN_CLI_OPTS test -Denv=dev -DthreadCount=4
  artifacts:
    when: always
    reports:
      junit:
        - target/surefire-reports/TEST-*.xml
    paths:
      - target/surefire-reports/
      - target/site/
    expire_in: 30 days
  only:
    - branches

api_tests_staging:
  <<: *test_template
  stage: test
  variables:
    ENVIRONMENT: staging
  script:
    - mvn $MAVEN_CLI_OPTS test -Denv=staging -DthreadCount=4
  artifacts:
    when: always
    reports:
      junit:
        - target/surefire-reports/TEST-*.xml
    paths:
      - target/surefire-reports/
      - target/site/
    expire_in: 30 days
  only:
    - main
    - develop

smoke_tests:
  <<: *test_template
  stage: test
  script:
    - mvn $MAVEN_CLI_OPTS test -Dgroups=smoke -Denv=production
  only:
    - tags

generate_report:
  stage: report
  image: maven:3.9-eclipse-temurin-17
  script:
    - mvn surefire-report:report
  artifacts:
    paths:
      - target/site/
    expire_in: 30 days
  dependencies:
    - api_tests_dev
  when: always
```

## Pros and Cons

### Pros

1. **Intuitive BDD Syntax**: The given-when-then syntax makes tests highly readable and self-documenting, allowing non-technical stakeholders to understand test scenarios easily.

2. **Comprehensive API Testing**: Supports all HTTP methods, authentication types, request/response specifications, and advanced features like multipart uploads and file downloads.

3. **Powerful Assertion Library**: Built-in integration with Hamcrest matchers and JsonPath/XmlPath provides extensive validation capabilities for complex response structures.

4. **Schema Validation**: Native support for JSON and XML schema validation ensures API contracts are maintained across versions.

5. **Excellent Integration**: Seamlessly integrates with popular testing frameworks (JUnit, TestNG), build tools (Maven, Gradle), and CI/CD pipelines.

6. **Rich Documentation**: Comprehensive official documentation, active community, and abundant examples make it easy to learn and troubleshoot.

7. **Flexible Configuration**: Request and response specifications allow for DRY principles, reducing code duplication across test suites.

### Cons

1. **Java Dependency**: Limited to Java ecosystem, which may not be ideal for teams working primarily with other languages like Python or JavaScript.

2. **Learning Curve for Non-Java Developers**: Developers unfamiliar with Java may find the setup and tooling more complex compared to lighter alternatives like Postman or Python's requests library.

3. **Limited Performance Testing**: While excellent for functional API testing, RestAssured is not designed for load or performance testing scenarios where tools like JMeter or Gatling excel.

4. **Verbose for Simple Tests**: Simple API calls may require more boilerplate code compared to minimal scripting approaches, though specifications help mitigate this.

5. **Debugging Complexity**: Troubleshooting failures in complex test chains can be challenging, especially when dealing with nested JSON paths or intricate response validations.

## Common Pitfalls

1. **Not Using Request/Response Specifications**: Writing repetitive configuration in every test instead of centralizing common settings in specifications leads to maintenance nightmares and code duplication.

2. **Hardcoding Base URLs and Endpoints**: Embedding environment-specific URLs directly in tests makes it difficult to run tests across different environments. Always use configuration files or environment variables.

3. **Ignoring Response Time Validations**: Focusing solely on functional correctness while neglecting performance assertions can allow slow endpoints to slip into production unnoticed.

4. **Inadequate Error Handling**: Not validating error responses with proper status codes, error messages, and response structures leaves gaps in API contract testing.

5. **Poor Test Data Management**: Using hardcoded test data or sharing mutable state between tests causes flaky tests and makes debugging difficult. Use data providers and ensure test independence.

6. **Not Enabling Logging Strategically**: Running all tests with verbose logging slows execution and clutters output, while having no logging makes debugging impossible. Use conditional logging based on environment or test failures.

7. **Ignoring Schema Validation**: Relying only on individual field assertions without schema validation can miss structural changes in API responses, breaking contract guarantees.

8. **Insufficient Authentication Testing**: Not testing various authentication scenarios (expired tokens, invalid credentials, insufficient permissions) leaves security vulnerabilities undetected.

9. **Not Extracting and Reusing Dynamic Values**: Failing to extract IDs, tokens, or other dynamic values from responses for use in subsequent requests forces unrealistic test scenarios with hardcoded values.

10. **Over-Complicating Assertions**: Using complex Groovy expressions in JsonPath when simpler Hamcrest matchers would suffice makes tests harder to read and maintain. Balance power with clarity.

## Real-World Examples

### Complete CRUD Test Suite
```java
package com.example.api.tests;

import io.restassured.response.Response;
import org.junit.jupiter.api.*;
import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;
import java.util.HashMap;
import java.util.Map;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class UserCRUDTests {

    private static String baseUrl = "https://api.example.com/api/v1";
    private static int createdUserId;
    private static String authToken;

    @BeforeAll
    public static void setup() {
        // Authenticate and get token
        Response loginResponse =
            given()
                .contentType("application/json")
                .body("""
                    {
                        "email": "admin@example.com",
                        "password": "AdminPass123!"
                    }
                    """)
            .when()
                .post(baseUrl + "/auth/login")
            .then()
                .statusCode(200)
                .extract()
                .response();

        authToken = loginResponse.path("accessToken");
    }

    @Test
    @Order(1)
    public void testCreateUser() {
        Map<String, Object> newUser = new HashMap<>();
        newUser.put("name", "Test User");
        newUser.put("email", "testuser@example.com");
        newUser.put("age", 25);
        newUser.put("roles", new String[]{"user"});

        Response response =
            given()
                .header("Authorization", "Bearer " + authToken)
                .contentType("application/json")
                .body(newUser)
            .when()
                .post(baseUrl + "/users")
            .then()
                .statusCode(201)
                .header("Location", notNullValue())
                .body("name", equalTo("Test User"))
                .body("email", equalTo("testuser@example.com"))
                .body("age", equalTo(25))
                .body("id", notNullValue())
                .body("createdAt", notNullValue())
                .extract()
                .response();

        createdUserId = response.path("id");
        System.out.println("Created user with ID: " + createdUserId);
    }

    @Test
    @Order(2)
    public void testGetUser() {
        given()
            .header("Authorization", "Bearer " + authToken)
            .pathParam("userId", createdUserId)
        .when()
            .get(baseUrl + "/users/{userId}")
        .then()
            .statusCode(200)
            .body("id", equalTo(createdUserId))
            .body("name", equalTo("Test User"))
            .body("email", equalTo("testuser@example.com"))
            .body("age", equalTo(25));
    }

    @Test
    @Order(3)
    public void testUpdateUser() {
        Map<String, Object> updateData = new HashMap<>();
        updateData.put("name", "Updated Test User");
        updateData.put("age", 26);

        given()
            .header("Authorization", "Bearer " + authToken)
            .contentType("application/json")
            .pathParam("userId", createdUserId)
            .body(updateData)
        .when()
            .patch(baseUrl + "/users/{userId}")
        .then()
            .statusCode(200)
            .body("id", equalTo(createdUserId))
            .body("name", equalTo("Updated Test User"))
            .body("age", equalTo(26))
            .body("email", equalTo("testuser@example.com"));
    }

    @Test
    @Order(4)
    public void testListUsers() {
        given()
            .header("Authorization", "Bearer " + authToken)
            .queryParam("page", 1)
            .queryParam("limit", 10)
        .when()
            .get(baseUrl + "/users")
        .then()
            .statusCode(200)
            .body("data", notNullValue())
            .body("data.size()", greaterThan(0))
            .body("data.id", hasItem(createdUserId))
            .body("total", greaterThan(0))
            .body("page", equalTo(1));
    }

    @Test
    @Order(5)
    public void testDeleteUser() {
        given()
            .header("Authorization", "Bearer " + authToken)
            .pathParam("userId", createdUserId)
        .when()
            .delete(baseUrl + "/users/{userId}")
        .then()
            .statusCode(204);
    }

    @Test
    @Order(6)
    public void testVerifyUserDeleted() {
        given()
            .header("Authorization", "Bearer " + authToken)
            .pathParam("userId", createdUserId)
        .when()
            .get(baseUrl + "/users/{userId}")
        .then()
            .statusCode(404)
            .body("message", containsString("not found"));
    }
}
```

### E-Commerce Order Flow
```java
package com.example.api.tests;

import io.restassured.response.Response;
import org.junit.jupiter.api.*;
import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;
import java.util.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class ECommerceOrderFlowTest {

    private static String baseUrl = "https://api.example.com/api/v1";
    private static String authToken;
    private static int productId;
    private static int cartId;
    private static String orderId;

    @BeforeAll
    public static void setup() {
        // Customer login
        Response loginResponse =
            given()
                .contentType("application/json")
                .body("""
                    {
                        "email": "customer@example.com",
                        "password": "CustomerPass123!"
                    }
                    """)
            .when()
                .post(baseUrl + "/auth/login")
            .then()
                .statusCode(200)
                .extract()
                .response();

        authToken = loginResponse.path("accessToken");
    }

    @Test
    @Order(1)
    @DisplayName("Search for products")
    public void testSearchProducts() {
        Response response =
            given()
                .header("Authorization", "Bearer " + authToken)
                .queryParam("q", "laptop")
                .queryParam("category", "Electronics")
                .queryParam("minPrice", 500)
                .queryParam("maxPrice", 2000)
            .when()
                .get(baseUrl + "/products/search")
            .then()
                .statusCode(200)
                .body("results.size()", greaterThan(0))
                .body("results[0].name", containsStringIgnoringCase("laptop"))
                .body("results[0].category", equalTo("Electronics"))
                .body("results[0].price", allOf(greaterThan(500f), lessThan(2000f)))
                .extract()
                .response();

        productId = response.path("results[0].id");
    }

    @Test
    @Order(2)
    @DisplayName("Get product details")
    public void testGetProductDetails() {
        given()
            .header("Authorization", "Bearer " + authToken)
            .pathParam("productId", productId)
        .when()
            .get(baseUrl + "/products/{productId}")
        .then()
            .statusCode(200)
            .body("id", equalTo(productId))
            .body("name", notNullValue())
            .body("price", greaterThan(0f))
            .body("stock", greaterThan(0))
            .body("description", notNullValue())
            .body("images", not(empty()));
    }

    @Test
    @Order(3)
    @DisplayName("Add product to cart")
    public void testAddToCart() {
        Map<String, Object> cartItem = Map.of(
            "productId", productId,
            "quantity", 1
        );

        Response response =
            given()
                .header("Authorization", "Bearer " + authToken)
                .contentType("application/json")
                .body(cartItem)
            .when()
                .post(baseUrl + "/cart/items")
            .then()
                .statusCode(201)
                .body("cart.items.size()", greaterThan(0))
                .body("cart.items[0].productId", equalTo(productId))
                .body("cart.items[0].quantity", equalTo(1))
                .body("cart.subtotal", greaterThan(0f))
                .extract()
                .response();

        cartId = response.path("cart.id");
    }

    @Test
    @Order(4)
    @DisplayName("Update cart item quantity")
    public void testUpdateCartQuantity() {
        Map<String, Object> updateData = Map.of("quantity", 2);

        given()
            .header("Authorization", "Bearer " + authToken)
            .contentType("application/json")
            .pathParam("cartId", cartId)
            .pathParam("productId", productId)
            .body(updateData)
        .when()
            .patch(baseUrl + "/cart/{cartId}/items/{productId}")
        .then()
            .statusCode(200)
            .body("items.find { it.productId == " + productId + " }.quantity", equalTo(2));
    }

    @Test
    @Order(5)
    @DisplayName("Apply discount coupon")
    public void testApplyCoupon() {
        Map<String, String> couponData = Map.of("couponCode", "SAVE10");

        given()
            .header("Authorization", "Bearer " + authToken)
            .contentType("application/json")
            .pathParam("cartId", cartId)
            .body(couponData)
        .when()
            .post(baseUrl + "/cart/{cartId}/coupon")
        .then()
            .statusCode(200)
            .body("discount", greaterThan(0f))
            .body("couponCode", equalTo("SAVE10"))
            .body("total", lessThan(response().path("subtotal")));
    }

    @Test
    @Order(6)
    @DisplayName("Create order from cart")
    public void testCreateOrder() {
        Map<String, Object> orderData = new HashMap<>();
        orderData.put("cartId", cartId);
        orderData.put("shippingAddress", Map.of(
            "street", "123 Main St",
            "city", "New York",
            "state", "NY",
            "zipCode", "10001"
        ));
        orderData.put("paymentMethod", Map.of(
            "type", "credit_card",
            "cardNumber", "4111111111111111",
            "expiryMonth", 12,
            "expiryYear", 2025,
            "cvv", "123"
        ));

        Response response =
            given()
                .header("Authorization", "Bearer " + authToken)
                .contentType("application/json")
                .body(orderData)
            .when()
                .post(baseUrl + "/orders")
            .then()
                .statusCode(201)
                .body("orderId", notNullValue())
                .body("status", equalTo("pending"))
                .body("total", greaterThan(0f))
                .body("items.size()", greaterThan(0))
                .extract()
                .response();

        orderId = response.path("orderId");
    }

    @Test
    @Order(7)
    @DisplayName("Track order status")
    public void testTrackOrder() {
        given()
            .header("Authorization", "Bearer " + authToken)
            .pathParam("orderId", orderId)
        .when()
            .get(baseUrl + "/orders/{orderId}")
        .then()
            .statusCode(200)
            .body("orderId", equalTo(orderId))
            .body("status", isOneOf("pending", "processing", "shipped", "delivered"))
            .body("trackingNumber", notNullValue())
            .body("estimatedDelivery", notNullValue());
    }

    @Test
    @Order(8)
    @DisplayName("Get order history")
    public void testGetOrderHistory() {
        given()
            .header("Authorization", "Bearer " + authToken)
            .queryParam("page", 1)
            .queryParam("limit", 10)
        .when()
            .get(baseUrl + "/orders")
        .then()
            .statusCode(200)
            .body("data.size()", greaterThan(0))
            .body("data.orderId", hasItem(orderId))
            .body("total", greaterThan(0));
    }
}
```

## Performance Considerations

### Parallel Test Execution
```xml
<!-- pom.xml -->
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-surefire-plugin</artifactId>
    <version>3.2.3</version>
    <configuration>
        <parallel>all</parallel>
        <threadCount>8</threadCount>
        <perCoreThreadCount>true</perCoreThreadCount>
        <forkCount>2C</forkCount>
        <reuseForks>true</reuseForks>
    </configuration>
</plugin>
```

### Connection Pooling
```java
package com.example.api.base;

import io.restassured.RestAssured;
import io.restassured.config.ConnectionConfig;
import io.restassured.config.HttpClientConfig;
import org.junit.jupiter.api.BeforeAll;

public class PerformanceOptimizedTests {

    @BeforeAll
    public static void configureConnectionPool() {
        RestAssured.config = RestAssured.config()
            .connectionConfig(ConnectionConfig.connectionConfig()
                .closeIdleConnectionsAfterEachResponse())
            .httpClient(HttpClientConfig.httpClientConfig()
                .setParam("http.connection.timeout", 10000)
                .setParam("http.socket.timeout", 30000)
                .setParam("http.connection-manager.timeout", 10000)
                .setParam("http.conn-manager.max-total", 100)
                .setParam("http.conn-manager.max-per-route", 20));
    }
}
```

### Response Caching Strategy
```java
package com.example.api.utils;

import io.restassured.response.Response;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;

public class ResponseCache {

    private static final Map<String, Response> cache = new ConcurrentHashMap<>();
    private static final long CACHE_TTL = 5 * 60 * 1000; // 5 minutes
    private static final Map<String, Long> timestamps = new ConcurrentHashMap<>();

    public static Response get(String key) {
        if (isExpired(key)) {
            invalidate(key);
            return null;
        }
        return cache.get(key);
    }

    public static void put(String key, Response response) {
        cache.put(key, response);
        timestamps.put(key, System.currentTimeMillis());
    }

    private static boolean isExpired(String key) {
        Long timestamp = timestamps.get(key);
        if (timestamp == null) return true;
        return System.currentTimeMillis() - timestamp > CACHE_TTL;
    }

    public static void invalidate(String key) {
        cache.remove(key);
        timestamps.remove(key);
    }

    public static void clear() {
        cache.clear();
        timestamps.clear();
    }
}
```

### Optimizing Test Data
```java
package com.example.api.utils;

import com.github.javafaker.Faker;
import java.util.Map;
import java.util.HashMap;
import java.util.concurrent.ConcurrentHashMap;

public class TestDataGenerator {

    private static final Faker faker = new Faker();
    private static final Map<String, Object> testDataCache = new ConcurrentHashMap<>();

    public static Map<String, Object> generateUserData() {
        return generateUserData(false);
    }

    public static Map<String, Object> generateUserData(boolean useCache) {
        String cacheKey = "user_data";

        if (useCache && testDataCache.containsKey(cacheKey)) {
            return (Map<String, Object>) testDataCache.get(cacheKey);
        }

        Map<String, Object> userData = new HashMap<>();
        userData.put("name", faker.name().fullName());
        userData.put("email", faker.internet().emailAddress());
        userData.put("age", faker.number().numberBetween(18, 65));
        userData.put("phone", faker.phoneNumber().phoneNumber());

        if (useCache) {
            testDataCache.put(cacheKey, userData);
        }

        return userData;
    }

    public static void clearCache() {
        testDataCache.clear();
    }
}
```

## Best Practices Summary

1. **Use Request and Response Specifications**: Centralize common configurations to reduce duplication and improve maintainability across your test suite.

2. **Implement Proper Test Organization**: Structure tests logically with base classes, utilities, and separate packages for different API modules or features.

3. **Externalize Configuration**: Store environment-specific settings in properties files and use system properties or environment variables for runtime configuration.

4. **Validate Both Success and Error Scenarios**: Test happy paths, edge cases, validation errors, authentication failures, and error handling comprehensively.

5. **Use Schema Validation**: Leverage JSON/XML schema validation to ensure API contracts are maintained and catch structural changes early.

6. **Implement Data-Driven Testing**: Use parameterized tests with external data sources to maximize test coverage with minimal code duplication.

7. **Extract and Reuse Dynamic Values**: Store tokens, IDs, and other dynamic values extracted from responses for use in subsequent API calls to create realistic test flows.

8. **Enable Conditional Logging**: Configure logging to activate on test failures or in specific environments to balance debugging capability with execution performance.

9. **Implement Parallel Execution**: Configure tests to run in parallel where possible to reduce overall execution time, especially in CI/CD pipelines.

10. **Use Proper Assertions**: Choose appropriate matchers and assertions that provide clear failure messages and accurately validate expected behavior.

11. **Manage Authentication Centrally**: Handle authentication tokens and credentials in a centralized authentication helper or specification to avoid repetition.

12. **Version Your Tests with Your API**: Keep test suites versioned alongside API versions to maintain compatibility and track changes over time.

13. **Implement Proper Cleanup**: Use @AfterEach and @AfterAll hooks to clean up test data, ensuring tests are independent and repeatable.

14. **Monitor Response Times**: Include performance assertions to catch degradation early and establish baseline performance expectations.

15. **Document Complex Test Scenarios**: Use @DisplayName annotations and comments to explain business logic and complex test flows for better team understanding.

## Conclusion

RestAssured has established itself as the leading Java-based framework for REST API testing, offering a powerful combination of readability, flexibility, and comprehensive testing capabilities. Its intuitive BDD-style syntax makes tests self-documenting, while its deep integration with the Java ecosystem ensures seamless incorporation into existing development workflows.

The framework excels at functional API testing, providing extensive support for authentication mechanisms, request/response validation, schema verification, and data-driven testing approaches. Its request and response specifications promote code reusability, while JsonPath and XmlPath support enable sophisticated assertions on complex response structures. When combined with modern CI/CD pipelines, RestAssured enables automated, continuous validation of API contracts and behavior.

While RestAssured requires Java knowledge and is not designed for performance testing scenarios, its strengths in functional testing, maintainability, and developer productivity make it an excellent choice for teams building robust API test automation frameworks. By following the best practices outlined in this guide, teams can build reliable, maintainable, and comprehensive API test suites that ensure quality and accelerate delivery.

Whether you are testing microservices, RESTful APIs, or complex integration scenarios, RestAssured provides the tools and flexibility needed to validate your APIs thoroughly and confidently. Its active community, comprehensive documentation, and continuous evolution ensure it remains a top choice for API testing in the Java ecosystem.
