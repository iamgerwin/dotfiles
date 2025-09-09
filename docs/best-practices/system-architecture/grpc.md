# gRPC Best Practices

## Official Documentation
- **gRPC Documentation**: https://grpc.io/docs
- **Protocol Buffers**: https://developers.google.com/protocol-buffers
- **gRPC Go**: https://grpc.io/docs/languages/go
- **gRPC Node.js**: https://grpc.io/docs/languages/node

## Protocol Buffers Schema Design

### Service Definition
```proto
syntax = "proto3";

package user.v1;

option go_package = "github.com/myorg/myapp/pkg/proto/user/v1;userv1";

import "google/protobuf/timestamp.proto";
import "google/protobuf/empty.proto";
import "validate/validate.proto";

// User service definition
service UserService {
  // Get a user by ID
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
  
  // List users with pagination
  rpc ListUsers(ListUsersRequest) returns (ListUsersResponse);
  
  // Create a new user
  rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);
  
  // Update an existing user
  rpc UpdateUser(UpdateUserRequest) returns (UpdateUserResponse);
  
  // Delete a user
  rpc DeleteUser(DeleteUserRequest) returns (google.protobuf.Empty);
  
  // Stream user updates
  rpc StreamUserUpdates(StreamUserUpdatesRequest) returns (stream UserUpdate);
}

// User message
message User {
  string id = 1 [(validate.rules).string.min_len = 1];
  string email = 2 [(validate.rules).string.email = true];
  string first_name = 3 [(validate.rules).string.min_len = 1];
  string last_name = 4 [(validate.rules).string.min_len = 1];
  UserRole role = 5;
  google.protobuf.Timestamp created_at = 6;
  google.protobuf.Timestamp updated_at = 7;
}

// User role enumeration
enum UserRole {
  USER_ROLE_UNSPECIFIED = 0;
  USER_ROLE_USER = 1;
  USER_ROLE_ADMIN = 2;
  USER_ROLE_MODERATOR = 3;
}

// Request messages
message GetUserRequest {
  string id = 1 [(validate.rules).string.min_len = 1];
}

message ListUsersRequest {
  int32 page_size = 1 [(validate.rules).int32 = {gte: 1, lte: 100}];
  string page_token = 2;
  string filter = 3; // e.g., "role:USER_ROLE_ADMIN"
  string order_by = 4; // e.g., "created_at desc"
}

message CreateUserRequest {
  string email = 1 [(validate.rules).string.email = true];
  string first_name = 2 [(validate.rules).string.min_len = 1];
  string last_name = 3 [(validate.rules).string.min_len = 1];
  string password = 4 [(validate.rules).string.min_len = 8];
  UserRole role = 5;
}

message UpdateUserRequest {
  string id = 1 [(validate.rules).string.min_len = 1];
  
  // Use field masks for partial updates
  google.protobuf.FieldMask update_mask = 2;
  
  // Fields that can be updated
  string email = 3 [(validate.rules).string.email = true];
  string first_name = 4;
  string last_name = 5;
  UserRole role = 6;
}

message DeleteUserRequest {
  string id = 1 [(validate.rules).string.min_len = 1];
}

// Response messages
message GetUserResponse {
  User user = 1;
}

message ListUsersResponse {
  repeated User users = 1;
  string next_page_token = 2;
  int32 total_count = 3;
}

message CreateUserResponse {
  User user = 1;
}

message UpdateUserResponse {
  User user = 1;
}

// Streaming messages
message StreamUserUpdatesRequest {
  repeated string user_ids = 1;
}

message UserUpdate {
  enum UpdateType {
    UPDATE_TYPE_UNSPECIFIED = 0;
    UPDATE_TYPE_CREATED = 1;
    UPDATE_TYPE_UPDATED = 2;
    UPDATE_TYPE_DELETED = 3;
  }
  
  UpdateType type = 1;
  User user = 2;
  google.protobuf.Timestamp timestamp = 3;
}
```

