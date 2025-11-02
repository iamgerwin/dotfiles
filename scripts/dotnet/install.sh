#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install .NET SDK
if ! command_exists dotnet; then
    echo "Installing .NET SDK..."
    # Download the install script
    curl -L https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh

    # Run the install script
    chmod +x dotnet-install.sh
    ./dotnet-install.sh --channel 8.0

    # Clean up the install script
    rm dotnet-install.sh
else
    echo ".NET SDK is already installed."
fi
