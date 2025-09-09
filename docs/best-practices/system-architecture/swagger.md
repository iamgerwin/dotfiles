# Swagger/OpenAPI Best Practices

## Official Documentation
- **OpenAPI Specification**: https://swagger.io/specification
- **Swagger Tools**: https://swagger.io/tools
- **OpenAPI Generator**: https://openapi-generator.tech
- **Swagger Editor**: https://editor.swagger.io

## OpenAPI Specification Structure

### Basic OpenAPI 3.0 Document
```yaml
openapi: 3.0.3
info:
  title: User Management API
  description: |
    A comprehensive API for managing users, authentication, and user profiles.
    
    ## Authentication
    This API uses Bearer token authentication. Include your token in the Authorization header:
    `Authorization: Bearer your-token-here`
    
    ## Rate Limiting
    API calls are limited to 1000 requests per hour per API key.
    
  version: 1.2.0
  termsOfService: https://example.com/terms
  contact:
    name: API Support
    url: https://example.com/support
    email: api-support@example.com
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT
    
servers:
  - url: https://api.example.com/v1
    description: Production server
  - url: https://staging-api.example.com/v1
    description: Staging server
  - url: http://localhost:3000/v1
    description: Development server

# Global security requirement
security:
  - bearerAuth: []

paths:
  /users:
    get:
      summary: List users
      description: Retrieve a paginated list of users with optional filtering
      operationId: listUsers
      tags:
        - Users
      parameters:
        - $ref: '#/components/parameters/PageParam'
        - $ref: '#/components/parameters/LimitParam'
        - name: search
          in: query
          description: Search term for filtering users by name or email
          required: false
          schema:
            type: string
            maxLength: 100
            example: "john"
        - name: role
          in: query
          description: Filter users by role
          required: false
          schema:
            $ref: '#/components/schemas/UserRole'
        - name: status
          in: query
          description: Filter users by status
          required: false
          schema:
            type: string
            enum: [active, inactive, suspended]
            example: active
      responses:
        '200':
          description: Users retrieved successfully
          content:
            application/json:
              schema:
                type: object
                required:
                  - data
                  - pagination
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
                  pagination:
                    $ref: '#/components/schemas/PaginationInfo'
              examples:
                successful_response:
                  summary: Successful user list
                  value:
                    data:
                      - id: "123e4567-e89b-12d3-a456-426614174000"
                        email: "john.doe@example.com"
                        firstName: "John"
                        lastName: "Doe"
                        role: "user"
                        status: "active"
                        createdAt: "2023-01-15T10:30:00Z"
                        updatedAt: "2023-02-01T14:22:00Z"
                    pagination:
                      page: 1
                      limit: 20
                      total: 150
                      totalPages: 8
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '500':
          $ref: '#/components/responses/InternalServerError'
          
    post:
      summary: Create user
      description: Create a new user account
      operationId: createUser
      tags:
        - Users
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
            examples:
              create_user_example:
                summary: Create user example
                value:
                  email: "jane.smith@example.com"
                  firstName: "Jane"
                  lastName: "Smith"
                  password: "SecurePassword123!"
                  role: "user"
      responses:
        '201':
          description: User created successfully
          content:
            application/json:
              schema:
                type: object
                required:
                  - data
                properties:
                  data:
                    $ref: '#/components/schemas/User'
        '400':
          $ref: '#/components/responses/BadRequest'
        '409':
          description: User already exists
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
              example:
                error: "Conflict"
                message: "User with this email already exists"
                code: "USER_EXISTS"

  /users/{userId}:
    parameters:
      - $ref: '#/components/parameters/UserIdParam'
      
    get:
      summary: Get user by ID
      description: Retrieve detailed information about a specific user
      operationId: getUserById
      tags:
        - Users
      responses:
        '200':
          description: User retrieved successfully
          content:
            application/json:
              schema:
                type: object
                required:
                  - data
                properties:
                  data:
                    $ref: '#/components/schemas/UserDetails'
        '404':
          $ref: '#/components/responses/NotFound'
          
    put:
      summary: Update user
      description: Update user information (requires admin role or self-update)
      operationId: updateUser
      tags:
        - Users
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UpdateUserRequest'
      responses:
        '200':
          description: User updated successfully
          content:
            application/json:
              schema:
                type: object
                required:
                  - data
                properties:
                  data:
                    $ref: '#/components/schemas/User'
        '404':
          $ref: '#/components/responses/NotFound'
          
    delete:
      summary: Delete user
      description: Delete a user account (admin only)
      operationId: deleteUser
      tags:
        - Users
      security:
        - bearerAuth: []
      responses:
        '204':
          description: User deleted successfully
        '404':
          $ref: '#/components/responses/NotFound'

  /auth/login:
    post:
      summary: User login
      description: Authenticate user and return access token
      operationId: loginUser
      tags:
        - Authentication
      security: []  # No authentication required for login
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - email
                - password
              properties:
                email:
                  type: string
                  format: email
                  example: "user@example.com"
                password:
                  type: string
                  format: password
                  minLength: 8
                  example: "password123"
      responses:
        '200':
          description: Login successful
          content:
            application/json:
              schema:
                type: object
                required:
                  - accessToken
                  - refreshToken
                  - user
                properties:
                  accessToken:
                    type: string
                    description: JWT access token (expires in 15 minutes)
                    example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
                  refreshToken:
                    type: string
                    description: Refresh token for obtaining new access tokens
                    example: "refresh_token_here"
                  user:
                    $ref: '#/components/schemas/User'
        '401':
          description: Invalid credentials
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
              example:
                error: "Unauthorized"
                message: "Invalid email or password"
                code: "INVALID_CREDENTIALS"

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: JWT token for authentication

  parameters:
    PageParam:
      name: page
      in: query
      description: Page number for pagination (1-based)
      required: false
      schema:
        type: integer
        minimum: 1
        default: 1
        example: 1
        
    LimitParam:
      name: limit
      in: query
      description: Number of items per page
      required: false
      schema:
        type: integer
        minimum: 1
        maximum: 100
        default: 20
        example: 20
        
    UserIdParam:
      name: userId
      in: path
      description: Unique identifier for the user
      required: true
      schema:
        type: string
        format: uuid
        example: "123e4567-e89b-12d3-a456-426614174000"

  schemas:
    User:
      type: object
      required:
        - id
        - email
        - firstName
        - lastName
        - role
        - status
        - createdAt
        - updatedAt
      properties:
        id:
          type: string
          format: uuid
          description: Unique identifier for the user
          example: "123e4567-e89b-12d3-a456-426614174000"
          readOnly: true
        email:
          type: string
          format: email
          description: User's email address
          example: "john.doe@example.com"
        firstName:
          type: string
          minLength: 1
          maxLength: 50
          description: User's first name
          example: "John"
        lastName:
          type: string
          minLength: 1
          maxLength: 50
          description: User's last name
          example: "Doe"
        role:
          $ref: '#/components/schemas/UserRole'
        status:
          type: string
          enum: [active, inactive, suspended]
          description: User account status
          example: "active"
        createdAt:
          type: string
          format: date-time
          description: User account creation timestamp
          example: "2023-01-15T10:30:00Z"
          readOnly: true
        updatedAt:
          type: string
          format: date-time
          description: User account last update timestamp
          example: "2023-02-01T14:22:00Z"
          readOnly: true

    UserDetails:
      allOf:
        - $ref: '#/components/schemas/User'
        - type: object
          properties:
            profile:
              $ref: '#/components/schemas/UserProfile'
            lastLoginAt:
              type: string
              format: date-time
              nullable: true
              description: Last login timestamp
              example: "2023-02-15T09:30:00Z"
              readOnly: true

    UserProfile:
      type: object
      properties:
        bio:
          type: string
          maxLength: 500
          description: User's biography
          example: "Software developer passionate about web technologies"
        avatar:
          type: string
          format: uri
          description: URL to user's avatar image
          example: "https://example.com/avatars/user123.jpg"
        phone:
          type: string
          pattern: '^\+?[1-9]\d{1,14}$'
          description: User's phone number in E.164 format
          example: "+1234567890"
        dateOfBirth:
          type: string
          format: date
          description: User's date of birth
          example: "1990-05-15"

    UserRole:
      type: string
      enum: [user, admin, moderator]
      description: User role determining permissions
      example: "user"

    CreateUserRequest:
      type: object
      required:
        - email
        - firstName
        - lastName
        - password
      properties:
        email:
          type: string
          format: email
          description: User's email address
          example: "jane.smith@example.com"
        firstName:
          type: string
          minLength: 1
          maxLength: 50
          description: User's first name
          example: "Jane"
        lastName:
          type: string
          minLength: 1
          maxLength: 50
          description: User's last name
          example: "Smith"
        password:
          type: string
          format: password
          minLength: 8
          pattern: '^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).*$'
          description: |
            User's password. Must contain:
            - At least 8 characters
            - At least one lowercase letter
            - At least one uppercase letter
            - At least one number
          example: "SecurePassword123!"
        role:
          $ref: '#/components/schemas/UserRole'
          default: "user"

    UpdateUserRequest:
      type: object
      properties:
        firstName:
          type: string
          minLength: 1
          maxLength: 50
          description: User's first name
          example: "Jane"
        lastName:
          type: string
          minLength: 1
          maxLength: 50
          description: User's last name
          example: "Smith"
        email:
          type: string
          format: email
          description: User's email address
          example: "jane.smith@example.com"
        role:
          $ref: '#/components/schemas/UserRole'
        profile:
          $ref: '#/components/schemas/UserProfile'

    PaginationInfo:
      type: object
      required:
        - page
        - limit
        - total
        - totalPages
      properties:
        page:
          type: integer
          minimum: 1
          description: Current page number
          example: 1
        limit:
          type: integer
          minimum: 1
          description: Number of items per page
          example: 20
        total:
          type: integer
          minimum: 0
          description: Total number of items
          example: 150
        totalPages:
          type: integer
          minimum: 0
          description: Total number of pages
          example: 8
        hasNext:
          type: boolean
          description: Whether there are more pages available
          example: true
        hasPrevious:
          type: boolean
          description: Whether there are previous pages available
          example: false

    ErrorResponse:
      type: object
      required:
        - error
        - message
      properties:
        error:
          type: string
          description: Error type/category
          example: "Bad Request"
        message:
          type: string
          description: Human-readable error message
          example: "Validation failed"
        code:
          type: string
          description: Machine-readable error code
          example: "VALIDATION_ERROR"
        details:
          type: array
          description: Additional error details (for validation errors)
          items:
            type: object
            properties:
              field:
                type: string
                description: Field that caused the error
                example: "email"
              message:
                type: string
                description: Field-specific error message
                example: "Invalid email format"
              value:
                description: The invalid value that was provided
                example: "invalid-email"
        requestId:
          type: string
          format: uuid
          description: Unique request identifier for debugging
          example: "req_123e4567-e89b-12d3-a456-426614174000"

  responses:
    BadRequest:
      description: Bad request - invalid input parameters
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error: "Bad Request"
            message: "Validation failed"
            code: "VALIDATION_ERROR"
            details:
              - field: "email"
                message: "Invalid email format"
                value: "invalid-email"

    Unauthorized:
      description: Authentication is required
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error: "Unauthorized"
            message: "Authentication required"
            code: "MISSING_TOKEN"

    Forbidden:
      description: Access forbidden - insufficient permissions
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error: "Forbidden"
            message: "Insufficient permissions"
            code: "ACCESS_DENIED"

    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error: "Not Found"
            message: "User not found"
            code: "USER_NOT_FOUND"

    InternalServerError:
      description: Internal server error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error: "Internal Server Error"
            message: "An unexpected error occurred"
            code: "INTERNAL_ERROR"

tags:
  - name: Authentication
    description: User authentication operations
  - name: Users
    description: User management operations
  - name: Admin
    description: Administrative operations
```

