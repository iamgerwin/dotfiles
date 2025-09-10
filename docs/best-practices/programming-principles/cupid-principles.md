# CUPID Principles

## Official Documentation & Resources
- **Dan North's Original Article**: https://dannorth.net/2022/02/10/cupid-for-joyful-coding/
- **CUPID vs SOLID Comparison**: https://medium.com/@kentbeck_7670/cupid-the-back-story-42213fd52d6e
- **Properties of Good Code**: https://www.youtube.com/watch?v=UBXXw2JSloo
- **Joyful Coding Blog**: https://dannorth.net/tags/joyful-coding/

## Introduction

CUPID is a set of properties for joyful coding, introduced by Dan North as a more human-centric alternative to SOLID. While SOLID focuses on object-oriented design principles, CUPID emphasizes properties that make code joyful to work with. CUPID stands for **Composable**, **Unix philosophy**, **Predictable**, **Idiomatic**, and **Domain-based**.

## The Five CUPID Properties

### 1. Composable

**Definition**: Code should work well with other code. Small pieces that compose into bigger pieces, which compose into even bigger pieces.

#### Good Composability - TypeScript

```typescript
// ✅ Good: Composable functions
const add = (a: number, b: number): number => a + b;
const multiply = (a: number, b: number): number => a * b;
const pipe = <T>(...functions: Array<(arg: T) => T>) => (value: T): T =>
    functions.reduce((acc, fn) => fn(acc), value);

// Compose simple functions into complex operations
const addThenMultiply = (x: number, y: number, z: number) => 
    pipe(
        (n: number) => add(n, y),
        (n: number) => multiply(n, z)
    )(x);

// ❌ Bad: Non-composable, monolithic function
function calculatePriceWithDiscountAndTax(
    basePrice: number, 
    discountPercent: number, 
    taxRate: number,
    customerType: 'regular' | 'premium' | 'vip',
    seasonalMultiplier: number
): number {
    let price = basePrice;
    
    // Discount logic
    if (customerType === 'premium') {
        price = price * (1 - (discountPercent + 5) / 100);
    } else if (customerType === 'vip') {
        price = price * (1 - (discountPercent + 10) / 100);
    } else {
        price = price * (1 - discountPercent / 100);
    }
    
    // Seasonal adjustment
    price = price * seasonalMultiplier;
    
    // Tax calculation
    price = price * (1 + taxRate / 100);
    
    return price;
}

// ✅ Good: Composable pricing system
interface PricingStrategy {
    apply(price: number): number;
}

class BaseDiscountStrategy implements PricingStrategy {
    constructor(private discountPercent: number) {}
    
    apply(price: number): number {
        return price * (1 - this.discountPercent / 100);
    }
}

class CustomerTypeStrategy implements PricingStrategy {
    constructor(
        private customerType: 'regular' | 'premium' | 'vip',
        private baseStrategy: PricingStrategy
    ) {}
    
    apply(price: number): number {
        const extraDiscount = this.customerType === 'vip' ? 10 : 
                             this.customerType === 'premium' ? 5 : 0;
        
        if (this.baseStrategy instanceof BaseDiscountStrategy) {
            const newDiscount = (this.baseStrategy as any).discountPercent + extraDiscount;
            return price * (1 - newDiscount / 100);
        }
        
        return this.baseStrategy.apply(price);
    }
}

class SeasonalStrategy implements PricingStrategy {
    constructor(private multiplier: number, private nextStrategy: PricingStrategy) {}
    
    apply(price: number): number {
        return this.nextStrategy.apply(price) * this.multiplier;
    }
}

class TaxStrategy implements PricingStrategy {
    constructor(private taxRate: number, private nextStrategy: PricingStrategy) {}
    
    apply(price: number): number {
        return this.nextStrategy.apply(price) * (1 + this.taxRate / 100);
    }
}

class PriceCalculator {
    private strategies: PricingStrategy[] = [];
    
    addStrategy(strategy: PricingStrategy): this {
        this.strategies.push(strategy);
        return this;
    }
    
    calculate(basePrice: number): number {
        return this.strategies.reduce((price, strategy) => 
            strategy.apply(price), basePrice);
    }
}

// Usage - highly composable
const calculator = new PriceCalculator()
    .addStrategy(new BaseDiscountStrategy(10))
    .addStrategy(new SeasonalStrategy(0.9))
    .addStrategy(new TaxStrategy(8.5));

const finalPrice = calculator.calculate(100);
```

#### Python Composability Example

