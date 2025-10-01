# PHPStan Best Practices

## Official Documentation
- **PHPStan Website**: https://phpstan.org
- **Documentation**: https://phpstan.org/user-guide/getting-started
- **GitHub Repository**: https://github.com/phpstan/phpstan
- **Rule Levels**: https://phpstan.org/user-guide/rule-levels
- **Config Reference**: https://phpstan.org/config-reference
- **Extensions**: https://github.com/phpstan/phpstan-extensions

## Installation and Setup

### Composer Installation (Recommended)
```bash
# Install as dev dependency
composer require --dev phpstan/phpstan

# Install with specific version
composer require --dev phpstan/phpstan:^1.10

# Verify installation
./vendor/bin/phpstan --version

# Run analysis
./vendor/bin/phpstan analyse src tests
```

### PHAR Installation
```bash
# Download PHAR file
wget https://github.com/phpstan/phpstan/releases/latest/download/phpstan.phar

# Make it executable
chmod +x phpstan.phar

# Run analysis
./phpstan.phar analyse src

# Install globally
sudo mv phpstan.phar /usr/local/bin/phpstan
phpstan analyse src
```

### Docker Installation
```bash
# Run with Docker
docker run --rm -v $(pwd):/app ghcr.io/phpstan/phpstan:latest analyse /app/src

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  phpstan:
    image: ghcr.io/phpstan/phpstan:latest
    volumes:
      - ./:/app
    working_dir: /app
    command: analyse src tests
EOF

# Run with docker-compose
docker-compose run --rm phpstan

# Custom Dockerfile with extensions
cat > Dockerfile.phpstan << 'EOF'
FROM ghcr.io/phpstan/phpstan:latest

RUN composer global require \
    phpstan/phpstan-symfony \
    phpstan/phpstan-doctrine \
    phpstan/phpstan-phpunit

WORKDIR /app
EOF

docker build -f Dockerfile.phpstan -t phpstan-custom .
docker run --rm -v $(pwd):/app phpstan-custom analyse src
```

## Configuration File Structure

### Basic phpstan.neon Configuration
```neon
# phpstan.neon or phpstan.neon.dist
parameters:
    level: 8
    paths:
        - src
        - tests

    # Exclude directories
    excludePaths:
        - src/Legacy/*
        - tests/Fixtures/*
        - */vendor/*

    # Report unmatched ignored errors
    reportUnmatchedIgnoredErrors: true

    # Check missing type hints
    checkMissingIterableValueType: false
    checkGenericClassInNonGenericObjectType: false

    # PHP version compatibility
    phpVersion: 80200 # PHP 8.2

    # Memory limit
    memoryLimit: 1G
```

### Advanced Configuration
```neon
includes:
    - vendor/phpstan/phpstan/conf/bleedingEdge.neon
    - phpstan-baseline.neon

parameters:
    level: max

    paths:
        - src
        - tests

    excludePaths:
        analyseAndScan:
            - */tests/Fixtures/*
        analyse:
            - src/Legacy/OldCode.php

    # Bootstrap file
    bootstrapFiles:
        - tests/bootstrap.php
        - config/constants.php

    # Auto-loading
    scanFiles:
        - vendor/autoload.php

    scanDirectories:
        - src/Models

    # Type aliases
    typeAliases:
        UserId: 'int<1, max>'
        Email: 'non-empty-string'
        Timestamp: 'int<0, max>'

    # Ignore errors
    ignoreErrors:
        - '#Call to an undefined method [a-zA-Z0-9\\_]+::magicMethod\(\)#'
        -
            message: '#Access to an undefined property#'
            path: src/DynamicProperty.php
        -
            message: '#Parameter \#1 \$user of method#'
            paths:
                - src/Legacy/*

    # Stub files
    stubFiles:
        - stubs/custom-library.stub

    # Parallel processing
    parallel:
        jobSize: 20
        maximumNumberOfProcesses: 32
        minimumNumberOfJobsPerProcess: 2

    # Universal object crates
    universalObjectCratesClasses:
        - stdClass
        - SimpleXMLElement

    # Dynamic constant names
    dynamicConstantNames:
        - APP_*
        - Symfony\Component\HttpKernel\Kernel::*_DIR

    # Custom rules
    customRulesetUsed: true

    # Treat PHP doc types as native
    treatPhpDocTypesAsCertain: false
```

### Project-Specific Configuration
```neon
# phpstan.neon
includes:
    - vendor/phpstan/phpstan-symfony/extension.neon
    - vendor/phpstan/phpstan-doctrine/extension.neon
    - vendor/phpstan/phpstan-phpunit/extension.neon

parameters:
    level: 8

    paths:
        - src
        - tests

    symfony:
        containerXmlPath: var/cache/dev/App_KernelDevDebugContainer.xml
        consoleApplicationLoader: tests/console-application.php

    doctrine:
        queryBuilderClass: Doctrine\ORM\QueryBuilder
        repositoryClass: Doctrine\ORM\EntityRepository
        objectManagerLoader: tests/object-manager.php

    phpunit:
        phpunitPath: vendor/bin/phpunit

    excludePaths:
        - src/Migrations/*
        - src/Kernel.php

    checkMissingIterableValueType: true
    checkGenericClassInNonGenericObjectType: true
    checkMissingCallableSignature: true

    polluteScopeWithLoopInitialAssignments: false
    polluteScopeWithAlwaysIterableForeach: false

    reportAlwaysTrueInLastCondition: true
    reportStaticMethodSignatures: true
    reportWrongPhpDocTypeInVarTag: true
```

## Strictness Levels (0-9)