## Advanced Schema Patterns

### Polymorphism with oneOf/anyOf
```yaml
components:
  schemas:
    Pet:
      type: object
      required:
        - name
        - petType
      properties:
        name:
          type: string
        petType:
          type: string
      discriminator:
        propertyName: petType
        mapping:
          dog: '#/components/schemas/Dog'
          cat: '#/components/schemas/Cat'

    Dog:
      allOf:
        - $ref: '#/components/schemas/Pet'
        - type: object
          properties:
            breed:
              type: string
            bark:
              type: boolean

    Cat:
      allOf:
        - $ref: '#/components/schemas/Pet'
        - type: object
          properties:
            huntingSkill:
              type: string
              enum: [clueless, poor, lazy, adventurous, aggressive]

    # Using oneOf for different response formats
    SearchResult:
      oneOf:
        - $ref: '#/components/schemas/User'
        - $ref: '#/components/schemas/Product'
        - $ref: '#/components/schemas/Article'
      discriminator:
        propertyName: type
```

### Complex Data Validation
```yaml
components:
  schemas:
    Address:
      type: object
      required:
        - street
        - city
        - country
      properties:
        street:
          type: string
          minLength: 1
          maxLength: 200
          example: "123 Main St"
        street2:
          type: string
          maxLength: 200
          example: "Apt 4B"
        city:
          type: string
          minLength: 1
          maxLength: 100
          example: "New York"
        state:
          type: string
          minLength: 2
          maxLength: 50
          example: "NY"
        postalCode:
          type: string
          pattern: '^[0-9]{5}(-[0-9]{4})?$'
          example: "10001"
        country:
          type: string
          minLength: 2
          maxLength: 2
          pattern: '^[A-Z]{2}$'
          example: "US"

    PaymentMethod:
      type: object
      required:
        - type
      properties:
        type:
          type: string
          enum: [credit_card, bank_account, paypal, stripe]
      discriminator:
        propertyName: type
        mapping:
          credit_card: '#/components/schemas/CreditCard'
          bank_account: '#/components/schemas/BankAccount'

    CreditCard:
      allOf:
        - $ref: '#/components/schemas/PaymentMethod'
        - type: object
          required:
            - cardNumber
            - expiryMonth
            - expiryYear
            - cvv
          properties:
            cardNumber:
              type: string
              pattern: '^[0-9]{13,19}$'
              example: "4532015112830366"
            expiryMonth:
              type: integer
              minimum: 1
              maximum: 12
              example: 12
            expiryYear:
              type: integer
              minimum: 2023
              maximum: 2035
              example: 2025
            cvv:
              type: string
              pattern: '^[0-9]{3,4}$'
              example: "123"
            holderName:
              type: string
              minLength: 1
              maxLength: 100
              example: "John Doe"

    # Conditional schemas using if/then/else
    UserRegistration:
      type: object
      required:
        - email
        - accountType
      properties:
        email:
          type: string
          format: email
        accountType:
          type: string
          enum: [personal, business]
        companyName:
          type: string
      if:
        properties:
          accountType:
            const: business
      then:
        required:
          - companyName
      else:
        properties:
          companyName:
            not: {}
```