```python
from typing import Callable, List
from functools import reduce

# ✅ Good: Composable data processing
def filter_active_users(users):
    return [user for user in users if user.get('active', False)]

def map_to_names(users):
    return [user.get('name', '') for user in users]

def sort_alphabetically(names):
    return sorted(names)

def compose(*functions):
    return lambda x: reduce(lambda acc, f: f(acc), functions, x)

# Compose operations
get_active_user_names = compose(
    filter_active_users,
    map_to_names,
    sort_alphabetically
)

# Usage
users = [
    {'name': 'Alice', 'active': True},
    {'name': 'Bob', 'active': False},
    {'name': 'Charlie', 'active': True}
]

active_names = get_active_user_names(users)  # ['Alice', 'Charlie']

# ❌ Bad: Non-composable
def get_active_user_names_monolithic(users):
    result = []
    for user in users:
        if user.get('active', False):
            result.append(user.get('name', ''))
    return sorted(result)
```

### 2. Unix Philosophy

**Definition**: Do one thing well. Write programs that do one thing and do it well. Write programs to work together.

#### TypeScript Example

```typescript
// ✅ Good: Unix philosophy - single responsibility tools
class Logger {
    private formatMessage(level: string, message: string): string {
        const timestamp = new Date().toISOString();
        return `[${timestamp}] ${level.toUpperCase()}: ${message}`;
    }
    
    info(message: string): void {
        console.log(this.formatMessage('info', message));
    }
    
    error(message: string): void {
        console.error(this.formatMessage('error', message));
    }
    
    warn(message: string): void {
        console.warn(this.formatMessage('warn', message));
    }
}

class FileWriter {
    async writeToFile(filename: string, content: string): Promise<void> {
        // Simple file writing logic
        console.log(`Writing to ${filename}: ${content}`);
    }
}

class EmailSender {
    async sendEmail(to: string, subject: string, body: string): Promise<void> {
        // Simple email sending logic
        console.log(`Sending email to ${to}: ${subject}`);
    }
}

// Compose these single-purpose tools
class NotificationService {
    constructor(
        private logger: Logger,
        private fileWriter: FileWriter,
        private emailSender: EmailSender
    ) {}
    
    async processNotification(notification: {
        message: string;
        recipient: string;
        logToFile: boolean;
    }): Promise<void> {
        // Each tool does one thing well
        this.logger.info(`Processing notification: ${notification.message}`);
        
        if (notification.logToFile) {
            await this.fileWriter.writeToFile(
                'notifications.log', 
                notification.message
            );
        }
        
        await this.emailSender.sendEmail(
            notification.recipient,
            'Notification',
            notification.message
        );
        
        this.logger.info('Notification processed successfully');
    }
}

// ❌ Bad: Swiss Army knife approach
class MegaNotificationTool {
    private logLevel: string = 'info';
    private fileFormat: string = 'txt';
    private emailTemplate: string = 'default';
    private databaseConnection: any;
    private cacheService: any;
    
    async doEverything(data: any): Promise<void> {
        // Trying to do everything in one class
        this.validateData(data);
        this.logMessage(data.message);
        this.saveToDatabase(data);
        this.updateCache(data);
        this.sendEmail(data);
        this.generateReport(data);
        this.updateAnalytics(data);
        // ... and many more responsibilities
    }
    
    private validateData(data: any): void { /* complex validation */ }
    private logMessage(message: string): void { /* logging logic */ }
    private saveToDatabase(data: any): void { /* database logic */ }
    private updateCache(data: any): void { /* cache logic */ }
    private sendEmail(data: any): void { /* email logic */ }
    private generateReport(data: any): void { /* reporting logic */ }
    private updateAnalytics(data: any): void { /* analytics logic */ }
}
```

#### Python Example

```python
# ✅ Good: Unix philosophy - small, focused tools
class TextProcessor:
    @staticmethod
    def normalize_whitespace(text: str) -> str:
        return ' '.join(text.split())
    
    @staticmethod
    def to_lowercase(text: str) -> str:
        return text.lower()
    
    @staticmethod
    def remove_punctuation(text: str) -> str:
        import string
        return text.translate(str.maketrans('', '', string.punctuation))

class WordCounter:
    @staticmethod
    def count_words(text: str) -> int:
        return len(text.split())
    
    @staticmethod
    def count_unique_words(text: str) -> int:
        return len(set(text.split()))

class TextAnalyzer:
    def __init__(self):
        self.processor = TextProcessor()
        self.counter = WordCounter()
    
    def analyze(self, text: str) -> dict:
        # Compose small tools
        clean_text = self.processor.remove_punctuation(
            self.processor.to_lowercase(
                self.processor.normalize_whitespace(text)
            )
        )
        
        return {
            'total_words': self.counter.count_words(clean_text),
            'unique_words': self.counter.count_unique_words(clean_text),
            'processed_text': clean_text
        }
```

