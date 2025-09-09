# 🧪 Comprehensive Testing Template

## Testing Overview
**Feature/Component**: [Name]
**Testing Type**: [Unit/Integration/E2E/Performance/Security]
**Framework**: [PHPUnit/Jest/Cypress/etc]
**Coverage Target**: [80%+]

## Test Strategy

### Testing Pyramid Distribution
- **Unit Tests (70%)**: Individual functions and methods
- **Integration Tests (20%)**: Component interactions
- **E2E Tests (10%)**: Critical user journeys

## Unit Tests

### PHP/Laravel (PHPUnit)
```php
<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Models\User;
use App\Services\UserService;

class UserServiceTest extends TestCase
{
    protected UserService $service;
    
    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new UserService();
    }
    
    /** @test */
    public function it_creates_user_with_valid_data()
    {
        $userData = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123'
        ];
        
        $user = $this->service->createUser($userData);
        
        $this->assertInstanceOf(User::class, $user);
        $this->assertEquals('John Doe', $user->name);
        $this->assertEquals('john@example.com', $user->email);
    }
    
    /** @test */
    public function it_throws_exception_for_duplicate_email()
    {
        User::factory()->create(['email' => 'existing@example.com']);
        
        $this->expectException(DuplicateEmailException::class);
        
        $this->service->createUser([
            'email' => 'existing@example.com'
        ]);
    }
    
    /** @test */
    public function it_handles_edge_cases()
    {
        // Test with minimum required fields
        // Test with maximum field lengths
        // Test with special characters
        // Test with null values
    }
}
```

### JavaScript (Jest)
```javascript
import { calculateTotal, validateInput, formatCurrency } from './utils';

describe('Utils Functions', () => {
    describe('calculateTotal', () => {
        it('calculates total with valid items', () => {
            const items = [
                { price: 10, quantity: 2 },
                { price: 5, quantity: 3 }
            ];
            
            expect(calculateTotal(items)).toBe(35);
        });
        
        it('handles empty array', () => {
            expect(calculateTotal([])).toBe(0);
        });
        
        it('handles negative quantities', () => {
            const items = [{ price: 10, quantity: -1 }];
            expect(() => calculateTotal(items)).toThrow('Invalid quantity');
        });
    });
    
    describe('validateInput', () => {
        it('validates required fields', () => {
            const input = { name: '', email: 'test@test.com' };
            const errors = validateInput(input);
            
            expect(errors).toHaveProperty('name');
            expect(errors.name).toBe('Name is required');
        });
    });
});
```

## Integration Tests

