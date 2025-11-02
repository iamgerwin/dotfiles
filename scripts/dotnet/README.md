# .NET Development Setup

This document provides instructions for setting up the .NET development environment.

## Installation

To install the .NET SDK, run the following command:

```bash
~/dotfiles/scripts/dotnet/install.sh
```

This will install the latest version of the .NET SDK (currently 8.0).

### Development Certificates

To install and trust development certificates for HTTPS, run the following command:

```bash
~/dotfiles/scripts/dotnet/dev-certs.sh
```

## Configuration

The shell environment is configured automatically by sourcing `~/dotfiles/shell/dotnet.zsh` from `~/.zprofile`. This sets the `DOTNET_ROOT` and adds the .NET tools to the `PATH`.
