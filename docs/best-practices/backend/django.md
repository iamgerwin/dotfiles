# Django Best Practices

## Official Documentation
- **Django Documentation**: https://docs.djangoproject.com
- **Django REST Framework**: https://www.django-rest-framework.org
- **Django Packages**: https://djangopackages.org
- **Django Girls Tutorial**: https://tutorial.djangogirls.org

## Project Structure

```
project-root/
├── project/
│   ├── settings/
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── development.py
│   │   ├── production.py
│   │   └── testing.py
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
├── apps/
│   ├── accounts/
│   │   ├── migrations/
│   │   ├── management/
│   │   │   └── commands/
│   │   ├── templates/
│   │   ├── static/
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   ├── urls.py
│   │   ├── forms.py
│   │   ├── admin.py
│   │   ├── signals.py
│   │   ├── tasks.py
│   │   └── tests/
│   │       ├── test_models.py
│   │       ├── test_views.py
│   │       └── test_serializers.py
│   └── products/
│       └── ...
├── core/
│   ├── middleware/
│   ├── decorators/
│   ├── mixins/
│   ├── validators/
│   └── utils/
├── static/
│   ├── css/
│   ├── js/
│   └── images/
├── media/
├── templates/
│   ├── base.html
│   └── includes/
├── locale/
├── requirements/
│   ├── base.txt
│   ├── development.txt
│   ├── production.txt
│   └── testing.txt
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
├── .env.example
├── manage.py
├── pytest.ini
└── README.md
```

## Core Best Practices

### 1. Models and Database

```python
# apps/accounts/models.py
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.core.validators import MinLengthValidator, EmailValidator
from django.utils.translation import gettext_lazy as _
from core.models import TimeStampedModel, UUIDModel
import uuid

class User(AbstractUser, UUIDModel, TimeStampedModel):
    """Custom User model with email as username field."""
    
    email = models.EmailField(
        _('email address'),
        unique=True,
        validators=[EmailValidator()],
        error_messages={
            'unique': _("A user with that email already exists."),
        }
    )
    username = models.CharField(
        _('username'),
        max_length=150,
        unique=True,
        help_text=_('Required. 150 characters or fewer.'),
        validators=[MinLengthValidator(3)],
    )
    bio = models.TextField(_('bio'), max_length=500, blank=True)
    avatar = models.ImageField(
        upload_to='avatars/%Y/%m/%d/',
        blank=True,
        null=True
    )
    is_email_verified = models.BooleanField(default=False)
    phone_number = models.CharField(max_length=20, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']
    
    class Meta:
        verbose_name = _('User')
        verbose_name_plural = _('Users')
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['email']),
            models.Index(fields=['username']),
            models.Index(fields=['-created_at']),
        ]
    
    def __str__(self):
        return self.email
    
    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}".strip() or self.username
    
    def get_absolute_url(self):
        from django.urls import reverse
        return reverse('user-detail', kwargs={'pk': self.pk})

# Base models
class TimeStampedModel(models.Model):
    """Abstract model with created and modified timestamps."""
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True, db_index=True)
    
    class Meta:
        abstract = True

class UUIDModel(models.Model):
    """Abstract model with UUID as primary key."""
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    
    class Meta:
        abstract = True

# Product model with advanced features
class Product(UUIDModel, TimeStampedModel):
    """Product model with optimized queries."""
    
    class Status(models.TextChoices):
        DRAFT = 'DR', _('Draft')
        PUBLISHED = 'PB', _('Published')
        ARCHIVED = 'AR', _('Archived')
    
    name = models.CharField(max_length=200, db_index=True)
    slug = models.SlugField(max_length=200, unique=True)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    stock = models.PositiveIntegerField(default=0)
    status = models.CharField(
        max_length=2,
        choices=Status.choices,
        default=Status.DRAFT
    )
    category = models.ForeignKey(
        'Category',
        on_delete=models.CASCADE,
        related_name='products'
    )
    tags = models.ManyToManyField('Tag', blank=True)
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_products'
    )
    
    objects = models.Manager()  # Default manager
    published = PublishedManager()  # Custom manager
    
    class Meta:
        verbose_name = _('Product')
        verbose_name_plural = _('Products')
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['slug']),
            models.Index(fields=['status', '-created_at']),
        ]
        permissions = [
            ('can_publish', 'Can publish products'),
        ]
    
    def __str__(self):
        return self.name
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)
    
    def get_absolute_url(self):
        return reverse('product-detail', kwargs={'slug': self.slug})
    
    @property
    def is_in_stock(self):
        return self.stock > 0
    
    def decrease_stock(self, quantity):
        """Decrease stock with atomic operation."""
        from django.db.models import F
        self.stock = F('stock') - quantity
        self.save(update_fields=['stock'])

# Custom Manager
class PublishedManager(models.Manager):
    def get_queryset(self):
        return super().get_queryset().filter(status=Product.Status.PUBLISHED)
    
    def with_related(self):
        """Optimize queries with select_related and prefetch_related."""
        return self.get_queryset().select_related(
            'category', 'created_by'
        ).prefetch_related('tags')
```

