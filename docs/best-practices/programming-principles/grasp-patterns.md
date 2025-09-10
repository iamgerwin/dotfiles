# GRASP Patterns - General Responsibility Assignment Software Patterns

## Overview

GRASP (General Responsibility Assignment Software Patterns) is a set of nine fundamental principles in object-oriented design and responsibility assignment. These patterns provide guidance on how to assign responsibilities to classes and objects in object-oriented design.

## The Nine GRASP Patterns

### 1. Information Expert

**Definition**: Assign responsibility to the class that has the information needed to fulfill it.

**Problem**: What is the most basic principle by which responsibilities are assigned in object-oriented design?

**Solution**: Assign responsibility to the information expert—the class that has the information necessary to fulfill the responsibility.

```typescript
// Bad: Order class doesn't have line item information
class OrderService {
  calculateTotal(order: Order, lineItems: LineItem[]): number {
    return lineItems.reduce((total, item) => total + item.getSubTotal(), 0);
  }
}

// Good: Order class is the information expert
class Order {
  private lineItems: LineItem[] = [];
  
  addLineItem(item: LineItem): void {
    this.lineItems.push(item);
  }
  
  // Order knows its line items, so it should calculate its own total
  calculateTotal(): number {
    return this.lineItems.reduce((total, item) => total + item.getSubTotal(), 0);
  }
}

class LineItem {
  constructor(
    private product: Product,
    private quantity: number
  ) {}
  
  // LineItem knows its product and quantity, so it calculates its subtotal
  getSubTotal(): number {
    return this.product.getPrice() * this.quantity;
  }
}
```

### 2. Creator

**Definition**: Assign class B the responsibility to create an instance of class A if one of these conditions applies:
- B contains or compositely aggregates A
- B records A
- B closely uses A
- B has the initializing data for A

```typescript
// Bad: External class creates line items
class OrderService {
  addItemToOrder(order: Order, product: Product, quantity: number): void {
    const lineItem = new LineItem(product, quantity); // Creator responsibility misplaced
    order.addLineItem(lineItem);
  }
}

// Good: Order creates its own line items
class Order {
  private lineItems: LineItem[] = [];
  
  // Order aggregates LineItems, so it should create them
  addItem(product: Product, quantity: number): void {
    const lineItem = new LineItem(product, quantity);
    this.lineItems.push(lineItem);
  }
}
```

### 3. Controller

**Definition**: Assign the responsibility of handling a system event to a class representing the overall system, a root object, a device that the software is running within, or a major subsystem.

```typescript
// Bad: UI component handles business logic
class OrderFormComponent {
  onSubmit(orderData: OrderData): void {
    // Business logic mixed with UI
    if (orderData.items.length === 0) {
      throw new Error('Order must have items');
    }
    
    const order = new Order();
    // ... complex order creation logic
    database.save(order);
  }
}

// Good: Dedicated controller handles system events
class OrderController {
  constructor(
    private orderService: OrderService,
    private validator: OrderValidator
  ) {}
  
  createOrder(orderData: OrderData): Order {
    this.validator.validate(orderData);
    return this.orderService.create(orderData);
  }
}

class OrderFormComponent {
  constructor(private orderController: OrderController) {}
  
  onSubmit(orderData: OrderData): void {
    try {
      const order = this.orderController.createOrder(orderData);
      this.showSuccess(`Order ${order.getId()} created`);
    } catch (error) {
      this.showError(error.message);
    }
  }
}
```

### 4. Low Coupling

**Definition**: How to reduce the impact of change and increase reuse?

**Solution**: Assign responsibilities so that coupling remains low.

```typescript
// Bad: High coupling - Order directly depends on EmailService and SMSService
class Order {
  constructor(
    private emailService: EmailService,
    private smsService: SMSService
  ) {}
  
  complete(): void {
    this.status = 'completed';
    
    // Tightly coupled to specific notification services
    this.emailService.sendOrderConfirmation(this);
    this.smsService.sendOrderAlert(this);
  }
}

// Good: Low coupling - Order depends on abstraction
interface NotificationService {
  notify(order: Order, type: NotificationType): void;
}

class Order {
  constructor(private notificationService: NotificationService) {}
  
  complete(): void {
    this.status = 'completed';
    this.notificationService.notify(this, 'ORDER_COMPLETED');
  }
}

class CompositeNotificationService implements NotificationService {
  constructor(
    private emailService: EmailService,
    private smsService: SMSService
  ) {}
  
  notify(order: Order, type: NotificationType): void {
    this.emailService.send(order, type);
    this.smsService.send(order, type);
  }
}
```

