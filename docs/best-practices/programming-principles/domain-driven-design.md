# Domain-Driven Design (DDD)

## Overview

Domain-Driven Design (DDD) is a software development approach that focuses on modeling software to match a domain according to input from domain experts. It was introduced by Eric Evans in his book "Domain-Driven Design: Tackling Complexity in the Heart of Software" (2003).

## Core Philosophy

DDD emphasizes:
- **Ubiquitous Language**: Common vocabulary between developers and domain experts
- **Domain Focus**: Business logic is the heart of the application
- **Collaborative Modeling**: Continuous collaboration between technical and domain experts
- **Strategic Design**: Organizing large systems into bounded contexts
- **Tactical Design**: Building blocks for implementing domain logic

## Strategic Design Patterns

### 1. Bounded Context

A bounded context defines explicit boundaries within which a domain model is valid.

```typescript
// E-commerce system with multiple bounded contexts

// Sales Bounded Context
namespace Sales {
  export class Customer {
    constructor(
      private customerId: CustomerId,
      private email: Email,
      private shippingAddress: Address
    ) {}
    
    placeOrder(items: OrderItem[]): Order {
      return new Order(this.customerId, items);
    }
  }
  
  export class Order {
    constructor(
      private customerId: CustomerId,
      private items: OrderItem[],
      private status: OrderStatus = 'pending'
    ) {}
    
    calculateTotal(): Money {
      return this.items.reduce(
        (total, item) => total.add(item.getSubtotal()),
        Money.zero()
      );
    }
  }
}

// Customer Support Bounded Context (different Customer model)
namespace CustomerSupport {
  export class Customer {
    constructor(
      private customerId: CustomerId,
      private contactInfo: ContactInfo,
      private supportHistory: SupportTicket[]
    ) {}
    
    createSupportTicket(issue: string): SupportTicket {
      const ticket = new SupportTicket(this.customerId, issue);
      this.supportHistory.push(ticket);
      return ticket;
    }
  }
  
  export class SupportTicket {
    constructor(
      private customerId: CustomerId,
      private issue: string,
      private status: TicketStatus = 'open'
    ) {}
    
    resolve(): void {
      this.status = 'resolved';
    }
  }
}
```

### 2. Context Map

Context maps show relationships between bounded contexts.

```typescript
// Context Map showing integration patterns

interface ContextMap {
  relationships: ContextRelationship[];
}

interface ContextRelationship {
  upstream: BoundedContext;
  downstream: BoundedContext;
  pattern: IntegrationPattern;
}

type IntegrationPattern = 
  | 'SharedKernel' 
  | 'CustomerSupplier'
  | 'Conformist'
  | 'AnticorruptionLayer'
  | 'PublishedLanguage'
  | 'OpenHostService';

// Example: Anti-corruption Layer
class PaymentGatewayAntiCorruptionLayer {
  constructor(private externalPaymentService: ExternalPaymentService) {}
  
  // Translates domain objects to external service format
  async processPayment(payment: Payment): Promise<PaymentResult> {
    const externalRequest = this.translateToExternalFormat(payment);
    const externalResponse = await this.externalPaymentService.charge(externalRequest);
    return this.translateToDomainFormat(externalResponse);
  }
  
  private translateToExternalFormat(payment: Payment): ExternalPaymentRequest {
    return {
      amount_cents: payment.getAmount().toCents(),
      currency_code: payment.getCurrency().getCode(),
      card_token: payment.getCardToken(),
      merchant_id: payment.getMerchantId()
    };
  }
  
  private translateToDomainFormat(response: ExternalPaymentResponse): PaymentResult {
    return new PaymentResult(
      response.success ? 'completed' : 'failed',
      response.transaction_id,
      response.error_message
    );
  }
}
```

### 3. Ubiquitous Language

Shared vocabulary between domain experts and developers.

```typescript
// Bad: Technical language that domain experts don't understand
class UserManager {
  processTransaction(userId: string, data: TransactionData): void {
    const user = this.userRepository.findById(userId);
    user.accountBalance -= data.amount;
    this.auditLogger.log(`Debit operation: ${data.amount}`);
  }
}

// Good: Ubiquitous language that reflects business terminology
class Account {
  constructor(
    private accountId: AccountId,
    private balance: Money,
    private owner: AccountHolder
  ) {}
  
  withdraw(amount: Money): WithdrawalResult {
    if (this.hasInsufficientFunds(amount)) {
      return WithdrawalResult.failed('Insufficient funds');
    }
    
    this.balance = this.balance.subtract(amount);
    this.recordWithdrawal(amount);
    
    return WithdrawalResult.successful(amount);
  }
  
  private hasInsufficientFunds(amount: Money): boolean {
    return this.balance.isLessThan(amount);
  }
  
  private recordWithdrawal(amount: Money): void {
    // Domain event for audit trail
    DomainEvents.raise(new MoneyWithdrawn(this.accountId, amount, new Date()));
  }
}
```