### 3. Predictable

**Definition**: Code should do what you expect it to do. The behavior should be obvious from reading the code.

#### TypeScript Example

```typescript
// ❌ Bad: Unpredictable behavior
class UserManager {
    private users: User[] = [];
    private cache: Map<string, User> = new Map();
    
    getUser(id: string): User | undefined {
        // Unpredictable: sometimes returns from cache, sometimes from array
        // Side effect: modifies cache
        if (Math.random() > 0.5) {
            const user = this.users.find(u => u.id === id);
            if (user) {
                this.cache.set(id, user); // Unexpected side effect
            }
            return user;
        } else {
            return this.cache.get(id);
        }
    }
    
    addUser(user: User): boolean {
        // Unpredictable: sometimes fails silently
        if (user.name.length < 2) {
            return false; // Silent failure
        }
        
        this.users.push(user);
        
        // Unexpected behavior: automatically sends email
        this.sendWelcomeEmail(user); // Side effect not obvious from method name
        return true;
    }
    
    private sendWelcomeEmail(user: User): void {
        console.log(`Sending email to ${user.email}`);
    }
}

// ✅ Good: Predictable behavior
interface UserRepository {
    save(user: User): Promise<void>;
    findById(id: string): Promise<User | null>;
    findAll(): Promise<User[]>;
}

interface UserValidationResult {
    isValid: boolean;
    errors: string[];
}

interface EmailService {
    sendWelcomeEmail(user: User): Promise<void>;
}

class UserService {
    constructor(
        private repository: UserRepository,
        private emailService: EmailService
    ) {}
    
    async findUserById(id: string): Promise<User | null> {
        // Predictable: always does the same thing
        return await this.repository.findById(id);
    }
    
    validateUser(user: User): UserValidationResult {
        // Predictable: pure function, no side effects
        const errors: string[] = [];
        
        if (!user.name || user.name.length < 2) {
            errors.push('Name must be at least 2 characters long');
        }
        
        if (!user.email || !this.isValidEmail(user.email)) {
            errors.push('Valid email is required');
        }
        
        return {
            isValid: errors.length === 0,
            errors
        };
    }
    
    async createUser(user: User): Promise<{ success: boolean; errors?: string[] }> {
        // Predictable: clear return type, explicit error handling
        const validation = this.validateUser(user);
        
        if (!validation.isValid) {
            return { success: false, errors: validation.errors };
        }
        
        try {
            await this.repository.save(user);
            return { success: true };
        } catch (error) {
            return { 
                success: false, 
                errors: [`Failed to save user: ${error.message}`] 
            };
        }
    }
    
    async createUserAndSendWelcome(user: User): Promise<{ success: boolean; errors?: string[] }> {
        // Predictable: method name clearly states what it does
        const createResult = await this.createUser(user);
        
        if (!createResult.success) {
            return createResult;
        }
        
        try {
            await this.emailService.sendWelcomeEmail(user);
            return { success: true };
        } catch (error) {
            return { 
                success: false, 
                errors: [`User created but email failed: ${error.message}`] 
            };
        }
    }
    
    private isValidEmail(email: string): boolean {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }
}
```

#### Python Predictable Example

```python
from typing import List, Optional, Dict, Any
from dataclasses import dataclass

# ✅ Good: Predictable data structures and functions
@dataclass
class ProcessingResult:
    success: bool
    data: Optional[Any] = None
    errors: List[str] = None
    
    def __post_init__(self):
        if self.errors is None:
            self.errors = []

class DataProcessor:
    @staticmethod
    def clean_data(raw_data: List[Dict[str, Any]]) -> ProcessingResult:
        """
        Predictable: Always returns ProcessingResult
        No side effects, pure function
        """
        try:
            cleaned = []
            errors = []
            
            for i, item in enumerate(raw_data):
                if not isinstance(item, dict):
                    errors.append(f"Item {i} is not a dictionary")
                    continue
                
                # Predictable cleaning rules
                clean_item = {
                    key: str(value).strip() if value is not None else ""
                    for key, value in item.items()
                }
                cleaned.append(clean_item)
            
            return ProcessingResult(
                success=len(errors) == 0,
                data=cleaned,
                errors=errors
            )
        except Exception as e:
            return ProcessingResult(
                success=False,
                errors=[f"Unexpected error: {str(e)}"]
            )
    
    @staticmethod
    def validate_required_fields(data: List[Dict[str, Any]], 
                                required_fields: List[str]) -> ProcessingResult:
        """
        Predictable: Clear input/output contract
        """
        errors = []
        
        for i, item in enumerate(data):
            for field in required_fields:
                if field not in item or not item[field]:
                    errors.append(f"Item {i} missing required field: {field}")
        
        return ProcessingResult(
            success=len(errors) == 0,
            data=data if len(errors) == 0 else None,
            errors=errors
        )
```

