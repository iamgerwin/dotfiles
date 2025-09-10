# FastEndpoints Best Practices

## Overview
FastEndpoints is a high-performance REST API framework for .NET that emphasizes developer productivity and runtime efficiency. These best practices ensure optimal API design, performance, and maintainability.

## Project Structure

### Organized Feature Folders
```
src/
├── Features/
│   ├── Auth/
│   │   ├── Login/
│   │   │   ├── Endpoint.cs
│   │   │   ├── Request.cs
│   │   │   ├── Response.cs
│   │   │   ├── Validator.cs
│   │   │   └── Mapper.cs
│   │   └── Register/
│   ├── Products/
│   │   ├── Create/
│   │   ├── Update/
│   │   ├── Delete/
│   │   └── List/
│   └── Orders/
├── Domain/
├── Infrastructure/
└── Common/
```

### Endpoint Organization
```csharp
// Features/Products/Create/Endpoint.cs
public class CreateProductEndpoint : Endpoint<CreateProductRequest, CreateProductResponse>
{
    private readonly IProductService _productService;
    
    public CreateProductEndpoint(IProductService productService)
    {
        _productService = productService;
    }
    
    public override void Configure()
    {
        Post("/api/products");
        Roles("Admin", "Manager");
        Description(b => b
            .Produces<CreateProductResponse>(201, "Product created successfully")
            .ProducesProblemFE(400)
            .ProducesProblemFE(401));
        
        Summary(s =>
        {
            s.Summary = "Create a new product";
            s.Description = "Creates a new product in the catalog";
            s.ExampleRequest = new CreateProductRequest
            {
                Name = "Sample Product",
                Price = 29.99m,
                Category = "Electronics"
            };
        });
    }
    
    public override async Task HandleAsync(CreateProductRequest req, CancellationToken ct)
    {
        var product = await _productService.CreateAsync(req, ct);
        
        await SendCreatedAtAsync<GetProductEndpoint>(
            new { id = product.Id }, 
            product, 
            cancellation: ct);
    }
}
```

## Request/Response Design

### Request DTOs
```csharp
// Features/Products/Create/Request.cs
public class CreateProductRequest
{
    public string Name { get; set; } = default!;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public string Category { get; set; } = default!;
    public List<string> Tags { get; set; } = new();
    
    // Route parameters
    [FromRoute] public int StoreId { get; set; }
    
    // Query parameters  
    [FromQuery] public bool? SendNotification { get; set; }
    
    // Headers
    [FromHeader("X-Tenant-Id")] public string? TenantId { get; set; }
}
```

### Response DTOs
```csharp
// Features/Products/Create/Response.cs
public class CreateProductResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = default!;
    public decimal Price { get; set; }
    public DateTime CreatedAt { get; set; }
    public string ResourceUrl { get; set; } = default!;
}

// Generic response wrapper
public class ApiResponse<T>
{
    public T Data { get; set; } = default!;
    public ApiMetadata Meta { get; set; } = new();
    public List<ApiLink> Links { get; set; } = new();
}
```

## Validation

### Fluent Validation
```csharp
// Features/Products/Create/Validator.cs
public class CreateProductValidator : Validator<CreateProductRequest>
{
    public CreateProductValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Product name is required")
            .MinimumLength(3).WithMessage("Name must be at least 3 characters")
            .MaximumLength(100).WithMessage("Name cannot exceed 100 characters");
            
        RuleFor(x => x.Price)
            .GreaterThan(0).WithMessage("Price must be greater than zero")
            .ScalePrecision(2, 10).WithMessage("Invalid price format");
            
        RuleFor(x => x.Category)
            .NotEmpty()
            .MustAsync(CategoryExists).WithMessage("Category does not exist");
            
        RuleFor(x => x.Tags)
            .Must(tags => tags.Count <= 10).WithMessage("Maximum 10 tags allowed")
            .ForEach(tag => tag.MaximumLength(20));
            
        When(x => x.SendNotification == true, () =>
        {
            RuleFor(x => x.TenantId)
                .NotEmpty().WithMessage("Tenant ID required for notifications");
        });
    }
    
    private async Task<bool> CategoryExists(string category, CancellationToken ct)
    {
        var service = Resolve<ICategoryService>();
        return await service.ExistsAsync(category, ct);
    }
}
```

