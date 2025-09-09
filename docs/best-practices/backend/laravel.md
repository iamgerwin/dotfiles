# Laravel Best Practices

## Official Documentation
- **Laravel Documentation**: https://laravel.com/docs
- **Laravel API Reference**: https://laravel.com/api/10.x/
- **Laracasts**: https://laracasts.com
- **Laravel News**: https://laravel-news.com

## Project Structure

```
project-root/
├── app/
│   ├── Console/
│   │   └── Commands/           # Custom Artisan commands
│   ├── Exceptions/
│   │   └── Handler.php         # Global exception handling
│   ├── Http/
│   │   ├── Controllers/        # HTTP controllers
│   │   │   ├── Api/           # API controllers
│   │   │   └── Web/           # Web controllers
│   │   ├── Middleware/         # HTTP middleware
│   │   ├── Requests/          # Form request validation
│   │   └── Resources/         # API resources (transformers)
│   ├── Models/                # Eloquent models
│   ├── Observers/             # Model observers
│   ├── Policies/              # Authorization policies
│   ├── Providers/             # Service providers
│   ├── Repositories/          # Repository pattern (optional)
│   ├── Services/              # Business logic services
│   ├── Traits/                # Reusable traits
│   └── View/
│       └── Components/        # Blade components
├── bootstrap/
│   ├── app.php               # Bootstrap the framework
│   └── cache/                # Framework bootstrap cache
├── config/                   # Configuration files
├── database/
│   ├── factories/           # Model factories
│   ├── migrations/          # Database migrations
│   └── seeders/            # Database seeders
├── lang/                    # Localization files
├── public/                  # Web server root
│   ├── index.php           # Application entry point
│   └── assets/             # Public assets (CSS, JS, images)
├── resources/
│   ├── css/                # Raw CSS files
│   ├── js/                 # Raw JavaScript files
│   └── views/              # Blade templates
├── routes/
│   ├── api.php            # API routes
│   ├── channels.php       # Broadcast channels
│   ├── console.php        # Console commands
│   └── web.php            # Web routes
├── storage/
│   ├── app/               # Application files
│   ├── framework/         # Framework files (cache, sessions)
│   └── logs/              # Application logs
├── tests/
│   ├── Feature/           # Feature tests
│   ├── Unit/              # Unit tests
│   └── TestCase.php       # Base test case
├── .env                   # Environment variables
├── .env.example          # Environment variables example
├── artisan               # Artisan CLI
├── composer.json         # PHP dependencies
├── package.json          # NPM dependencies
├── phpunit.xml          # PHPUnit configuration
└── vite.config.js       # Vite configuration
```

## Coding Standards

### PHP Standards
- Follow **PSR-12** coding standard
- Use **PHP 8.1+** features (typed properties, enums, etc.)
- Enable strict types: `declare(strict_types=1);`

### Naming Conventions
```php
// Controllers - singular, PascalCase with Controller suffix
class UserController extends Controller

// Models - singular, PascalCase
class User extends Model

// Migrations - snake_case with timestamp
2024_01_15_000000_create_users_table.php

// Requests - PascalCase with Request suffix
class StoreUserRequest extends FormRequest

// Services - PascalCase with Service suffix
class PaymentService

// Traits - PascalCase with descriptive name
trait HasRoles

// Methods - camelCase
public function getUserById(int $id): User

// Variables - camelCase
$userEmail = $user->email;

// Constants - UPPER_SNAKE_CASE
const MAX_LOGIN_ATTEMPTS = 5;
```

## Best Practices

### 1. Controllers
```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreUserRequest;
use App\Http\Resources\UserResource;
use App\Services\UserService;
use App\Models\User;

class UserController extends Controller
{
    public function __construct(
        private readonly UserService $userService
    ) {}

    // Keep controllers thin - delegate business logic to services
    public function store(StoreUserRequest $request): UserResource
    {
        $user = $this->userService->create($request->validated());
        
        return new UserResource($user);
    }

    // Use route model binding
    public function show(User $user): UserResource
    {
        $this->authorize('view', $user);
        
        return new UserResource($user->load('profile'));
    }
}
```

### 2. Models
```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;

class User extends Model
{
    use HasFactory, SoftDeletes;

    // Explicitly define table name
    protected $table = 'users';

    // Use fillable for mass assignment protection
    protected $fillable = [
        'name',
        'email',
        'password',
    ];

    // Hide sensitive attributes
    protected $hidden = [
        'password',
        'remember_token',
    ];

    // Cast attributes to native types
    protected $casts = [
        'email_verified_at' => 'datetime',
        'is_active' => 'boolean',
        'settings' => 'array',
    ];

    // Define relationships with return types
    public function posts(): HasMany
    {
        return $this->hasMany(Post::class);
    }

    // Use scopes for query reusability
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    // Accessors and mutators using Laravel 9+ syntax
    protected function firstName(): Attribute
    {
        return Attribute::make(
            get: fn ($value) => ucfirst($value),
            set: fn ($value) => strtolower($value),
        );
    }
}
```

### 3. Services
```php
<?php

namespace App\Services;

use App\Models\User;
use App\Repositories\UserRepository;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class UserService
{
    public function __construct(
        private readonly UserRepository $userRepository
    ) {}

    public function create(array $data): User
    {
        return DB::transaction(function () use ($data) {
            $data['password'] = Hash::make($data['password']);
            
            $user = $this->userRepository->create($data);
            
            // Additional business logic
            event(new UserCreated($user));
            
            return $user;
        });
    }
}
```

