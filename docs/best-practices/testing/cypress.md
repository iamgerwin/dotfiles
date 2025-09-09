# Cypress Best Practices

## Official Documentation
- **Cypress Documentation**: https://docs.cypress.io
- **Best Practices Guide**: https://docs.cypress.io/guides/references/best-practices
- **API Reference**: https://docs.cypress.io/api/table-of-contents
- **GitHub Repository**: https://github.com/cypress-io/cypress

## Installation and Setup

### Installation
```bash
# Install Cypress
npm install --save-dev cypress

# Install TypeScript support
npm install --save-dev typescript @types/cypress

# Open Cypress Test Runner
npx cypress open

# Run Cypress headlessly
npx cypress run
```

### Configuration
```typescript
// cypress.config.ts
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    // Base URL for your application
    baseUrl: 'http://localhost:3000',
    
    // Viewport settings
    viewportWidth: 1280,
    viewportHeight: 720,
    
    // Test files
    specPattern: 'cypress/e2e/**/*.cy.{js,jsx,ts,tsx}',
    supportFile: 'cypress/support/e2e.ts',
    fixturesFolder: 'cypress/fixtures',
    screenshotsFolder: 'cypress/screenshots',
    videosFolder: 'cypress/videos',
    
    // Test behavior
    defaultCommandTimeout: 10000,
    requestTimeout: 10000,
    responseTimeout: 30000,
    pageLoadTimeout: 30000,
    
    // Retry configuration
    retries: {
      runMode: 2,
      openMode: 0
    },
    
    // Video and screenshot settings
    video: true,
    screenshotOnRunFailure: true,
    
    // Browser settings
    chromeWebSecurity: false,
    
    // Environment variables
    env: {
      apiUrl: 'http://localhost:3001/api',
      testUser: {
        email: 'test@example.com',
        password: 'password123'
      }
    },
    
    // Setup and teardown
    setupNodeEvents(on, config) {
      // Node event listeners
      
      // Task registration
      on('task', {
        // Database seeding
        seedDatabase: (data) => {
          // Implement database seeding logic
          console.log('Seeding database with:', data);
          return null;
        },
        
        // Database cleanup
        cleanDatabase: () => {
          console.log('Cleaning up database');
          return null;
        },
        
        // Log messages
        log: (message) => {
          console.log(message);
          return null;
        },
        
        // File operations
        readFileMaybe: (filename) => {
          try {
            const fs = require('fs');
            return fs.readFileSync(filename, 'utf8');
          } catch (e) {
            return null;
          }
        }
      });
      
      // Plugin configurations
      
      // Code coverage (if using @cypress/code-coverage)
      require('@cypress/code-coverage/task')(on, config);
      
      return config;
    }
  },
  
  component: {
    devServer: {
      framework: 'react',
      bundler: 'vite', // or 'webpack'
    },
    specPattern: 'src/**/*.cy.{js,jsx,ts,tsx}',
    supportFile: 'cypress/support/component.ts'
  }
});
```

### Support Files
```typescript
// cypress/support/e2e.ts
import './commands';
import 'cypress-real-events/support';

// Global configuration
Cypress.config('defaultCommandTimeout', 10000);

// Global hooks
beforeEach(() => {
  // Set up common test data or state
  cy.log('Setting up test environment');
});

afterEach(() => {
  // Clean up after each test
  cy.log('Cleaning up test environment');
});

// Handle uncaught exceptions
Cypress.on('uncaught:exception', (err, runnable) => {
  // Return false to prevent Cypress from failing the test
  if (err.message.includes('ResizeObserver loop limit exceeded')) {
    return false;
  }
  
  if (err.message.includes('Non-Error promise rejection captured')) {
    return false;
  }
  
  // Let other errors fail the test
  return true;
});

// Network stubbing
Cypress.on('window:before:load', (win) => {
  // Stub console methods to reduce noise
  win.console.warn = cy.stub();
  win.console.info = cy.stub();
});
```

