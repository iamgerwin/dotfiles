# Python Best Practices

## Official Documentation
- **Python Documentation**: https://docs.python.org/3/
- **PEP 8 Style Guide**: https://pep8.org/
- **Python Package Index (PyPI)**: https://pypi.org/
- **Real Python**: https://realpython.com/

## Project Structure

```
project-root/
├── src/
│   ├── __init__.py
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes/
│   │   │   ├── __init__.py
│   │   │   ├── auth.py
│   │   │   └── users.py
│   │   ├── middlewares/
│   │   │   ├── __init__.py
│   │   │   └── auth.py
│   │   └── dependencies.py
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py
│   │   ├── exceptions.py
│   │   └── security.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── base.py
│   │   └── user.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── auth_service.py
│   │   └── user_service.py
│   ├── repositories/
│   │   ├── __init__.py
│   │   └── user_repository.py
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── validators.py
│   │   └── helpers.py
│   └── main.py
├── tests/
│   ├── __init__.py
│   ├── unit/
│   ├── integration/
│   └── conftest.py
├── alembic/
│   └── versions/
├── scripts/
├── docs/
├── requirements/
│   ├── base.txt
│   ├── dev.txt
│   └── prod.txt
├── .env.example
├── .gitignore
├── Dockerfile
├── docker-compose.yml
├── Makefile
├── pyproject.toml
├── setup.py
└── README.md
```

## Core Best Practices

### 1. FastAPI Application Structure

```python
# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn

from src.core.config import settings
from src.api.routes import auth, users, products
from src.core.database import engine, Base
from src.core.exceptions import setup_exception_handlers


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Handle startup and shutdown events."""
    # Startup
    print("Starting up...")
    # Create database tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    yield
    
    # Shutdown
    print("Shutting down...")
    # Close database connections
    await engine.dispose()


def create_application() -> FastAPI:
    """Create and configure FastAPI application."""
    
    app = FastAPI(
        title=settings.PROJECT_NAME,
        version=settings.VERSION,
        description=settings.DESCRIPTION,
        docs_url="/api/docs",
        redoc_url="/api/redoc",
        openapi_url="/api/openapi.json",
        lifespan=lifespan
    )
    
    # CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Exception handlers
    setup_exception_handlers(app)
    
    # Include routers
    app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
    app.include_router(users.router, prefix="/api/users", tags=["Users"])
    app.include_router(products.router, prefix="/api/products", tags=["Products"])
    
    @app.get("/health")
    async def health_check():
        """Health check endpoint."""
        return {"status": "healthy", "version": settings.VERSION}
    
    return app


app = create_application()

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level="info"
    )
```

### 2. Configuration Management

```python
# core/config.py
from pydantic_settings import BaseSettings
from pydantic import Field, validator
from typing import List, Optional
from functools import lru_cache
import secrets


class Settings(BaseSettings):
    """Application settings."""
    
    # Application
    PROJECT_NAME: str = "My API"
    VERSION: str = "1.0.0"
    DESCRIPTION: str = "FastAPI application"
    DEBUG: bool = Field(default=False, env="DEBUG")
    
    # Security
    SECRET_KEY: str = Field(default_factory=lambda: secrets.token_urlsafe(32))
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    BCRYPT_ROUNDS: int = 12
    
    # Database
    DATABASE_URL: str = Field(..., env="DATABASE_URL")
    DATABASE_POOL_SIZE: int = 5
    DATABASE_MAX_OVERFLOW: int = 10
    
    # Redis
    REDIS_URL: str = Field(default="redis://localhost:6379", env="REDIS_URL")
    
    # CORS
    ALLOWED_ORIGINS: List[str] = Field(
        default=["http://localhost:3000"],
        env="ALLOWED_ORIGINS"
    )
    
    # Email
    SMTP_HOST: Optional[str] = Field(None, env="SMTP_HOST")
    SMTP_PORT: int = Field(587, env="SMTP_PORT")
    SMTP_USER: Optional[str] = Field(None, env="SMTP_USER")
    SMTP_PASSWORD: Optional[str] = Field(None, env="SMTP_PASSWORD")
    EMAIL_FROM: str = Field("noreply@example.com", env="EMAIL_FROM")
    
    # AWS
    AWS_ACCESS_KEY_ID: Optional[str] = Field(None, env="AWS_ACCESS_KEY_ID")
    AWS_SECRET_ACCESS_KEY: Optional[str] = Field(None, env="AWS_SECRET_ACCESS_KEY")
    AWS_REGION: str = Field("us-east-1", env="AWS_REGION")
    S3_BUCKET: Optional[str] = Field(None, env="S3_BUCKET")
    
    @validator("ALLOWED_ORIGINS", pre=True)
    def parse_origins(cls, v):
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(",")]
        return v
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        
        # Allow extra fields for forward compatibility
        extra = "allow"


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()


settings = get_settings()
```

