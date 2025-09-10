# SOLID Principles

## Official Documentation & Resources
- **Robert C. Martin (Uncle Bob)**: https://blog.cleancoder.com/uncle-bob/2020/10/18/Solid-Relevance.html
- **SOLID Principles Explained**: https://scotch.io/bar-talk/s-o-l-i-d-the-first-five-principles-of-object-oriented-design
- **Clean Architecture Book**: https://www.amazon.com/Clean-Architecture-Craftsmans-Software-Structure/dp/0134494164
- **Martin Fowler on SOLID**: https://martinfowler.com/tags/solid.html

## Introduction

SOLID is an acronym for five design principles intended to make software designs more understandable, flexible, and maintainable. These principles were introduced by Robert C. Martin (Uncle Bob) and form the foundation of clean, object-oriented design.

## The Five SOLID Principles

### 1. Single Responsibility Principle (SRP)

**Definition**: A class should have only one reason to change, meaning it should have only one job or responsibility.

#### Good Example - JavaScript/TypeScript

```typescript
// L Bad: Multiple responsibilities
class User {
    constructor(
        public name: string,
        public email: string
    ) {}

    // User data responsibility
    getName(): string {
        return this.name;
    }

    // Email validation responsibility
    validateEmail(): boolean {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.email);
    }

    // Persistence responsibility
    save(): void {
        // Save to database
        console.log('Saving user to database');
    }

    // Email sending responsibility
    sendWelcomeEmail(): void {
        console.log('Sending welcome email');
    }
}

//  Good: Single responsibilities
class User {
    constructor(
        public name: string,
        public email: string
    ) {}

    getName(): string {
        return this.name;
    }

    getEmail(): string {
        return this.email;
    }
}

class EmailValidator {
    static validate(email: string): boolean {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }
}

class UserRepository {
    save(user: User): void {
        console.log('Saving user to database');
    }
}

class EmailService {
    sendWelcomeEmail(user: User): void {
        console.log(`Sending welcome email to ${user.getEmail()}`);
    }
}
```

#### Python Example

```python
# L Bad: Multiple responsibilities
class Order:
    def __init__(self, items):
        self.items = items
    
    def calculate_total(self):
        return sum(item.price for item in self.items)
    
    def print_invoice(self):
        # Printing responsibility
        print(f"Invoice Total: ${self.calculate_total()}")
    
    def save_to_database(self):
        # Persistence responsibility
        print("Saving order to database")

#  Good: Single responsibilities
class Order:
    def __init__(self, items):
        self.items = items
    
    def calculate_total(self):
        return sum(item.price for item in self.items)

class InvoicePrinter:
    @staticmethod
    def print_invoice(order):
        print(f"Invoice Total: ${order.calculate_total()}")

class OrderRepository:
    @staticmethod
    def save(order):
        print("Saving order to database")
```

#### Java Example

```java
// L Bad: Multiple responsibilities
public class Employee {
    private String name;
    private double salary;
    
    public Employee(String name, double salary) {
        this.name = name;
        this.salary = salary;
    }
    
    // Employee data responsibility
    public String getName() { return name; }
    public double getSalary() { return salary; }
    
    // Tax calculation responsibility
    public double calculateTax() {
        return salary * 0.2;
    }
    
    // Reporting responsibility
    public void printReport() {
        System.out.println("Employee: " + name + ", Salary: " + salary);
    }
    
    // Persistence responsibility
    public void saveToDatabase() {
        System.out.println("Saving employee to database");
    }
}

//  Good: Single responsibilities
public class Employee {
    private String name;
    private double salary;
    
    public Employee(String name, double salary) {
        this.name = name;
        this.salary = salary;
    }
    
    public String getName() { return name; }
    public double getSalary() { return salary; }
}

public class TaxCalculator {
    public static double calculateTax(Employee employee) {
        return employee.getSalary() * 0.2;
    }
}

public class EmployeeReportGenerator {
    public static void printReport(Employee employee) {
        System.out.println("Employee: " + employee.getName() + 
                          ", Salary: " + employee.getSalary());
    }
}

public class EmployeeRepository {
    public void save(Employee employee) {
        System.out.println("Saving employee to database");
    }
}
```

### 2. Open/Closed Principle (OCP)

