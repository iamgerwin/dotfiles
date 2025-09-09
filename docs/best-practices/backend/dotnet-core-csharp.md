# .NET Core C# Best Practices

## Official Documentation
- **.NET Documentation**: https://docs.microsoft.com/dotnet
- **C# Programming Guide**: https://docs.microsoft.com/dotnet/csharp
- **ASP.NET Core Documentation**: https://docs.microsoft.com/aspnet/core
- **Entity Framework Core**: https://docs.microsoft.com/ef/core

## Project Structure

```
project-root/
├── src/
│   ├── MyApp.Api/
│   │   ├── Controllers/
│   │   ├── Filters/
│   │   ├── Middleware/
│   │   ├── Extensions/
│   │   ├── Program.cs
│   │   ├── appsettings.json
│   │   └── MyApp.Api.csproj
│   ├── MyApp.Application/
│   │   ├── Commands/
│   │   ├── Queries/
│   │   ├── Validators/
│   │   ├── Mappings/
│   │   ├── Services/
│   │   ├── Interfaces/
│   │   ├── DTOs/
│   │   └── MyApp.Application.csproj
│   ├── MyApp.Domain/
│   │   ├── Entities/
│   │   ├── ValueObjects/
│   │   ├── Enums/
│   │   ├── Events/
│   │   ├── Exceptions/
│   │   ├── Interfaces/
│   │   └── MyApp.Domain.csproj
│   ├── MyApp.Infrastructure/
│   │   ├── Data/
│   │   │   ├── Contexts/
│   │   │   ├── Configurations/
│   │   │   ├── Migrations/
│   │   │   └── Repositories/
│   │   ├── Services/
│   │   ├── Identity/
│   │   └── MyApp.Infrastructure.csproj
│   └── MyApp.Shared/
│       ├── Constants/
│       ├── Extensions/
│       ├── Helpers/
│       └── MyApp.Shared.csproj
├── tests/
│   ├── MyApp.UnitTests/
│   ├── MyApp.IntegrationTests/
│   └── MyApp.FunctionalTests/
├── docker-compose.yml
├── Dockerfile
├── .editorconfig
├── .gitignore
└── MyApp.sln
```

## Core Best Practices

### 1. Clean Architecture with CQRS

