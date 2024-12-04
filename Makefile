# =============================================================================
# 📚 Documentation
# =============================================================================
# This Makefile is designed to support Go projects of any size, from small
# personal projects to large enterprise applications. It provides a comprehensive
# set of targets for development, testing, building, and deployment.
#
# Quick Start:
# 1. Copy this Makefile to your project
# 2. Create a .env file for local overrides (optional)
# 3. Run `make init` to initialize the project
# 4. Run `make help` to see available commands
#
# Configuration:
# The Makefile can be configured in several ways (in order of precedence):
# 1. Command line variables: make build GOOS=darwin
# 2. Environment variables: export GOOS=darwin
# 3. .env file in project root
# 4. Default values in this Makefile
#
# For large projects:
# - Create a config/ directory with environment-specific configs
# - Use config.mk files for project-specific settings
# - Enable build caching and parallel builds
# - Set up CI/CD pipeline configurations
#
# For small projects:
# - Use default configurations
# - Disable unused features in .env file
# - Focus on core development commands

# =============================================================================
# 🔄 Load Environment & Configs
# =============================================================================
# Load .env file if it exists
ifneq (,$(wildcard .env))
    include .env
    # Only export specific variables that need to be in the environment
    export GOOS
    export GOARCH
    export CGO_ENABLED
    export PROJECT_NAME
    export ORGANIZATION
    export DATABASE_URL
    # Add other variables that actually need to be in the environment
endif

# Load project-specific config if it exists
ifneq (,$(wildcard config.mk))
    include config.mk
endif

# =============================================================================
# 🎯 Project Configuration
# =============================================================================
# Project Settings
PROJECT_NAME ?= myapp
ORGANIZATION ?= myorg
DESCRIPTION ?= "My Awesome Go Project"
MAINTAINER ?= "maintainer@example.com"

# Feature Flags (can be disabled in .env)
ENABLE_DOCKER ?= true
ENABLE_PROTO ?= true
ENABLE_DOCS ?= true
ENABLE_SECURITY_SCAN ?= true
ENABLE_ADVANCED_TESTING ?= true
ENABLE_BUILD_CACHE ?= true

