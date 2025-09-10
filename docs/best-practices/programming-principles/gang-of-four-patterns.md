# Gang of Four Design Patterns

## Overview

The Gang of Four (GoF) design patterns are 23 common software design patterns introduced in the book "Design Patterns: Elements of Reusable Object-Oriented Software" by Erich Gamma, Richard Helm, Ralph Johnson, and John Vlissides in 1994.

## Pattern Categories

### Creational Patterns
Deal with object creation mechanisms

### Structural Patterns  
Deal with object composition and relationships

### Behavioral Patterns
Deal with communication between objects and the assignment of responsibilities

---

## Creational Patterns

### 1. Singleton

**Intent**: Ensure a class has only one instance and provide global access to it.

```typescript
// Traditional Singleton (not recommended in modern JS/TS)
class DatabaseConnection {
  private static instance: DatabaseConnection;
  private constructor(private connectionString: string) {}
  
  static getInstance(connectionString: string = 'default'): DatabaseConnection {
    if (!DatabaseConnection.instance) {
      DatabaseConnection.instance = new DatabaseConnection(connectionString);
    }
    return DatabaseConnection.instance;
  }
  
  query(sql: string): any[] {
    console.log(`Executing: ${sql}`);
    return [];
  }
}

// Modern approach: Module singleton
class DatabaseManager {
  constructor(private connectionString: string) {}
  
  query(sql: string): any[] {
    console.log(`Executing: ${sql}`);
    return [];
  }
}

// Export single instance
export const dbManager = new DatabaseManager(process.env.DB_CONNECTION_STRING!);

// Usage
import { dbManager } from './database';
const results = dbManager.query('SELECT * FROM users');
```

### 2. Factory Method

**Intent**: Create objects without specifying the exact class to create.

```typescript
// Product hierarchy
interface Logger {
  log(message: string): void;
}

class FileLogger implements Logger {
  log(message: string): void {
    console.log(`[FILE] ${message}`);
  }
}

class DatabaseLogger implements Logger {
  log(message: string): void {
    console.log(`[DB] ${message}`);
  }
}

class ConsoleLogger implements Logger {
  log(message: string): void {
    console.log(`[CONSOLE] ${message}`);
  }
}

// Factory
abstract class LoggerFactory {
  abstract createLogger(): Logger;
  
  // Template method using the factory method
  logMessage(message: string): void {
    const logger = this.createLogger();
    logger.log(message);
  }
}

class FileLoggerFactory extends LoggerFactory {
  createLogger(): Logger {
    return new FileLogger();
  }
}

class DatabaseLoggerFactory extends LoggerFactory {
  createLogger(): Logger {
    return new DatabaseLogger();
  }
}

// Usage
function clientCode(factory: LoggerFactory) {
  factory.logMessage('Application started');
}

clientCode(new FileLoggerFactory());
clientCode(new DatabaseLoggerFactory());
```

### 3. Abstract Factory

**Intent**: Provide an interface for creating families of related objects.

