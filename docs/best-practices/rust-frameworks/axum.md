# Axum Best Practices

## Official Documentation
- **Axum**: https://github.com/tokio-rs/axum
- **Documentation**: https://docs.rs/axum/latest/axum/
- **Examples**: https://github.com/tokio-rs/axum/tree/main/examples
- **Tokio**: https://tokio.rs
- **Tower Middleware**: https://docs.rs/tower/latest/tower/
- **Axum Community**: https://discord.gg/tokio

## Introduction

Axum is an ergonomic and modular web framework for Rust built on top of Tokio, Tower, and Hyper. Created by the Tokio team, it provides a type-safe, composable approach to building web services with excellent performance and minimal boilerplate.

### When to Use Axum

**Ideal Scenarios:**
- High-performance REST APIs and microservices
- WebSocket servers requiring real-time communication
- gRPC services leveraging Tonic integration
- Applications requiring compile-time guarantees and type safety
- Services needing fine-grained control over async execution
- Systems with strict performance and resource requirements
- Backend services in Rust-native ecosystems
- Projects leveraging Tower middleware ecosystem

**When to Avoid:**
- Rapid prototyping where development speed trumps performance
- Teams without Rust experience or time to learn
- Projects with heavy template rendering needs (consider Actix-web)
- Applications requiring extensive third-party integrations (Node.js ecosystem richer)
- Simple CRUD apps where framework complexity exceeds benefits
- Greenfield projects with tight deadlines and limited Rust expertise

## Core Concepts

### Request Routing

```rust
use axum::{
    routing::{get, post, put, delete},
    Router,
};

async fn create_router() -> Router {
    Router::new()
        // Basic routes
        .route("/", get(root))
        .route("/users", get(list_users).post(create_user))
        .route("/users/:id", get(get_user).put(update_user).delete(delete_user))

        // Nested routers
        .nest("/api/v1", api_v1_router())
        .nest("/admin", admin_router())

        // Fallback for 404
        .fallback(handler_404)
}

async fn root() -> &'static str {
    "Hello, World!"
}

async fn handler_404() -> (StatusCode, &'static str) {
    (StatusCode::NOT_FOUND, "Not found")
}
```

### Extractors

Extractors allow you to parse incoming requests in a type-safe manner.

```rust
use axum::{
    extract::{Path, Query, Json, State},
    http::{StatusCode, HeaderMap},
};
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
struct Pagination {
    page: Option<u32>,
    per_page: Option<u32>,
}

#[derive(Deserialize, Serialize)]
struct User {
    id: u64,
    name: String,
    email: String,
}

#[derive(Deserialize)]
struct CreateUserRequest {
    name: String,
    email: String,
}

// Path parameters
async fn get_user(
    Path(user_id): Path<u64>,
) -> Result<Json<User>, StatusCode> {
    // Fetch user from database
    let user = fetch_user(user_id).await
        .ok_or(StatusCode::NOT_FOUND)?;

    Ok(Json(user))
}

// Query parameters
async fn list_users(
    Query(pagination): Query<Pagination>,
) -> Json<Vec<User>> {
    let page = pagination.page.unwrap_or(1);
    let per_page = pagination.per_page.unwrap_or(20);

    let users = fetch_users(page, per_page).await;
    Json(users)
}

// JSON body
async fn create_user(
    Json(payload): Json<CreateUserRequest>,
) -> Result<(StatusCode, Json<User>), StatusCode> {
    let user = insert_user(payload).await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok((StatusCode::CREATED, Json(user)))
}

// Multiple extractors
async fn update_user(
    Path(user_id): Path<u64>,
    headers: HeaderMap,
    Json(payload): Json<CreateUserRequest>,
) -> Result<Json<User>, StatusCode> {
    // Verify authorization from headers
    let auth_token = headers
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    verify_token(auth_token)?;

    let user = update_user_in_db(user_id, payload).await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(user))
}
```

### State Management

