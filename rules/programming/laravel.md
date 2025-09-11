# Laravel Best Practices and Bad Code Avoidance

## Code Structure and Organization
- Follow Laravel’s MVC pattern strictly: Controllers handle HTTP requests, Models handle data, and Views handle presentation.
- Keep Controllers thin: Delegate business logic to Services or Actions to improve testability and readability.
- Use Eloquent ORM properly: Avoid raw SQL queries unless absolutely necessary.
- Group related routes using route groups, prefixes, and middleware to keep `routes/web.php` organized.

## Naming Conventions
- Use meaningful, descriptive names for models, controllers, variables, and methods.
- Follow PSR-12 coding standards for PHP code style.
- Use singular names for models and plural names for database tables (Laravel convention).

## Database and Migrations
- Use Laravel migrations and seeders for all database schema changes and initial data setup.
- Keep migrations small and focused; avoid large, complicated migrations.
- Use database relationships (hasOne, hasMany, belongsTo, etc.) to leverage Laravel’s ORM features.
- Avoid querying inside loops — eager load relationships using `with()` to optimize performance.

## Security Practices
- Always use Laravel's built-in validation and Authorization (e.g., Form Requests, Gates, Policies).
- Avoid mass assignment vulnerabilities by specifying `$fillable` or `$guarded` in models.
- Use Laravel’s built-in encryption and hashing for sensitive data like passwords.
- Sanitize and escape user input when displaying data.

## Testing
- Write Feature tests for user flows and Unit tests for isolated logic.
- Use Laravel’s testing helpers for HTTP requests, database transactions, and authentication.
- Mock external services or APIs to avoid flaky tests.
- Ensure database is cleaned up or reset between tests.

## Performance and Optimization
- Use caching strategies (Redis or file cache) for expensive queries or API calls.
- Avoid N+1 query problems by eager loading relationships.
- Optimize queues and jobs for background processing.
- Use pagination for large datasets instead of loading everything at once.

## Code Quality
- Use Laravel’s Request Validation instead of manual checks in controllers.
- Avoid long methods by breaking them into smaller reusable methods.
- Use Events and Listeners for decoupling concerns.
- Follow DRY (Don’t Repeat Yourself): extract reusable logic into Traits or Services.
- Avoid heavy logic inside Blade templates; keep templates simple and presentational.

## Environment and Configuration
- Use environment variables (`.env`) for configuration — never hardcode sensitive values.
- Use config caching (`php artisan config:cache`) in production for better performance.
- Keep multiple environment configs well organized and avoid committing secrets to version control.

## Logging and Error Handling
- Leverage Laravel’s built-in logging facilities for monitoring and debugging.
- Handle exceptions gracefully with custom exception handlers.
- Use notifications (email/slack) for critical errors if applicable.

## Deployment and Maintenance
- Use database migrations for schema changes during deployments.
- Run automated tests before deployment with CI/CD pipelines.
- Keep dependencies up to date but verify backward compatibility.
- Regularly review and refactor old code to maintain quality.

## Common Anti-Patterns to Avoid
- Putting business logic in controllers or views.
- Ignoring validation and authorization checks.
- Writing raw SQL when Eloquent or Query Builder can be used.
- Overusing facades in places where dependency injection would be clearer.
- Committing `.env` files or sensitive data to repositories.
- Not handling edge cases like empty states or failure responses gracefully.

---

Following these Laravel best practices ensures maintainable, secure, and performant applications that leverage the framework’s full power effectively.