### 2. Views and ViewSets

```python
# apps/products/views.py
from django.shortcuts import get_object_or_404
from django.views.generic import ListView, DetailView, CreateView, UpdateView
from django.contrib.auth.mixins import LoginRequiredMixin, PermissionRequiredMixin
from django.db.models import Q, Count, Avg
from django.core.cache import cache
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page
from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly
from .models import Product
from .serializers import ProductSerializer, ProductDetailSerializer
from .filters import ProductFilter
from .permissions import IsOwnerOrReadOnly
from .pagination import StandardResultsSetPagination

# Class-Based Views
class ProductListView(ListView):
    model = Product
    template_name = 'products/list.html'
    context_object_name = 'products'
    paginate_by = 20
    
    def get_queryset(self):
        queryset = Product.published.with_related()
        
        # Search functionality
        search_query = self.request.GET.get('q')
        if search_query:
            queryset = queryset.filter(
                Q(name__icontains=search_query) |
                Q(description__icontains=search_query)
            )
        
        # Filter by category
        category_slug = self.kwargs.get('category_slug')
        if category_slug:
            queryset = queryset.filter(category__slug=category_slug)
        
        return queryset
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['categories'] = cache.get_or_set(
            'categories_list',
            lambda: Category.objects.annotate(
                product_count=Count('products')
            ),
            3600
        )
        return context

@method_decorator(cache_page(60 * 15), name='dispatch')
class ProductDetailView(DetailView):
    model = Product
    template_name = 'products/detail.html'
    context_object_name = 'product'
    
    def get_queryset(self):
        return Product.published.with_related()
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        # Get related products
        context['related_products'] = Product.published.filter(
            category=self.object.category
        ).exclude(pk=self.object.pk)[:4]
        return context

class ProductCreateView(LoginRequiredMixin, PermissionRequiredMixin, CreateView):
    model = Product
    fields = ['name', 'description', 'price', 'stock', 'category', 'tags']
    template_name = 'products/form.html'
    permission_required = 'products.add_product'
    
    def form_valid(self, form):
        form.instance.created_by = self.request.user
        return super().form_valid(form)

# Django REST Framework ViewSet
class ProductViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Product model with custom actions.
    """
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    permission_classes = [IsAuthenticatedOrReadOnly, IsOwnerOrReadOnly]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'description']
    ordering_fields = ['created_at', 'price', 'name']
    ordering = ['-created_at']
    pagination_class = StandardResultsSetPagination
    filterset_class = ProductFilter
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return ProductDetailSerializer
        return ProductSerializer
    
    def get_queryset(self):
        queryset = Product.objects.all()
        
        if self.action == 'list':
            queryset = queryset.filter(status=Product.Status.PUBLISHED)
        
        # Optimize queries
        if self.action in ['list', 'retrieve']:
            queryset = queryset.select_related(
                'category', 'created_by'
            ).prefetch_related('tags')
        
        return queryset
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def add_to_cart(self, request, pk=None):
        """Custom action to add product to cart."""
        product = self.get_object()
        quantity = request.data.get('quantity', 1)
        
        if not product.is_in_stock:
            return Response(
                {'error': 'Product is out of stock'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Add to cart logic
        cart_item, created = CartItem.objects.get_or_create(
            user=request.user,
            product=product,
            defaults={'quantity': quantity}
        )
        
        if not created:
            cart_item.quantity += quantity
            cart_item.save()
        
        return Response(
            {'message': 'Product added to cart'},
            status=status.HTTP_200_OK
        )
    
    @action(detail=False, methods=['get'])
    def popular(self, request):
        """Get popular products based on orders."""
        popular_products = self.get_queryset().annotate(
            order_count=Count('orderitem')
        ).order_by('-order_count')[:10]
        
        serializer = self.get_serializer(popular_products, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def recommendations(self, request):
        """Get product recommendations for user."""
        if not request.user.is_authenticated:
            return Response(
                {'error': 'Authentication required'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        # Simple recommendation logic
        user_categories = request.user.orders.values_list(
            'items__product__category', flat=True
        ).distinct()
        
        recommendations = self.get_queryset().filter(
            category__in=user_categories
        ).exclude(
            orderitem__order__user=request.user
        ).distinct()[:10]
        
        serializer = self.get_serializer(recommendations, many=True)
        return Response(serializer.data)
```

