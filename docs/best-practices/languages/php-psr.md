# PHP PSR (PHP Standards Recommendations) Best Practices

## Overview
PSR standards are PHP specifications published by the PHP Framework Interop Group (PHP-FIG) to standardize common aspects of PHP development, ensuring interoperability between frameworks and libraries.

## Documentation
- [Official PHP-FIG Website](https://www.php-fig.org)
- [PSR Index](https://www.php-fig.org/psr)
- [PHP-FIG GitHub](https://github.com/php-fig)
- [PHP Documentation](https://www.php.net/docs.php)

## PSR Standards Overview

### Accepted Standards
- **PSR-1**: Basic Coding Standard
- **PSR-3**: Logger Interface
- **PSR-4**: Autoloading Standard
- **PSR-6**: Caching Interface
- **PSR-7**: HTTP Message Interface
- **PSR-11**: Container Interface
- **PSR-12**: Extended Coding Style Guide
- **PSR-13**: Hypermedia Links
- **PSR-14**: Event Dispatcher
- **PSR-15**: HTTP Handlers
- **PSR-16**: Simple Cache
- **PSR-17**: HTTP Factories
- **PSR-18**: HTTP Client

## PSR-1: Basic Coding Standard

### Key Requirements

```php
<?php
// Files MUST use only <?php and <?= tags
// Files MUST use only UTF-8 without BOM for PHP code
// Files SHOULD either declare symbols OR execute logic, not both

// Namespace and class declaration
namespace Vendor\Package;

// Class names MUST be declared in StudlyCaps
class ClassName
{
    // Class constants MUST be declared in all upper case with underscore separators
    const VERSION = '1.0.0';
    const DATE_APPROVED = '2024-01-01';
    
    // Method names MUST be declared in camelCase
    public function methodName()
    {
        // Code here
    }
}

// Property names can be any convention but should be consistent
class ConsistentNaming
{
    // Choose one style and stick to it:
    public $camelCase;      // Option 1: camelCase
    public $under_score;    // Option 2: underscore
    public $StudlyCaps;     // Option 3: StudlyCaps
}
```

## PSR-12: Extended Coding Style Guide

### File Structure

```php
<?php

declare(strict_types=1);

namespace Vendor\Package;

use Vendor\Package\{ClassA as A, ClassB, ClassC as C};
use Vendor\Package\SomeNamespace\ClassD as D;
use Vendor\Package\AnotherNamespace\ClassE as E;

use function Vendor\Package\{functionA, functionB, functionC};
use function Another\Vendor\functionD;

use const Vendor\Package\{CONSTANT_A, CONSTANT_B, CONSTANT_C};
use const Another\Vendor\CONSTANT_D;

/**
 * Class documentation block
 */
class Foo extends Bar implements FooInterface
{
    // Trait usage
    use SomeTrait;
    use OtherTrait {
        OtherTrait::method insteadof SomeTrait;
        OtherTrait::method as otherMethod;
    }
    
    // Property declarations
    private const CONSTANT = 'constant';
    
    public static int $publicStaticProperty = 1;
    
    protected string $protectedProperty = 'protected';
    
    private ?string $privateProperty = null;
    
    // Method declarations
    public function sampleMethod(int $a, ?string $b = null): array
    {
        if ($a === $b) {
            bar();
        } elseif ($a > $b) {
            $foo->bar($arg1);
        } else {
            BazClass::bar($arg2, $arg3);
        }
    }
    
    final public static function finalStaticMethod(): void
    {
        // Method body
    }
    
    abstract protected function abstractProtectedMethod(): string;
}
```

### Control Structures

```php
<?php

// if, elseif, else
if ($expr1) {
    // if body
} elseif ($expr2) {
    // elseif body
} else {
    // else body
}

// switch, case
switch ($expr) {
    case 0:
        echo 'First case, with a break';
        break;
    case 1:
        echo 'Second case, which falls through';
        // no break
    case 2:
    case 3:
    case 4:
        echo 'Third case, return instead of break';
        return;
    default:
        echo 'Default case';
        break;
}

// while
while ($expr) {
    // structure body
}

// do while
do {
    // structure body
} while ($expr);

// for
for ($i = 0; $i < 10; $i++) {
    // for body
}

// foreach
foreach ($iterable as $key => $value) {
    // foreach body
}

// try, catch, finally
try {
    // try body
} catch (FirstThrowableType $e) {
    // catch body
} catch (OtherThrowableType | AnotherThrowableType $e) {
    // catch body
} finally {
    // finally body
}
```

### Operators and Spacing

```php
<?php

// Binary operators
$sum = $a + $b;
$result = $foo || $bar;
$type = $foo instanceof Bar;

// Ternary operators
$variable = $foo ? 'foo' : 'bar';
$variable = $foo ?: 'bar';
$variable = $foo ?? 'bar';

// Null coalescing operator
$username = $_GET['user'] ?? 'nobody';

// Comparison operators
if ($a === $b) {
    // Code
}

// Assignment operators
$foo = $bar;
$foo += $bar;

// Logical operators
if ($foo && $bar) {
    // Code
}

// Increment/Decrement
$i++;
++$j;
```

## PSR-4: Autoloading Standard

### Directory Structure

```
vendor/
└── Package/
    └── src/
        ├── ClassName.php
        ├── Namespace/
        │   └── ClassInNamespace.php
        └── Another/
            └── Namespace/
                └── AnotherClass.php
```

### Composer Configuration

```json
{
    "autoload": {
        "psr-4": {
            "Vendor\\Package\\": "src/",
            "Vendor\\AnotherPackage\\": "lib/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "Vendor\\Package\\Tests\\": "tests/"
        }
    }
}
```

### Implementation Example

```php
<?php
// File: src/Http/Controller/UserController.php

namespace Vendor\Package\Http\Controller;

use Vendor\Package\Model\User;
use Vendor\Package\Service\UserService;

class UserController
{
    private UserService $userService;
    
    public function __construct(UserService $userService)
    {
        $this->userService = $userService;
    }
    
    public function show(int $id): User
    {
        return $this->userService->findById($id);
    }
}
```

## PSR-3: Logger Interface

```php
<?php

namespace Psr\Log;

interface LoggerInterface
{
    public function emergency(string|\Stringable $message, array $context = []): void;
    public function alert(string|\Stringable $message, array $context = []): void;
    public function critical(string|\Stringable $message, array $context = []): void;
    public function error(string|\Stringable $message, array $context = []): void;
    public function warning(string|\Stringable $message, array $context = []): void;
    public function notice(string|\Stringable $message, array $context = []): void;
    public function info(string|\Stringable $message, array $context = []): void;
    public function debug(string|\Stringable $message, array $context = []): void;
    public function log($level, string|\Stringable $message, array $context = []): void;
}

// Implementation example
use Psr\Log\LoggerInterface;
use Psr\Log\LogLevel;

class FileLogger implements LoggerInterface
{
    private string $logFile;
    
    public function __construct(string $logFile)
    {
        $this->logFile = $logFile;
    }
    
    public function log($level, string|\Stringable $message, array $context = []): void
    {
        $message = $this->interpolate($message, $context);
        $timestamp = date('Y-m-d H:i:s');
        $logEntry = sprintf("[%s] %s: %s\n", $timestamp, strtoupper($level), $message);
        file_put_contents($this->logFile, $logEntry, FILE_APPEND);
    }
    
    private function interpolate($message, array $context = []): string
    {
        $replace = [];
        foreach ($context as $key => $val) {
            if (!is_array($val) && (!is_object($val) || method_exists($val, '__toString'))) {
                $replace['{' . $key . '}'] = $val;
            }
        }
        return strtr($message, $replace);
    }
    
    public function emergency(string|\Stringable $message, array $context = []): void
    {
        $this->log(LogLevel::EMERGENCY, $message, $context);
    }
    
    // Implement other methods...
}
```

## PSR-7: HTTP Message Interface

```php
<?php

use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\StreamInterface;

// Request handling
class RequestHandler
{
    public function handle(ServerRequestInterface $request): ResponseInterface
    {
        // Get request data
        $method = $request->getMethod();
        $uri = $request->getUri();
        $headers = $request->getHeaders();
        $body = $request->getBody();
        $queryParams = $request->getQueryParams();
        $parsedBody = $request->getParsedBody();
        $uploadedFiles = $request->getUploadedFiles();
        $attributes = $request->getAttributes();
        
        // Process request
        $data = $this->processRequest($request);
        
        // Create response
        $response = new Response();
        $response = $response->withStatus(200)
            ->withHeader('Content-Type', 'application/json')
            ->withBody($this->createStream(json_encode($data)));
            
        return $response;
    }
    
    private function createStream(string $content): StreamInterface
    {
        $stream = fopen('php://temp', 'r+');
        fwrite($stream, $content);
        rewind($stream);
        return new Stream($stream);
    }
}
```

## PSR-11: Container Interface

```php
<?php

use Psr\Container\ContainerInterface;
use Psr\Container\NotFoundExceptionInterface;
use Psr\Container\ContainerExceptionInterface;

class Container implements ContainerInterface
{
    private array $services = [];
    private array $factories = [];
    
    public function get(string $id)
    {
        if (!$this->has($id)) {
            throw new NotFoundException("Service '$id' not found");
        }
        
        if (!isset($this->services[$id])) {
            $this->services[$id] = $this->factories[$id]($this);
        }
        
        return $this->services[$id];
    }
    
    public function has(string $id): bool
    {
        return isset($this->factories[$id]) || isset($this->services[$id]);
    }
    
    public function set(string $id, callable $factory): void
    {
        $this->factories[$id] = $factory;
    }
    
    public function singleton(string $id, callable $factory): void
    {
        $this->factories[$id] = function($container) use ($factory) {
            static $instance;
            if ($instance === null) {
                $instance = $factory($container);
            }
            return $instance;
        };
    }
}

// Usage
$container = new Container();

$container->singleton(DatabaseInterface::class, function($container) {
    return new MySQLDatabase(
        $container->get('db.host'),
        $container->get('db.user'),
        $container->get('db.password')
    );
});

$container->set(UserRepository::class, function($container) {
    return new UserRepository($container->get(DatabaseInterface::class));
});
```

## PSR-15: HTTP Server Request Handlers

```php
<?php

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;

// Middleware implementation
class AuthenticationMiddleware implements MiddlewareInterface
{
    public function process(
        ServerRequestInterface $request,
        RequestHandlerInterface $handler
    ): ResponseInterface {
        $token = $request->getHeaderLine('Authorization');
        
        if (!$this->isValidToken($token)) {
            return new Response(401, ['Content-Type' => 'application/json'], 
                json_encode(['error' => 'Unauthorized'])
            );
        }
        
        $request = $request->withAttribute('user', $this->getUserFromToken($token));
        
        return $handler->handle($request);
    }
    
    private function isValidToken(string $token): bool
    {
        // Token validation logic
        return true;
    }
    
    private function getUserFromToken(string $token): array
    {
        // Extract user from token
        return ['id' => 1, 'name' => 'John Doe'];
    }
}

// Request handler
class Application implements RequestHandlerInterface
{
    private array $middleware = [];
    private RequestHandlerInterface $handler;
    
    public function pipe(MiddlewareInterface $middleware): self
    {
        $this->middleware[] = $middleware;
        return $this;
    }
    
    public function handle(ServerRequestInterface $request): ResponseInterface
    {
        $handler = $this->handler;
        
        foreach (array_reverse($this->middleware) as $middleware) {
            $handler = new class($middleware, $handler) implements RequestHandlerInterface {
                private MiddlewareInterface $middleware;
                private RequestHandlerInterface $handler;
                
                public function __construct(
                    MiddlewareInterface $middleware,
                    RequestHandlerInterface $handler
                ) {
                    $this->middleware = $middleware;
                    $this->handler = $handler;
                }
                
                public function handle(ServerRequestInterface $request): ResponseInterface
                {
                    return $this->middleware->process($request, $this->handler);
                }
            };
        }
        
        return $handler->handle($request);
    }
}
```

## PSR-14: Event Dispatcher

```php
<?php

use Psr\EventDispatcher\EventDispatcherInterface;
use Psr\EventDispatcher\ListenerProviderInterface;
use Psr\EventDispatcher\StoppableEventInterface;

// Event
class UserCreatedEvent implements StoppableEventInterface
{
    private User $user;
    private bool $propagationStopped = false;
    
    public function __construct(User $user)
    {
        $this->user = $user;
    }
    
    public function getUser(): User
    {
        return $this->user;
    }
    
    public function stopPropagation(): void
    {
        $this->propagationStopped = true;
    }
    
    public function isPropagationStopped(): bool
    {
        return $this->propagationStopped;
    }
}

// Listener Provider
class ListenerProvider implements ListenerProviderInterface
{
    private array $listeners = [];
    
    public function getListenersForEvent(object $event): iterable
    {
        $eventType = get_class($event);
        
        if (isset($this->listeners[$eventType])) {
            yield from $this->listeners[$eventType];
        }
        
        foreach (class_parents($event) as $parent) {
            if (isset($this->listeners[$parent])) {
                yield from $this->listeners[$parent];
            }
        }
        
        foreach (class_implements($event) as $interface) {
            if (isset($this->listeners[$interface])) {
                yield from $this->listeners[$interface];
            }
        }
    }
    
    public function addListener(string $eventType, callable $listener): void
    {
        $this->listeners[$eventType][] = $listener;
    }
}

// Event Dispatcher
class EventDispatcher implements EventDispatcherInterface
{
    private ListenerProviderInterface $listenerProvider;
    
    public function __construct(ListenerProviderInterface $listenerProvider)
    {
        $this->listenerProvider = $listenerProvider;
    }
    
    public function dispatch(object $event): object
    {
        $stoppable = $event instanceof StoppableEventInterface;
        
        foreach ($this->listenerProvider->getListenersForEvent($event) as $listener) {
            if ($stoppable && $event->isPropagationStopped()) {
                break;
            }
            
            $listener($event);
        }
        
        return $event;
    }
}
```

## PSR-16: Simple Cache

```php
<?php

use Psr\SimpleCache\CacheInterface;
use DateInterval;

class FileCache implements CacheInterface
{
    private string $directory;
    
    public function __construct(string $directory)
    {
        $this->directory = rtrim($directory, '/');
    }
    
    public function get(string $key, $default = null)
    {
        $this->validateKey($key);
        $file = $this->getFilePath($key);
        
        if (!file_exists($file)) {
            return $default;
        }
        
        $data = unserialize(file_get_contents($file));
        
        if ($data['expires'] !== null && $data['expires'] < time()) {
            $this->delete($key);
            return $default;
        }
        
        return $data['value'];
    }
    
    public function set(string $key, $value, $ttl = null): bool
    {
        $this->validateKey($key);
        
        $expires = null;
        if ($ttl !== null) {
            $expires = time() + $this->ttlToSeconds($ttl);
        }
        
        $data = serialize([
            'value' => $value,
            'expires' => $expires
        ]);
        
        return file_put_contents($this->getFilePath($key), $data) !== false;
    }
    
    public function delete(string $key): bool
    {
        $this->validateKey($key);
        $file = $this->getFilePath($key);
        
        if (file_exists($file)) {
            return unlink($file);
        }
        
        return true;
    }
    
    public function clear(): bool
    {
        $files = glob($this->directory . '/*.cache');
        foreach ($files as $file) {
            unlink($file);
        }
        return true;
    }
    
    public function getMultiple(iterable $keys, $default = null): iterable
    {
        $values = [];
        foreach ($keys as $key) {
            $values[$key] = $this->get($key, $default);
        }
        return $values;
    }
    
    public function setMultiple(iterable $values, $ttl = null): bool
    {
        foreach ($values as $key => $value) {
            if (!$this->set($key, $value, $ttl)) {
                return false;
            }
        }
        return true;
    }
    
    public function deleteMultiple(iterable $keys): bool
    {
        foreach ($keys as $key) {
            if (!$this->delete($key)) {
                return false;
            }
        }
        return true;
    }
    
    public function has(string $key): bool
    {
        return $this->get($key) !== null;
    }
    
    private function validateKey(string $key): void
    {
        if (!preg_match('/^[a-zA-Z0-9_.]+$/', $key)) {
            throw new InvalidArgumentException("Invalid cache key: $key");
        }
    }
    
    private function getFilePath(string $key): string
    {
        return $this->directory . '/' . $key . '.cache';
    }
    
    private function ttlToSeconds($ttl): int
    {
        if (is_int($ttl)) {
            return $ttl;
        }
        
        if ($ttl instanceof DateInterval) {
            return (new DateTime())->add($ttl)->getTimestamp() - time();
        }
        
        throw new InvalidArgumentException('Invalid TTL');
    }
}
```

## PSR-18: HTTP Client

```php
<?php

use Psr\Http\Client\ClientInterface;
use Psr\Http\Client\ClientExceptionInterface;
use Psr\Http\Client\NetworkExceptionInterface;
use Psr\Http\Client\RequestExceptionInterface;
use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;

class HttpClient implements ClientInterface
{
    private array $options;
    
    public function __construct(array $options = [])
    {
        $this->options = array_merge([
            'timeout' => 30,
            'follow_redirects' => true,
            'max_redirects' => 5,
            'verify_ssl' => true,
        ], $options);
    }
    
    public function sendRequest(RequestInterface $request): ResponseInterface
    {
        $ch = curl_init();
        
        // Set URL
        curl_setopt($ch, CURLOPT_URL, (string) $request->getUri());
        
        // Set method
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $request->getMethod());
        
        // Set headers
        $headers = [];
        foreach ($request->getHeaders() as $name => $values) {
            foreach ($values as $value) {
                $headers[] = "$name: $value";
            }
        }
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        
        // Set body
        $body = (string) $request->getBody();
        if ($body !== '') {
            curl_setopt($ch, CURLOPT_POSTFIELDS, $body);
        }
        
        // Set options
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, $this->options['timeout']);
        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, $this->options['follow_redirects']);
        curl_setopt($ch, CURLOPT_MAXREDIRS, $this->options['max_redirects']);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->options['verify_ssl']);
        curl_setopt($ch, CURLOPT_HEADER, true);
        
        // Execute request
        $response = curl_exec($ch);
        
        if ($response === false) {
            $error = curl_error($ch);
            curl_close($ch);
            throw new NetworkException("Network error: $error", $request);
        }
        
        // Parse response
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $headerSize = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
        curl_close($ch);
        
        $headerStr = substr($response, 0, $headerSize);
        $body = substr($response, $headerSize);
        
        // Create response object
        return $this->createResponse($httpCode, $headerStr, $body);
    }
    
    private function createResponse(int $statusCode, string $headerStr, string $body): ResponseInterface
    {
        // Parse headers and create PSR-7 response
        // Implementation depends on PSR-7 implementation being used
        return new Response($statusCode, $this->parseHeaders($headerStr), $body);
    }
    
    private function parseHeaders(string $headerStr): array
    {
        $headers = [];
        $lines = explode("\r\n", $headerStr);
        
        foreach ($lines as $line) {
            if (strpos($line, ':') !== false) {
                [$name, $value] = explode(':', $line, 2);
                $headers[trim($name)][] = trim($value);
            }
        }
        
        return $headers;
    }
}
```

## Code Quality Tools

### PHP CodeSniffer Configuration

```xml
<?xml version="1.0"?>
<ruleset name="Project">
    <description>Project coding standards</description>
    
    <!-- Include PSR-12 standard -->
    <rule ref="PSR12"/>
    
    <!-- Files to check -->
    <file>src/</file>
    <file>tests/</file>
    
    <!-- Exclude patterns -->
    <exclude-pattern>*/vendor/*</exclude-pattern>
    <exclude-pattern>*/cache/*</exclude-pattern>
    
    <!-- Custom rules -->
    <rule ref="Generic.Arrays.DisallowLongArraySyntax"/>
    <rule ref="Generic.CodeAnalysis.UnusedFunctionParameter"/>
    <rule ref="Generic.Commenting.Todo"/>
    <rule ref="Generic.Files.LineLength">
        <properties>
            <property name="lineLimit" value="120"/>
            <property name="absoluteLineLimit" value="150"/>
        </properties>
    </rule>
</ruleset>
```

### PHPStan Configuration

```neon
parameters:
    level: 8
    paths:
        - src
        - tests
    excludePaths:
        - src/*/cache/*
    checkMissingIterableValueType: false
    checkGenericClassInNonGenericObjectType: false
```

## Best Practices Summary

1. **Always follow PSR-12** for coding style consistency
2. **Use PSR-4** for autoloading with Composer
3. **Implement interfaces** from PSR when building libraries
4. **Type declarations** should be used everywhere possible
5. **Strict types** should be enabled per file
6. **Dependency injection** over static calls
7. **Composition over inheritance** where appropriate
8. **Single responsibility** for classes and methods
9. **Immutability** where possible
10. **Proper error handling** with exceptions
11. **Comprehensive testing** with PHPUnit
12. **Static analysis** with PHPStan or Psalm
13. **Code formatting** with PHP-CS-Fixer
14. **Documentation** with PHPDoc blocks
15. **Version control** with semantic versioning