**Definition**: Software entities should be open for extension but closed for modification. You should be able to extend behavior without modifying existing code.

#### TypeScript Example

```typescript
// L Bad: Modification required for new shapes
class Rectangle {
    constructor(public width: number, public height: number) {}
}

class Circle {
    constructor(public radius: number) {}
}

class AreaCalculator {
    calculateArea(shape: any): number {
        if (shape instanceof Rectangle) {
            return shape.width * shape.height;
        } else if (shape instanceof Circle) {
            return Math.PI * shape.radius * shape.radius;
        }
        // Need to modify this method for new shapes
        throw new Error('Unknown shape');
    }
}

//  Good: Open for extension, closed for modification
interface Shape {
    calculateArea(): number;
}

class Rectangle implements Shape {
    constructor(private width: number, private height: number) {}
    
    calculateArea(): number {
        return this.width * this.height;
    }
}

class Circle implements Shape {
    constructor(private radius: number) {}
    
    calculateArea(): number {
        return Math.PI * this.radius * this.radius;
    }
}

class Triangle implements Shape {
    constructor(private base: number, private height: number) {}
    
    calculateArea(): number {
        return (this.base * this.height) / 2;
    }
}

class AreaCalculator {
    calculateArea(shape: Shape): number {
        return shape.calculateArea(); // No modification needed for new shapes
    }
    
    calculateTotalArea(shapes: Shape[]): number {
        return shapes.reduce((total, shape) => total + shape.calculateArea(), 0);
    }
}
```

#### Python Example

```python
from abc import ABC, abstractmethod

#  Good: Using strategy pattern
class PaymentProcessor(ABC):
    @abstractmethod
    def process_payment(self, amount: float) -> bool:
        pass

class CreditCardProcessor(PaymentProcessor):
    def process_payment(self, amount: float) -> bool:
        print(f"Processing ${amount} via Credit Card")
        return True

class PayPalProcessor(PaymentProcessor):
    def process_payment(self, amount: float) -> bool:
        print(f"Processing ${amount} via PayPal")
        return True

class CryptocurrencyProcessor(PaymentProcessor):
    def process_payment(self, amount: float) -> bool:
        print(f"Processing ${amount} via Cryptocurrency")
        return True

class PaymentService:
    def __init__(self, processor: PaymentProcessor):
        self.processor = processor
    
    def process_order_payment(self, amount: float) -> bool:
        return self.processor.process_payment(amount)

# Usage - no modification needed for new payment types
credit_service = PaymentService(CreditCardProcessor())
paypal_service = PaymentService(PayPalProcessor())
crypto_service = PaymentService(CryptocurrencyProcessor())
```

### 3. Liskov Substitution Principle (LSP)

**Definition**: Objects of a superclass should be replaceable with objects of subclasses without breaking the application functionality.

#### TypeScript Example

```typescript
// L Bad: LSP violation
class Bird {
    fly(): void {
        console.log('Flying high!');
    }
}

class Penguin extends Bird {
    fly(): void {
        throw new Error('Penguins cannot fly!'); // Breaks LSP
    }
}

function makeBirdFly(bird: Bird): void {
    bird.fly(); // Will throw error for Penguin
}

//  Good: LSP compliant
abstract class Bird {
    abstract move(): void;
}

class FlyingBird extends Bird {
    move(): void {
        this.fly();
    }
    
    fly(): void {
        console.log('Flying high!');
    }
}

class SwimmingBird extends Bird {
    move(): void {
        this.swim();
    }
    
    swim(): void {
        console.log('Swimming gracefully!');
    }
}

class Eagle extends FlyingBird {
    fly(): void {
        console.log('Eagle soaring!');
    }
}

class Penguin extends SwimmingBird {
    swim(): void {
        console.log('Penguin swimming!');
    }
}

function makeBirdMove(bird: Bird): void {
    bird.move(); // Works for all bird types
}
```

#### Python Example