### Error Handling Schema
```proto
syntax = "proto3";

package common.v1;

import "google/rpc/status.proto";
import "google/protobuf/any.proto";

// Custom error details
message ErrorInfo {
  string reason = 1;
  string domain = 2;
  map<string, string> metadata = 3;
}

message ValidationError {
  repeated FieldViolation field_violations = 1;
}

message FieldViolation {
  string field = 1;
  string description = 2;
}

message RateLimitInfo {
  int64 requests_per_unit = 1;
  string unit = 2; // "minute", "hour", etc.
  int64 retry_after_seconds = 3;
}
```

## Server Implementation

### Go Server Implementation
```go
package server

import (
    "context"
    "errors"
    "fmt"
    "log"
    "net"
    "time"

    "google.golang.org/grpc"
    "google.golang.org/grpc/codes"
    "google.golang.org/grpc/status"
    "google.golang.org/grpc/reflection"
    "google.golang.org/grpc/health"
    "google.golang.org/grpc/health/grpc_health_v1"
    "google.golang.org/grpc/keepalive"
    
    userv1 "github.com/myorg/myapp/pkg/proto/user/v1"
    "github.com/myorg/myapp/internal/service"
)

type UserServer struct {
    userv1.UnimplementedUserServiceServer
    userService service.UserService
}

func NewUserServer(userService service.UserService) *UserServer {
    return &UserServer{
        userService: userService,
    }
}

func (s *UserServer) GetUser(ctx context.Context, req *userv1.GetUserRequest) (*userv1.GetUserResponse, error) {
    // Validate request
    if err := req.Validate(); err != nil {
        return nil, status.Error(codes.InvalidArgument, err.Error())
    }

    // Add timeout to prevent long-running requests
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()

    user, err := s.userService.GetUser(ctx, req.GetId())
    if err != nil {
        if errors.Is(err, service.ErrUserNotFound) {
            return nil, status.Error(codes.NotFound, "user not found")
        }
        return nil, status.Error(codes.Internal, "internal server error")
    }

    return &userv1.GetUserResponse{
        User: convertUserToProto(user),
    }, nil
}

func (s *UserServer) ListUsers(ctx context.Context, req *userv1.ListUsersRequest) (*userv1.ListUsersResponse, error) {
    if err := req.Validate(); err != nil {
        return nil, status.Error(codes.InvalidArgument, err.Error())
    }

    ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
    defer cancel()

    users, nextToken, totalCount, err := s.userService.ListUsers(ctx, &service.ListUsersParams{
        PageSize:  int(req.GetPageSize()),
        PageToken: req.GetPageToken(),
        Filter:    req.GetFilter(),
        OrderBy:   req.GetOrderBy(),
    })
    if err != nil {
        return nil, status.Error(codes.Internal, "failed to list users")
    }

    protoUsers := make([]*userv1.User, len(users))
    for i, user := range users {
        protoUsers[i] = convertUserToProto(user)
    }

    return &userv1.ListUsersResponse{
        Users:         protoUsers,
        NextPageToken: nextToken,
        TotalCount:    int32(totalCount),
    }, nil
}

func (s *UserServer) CreateUser(ctx context.Context, req *userv1.CreateUserRequest) (*userv1.CreateUserResponse, error) {
    if err := req.Validate(); err != nil {
        return nil, status.Error(codes.InvalidArgument, err.Error())
    }

    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()

    user, err := s.userService.CreateUser(ctx, &service.CreateUserParams{
        Email:     req.GetEmail(),
        FirstName: req.GetFirstName(),
        LastName:  req.GetLastName(),
        Password:  req.GetPassword(),
        Role:      convertRoleFromProto(req.GetRole()),
    })
    if err != nil {
        if errors.Is(err, service.ErrUserExists) {
            return nil, status.Error(codes.AlreadyExists, "user already exists")
        }
        return nil, status.Error(codes.Internal, "failed to create user")
    }

    return &userv1.CreateUserResponse{
        User: convertUserToProto(user),
    }, nil
}

func (s *UserServer) StreamUserUpdates(req *userv1.StreamUserUpdatesRequest, stream userv1.UserService_StreamUserUpdatesServer) error {
    if err := req.Validate(); err != nil {
        return status.Error(codes.InvalidArgument, err.Error())
    }

    updatesCh := make(chan *service.UserUpdate, 100)
    
    // Subscribe to user updates
    unsubscribe, err := s.userService.SubscribeToUserUpdates(stream.Context(), req.GetUserIds(), updatesCh)
    if err != nil {
        return status.Error(codes.Internal, "failed to subscribe to updates")
    }
    defer unsubscribe()

    for {
        select {
        case <-stream.Context().Done():
            return nil
        case update := <-updatesCh:
            protoUpdate := &userv1.UserUpdate{
                Type:      convertUpdateTypeToProto(update.Type),
                User:      convertUserToProto(update.User),
                Timestamp: timestamppb.New(update.Timestamp),
            }
            
            if err := stream.Send(protoUpdate); err != nil {
                return err
            }
        }
    }
}

// Server configuration and startup
func StartServer() error {
    lis, err := net.Listen("tcp", ":8080")
    if err != nil {
        return fmt.Errorf("failed to listen: %v", err)
    }

    // Configure server options
    opts := []grpc.ServerOption{
        grpc.MaxRecvMsgSize(4 * 1024 * 1024),  // 4MB
        grpc.MaxSendMsgSize(4 * 1024 * 1024),  // 4MB
        grpc.KeepaliveParams(keepalive.ServerParameters{
            MaxConnectionIdle:     15 * time.Second,
            MaxConnectionAge:      30 * time.Second,
            MaxConnectionAgeGrace: 5 * time.Second,
            Time:                  5 * time.Second,
            Timeout:               1 * time.Second,
        }),
        grpc.KeepaliveEnforcementPolicy(keepalive.EnforcementPolicy{
            MinTime:             5 * time.Second,
            PermitWithoutStream: true,
        }),
        grpc.UnaryInterceptor(grpc_middleware.ChainUnaryServer(
            grpc_recovery.UnaryServerInterceptor(),
            grpc_auth.UnaryServerInterceptor(authFunc),
            grpc_validator.UnaryServerInterceptor(),
            grpc_prometheus.UnaryServerInterceptor,
        )),
        grpc.StreamInterceptor(grpc_middleware.ChainStreamServer(
            grpc_recovery.StreamServerInterceptor(),
            grpc_auth.StreamServerInterceptor(authFunc),
            grpc_validator.StreamServerInterceptor(),
            grpc_prometheus.StreamServerInterceptor,
        )),
    }

    s := grpc.NewServer(opts...)

    // Register services
    userService := service.NewUserService(db)
    userServer := NewUserServer(userService)
    userv1.RegisterUserServiceServer(s, userServer)

    // Enable reflection for development
    if os.Getenv("ENV") == "development" {
        reflection.Register(s)
    }

    // Register health check service
    healthServer := health.NewServer()
    grpc_health_v1.RegisterHealthServer(s, healthServer)
    healthServer.SetServingStatus("", grpc_health_v1.HealthCheckResponse_SERVING)

    log.Printf("Starting gRPC server on :8080")
    return s.Serve(lis)
}
```