## Tactical Design Patterns

### 1. Entities

Objects with identity that persists over time.

```typescript
class Order {
  constructor(
    private orderId: OrderId,
    private customerId: CustomerId,
    private orderDate: Date,
    private items: OrderItem[] = []
  ) {}
  
  // Business invariants enforced
  addItem(product: Product, quantity: Quantity): void {
    if (this.isCompleted()) {
      throw new Error('Cannot modify completed order');
    }
    
    const existingItem = this.items.find(item => 
      item.getProductId().equals(product.getId())
    );
    
    if (existingItem) {
      existingItem.increaseQuantity(quantity);
    } else {
      this.items.push(new OrderItem(product, quantity));
    }
  }
  
  complete(): void {
    if (this.items.length === 0) {
      throw new Error('Cannot complete order without items');
    }
    
    this.status = OrderStatus.COMPLETED;
    DomainEvents.raise(new OrderCompleted(this.orderId, this.customerId));
  }
  
  // Identity comparison
  equals(other: Order): boolean {
    return this.orderId.equals(other.orderId);
  }
}
```

### 2. Value Objects

Objects defined by their attributes rather than identity.

```typescript
class Money {
  constructor(
    private amount: number,
    private currency: Currency
  ) {
    if (amount < 0) {
      throw new Error('Money amount cannot be negative');
    }
    this.validateCurrency(currency);
  }
  
  add(other: Money): Money {
    this.ensureSameCurrency(other);
    return new Money(this.amount + other.amount, this.currency);
  }
  
  subtract(other: Money): Money {
    this.ensureSameCurrency(other);
    return new Money(this.amount - other.amount, this.currency);
  }
  
  multiply(factor: number): Money {
    return new Money(this.amount * factor, this.currency);
  }
  
  isGreaterThan(other: Money): boolean {
    this.ensureSameCurrency(other);
    return this.amount > other.amount;
  }
  
  // Value object equality based on attributes
  equals(other: Money): boolean {
    return this.amount === other.amount && 
           this.currency.equals(other.currency);
  }
  
  private ensureSameCurrency(other: Money): void {
    if (!this.currency.equals(other.currency)) {
      throw new Error('Cannot operate on different currencies');
    }
  }
}

class Address {
  constructor(
    private street: string,
    private city: string,
    private postalCode: string,
    private country: string
  ) {
    this.validate();
  }
  
  private validate(): void {
    if (!this.street || !this.city || !this.postalCode || !this.country) {
      throw new Error('All address fields are required');
    }
  }
  
  equals(other: Address): boolean {
    return this.street === other.street &&
           this.city === other.city &&
           this.postalCode === other.postalCode &&
           this.country === other.country;
  }
  
  toString(): string {
    return `${this.street}, ${this.city}, ${this.postalCode}, ${this.country}`;
  }
}
```

### 3. Aggregates and Aggregate Roots

Groups of related entities and value objects with a single root.

```typescript
// Order Aggregate with Order as Aggregate Root
class Order {
  constructor(
    private orderId: OrderId,
    private customerId: CustomerId,
    private shippingAddress: Address,
    private items: OrderItem[] = [],
    private status: OrderStatus = OrderStatus.DRAFT
  ) {}
  
  // All modifications go through the aggregate root
  addItem(product: Product, quantity: number, unitPrice: Money): void {
    this.ensureOrderCanBeModified();
    
    const orderItem = new OrderItem(
      OrderItemId.generate(),
      product.getId(),
      quantity,
      unitPrice
    );
    
    this.items.push(orderItem);
    this.recalculateTotal();
  }
  
  removeItem(itemId: OrderItemId): void {
    this.ensureOrderCanBeModified();
    this.items = this.items.filter(item => !item.getId().equals(itemId));
    this.recalculateTotal();
  }
  
  ship(trackingNumber: TrackingNumber): void {
    if (this.status !== OrderStatus.PAID) {
      throw new Error('Can only ship paid orders');
    }
    
    this.status = OrderStatus.SHIPPED;
    this.trackingNumber = trackingNumber;
    
    // Domain event
    DomainEvents.raise(new OrderShipped(this.orderId, trackingNumber));
  }
  
  // Aggregate root controls access to internal entities
  getItems(): readonly OrderItem[] {
    return this.items;
  }
  
  private ensureOrderCanBeModified(): void {
    if (this.status === OrderStatus.SHIPPED || this.status === OrderStatus.DELIVERED) {
      throw new Error('Cannot modify shipped or delivered orders');
    }
  }
  
  private recalculateTotal(): void {
    this.total = this.items.reduce(
      (sum, item) => sum.add(item.getSubtotal()),
      Money.zero(this.getCurrency())
    );
  }
}

// Internal entity - only accessed through aggregate root
class OrderItem {
  constructor(
    private id: OrderItemId,
    private productId: ProductId,
    private quantity: number,
    private unitPrice: Money
  ) {}
  
  getId(): OrderItemId {
    return this.id;
  }
  
  getSubtotal(): Money {
    return this.unitPrice.multiply(this.quantity);
  }
  
  changeQuantity(newQuantity: number): void {
    if (newQuantity <= 0) {
      throw new Error('Quantity must be positive');
    }
    this.quantity = newQuantity;
  }
}
```