### 4. Idiomatic

**Definition**: Code should feel natural in the language and environment it's written in. Follow the conventions and patterns that are familiar to developers in that ecosystem.

#### TypeScript Idiomatic Code

```typescript
// ✅ Good: Idiomatic TypeScript
interface User {
    readonly id: string;
    name: string;
    email: string;
    createdAt: Date;
}

interface UserRepository {
    findById(id: string): Promise<User | null>;
    save(user: User): Promise<void>;
    findByEmail(email: string): Promise<User | null>;
}

// Using TypeScript's advanced type features idiomatically
type UserCreateInput = Omit<User, 'id' | 'createdAt'>;
type UserUpdateInput = Partial<Pick<User, 'name' | 'email'>>;

class UserService {
    constructor(private readonly repository: UserRepository) {}
    
    // Idiomatic async/await usage
    async createUser(input: UserCreateInput): Promise<User> {
        const existingUser = await this.repository.findByEmail(input.email);
        
        if (existingUser) {
            throw new Error('User with this email already exists');
        }
        
        const user: User = {
            id: crypto.randomUUID(),
            ...input,
            createdAt: new Date()
        };
        
        await this.repository.save(user);
        return user;
    }
    
    // Idiomatic optional chaining and nullish coalescing
    async updateUser(id: string, updates: UserUpdateInput): Promise<User | null> {
        const user = await this.repository.findById(id);
        
        if (!user) {
            return null;
        }
        
        const updatedUser: User = {
            ...user,
            name: updates.name ?? user.name,
            email: updates.email ?? user.email
        };
        
        await this.repository.save(updatedUser);
        return updatedUser;
    }
    
    // Idiomatic array methods and functional programming
    async getUsersByEmails(emails: string[]): Promise<User[]> {
        const userPromises = emails.map(email => 
            this.repository.findByEmail(email)
        );
        
        const users = await Promise.all(userPromises);
        
        return users
            .filter((user): user is User => user !== null)
            .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
    }
}

// ❌ Bad: Non-idiomatic TypeScript (Java-style)
class UserServiceJavaStyle {
    private repository: UserRepository;
    
    constructor(repository: UserRepository) {
        this.repository = repository;
    }
    
    public createUser(name: string, email: string): Promise<User> {
        return new Promise<User>((resolve, reject) => {
            this.repository.findByEmail(email).then((existingUser: User | null) => {
                if (existingUser != null) {
                    reject(new Error('User exists'));
                    return;
                }
                
                let user: User = {
                    id: this.generateId(),
                    name: name,
                    email: email,
                    createdAt: new Date()
                };
                
                this.repository.save(user).then(() => {
                    resolve(user);
                }).catch((error: any) => {
                    reject(error);
                });
            }).catch((error: any) => {
                reject(error);
            });
        });
    }
    
    private generateId(): string {
        return Math.random().toString(36);
    }
}
```

#### Python Idiomatic Code