### 5. High Cohesion

**Definition**: How to keep objects focused, understandable, and manageable, and as a side effect, support Low Coupling?

**Solution**: Assign responsibilities so that cohesion remains high.

```typescript
// Bad: Low cohesion - Order handles multiple unrelated responsibilities
class Order {
  private items: LineItem[] = [];
  
  addItem(product: Product, quantity: number): void {
    this.items.push(new LineItem(product, quantity));
  }
  
  calculateTotal(): number {
    return this.items.reduce((total, item) => total + item.getSubTotal(), 0);
  }
  
  // Email functionality doesn't belong here
  sendConfirmationEmail(): void {
    const template = this.buildEmailTemplate();
    this.connectToEmailServer();
    this.sendEmail(template);
  }
  
  // Report generation doesn't belong here
  generateSalesReport(): string {
    return this.formatReportData();
  }
}

// Good: High cohesion - Each class has a single, focused responsibility
class Order {
  private items: LineItem[] = [];
  
  addItem(product: Product, quantity: number): void {
    this.items.push(new LineItem(product, quantity));
  }
  
  calculateTotal(): number {
    return this.items.reduce((total, item) => total + item.getSubTotal(), 0);
  }
  
  getItems(): readonly LineItem[] {
    return this.items;
  }
}

class EmailService {
  sendOrderConfirmation(order: Order): void {
    const template = this.buildConfirmationTemplate(order);
    this.sendEmail(template);
  }
  
  private buildConfirmationTemplate(order: Order): EmailTemplate {
    // Email template building logic
  }
}

class ReportService {
  generateOrderReport(orders: Order[]): string {
    return orders
      .map(order => this.formatOrderData(order))
      .join('\n');
  }
}
```

### 6. Polymorphism

**Definition**: How to handle alternatives based on type? How to create pluggable software components?

**Solution**: When related alternatives or behaviors vary by type (class), assign responsibility for the behavior using polymorphic operations to the types for which the behavior varies.

```typescript
// Bad: Type checking with switch/if statements
class PaymentProcessor {
  processPayment(payment: Payment): void {
    switch (payment.type) {
      case 'credit_card':
        this.processCreditCard(payment);
        break;
      case 'paypal':
        this.processPayPal(payment);
        break;
      case 'bank_transfer':
        this.processBankTransfer(payment);
        break;
      default:
        throw new Error('Unsupported payment type');
    }
  }
  
  private processCreditCard(payment: Payment): void {
    // Credit card processing logic
  }
  
  private processPayPal(payment: Payment): void {
    // PayPal processing logic
  }
  
  private processBankTransfer(payment: Payment): void {
    // Bank transfer processing logic
  }
}

// Good: Polymorphism eliminates type checking
abstract class Payment {
  abstract process(): void;
}

class CreditCardPayment extends Payment {
  process(): void {
    // Credit card specific processing
    console.log('Processing credit card payment');
  }
}

class PayPalPayment extends Payment {
  process(): void {
    // PayPal specific processing
    console.log('Processing PayPal payment');
  }
}

class BankTransferPayment extends Payment {
  process(): void {
    // Bank transfer specific processing
    console.log('Processing bank transfer payment');
  }
}

class PaymentProcessor {
  processPayment(payment: Payment): void {
    payment.process(); // Polymorphic call
  }
}
```

### 7. Pure Fabrication

**Definition**: What object should have the responsibility when you do not want to violate High Cohesion and Low Coupling, but solutions offered by Information Expert are not appropriate?

**Solution**: Assign a highly cohesive set of responsibilities to an artificial or convenience class that does not represent a domain concept—something made up to support high cohesion, low coupling, and reuse.

```typescript
// Bad: DatabaseService violates cohesion by handling multiple domain objects
class DatabaseService {
  saveUser(user: User): void {
    // User saving logic
  }
  
  saveOrder(order: Order): void {
    // Order saving logic
  }
  
  saveProduct(product: Product): void {
    // Product saving logic
  }
}

// Good: Pure fabrication - Repository pattern
interface Repository<T> {
  save(entity: T): void;
  findById(id: string): T | null;
  findAll(): T[];
  delete(id: string): void;
}

// Pure fabrication for database operations
class DatabaseRepository<T> implements Repository<T> {
  constructor(
    private tableName: string,
    private mapper: EntityMapper<T>
  ) {}
  
  save(entity: T): void {
    const data = this.mapper.toDatabase(entity);
    // Generic database save logic
  }
  
  findById(id: string): T | null {
    // Generic database query logic
    const data = this.queryDatabase(`SELECT * FROM ${this.tableName} WHERE id = ?`, [id]);
    return data ? this.mapper.fromDatabase(data) : null;
  }
}

// Specific repositories
const userRepository = new DatabaseRepository<User>('users', new UserMapper());
const orderRepository = new DatabaseRepository<Order>('orders', new OrderMapper());
```