### Custom Commands
```typescript
// cypress/support/commands.ts
declare global {
  namespace Cypress {
    interface Chainable {
      login(email?: string, password?: string): Chainable<void>;
      logout(): Chainable<void>;
      loginByApi(email: string, password: string): Chainable<void>;
      seedAndVisit(seedData: any, route?: string): Chainable<void>;
      getByTestId(testId: string): Chainable<JQuery<HTMLElement>>;
      findByTestId(testId: string): Chainable<JQuery<HTMLElement>>;
      shouldBeVisible(selector: string): Chainable<void>;
      shouldContainText(selector: string, text: string): Chainable<void>;
      waitForApiResponse(alias: string, timeout?: number): Chainable<void>;
      uploadFile(selector: string, filePath: string): Chainable<void>;
      dragAndDrop(source: string, target: string): Chainable<void>;
    }
  }
}

// Authentication commands
Cypress.Commands.add('login', (email?: string, password?: string) => {
  const userEmail = email || Cypress.env('testUser').email;
  const userPassword = password || Cypress.env('testUser').password;
  
  cy.visit('/login');
  cy.getByTestId('email-input').type(userEmail);
  cy.getByTestId('password-input').type(userPassword);
  cy.getByTestId('login-button').click();
  
  // Wait for successful login
  cy.url().should('include', '/dashboard');
  cy.getByTestId('welcome-message').should('be.visible');
});

Cypress.Commands.add('logout', () => {
  cy.getByTestId('user-menu').click();
  cy.getByTestId('logout-button').click();
  cy.url().should('include', '/login');
});

// API-based login for faster test setup
Cypress.Commands.add('loginByApi', (email: string, password: string) => {
  cy.request({
    method: 'POST',
    url: `${Cypress.env('apiUrl')}/auth/login`,
    body: { email, password }
  }).then((response) => {
    expect(response.status).to.eq(200);
    
    // Store token in localStorage
    window.localStorage.setItem('authToken', response.body.accessToken);
    
    // Set auth cookie if needed
    cy.setCookie('auth-token', response.body.accessToken);
  });
});

// Test data management
Cypress.Commands.add('seedAndVisit', (seedData: any, route = '/') => {
  cy.task('seedDatabase', seedData);
  cy.visit(route);
});

// Element selection helpers
Cypress.Commands.add('getByTestId', (testId: string) => {
  return cy.get(`[data-testid="${testId}"]`);
});

Cypress.Commands.add('findByTestId', { prevSubject: 'element' }, (subject, testId: string) => {
  return cy.wrap(subject).find(`[data-testid="${testId}"]`);
});

// Visibility helpers
Cypress.Commands.add('shouldBeVisible', (selector: string) => {
  cy.get(selector).should('be.visible');
});

Cypress.Commands.add('shouldContainText', (selector: string, text: string) => {
  cy.get(selector).should('contain.text', text);
});

// API helpers
Cypress.Commands.add('waitForApiResponse', (alias: string, timeout = 10000) => {
  cy.wait(alias, { timeout });
});

// File upload
Cypress.Commands.add('uploadFile', (selector: string, filePath: string) => {
  cy.get(selector).selectFile(filePath, { force: true });
});

// Drag and drop
Cypress.Commands.add('dragAndDrop', (source: string, target: string) => {
  const dataTransfer = new DataTransfer();
  
  cy.get(source).trigger('mousedown', { which: 1 });
  cy.get(source).trigger('dragstart', { dataTransfer });
  cy.get(target).trigger('dragover', { dataTransfer });
  cy.get(target).trigger('drop', { dataTransfer });
  cy.get(source).trigger('dragend');
});
```

## Test Structure and Organization

### Basic Test Structure
```typescript
// cypress/e2e/auth/login.cy.ts
describe('Login Functionality', () => {
  beforeEach(() => {
    // Set up test environment
    cy.task('cleanDatabase');
    cy.visit('/login');
  });
  
  it('should login successfully with valid credentials', () => {
    const email = 'test@example.com';
    const password = 'password123';
    
    cy.getByTestId('email-input').type(email);
    cy.getByTestId('password-input').type(password);
    cy.getByTestId('login-button').click();
    
    // Verify successful login
    cy.url().should('include', '/dashboard');
    cy.getByTestId('welcome-message')
      .should('be.visible')
      .and('contain.text', 'Welcome');
  });
  
  it('should show error for invalid credentials', () => {
    cy.getByTestId('email-input').type('invalid@example.com');
    cy.getByTestId('password-input').type('wrongpassword');
    cy.getByTestId('login-button').click();
    
    cy.getByTestId('error-message')
      .should('be.visible')
      .and('contain.text', 'Invalid credentials');
    
    // Ensure we stay on login page
    cy.url().should('include', '/login');
  });
  
  it('should validate required fields', () => {
    cy.getByTestId('login-button').click();
    
    cy.getByTestId('email-error')
      .should('be.visible')
      .and('contain.text', 'Email is required');
    
    cy.getByTestId('password-error')
      .should('be.visible')
      .and('contain.text', 'Password is required');
  });
  
  it('should redirect to dashboard when already authenticated', () => {
    // Login first
    cy.login();
    
    // Try to visit login page
    cy.visit('/login');
    
    // Should redirect to dashboard
    cy.url().should('include', '/dashboard');
  });
  
  it('should handle forgot password flow', () => {
    cy.getByTestId('forgot-password-link').click();
    
    cy.url().should('include', '/forgot-password');
    cy.getByTestId('forgot-password-form').should('be.visible');
  });
});
```

