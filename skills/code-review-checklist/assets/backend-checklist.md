# Backend Code Review Checklist

## Code Quality & Standards

- [ ] Code follows PSR-12 / team coding standards
- [ ] No magic numbers or strings (use constants/enums)
- [ ] Methods are focused and single-purpose
- [ ] Class naming is clear and descriptive
- [ ] No code duplication (DRY principle)
- [ ] Proper use of type hints and return types
- [ ] No unnecessary comments (code is self-documenting)

## Security Considerations

- [ ] Input validation on all user data
- [ ] Authorization checks in place (Gates/Policies)
- [ ] No raw SQL queries (use Eloquent/Query Builder)
- [ ] Sensitive data not logged or exposed
- [ ] CSRF protection on forms
- [ ] Mass assignment protection (fillable/guarded)
- [ ] File uploads validated (type, size, extension)
- [ ] No hardcoded credentials or secrets

## Database & Performance

- [ ] N+1 queries addressed (eager loading)
- [ ] Indexes added for frequently queried columns
- [ ] Large datasets paginated
- [ ] Database transactions used for multiple operations
- [ ] Migrations are reversible
- [ ] Query optimization considered for complex queries

## Error Handling

- [ ] Appropriate exceptions thrown
- [ ] Errors logged with sufficient context
- [ ] User-friendly error messages
- [ ] Edge cases handled gracefully
- [ ] No silent failures

## Testing

- [ ] Unit tests cover new functionality
- [ ] Integration tests for critical paths
- [ ] Edge cases tested
- [ ] Test assertions are meaningful
- [ ] Tests are independent and isolated
- [ ] Mocking used appropriately

## Documentation

- [ ] PHPDoc blocks on public methods
- [ ] Complex logic explained
- [ ] API endpoints documented
- [ ] README updated if needed
- [ ] Breaking changes noted

## Laravel-Specific

- [ ] Form Requests used for validation
- [ ] Resources/Transformers for API responses
- [ ] Jobs for heavy processing
- [ ] Events/Listeners for decoupled logic
- [ ] Service classes for business logic
- [ ] Repository pattern if applicable
- [ ] Cache invalidation handled

## Final Checks

- [ ] PR description is clear and complete
- [ ] Related issues linked
- [ ] No debug code left (dd(), dump(), var_dump())
- [ ] No .env changes committed
- [ ] Branch is up to date with target branch