### Level Progression Overview
```php
<?php

// Level 0 - Basic checks
// - Basic undefined variables
// - Unknown classes in type hints

class Level0Example
{
    public function test()
    {
        echo $undefinedVariable; // Detected
        $user = new NonExistentClass(); // Detected
    }
}

// Level 1 - Unknown methods and properties
class Level1Example
{
    public function test(User $user)
    {
        $user->unknownMethod(); // Detected
        echo $user->unknownProperty; // Detected
    }
}

// Level 2 - Unknown methods on all types
class Level2Example
{
    public function test($mixed)
    {
        $mixed->someMethod(); // Detected
    }
}

// Level 3 - Return types, property types
class Level3Example
{
    public function getString(): string
    {
        return 123; // Detected - wrong return type
    }

    private string $name;

    public function setName($value)
    {
        $this->name = 123; // Detected - wrong property type
    }
}

// Level 4 - Dead code detection
class Level4Example
{
    public function test()
    {
        if (false) {
            echo "This is dead code"; // Detected
        }

        return;
        echo "Unreachable code"; // Detected
    }
}

// Level 5 - Argument type checks
class Level5Example
{
    public function process(string $value)
    {
        // Implementation
    }

    public function test()
    {
        $this->process(123); // Detected - wrong argument type
    }
}

// Level 6 - Missing type hints
class Level6Example
{
    private $property; // Detected - missing type hint

    public function test($param) // Detected - missing param type
    {
        return $param; // Detected - missing return type
    }
}

// Level 7 - Partially wrong union types
class Level7Example
{
    public function test(int|string $value): int
    {
        return $value; // Detected - string part not compatible
    }
}

// Level 8 - Calling methods on nullable types
class Level8Example
{
    public function test(?User $user)
    {
        echo $user->getName(); // Detected - possible null
    }
}

// Level 9 (max) - Strict mixed type checking
class Level9Example
{
    public function test(mixed $value)
    {
        echo $value->property; // Detected - mixed has no known properties
        $value->method(); // Detected - mixed has no known methods
    }
}
```

### Recommended Level Strategy
```neon
# Start with level 0 for legacy projects
parameters:
    level: 0

# Gradually increase level
parameters:
    level: 5 # Good balance for most projects

# Use max for new projects
parameters:
    level: max # Equivalent to level 9
```

## Core Concepts

### Type Inference
```php
<?php

class TypeInferenceExample
{
    public function basicInference(): void
    {
        $string = 'hello'; // PHPStan knows this is string
        $length = strlen($string); // PHPStan knows this is int

        // Array type inference
        $numbers = [1, 2, 3]; // array<int, int>
        $first = $numbers[0]; // int

        // Conditional type inference
        $value = random_int(0, 1) ? 'string' : 42; // string|int
    }

    public function narrowingTypes(?User $user): void
    {
        if ($user === null) {
            return;
        }

        // PHPStan knows $user is User here (not null)
        echo $user->getName();
    }

    public function assertTypes(mixed $value): void
    {
        assert($value instanceof User);

        // PHPStan knows $value is User after assertion
        echo $value->getName();
    }

    public function arrayShapeInference(): void
    {
        $data = [
            'id' => 1,
            'name' => 'John',
            'active' => true,
        ]; // array{id: int, name: string, active: bool}

        echo $data['name']; // string
    }
}
```

### Generics
```php
<?php

/**
 * @template T
 */
class Collection
{
    /**
     * @var array<T>
     */
    private array $items;

    /**
     * @param array<T> $items
     */
    public function __construct(array $items = [])
    {
        $this->items = $items;
    }

    /**
     * @param T $item
     */
    public function add($item): void
    {
        $this->items[] = $item;
    }

    /**
     * @return T|null
     */
    public function first()
    {
        return $this->items[0] ?? null;
    }

    /**
     * @template U
     * @param callable(T): U $callback
     * @return Collection<U>
     */
    public function map(callable $callback): Collection
    {
        return new Collection(array_map($callback, $this->items));
    }
}

// Usage
/** @var Collection<User> $users */
$users = new Collection([new User('John'), new User('Jane')]);
$firstUser = $users->first(); // User|null

$names = $users->map(fn(User $u) => $u->getName()); // Collection<string>

/**
 * @template TKey of array-key
 * @template TValue
 */
interface Repository
{
    /**
     * @param TKey $id
     * @return TValue|null
     */
    public function find($id);

    /**
     * @return array<TKey, TValue>
     */
    public function findAll(): array;
}

/**
 * @implements Repository<int, User>
 */
class UserRepository implements Repository
{
    public function find($id): ?User
    {
        // Implementation
        return new User('John');
    }

    public function findAll(): array
    {
        // Returns array<int, User>
        return [];
    }
}
```

### Advanced Type Rules
```php
<?php

use function PHPStan\Testing\assertType;

class AdvancedTypeRules
{
    /**
     * @param positive-int $positiveInt
     * @param negative-int $negativeInt
     * @param non-empty-string $nonEmptyString
     * @param non-empty-array<string> $nonEmptyArray
     * @param class-string $className
     * @param callable-string $callableName
     */
    public function specificTypes(
        int $positiveInt,
        int $negativeInt,
        string $nonEmptyString,
        array $nonEmptyArray,
        string $className,
        string $callableName
    ): void {
        // PHPStan enforces these specific types
    }

    /**
     * @param array{id: int, name: string, email?: string} $user
     */
    public function arrayShape(array $user): void
    {
        // PHPStan knows exact array structure
        $id = $user['id']; // int
        $name = $user['name']; // string
        $email = $user['email'] ?? null; // string|null
    }

    /**
     * @param list<int> $intList List with sequential numeric keys
     * @param array<string, User> $userMap String keys to User values
     */
    public function arrayTypes(array $intList, array $userMap): void
    {
        // Specific array type enforcement
    }

    /**
     * @param literal-string $literalOnly
     */
    public function literalString(string $literalOnly): void
    {
        // Only accepts string literals, not variables
    }

    /**
     * @param int<1, 100> $percentage
     * @param int<min, -1>|int<1, max> $nonZero
     */
    public function integerRanges(int $percentage, int $nonZero): void
    {
        // Range-based integer types
    }

    /**
     * @phpstan-assert User $value
     */
    public function assertUser(mixed $value): void
    {
        if (!$value instanceof User) {
            throw new \InvalidArgumentException('Expected User instance');
        }
    }

    /**
     * @phpstan-assert-if-true string $value
     */
    public function isString(mixed $value): bool
    {
        return is_string($value);
    }
}
```

## Rule Levels and Customization

### Custom Rules Implementation
```php
<?php
// src/PHPStan/Rules/NoEchoInProductionRule.php

namespace App\PHPStan\Rules;

use PhpParser\Node;
use PhpParser\Node\Stmt\Echo_;
use PHPStan\Analyser\Scope;
use PHPStan\Rules\Rule;
use PHPStan\Rules\RuleErrorBuilder;

/**
 * @implements Rule<Echo_>
 */
class NoEchoInProductionRule implements Rule
{
    public function getNodeType(): string
    {
        return Echo_::class;
    }

    public function processNode(Node $node, Scope $scope): array
    {
        // Disallow echo statements in production code
        if ($this->isProductionCode($scope->getFile())) {
            return [
                RuleErrorBuilder::message('Echo statement is not allowed in production code. Use a logger instead.')
                    ->file($scope->getFile())
                    ->line($node->getLine())
                    ->build()
            ];
        }

        return [];
    }

    private function isProductionCode(string $file): bool
    {
        return !str_contains($file, '/tests/') && !str_contains($file, '/dev/');
    }
}
```