### 3. Serializers (Django REST Framework)

```python
# apps/products/serializers.py
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Product, Category, Tag

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    full_name = serializers.ReadOnlyField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'full_name', 'avatar']
        read_only_fields = ['id']

class TagSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tag
        fields = ['id', 'name', 'slug']

class CategorySerializer(serializers.ModelSerializer):
    product_count = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Category
        fields = ['id', 'name', 'slug', 'product_count']

class ProductSerializer(serializers.ModelSerializer):
    created_by = UserSerializer(read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)
    is_in_stock = serializers.BooleanField(read_only=True)
    url = serializers.HyperlinkedIdentityField(
        view_name='product-detail',
        lookup_field='slug'
    )
    
    class Meta:
        model = Product
        fields = [
            'id', 'url', 'name', 'slug', 'description', 'price',
            'stock', 'is_in_stock', 'status', 'category', 'category_name',
            'tags', 'created_by', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'slug', 'created_by', 'created_at', 'updated_at']
    
    def validate_price(self, value):
        if value <= 0:
            raise serializers.ValidationError("Price must be greater than zero.")
        return value
    
    def validate(self, data):
        if data.get('stock', 0) < 0:
            raise serializers.ValidationError("Stock cannot be negative.")
        return data

class ProductDetailSerializer(ProductSerializer):
    category = CategorySerializer(read_only=True)
    tags = TagSerializer(many=True, read_only=True)
    related_products = serializers.SerializerMethodField()
    
    class Meta(ProductSerializer.Meta):
        fields = ProductSerializer.Meta.fields + ['related_products']
    
    def get_related_products(self, obj):
        related = Product.published.filter(
            category=obj.category
        ).exclude(pk=obj.pk)[:4]
        return ProductSerializer(related, many=True, context=self.context).data

# Nested Serializer with create/update
class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True)
    total_amount = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    
    class Meta:
        model = Order
        fields = ['id', 'user', 'items', 'total_amount', 'status', 'created_at']
    
    def create(self, validated_data):
        items_data = validated_data.pop('items')
        order = Order.objects.create(**validated_data)
        
        for item_data in items_data:
            OrderItem.objects.create(order=order, **item_data)
        
        return order
    
    def update(self, instance, validated_data):
        items_data = validated_data.pop('items', None)
        
        # Update order fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Update items if provided
        if items_data is not None:
            instance.items.all().delete()
            for item_data in items_data:
                OrderItem.objects.create(order=instance, **item_data)
        
        return instance
```

### 4. Forms and Validation