### File Upload Specifications
```yaml
paths:
  /users/{userId}/avatar:
    post:
      summary: Upload user avatar
      operationId: uploadAvatar
      parameters:
        - name: userId
          in: path
          required: true
          schema:
            type: string
            format: uuid
      requestBody:
        required: true
        content:
          multipart/form-data:
            schema:
              type: object
              required:
                - file
              properties:
                file:
                  type: string
                  format: binary
                  description: Avatar image file (JPEG, PNG, WebP)
                description:
                  type: string
                  maxLength: 200
                  description: Optional description of the avatar
            encoding:
              file:
                contentType: image/jpeg, image/png, image/webp
                headers:
                  X-File-Size:
                    schema:
                      type: integer
                      maximum: 5242880  # 5MB
      responses:
        '200':
          description: Avatar uploaded successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  avatarUrl:
                    type: string
                    format: uri
                    example: "https://cdn.example.com/avatars/user123.jpg"
        '413':
          description: File too large
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'

  /exports/users:
    get:
      summary: Export users data
      operationId: exportUsers
      parameters:
        - name: format
          in: query
          required: true
          schema:
            type: string
            enum: [csv, xlsx, json]
        - name: fields
          in: query
          description: Comma-separated list of fields to include
          schema:
            type: string
            example: "id,email,firstName,lastName"
      responses:
        '200':
          description: Export file
          content:
            application/csv:
              schema:
                type: string
                format: binary
            application/vnd.openxmlformats-officedocument.spreadsheetml.sheet:
              schema:
                type: string
                format: binary
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/User'
          headers:
            Content-Disposition:
              schema:
                type: string
                example: 'attachment; filename="users.csv"'
```