```typescript
// Abstract products
interface Button {
  render(): void;
  onClick(callback: () => void): void;
}

interface Checkbox {
  render(): void;
  toggle(): void;
}

// Windows implementations
class WindowsButton implements Button {
  render(): void {
    console.log('Rendering Windows button');
  }
  
  onClick(callback: () => void): void {
    console.log('Windows button clicked');
    callback();
  }
}

class WindowsCheckbox implements Checkbox {
  render(): void {
    console.log('Rendering Windows checkbox');
  }
  
  toggle(): void {
    console.log('Windows checkbox toggled');
  }
}

// macOS implementations
class MacButton implements Button {
  render(): void {
    console.log('Rendering macOS button');
  }
  
  onClick(callback: () => void): void {
    console.log('macOS button clicked');
    callback();
  }
}

class MacCheckbox implements Checkbox {
  render(): void {
    console.log('Rendering macOS checkbox');
  }
  
  toggle(): void {
    console.log('macOS checkbox toggled');
  }
}

// Abstract factory
interface GUIFactory {
  createButton(): Button;
  createCheckbox(): Checkbox;
}

// Concrete factories
class WindowsFactory implements GUIFactory {
  createButton(): Button {
    return new WindowsButton();
  }
  
  createCheckbox(): Checkbox {
    return new WindowsCheckbox();
  }
}

class MacFactory implements GUIFactory {
  createButton(): Button {
    return new MacButton();
  }
  
  createCheckbox(): Checkbox {
    return new MacCheckbox();
  }
}

// Client code
class Application {
  constructor(private factory: GUIFactory) {}
  
  createUI(): void {
    const button = this.factory.createButton();
    const checkbox = this.factory.createCheckbox();
    
    button.render();
    checkbox.render();
  }
}

// Usage
const os = process.platform;
const factory = os === 'darwin' ? new MacFactory() : new WindowsFactory();
const app = new Application(factory);
app.createUI();
```

### 4. Builder

**Intent**: Construct complex objects step by step.

```typescript
// Product
class House {
  constructor(
    public walls: string,
    public doors: number,
    public windows: number,
    public roof: string,
    public garage: boolean = false,
    public garden: boolean = false,
    public pool: boolean = false
  ) {}
  
  describe(): string {
    return `House with ${this.walls} walls, ${this.doors} doors, ${this.windows} windows, ${this.roof} roof` +
           `${this.garage ? ', garage' : ''}${this.garden ? ', garden' : ''}${this.pool ? ', pool' : ''}`;
  }
}

// Builder interface
interface HouseBuilder {
  setWalls(walls: string): HouseBuilder;
  setDoors(doors: number): HouseBuilder;
  setWindows(windows: number): HouseBuilder;
  setRoof(roof: string): HouseBuilder;
  addGarage(): HouseBuilder;
  addGarden(): HouseBuilder;
  addPool(): HouseBuilder;
  build(): House;
}

// Concrete builder
class ConcreteHouseBuilder implements HouseBuilder {
  private walls: string = '';
  private doors: number = 0;
  private windows: number = 0;
  private roof: string = '';
  private garage: boolean = false;
  private garden: boolean = false;
  private pool: boolean = false;
  
  setWalls(walls: string): HouseBuilder {
    this.walls = walls;
    return this;
  }
  
  setDoors(doors: number): HouseBuilder {
    this.doors = doors;
    return this;
  }
  
  setWindows(windows: number): HouseBuilder {
    this.windows = windows;
    return this;
  }
  
  setRoof(roof: string): HouseBuilder {
    this.roof = roof;
    return this;
  }
  
  addGarage(): HouseBuilder {
    this.garage = true;
    return this;
  }
  
  addGarden(): HouseBuilder {
    this.garden = true;
    return this;
  }
  
  addPool(): HouseBuilder {
    this.pool = true;
    return this;
  }
  
  build(): House {
    return new House(
      this.walls,
      this.doors,
      this.windows,
      this.roof,
      this.garage,
      this.garden,
      this.pool
    );
  }
}

// Director (optional)
class HouseDirector {
  buildMinimalHouse(builder: HouseBuilder): House {
    return builder
      .setWalls('wood')
      .setDoors(1)
      .setWindows(2)
      .setRoof('tile')
      .build();
  }
  
  buildLuxuryHouse(builder: HouseBuilder): House {
    return builder
      .setWalls('brick')
      .setDoors(3)
      .setWindows(8)
      .setRoof('slate')
      .addGarage()
      .addGarden()
      .addPool()
      .build();
  }
}

// Usage
const builder = new ConcreteHouseBuilder();
const director = new HouseDirector();

const minimalHouse = director.buildMinimalHouse(builder);
console.log(minimalHouse.describe());

const customHouse = new ConcreteHouseBuilder()
  .setWalls('concrete')
  .setDoors(2)
  .setWindows(4)
  .setRoof('metal')
  .addGarden()
  .build();

console.log(customHouse.describe());
```