### Node.js Server Implementation
```javascript
const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const path = require('path');

// Load proto files
const packageDefinition = protoLoader.loadSync(
  path.join(__dirname, '../proto/user/v1/user.proto'),
  {
    keepCase: true,
    longs: String,
    enums: String,
    defaults: true,
    oneofs: true,
    includeDirs: [path.join(__dirname, '../proto')]
  }
);

const userProto = grpc.loadPackageDefinition(packageDefinition).user.v1;

class UserService {
  constructor(userRepository) {
    this.userRepository = userRepository;
  }

  async getUser(call, callback) {
    try {
      // Validate request
      if (!call.request.id) {
        return callback({
          code: grpc.status.INVALID_ARGUMENT,
          message: 'User ID is required'
        });
      }

      const user = await this.userRepository.findById(call.request.id);
      
      if (!user) {
        return callback({
          code: grpc.status.NOT_FOUND,
          message: 'User not found'
        });
      }

      callback(null, { user: this.convertUserToProto(user) });
    } catch (error) {
      console.error('Error in getUser:', error);
      callback({
        code: grpc.status.INTERNAL,
        message: 'Internal server error'
      });
    }
  }

  async listUsers(call, callback) {
    try {
      const { pageSize = 10, pageToken, filter, orderBy } = call.request;

      if (pageSize > 100) {
        return callback({
          code: grpc.status.INVALID_ARGUMENT,
          message: 'Page size cannot exceed 100'
        });
      }

      const result = await this.userRepository.findMany({
        pageSize: parseInt(pageSize),
        pageToken,
        filter,
        orderBy
      });

      const protoUsers = result.users.map(user => this.convertUserToProto(user));

      callback(null, {
        users: protoUsers,
        nextPageToken: result.nextPageToken,
        totalCount: result.totalCount
      });
    } catch (error) {
      console.error('Error in listUsers:', error);
      callback({
        code: grpc.status.INTERNAL,
        message: 'Failed to list users'
      });
    }
  }

  async createUser(call, callback) {
    try {
      const { email, firstName, lastName, password, role } = call.request;

      // Validate email format
      if (!this.isValidEmail(email)) {
        return callback({
          code: grpc.status.INVALID_ARGUMENT,
          message: 'Invalid email format'
        });
      }

      // Check if user exists
      const existingUser = await this.userRepository.findByEmail(email);
      if (existingUser) {
        return callback({
          code: grpc.status.ALREADY_EXISTS,
          message: 'User already exists'
        });
      }

      const user = await this.userRepository.create({
        email,
        firstName,
        lastName,
        password,
        role
      });

      callback(null, { user: this.convertUserToProto(user) });
    } catch (error) {
      console.error('Error in createUser:', error);
      callback({
        code: grpc.status.INTERNAL,
        message: 'Failed to create user'
      });
    }
  }

  streamUserUpdates(call) {
    const { userIds } = call.request;

    // Set up real-time updates subscription
    const subscription = this.userRepository.subscribeToUpdates(userIds, (update) => {
      const protoUpdate = {
        type: this.convertUpdateType(update.type),
        user: this.convertUserToProto(update.user),
        timestamp: {
          seconds: Math.floor(update.timestamp.getTime() / 1000),
          nanos: (update.timestamp.getTime() % 1000) * 1000000
        }
      };

      call.write(protoUpdate);
    });

    call.on('cancelled', () => {
      subscription.unsubscribe();
    });

    call.on('error', (error) => {
      console.error('Stream error:', error);
      subscription.unsubscribe();
    });
  }

  convertUserToProto(user) {
    return {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      createdAt: {
        seconds: Math.floor(user.createdAt.getTime() / 1000),
        nanos: (user.createdAt.getTime() % 1000) * 1000000
      },
      updatedAt: {
        seconds: Math.floor(user.updatedAt.getTime() / 1000),
        nanos: (user.updatedAt.getTime() % 1000) * 1000000
      }
    };
  }

  isValidEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }
}

// Server setup
function startServer() {
  const server = new grpc.Server({
    'grpc.keepalive_time_ms': 30000,
    'grpc.keepalive_timeout_ms': 5000,
    'grpc.keepalive_permit_without_calls': true,
    'grpc.http2.max_pings_without_data': 0,
    'grpc.http2.min_time_between_pings_ms': 10000,
    'grpc.http2.min_ping_interval_without_data_ms': 300000
  });

  const userRepository = new UserRepository();
  const userService = new UserService(userRepository);

  server.addService(userProto.UserService.service, {
    getUser: userService.getUser.bind(userService),
    listUsers: userService.listUsers.bind(userService),
    createUser: userService.createUser.bind(userService),
    updateUser: userService.updateUser.bind(userService),
    deleteUser: userService.deleteUser.bind(userService),
    streamUserUpdates: userService.streamUserUpdates.bind(userService)
  });

  const port = process.env.PORT || 8080;
  server.bindAsync(`0.0.0.0:${port}`, grpc.ServerCredentials.createInsecure(), (err, port) => {
    if (err) {
      console.error('Failed to start server:', err);
      return;
    }
    
    console.log(`gRPC server started on port ${port}`);
    server.start();
  });
}

module.exports = { startServer };
```