## Security Documentation

### Authentication Schemes
```yaml
components:
  securitySchemes:
    # JWT Bearer Token
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: |
        JWT token for authentication. Include in Authorization header as:
        `Authorization: Bearer <token>`

    # API Key in Header
    apiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
      description: API key for service-to-service authentication

    # OAuth 2.0
    oauth2:
      type: oauth2
      flows:
        authorizationCode:
          authorizationUrl: https://auth.example.com/oauth/authorize
          tokenUrl: https://auth.example.com/oauth/token
          scopes:
            read: Read access to resources
            write: Write access to resources
            admin: Administrative access
        clientCredentials:
          tokenUrl: https://auth.example.com/oauth/token
          scopes:
            api: API access

    # Basic Authentication (for admin endpoints)
    basicAuth:
      type: http
      scheme: basic
      description: Basic HTTP authentication for administrative access

# Apply different security schemes to different operations
paths:
  /public/health:
    get:
      security: []  # No authentication required
      
  /users:
    get:
      security:
        - bearerAuth: []
        - apiKeyAuth: []  # Alternative authentication method
        
  /admin/users:
    post:
      security:
        - oauth2: [admin]  # Requires admin scope
        - bearerAuth: []   # Alternative: JWT with admin role check
```

### Rate Limiting Documentation
```yaml
paths:
  /api/search:
    get:
      summary: Search resources
      description: |
        Search across resources with rate limiting applied.
        
        **Rate Limits:**
        - Authenticated users: 1000 requests per hour
        - Anonymous users: 100 requests per hour
        
        Rate limit headers are included in responses:
        - `X-RateLimit-Limit`: Maximum requests allowed
        - `X-RateLimit-Remaining`: Remaining requests in current window
        - `X-RateLimit-Reset`: Unix timestamp when limit resets
      responses:
        '200':
          description: Search results
          headers:
            X-RateLimit-Limit:
              schema:
                type: integer
                example: 1000
              description: Maximum requests per hour
            X-RateLimit-Remaining:
              schema:
                type: integer
                example: 999
              description: Remaining requests in current hour
            X-RateLimit-Reset:
              schema:
                type: integer
                example: 1609459200
              description: Unix timestamp when rate limit resets
        '429':
          description: Rate limit exceeded
          headers:
            Retry-After:
              schema:
                type: integer
                example: 3600
              description: Seconds to wait before retrying
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
              example:
                error: "Too Many Requests"
                message: "Rate limit exceeded. Try again in 1 hour."
                code: "RATE_LIMIT_EXCEEDED"
```