```python
from typing import List, Dict, Optional, Iterator
from dataclasses import dataclass, field
from pathlib import Path
import json

# ✅ Good: Idiomatic Python
@dataclass
class Configuration:
    app_name: str
    debug: bool = False
    database_url: str = ""
    allowed_hosts: List[str] = field(default_factory=list)
    
    @classmethod
    def from_file(cls, config_path: Path) -> 'Configuration':
        """Idiomatic class method constructor"""
        with config_path.open() as f:
            data = json.load(f)
        return cls(**data)
    
    def __post_init__(self):
        """Pythonic post-initialization validation"""
        if not self.app_name:
            raise ValueError("app_name is required")

class DataProcessor:
    def __init__(self, config: Configuration):
        self.config = config
    
    def process_items(self, items: List[Dict]) -> Iterator[Dict]:
        """Idiomatic generator function"""
        for item in items:
            if self._is_valid_item(item):
                yield self._transform_item(item)
    
    def _is_valid_item(self, item: Dict) -> bool:
        """Pythonic private method naming"""
        return bool(item.get('id')) and bool(item.get('name'))
    
    def _transform_item(self, item: Dict) -> Dict:
        """Idiomatic dict comprehension and string methods"""
        return {
            key.lower().replace(' ', '_'): str(value).strip()
            for key, value in item.items()
            if value is not None
        }
    
    def batch_process(self, items: List[Dict], batch_size: int = 100) -> List[Dict]:
        """Idiomatic list comprehension with slicing"""
        processed_items = list(self.process_items(items))
        
        return [
            processed_items[i:i + batch_size]
            for i in range(0, len(processed_items), batch_size)
        ]
    
    def __len__(self) -> int:
        """Pythonic magic method"""
        return len(self.config.allowed_hosts)
    
    def __repr__(self) -> str:
        """Pythonic string representation"""
        return f"DataProcessor(app={self.config.app_name})"

# Context manager - idiomatic Python
class DatabaseConnection:
    def __init__(self, connection_string: str):
        self.connection_string = connection_string
        self.connection = None
    
    def __enter__(self):
        print(f"Connecting to {self.connection_string}")
        self.connection = "mock_connection"
        return self.connection
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        print("Closing connection")
        self.connection = None

# Idiomatic usage
def main():
    config = Configuration.from_file(Path("config.json"))
    processor = DataProcessor(config)
    
    # Context manager usage
    with DatabaseConnection(config.database_url) as conn:
        # List comprehension with conditional
        items = [
            {'id': i, 'name': f'Item {i}'}
            for i in range(10)
            if i % 2 == 0
        ]
        
        # Generator usage
        processed = list(processor.process_items(items))
        print(f"Processed {len(processed)} items")
```

### 5. Domain-based

**Definition**: Code should reflect the problem domain. Use the language and concepts that domain experts use.

#### E-commerce Domain Example - TypeScript

```typescript
// ✅ Good: Domain-driven terminology
interface Money {
    readonly amount: number;
    readonly currency: string;
}

interface Product {
    readonly sku: string;
    readonly name: string;
    readonly price: Money;
    readonly inventory: number;
}

interface Customer {
    readonly customerId: string;
    readonly email: string;
    readonly shippingAddress: Address;
    readonly loyaltyTier: 'Bronze' | 'Silver' | 'Gold' | 'Platinum';
}

interface Address {
    street: string;
    city: string;
    state: string;
    zipCode: string;
    country: string;
}

// Domain entities use business language
class ShoppingCart {
    private items: Map<string, CartItem> = new Map();
    
    addItem(product: Product, quantity: number): void {
        const existingItem = this.items.get(product.sku);
        
        if (existingItem) {
            existingItem.increaseQuantity(quantity);
        } else {
            this.items.set(product.sku, new CartItem(product, quantity));
        }
    }
    
    removeItem(sku: string): void {
        this.items.delete(sku);
    }
    
    calculateSubtotal(): Money {
        let total = 0;
        let currency = 'USD';
        
        for (const item of this.items.values()) {
            total += item.getLineTotal().amount;
            currency = item.getLineTotal().currency;
        }
        
        return { amount: total, currency };
    }
    
    applyDiscount(discount: Discount): Money {
        const subtotal = this.calculateSubtotal();
        return discount.apply(subtotal);
    }
    
    isEmpty(): boolean {
        return this.items.size === 0;
    }
}

class CartItem {
    constructor(
        private readonly product: Product,
        private quantity: number
    ) {}
    
    increaseQuantity(amount: number): void {
        this.quantity += amount;
    }
    
    decreaseQuantity(amount: number): void {
        if (amount >= this.quantity) {
            throw new Error('Cannot decrease quantity below zero');
        }
        this.quantity -= amount;
    }
    
    getLineTotal(): Money {
        return {
            amount: this.product.price.amount * this.quantity,
            currency: this.product.price.currency
        };
    }
}

// Domain services use business concepts
abstract class Discount {
    abstract apply(subtotal: Money): Money;
    abstract description(): string;
}

class PercentageDiscount extends Discount {
    constructor(private readonly percentage: number) {
        super();
    }
    
    apply(subtotal: Money): Money {
        const discountAmount = subtotal.amount * (this.percentage / 100);
        return {
            amount: subtotal.amount - discountAmount,
            currency: subtotal.currency
        };
    }
    
    description(): string {
        return `${this.percentage}% off`;
    }
}

class LoyaltyDiscount extends Discount {
    private static readonly TIER_DISCOUNTS = {
        'Bronze': 0,
        'Silver': 5,
        'Gold': 10,
        'Platinum': 15
    };
    
    constructor(private readonly loyaltyTier: Customer['loyaltyTier']) {
        super();
    }
    
    apply(subtotal: Money): Money {
        const discountPercent = LoyaltyDiscount.TIER_DISCOUNTS[this.loyaltyTier];
        const discountAmount = subtotal.amount * (discountPercent / 100);
        
        return {
            amount: subtotal.amount - discountAmount,
            currency: subtotal.currency
        };
    }
    
    description(): string {
        const percent = LoyaltyDiscount.TIER_DISCOUNTS[this.loyaltyTier];
        return `${this.loyaltyTier} member ${percent}% discount`;
    }
}

class OrderService {
    async placeOrder(
        customer: Customer,
        cart: ShoppingCart,
        paymentMethod: PaymentMethod
    ): Promise<Order> {
        if (cart.isEmpty()) {
            throw new Error('Cannot place order with empty cart');
        }
        
        const loyaltyDiscount = new LoyaltyDiscount(customer.loyaltyTier);
        const finalAmount = cart.applyDiscount(loyaltyDiscount);
        
        const payment = await this.processPayment(paymentMethod, finalAmount);
        
        if (!payment.isSuccessful()) {
            throw new Error('Payment processing failed');
        }
        
        return new Order(
            customer,
            cart,
            finalAmount,
            payment.getTransactionId()
        );
    }
    
    private async processPayment(
        paymentMethod: PaymentMethod, 
        amount: Money
    ): Promise<PaymentResult> {
        // Domain-specific payment processing
        return await paymentMethod.charge(amount);
    }
}

// ❌ Bad: Technical/generic terminology
class DataManager {
    private records: Map<string, any> = new Map();
    
    addRecord(key: string, data: any): void {
        this.records.set(key, data);
    }
    
    processCalculation(items: any[]): number {
        return items.reduce((sum, item) => sum + item.value, 0);
    }
    
    executeBusinessLogic(input: any): any {
        // Generic, non-domain specific code
        return input;
    }
}
```