### 8. Indirection

**Definition**: Where to assign responsibility to avoid direct coupling between two (or more) things?

**Solution**: Assign the responsibility to an intermediate object to mediate between other components or services so that they are not directly coupled.

```typescript
// Bad: Direct coupling between Order and external services
class Order {
  constructor(
    private paymentGateway: PaymentGateway,
    private inventoryService: InventoryService,
    private emailService: EmailService
  ) {}
  
  complete(): void {
    // Direct coupling to multiple services
    this.paymentGateway.charge(this.total);
    this.inventoryService.updateStock(this.items);
    this.emailService.sendConfirmation(this);
  }
}

// Good: Indirection through OrderService
class OrderService {
  constructor(
    private paymentService: PaymentService,
    private inventoryService: InventoryService,
    private notificationService: NotificationService
  ) {}
  
  completeOrder(order: Order): void {
    this.paymentService.processPayment(order);
    this.inventoryService.updateInventory(order);
    this.notificationService.sendConfirmation(order);
  }
}

class Order {
  // Order is now decoupled from external services
  complete(): void {
    this.status = 'completed';
    this.completedAt = new Date();
  }
}

// Usage with indirection
class OrderController {
  constructor(private orderService: OrderService) {}
  
  submitOrder(orderData: OrderData): void {
    const order = new Order(orderData);
    this.orderService.completeOrder(order);
  }
}
```

### 9. Protected Variations

**Definition**: How to design objects, subsystems, and systems so that the variations or instability in these elements do not have an undesirable impact on other elements?

**Solution**: Identify points of predicted variation or instability; assign responsibilities to create a stable interface around them.

```typescript
// Bad: Direct dependency on external API format
class WeatherService {
  async getWeather(city: string): Promise<WeatherData> {
    const response = await fetch(`https://api.weather.com/v1/weather?city=${city}`);
    const data = await response.json();
    
    // Directly using external API format
    return {
      temperature: data.main.temp,
      humidity: data.main.humidity,
      condition: data.weather[0].main
    };
  }
}

// Good: Protected variation with adapter pattern
interface WeatherProvider {
  getWeather(city: string): Promise<WeatherData>;
}

class WeatherApiAdapter implements WeatherProvider {
  async getWeather(city: string): Promise<WeatherData> {
    const response = await fetch(`https://api.weather.com/v1/weather?city=${city}`);
    const data = await response.json();
    
    // Adapter protects against API format changes
    return this.mapToInternalFormat(data);
  }
  
  private mapToInternalFormat(apiData: any): WeatherData {
    return {
      temperature: apiData.main.temp,
      humidity: apiData.main.humidity,
      condition: apiData.weather[0].main
    };
  }
}

class AlternativeWeatherAdapter implements WeatherProvider {
  async getWeather(city: string): Promise<WeatherData> {
    // Different API with different format
    const response = await fetch(`https://alternative-weather.com/api?location=${city}`);
    const data = await response.json();
    
    return {
      temperature: data.currentTemp,
      humidity: data.moistureLevel,
      condition: data.skyCondition
    };
  }
}

class WeatherService {
  constructor(private weatherProvider: WeatherProvider) {}
  
  async getWeather(city: string): Promise<WeatherData> {
    return this.weatherProvider.getWeather(city);
  }
}
```

## Real-World Example: E-commerce System

```typescript
// Applying multiple GRASP patterns together

// Information Expert & High Cohesion
class Product {
  constructor(
    private id: string,
    private name: string,
    private price: number,
    private stock: number
  ) {}
  
  // Information Expert: Product knows its own price
  getPrice(): number {
    return this.price;
  }
  
  // Information Expert: Product knows if it's available
  isAvailable(quantity: number): boolean {
    return this.stock >= quantity;
  }
}

// Creator & Information Expert
class ShoppingCart {
  private items: CartItem[] = [];
  
