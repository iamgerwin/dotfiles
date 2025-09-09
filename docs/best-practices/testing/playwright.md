# Playwright Best Practices

## Official Documentation
- **Playwright Documentation**: https://playwright.dev
- **API Reference**: https://playwright.dev/docs/api/class-playwright
- **Test Runner**: https://playwright.dev/docs/test-runners
- **GitHub Repository**: https://github.com/microsoft/playwright

## Installation and Setup

### Installation
```bash
# Install Playwright
npm init playwright@latest

# Or install in existing project
npm install -D @playwright/test
npx playwright install

# Install specific browsers
npx playwright install chromium firefox webkit

# Install system dependencies (Linux)
npx playwright install-deps
```

### Configuration File
```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  // Test directory
  testDir: './tests',
  
  // Glob patterns for test files
  testMatch: '**/*.spec.ts',
  
  // Global test timeout
  timeout: 30000,
  
  // Expect timeout for assertions
  expect: {
    timeout: 5000
  },
  
  // Fail the build on CI if you accidentally left test.only in the source code
  forbidOnly: !!process.env.CI,
  
  // Retry on CI only
  retries: process.env.CI ? 2 : 0,
  
  // Opt out of parallel tests on CI
  workers: process.env.CI ? 1 : undefined,
  
  // Reporter configuration
  reporter: [
    ['html', { open: 'never' }],
    ['json', { outputFile: 'test-results.json' }],
    ['junit', { outputFile: 'test-results.xml' }],
    // Use 'github' reporter on CI
    process.env.CI ? ['github'] : ['list']
  ],
  
  // Global setup/teardown
  globalSetup: require.resolve('./global-setup'),
  globalTeardown: require.resolve('./global-teardown'),
  
  // Shared settings for all projects
  use: {
    // Base URL for all tests
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    
    // Collect trace when retrying the failed test
    trace: 'on-first-retry',
    
    // Record video only when retrying
    video: 'retain-on-failure',
    
    // Take screenshot only when retrying
    screenshot: 'only-on-failure',
    
    // Global test timeout
    actionTimeout: 10000,
    navigationTimeout: 30000,
    
    // Browser context options
    viewport: { width: 1280, height: 720 },
    ignoreHTTPSErrors: true,
    
    // Extra HTTP headers
    extraHTTPHeaders: {
      'Accept-Language': 'en-US,en;q=0.9'
    }
  },

  // Configure projects for major browsers
  projects: [
    {
      name: 'chromium',
      use: { 
        ...devices['Desktop Chrome'],
        // Chrome-specific options
        launchOptions: {
          args: ['--disable-dev-shm-usage']
        }
      },
    },
    
    {
      name: 'firefox',
      use: { 
        ...devices['Desktop Firefox'] 
      },
    },
    
    {
      name: 'webkit',
      use: { 
        ...devices['Desktop Safari'] 
      },
    },
    
    // Mobile browsers
    {
      name: 'Mobile Chrome',
      use: { 
        ...devices['Pixel 5'] 
      },
    },
    {
      name: 'Mobile Safari',
      use: { 
        ...devices['iPhone 12'] 
      },
    },
    
    // Microsoft Edge
    {
      name: 'Microsoft Edge',
      use: { 
        ...devices['Desktop Edge'], 
        channel: 'msedge' 
      },
    },
    
    // API testing
    {
      name: 'api',
      testMatch: '**/*.api.spec.ts',
      use: {
        // No browser needed for API tests
        baseURL: process.env.API_BASE_URL || 'http://localhost:3001/api'
      }
    }
  ],

  // Web server configuration
  webServer: {
    command: 'npm run start',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120000
  }
});
```

### Environment Configuration
```typescript
// global-setup.ts
import { chromium, FullConfig } from '@playwright/test';

async function globalSetup(config: FullConfig) {
  // Set up authentication
  if (process.env.NODE_ENV !== 'test') {
    const browser = await chromium.launch();
    const context = await browser.newContext();
    const page = await context.newPage();
    
    // Login and save authentication state
    await page.goto('/login');
    await page.fill('[data-testid="email"]', process.env.TEST_USER_EMAIL!);
    await page.fill('[data-testid="password"]', process.env.TEST_USER_PASSWORD!);
    await page.click('[data-testid="login-button"]');
    
    // Wait for successful login
    await page.waitForURL('/dashboard');
    
    // Save signed-in state
    await context.storageState({ path: 'auth-state.json' });
    
    await browser.close();
  }
  
  // Set up test database
  if (process.env.DATABASE_URL) {
    // Initialize test database
    console.log('Setting up test database...');
  }
}

export default globalSetup;
```

```typescript
// global-teardown.ts
import { FullConfig } from '@playwright/test';

async function globalTeardown(config: FullConfig) {
  // Clean up test data
  console.log('Cleaning up test data...');
  
  // Close database connections
  if (process.env.DATABASE_URL) {
    console.log('Closing database connections...');
  }
}

export default globalTeardown;
```

## Page Object Model

