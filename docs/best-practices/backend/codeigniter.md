# CodeIgniter 4 - PHP Web Framework Best Practices

## Official Documentation
- [CodeIgniter 4 Documentation](https://codeigniter.com/user_guide/)
- [CodeIgniter 4 GitHub](https://github.com/codeigniter4/CodeIgniter4)
- [CodeIgniter 4 Community](https://forum.codeigniter.com/)

## Project Structure

```
app/
├── Config/          # Configuration files
│   ├── App.php
│   ├── Database.php
│   ├── Routes.php
│   └── Validation.php
├── Controllers/     # Request handlers
├── Models/         # Data access layer
├── Views/          # Presentation templates
├── Filters/        # Request/response filters
├── Helpers/        # Custom helper functions
├── Libraries/      # Custom libraries
├── Language/       # Localization files
├── Database/       # Database migrations and seeds
│   ├── Migrations/
│   └── Seeds/
├── Commands/       # CLI commands
└── ThirdParty/     # Third-party packages
public/
├── index.php       # Entry point
├── .htaccess       # Apache rewrite rules
├── css/
├── js/
└── images/
writable/
├── cache/          # Cache files
├── logs/           # Application logs
├── session/        # Session storage
└── uploads/        # File uploads
system/             # Framework core (don't modify)
vendor/             # Composer dependencies
```

## Core Best Practices

### 1. Configuration Management
```php
// app/Config/App.php
<?php
namespace Config;

use CodeIgniter\Config\BaseConfig;

class App extends BaseConfig
{
    // Use environment-specific configs
    public $baseURL = 'http://localhost:8080/';
    
    // Security settings
    public $CSRFTokenName  = 'csrf_token_name';
    public $CSRFHeaderName = 'X-Requested-With';
    public $CSRFProtection = true;
    
    // Enable HTTPS only in production
    public $forceGlobalSecureRequests = false;
}
```

### 2. Database Configuration
```php
// app/Config/Database.php
<?php
namespace Config;

use CodeIgniter\Database\Config;

class Database extends Config
{
    public $default = [
        'DSN'      => '',
        'hostname' => 'localhost',
        'username' => '',
        'password' => '',
        'database' => '',
        'DBDriver' => 'MySQLi',
        'DBPrefix' => '',
        'pConnect' => false,
        'DBDebug'  => (ENVIRONMENT !== 'production'),
        'charset'  => 'utf8mb4',
        'DBCollat' => 'utf8mb4_general_ci',
        'swapPre'  => '',
        'encrypt'  => false,
        'compress' => false,
        'strictOn' => false,
    ];
}
```

### 3. Model Best Practices
```php
// app/Models/UserModel.php
<?php
namespace App\Models;

use CodeIgniter\Model;

class UserModel extends Model
{
    protected $table = 'users';
    protected $primaryKey = 'id';
    protected $returnType = 'array';
    protected $useSoftDeletes = true;
    
    // Allowed fields for mass assignment
    protected $allowedFields = [
        'name', 'email', 'password', 'role'
    ];
    
    // Validation rules
    protected $validationRules = [
        'name'     => 'required|min_length[3]|max_length[255]',
        'email'    => 'required|valid_email|is_unique[users.email]',
        'password' => 'required|min_length[8]'
    ];
    
    // Timestamps
    protected $useTimestamps = true;
    protected $createdField  = 'created_at';
    protected $updatedField  = 'updated_at';
    protected $deletedField  = 'deleted_at';
    
    // Callbacks
    protected $beforeInsert = ['hashPassword'];
    protected $beforeUpdate = ['hashPassword'];
    
    protected function hashPassword(array $data)
    {
        if (isset($data['data']['password'])) {
            $data['data']['password'] = password_hash($data['data']['password'], PASSWORD_DEFAULT);
        }
        return $data;
    }
    
    // Custom methods
    public function findByEmail(string $email)
    {
        return $this->where('email', $email)->first();
    }
}
```

### 4. Controller Structure
```php
// app/Controllers/UserController.php
<?php
namespace App\Controllers;

use App\Models\UserModel;
use CodeIgniter\RESTful\ResourceController;

class UserController extends ResourceController
{
    protected $modelName = 'App\Models\UserModel';
    protected $format    = 'json';
    
    public function index()
    {
        $data = $this->model->findAll();
        
        return $this->respond([
            'status' => 'success',
            'data'   => $data
        ]);
    }
    
    public function show($id = null)
    {
        $data = $this->model->find($id);
        
        if (!$data) {
            return $this->failNotFound('User not found');
        }
        
        return $this->respond([
            'status' => 'success',
            'data'   => $data
        ]);
    }
    
    public function create()
    {
        $rules = [
            'name'     => 'required|min_length[3]|max_length[255]',
            'email'    => 'required|valid_email|is_unique[users.email]',
            'password' => 'required|min_length[8]'
        ];
        
        if (!$this->validate($rules)) {
            return $this->fail($this->validator->getErrors());
        }
        
        $data = $this->request->getJSON(true);
        
        $userId = $this->model->insert($data);
        
        if (!$userId) {
            return $this->failServerError('Failed to create user');
        }
        
        return $this->respondCreated([
            'status' => 'success',
            'message' => 'User created successfully',
            'data' => ['id' => $userId]
        ]);
    }
}
```

### 5. Route Configuration
```php
// app/Config/Routes.php
<?php

use CodeIgniter\Router\RouteCollection;

/**
 * @var RouteCollection $routes
 */
$routes->get('/', 'Home::index');

// API routes with versioning
$routes->group('api/v1', ['namespace' => 'App\Controllers\API\V1'], function($routes) {
    // Authentication routes
    $routes->post('login', 'AuthController::login');
    $routes->post('register', 'AuthController::register');
    
    // Protected routes
    $routes->group('', ['filter' => 'auth'], function($routes) {
        $routes->resource('users', ['controller' => 'UserController']);
        $routes->resource('posts', ['controller' => 'PostController']);
    });
});

// Admin routes
$routes->group('admin', ['filter' => 'admin'], function($routes) {
    $routes->get('dashboard', 'Admin\DashboardController::index');
    $routes->resource('users', ['controller' => 'Admin\UserController']);
});
```

### 6. Authentication Filter
```php
// app/Filters/AuthFilter.php
<?php
namespace App\Filters;

use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;
use CodeIgniter\Filters\FilterInterface;

class AuthFilter implements FilterInterface
{
    public function before(RequestInterface $request, $arguments = null)
    {
        $authHeader = $request->getServer('HTTP_AUTHORIZATION');
        
        if (!$authHeader) {
            return service('response')
                ->setJSON(['error' => 'Authorization header missing'])
                ->setStatusCode(401);
        }
        
        $token = substr($authHeader, 7); // Remove 'Bearer ' prefix
        
        // Validate JWT token
        $jwt = service('jwt');
        try {
            $payload = $jwt->decode($token);
            $request->user = $payload;
        } catch (\Exception $e) {
            return service('response')
                ->setJSON(['error' => 'Invalid token'])
                ->setStatusCode(401);
        }
    }
    
    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
        // Post-processing if needed
    }
}
```

### 7. Custom Helper Functions
```php
// app/Helpers/custom_helper.php
<?php

if (!function_exists('format_currency')) {
    function format_currency($amount, $currency = 'USD')
    {
        return number_format($amount, 2) . ' ' . $currency;
    }
}

if (!function_exists('is_ajax_request')) {
    function is_ajax_request()
    {
        return service('request')->isAJAX();
    }
}

if (!function_exists('generate_slug')) {
    function generate_slug(string $string): string
    {
        return url_title($string, '-', true);
    }
}
```

### 8. Database Migration
```php
// app/Database/Migrations/2023-01-01-000001_create_users_table.php
<?php
namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateUsersTable extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id' => [
                'type'           => 'INT',
                'constraint'     => 5,
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'name' => [
                'type'       => 'VARCHAR',
                'constraint' => '255',
            ],
            'email' => [
                'type'       => 'VARCHAR',
                'constraint' => '255',
                'unique'     => true,
            ],
            'password' => [
                'type'       => 'VARCHAR',
                'constraint' => '255',
            ],
            'role' => [
                'type'       => 'ENUM',
                'constraint' => ['user', 'admin'],
                'default'    => 'user',
            ],
            'created_at' => [
                'type' => 'DATETIME',
                'null' => true,
            ],
            'updated_at' => [
                'type' => 'DATETIME',
                'null' => true,
            ],
            'deleted_at' => [
                'type' => 'DATETIME',
                'null' => true,
            ],
        ]);
        
        $this->forge->addPrimaryKey('id');
        $this->forge->addKey('email');
        $this->forge->createTable('users');
    }
    
    public function down()
    {
        $this->forge->dropTable('users');
    }
}
```

### 9. Environment Configuration
```bash
# .env file
CI_ENVIRONMENT = development

app.baseURL = 'http://localhost:8080/'
app.sessionDriver = 'CodeIgniter\Session\Handlers\FileHandler'
app.sessionSavePath = null

database.default.hostname = localhost
database.default.database = your_database
database.default.username = your_username
database.default.password = your_password
database.default.DBDriver = MySQLi

logger.threshold = 4

# JWT Secret
JWT_SECRET = your-secret-key
JWT_ALGORITHM = HS256
JWT_EXPIRY = 3600
```

## Performance Optimization

### 1. Enable Caching
```php
// In controller
$cache = service('cache');

public function getData()
{
    $cacheKey = 'expensive_data';
    
    if (!$data = $cache->get($cacheKey)) {
        $data = $this->performExpensiveOperation();
        $cache->save($cacheKey, $data, 3600); // Cache for 1 hour
    }
    
    return $this->respond($data);
}
```

### 2. Database Query Optimization
```php
// Use query builder efficiently
$users = $this->db->table('users')
    ->select('id, name, email')
    ->where('active', 1)
    ->limit(10)
    ->get()
    ->getResultArray();

// Use eager loading for relationships
$posts = $this->postModel->with('users')->findAll();
```

## Security Best Practices

### 1. Input Validation
```php
// Always validate input
$validation = service('validation');
$validation->setRules([
    'email' => 'required|valid_email',
    'age'   => 'required|integer|greater_than[17]'
]);

if (!$validation->withRequest($this->request)->run()) {
    return $this->failValidationErrors($validation->getErrors());
}
```

### 2. SQL Injection Prevention
```php
// Use query builder or prepared statements
$users = $this->db->table('users')
    ->where('email', $email) // Automatically escaped
    ->get();

// Or with manual escaping
$sql = "SELECT * FROM users WHERE email = ?";
$users = $this->db->query($sql, [$email]);
```

### 3. CSRF Protection
```php
// In forms
echo form_open('contact', ['csrf_id' => 'my-form']);
echo csrf_field();
```

## Testing

### 1. Unit Testing
```php
// tests/unit/UserModelTest.php
<?php
namespace Tests\Unit;

use CodeIgniter\Test\CIUnitTestCase;
use CodeIgniter\Test\DatabaseTestTrait;
use App\Models\UserModel;

class UserModelTest extends CIUnitTestCase
{
    use DatabaseTestTrait;
    
    protected $migrate     = true;
    protected $migrateOnce = false;
    protected $refresh     = true;
    
    public function testCanCreateUser()
    {
        $model = new UserModel();
        
        $data = [
            'name'     => 'John Doe',
            'email'    => 'john@example.com',
            'password' => 'password123'
        ];
        
        $result = $model->insert($data);
        
        $this->assertNotFalse($result);
        $this->seeInDatabase('users', ['email' => 'john@example.com']);
    }
}
```

### 2. Feature Testing
```php
// tests/feature/AuthTest.php
<?php
namespace Tests\Feature;

use CodeIgniter\Test\CIUnitTestCase;
use CodeIgniter\Test\FeatureTestTrait;

class AuthTest extends CIUnitTestCase
{
    use FeatureTestTrait;
    
    public function testLoginWithValidCredentials()
    {
        $response = $this->post('/api/v1/login', [
            'email'    => 'user@example.com',
            'password' => 'password123'
        ]);
        
        $response->assertStatus(200);
        $response->assertJSONFragment(['status' => 'success']);
    }
}
```

## Common Pitfalls to Avoid

1. **Ignoring Environment Variables**: Always use .env for configuration
2. **Not Using Validation**: Always validate user input
3. **Direct Database Queries**: Use query builder or models
4. **Missing CSRF Protection**: Enable CSRF for forms
5. **Hardcoded Paths**: Use base_url() and site_url() helpers
6. **Not Using Migrations**: Version control your database schema
7. **Ignoring Error Handling**: Implement proper error handling
8. **Missing Input Sanitization**: Always sanitize user input
9. **Not Using Filters**: Implement authentication and authorization filters
10. **Poor Session Management**: Configure sessions properly

## Useful Packages

- **CodeIgniter Shield**: Authentication and authorization
- **CodeIgniter Settings**: Application settings management
- **Tatter\Audits**: Database change auditing
- **CodeIgniter Queue**: Background job processing
- **Tatter\Files**: File management utilities

## Deployment Checklist

- [ ] Set `CI_ENVIRONMENT` to `production`
- [ ] Enable HTTPS and set `forceGlobalSecureRequests = true`
- [ ] Configure proper error logging
- [ ] Set up database backups
- [ ] Configure caching (Redis/Memcached)
- [ ] Optimize composer autoloader (`composer install --optimize-autoloader --no-dev`)
- [ ] Set proper file permissions
- [ ] Configure web server security headers
- [ ] Enable CSRF protection
- [ ] Set up monitoring and logging