### Register Custom Rules
```neon
# phpstan.neon
services:
    -
        class: App\PHPStan\Rules\NoEchoInProductionRule
        tags:
            - phpstan.rules.rule

    -
        class: App\PHPStan\Rules\RequireStrictTypesRule
        tags:
            - phpstan.rules.rule

    -
        class: App\PHPStan\Type\WordPressExtension
        tags:
            - phpstan.broker.dynamicMethodReturnTypeExtension

rules:
    - App\PHPStan\Rules\NoEchoInProductionRule
    - App\PHPStan\Rules\RequireStrictTypesRule
```

### Custom Type Extensions
```php
<?php
// src/PHPStan/Type/RequestDynamicReturnTypeExtension.php

namespace App\PHPStan\Type;

use PhpParser\Node\Expr\MethodCall;
use PHPStan\Analyser\Scope;
use PHPStan\Reflection\MethodReflection;
use PHPStan\Type\DynamicMethodReturnTypeExtension;
use PHPStan\Type\Type;
use PHPStan\Type\StringType;
use PHPStan\Type\IntegerType;
use PHPStan\Type\ArrayType;
use PHPStan\Type\MixedType;

class RequestDynamicReturnTypeExtension implements DynamicMethodReturnTypeExtension
{
    public function getClass(): string
    {
        return \Illuminate\Http\Request::class;
    }

    public function isMethodSupported(MethodReflection $methodReflection): bool
    {
        return in_array($methodReflection->getName(), ['input', 'get', 'post'], true);
    }

    public function getTypeFromMethodCall(
        MethodReflection $methodReflection,
        MethodCall $methodCall,
        Scope $scope
    ): Type {
        $args = $methodCall->getArgs();

        if (count($args) === 0) {
            return new ArrayType(new StringType(), new MixedType());
        }

        // Return specific type based on default value
        if (count($args) >= 2) {
            return $scope->getType($args[1]->value);
        }

        return new MixedType();
    }
}
```

## Baseline Files for Legacy Projects

### Generate Baseline
```bash
# Generate baseline file
./vendor/bin/phpstan analyse --generate-baseline

# Generate baseline with specific name
./vendor/bin/phpstan analyse --generate-baseline=phpstan-baseline.neon

# Generate baseline for specific level
./vendor/bin/phpstan analyse --level=8 --generate-baseline
```

### Baseline File Structure
```neon
# phpstan-baseline.neon
parameters:
    ignoreErrors:
        -
            message: "#^Parameter \\#1 \\$user of method App\\\\Service\\\\UserService\\:\\:process\\(\\) expects App\\\\Entity\\\\User, App\\\\Entity\\\\User\\|null given\\.$#"
            count: 3
            path: src/Controller/UserController.php

        -
            message: "#^Method App\\\\Repository\\\\ProductRepository\\:\\:findActive\\(\\) should return array\\<App\\\\Entity\\\\Product\\> but returns array\\<int, object\\>\\.$#"
            count: 1
            path: src/Repository/ProductRepository.php

        -
            message: "#^Call to an undefined method Doctrine\\\\Common\\\\Collections\\\\Collection\\:\\:toArray\\(\\)\\.$#"
            count: 5
            path: src/Service/CollectionService.php

        -
            message: "#^Access to an undefined property App\\\\Entity\\\\User\\:\\:\\$dynamicProperty\\.$#"
            count: 2
            path: src/Legacy/DynamicPropertyHandler.php
```

### Include Baseline in Config
```neon
# phpstan.neon
includes:
    - phpstan-baseline.neon

parameters:
    level: 8
    paths:
        - src
```

### Baseline Management Strategy
```bash
# Review and reduce baseline regularly
./vendor/bin/phpstan analyse --generate-baseline=phpstan-baseline-new.neon

# Compare old and new baseline
diff phpstan-baseline.neon phpstan-baseline-new.neon

# Fix errors and regenerate
./vendor/bin/phpstan analyse --generate-baseline

# Split baseline by directory
./vendor/bin/phpstan analyse src/Legacy --generate-baseline=baselines/legacy.neon
./vendor/bin/phpstan analyse src/Admin --generate-baseline=baselines/admin.neon
```

## Custom Rules and Extensions

### Extension Interface Types
```php
<?php

// 1. Dynamic Method Return Type Extension
use PHPStan\Type\DynamicMethodReturnTypeExtension;

// 2. Dynamic Static Method Return Type Extension
use PHPStan\Type\DynamicStaticMethodReturnTypeExtension;

// 3. Dynamic Function Return Type Extension
use PHPStan\Type\DynamicFunctionReturnTypeExtension;

// 4. Method Type Specifying Extension
use PHPStan\Type\MethodTypeSpecifyingExtension;

// 5. Static Method Type Specifying Extension
use PHPStan\Type\StaticMethodTypeSpecifyingExtension;

// 6. Broker Properties Class Reflection Extension
use PHPStan\Reflection\BrokerAwareExtension;
use PHPStan\Reflection\PropertiesClassReflectionExtension;

// 7. Methods Class Reflection Extension
use PHPStan\Reflection\MethodsClassReflectionExtension;
```

### Collection Extension Example
```php
<?php
// src/PHPStan/Extension/CollectionExtension.php

namespace App\PHPStan\Extension;

use PhpParser\Node\Expr\MethodCall;
use PHPStan\Analyser\Scope;
use PHPStan\Reflection\MethodReflection;
use PHPStan\Type\DynamicMethodReturnTypeExtension;
use PHPStan\Type\Type;
use PHPStan\Type\Generic\GenericObjectType;

class CollectionExtension implements DynamicMethodReturnTypeExtension
{
    public function getClass(): string
    {
        return \Illuminate\Support\Collection::class;
    }

    public function isMethodSupported(MethodReflection $methodReflection): bool
    {
        return $methodReflection->getName() === 'first';
    }

    public function getTypeFromMethodCall(
        MethodReflection $methodReflection,
        MethodCall $methodCall,
        Scope $scope
    ): Type {
        $callerType = $scope->getType($methodCall->var);

        if ($callerType instanceof GenericObjectType) {
            $itemType = $callerType->getTypes()[0];
            return $itemType->toUnion($itemType->toNullable());
        }

        return $methodReflection->getReturnType();
    }
}
```

