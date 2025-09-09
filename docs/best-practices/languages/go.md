# Go Best Practices

## Official Documentation
- **Go Documentation**: https://go.dev/doc/
- **Effective Go**: https://go.dev/doc/effective_go
- **Go Code Review Comments**: https://github.com/golang/go/wiki/CodeReviewComments
- **Go Modules**: https://go.dev/ref/mod

## Project Structure

```
project-root/
├── cmd/
│   ├── api/
│   │   └── main.go
│   └── worker/
│       └── main.go
├── internal/
│   ├── config/
│   │   └── config.go
│   ├── database/
│   │   ├── postgres.go
│   │   └── migrations/
│   ├── handler/
│   │   ├── auth.go
│   │   ├── user.go
│   │   └── product.go
│   ├── middleware/
│   │   ├── auth.go
│   │   ├── cors.go
│   │   └── logger.go
│   ├── model/
│   │   ├── user.go
│   │   └── product.go
│   ├── repository/
│   │   ├── interface.go
│   │   ├── user_repository.go
│   │   └── product_repository.go
│   ├── service/
│   │   ├── auth_service.go
│   │   ├── user_service.go
│   │   └── product_service.go
│   └── util/
│       ├── validator.go
│       └── response.go
├── pkg/
│   ├── errors/
│   │   └── errors.go
│   ├── logger/
│   │   └── logger.go
│   └── token/
│       └── jwt.go
├── api/
│   └── openapi.yaml
├── scripts/
│   └── migrate.sh
├── test/
│   ├── integration/
│   └── mocks/
├── .env.example
├── .gitignore
├── Dockerfile
├── Makefile
├── go.mod
├── go.sum
└── README.md
```

## Core Best Practices

### 1. Application Structure with Clean Architecture

```go
// internal/model/user.go
package model

import (
    "time"
    "github.com/google/uuid"
)

type User struct {
    ID        uuid.UUID  `json:"id" db:"id"`
    Email     string     `json:"email" db:"email"`
    Username  string     `json:"username" db:"username"`
    Password  string     `json:"-" db:"password_hash"`
    Role      UserRole   `json:"role" db:"role"`
    CreatedAt time.Time  `json:"created_at" db:"created_at"`
    UpdatedAt time.Time  `json:"updated_at" db:"updated_at"`
    DeletedAt *time.Time `json:"-" db:"deleted_at"`
}

type UserRole string

const (
    RoleAdmin     UserRole = "admin"
    RoleUser      UserRole = "user"
    RoleModerator UserRole = "moderator"
)

// Validation
func (u *User) Validate() error {
    if u.Email == "" {
        return ErrInvalidEmail
    }
    if u.Username == "" || len(u.Username) < 3 {
        return ErrInvalidUsername
    }
    return nil
}

// internal/repository/interface.go
package repository

import (
    "context"
    "github.com/google/uuid"
    "myapp/internal/model"
)

type UserRepository interface {
    Create(ctx context.Context, user *model.User) error
    GetByID(ctx context.Context, id uuid.UUID) (*model.User, error)
    GetByEmail(ctx context.Context, email string) (*model.User, error)
    Update(ctx context.Context, user *model.User) error
    Delete(ctx context.Context, id uuid.UUID) error
    List(ctx context.Context, offset, limit int) ([]*model.User, error)
}

type ProductRepository interface {
    Create(ctx context.Context, product *model.Product) error
    GetByID(ctx context.Context, id uuid.UUID) (*model.Product, error)
    Update(ctx context.Context, product *model.Product) error
    Delete(ctx context.Context, id uuid.UUID) error
    List(ctx context.Context, filter ProductFilter) ([]*model.Product, error)
}

// internal/repository/user_repository.go
package repository

import (
    "context"
    "database/sql"
    "fmt"
    "github.com/google/uuid"
    "github.com/jmoiron/sqlx"
    "myapp/internal/model"
    "myapp/pkg/errors"
)

type userRepository struct {
    db *sqlx.DB
}

func NewUserRepository(db *sqlx.DB) UserRepository {
    return &userRepository{db: db}
}

func (r *userRepository) Create(ctx context.Context, user *model.User) error {
    query := `
        INSERT INTO users (id, email, username, password_hash, role, created_at, updated_at)
        VALUES (:id, :email, :username, :password_hash, :role, :created_at, :updated_at)
    `
    
    user.ID = uuid.New()
    user.CreatedAt = time.Now()
    user.UpdatedAt = time.Now()
    
    _, err := r.db.NamedExecContext(ctx, query, user)
    if err != nil {
        return errors.Wrap(err, "failed to create user")
    }
    
    return nil
}

func (r *userRepository) GetByID(ctx context.Context, id uuid.UUID) (*model.User, error) {
    var user model.User
    query := `
        SELECT id, email, username, password_hash, role, created_at, updated_at
        FROM users
        WHERE id = $1 AND deleted_at IS NULL
    `
    
    err := r.db.GetContext(ctx, &user, query, id)
    if err != nil {
        if err == sql.ErrNoRows {
            return nil, errors.ErrNotFound
        }
        return nil, errors.Wrap(err, "failed to get user")
    }
    
    return &user, nil
}

func (r *userRepository) Update(ctx context.Context, user *model.User) error {
    query := `
        UPDATE users
        SET email = :email, username = :username, updated_at = :updated_at
        WHERE id = :id AND deleted_at IS NULL
    `
    
    user.UpdatedAt = time.Now()
    
    result, err := r.db.NamedExecContext(ctx, query, user)
    if err != nil {
        return errors.Wrap(err, "failed to update user")
    }
    
    rows, err := result.RowsAffected()
    if err != nil {
        return errors.Wrap(err, "failed to get rows affected")
    }
    
    if rows == 0 {
        return errors.ErrNotFound
    }
    
    return nil
}
```

