# Rust Best Practices

## Official Documentation
- **The Rust Book**: https://doc.rust-lang.org/book/
- **Rust by Example**: https://doc.rust-lang.org/rust-by-example/
- **Rust API Guidelines**: https://rust-lang.github.io/api-guidelines/
- **Cargo Documentation**: https://doc.rust-lang.org/cargo/

## Project Structure

```
project-root/
├── src/
│   ├── bin/
│   │   └── cli.rs
│   ├── config/
│   │   └── mod.rs
│   ├── db/
│   │   ├── mod.rs
│   │   ├── models.rs
│   │   └── schema.rs
│   ├── handlers/
│   │   ├── mod.rs
│   │   ├── auth.rs
│   │   └── users.rs
│   ├── middleware/
│   │   ├── mod.rs
│   │   ├── auth.rs
│   │   └── cors.rs
│   ├── models/
│   │   ├── mod.rs
│   │   ├── user.rs
│   │   └── product.rs
│   ├── services/
│   │   ├── mod.rs
│   │   ├── auth_service.rs
│   │   └── user_service.rs
│   ├── utils/
│   │   ├── mod.rs
│   │   ├── errors.rs
│   │   └── validators.rs
│   ├── lib.rs
│   └── main.rs
├── tests/
│   ├── common/
│   │   └── mod.rs
│   ├── integration/
│   │   └── api_test.rs
│   └── unit/
│       └── service_test.rs
├── benches/
│   └── benchmark.rs
├── migrations/
├── .env.example
├── Cargo.toml
├── Cargo.lock
├── diesel.toml
├── rustfmt.toml
├── clippy.toml
└── README.md
```

## Core Best Practices

### 1. Error Handling

```rust
use thiserror::Error;
use std::fmt;

// Define custom error types with thiserror
#[derive(Error, Debug)]
pub enum AppError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
    
    #[error("Validation error: {0}")]
    Validation(String),
    
    #[error("Authentication failed")]
    Authentication,
    
    #[error("Not found: {0}")]
    NotFound(String),
    
    #[error("Internal server error")]
    Internal,
    
    #[error("Bad request: {0}")]
    BadRequest(String),
}

// Implement ResponseError for Actix-web
impl actix_web::error::ResponseError for AppError {
    fn error_response(&self) -> actix_web::HttpResponse {
        use actix_web::http::StatusCode;
        
        let status = match self {
            AppError::Database(_) => StatusCode::INTERNAL_SERVER_ERROR,
            AppError::Validation(_) => StatusCode::BAD_REQUEST,
            AppError::Authentication => StatusCode::UNAUTHORIZED,
            AppError::NotFound(_) => StatusCode::NOT_FOUND,
            AppError::Internal => StatusCode::INTERNAL_SERVER_ERROR,
            AppError::BadRequest(_) => StatusCode::BAD_REQUEST,
        };
        
        actix_web::HttpResponse::build(status)
            .json(serde_json::json!({
                "error": self.to_string(),
                "status": status.as_u16(),
            }))
    }
}

// Result type alias for convenience
pub type Result<T> = std::result::Result<T, AppError>;

// Example usage with ? operator
pub async fn get_user_by_id(pool: &PgPool, id: Uuid) -> Result<User> {
    let user = sqlx::query_as!(
        User,
        r#"
        SELECT id, email, username, created_at, updated_at
        FROM users
        WHERE id = $1
        "#,
        id
    )
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| AppError::NotFound(format!("User with id {} not found", id)))?;
    
    Ok(user)
}
```

### 2. Async Web Server with Actix-web

