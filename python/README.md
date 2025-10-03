# Python, FastAPI, and Django Development Setup

Complete guide for setting up Python development environment using pyenv for version management with FastAPI and Django frameworks.

## Quick Start

```bash
# Run automated setup
cd ~/dotfiles
./python/setup.sh

# Verify installation
python --version
pip --version
python -c "import fastapi; print(fastapi.__version__)"
python -c "import django; print(django.get_version())"
```

## Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [FastAPI Development](#fastapi-development)
- [Django Development](#django-development)
- [Virtual Environments](#virtual-environments)
- [Troubleshooting](#troubleshooting)
- [Upgrading](#upgrading)
- [Uninstallation](#uninstallation)

## Prerequisites

### System Requirements

- macOS (10.15 or later)
- Homebrew installed
- Xcode Command Line Tools

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Verify Homebrew
brew --version
```

### Required Dependencies

All dependencies are installed automatically via `setup.sh`, but you can install them manually:

```bash
cd ~/dotfiles
brew bundle --file=Brewfile
```

Dependencies include:
- **pyenv** - Python version manager
- **python@3.12** - System Python fallback

## Installation

### Automated Installation (Recommended)

```bash
cd ~/dotfiles
./python/setup.sh
```

The setup script will:
1. Install all required dependencies via Homebrew
2. Configure pyenv in your shell
3. Install Python 3.12.8 (latest stable)
4. Update pip to latest version
5. Install FastAPI with uvicorn server
6. Install Django with common dependencies
7. Install development tools (black, flake8, mypy, poetry)

### Manual Installation

If you prefer manual installation:

```bash
# 1. Install pyenv
brew install pyenv

# 2. Initialize pyenv in your shell
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init --path)"' >> ~/.zshrc
echo 'eval "$(pyenv init -)"' >> ~/.zshrc
source ~/.zshrc

# 3. Install Python
pyenv install 3.12.8

# 4. Set global Python version
pyenv global 3.12.8
pyenv rehash

# 5. Update pip
python -m pip install --upgrade pip

# 6. Install FastAPI and Django
pip install fastapi uvicorn[standard]
pip install django djangorestframework
```

## Configuration

### Shell Integration

pyenv initialization is automatically added to `.zshrc` during setup:

```bash
# pyenv initialization
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
```

If using a different shell (bash):

```bash
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
source ~/.bashrc
```

### Python Version

The default Python version is specified in `.python-version`:

```
3.12.8
```

This file ensures consistent Python versions across your development environment.

## Usage

### pyenv Commands

```bash
# List available Python versions
pyenv install --list

# Install a specific Python version
pyenv install 3.11.0

# List installed versions
pyenv versions

# Set global Python version
pyenv global 3.12.8

# Set local (project-specific) Python version
pyenv local 3.11.0

# Display current Python version
pyenv version

# Uninstall a Python version
pyenv uninstall 3.10.0
```

### pip Management

```bash
# Update pip
python -m pip install --upgrade pip

# Install a package
pip install package_name

# Install from requirements.txt
pip install -r requirements.txt

# List installed packages
pip list

# Show package info
pip show package_name

# Uninstall a package
pip uninstall package_name

# Generate requirements.txt
pip freeze > requirements.txt
```

## FastAPI Development

### Creating a New FastAPI Project

```bash
# Create project directory
mkdir myapi && cd myapi

# Set project-specific Python version (optional)
echo "3.12.8" > .python-version

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install FastAPI and dependencies
pip install fastapi uvicorn[standard]
pip install python-multipart  # For forms and file uploads
pip install sqlalchemy  # For database ORM
pip install pydantic-settings  # For configuration
```

### Basic FastAPI Application

Create `main.py`:

```python
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="My API", version="1.0.0")

class Item(BaseModel):
    name: str
    description: str | None = None
    price: float

@app.get("/")
async def root():
    return {"message": "Hello World"}

@app.get("/items/{item_id}")
async def read_item(item_id: int):
    return {"item_id": item_id}

@app.post("/items/")
async def create_item(item: Item):
    return {"item": item}
```

### Running FastAPI

```bash
# Development mode with auto-reload
uvicorn main:app --reload

# Production mode
uvicorn main:app --host 0.0.0.0 --port 8000

# With workers (production)
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

### FastAPI Project Structure

```
myapi/
├── .python-version
├── venv/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── models/
│   │   └── __init__.py
│   ├── routers/
│   │   └── __init__.py
│   ├── schemas/
│   │   └── __init__.py
│   └── database.py
├── tests/
│   └── test_main.py
├── requirements.txt
└── README.md
```

### Sample requirements.txt (FastAPI)

```
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
pydantic-settings==2.1.0
sqlalchemy==2.0.23
alembic==1.13.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
httpx==0.25.2
pytest==7.4.3
pytest-asyncio==0.21.1
```

## Django Development

### Creating a New Django Project

```bash
# Create project directory
mkdir myproject && cd myproject

# Set project-specific Python version (optional)
echo "3.12.8" > .python-version

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install Django and dependencies
pip install django djangorestframework
pip install django-environ  # For environment variables
pip install django-cors-headers  # For CORS
pip install psycopg2-binary  # For PostgreSQL
```

### Create Django Project

```bash
# Create project
django-admin startproject myproject .

# Create app
python manage.py startapp myapp

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Run development server
python manage.py runserver
```

### Django Project Structure

```
myproject/
├── .python-version
├── venv/
├── manage.py
├── myproject/
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   ├── asgi.py
│   └── wsgi.py
├── myapp/
│   ├── __init__.py
│   ├── models.py
│   ├── views.py
│   ├── urls.py
│   ├── admin.py
│   ├── apps.py
│   ├── tests.py
│   └── migrations/
├── templates/
├── static/
├── requirements.txt
└── README.md
```

### Sample requirements.txt (Django)

```
Django==5.0.0
djangorestframework==3.14.0
django-cors-headers==4.3.1
django-environ==0.11.2
psycopg2-binary==2.9.9
pillow==10.1.0
celery[redis]==5.3.4
gunicorn==21.2.0
whitenoise==6.6.0
```

### Django REST API Example

```python
# models.py
from django.db import models

class Task(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    completed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

# serializers.py
from rest_framework import serializers
from .models import Task

class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = '__all__'

# views.py
from rest_framework import viewsets
from .models import Task
from .serializers import TaskSerializer

class TaskViewSet(viewsets.ModelViewSet):
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
```

## Virtual Environments

### Using venv (Built-in)

```bash
# Create virtual environment
python -m venv venv

# Activate (macOS/Linux)
source venv/bin/activate

# Activate (Windows)
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Deactivate
deactivate
```

### Using Poetry (Modern)

```bash
# Install Poetry (if not already installed)
curl -sSL https://install.python-poetry.org | python3 -

# Create new project
poetry new myproject
cd myproject

# Add dependencies
poetry add fastapi uvicorn

# Add dev dependencies
poetry add --group dev pytest black flake8

# Install dependencies
poetry install

# Activate virtual environment
poetry shell

# Run commands
poetry run python main.py
poetry run pytest
```

### Sample pyproject.toml (Poetry)

```toml
[tool.poetry]
name = "myproject"
version = "0.1.0"
description = "My FastAPI project"
authors = ["Your Name <you@example.com>"]

[tool.poetry.dependencies]
python = "^3.12"
fastapi = "^0.104.1"
uvicorn = {extras = ["standard"], version = "^0.24.0"}
sqlalchemy = "^2.0.23"

[tool.poetry.group.dev.dependencies]
pytest = "^7.4.3"
black = "^23.12.0"
flake8 = "^6.1.0"
mypy = "^1.7.1"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

## Troubleshooting

### Python Command Not Found

```bash
# Solution: Ensure pyenv is initialized
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# Verify Python is in PATH
which python  # Should show: ~/.pyenv/shims/python
```

### Wrong Python Version Active

```bash
# Check current version
pyenv version

# Check .python-version file
cat .python-version

# Re-enter directory to activate
cd .
```

### pip Installation Fails

```bash
# Update pip
python -m pip install --upgrade pip

# Install with verbose output
pip install package_name --verbose

# Clear pip cache
pip cache purge
```

### Virtual Environment Issues

```bash
# Recreate virtual environment
rm -rf venv
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### pyenv Build Failures

```bash
# Install build dependencies
brew install openssl readline sqlite3 xz zlib

# Reinstall Python with proper flags
CFLAGS="-I$(brew --prefix openssl)/include" \
LDFLAGS="-L$(brew --prefix openssl)/lib" \
pyenv install 3.12.8
```

## Upgrading

### Upgrading Python

```bash
# List available versions
pyenv install --list

# Install new version
pyenv install 3.12.9

# Set as global version
pyenv global 3.12.9
pyenv rehash

# Update project .python-version
echo "3.12.9" > ~/dotfiles/python/.python-version
```

### Upgrading FastAPI/Django

```bash
# Update specific package
pip install --upgrade fastapi
pip install --upgrade django

# Update all packages
pip list --outdated
pip install --upgrade package_name

# Update using Poetry
poetry update fastapi
poetry update
```

### Upgrading pip

```bash
# Update pip itself
python -m pip install --upgrade pip

# Verify new version
pip --version
```

## Uninstallation

### Remove Python Version

```bash
# Uninstall specific Python version
pyenv uninstall 3.11.0

# List installed versions
pyenv versions
```

### Complete Removal

```bash
# Remove all Python versions
rm -rf ~/.pyenv

# Remove from shell configuration
# Edit ~/.zshrc and remove pyenv initialization lines

# Remove Homebrew packages
brew uninstall pyenv
```

## Verification

### Health Check Commands

```bash
# Verify pyenv installation
pyenv --version

# Verify Python installation
python --version

# Check Python path (should be pyenv shim)
which python

# Verify FastAPI
python -c "import fastapi; print(fastapi.__version__)"

# Verify Django
python -c "import django; print(django.get_version())"

# Check pip environment
pip --version

# List installed packages
pip list
```

### Expected Output

```bash
$ python --version
Python 3.12.8

$ which python
/Users/username/.pyenv/shims/python

$ python -c "import fastapi; print(fastapi.__version__)"
0.104.1

$ python -c "import django; print(django.get_version())"
5.0
```

## Best Practices

### Version Management

- Use `.python-version` in all projects for consistency
- Keep global Python version updated to latest stable
- Test applications against multiple Python versions before upgrading
- Use virtual environments for all projects

### Dependency Management

- Always use `requirements.txt` or `pyproject.toml` in projects
- Pin major versions for production (e.g., `django>=4.2,<5.0`)
- Commit `requirements.txt` or `poetry.lock` to version control
- Separate dev dependencies from production dependencies

### Project Structure

- Use virtual environments (venv or Poetry)
- Follow framework conventions (FastAPI app structure, Django apps)
- Keep `requirements.txt` or `pyproject.toml` updated
- Use environment variables for configuration (django-environ, pydantic-settings)

### Performance

- Use `uvicorn` with workers for production FastAPI apps
- Use `gunicorn` for production Django apps
- Enable caching for API responses
- Use async/await in FastAPI for concurrent operations

### Security

- Keep Python and dependencies updated for security patches
- Use virtual environments to isolate dependencies
- Validate input with Pydantic (FastAPI) or serializers (Django)
- Use environment variables for secrets
- Run security audits: `pip-audit` or `safety check`

### Testing

- Write tests with pytest
- Use `pytest-asyncio` for async FastAPI tests
- Use Django's test framework for Django projects
- Maintain test coverage above 80%

## Additional Resources

- **Python Official Site**: https://www.python.org
- **FastAPI Documentation**: https://fastapi.tiangolo.com
- **Django Documentation**: https://docs.djangoproject.com
- **pyenv Documentation**: https://github.com/pyenv/pyenv
- **Poetry Documentation**: https://python-poetry.org

## Support

If you encounter issues not covered in this guide:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review pyenv documentation: https://github.com/pyenv/pyenv
3. Search FastAPI issues: https://github.com/tiangolo/fastapi/issues
4. Search Django issues: https://code.djangoproject.com/
5. Check Python version compatibility: https://www.python.org/downloads/

---

**Maintained by**: Dotfiles Repository
**Last Updated**: 2025-10-04
**Python Version**: 3.12.8
**FastAPI Version**: 0.104.x
**Django Version**: 5.0.x