### 2. Service Layer

```go
// internal/service/user_service.go
package service

import (
    "context"
    "myapp/internal/model"
    "myapp/internal/repository"
    "myapp/pkg/errors"
    "myapp/pkg/token"
    "golang.org/x/crypto/bcrypt"
)

type UserService interface {
    Register(ctx context.Context, input RegisterInput) (*model.User, error)
    Login(ctx context.Context, email, password string) (string, error)
    GetUser(ctx context.Context, id uuid.UUID) (*model.User, error)
    UpdateUser(ctx context.Context, id uuid.UUID, input UpdateUserInput) (*model.User, error)
    ListUsers(ctx context.Context, page, pageSize int) (*PaginatedUsers, error)
}

type userService struct {
    userRepo repository.UserRepository
    jwtMaker token.Maker
}

func NewUserService(userRepo repository.UserRepository, jwtMaker token.Maker) UserService {
    return &userService{
        userRepo: userRepo,
        jwtMaker: jwtMaker,
    }
}

type RegisterInput struct {
    Email    string `json:"email" validate:"required,email"`
    Username string `json:"username" validate:"required,min=3,max=30"`
    Password string `json:"password" validate:"required,min=8"`
}

type UpdateUserInput struct {
    Username *string `json:"username,omitempty" validate:"omitempty,min=3,max=30"`
    Email    *string `json:"email,omitempty" validate:"omitempty,email"`
}

type PaginatedUsers struct {
    Users      []*model.User `json:"users"`
    TotalCount int64         `json:"total_count"`
    Page       int           `json:"page"`
    PageSize   int           `json:"page_size"`
}

func (s *userService) Register(ctx context.Context, input RegisterInput) (*model.User, error) {
    // Check if user already exists
    existingUser, _ := s.userRepo.GetByEmail(ctx, input.Email)
    if existingUser != nil {
        return nil, errors.ErrEmailAlreadyExists
    }
    
    // Hash password
    hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
    if err != nil {
        return nil, errors.Wrap(err, "failed to hash password")
    }
    
    user := &model.User{
        Email:    input.Email,
        Username: input.Username,
        Password: string(hashedPassword),
        Role:     model.RoleUser,
    }
    
    if err := s.userRepo.Create(ctx, user); err != nil {
        return nil, err
    }
    
    return user, nil
}

func (s *userService) Login(ctx context.Context, email, password string) (string, error) {
    user, err := s.userRepo.GetByEmail(ctx, email)
    if err != nil {
        if errors.Is(err, errors.ErrNotFound) {
            return "", errors.ErrInvalidCredentials
        }
        return "", err
    }
    
    // Verify password
    if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password)); err != nil {
        return "", errors.ErrInvalidCredentials
    }
    
    // Generate JWT token
    token, err := s.jwtMaker.CreateToken(user.ID.String(), user.Role, 24*time.Hour)
    if err != nil {
        return "", errors.Wrap(err, "failed to create token")
    }
    
    return token, nil
}

func (s *userService) GetUser(ctx context.Context, id uuid.UUID) (*model.User, error) {
    return s.userRepo.GetByID(ctx, id)
}

func (s *userService) UpdateUser(ctx context.Context, id uuid.UUID, input UpdateUserInput) (*model.User, error) {
    user, err := s.userRepo.GetByID(ctx, id)
    if err != nil {
        return nil, err
    }
    
    if input.Username != nil {
        user.Username = *input.Username
    }
    
    if input.Email != nil {
        user.Email = *input.Email
    }
    
    if err := s.userRepo.Update(ctx, user); err != nil {
        return nil, err
    }
    
    return user, nil
}
```