### Properties Extension Example
```php
<?php
// src/PHPStan/Extension/MagicPropertiesExtension.php

namespace App\PHPStan\Extension;

use PHPStan\Reflection\ClassReflection;
use PHPStan\Reflection\PropertiesClassReflectionExtension;
use PHPStan\Reflection\PropertyReflection;
use PHPStan\Type\Type;
use PHPStan\Type\MixedType;

class MagicPropertiesExtension implements PropertiesClassReflectionExtension
{
    public function hasProperty(ClassReflection $classReflection, string $propertyName): bool
    {
        // Support magic properties for specific classes
        return $classReflection->getName() === 'App\Entity\DynamicEntity'
            && str_starts_with($propertyName, 'dynamic_');
    }

    public function getProperty(ClassReflection $classReflection, string $propertyName): PropertyReflection
    {
        return new class($classReflection, new MixedType()) implements PropertyReflection {
            private ClassReflection $classReflection;
            private Type $type;

            public function __construct(ClassReflection $classReflection, Type $type)
            {
                $this->classReflection = $classReflection;
                $this->type = $type;
            }

            public function getDeclaringClass(): ClassReflection
            {
                return $this->classReflection;
            }

            public function isStatic(): bool
            {
                return false;
            }

            public function isPrivate(): bool
            {
                return false;
            }

            public function isPublic(): bool
            {
                return true;
            }

            public function getDocComment(): ?string
            {
                return null;
            }

            public function getReadableType(): Type
            {
                return $this->type;
            }

            public function getWritableType(): Type
            {
                return $this->type;
            }

            public function canChangeTypeAfterAssignment(): bool
            {
                return true;
            }

            public function isReadable(): bool
            {
                return true;
            }

            public function isWritable(): bool
            {
                return true;
            }
        };
    }
}
```

## Framework Integrations

### Laravel Integration
```bash
# Install Laravel extension
composer require --dev phpstan/phpstan-laravel

# Install Larastan (Laravel-specific features)
composer require --dev larastan/larastan
```

```neon
# phpstan.neon
includes:
    - vendor/larastan/larastan/extension.neon

parameters:
    level: 8

    paths:
        - app
        - config
        - database
        - routes

    excludePaths:
        - app/Console/Kernel.php
        - app/Http/Kernel.php

    checkModelProperties: true
    checkOctaneCompatibility: true
    noUnnecessaryCollectionCall: true
    noUnnecessaryCollectionCallOnly: []
    noUnnecessaryCollectionCallExcept: []
```

### Symfony Integration
```bash
# Install Symfony extension
composer require --dev phpstan/phpstan-symfony
```

```neon
# phpstan.neon
includes:
    - vendor/phpstan/phpstan-symfony/extension.neon

parameters:
    level: 8

    symfony:
        containerXmlPath: var/cache/dev/App_KernelDevDebugContainer.xml
        constantHassers: false
        consoleApplicationLoader: tests/console-application.php

    paths:
        - src
        - tests

    excludePaths:
        - src/Kernel.php
        - src/Migrations/*
```

### Doctrine Integration
```bash
# Install Doctrine extension
composer require --dev phpstan/phpstan-doctrine
```

```neon
# phpstan.neon
includes:
    - vendor/phpstan/phpstan-doctrine/extension.neon
    - vendor/phpstan/phpstan-doctrine/rules.neon

parameters:
    level: 8

    doctrine:
        queryBuilderClass: Doctrine\ORM\QueryBuilder
        repositoryClass: Doctrine\ORM\EntityRepository
        objectManagerLoader: tests/object-manager.php
        allCollectionsSelectable: true
```

```php
<?php
// tests/object-manager.php

use Doctrine\ORM\EntityManager;
use Doctrine\ORM\Tools\Setup;

require_once __DIR__ . '/../vendor/autoload.php';

$paths = [__DIR__ . '/../src/Entity'];
$isDevMode = true;

$dbParams = [
    'driver' => 'pdo_sqlite',
    'memory' => true,
];

$config = Setup::createAttributeConfiguration($paths, $isDevMode);

return EntityManager::create($dbParams, $config);
```

### WordPress Integration
```bash
# Install WordPress extensions
composer require --dev szepeviktor/phpstan-wordpress
composer require --dev php-stubs/wordpress-stubs
```

```neon
# phpstan.neon
includes:
    - vendor/szepeviktor/phpstan-wordpress/extension.neon

parameters:
    level: 8

    paths:
        - wp-content/plugins/my-plugin
        - wp-content/themes/my-theme

    excludePaths:
        - wp-content/plugins/my-plugin/vendor/*

    bootstrapFiles:
        - vendor/php-stubs/wordpress-stubs/wordpress-stubs.php

    wordpress:
        constantsFile: wordpress-constants.php
```

## CI/CD Integration

### GitHub Actions
```yaml
# .github/workflows/phpstan.yml
name: PHPStan Analysis

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  phpstan:
    name: PHPStan Static Analysis
    runs-on: ubuntu-latest

    strategy:
      matrix:
        php-version: ['8.1', '8.2', '8.3']

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php-version }}
          coverage: none
          extensions: mbstring, pdo, pdo_mysql
          tools: composer:v2

      - name: Get Composer cache directory
        id: composer-cache
        run: echo "dir=$(composer config cache-files-dir)" >> $GITHUB_OUTPUT

      - name: Cache Composer dependencies
        uses: actions/cache@v3
        with:
          path: ${{ steps.composer-cache.outputs.dir }}
          key: ${{ runner.os }}-composer-${{ hashFiles('**/composer.lock') }}
          restore-keys: ${{ runner.os }}-composer-

      - name: Install dependencies
        run: composer install --prefer-dist --no-progress --no-suggest

      - name: Run PHPStan
        run: vendor/bin/phpstan analyse --error-format=github --no-progress

      - name: Run PHPStan with memory limit
        if: failure()
        run: vendor/bin/phpstan analyse --memory-limit=2G --error-format=github

  phpstan-baseline-check:
    name: Check PHPStan Baseline
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'

      - name: Install dependencies
        run: composer install --prefer-dist --no-progress

      - name: Generate new baseline
        run: vendor/bin/phpstan analyse --generate-baseline=phpstan-baseline-new.neon

      - name: Compare baselines
        run: |
          if ! diff -q phpstan-baseline.neon phpstan-baseline-new.neon; then
            echo "::warning::Baseline has changed. Please review and update if needed."
            diff phpstan-baseline.neon phpstan-baseline-new.neon || true
          fi
```