### 5. Prototype

**Intent**: Create objects by cloning existing instances.

```typescript
interface Cloneable {
  clone(): Cloneable;
}

class Shape implements Cloneable {
  constructor(
    public x: number,
    public y: number,
    public color: string
  ) {}
  
  clone(): Shape {
    return new Shape(this.x, this.y, this.color);
  }
  
  draw(): void {
    console.log(`Drawing shape at (${this.x}, ${this.y}) with color ${this.color}`);
  }
}

class Circle extends Shape {
  constructor(
    x: number,
    y: number,
    color: string,
    public radius: number
  ) {
    super(x, y, color);
  }
  
  clone(): Circle {
    return new Circle(this.x, this.y, this.color, this.radius);
  }
  
  draw(): void {
    console.log(`Drawing circle at (${this.x}, ${this.y}) with radius ${this.radius} and color ${this.color}`);
  }
}

class Rectangle extends Shape {
  constructor(
    x: number,
    y: number,
    color: string,
    public width: number,
    public height: number
  ) {
    super(x, y, color);
  }
  
  clone(): Rectangle {
    return new Rectangle(this.x, this.y, this.color, this.width, this.height);
  }
  
  draw(): void {
    console.log(`Drawing rectangle at (${this.x}, ${this.y}) with size ${this.width}x${this.height} and color ${this.color}`);
  }
}

// Prototype registry
class ShapeRegistry {
  private prototypes: Map<string, Shape> = new Map();
  
  register(id: string, prototype: Shape): void {
    this.prototypes.set(id, prototype);
  }
  
  create(id: string): Shape | null {
    const prototype = this.prototypes.get(id);
    return prototype ? prototype.clone() : null;
  }
}

// Usage
const registry = new ShapeRegistry();

// Register prototypes
registry.register('red-circle', new Circle(0, 0, 'red', 10));
registry.register('blue-rectangle', new Rectangle(0, 0, 'blue', 20, 15));

// Clone prototypes
const circle1 = registry.create('red-circle') as Circle;
circle1.x = 10;
circle1.y = 20;

const circle2 = registry.create('red-circle') as Circle;
circle2.x = 30;
circle2.y = 40;

circle1.draw(); // Drawing circle at (10, 20) with radius 10 and color red
circle2.draw(); // Drawing circle at (30, 40) with radius 10 and color red
```

---

## Structural Patterns

### 1. Adapter

**Intent**: Allow incompatible interfaces to work together.

```typescript
// Target interface (what client expects)
interface MediaPlayer {
  play(audioType: string, fileName: string): void;
}

// Adaptee (existing incompatible interface)
class AdvancedMediaPlayer {
  playVlc(fileName: string): void {
    console.log(`Playing VLC file: ${fileName}`);
  }
  
  playMp4(fileName: string): void {
    console.log(`Playing MP4 file: ${fileName}`);
  }
}

// Adapter
class MediaAdapter implements MediaPlayer {
  private advancedPlayer: AdvancedMediaPlayer;
  
  constructor(private audioType: string) {
    this.advancedPlayer = new AdvancedMediaPlayer();
  }
  
  play(audioType: string, fileName: string): void {
    if (audioType === 'vlc') {
      this.advancedPlayer.playVlc(fileName);
    } else if (audioType === 'mp4') {
      this.advancedPlayer.playMp4(fileName);
    }
  }
}

// Context (Client)
class AudioPlayer implements MediaPlayer {
  play(audioType: string, fileName: string): void {
    if (audioType === 'mp3') {
      console.log(`Playing MP3 file: ${fileName}`);
    } else if (audioType === 'vlc' || audioType === 'mp4') {
      const adapter = new MediaAdapter(audioType);
      adapter.play(audioType, fileName);
    } else {
      console.log(`${audioType} format not supported`);
    }
  }
}

// Usage
const player = new AudioPlayer();
player.play('mp3', 'song.mp3');
player.play('vlc', 'movie.vlc');
player.play('mp4', 'video.mp4');
player.play('avi', 'video.avi'); // Not supported
```