```rust
use actix_web::{web, App, HttpServer, middleware, HttpResponse};
use actix_cors::Cors;
use sqlx::postgres::PgPoolOptions;
use std::sync::Arc;
use dotenv::dotenv;

// Application state
#[derive(Clone)]
pub struct AppState {
    pub db: sqlx::PgPool,
    pub jwt_secret: String,
    pub redis_client: redis::Client,
}

// Main application setup
#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenv().ok();
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));

    // Database connection pool
    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
        .expect("Failed to create pool");

    // Run migrations
    sqlx::migrate!("./migrations")
        .run(&pool)
        .await
        .expect("Failed to migrate database");

    // Redis client
    let redis_url = std::env::var("REDIS_URL")
        .unwrap_or_else(|_| "redis://127.0.0.1/".to_string());
    let redis_client = redis::Client::open(redis_url)
        .expect("Failed to create Redis client");

    let jwt_secret = std::env::var("JWT_SECRET")
        .expect("JWT_SECRET must be set");

    let state = AppState {
        db: pool,
        jwt_secret,
        redis_client,
    };

    log::info!("Starting server at http://localhost:8080");

    HttpServer::new(move || {
        let cors = Cors::default()
            .allowed_origin("http://localhost:3000")
            .allowed_methods(vec!["GET", "POST", "PUT", "DELETE"])
            .allowed_headers(vec!["Authorization", "Content-Type"])
            .max_age(3600);

        App::new()
            .app_data(web::Data::new(state.clone()))
            .wrap(cors)
            .wrap(middleware::Logger::default())
            .wrap(middleware::NormalizePath::trim())
            .configure(configure_routes)
            .default_service(web::route().to(not_found))
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}

fn configure_routes(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/api")
            .service(
                web::scope("/auth")
                    .route("/register", web::post().to(handlers::auth::register))
                    .route("/login", web::post().to(handlers::auth::login))
                    .route("/refresh", web::post().to(handlers::auth::refresh_token))
            )
            .service(
                web::scope("/users")
                    .wrap(middleware::auth::Auth)
                    .route("", web::get().to(handlers::users::list))
                    .route("/{id}", web::get().to(handlers::users::get))
                    .route("/{id}", web::put().to(handlers::users::update))
                    .route("/{id}", web::delete().to(handlers::users::delete))
            )
            .service(
                web::scope("/health")
                    .route("", web::get().to(health_check))
            )
    );
}

async fn health_check(state: web::Data<AppState>) -> Result<HttpResponse, AppError> {
    // Check database connection
    sqlx::query("SELECT 1")
        .fetch_one(&state.db)
        .await
        .map_err(|_| AppError::Internal)?;
    
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "status": "healthy",
        "timestamp": chrono::Utc::now()
    })))
}

async fn not_found() -> HttpResponse {
    HttpResponse::NotFound().json(serde_json::json!({
        "error": "Resource not found"
    }))
}
```

### 3. Database with SQLx