```csharp
// Domain Entity
namespace MyApp.Domain.Entities;

public class User : BaseEntity, IAggregateRoot
{
    public string Email { get; private set; }
    public string Username { get; private set; }
    public string PasswordHash { get; private set; }
    public UserRole Role { get; private set; }
    public bool IsActive { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? UpdatedAt { get; private set; }
    
    private readonly List<RefreshToken> _refreshTokens = new();
    public IReadOnlyCollection<RefreshToken> RefreshTokens => _refreshTokens.AsReadOnly();

    protected User() { } // For EF Core

    public User(string email, string username, string passwordHash, UserRole role = UserRole.User)
    {
        Email = Guard.Against.NullOrEmpty(email, nameof(email));
        Username = Guard.Against.NullOrEmpty(username, nameof(username));
        PasswordHash = Guard.Against.NullOrEmpty(passwordHash, nameof(passwordHash));
        Role = role;
        IsActive = true;
        CreatedAt = DateTime.UtcNow;
        
        ValidateEmail(email);
        ValidateUsername(username);
        
        AddDomainEvent(new UserCreatedEvent(this));
    }

    public void UpdateProfile(string username, string email)
    {
        Username = Guard.Against.NullOrEmpty(username, nameof(username));
        Email = Guard.Against.NullOrEmpty(email, nameof(email));
        
        ValidateEmail(email);
        ValidateUsername(username);
        
        UpdatedAt = DateTime.UtcNow;
        AddDomainEvent(new UserUpdatedEvent(this));
    }

    public void ChangePassword(string newPasswordHash)
    {
        PasswordHash = Guard.Against.NullOrEmpty(newPasswordHash, nameof(newPasswordHash));
        UpdatedAt = DateTime.UtcNow;
        
        RevokeAllRefreshTokens();
        AddDomainEvent(new UserPasswordChangedEvent(Id));
    }

    public void Deactivate()
    {
        IsActive = false;
        UpdatedAt = DateTime.UtcNow;
        RevokeAllRefreshTokens();
    }

    public RefreshToken GenerateRefreshToken(string ipAddress)
    {
        var refreshToken = new RefreshToken(ipAddress);
        _refreshTokens.Add(refreshToken);
        RemoveOldRefreshTokens();
        
        return refreshToken;
    }

    public void RevokeRefreshToken(string token, string ipAddress)
    {
        var refreshToken = _refreshTokens.SingleOrDefault(x => x.Token == token);
        
        if (refreshToken == null || !refreshToken.IsActive)
            throw new AppException("Invalid token");
            
        refreshToken.Revoke(ipAddress);
    }

    private void RevokeAllRefreshTokens()
    {
        foreach (var token in _refreshTokens.Where(x => x.IsActive))
        {
            token.Revoke("System");
        }
    }

    private void RemoveOldRefreshTokens()
    {
        _refreshTokens.RemoveAll(x => 
            !x.IsActive && 
            x.Created.AddDays(7) <= DateTime.UtcNow);
    }

    private static void ValidateEmail(string email)
    {
        if (!new EmailAddressAttribute().IsValid(email))
            throw new DomainException("Invalid email address");
    }

    private static void ValidateUsername(string username)
    {
        if (username.Length < 3 || username.Length > 30)
            throw new DomainException("Username must be between 3 and 30 characters");
    }
}

// Value Object
public class RefreshToken : ValueObject
{
    public string Token { get; private set; }
    public DateTime Expires { get; private set; }
    public DateTime Created { get; private set; }
    public string CreatedByIp { get; private set; }
    public DateTime? Revoked { get; private set; }
    public string? RevokedByIp { get; private set; }
    public string? ReplacedByToken { get; private set; }
    
    public bool IsExpired => DateTime.UtcNow >= Expires;
    public bool IsRevoked => Revoked != null;
    public bool IsActive => !IsRevoked && !IsExpired;

    public RefreshToken(string createdByIp)
    {
        Token = GenerateToken();
        Expires = DateTime.UtcNow.AddDays(7);
        Created = DateTime.UtcNow;
        CreatedByIp = createdByIp;
    }

    public void Revoke(string revokedByIp, string? replacedByToken = null)
    {
        Revoked = DateTime.UtcNow;
        RevokedByIp = revokedByIp;
        ReplacedByToken = replacedByToken;
    }

    private static string GenerateToken()
    {
        var randomBytes = new byte[64];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomBytes);
        return Convert.ToBase64String(randomBytes);
    }

    protected override IEnumerable<object> GetEqualityComponents()
    {
        yield return Token;
    }
}
```

### 2. CQRS with MediatR

