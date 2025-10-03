#!/usr/bin/env bash

# Python, FastAPI, and Django Setup Script
# Installs Python via pyenv and sets up modern Python development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_VERSION=$(cat "$SCRIPT_DIR/.python-version")

echo -e "${GREEN}=== Python, FastAPI, and Django Setup ===${NC}"
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${RED}Error: Homebrew is not installed${NC}"
    echo "Please install Homebrew first: https://brew.sh"
    exit 1
fi

echo -e "${YELLOW}Installing dependencies via Homebrew...${NC}"
cd "$SCRIPT_DIR/.." && brew bundle --file=Brewfile

# Initialize pyenv if not already in PATH
if ! command -v pyenv &> /dev/null; then
    echo -e "${RED}Error: pyenv not found in PATH${NC}"
    echo "Please restart your shell or run: eval \"\$(pyenv init --path)\" && eval \"\$(pyenv init -)\""
    exit 1
fi

# Check if pyenv is initialized
if ! pyenv version &> /dev/null; then
    echo -e "${YELLOW}Initializing pyenv...${NC}"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

echo ""
echo -e "${YELLOW}Installing Python ${PYTHON_VERSION}...${NC}"

# Check if Python version is already installed
if pyenv versions | grep -q "$PYTHON_VERSION"; then
    echo -e "${GREEN}Python ${PYTHON_VERSION} is already installed${NC}"
else
    # Install Python
    pyenv install "$PYTHON_VERSION"
    echo -e "${GREEN}Python ${PYTHON_VERSION} installed successfully${NC}"
fi

# Set global Python version
echo -e "${YELLOW}Setting global Python version to ${PYTHON_VERSION}...${NC}"
pyenv global "$PYTHON_VERSION"
pyenv rehash

# Verify Python installation
CURRENT_PYTHON=$(python --version)
echo -e "${GREEN}Active Python version: ${CURRENT_PYTHON}${NC}"

# Update pip
echo ""
echo -e "${YELLOW}Updating pip...${NC}"
python -m pip install --upgrade pip

# Install essential development tools
echo ""
echo -e "${YELLOW}Installing essential Python development tools...${NC}"
pip install --upgrade setuptools wheel

# Install FastAPI and dependencies
echo ""
echo -e "${YELLOW}Installing FastAPI and dependencies...${NC}"
pip install fastapi uvicorn[standard]
pip install python-multipart  # For form data and file uploads
pip install python-jose[cryptography]  # For JWT tokens
pip install passlib[bcrypt]  # For password hashing
pip install httpx  # For async HTTP requests
pip install pytest pytest-asyncio httpx  # For testing

# Install Django and common dependencies
echo ""
echo -e "${YELLOW}Installing Django and dependencies...${NC}"
pip install django
pip install djangorestframework  # For building APIs
pip install django-cors-headers  # For CORS support
pip install django-environ  # For environment variables
pip install psycopg2-binary  # PostgreSQL adapter
pip install pillow  # For image handling
pip install celery[redis]  # For background tasks

# Install common Python tools
echo ""
echo -e "${YELLOW}Installing common Python development tools...${NC}"
pip install black  # Code formatter
pip install flake8  # Linter
pip install mypy  # Type checker
pip install pylint  # Code analyzer
pip install ipython  # Enhanced Python shell
pip install poetry  # Dependency management

# Verify installations
FASTAPI_VERSION=$(python -c "import fastapi; print(fastapi.__version__)" 2>/dev/null || echo "not found")
DJANGO_VERSION=$(python -c "import django; print(django.get_version())" 2>/dev/null || echo "not found")
PIP_VERSION=$(pip --version | awk '{print $2}')

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo -e "Python:   ${GREEN}${CURRENT_PYTHON}${NC}"
echo -e "pip:      ${GREEN}${PIP_VERSION}${NC}"
echo -e "FastAPI:  ${GREEN}${FASTAPI_VERSION}${NC}"
echo -e "Django:   ${GREEN}${DJANGO_VERSION}${NC}"
echo ""
echo -e "${YELLOW}To verify pyenv is working correctly:${NC}"
echo -e "  which python    # Should show: $HOME/.pyenv/shims/python"
echo -e "  python --version"
echo ""
echo -e "${YELLOW}To create a new FastAPI project:${NC}"
echo -e "  mkdir myapi && cd myapi"
echo -e "  python -m venv venv"
echo -e "  source venv/bin/activate"
echo -e "  pip install fastapi uvicorn[standard]"
echo -e "  # Create main.py with your FastAPI app"
echo -e "  uvicorn main:app --reload"
echo ""
echo -e "${YELLOW}To create a new Django project:${NC}"
echo -e "  django-admin startproject myproject"
echo -e "  cd myproject"
echo -e "  python manage.py migrate"
echo -e "  python manage.py runserver"
echo ""
echo -e "${YELLOW}Using virtual environments (recommended):${NC}"
echo -e "  python -m venv venv          # Create virtual environment"
echo -e "  source venv/bin/activate     # Activate (macOS/Linux)"
echo -e "  pip install -r requirements.txt  # Install dependencies"
echo -e "  deactivate                   # Deactivate when done"
echo ""
echo -e "${YELLOW}Using Poetry for dependency management:${NC}"
echo -e "  poetry new myproject         # Create new project"
echo -e "  poetry add fastapi uvicorn   # Add dependencies"
echo -e "  poetry install               # Install dependencies"
echo -e "  poetry shell                 # Activate virtual environment"
echo ""
echo -e "${GREEN}Setup complete! Happy coding!${NC}"