### API Testing
```typescript
// cypress/e2e/api/users.cy.ts
describe('Users API', () => {
  let authToken: string;
  
  before(() => {
    // Get authentication token
    cy.request({
      method: 'POST',
      url: `${Cypress.env('apiUrl')}/auth/login`,
      body: {
        email: Cypress.env('testUser').email,
        password: Cypress.env('testUser').password
      }
    }).then((response) => {
      authToken = response.body.accessToken;
    });
  });
  
  beforeEach(() => {
    cy.task('cleanDatabase');
  });
  
  it('should get users list', () => {
    cy.request({
      method: 'GET',
      url: `${Cypress.env('apiUrl')}/users`,
      headers: {
        'Authorization': `Bearer ${authToken}`
      },
      qs: {
        page: 1,
        limit: 10
      }
    }).then((response) => {
      expect(response.status).to.eq(200);
      expect(response.body).to.have.property('data');
      expect(response.body).to.have.property('pagination');
      expect(response.body.data).to.be.an('array');
    });
  });
  
  it('should create a new user', () => {
    const newUser = {
      email: `test.${Date.now()}@example.com`,
      firstName: 'Test',
      lastName: 'User',
      password: 'TestPassword123!',
      role: 'user'
    };
    
    cy.request({
      method: 'POST',
      url: `${Cypress.env('apiUrl')}/users`,
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      },
      body: newUser
    }).then((response) => {
      expect(response.status).to.eq(201);
      expect(response.body.data).to.have.property('id');
      expect(response.body.data.email).to.eq(newUser.email);
      expect(response.body.data.firstName).to.eq(newUser.firstName);
    });
  });
  
  it('should return validation error for invalid data', () => {
    const invalidUser = {
      email: 'invalid-email',
      firstName: '',
      password: '123' // Too short
    };
    
    cy.request({
      method: 'POST',
      url: `${Cypress.env('apiUrl')}/users`,
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      },
      body: invalidUser,
      failOnStatusCode: false
    }).then((response) => {
      expect(response.status).to.eq(400);
      expect(response.body).to.have.property('error');
      expect(response.body).to.have.property('details');
    });
  });
  
  it('should handle authentication errors', () => {
    cy.request({
      method: 'GET',
      url: `${Cypress.env('apiUrl')}/users`,
      failOnStatusCode: false
    }).then((response) => {
      expect(response.status).to.eq(401);
    });
  });
});
```

### UI Component Testing
```typescript
// cypress/e2e/components/user-management.cy.ts
describe('User Management Interface', () => {
  beforeEach(() => {
    // Set up authenticated session
    cy.loginByApi(
      Cypress.env('testUser').email,
      Cypress.env('testUser').password
    );
    
    // Seed test data
    cy.task('seedDatabase', {
      users: [
        {
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: 'Doe',
          role: 'user'
        },
        {
          email: 'jane.admin@example.com',
          firstName: 'Jane',
          lastName: 'Admin',
          role: 'admin'
        }
      ]
    });
    
    cy.visit('/users');
  });
  
  it('should display users table', () => {
    cy.getByTestId('users-table').should('be.visible');
    cy.getByTestId('table-row').should('have.length.at.least', 2);
    
    // Check if user data is displayed correctly
    cy.getByTestId('table-row').first().within(() => {
      cy.should('contain.text', 'john.doe@example.com');
      cy.should('contain.text', 'John');
      cy.should('contain.text', 'Doe');
      cy.should('contain.text', 'user');
    });
  });
  
  it('should filter users by search', () => {
    cy.getByTestId('search-input').type('john');
    
    // Wait for search results
    cy.getByTestId('table-row').should('have.length', 1);
    cy.getByTestId('table-row').should('contain.text', 'john.doe@example.com');
  });
  
  it('should open add user modal', () => {
    cy.getByTestId('add-user-button').click();
    
    cy.getByTestId('add-user-modal').should('be.visible');
    cy.getByTestId('modal-title').should('contain.text', 'Add New User');
    
    // Check form fields
    cy.getByTestId('email-input').should('be.visible');
    cy.getByTestId('first-name-input').should('be.visible');
    cy.getByTestId('last-name-input').should('be.visible');
    cy.getByTestId('role-select').should('be.visible');
  });
  
  it('should create a new user through UI', () => {
    const newUser = {
      email: `ui.test.${Date.now()}@example.com`,
      firstName: 'UI',
      lastName: 'Test',
      role: 'moderator'
    };
    
    // Intercept API call
    cy.intercept('POST', '/api/users', { fixture: 'new-user.json' }).as('createUser');
    
    cy.getByTestId('add-user-button').click();
    cy.getByTestId('email-input').type(newUser.email);
    cy.getByTestId('first-name-input').type(newUser.firstName);
    cy.getByTestId('last-name-input').type(newUser.lastName);
    cy.getByTestId('role-select').select(newUser.role);
    cy.getByTestId('save-button').click();
    
    // Wait for API call
    cy.wait('@createUser');
    
    // Modal should close
    cy.getByTestId('add-user-modal').should('not.exist');
    
    // User should appear in table
    cy.getByTestId('table-row')
      .contains(newUser.email)
      .should('be.visible');
  });
  
  it('should handle form validation errors', () => {
    cy.getByTestId('add-user-button').click();
    cy.getByTestId('save-button').click();
    
    // Check validation messages
    cy.getByTestId('email-error').should('contain.text', 'Email is required');
    cy.getByTestId('first-name-error').should('contain.text', 'First name is required');
    cy.getByTestId('last-name-error').should('contain.text', 'Last name is required');
  });
  
  it('should edit user', () => {
    // Click edit button for first user
    cy.getByTestId('table-row').first().within(() => {
      cy.getByTestId('edit-button').click();
    });
    
    cy.getByTestId('edit-user-modal').should('be.visible');
    
    // Update user data
    cy.getByTestId('first-name-input').clear().type('Johnny');
    cy.getByTestId('save-button').click();
    
    // Verify updated data in table
    cy.getByTestId('table-row').first().should('contain.text', 'Johnny');
  });
  
  it('should delete user with confirmation', () => {
    const initialCount = 2;
    
    cy.getByTestId('table-row').should('have.length', initialCount);
    
    // Click delete button for first user
    cy.getByTestId('table-row').first().within(() => {
      cy.getByTestId('delete-button').click();
    });
    
    // Confirm deletion
    cy.getByTestId('confirm-dialog').should('be.visible');
    cy.getByTestId('confirm-button').click();
    
    // Verify user is deleted
    cy.getByTestId('table-row').should('have.length', initialCount - 1);
  });
});
```