```python
# L Bad: LSP violation
class Rectangle:
    def __init__(self, width, height):
        self._width = width
        self._height = height
    
    def set_width(self, width):
        self._width = width
    
    def set_height(self, height):
        self._height = height
    
    def get_area(self):
        return self._width * self._height

class Square(Rectangle):
    def set_width(self, width):
        self._width = width
        self._height = width  # Violates LSP - unexpected behavior
    
    def set_height(self, height):
        self._height = height
        self._width = height  # Violates LSP - unexpected behavior

#  Good: LSP compliant
from abc import ABC, abstractmethod

class Shape(ABC):
    @abstractmethod
    def get_area(self):
        pass

class Rectangle(Shape):
    def __init__(self, width, height):
        self._width = width
        self._height = height
    
    def get_area(self):
        return self._width * self._height

class Square(Shape):
    def __init__(self, side):
        self._side = side
    
    def get_area(self):
        return self._side * self._side

def calculate_area(shape: Shape):
    return shape.get_area()  # Works correctly for all shapes
```

### 4. Interface Segregation Principle (ISP)

**Definition**: No client should be forced to depend on methods it does not use. Create specific interfaces rather than one general-purpose interface.

#### TypeScript Example

```typescript
// L Bad: Fat interface
interface Worker {
    work(): void;
    eat(): void;
    sleep(): void;
    code(): void;
    designUI(): void;
    manageTeam(): void;
}

class Developer implements Worker {
    work(): void { console.log('Coding...'); }
    eat(): void { console.log('Eating...'); }
    sleep(): void { console.log('Sleeping...'); }
    code(): void { console.log('Writing code...'); }
    designUI(): void { 
        throw new Error('Developers don\'t design UI'); // Forced to implement
    }
    manageTeam(): void { 
        throw new Error('Developers don\'t manage teams'); // Forced to implement
    }
}

//  Good: Segregated interfaces
interface Workable {
    work(): void;
}

interface Eatable {
    eat(): void;
}

interface Sleepable {
    sleep(): void;
}

interface Codeable {
    code(): void;
}

interface Designable {
    designUI(): void;
}

interface Manageable {
    manageTeam(): void;
}

class Developer implements Workable, Eatable, Sleepable, Codeable {
    work(): void { console.log('Coding...'); }
    eat(): void { console.log('Eating...'); }
    sleep(): void { console.log('Sleeping...'); }
    code(): void { console.log('Writing code...'); }
}

class Designer implements Workable, Eatable, Sleepable, Designable {
    work(): void { console.log('Designing...'); }
    eat(): void { console.log('Eating...'); }
    sleep(): void { console.log('Sleeping...'); }
    designUI(): void { console.log('Designing beautiful UI...'); }
}

class Manager implements Workable, Eatable, Sleepable, Manageable {
    work(): void { console.log('Managing...'); }
    eat(): void { console.log('Eating...'); }
    sleep(): void { console.log('Sleeping...'); }
    manageTeam(): void { console.log('Managing the team...'); }
}
```

#### Java Example

```java
// L Bad: Fat interface
interface MultiFunctionPrinter {
    void print(String document);
    void scan(String document);
    void fax(String document);
    void photocopy(String document);
}

class SimplePrinter implements MultiFunctionPrinter {
    public void print(String document) {
        System.out.println("Printing: " + document);
    }
    
    public void scan(String document) {
        throw new UnsupportedOperationException("Simple printer cannot scan");
    }
    
    public void fax(String document) {
        throw new UnsupportedOperationException("Simple printer cannot fax");
    }
    
    public void photocopy(String document) {
        throw new UnsupportedOperationException("Simple printer cannot photocopy");
    }
}

//  Good: Segregated interfaces
interface Printable {
    void print(String document);
}

interface Scannable {
    void scan(String document);
}

interface Faxable {
    void fax(String document);
}

interface Photocopiable {
    void photocopy(String document);
}

class SimplePrinter implements Printable {
    public void print(String document) {
        System.out.println("Printing: " + document);
    }
}

class MultiFunctionPrinter implements Printable, Scannable, Faxable, Photocopiable {
    public void print(String document) {
        System.out.println("Printing: " + document);
    }
    
    public void scan(String document) {
        System.out.println("Scanning: " + document);
    }
    
    public void fax(String document) {
        System.out.println("Faxing: " + document);
    }
    
    public void photocopy(String document) {
        System.out.println("Photocopying: " + document);
    }
}
```

### 5. Dependency Inversion Principle (DIP)

**Definition**: High-level modules should not depend on low-level modules. Both should depend on abstractions. Abstractions should not depend on details; details should depend on abstractions.

