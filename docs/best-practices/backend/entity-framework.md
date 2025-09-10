# Entity Framework Core Best Practices

## Official Documentation
- **Entity Framework Core**: https://docs.microsoft.com/en-us/ef/core/
- **EF Core GitHub**: https://github.com/dotnet/efcore
- **Migration Guide**: https://docs.microsoft.com/en-us/ef/core/managing-schemas/migrations/
- **Performance Guide**: https://docs.microsoft.com/en-us/ef/core/performance/

## Project Structure
```
src/
├── Domain/
│   ├── Entities/
│   ├── ValueObjects/
│   └── Aggregates/
├── Infrastructure/
│   ├── Data/
│   │   ├── ApplicationDbContext.cs
│   │   ├── Configurations/
│   │   ├── Migrations/
│   │   └── Repositories/
│   └── Services/
├── Application/
│   ├── Interfaces/
│   └── Services/
└── API/
    └── Controllers/
```

## Core Best Practices

### 1. DbContext Configuration
```csharp
// ApplicationDbContext.cs
public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options) { }

    public DbSet<Product> Products => Set<Product>();
    public DbSet<Order> Orders => Set<Order>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Apply all configurations from assembly
        modelBuilder.ApplyConfigurationsFromAssembly(
            Assembly.GetExecutingAssembly()
        );

        // Global query filters
        modelBuilder.Entity<Product>()
            .HasQueryFilter(p => !p.IsDeleted);

        // Value conversions
        modelBuilder.Entity<Order>()
            .Property(o => o.Status)
            .HasConversion<string>();

        base.OnModelCreating(modelBuilder);
    }

    // Audit trail
    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        foreach (var entry in ChangeTracker.Entries<IAuditable>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.CreatedAt = DateTime.UtcNow;
                    break;
                case EntityState.Modified:
                    entry.Entity.UpdatedAt = DateTime.UtcNow;
                    break;
            }
        }

        return base.SaveChangesAsync(cancellationToken);
    }
}
```

### 2. Entity Configuration
```csharp
// Configurations/ProductConfiguration.cs
public class ProductConfiguration : IEntityTypeConfiguration<Product>
{
    public void Configure(EntityTypeBuilder<Product> builder)
    {
        builder.ToTable("Products");

        builder.HasKey(p => p.Id);

        builder.Property(p => p.Name)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(p => p.Price)
            .HasPrecision(18, 2)
            .IsRequired();

        // Index configuration
        builder.HasIndex(p => p.Sku)
            .IsUnique();

        builder.HasIndex(p => new { p.CategoryId, p.IsActive })
            .HasDatabaseName("IX_Products_Category_Active");

        // Relationships
        builder.HasOne(p => p.Category)
            .WithMany(c => c.Products)
            .HasForeignKey(p => p.CategoryId)
            .OnDelete(DeleteBehavior.Restrict);

        // Owned types
        builder.OwnsOne(p => p.Dimensions, d =>
        {
            d.Property(x => x.Length).HasColumnName("Length");
            d.Property(x => x.Width).HasColumnName("Width");
            d.Property(x => x.Height).HasColumnName("Height");
        });

        // Seed data
        builder.HasData(
            new Product { Id = 1, Name = "Sample Product", Price = 9.99m }
        );
    }
}
```