### GitLab CI
```yaml
# .gitlab-ci.yml
variables:
  COMPOSER_CACHE_DIR: "$CI_PROJECT_DIR/.composer-cache"

cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - .composer-cache/
    - vendor/

phpstan:
  stage: test
  image: php:8.2-cli

  before_script:
    - apt-get update && apt-get install -y git unzip
    - curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    - composer install --prefer-dist --no-progress --no-interaction

  script:
    - vendor/bin/phpstan analyse --error-format=gitlab --no-progress > phpstan-report.json

  artifacts:
    reports:
      codequality: phpstan-report.json
    when: always
    expire_in: 1 week

phpstan:strict:
  stage: test
  image: php:8.2-cli

  before_script:
    - apt-get update && apt-get install -y git unzip
    - curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    - composer install --prefer-dist --no-progress --no-interaction

  script:
    - vendor/bin/phpstan analyse --level=max --no-progress

  allow_failure: true
  only:
    - merge_requests
```

### Jenkins Pipeline
```groovy
// Jenkinsfile
pipeline {
    agent any

    environment {
        COMPOSER_HOME = "${WORKSPACE}/.composer"
    }

    stages {
        stage('Install Dependencies') {
            steps {
                sh 'composer install --prefer-dist --no-progress --no-interaction'
            }
        }

        stage('PHPStan Analysis') {
            steps {
                script {
                    def phpstanStatus = sh(
                        script: 'vendor/bin/phpstan analyse --error-format=checkstyle --no-progress > phpstan-report.xml',
                        returnStatus: true
                    )

                    // Publish Checkstyle report
                    recordIssues(
                        tools: [checkStyle(pattern: 'phpstan-report.xml')],
                        qualityGates: [[threshold: 1, type: 'TOTAL', unstable: true]]
                    )

                    if (phpstanStatus != 0) {
                        unstable('PHPStan found issues')
                    }
                }
            }
        }

        stage('PHPStan Strict Check') {
            when {
                branch 'main'
            }
            steps {
                sh 'vendor/bin/phpstan analyse --level=max --no-progress'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'phpstan-report.xml', allowEmptyArchive: true
        }

        failure {
            emailext(
                subject: "PHPStan Analysis Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "PHPStan analysis failed. Check ${env.BUILD_URL} for details.",
                to: "${env.CHANGE_AUTHOR_EMAIL}"
            )
        }
    }
}
```

## IDE Integration

### PHPStorm Configuration
```xml
<!-- .idea/phpstan.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="PHPStanConfiguration">
    <config_path>$PROJECT_DIR$/phpstan.neon</config_path>
    <level>8</level>
    <paths>
      <path>$PROJECT_DIR$/src</path>
      <path>$PROJECT_DIR$/tests</path>
    </paths>
    <excluded_paths>
      <path>$PROJECT_DIR$/vendor</path>
    </excluded_paths>
    <memory_limit>1G</memory_limit>
    <autoload_file>$PROJECT_DIR$/vendor/autoload.php</autoload_file>
  </component>
</project>
```

### VS Code Configuration
```json
// .vscode/settings.json
{
  "phpstan.enabled": true,
  "phpstan.level": "8",
  "phpstan.configFile": "./phpstan.neon",
  "phpstan.memoryLimit": "1G",
  "phpstan.paths": {
    "phpstan": "./vendor/bin/phpstan"
  },
  "phpstan.options": [
    "--no-progress",
    "--error-format=raw"
  ],
  "phpstan.suppressTimeoutMessage": false,

  // Enable on save
  "phpstan.enableOnSave": true,

  // Show inline errors
  "phpstan.enableInlineErrors": true
}
```

```json
// .vscode/extensions.json
{
  "recommendations": [
    "swordev.phpstan",
    "bmewburn.vscode-intelephense-client"
  ]
}
```

### VS Code Tasks
```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "PHPStan Analyze",
      "type": "shell",
      "command": "./vendor/bin/phpstan",
      "args": ["analyse", "--no-progress"],
      "group": {
        "kind": "test",
        "isDefault": true
      },
      "presentation": {
        "reveal": "always",
        "panel": "new"
      },
      "problemMatcher": {
        "owner": "phpstan",
        "fileLocation": ["relative", "${workspaceFolder}"],
        "pattern": {
          "regexp": "^(.*):(\\d+):(.*)$",
          "file": 1,
          "line": 2,
          "message": 3
        }
      }
    },
    {
      "label": "PHPStan Generate Baseline",
      "type": "shell",
      "command": "./vendor/bin/phpstan",
      "args": ["analyse", "--generate-baseline"]
    }
  ]
}
```

## Ignoring Errors Strategically

### Inline Ignores
```php
<?php

class IgnoreExample
{
    public function legacyMethod()
    {
        // Ignore specific error on next line
        /** @phpstan-ignore-next-line */
        $result = $this->undefinedMethod();

        // Ignore with reason
        /** @phpstan-ignore-next-line Call to undefined method for legacy support */
        $legacy = $this->oldApi();

        // Ignore multiple lines
        /**
         * @phpstan-ignore-next-line
         */
        $value = $unknown->property;
    }

    /**
     * @phpstan-ignore-next-line Return type mismatch intentional
     */
    public function intentionalTypeMismatch(): string
    {
        return 123; // Intentionally returning int
    }

    // Ignore entire method
    /**
     * @phpstan-ignore-method
     */
    public function complexLegacyLogic()
    {
        // Complex code that can't be analyzed
    }
}
```

### Configuration-Based Ignores
```neon
parameters:
    # Ignore by error message pattern
    ignoreErrors:
        # Simple pattern
        - '#Call to an undefined method [a-zA-Z0-9\\_]+::magicMethod\(\)#'

        # Ignore in specific file
        -
            message: '#Access to an undefined property#'
            path: src/Legacy/DynamicProperties.php

        # Ignore in multiple paths
        -
            message: '#Parameter \#1 \$user of method#'
            paths:
                - src/Legacy/*
                - src/External/ThirdParty/*

        # Ignore with count (fails if count changes)
        -
            message: '#should return App\\Entity\\User but returns App\\Entity\\User\|null#'
            count: 3
            path: src/Service/UserService.php

        # Ignore specific identifier
        -
            identifier: argument.type
            path: src/Legacy/*

        # Complex regex pattern
        -
            message: "#^Call to method [a-zA-Z]+\\(\\) on an unknown class Doctrine\\\\\\\\ORM\\\\\\\\[a-zA-Z]+\\.$#"
            path: src/Repository/*

    # Report unmatched ignored errors (recommended)
    reportUnmatchedIgnoredErrors: true
```