### Complex Validation
```csharp
public class OrderValidator : Validator<CreateOrderRequest>
{
    public OrderValidator()
    {
        RuleFor(x => x.Items)
            .NotEmpty().WithMessage("Order must contain at least one item")
            .MustAsync(ValidateInventory).WithMessage("Insufficient inventory");
            
        RuleFor(x => x.ShippingAddress)
            .SetValidator(new AddressValidator());
            
        RuleFor(x => x.PaymentMethod)
            .IsInEnum().WithMessage("Invalid payment method");
            
        RuleFor(x => x)
            .MustAsync(ValidateTotalAmount)
            .WithMessage("Order total mismatch");
    }
    
    private async Task<bool> ValidateInventory(List<OrderItem> items, CancellationToken ct)
    {
        var inventoryService = Resolve<IInventoryService>();
        return await inventoryService.CheckAvailabilityAsync(items, ct);
    }
}
```

## Authentication & Authorization

### JWT Authentication
```csharp
// Program.cs
builder.Services
    .AddAuthenticationJwtBearer(s => s.SigningKey = builder.Configuration["JwtKey"])
    .AddAuthorization()
    .AddFastEndpoints();

// Custom JWT configuration
builder.Services.Configure<JwtCreationOptions>(options =>
{
    options.SigningKey = builder.Configuration["JwtKey"];
    options.ExpireAt = DateTime.UtcNow.AddHours(8);
    options.Issuer = "api.example.com";
    options.Audience = "api.example.com";
});
```

### Policy-Based Authorization
```csharp
public class UpdateProductEndpoint : Endpoint<UpdateProductRequest, UpdateProductResponse>
{
    public override void Configure()
    {
        Put("/api/products/{id}");
        Policies("ProductManager", "CanEditProducts");
        PreProcessor<ProductOwnershipValidator>();
    }
}

// Pre-processor for ownership validation
public class ProductOwnershipValidator : IPreProcessor<UpdateProductRequest>
{
    public async Task PreProcessAsync(UpdateProductRequest req, HttpContext ctx, List<ValidationFailure> failures, CancellationToken ct)
    {
        var userId = ctx.User.GetUserId();
        var productService = ctx.Resolve<IProductService>();
        
        if (!await productService.IsOwnerAsync(req.Id, userId, ct))
        {
            failures.Add(new ValidationFailure("Id", "You don't have permission to edit this product"));
        }
    }
}
```

### Claims-Based Security
```csharp
public class SecureEndpoint : Endpoint<Request, Response>
{
    public override void Configure()
    {
        Get("/api/secure");
        Claims("permission", "read:data");
        ClaimsAll("role", "admin", "manager"); // Requires all claims
        ClaimsAny("department", "sales", "marketing"); // Requires any claim
    }
    
    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        var userId = User.GetClaim("sub");
        var permissions = User.GetClaims("permissions");
        var tenant = User.GetTenantId();
        
        // Process with user context
    }
}
```

## Error Handling

### Global Error Handling
```csharp
// Program.cs
app.UseFastEndpoints(c =>
{
    c.Errors.ResponseBuilder = (failures, ctx, statusCode) =>
    {
        return new ValidationProblemDetails(failures.ToValidationErrors())
        {
            Type = "https://api.example.com/errors/validation",
            Title = "Validation Error",
            Status = statusCode,
            Instance = ctx.Request.Path,
            Extensions =
            {
                ["traceId"] = Activity.Current?.Id ?? ctx.TraceIdentifier
            }
        };
    };
    
    c.Errors.ProducesMetadataType = typeof(ProblemDetails);
});
```

