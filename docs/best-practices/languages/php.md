# PHP Best Practices

## Overview
PHP is a widely-used server-side scripting language designed for web development. This guide covers modern PHP development practices, performance optimization, security, and architectural patterns.

## Documentation
- [Official PHP Documentation](https://www.php.net/docs.php)
- [PHP The Right Way](https://phptherightway.com)
- [PHP-FIG Standards](https://www.php-fig.org)
- [Modern PHP](https://www.php.net/manual/en/language.oop5.php)

## Modern PHP Features

### PHP 8.x Features

```php
<?php

// Constructor Property Promotion (PHP 8.0)
class User
{
    public function __construct(
        private string $name,
        private string $email,
        private ?int $age = null,
        private readonly string $id = uniqid()
    ) {}
}

// Named Arguments (PHP 8.0)
$user = new User(
    name: 'John Doe',
    email: 'john@example.com',
    age: 30
);

// Match Expression (PHP 8.0)
$status = match($code) {
    200, 201 => 'success',
    400, 404 => 'client error',
    500 => 'server error',
    default => 'unknown'
};

// Nullsafe Operator (PHP 8.0)
$country = $user?->getAddress()?->getCountry()?->getName();

// Union Types (PHP 8.0)
function processValue(int|float|string $value): void
{
    // Process value
}

// Attributes (PHP 8.0)
#[Route('/api/users', methods: ['GET'])]
#[RequiresAuth]
class UserController
{
    #[Inject]
    private UserService $userService;
    
    #[Cache(ttl: 3600)]
    public function index(): array
    {
        return $this->userService->getAllUsers();
    }
}

// Enums (PHP 8.1)
enum Status: string
{
    case PENDING = 'pending';
    case APPROVED = 'approved';
    case REJECTED = 'rejected';
    
    public function getLabel(): string
    {
        return match($this) {
            self::PENDING => 'Pending Review',
            self::APPROVED => 'Approved',
            self::REJECTED => 'Rejected'
        };
    }
}

// Readonly Properties (PHP 8.1)
class Config
{
    public readonly string $appName;
    public readonly array $settings;
    
    public function __construct()
    {
        $this->appName = 'MyApp';
        $this->settings = ['debug' => true];
    }
}

// First-class Callable Syntax (PHP 8.1)
$fn = strlen(...);
$result = array_map($fn, ['hello', 'world']);

// Readonly Classes (PHP 8.2)
readonly class ImmutableData
{
    public function __construct(
        public string $id,
        public string $value,
        public DateTime $createdAt
    ) {}
}

// DNF Types (PHP 8.2)
function process((A&B)|null $value): void
{
    // Process value
}

// Constants in Traits (PHP 8.2)
trait HasVersion
{
    public const VERSION = '1.0.0';
}

// Typed Class Constants (PHP 8.3)
class App
{
    public const string NAME = 'MyApp';
    public const int VERSION = 1;
}
```

## Architecture Patterns

### Repository Pattern

```php
<?php

namespace App\Repository;

interface UserRepositoryInterface
{
    public function find(int $id): ?User;
    public function findAll(): array;
    public function findBy(array $criteria): array;
    public function save(User $user): void;
    public function delete(User $user): void;
}

class UserRepository implements UserRepositoryInterface
{
    private PDO $connection;
    
    public function __construct(PDO $connection)
    {
        $this->connection = $connection;
    }
    
    public function find(int $id): ?User
    {
        $stmt = $this->connection->prepare('
            SELECT * FROM users WHERE id = :id
        ');
        $stmt->execute(['id' => $id]);
        
        $data = $stmt->fetch(PDO::FETCH_ASSOC);
        
        return $data ? $this->hydrate($data) : null;
    }
    
    public function findAll(): array
    {
        $stmt = $this->connection->query('SELECT * FROM users');
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        return array_map([$this, 'hydrate'], $results);
    }
    
    public function findBy(array $criteria): array
    {
        $sql = 'SELECT * FROM users WHERE 1=1';
        $params = [];
        
        foreach ($criteria as $field => $value) {
            $sql .= " AND {$field} = :{$field}";
            $params[$field] = $value;
        }
        
        $stmt = $this->connection->prepare($sql);
        $stmt->execute($params);
        
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        return array_map([$this, 'hydrate'], $results);
    }
    
    public function save(User $user): void
    {
        if ($user->getId()) {
            $this->update($user);
        } else {
            $this->insert($user);
        }
    }
    
    private function insert(User $user): void
    {
        $stmt = $this->connection->prepare('
            INSERT INTO users (name, email, created_at)
            VALUES (:name, :email, :created_at)
        ');
        
        $stmt->execute([
            'name' => $user->getName(),
            'email' => $user->getEmail(),
            'created_at' => $user->getCreatedAt()->format('Y-m-d H:i:s')
        ]);
        
        $user->setId($this->connection->lastInsertId());
    }
    
    private function update(User $user): void
    {
        $stmt = $this->connection->prepare('
            UPDATE users 
            SET name = :name, email = :email, updated_at = :updated_at
            WHERE id = :id
        ');
        
        $stmt->execute([
            'id' => $user->getId(),
            'name' => $user->getName(),
            'email' => $user->getEmail(),
            'updated_at' => (new DateTime())->format('Y-m-d H:i:s')
        ]);
    }
    
    public function delete(User $user): void
    {
        $stmt = $this->connection->prepare('DELETE FROM users WHERE id = :id');
        $stmt->execute(['id' => $user->getId()]);
    }
    
    private function hydrate(array $data): User
    {
        $user = new User();
        $user->setId($data['id']);
        $user->setName($data['name']);
        $user->setEmail($data['email']);
        $user->setCreatedAt(new DateTime($data['created_at']));
        
        if ($data['updated_at']) {
            $user->setUpdatedAt(new DateTime($data['updated_at']));
        }
        
        return $user;
    }
}
```

### Service Layer Pattern

```php
<?php

namespace App\Service;

class UserService
{
    private UserRepositoryInterface $userRepository;
    private EventDispatcherInterface $eventDispatcher;
    private LoggerInterface $logger;
    private CacheInterface $cache;
    
    public function __construct(
        UserRepositoryInterface $userRepository,
        EventDispatcherInterface $eventDispatcher,
        LoggerInterface $logger,
        CacheInterface $cache
    ) {
        $this->userRepository = $userRepository;
        $this->eventDispatcher = $eventDispatcher;
        $this->logger = $logger;
        $this->cache = $cache;
    }
    
    public function createUser(array $data): User
    {
        $this->validateUserData($data);
        
        $user = new User();
        $user->setName($data['name']);
        $user->setEmail($data['email']);
        $user->setPassword($this->hashPassword($data['password']));
        $user->setCreatedAt(new DateTime());
        
        try {
            $this->userRepository->save($user);
            
            $this->eventDispatcher->dispatch(
                new UserCreatedEvent($user)
            );
            
            $this->logger->info('User created', [
                'user_id' => $user->getId(),
                'email' => $user->getEmail()
            ]);
            
            return $user;
        } catch (\Exception $e) {
            $this->logger->error('Failed to create user', [
                'error' => $e->getMessage(),
                'data' => $data
            ]);
            
            throw new UserCreationException(
                'Failed to create user: ' . $e->getMessage(),
                0,
                $e
            );
        }
    }
    
    public function getUser(int $id): ?User
    {
        $cacheKey = "user_{$id}";
        
        if ($this->cache->has($cacheKey)) {
            return $this->cache->get($cacheKey);
        }
        
        $user = $this->userRepository->find($id);
        
        if ($user) {
            $this->cache->set($cacheKey, $user, 3600);
        }
        
        return $user;
    }
    
    public function updateUser(int $id, array $data): User
    {
        $user = $this->userRepository->find($id);
        
        if (!$user) {
            throw new UserNotFoundException("User {$id} not found");
        }
        
        if (isset($data['name'])) {
            $user->setName($data['name']);
        }
        
        if (isset($data['email'])) {
            $this->validateEmail($data['email']);
            $user->setEmail($data['email']);
        }
        
        $user->setUpdatedAt(new DateTime());
        
        $this->userRepository->save($user);
        
        $this->cache->delete("user_{$id}");
        
        $this->eventDispatcher->dispatch(
            new UserUpdatedEvent($user, $data)
        );
        
        return $user;
    }
    
    private function validateUserData(array $data): void
    {
        $errors = [];
        
        if (empty($data['name'])) {
            $errors['name'] = 'Name is required';
        }
        
        if (empty($data['email'])) {
            $errors['email'] = 'Email is required';
        } elseif (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
            $errors['email'] = 'Invalid email format';
        } elseif ($this->emailExists($data['email'])) {
            $errors['email'] = 'Email already exists';
        }
        
        if (empty($data['password'])) {
            $errors['password'] = 'Password is required';
        } elseif (strlen($data['password']) < 8) {
            $errors['password'] = 'Password must be at least 8 characters';
        }
        
        if (!empty($errors)) {
            throw new ValidationException($errors);
        }
    }
    
    private function emailExists(string $email): bool
    {
        $users = $this->userRepository->findBy(['email' => $email]);
        return !empty($users);
    }
    
    private function hashPassword(string $password): string
    {
        return password_hash($password, PASSWORD_ARGON2ID);
    }
}
```

### Value Objects

```php
<?php

namespace App\ValueObject;

final class Email
{
    private string $value;
    
    public function __construct(string $email)
    {
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException("Invalid email: {$email}");
        }
        
        $this->value = strtolower($email);
    }
    
    public function getValue(): string
    {
        return $this->value;
    }
    
    public function getDomain(): string
    {
        return substr($this->value, strpos($this->value, '@') + 1);
    }
    
    public function equals(Email $other): bool
    {
        return $this->value === $other->value;
    }
    
    public function __toString(): string
    {
        return $this->value;
    }
}

final class Money
{
    private int $amount;
    private string $currency;
    
    public function __construct(int $amount, string $currency = 'USD')
    {
        if ($amount < 0) {
            throw new InvalidArgumentException('Amount cannot be negative');
        }
        
        if (!in_array($currency, ['USD', 'EUR', 'GBP'])) {
            throw new InvalidArgumentException("Unsupported currency: {$currency}");
        }
        
        $this->amount = $amount;
        $this->currency = $currency;
    }
    
    public function getAmount(): int
    {
        return $this->amount;
    }
    
    public function getCurrency(): string
    {
        return $this->currency;
    }
    
    public function add(Money $other): self
    {
        if ($this->currency !== $other->currency) {
            throw new InvalidArgumentException('Cannot add different currencies');
        }
        
        return new self($this->amount + $other->amount, $this->currency);
    }
    
    public function subtract(Money $other): self
    {
        if ($this->currency !== $other->currency) {
            throw new InvalidArgumentException('Cannot subtract different currencies');
        }
        
        if ($this->amount < $other->amount) {
            throw new InvalidArgumentException('Insufficient funds');
        }
        
        return new self($this->amount - $other->amount, $this->currency);
    }
    
    public function multiply(int $multiplier): self
    {
        return new self($this->amount * $multiplier, $this->currency);
    }
    
    public function format(): string
    {
        $symbol = match($this->currency) {
            'USD' => '$',
            'EUR' => '€',
            'GBP' => '£'
        };
        
        return $symbol . number_format($this->amount / 100, 2);
    }
}
```

## Database Best Practices

### PDO Usage

```php
<?php

class Database
{
    private PDO $pdo;
    private array $config;
    
    public function __construct(array $config)
    {
        $this->config = $config;
        $this->connect();
    }
    
    private function connect(): void
    {
        $dsn = sprintf(
            '%s:host=%s;port=%s;dbname=%s;charset=%s',
            $this->config['driver'] ?? 'mysql',
            $this->config['host'] ?? 'localhost',
            $this->config['port'] ?? 3306,
            $this->config['database'],
            $this->config['charset'] ?? 'utf8mb4'
        );
        
        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
            PDO::ATTR_PERSISTENT => $this->config['persistent'] ?? false
        ];
        
        try {
            $this->pdo = new PDO(
                $dsn,
                $this->config['username'],
                $this->config['password'],
                $options
            );
        } catch (PDOException $e) {
            throw new DatabaseException(
                'Connection failed: ' . $e->getMessage()
            );
        }
    }
    
    public function query(string $sql, array $params = []): PDOStatement
    {
        try {
            $stmt = $this->pdo->prepare($sql);
            $stmt->execute($params);
            return $stmt;
        } catch (PDOException $e) {
            throw new QueryException(
                "Query failed: {$e->getMessage()}\nSQL: {$sql}"
            );
        }
    }
    
    public function transaction(callable $callback): mixed
    {
        $this->pdo->beginTransaction();
        
        try {
            $result = $callback($this);
            $this->pdo->commit();
            return $result;
        } catch (\Exception $e) {
            $this->pdo->rollBack();
            throw $e;
        }
    }
    
    public function lastInsertId(): string
    {
        return $this->pdo->lastInsertId();
    }
}

// Usage
$db = new Database([
    'driver' => 'mysql',
    'host' => 'localhost',
    'database' => 'myapp',
    'username' => 'user',
    'password' => 'password'
]);

// Simple query
$users = $db->query('SELECT * FROM users WHERE active = :active', [
    'active' => true
])->fetchAll();

// Transaction
$db->transaction(function($db) use ($userData) {
    $db->query(
        'INSERT INTO users (name, email) VALUES (:name, :email)',
        ['name' => $userData['name'], 'email' => $userData['email']]
    );
    
    $userId = $db->lastInsertId();
    
    $db->query(
        'INSERT INTO profiles (user_id, bio) VALUES (:user_id, :bio)',
        ['user_id' => $userId, 'bio' => $userData['bio']]
    );
    
    return $userId;
});
```

### Query Builder

```php
<?php

class QueryBuilder
{
    private Database $db;
    private string $table;
    private array $select = ['*'];
    private array $where = [];
    private array $join = [];
    private array $orderBy = [];
    private ?int $limit = null;
    private ?int $offset = null;
    private array $bindings = [];
    
    public function __construct(Database $db)
    {
        $this->db = $db;
    }
    
    public function table(string $table): self
    {
        $this->table = $table;
        return $this;
    }
    
    public function select(...$columns): self
    {
        $this->select = empty($columns) ? ['*'] : $columns;
        return $this;
    }
    
    public function where(string $column, $operator, $value = null): self
    {
        if ($value === null) {
            $value = $operator;
            $operator = '=';
        }
        
        $placeholder = ':where_' . count($this->bindings);
        $this->where[] = "{$column} {$operator} {$placeholder}";
        $this->bindings[$placeholder] = $value;
        
        return $this;
    }
    
    public function whereIn(string $column, array $values): self
    {
        $placeholders = [];
        foreach ($values as $i => $value) {
            $placeholder = ':wherein_' . count($this->bindings) . '_' . $i;
            $placeholders[] = $placeholder;
            $this->bindings[$placeholder] = $value;
        }
        
        $this->where[] = "{$column} IN (" . implode(', ', $placeholders) . ")";
        
        return $this;
    }
    
    public function join(string $table, string $first, string $operator, string $second): self
    {
        $this->join[] = "JOIN {$table} ON {$first} {$operator} {$second}";
        return $this;
    }
    
    public function leftJoin(string $table, string $first, string $operator, string $second): self
    {
        $this->join[] = "LEFT JOIN {$table} ON {$first} {$operator} {$second}";
        return $this;
    }
    
    public function orderBy(string $column, string $direction = 'ASC'): self
    {
        $this->orderBy[] = "{$column} {$direction}";
        return $this;
    }
    
    public function limit(int $limit): self
    {
        $this->limit = $limit;
        return $this;
    }
    
    public function offset(int $offset): self
    {
        $this->offset = $offset;
        return $this;
    }
    
    public function get(): array
    {
        $sql = $this->buildSelectQuery();
        return $this->db->query($sql, $this->bindings)->fetchAll();
    }
    
    public function first(): ?array
    {
        $this->limit(1);
        $results = $this->get();
        return $results[0] ?? null;
    }
    
    public function count(): int
    {
        $this->select = ['COUNT(*) as count'];
        $result = $this->first();
        return (int) $result['count'];
    }
    
    public function insert(array $data): string
    {
        $columns = array_keys($data);
        $placeholders = array_map(fn($col) => ":{$col}", $columns);
        
        $sql = sprintf(
            "INSERT INTO %s (%s) VALUES (%s)",
            $this->table,
            implode(', ', $columns),
            implode(', ', $placeholders)
        );
        
        $this->db->query($sql, $data);
        return $this->db->lastInsertId();
    }
    
    public function update(array $data): int
    {
        $set = [];
        foreach ($data as $column => $value) {
            $placeholder = ":update_{$column}";
            $set[] = "{$column} = {$placeholder}";
            $this->bindings[$placeholder] = $value;
        }
        
        $sql = sprintf(
            "UPDATE %s SET %s%s",
            $this->table,
            implode(', ', $set),
            $this->buildWhereClause()
        );
        
        $stmt = $this->db->query($sql, $this->bindings);
        return $stmt->rowCount();
    }
    
    public function delete(): int
    {
        $sql = "DELETE FROM {$this->table}" . $this->buildWhereClause();
        $stmt = $this->db->query($sql, $this->bindings);
        return $stmt->rowCount();
    }
    
    private function buildSelectQuery(): string
    {
        $sql = sprintf(
            "SELECT %s FROM %s",
            implode(', ', $this->select),
            $this->table
        );
        
        if (!empty($this->join)) {
            $sql .= ' ' . implode(' ', $this->join);
        }
        
        $sql .= $this->buildWhereClause();
        
        if (!empty($this->orderBy)) {
            $sql .= ' ORDER BY ' . implode(', ', $this->orderBy);
        }
        
        if ($this->limit !== null) {
            $sql .= " LIMIT {$this->limit}";
        }
        
        if ($this->offset !== null) {
            $sql .= " OFFSET {$this->offset}";
        }
        
        return $sql;
    }
    
    private function buildWhereClause(): string
    {
        if (empty($this->where)) {
            return '';
        }
        
        return ' WHERE ' . implode(' AND ', $this->where);
    }
}
```

## Error Handling

### Custom Exception Classes

```php
<?php

namespace App\Exception;

class AppException extends \Exception
{
    protected array $context = [];
    
    public function __construct(
        string $message = "",
        int $code = 0,
        ?\Throwable $previous = null,
        array $context = []
    ) {
        parent::__construct($message, $code, $previous);
        $this->context = $context;
    }
    
    public function getContext(): array
    {
        return $this->context;
    }
}

class ValidationException extends AppException
{
    private array $errors;
    
    public function __construct(array $errors, string $message = "Validation failed")
    {
        $this->errors = $errors;
        parent::__construct($message, 422);
    }
    
    public function getErrors(): array
    {
        return $this->errors;
    }
}

class NotFoundException extends AppException
{
    public function __construct(string $resource = "Resource")
    {
        parent::__construct("{$resource} not found", 404);
    }
}

class UnauthorizedException extends AppException
{
    public function __construct(string $message = "Unauthorized")
    {
        parent::__construct($message, 401);
    }
}

class ForbiddenException extends AppException
{
    public function __construct(string $message = "Forbidden")
    {
        parent::__construct($message, 403);
    }
}
```

### Global Exception Handler

```php
<?php

class ExceptionHandler
{
    private LoggerInterface $logger;
    private bool $debug;
    
    public function __construct(LoggerInterface $logger, bool $debug = false)
    {
        $this->logger = $logger;
        $this->debug = $debug;
    }
    
    public function handle(\Throwable $exception): Response
    {
        $this->logger->error($exception->getMessage(), [
            'exception' => get_class($exception),
            'file' => $exception->getFile(),
            'line' => $exception->getLine(),
            'trace' => $exception->getTraceAsString(),
            'context' => method_exists($exception, 'getContext') 
                ? $exception->getContext() 
                : []
        ]);
        
        if ($exception instanceof ValidationException) {
            return $this->validationErrorResponse($exception);
        }
        
        if ($exception instanceof NotFoundException) {
            return $this->notFoundResponse($exception);
        }
        
        if ($exception instanceof UnauthorizedException) {
            return $this->unauthorizedResponse($exception);
        }
        
        if ($exception instanceof ForbiddenException) {
            return $this->forbiddenResponse($exception);
        }
        
        return $this->serverErrorResponse($exception);
    }
    
    private function validationErrorResponse(ValidationException $exception): Response
    {
        return new JsonResponse([
            'error' => 'Validation failed',
            'errors' => $exception->getErrors()
        ], 422);
    }
    
    private function notFoundResponse(NotFoundException $exception): Response
    {
        return new JsonResponse([
            'error' => $exception->getMessage()
        ], 404);
    }
    
    private function unauthorizedResponse(UnauthorizedException $exception): Response
    {
        return new JsonResponse([
            'error' => $exception->getMessage()
        ], 401);
    }
    
    private function forbiddenResponse(ForbiddenException $exception): Response
    {
        return new JsonResponse([
            'error' => $exception->getMessage()
        ], 403);
    }
    
    private function serverErrorResponse(\Throwable $exception): Response
    {
        $response = [
            'error' => 'Internal server error'
        ];
        
        if ($this->debug) {
            $response['message'] = $exception->getMessage();
            $response['trace'] = $exception->getTrace();
        }
        
        return new JsonResponse($response, 500);
    }
}

// Register handler
set_exception_handler(function($exception) use ($container) {
    $handler = $container->get(ExceptionHandler::class);
    $response = $handler->handle($exception);
    $response->send();
});
```

## Security Best Practices

### Input Validation and Sanitization

```php
<?php

class Validator
{
    private array $errors = [];
    private array $data;
    
    public function validate(array $data, array $rules): bool
    {
        $this->data = $data;
        $this->errors = [];
        
        foreach ($rules as $field => $fieldRules) {
            $value = $data[$field] ?? null;
            
            foreach ($fieldRules as $rule) {
                if (!$this->applyRule($field, $value, $rule)) {
                    break;
                }
            }
        }
        
        return empty($this->errors);
    }
    
    private function applyRule(string $field, $value, $rule): bool
    {
        if (is_string($rule)) {
            $ruleName = $rule;
            $ruleValue = null;
        } else {
            $ruleName = $rule[0];
            $ruleValue = $rule[1] ?? null;
        }
        
        switch ($ruleName) {
            case 'required':
                if (empty($value)) {
                    $this->addError($field, "{$field} is required");
                    return false;
                }
                break;
                
            case 'email':
                if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
                    $this->addError($field, "{$field} must be a valid email");
                    return false;
                }
                break;
                
            case 'min':
                if (strlen($value) < $ruleValue) {
                    $this->addError($field, "{$field} must be at least {$ruleValue} characters");
                    return false;
                }
                break;
                
            case 'max':
                if (strlen($value) > $ruleValue) {
                    $this->addError($field, "{$field} must not exceed {$ruleValue} characters");
                    return false;
                }
                break;
                
            case 'numeric':
                if (!is_numeric($value)) {
                    $this->addError($field, "{$field} must be numeric");
                    return false;
                }
                break;
                
            case 'regex':
                if (!preg_match($ruleValue, $value)) {
                    $this->addError($field, "{$field} format is invalid");
                    return false;
                }
                break;
                
            case 'in':
                if (!in_array($value, $ruleValue)) {
                    $this->addError($field, "{$field} must be one of: " . implode(', ', $ruleValue));
                    return false;
                }
                break;
                
            case 'confirmed':
                $confirmField = "{$field}_confirmation";
                if ($value !== ($this->data[$confirmField] ?? null)) {
                    $this->addError($field, "{$field} confirmation does not match");
                    return false;
                }
                break;
                
            case 'unique':
                [$table, $column] = $ruleValue;
                if ($this->existsInDatabase($table, $column, $value)) {
                    $this->addError($field, "{$field} already exists");
                    return false;
                }
                break;
        }
        
        return true;
    }
    
    private function addError(string $field, string $message): void
    {
        $this->errors[$field][] = $message;
    }
    
    public function getErrors(): array
    {
        return $this->errors;
    }
    
    private function existsInDatabase(string $table, string $column, $value): bool
    {
        // Check database for existing value
        // Implementation depends on your database layer
        return false;
    }
}

// Input sanitization
class Sanitizer
{
    public static function sanitize(array $data, array $filters = []): array
    {
        $sanitized = [];
        
        foreach ($data as $key => $value) {
            $filter = $filters[$key] ?? 'string';
            $sanitized[$key] = self::applyFilter($value, $filter);
        }
        
        return $sanitized;
    }
    
    private static function applyFilter($value, string $filter)
    {
        return match($filter) {
            'string' => filter_var($value, FILTER_SANITIZE_STRING),
            'email' => filter_var($value, FILTER_SANITIZE_EMAIL),
            'int' => filter_var($value, FILTER_SANITIZE_NUMBER_INT),
            'float' => filter_var($value, FILTER_SANITIZE_NUMBER_FLOAT, FILTER_FLAG_ALLOW_FRACTION),
            'url' => filter_var($value, FILTER_SANITIZE_URL),
            'html' => strip_tags($value, '<p><br><strong><em>'),
            'raw' => $value,
            default => htmlspecialchars($value, ENT_QUOTES, 'UTF-8')
        };
    }
}
```

### Authentication

```php
<?php

class AuthService
{
    private UserRepositoryInterface $userRepository;
    private SessionInterface $session;
    private TokenService $tokenService;
    
    public function attempt(string $email, string $password): bool
    {
        $user = $this->userRepository->findByEmail($email);
        
        if (!$user || !password_verify($password, $user->getPassword())) {
            return false;
        }
        
        if (password_needs_rehash($user->getPassword(), PASSWORD_ARGON2ID)) {
            $user->setPassword(password_hash($password, PASSWORD_ARGON2ID));
            $this->userRepository->save($user);
        }
        
        $this->login($user);
        
        return true;
    }
    
    public function login(User $user): void
    {
        $this->session->regenerate();
        $this->session->set('user_id', $user->getId());
        $this->session->set('user_roles', $user->getRoles());
        $this->session->set('login_time', time());
    }
    
    public function logout(): void
    {
        $this->session->destroy();
    }
    
    public function check(): bool
    {
        return $this->session->has('user_id');
    }
    
    public function user(): ?User
    {
        if (!$this->check()) {
            return null;
        }
        
        $userId = $this->session->get('user_id');
        return $this->userRepository->find($userId);
    }
    
    public function generateApiToken(User $user): string
    {
        return $this->tokenService->generate([
            'user_id' => $user->getId(),
            'email' => $user->getEmail(),
            'exp' => time() + 3600
        ]);
    }
    
    public function validateApiToken(string $token): ?User
    {
        $payload = $this->tokenService->validate($token);
        
        if (!$payload || $payload['exp'] < time()) {
            return null;
        }
        
        return $this->userRepository->find($payload['user_id']);
    }
}
```

## Performance Optimization

### Caching

```php
<?php

class CacheManager
{
    private array $drivers = [];
    private string $defaultDriver;
    
    public function __construct(array $config)
    {
        $this->defaultDriver = $config['default'];
        
        foreach ($config['drivers'] as $name => $driverConfig) {
            $this->drivers[$name] = $this->createDriver($driverConfig);
        }
    }
    
    private function createDriver(array $config): CacheInterface
    {
        return match($config['type']) {
            'redis' => new RedisCache($config),
            'memcached' => new MemcachedCache($config),
            'apcu' => new ApcuCache(),
            'file' => new FileCache($config['path']),
            default => new ArrayCache()
        };
    }
    
    public function driver(string $name = null): CacheInterface
    {
        $name = $name ?? $this->defaultDriver;
        
        if (!isset($this->drivers[$name])) {
            throw new InvalidArgumentException("Cache driver [{$name}] not configured");
        }
        
        return $this->drivers[$name];
    }
    
    public function remember(string $key, int $ttl, callable $callback)
    {
        $driver = $this->driver();
        
        if ($driver->has($key)) {
            return $driver->get($key);
        }
        
        $value = $callback();
        $driver->set($key, $value, $ttl);
        
        return $value;
    }
    
    public function tags(array $tags): TaggedCache
    {
        $driver = $this->driver();
        
        if (!$driver instanceof TaggableCache) {
            throw new RuntimeException('This cache driver does not support tagging');
        }
        
        return new TaggedCache($driver, $tags);
    }
}

// Usage
$cache = new CacheManager([
    'default' => 'redis',
    'drivers' => [
        'redis' => [
            'type' => 'redis',
            'host' => 'localhost',
            'port' => 6379
        ]
    ]
]);

$users = $cache->remember('users:all', 3600, function() {
    return $userRepository->findAll();
});
```

### Lazy Loading

```php
<?php

class LazyCollection implements \IteratorAggregate, \Countable
{
    private \Closure $source;
    private ?array $items = null;
    
    public function __construct(\Closure $source)
    {
        $this->source = $source;
    }
    
    public function getIterator(): \Traversable
    {
        foreach ($this->resolve() as $item) {
            yield $item;
        }
    }
    
    public function count(): int
    {
        return count($this->resolve());
    }
    
    public function map(callable $callback): self
    {
        return new self(function() use ($callback) {
            foreach ($this->resolve() as $key => $value) {
                yield $key => $callback($value, $key);
            }
        });
    }
    
    public function filter(callable $callback): self
    {
        return new self(function() use ($callback) {
            foreach ($this->resolve() as $key => $value) {
                if ($callback($value, $key)) {
                    yield $key => $value;
                }
            }
        });
    }
    
    public function take(int $limit): self
    {
        return new self(function() use ($limit) {
            $count = 0;
            foreach ($this->resolve() as $key => $value) {
                if ($count >= $limit) {
                    break;
                }
                yield $key => $value;
                $count++;
            }
        });
    }
    
    public function chunk(int $size): self
    {
        return new self(function() use ($size) {
            $chunk = [];
            $count = 0;
            
            foreach ($this->resolve() as $key => $value) {
                $chunk[$key] = $value;
                $count++;
                
                if ($count >= $size) {
                    yield $chunk;
                    $chunk = [];
                    $count = 0;
                }
            }
            
            if (!empty($chunk)) {
                yield $chunk;
            }
        });
    }
    
    private function resolve(): \Generator
    {
        return ($this->source)();
    }
    
    public function toArray(): array
    {
        if ($this->items === null) {
            $this->items = iterator_to_array($this->resolve());
        }
        
        return $this->items;
    }
}

// Usage
$collection = new LazyCollection(function() {
    $handle = fopen('large-file.csv', 'r');
    
    while (($line = fgetcsv($handle)) !== false) {
        yield $line;
    }
    
    fclose($handle);
});

$results = $collection
    ->filter(fn($row) => $row[2] > 100)
    ->map(fn($row) => [
        'name' => $row[0],
        'value' => $row[2]
    ])
    ->take(10)
    ->toArray();
```

## Testing

### Unit Testing with PHPUnit

```php
<?php

use PHPUnit\Framework\TestCase;

class UserServiceTest extends TestCase
{
    private UserService $userService;
    private UserRepositoryInterface $userRepository;
    private EventDispatcherInterface $eventDispatcher;
    
    protected function setUp(): void
    {
        $this->userRepository = $this->createMock(UserRepositoryInterface::class);
        $this->eventDispatcher = $this->createMock(EventDispatcherInterface::class);
        $logger = $this->createMock(LoggerInterface::class);
        $cache = $this->createMock(CacheInterface::class);
        
        $this->userService = new UserService(
            $this->userRepository,
            $this->eventDispatcher,
            $logger,
            $cache
        );
    }
    
    public function testCreateUserSuccess(): void
    {
        $userData = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123'
        ];
        
        $this->userRepository
            ->expects($this->once())
            ->method('findBy')
            ->with(['email' => $userData['email']])
            ->willReturn([]);
            
        $this->userRepository
            ->expects($this->once())
            ->method('save')
            ->with($this->isInstanceOf(User::class));
            
        $this->eventDispatcher
            ->expects($this->once())
            ->method('dispatch')
            ->with($this->isInstanceOf(UserCreatedEvent::class));
            
        $user = $this->userService->createUser($userData);
        
        $this->assertInstanceOf(User::class, $user);
        $this->assertEquals($userData['name'], $user->getName());
        $this->assertEquals($userData['email'], $user->getEmail());
    }
    
    public function testCreateUserWithExistingEmail(): void
    {
        $this->expectException(ValidationException::class);
        
        $userData = [
            'name' => 'John Doe',
            'email' => 'existing@example.com',
            'password' => 'password123'
        ];
        
        $this->userRepository
            ->expects($this->once())
            ->method('findBy')
            ->with(['email' => $userData['email']])
            ->willReturn([new User()]);
            
        $this->userService->createUser($userData);
    }
    
    /**
     * @dataProvider invalidUserDataProvider
     */
    public function testCreateUserWithInvalidData(array $userData, string $expectedError): void
    {
        $this->expectException(ValidationException::class);
        
        try {
            $this->userService->createUser($userData);
        } catch (ValidationException $e) {
            $this->assertArrayHasKey($expectedError, $e->getErrors());
            throw $e;
        }
    }
    
    public function invalidUserDataProvider(): array
    {
        return [
            'missing name' => [
                ['email' => 'test@example.com', 'password' => 'password'],
                'name'
            ],
            'invalid email' => [
                ['name' => 'John', 'email' => 'invalid', 'password' => 'password'],
                'email'
            ],
            'short password' => [
                ['name' => 'John', 'email' => 'test@example.com', 'password' => '123'],
                'password'
            ]
        ];
    }
}
```

## Common Pitfalls and Solutions

1. **SQL Injection**: Always use prepared statements with PDO
2. **XSS Attacks**: Escape output with `htmlspecialchars()`
3. **CSRF Protection**: Implement token validation
4. **Session Hijacking**: Regenerate session IDs
5. **Password Storage**: Use `password_hash()` with Argon2id
6. **File Upload Security**: Validate MIME types and extensions
7. **Error Disclosure**: Don't expose sensitive info in production
8. **Dependency Vulnerabilities**: Regular updates with Composer
9. **Memory Leaks**: Unset large variables and close resources
10. **N+1 Query Problem**: Use eager loading or joins

## Swoole and Laravel Octane

### Swoole Overview
Swoole is a high-performance coroutine-based PHP extension for building async, concurrent applications.

### Laravel Octane Setup

```bash
# Install Octane
composer require laravel/octane

# Install Swoole extension
pecl install swoole

# Or install RoadRunner
./vendor/bin/rr get-binary
```

### Octane Configuration

```php
// config/octane.php
return [
    'server' => env('OCTANE_SERVER', 'swoole'),
    
    'swoole' => [
        'options' => [
            'log_level' => app()->environment('production') ? SWOOLE_LOG_ERROR : SWOOLE_LOG_INFO,
            'package_max_length' => 10 * 1024 * 1024,
            'max_request' => 1000,
            'socket_buffer_size' => 10 * 1024 * 1024,
            'task_worker_num' => swoole_cpu_num() * 2,
            'worker_num' => swoole_cpu_num() * 2,
        ],
    ],
    
    'cache' => [
        'rows' => 1000,
        'bytes' => 10000,
    ],
    
    'tables' => [
        'example' => [
            'columns' => [
                ['name' => 'id', 'type' => 'int', 'size' => 8],
                ['name' => 'data', 'type' => 'string', 'size' => 1000],
            ],
            'size' => 1000,
        ],
    ],
    
    'warm' => [
        ...Octane::defaultServicesToWarm(),
        \App\Services\ExpensiveService::class,
    ],
    
    'flush' => [
        \App\Services\StatefulService::class,
    ],
];
```

### Octane-Optimized Code

```php
<?php

namespace App\Http\Controllers;

use Laravel\Octane\Facades\Octane;
use Illuminate\Support\Facades\Cache;

class OctaneController extends Controller
{
    // Concurrent tasks execution
    public function concurrent()
    {
        [$users, $posts, $stats] = Octane::concurrently([
            fn () => User::all(),
            fn () => Post::latest()->take(10)->get(),
            fn () => $this->calculateStats(),
        ]);
        
        return response()->json([
            'users' => $users,
            'posts' => $posts,
            'stats' => $stats,
        ]);
    }
    
    // Using Octane cache
    public function cached()
    {
        return Octane::cache('users', function () {
            return User::with('posts')->get();
        }, seconds: 60);
    }
    
    // Using Octane tables for ultra-fast memory storage
    public function table()
    {
        // Store in Octane table
        Octane::table('example')->set('key', [
            'id' => 1,
            'data' => 'value'
        ]);
        
        // Retrieve from table
        $value = Octane::table('example')->get('key');
        
        return response()->json($value);
    }
    
    // Task dispatching
    public function task()
    {
        Octane::task(function () {
            // Heavy background task
            $this->processLargeDataset();
        });
        
        return response()->json(['status' => 'Task dispatched']);
    }
    
    // WebSocket support with Swoole
    public function websocket()
    {
        Octane::onMessage(function ($connection, $data) {
            $message = json_decode($data, true);
            
            // Broadcast to all connections
            foreach (Octane::connections() as $conn) {
                $conn->send(json_encode([
                    'user' => $connection->id,
                    'message' => $message['text'],
                    'timestamp' => now(),
                ]));
            }
        });
    }
}

// Service with state management for Octane
namespace App\Services;

use Laravel\Octane\Contracts\DispatchesCoroutines;

class StatefulService implements DispatchesCoroutines
{
    private array $cache = [];
    private int $requestCount = 0;
    
    public function handle()
    {
        $this->requestCount++;
        
        // Be careful with stateful services
        // They persist between requests
    }
    
    public function flush()
    {
        // Reset state between requests
        $this->cache = [];
        $this->requestCount = 0;
    }
}
```

### Swoole Coroutines

```php
<?php

use Swoole\Coroutine;
use Swoole\Coroutine\Http\Client;
use Swoole\Coroutine\MySQL;

// Coroutine-based HTTP requests
Coroutine\run(function () {
    // Concurrent HTTP requests
    $results = [];
    
    Coroutine::create(function () use (&$results) {
        $client = new Client('api.example.com', 443, true);
        $client->get('/users');
        $results['users'] = json_decode($client->body, true);
    });
    
    Coroutine::create(function () use (&$results) {
        $client = new Client('api.example.com', 443, true);
        $client->get('/posts');
        $results['posts'] = json_decode($client->body, true);
    });
    
    // Wait for all coroutines
    Coroutine::sleep(0.001);
    
    var_dump($results);
});

// Coroutine MySQL
Coroutine\run(function () {
    $mysql = new MySQL();
    $mysql->connect([
        'host' => '127.0.0.1',
        'port' => 3306,
        'user' => 'root',
        'password' => 'password',
        'database' => 'test',
    ]);
    
    // Concurrent queries
    $users = $mysql->query('SELECT * FROM users');
    $posts = $mysql->query('SELECT * FROM posts');
    
    var_dump($users, $posts);
});

// Channel for coroutine communication
$channel = new Coroutine\Channel(10);

Coroutine::create(function () use ($channel) {
    for ($i = 0; $i < 10; $i++) {
        $channel->push(['id' => $i, 'data' => "message-$i"]);
        Coroutine::sleep(0.1);
    }
});

Coroutine::create(function () use ($channel) {
    while ($data = $channel->pop()) {
        echo "Received: " . json_encode($data) . "\n";
    }
});
```

### Octane Best Practices

```php
// 1. Avoid memory leaks - reset services
class LeakyService
{
    private array $data = [];
    
    public function addData($item)
    {
        $this->data[] = $item; // This accumulates between requests!
    }
    
    public function flush()
    {
        $this->data = []; // Reset in octane.php flush array
    }
}

// 2. Use dependency injection properly
class GoodController extends Controller
{
    // Don't inject request in constructor with Octane
    // BAD:
    // public function __construct(Request $request) { }
    
    // GOOD:
    public function index(Request $request)
    {
        return $request->all();
    }
}

// 3. Handle static properties carefully
class StaticService
{
    private static ?array $cache = null;
    
    public static function get()
    {
        if (self::$cache === null) {
            self::$cache = expensive_operation();
        }
        return self::$cache;
    }
    
    public static function flush()
    {
        self::$cache = null;
    }
}

// 4. Database connection management
DB::connection()->beforeExecuting(function () {
    if (!DB::connection()->getPdo()) {
        DB::connection()->reconnect();
    }
});

// 5. File upload handling
Route::post('/upload', function (Request $request) {
    $file = $request->file('file');
    
    // Move file immediately to prevent issues
    $path = $file->storeAs('uploads', $file->hashName());
    
    // Process in background
    dispatch(new ProcessUpload($path));
    
    return response()->json(['path' => $path]);
});
```

### Running Octane

```bash
# Start Octane server with Swoole
php artisan octane:start --server=swoole --host=0.0.0.0 --port=8000 --workers=4

# Start with RoadRunner
php artisan octane:start --server=roadrunner --host=0.0.0.0 --port=8000

# Production with supervisor
[program:octane]
process_name=%(program_name)s_%(process_num)02d
command=php /path/to/artisan octane:start --server=swoole --host=127.0.0.1 --port=8000
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/octane.log
stopwaitsecs=3600

# Reload workers gracefully
php artisan octane:reload

# Check status
php artisan octane:status
```

## Performance Tips

1. **OpCode Caching**: Enable OPcache in production
2. **Database Indexing**: Index frequently queried columns
3. **Query Optimization**: Use EXPLAIN to analyze queries
4. **Connection Pooling**: Reuse database connections
5. **Output Buffering**: Use `ob_start()` for large outputs
6. **Lazy Loading**: Load resources only when needed
7. **CDN Usage**: Serve static assets from CDN
8. **HTTP Caching**: Implement proper cache headers
9. **Compression**: Enable gzip/brotli compression
10. **Profiling**: Use tools like Xdebug or Blackfire
11. **Swoole/Octane**: Use for high-concurrency applications
12. **Coroutines**: Leverage async programming with Swoole