## Client Implementation

### Go Client
```go
package client

import (
    "context"
    "crypto/tls"
    "log"
    "time"

    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials"
    "google.golang.org/grpc/keepalive"
    
    userv1 "github.com/myorg/myapp/pkg/proto/user/v1"
)

type UserClient struct {
    client userv1.UserServiceClient
    conn   *grpc.ClientConn
}

func NewUserClient(address string) (*UserClient, error) {
    // Configure TLS
    tlsConfig := &tls.Config{
        ServerName: "api.example.com",
    }
    
    // Configure connection options
    opts := []grpc.DialOption{
        grpc.WithTransportCredentials(credentials.NewTLS(tlsConfig)),
        grpc.WithKeepaliveParams(keepalive.ClientParameters{
            Time:                10 * time.Second,
            Timeout:             time.Second,
            PermitWithoutStream: true,
        }),
        grpc.WithUnaryInterceptor(grpc_middleware.ChainUnaryClient(
            grpc_retry.UnaryClientInterceptor(
                grpc_retry.WithMax(3),
                grpc_retry.WithBackoff(grpc_retry.BackoffLinear(100*time.Millisecond)),
            ),
            grpc_prometheus.UnaryClientInterceptor,
        )),
        grpc.WithStreamInterceptor(grpc_middleware.ChainStreamClient(
            grpc_retry.StreamClientInterceptor(),
            grpc_prometheus.StreamClientInterceptor,
        )),
    }

    conn, err := grpc.Dial(address, opts...)
    if err != nil {
        return nil, err
    }

    client := userv1.NewUserServiceClient(conn)

    return &UserClient{
        client: client,
        conn:   conn,
    }, nil
}

func (c *UserClient) GetUser(ctx context.Context, userID string) (*userv1.User, error) {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()

    req := &userv1.GetUserRequest{
        Id: userID,
    }

    resp, err := c.client.GetUser(ctx, req)
    if err != nil {
        return nil, err
    }

    return resp.GetUser(), nil
}

func (c *UserClient) ListUsers(ctx context.Context, pageSize int32, pageToken string) ([]*userv1.User, string, error) {
    ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
    defer cancel()

    req := &userv1.ListUsersRequest{
        PageSize:  pageSize,
        PageToken: pageToken,
    }

    resp, err := c.client.ListUsers(ctx, req)
    if err != nil {
        return nil, "", err
    }

    return resp.GetUsers(), resp.GetNextPageToken(), nil
}

func (c *UserClient) StreamUserUpdates(ctx context.Context, userIDs []string) (<-chan *userv1.UserUpdate, error) {
    req := &userv1.StreamUserUpdatesRequest{
        UserIds: userIDs,
    }

    stream, err := c.client.StreamUserUpdates(ctx, req)
    if err != nil {
        return nil, err
    }

    updatesCh := make(chan *userv1.UserUpdate, 100)

    go func() {
        defer close(updatesCh)
        
        for {
            update, err := stream.Recv()
            if err != nil {
                log.Printf("Stream error: %v", err)
                return
            }

            select {
            case updatesCh <- update:
            case <-ctx.Done():
                return
            }
        }
    }()

    return updatesCh, nil
}

func (c *UserClient) Close() error {
    return c.conn.Close()
}
```