### 3. HTTP Handlers with Gin

```go
// internal/handler/user.go
package handler

import (
    "net/http"
    "strconv"
    
    "github.com/gin-gonic/gin"
    "github.com/google/uuid"
    "myapp/internal/service"
    "myapp/pkg/errors"
    "myapp/pkg/util"
)

type UserHandler struct {
    userService service.UserService
}

func NewUserHandler(userService service.UserService) *UserHandler {
    return &UserHandler{
        userService: userService,
    }
}

func (h *UserHandler) Register(c *gin.Context) {
    var input service.RegisterInput
    if err := c.ShouldBindJSON(&input); err != nil {
        util.ErrorResponse(c, http.StatusBadRequest, "Invalid input", err)
        return
    }
    
    user, err := h.userService.Register(c.Request.Context(), input)
    if err != nil {
        switch {
        case errors.Is(err, errors.ErrEmailAlreadyExists):
            util.ErrorResponse(c, http.StatusConflict, "Email already exists", err)
        default:
            util.ErrorResponse(c, http.StatusInternalServerError, "Failed to register user", err)
        }
        return
    }
    
    util.SuccessResponse(c, http.StatusCreated, "User registered successfully", user)
}

func (h *UserHandler) Login(c *gin.Context) {
    var input struct {
        Email    string `json:"email" binding:"required,email"`
        Password string `json:"password" binding:"required"`
    }
    
    if err := c.ShouldBindJSON(&input); err != nil {
        util.ErrorResponse(c, http.StatusBadRequest, "Invalid input", err)
        return
    }
    
    token, err := h.userService.Login(c.Request.Context(), input.Email, input.Password)
    if err != nil {
        if errors.Is(err, errors.ErrInvalidCredentials) {
            util.ErrorResponse(c, http.StatusUnauthorized, "Invalid credentials", err)
        } else {
            util.ErrorResponse(c, http.StatusInternalServerError, "Failed to login", err)
        }
        return
    }
    
    util.SuccessResponse(c, http.StatusOK, "Login successful", gin.H{
        "token": token,
    })
}

func (h *UserHandler) GetUser(c *gin.Context) {
    idStr := c.Param("id")
    id, err := uuid.Parse(idStr)
    if err != nil {
        util.ErrorResponse(c, http.StatusBadRequest, "Invalid user ID", err)
        return
    }
    
    user, err := h.userService.GetUser(c.Request.Context(), id)
    if err != nil {
        if errors.Is(err, errors.ErrNotFound) {
            util.ErrorResponse(c, http.StatusNotFound, "User not found", err)
        } else {
            util.ErrorResponse(c, http.StatusInternalServerError, "Failed to get user", err)
        }
        return
    }
    
    util.SuccessResponse(c, http.StatusOK, "User retrieved successfully", user)
}

func (h *UserHandler) ListUsers(c *gin.Context) {
    page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
    pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))
    
    if page < 1 {
        page = 1
    }
    if pageSize < 1 || pageSize > 100 {
        pageSize = 10
    }
    
    result, err := h.userService.ListUsers(c.Request.Context(), page, pageSize)
    if err != nil {
        util.ErrorResponse(c, http.StatusInternalServerError, "Failed to list users", err)
        return
    }
    
    util.SuccessResponse(c, http.StatusOK, "Users retrieved successfully", result)
}
```

### 4. Middleware