### Strategic Ignore Practices
```neon
# phpstan-ignores.neon
# Separate file for ignores - better maintainability

parameters:
    ignoreErrors:
        # Third-party library issues
        -
            message: '#Unsafe usage of new static#'
            path: vendor/external/library/*

        # Known framework limitations
        -
            message: '#Cannot call method.*on mixed#'
            paths:
                - src/Controller/*
            count: 15 # Track count to notice when it changes

        # Temporary ignores for refactoring
        -
            identifier: phpstan.temporaryIgnore
            message: '#Missing return type#'
            path: src/Legacy/ToRefactor.php
            # TODO: Remove after refactoring sprint 2024-Q1
```

## Performance Optimization

### Large Codebase Optimization
```neon
parameters:
    # Parallel processing
    parallel:
        jobSize: 20                    # Files per job
        maximumNumberOfProcesses: 32   # Max parallel processes
        minimumNumberOfJobsPerProcess: 2
        processTimeout: 300.0          # 5 minutes timeout

    # Memory management
    memoryLimit: 2G

    # Disable expensive checks for large codebases
    checkMissingIterableValueType: false
    checkGenericClassInNonGenericObjectType: false
    checkBenevolentUnionTypes: false

    # Result cache
    resultCachePath: %currentWorkingDirectory%/tmp/phpstan
    tmpDir: %currentWorkingDirectory%/tmp/phpstan

    # Exclude vendor from full analysis
    excludePaths:
        analyseAndScan:
            - vendor/*
        analyse:
            - tests/Fixtures/*

    # Scan fewer directories
    scanDirectories:
        - src/Entity
        - src/ValueObject

    # Limit stub files
    stubFiles:
        - stubs/critical-library.stub
```

### Incremental Analysis
```bash
# Use result cache
./vendor/bin/phpstan analyse --memory-limit=2G

# Clear cache when needed
./vendor/bin/phpstan clear-result-cache

# Analyze only changed files (with git)
git diff --name-only --diff-filter=ACMR HEAD | grep '\.php$' | xargs -r ./vendor/bin/phpstan analyse

# Analyze specific paths
./vendor/bin/phpstan analyse src/Controller src/Service
```

### Docker Performance Optimization
```dockerfile
# Dockerfile.phpstan
FROM php:8.2-cli-alpine

# Install dependencies
RUN apk add --no-cache git

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /app

# Copy composer files
COPY composer.json composer.lock ./

# Install dependencies with optimizations
RUN composer install \
    --no-dev \
    --no-scripts \
    --no-progress \
    --optimize-autoloader \
    --classmap-authoritative

# Copy application
COPY . .

# Pre-generate result cache
RUN vendor/bin/phpstan analyse --no-progress || true

# Set entrypoint
ENTRYPOINT ["vendor/bin/phpstan"]
CMD ["analyse", "--no-progress"]
```

## Bleeding Edge Features

### Enable Bleeding Edge
```neon
# phpstan.neon
includes:
    - vendor/phpstan/phpstan/conf/bleedingEdge.neon

parameters:
    level: max

    # Individual bleeding edge features (as of 1.10+)
    featureToggles:
        bleedingEdge: true

        # Specific features
        disableRuntimeReflectionProvider: true
        closureDefaultParameterTypeRule: true
        readOnlyByPhpDocType: true
        stricterFunctionMap: true
```

### New Type System Features
```php
<?php

// Readonly properties (PHP 8.1+)
class ReadonlyExample
{
    public function __construct(
        public readonly string $id,
        public readonly DateTimeImmutable $createdAt,
    ) {}
}

// Enums with PHPStan
enum Status: string
{
    case PENDING = 'pending';
    case APPROVED = 'approved';
    case REJECTED = 'rejected';

    public function isApproved(): bool
    {
        return $this === self::APPROVED;
    }
}

// Intersection types
interface Timestampable
{
    public function getCreatedAt(): DateTimeInterface;
}

interface Identifiable
{
    public function getId(): string;
}

function process(Timestampable&Identifiable $entity): void
{
    // PHPStan knows $entity has both interfaces
    $entity->getId();
    $entity->getCreatedAt();
}

// Never type
function terminate(): never
{
    exit(1);
}

// Disjunctive Normal Form (DNF) types
function complex((A&B)|C $param): void
{
    // Complex type handling
}
```

## PHPStan Extensions Ecosystem

### Popular Extensions
```bash
# Deprecation rules
composer require --dev phpstan/phpstan-deprecation-rules

# Strict rules
composer require --dev phpstan/phpstan-strict-rules

# PHPUnit support
composer require --dev phpstan/phpstan-phpunit

# Mockery support
composer require --dev phpstan/phpstan-mockery

# Beberlei Assert
composer require --dev phpstan/phpstan-beberlei-assert

# Webmozart Assert
composer require --dev phpstan/phpstan-webmozart-assert
```

```neon
# phpstan.neon with extensions
includes:
    - vendor/phpstan/phpstan-deprecation-rules/rules.neon
    - vendor/phpstan/phpstan-strict-rules/rules.neon
    - vendor/phpstan/phpstan-phpunit/extension.neon
    - vendor/phpstan/phpstan-mockery/extension.neon

parameters:
    level: 8

    strictRules:
        allRules: false
        booleansInConditions: true
        uselessCast: true
        requireParentConstructorCall: true
        disallowedLooseComparison: true

    deprecationRules:
        deprecationsThrowException: false
```

### Community Extensions
```bash
# API Platform
composer require --dev api-platform/phpstan-extension

# Laravel IDE Helper
composer require --dev barryvdh/laravel-ide-helper

# PhpSpec
composer require --dev phpstan/phpstan-phpspec

# Infection
composer require --dev infection/infection

# Rector
composer require --dev rector/rector
```

## Type Coverage Analysis

### Measure Type Coverage
```bash
# Install type coverage tool
composer require --dev tomasvotruba/type-coverage

# Run type coverage analysis
vendor/bin/type-coverage --json
```

```php
<?php
// Type coverage example

// Poor type coverage (0%)
class PoorCoverage
{
    private $id;
    private $name;

    public function __construct($id, $name)
    {
        $this->id = $id;
        $this->name = $name;
    }

    public function process($data)
    {
        return $data;
    }
}

// Good type coverage (100%)
class GoodCoverage
{
    private int $id;
    private string $name;

    public function __construct(int $id, string $name)
    {
        $this->id = $id;
        $this->name = $name;
    }

    public function process(array $data): array
    {
        return $data;
    }
}
```