#### Banking Domain Example - Python

```python
from decimal import Decimal, ROUND_HALF_UP
from datetime import datetime
from typing import List, Optional
from enum import Enum
from dataclasses import dataclass

# ✅ Good: Banking domain language
class TransactionType(Enum):
    DEPOSIT = "deposit"
    WITHDRAWAL = "withdrawal"
    TRANSFER = "transfer"
    INTEREST_CREDIT = "interest_credit"
    OVERDRAFT_FEE = "overdraft_fee"

class AccountType(Enum):
    CHECKING = "checking"
    SAVINGS = "savings"
    MONEY_MARKET = "money_market"

@dataclass(frozen=True)
class Money:
    amount: Decimal
    currency: str = "USD"
    
    def __post_init__(self):
        # Domain rule: money amounts should be precise
        object.__setattr__(self, 'amount', 
                          self.amount.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP))
    
    def add(self, other: 'Money') -> 'Money':
        if self.currency != other.currency:
            raise ValueError("Cannot add different currencies")
        return Money(self.amount + other.amount, self.currency)
    
    def subtract(self, other: 'Money') -> 'Money':
        if self.currency != other.currency:
            raise ValueError("Cannot subtract different currencies")
        return Money(self.amount - other.amount, self.currency)

@dataclass
class Transaction:
    transaction_id: str
    account_number: str
    transaction_type: TransactionType
    amount: Money
    timestamp: datetime
    description: str
    balance_after: Money

class BankAccount:
    def __init__(self, account_number: str, account_type: AccountType, 
                 account_holder: str, initial_deposit: Money):
        self.account_number = account_number
        self.account_type = account_type
        self.account_holder = account_holder
        self.balance = initial_deposit
        self.transaction_history: List[Transaction] = []
        self.is_active = True
        self.created_date = datetime.now()
    
    def deposit(self, amount: Money, description: str = "") -> Transaction:
        """Domain operation: making a deposit"""
        if not self.is_active:
            raise ValueError("Cannot deposit to inactive account")
        
        if amount.amount <= 0:
            raise ValueError("Deposit amount must be positive")
        
        self.balance = self.balance.add(amount)
        
        transaction = Transaction(
            transaction_id=self._generate_transaction_id(),
            account_number=self.account_number,
            transaction_type=TransactionType.DEPOSIT,
            amount=amount,
            timestamp=datetime.now(),
            description=description or f"Deposit to {self.account_type.value}",
            balance_after=self.balance
        )
        
        self.transaction_history.append(transaction)
        return transaction
    
    def withdraw(self, amount: Money, description: str = "") -> Transaction:
        """Domain operation: making a withdrawal"""
        if not self.is_active:
            raise ValueError("Cannot withdraw from inactive account")
        
        if amount.amount <= 0:
            raise ValueError("Withdrawal amount must be positive")
        
        # Domain rule: checking accounts allow overdrafts, savings don't
        if self.account_type == AccountType.SAVINGS and amount.amount > self.balance.amount:
            raise ValueError("Insufficient funds for withdrawal")
        
        self.balance = self.balance.subtract(amount)
        
        # Domain rule: overdraft fee for negative balance
        if self.balance.amount < 0 and self.account_type == AccountType.CHECKING:
            overdraft_fee = Money(Decimal('35.00'))
            self.balance = self.balance.subtract(overdraft_fee)
            
            # Record overdraft fee transaction
            fee_transaction = Transaction(
                transaction_id=self._generate_transaction_id(),
                account_number=self.account_number,
                transaction_type=TransactionType.OVERDRAFT_FEE,
                amount=overdraft_fee,
                timestamp=datetime.now(),
                description="Overdraft fee",
                balance_after=self.balance
            )
            self.transaction_history.append(fee_transaction)
        
        transaction = Transaction(
            transaction_id=self._generate_transaction_id(),
            account_number=self.account_number,
            transaction_type=TransactionType.WITHDRAWAL,
            amount=amount,
            timestamp=datetime.now(),
            description=description or f"Withdrawal from {self.account_type.value}",
            balance_after=self.balance
        )
        
        self.transaction_history.append(transaction)
        return transaction
    
    def calculate_available_balance(self) -> Money:
        """Domain concept: available balance vs actual balance"""
        if self.account_type == AccountType.CHECKING:
            # Checking accounts have overdraft protection up to $500
            overdraft_limit = Money(Decimal('500.00'))
            return self.balance.add(overdraft_limit)
        else:
            # Savings accounts can't go negative
            return self.balance if self.balance.amount >= 0 else Money(Decimal('0.00'))
    
    def get_monthly_statement(self, year: int, month: int) -> List[Transaction]:
        """Domain operation: generating monthly statements"""
        return [
            transaction for transaction in self.transaction_history
            if transaction.timestamp.year == year and transaction.timestamp.month == month
        ]
    
    def close_account(self) -> None:
        """Domain operation: account closure"""
        if self.balance.amount != 0:
            raise ValueError("Cannot close account with non-zero balance")
        self.is_active = False
    
    def _generate_transaction_id(self) -> str:
        """Generate unique transaction ID"""
        import uuid
        return str(uuid.uuid4())[:8].upper()

class BankingService:
    def __init__(self):
        self.accounts: dict[str, BankAccount] = {}
    
    def open_account(self, account_holder: str, account_type: AccountType, 
                     initial_deposit: Money) -> BankAccount:
        """Domain service: account opening"""
        # Domain rule: minimum opening deposit requirements
        minimum_deposits = {
            AccountType.CHECKING: Money(Decimal('25.00')),
            AccountType.SAVINGS: Money(Decimal('100.00')),
            AccountType.MONEY_MARKET: Money(Decimal('2500.00'))
        }
        
        if initial_deposit.amount < minimum_deposits[account_type].amount:
            raise ValueError(f"Minimum opening deposit for {account_type.value} is "
                           f"{minimum_deposits[account_type].amount}")
        
        account_number = self._generate_account_number()
        account = BankAccount(account_number, account_type, account_holder, initial_deposit)
        self.accounts[account_number] = account
        return account
    
    def transfer_funds(self, from_account: str, to_account: str, 
                      amount: Money, description: str = "") -> tuple[Transaction, Transaction]:
        """Domain service: inter-account transfers"""
        source = self.accounts.get(from_account)
        destination = self.accounts.get(to_account)
        
        if not source or not destination:
            raise ValueError("Invalid account numbers")
        
        # Execute as atomic operation
        withdrawal = source.withdraw(amount, f"Transfer to {to_account}")
        deposit = destination.deposit(amount, f"Transfer from {from_account}")
        
        return withdrawal, deposit
    
    def _generate_account_number(self) -> str:
        """Generate unique account number"""
        import random
        return f"{random.randint(100000, 999999)}"
```