## Code Generation Best Practices

### Swagger Codegen Configuration
```yaml
# swagger-codegen-config.yaml
modelPackage: com.example.api.model
apiPackage: com.example.api.client
invokerPackage: com.example.api
groupId: com.example
artifactId: api-client
artifactVersion: 1.0.0
artifactDescription: Example API Client
scmConnection: scm:git:git@github.com:example/api-client.git
scmDeveloperConnection: scm:git:git@github.com:example/api-client.git
scmUrl: https://github.com/example/api-client

# Additional properties
library: okhttp-gson
dateLibrary: java8
serializationLibrary: gson
useBeanValidation: true
performBeanValidation: true
hideGenerationTimestamp: true
```

```bash
# Generate Java client
swagger-codegen generate \
  -i openapi.yaml \
  -l java \
  -o ./generated-client \
  -c swagger-codegen-config.yaml

# Generate TypeScript client
swagger-codegen generate \
  -i openapi.yaml \
  -l typescript-axios \
  -o ./generated-client-ts \
  --additional-properties=npmName=api-client,npmVersion=1.0.0

# Generate server stubs
swagger-codegen generate \
  -i openapi.yaml \
  -l spring \
  -o ./generated-server \
  --additional-properties=basePackage=com.example.api
```

### OpenAPI Generator Configuration
```yaml
# openapitools.json
{
  "generator-cli": {
    "version": "6.6.0"
  }
}
```