```rust
use axum::{
    extract::State,
    routing::get,
    Router,
};
use sqlx::PgPool;
use std::sync::Arc;

#[derive(Clone)]
struct AppState {
    db: PgPool,
    config: Arc<Config>,
}

#[derive(Clone)]
struct Config {
    max_upload_size: usize,
    api_key: String,
}

async fn create_app(db: PgPool) -> Router {
    let state = AppState {
        db,
        config: Arc::new(Config {
            max_upload_size: 10_485_760, // 10MB
            api_key: std::env::var("API_KEY").unwrap(),
        }),
    };

    Router::new()
        .route("/users", get(list_users))
        .with_state(state)
}

async fn list_users(
    State(state): State<AppState>,
) -> Result<Json<Vec<User>>, StatusCode> {
    let users = sqlx::query_as::<_, User>("SELECT * FROM users")
        .fetch_all(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(users))
}
```

## Best Practices

### Error Handling

```rust
use axum::{
    response::{IntoResponse, Response},
    http::StatusCode,
    Json,
};
use serde_json::json;
use thiserror::Error;

#[derive(Error, Debug)]
enum AppError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),

    #[error("Not found")]
    NotFound,

    #[error("Unauthorized")]
    Unauthorized,

    #[error("Validation error: {0}")]
    Validation(String),

    #[error("Internal server error")]
    Internal,
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            AppError::Database(e) => {
                tracing::error!("Database error: {}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, "Internal server error")
            }
            AppError::NotFound => (StatusCode::NOT_FOUND, "Resource not found"),
            AppError::Unauthorized => (StatusCode::UNAUTHORIZED, "Unauthorized"),
            AppError::Validation(msg) => (StatusCode::BAD_REQUEST, msg.as_str()),
            AppError::Internal => (StatusCode::INTERNAL_SERVER_ERROR, "Internal server error"),
        };

        let body = Json(json!({
            "error": message,
        }));

        (status, body).into_response()
    }
}

// Usage in handlers
async fn get_user(
    Path(user_id): Path<u64>,
    State(state): State<AppState>,
) -> Result<Json<User>, AppError> {
    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = $1")
        .bind(user_id)
        .fetch_optional(&state.db)
        .await?
        .ok_or(AppError::NotFound)?;

    Ok(Json(user))
}
```

### Middleware

```rust
use axum::{
    middleware::{self, Next},
    http::{Request, StatusCode},
    response::Response,
};
use tower::ServiceBuilder;
use tower_http::{
    trace::TraceLayer,
    cors::CorsLayer,
    compression::CompressionLayer,
};

// Custom middleware
async fn auth_middleware<B>(
    headers: HeaderMap,
    mut req: Request<B>,
    next: Next<B>,
) -> Result<Response, StatusCode> {
    let auth_header = headers
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .ok_or(StatusCode::UNAUTHORIZED)?;

    // Verify token
    let user_id = verify_jwt(token)
        .map_err(|_| StatusCode::UNAUTHORIZED)?;

    // Add user_id to request extensions
    req.extensions_mut().insert(user_id);

    Ok(next.run(req).await)
}

// Request logging middleware
async fn logging_middleware<B>(
    req: Request<B>,
    next: Next<B>,
) -> Response {
    let method = req.method().clone();
    let uri = req.uri().clone();

    let start = std::time::Instant::now();
    let response = next.run(req).await;
    let elapsed = start.elapsed();

    tracing::info!(
        method = %method,
        uri = %uri,
        status = response.status().as_u16(),
        duration_ms = elapsed.as_millis(),
        "Request processed"
    );

    response
}

// Apply middleware
fn create_app() -> Router {
    let app = Router::new()
        .route("/protected", get(protected_handler))
        .route_layer(middleware::from_fn(auth_middleware))
        .route("/public", get(public_handler));

    let middleware_stack = ServiceBuilder::new()
        .layer(TraceLayer::new_for_http())
        .layer(CompressionLayer::new())
        .layer(CorsLayer::permissive())
        .layer(middleware::from_fn(logging_middleware));

    app.layer(middleware_stack)
}
```

### Database Integration (SQLx)