### Base Page Class
```typescript
// pages/base.page.ts
import { Page, Locator, expect } from '@playwright/test';

export class BasePage {
  readonly page: Page;
  
  constructor(page: Page) {
    this.page = page;
  }
  
  // Navigation helpers
  async goto(url: string) {
    await this.page.goto(url);
    await this.waitForPageLoad();
  }
  
  async waitForPageLoad() {
    await this.page.waitForLoadState('networkidle');
  }
  
  // Common element interactions
  async clickElement(locator: Locator) {
    await locator.waitFor({ state: 'visible' });
    await locator.click();
  }
  
  async fillField(locator: Locator, value: string) {
    await locator.waitFor({ state: 'visible' });
    await locator.fill(value);
  }
  
  async selectOption(locator: Locator, value: string) {
    await locator.waitFor({ state: 'visible' });
    await locator.selectOption(value);
  }
  
  // Wait helpers
  async waitForText(locator: Locator, text: string) {
    await expect(locator).toContainText(text);
  }
  
  async waitForElementVisible(locator: Locator) {
    await expect(locator).toBeVisible();
  }
  
  async waitForElementHidden(locator: Locator) {
    await expect(locator).toBeHidden();
  }
  
  // Alert/notification helpers
  async acceptDialog() {
    this.page.once('dialog', dialog => dialog.accept());
  }
  
  async dismissDialog() {
    this.page.once('dialog', dialog => dialog.dismiss());
  }
  
  // Screenshot helpers
  async takeScreenshot(name: string) {
    await this.page.screenshot({ 
      path: `screenshots/${name}.png`,
      fullPage: true 
    });
  }
  
  // Error handling
  async handleError(error: Error, context: string) {
    console.error(`Error in ${context}:`, error);
    await this.takeScreenshot(`error-${context}-${Date.now()}`);
    throw error;
  }
}
```

### Specific Page Classes
```typescript
// pages/login.page.ts
import { Page, Locator } from '@playwright/test';
import { BasePage } from './base.page';

export class LoginPage extends BasePage {
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly loginButton: Locator;
  readonly errorMessage: Locator;
  readonly forgotPasswordLink: Locator;
  readonly rememberMeCheckbox: Locator;
  
  constructor(page: Page) {
    super(page);
    this.emailInput = page.getByTestId('email');
    this.passwordInput = page.getByTestId('password');
    this.loginButton = page.getByTestId('login-button');
    this.errorMessage = page.getByTestId('error-message');
    this.forgotPasswordLink = page.getByText('Forgot password?');
    this.rememberMeCheckbox = page.getByTestId('remember-me');
  }
  
  async goto() {
    await super.goto('/login');
    await this.waitForElementVisible(this.loginButton);
  }
  
  async login(email: string, password: string, rememberMe: boolean = false) {
    try {
      await this.fillField(this.emailInput, email);
      await this.fillField(this.passwordInput, password);
      
      if (rememberMe) {
        await this.clickElement(this.rememberMeCheckbox);
      }
      
      await this.clickElement(this.loginButton);
      
      // Wait for navigation
      await this.page.waitForURL('/dashboard', { timeout: 10000 });
    } catch (error) {
      await this.handleError(error as Error, 'login');
    }
  }
  
  async loginWithInvalidCredentials(email: string, password: string) {
    await this.fillField(this.emailInput, email);
    await this.fillField(this.passwordInput, password);
    await this.clickElement(this.loginButton);
    
    // Wait for error message
    await this.waitForElementVisible(this.errorMessage);
  }
  
  async getErrorMessage(): Promise<string> {
    return await this.errorMessage.textContent() || '';
  }
  
  async clickForgotPassword() {
    await this.clickElement(this.forgotPasswordLink);
  }
}
```

```typescript
// pages/dashboard.page.ts
import { Page, Locator } from '@playwright/test';
import { BasePage } from './base.page';

export class DashboardPage extends BasePage {
  readonly welcomeMessage: Locator;
  readonly userMenu: Locator;
  readonly logoutButton: Locator;
  readonly navigationMenu: Locator;
  readonly loadingSpinner: Locator;
  
  constructor(page: Page) {
    super(page);
    this.welcomeMessage = page.getByTestId('welcome-message');
    this.userMenu = page.getByTestId('user-menu');
    this.logoutButton = page.getByTestId('logout-button');
    this.navigationMenu = page.getByTestId('navigation-menu');
    this.loadingSpinner = page.getByTestId('loading-spinner');
  }
  
  async goto() {
    await super.goto('/dashboard');
    await this.waitForDashboardLoad();
  }
  
  async waitForDashboardLoad() {
    await this.waitForElementHidden(this.loadingSpinner);
    await this.waitForElementVisible(this.welcomeMessage);
  }
  
  async getWelcomeMessage(): Promise<string> {
    return await this.welcomeMessage.textContent() || '';
  }
  
  async logout() {
    await this.clickElement(this.userMenu);
    await this.clickElement(this.logoutButton);
    await this.page.waitForURL('/login');
  }
  
  async navigateTo(section: string) {
    const link = this.navigationMenu.getByText(section);
    await this.clickElement(link);
  }
}
```