### 2. Decorator

**Intent**: Add behavior to objects dynamically without altering their structure.

```typescript
// Component interface
interface Coffee {
  getCost(): number;
  getDescription(): string;
}

// Concrete component
class SimpleCoffee implements Coffee {
  getCost(): number {
    return 2;
  }
  
  getDescription(): string {
    return 'Simple coffee';
  }
}

// Base decorator
abstract class CoffeeDecorator implements Coffee {
  constructor(protected coffee: Coffee) {}
  
  getCost(): number {
    return this.coffee.getCost();
  }
  
  getDescription(): string {
    return this.coffee.getDescription();
  }
}

// Concrete decorators
class MilkDecorator extends CoffeeDecorator {
  getCost(): number {
    return super.getCost() + 0.5;
  }
  
  getDescription(): string {
    return super.getDescription() + ', milk';
  }
}

class SugarDecorator extends CoffeeDecorator {
  getCost(): number {
    return super.getCost() + 0.25;
  }
  
  getDescription(): string {
    return super.getDescription() + ', sugar';
  }
}

class WhipDecorator extends CoffeeDecorator {
  getCost(): number {
    return super.getCost() + 0.75;
  }
  
  getDescription(): string {
    return super.getDescription() + ', whip';
  }
}

// Usage
let coffee: Coffee = new SimpleCoffee();
console.log(`${coffee.getDescription()}: $${coffee.getCost()}`);

coffee = new MilkDecorator(coffee);
console.log(`${coffee.getDescription()}: $${coffee.getCost()}`);

coffee = new SugarDecorator(coffee);
console.log(`${coffee.getDescription()}: $${coffee.getCost()}`);

coffee = new WhipDecorator(coffee);
console.log(`${coffee.getDescription()}: $${coffee.getCost()}`);

// Output:
// Simple coffee: $2
// Simple coffee, milk: $2.5  
// Simple coffee, milk, sugar: $2.75
// Simple coffee, milk, sugar, whip: $3.5
```

### 3. Facade

**Intent**: Provide a simplified interface to a complex subsystem.

```typescript
// Complex subsystem classes
class CPU {
  freeze(): void {
    console.log('CPU: Freezing processor');
  }
  
  jump(position: number): void {
    console.log(`CPU: Jumping to position ${position}`);
  }
  
  execute(): void {
    console.log('CPU: Executing instructions');
  }
}

class Memory {
  load(position: number, data: string): void {
    console.log(`Memory: Loading data "${data}" at position ${position}`);
  }
}

class HardDrive {
  read(lba: number, size: number): string {
    console.log(`HardDrive: Reading ${size} bytes from LBA ${lba}`);
    return 'boot data';
  }
}

// Facade
class ComputerFacade {
  constructor(
    private cpu: CPU,
    private memory: Memory,
    private hardDrive: HardDrive
  ) {}
  
  start(): void {
    console.log('Starting computer...');
    this.cpu.freeze();
    const bootData = this.hardDrive.read(0, 1024);
    this.memory.load(0, bootData);
    this.cpu.jump(0);
    this.cpu.execute();
    console.log('Computer started successfully!');
  }
}

// Usage
const cpu = new CPU();
const memory = new Memory();
const hardDrive = new HardDrive();

const computer = new ComputerFacade(cpu, memory, hardDrive);
computer.start(); // Simple interface to complex boot process
```

### 4. Composite

**Intent**: Compose objects into tree structures to represent part-whole hierarchies.