```rust
use sqlx::{postgres::PgPool, FromRow};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

// Model definition
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct User {
    pub id: Uuid,
    pub email: String,
    pub username: String,
    #[serde(skip_serializing)]
    pub password_hash: String,
    pub role: UserRole,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "user_role", rename_all = "lowercase")]
pub enum UserRole {
    Admin,
    User,
    Moderator,
}

// Repository pattern
pub struct UserRepository {
    pool: PgPool,
}

impl UserRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn create(&self, input: CreateUserInput) -> Result<User> {
        let id = Uuid::new_v4();
        let now = Utc::now();
        let password_hash = hash_password(&input.password)?;

        let user = sqlx::query_as!(
            User,
            r#"
            INSERT INTO users (id, email, username, password_hash, role, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING id, email, username, password_hash, role as "role: UserRole", 
                      is_active, created_at, updated_at
            "#,
            id,
            input.email,
            input.username,
            password_hash,
            UserRole::User as UserRole,
            now,
            now
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(user)
    }

    pub async fn find_by_id(&self, id: Uuid) -> Result<Option<User>> {
        let user = sqlx::query_as!(
            User,
            r#"
            SELECT id, email, username, password_hash, 
                   role as "role: UserRole", is_active, 
                   created_at, updated_at
            FROM users
            WHERE id = $1
            "#,
            id
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok(user)
    }

    pub async fn find_by_email(&self, email: &str) -> Result<Option<User>> {
        let user = sqlx::query_as!(
            User,
            r#"
            SELECT id, email, username, password_hash,
                   role as "role: UserRole", is_active,
                   created_at, updated_at
            FROM users
            WHERE email = $1
            "#,
            email
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok(user)
    }

    pub async fn update(&self, id: Uuid, input: UpdateUserInput) -> Result<User> {
        let mut query = String::from("UPDATE users SET updated_at = NOW()");
        let mut param_count = 1;
        let mut params: Vec<Box<dyn ToString>> = vec![];

        if let Some(username) = input.username {
            param_count += 1;
            query.push_str(&format!(", username = ${}", param_count));
            params.push(Box::new(username));
        }

        if let Some(email) = input.email {
            param_count += 1;
            query.push_str(&format!(", email = ${}", param_count));
            params.push(Box::new(email));
        }

        query.push_str(&format!(" WHERE id = $1 RETURNING *"));

        // Use dynamic query building or consider using a query builder
        todo!("Implement dynamic update query")
    }

    pub async fn list(&self, pagination: Pagination) -> Result<Vec<User>> {
        let users = sqlx::query_as!(
            User,
            r#"
            SELECT id, email, username, password_hash,
                   role as "role: UserRole", is_active,
                   created_at, updated_at
            FROM users
            ORDER BY created_at DESC
            LIMIT $1 OFFSET $2
            "#,
            pagination.limit as i64,
            pagination.offset as i64
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(users)
    }
}

// Transactions
pub async fn transfer_credits(
    pool: &PgPool,
    from_user_id: Uuid,
    to_user_id: Uuid,
    amount: i32,
) -> Result<()> {
    let mut tx = pool.begin().await?;

    // Deduct from sender
    sqlx::query!(
        "UPDATE users SET credits = credits - $1 WHERE id = $2 AND credits >= $1",
        amount,
        from_user_id
    )
    .execute(&mut *tx)
    .await?;

    // Add to receiver
    sqlx::query!(
        "UPDATE users SET credits = credits + $1 WHERE id = $2",
        amount,
        to_user_id
    )
    .execute(&mut *tx)
    .await?;

    // Log transaction
    sqlx::query!(
        "INSERT INTO transactions (from_user_id, to_user_id, amount, created_at)
         VALUES ($1, $2, $3, NOW())",
        from_user_id,
        to_user_id,
        amount
    )
    .execute(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(())
}
```

### 4. Authentication with JWT

```rust
use jsonwebtoken::{encode, decode, Header, Validation, EncodingKey, DecodingKey};
use serde::{Deserialize, Serialize};
use chrono::{Utc, Duration};
use actix_web::{FromRequest, HttpRequest, dev::Payload, Error as ActixError};
use futures::future::{Ready, ok, err};

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,  // user id
    pub email: String,
    pub role: String,
    pub exp: i64,     // expiry
    pub iat: i64,     // issued at
}

impl Claims {
    pub fn new(user_id: &str, email: &str, role: &str) -> Self {
        let now = Utc::now();
        let exp = (now + Duration::hours(24)).timestamp();

        Self {
            sub: user_id.to_string(),
            email: email.to_string(),
            role: role.to_string(),
            exp,
            iat: now.timestamp(),
        }
    }
}

pub struct JwtService {
    secret: String,
}

impl JwtService {
    pub fn new(secret: String) -> Self {
        Self { secret }
    }

    pub fn generate_token(&self, claims: &Claims) -> Result<String> {
        let token = encode(
            &Header::default(),
            claims,
            &EncodingKey::from_secret(self.secret.as_ref()),
        )
        .map_err(|_| AppError::Internal)?;

        Ok(token)
    }

    pub fn verify_token(&self, token: &str) -> Result<Claims> {
        let token_data = decode::<Claims>(
            token,
            &DecodingKey::from_secret(self.secret.as_ref()),
            &Validation::default(),
        )
        .map_err(|_| AppError::Authentication)?;

        Ok(token_data.claims)
    }
}

// Actix-web extractor for authenticated user
pub struct AuthUser {
    pub id: Uuid,
    pub email: String,
    pub role: UserRole,
}

impl FromRequest for AuthUser {
    type Error = ActixError;
    type Future = Ready<Result<Self, Self::Error>>;

    fn from_request(req: &HttpRequest, _: &mut Payload) -> Self::Future {
        let auth_header = req.headers().get("Authorization");

        match auth_header {
            Some(header_value) => {
                let header_str = match header_value.to_str() {
                    Ok(s) => s,
                    Err(_) => return err(AppError::Authentication.into()),
                };

                if !header_str.starts_with("Bearer ") {
                    return err(AppError::Authentication.into());
                }

                let token = &header_str[7..];
                let state = req.app_data::<web::Data<AppState>>().unwrap();
                let jwt_service = JwtService::new(state.jwt_secret.clone());

                match jwt_service.verify_token(token) {
                    Ok(claims) => {
                        let user_id = Uuid::parse_str(&claims.sub).unwrap();
                        let role = UserRole::from_str(&claims.role).unwrap();

                        ok(AuthUser {
                            id: user_id,
                            email: claims.email,
                            role,
                        })
                    }
                    Err(_) => err(AppError::Authentication.into()),
                }
            }
            None => err(AppError::Authentication.into()),
        }
    }
}
```