### Page Object Model
```typescript
// cypress/support/page-objects/login.page.ts
export class LoginPage {
  // Selectors
  private selectors = {
    emailInput: '[data-testid="email-input"]',
    passwordInput: '[data-testid="password-input"]',
    loginButton: '[data-testid="login-button"]',
    errorMessage: '[data-testid="error-message"]',
    forgotPasswordLink: '[data-testid="forgot-password-link"]',
    rememberMeCheckbox: '[data-testid="remember-me-checkbox"]'
  };
  
  // Actions
  visit() {
    cy.visit('/login');
    return this;
  }
  
  fillEmail(email: string) {
    cy.get(this.selectors.emailInput).type(email);
    return this;
  }
  
  fillPassword(password: string) {
    cy.get(this.selectors.passwordInput).type(password);
    return this;
  }
  
  clickLogin() {
    cy.get(this.selectors.loginButton).click();
    return this;
  }
  
  login(email: string, password: string) {
    this.fillEmail(email)
        .fillPassword(password)
        .clickLogin();
    return this;
  }
  
  clickForgotPassword() {
    cy.get(this.selectors.forgotPasswordLink).click();
    return this;
  }
  
  checkRememberMe() {
    cy.get(this.selectors.rememberMeCheckbox).check();
    return this;
  }
  
  // Assertions
  shouldShowError(message: string) {
    cy.get(this.selectors.errorMessage)
      .should('be.visible')
      .and('contain.text', message);
    return this;
  }
  
  shouldRedirectToDashboard() {
    cy.url().should('include', '/dashboard');
    return this;
  }
}
```

```typescript
// cypress/support/page-objects/user-management.page.ts
export class UserManagementPage {
  private selectors = {
    addUserButton: '[data-testid="add-user-button"]',
    searchInput: '[data-testid="search-input"]',
    usersTable: '[data-testid="users-table"]',
    tableRow: '[data-testid="table-row"]',
    // Modal selectors
    modal: '[data-testid="add-user-modal"]',
    modalEmailInput: '[data-testid="email-input"]',
    modalFirstNameInput: '[data-testid="first-name-input"]',
    modalLastNameInput: '[data-testid="last-name-input"]',
    modalRoleSelect: '[data-testid="role-select"]',
    modalSaveButton: '[data-testid="save-button"]',
    modalCancelButton: '[data-testid="cancel-button"]'
  };
  
  visit() {
    cy.visit('/users');
    return this;
  }
  
  clickAddUser() {
    cy.get(this.selectors.addUserButton).click();
    return this;
  }
  
  searchUser(searchTerm: string) {
    cy.get(this.selectors.searchInput).type(searchTerm);
    return this;
  }
  
  addUser(userData: {
    email: string;
    firstName: string;
    lastName: string;
    role: string;
  }) {
    this.clickAddUser();
    
    cy.get(this.selectors.modalEmailInput).type(userData.email);
    cy.get(this.selectors.modalFirstNameInput).type(userData.firstName);
    cy.get(this.selectors.modalLastNameInput).type(userData.lastName);
    cy.get(this.selectors.modalRoleSelect).select(userData.role);
    cy.get(this.selectors.modalSaveButton).click();
    
    return this;
  }
  
  getUserRow(email: string) {
    return cy.get(this.selectors.tableRow).contains(email).parent();
  }
  
  editUser(email: string, newData: Partial<{
    firstName: string;
    lastName: string;
    role: string;
  }>) {
    this.getUserRow(email).within(() => {
      cy.getByTestId('edit-button').click();
    });
    
    if (newData.firstName) {
      cy.get(this.selectors.modalFirstNameInput).clear().type(newData.firstName);
    }
    if (newData.lastName) {
      cy.get(this.selectors.modalLastNameInput).clear().type(newData.lastName);
    }
    if (newData.role) {
      cy.get(this.selectors.modalRoleSelect).select(newData.role);
    }
    
    cy.get(this.selectors.modalSaveButton).click();
    return this;
  }
  
  deleteUser(email: string) {
    this.getUserRow(email).within(() => {
      cy.getByTestId('delete-button').click();
    });
    
    cy.getByTestId('confirm-button').click();
    return this;
  }
  
  // Assertions
  shouldDisplayUsersTable() {
    cy.get(this.selectors.usersTable).should('be.visible');
    return this;
  }
  
  shouldHaveUserCount(count: number) {
    cy.get(this.selectors.tableRow).should('have.length', count);
    return this;
  }
  
  shouldContainUser(email: string) {
    cy.get(this.selectors.tableRow).should('contain.text', email);
    return this;
  }
  
  shouldNotContainUser(email: string) {
    cy.get(this.selectors.tableRow).should('not.contain.text', email);
    return this;
  }
}
```