```typescript
// Component interface
abstract class FileSystemComponent {
  constructor(protected name: string) {}
  
  abstract getSize(): number;
  abstract display(indent: string): void;
  
  // Default implementations for composite operations
  add(component: FileSystemComponent): void {
    throw new Error('Operation not supported');
  }
  
  remove(component: FileSystemComponent): void {
    throw new Error('Operation not supported');
  }
  
  getChildren(): FileSystemComponent[] {
    throw new Error('Operation not supported');
  }
}

// Leaf
class File extends FileSystemComponent {
  constructor(name: string, private size: number) {
    super(name);
  }
  
  getSize(): number {
    return this.size;
  }
  
  display(indent: string = ''): void {
    console.log(`${indent}📄 ${this.name} (${this.size} bytes)`);
  }
}

// Composite
class Directory extends FileSystemComponent {
  private children: FileSystemComponent[] = [];
  
  add(component: FileSystemComponent): void {
    this.children.push(component);
  }
  
  remove(component: FileSystemComponent): void {
    const index = this.children.indexOf(component);
    if (index !== -1) {
      this.children.splice(index, 1);
    }
  }
  
  getChildren(): FileSystemComponent[] {
    return [...this.children];
  }
  
  getSize(): number {
    return this.children.reduce((total, child) => total + child.getSize(), 0);
  }
  
  display(indent: string = ''): void {
    console.log(`${indent}📁 ${this.name}/`);
    this.children.forEach(child => child.display(indent + '  '));
  }
}

// Usage
const root = new Directory('root');
const documents = new Directory('documents');
const pictures = new Directory('pictures');

const resume = new File('resume.pdf', 1024);
const photo1 = new File('vacation.jpg', 2048);
const photo2 = new File('family.jpg', 1536);

documents.add(resume);
pictures.add(photo1);
pictures.add(photo2);

root.add(documents);
root.add(pictures);

console.log(`Total size: ${root.getSize()} bytes`);
root.display();
```

---

## Behavioral Patterns

### 1. Observer

**Intent**: Define a one-to-many dependency between objects so that when one object changes state, all dependents are notified.

```typescript
// Observer interface
interface Observer {
  update(temperature: number, humidity: number, pressure: number): void;
}

// Subject interface
interface Subject {
  registerObserver(observer: Observer): void;
  removeObserver(observer: Observer): void;
  notifyObservers(): void;
}

// Concrete subject
class WeatherData implements Subject {
  private observers: Observer[] = [];
  private temperature: number = 0;
  private humidity: number = 0;
  private pressure: number = 0;
  
  registerObserver(observer: Observer): void {
    this.observers.push(observer);
  }
  
  removeObserver(observer: Observer): void {
    const index = this.observers.indexOf(observer);
    if (index !== -1) {
      this.observers.splice(index, 1);
    }
  }
  
  notifyObservers(): void {
    this.observers.forEach(observer => {
      observer.update(this.temperature, this.humidity, this.pressure);
    });
  }
  
  measurementsChanged(): void {
    this.notifyObservers();
  }
  
  setMeasurements(temperature: number, humidity: number, pressure: number): void {
    this.temperature = temperature;
    this.humidity = humidity;
    this.pressure = pressure;
    this.measurementsChanged();
  }
  
  getTemperature(): number { return this.temperature; }
  getHumidity(): number { return this.humidity; }
  getPressure(): number { return this.pressure; }
}

// Concrete observers
class CurrentConditionsDisplay implements Observer {
  constructor(private weatherData: Subject) {
    weatherData.registerObserver(this);
  }
  
  update(temperature: number, humidity: number, pressure: number): void {
    console.log(`Current conditions: ${temperature}°C, ${humidity}% humidity`);
  }
}

class StatisticsDisplay implements Observer {
  private maxTemp: number = Number.MIN_VALUE;
  private minTemp: number = Number.MAX_VALUE;
  private tempSum: number = 0;
  private numReadings: number = 0;
  
  constructor(private weatherData: Subject) {
    weatherData.registerObserver(this);
  }
  
  update(temperature: number, humidity: number, pressure: number): void {
    this.tempSum += temperature;
    this.numReadings++;
    
    if (temperature > this.maxTemp) {
      this.maxTemp = temperature;
    }
    
    if (temperature < this.minTemp) {
      this.minTemp = temperature;
    }
    
    console.log(`Avg/Max/Min temperature: ${(this.tempSum/this.numReadings).toFixed(1)}/${this.maxTemp}/${this.minTemp}`);
  }
}

// Usage
const weatherData = new WeatherData();
const currentDisplay = new CurrentConditionsDisplay(weatherData);
const statisticsDisplay = new StatisticsDisplay(weatherData);

weatherData.setMeasurements(25, 65, 1013.25);
weatherData.setMeasurements(27, 70, 1010.15);
weatherData.setMeasurements(22, 90, 1012.0);
```