```yaml
# config.yaml for TypeScript client
npmName: "@example/api-client"
npmVersion: "1.0.0"
npmRepository: "https://npm.example.com"
supportsES6: true
modelPropertyNaming: "camelCase"
enumPropertyNaming: "UPPERCASE"
withInterfaces: true
typescriptThreePlus: true
useSingleRequestParameter: false
```

```bash
# Generate with OpenAPI Generator
npx @openapitools/openapi-generator-cli generate \
  -i openapi.yaml \
  -g typescript-axios \
  -o ./generated \
  -c config.yaml

# Generate multiple clients at once
npx @openapitools/openapi-generator-cli batch \
  --includes "*.yaml" \
  --parallel
```

## Documentation Generation

### Redoc Configuration
```yaml
# redoc-config.yaml
theme:
  colors:
    primary:
      main: '#1976d2'
    success:
      main: '#4caf50'
  typography:
    fontSize: '14px'
    fontFamily: 'Roboto, sans-serif'
  sidebar:
    backgroundColor: '#fafafa'
    textColor: '#333333'
  
scrollYOffset: 60
hideDownloadButton: false
disableSearch: false
expandResponses: '200,201'
expandSingleSchemaField: true
hideSchemaPattern: true
hideRequestPayloadSample: false
pathInMiddlePanel: true
requiredPropsFirst: true
sortPropsAlphabetically: true
showExtensions: true
nativeScrollbars: false
```

```html
<!-- redoc.html -->
<!DOCTYPE html>
<html>
  <head>
    <title>API Documentation</title>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link href="https://fonts.googleapis.com/css?family=Montserrat:300,400,700|Roboto:300,400,700" rel="stylesheet">
    <style>
      body { margin: 0; padding: 0; }
      redoc { display: block; }
    </style>
  </head>
  <body>
    <redoc spec-url="./openapi.yaml" lazy-rendering></redoc>
    <script src="https://cdn.jsdelivr.net/npm/redoc@2.0.0/bundles/redoc.standalone.js"></script>
  </body>
</html>
```

### Swagger UI Configuration
```yaml
# swagger-ui-config.yaml
url: "./openapi.yaml"
dom_id: "#swagger-ui"
layout: "StandaloneLayout"
deepLinking: true
showExtensions: true
showCommonExtensions: true
filter: true
defaultModelExpandDepth: 3
defaultModelsExpandDepth: 1
displayOperationId: false
displayRequestDuration: true
docExpansion: "list"
maxDisplayedTags: 50
operationsSorter: "alpha"
showMutatedRequest: true
supportedSubmitMethods: ["get", "post", "put", "delete", "patch"]
tagsSorter: "alpha"
validatorUrl: null
withCredentials: false
persistAuthorization: true
```

## Testing and Validation

### API Testing with Newman
```json
{
  "info": {
    "name": "User API Tests",
    "description": "Postman collection for testing User Management API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "variable": [
    {
      "key": "base_url",
      "value": "https://api.example.com/v1",
      "type": "string"
    },
    {
      "key": "access_token",
      "value": "",
      "type": "string"
    }
  ],
  "item": [
    {
      "name": "Authentication",
      "item": [
        {
          "name": "Login",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"email\": \"{{test_email}}\",\n  \"password\": \"{{test_password}}\"\n}"
            },
            "url": "{{base_url}}/auth/login"
          },
          "event": [
            {
              "listen": "test",
              "script": {
                "exec": [
                  "pm.test('Login successful', function () {",
                  "    pm.response.to.have.status(200);",
                  "    const response = pm.response.json();",
                  "    pm.expect(response).to.have.property('accessToken');",
                  "    pm.globals.set('access_token', response.accessToken);",
                  "});",
                  "",
                  "pm.test('Response time is less than 2000ms', function () {",
                  "    pm.expect(pm.response.responseTime).to.be.below(2000);",
                  "});"
                ]
              }
            }
          ]
        }
      ]
    }
  ]
}
```