### 3. Repository Pattern
```csharp
// Interfaces/IRepository.cs
public interface IRepository<T> where T : class
{
    IQueryable<T> Query();
    Task<T?> GetByIdAsync(int id);
    Task<List<T>> GetAllAsync();
    Task AddAsync(T entity);
    Task AddRangeAsync(IEnumerable<T> entities);
    void Update(T entity);
    void Remove(T entity);
    Task<int> SaveChangesAsync();
}

// Repositories/Repository.cs
public class Repository<T> : IRepository<T> where T : class
{
    protected readonly ApplicationDbContext _context;
    protected readonly DbSet<T> _dbSet;

    public Repository(ApplicationDbContext context)
    {
        _context = context;
        _dbSet = context.Set<T>();
    }

    public IQueryable<T> Query() => _dbSet.AsQueryable();

    public async Task<T?> GetByIdAsync(int id)
    {
        return await _dbSet.FindAsync(id);
    }

    public async Task<List<T>> GetAllAsync()
    {
        return await _dbSet.ToListAsync();
    }

    public async Task AddAsync(T entity)
    {
        await _dbSet.AddAsync(entity);
    }

    public async Task AddRangeAsync(IEnumerable<T> entities)
    {
        await _dbSet.AddRangeAsync(entities);
    }

    public void Update(T entity)
    {
        _dbSet.Update(entity);
    }

    public void Remove(T entity)
    {
        _dbSet.Remove(entity);
    }

    public async Task<int> SaveChangesAsync()
    {
        return await _context.SaveChangesAsync();
    }
}

// Repositories/ProductRepository.cs
public class ProductRepository : Repository<Product>, IProductRepository
{
    public ProductRepository(ApplicationDbContext context) : base(context) { }

    public async Task<IEnumerable<Product>> GetActiveProductsAsync()
    {
        return await _dbSet
            .Include(p => p.Category)
            .Where(p => p.IsActive)
            .OrderBy(p => p.Name)
            .ToListAsync();
    }

    public async Task<Product?> GetProductWithDetailsAsync(int id)
    {
        return await _dbSet
            .Include(p => p.Category)
            .Include(p => p.Reviews)
            .AsSplitQuery()
            .FirstOrDefaultAsync(p => p.Id == id);
    }
}
```

### 4. Unit of Work Pattern
```csharp
// Interfaces/IUnitOfWork.cs
public interface IUnitOfWork : IDisposable
{
    IProductRepository Products { get; }
    IOrderRepository Orders { get; }
    ICategoryRepository Categories { get; }
    
    Task<int> SaveChangesAsync();
    Task BeginTransactionAsync();
    Task CommitTransactionAsync();
    Task RollbackTransactionAsync();
}

// UnitOfWork.cs
public class UnitOfWork : IUnitOfWork
{
    private readonly ApplicationDbContext _context;
    private IDbContextTransaction? _transaction;

    public UnitOfWork(ApplicationDbContext context)
    {
        _context = context;
        Products = new ProductRepository(_context);
        Orders = new OrderRepository(_context);
        Categories = new CategoryRepository(_context);
    }

    public IProductRepository Products { get; }
    public IOrderRepository Orders { get; }
    public ICategoryRepository Categories { get; }

    public async Task<int> SaveChangesAsync()
    {
        return await _context.SaveChangesAsync();
    }

    public async Task BeginTransactionAsync()
    {
        _transaction = await _context.Database.BeginTransactionAsync();
    }

    public async Task CommitTransactionAsync()
    {
        if (_transaction != null)
        {
            await _transaction.CommitAsync();
            await _transaction.DisposeAsync();
            _transaction = null;
        }
    }

    public async Task RollbackTransactionAsync()
    {
        if (_transaction != null)
        {
            await _transaction.RollbackAsync();
            await _transaction.DisposeAsync();
            _transaction = null;
        }
    }

    public void Dispose()
    {
        _transaction?.Dispose();
        _context.Dispose();
    }
}
```

### 5. Query Optimization
```csharp
public class ProductService
{
    private readonly ApplicationDbContext _context;

    public ProductService(ApplicationDbContext context)
    {
        _context = context;
    }

    // Projection to reduce data transfer
    public async Task<List<ProductDto>> GetProductListAsync()
    {
        return await _context.Products
            .Where(p => p.IsActive)
            .Select(p => new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                Price = p.Price,
                CategoryName = p.Category.Name
            })
            .ToListAsync();
    }

    // Split queries for multiple includes
    public async Task<Order?> GetOrderWithDetailsAsync(int orderId)
    {
        return await _context.Orders
            .Include(o => o.Customer)
            .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
            .AsSplitQuery()
            .FirstOrDefaultAsync(o => o.Id == orderId);
    }

    // No tracking for read-only queries
    public async Task<List<Product>> GetProductsForDisplayAsync()
    {
        return await _context.Products
            .AsNoTracking()
            .Where(p => p.IsActive)
            .ToListAsync();
    }

    // Compiled queries for performance
    private static readonly Func<ApplicationDbContext, int, Task<Product?>> 
        GetProductByIdCompiled = EF.CompileAsyncQuery(
            (ApplicationDbContext context, int id) =>
                context.Products.FirstOrDefault(p => p.Id == id)
        );

    public Task<Product?> GetProductByIdAsync(int id)
    {
        return GetProductByIdCompiled(_context, id);
    }

    // Batch operations
    public async Task UpdatePricesAsync(Dictionary<int, decimal> priceUpdates)
    {
        var productIds = priceUpdates.Keys.ToList();
        var products = await _context.Products
            .Where(p => productIds.Contains(p.Id))
            .ToListAsync();

        foreach (var product in products)
        {
            if (priceUpdates.TryGetValue(product.Id, out var newPrice))
            {
                product.Price = newPrice;
            }
        }

        await _context.SaveChangesAsync();
    }
}
```