```rust
use sqlx::{postgres::PgPoolOptions, PgPool, FromRow};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, FromRow)]
struct User {
    id: i64,
    email: String,
    name: String,
    created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Deserialize)]
struct CreateUser {
    email: String,
    name: String,
}

async fn create_pool() -> Result<PgPool, sqlx::Error> {
    PgPoolOptions::new()
        .max_connections(5)
        .connect(&std::env::var("DATABASE_URL").unwrap())
        .await
}

// CRUD operations
async fn create_user(
    State(state): State<AppState>,
    Json(payload): Json<CreateUser>,
) -> Result<Json<User>, AppError> {
    let user = sqlx::query_as::<_, User>(
        "INSERT INTO users (email, name) VALUES ($1, $2) RETURNING *"
    )
    .bind(&payload.email)
    .bind(&payload.name)
    .fetch_one(&state.db)
    .await?;

    Ok(Json(user))
}

async fn list_users(
    State(state): State<AppState>,
    Query(pagination): Query<Pagination>,
) -> Result<Json<Vec<User>>, AppError> {
    let page = pagination.page.unwrap_or(1);
    let per_page = pagination.per_page.unwrap_or(20);
    let offset = (page - 1) * per_page;

    let users = sqlx::query_as::<_, User>(
        "SELECT * FROM users ORDER BY created_at DESC LIMIT $1 OFFSET $2"
    )
    .bind(per_page as i64)
    .bind(offset as i64)
    .fetch_all(&state.db)
    .await?;

    Ok(Json(users))
}

async fn update_user(
    Path(user_id): Path<i64>,
    State(state): State<AppState>,
    Json(payload): Json<CreateUser>,
) -> Result<Json<User>, AppError> {
    let user = sqlx::query_as::<_, User>(
        "UPDATE users SET email = $1, name = $2 WHERE id = $3 RETURNING *"
    )
    .bind(&payload.email)
    .bind(&payload.name)
    .bind(user_id)
    .fetch_optional(&state.db)
    .await?
    .ok_or(AppError::NotFound)?;

    Ok(Json(user))
}

async fn delete_user(
    Path(user_id): Path<i64>,
    State(state): State<AppState>,
) -> Result<StatusCode, AppError> {
    let result = sqlx::query("DELETE FROM users WHERE id = $1")
        .bind(user_id)
        .execute(&state.db)
        .await?;

    if result.rows_affected() == 0 {
        return Err(AppError::NotFound);
    }

    Ok(StatusCode::NO_CONTENT)
}
```

### WebSocket Support

```rust
use axum::{
    extract::ws::{WebSocket, WebSocketUpgrade, Message},
    response::Response,
};
use futures::{sink::SinkExt, stream::StreamExt};

async fn ws_handler(
    ws: WebSocketUpgrade,
) -> Response {
    ws.on_upgrade(handle_socket)
}

async fn handle_socket(mut socket: WebSocket) {
    // Send initial message
    if socket.send(Message::Text("Connected!".to_string())).await.is_err() {
        return;
    }

    // Handle incoming messages
    while let Some(msg) = socket.recv().await {
        let msg = match msg {
            Ok(msg) => msg,
            Err(e) => {
                tracing::error!("WebSocket error: {}", e);
                break;
            }
        };

        match msg {
            Message::Text(text) => {
                tracing::info!("Received: {}", text);

                // Echo back
                if socket
                    .send(Message::Text(format!("Echo: {}", text)))
                    .await
                    .is_err()
                {
                    break;
                }
            }
            Message::Binary(data) => {
                tracing::info!("Received {} bytes", data.len());
            }
            Message::Ping(data) => {
                if socket.send(Message::Pong(data)).await.is_err() {
                    break;
                }
            }
            Message::Close(_) => {
                tracing::info!("Client disconnected");
                break;
            }
            _ => {}
        }
    }
}

// Router setup
fn create_router() -> Router {
    Router::new()
        .route("/ws", get(ws_handler))
}
```

### Request Validation

```rust
use validator::{Validate, ValidationError};

#[derive(Debug, Deserialize, Validate)]
struct CreateUserRequest {
    #[validate(email)]
    email: String,

    #[validate(length(min = 3, max = 50))]
    name: String,

    #[validate(length(min = 8))]
    password: String,

    #[validate(range(min = 18, max = 120))]
    age: u8,
}

// Custom validator
fn validate_username(username: &str) -> Result<(), ValidationError> {
    if username.chars().all(|c| c.is_alphanumeric() || c == '_') {
        Ok(())
    } else {
        Err(ValidationError::new("invalid_username"))
    }
}

async fn create_user(
    State(state): State<AppState>,
    Json(payload): Json<CreateUserRequest>,
) -> Result<Json<User>, AppError> {
    // Validate input
    payload.validate()
        .map_err(|e| AppError::Validation(format!("{}", e)))?;

    // Hash password
    let password_hash = hash_password(&payload.password)?;

    // Insert into database
    let user = sqlx::query_as::<_, User>(
        "INSERT INTO users (email, name, password_hash, age) VALUES ($1, $2, $3, $4) RETURNING *"
    )
    .bind(&payload.email)
    .bind(&payload.name)
    .bind(&password_hash)
    .bind(payload.age as i32)
    .fetch_one(&state.db)
    .await?;

    Ok(Json(user))
}
```