## When to Use CUPID Principles

### ✅ Use When:
- Building complex business applications
- Working with domain experts
- Creating maintainable codebases
- Developing in teams
- Building systems that need to evolve
- When code joy and developer experience matter

### ❌ Consider Alternatives When:
- Working on simple scripts or utilities
- Building prototypes or throwaway code
- Working under extreme time pressure
- When performance is the absolute priority
- In highly constrained environments

## Common Mistakes and How to Avoid Them

### 1. Over-Composing Simple Operations
```typescript
// ❌ Overkill composition
const addOne = (x: number) => x + 1;
const multiplyByTwo = (x: number) => x * 2;
const subtractThree = (x: number) => x - 3;

const complexOperation = pipe(addOne, multiplyByTwo, subtractThree);

// ✅ Simple and clear
const simpleOperation = (x: number) => (x + 1) * 2 - 3;
```

### 2. Fighting Language Idioms
```python
# ❌ Fighting Python idioms
class ListProcessor:
    def process_list(self, items):
        result = []
        for i in range(len(items)):
            if items[i] % 2 == 0:
                result.append(items[i] * 2)
        return result

# ✅ Pythonic approach
def process_list(items):
    return [item * 2 for item in items if item % 2 == 0]
```

### 3. Over-Engineering Domain Models
```typescript
// ❌ Over-engineered
class EmailAddress {
    private value: string;
    constructor(email: string) {
        this.validate(email);
        this.value = email;
    }
    
    private validate(email: string): void {
        // Complex validation logic
    }
    
    getValue(): string { return this.value; }
}

class Person {
    constructor(private email: EmailAddress) {}
}

// ✅ Appropriate for context
interface Person {
    email: string; // Simple validation at boundaries
}

function isValidEmail(email: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
```

