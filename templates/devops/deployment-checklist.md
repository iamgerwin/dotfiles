# 🚀 Deployment Checklist Template

## Deployment Information
**Application**: [Application name]
**Version**: [Version number]
**Environment**: [Production/Staging/Development]
**Deployment Date**: [Date]
**Deployer**: [Name]

## Pre-Deployment Checklist

### Code Preparation
- [ ] All code merged to deployment branch
- [ ] Code review completed
- [ ] All tests passing
- [ ] No console.log or debug statements
- [ ] Linting passed
- [ ] Build successful locally

### Database
- [ ] Migrations tested on staging
- [ ] Backup current database
- [ ] Migration rollback plan prepared
- [ ] Seeds/initial data ready (if needed)
- [ ] Database performance impact assessed

### Configuration
- [ ] Environment variables updated
- [ ] API keys and secrets configured
- [ ] Feature flags set appropriately
- [ ] Cache configuration verified
- [ ] Queue workers configuration checked

### Dependencies
- [ ] Composer dependencies updated
- [ ] NPM packages updated
- [ ] No security vulnerabilities in dependencies
- [ ] Lock files committed (composer.lock, package-lock.json)

### Documentation
- [ ] README updated
- [ ] API documentation current
- [ ] CHANGELOG updated
- [ ] Deployment notes prepared
- [ ] Rollback procedure documented

## Deployment Process

### Step 1: Prepare Environment
```bash
# Put application in maintenance mode
php artisan down --message="Upgrading application" --retry=60

# Backup database
mysqldump -u [user] -p [database] > backup_$(date +%Y%m%d_%H%M%S).sql

# Pull latest code
git fetch origin
git checkout [branch]
git pull origin [branch]
```

### Step 2: Update Dependencies
```bash
# Install composer dependencies
composer install --no-dev --optimize-autoloader

# Install NPM dependencies and build assets
npm ci
npm run production

# Clear and rebuild caches
php artisan cache:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

### Step 3: Database Updates
```bash
# Run migrations
php artisan migrate --force

# Run seeders if needed
php artisan db:seed --class=ProductionSeeder --force
```

### Step 4: Application Updates
```bash
# Clear application cache
php artisan cache:clear

# Restart queue workers
php artisan queue:restart

# Clear expired password reset tokens
php artisan auth:clear-resets

# Clear and regenerate cached events
php artisan event:cache

# Storage link (if needed)
php artisan storage:link
```

### Step 5: Verify Deployment
```bash
# Run health check
curl https://[domain]/health

# Check application version
php artisan about

# Verify critical features
php artisan app:verify-deployment
```

### Step 6: Complete Deployment
```bash
# Bring application back online
php artisan up

# Clear CDN cache (if applicable)
# Clear browser cache notification
# Monitor logs for errors
tail -f storage/logs/laravel.log
```

## Post-Deployment Checklist

### Immediate Verification (First 5 minutes)
- [ ] Application accessible
- [ ] Login functionality working
- [ ] Critical features operational
- [ ] No 500 errors in logs
- [ ] Database connections stable
- [ ] Queue processing normally

### Monitoring (First 30 minutes)
- [ ] Error rate normal
- [ ] Response times acceptable
- [ ] Memory usage stable
- [ ] CPU usage normal
- [ ] No unusual database queries
- [ ] Third-party integrations working

### User Verification
- [ ] Key user workflows tested
- [ ] Payment processing working (if applicable)
- [ ] Email notifications sending
- [ ] File uploads/downloads working
- [ ] Search functionality operational
- [ ] Mobile responsiveness verified

## Rollback Plan

### Automatic Rollback Triggers
- Error rate > 5%
- Response time > 3 seconds
- Memory usage > 90%
- Critical feature failure

### Rollback Procedure
```bash
# 1. Put application in maintenance mode
php artisan down

# 2. Revert code to previous version
git checkout [previous-version-tag]

# 3. Restore database backup
mysql -u [user] -p [database] < backup_[timestamp].sql

# 4. Clear all caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# 5. Reinstall previous dependencies
composer install
npm ci
npm run production

# 6. Bring application back online
php artisan up

# 7. Notify team of rollback
```

## Communication Plan

### Pre-Deployment
- [ ] Team notified of deployment window
- [ ] Stakeholders informed
- [ ] Maintenance page prepared
- [ ] Status page updated

### During Deployment
- [ ] Real-time updates in deployment channel
- [ ] Issue escalation path clear
- [ ] Emergency contacts available

### Post-Deployment
- [ ] Success notification sent
- [ ] Release notes published
- [ ] Customer notification (if needed)
- [ ] Team retrospective scheduled

## Environment-Specific Considerations

### Production
- Deploy during low-traffic window
- Have rollback plan ready
- Monitor closely for 24 hours
- Keep team on standby

### Staging
- Mirror production process
- Test rollback procedure
- Verify with QA team
- Document any issues

### Development
- Can be more aggressive
- Test new deployment scripts
- Experiment with optimizations

## Security Checklist
- [ ] No sensitive data in logs
- [ ] API keys rotated if needed
- [ ] File permissions correct
- [ ] Debug mode disabled
- [ ] HTTPS enforced
- [ ] Security headers configured
- [ ] Rate limiting active
- [ ] CORS properly configured

## Performance Verification
- [ ] Page load times acceptable
- [ ] Database query performance normal
- [ ] API response times within SLA
- [ ] CDN cache hit rate normal
- [ ] No memory leaks detected

## Deployment Metrics
- **Deployment Duration**: [time]
- **Downtime**: [time or zero-downtime]
- **Issues Encountered**: [list]
- **Rollback Required**: [Yes/No]
- **Performance Impact**: [metrics]

## Lessons Learned
- What went well:
- What could be improved:
- Action items for next deployment:

---
Remember: Always have a rollback plan. Monitor closely after deployment. Document everything.