### 2. Strategy

**Intent**: Define a family of algorithms, encapsulate each one, and make them interchangeable.

```typescript
// Strategy interface
interface PaymentStrategy {
  pay(amount: number): void;
}

// Concrete strategies
class CreditCardStrategy implements PaymentStrategy {
  constructor(
    private name: string,
    private cardNumber: string,
    private cvv: string,
    private dateOfExpiry: string
  ) {}
  
  pay(amount: number): void {
    console.log(`$${amount} paid with credit card ending in ${this.cardNumber.slice(-4)}`);
  }
}

class PayPalStrategy implements PaymentStrategy {
  constructor(private emailId: string) {}
  
  pay(amount: number): void {
    console.log(`$${amount} paid using PayPal account ${this.emailId}`);
  }
}

class BitcoinStrategy implements PaymentStrategy {
  constructor(private walletAddress: string) {}
  
  pay(amount: number): void {
    console.log(`$${amount} paid using Bitcoin wallet ${this.walletAddress}`);
  }
}

// Context
class ShoppingCart {
  private items: { name: string; price: number }[] = [];
  
  addItem(name: string, price: number): void {
    this.items.push({ name, price });
  }
  
  calculateTotal(): number {
    return this.items.reduce((total, item) => total + item.price, 0);
  }
  
  pay(paymentStrategy: PaymentStrategy): void {
    const amount = this.calculateTotal();
    paymentStrategy.pay(amount);
  }
}

// Usage
const cart = new ShoppingCart();
cart.addItem('Laptop', 1200);
cart.addItem('Mouse', 25);

// Pay with different strategies
cart.pay(new CreditCardStrategy('John Doe', '1234567890123456', '123', '12/25'));
cart.pay(new PayPalStrategy('john@example.com'));
cart.pay(new BitcoinStrategy('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'));
```

### 3. Command

**Intent**: Encapsulate a request as an object, allowing you to parameterize clients with different requests and support undo operations.