### 6. Migrations
```csharp
// Add migration
// dotnet ef migrations add InitialCreate

// Update database
// dotnet ef database update

// Generate SQL script
// dotnet ef migrations script

// Custom migration
public partial class AddProductIndex : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateIndex(
            name: "IX_Products_CreatedAt",
            table: "Products",
            column: "CreatedAt")
            .Annotation("SqlServer:Include", new[] { "Name", "Price" });

        // Raw SQL for complex operations
        migrationBuilder.Sql(@"
            CREATE PROCEDURE GetTopProducts
                @Count INT
            AS
            BEGIN
                SELECT TOP(@Count) * FROM Products
                WHERE IsActive = 1
                ORDER BY Sales DESC
            END
        ");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropIndex(
            name: "IX_Products_CreatedAt",
            table: "Products");

        migrationBuilder.Sql("DROP PROCEDURE GetTopProducts");
    }
}
```

### 7. Dependency Injection Setup
```csharp
// Program.cs (.NET 6+)
var builder = WebApplication.CreateBuilder(args);

// Add DbContext
builder.Services.AddDbContext<ApplicationDbContext>(options =>
{
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        sqlOptions =>
        {
            sqlOptions.EnableRetryOnFailure(
                maxRetryCount: 5,
                maxRetryDelay: TimeSpan.FromSeconds(30),
                errorNumbersToAdd: null);
            
            sqlOptions.CommandTimeout(30);
        });

    // Development options
    if (builder.Environment.IsDevelopment())
    {
        options.EnableSensitiveDataLogging();
        options.EnableDetailedErrors();
    }
});

// Add repositories and UoW
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();
builder.Services.AddScoped(typeof(IRepository<>), typeof(Repository<>));

// Add health checks
builder.Services.AddHealthChecks()
    .AddDbContextCheck<ApplicationDbContext>();

var app = builder.Build();

// Auto-migrate in development
if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    await context.Database.MigrateAsync();
}
```

## Common Patterns

### Global Query Filters
```csharp
// Soft delete implementation
modelBuilder.Entity<Product>()
    .HasQueryFilter(p => !p.IsDeleted);

// Multi-tenancy
modelBuilder.Entity<Order>()
    .HasQueryFilter(o => o.TenantId == _currentTenantId);

// Temporarily ignore filters
var allProducts = await _context.Products
    .IgnoreQueryFilters()
    .ToListAsync();
```

### Value Objects
```csharp
// Value object
public class Money : IEquatable<Money>
{
    public decimal Amount { get; }
    public string Currency { get; }

    public Money(decimal amount, string currency)
    {
        Amount = amount;
        Currency = currency;
    }

    public bool Equals(Money? other)
    {
        return other != null && 
               Amount == other.Amount && 
               Currency == other.Currency;
    }
}

// Configuration
builder.OwnsOne(o => o.TotalAmount, m =>
{
    m.Property(x => x.Amount).HasColumnName("TotalAmount");
    m.Property(x => x.Currency).HasColumnName("Currency");
});
```

### Concurrency Control
```csharp
// Optimistic concurrency with row version
public class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    
    [Timestamp]
    public byte[] RowVersion { get; set; }
}

// Handling concurrency conflicts
try
{
    await _context.SaveChangesAsync();
}
catch (DbUpdateConcurrencyException ex)
{
    foreach (var entry in ex.Entries)
    {
        var databaseValues = await entry.GetDatabaseValuesAsync();
        if (databaseValues == null)
        {
            // Entity was deleted
        }
        else
        {
            // Resolve conflict
            entry.OriginalValues.SetValues(databaseValues);
        }
    }
}
```