### Custom Type Coverage Configuration
```neon
# phpstan.neon
parameters:
    level: 8

    # Require return type declarations
    checkMissingCallableSignature: true

    # Check union types
    checkUnionTypes: true

    # Report missing types
    reportMaybesInMethodSignatures: true
    reportStaticMethodSignatures: true

    # PHPDoc validation
    reportWrongPhpDocTypeInVarTag: true
    reportAnyTypeWideningInVarTag: true
```

## Migration from Other Tools

### From Psalm
```bash
# Convert Psalm config to PHPStan
# Psalm configuration
cat > psalm.xml << 'XML'
<?xml version="1.0"?>
<psalm errorLevel="3">
    <projectFiles>
        <directory name="src"/>
    </projectFiles>
</psalm>
XML

# Equivalent PHPStan configuration
cat > phpstan.neon << 'NEON'
parameters:
    level: 7  # Psalm level 3 ≈ PHPStan level 7
    paths:
        - src
NEON
```

### From Phan
```php
<?php
// .phan/config.php

return [
    'target_php_version' => '8.1',
    'directory_list' => ['src', 'vendor'],
    'exclude_analysis_directory_list' => ['vendor'],
];
```

```neon
# Equivalent phpstan.neon
parameters:
    phpVersion: 80100
    paths:
        - src
    excludePaths:
        - vendor/*
    level: 6
```

### Migration Strategy
```bash
# 1. Install PHPStan alongside existing tool
composer require --dev phpstan/phpstan

# 2. Run both tools in parallel
./vendor/bin/psalm --report=psalm-report.json
./vendor/bin/phpstan analyse --error-format=json > phpstan-report.json

# 3. Compare results
php compare-results.php psalm-report.json phpstan-report.json

# 4. Generate baseline for PHPStan
./vendor/bin/phpstan analyse --generate-baseline

# 5. Gradually fix issues and remove baseline
./vendor/bin/phpstan analyse --generate-baseline=new-baseline.neon
diff phpstan-baseline.neon new-baseline.neon

# 6. Remove old tool
composer remove --dev vimeo/psalm
```

## Pros and Cons

### Pros

1. **No Code Execution Required**
   - Analyzes code statically without running it
   - Safe to run on untrusted code
   - No need for complete runtime environment

2. **Exceptional Type Inference**
   - Advanced type inference engine
   - Understands complex type relationships
   - Supports generics and templates

3. **Framework Integration**
   - Extensive framework support (Laravel, Symfony, Doctrine)
   - Custom extensions for popular libraries
   - Active community creating new extensions

4. **Incremental Adoption**
   - 10 strictness levels (0-9)
   - Baseline support for legacy projects
   - Can start at level 0 and gradually increase

5. **Fast Performance**
   - Result caching for speed
   - Parallel processing support
   - Efficient memory usage

6. **Excellent Documentation**
   - Comprehensive user guide
   - Clear error messages
   - Active community support

7. **CI/CD Friendly**
   - Multiple output formats
   - Easy integration with pipelines
   - Exit codes for pass/fail detection

### Cons

1. **Learning Curve**
   - Advanced features require PHPDoc knowledge
   - Generics syntax can be complex
   - Type system nuances take time to master

2. **Configuration Complexity**
   - NEON format may be unfamiliar
   - Many configuration options to understand
   - Requires tuning for large projects

3. **False Positives**
   - May report issues in valid code
   - Dynamic PHP features hard to analyze
   - Magic methods need explicit documentation

4. **Performance on Large Codebases**
   - Can be slow on very large projects
   - Memory intensive for complex analysis
   - May require configuration tuning

5. **Limited Runtime Checks**
   - Cannot detect runtime-specific issues
   - No actual test execution
   - Logic errors may go undetected

## Common Pitfalls

### 1. Not Using Baseline Properly
```bash
# Wrong: Ignoring all errors permanently
./vendor/bin/phpstan analyse --generate-baseline
git add phpstan-baseline.neon
git commit -m "Add baseline"
# Then forgetting about it

# Right: Using baseline temporarily and reducing it
./vendor/bin/phpstan analyse --generate-baseline
# Fix issues gradually
./vendor/bin/phpstan analyse --generate-baseline
# Compare and track reduction
```

### 2. Ignoring Errors Without Understanding
```php
<?php

// Wrong: Blindly ignoring without investigation
/** @phpstan-ignore-next-line */
$result = $user->process();

// Right: Document reason and plan to fix
/**
 * @phpstan-ignore-next-line Temporary ignore - User::process() return type will be fixed in #1234
 * TODO: Remove this ignore after PR #1234 is merged
 */
$result = $user->process();
```

### 3. Starting at Too High Level
```neon
# Wrong: Starting new project at level max immediately
parameters:
    level: max

# Right: Start reasonable and increase gradually
parameters:
    level: 6  # Start here
    # TODO: Increase to 7 after fixing property types
    # TODO: Increase to 8 after fixing nullable handling
```

### 4. Not Using Type Hints
```php
<?php

// Wrong: Relying on PHPDoc only
class BadPractice
{
    /** @var string */
    private $name;

    /** @param string $name */
    public function setName($name)
    {
        $this->name = $name;
    }
}

// Right: Use native type hints
class GoodPractice
{
    private string $name;

    public function setName(string $name): void
    {
        $this->name = $name;
    }
}
```

### 5. Incorrect Generic Annotations
```php
<?php

// Wrong: Invalid generic syntax
/** @return Collection<User> */
public function getUsers(): Collection
{
    return new Collection($this->users);
}

// Right: Proper generic syntax
/** @return Collection<int, User> */
public function getUsers(): Collection
{
    return new Collection($this->users);
}
```

### 6. Missing Null Checks
```php
<?php

// Wrong: Not handling nullable types
public function process(?User $user): string
{
    return $user->getName(); // PHPStan error
}

// Right: Check for null
public function process(?User $user): string
{
    if ($user === null) {
        return 'Unknown';
    }

    return $user->getName();
}

// Alternative: Use null-safe operator (PHP 8.0+)
public function process(?User $user): ?string
{
    return $user?->getName();
}
```

