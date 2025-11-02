#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install .NET SDK
if command_exists dotnet; then
    echo "Installing .NET Dev Certs..."
    dotnet dev-certs https --trust
else
    echo ".NET SDK is not installed. Cannot install dev certs"
fi