## Testing Patterns

### Data-Driven Testing
```typescript
// cypress/e2e/data-driven/user-validation.cy.ts
describe('User Form Validation', () => {
  const testCases = [
    {
      description: 'should reject invalid email formats',
      email: 'invalid-email',
      expectedError: 'Please enter a valid email address'
    },
    {
      description: 'should reject empty email',
      email: '',
      expectedError: 'Email is required'
    },
    {
      description: 'should reject email with spaces',
      email: 'test @example.com',
      expectedError: 'Please enter a valid email address'
    },
    {
      description: 'should reject email without domain',
      email: 'test@',
      expectedError: 'Please enter a valid email address'
    }
  ];
  
  beforeEach(() => {
    cy.visit('/register');
  });
  
  testCases.forEach((testCase) => {
    it(testCase.description, () => {
      cy.getByTestId('email-input').type(testCase.email);
      cy.getByTestId('submit-button').click();
      
      cy.getByTestId('email-error')
        .should('be.visible')
        .and('contain.text', testCase.expectedError);
    });
  });
  
  // Test with fixture data
  it('should validate multiple user scenarios from fixture', () => {
    cy.fixture('invalid-users.json').then((users) => {
      users.forEach((user, index) => {
        cy.getByTestId('email-input').clear().type(user.email);
        cy.getByTestId('first-name-input').clear().type(user.firstName);
        cy.getByTestId('last-name-input').clear().type(user.lastName);
        cy.getByTestId('submit-button').click();
        
        // Check for expected validation errors
        user.expectedErrors.forEach((error) => {
          cy.getByTestId(error.field + '-error')
            .should('be.visible')
            .and('contain.text', error.message);
        });
      });
    });
  });
});
```

### Network Stubbing and Mocking
```typescript
// cypress/e2e/network/api-mocking.cy.ts
describe('API Mocking and Stubbing', () => {
  beforeEach(() => {
    cy.loginByApi(
      Cypress.env('testUser').email,
      Cypress.env('testUser').password
    );
  });
  
  it('should handle API success response', () => {
    // Intercept API call and return mock data
    cy.intercept('GET', '/api/users*', { fixture: 'users-list.json' }).as('getUsers');
    
    cy.visit('/users');
    
    cy.wait('@getUsers').then((interception) => {
      expect(interception.response?.statusCode).to.eq(200);
    });
    
    // Verify UI displays mocked data
    cy.getByTestId('table-row').should('have.length', 3);
    cy.getByTestId('table-row').first().should('contain.text', 'John Doe');
  });
  
  it('should handle API error response', () => {
    // Mock API error
    cy.intercept('GET', '/api/users*', {
      statusCode: 500,
      body: { error: 'Internal Server Error' }
    }).as('getUsersError');
    
    cy.visit('/users');
    
    cy.wait('@getUsersError');
    
    // Verify error handling in UI
    cy.getByTestId('error-message')
      .should('be.visible')
      .and('contain.text', 'Failed to load users');
  });
  
  it('should handle slow API response', () => {
    // Mock slow response
    cy.intercept('GET', '/api/users*', {
      fixture: 'users-list.json',
      delay: 3000
    }).as('getSlowUsers');
    
    cy.visit('/users');
    
    // Verify loading state is shown
    cy.getByTestId('loading-spinner').should('be.visible');
    
    cy.wait('@getSlowUsers');
    
    // Verify loading state is hidden and data is shown
    cy.getByTestId('loading-spinner').should('not.exist');
    cy.getByTestId('table-row').should('have.length.greaterThan', 0);
  });
  
  it('should handle network failure', () => {
    // Force network error
    cy.intercept('GET', '/api/users*', { forceNetworkError: true }).as('networkError');
    
    cy.visit('/users');
    
    cy.wait('@networkError');
    
    // Verify network error handling
    cy.getByTestId('error-message')
      .should('be.visible')
      .and('contain.text', 'Network error');
  });
});
```