### 3. SQLAlchemy Models with Async

```python
# models/base.py
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column, DateTime, Integer
from sqlalchemy.sql import func
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
import uuid

Base = declarative_base()


class BaseModel(Base):
    """Base model with common fields."""
    
    __abstract__ = True
    
    id = Column(Integer, primary_key=True, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )


# models/user.py
from sqlalchemy import Column, String, Boolean, Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import enum
import uuid

from .base import BaseModel


class UserRole(str, enum.Enum):
    """User role enumeration."""
    ADMIN = "admin"
    USER = "user"
    MODERATOR = "moderator"


class User(BaseModel):
    """User model."""
    
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100))
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    role = Column(SQLEnum(UserRole), default=UserRole.USER)
    
    # Relationships
    posts = relationship("Post", back_populates="author", cascade="all, delete-orphan")
    refresh_tokens = relationship("RefreshToken", back_populates="user", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<User(id={self.id}, email={self.email})>"
    
    def to_dict(self):
        """Convert model to dictionary."""
        return {
            "id": str(self.id),
            "email": self.email,
            "username": self.username,
            "full_name": self.full_name,
            "is_active": self.is_active,
            "is_verified": self.is_verified,
            "role": self.role.value if self.role else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }
```

### 4. Repository Pattern

```python
# repositories/base.py
from typing import Generic, TypeVar, Type, Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from sqlalchemy.sql import func

from src.models.base import Base

ModelType = TypeVar("ModelType", bound=Base)


class BaseRepository(Generic[ModelType]):
    """Base repository with CRUD operations."""
    
    def __init__(self, model: Type[ModelType], session: AsyncSession):
        self.model = model
        self.session = session
    
    async def create(self, **kwargs) -> ModelType:
        """Create a new record."""
        instance = self.model(**kwargs)
        self.session.add(instance)
        await self.session.commit()
        await self.session.refresh(instance)
        return instance
    
    async def get(self, id: Any) -> Optional[ModelType]:
        """Get a record by ID."""
        query = select(self.model).where(self.model.id == id)
        result = await self.session.execute(query)
        return result.scalar_one_or_none()
    
    async def get_by(self, **kwargs) -> Optional[ModelType]:
        """Get a record by field values."""
        query = select(self.model).filter_by(**kwargs)
        result = await self.session.execute(query)
        return result.scalar_one_or_none()
    
    async def get_all(
        self,
        skip: int = 0,
        limit: int = 100,
        **filters
    ) -> List[ModelType]:
        """Get all records with pagination."""
        query = select(self.model).filter_by(**filters).offset(skip).limit(limit)
        result = await self.session.execute(query)
        return result.scalars().all()
    
    async def update(self, id: Any, **kwargs) -> Optional[ModelType]:
        """Update a record."""
        query = (
            update(self.model)
            .where(self.model.id == id)
            .values(**kwargs)
            .returning(self.model)
        )
        result = await self.session.execute(query)
        await self.session.commit()
        return result.scalar_one_or_none()
    
    async def delete(self, id: Any) -> bool:
        """Delete a record."""
        query = delete(self.model).where(self.model.id == id)
        result = await self.session.execute(query)
        await self.session.commit()
        return result.rowcount > 0
    
    async def count(self, **filters) -> int:
        """Count records."""
        query = select(func.count()).select_from(self.model).filter_by(**filters)
        result = await self.session.execute(query)
        return result.scalar()


# repositories/user_repository.py
from typing import Optional, List
from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.user import User
from .base import BaseRepository


class UserRepository(BaseRepository[User]):
    """User repository with custom methods."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(User, session)
    
    async def get_by_email(self, email: str) -> Optional[User]:
        """Get user by email."""
        return await self.get_by(email=email)
    
    async def get_by_username(self, username: str) -> Optional[User]:
        """Get user by username."""
        return await self.get_by(username=username)
    
    async def search(
        self,
        query: str,
        skip: int = 0,
        limit: int = 100
    ) -> List[User]:
        """Search users by email or username."""
        search_query = select(User).where(
            or_(
                User.email.ilike(f"%{query}%"),
                User.username.ilike(f"%{query}%"),
                User.full_name.ilike(f"%{query}%")
            )
        ).offset(skip).limit(limit)
        
        result = await self.session.execute(search_query)
        return result.scalars().all()
    
    async def get_active_users(
        self,
        skip: int = 0,
        limit: int = 100
    ) -> List[User]:
        """Get active users."""
        return await self.get_all(skip=skip, limit=limit, is_active=True)
```