### API Endpoint Tests (Laravel)
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
    
    /** @test */
    public function authenticated_user_can_get_profile()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);
        
        $response = $this->getJson('/api/user/profile');
        
        $response->assertStatus(200)
                 ->assertJson([
                     'data' => [
                         'id' => $user->id,
                         'email' => $user->email
                     ]
                 ]);
    }
    
    /** @test */
    public function unauthenticated_user_cannot_access_protected_routes()
    {
        $response = $this->getJson('/api/user/profile');
        
        $response->assertStatus(401);
    }
    
    /** @test */
    public function it_validates_user_creation_request()
    {
        Sanctum::actingAs(User::factory()->admin()->create());
        
        $response = $this->postJson('/api/users', [
            'name' => '',  // Invalid: empty
            'email' => 'not-an-email',  // Invalid: format
        ]);
        
        $response->assertStatus(422)
                 ->assertJsonValidationErrors(['name', 'email']);
    }
}
```

## E2E Tests

### Cypress Test
```javascript
describe('User Registration Flow', () => {
    beforeEach(() => {
        cy.visit('/register');
    });
    
    it('completes registration successfully', () => {
        // Fill form
        cy.get('[data-testid="name-input"]').type('John Doe');
        cy.get('[data-testid="email-input"]').type('john@example.com');
        cy.get('[data-testid="password-input"]').type('SecurePass123!');
        cy.get('[data-testid="confirm-password-input"]').type('SecurePass123!');
        
        // Accept terms
        cy.get('[data-testid="terms-checkbox"]').check();
        
        // Submit
        cy.get('[data-testid="register-button"]').click();
        
        // Verify redirect and success message
        cy.url().should('include', '/dashboard');
        cy.contains('Welcome, John!').should('be.visible');
    });
    
    it('shows validation errors', () => {
        // Submit empty form
        cy.get('[data-testid="register-button"]').click();
        
        // Check for error messages
        cy.contains('Name is required').should('be.visible');
        cy.contains('Email is required').should('be.visible');
        cy.contains('Password is required').should('be.visible');
    });
    
    it('handles server errors gracefully', () => {
        // Mock server error
        cy.intercept('POST', '/api/register', {
            statusCode: 500,
            body: { message: 'Server error' }
        });
        
        // Fill and submit form
        cy.get('[data-testid="email-input"]').type('test@test.com');
        // ... fill other fields
        cy.get('[data-testid="register-button"]').click();
        
        // Verify error handling
        cy.contains('Something went wrong').should('be.visible');
    });
});
```

## Performance Tests

### Load Testing Script
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
    stages: [
        { duration: '2m', target: 100 }, // Ramp up
        { duration: '5m', target: 100 }, // Stay at 100 users
        { duration: '2m', target: 0 },   // Ramp down
    ],
    thresholds: {
        http_req_duration: ['p(95)<500'], // 95% of requests under 500ms
        http_req_failed: ['rate<0.1'],    // Error rate under 10%
    },
};

export default function() {
    let response = http.get('https://api.example.com/users');
    
    check(response, {
        'status is 200': (r) => r.status === 200,
        'response time < 500ms': (r) => r.timings.duration < 500,
    });
    
    sleep(1);
}
```

## Test Data Management

### Factories (Laravel)
```php
// database/factories/UserFactory.php
public function definition()
{
    return [
        'name' => fake()->name(),
        'email' => fake()->unique()->safeEmail(),
        'password' => bcrypt('password'),
        'email_verified_at' => now(),
    ];
}

// Custom states
public function admin()
{
    return $this->state(fn (array $attributes) => [
        'role' => 'admin',
    ]);
}

public function unverified()
{
    return $this->state(fn (array $attributes) => [
        'email_verified_at' => null,
    ]);
}
```

## Mock Strategies

### External Service Mocks
```php
// Mock payment gateway
$this->mock(PaymentGateway::class, function ($mock) {
    $mock->shouldReceive('charge')
         ->once()
         ->with(1000, 'tok_visa')
         ->andReturn(['status' => 'success', 'id' => 'ch_123']);
});

// Mock email service
Mail::fake();
// ... perform action
Mail::assertSent(WelcomeEmail::class, function ($mail) use ($user) {
    return $mail->hasTo($user->email);
});
```

## Test Checklist

### Before Writing Tests
- [ ] Identify test scenarios
- [ ] Define test data requirements
- [ ] Determine mocking needs
- [ ] Set coverage targets

### Test Coverage Areas
- [ ] Happy path scenarios
- [ ] Error conditions
- [ ] Edge cases
- [ ] Boundary values
- [ ] Null/empty inputs
- [ ] Invalid data types
- [ ] Concurrent operations
- [ ] Permission checks

### After Writing Tests
- [ ] All tests passing
- [ ] Coverage target met
- [ ] No flaky tests
- [ ] Tests run in CI/CD
- [ ] Documentation updated

## Common Testing Patterns

### Arrange-Act-Assert
```php
public function test_example()
{
    // Arrange
    $user = User::factory()->create();
    $service = new UserService();
    
    // Act
    $result = $service->processUser($user);
    
    // Assert
    $this->assertTrue($result);
}
```

### Given-When-Then (BDD)
```php
public function test_user_can_purchase_product()
{
    // Given - a user with sufficient balance
    $user = User::factory()->create(['balance' => 100]);
    $product = Product::factory()->create(['price' => 50]);
    
    // When - the user purchases the product
    $purchase = $user->purchase($product);
    
    // Then - the purchase is successful and balance is updated
    $this->assertTrue($purchase->successful);
    $this->assertEquals(50, $user->fresh()->balance);
}
```

---
Remember: Write tests before or alongside implementation, not after. Test behavior, not implementation details.