### Custom Error Responses
```csharp
public class ErrorEndpoint : Endpoint<Request, Response>
{
    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        try
        {
            // Business logic
        }
        catch (NotFoundException ex)
        {
            await SendNotFoundAsync(ct);
        }
        catch (BusinessRuleException ex)
        {
            ThrowError(ex.Message, StatusCodes.Status422UnprocessableEntity);
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Unexpected error");
            ThrowError("An unexpected error occurred", StatusCodes.Status500InternalServerError);
        }
    }
}

// Custom error response
public class CustomErrorResponse : IErrorResponse
{
    public string Type { get; set; } = default!;
    public string Title { get; set; } = default!;
    public int Status { get; set; }
    public Dictionary<string, string[]> Errors { get; set; } = new();
    public string TraceId { get; set; } = default!;
}
```

## Performance Optimization

### Response Caching
```csharp
public class GetProductsEndpoint : Endpoint<GetProductsRequest, List<ProductResponse>>
{
    public override void Configure()
    {
        Get("/api/products");
        AllowAnonymous();
        ResponseCache(60); // Cache for 60 seconds
        Options(x => x
            .CacheOutput(p => p
                .Expire(TimeSpan.FromMinutes(5))
                .VaryByQuery("category", "sort")
                .VaryByHeader("Accept-Language")));
    }
}

// Conditional caching
public class CachedEndpoint : Endpoint<Request, Response>
{
    public override void Configure()
    {
        Get("/api/data");
        ResponseCache(300, varyByHeader: "Authorization");
    }
    
    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        var etag = GenerateETag(req);
        
        if (HttpContext.Request.Headers.IfNoneMatch == etag)
        {
            await SendNoContentAsync(ct);
            return;
        }
        
        HttpContext.Response.Headers.ETag = etag;
        await SendOkAsync(response, ct);
    }
}
```

### Pagination
```csharp
public class ListProductsEndpoint : EndpointWithoutRequest<PagedResponse<ProductDto>>
{
    public override void Configure()
    {
        Get("/api/products");
        AllowAnonymous();
    }
    
    public override async Task HandleAsync(CancellationToken ct)
    {
        var page = Query<int>("page", 1);
        var pageSize = Query<int>("pageSize", 20);
        var sortBy = Query<string>("sortBy", "name");
        
        var result = await _productService.GetPagedAsync(page, pageSize, sortBy, ct);
        
        await SendOkAsync(new PagedResponse<ProductDto>
        {
            Items = result.Items,
            Page = page,
            PageSize = pageSize,
            TotalCount = result.TotalCount,
            TotalPages = (int)Math.Ceiling(result.TotalCount / (double)pageSize),
            Links = new PaginationLinks
            {
                First = $"/api/products?page=1&pageSize={pageSize}",
                Last = $"/api/products?page={result.TotalPages}&pageSize={pageSize}",
                Next = page < result.TotalPages ? $"/api/products?page={page + 1}&pageSize={pageSize}" : null,
                Previous = page > 1 ? $"/api/products?page={page - 1}&pageSize={pageSize}" : null
            }
        }, ct);
    }
}
```

### Streaming Responses
```csharp
public class StreamEndpoint : EndpointWithoutRequest
{
    public override void Configure()
    {
        Get("/api/stream");
        AllowAnonymous();
    }
    
    public override async Task HandleAsync(CancellationToken ct)
    {
        HttpContext.Response.ContentType = "text/event-stream";
        
        await foreach (var item in GetStreamingDataAsync(ct))
        {
            var json = JsonSerializer.Serialize(item);
            await HttpContext.Response.WriteAsync($"data: {json}\n\n", ct);
            await HttpContext.Response.Body.FlushAsync(ct);
        }
    }
    
    private async IAsyncEnumerable<DataItem> GetStreamingDataAsync([EnumeratorCancellation] CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            yield return await GetNextDataItemAsync(ct);
            await Task.Delay(1000, ct);
        }
    }
}
```

## Testing