```typescript
// Command interface
interface Command {
  execute(): void;
  undo(): void;
}

// Receiver
class Light {
  constructor(private location: string) {}
  
  on(): void {
    console.log(`${this.location} light is ON`);
  }
  
  off(): void {
    console.log(`${this.location} light is OFF`);
  }
}

class Stereo {
  on(): void {
    console.log('Stereo is ON');
  }
  
  off(): void {
    console.log('Stereo is OFF');
  }
  
  setVolume(volume: number): void {
    console.log(`Stereo volume set to ${volume}`);
  }
}

// Concrete commands
class LightOnCommand implements Command {
  constructor(private light: Light) {}
  
  execute(): void {
    this.light.on();
  }
  
  undo(): void {
    this.light.off();
  }
}

class LightOffCommand implements Command {
  constructor(private light: Light) {}
  
  execute(): void {
    this.light.off();
  }
  
  undo(): void {
    this.light.on();
  }
}

class StereoOnCommand implements Command {
  constructor(private stereo: Stereo) {}
  
  execute(): void {
    this.stereo.on();
    this.stereo.setVolume(11);
  }
  
  undo(): void {
    this.stereo.off();
  }
}

// Null object pattern
class NoCommand implements Command {
  execute(): void {}
  undo(): void {}
}

// Macro command
class MacroCommand implements Command {
  constructor(private commands: Command[]) {}
  
  execute(): void {
    this.commands.forEach(command => command.execute());
  }
  
  undo(): void {
    // Undo in reverse order
    for (let i = this.commands.length - 1; i >= 0; i--) {
      this.commands[i].undo();
    }
  }
}

// Invoker
class RemoteControl {
  private onCommands: Command[] = [];
  private offCommands: Command[] = [];
  private undoCommand: Command = new NoCommand();
  
  constructor() {
    // Initialize with NoCommand objects
    for (let i = 0; i < 7; i++) {
      this.onCommands[i] = new NoCommand();
      this.offCommands[i] = new NoCommand();
    }
  }
  
  setCommand(slot: number, onCommand: Command, offCommand: Command): void {
    this.onCommands[slot] = onCommand;
    this.offCommands[slot] = offCommand;
  }
  
  onButtonPressed(slot: number): void {
    this.onCommands[slot].execute();
    this.undoCommand = this.onCommands[slot];
  }
  
  offButtonPressed(slot: number): void {
    this.offCommands[slot].execute();
    this.undoCommand = this.offCommands[slot];
  }
  
  undoButtonPressed(): void {
    this.undoCommand.undo();
  }
}

// Usage
const remote = new RemoteControl();

// Set up devices
const livingRoomLight = new Light('Living Room');
const kitchenLight = new Light('Kitchen');
const stereo = new Stereo();

// Set up commands
const livingRoomLightOn = new LightOnCommand(livingRoomLight);
const livingRoomLightOff = new LightOffCommand(livingRoomLight);
const kitchenLightOn = new LightOnCommand(kitchenLight);
const kitchenLightOff = new LightOffCommand(kitchenLight);
const stereoOn = new StereoOnCommand(stereo);

// Set commands to remote
remote.setCommand(0, livingRoomLightOn, livingRoomLightOff);
remote.setCommand(1, kitchenLightOn, kitchenLightOff);
remote.setCommand(2, stereoOn, new NoCommand());

// Use remote
remote.onButtonPressed(0);  // Living room light on
remote.offButtonPressed(0); // Living room light off
remote.undoButtonPressed(); // Undo (living room light on)

// Macro command example
const partyModeOn = new MacroCommand([livingRoomLightOn, stereoOn]);
const partyModeOff = new MacroCommand([livingRoomLightOff, new NoCommand()]);
remote.setCommand(3, partyModeOn, partyModeOff);

remote.onButtonPressed(3); // Party mode on
remote.undoButtonPressed(); // Undo party mode
```

### 4. Template Method

**Intent**: Define the skeleton of an algorithm in a base class, letting subclasses override specific steps without changing the algorithm's structure.