## Performance Optimization

### 1. Query Optimization
- Use projections to select only needed columns
- Apply filters early in the query chain
- Use `AsNoTracking()` for read-only scenarios
- Implement pagination with `Skip()` and `Take()`
- Use compiled queries for frequently executed queries

### 2. Loading Strategies
```csharp
// Eager loading
var orders = await _context.Orders
    .Include(o => o.Customer)
    .ToListAsync();

// Split queries for multiple includes
var products = await _context.Products
    .Include(p => p.Reviews)
    .Include(p => p.Images)
    .AsSplitQuery()
    .ToListAsync();

// Explicit loading
var order = await _context.Orders.FindAsync(orderId);
await _context.Entry(order)
    .Collection(o => o.OrderItems)
    .LoadAsync();

// Lazy loading (use cautiously)
services.AddDbContext<ApplicationDbContext>(options =>
    options.UseLazyLoadingProxies()
           .UseSqlServer(connectionString));
```

### 3. Bulk Operations
```csharp
// Use third-party libraries for bulk operations
// Install-Package EFCore.BulkExtensions

await _context.BulkInsertAsync(products);
await _context.BulkUpdateAsync(products);
await _context.BulkDeleteAsync(products);

// Or use raw SQL for performance
await _context.Database.ExecuteSqlRawAsync(
    "UPDATE Products SET Price = Price * 1.1 WHERE CategoryId = {0}",
    categoryId);
```

## Testing

### Unit Testing with InMemory Database
```csharp
[TestClass]
public class ProductRepositoryTests
{
    private ApplicationDbContext GetInMemoryContext()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        
        return new ApplicationDbContext(options);
    }

    [TestMethod]
    public async Task GetActiveProducts_ReturnsOnlyActiveProducts()
    {
        // Arrange
        using var context = GetInMemoryContext();
        var repository = new ProductRepository(context);
        
        await context.Products.AddRangeAsync(
            new Product { Name = "Active", IsActive = true },
            new Product { Name = "Inactive", IsActive = false }
        );
        await context.SaveChangesAsync();

        // Act
        var result = await repository.GetActiveProductsAsync();

        // Assert
        Assert.AreEqual(1, result.Count());
        Assert.IsTrue(result.All(p => p.IsActive));
    }
}
```

## Common Pitfalls to Avoid

1. **N+1 Query Problem**: Always use `Include()` for related data
2. **Over-fetching**: Use projections instead of loading entire entities
3. **Tracking Too Many Entities**: Use `AsNoTracking()` for read operations
4. **Not Using Async Methods**: Always prefer async methods for I/O operations
5. **Ignoring SQL Generated**: Monitor generated SQL in development
6. **Not Handling Concurrency**: Implement optimistic concurrency control
7. **Large Migrations**: Break complex schema changes into smaller migrations
8. **Not Indexing Foreign Keys**: Add indexes for foreign key columns
9. **Using Lazy Loading**: Can cause performance issues, use explicit/eager loading
10. **Not Disposing DbContext**: Use dependency injection or using statements

## Security Considerations

### SQL Injection Prevention
```csharp
// Safe - Parameterized query
var products = await _context.Products
    .FromSqlRaw("SELECT * FROM Products WHERE CategoryId = {0}", categoryId)
    .ToListAsync();

// Safe - LINQ
var products = await _context.Products
    .Where(p => p.CategoryId == categoryId)
    .ToListAsync();

// Unsafe - Never do this
var products = await _context.Products
    .FromSqlRaw($"SELECT * FROM Products WHERE CategoryId = {categoryId}")
    .ToListAsync();
```

## Useful NuGet Packages

- **EFCore.BulkExtensions**: Bulk operations
- **Z.EntityFramework.Plus.EFCore**: Query future, batch operations
- **EntityFrameworkCore.Triggers**: Database triggers in code
- **Audit.EntityFramework.Core**: Automatic audit trails
- **EFCore.NamingConventions**: Snake case naming
- **Microsoft.EntityFrameworkCore.Proxies**: Lazy loading support
- **EntityFramework.Exceptions**: Better exception messages
- **EFCore.CheckConstraints**: Check constraints support