### 5. Testing

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::{test, web, App};
    use sqlx::postgres::PgPoolOptions;

    // Unit tests
    #[test]
    fn test_password_hashing() {
        let password = "test_password";
        let hash = hash_password(password).unwrap();
        
        assert!(verify_password(password, &hash).unwrap());
        assert!(!verify_password("wrong_password", &hash).unwrap());
    }

    #[test]
    fn test_jwt_generation() {
        let jwt_service = JwtService::new("test_secret".to_string());
        let claims = Claims::new("user_id", "test@example.com", "user");
        
        let token = jwt_service.generate_token(&claims).unwrap();
        let verified_claims = jwt_service.verify_token(&token).unwrap();
        
        assert_eq!(verified_claims.sub, "user_id");
        assert_eq!(verified_claims.email, "test@example.com");
    }

    // Integration tests
    #[actix_rt::test]
    async fn test_health_endpoint() {
        let pool = create_test_pool().await;
        let state = AppState {
            db: pool,
            jwt_secret: "test_secret".to_string(),
            redis_client: create_test_redis(),
        };

        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(state))
                .route("/health", web::get().to(health_check))
        ).await;

        let req = test::TestRequest::get()
            .uri("/health")
            .to_request();
        
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }

    #[actix_rt::test]
    async fn test_user_creation() {
        let pool = create_test_pool().await;
        let repo = UserRepository::new(pool);

        let input = CreateUserInput {
            email: "test@example.com".to_string(),
            username: "testuser".to_string(),
            password: "password123".to_string(),
        };

        let user = repo.create(input).await.unwrap();
        
        assert_eq!(user.email, "test@example.com");
        assert_eq!(user.username, "testuser");
        assert_eq!(user.role, UserRole::User);
    }

    async fn create_test_pool() -> PgPool {
        let database_url = std::env::var("TEST_DATABASE_URL")
            .unwrap_or_else(|_| "postgres://localhost/test_db".to_string());
        
        PgPoolOptions::new()
            .max_connections(5)
            .connect(&database_url)
            .await
            .expect("Failed to create test pool")
    }
}

// Benchmarks
#[cfg(all(test, not(target_env = "msvc")))]
mod benches {
    use criterion::{black_box, criterion_group, criterion_main, Criterion};
    use super::*;

    fn benchmark_password_hashing(c: &mut Criterion) {
        c.bench_function("password hashing", |b| {
            b.iter(|| hash_password(black_box("test_password")))
        });
    }

    fn benchmark_jwt_generation(c: &mut Criterion) {
        let jwt_service = JwtService::new("test_secret".to_string());
        let claims = Claims::new("user_id", "test@example.com", "user");
        
        c.bench_function("jwt generation", |b| {
            b.iter(|| jwt_service.generate_token(black_box(&claims)))
        });
    }