### 5. Service Layer

```python
# services/auth_service.py
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import jwt
from passlib.context import CryptContext
from fastapi import HTTPException, status

from src.core.config import settings
from src.models.user import User
from src.repositories.user_repository import UserRepository
from src.schemas.auth import TokenData, UserCreate, UserLogin


class AuthService:
    """Authentication service."""
    
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
    
    def __init__(self, user_repository: UserRepository):
        self.user_repository = user_repository
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """Verify password against hash."""
        return self.pwd_context.verify(plain_password, hashed_password)
    
    def hash_password(self, password: str) -> str:
        """Hash password."""
        return self.pwd_context.hash(password)
    
    def create_access_token(self, data: Dict[str, Any]) -> str:
        """Create JWT access token."""
        to_encode = data.copy()
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode.update({"exp": expire, "type": "access"})
        
        encoded_jwt = jwt.encode(
            to_encode,
            settings.SECRET_KEY,
            algorithm=settings.ALGORITHM
        )
        return encoded_jwt
    
    def create_refresh_token(self, data: Dict[str, Any]) -> str:
        """Create JWT refresh token."""
        to_encode = data.copy()
        expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
        to_encode.update({"exp": expire, "type": "refresh"})
        
        encoded_jwt = jwt.encode(
            to_encode,
            settings.SECRET_KEY,
            algorithm=settings.ALGORITHM
        )
        return encoded_jwt
    
    def decode_token(self, token: str) -> TokenData:
        """Decode and validate JWT token."""
        try:
            payload = jwt.decode(
                token,
                settings.SECRET_KEY,
                algorithms=[settings.ALGORITHM]
            )
            user_id: str = payload.get("sub")
            if user_id is None:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token"
                )
            return TokenData(user_id=user_id)
        except jwt.ExpiredSignatureError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has expired"
            )
        except jwt.JWTError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
    
    async def register(self, user_data: UserCreate) -> User:
        """Register a new user."""
        # Check if user exists
        existing_user = await self.user_repository.get_by_email(user_data.email)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        
        existing_username = await self.user_repository.get_by_username(user_data.username)
        if existing_username:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already taken"
            )
        
        # Create user
        hashed_password = self.hash_password(user_data.password)
        user = await self.user_repository.create(
            email=user_data.email,
            username=user_data.username,
            hashed_password=hashed_password,
            full_name=user_data.full_name
        )
        
        return user
    
    async def authenticate(self, credentials: UserLogin) -> Optional[User]:
        """Authenticate user."""
        user = await self.user_repository.get_by_email(credentials.email)
        
        if not user:
            return None
        
        if not self.verify_password(credentials.password, user.hashed_password):
            return None
        
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User account is inactive"
            )
        
        return user
```

### 6. API Routes with Dependency Injection

```python
# api/routes/auth.py
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_session
from src.services.auth_service import AuthService
from src.repositories.user_repository import UserRepository
from src.schemas.auth import Token, UserCreate, UserResponse
from src.models.user import User

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/token")


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    session: AsyncSession = Depends(get_session)
) -> User:
    """Get current authenticated user."""
    auth_service = AuthService(UserRepository(session))
    token_data = auth_service.decode_token(token)
    
    user = await UserRepository(session).get(token_data.user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    
    return user


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserCreate,
    session: AsyncSession = Depends(get_session)
):
    """Register a new user."""
    auth_service = AuthService(UserRepository(session))
    user = await auth_service.register(user_data)
    return UserResponse.from_orm(user)


@router.post("/token", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    session: AsyncSession = Depends(get_session)
):
    """Login and get access token."""
    auth_service = AuthService(UserRepository(session))
    
    user = await auth_service.authenticate(
        UserLogin(email=form_data.username, password=form_data.password)
    )
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = auth_service.create_access_token(
        data={"sub": str(user.id), "email": user.email}
    )
    refresh_token = auth_service.create_refresh_token(
        data={"sub": str(user.id)}
    )
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    """Get current user information."""
    return UserResponse.from_orm(current_user)
```

### 7. Celery for Background Tasks