### JavaScript Client
```javascript
const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const path = require('path');

class UserClient {
  constructor(address) {
    // Load proto files
    const packageDefinition = protoLoader.loadSync(
      path.join(__dirname, '../proto/user/v1/user.proto'),
      {
        keepCase: true,
        longs: String,
        enums: String,
        defaults: true,
        oneofs: true,
        includeDirs: [path.join(__dirname, '../proto')]
      }
    );

    const userProto = grpc.loadPackageDefinition(packageDefinition).user.v1;

    // Configure client options
    const options = {
      'grpc.keepalive_time_ms': 30000,
      'grpc.keepalive_timeout_ms': 5000,
      'grpc.keepalive_permit_without_calls': true,
      'grpc.http2.max_pings_without_data': 0,
      'grpc.http2.min_time_between_pings_ms': 10000,
      'grpc.http2.min_ping_interval_without_data_ms': 300000
    };

    // Create client with TLS credentials
    const credentials = grpc.credentials.createSsl();
    this.client = new userProto.UserService(address, credentials, options);
  }

  getUser(userId) {
    return new Promise((resolve, reject) => {
      const deadline = new Date();
      deadline.setSeconds(deadline.getSeconds() + 5);

      this.client.getUser(
        { id: userId },
        { deadline },
        (error, response) => {
          if (error) {
            reject(error);
          } else {
            resolve(response.user);
          }
        }
      );
    });
  }

  listUsers(pageSize = 10, pageToken = '') {
    return new Promise((resolve, reject) => {
      const deadline = new Date();
      deadline.setSeconds(deadline.getSeconds() + 10);

      this.client.listUsers(
        {
          pageSize,
          pageToken
        },
        { deadline },
        (error, response) => {
          if (error) {
            reject(error);
          } else {
            resolve({
              users: response.users,
              nextPageToken: response.nextPageToken,
              totalCount: response.totalCount
            });
          }
        }
      );
    });
  }

  async createUser(userData) {
    return new Promise((resolve, reject) => {
      const deadline = new Date();
      deadline.setSeconds(deadline.getSeconds() + 5);

      this.client.createUser(
        userData,
        { deadline },
        (error, response) => {
          if (error) {
            reject(error);
          } else {
            resolve(response.user);
          }
        }
      );
    });
  }

  streamUserUpdates(userIds) {
    const stream = this.client.streamUserUpdates({ userIds });
    
    return {
      on: (event, callback) => stream.on(event, callback),
      cancel: () => stream.cancel(),
      destroy: () => stream.destroy()
    };
  }

  close() {
    this.client.close();
  }
}

// Usage example
async function example() {
  const client = new UserClient('api.example.com:443');

  try {
    // Get a user
    const user = await client.getUser('user-123');
    console.log('User:', user);

    // List users
    const { users, nextPageToken } = await client.listUsers(10);
    console.log('Users:', users);

    // Stream updates
    const stream = client.streamUserUpdates(['user-123', 'user-456']);
    
    stream.on('data', (update) => {
      console.log('User update:', update);
    });
    
    stream.on('error', (error) => {
      console.error('Stream error:', error);
    });

    stream.on('end', () => {
      console.log('Stream ended');
    });

    // Clean up after 30 seconds
    setTimeout(() => {
      stream.cancel();
      client.close();
    }, 30000);

  } catch (error) {
    console.error('Error:', error);
    client.close();
  }
}

module.exports = UserClient;
```