```go
// internal/middleware/auth.go
package middleware

import (
    "net/http"
    "strings"
    
    "github.com/gin-gonic/gin"
    "myapp/pkg/token"
    "myapp/pkg/util"
)

func AuthMiddleware(tokenMaker token.Maker) gin.HandlerFunc {
    return func(c *gin.Context) {
        authHeader := c.GetHeader("Authorization")
        if authHeader == "" {
            util.ErrorResponse(c, http.StatusUnauthorized, "Authorization header is required", nil)
            c.Abort()
            return
        }
        
        fields := strings.Fields(authHeader)
        if len(fields) != 2 || fields[0] != "Bearer" {
            util.ErrorResponse(c, http.StatusUnauthorized, "Invalid authorization header format", nil)
            c.Abort()
            return
        }
        
        accessToken := fields[1]
        payload, err := tokenMaker.VerifyToken(accessToken)
        if err != nil {
            util.ErrorResponse(c, http.StatusUnauthorized, "Invalid or expired token", err)
            c.Abort()
            return
        }
        
        c.Set("user_id", payload.UserID)
        c.Set("user_role", payload.Role)
        c.Next()
    }
}

func RequireRole(roles ...string) gin.HandlerFunc {
    return func(c *gin.Context) {
        userRole, exists := c.Get("user_role")
        if !exists {
            util.ErrorResponse(c, http.StatusForbidden, "Access denied", nil)
            c.Abort()
            return
        }
        
        for _, role := range roles {
            if userRole == role {
                c.Next()
                return
            }
        }
        
        util.ErrorResponse(c, http.StatusForbidden, "Insufficient permissions", nil)
        c.Abort()
    }
}

// internal/middleware/logger.go
package middleware

import (
    "time"
    
    "github.com/gin-gonic/gin"
    "go.uber.org/zap"
)

func LoggerMiddleware(logger *zap.Logger) gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()
        path := c.Request.URL.Path
        raw := c.Request.URL.RawQuery
        
        c.Next()
        
        latency := time.Since(start)
        clientIP := c.ClientIP()
        method := c.Request.Method
        statusCode := c.Writer.Status()
        
        if raw != "" {
            path = path + "?" + raw
        }
        
        logger.Info("HTTP Request",
            zap.String("method", method),
            zap.String("path", path),
            zap.Int("status", statusCode),
            zap.String("ip", clientIP),
            zap.Duration("latency", latency),
            zap.String("user-agent", c.Request.UserAgent()),
        )
    }
}
```

### 5. Error Handling

```go
// pkg/errors/errors.go
package errors

import (
    "errors"
    "fmt"
)

var (
    ErrNotFound           = errors.New("resource not found")
    ErrInvalidCredentials = errors.New("invalid credentials")
    ErrEmailAlreadyExists = errors.New("email already exists")
    ErrUnauthorized       = errors.New("unauthorized")
    ErrForbidden          = errors.New("forbidden")
    ErrInvalidInput       = errors.New("invalid input")
    ErrInternal           = errors.New("internal server error")
)

type AppError struct {
    Code    string `json:"code"`
    Message string `json:"message"`
    Err     error  `json:"-"`
}

func (e *AppError) Error() string {
    if e.Err != nil {
        return fmt.Sprintf("%s: %v", e.Message, e.Err)
    }
    return e.Message
}

func (e *AppError) Unwrap() error {
    return e.Err
}

func New(code, message string) *AppError {
    return &AppError{
        Code:    code,
        Message: message,
    }
}

func Wrap(err error, message string) error {
    if err == nil {
        return nil
    }
    return &AppError{
        Message: message,
        Err:     err,
    }
}

func Is(err, target error) bool {
    return errors.Is(err, target)
}
```

### 6. Configuration

