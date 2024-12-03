# Ultimate Golang Makefile

A comprehensive, production-ready Makefile system for Go projects of any size. This Makefile provides a complete set of commands for development, testing, building, and deployment workflows while remaining flexible and customizable.

## 🚀 Features

- **Flexible Configuration**: Support for environment variables, .env files, and command-line overrides
- **Multi-Environment Support**: Development, staging, and production builds
- **Cross-Platform Building**: Support for multiple OS/Architecture combinations
- **Advanced Testing**: Unit, integration, and end-to-end testing with coverage reports
- **Docker Integration**: Build, push, and run Docker containers
- **Database Operations**: Migration management and database utilities
- **Development Tools**: Hot reload, formatting, linting, and security scanning
- **CI/CD Ready**: Integrated pipeline support for common CI systems
- **Documentation**: Automatic API documentation generation
- **Monorepo Support**: Build and manage multiple services
- **Comprehensive Reporting**: Test coverage, benchmarks, and security reports

## 📋 Prerequisites

- Go 1.21 or higher
- Make
- Docker (optional)
- Git

## 🛠 Installation

1. Copy the Makefile to your project root:
```bash
curl -O https://raw.githubusercontent.com/crazywolf132/ultimate-gomake/main/Makefile
```

2. Initialize your project:
```bash
make init
```

This will:
- Create necessary directories
- Initialize Go modules
- Install required tools
- Create default configuration files

## ⚙️ Configuration

### Environment Variables

Create a `.env` file in your project root to override default settings:

```env
# Project Configuration
PROJECT_NAME=myapp
ORGANIZATION=myorg
ENABLE_DOCKER=true
ENABLE_PROTO=false

# Build Settings
CGO_ENABLED=0
COVERAGE_THRESHOLD=80

# Docker Settings
DOCKER_REGISTRY=docker.io
DOCKER_REPO=myorg/myapp
```

### Project Structure

The Makefile assumes the following project structure:
```
.
├── cmd/
│   └── myapp/
│       └── main.go
├── pkg/
├── internal/
├── api/
├── docs/
├── scripts/
├── build/
├── configs/
├── test/
│   ├── e2e/
│   └── integration/
└── Makefile
```

## 🎯 Common Commands

### Development

```bash
# Start development with hot reload
make dev

# Run tests
make test

# Run tests with coverage
make test-coverage

# Format and lint code
make fmt lint

# Generate mocks and protobuf
make generate
```

### Building

```bash
# Build for current platform
make build

# Build for all platforms
make build-all

# Build with debug symbols
make build-debug

# Build with race detector
make build-race
```

### Docker Operations

```bash
# Build Docker image
make docker-build

# Push Docker image
make docker-push

# Run in Docker container
make docker-run
```

### Database Operations

```bash
# Run migrations
make db-migrate

# Rollback last migration
make db-rollback

# Reset database
make db-reset
```

### Maintenance

```bash
# Install/update dependencies
make deps
make deps-update

# Clean build artifacts
make clean

# Update tools
make tools
```

## 🏗️ Project Types

### Basic Project

For single-service projects, use default settings:

```env
PROJECT_TYPE=basic
```

### Monorepo

For multiple services, configure as follows:

```env
PROJECT_TYPE=monorepo
MONOREPO_SERVICES=service1 service2 service3
```

Directory structure for monorepo:
```
.
├── services/
│   ├── service1/
│   │   └── cmd/
│   ├── service2/
│   │   └── cmd/
│   └── service3/
│       └── cmd/
└── Makefile
```

## 📊 Reports

Generate comprehensive project reports:

```bash
make report
```

This creates:
- Test coverage reports
- Benchmark results
- Linting reports
- Security scan results

Reports are saved in `docs/reports/`.

## 🔄 CI/CD Integration

The Makefile includes predefined CI/CD targets:

```bash
# Run CI pipeline
make ci

# Run CD pipeline
make cd
```

Customize pipelines by modifying these targets in the Makefile.

## 📚 Documentation

```bash
# Generate documentation
make docs

# Serve documentation locally
make serve-docs
```

## 🎨 Customization

### Adding New Targets

Add custom targets at the end of the Makefile:

```makefile
.PHONY: custom-target
custom-target: ## Custom target description
    @echo "Running custom target..."
    @# Custom commands here
```

### Modifying Existing Targets

Override existing targets by redefining them in `config.mk`:

```makefile
# config.mk
.PHONY: test
test: ## Custom test implementation
    @echo "Running custom tests..."
    @# Custom test commands
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgements

Special thanks to the Go community and all contributors who have helped shape this Makefile system.