### Visual Testing
```typescript
// cypress/e2e/visual/visual-regression.cy.ts
describe('Visual Regression Testing', () => {
  beforeEach(() => {
    cy.loginByApi(
      Cypress.env('testUser').email,
      Cypress.env('testUser').password
    );
  });
  
  it('should match login page appearance', () => {
    cy.visit('/login');
    
    // Hide dynamic elements
    cy.get('.timestamp').invoke('css', 'visibility', 'hidden');
    
    cy.matchImageSnapshot('login-page');
  });
  
  it('should match dashboard layout', () => {
    cy.visit('/dashboard');
    cy.getByTestId('welcome-message').should('be.visible');
    
    // Wait for all content to load
    cy.get('[data-testid="loading-spinner"]').should('not.exist');
    
    cy.matchImageSnapshot('dashboard-layout');
  });
  
  it('should match modal dialog appearance', () => {
    cy.visit('/users');
    cy.getByTestId('add-user-button').click();
    cy.getByTestId('add-user-modal').should('be.visible');
    
    cy.matchImageSnapshot('add-user-modal');
  });
  
  it('should match responsive design', () => {
    // Test different viewports
    const viewports = [
      { width: 320, height: 568 }, // Mobile
      { width: 768, height: 1024 }, // Tablet
      { width: 1920, height: 1080 } // Desktop
    ];
    
    viewports.forEach((viewport, index) => {
      cy.viewport(viewport.width, viewport.height);
      cy.visit('/dashboard');
      cy.getByTestId('welcome-message').should('be.visible');
      
      cy.matchImageSnapshot(`dashboard-${viewport.width}x${viewport.height}`);
    });
  });
});
```

## Advanced Testing Features

### File Upload Testing
```typescript
// cypress/e2e/features/file-upload.cy.ts
describe('File Upload Functionality', () => {
  beforeEach(() => {
    cy.loginByApi(
      Cypress.env('testUser').email,
      Cypress.env('testUser').password
    );
    cy.visit('/profile');
  });
  
  it('should upload avatar image', () => {
    const fileName = 'avatar.jpg';
    
    cy.fixture(fileName, 'base64').then((fileContent) => {
      cy.get('[data-testid="avatar-upload"]').selectFile({
        contents: Cypress.Buffer.from(fileContent, 'base64'),
        fileName,
        mimeType: 'image/jpeg'
      });
    });
    
    // Verify upload success
    cy.getByTestId('upload-success-message')
      .should('be.visible')
      .and('contain.text', 'Avatar updated successfully');
    
    // Verify image is displayed
    cy.getByTestId('avatar-image')
      .should('be.visible')
      .and('have.attr', 'src')
      .and('include', 'avatar');
  });
  
  it('should handle file size validation', () => {
    // Create a large dummy file
    const largeFile = new File(['a'.repeat(6 * 1024 * 1024)], 'large-file.jpg', {
      type: 'image/jpeg'
    });
    
    cy.get('[data-testid="avatar-upload"]').selectFile(largeFile);
    
    cy.getByTestId('upload-error-message')
      .should('be.visible')
      .and('contain.text', 'File size must be less than 5MB');
  });
  
  it('should handle invalid file types', () => {
    cy.get('[data-testid="avatar-upload"]').selectFile('cypress/fixtures/document.pdf');
    
    cy.getByTestId('upload-error-message')
      .should('be.visible')
      .and('contain.text', 'Only image files are allowed');
  });
});
```

### Drag and Drop Testing
```typescript
// cypress/e2e/features/drag-drop.cy.ts
describe('Drag and Drop Functionality', () => {
  beforeEach(() => {
    cy.loginByApi(
      Cypress.env('testUser').email,
      Cypress.env('testUser').password
    );
    cy.visit('/kanban-board');
  });
  
  it('should move task between columns', () => {
    const taskId = 'task-1';
    const sourceColumn = '[data-testid="todo-column"]';
    const targetColumn = '[data-testid="in-progress-column"]';
    
    // Verify initial state
    cy.get(sourceColumn).within(() => {
      cy.getByTestId(taskId).should('exist');
    });
    
    cy.get(targetColumn).within(() => {
      cy.getByTestId(taskId).should('not.exist');
    });
    
    // Perform drag and drop
    cy.dragAndDrop(`[data-testid="${taskId}"]`, targetColumn);
    
    // Verify task moved
    cy.get(sourceColumn).within(() => {
      cy.getByTestId(taskId).should('not.exist');
    });
    
    cy.get(targetColumn).within(() => {
      cy.getByTestId(taskId).should('exist');
    });
  });
  
  it('should reorder tasks within the same column', () => {
    const task1 = '[data-testid="task-1"]';
    const task2 = '[data-testid="task-2"]';
    
    // Get initial order
    cy.get('[data-testid="todo-column"] .task').then((tasks) => {
      const initialOrder = Array.from(tasks).map(task => task.getAttribute('data-testid'));
      expect(initialOrder).to.deep.equal(['task-1', 'task-2', 'task-3']);
    });
    
    // Drag task-1 below task-2
    cy.dragAndDrop(task1, task2);
    
    // Verify new order
    cy.get('[data-testid="todo-column"] .task').then((tasks) => {
      const newOrder = Array.from(tasks).map(task => task.getAttribute('data-testid'));
      expect(newOrder).to.deep.equal(['task-2', 'task-1', 'task-3']);
    });
  });
});
```