## Middleware and Interceptors

### Authentication Interceptor
```go
func authInterceptor(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
    // Skip auth for health checks
    if info.FullMethod == "/grpc.health.v1.Health/Check" {
        return handler(ctx, req)
    }

    // Extract token from metadata
    md, ok := metadata.FromIncomingContext(ctx)
    if !ok {
        return nil, status.Error(codes.Unauthenticated, "missing metadata")
    }

    tokens := md["authorization"]
    if len(tokens) == 0 {
        return nil, status.Error(codes.Unauthenticated, "missing authorization token")
    }

    token := tokens[0]
    if !strings.HasPrefix(token, "Bearer ") {
        return nil, status.Error(codes.Unauthenticated, "invalid token format")
    }

    // Validate JWT token
    claims, err := validateJWT(strings.TrimPrefix(token, "Bearer "))
    if err != nil {
        return nil, status.Error(codes.Unauthenticated, "invalid token")
    }

    // Add user info to context
    ctx = context.WithValue(ctx, "user", claims)
    
    return handler(ctx, req)
}
```

### Rate Limiting Interceptor
```go
import (
    "golang.org/x/time/rate"
    "sync"
)

type RateLimiter struct {
    limiters sync.Map
}

func NewRateLimiter() *RateLimiter {
    return &RateLimiter{}
}

func (rl *RateLimiter) getLimiter(key string) *rate.Limiter {
    limiter, exists := rl.limiters.Load(key)
    if !exists {
        limiter = rate.NewLimiter(rate.Every(time.Minute), 100) // 100 requests per minute
        rl.limiters.Store(key, limiter)
    }
    return limiter.(*rate.Limiter)
}

func (rl *RateLimiter) UnaryInterceptor(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
    // Get client IP or user ID for rate limiting key
    key := getClientKey(ctx)
    limiter := rl.getLimiter(key)

    if !limiter.Allow() {
        return nil, status.Error(codes.ResourceExhausted, "rate limit exceeded")
    }

    return handler(ctx, req)
}
```