```python
# tasks/celery_app.py
from celery import Celery
from src.core.config import settings

celery_app = Celery(
    "tasks",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
    include=["src.tasks.email", "src.tasks.notifications"]
)

# Celery configuration
celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_time_limit=30 * 60,  # 30 minutes
    task_soft_time_limit=25 * 60,  # 25 minutes
    worker_prefetch_multiplier=1,
    worker_max_tasks_per_child=1000,
)

# Beat schedule for periodic tasks
celery_app.conf.beat_schedule = {
    "cleanup-expired-tokens": {
        "task": "src.tasks.auth.cleanup_expired_tokens",
        "schedule": 3600.0,  # Every hour
    },
    "send-daily-report": {
        "task": "src.tasks.reports.send_daily_report",
        "schedule": crontab(hour=9, minute=0),  # Daily at 9 AM
    },
}

# tasks/email.py
from celery import shared_task
from src.services.email_service import EmailService

@shared_task(bind=True, max_retries=3)
def send_email_task(self, to_email: str, subject: str, body: str):
    """Send email asynchronously."""
    try:
        email_service = EmailService()
        email_service.send_email(to_email, subject, body)
        return f"Email sent to {to_email}"
    except Exception as exc:
        # Retry with exponential backoff
        raise self.retry(exc=exc, countdown=2 ** self.request.retries)

@shared_task
def send_welcome_email(user_id: str):
    """Send welcome email to new user."""
    # Get user from database
    # Send email
    pass
```

### 8. Testing

```python
# tests/conftest.py
import pytest
import asyncio
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from httpx import AsyncClient

from src.main import app
from src.core.database import Base, get_session
from src.core.config import settings

# Test database URL
TEST_DATABASE_URL = "sqlite+aiosqlite:///./test.db"

@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for async tests."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope="session")
async def engine():
    """Create test database engine."""
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()

@pytest.fixture
async def session(engine) -> AsyncGenerator[AsyncSession, None]:
    """Create test database session."""
    async_session = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )
    async with async_session() as session:
        yield session

@pytest.fixture
async def client(session) -> AsyncGenerator[AsyncClient, None]:
    """Create test client."""
    def override_get_session():
        return session
    
    app.dependency_overrides[get_session] = override_get_session
    
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client
    
    app.dependency_overrides.clear()

# tests/unit/test_auth_service.py
import pytest
from src.services.auth_service import AuthService
from src.schemas.auth import UserCreate

@pytest.mark.asyncio
async def test_register_user(session):
    """Test user registration."""
    auth_service = AuthService(UserRepository(session))
    
    user_data = UserCreate(
        email="test@example.com",
        username="testuser",
        password="Test@123",
        full_name="Test User"
    )
    
    user = await auth_service.register(user_data)
    
    assert user.email == "test@example.com"
    assert user.username == "testuser"
    assert auth_service.verify_password("Test@123", user.hashed_password)

@pytest.mark.asyncio
async def test_authenticate_user(session):
    """Test user authentication."""
    auth_service = AuthService(UserRepository(session))
    
    # Register user first
    user_data = UserCreate(
        email="auth@example.com",
        username="authuser",
        password="Auth@123",
        full_name="Auth User"
    )
    await auth_service.register(user_data)
    
    # Test authentication
    credentials = UserLogin(
        email="auth@example.com",
        password="Auth@123"
    )
    
    user = await auth_service.authenticate(credentials)
    assert user is not None
    assert user.email == "auth@example.com"

# tests/integration/test_auth_endpoints.py
@pytest.mark.asyncio
async def test_register_endpoint(client):
    """Test registration endpoint."""
    response = await client.post(
        "/api/auth/register",
        json={
            "email": "newuser@example.com",
            "username": "newuser",
            "password": "New@123",
            "full_name": "New User"
        }
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "newuser@example.com"
    assert "id" in data

@pytest.mark.asyncio
async def test_login_endpoint(client):
    """Test login endpoint."""
    # Register user first
    await client.post(
        "/api/auth/register",
        json={
            "email": "login@example.com",
            "username": "loginuser",
            "password": "Login@123",
            "full_name": "Login User"
        }
    )
    
    # Test login
    response = await client.post(
        "/api/auth/token",
        data={
            "username": "login@example.com",
            "password": "Login@123"
        }
    )
    
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"
```

### Common Pitfalls to Avoid

1. **Not using virtual environments**
2. **Ignoring PEP 8 style guide**
3. **Not handling exceptions properly**
4. **Using mutable default arguments**
5. **Not using type hints**
6. **Blocking async functions with sync code**
7. **Not using context managers**
8. **Global state mutations**
9. **Not writing tests**
10. **Hardcoding configuration values**

### Useful Libraries

- **FastAPI**: Modern web framework
- **Django**: Full-featured web framework
- **Flask**: Lightweight web framework
- **SQLAlchemy**: ORM
- **Pydantic**: Data validation
- **Celery**: Task queue
- **Redis**: Caching
- **pytest**: Testing framework
- **Black**: Code formatter
- **Ruff**: Linter
- **Poetry**: Dependency management
- **httpx**: Async HTTP client