### 4. Form Requests
```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

class StoreUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', User::class);
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'],
            'password' => ['required', Password::defaults()],
            'role' => ['required', 'exists:roles,id'],
        ];
    }

    public function messages(): array
    {
        return [
            'email.unique' => 'This email address is already registered.',
        ];
    }
}
```

### 5. API Resources
```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'posts' => PostResource::collection($this->whenLoaded('posts')),
            'posts_count' => $this->whenCounted('posts'),
            'created_at' => $this->created_at->toISOString(),
        ];
    }
}
```

### 6. Migrations
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('posts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->text('content');
            $table->enum('status', ['draft', 'published'])->default('draft');
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
            
            $table->index(['user_id', 'status']);
            $table->index('published_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('posts');
    }
};
```

## Testing

### Unit Tests
```php
<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Services\UserService;
use App\Models\User;

class UserServiceTest extends TestCase
{
    public function test_can_create_user(): void
    {
        $service = app(UserService::class);
        
        $userData = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
        ];
        
        $user = $service->create($userData);
        
        $this->assertInstanceOf(User::class, $user);
        $this->assertEquals('John Doe', $user->name);
    }
}
```

### Feature Tests
```php
<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use Laravel\Sanctum\Sanctum;
use Illuminate\Foundation\Testing\RefreshDatabase;

class UserApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_get_user_list(): void
    {
        Sanctum::actingAs(User::factory()->create());
        
        User::factory()->count(5)->create();
        
        $response = $this->getJson('/api/users');
        
        $response->assertOk()
                 ->assertJsonCount(6, 'data')
                 ->assertJsonStructure([
                     'data' => [
                         '*' => ['id', 'name', 'email']
                     ]
                 ]);
    }
}
```

## Performance Optimization

### Query Optimization
```php
// Bad - N+1 problem
$users = User::all();
foreach ($users as $user) {
    echo $user->posts->count();
}

// Good - Eager loading
$users = User::with('posts')->get();

// Better - Lazy eager loading
$users = User::all();
$users->load('posts');

// Best - Count optimization
$users = User::withCount('posts')->get();
```

### Caching
```php
// Cache expensive queries
$users = Cache::remember('active-users', 3600, function () {
    return User::active()
               ->with('profile')
               ->get();
});

// Cache configuration and routes
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

### Database Indexing
```php
// In migration
$table->index('email');
$table->index(['status', 'created_at']);
$table->unique('slug');
```

## Security Best Practices

### Authentication & Authorization
```php
// Use policies for authorization
public function update(Request $request, Post $post)
{
    $this->authorize('update', $post);
    // ...
}

// Protect against mass assignment
protected $fillable = ['name', 'email'];
// or
protected $guarded = ['id', 'password'];

// Hash passwords
$user->password = Hash::make($request->password);

// Use prepared statements (automatic with Eloquent)
User::where('email', $email)->first();
```

### CSRF Protection
```blade
<!-- In forms -->
@csrf

<!-- In AJAX -->
$.ajaxSetup({
    headers: {
        'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
    }
});
```

## Error Handling

```php
// app/Exceptions/Handler.php
public function register(): void
{
    $this->reportable(function (Throwable $e) {
        if (app()->environment('production')) {
            // Send to error tracking service
        }
    });

    $this->renderable(function (NotFoundHttpException $e, $request) {
        if ($request->is('api/*')) {
            return response()->json([
                'message' => 'Resource not found'
            ], 404);
        }
    });
}
```

## Environment Configuration

### .env Best Practices
```env
# Application
APP_NAME="My Application"
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost

# Database
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=root
DB_PASSWORD=

# Cache
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

# Mail
MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025

# AWS
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
```

## Common Artisan Commands

```bash
# Development
php artisan serve                 # Start development server
php artisan tinker                # Interactive shell
php artisan make:model Post -mfsc # Model with migration, factory, seeder, controller

# Database
php artisan migrate               # Run migrations
php artisan migrate:rollback      # Rollback migrations
php artisan db:seed              # Run seeders

# Cache
php artisan cache:clear          # Clear application cache
php artisan config:cache         # Cache configuration
php artisan route:cache          # Cache routes

# Queue
php artisan queue:work           # Process queue jobs
php artisan queue:listen         # Listen for queue jobs

# Optimization
php artisan optimize             # Cache bootstrap files
php artisan optimize:clear       # Clear cached bootstrap files
```

## Package Recommendations

- **Laravel Debugbar**: Development debugging
- **Laravel Telescope**: Application debugging and monitoring
- **Laravel Sanctum**: API authentication
- **Laravel Scout**: Full-text search
- **Laravel Horizon**: Queue monitoring
- **Spatie Laravel-permission**: Roles and permissions
- **Laravel Excel**: Excel import/export
- **Laravel Backup**: Application backup

## Resources
- **Style Guide**: https://github.com/alexeymezenin/laravel-best-practices
- **Laravel Daily**: https://laraveldaily.com
- **Laravel Recipes**: https://laravel-recipes.com
- **Laravel Cheat Sheet**: https://learninglaravel.net/cheatsheet