```typescript
// pages/user-management.page.ts
import { Page, Locator } from '@playwright/test';
import { BasePage } from './base.page';

export class UserManagementPage extends BasePage {
  readonly addUserButton: Locator;
  readonly userTable: Locator;
  readonly searchInput: Locator;
  readonly filterDropdown: Locator;
  readonly paginationNext: Locator;
  readonly paginationPrev: Locator;
  
  // Modal elements
  readonly addUserModal: Locator;
  readonly modalEmailInput: Locator;
  readonly modalFirstNameInput: Locator;
  readonly modalLastNameInput: Locator;
  readonly modalRoleSelect: Locator;
  readonly modalSaveButton: Locator;
  readonly modalCancelButton: Locator;
  
  constructor(page: Page) {
    super(page);
    this.addUserButton = page.getByTestId('add-user-button');
    this.userTable = page.getByTestId('user-table');
    this.searchInput = page.getByTestId('search-input');
    this.filterDropdown = page.getByTestId('filter-dropdown');
    this.paginationNext = page.getByTestId('pagination-next');
    this.paginationPrev = page.getByTestId('pagination-prev');
    
    // Modal
    this.addUserModal = page.getByTestId('add-user-modal');
    this.modalEmailInput = page.getByTestId('modal-email');
    this.modalFirstNameInput = page.getByTestId('modal-firstname');
    this.modalLastNameInput = page.getByTestId('modal-lastname');
    this.modalRoleSelect = page.getByTestId('modal-role');
    this.modalSaveButton = page.getByTestId('modal-save');
    this.modalCancelButton = page.getByTestId('modal-cancel');
  }
  
  async goto() {
    await super.goto('/users');
    await this.waitForElementVisible(this.userTable);
  }
  
  async addUser(userData: {
    email: string;
    firstName: string;
    lastName: string;
    role: string;
  }) {
    await this.clickElement(this.addUserButton);
    await this.waitForElementVisible(this.addUserModal);
    
    await this.fillField(this.modalEmailInput, userData.email);
    await this.fillField(this.modalFirstNameInput, userData.firstName);
    await this.fillField(this.modalLastNameInput, userData.lastName);
    await this.selectOption(this.modalRoleSelect, userData.role);
    
    await this.clickElement(this.modalSaveButton);
    
    // Wait for modal to close
    await this.waitForElementHidden(this.addUserModal);
  }
  
  async searchUser(searchTerm: string) {
    await this.fillField(this.searchInput, searchTerm);
    await this.page.keyboard.press('Enter');
    
    // Wait for search results
    await this.page.waitForTimeout(1000);
  }
  
  async getUserRowByEmail(email: string): Promise<Locator> {
    return this.userTable.locator(`tr:has-text("${email}")`);
  }
  
  async deleteUser(email: string) {
    const userRow = await this.getUserRowByEmail(email);
    const deleteButton = userRow.getByTestId('delete-button');
    
    await this.clickElement(deleteButton);
    
    // Confirm deletion
    this.acceptDialog();
  }
  
  async editUser(email: string, newData: Partial<{
    firstName: string;
    lastName: string;
    role: string;
  }>) {
    const userRow = await this.getUserRowByEmail(email);
    const editButton = userRow.getByTestId('edit-button');
    
    await this.clickElement(editButton);
    await this.waitForElementVisible(this.addUserModal);
    
    if (newData.firstName) {
      await this.fillField(this.modalFirstNameInput, newData.firstName);
    }
    if (newData.lastName) {
      await this.fillField(this.modalLastNameInput, newData.lastName);
    }
    if (newData.role) {
      await this.selectOption(this.modalRoleSelect, newData.role);
    }
    
    await this.clickElement(this.modalSaveButton);
    await this.waitForElementHidden(this.addUserModal);
  }
}
```

## Test Structure and Organization

### Basic Test Structure
```typescript
// tests/auth/login.spec.ts
import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/login.page';
import { DashboardPage } from '../pages/dashboard.page';

test.describe('Login Functionality', () => {
  let loginPage: LoginPage;
  let dashboardPage: DashboardPage;
  
  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    dashboardPage = new DashboardPage(page);
    await loginPage.goto();
  });
  
  test('should login successfully with valid credentials', async () => {
    const email = 'user@example.com';
    const password = 'password123';
    
    await loginPage.login(email, password);
    
    // Verify successful login
    await expect(dashboardPage.welcomeMessage).toBeVisible();
    const welcomeText = await dashboardPage.getWelcomeMessage();
    expect(welcomeText).toContain('Welcome');
  });
  
  test('should show error for invalid credentials', async () => {
    await loginPage.loginWithInvalidCredentials('invalid@example.com', 'wrongpassword');
    
    // Verify error message is displayed
    await expect(loginPage.errorMessage).toBeVisible();
    const errorText = await loginPage.getErrorMessage();
    expect(errorText).toContain('Invalid credentials');
  });
  
  test('should remember user when remember me is checked', async ({ page }) => {
    await loginPage.login('user@example.com', 'password123', true);
    
    // Close and reopen browser to check persistence
    await page.context().close();
    const newContext = await page.context().browser()?.newContext({
      storageState: 'auth-state.json'
    });
    
    if (newContext) {
      const newPage = await newContext.newPage();
      await newPage.goto('/dashboard');
      
      const newDashboardPage = new DashboardPage(newPage);
      await expect(newDashboardPage.welcomeMessage).toBeVisible();
    }
  });
  
  test('should redirect to forgot password page', async () => {
    await loginPage.clickForgotPassword();
    await expect(loginPage.page).toHaveURL('/forgot-password');
  });
});
```