```python
# apps/accounts/forms.py
from django import forms
from django.contrib.auth.forms import UserCreationForm, UserChangeForm
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
import re

User = get_user_model()

class CustomUserCreationForm(UserCreationForm):
    email = forms.EmailField(
        required=True,
        widget=forms.EmailInput(attrs={
            'class': 'form-control',
            'placeholder': 'Email address'
        })
    )
    
    class Meta(UserCreationForm.Meta):
        model = User
        fields = ('email', 'username', 'password1', 'password2')
        widgets = {
            'username': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Username'
            }),
        }
    
    def clean_email(self):
        email = self.cleaned_data.get('email')
        if User.objects.filter(email=email).exists():
            raise ValidationError("This email is already registered.")
        return email
    
    def clean_username(self):
        username = self.cleaned_data.get('username')
        if not re.match("^[a-zA-Z0-9_-]+$", username):
            raise ValidationError(
                "Username can only contain letters, numbers, hyphens, and underscores."
            )
        return username

class UserProfileForm(forms.ModelForm):
    class Meta:
        model = User
        fields = ['first_name', 'last_name', 'bio', 'avatar', 'date_of_birth']
        widgets = {
            'bio': forms.Textarea(attrs={'rows': 4}),
            'date_of_birth': forms.DateInput(attrs={'type': 'date'}),
        }
    
    def clean_avatar(self):
        avatar = self.cleaned_data.get('avatar')
        if avatar:
            if avatar.size > 5 * 1024 * 1024:  # 5MB limit
                raise ValidationError("Image file too large ( > 5MB )")
            return avatar
        return None

# Formset example
OrderItemFormSet = forms.inlineformset_factory(
    Order,
    OrderItem,
    fields=('product', 'quantity', 'price'),
    extra=1,
    can_delete=True,
    widgets={
        'product': forms.Select(attrs={'class': 'form-control'}),
        'quantity': forms.NumberInput(attrs={'class': 'form-control', 'min': '1'}),
        'price': forms.NumberInput(attrs={'class': 'form-control', 'step': '0.01'}),
    }
)
```

### 5. Middleware

```python
# core/middleware/security.py
import time
import logging
from django.core.cache import cache
from django.http import HttpResponseForbidden
from django.utils.deprecation import MiddlewareMixin

logger = logging.getLogger(__name__)

class RateLimitMiddleware(MiddlewareMixin):
    """Rate limiting middleware using cache."""
    
    def process_request(self, request):
        if request.user.is_authenticated:
            ident = request.user.pk
        else:
            ident = request.META.get('REMOTE_ADDR')
        
        key = f'rate_limit_{ident}'
        requests = cache.get(key, 0)
        
        if requests >= 100:  # 100 requests per minute
            return HttpResponseForbidden('Rate limit exceeded')
        
        cache.set(key, requests + 1, 60)  # Reset after 60 seconds
        return None

class RequestLoggingMiddleware(MiddlewareMixin):
    """Log all requests with timing information."""
    
    def process_request(self, request):
        request.start_time = time.time()
        return None
    
    def process_response(self, request, response):
        if hasattr(request, 'start_time'):
            duration = time.time() - request.start_time
            logger.info(
                f"{request.method} {request.path} "
                f"completed in {duration:.2f}s with status {response.status_code}"
            )
        return response

class HealthCheckMiddleware(MiddlewareMixin):
    """Bypass authentication for health check endpoint."""
    
    def process_request(self, request):
        if request.path == '/health/':
            return JsonResponse({'status': 'healthy'})
        return None
```

### 6. Signals

```python
# apps/accounts/signals.py
from django.db.models.signals import post_save, pre_delete
from django.dispatch import receiver
from django.core.cache import cache
from django.contrib.auth import get_user_model
from .models import UserProfile
from .tasks import send_welcome_email

User = get_user_model()

@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    """Create user profile when user is created."""
    if created:
        UserProfile.objects.create(user=instance)
        # Send welcome email asynchronously
        send_welcome_email.delay(instance.email, instance.username)

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    """Save user profile when user is saved."""
    if hasattr(instance, 'profile'):
        instance.profile.save()

@receiver(pre_delete, sender=Product)
def clear_product_cache(sender, instance, **kwargs):
    """Clear cache when product is deleted."""
    cache.delete(f'product_{instance.slug}')
    cache.delete('popular_products')

# apps/products/apps.py
from django.apps import AppConfig

class ProductsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.products'
    
    def ready(self):
        import apps.products.signals  # Import signals
```

### 7. Celery Tasks