### 4. Domain Services

Services that contain domain logic that doesn't naturally fit in entities or value objects.

```typescript
// Domain Service for complex business logic
class PricingService {
  constructor(
    private discountRules: DiscountRules,
    private taxCalculator: TaxCalculator
  ) {}
  
  calculateOrderPrice(order: Order, customer: Customer): OrderPricing {
    let subtotal = this.calculateSubtotal(order);
    
    // Apply customer-specific discounts
    const discount = this.discountRules.calculateDiscount(customer, order);
    subtotal = subtotal.subtract(discount);
    
    // Calculate tax based on shipping address
    const tax = this.taxCalculator.calculate(subtotal, order.getShippingAddress());
    
    const total = subtotal.add(tax);
    
    return new OrderPricing(subtotal, discount, tax, total);
  }
  
  private calculateSubtotal(order: Order): Money {
    return order.getItems().reduce(
      (sum, item) => sum.add(item.getSubtotal()),
      Money.zero()
    );
  }
}

// Complex domain logic for fraud detection
class FraudDetectionService {
  constructor(
    private customerRepository: CustomerRepository,
    private orderRepository: OrderRepository
  ) {}
  
  assessRisk(order: Order): FraudRisk {
    const customer = this.customerRepository.findById(order.getCustomerId());
    const recentOrders = this.orderRepository.findRecentByCustomer(customer.getId());
    
    let riskScore = 0;
    
    // Multiple large orders in short time
    if (this.hasMultipleLargeOrdersRecently(recentOrders)) {
      riskScore += 30;
    }
    
    // New customer with large order
    if (customer.isNew() && order.getTotal().isGreaterThan(Money.of(500, 'USD'))) {
      riskScore += 25;
    }
    
    // Shipping to different country than billing
    if (this.hasInternationalShipping(order, customer)) {
      riskScore += 15;
    }
    
    return FraudRisk.fromScore(riskScore);
  }
  
  private hasMultipleLargeOrdersRecently(orders: Order[]): boolean {
    const recentLargeOrders = orders.filter(order =>
      order.getTotal().isGreaterThan(Money.of(200, 'USD')) &&
      this.isWithinLastHour(order.getCreatedAt())
    );
    
    return recentLargeOrders.length >= 3;
  }
}
```

### 5. Repositories

Abstraction for data access that appears as an in-memory collection.

```typescript
interface OrderRepository {
  findById(orderId: OrderId): Order | null;
  findByCustomerId(customerId: CustomerId): Order[];
  save(order: Order): void;
  delete(order: Order): void;
  nextId(): OrderId;
}

// Implementation would be in infrastructure layer
class SqlOrderRepository implements OrderRepository {
  constructor(private connection: DatabaseConnection) {}
  
  findById(orderId: OrderId): Order | null {
    const sql = `
      SELECT o.*, oi.* 
      FROM orders o 
      LEFT JOIN order_items oi ON o.id = oi.order_id 
      WHERE o.id = ?
    `;
    
    const rows = this.connection.query(sql, [orderId.getValue()]);
    
    if (rows.length === 0) return null;
    
    return this.mapRowsToOrder(rows);
  }
  
  save(order: Order): void {
    const orderData = this.mapOrderToData(order);
    
    this.connection.transaction(() => {
      this.saveOrderData(orderData);
      this.saveOrderItems(order.getItems());
    });
  }
  
  private mapRowsToOrder(rows: any[]): Order {
    // Complex mapping logic to reconstruct aggregate
    const orderData = rows[0];
    const items = rows.map(row => this.mapRowToOrderItem(row));
    
    return new Order(
      new OrderId(orderData.id),
      new CustomerId(orderData.customer_id),
      this.mapRowToAddress(orderData),
      items,
      OrderStatus.fromString(orderData.status)
    );
  }
}
```