```go
// internal/config/config.go
package config

import (
    "fmt"
    "time"
    
    "github.com/spf13/viper"
)

type Config struct {
    Server   ServerConfig   `mapstructure:"server"`
    Database DatabaseConfig `mapstructure:"database"`
    Redis    RedisConfig    `mapstructure:"redis"`
    JWT      JWTConfig      `mapstructure:"jwt"`
    Logger   LoggerConfig   `mapstructure:"logger"`
}

type ServerConfig struct {
    Port         string        `mapstructure:"port"`
    ReadTimeout  time.Duration `mapstructure:"read_timeout"`
    WriteTimeout time.Duration `mapstructure:"write_timeout"`
    IdleTimeout  time.Duration `mapstructure:"idle_timeout"`
}

type DatabaseConfig struct {
    Driver          string        `mapstructure:"driver"`
    DSN             string        `mapstructure:"dsn"`
    MaxOpenConns    int           `mapstructure:"max_open_conns"`
    MaxIdleConns    int           `mapstructure:"max_idle_conns"`
    ConnMaxLifetime time.Duration `mapstructure:"conn_max_lifetime"`
}

type RedisConfig struct {
    Addr     string `mapstructure:"addr"`
    Password string `mapstructure:"password"`
    DB       int    `mapstructure:"db"`
}

type JWTConfig struct {
    Secret     string        `mapstructure:"secret"`
    Expiration time.Duration `mapstructure:"expiration"`
}

type LoggerConfig struct {
    Level  string `mapstructure:"level"`
    Format string `mapstructure:"format"`
}

func Load(configPath string) (*Config, error) {
    viper.SetConfigFile(configPath)
    
    // Set defaults
    viper.SetDefault("server.port", "8080")
    viper.SetDefault("server.read_timeout", "15s")
    viper.SetDefault("server.write_timeout", "15s")
    viper.SetDefault("server.idle_timeout", "60s")
    
    viper.SetDefault("database.max_open_conns", 25)
    viper.SetDefault("database.max_idle_conns", 25)
    viper.SetDefault("database.conn_max_lifetime", "5m")
    
    viper.SetDefault("logger.level", "info")
    viper.SetDefault("logger.format", "json")
    
    // Read environment variables
    viper.AutomaticEnv()
    
    if err := viper.ReadInConfig(); err != nil {
        return nil, fmt.Errorf("failed to read config: %w", err)
    }
    
    var config Config
    if err := viper.Unmarshal(&config); err != nil {
        return nil, fmt.Errorf("failed to unmarshal config: %w", err)
    }
    
    return &config, nil
}
```

### 7. Main Application

```go
// cmd/api/main.go
package main

import (
    "context"
    "fmt"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"
    
    "github.com/gin-gonic/gin"
    "github.com/jmoiron/sqlx"
    _ "github.com/lib/pq"
    "go.uber.org/zap"
    
    "myapp/internal/config"
    "myapp/internal/handler"
    "myapp/internal/middleware"
    "myapp/internal/repository"
    "myapp/internal/service"
    "myapp/pkg/logger"
    "myapp/pkg/token"
)

func main() {
    // Load configuration
    cfg, err := config.Load("config.yaml")
    if err != nil {
        panic(fmt.Errorf("failed to load config: %w", err))
    }
    
    // Initialize logger
    log, err := logger.New(cfg.Logger.Level, cfg.Logger.Format)
    if err != nil {
        panic(fmt.Errorf("failed to initialize logger: %w", err))
    }
    defer log.Sync()
    
    // Connect to database
    db, err := sqlx.Connect(cfg.Database.Driver, cfg.Database.DSN)
    if err != nil {
        log.Fatal("Failed to connect to database", zap.Error(err))
    }
    defer db.Close()
    
    db.SetMaxOpenConns(cfg.Database.MaxOpenConns)
    db.SetMaxIdleConns(cfg.Database.MaxIdleConns)
    db.SetConnMaxLifetime(cfg.Database.ConnMaxLifetime)
    
    // Run migrations
    if err := runMigrations(db); err != nil {
        log.Fatal("Failed to run migrations", zap.Error(err))
    }
    
    // Initialize repositories
    userRepo := repository.NewUserRepository(db)
    productRepo := repository.NewProductRepository(db)
    
    // Initialize token maker
    tokenMaker, err := token.NewJWTMaker(cfg.JWT.Secret)
    if err != nil {
        log.Fatal("Failed to create token maker", zap.Error(err))
    }
    
    // Initialize services
    userService := service.NewUserService(userRepo, tokenMaker)
    productService := service.NewProductService(productRepo)
    
    // Initialize handlers
    userHandler := handler.NewUserHandler(userService)
    productHandler := handler.NewProductHandler(productService)
    
    // Setup router
    router := setupRouter(cfg, log, tokenMaker, userHandler, productHandler)
    
    // Start server
    srv := &http.Server{
        Addr:         ":" + cfg.Server.Port,
        Handler:      router,
        ReadTimeout:  cfg.Server.ReadTimeout,
        WriteTimeout: cfg.Server.WriteTimeout,
        IdleTimeout:  cfg.Server.IdleTimeout,
    }
    
    // Graceful shutdown
    go func() {
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatal("Failed to start server", zap.Error(err))
        }
    }()
    
    log.Info("Server started", zap.String("port", cfg.Server.Port))
    
    // Wait for interrupt signal
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit
    
    log.Info("Shutting down server...")
    
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()
    
    if err := srv.Shutdown(ctx); err != nil {
        log.Fatal("Server forced to shutdown", zap.Error(err))
    }
    
    log.Info("Server shutdown complete")
}

func setupRouter(
    cfg *config.Config,
    log *zap.Logger,
    tokenMaker token.Maker,
    userHandler *handler.UserHandler,
    productHandler *handler.ProductHandler,
) *gin.Engine {
    gin.SetMode(gin.ReleaseMode)
    
    router := gin.New()
    router.Use(middleware.LoggerMiddleware(log))
    router.Use(middleware.RecoveryMiddleware(log))
    router.Use(middleware.CORSMiddleware())
    
    // Health check
    router.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{"status": "healthy"})
    })
    
    v1 := router.Group("/api/v1")
    {
        // Public routes
        auth := v1.Group("/auth")
        {
            auth.POST("/register", userHandler.Register)
            auth.POST("/login", userHandler.Login)
        }
        
        // Protected routes
        protected := v1.Group("/")
        protected.Use(middleware.AuthMiddleware(tokenMaker))
        {
            users := protected.Group("/users")
            {
                users.GET("/:id", userHandler.GetUser)
                users.GET("", userHandler.ListUsers)
                users.PUT("/:id", userHandler.UpdateUser)
                users.DELETE("/:id", middleware.RequireRole("admin"), userHandler.DeleteUser)
            }
            
            products := protected.Group("/products")
            {
                products.GET("", productHandler.ListProducts)
                products.GET("/:id", productHandler.GetProduct)
                products.POST("", middleware.RequireRole("admin"), productHandler.CreateProduct)
                products.PUT("/:id", middleware.RequireRole("admin"), productHandler.UpdateProduct)
                products.DELETE("/:id", middleware.RequireRole("admin"), productHandler.DeleteProduct)
            }
        }
    }
    
    return router
}
```