## Project Structure

```plaintext
axum-project/
├── src/
│   ├── main.rs                    # Application entry point
│   ├── lib.rs                     # Library root (for testing)
│   ├── config/
│   │   ├── mod.rs
│   │   └── settings.rs            # Configuration management
│   ├── routes/
│   │   ├── mod.rs
│   │   ├── users.rs               # User routes
│   │   ├── auth.rs                # Authentication routes
│   │   └── health.rs              # Health check routes
│   ├── handlers/
│   │   ├── mod.rs
│   │   ├── users.rs               # User handlers
│   │   └── auth.rs                # Auth handlers
│   ├── models/
│   │   ├── mod.rs
│   │   ├── user.rs                # User model
│   │   └── post.rs                # Post model
│   ├── middleware/
│   │   ├── mod.rs
│   │   ├── auth.rs                # Authentication middleware
│   │   ├── logging.rs             # Logging middleware
│   │   └── rate_limit.rs          # Rate limiting
│   ├── services/
│   │   ├── mod.rs
│   │   ├── user_service.rs        # Business logic
│   │   └── email_service.rs       # Email service
│   ├── db/
│   │   ├── mod.rs
│   │   └── migrations/            # SQL migrations
│   ├── error.rs                   # Error types
│   └── utils/
│       ├── mod.rs
│       ├── jwt.rs                 # JWT utilities
│       └── password.rs            # Password hashing
├── tests/
│   ├── integration_test.rs
│   └── api_test.rs
├── Cargo.toml
├── .env
├── .env.example
└── README.md
```

## Security and Safety

### Authentication with JWT

```rust
use jsonwebtoken::{encode, decode, Header, Validation, EncodingKey, DecodingKey};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
struct Claims {
    sub: String,      // Subject (user ID)
    exp: usize,       // Expiration
    iat: usize,       // Issued at
}

fn create_jwt(user_id: &str) -> Result<String, AppError> {
    let expiration = chrono::Utc::now()
        .checked_add_signed(chrono::Duration::hours(24))
        .expect("valid timestamp")
        .timestamp() as usize;

    let claims = Claims {
        sub: user_id.to_owned(),
        exp: expiration,
        iat: chrono::Utc::now().timestamp() as usize,
    };

    let secret = std::env::var("JWT_SECRET")
        .expect("JWT_SECRET must be set");

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
    .map_err(|_| AppError::Internal)
}

fn verify_jwt(token: &str) -> Result<String, AppError> {
    let secret = std::env::var("JWT_SECRET")
        .expect("JWT_SECRET must be set");

    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::default(),
    )
    .map_err(|_| AppError::Unauthorized)?;

    Ok(token_data.claims.sub)
}

// Login handler
#[derive(Deserialize)]
struct LoginRequest {
    email: String,
    password: String,
}

#[derive(Serialize)]
struct LoginResponse {
    token: String,
    user: User,
}

async fn login(
    State(state): State<AppState>,
    Json(payload): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, AppError> {
    // Fetch user
    let user = sqlx::query_as::<_, User>(
        "SELECT * FROM users WHERE email = $1"
    )
    .bind(&payload.email)
    .fetch_optional(&state.db)
    .await?
    .ok_or(AppError::Unauthorized)?;

    // Verify password
    verify_password(&payload.password, &user.password_hash)
        .map_err(|_| AppError::Unauthorized)?;

    // Generate JWT
    let token = create_jwt(&user.id.to_string())?;

    Ok(Json(LoginResponse { token, user }))
}
```

### Password Hashing

```rust
use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};

fn hash_password(password: &str) -> Result<String, AppError> {
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();

    argon2
        .hash_password(password.as_bytes(), &salt)
        .map(|hash| hash.to_string())
        .map_err(|_| AppError::Internal)
}

fn verify_password(password: &str, hash: &str) -> Result<(), AppError> {
    let parsed_hash = PasswordHash::new(hash)
        .map_err(|_| AppError::Internal)?;

    Argon2::default()
        .verify_password(password.as_bytes(), &parsed_hash)
        .map_err(|_| AppError::Unauthorized)
}
```