# Project Structure
PROJECT_TYPE ?= basic # basic, monorepo, microservices
MONOREPO_SERVICES ?= $(wildcard services/*)
BUILD_TARGETS ?= $(if $(filter monorepo,$(PROJECT_TYPE)),$(MONOREPO_SERVICES),$(PROJECT_NAME))

# Build Settings
BUILD_SYSTEM ?= local # local, ci
CI_SYSTEM ?= github # github, gitlab, jenkins
PARALLEL_JOBS ?= $(shell nproc)
ENABLE_PARALLEL := $(if $(filter local,$(BUILD_SYSTEM)),true,false)

# Version Control
VERSION_STRATEGY ?= git # git, semver, date
VERSION := $(shell \
    if [ "$(VERSION_STRATEGY)" = "git" ] && git rev-parse --git-dir > /dev/null 2>&1; then \
        git describe --tags --always --dirty 2>/dev/null || echo "dev"; \
    elif [ "$(VERSION_STRATEGY)" = "semver" ]; then \
        cat VERSION 2>/dev/null || echo "0.1.0"; \
    else \
        date -u '+%Y%m%d-%H%M%S'; \
    fi)
GIT_COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
BUILD_TIME ?= $(shell date -u '+%Y-%m-%d_%H:%M:%S')
BUILD_BY ?= $(shell whoami)

# Go Configuration
GO ?= go
GOCMD = $(shell which go)
GOPATH ?= $(shell $(GO) env GOPATH)
GOBIN ?= $(GOPATH)/bin
GOOS ?= $(shell $(GO) env GOOS)
GOARCH ?= $(shell $(GO) env GOARCH)
CGO_ENABLED ?= 0

# Tools & Linters
GOLANGCI_LINT ?= $(GOBIN)/golangci-lint
GOFUMPT ?= $(GOBIN)/gofumpt
GODOC ?= $(GOBIN)/godoc
GOVULNCHECK ?= $(GOBIN)/govulncheck
MOCKGEN ?= $(GOBIN)/mockgen
AIR ?= $(GOBIN)/air

# Directories
ROOT_DIR ?= $(shell pwd)
BIN_DIR ?= $(ROOT_DIR)/bin
DIST_DIR ?= $(ROOT_DIR)/dist
DOCS_DIR ?= $(ROOT_DIR)/docs
TOOLS_DIR ?= $(ROOT_DIR)/tools
PROTO_DIR ?= $(ROOT_DIR)/proto
CONFIG_DIR ?= $(ROOT_DIR)/configs
SCRIPTS_DIR ?= $(ROOT_DIR)/scripts
MIGRATIONS_DIR ?= $(ROOT_DIR)/migrations

# Source Files
GOFILES = $(shell find . -type f -name '*.go' -not -path "./vendor/*" -not -path "./.git/*")
GOPACKAGES = $(shell $(GO) list ./... | grep -v /vendor/)

# Build Configuration
BUILD_TAGS ?= 
EXTRA_TAGS ?=
ALL_TAGS = $(BUILD_TAGS) $(EXTRA_TAGS)

# Linker Flags
LD_FLAGS += -s -w
LD_FLAGS += -X '$(shell go list -m)/pkg/version.Version=$(VERSION)'
LD_FLAGS += -X '$(shell go list -m)/pkg/version.Commit=$(GIT_COMMIT)'
LD_FLAGS += -X '$(shell go list -m)/pkg/version.Branch=$(GIT_BRANCH)'
LD_FLAGS += -X '$(shell go list -m)/pkg/version.BuildTime=$(BUILD_TIME)'
LD_FLAGS += -X '$(shell go list -m)/pkg/version.BuildBy=$(BUILD_BY)'

# Performance & Debug Flags
GCFLAGS ?=
ASMFLAGS ?=

# Docker Configuration
DOCKER_REGISTRY ?= docker.io
DOCKER_REPO ?= $(ORGANIZATION)/$(PROJECT_NAME)
DOCKER_IMAGE ?= $(DOCKER_REGISTRY)/$(DOCKER_REPO)
DOCKER_TAG ?= $(VERSION)
DOCKERFILE ?= Dockerfile
DOCKER_BUILD_ARGS ?=
DOCKER_BUILD_CONTEXT ?= .

# Test Configuration
TEST_TIMEOUT ?= 5m
TEST_FLAGS ?= -v -race -cover
COVERAGE_OUT ?= coverage.out
COVERAGE_HTML ?= coverage.html
COVERAGE_THRESHOLD ?= 80
BENCH_FLAGS ?= -benchmem
BENCH_TIME ?= 2s
TEST_PATTERN ?= .
SKIP_PATTERN ?=

# Cross-Compilation Targets
PLATFORMS ?= \
    linux/amd64/- \
    linux/arm64/- \
    linux/arm/7 \
    darwin/amd64/- \
    darwin/arm64/- \
    windows/amd64/- \
    windows/arm64/-

# =============================================================================
# 🎨 Terminal Colors & Emoji
# =============================================================================
# Colors
BLUE := \033[34m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
MAGENTA := \033[35m
CYAN := \033[36m
WHITE := \033[37m
BOLD := \033[1m
RESET := \033[0m

# Status Indicators
INFO := @printf "$(BLUE)ℹ️  $(RESET)"
SUCCESS := @printf "$(GREEN)✅ $(RESET)"
WARN := @printf "$(YELLOW)⚠️  $(RESET)"
ERROR := @printf "$(RED)❌ $(RESET)"
WORKING := @printf "$(CYAN)🔨 $(RESET)"
DEBUG := @printf "$(MAGENTA)🔍 $(RESET)"
ROCKET := @printf "$(GREEN)🚀 $(RESET)"
PACKAGE := @printf "$(CYAN)📦 $(RESET)"
TRASH := @printf "$(YELLOW)🗑️  $(RESET)"

# =============================================================================
# 🎯 Core Build System
# =============================================================================
.PHONY: init
init: ## Initialize project with sensible defaults
	$(INFO) Initializing project...
	@if [ ! -f "go.mod" ]; then \
		$(GO) mod init $(shell basename $(CURDIR)); \
	fi
	@if [ ! -f ".env" ]; then \
		echo "# Project Configuration" > .env; \
		echo "PROJECT_NAME=$(PROJECT_NAME)" >> .env; \
		echo "ENABLE_DOCKER=true" >> .env; \
		echo "ENABLE_PROTO=false" >> .env; \
	fi
	@if [ ! -f ".gitignore" ]; then \
		curl -sL https://www.gitignore.io/api/go > .gitignore; \
	fi
	@mkdir -p cmd pkg internal api docs scripts build configs
	$(MAKE) deps
	$(SUCCESS) Project initialized!

.PHONY: build
build: $(BIN_DIR) ## Build all targets
	$(WORKING) Building project...
	@$(foreach target,$(BUILD_TARGETS),\
		$(MAKE) build-target TARGET=$(target) $(if $(filter true,$(ENABLE_PARALLEL)),--jobs=$(PARALLEL_JOBS)) &)
	@wait
	$(SUCCESS) Build complete!

.PHONY: build-target
build-target: generate
	$(INFO) Building $(TARGET)...
	@if [ -f "$(TARGET)/Makefile" ]; then \
		$(MAKE) -C $(TARGET) build; \
	else \
		CGO_ENABLED=$(CGO_ENABLED) \
		$(GO) build -tags '$(ALL_TAGS)' \
			$(if $(filter true,$(ENABLE_BUILD_CACHE)),-x) \
			-ldflags '$(LD_FLAGS)' \
			-gcflags '$(GCFLAGS)' \
			-asmflags '$(ASMFLAGS)' \
			-o $(BIN_DIR)/$(notdir $(TARGET)) \
			./$(if $(filter monorepo,$(PROJECT_TYPE)),$(TARGET)/cmd,cmd)/$(notdir $(TARGET)); \
	fi

.PHONY: install
install: build ## Install the application
	$(WORKING) Installing $(PROJECT_NAME)...
	$(GO) install -tags '$(ALL_TAGS)' -ldflags '$(LD_FLAGS)' ./cmd/$(PROJECT_NAME)
	$(SUCCESS) Installation complete!

# =============================================================================
# 🔄 Development Workflow
# =============================================================================
.PHONY: dev
dev: deps generate ## Start development environment
	$(INFO) Starting development environment...
	@if [ ! -f ".air.toml" ]; then \
		cp $(CONFIG_DIR)/air.toml.example .air.toml 2>/dev/null || \
		curl -sL https://raw.githubusercontent.com/cosmtrek/air/master/air.conf.example > .air.toml; \
	fi
	$(ROCKET) Running with hot reload...
	$(AIR) -c .air.toml

.PHONY: run
run: build ## Run the application
	$(ROCKET) Running $(PROJECT_NAME)...
	$(BIN_DIR)/$(PROJECT_NAME)

.PHONY: generate
generate: ## Run code generation
	$(WORKING) Running code generation...
	$(GO) generate ./...
	@if [ -n "$(wildcard $(PROTO_DIR)/*.proto)" ]; then \
		$(MAKE) proto; \
	fi
	$(SUCCESS) Generation complete!

# =============================================================================
# 🧪 Testing & Quality
# =============================================================================
.PHONY: test
test: ## Run tests
	$(INFO) Running tests...
	$(GO) test $(TEST_FLAGS) \
		-timeout $(TEST_TIMEOUT) \
		-run '$(TEST_PATTERN)' \
		$(if $(SKIP_PATTERN),-skip '$(SKIP_PATTERN)') \
		./...

.PHONY: test-coverage
test-coverage: ## Run tests with coverage
	$(INFO) Running tests with coverage...
	$(GO) test $(TEST_FLAGS) \
		-timeout $(TEST_TIMEOUT) \
		-coverprofile=$(COVERAGE_OUT) \
		./...
	$(GO) tool cover -html=$(COVERAGE_OUT) -o $(COVERAGE_HTML)
	@coverage=$$(go tool cover -func=$(COVERAGE_OUT) | grep total | awk '{print $$3}' | sed 's/%//'); \
	if [ "$${coverage%.*}" -lt "$(COVERAGE_THRESHOLD)" ]; then \
		$(ERROR) "Coverage $${coverage}% is below threshold $(COVERAGE_THRESHOLD)%"; \
		exit 1; \
	fi
	$(SUCCESS) Coverage report generated: $(COVERAGE_HTML)

.PHONY: test-integration
test-integration: ## Run integration tests
	$(INFO) Running integration tests...
	$(GO) test $(TEST_FLAGS) \
		-tags=integration \
		-timeout $(TEST_TIMEOUT) \
		./...

.PHONY: test-e2e
test-e2e: ## Run end-to-end tests
	$(INFO) Running end-to-end tests...
	$(GO) test $(TEST_FLAGS) \
		-tags=e2e \
		-timeout $(TEST_TIMEOUT) \
		./test/e2e/...

.PHONY: bench
bench: ## Run benchmarks
	$(INFO) Running benchmarks...
	$(GO) test -bench=. \
		$(BENCH_FLAGS) \
		-run=^$ \
		-benchtime=$(BENCH_TIME) \
		./...

.PHONY: lint
lint: ## Run linters
	$(INFO) Running linters...
	$(GOLANGCI_LINT) run --fix
	$(SUCCESS) Lint complete!

.PHONY: fmt
fmt: ## Format code
	$(INFO) Formatting code...
	$(GO) fmt ./...
	$(GOFUMPT) -l -w .
	$(SUCCESS) Format complete!

.PHONY: vet
vet: ## Run go vet
	$(INFO) Running go vet...
	$(GO) vet ./...
	$(SUCCESS) Vet complete!

.PHONY: security
security: ## Run security checks
	$(INFO) Running security checks...
	$(GOVULNCHECK) ./...
	$(SUCCESS) Security check complete!

# =============================================================================
# 🏗️ Build Variations
# =============================================================================
.PHONY: build-all
build-all: $(DIST_DIR) ## Build for all platforms
	$(WORKING) Building for all platforms...
	@$(foreach platform,$(PLATFORMS),\
		$(eval OS := $(word 1,$(subst /, ,$(platform)))) \
		$(eval ARCH := $(word 2,$(subst /, ,$(platform)))) \
		$(eval ARM := $(word 3,$(subst /, ,$(platform)))) \
		$(WORKING) Building for $(OS)/$(ARCH)$(if $(ARM),/v$(ARM))... && \
		GOOS=$(OS) GOARCH=$(ARCH) $(if $(ARM),GOARM=$(ARM)) \
		CGO_ENABLED=$(CGO_ENABLED) \
		$(GO) build -tags '$(ALL_TAGS)' \
			-ldflags '$(LD_FLAGS)' \
			-o $(DIST_DIR)/$(PROJECT_NAME)-$(OS)-$(ARCH)$(if $(ARM),v$(ARM))$(if $(findstring windows,$(OS)),.exe,) \
			./cmd/$(PROJECT_NAME) ; \
	)
	$(PACKAGE) Creating release archives...
	@cd $(DIST_DIR) && \
	for file in $(PROJECT_NAME)-* ; do \
		if [ -f "$$file" ]; then \
			tar czf "$$file.tar.gz" "$$file" || exit 1; \
			rm -f "$$file"; \
		fi \
	done
	$(SUCCESS) All platforms built and archived!
.PHONY: build-debug
build-debug: GCFLAGS += -N -l ## Build with debug symbols
build-debug: BUILD_TAGS += debug
build-debug: build

.PHONY: build-race
build-race: CGO_ENABLED=1 ## Build with race detector
build-race: BUILD_TAGS += race
build-race: build

# =============================================================================
# 📦 Docker Support
# =============================================================================
.PHONY: docker-build
docker-build: ## Build Docker image
	$(WORKING) Building Docker image...
	docker build $(DOCKER_BUILD_ARGS) \
		--build-arg VERSION=$(VERSION) \
		--build-arg BUILD_TIME=$(BUILD_TIME) \
		--build-arg GIT_COMMIT=$(GIT_COMMIT) \
		-f $(DOCKERFILE) \
		-t $(DOCKER_IMAGE):$(DOCKER_TAG) \
		$(DOCKER_BUILD_CONTEXT)
	$(SUCCESS) Docker image built!

.PHONY: docker-push
docker-push: ## Push Docker image
	$(WORKING) Pushing Docker image...
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)
	$(SUCCESS) Docker image pushed!

.PHONY: docker-run
docker-run: ## Run Docker container
	$(ROCKET) Running Docker container...
	docker run --rm -it $(DOCKER_IMAGE):$(DOCKER_TAG)

# =============================================================================
# 🗄️ Database Operations
# =============================================================================
.PHONY: db-migrate
db-migrate: ## Run database migrations
	$(INFO) Running database migrations...
	@if [ -d "$(MIGRATIONS_DIR)" ]; then \
		go run -tags 'postgres mysql' github.com/golang-migrate/migrate/v4/cmd/migrate@latest \
			-database "$(DATABASE_URL)" \
			-path $(MIGRATIONS_DIR) up; \
	else \
		$(WARN) No migrations directory found; \
	fi

.PHONY: db-rollback
db-rollback: ## Rollback database migration
	$(INFO) Rolling back database migration...
	go run -tags 'postgres mysql' github.com/golang-migrate/migrate/v4/cmd/migrate@latest \
		-database "$(DATABASE_URL)" \
		-path $(MIGRATIONS_DIR) down 1

.PHONY: db-reset
db-reset: ## Reset database
	$(WARN) Resetting database...
	go run -tags 'postgres mysql' github.com/golang-migrate/migrate/v4/cmd/migrate@latest \
		-database "$(DATABASE_URL)" \
		-path $(MIGRATIONS_DIR) drop -f

# =============================================================================
# 📊 Reporting & Analytics
# =============================================================================
.PHONY: report
report: ## Generate project reports
	$(INFO) Generating project reports...
	@mkdir -p $(DOCS_DIR)/reports
	@$(MAKE) test-coverage
	@$(MAKE) benchmark-report
	@$(MAKE) lint-report
	@$(MAKE) security-report
	$(SUCCESS) Reports generated in $(DOCS_DIR)/reports

.PHONY: benchmark-report
benchmark-report:
	$(GO) test -bench=. -benchmem ./... > $(DOCS_DIR)/reports/benchmark.txt

.PHONY: lint-report
lint-report:
	$(GOLANGCI_LINT) run --out-format checkstyle > $(DOCS_DIR)/reports/lint-checkstyle.xml

.PHONY: security-report
security-report:
	$(GOVULNCHECK) -json ./... > $(DOCS_DIR)/reports/security.json

# =============================================================================
# 🔄 CI/CD Integration
# =============================================================================
.PHONY: ci
ci: ## Run CI pipeline
	$(INFO) Running CI pipeline...
	@$(MAKE) deps-verify
	@$(MAKE) lint
	@$(MAKE) test-coverage
	@$(MAKE) security
	@$(MAKE) build
	$(SUCCESS) CI pipeline complete!

.PHONY: cd
cd: ## Run CD pipeline
	$(INFO) Running CD pipeline...
	@$(MAKE) build
	@if [ "$(ENABLE_DOCKER)" = "true" ]; then \
		$(MAKE) docker-build; \
		$(MAKE) docker-push; \
	fi
	$(SUCCESS) CD pipeline complete!

# =============================================================================
# 🧹 Cleanup & Maintenance
# =============================================================================
.PHONY: clean
clean: ## Clean build artifacts
	$(TRASH) Cleaning build artifacts...
	rm -rf $(BIN_DIR) $(DIST_DIR)
	$(GO) clean -cache -testcache -modcache
	$(SUCCESS) Clean complete!

.PHONY: deps
deps: ## Install dependencies
	$(WORKING) Installing dependencies...
	$(GO) mod download
	@if [ ! -f "$(GOLANGCI_LINT)" ]; then \
		$(GO) install github.com/golangci/golangci-lint/cmd/golangci-lint@latest; \
	fi
	@if [ ! -f "$(GOFUMPT)" ]; then \
		$(GO) install mvdan.cc/gofumpt@latest; \
	fi
	@if [ ! -f "$(GOVULNCHECK)" ]; then \
		$(GO) install golang.org/x/vuln/cmd/govulncheck@latest; \
	fi
	@if [ ! -f "$(MOCKGEN)" ]; then \
		$(GO) install github.com/golang/mock/mockgen@latest; \
	fi
	@if [ ! -f "$(AIR)" ]; then \
		$(GO) install github.com/cosmtrek/air@latest; \
	fi
	$(SUCCESS) Dependencies installed!

.PHONY: deps-update
deps-update: ## Update dependencies
	$(WORKING) Updating dependencies...
	$(GO) get -u ./...
	$(GO) mod tidy
	$(SUCCESS) Dependencies updated!

.PHONY: deps-verify
deps-verify: ## Verify dependencies
	$(INFO) Verifying dependencies...
	$(GO) mod verify
	$(SUCCESS) Dependencies verified!

# =============================================================================
# 📚 Documentation
# =============================================================================
.PHONY: docs
docs: $(DOCS_DIR) ## Generate documentation
	$(WORKING) Generating documentation...
	@mkdir -p $(DOCS_DIR)
	$(GO) doc -all > $(DOCS_DIR)/API.md
	@if [ -f "README.md.tmpl" ]; then \
		VERSION=$(VERSION) \
		BUILD_TIME=$(BUILD_TIME) \
		envsubst < README.md.tmpl > README.md; \
	fi
	$(SUCCESS) Documentation generated!

.PHONY: serve-docs
serve-docs: ## Serve documentation locally
	$(ROCKET) Serving documentation at http://localhost:6060
	$(GODOC) -http=:6060

# =============================================================================
# 🛠️ Tools & Utilities
# =============================================================================
.PHONY: tools
tools: ## Install all tools
	$(INFO) Installing tools...
	$(GO) install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	$(GO) install mvdan.cc/gofumpt@latest
	$(GO) install golang.org/x/vuln/cmd/govulncheck@latest
	$(GO) install github.com/golang/mock/mockgen@latest
	$(GO) install github.com/cosmtrek/air@latest
	$(GO) install github.com/swaggo/swag/cmd/swag@latest
	$(SUCCESS) Tools installed!

.PHONY: proto
proto: ## Generate protocol buffers
	$(WORKING) Generating protocol buffers...
	@if [ -d "$(PROTO_DIR)" ]; then \
		protoc --go_out=. --go_opt=paths=source_relative \
			--go-grpc_out=. --go-grpc_opt=paths=source_relative \
			$(PROTO_DIR)/*.proto; \
	fi
	$(SUCCESS) Protocol buffers generated!

.PHONY: mock
mock: ## Generate mocks
	$(WORKING) Generating mocks...
	$(MOCKGEN) -source=pkg/interfaces.go -destination=pkg/mocks/mocks.go
	$(SUCCESS) Mocks generated!

.PHONY: version
version: ## Display version information
	@echo "$(CYAN)Version:$(RESET)    $(VERSION)"
	@echo "$(CYAN)Commit:$(RESET)     $(GIT_COMMIT)"
	@echo "$(CYAN)Branch:$(RESET)     $(GIT_BRANCH)"
	@echo "$(CYAN)Built:$(RESET)      $(BUILD_TIME)"
	@echo "$(CYAN)Built by:$(RESET)   $(BUILD_BY)"
	@echo "$(CYAN)Go version:$(RESET) $(shell $(GO) version)"

# =============================================================================
# 📁 Directory Creation
# =============================================================================
$(BIN_DIR) $(DIST_DIR) $(DOCS_DIR):
	mkdir -p $@

# =============================================================================
# 💡 Help
# =============================================================================
.PHONY: help
help: ## Show this help message
	@echo "$(CYAN)$(BOLD)$(PROJECT_NAME) - $(DESCRIPTION)$(RESET)"
	@echo "$(WHITE)Maintained by $(MAINTAINER)$(RESET)\n"
	@echo "$(CYAN)$(BOLD)Available targets:$(RESET)"
	@awk 'BEGIN {FS = ":.*##"; printf ""} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  $(CYAN)%-20s$(RESET) %s\n", $$1, $$2 } \
		/^##@/ { printf "\n$(MAGENTA)%s$(RESET)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help