### Parameterized Tests
```typescript
// tests/user-management/user-crud.spec.ts
import { test, expect } from '@playwright/test';
import { UserManagementPage } from '../pages/user-management.page';

test.describe('User CRUD Operations', () => {
  let userManagementPage: UserManagementPage;
  
  test.beforeEach(async ({ page }) => {
    // Use authenticated state
    await page.context().addCookies([
      {
        name: 'auth-token',
        value: process.env.TEST_AUTH_TOKEN!,
        domain: 'localhost',
        path: '/'
      }
    ]);
    
    userManagementPage = new UserManagementPage(page);
    await userManagementPage.goto();
  });
  
  const testUsers = [
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
    },
    {
      email: 'bob.moderator@example.com',
      firstName: 'Bob',
      lastName: 'Moderator',
      role: 'moderator'
    }
  ];
  
  testUsers.forEach(userData => {
    test(`should create user with role ${userData.role}`, async () => {
      await userManagementPage.addUser(userData);
      
      // Verify user appears in table
      const userRow = await userManagementPage.getUserRowByEmail(userData.email);
      await expect(userRow).toBeVisible();
      await expect(userRow).toContainText(userData.firstName);
      await expect(userRow).toContainText(userData.lastName);
      await expect(userRow).toContainText(userData.role);
    });
  });
  
  test('should search and filter users', async () => {
    // Add test data
    await userManagementPage.addUser(testUsers[0]);
    await userManagementPage.addUser(testUsers[1]);
    
    // Test search functionality
    await userManagementPage.searchUser('john.doe');
    
    const johnRow = await userManagementPage.getUserRowByEmail('john.doe@example.com');
    const janeRow = await userManagementPage.getUserRowByEmail('jane.admin@example.com');
    
    await expect(johnRow).toBeVisible();
    await expect(janeRow).not.toBeVisible();
  });
  
  test('should edit user information', async () => {
    const originalUser = testUsers[0];
    await userManagementPage.addUser(originalUser);
    
    const updatedData = {
      firstName: 'Johnny',
      lastName: 'Updated',
      role: 'moderator'
    };
    
    await userManagementPage.editUser(originalUser.email, updatedData);
    
    // Verify changes
    const userRow = await userManagementPage.getUserRowByEmail(originalUser.email);
    await expect(userRow).toContainText(updatedData.firstName);
    await expect(userRow).toContainText(updatedData.lastName);
    await expect(userRow).toContainText(updatedData.role);
  });
  
  test('should delete user', async () => {
    const userToDelete = testUsers[0];
    await userManagementPage.addUser(userToDelete);
    
    // Verify user exists
    let userRow = await userManagementPage.getUserRowByEmail(userToDelete.email);
    await expect(userRow).toBeVisible();
    
    // Delete user
    await userManagementPage.deleteUser(userToDelete.email);
    
    // Verify user is deleted
    userRow = await userManagementPage.getUserRowByEmail(userToDelete.email);
    await expect(userRow).not.toBeVisible();
  });
});
```

### Test Data Management
```typescript
// tests/fixtures/test-data.ts
export interface TestUser {
  id?: string;
  email: string;
  firstName: string;
  lastName: string;
  role: 'user' | 'admin' | 'moderator';
  password?: string;
}

export class TestDataManager {
  private createdUsers: TestUser[] = [];
  
  generateUser(overrides: Partial<TestUser> = {}): TestUser {
    const timestamp = Date.now();
    return {
      email: `test.user.${timestamp}@example.com`,
      firstName: `Test${timestamp}`,
      lastName: 'User',
      role: 'user',
      password: 'TestPassword123!',
      ...overrides
    };
  }
  
  generateUsers(count: number, overrides: Partial<TestUser> = {}): TestUser[] {
    return Array.from({ length: count }, () => this.generateUser(overrides));
  }
  
  trackUser(user: TestUser) {
    this.createdUsers.push(user);
  }
  
  getCreatedUsers(): TestUser[] {
    return this.createdUsers;
  }
  
  clearTrackedUsers() {
    this.createdUsers = [];
  }
}

// Fixture usage
import { test as base } from '@playwright/test';

type TestFixtures = {
  testDataManager: TestDataManager;
  testUser: TestUser;
};

export const test = base.extend<TestFixtures>({
  testDataManager: async ({}, use) => {
    const manager = new TestDataManager();
    await use(manager);
    
    // Cleanup tracked users after test
    const users = manager.getCreatedUsers();
    for (const user of users) {
      // API call to delete user
      console.log(`Cleaning up user: ${user.email}`);
    }
  },
  
  testUser: async ({ testDataManager }, use) => {
    const user = testDataManager.generateUser();
    testDataManager.trackUser(user);
    await use(user);
  }
});
```

## API Testing