### CORS Configuration

```rust
use tower_http::cors::{CorsLayer, Any};
use http::Method;

fn configure_cors() -> CorsLayer {
    CorsLayer::new()
        .allow_origin([
            "http://localhost:3000".parse().unwrap(),
            "https://yourdomain.com".parse().unwrap(),
        ])
        .allow_methods([Method::GET, Method::POST, Method::PUT, Method::DELETE])
        .allow_headers(Any)
        .allow_credentials(true)
}
```

### Rate Limiting

```rust
use tower_governor::{GovernorLayer, GovernorConfigBuilder};

fn create_rate_limiter() -> GovernorLayer {
    let governor_conf = Box::new(
        GovernorConfigBuilder::default()
            .per_second(2)
            .burst_size(5)
            .finish()
            .unwrap()
    );

    GovernorLayer {
        config: Box::leak(governor_conf),
    }
}

// Apply to specific routes
Router::new()
    .route("/api/login", post(login))
    .layer(create_rate_limiter())
```

## Common Vulnerabilities

### 1. SQL Injection

```rust
// VULNERABLE: String concatenation
async fn vulnerable_search(query: String) -> Result<Json<Vec<User>>, AppError> {
    let sql = format!("SELECT * FROM users WHERE name LIKE '%{}%'", query);
    // Attacker could inject: %'; DROP TABLE users; --
    let users = sqlx::query_as::<_, User>(&sql)
        .fetch_all(&state.db)
        .await?;
    Ok(Json(users))
}

// SECURE: Parameterized queries
async fn secure_search(
    State(state): State<AppState>,
    Query(SearchParams { query }): Query<SearchParams>,
) -> Result<Json<Vec<User>>, AppError> {
    let search_pattern = format!("%{}%", query);
    let users = sqlx::query_as::<_, User>(
        "SELECT * FROM users WHERE name LIKE $1"
    )
    .bind(search_pattern)
    .fetch_all(&state.db)
    .await?;

    Ok(Json(users))
}
```

### 2. Missing Authentication

```rust
// VULNERABLE: No authentication check
async fn delete_user(
    Path(user_id): Path<i64>,
    State(state): State<AppState>,
) -> Result<StatusCode, AppError> {
    sqlx::query("DELETE FROM users WHERE id = $1")
        .bind(user_id)
        .execute(&state.db)
        .await?;
    Ok(StatusCode::NO_CONTENT)
}

// SECURE: Require authentication
async fn delete_user(
    Path(user_id): Path<i64>,
    State(state): State<AppState>,
    Extension(current_user_id): Extension<i64>,
) -> Result<StatusCode, AppError> {
    // Only admins or the user themselves can delete
    let current_user = get_user_by_id(&state.db, current_user_id).await?;

    if current_user.role != "admin" && current_user_id != user_id {
        return Err(AppError::Unauthorized);
    }

    sqlx::query("DELETE FROM users WHERE id = $1")
        .bind(user_id)
        .execute(&state.db)
        .await?;

    Ok(StatusCode::NO_CONTENT)
}
```

## Common Pitfalls

### 1. Blocking Operations

```rust
// BAD: Blocking the async runtime
async fn bad_handler() -> String {
    std::thread::sleep(Duration::from_secs(5)); // Blocks entire thread
    "Done".to_string()
}

// GOOD: Use tokio::time::sleep
async fn good_handler() -> String {
    tokio::time::sleep(Duration::from_secs(5)).await; // Async sleep
    "Done".to_string()
}

// GOOD: Spawn blocking for CPU-intensive work
async fn cpu_intensive_handler() -> Result<Json<Data>, AppError> {
    let result = tokio::task::spawn_blocking(|| {
        // Heavy computation
        expensive_computation()
    })
    .await
    .map_err(|_| AppError::Internal)?;

    Ok(Json(result))
}
```

### 2. Not Using Connection Pooling

```rust
// BAD: Creating new connection per request
async fn bad_query() -> Result<Json<Vec<User>>, AppError> {
    let conn = PgConnection::connect(&env::var("DATABASE_URL").unwrap())
        .await?;
    // Use connection
    Ok(Json(users))
}

// GOOD: Use connection pool
async fn good_query(
    State(AppState { db, .. }): State<AppState>,
) -> Result<Json<Vec<User>>, AppError> {
    let users = sqlx::query_as::<_, User>("SELECT * FROM users")
        .fetch_all(&db)  // Uses pooled connection
        .await?;
    Ok(Json(users))
}
```