```csharp
// Command
namespace MyApp.Application.Commands;

public record CreateUserCommand : IRequest<Result<UserDto>>
{
    public string Email { get; init; } = default!;
    public string Username { get; init; } = default!;
    public string Password { get; init; } = default!;
    public UserRole Role { get; init; } = UserRole.User;
}

// Command Handler
public class CreateUserCommandHandler : IRequestHandler<CreateUserCommand, Result<UserDto>>
{
    private readonly IUserRepository _userRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IMapper _mapper;
    private readonly ILogger<CreateUserCommandHandler> _logger;
    private readonly IPublisher _publisher;

    public CreateUserCommandHandler(
        IUserRepository userRepository,
        IPasswordHasher passwordHasher,
        IMapper mapper,
        ILogger<CreateUserCommandHandler> logger,
        IPublisher publisher)
    {
        _userRepository = userRepository;
        _passwordHasher = passwordHasher;
        _mapper = mapper;
        _logger = logger;
        _publisher = publisher;
    }

    public async Task<Result<UserDto>> Handle(CreateUserCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // Check if user already exists
            var existingUser = await _userRepository.GetByEmailAsync(request.Email, cancellationToken);
            if (existingUser != null)
                return Result<UserDto>.Failure("User with this email already exists");

            // Create user
            var passwordHash = _passwordHasher.Hash(request.Password);
            var user = new User(request.Email, request.Username, passwordHash, request.Role);

            // Save to database
            await _userRepository.AddAsync(user, cancellationToken);
            await _userRepository.SaveChangesAsync(cancellationToken);

            // Publish domain events
            foreach (var domainEvent in user.DomainEvents)
            {
                await _publisher.Publish(domainEvent, cancellationToken);
            }

            _logger.LogInformation("User created successfully with ID: {UserId}", user.Id);

            // Map to DTO and return
            var userDto = _mapper.Map<UserDto>(user);
            return Result<UserDto>.Success(userDto);
        }
        catch (DomainException ex)
        {
            _logger.LogWarning(ex, "Domain validation failed");
            return Result<UserDto>.Failure(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create user");
            return Result<UserDto>.Failure("An error occurred while creating the user");
        }
    }
}

// Query
public record GetUserByIdQuery(Guid Id) : IRequest<Result<UserDto>>;

// Query Handler
public class GetUserByIdQueryHandler : IRequestHandler<GetUserByIdQuery, Result<UserDto>>
{
    private readonly IUserRepository _userRepository;
    private readonly IMapper _mapper;
    private readonly IMemoryCache _cache;

    public GetUserByIdQueryHandler(
        IUserRepository userRepository,
        IMapper mapper,
        IMemoryCache cache)
    {
        _userRepository = userRepository;
        _mapper = mapper;
        _cache = cache;
    }

    public async Task<Result<UserDto>> Handle(GetUserByIdQuery request, CancellationToken cancellationToken)
    {
        var cacheKey = $"user_{request.Id}";
        
        if (_cache.TryGetValue<UserDto>(cacheKey, out var cachedUser))
            return Result<UserDto>.Success(cachedUser!);

        var user = await _userRepository.GetByIdAsync(request.Id, cancellationToken);
        
        if (user == null)
            return Result<UserDto>.Failure("User not found");

        var userDto = _mapper.Map<UserDto>(user);
        
        _cache.Set(cacheKey, userDto, TimeSpan.FromMinutes(5));
        
        return Result<UserDto>.Success(userDto);
    }
}

// Validator
public class CreateUserCommandValidator : AbstractValidator<CreateUserCommand>
{
    public CreateUserCommandValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required")
            .EmailAddress().WithMessage("Invalid email format");

        RuleFor(x => x.Username)
            .NotEmpty().WithMessage("Username is required")
            .Length(3, 30).WithMessage("Username must be between 3 and 30 characters")
            .Matches("^[a-zA-Z0-9_-]+$").WithMessage("Username can only contain letters, numbers, hyphens, and underscores");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required")
            .MinimumLength(8).WithMessage("Password must be at least 8 characters")
            .Matches("[A-Z]").WithMessage("Password must contain at least one uppercase letter")
            .Matches("[a-z]").WithMessage("Password must contain at least one lowercase letter")
            .Matches("[0-9]").WithMessage("Password must contain at least one number")
            .Matches("[^a-zA-Z0-9]").WithMessage("Password must contain at least one special character");

        RuleFor(x => x.Role)
            .IsInEnum().WithMessage("Invalid role");
    }
}
```

### 3. API Controllers

```csharp
namespace MyApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class UsersController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ILogger<UsersController> _logger;

    public UsersController(IMediator mediator, ILogger<UsersController> logger)
    {
        _mediator = mediator;
        _logger = logger;
    }

    /// <summary>
    /// Get user by ID
    /// </summary>
    /// <param name="id">User ID</param>
    /// <returns>User details</returns>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<UserDto>> GetById(Guid id)
    {
        var result = await _mediator.Send(new GetUserByIdQuery(id));
        
        return result.IsSuccess 
            ? Ok(result.Value) 
            : NotFound(new ProblemDetails { Title = result.Error });
    }

    /// <summary>
    /// Create a new user
    /// </summary>
    /// <param name="command">User creation details</param>
    /// <returns>Created user</returns>
    [HttpPost]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<UserDto>> Create([FromBody] CreateUserCommand command)
    {
        var result = await _mediator.Send(command);
        
        if (!result.IsSuccess)
            return BadRequest(new ProblemDetails { Title = result.Error });

        return CreatedAtAction(
            nameof(GetById),
            new { id = result.Value!.Id },
            result.Value);
    }

    /// <summary>
    /// Update user profile
    /// </summary>
    /// <param name="id">User ID</param>
    /// <param name="command">Update details</param>
    /// <returns>Updated user</returns>
    [HttpPut("{id:guid}")]
    [Authorize]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<UserDto>> Update(Guid id, [FromBody] UpdateUserCommand command)
    {
        if (id != command.Id)
            return BadRequest(new ProblemDetails { Title = "ID mismatch" });

        var currentUserId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (currentUserId != id.ToString() && !User.IsInRole("Admin"))
            return Forbid();

        var result = await _mediator.Send(command);
        
        return result.IsSuccess 
            ? Ok(result.Value) 
            : NotFound(new ProblemDetails { Title = result.Error });
    }

    /// <summary>
    /// Delete a user
    /// </summary>
    /// <param name="id">User ID</param>
    /// <returns>No content</returns>
    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid id)
    {
        var result = await _mediator.Send(new DeleteUserCommand(id));
        
        return result.IsSuccess 
            ? NoContent() 
            : NotFound(new ProblemDetails { Title = result.Error });
    }

    /// <summary>
    /// Get paginated list of users
    /// </summary>
    /// <param name="query">Pagination parameters</param>
    /// <returns>Paginated user list</returns>
    [HttpGet]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(typeof(PaginatedList<UserDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PaginatedList<UserDto>>> GetAll([FromQuery] GetUsersQuery query)
    {
        var result = await _mediator.Send(query);
        return Ok(result);
    }
}
```