### 8. Testing

```go
// test/integration/user_test.go
package integration

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
    
    "github.com/gin-gonic/gin"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    
    "myapp/internal/handler"
    "myapp/internal/service"
)

func TestUserRegistration(t *testing.T) {
    router := setupTestRouter()
    
    tests := []struct {
        name       string
        input      service.RegisterInput
        wantStatus int
    }{
        {
            name: "Valid registration",
            input: service.RegisterInput{
                Email:    "test@example.com",
                Username: "testuser",
                Password: "password123",
            },
            wantStatus: http.StatusCreated,
        },
        {
            name: "Invalid email",
            input: service.RegisterInput{
                Email:    "invalid-email",
                Username: "testuser",
                Password: "password123",
            },
            wantStatus: http.StatusBadRequest,
        },
        {
            name: "Short password",
            input: service.RegisterInput{
                Email:    "test@example.com",
                Username: "testuser",
                Password: "pass",
            },
            wantStatus: http.StatusBadRequest,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            body, _ := json.Marshal(tt.input)
            req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", bytes.NewBuffer(body))
            req.Header.Set("Content-Type", "application/json")
            
            w := httptest.NewRecorder()
            router.ServeHTTP(w, req)
            
            assert.Equal(t, tt.wantStatus, w.Code)
        })
    }
}

// Unit test example
func TestPasswordHashing(t *testing.T) {
    password := "testpassword123"
    
    hash, err := hashPassword(password)
    require.NoError(t, err)
    require.NotEmpty(t, hash)
    require.NotEqual(t, password, hash)
    
    err = verifyPassword(password, hash)
    require.NoError(t, err)
    
    err = verifyPassword("wrongpassword", hash)
    require.Error(t, err)
}

// Benchmark example
func BenchmarkPasswordHashing(b *testing.B) {
    password := "testpassword123"
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        _, _ = hashPassword(password)
    }
}
```

### Common Pitfalls to Avoid

1. **Not handling errors properly**
2. **Ignoring context cancellation**
3. **Not using interfaces for testability**
4. **Creating goroutine leaks**
5. **Not properly closing resources**
6. **Using naked returns in long functions**
7. **Not following Go naming conventions**
8. **Ignoring race conditions**
9. **Not using defer for cleanup**
10. **Using panic instead of returning errors**

### Useful Libraries

- **gin-gonic/gin**: Web framework
- **gorilla/mux**: HTTP router
- **fiber**: Fast web framework
- **gorm**: ORM library
- **sqlx**: SQL extensions
- **go-redis/redis**: Redis client
- **golang-jwt/jwt**: JWT implementation
- **testify**: Testing toolkit
- **mockery**: Mock generation
- **viper**: Configuration management
- **zap**: Structured logging
- **golang-migrate**: Database migrations