### API Test Structure
```typescript
// tests/api/users.api.spec.ts
import { test, expect, APIRequestContext } from '@playwright/test';

test.describe('Users API', () => {
  let apiContext: APIRequestContext;
  let authToken: string;
  
  test.beforeAll(async ({ playwright }) => {
    apiContext = await playwright.request.newContext({
      baseURL: process.env.API_BASE_URL || 'http://localhost:3001/api',
      extraHTTPHeaders: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    });
    
    // Authenticate and get token
    const loginResponse = await apiContext.post('/auth/login', {
      data: {
        email: process.env.TEST_USER_EMAIL,
        password: process.env.TEST_USER_PASSWORD
      }
    });
    
    expect(loginResponse.ok()).toBeTruthy();
    const loginData = await loginResponse.json();
    authToken = loginData.accessToken;
  });
  
  test.afterAll(async () => {
    await apiContext.dispose();
  });
  
  test('should get users list', async () => {
    const response = await apiContext.get('/users', {
      headers: {
        'Authorization': `Bearer ${authToken}`
      },
      params: {
        page: '1',
        limit: '10'
      }
    });
    
    expect(response.ok()).toBeTruthy();
    expect(response.status()).toBe(200);
    
    const data = await response.json();
    expect(data).toHaveProperty('data');
    expect(data).toHaveProperty('pagination');
    expect(Array.isArray(data.data)).toBeTruthy();
    
    // Validate user structure
    if (data.data.length > 0) {
      const user = data.data[0];
      expect(user).toHaveProperty('id');
      expect(user).toHaveProperty('email');
      expect(user).toHaveProperty('firstName');
      expect(user).toHaveProperty('lastName');
      expect(user).toHaveProperty('role');
    }
  });
  
  test('should create a new user', async () => {
    const newUser = {
      email: `test.${Date.now()}@example.com`,
      firstName: 'Test',
      lastName: 'User',
      password: 'TestPassword123!',
      role: 'user'
    };
    
    const response = await apiContext.post('/users', {
      headers: {
        'Authorization': `Bearer ${authToken}`
      },
      data: newUser
    });
    
    expect(response.ok()).toBeTruthy();
    expect(response.status()).toBe(201);
    
    const data = await response.json();
    expect(data).toHaveProperty('data');
    
    const createdUser = data.data;
    expect(createdUser.email).toBe(newUser.email);
    expect(createdUser.firstName).toBe(newUser.firstName);
    expect(createdUser.lastName).toBe(newUser.lastName);
    expect(createdUser.role).toBe(newUser.role);
    expect(createdUser).toHaveProperty('id');
    expect(createdUser).toHaveProperty('createdAt');
    
    // Store for cleanup
    test.info().annotations.push({ type: 'user-id', description: createdUser.id });
  });
  
  test('should return validation error for invalid user data', async () => {
    const invalidUser = {
      email: 'invalid-email',
      firstName: '',
      password: '123' // Too short
    };
    
    const response = await apiContext.post('/users', {
      headers: {
        'Authorization': `Bearer ${authToken}`
      },
      data: invalidUser
    });
    
    expect(response.ok()).toBeFalsy();
    expect(response.status()).toBe(400);
    
    const data = await response.json();
    expect(data).toHaveProperty('error');
    expect(data).toHaveProperty('details');
    expect(Array.isArray(data.details)).toBeTruthy();
  });
  
  test('should update user information', async () => {
    // First create a user
    const createResponse = await apiContext.post('/users', {
      headers: {
        'Authorization': `Bearer ${authToken}`
      },
      data: {
        email: `update.test.${Date.now()}@example.com`,
        firstName: 'Original',
        lastName: 'User',
        password: 'TestPassword123!',
        role: 'user'
      }
    });
    
    const createData = await createResponse.json();
    const userId = createData.data.id;
    
    // Update the user
    const updateData = {
      firstName: 'Updated',
      lastName: 'Name'
    };
    
    const updateResponse = await apiContext.put(`/users/${userId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      },
      data: updateData
    });
    
    expect(updateResponse.ok()).toBeTruthy();
    expect(updateResponse.status()).toBe(200);
    
    const updatedData = await updateResponse.json();
    expect(updatedData.data.firstName).toBe(updateData.firstName);
    expect(updatedData.data.lastName).toBe(updateData.lastName);
  });
  
  test('should delete user', async () => {
    // First create a user
    const createResponse = await apiContext.post('/users', {
      headers: {
        'Authorization': `Bearer ${authToken}`
      },
      data: {
        email: `delete.test.${Date.now()}@example.com`,
        firstName: 'Delete',
        lastName: 'Me',
        password: 'TestPassword123!',
        role: 'user'
      }
    });
    
    const createData = await createResponse.json();
    const userId = createData.data.id;
    
    // Delete the user
    const deleteResponse = await apiContext.delete(`/users/${userId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });
    
    expect(deleteResponse.ok()).toBeTruthy();
    expect(deleteResponse.status()).toBe(204);
    
    // Verify user is deleted
    const getResponse = await apiContext.get(`/users/${userId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });
    
    expect(getResponse.status()).toBe(404);
  });
  
  test('should handle authentication errors', async () => {
    const response = await apiContext.get('/users');
    
    expect(response.status()).toBe(401);
    
    const data = await response.json();
    expect(data).toHaveProperty('error');
    expect(data.error).toContain('Unauthorized');
  });
});
```

### API Response Schema Validation
```typescript
// tests/api/schema-validation.spec.ts
import { test, expect } from '@playwright/test';
import Ajv, { JSONSchemaType } from 'ajv';
import addFormats from 'ajv-formats';

interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: 'user' | 'admin' | 'moderator';
  status: 'active' | 'inactive' | 'suspended';
  createdAt: string;
  updatedAt: string;
}