### 7. Over-Complicating Types
```php
<?php

// Wrong: Overly complex types
/**
 * @param array<int, array{id: int, name: string, tags: array<int, string>, meta: array<string, mixed>}> $data
 */
public function process(array $data): void
{
    // Complex type hard to maintain
}

// Right: Use value objects
public function process(UserData ...$users): void
{
    // Clear and maintainable
}

class UserData
{
    public int $id;
    public string $name;
    /** @var array<int, string> */
    public array $tags;
    /** @var array<string, mixed> */
    public array $meta;
}
```

### 8. Not Leveraging Assertions
```php
<?php

// Wrong: Casting without assertion
public function process(mixed $value): string
{
    return (string) $value; // Unsafe cast
}

// Right: Use assertions
public function process(mixed $value): string
{
    assert(is_string($value));
    return $value; // PHPStan knows it's string
}

// Better: Type guard method
/**
 * @phpstan-assert string $value
 */
private function assertString(mixed $value): void
{
    if (!is_string($value)) {
        throw new InvalidArgumentException('Expected string');
    }
}

public function process(mixed $value): string
{
    $this->assertString($value);
    return $value;
}
```

### 9. Ignoring Configuration Options
```neon
# Wrong: Minimal configuration
parameters:
    level: 8
    paths:
        - src

# Right: Comprehensive configuration
parameters:
    level: 8
    paths:
        - src
        - tests

    excludePaths:
        - src/Migrations/*

    checkMissingIterableValueType: true
    checkGenericClassInNonGenericObjectType: true
    reportUnmatchedIgnoredErrors: true

    parallel:
        maximumNumberOfProcesses: 4
```

### 10. Not Testing Configuration Changes
```bash
# Wrong: Changing config without testing
vim phpstan.neon  # Make changes
git commit -m "Update PHPStan config"

# Right: Test before committing
vim phpstan.neon  # Make changes
./vendor/bin/phpstan analyse  # Verify it works
./vendor/bin/phpstan analyse --level=max  # Test stricter level
git commit -m "Update PHPStan config"
```

## Real-World Examples

### API Response Handling
```php
<?php

namespace App\Service;

use App\DTO\ApiResponse;
use GuzzleHttp\Client;
use GuzzleHttp\Exception\GuzzleException;

class ApiService
{
    private Client $client;

    public function __construct(Client $client)
    {
        $this->client = $client;
    }

    /**
     * @return ApiResponse<User>
     * @throws ApiException
     */
    public function getUser(int $id): ApiResponse
    {
        try {
            $response = $this->client->get("/api/users/{$id}");
            $data = json_decode($response->getBody()->getContents(), true);

            if (!is_array($data)) {
                throw new ApiException('Invalid response format');
            }

            return ApiResponse::success($this->hydrateUser($data));
        } catch (GuzzleException $e) {
            throw new ApiException('Failed to fetch user', 0, $e);
        }
    }

    /**
     * @param array<string, mixed> $data
     */
    private function hydrateUser(array $data): User
    {
        return new User(
            id: $data['id'] ?? throw new ApiException('Missing user ID'),
            name: $data['name'] ?? throw new ApiException('Missing user name'),
            email: $data['email'] ?? throw new ApiException('Missing user email')
        );
    }
}

/**
 * @template T
 */
class ApiResponse
{
    /**
     * @param T $data
     */
    private function __construct(
        private mixed $data,
        private bool $success,
        private ?string $error = null
    ) {}

    /**
     * @template U
     * @param U $data
     * @return self<U>
     */
    public static function success(mixed $data): self
    {
        return new self($data, true);
    }

    /**
     * @return self<null>
     */
    public static function error(string $error): self
    {
        return new self(null, false, $error);
    }

    /**
     * @return T
     */
    public function getData(): mixed
    {
        if (!$this->success) {
            throw new \RuntimeException('Cannot get data from error response');
        }

        return $this->data;
    }
}
```

### Repository Pattern with Doctrine
```php
<?php

namespace App\Repository;

use App\Entity\Product;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<Product>
 *
 * @method Product|null find($id, $lockMode = null, $lockVersion = null)
 * @method Product|null findOneBy(array $criteria, array $orderBy = null)
 * @method Product[]    findAll()
 * @method Product[]    findBy(array $criteria, array $orderBy = null, $limit = null, $offset = null)
 */
class ProductRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Product::class);
    }

    /**
     * @return array<Product>
     */
    public function findActiveProducts(): array
    {
        return $this->createQueryBuilder('p')
            ->where('p.active = :active')
            ->setParameter('active', true)
            ->orderBy('p.createdAt', 'DESC')
            ->getQuery()
            ->getResult();
    }

    /**
     * @param positive-int $categoryId
     * @return array<Product>
     */
    public function findByCategory(int $categoryId): array
    {
        return $this->createQueryBuilder('p')
            ->innerJoin('p.category', 'c')
            ->where('c.id = :categoryId')
            ->setParameter('categoryId', $categoryId)
            ->getQuery()
            ->getResult();
    }
}
```

## Best Practices Summary

1. **Start with appropriate level**: Begin at level 0-5 for legacy projects, 6-8 for established projects, max for new projects

2. **Use baselines strategically**: Generate baseline for legacy code, track reduction over time, never commit to permanent ignores

3. **Leverage native type hints**: Prefer native PHP type hints over PHPDoc when possible

4. **Write comprehensive PHPDoc**: Use PHPDoc for generics, complex types, and additional context

5. **Configure for your project**: Tune parallel processing, memory limits, and strictness for optimal performance

6. **Integrate with CI/CD**: Run PHPStan on every commit, fail builds on new errors, track metrics over time

7. **Use framework extensions**: Install official extensions for frameworks you use

8. **Document ignores**: Always add context when ignoring errors, include ticket numbers for planned fixes

9. **Regular maintenance**: Update PHPStan regularly, review and reduce baseline, increase strictness gradually

10. **Team adoption**: Train team on type system, review PHPStan errors in code reviews, celebrate reduction in error count

## Conclusion

PHPStan is a powerful static analysis tool that brings type safety to PHP. Its sophisticated type inference engine, extensive framework support, and incremental adoption model make it suitable for projects of any size and age. By catching bugs before runtime, improving code quality, and providing excellent IDE integration, PHPStan significantly enhances the PHP development experience.

The key to success with PHPStan is gradual adoption - start at a comfortable strictness level, use baselines for legacy code, and progressively increase rigor as you refactor and improve your codebase. Combined with proper configuration, CI/CD integration, and team training, PHPStan becomes an invaluable tool in maintaining high-quality PHP applications.

For teams serious about code quality, PHPStan is not just a linting tool but a fundamental part of the development workflow that pays dividends through reduced bugs, improved maintainability, and better developer experience.