## Testing Strategies

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use axum::body::Body;
    use axum::http::{Request, StatusCode};
    use tower::ServiceExt;

    #[tokio::test]
    async fn test_get_user() {
        let app = create_test_app().await;

        let response = app
            .oneshot(
                Request::builder()
                    .uri("/users/1")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();

        assert_eq!(response.status(), StatusCode::OK);

        let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
        let user: User = serde_json::from_slice(&body).unwrap();

        assert_eq!(user.id, 1);
    }

    #[tokio::test]
    async fn test_create_user() {
        let app = create_test_app().await;

        let payload = json!({
            "name": "John Doe",
            "email": "john@example.com",
        });

        let response = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/users")
                    .header("content-type", "application/json")
                    .body(Body::from(serde_json::to_string(&payload).unwrap()))
                    .unwrap(),
            )
            .await
            .unwrap();

        assert_eq!(response.status(), StatusCode::CREATED);
    }
}
```

## Pros and Cons

### Pros
✓ **Excellent performance** with minimal overhead on Tokio runtime
✓ **Type safety** with compile-time guarantees and zero-cost abstractions
✓ **Ergonomic API** with intuitive extractors and handlers
✓ **Tower middleware** ecosystem for composable request/response processing
✓ **Memory safe** leveraging Rust's ownership system
✓ **Async-first** design built on Tokio for efficient concurrency
✓ **Low resource usage** suitable for resource-constrained environments
✓ **WebSocket support** with built-in async handling
✓ **Strong typing** prevents entire classes of runtime errors

### Cons
✗ **Rust learning curve** steep for developers new to the language
✗ **Compile times** can be long for larger projects
✗ **Smaller ecosystem** compared to Node.js or Python frameworks
✗ **Verbose error handling** requires explicit Result types
✗ **Limited ORM options** compared to mature ecosystems
✗ **Fewer templates and examples** than established frameworks
✗ **Async complexity** requires understanding of async/await and Tokio
✗ **Breaking changes** in early versions as framework matures

## Summary

**Key Takeaways:**
- Leverage extractors for type-safe request parsing
- Use `State` for sharing application state across handlers
- Implement custom error types with `IntoResponse` for consistent error handling
- Apply middleware with Tower's composable layers
- Use SQLx for compile-time verified SQL queries
- Hash passwords with Argon2 or bcrypt
- Implement JWT authentication for stateless APIs
- Configure CORS and rate limiting for production
- Avoid blocking operations in async handlers
- Use connection pooling for database access

**Quick Reference Checklist:**
- [ ] All handlers return `Result<T, AppError>`
- [ ] Database queries use parameterized statements
- [ ] Passwords hashed with Argon2 or bcrypt
- [ ] JWT tokens validated on protected routes
- [ ] CORS configured for allowed origins
- [ ] Rate limiting applied to sensitive endpoints
- [ ] Input validation with `validator` crate
- [ ] Error responses don't leak sensitive information
- [ ] Database connection pool configured
- [ ] Logging and tracing enabled
- [ ] Tests cover critical endpoints

## Conclusion

Axum delivers a modern, type-safe foundation for building high-performance web services in Rust. Its integration with the Tokio ecosystem and Tower middleware makes it an excellent choice for developers prioritizing performance, safety, and composability. While Rust's learning curve and ecosystem maturity present challenges, teams investing in Rust expertise gain compile-time guarantees and runtime efficiency unmatched by most alternatives.

Choose Axum for performance-critical services where type safety and resource efficiency are priorities. For rapid development or teams without Rust experience, consider mature frameworks in other languages.

## Resources

- **Axum Documentation**: https://docs.rs/axum/latest/axum/
- **Axum Examples**: https://github.com/tokio-rs/axum/tree/main/examples
- **Tokio Tutorial**: https://tokio.rs/tokio/tutorial
- **Tower Documentation**: https://docs.rs/tower/latest/tower/
- **SQLx Documentation**: https://docs.rs/sqlx/latest/sqlx/
- **Rust Book**: https://doc.rust-lang.org/book/
- **Async Book**: https://rust-lang.github.io/async-book/
- **Tokio Discord**: https://discord.gg/tokio