interface UserListResponse {
  data: User[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

const userSchema: JSONSchemaType<User> = {
  type: 'object',
  properties: {
    id: { type: 'string', format: 'uuid' },
    email: { type: 'string', format: 'email' },
    firstName: { type: 'string', minLength: 1 },
    lastName: { type: 'string', minLength: 1 },
    role: { type: 'string', enum: ['user', 'admin', 'moderator'] },
    status: { type: 'string', enum: ['active', 'inactive', 'suspended'] },
    createdAt: { type: 'string', format: 'date-time' },
    updatedAt: { type: 'string', format: 'date-time' }
  },
  required: ['id', 'email', 'firstName', 'lastName', 'role', 'status', 'createdAt', 'updatedAt'],
  additionalProperties: false
};

const userListSchema: JSONSchemaType<UserListResponse> = {
  type: 'object',
  properties: {
    data: {
      type: 'array',
      items: userSchema
    },
    pagination: {
      type: 'object',
      properties: {
        page: { type: 'number', minimum: 1 },
        limit: { type: 'number', minimum: 1, maximum: 100 },
        total: { type: 'number', minimum: 0 },
        totalPages: { type: 'number', minimum: 0 }
      },
      required: ['page', 'limit', 'total', 'totalPages'],
      additionalProperties: false
    }
  },
  required: ['data', 'pagination'],
  additionalProperties: false
};

test.describe('API Schema Validation', () => {
  let ajv: Ajv;
  
  test.beforeAll(() => {
    ajv = new Ajv();
    addFormats(ajv);
  });
  
  test('should validate user list response schema', async ({ request }) => {
    const response = await request.get('/api/users', {
      headers: {
        'Authorization': `Bearer ${process.env.TEST_AUTH_TOKEN}`
      }
    });
    
    expect(response.ok()).toBeTruthy();
    
    const data = await response.json();
    const validate = ajv.compile(userListSchema);
    const valid = validate(data);
    
    if (!valid) {
      console.error('Schema validation errors:', validate.errors);
    }
    
    expect(valid).toBeTruthy();
  });
});
```

## Visual Testing

### Visual Regression Tests
```typescript
// tests/visual/visual-regression.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Visual Regression Tests', () => {
  test('should match login page screenshot', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');
    
    // Hide dynamic elements that might cause flaky tests
    await page.addStyleTag({
      content: `
        .timestamp, .loading-spinner, .cursor-blink {
          display: none !important;
        }
      `
    });
    
    await expect(page).toHaveScreenshot('login-page.png');
  });
  
  test('should match dashboard layout across browsers', async ({ page, browserName }) => {
    await page.goto('/dashboard');
    await page.waitForSelector('[data-testid="welcome-message"]');
    
    // Wait for all images to load
    await page.evaluate(() => {
      return Promise.all(
        Array.from(document.images, img => {
          if (img.complete) return Promise.resolve();
          return new Promise(resolve => {
            img.onload = img.onerror = resolve;
          });
        })
      );
    });
    
    await expect(page).toHaveScreenshot(`dashboard-${browserName}.png`, {
      fullPage: true,
      threshold: 0.3 // Allow 30% difference for browser variations
    });
  });
  
  test('should match modal dialog appearance', async ({ page }) => {
    await page.goto('/users');
    await page.click('[data-testid="add-user-button"]');
    
    const modal = page.getByTestId('add-user-modal');
    await expect(modal).toBeVisible();
    
    // Screenshot only the modal
    await expect(modal).toHaveScreenshot('add-user-modal.png');
  });
  
  test('should handle responsive design', async ({ page }) => {
    // Test mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');
    
    await expect(page).toHaveScreenshot('dashboard-mobile.png');
    
    // Test tablet viewport
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.waitForLoadState('networkidle');
    
    await expect(page).toHaveScreenshot('dashboard-tablet.png');
    
    // Test desktop viewport
    await page.setViewportSize({ width: 1920, height: 1080 });
    await page.waitForLoadState('networkidle');
    
    await expect(page).toHaveScreenshot('dashboard-desktop.png');
  });
});
```

### Component Visual Testing
```typescript
// tests/visual/component-visual.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Component Visual Tests', () => {
  test('should render button variations correctly', async ({ page }) => {
    await page.goto('/styleguide');
    
    const buttonContainer = page.getByTestId('button-variations');
    await expect(buttonContainer).toHaveScreenshot('button-variations.png');
  });
  
  test('should render form components correctly', async ({ page }) => {
    await page.goto('/styleguide');
    
    const formContainer = page.getByTestId('form-components');
    await expect(formContainer).toHaveScreenshot('form-components.png');
  });
  
  test('should render data table with different states', async ({ page }) => {
    await page.goto('/styleguide');
    
    // Test empty state
    const emptyTable = page.getByTestId('empty-table');
    await expect(emptyTable).toHaveScreenshot('table-empty.png');
    
    // Test loading state
    const loadingTable = page.getByTestId('loading-table');
    await expect(loadingTable).toHaveScreenshot('table-loading.png');
    
    // Test error state
    const errorTable = page.getByTestId('error-table');
    await expect(errorTable).toHaveScreenshot('table-error.png');
    
    // Test populated state
    const populatedTable = page.getByTestId('populated-table');
    await expect(populatedTable).toHaveScreenshot('table-populated.png');
  });
});
```

## Performance Testing

### Performance Metrics
```typescript
// tests/performance/performance.spec.ts
import { test, expect, chromium } from '@playwright/test';