#### TypeScript Example

```typescript
// L Bad: High-level module depends on low-level module
class MySQLDatabase {
    save(data: string): void {
        console.log('Saving to MySQL database');
    }
}

class UserService {
    private database: MySQLDatabase; // Tight coupling
    
    constructor() {
        this.database = new MySQLDatabase(); // Direct dependency
    }
    
    createUser(userData: string): void {
        // Business logic
        this.database.save(userData);
    }
}

//  Good: Both depend on abstraction
interface Database {
    save(data: string): void;
}

class MySQLDatabase implements Database {
    save(data: string): void {
        console.log('Saving to MySQL database');
    }
}

class MongoDatabase implements Database {
    save(data: string): void {
        console.log('Saving to MongoDB database');
    }
}

class RedisDatabase implements Database {
    save(data: string): void {
        console.log('Saving to Redis database');
    }
}

class UserService {
    private database: Database; // Depends on abstraction
    
    constructor(database: Database) { // Dependency injection
        this.database = database;
    }
    
    createUser(userData: string): void {
        // Business logic
        this.database.save(userData);
    }
}

// Usage with dependency injection
const mysqlDB = new MySQLDatabase();
const mongoDB = new MongoDatabase();
const redisDB = new RedisDatabase();

const userServiceWithMySQL = new UserService(mysqlDB);
const userServiceWithMongo = new UserService(mongoDB);
const userServiceWithRedis = new UserService(redisDB);
```

#### Python Example

```python
from abc import ABC, abstractmethod

# L Bad: Direct dependency
class EmailSender:
    def send_email(self, message: str, recipient: str):
        print(f"Sending email to {recipient}: {message}")

class NotificationService:
    def __init__(self):
        self.email_sender = EmailSender()  # Direct dependency
    
    def send_notification(self, message: str, recipient: str):
        self.email_sender.send_email(message, recipient)

#  Good: Dependency inversion
class MessageSender(ABC):
    @abstractmethod
    def send_message(self, message: str, recipient: str):
        pass

class EmailSender(MessageSender):
    def send_message(self, message: str, recipient: str):
        print(f"Sending email to {recipient}: {message}")

class SMSSender(MessageSender):
    def send_message(self, message: str, recipient: str):
        print(f"Sending SMS to {recipient}: {message}")

class PushNotificationSender(MessageSender):
    def send_message(self, message: str, recipient: str):
        print(f"Sending push notification to {recipient}: {message}")

class NotificationService:
    def __init__(self, message_sender: MessageSender):
        self.message_sender = message_sender  # Depends on abstraction
    
    def send_notification(self, message: str, recipient: str):
        self.message_sender.send_message(message, recipient)

# Usage with dependency injection
email_service = NotificationService(EmailSender())
sms_service = NotificationService(SMSSender())
push_service = NotificationService(PushNotificationSender())
```

## When to Use SOLID Principles

###  Use When:
- Building complex applications with multiple developers
- Creating reusable libraries or frameworks
- Working on long-term projects that need maintainability
- Implementing enterprise-level software
- When you expect requirements to change frequently
- Building testable and mockable code

### L Avoid When:
- Creating simple scripts or prototypes
- Working under extreme time constraints
- Building throwaway code
- Over-engineering simple problems
- When the overhead outweighs the benefits

## Common Mistakes and How to Avoid Them

### 1. Over-Engineering Simple Solutions
```typescript
// L Overkill for simple validation
interface Validator {
    validate(input: string): boolean;
}

class EmailValidator implements Validator {
    validate(input: string): boolean {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input);
    }
}

//  Simple solution for simple problem
function validateEmail(email: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
```

### 2. Creating Too Many Small Classes (Single Responsibility Gone Wrong)
```typescript
// L Too granular
class UserName {
    constructor(private name: string) {}
    getName(): string { return this.name; }
}

class UserEmail {
    constructor(private email: string) {}
    getEmail(): string { return this.email; }
}

class UserAge {
    constructor(private age: number) {}
    getAge(): number { return this.age; }
}

//  Appropriate granularity
class User {
    constructor(
        private name: string,
        private email: string,
        private age: number
    ) {}
    
    getName(): string { return this.name; }
    getEmail(): string { return this.email; }
    getAge(): number { return this.age; }
}
```