### Integration Testing
```csharp
public class ProductEndpointTests : TestBase<Program>
{
    [Fact]
    public async Task CreateProduct_ValidRequest_Returns201()
    {
        // Arrange
        var request = new CreateProductRequest
        {
            Name = "Test Product",
            Price = 99.99m,
            Category = "Electronics"
        };
        
        // Act
        var (response, result) = await Client.POSTAsync<CreateProductEndpoint, CreateProductRequest, CreateProductResponse>(request);
        
        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        result.Name.Should().Be(request.Name);
        result.Id.Should().BeGreaterThan(0);
    }
    
    [Fact]
    public async Task CreateProduct_InvalidRequest_Returns400()
    {
        // Arrange
        var request = new CreateProductRequest { Price = -10 };
        
        // Act
        var (response, result) = await Client.POSTAsync<CreateProductEndpoint, CreateProductRequest, ErrorResponse>(request);
        
        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        result.Errors.Should().ContainKey("Name");
        result.Errors.Should().ContainKey("Price");
    }
}
```

### Unit Testing Endpoints
```csharp
public class EndpointUnitTests
{
    private readonly CreateProductEndpoint _endpoint;
    private readonly Mock<IProductService> _productService;
    
    public EndpointUnitTests()
    {
        _productService = new Mock<IProductService>();
        _endpoint = Factory.Create<CreateProductEndpoint>(_productService.Object);
    }
    
    [Fact]
    public async Task HandleAsync_CallsService_WithCorrectParameters()
    {
        // Arrange
        var request = new CreateProductRequest { Name = "Test" };
        var expectedProduct = new Product { Id = 1, Name = "Test" };
        
        _productService
            .Setup(x => x.CreateAsync(It.IsAny<CreateProductRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(expectedProduct);
        
        // Act
        await _endpoint.HandleAsync(request, CancellationToken.None);
        
        // Assert
        _productService.Verify(x => x.CreateAsync(
            It.Is<CreateProductRequest>(r => r.Name == "Test"),
            It.IsAny<CancellationToken>()), 
            Times.Once);
    }
}
```

## Middleware & Processors

### Pre-Processors
```csharp
public class TenantResolutionProcessor<TRequest> : IPreProcessor<TRequest>
{
    public async Task PreProcessAsync(TRequest req, HttpContext ctx, List<ValidationFailure> failures, CancellationToken ct)
    {
        var tenantId = ctx.Request.Headers["X-Tenant-Id"].FirstOrDefault();
        
        if (string.IsNullOrEmpty(tenantId))
        {
            failures.Add(new ValidationFailure("TenantId", "Tenant ID is required"));
            return;
        }
        
        var tenantService = ctx.Resolve<ITenantService>();
        var tenant = await tenantService.GetAsync(tenantId, ct);
        
        if (tenant == null)
        {
            failures.Add(new ValidationFailure("TenantId", "Invalid tenant"));
            return;
        }
        
        ctx.Items["Tenant"] = tenant;
    }
}
```

### Post-Processors
```csharp
public class AuditLogProcessor<TRequest, TResponse> : IPostProcessor<TRequest, TResponse>
{
    public async Task PostProcessAsync(TRequest req, TResponse res, HttpContext ctx, CancellationToken ct)
    {
        var auditService = ctx.Resolve<IAuditService>();
        
        await auditService.LogAsync(new AuditEntry
        {
            UserId = ctx.User.GetUserId(),
            Action = ctx.Request.Method + " " + ctx.Request.Path,
            RequestData = JsonSerializer.Serialize(req),
            ResponseData = JsonSerializer.Serialize(res),
            Timestamp = DateTime.UtcNow,
            IpAddress = ctx.Connection.RemoteIpAddress?.ToString()
        }, ct);
    }
}
```

## Swagger/OpenAPI