### Contract Testing with Pact
```javascript
// user-api.pact.js
const { Pact } = require('@pact-foundation/pact');
const { like, eachLike, term } = require('@pact-foundation/pact').Matchers;

const provider = new Pact({
  consumer: 'UserAPIConsumer',
  provider: 'UserAPIProvider',
  port: 1234,
  log: path.resolve(process.cwd(), 'logs', 'pact.log'),
  dir: path.resolve(process.cwd(), 'pacts'),
  logLevel: 'INFO'
});

describe('User API Contract', () => {
  beforeAll(() => provider.setup());
  afterEach(() => provider.verify());
  afterAll(() => provider.finalize());

  describe('GET /users', () => {
    beforeEach(() => {
      return provider
        .given('users exist')
        .uponReceiving('a request for all users')
        .withRequest({
          method: 'GET',
          path: '/users',
          headers: {
            'Authorization': term({
              matcher: 'Bearer .*',
              generate: 'Bearer token123'
            }),
            'Accept': 'application/json'
          }
        })
        .willRespondWith({
          status: 200,
          headers: {
            'Content-Type': 'application/json'
          },
          body: {
            data: eachLike({
              id: like('123e4567-e89b-12d3-a456-426614174000'),
              email: like('user@example.com'),
              firstName: like('John'),
              lastName: like('Doe'),
              role: term({
                matcher: '^(user|admin|moderator)$',
                generate: 'user'
              })
            }),
            pagination: like({
              page: 1,
              limit: 20,
              total: 50,
              totalPages: 3
            })
          }
        });
    });

    it('should return users list', async () => {
      const response = await fetch('http://localhost:1234/users', {
        headers: {
          'Authorization': 'Bearer token123',
          'Accept': 'application/json'
        }
      });
      
      expect(response.status).toBe(200);
      const data = await response.json();
      expect(data.data).toBeDefined();
      expect(data.pagination).toBeDefined();
    });
  });
});
```

### Schema Validation Testing
```javascript
// schema-validation.test.js
const Ajv = require('ajv');
const addFormats = require('ajv-formats');
const fs = require('fs');
const yaml = require('js-yaml');

describe('OpenAPI Schema Validation', () => {
  let ajv;
  let openApiSpec;

  beforeAll(() => {
    ajv = new Ajv({ strict: false });
    addFormats(ajv);
    
    const specFile = fs.readFileSync('./openapi.yaml', 'utf8');
    openApiSpec = yaml.load(specFile);
  });

  describe('User Schema Validation', () => {
    let userSchema;

    beforeAll(() => {
      userSchema = openApiSpec.components.schemas.User;
      ajv.addSchema(userSchema, 'User');
    });

    it('should validate a correct user object', () => {
      const validUser = {
        id: '123e4567-e89b-12d3-a456-426614174000',
        email: 'user@example.com',
        firstName: 'John',
        lastName: 'Doe',
        role: 'user',
        status: 'active',
        createdAt: '2023-01-15T10:30:00Z',
        updatedAt: '2023-02-01T14:22:00Z'
      };

      const validate = ajv.getSchema('User');
      const valid = validate(validUser);
      
      expect(valid).toBe(true);
      expect(validate.errors).toBeNull();
    });

    it('should reject user with invalid email', () => {
      const invalidUser = {
        id: '123e4567-e89b-12d3-a456-426614174000',
        email: 'invalid-email',  // Invalid email format
        firstName: 'John',
        lastName: 'Doe',
        role: 'user',
        status: 'active',
        createdAt: '2023-01-15T10:30:00Z',
        updatedAt: '2023-02-01T14:22:00Z'
      };

      const validate = ajv.getSchema('User');
      const valid = validate(invalidUser);
      
      expect(valid).toBe(false);
      expect(validate.errors).toContainEqual(
        expect.objectContaining({
          instancePath: '/email',
          keyword: 'format'
        })
      );
    });

    it('should reject user with missing required fields', () => {
      const invalidUser = {
        id: '123e4567-e89b-12d3-a456-426614174000',
        email: 'user@example.com'
        // Missing required fields
      };

      const validate = ajv.getSchema('User');
      const valid = validate(invalidUser);
      
      expect(valid).toBe(false);
      expect(validate.errors).toContainEqual(
        expect.objectContaining({
          keyword: 'required'
        })
      );
    });
  });
});
```