## Benefits and Trade-offs

### Benefits
- **Developer Joy**: Code is pleasant to work with
- **Domain Alignment**: Code matches business concepts
- **Maintainability**: Easier to understand and modify
- **Composability**: Pieces work well together
- **Predictability**: Behavior is clear and expected
- **Team Productivity**: Reduced cognitive load

### Trade-offs
- **Learning Curve**: Requires understanding domain concepts
- **Initial Overhead**: More upfront design thinking
- **Abstraction Cost**: Additional layers may impact performance
- **Context Sensitivity**: What's idiomatic varies by language/team
- **Flexibility vs Simplicity**: Balance needed for each situation

## CUPID vs SOLID Comparison

| Aspect | SOLID | CUPID |
|--------|-------|-------|
| Focus | Object-oriented design | Human-centric properties |
| Approach | Prescriptive rules | Descriptive properties |
| Domain | Technical structure | Business alignment |
| Flexibility | More rigid | More contextual |
| Adoption | Established standard | Emerging alternative |

## Real-World Application

```typescript
// E-commerce checkout process following CUPID
class CheckoutService {
    constructor(
        private cartService: CartService,
        private pricingService: PricingService,
        private paymentService: PaymentService,
        private inventoryService: InventoryService,
        private orderService: OrderService
    ) {}
    
    // Composable: each step is independent and reusable
    // Unix philosophy: each service does one thing well
    // Predictable: clear input/output contracts
    // Idiomatic: follows TypeScript conventions
    // Domain-based: uses checkout business language
    async processCheckout(checkoutRequest: CheckoutRequest): Promise<CheckoutResult> {
        // Validate cart items are still available
        const availability = await this.inventoryService.checkAvailability(
            checkoutRequest.cartId
        );
        
        if (!availability.allItemsAvailable) {
            return CheckoutResult.unavailableItems(availability.unavailableItems);
        }
        
        // Calculate final pricing
        const pricing = await this.pricingService.calculateFinalPrice(
            checkoutRequest.cartId,
            checkoutRequest.customerId,
            checkoutRequest.promoCode
        );
        
        // Process payment
        const paymentResult = await this.paymentService.processPayment({
            amount: pricing.finalAmount,
            paymentMethod: checkoutRequest.paymentMethod,
            customerId: checkoutRequest.customerId
        });
        
        if (!paymentResult.isSuccessful) {
            return CheckoutResult.paymentFailed(paymentResult.errorMessage);
        }
        
        // Create order
        const order = await this.orderService.createOrder({
            customerId: checkoutRequest.customerId,
            cartId: checkoutRequest.cartId,
            paymentTransactionId: paymentResult.transactionId,
            finalAmount: pricing.finalAmount
        });
        
        return CheckoutResult.success(order);
    }
}
```

## Conclusion

CUPID principles provide a human-centric approach to writing code that is joyful to work with. Unlike SOLID's focus on object-oriented structure, CUPID emphasizes properties that make code feel natural, predictable, and aligned with the problem domain. 

The key is to apply these properties thoughtfully, considering your specific context, team, and requirements. CUPID isn't about replacing SOLID but offering an alternative perspective that prioritizes developer experience and domain alignment.

Remember: These are properties to strive for, not rigid rules. The goal is joyful coding that serves both developers and the business domain effectively.