### 4. Repository Pattern with EF Core

```csharp
// Generic Repository Interface
public interface IRepository<T> where T : BaseEntity, IAggregateRoot
{
    Task<T?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<T>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<T>> GetAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default);
    Task<T> AddAsync(T entity, CancellationToken cancellationToken = default);
    Task UpdateAsync(T entity, CancellationToken cancellationToken = default);
    Task DeleteAsync(T entity, CancellationToken cancellationToken = default);
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}

// Generic Repository Implementation
public class Repository<T> : IRepository<T> where T : BaseEntity, IAggregateRoot
{
    protected readonly ApplicationDbContext _context;
    protected readonly DbSet<T> _dbSet;

    public Repository(ApplicationDbContext context)
    {
        _context = context;
        _dbSet = context.Set<T>();
    }

    public virtual async Task<T?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _dbSet.FindAsync(new object[] { id }, cancellationToken);
    }

    public virtual async Task<IReadOnlyList<T>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return await _dbSet.ToListAsync(cancellationToken);
    }

    public virtual async Task<IReadOnlyList<T>> GetAsync(
        Expression<Func<T, bool>> predicate, 
        CancellationToken cancellationToken = default)
    {
        return await _dbSet.Where(predicate).ToListAsync(cancellationToken);
    }

    public virtual async Task<T> AddAsync(T entity, CancellationToken cancellationToken = default)
    {
        await _dbSet.AddAsync(entity, cancellationToken);
        return entity;
    }

    public virtual Task UpdateAsync(T entity, CancellationToken cancellationToken = default)
    {
        _context.Entry(entity).State = EntityState.Modified;
        return Task.CompletedTask;
    }

    public virtual Task DeleteAsync(T entity, CancellationToken cancellationToken = default)
    {
        _dbSet.Remove(entity);
        return Task.CompletedTask;
    }

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await _context.SaveChangesAsync(cancellationToken);
    }
}

// Specific Repository
public interface IUserRepository : IRepository<User>
{
    Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default);
    Task<User?> GetByUsernameAsync(string username, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<User>> GetActiveUsersAsync(CancellationToken cancellationToken = default);
    Task<PaginatedList<User>> GetPaginatedAsync(int pageNumber, int pageSize, CancellationToken cancellationToken = default);
}

public class UserRepository : Repository<User>, IUserRepository
{
    public UserRepository(ApplicationDbContext context) : base(context) { }

    public async Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(u => u.RefreshTokens)
            .FirstOrDefaultAsync(u => u.Email == email, cancellationToken);
    }

    public async Task<User?> GetByUsernameAsync(string username, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .FirstOrDefaultAsync(u => u.Username == username, cancellationToken);
    }

    public async Task<IReadOnlyList<User>> GetActiveUsersAsync(CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Where(u => u.IsActive)
            .OrderBy(u => u.Username)
            .ToListAsync(cancellationToken);
    }

    public async Task<PaginatedList<User>> GetPaginatedAsync(
        int pageNumber, 
        int pageSize, 
        CancellationToken cancellationToken = default)
    {
        var query = _dbSet.Where(u => u.IsActive);
        
        var count = await query.CountAsync(cancellationToken);
        
        var items = await query
            .OrderBy(u => u.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return new PaginatedList<User>(items, count, pageNumber, pageSize);
    }

    public override async Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(u => u.RefreshTokens)
            .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);
    }
}
```

### 5. Entity Framework Configuration