### API Documentation
```csharp
// Program.cs
builder.Services
    .SwaggerDocument(o =>
    {
        o.DocumentSettings = s =>
        {
            s.Title = "Product API";
            s.Version = "v1";
            s.Description = "Product management API";
        };
        
        o.ShortSchemaNames = true;
        o.AutoTagPathSegmentIndex = 2;
    })
    .AddSwaggerGen();

// Endpoint documentation
public class DocumentedEndpoint : Endpoint<Request, Response>
{
    public override void Configure()
    {
        Post("/api/products");
        
        Description(b => b
            .Accepts<Request>("application/json")
            .Produces<Response>(201, "application/json")
            .ProducesProblemFE(400)
            .ProducesProblemFE<InternalErrorResponse>(500));
            
        Summary(s =>
        {
            s.Summary = "Create a product";
            s.Description = "Creates a new product in the catalog";
            s.RequestParam(r => r.Name, "Product name (3-100 characters)");
            s.RequestParam(r => r.Price, "Product price in USD");
            s.Response(201, "Product created successfully");
            s.Response(400, "Invalid request data");
        });
    }
}
```

## Rate Limiting

### Endpoint Rate Limiting
```csharp
public class RateLimitedEndpoint : Endpoint<Request, Response>
{
    public override void Configure()
    {
        Get("/api/data");
        Throttle(
            hitLimit: 100,
            durationSeconds: 60,
            headerName: "X-Client-Id" // Rate limit per client
        );
    }
}

// Global rate limiting
app.UseRateLimiter(new RateLimiterOptions
{
    GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
    {
        var clientId = context.Request.Headers["X-Client-Id"].FirstOrDefault() ?? "anonymous";
        
        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: clientId,
            factory: partition => new FixedWindowRateLimiterOptions
            {
                AutoReplenishment = true,
                PermitLimit = 100,
                Window = TimeSpan.FromMinutes(1)
            });
    })
});
```

## Background Jobs

### Endpoint with Background Processing
```csharp
public class ProcessOrderEndpoint : Endpoint<ProcessOrderRequest, ProcessOrderResponse>
{
    private readonly IBackgroundJobClient _jobClient;
    
    public override async Task HandleAsync(ProcessOrderRequest req, CancellationToken ct)
    {
        // Immediate response
        var orderId = await CreateOrderAsync(req, ct);
        
        // Queue background job
        _jobClient.Enqueue<IOrderProcessor>(x => x.ProcessAsync(orderId, CancellationToken.None));
        
        await SendAcceptedAsync(new ProcessOrderResponse
        {
            OrderId = orderId,
            Status = "Processing",
            EstimatedCompletion = DateTime.UtcNow.AddMinutes(5)
        }, ct);
    }
}
```

## Health Checks

### API Health Endpoints
```csharp
public class HealthCheckEndpoint : EndpointWithoutRequest<HealthResponse>
{
    public override void Configure()
    {
        Get("/health");
        AllowAnonymous();
        DontCatchExceptions();
    }
    
    public override async Task HandleAsync(CancellationToken ct)
    {
        var healthService = Resolve<IHealthCheckService>();
        var result = await healthService.CheckHealthAsync(ct);
        
        var response = new HealthResponse
        {
            Status = result.Status.ToString(),
            Duration = result.TotalDuration,
            Checks = result.Entries.Select(e => new HealthCheck
            {
                Name = e.Key,
                Status = e.Value.Status.ToString(),
                Duration = e.Value.Duration,
                Description = e.Value.Description
            }).ToList()
        };
        
        var statusCode = result.Status == HealthStatus.Healthy ? 200 : 503;
        await SendAsync(response, statusCode, ct);
    }
}
```

## Best Practices Summary

1. **Vertical Slice Architecture**: Organize features in folders with all related files together
2. **Single Responsibility**: Keep endpoints focused on one operation
3. **Validation First**: Always validate input before processing
4. **Proper Status Codes**: Use appropriate HTTP status codes
5. **Consistent Error Handling**: Implement global error handling with detailed responses
6. **Security by Default**: Require authentication unless explicitly allowing anonymous
7. **Performance Focus**: Use caching, pagination, and streaming where appropriate
8. **Comprehensive Testing**: Write integration and unit tests for all endpoints
9. **API Documentation**: Document all endpoints with OpenAPI/Swagger
10. **Monitoring Ready**: Include health checks and logging

## Conclusion

FastEndpoints provides a streamlined approach to building high-performance APIs in .NET. Following these best practices ensures your APIs are fast, secure, maintainable, and production-ready.