test.describe('Performance Tests', () => {
  test('should meet performance benchmarks', async ({ page }) => {
    // Enable performance tracking
    const client = await page.context().newCDPSession(page);
    await client.send('Performance.enable');
    
    const startTime = Date.now();
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');
    const endTime = Date.now();
    
    const loadTime = endTime - startTime;
    expect(loadTime).toBeLessThan(3000); // Should load in less than 3 seconds
    
    // Get performance metrics
    const metrics = await client.send('Performance.getMetrics');
    const metricsMap = new Map(
      metrics.metrics.map(metric => [metric.name, metric.value])
    );
    
    // Check specific metrics
    const jsHeapUsedSize = metricsMap.get('JSHeapUsedSize');
    const domNodes = metricsMap.get('Nodes');
    
    expect(jsHeapUsedSize).toBeLessThan(50 * 1024 * 1024); // Less than 50MB
    expect(domNodes).toBeLessThan(5000); // Less than 5000 DOM nodes
  });
  
  test('should handle large datasets efficiently', async ({ page }) => {
    // Navigate to page with large dataset
    await page.goto('/users?limit=100');
    
    // Measure rendering time
    const startTime = await page.evaluate(() => performance.now());
    await page.waitForSelector('[data-testid="user-table"] tbody tr:nth-child(100)');
    const endTime = await page.evaluate(() => performance.now());
    
    const renderTime = endTime - startTime;
    expect(renderTime).toBeLessThan(2000); // Should render 100 items in less than 2 seconds
  });
  
  test('should maintain performance during interactions', async ({ page }) => {
    await page.goto('/users');
    
    // Measure search performance
    const searchStartTime = Date.now();
    await page.fill('[data-testid="search-input"]', 'john');
    await page.waitForLoadState('networkidle');
    const searchEndTime = Date.now();
    
    const searchTime = searchEndTime - searchStartTime;
    expect(searchTime).toBeLessThan(1000); // Search should complete in less than 1 second
    
    // Measure pagination performance
    const paginationStartTime = Date.now();
    await page.click('[data-testid="pagination-next"]');
    await page.waitForLoadState('networkidle');
    const paginationEndTime = Date.now();
    
    const paginationTime = paginationEndTime - paginationStartTime;
    expect(paginationTime).toBeLessThan(1000);
  });
});
```

### Lighthouse Integration
```typescript
// tests/performance/lighthouse.spec.ts
import { test, expect } from '@playwright/test';
import { playAudit } from 'playwright-lighthouse';

test.describe('Lighthouse Performance Audits', () => {
  test('should pass lighthouse performance audit', async ({ page, browserName }) => {
    // Skip for non-Chromium browsers
    test.skip(browserName !== 'chromium', 'Lighthouse only works with Chromium');
    
    await page.goto('/dashboard');
    
    const audit = await playAudit({
      page,
      thresholds: {
        performance: 80,
        accessibility: 90,
        'best-practices': 80,
        seo: 80
      },
      reports: {
        formats: {
          html: true,
          json: true
        },
        directory: './lighthouse-reports',
        name: 'dashboard-audit'
      }
    });
    
    expect(audit.lhr.categories.performance.score! * 100).toBeGreaterThanOrEqual(80);
    expect(audit.lhr.categories.accessibility.score! * 100).toBeGreaterThanOrEqual(90);
  });
});
```

## Test Utilities and Helpers

### Custom Assertions
```typescript
// tests/utils/custom-assertions.ts
import { expect } from '@playwright/test';

export function expectToBeValidEmail(received: string) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  const pass = emailRegex.test(received);
  
  return {
    pass,
    message: () => pass
      ? `expected ${received} not to be a valid email`
      : `expected ${received} to be a valid email`,
    actual: received,
    expected: 'valid email format'
  };
}

export function expectToBeValidUUID(received: string) {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  const pass = uuidRegex.test(received);
  
  return {
    pass,
    message: () => pass
      ? `expected ${received} not to be a valid UUID`
      : `expected ${received} to be a valid UUID`,
    actual: received,
    expected: 'valid UUID format'
  };
}

// Extend expect
expect.extend({
  toBeValidEmail: expectToBeValidEmail,
  toBeValidUUID: expectToBeValidUUID
});

// Type definitions
declare module '@playwright/test' {
  interface Matchers<R> {
    toBeValidEmail(): R;
    toBeValidUUID(): R;
  }
}
```

### Test Utilities
```typescript
// tests/utils/test-utils.ts
import { Page, Locator, expect } from '@playwright/test';

export class TestUtils {
  readonly page: Page;
  
  constructor(page: Page) {
    this.page = page;
  }
  
  async waitForApiResponse(urlPattern: string | RegExp, timeout = 10000) {
    return this.page.waitForResponse(
      response => {
        const url = response.url();
        if (typeof urlPattern === 'string') {
          return url.includes(urlPattern);
        }
        return urlPattern.test(url);
      },
      { timeout }
    );
  }
  
  async waitForNoLoadingSpinners() {
    await this.page.waitForFunction(
      () => document.querySelectorAll('.loading-spinner, .spinner').length === 0,
      { timeout: 10000 }
    );
  }
  
  async scrollToElement(locator: Locator) {
    await locator.scrollIntoViewIfNeeded();
  }
  
  async dragAndDrop(source: Locator, target: Locator) {
    const sourceBounding = await source.boundingBox();
    const targetBounding = await target.boundingBox();
    
    if (sourceBounding && targetBounding) {
      await this.page.mouse.move(
        sourceBounding.x + sourceBounding.width / 2,
        sourceBounding.y + sourceBounding.height / 2
      );
      await this.page.mouse.down();
      await this.page.mouse.move(
        targetBounding.x + targetBounding.width / 2,
        targetBounding.y + targetBounding.height / 2
      );
      await this.page.mouse.up();
    }
  }
  
