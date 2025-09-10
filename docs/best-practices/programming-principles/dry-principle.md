# DRY Principle - Don't Repeat Yourself

## Overview

The DRY (Don't Repeat Yourself) principle states that "Every piece of knowledge must have a single, unambiguous, authoritative representation within a system." This principle was formulated by Andy Hunt and Dave Thomas in their book "The Pragmatic Programmer."

## Core Concept

DRY is about avoiding duplication of:
- **Code logic**
- **Business rules**
- **Configuration**
- **Documentation**
- **Data structures**
- **Algorithms**

The key insight is that duplication leads to maintenance nightmares, inconsistency, and bugs.

## Types of Duplication

### 1. Imposed Duplication
Duplication that seems unavoidable due to external constraints.

```typescript
// Bad: Imposed duplication in type definitions
interface UserAPI {
  id: string;
  name: string;
  email: string;
  createdAt: string; // API returns string
}

interface UserModel {
  id: string;
  name: string;
  email: string;
  createdAt: Date; // Model uses Date object
}

// Good: Use transformation with shared base
interface BaseUser {
  id: string;
  name: string;
  email: string;
}

interface UserAPI extends BaseUser {
  createdAt: string;
}

interface UserModel extends BaseUser {
  createdAt: Date;
}

// Transform function eliminates duplication
function apiToModel(apiUser: UserAPI): UserModel {
  return {
    ...apiUser,
    createdAt: new Date(apiUser.createdAt)
  };
}
```

### 2. Inadvertent Duplication
Duplication that happens by accident, often due to lack of awareness.

```typescript
// Bad: Inadvertent duplication of validation logic
class UserService {
  createUser(userData: UserData): User {
    // Validation logic duplicated
    if (!userData.email || !userData.email.includes('@')) {
      throw new Error('Invalid email');
    }
    if (!userData.name || userData.name.length < 2) {
      throw new Error('Name too short');
    }
    
    return new User(userData);
  }
  
  updateUser(id: string, userData: UserData): User {
    // Same validation logic duplicated here
    if (!userData.email || !userData.email.includes('@')) {
      throw new Error('Invalid email');
    }
    if (!userData.name || userData.name.length < 2) {
      throw new Error('Name too short');
    }
    
    const user = this.findById(id);
    return user.update(userData);
  }
}

// Good: Extract validation to eliminate duplication
class UserValidator {
  static validate(userData: UserData): void {
    if (!userData.email || !this.isValidEmail(userData.email)) {
      throw new Error('Invalid email');
    }
    if (!userData.name || userData.name.length < 2) {
      throw new Error('Name too short');
    }
  }
  
  private static isValidEmail(email: string): boolean {
    return email.includes('@') && email.includes('.');
  }
}

class UserService {
  createUser(userData: UserData): User {
    UserValidator.validate(userData);
    return new User(userData);
  }
  
  updateUser(id: string, userData: UserData): User {
    UserValidator.validate(userData);
    const user = this.findById(id);
    return user.update(userData);
  }
}
```

### 3. Impatient Duplication
Duplication introduced by developers in a hurry.

```typescript
// Bad: Copy-paste programming
function calculateOrderTax(order: Order): number {
  let tax = 0;
  for (const item of order.items) {
    tax += item.price * item.quantity * 0.08; // Tax rate hardcoded
  }
  return tax;
}

function calculateInvoiceTax(invoice: Invoice): number {
  let tax = 0;
  for (const lineItem of invoice.lineItems) {
    tax += lineItem.amount * 0.08; // Tax rate duplicated and hardcoded
  }
  return tax;
}

// Good: Extract common logic
class TaxCalculator {
  private static readonly TAX_RATE = 0.08;
  
  static calculateTax(amount: number): number {
    return amount * this.TAX_RATE;
  }
  
  static calculateTotalTax(amounts: number[]): number {
    return amounts.reduce((total, amount) => total + this.calculateTax(amount), 0);
  }
}

function calculateOrderTax(order: Order): number {
  const amounts = order.items.map(item => item.price * item.quantity);
  return TaxCalculator.calculateTotalTax(amounts);
}

function calculateInvoiceTax(invoice: Invoice): number {
  const amounts = invoice.lineItems.map(item => item.amount);
  return TaxCalculator.calculateTotalTax(amounts);
}
```

### 4. Interdeveloper Duplication
Duplication across different modules or teams.

```typescript
// Bad: Multiple teams implementing similar functionality
// Team A's implementation
class TeamAUserService {
  async fetchUser(id: string): Promise<User> {
    const response = await fetch(`/api/users/${id}`, {
      headers: { 'Authorization': `Bearer ${this.getToken()}` }
    });
    if (!response.ok) {
      throw new Error('User not found');
    }
    return response.json();
  }
  
  private getToken(): string {
    return localStorage.getItem('auth_token') || '';
  }
}

// Team B's implementation (duplicates HTTP logic)
class TeamBProductService {
  async fetchProduct(id: string): Promise<Product> {
    const response = await fetch(`/api/products/${id}`, {
      headers: { 'Authorization': `Bearer ${this.getToken()}` }
    });
    if (!response.ok) {
      throw new Error('Product not found');
    }
    return response.json();
  }
  
  private getToken(): string {
    return localStorage.getItem('auth_token') || '';
  }
}

// Good: Shared HTTP client eliminates duplication
class ApiClient {
  private baseUrl: string;
  
  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }
  
  async get<T>(endpoint: string): Promise<T> {
    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      headers: { 'Authorization': `Bearer ${this.getToken()}` }
    });
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    
    return response.json();
  }
  
  private getToken(): string {
    return localStorage.getItem('auth_token') || '';
  }
}

class UserService {
  constructor(private apiClient: ApiClient) {}
  
  async fetchUser(id: string): Promise<User> {
    return this.apiClient.get<User>(`/users/${id}`);
  }
}

class ProductService {
  constructor(private apiClient: ApiClient) {}
  
  async fetchProduct(id: string): Promise<Product> {
    return this.apiClient.get<Product>(`/products/${id}`);
  }
}
```

## DRY Implementation Strategies

### 1. Extract Functions/Methods
```typescript
// Bad: Repeated calculations
class PriceCalculator {
  calculateProductPrice(product: Product): number {
    return product.basePrice + (product.basePrice * 0.1); // Tax
  }
  
  calculateServicePrice(service: Service): number {
    return service.basePrice + (service.basePrice * 0.1); // Tax duplicated
  }
}

// Good: Extract common calculation
class PriceCalculator {
  private static readonly TAX_RATE = 0.1;
  
  private static addTax(basePrice: number): number {
    return basePrice + (basePrice * this.TAX_RATE);
  }
  
  calculateProductPrice(product: Product): number {
    return this.addTax(product.basePrice);
  }
  
  calculateServicePrice(service: Service): number {
    return this.addTax(service.basePrice);
  }
}
```

### 2. Use Constants and Configuration
```typescript
// Bad: Magic numbers and strings scattered throughout code
class EmailService {
  sendWelcomeEmail(user: User): void {
    this.send(user.email, 'Welcome!', this.buildTemplate(), 'noreply@company.com');
  }
  
  sendPasswordReset(user: User): void {
    this.send(user.email, 'Password Reset', this.buildResetTemplate(), 'noreply@company.com');
  }
}

// Good: Centralized configuration
class EmailConfig {
  static readonly FROM_ADDRESS = 'noreply@company.com';
  static readonly SUBJECTS = {
    WELCOME: 'Welcome!',
    PASSWORD_RESET: 'Password Reset',
    ORDER_CONFIRMATION: 'Order Confirmation'
  } as const;
}

class EmailService {
  sendWelcomeEmail(user: User): void {
    this.send(
      user.email, 
      EmailConfig.SUBJECTS.WELCOME, 
      this.buildTemplate(), 
      EmailConfig.FROM_ADDRESS
    );
  }
  
  sendPasswordReset(user: User): void {
    this.send(
      user.email, 
      EmailConfig.SUBJECTS.PASSWORD_RESET, 
      this.buildResetTemplate(), 
      EmailConfig.FROM_ADDRESS
    );
  }
}
```

### 3. Template Method Pattern
```typescript
// Bad: Duplicated process structure
class OrderProcessor {
  processOnlineOrder(order: OnlineOrder): void {
    this.validateOrder(order);
    this.calculatePricing(order);
    this.applyOnlineDiscount(order);
    this.processPayment(order);
    this.updateInventory(order);
    this.sendConfirmation(order);
  }
  
  processPhoneOrder(order: PhoneOrder): void {
    this.validateOrder(order);
    this.calculatePricing(order);
    this.applyPhoneDiscount(order);
    this.processPayment(order);
    this.updateInventory(order);
    this.sendConfirmation(order);
  }
}

// Good: Template method eliminates structural duplication
abstract class OrderProcessor {
  // Template method defines the algorithm structure
  processOrder(order: Order): void {
    this.validateOrder(order);
    this.calculatePricing(order);
    this.applyDiscount(order); // Abstract method
    this.processPayment(order);
    this.updateInventory(order);
    this.sendConfirmation(order);
  }
  
  protected validateOrder(order: Order): void {
    // Common validation logic
  }
  
  protected calculatePricing(order: Order): void {
    // Common pricing logic
  }
  
  protected abstract applyDiscount(order: Order): void;
  
  protected processPayment(order: Order): void {
    // Common payment logic
  }
  
  protected updateInventory(order: Order): void {
    // Common inventory logic
  }
  
  protected sendConfirmation(order: Order): void {
    // Common confirmation logic
  }
}

class OnlineOrderProcessor extends OrderProcessor {
  protected applyDiscount(order: Order): void {
    // Online-specific discount logic
    order.applyPercentageDiscount(0.05);
  }
}

class PhoneOrderProcessor extends OrderProcessor {
  protected applyDiscount(order: Order): void {
    // Phone-specific discount logic
    order.applyFixedDiscount(10);
  }
}
```

### 4. Higher-Order Functions
```typescript
// Bad: Repeated array processing patterns
class DataProcessor {
  processUsers(users: User[]): ProcessedUser[] {
    const result: ProcessedUser[] = [];
    for (const user of users) {
      if (user.isActive) {
        result.push(this.transformUser(user));
      }
    }
    return result;
  }
  
  processProducts(products: Product[]): ProcessedProduct[] {
    const result: ProcessedProduct[] = [];
    for (const product of products) {
      if (product.isAvailable) {
        result.push(this.transformProduct(product));
      }
    }
    return result;
  }
}

// Good: Higher-order function eliminates pattern duplication
class DataProcessor {
  private static filterAndTransform<T, R>(
    items: T[],
    predicate: (item: T) => boolean,
    transformer: (item: T) => R
  ): R[] {
    return items.filter(predicate).map(transformer);
  }
  
  processUsers(users: User[]): ProcessedUser[] {
    return DataProcessor.filterAndTransform(
      users,
      user => user.isActive,
      user => this.transformUser(user)
    );
  }
  
  processProducts(products: Product[]): ProcessedProduct[] {
    return DataProcessor.filterAndTransform(
      products,
      product => product.isAvailable,
      product => this.transformProduct(product)
    );
  }
}
```

### 5. Configuration-Driven Development
```typescript
// Bad: Hardcoded business rules
class PricingEngine {
  calculatePrice(product: Product, customer: Customer): number {
    let price = product.basePrice;
    
    // Premium customers get 10% discount
    if (customer.tier === 'premium') {
      price *= 0.9;
    }
    
    // Electronics have 15% tax
    if (product.category === 'electronics') {
      price *= 1.15;
    }
    
    // Orders over $100 get free shipping
    if (price > 100) {
      // Free shipping
    } else {
      price += 10; // Shipping cost
    }
    
    return price;
  }
}

// Good: Configuration-driven pricing
interface PricingRule {
  condition: (product: Product, customer: Customer, currentPrice: number) => boolean;
  action: (currentPrice: number) => number;
}

class PricingEngine {
  private rules: PricingRule[] = [
    {
      condition: (_, customer) => customer.tier === 'premium',
      action: (price) => price * 0.9
    },
    {
      condition: (product) => product.category === 'electronics',
      action: (price) => price * 1.15
    },
    {
      condition: (_, __, price) => price <= 100,
      action: (price) => price + 10
    }
  ];
  
  calculatePrice(product: Product, customer: Customer): number {
    return this.rules.reduce((price, rule) => {
      if (rule.condition(product, customer, price)) {
        return rule.action(price);
      }
      return price;
    }, product.basePrice);
  }
  
  addRule(rule: PricingRule): void {
    this.rules.push(rule);
  }
}
```

## DRY in Different Domains

### Database Schema
```sql
-- Bad: Duplicated address structure
CREATE TABLE users (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255),
    street VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    zip VARCHAR(255)
);

CREATE TABLE companies (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    street VARCHAR(255),    -- Duplicated address structure
    city VARCHAR(255),
    state VARCHAR(255),
    zip VARCHAR(255)
);

-- Good: Extract address to separate table
CREATE TABLE addresses (
    id UUID PRIMARY KEY,
    street VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    zip VARCHAR(255)
);

CREATE TABLE users (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255),
    address_id UUID REFERENCES addresses(id)
);

CREATE TABLE companies (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    address_id UUID REFERENCES addresses(id)
);
```

### CSS Styles
```css
/* Bad: Repeated styles */
.primary-button {
    background-color: #007bff;
    color: white;
    border: none;
    padding: 10px 20px;
    border-radius: 4px;
    cursor: pointer;
}

.secondary-button {
    background-color: #6c757d;
    color: white;
    border: none;
    padding: 10px 20px;    /* Duplicated */
    border-radius: 4px;    /* Duplicated */
    cursor: pointer;       /* Duplicated */
}

/* Good: Use base class and variants */
.btn {
    border: none;
    padding: 10px 20px;
    border-radius: 4px;
    cursor: pointer;
    color: white;
}

.btn-primary {
    background-color: #007bff;
}

.btn-secondary {
    background-color: #6c757d;
}
```

### Documentation
```typescript
/**
 * Bad: Duplicated documentation
 */
class UserService {
  /**
   * Creates a new user
   * @param userData - The user data containing name, email, and password
   * @param userData.name - User's full name (required, min 2 chars)
   * @param userData.email - User's email address (required, valid email)
   * @param userData.password - User's password (required, min 8 chars)
   */
  createUser(userData: UserData): User { /* ... */ }
  
  /**
   * Updates an existing user
   * @param id - User ID
   * @param userData - The user data containing name, email, and password
   * @param userData.name - User's full name (required, min 2 chars)  // Duplicated
   * @param userData.email - User's email address (required, valid email)  // Duplicated  
   * @param userData.password - User's password (required, min 8 chars)  // Duplicated
   */
  updateUser(id: string, userData: UserData): User { /* ... */ }
}

/**
 * Good: Reference shared documentation
 */
/**
 * @typedef {Object} UserData
 * @property {string} name - User's full name (required, min 2 chars)
 * @property {string} email - User's email address (required, valid email)
 * @property {string} password - User's password (required, min 8 chars)
 */

class UserService {
  /**
   * Creates a new user
   * @param {UserData} userData - The user data
   */
  createUser(userData: UserData): User { /* ... */ }
  
  /**
   * Updates an existing user
   * @param {string} id - User ID
   * @param {UserData} userData - The user data
   */
  updateUser(id: string, userData: UserData): User { /* ... */ }
}
```

## When NOT to Apply DRY

### 1. Coincidental Duplication
```typescript
// These look similar but represent different concepts
class BankAccount {
  withdraw(amount: number): void {
    if (amount > this.balance) {
      throw new Error('Insufficient funds');
    }
    this.balance -= amount;
  }
}

class InventoryItem {
  reserve(quantity: number): void {
    if (quantity > this.available) {
      throw new Error('Insufficient inventory'); // Don't DRY this with BankAccount
    }
    this.available -= quantity;
  }
}
```

### 2. Premature Abstraction
```typescript
// Bad: Premature abstraction based on similar code
class GenericValidator {
  validate(value: any, rules: any[]): boolean {
    // Overly generic validation that's hard to maintain
    return rules.every(rule => rule.check(value));
  }
}

// Good: Keep separate until patterns emerge
class EmailValidator {
  validate(email: string): boolean {
    return email.includes('@') && email.includes('.');
  }
}

class PasswordValidator {
  validate(password: string): boolean {
    return password.length >= 8 && /[A-Z]/.test(password);
  }
}
```

### 3. Different Rates of Change
```typescript
// These methods look similar but change for different reasons
class ReportGenerator {
  // Changes based on accounting requirements
  generateFinancialReport(): string {
    return `Revenue: ${this.calculateRevenue()}`;
  }
  
  // Changes based on HR requirements
  generateHRReport(): string {
    return `Employees: ${this.countEmployees()}`;
  }
}
```

## DRY Best Practices

1. **Identify True Duplication**: Ensure duplication represents the same knowledge
2. **Consider the Context**: Duplication in different contexts might be acceptable
3. **Extract Gradually**: Don't create abstractions until you have 3+ similar cases
4. **Use Meaningful Names**: Extracted code should have clear, descriptive names
5. **Maintain Single Source of Truth**: Each piece of knowledge should have one authoritative representation
6. **Document Shared Code**: Well-documented shared code prevents misuse
7. **Version Shared Dependencies**: Use semantic versioning for shared libraries
8. **Test Thoroughly**: Shared code needs comprehensive testing
9. **Consider Performance**: Sometimes duplication is faster than abstraction
10. **Balance with Other Principles**: DRY should complement, not override, other design principles

## Tools for Managing DRY

- **Linters**: ESLint rules for detecting code duplication
- **Code Analysis**: SonarQube, CodeClimate for duplication detection
- **Templates**: Code generators and scaffolding tools
- **Shared Libraries**: npm packages, internal libraries
- **Configuration Management**: Environment-specific configurations
- **Documentation Tools**: Tools that sync documentation with code

## Measuring DRY Compliance

```typescript
// Metrics to track
interface DRYMetrics {
  duplicatedLines: number;
  duplicatedBlocks: number;
  duplicatedFiles: number;
  abstractionLevel: number;
  reusabilityScore: number;
}

// Example duplication detection
function detectDuplication(codebase: string[]): DRYMetrics {
  // Implementation would analyze code for patterns
  return {
    duplicatedLines: 150,
    duplicatedBlocks: 12,
    duplicatedFiles: 3,
    abstractionLevel: 0.75,
    reusabilityScore: 0.82
  };
}
```

The DRY principle is fundamental to maintainable software but should be applied judiciously. Focus on eliminating meaningful duplication while avoiding premature abstraction that can make code more complex than necessary.