```python
# apps/accounts/tasks.py
from celery import shared_task
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.utils.html import strip_tags
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

@shared_task(bind=True, max_retries=3)
def send_welcome_email(self, email, username):
    """Send welcome email to new users."""
    try:
        subject = 'Welcome to Our Platform!'
        html_message = render_to_string('emails/welcome.html', {
            'username': username
        })
        plain_message = strip_tags(html_message)
        
        send_mail(
            subject,
            plain_message,
            settings.DEFAULT_FROM_EMAIL,
            [email],
            html_message=html_message,
            fail_silently=False,
        )
        
        logger.info(f"Welcome email sent to {email}")
        return True
        
    except Exception as exc:
        logger.error(f"Failed to send email to {email}: {exc}")
        raise self.retry(exc=exc, countdown=60)

@shared_task
def cleanup_expired_sessions():
    """Clean up expired sessions daily."""
    from django.contrib.sessions.models import Session
    from django.utils import timezone
    
    expired_sessions = Session.objects.filter(expire_date__lt=timezone.now())
    count = expired_sessions.count()
    expired_sessions.delete()
    
    logger.info(f"Deleted {count} expired sessions")
    return count

@shared_task
def generate_sales_report():
    """Generate daily sales report."""
    from datetime import datetime, timedelta
    from apps.orders.models import Order
    
    yesterday = datetime.now().date() - timedelta(days=1)
    orders = Order.objects.filter(
        created_at__date=yesterday,
        status='completed'
    )
    
    total_sales = orders.aggregate(
        total=models.Sum('total_amount')
    )['total'] or 0
    
    # Generate report logic
    report_data = {
        'date': yesterday,
        'total_orders': orders.count(),
        'total_sales': total_sales,
    }
    
    # Save or email report
    return report_data
```

### 8. Testing

```python
# apps/products/tests/test_models.py
from django.test import TestCase
from django.contrib.auth import get_user_model
from apps.products.models import Product, Category
from decimal import Decimal

User = get_user_model()

class ProductModelTest(TestCase):
    @classmethod
    def setUpTestData(cls):
        cls.user = User.objects.create_user(
            email='test@example.com',
            username='testuser',
            password='testpass123'
        )
        cls.category = Category.objects.create(
            name='Electronics',
            slug='electronics'
        )
    
    def test_product_creation(self):
        product = Product.objects.create(
            name='Test Product',
            description='Test description',
            price=Decimal('99.99'),
            stock=10,
            category=self.category,
            created_by=self.user
        )
        
        self.assertEqual(str(product), 'Test Product')
        self.assertEqual(product.slug, 'test-product')
        self.assertTrue(product.is_in_stock)
    
    def test_product_stock_operations(self):
        product = Product.objects.create(
            name='Test Product',
            price=Decimal('50.00'),
            stock=5,
            category=self.category
        )
        
        product.decrease_stock(3)
        product.refresh_from_db()
        self.assertEqual(product.stock, 2)

# apps/products/tests/test_views.py
from django.test import TestCase, Client
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status

class ProductViewTest(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='test@example.com',
            username='testuser',
            password='testpass123'
        )
        self.category = Category.objects.create(
            name='Books',
            slug='books'
        )
        self.product = Product.objects.create(
            name='Test Book',
            description='A test book',
            price=Decimal('29.99'),
            stock=100,
            category=self.category,
            status=Product.Status.PUBLISHED
        )
    
    def test_list_products(self):
        url = reverse('product-list')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
    
    def test_create_product_authenticated(self):
        self.client.force_authenticate(user=self.user)
        url = reverse('product-list')
        data = {
            'name': 'New Product',
            'description': 'New description',
            'price': '19.99',
            'stock': 50,
            'category': self.category.id
        }
        
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Product.objects.count(), 2)
    
    def test_create_product_unauthenticated(self):
        url = reverse('product-list')
        data = {
            'name': 'New Product',
            'price': '19.99'
        }
        
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
```

### Common Pitfalls to Avoid

1. **Not using select_related and prefetch_related**
2. **Storing sensitive data in settings**
3. **Not using database indexes**
4. **Using inline CSS/JS instead of static files**
5. **Not implementing proper caching**
6. **Ignoring database migrations**
7. **Not using Django's built-in security features**
8. **Creating circular imports**
9. **Not writing tests**
10. **Using development server in production**

### Useful Packages

- **django-rest-framework**: REST API framework
- **django-cors-headers**: CORS handling
- **django-filter**: Filtering querysets
- **django-crispy-forms**: Better forms
- **django-debug-toolbar**: Development debugging
- **celery**: Asynchronous tasks
- **redis**: Caching and message broker
- **django-storages**: Cloud storage backends
- **django-allauth**: Authentication
- **django-extensions**: Management extensions
- **pytest-django**: Testing with pytest
- **factory-boy**: Test fixtures