  async uploadFile(fileInput: Locator, filePath: string) {
    await fileInput.setInputFiles(filePath);
  }
  
  async clearBrowserData() {
    await this.page.context().clearCookies();
    await this.page.evaluate(() => {
      localStorage.clear();
      sessionStorage.clear();
    });
  }
  
  async mockApiResponse(url: string | RegExp, response: object, status = 200) {
    await this.page.route(url, route => {
      route.fulfill({
        status,
        contentType: 'application/json',
        body: JSON.stringify(response)
      });
    });
  }
  
  async interceptApiCall(url: string | RegExp): Promise<any> {
    return new Promise(resolve => {
      this.page.route(url, async route => {
        const response = await route.fetch();
        const json = await response.json();
        await route.fulfill({ response });
        resolve(json);
      });
    });
  }
  
  async getConsoleErrors(): Promise<string[]> {
    const errors: string[] = [];
    
    this.page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });
    
    return errors;
  }
  
  async getNetworkErrors() {
    const errors: any[] = [];
    
    this.page.on('response', response => {
      if (response.status() >= 400) {
        errors.push({
          url: response.url(),
          status: response.status(),
          statusText: response.statusText()
        });
      }
    });
    
    return errors;
  }
}
```

## CI/CD Integration

### GitHub Actions Workflow
```yaml
# .github/workflows/playwright.yml
name: Playwright Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    timeout-minutes: 60
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        browser: [chromium, firefox, webkit]
        
    steps:
    - uses: actions/checkout@v3
    
    - uses: actions/setup-node@v3
      with:
        node-version: 18
        cache: 'npm'
        
    - name: Install dependencies
      run: npm ci
      
    - name: Install Playwright Browsers
      run: npx playwright install --with-deps ${{ matrix.browser }}
      
    - name: Start application
      run: |
        npm run build
        npm run start &
        npx wait-on http://localhost:3000
        
    - name: Run Playwright tests
      run: npx playwright test --project=${{ matrix.browser }}
      env:
        BASE_URL: http://localhost:3000
        TEST_USER_EMAIL: ${{ secrets.TEST_USER_EMAIL }}
        TEST_USER_PASSWORD: ${{ secrets.TEST_USER_PASSWORD }}
        
    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: playwright-report-${{ matrix.browser }}
        path: playwright-report/
        retention-days: 30
        
    - name: Upload test screenshots
      uses: actions/upload-artifact@v3
      if: failure()
      with:
        name: playwright-screenshots-${{ matrix.browser }}
        path: test-results/
        retention-days: 30

  visual-regression:
    timeout-minutes: 30
    runs-on: ubuntu-latest
    needs: test
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: actions/setup-node@v3
      with:
        node-version: 18
        cache: 'npm'
        
    - name: Install dependencies
      run: npm ci
      
    - name: Install Playwright
      run: npx playwright install --with-deps chromium
      
    - name: Run visual regression tests
      run: npx playwright test tests/visual/ --project=chromium
      
    - name: Upload visual test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: visual-test-results
        path: |
          test-results/
          playwright-report/
```

### Test Reporting
```typescript
// playwright-report.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  reporter: [
    ['html', { 
      open: 'never',
      outputFolder: 'playwright-report' 
    }],
    ['json', { 
      outputFile: 'test-results/results.json' 
    }],
    ['junit', { 
      outputFile: 'test-results/results.xml' 
    }],
    ['@playwright/test/reporter', {
      outputFile: 'test-results/results.jsonl'
    }],
    // Custom reporter for Slack/Teams notifications
    ['./custom-reporter.ts']
  ]
});
```

```typescript
// custom-reporter.ts
import { Reporter, TestCase, TestResult } from '@playwright/test/reporter';

class CustomReporter implements Reporter {
  onBegin(config: any, suite: any) {
    console.log(`Starting test suite with ${suite.allTests().length} tests`);
  }

  onTestEnd(test: TestCase, result: TestResult) {
    if (result.status === 'failed') {
      console.log(`FAILED: ${test.title}`);
      
      // Send notification to Slack/Teams
      if (process.env.CI) {
        this.sendFailureNotification(test, result);
      }
    }
  }

  onEnd(result: any) {
    const { failed, passed, skipped } = result;
    
    console.log(`Tests completed: ${passed} passed, ${failed} failed, ${skipped} skipped`);
    
    if (failed > 0 && process.env.CI) {
      this.sendSummaryNotification(result);
    }
  }

  private async sendFailureNotification(test: TestCase, result: TestResult) {
    // Implement Slack/Teams notification logic
  }

  private async sendSummaryNotification(result: any) {
    // Implement summary notification logic
  }
}

export default CustomReporter;
```

## Common Pitfalls

1. **Not using proper selectors**: Use `data-testid` attributes instead of CSS classes or text content
2. **Missing waits**: Always wait for elements to be visible/stable before interacting
3. **Hardcoded timeouts**: Use dynamic waits instead of fixed timeouts
4. **Not cleaning up test data**: Implement proper test data cleanup
5. **Flaky tests**: Address timing issues and unstable elements
6. **Poor page object organization**: Keep page objects focused and maintainable
7. **Not testing error states**: Include negative test scenarios
8. **Missing mobile testing**: Test responsive designs across different viewports
9. **Not using parallelization**: Configure proper test parallelization for faster execution
10. **Inadequate reporting**: Implement comprehensive test reporting and failure analysis