### Accessibility Testing
```typescript
// cypress/e2e/accessibility/a11y.cy.ts
describe('Accessibility Testing', () => {
  beforeEach(() => {
    cy.injectAxe();
  });
  
  it('should have no accessibility violations on login page', () => {
    cy.visit('/login');
    cy.checkA11y();
  });
  
  it('should have no accessibility violations on dashboard', () => {
    cy.loginByApi(
      Cypress.env('testUser').email,
      Cypress.env('testUser').password
    );
    cy.visit('/dashboard');
    cy.checkA11y();
  });
  
  it('should support keyboard navigation', () => {
    cy.visit('/login');
    
    // Tab through form elements
    cy.get('body').tab();
    cy.focused().should('have.attr', 'data-testid', 'email-input');
    
    cy.focused().tab();
    cy.focused().should('have.attr', 'data-testid', 'password-input');
    
    cy.focused().tab();
    cy.focused().should('have.attr', 'data-testid', 'login-button');
    
    // Test Enter key on button
    cy.focused().type('{enter}');
  });
  
  it('should have proper ARIA labels', () => {
    cy.visit('/users');
    
    cy.getByTestId('add-user-button')
      .should('have.attr', 'aria-label', 'Add new user');
    
    cy.getByTestId('search-input')
      .should('have.attr', 'aria-label', 'Search users');
    
    cy.getByTestId('users-table')
      .should('have.attr', 'role', 'table');
  });
  
  it('should announce dynamic content changes', () => {
    cy.visit('/users');
    
    // Add user and check for announcement
    cy.getByTestId('add-user-button').click();
    
    cy.get('[role="alert"]')
      .should('be.visible')
      .and('contain.text', 'Add user dialog opened');
  });
});
```

## Performance Testing

### Performance Monitoring
```typescript
// cypress/e2e/performance/performance.cy.ts
describe('Performance Testing', () => {
  it('should meet performance benchmarks', () => {
    cy.visit('/dashboard', {
      onBeforeLoad: (win) => {
        win.performance.mark('start-load');
      },
      onLoad: (win) => {
        win.performance.mark('end-load');
        win.performance.measure('page-load', 'start-load', 'end-load');
      }
    });
    
    cy.window().then((win) => {
      const measure = win.performance.getEntriesByName('page-load')[0];
      expect(measure.duration).to.be.lessThan(3000); // Less than 3 seconds
    });
  });
  
  it('should handle large datasets efficiently', () => {
    // Mock large dataset
    cy.intercept('GET', '/api/users*', { fixture: 'large-users-list.json' });
    
    const startTime = Date.now();
    
    cy.visit('/users');
    cy.getByTestId('table-row').should('have.length', 100);
    
    cy.then(() => {
      const loadTime = Date.now() - startTime;
      expect(loadTime).to.be.lessThan(5000); // Should render in less than 5 seconds
    });
  });
  
  it('should handle rapid interactions', () => {
    cy.visit('/users');
    
    // Rapid search operations
    const searches = ['a', 'ab', 'abc', 'abcd'];
    
    searches.forEach((search, index) => {
      cy.getByTestId('search-input').clear().type(search);
      cy.wait(100); // Small delay between searches
    });
    
    // Should handle all searches without errors
    cy.getByTestId('search-input').should('have.value', 'abcd');
    cy.getByTestId('error-message').should('not.exist');
  });
});
```

### Memory Leak Detection
```typescript
// cypress/e2e/performance/memory-leaks.cy.ts
describe('Memory Leak Detection', () => {
  it('should not leak memory during navigation', () => {
    let initialMemory: number;
    
    cy.visit('/dashboard');
    
    cy.window().then((win) => {
      // Force garbage collection if available
      if ((win as any).gc) {
        (win as any).gc();
      }
      
      // Get initial memory usage
      initialMemory = (win.performance as any).memory?.usedJSHeapSize || 0;
    });
    
    // Navigate between pages multiple times
    const pages = ['/users', '/settings', '/reports', '/dashboard'];
    
    // Repeat navigation 10 times
    for (let i = 0; i < 10; i++) {
      pages.forEach((page) => {
        cy.visit(page);
        cy.wait(500);
      });
    }
    
    cy.window().then((win) => {
      // Force garbage collection again
      if ((win as any).gc) {
        (win as any).gc();
      }
      
      const finalMemory = (win.performance as any).memory?.usedJSHeapSize || 0;
      const memoryGrowth = finalMemory - initialMemory;
      
      // Memory growth should be reasonable (less than 50MB)
      expect(memoryGrowth).to.be.lessThan(50 * 1024 * 1024);
    });
  });
});
```