```csharp
// DbContext
public class ApplicationDbContext : DbContext
{
    private readonly IMediator _mediator;
    private readonly ICurrentUserService _currentUserService;

    public ApplicationDbContext(
        DbContextOptions<ApplicationDbContext> options,
        IMediator mediator,
        ICurrentUserService currentUserService) : base(options)
    {
        _mediator = mediator;
        _currentUserService = currentUserService;
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<Order> Orders => Set<Order>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
        
        // Global query filters
        modelBuilder.Entity<User>().HasQueryFilter(u => !u.IsDeleted);
        
        base.OnModelCreating(modelBuilder);
    }

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        // Handle auditing
        foreach (var entry in ChangeTracker.Entries<AuditableEntity>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.CreatedBy = _currentUserService.UserId;
                    entry.Entity.CreatedAt = DateTime.UtcNow;
                    break;
                case EntityState.Modified:
                    entry.Entity.LastModifiedBy = _currentUserService.UserId;
                    entry.Entity.LastModifiedAt = DateTime.UtcNow;
                    break;
            }
        }

        // Save and publish domain events
        var entities = ChangeTracker.Entries<BaseEntity>()
            .Where(e => e.Entity.DomainEvents.Any())
            .Select(e => e.Entity);

        var domainEvents = entities
            .SelectMany(e => e.DomainEvents)
            .ToList();

        var result = await base.SaveChangesAsync(cancellationToken);

        await DispatchEvents(domainEvents, cancellationToken);

        return result;
    }

    private async Task DispatchEvents(List<DomainEvent> domainEvents, CancellationToken cancellationToken)
    {
        foreach (var domainEvent in domainEvents)
        {
            await _mediator.Publish(domainEvent, cancellationToken);
        }
    }
}

// Entity Configuration
public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("Users");

        builder.HasKey(u => u.Id);

        builder.Property(u => u.Email)
            .IsRequired()
            .HasMaxLength(256);

        builder.Property(u => u.Username)
            .IsRequired()
            .HasMaxLength(30);

        builder.Property(u => u.PasswordHash)
            .IsRequired();

        builder.Property(u => u.Role)
            .IsRequired()
            .HasConversion<string>();

        builder.HasIndex(u => u.Email)
            .IsUnique();

        builder.HasIndex(u => u.Username)
            .IsUnique();

        // Owned entity
        builder.OwnsMany(u => u.RefreshTokens, rt =>
        {
            rt.ToTable("RefreshTokens");
            rt.HasKey("UserId", "Token");
            rt.Property(r => r.Token).HasMaxLength(256);
        });

        // Ignore domain events
        builder.Ignore(u => u.DomainEvents);
    }
}
```

### 6. Middleware and Filters

```csharp
// Exception Middleware
public class ExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionMiddleware> _logger;
    private readonly IWebHostEnvironment _env;

    public ExceptionMiddleware(
        RequestDelegate next,
        ILogger<ExceptionMiddleware> logger,
        IWebHostEnvironment env)
    {
        _next = next;
        _logger = logger;
        _env = env;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An unhandled exception occurred");
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";
        
        var response = new ApiErrorResponse();

        switch (exception)
        {
            case ValidationException validationException:
                response.StatusCode = StatusCodes.Status400BadRequest;
                response.Message = "Validation failed";
                response.Errors = validationException.Errors.Select(e => new ApiError
                {
                    Field = e.PropertyName,
                    Message = e.ErrorMessage
                }).ToList();
                break;
                
            case NotFoundException:
                response.StatusCode = StatusCodes.Status404NotFound;
                response.Message = exception.Message;
                break;
                
            case UnauthorizedException:
                response.StatusCode = StatusCodes.Status401Unauthorized;
                response.Message = "Unauthorized";
                break;
                
            case ForbiddenException:
                response.StatusCode = StatusCodes.Status403Forbidden;
                response.Message = "Forbidden";
                break;
                
            default:
                response.StatusCode = StatusCodes.Status500InternalServerError;
                response.Message = "An error occurred while processing your request";
                
                if (_env.IsDevelopment())
                {
                    response.Details = exception.ToString();
                }
                break;
        }

        context.Response.StatusCode = response.StatusCode;
        
        var jsonResponse = JsonSerializer.Serialize(response, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });
        
        await context.Response.WriteAsync(jsonResponse);
    }
}

// Validation Filter
public class ValidationFilter : IAsyncActionFilter
{
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        if (!context.ModelState.IsValid)
        {
            var errors = context.ModelState
                .Where(x => x.Value?.Errors.Count > 0)
                .ToDictionary(
                    kvp => kvp.Key,
                    kvp => kvp.Value!.Errors.Select(e => e.ErrorMessage).ToArray()
                );

            var response = new ApiErrorResponse
            {
                StatusCode = StatusCodes.Status400BadRequest,
                Message = "Validation failed",
                Errors = errors.SelectMany(e => e.Value.Select(v => new ApiError
                {
                    Field = e.Key,
                    Message = v
                })).ToList()
            };

            context.Result = new BadRequestObjectResult(response);
            return;
        }

        await next();
    }
}
```