### 6. Domain Events

Events representing something important that happened in the domain.

```typescript
abstract class DomainEvent {
  constructor(
    public readonly occurredOn: Date = new Date(),
    public readonly eventId: string = crypto.randomUUID()
  ) {}
}

class OrderPlaced extends DomainEvent {
  constructor(
    public readonly orderId: OrderId,
    public readonly customerId: CustomerId,
    public readonly orderTotal: Money
  ) {
    super();
  }
}

class PaymentProcessed extends DomainEvent {
  constructor(
    public readonly orderId: OrderId,
    public readonly paymentId: PaymentId,
    public readonly amount: Money
  ) {
    super();
  }
}

// Domain Events Registry
class DomainEvents {
  private static handlers: Map<string, ((event: DomainEvent) => void)[]> = new Map();
  
  static register<T extends DomainEvent>(
    eventType: new (...args: any[]) => T,
    handler: (event: T) => void
  ): void {
    const eventName = eventType.name;
    
    if (!this.handlers.has(eventName)) {
      this.handlers.set(eventName, []);
    }
    
    this.handlers.get(eventName)!.push(handler);
  }
  
  static raise(event: DomainEvent): void {
    const eventName = event.constructor.name;
    const eventHandlers = this.handlers.get(eventName) || [];
    
    eventHandlers.forEach(handler => handler(event));
  }
  
  static clear(): void {
    this.handlers.clear();
  }
}

// Usage
DomainEvents.register(OrderPlaced, (event) => {
  // Send confirmation email
  emailService.sendOrderConfirmation(event.customerId, event.orderId);
});

DomainEvents.register(PaymentProcessed, (event) => {
  // Update inventory
  inventoryService.reserveItems(event.orderId);
});
```

## Application Layer Patterns

### 1. Application Services

Orchestrate domain objects to fulfill use cases.

```typescript
class PlaceOrderApplicationService {
  constructor(
    private orderRepository: OrderRepository,
    private customerRepository: CustomerRepository,
    private productRepository: ProductRepository,
    private pricingService: PricingService,
    private paymentService: PaymentService
  ) {}
  
  async execute(command: PlaceOrderCommand): Promise<PlaceOrderResult> {
    // 1. Validate input
    const validation = this.validateCommand(command);
    if (!validation.isValid) {
      return PlaceOrderResult.failed(validation.errors);
    }
    
    // 2. Load domain objects
    const customer = await this.customerRepository.findById(command.customerId);
    if (!customer) {
      return PlaceOrderResult.failed(['Customer not found']);
    }
    
    const products = await this.loadProducts(command.items);
    
    // 3. Execute domain logic
    const order = new Order(
      this.orderRepository.nextId(),
      command.customerId,
      command.shippingAddress
    );
    
    // Add items to order
    for (const item of command.items) {
      const product = products.find(p => p.getId().equals(item.productId));
      order.addItem(product!, item.quantity, product!.getPrice());
    }
    
    // Calculate pricing
    const pricing = this.pricingService.calculateOrderPrice(order, customer);
    order.applyPricing(pricing);
    
    // Process payment
    const paymentResult = await this.paymentService.process(
      command.paymentInfo,
      pricing.total
    );
    
    if (!paymentResult.isSuccessful()) {
      return PlaceOrderResult.failed(['Payment failed']);
    }
    
    order.markAsPaid(paymentResult.getTransactionId());
    
    // 4. Persist changes
    await this.orderRepository.save(order);
    
    return PlaceOrderResult.successful(order.getId());
  }
  
  private async loadProducts(items: OrderItemRequest[]): Promise<Product[]> {
    const productIds = items.map(item => item.productId);
    return Promise.all(
      productIds.map(id => this.productRepository.findById(id))
    );
  }
}
```

### 2. Command and Query Separation

Separate commands (write operations) from queries (read operations).