### 3. Incorrect Interface Segregation
```typescript
// L Too many small interfaces
interface HasName { getName(): string; }
interface HasEmail { getEmail(): string; }
interface HasAge { getAge(): number; }

//  Logical interface grouping
interface UserProfile {
    getName(): string;
    getEmail(): string;
    getAge(): number;
}

interface AdminCapabilities {
    deleteUser(id: string): void;
    banUser(id: string): void;
}
```

## Real-World Applications

### E-commerce System Example

```typescript
// Product domain following SOLID principles

interface ProductRepository {
    save(product: Product): Promise<void>;
    findById(id: string): Promise<Product | null>;
    findAll(): Promise<Product[]>;
}

interface PriceCalculator {
    calculatePrice(product: Product): number;
}

interface InventoryChecker {
    isInStock(productId: string): Promise<boolean>;
}

class Product {
    constructor(
        private id: string,
        private name: string,
        private basePrice: number
    ) {}
    
    getId(): string { return this.id; }
    getName(): string { return this.name; }
    getBasePrice(): number { return this.basePrice; }
}

class RegularPriceCalculator implements PriceCalculator {
    calculatePrice(product: Product): number {
        return product.getBasePrice();
    }
}

class DiscountPriceCalculator implements PriceCalculator {
    constructor(private discountPercentage: number) {}
    
    calculatePrice(product: Product): number {
        return product.getBasePrice() * (1 - this.discountPercentage / 100);
    }
}

class ProductService {
    constructor(
        private repository: ProductRepository,
        private priceCalculator: PriceCalculator,
        private inventoryChecker: InventoryChecker
    ) {}
    
    async getProductWithPrice(id: string): Promise<any> {
        const product = await this.repository.findById(id);
        if (!product) return null;
        
        const price = this.priceCalculator.calculatePrice(product);
        const inStock = await this.inventoryChecker.isInStock(id);
        
        return {
            ...product,
            price,
            inStock
        };
    }
}
```

## Benefits and Trade-offs

### Benefits
- **Maintainability**: Code is easier to understand and modify
- **Testability**: Dependencies can be easily mocked
- **Flexibility**: Easy to extend and adapt to new requirements
- **Reusability**: Components can be reused in different contexts
- **Reduced Coupling**: Changes in one part don't ripple through the system
- **Team Collaboration**: Clear interfaces make it easier for teams to work together

### Trade-offs
- **Initial Complexity**: More upfront design and planning required
- **Learning Curve**: Developers need to understand the principles
- **Over-Engineering Risk**: Can lead to unnecessary abstraction
- **Performance Overhead**: More indirection can impact performance
- **Increased Code Volume**: More interfaces and classes to maintain

## Testing with SOLID Principles

```typescript
// Example of how SOLID makes testing easier
interface UserRepository {
    save(user: User): Promise<void>;
    findByEmail(email: string): Promise<User | null>;
}

interface EmailService {
    sendWelcomeEmail(user: User): Promise<void>;
}

class UserRegistrationService {
    constructor(
        private userRepository: UserRepository,
        private emailService: EmailService
    ) {}
    
    async registerUser(userData: any): Promise<User> {
        const user = new User(userData.name, userData.email);
        await this.userRepository.save(user);
        await this.emailService.sendWelcomeEmail(user);
        return user;
    }
}

// Easy to test with mocks
class MockUserRepository implements UserRepository {
    async save(user: User): Promise<void> {
        // Mock implementation
    }
    
    async findByEmail(email: string): Promise<User | null> {
        // Mock implementation
        return null;
    }
}

class MockEmailService implements EmailService {
    async sendWelcomeEmail(user: User): Promise<void> {
        // Mock implementation
    }
}

// Test
const mockRepo = new MockUserRepository();
const mockEmailService = new MockEmailService();
const service = new UserRegistrationService(mockRepo, mockEmailService);
// Test the service without external dependencies
```

## Conclusion

SOLID principles are fundamental guidelines that help create maintainable, flexible, and robust object-oriented software. While they require initial investment in design and learning, they pay dividends in the long run by making code easier to understand, test, and modify. Apply them judiciously based on your project's complexity and requirements.

Remember: These are principles, not rigid rules. Use good judgment about when and how to apply them in your specific context.