  // Creator: Cart creates and manages its items
  addItem(product: Product, quantity: number): void {
    if (!product.isAvailable(quantity)) {
      throw new Error('Product not available');
    }
    
    const existingItem = this.items.find(item => item.getProductId() === product.getId());
    if (existingItem) {
      existingItem.increaseQuantity(quantity);
    } else {
      this.items.push(new CartItem(product, quantity));
    }
  }
  
  // Information Expert: Cart calculates its own total
  getTotal(): number {
    return this.items.reduce((total, item) => total + item.getSubtotal(), 0);
  }
}

// High Cohesion
class CartItem {
  constructor(
    private product: Product,
    private quantity: number
  ) {}
  
  getProductId(): string {
    return this.product.getId();
  }
  
  increaseQuantity(amount: number): void {
    this.quantity += amount;
  }
  
  // Information Expert: Item calculates its own subtotal
  getSubtotal(): number {
    return this.product.getPrice() * this.quantity;
  }
}

// Controller
class OrderController {
  constructor(
    private orderService: OrderService,
    private paymentService: PaymentService
  ) {}
  
  // Controller handles system events
  placeOrder(cart: ShoppingCart, paymentInfo: PaymentInfo): Order {
    const order = this.orderService.createOrder(cart);
    this.paymentService.processPayment(order, paymentInfo);
    return order;
  }
}

// Pure Fabrication & Indirection
class OrderService {
  constructor(
    private orderRepository: OrderRepository,
    private inventoryService: InventoryService,
    private notificationService: NotificationService
  ) {}
  
  createOrder(cart: ShoppingCart): Order {
    const order = new Order(cart.getItems(), cart.getTotal());
    
    this.orderRepository.save(order);
    this.inventoryService.reserveItems(cart.getItems());
    this.notificationService.sendOrderConfirmation(order);
    
    return order;
  }
}

// Polymorphism & Protected Variations
interface PaymentProcessor {
  process(amount: number, paymentInfo: PaymentInfo): PaymentResult;
}

class CreditCardProcessor implements PaymentProcessor {
  process(amount: number, paymentInfo: PaymentInfo): PaymentResult {
    // Credit card processing logic
    return new PaymentResult('success', 'CC123456');
  }
}

class PayPalProcessor implements PaymentProcessor {
  process(amount: number, paymentInfo: PaymentInfo): PaymentResult {
    // PayPal processing logic
    return new PaymentResult('success', 'PP789012');
  }
}

// Low Coupling through Dependency Injection
class PaymentService {
  constructor(private processor: PaymentProcessor) {}
  
  processPayment(order: Order, paymentInfo: PaymentInfo): void {
    const result = this.processor.process(order.getTotal(), paymentInfo);
    if (result.isSuccessful()) {
      order.markAsPaid(result.getTransactionId());
    } else {
      throw new Error('Payment failed');
    }
  }
}
```

## Benefits of GRASP Patterns

1. **Maintainability**: Clear responsibility assignment makes code easier to modify
2. **Reusability**: Well-designed classes can be reused in different contexts
3. **Testability**: Focused responsibilities make units easier to test
4. **Flexibility**: Low coupling enables easy changes and extensions
5. **Understandability**: High cohesion makes code easier to understand

## Common Anti-patterns to Avoid

1. **God Class**: One class doing too many things (violates High Cohesion)
2. **Feature Envy**: Class using more features of another class than its own (violates Information Expert)
3. **Inappropriate Intimacy**: Classes too tightly coupled (violates Low Coupling)
4. **Lazy Class**: Class that doesn't do enough to justify its existence
5. **Large Class**: Class with too many responsibilities (violates High Cohesion)

## Relationship with SOLID Principles

GRASP patterns complement SOLID principles:

- **Information Expert** supports **Single Responsibility Principle**
- **Low Coupling** supports **Dependency Inversion Principle**
- **High Cohesion** supports **Single Responsibility Principle**
- **Polymorphism** supports **Open/Closed Principle** and **Liskov Substitution Principle**
- **Protected Variations** supports **Open/Closed Principle**

## Best Practices

1. **Apply patterns together**: GRASP patterns work best when applied in combination
2. **Consider trade-offs**: Sometimes patterns conflict; find the right balance
3. **Start with Information Expert**: Often the most natural starting point
4. **Use Pure Fabrication sparingly**: Only when domain objects can't handle the responsibility
5. **Prefer composition over inheritance**: Use Indirection and Protected Variations
6. **Design for change**: Use Protected Variations for likely variation points

GRASP provides a solid foundation for object-oriented design decisions, helping create maintainable, flexible, and understandable software systems.