```typescript
// Command Side - Domain focused
class CreateCustomerCommand {
  constructor(
    public readonly name: string,
    public readonly email: string,
    public readonly address: Address
  ) {}
}

class CreateCustomerCommandHandler {
  constructor(private customerRepository: CustomerRepository) {}
  
  async handle(command: CreateCustomerCommand): Promise<void> {
    // Domain logic
    const customer = Customer.create(
      this.customerRepository.nextId(),
      command.name,
      new Email(command.email),
      command.address
    );
    
    await this.customerRepository.save(customer);
  }
}

// Query Side - Optimized for reading
interface CustomerQueryService {
  findById(id: string): Promise<CustomerView | null>;
  findByEmail(email: string): Promise<CustomerView | null>;
  searchCustomers(criteria: CustomerSearchCriteria): Promise<CustomerView[]>;
}

interface CustomerView {
  id: string;
  name: string;
  email: string;
  totalOrders: number;
  lifetimeValue: number;
  lastOrderDate?: Date;
}

class SqlCustomerQueryService implements CustomerQueryService {
  constructor(private connection: DatabaseConnection) {}
  
  async findById(id: string): Promise<CustomerView | null> {
    const sql = `
      SELECT 
        c.id,
        c.name,
        c.email,
        COUNT(o.id) as total_orders,
        SUM(o.total) as lifetime_value,
        MAX(o.created_at) as last_order_date
      FROM customers c
      LEFT JOIN orders o ON c.id = o.customer_id
      WHERE c.id = ?
      GROUP BY c.id, c.name, c.email
    `;
    
    const row = await this.connection.queryOne(sql, [id]);
    return row ? this.mapRowToCustomerView(row) : null;
  }
}
```

## Infrastructure Layer

### 1. Persistence

```typescript
// Domain model persistence
class JpaOrderRepository implements OrderRepository {
  constructor(private entityManager: EntityManager) {}
  
  async save(order: Order): Promise<void> {
    // Map domain object to JPA entity
    const orderEntity = this.mapToEntity(order);
    
    await this.entityManager.transaction(async (em) => {
      await em.save(orderEntity);
      
      // Save order items
      for (const item of order.getItems()) {
        const itemEntity = this.mapItemToEntity(item, order.getId());
        await em.save(itemEntity);
      }
    });
    
    // Publish domain events after successful persistence
    this.publishDomainEvents(order.getUncommittedEvents());
    order.markEventsAsCommitted();
  }
  
  private mapToEntity(order: Order): OrderEntity {
    return new OrderEntity(
      order.getId().getValue(),
      order.getCustomerId().getValue(),
      order.getShippingAddress().toString(),
      order.getTotal().getAmount(),
      order.getStatus().toString()
    );
  }
}
```

### 2. Event Publishing

```typescript
interface EventPublisher {
  publish(events: DomainEvent[]): Promise<void>;
}

class MessageBrokerEventPublisher implements EventPublisher {
  constructor(private messageBroker: MessageBroker) {}
  
  async publish(events: DomainEvent[]): Promise<void> {
    const messages = events.map(event => ({
      topic: this.getTopicForEvent(event),
      payload: JSON.stringify(event),
      headers: {
        eventType: event.constructor.name,
        eventId: event.eventId,
        occurredOn: event.occurredOn.toISOString()
      }
    }));
    
    await Promise.all(
      messages.map(message => this.messageBroker.send(message))
    );
  }
  
  private getTopicForEvent(event: DomainEvent): string {
    return `domain.${event.constructor.name.toLowerCase()}`;
  }
}
```

## DDD Best Practices

1. **Start with the Domain**: Begin by understanding the business domain
2. **Use Ubiquitous Language**: Maintain consistent terminology throughout
3. **Model Explicitly**: Make implicit concepts explicit in code
4. **Protect Business Invariants**: Use aggregates to maintain consistency
5. **Design for Change**: Use bounded contexts to isolate changes
6. **Iterate with Domain Experts**: Continuously refine the model
7. **Separate Concerns**: Keep domain logic separate from infrastructure
8. **Use Domain Events**: Communicate between bounded contexts
9. **Focus on Behavior**: Model behavior, not just data
10. **Keep Aggregates Small**: Prefer smaller, focused aggregates

## Common Pitfalls

1. **Anemic Domain Models**: Models with only getters/setters
2. **God Aggregates**: Overly large aggregates with too much responsibility
3. **Technical Modeling**: Modeling based on technical constraints rather than domain
4. **Missing Ubiquitous Language**: Using technical jargon instead of business language
5. **Leaky Abstractions**: Domain concepts leaking into infrastructure
6. **Event Sourcing Everywhere**: Overusing event sourcing where not needed
7. **Over-Engineering**: Adding complexity without business value
8. **Ignoring Legacy Systems**: Not planning for integration with existing systems

DDD provides a structured approach to building complex software systems that truly reflect the business domain and remain maintainable over time.