### 7. Testing

```csharp
// Unit Test
[TestClass]
public class UserServiceTests
{
    private Mock<IUserRepository> _userRepositoryMock;
    private Mock<IPasswordHasher> _passwordHasherMock;
    private Mock<IMapper> _mapperMock;
    private Mock<ILogger<CreateUserCommandHandler>> _loggerMock;
    private CreateUserCommandHandler _handler;

    [TestInitialize]
    public void Setup()
    {
        _userRepositoryMock = new Mock<IUserRepository>();
        _passwordHasherMock = new Mock<IPasswordHasher>();
        _mapperMock = new Mock<IMapper>();
        _loggerMock = new Mock<ILogger<CreateUserCommandHandler>>();
        
        _handler = new CreateUserCommandHandler(
            _userRepositoryMock.Object,
            _passwordHasherMock.Object,
            _mapperMock.Object,
            _loggerMock.Object,
            Mock.Of<IPublisher>());
    }

    [TestMethod]
    public async Task CreateUser_WithValidData_ReturnsSuccess()
    {
        // Arrange
        var command = new CreateUserCommand
        {
            Email = "test@example.com",
            Username = "testuser",
            Password = "Test@123",
            Role = UserRole.User
        };

        _userRepositoryMock
            .Setup(x => x.GetByEmailAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((User?)null);

        _passwordHasherMock
            .Setup(x => x.Hash(It.IsAny<string>()))
            .Returns("hashedPassword");

        _mapperMock
            .Setup(x => x.Map<UserDto>(It.IsAny<User>()))
            .Returns(new UserDto { Id = Guid.NewGuid(), Email = command.Email });

        // Act
        var result = await _handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.IsTrue(result.IsSuccess);
        Assert.IsNotNull(result.Value);
        Assert.AreEqual(command.Email, result.Value.Email);
        
        _userRepositoryMock.Verify(x => x.AddAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()), Times.Once);
        _userRepositoryMock.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [TestMethod]
    public async Task CreateUser_WithExistingEmail_ReturnsFailure()
    {
        // Arrange
        var command = new CreateUserCommand
        {
            Email = "existing@example.com",
            Username = "testuser",
            Password = "Test@123"
        };

        _userRepositoryMock
            .Setup(x => x.GetByEmailAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User("existing@example.com", "existing", "hash"));

        // Act
        var result = await _handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.IsFalse(result.IsSuccess);
        Assert.AreEqual("User with this email already exists", result.Error);
        
        _userRepositoryMock.Verify(x => x.AddAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()), Times.Never);
    }
}

// Integration Test
[TestClass]
public class UserControllerIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;

    public UserControllerIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = _factory.CreateClient();
    }

    [TestMethod]
    public async Task CreateUser_ReturnsCreatedResult()
    {
        // Arrange
        var command = new CreateUserCommand
        {
            Email = "integration@test.com",
            Username = "integrationtest",
            Password = "Test@123"
        };

        var content = new StringContent(
            JsonSerializer.Serialize(command),
            Encoding.UTF8,
            "application/json");

        // Act
        var response = await _client.PostAsync("/api/users", content);

        // Assert
        response.EnsureSuccessStatusCode();
        Assert.AreEqual(HttpStatusCode.Created, response.StatusCode);
        
        var responseString = await response.Content.ReadAsStringAsync();
        var user = JsonSerializer.Deserialize<UserDto>(responseString);
        
        Assert.IsNotNull(user);
        Assert.AreEqual(command.Email, user.Email);
    }
}
```

### Common Pitfalls to Avoid

1. **Not using async/await properly**
2. **Ignoring dependency injection**
3. **Creating fat controllers**
4. **Not handling exceptions globally**
5. **Using Entity Framework incorrectly**
6. **Not implementing proper logging**
7. **Ignoring SOLID principles**
8. **Not using cancellation tokens**
9. **Creating memory leaks**
10. **Not writing testable code**

### Useful NuGet Packages

- **MediatR**: CQRS implementation
- **FluentValidation**: Validation framework
- **AutoMapper**: Object mapping
- **Serilog**: Structured logging
- **Polly**: Resilience and transient fault handling
- **FluentAssertions**: Testing assertions
- **Moq**: Mocking framework
- **Swashbuckle**: Swagger/OpenAPI
- **IdentityServer4**: Authentication/Authorization
- **Dapper**: Micro ORM
- **Hangfire**: Background jobs
- **MassTransit**: Message bus