## CI/CD Integration

### GitHub Actions Workflow
```yaml
# .github/workflows/api-docs.yml
name: API Documentation

on:
  push:
    paths:
      - 'openapi.yaml'
      - 'docs/**'
  pull_request:
    paths:
      - 'openapi.yaml'
      - 'docs/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Validate OpenAPI Spec
        uses: char0n/swagger-editor-validate@v1
        with:
          definition-file: openapi.yaml
          
      - name: Lint OpenAPI Spec
        run: |
          npx @apidevtools/swagger-parser validate openapi.yaml
          npx spectral lint openapi.yaml

  generate-docs:
    runs-on: ubuntu-latest
    needs: validate
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Generate Documentation
        run: |
          # Generate static documentation
          npx redoc-cli build openapi.yaml --output docs/index.html
          
          # Generate API clients
          npx @openapitools/openapi-generator-cli generate \
            -i openapi.yaml \
            -g typescript-axios \
            -o clients/typescript
            
          npx @openapitools/openapi-generator-cli generate \
            -i openapi.yaml \
            -g python \
            -o clients/python
            
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./docs
          
      - name: Publish TypeScript Client
        run: |
          cd clients/typescript
          npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}

  breaking-changes:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
          
      - name: Check for Breaking Changes
        run: |
          # Compare with main branch
          git checkout main
          cp openapi.yaml openapi-main.yaml
          git checkout ${{ github.head_ref }}
          
          # Use oasdiff to detect breaking changes
          docker run --rm -v $PWD:/specs:ro \
            tufin/oasdiff breaking \
            /specs/openapi-main.yaml \
            /specs/openapi.yaml
```

### Spectral Linting Configuration
```yaml
# .spectral.yml
extends: ["@stoplight/spectral/rulesets/oas"]

rules:
  # Custom rules
  operation-description: error
  operation-operationId: error
  operation-tags: error
  operation-2xx-response: error
  operation-4xx-response: error
  
  # Custom rule: All operations must have examples
  oas3-examples:
    description: "All operations should have examples"
    given: "$.paths[*][*].responses[*].content[*]"
    then:
      field: "examples"
      function: "truthy"
    severity: warn
    
  # Custom rule: Error responses should follow standard format
  error-response-format:
    description: "Error responses should use standard ErrorResponse schema"
    given: "$.paths[*][*].responses[?(@property >= '400')].content.application/json.schema"
    then:
      field: "$ref"
      function: "pattern"
      functionOptions:
        match: "#/components/schemas/ErrorResponse"
    severity: error
    
  # Custom rule: All schemas should have descriptions
  schema-description:
    description: "All schemas should have descriptions"
    given: "$.components.schemas[*]"
    then:
      field: "description"
      function: "truthy"
    severity: warn
```

## Common Pitfalls

1. **Incomplete error documentation**: Document all possible error responses
2. **Missing examples**: Provide realistic examples for all schemas and operations
3. **Inconsistent naming**: Use consistent naming conventions throughout
4. **No versioning strategy**: Plan for API evolution and breaking changes
5. **Over-complex schemas**: Keep schemas simple and focused
6. **Missing security documentation**: Clearly document authentication and authorization
7. **No validation rules**: Use schema validation properties appropriately
8. **Poor descriptions**: Write clear, concise descriptions for all components
9. **Ignoring HTTP semantics**: Use correct HTTP methods and status codes
10. **No testing of spec**: Validate and test the OpenAPI specification itself