### Logging Interceptor
```go
func loggingInterceptor(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
    start := time.Now()
    
    // Extract request ID
    requestID := getRequestID(ctx)
    
    log.Printf("Started %s - RequestID: %s", info.FullMethod, requestID)
    
    resp, err := handler(ctx, req)
    
    duration := time.Since(start)
    status := "OK"
    if err != nil {
        status = grpc.Code(err).String()
    }
    
    log.Printf("Completed %s in %v - Status: %s - RequestID: %s", 
        info.FullMethod, duration, status, requestID)
    
    return resp, err
}
```

## Performance Optimization

### Connection Pooling
```go
type ClientPool struct {
    pool sync.Pool
    address string
}

func NewClientPool(address string) *ClientPool {
    return &ClientPool{
        address: address,
        pool: sync.Pool{
            New: func() interface{} {
                conn, err := grpc.Dial(address, grpc.WithInsecure())
                if err != nil {
                    log.Fatal(err)
                }
                return userv1.NewUserServiceClient(conn)
            },
        },
    }
}

func (cp *ClientPool) GetClient() userv1.UserServiceClient {
    return cp.pool.Get().(userv1.UserServiceClient)
}

func (cp *ClientPool) PutClient(client userv1.UserServiceClient) {
    cp.pool.Put(client)
}
```

### Streaming Optimization
```go
func (s *UserServer) StreamUserUpdates(req *userv1.StreamUserUpdatesRequest, stream userv1.UserService_StreamUserUpdatesServer) error {
    // Use buffered channel to prevent blocking
    updatesCh := make(chan *userv1.UserUpdate, 1000)
    
    // Batch updates to reduce network calls
    ticker := time.NewTicker(100 * time.Millisecond)
    defer ticker.Stop()
    
    updates := make([]*userv1.UserUpdate, 0, 100)
    
    for {
        select {
        case <-stream.Context().Done():
            return nil
        case update := <-updatesCh:
            updates = append(updates, update)
        case <-ticker.C:
            if len(updates) > 0 {
                // Send batched updates
                for _, update := range updates {
                    if err := stream.Send(update); err != nil {
                        return err
                    }
                }
                updates = updates[:0] // Reset slice
            }
        }
    }
}
```

### Caching Strategy
```go
import (
    "github.com/go-redis/redis/v8"
    "encoding/json"
    "time"
)

type CachedUserService struct {
    userService UserService
    redis       *redis.Client
}

func (c *CachedUserService) GetUser(ctx context.Context, userID string) (*User, error) {
    // Try cache first
    cacheKey := fmt.Sprintf("user:%s", userID)
    cached, err := c.redis.Get(ctx, cacheKey).Result()
    if err == nil {
        var user User
        if err := json.Unmarshal([]byte(cached), &user); err == nil {
            return &user, nil
        }
    }

    // Cache miss, fetch from database
    user, err := c.userService.GetUser(ctx, userID)
    if err != nil {
        return nil, err
    }

    // Cache the result
    userData, _ := json.Marshal(user)
    c.redis.Set(ctx, cacheKey, userData, 5*time.Minute)

    return user, nil
}
```

## Testing