```typescript
// Abstract class defining the template method
abstract class DataMiner {
  // Template method
  mineData(path: string): void {
    const file = this.openFile(path);
    const rawData = this.extractData(file);
    const data = this.parseData(rawData);
    const analysis = this.analyzeData(data);
    this.sendReport(analysis);
    this.closeFile(file);
  }
  
  // Concrete methods (same for all subclasses)
  protected openFile(path: string): any {
    console.log(`Opening file: ${path}`);
    return { path, handle: 'file_handle' };
  }
  
  protected closeFile(file: any): void {
    console.log(`Closing file: ${file.path}`);
  }
  
  protected sendReport(analysis: any): void {
    console.log('Sending report via email');
  }
  
  // Abstract methods (must be implemented by subclasses)
  protected abstract extractData(file: any): string;
  protected abstract parseData(rawData: string): any[];
  
  // Hook method (can be overridden but has default implementation)
  protected analyzeData(data: any[]): any {
    console.log('Performing basic analysis');
    return { summary: `Analyzed ${data.length} records` };
  }
}

// Concrete implementation for CSV files
class CSVDataMiner extends DataMiner {
  protected extractData(file: any): string {
    console.log('Extracting data from CSV file');
    return 'name,age\nJohn,25\nJane,30';
  }
  
  protected parseData(rawData: string): any[] {
    console.log('Parsing CSV data');
    const lines = rawData.split('\n');
    const headers = lines[0].split(',');
    return lines.slice(1).map(line => {
      const values = line.split(',');
      const obj: any = {};
      headers.forEach((header, index) => {
        obj[header] = values[index];
      });
      return obj;
    });
  }
  
  // Override hook method for CSV-specific analysis
  protected analyzeData(data: any[]): any {
    console.log('Performing CSV-specific analysis');
    const avgAge = data.reduce((sum, person) => sum + parseInt(person.age), 0) / data.length;
    return { summary: `Analyzed ${data.length} records`, averageAge: avgAge };
  }
}

// Concrete implementation for JSON files
class JSONDataMiner extends DataMiner {
  protected extractData(file: any): string {
    console.log('Extracting data from JSON file');
    return '[{"name": "Alice", "age": 28}, {"name": "Bob", "age": 35}]';
  }
  
  protected parseData(rawData: string): any[] {
    console.log('Parsing JSON data');
    return JSON.parse(rawData);
  }
}

// Usage
console.log('=== Processing CSV ===');
const csvMiner = new CSVDataMiner();
csvMiner.mineData('data.csv');

console.log('\n=== Processing JSON ===');
const jsonMiner = new JSONDataMiner();
jsonMiner.mineData('data.json');
```

## Pattern Selection Guidelines

### When to Use Each Pattern

**Creational Patterns:**
- **Singleton**: When you need exactly one instance (logging, caching, configuration)
- **Factory Method**: When you need to create objects but don't know the exact types
- **Abstract Factory**: When you need to create families of related objects
- **Builder**: When constructing complex objects with many optional parameters
- **Prototype**: When creating objects is expensive and you need many similar instances

**Structural Patterns:**
- **Adapter**: When you need to use an existing class with incompatible interface
- **Decorator**: When you want to add responsibilities to objects dynamically
- **Facade**: When you want to provide a simple interface to a complex system
- **Composite**: When you need to represent part-whole hierarchies

**Behavioral Patterns:**
- **Observer**: When changes to one object require updating multiple dependent objects
- **Strategy**: When you have multiple ways to perform a task and want to choose at runtime
- **Command**: When you want to parameterize objects with operations, queue operations, or support undo
- **Template Method**: When you have an algorithm with varying steps but the same overall structure

## Best Practices

1. **Don't Force Patterns**: Use patterns to solve actual problems, not just to use patterns
2. **Understand Intent**: Know why a pattern exists before using it
3. **Consider Alternatives**: Modern languages offer features that might eliminate the need for some patterns
4. **Keep It Simple**: Don't over-engineer solutions with unnecessary patterns
5. **Combine Patterns**: Many real-world solutions combine multiple patterns
6. **Document Pattern Usage**: Make it clear when and why you're using a pattern
7. **Consider Performance**: Some patterns add overhead; ensure it's justified
8. **Test Pattern Implementations**: Patterns can introduce complexity; test thoroughly

## Modern Considerations

Some GoF patterns are less relevant in modern programming due to language evolution:

- **Singleton**: Often replaced by dependency injection containers
- **Visitor**: Less needed with modern languages that support pattern matching
- **Iterator**: Built into most modern languages
- **Factory**: Often replaced by more advanced IoC containers

However, the core concepts and problem-solving approaches from GoF patterns remain valuable for designing maintainable, flexible software systems.