    criterion_group!(benches, benchmark_password_hashing, benchmark_jwt_generation);
    criterion_main!(benches);
}
```

### 6. Configuration Management

```rust
use serde::Deserialize;
use config::{Config, ConfigError, Environment, File};

#[derive(Debug, Deserialize, Clone)]
pub struct Settings {
    pub server: ServerConfig,
    pub database: DatabaseConfig,
    pub redis: RedisConfig,
    pub jwt: JwtConfig,
    pub cors: CorsConfig,
}

#[derive(Debug, Deserialize, Clone)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
    pub workers: usize,
}

#[derive(Debug, Deserialize, Clone)]
pub struct DatabaseConfig {
    pub url: String,
    pub max_connections: u32,
    pub min_connections: u32,
    pub connect_timeout: u64,
}

#[derive(Debug, Deserialize, Clone)]
pub struct RedisConfig {
    pub url: String,
}

#[derive(Debug, Deserialize, Clone)]
pub struct JwtConfig {
    pub secret: String,
    pub expiration: i64,
}

#[derive(Debug, Deserialize, Clone)]
pub struct CorsConfig {
    pub allowed_origins: Vec<String>,
    pub allowed_methods: Vec<String>,
    pub allowed_headers: Vec<String>,
    pub max_age: usize,
}

impl Settings {
    pub fn new() -> Result<Self, ConfigError> {
        let environment = std::env::var("RUN_ENV")
            .unwrap_or_else(|_| "development".into());

        let mut builder = Config::builder()
            // Start with default values
            .set_default("server.host", "127.0.0.1")?
            .set_default("server.port", 8080)?
            .set_default("server.workers", 4)?
            // Add configuration from file
            .add_source(File::with_name("config/default"))
            // Add environment-specific configuration
            .add_source(File::with_name(&format!("config/{}", environment)).required(false))
            // Add environment variables (with prefix APP)
            .add_source(Environment::with_prefix("APP").separator("__"));

        builder.build()?.try_deserialize()
    }
}
```

### Common Pitfalls to Avoid

1. **Not handling all Result types properly**
2. **Ignoring lifetime annotations when needed**
3. **Creating unnecessary clones**
4. **Not using iterators effectively**
5. **Blocking async runtime with synchronous code**
6. **Not leveraging the type system**
7. **Using unwrap() in production code**
8. **Not implementing proper error types**
9. **Ignoring compiler warnings**
10. **Not using cargo clippy and fmt**

### Performance Tips

```rust
// Use iterators instead of loops
let sum: i32 = numbers.iter().filter(|&&x| x > 0).sum();

// Use Vec::with_capacity when size is known
let mut vec = Vec::with_capacity(1000);

// Use Cow for efficient string handling
use std::borrow::Cow;
fn process_string(s: &str) -> Cow<str> {
    if s.contains("old") {
        Cow::Owned(s.replace("old", "new"))
    } else {
        Cow::Borrowed(s)
    }
}

// Use Arc for shared ownership in async contexts
use std::sync::Arc;
let shared_state = Arc::new(AppState { /* ... */ });

// Use lazy_static for global constants
use lazy_static::lazy_static;
lazy_static! {
    static ref REGEX: Regex = Regex::new(r"^\d{4}-\d{2}-\d{2}$").unwrap();
}
```

### Useful Crates

- **tokio**: Async runtime
- **actix-web**: Web framework
- **axum**: Alternative web framework
- **sqlx**: Async SQL toolkit
- **diesel**: ORM and query builder
- **serde**: Serialization framework
- **reqwest**: HTTP client
- **redis**: Redis client
- **jsonwebtoken**: JWT handling
- **bcrypt/argon2**: Password hashing
- **uuid**: UUID generation
- **chrono**: Date and time
- **tracing**: Application instrumentation
- **thiserror/anyhow**: Error handling