### Unit Testing
```go
func TestUserServer_GetUser(t *testing.T) {
    tests := []struct {
        name        string
        request     *userv1.GetUserRequest
        mockUser    *service.User
        mockError   error
        expectedErr error
    }{
        {
            name:     "successful get user",
            request:  &userv1.GetUserRequest{Id: "user-123"},
            mockUser: &service.User{ID: "user-123", Email: "test@example.com"},
            expectedErr: nil,
        },
        {
            name:        "user not found",
            request:     &userv1.GetUserRequest{Id: "nonexistent"},
            mockError:   service.ErrUserNotFound,
            expectedErr: status.Error(codes.NotFound, "user not found"),
        },
        {
            name:        "invalid request",
            request:     &userv1.GetUserRequest{},
            expectedErr: status.Error(codes.InvalidArgument, "validation failed"),
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            mockService := &mocks.UserService{}
            server := NewUserServer(mockService)

            if tt.mockUser != nil {
                mockService.On("GetUser", mock.Anything, tt.request.Id).Return(tt.mockUser, tt.mockError)
            }

            resp, err := server.GetUser(context.Background(), tt.request)

            if tt.expectedErr != nil {
                assert.Error(t, err)
                assert.Equal(t, tt.expectedErr.Error(), err.Error())
            } else {
                assert.NoError(t, err)
                assert.Equal(t, tt.mockUser.ID, resp.User.Id)
            }

            mockService.AssertExpectations(t)
        })
    }
}
```

### Integration Testing
```go
func TestUserServiceIntegration(t *testing.T) {
    // Start test server
    lis, err := net.Listen("tcp", ":0")
    require.NoError(t, err)

    server := grpc.NewServer()
    userService := &testUserService{}
    userv1.RegisterUserServiceServer(server, NewUserServer(userService))

    go server.Serve(lis)
    defer server.Stop()

    // Create client
    conn, err := grpc.Dial(lis.Addr().String(), grpc.WithInsecure())
    require.NoError(t, err)
    defer conn.Close()

    client := userv1.NewUserServiceClient(conn)

    // Test create user
    createReq := &userv1.CreateUserRequest{
        Email:     "test@example.com",
        FirstName: "John",
        LastName:  "Doe",
        Password:  "password123",
        Role:      userv1.UserRole_USER_ROLE_USER,
    }

    createResp, err := client.CreateUser(context.Background(), createReq)
    require.NoError(t, err)
    assert.Equal(t, createReq.Email, createResp.User.Email)

    // Test get user
    getReq := &userv1.GetUserRequest{Id: createResp.User.Id}
    getResp, err := client.GetUser(context.Background(), getReq)
    require.NoError(t, err)
    assert.Equal(t, createResp.User.Id, getResp.User.Id)
}
```

## Monitoring and Observability

### Prometheus Metrics
```go
import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    requestsTotal = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "grpc_requests_total",
            Help: "Total number of gRPC requests",
        },
        []string{"method", "status"},
    )

    requestDuration = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "grpc_request_duration_seconds",
            Help:    "Duration of gRPC requests",
            Buckets: prometheus.DefBuckets,
        },
        []string{"method"},
    )

    activeConnections = promauto.NewGauge(
        prometheus.GaugeOpts{
            Name: "grpc_active_connections",
            Help: "Number of active gRPC connections",
        },
    )
)

func metricsInterceptor(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
    start := time.Now()
    
    resp, err := handler(ctx, req)
    
    status := "success"
    if err != nil {
        status = "error"
    }
    
    requestsTotal.WithLabelValues(info.FullMethod, status).Inc()
    requestDuration.WithLabelValues(info.FullMethod).Observe(time.Since(start).Seconds())
    
    return resp, err
}
```

### Distributed Tracing
```go
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/trace"
)

func tracingInterceptor(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
    tracer := otel.Tracer("user-service")
    ctx, span := tracer.Start(ctx, info.FullMethod)
    defer span.End()

    span.SetAttributes(
        attribute.String("rpc.system", "grpc"),
        attribute.String("rpc.method", info.FullMethod),
    )

    resp, err := handler(ctx, req)

    if err != nil {
        span.RecordError(err)
        span.SetStatus(codes.Error, err.Error())
    }

    return resp, err
}
```

## Common Pitfalls

1. **Large message sizes**: Use streaming for large payloads
2. **No proper error handling**: Implement structured error responses
3. **Missing validation**: Always validate inputs with proto validation
4. **No connection management**: Implement proper connection pooling
5. **Blocking operations**: Use timeouts and context cancellation
6. **No authentication/authorization**: Secure your services properly
7. **Poor schema versioning**: Plan for backward compatibility
8. **Missing monitoring**: Implement metrics and tracing
9. **No rate limiting**: Protect services from abuse
10. **Inefficient streaming**: Use proper buffering and batching strategies