## CI/CD Integration

### GitHub Actions Configuration
```yaml
# .github/workflows/cypress.yml
name: Cypress Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  cypress-run:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        browser: [chrome, firefox, edge]
      fail-fast: false
      
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: 18
          cache: 'npm'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Build application
        run: npm run build
        
      - name: Start application
        run: |
          npm run start &
          npx wait-on http://localhost:3000
          
      - name: Run Cypress tests
        uses: cypress-io/github-action@v5
        with:
          browser: ${{ matrix.browser }}
          record: true
          parallel: true
          group: 'Tests - ${{ matrix.browser }}'
        env:
          CYPRESS_RECORD_KEY: ${{ secrets.CYPRESS_RECORD_KEY }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          CYPRESS_baseUrl: http://localhost:3000
          CYPRESS_apiUrl: http://localhost:3001/api
          
      - name: Upload screenshots
        uses: actions/upload-artifact@v3
        if: failure()
        with:
          name: cypress-screenshots-${{ matrix.browser }}
          path: cypress/screenshots
          
      - name: Upload videos
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: cypress-videos-${{ matrix.browser }}
          path: cypress/videos

  cypress-component-tests:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: 18
          cache: 'npm'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run Cypress Component Tests
        uses: cypress-io/github-action@v5
        with:
          component: true
          record: true
          group: 'Component Tests'
        env:
          CYPRESS_RECORD_KEY: ${{ secrets.CYPRESS_RECORD_KEY }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Custom Reporting
```typescript
// cypress/plugins/reporter.ts
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      // Custom reporter for Slack notifications
      on('after:run', (results) => {
        if (results.failures > 0) {
          sendSlackNotification({
            channel: '#testing',
            text: `🔴 Cypress tests failed: ${results.failures} failures out of ${results.totalTests} tests`,
            attachments: [
              {
                color: 'danger',
                fields: [
                  {
                    title: 'Branch',
                    value: process.env.GITHUB_REF,
                    short: true
                  },
                  {
                    title: 'Commit',
                    value: process.env.GITHUB_SHA?.substr(0, 7),
                    short: true
                  }
                ]
              }
            ]
          });
        }
      });
      
      // Generate custom HTML report
      on('after:run', (results) => {
        generateCustomReport(results);
      });
      
      return config;
    }
  }
});

function sendSlackNotification(message: any) {
  // Implement Slack webhook integration
}

function generateCustomReport(results: any) {
  // Generate custom HTML report
}
```

## Test Data Management

### Fixtures
```json
// cypress/fixtures/users-list.json
{
  "data": [
    {
      "id": "1",
      "email": "john.doe@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "role": "user",
      "status": "active",
      "createdAt": "2023-01-15T10:30:00Z"
    },
    {
      "id": "2",
      "email": "jane.admin@example.com",
      "firstName": "Jane",
      "lastName": "Admin",
      "role": "admin",
      "status": "active",
      "createdAt": "2023-01-16T11:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 2,
    "totalPages": 1
  }
}
```

```json
// cypress/fixtures/invalid-users.json
[
  {
    "email": "invalid-email",
    "firstName": "",
    "lastName": "User",
    "expectedErrors": [
      {
        "field": "email",
        "message": "Please enter a valid email address"
      },
      {
        "field": "first-name",
        "message": "First name is required"
      }
    ]
  },
  {
    "email": "test@example.com",
    "firstName": "Test",
    "lastName": "",
    "expectedErrors": [
      {
        "field": "last-name",
        "message": "Last name is required"
      }
    ]
  }
]
```

### Environment Configuration
```json
// cypress.env.json
{
  "apiUrl": "http://localhost:3001/api",
  "testUser": {
    "email": "test@example.com",
    "password": "password123"
  },
  "adminUser": {
    "email": "admin@example.com",
    "password": "adminpass123"
  },
  "database": {
    "host": "localhost",
    "port": 5432,
    "name": "test_db"
  }
}
```

## Common Pitfalls

1. **Using CSS selectors instead of data attributes**: Use `data-testid` attributes for stable selectors
2. **Not waiting for elements**: Always wait for elements to be visible/actionable before interacting
3. **Hard-coded waits**: Use dynamic waits instead of `cy.wait(5000)`
4. **Testing implementation details**: Focus on user behavior, not internal implementation
5. **Not cleaning up test data**: Always clean up data between tests
6. **Flaky tests due to timing**: Address race conditions and async operations properly
7. **Over-mocking APIs**: Balance between isolation and realistic testing
8. **Not testing error states**: Include negative test scenarios
9. **Poor test organization**: Use proper describe blocks and meaningful test names
10. **Not using page objects**: Implement page object pattern for maintainable tests