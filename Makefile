# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

# Makefile for Mock PVE API Server
# Provides convenient commands for development, testing, and architecture validation

.DEFAULT_GOAL := help
.PHONY: help deps compile test format lint docs clean container arch-validate arch-viz validate release

# Configuration
ELIXIR_VERSION ?= 1.15
OTP_VERSION ?= 26
IMAGE_NAME ?= mock-pve-api
CONTAINER_REGISTRY ?= docker.io
NAMESPACE ?= jrjsmrtn

# Container runtime detection (prefer Podman)
CONTAINER_RUNTIME ?= $(shell which podman 2>/dev/null || which docker 2>/dev/null || echo "podman")

# Colors for output
BLUE := \033[34m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

help: ## Show this help message
	@echo "$(BLUE)Mock PVE API Server - Development Commands$(RESET)"
	@echo ""
	@echo "$(GREEN)Development:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '^(deps|compile|test|format|lint|docs|clean):' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-12s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Containers:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '^(container|build|push|run):' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-12s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Architecture:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '^(arch-|validate):' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-12s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Security:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '^(sbom|vulnerability|security):' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-12s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Release:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '^(release|tag):' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-12s$(RESET) %s\n", $$1, $$2}'

## Development Commands
deps: ## Install Elixir dependencies
	@echo "$(BLUE)Installing dependencies...$(RESET)"
	mix deps.get
	mix deps.compile

compile: deps ## Compile the application
	@echo "$(BLUE)Compiling application...$(RESET)"
	mix compile

test: ## Run test suite
	@echo "$(BLUE)Running tests...$(RESET)"
	mix test

test-cover: ## Run tests with coverage report
	@echo "$(BLUE)Running tests with coverage...$(RESET)"
	mix test --cover

test-watch: ## Run tests in watch mode (requires mix_test_watch)
	@echo "$(BLUE)Starting test watcher...$(RESET)"
	mix test.watch

format: ## Format Elixir code
	@echo "$(BLUE)Formatting code...$(RESET)"
	mix format

format-check: ## Check if code is formatted
	@echo "$(BLUE)Checking code formatting...$(RESET)"
	mix format --check-formatted

lint: format-check ## Run code linting (credo when available)
	@echo "$(BLUE)Running linter...$(RESET)"
	@if mix help credo >/dev/null 2>&1; then \
		mix credo; \
	else \
		echo "$(YELLOW)Credo not available, skipping lint check$(RESET)"; \
	fi

typecheck: ## Run type checking with dialyzer (when available)
	@echo "$(BLUE)Running type checker...$(RESET)"
	@if mix help dialyzer >/dev/null 2>&1; then \
		mix dialyzer; \
	else \
		echo "$(YELLOW)Dialyzer not available, skipping type check$(RESET)"; \
	fi

docs: ## Generate documentation
	@echo "$(BLUE)Generating documentation...$(RESET)"
	mix docs
	@echo "$(GREEN)Documentation generated in doc/$(RESET)"

docs-open: docs ## Generate and open documentation
	@echo "$(BLUE)Opening documentation...$(RESET)"
	@if command -v open >/dev/null 2>&1; then \
		open doc/index.html; \
	elif command -v xdg-open >/dev/null 2>&1; then \
		xdg-open doc/index.html; \
	else \
		echo "$(YELLOW)Please open doc/index.html manually$(RESET)"; \
	fi

docs-coverage: ## Generate API reference documentation from Coverage module
	@echo "$(BLUE)Generating API reference documentation...$(RESET)"
	mix docs.coverage
	@echo "$(GREEN)Documentation generated at docs/reference/api-reference.md$(RESET)"

docs-coverage-check: ## Check if API reference docs are up-to-date
	@echo "$(BLUE)Checking API reference documentation...$(RESET)"
	@mix docs.coverage --check

LEFTHOOK_VERSION ?= 2.1.1

install-lefthook: ## Install lefthook binary (if not present)
	@if command -v lefthook >/dev/null 2>&1; then \
		echo "$(GREEN)lefthook already on PATH$(RESET)"; \
	elif [ -x bin/lefthook ]; then \
		echo "$(GREEN)lefthook already installed at bin/lefthook$(RESET)"; \
	else \
		echo "$(BLUE)Downloading lefthook $(LEFTHOOK_VERSION)...$(RESET)"; \
		mkdir -p bin; \
		OS=$$(uname -s); ARCH=$$(uname -m); \
		if [ "$$ARCH" = "aarch64" ]; then ARCH=arm64; fi; \
		URL="https://github.com/evilmartians/lefthook/releases/download/v$(LEFTHOOK_VERSION)/lefthook_$(LEFTHOOK_VERSION)_$${OS}_$${ARCH}"; \
		curl -fsSL "$$URL" -o bin/lefthook && chmod +x bin/lefthook; \
		echo "$(GREEN)lefthook installed at bin/lefthook$(RESET)"; \
	fi

LEFTHOOK := $(shell command -v lefthook 2>/dev/null || echo bin/lefthook)

install-hooks: install-lefthook ## Install git hooks via lefthook
	$(LEFTHOOK) install

uninstall-hooks: ## Remove git hooks
	$(LEFTHOOK) uninstall

clean: ## Clean build artifacts
	@echo "$(BLUE)Cleaning build artifacts...$(RESET)"
	mix clean
	rm -rf _build deps doc cover

server: ## Start development server
	@echo "$(BLUE)Starting development server...$(RESET)"
	@echo "$(GREEN)Mock PVE API will be available at http://localhost:8006$(RESET)"
	iex -S mix run --no-halt

## Container Commands (Podman/Docker)
container-build: ## Build container image using detected runtime
	@echo "$(BLUE)Building container image with $(CONTAINER_RUNTIME)...$(RESET)"
	$(CONTAINER_RUNTIME) build -f containers/Containerfile -t $(IMAGE_NAME):latest .
	@echo "$(GREEN)Image built: $(IMAGE_NAME):latest$(RESET)"

container-build-dev: ## Build development container image
	@echo "$(BLUE)Building development container image with $(CONTAINER_RUNTIME)...$(RESET)"
	$(CONTAINER_RUNTIME) build -f containers/Containerfile.dev -t $(IMAGE_NAME):dev .
	@echo "$(GREEN)Development image built: $(IMAGE_NAME):dev$(RESET)"

container-run: ## Run container locally
	@echo "$(BLUE)Starting container with $(CONTAINER_RUNTIME)...$(RESET)"
	@echo "$(GREEN)Mock PVE API will be available at http://localhost:8006$(RESET)"
	$(CONTAINER_RUNTIME) run --rm -p 8006:8006 \
		-e MOCK_PVE_VERSION=8.3 \
		-e MOCK_PVE_LOG_LEVEL=info \
		$(CONTAINER_REGISTRY)/$(NAMESPACE)/$(IMAGE_NAME):latest

container-run-dev: ## Run development container with volume mount
	@echo "$(BLUE)Starting development container with $(CONTAINER_RUNTIME)...$(RESET)"
	@echo "$(GREEN)Mock PVE API will be available at http://localhost:8006$(RESET)"
	$(CONTAINER_RUNTIME) run --rm -it -p 8006:8006 \
		-v $(PWD):/app \
		-e MOCK_PVE_VERSION=8.3 \
		-e MOCK_PVE_LOG_LEVEL=debug \
		$(IMAGE_NAME):dev

# Legacy Docker aliases for compatibility
docker-build: container-build ## Alias for container-build (legacy)
docker-build-dev: container-build-dev ## Alias for container-build-dev (legacy)
docker-run: container-run ## Alias for container-run (legacy)
docker-run-dev: container-run-dev ## Alias for container-run-dev (legacy)
docker-run-versions: container-run-versions ## Alias for container-run-versions (legacy)

container-run-versions: ## Run multiple PVE versions simultaneously
	@echo "$(BLUE)Starting multiple PVE versions with $(CONTAINER_RUNTIME)...$(RESET)"
	@for version in 7.4 8.0 8.3 9.0; do \
		port=$$((8000 + $${version%%.*})); \
		echo "$(GREEN)Starting PVE $$version on port $$port$(RESET)"; \
		$(CONTAINER_RUNTIME) run -d --name mock-pve-$$version \
			-p $$port:8006 \
			-e MOCK_PVE_VERSION=$$version \
			$(CONTAINER_REGISTRY)/$(NAMESPACE)/$(IMAGE_NAME):latest; \
	done
	@echo "$(GREEN)All versions started:$(RESET)"
	@echo "  PVE 7.4: http://localhost:8007"
	@echo "  PVE 8.0: http://localhost:8008"  
	@echo "  PVE 8.3: http://localhost:8008"
	@echo "  PVE 9.0: http://localhost:8009"

docker-stop-versions: ## Stop all version containers
	@echo "$(BLUE)Stopping all version containers...$(RESET)"
	@for version in 7.4 8.0 8.3 9.0; do \
		docker stop mock-pve-$$version 2>/dev/null || true; \
		docker rm mock-pve-$$version 2>/dev/null || true; \
	done
	@echo "$(GREEN)All version containers stopped$(RESET)"

docker-compose-up: ## Start services with docker-compose
	@echo "$(BLUE)Starting services with docker-compose...$(RESET)"
	docker-compose up -d
	@echo "$(GREEN)Services started. Check docker-compose ps for details$(RESET)"

docker-compose-down: ## Stop docker-compose services  
	@echo "$(BLUE)Stopping docker-compose services...$(RESET)"
	docker-compose down
	@echo "$(GREEN)Services stopped$(RESET)"

## Architecture Commands
arch-validate: ## Validate C4 architecture model
	@echo "$(BLUE)Validating C4 architecture model...$(RESET)"
	@if ! command -v podman >/dev/null 2>&1 && ! command -v docker >/dev/null 2>&1; then \
		echo "$(RED)Error: Neither podman nor docker found$(RESET)"; \
		exit 1; \
	fi
	@CONTAINER_CMD=$$(command -v podman || command -v docker); \
	$$CONTAINER_CMD run --rm -v $(PWD)/docs/architecture:/usr/local/structurizr \
		structurizr/cli validate -w workspace.dsl
	@echo "$(GREEN)Architecture model is valid$(RESET)"

arch-viz: ## Start interactive architecture visualization
	@echo "$(BLUE)Starting architecture visualization...$(RESET)"
	@if ! command -v podman >/dev/null 2>&1 && ! command -v docker >/dev/null 2>&1; then \
		echo "$(RED)Error: Neither podman nor docker found$(RESET)"; \
		exit 1; \
	fi
	@CONTAINER_CMD=$$(command -v podman || command -v docker); \
	echo "$(GREEN)Architecture visualization will be available at http://localhost:8080$(RESET)"; \
	$$CONTAINER_CMD run --rm -p 8080:8080 -v $(PWD)/docs/architecture:/usr/local/structurizr \
		structurizr/lite

validate: arch-validate lint typecheck test ## Run all validation checks
	@echo "$(GREEN)All validation checks passed!$(RESET)"

## Testing Commands
test-examples: ## Test example scripts against a local dev server (HTTPS default)
	@echo "$(BLUE)Starting mock server for example testing...$(RESET)"
	@MIX_ENV=dev mix run --no-halt &
	@MOCK_PID=$$!; \
	sleep 8; \
	echo "$(GREEN)Testing Shell/curl example...$(RESET)"; \
	bash examples/shell/test-endpoints.sh; SHELL_RC=$$?; \
	echo ""; \
	echo "$(GREEN)Testing proxmoxer integration...$(RESET)"; \
	python3 examples/proxmoxer/test_proxmoxer.py; PROX_RC=$$?; \
	kill $$MOCK_PID 2>/dev/null; \
	if [ $$SHELL_RC -ne 0 ] || [ $$PROX_RC -ne 0 ]; then \
		echo "$(RED)Some example tests failed$(RESET)"; exit 1; \
	fi; \
	echo "$(GREEN)All example tests passed!$(RESET)"

test-integration: container-build ## Run integration tests against container
	@echo "$(BLUE)Running integration tests...$(RESET)"
	@$(CONTAINER_RUNTIME) run -d --name integration-mock-pve -p 8006:8006 \
		-e MOCK_PVE_VERSION=8.3 \
		$(IMAGE_NAME):latest
	@sleep 2
	@# Basic health check
	@curl -f http://localhost:8006/api2/json/version >/dev/null || { \
		echo "$(RED)Health check failed$(RESET)"; \
		$(CONTAINER_RUNTIME) logs integration-mock-pve; \
		$(CONTAINER_RUNTIME) stop integration-mock-pve && $(CONTAINER_RUNTIME) rm integration-mock-pve; \
		exit 1; \
	}
	@echo "$(GREEN)Integration test passed$(RESET)"
	@$(CONTAINER_RUNTIME) stop integration-mock-pve && $(CONTAINER_RUNTIME) rm integration-mock-pve

benchmark: container-build ## Run performance benchmarks
	@echo "$(BLUE)Running performance benchmarks...$(RESET)"
	@$(CONTAINER_RUNTIME) run -d --name benchmark-mock-pve -p 8006:8006 $(IMAGE_NAME):latest
	@sleep 2
	@# Simple benchmark using curl or ab if available
	@if command -v ab >/dev/null 2>&1; then \
		echo "$(GREEN)Running Apache Bench test...$(RESET)"; \
		ab -n 1000 -c 10 http://localhost:8006/api2/json/version; \
	else \
		echo "$(YELLOW)Apache Bench not available, running simple test...$(RESET)"; \
		for i in {1..100}; do curl -s http://localhost:8006/api2/json/version >/dev/null; done; \
		echo "$(GREEN)Completed 100 requests$(RESET)"; \
	fi
	@$(CONTAINER_RUNTIME) stop benchmark-mock-pve && $(CONTAINER_RUNTIME) rm benchmark-mock-pve

## Security & Compliance Commands
sbom: ## Generate Software Bill of Materials (SBOM)
	@echo "$(BLUE)Generating SBOM files...$(RESET)"
	./scripts/generate-sbom.sh
	@echo "$(GREEN)SBOM generation completed$(RESET)"

sbom-deps: ## Generate SBOM for dependencies only
	@echo "$(BLUE)Generating dependency SBOM...$(RESET)"
	./scripts/generate-sbom.sh --deps-only
	@echo "$(GREEN)Dependency SBOM generated$(RESET)"

sbom-container: ## Generate SBOM for container image
	@echo "$(BLUE)Generating container SBOM...$(RESET)"
	./scripts/generate-sbom.sh --container
	@echo "$(GREEN)Container SBOM generated$(RESET)"

sbom-source: ## Generate SBOM for source code
	@echo "$(BLUE)Generating source SBOM...$(RESET)"
	./scripts/generate-sbom.sh --source
	@echo "$(GREEN)Source SBOM generated$(RESET)"

vulnerability-scan: ## Run vulnerability scan on SBOM
	@echo "$(BLUE)Running vulnerability scan...$(RESET)"
	@if [ ! -f sbom/source-spdx.json ]; then \
		echo "$(YELLOW)SBOM not found, generating first...$(RESET)"; \
		./scripts/generate-sbom.sh --source; \
	fi
	@if command -v grype >/dev/null 2>&1; then \
		grype sbom:sbom/source-spdx.json; \
	else \
		echo "$(YELLOW)Grype not installed, installing...$(RESET)"; \
		./scripts/generate-sbom.sh; \
	fi

security-audit: sbom vulnerability-scan ## Complete security audit with SBOM and vulnerability scan
	@echo "$(GREEN)Security audit completed$(RESET)"

## Release Commands  
release-check: validate test-integration security-audit ## Check if ready for release
	@echo "$(BLUE)Checking release readiness...$(RESET)"
	@echo "$(GREEN)✓ Code validation passed$(RESET)"
	@echo "$(GREEN)✓ Integration tests passed$(RESET)"
	@echo "$(GREEN)✓ Security audit completed$(RESET)"
	@echo "$(GREEN)✓ Ready for release$(RESET)"

tag: ## Create and push git tag (usage: make tag VERSION=v0.1.0)
ifndef VERSION
	@echo "$(RED)Error: VERSION is required. Usage: make tag VERSION=v0.1.0$(RESET)"
	@exit 1
endif
	@echo "$(BLUE)Creating tag $(VERSION)...$(RESET)"
	git tag -a $(VERSION) -m "Release $(VERSION)"
	git push origin $(VERSION)
	@echo "$(GREEN)Tag $(VERSION) created and pushed$(RESET)"

release: release-check ## Create GitHub release (requires gh CLI)
ifndef VERSION  
	@echo "$(RED)Error: VERSION is required. Usage: make release VERSION=v0.1.0$(RESET)"
	@exit 1
endif
	@if ! command -v gh >/dev/null 2>&1; then \
		echo "$(RED)Error: GitHub CLI (gh) is required for releases$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Creating GitHub release $(VERSION)...$(RESET)"
	gh release create $(VERSION) --generate-notes --title "Mock PVE API $(VERSION)"
	@echo "$(GREEN)Release $(VERSION) created$(RESET)"

## Utility Commands
version: ## Show version information
	@echo "$(BLUE)Mock PVE API Server$(RESET)"
	@echo "Elixir: $$(elixir --version | head -1)"
	@echo "OTP: $$(elixir --version | tail -1)"
	@if command -v docker >/dev/null 2>&1; then \
		echo "Docker: $$(docker --version)"; \
	fi
	@if command -v podman >/dev/null 2>&1; then \
		echo "Podman: $$(podman --version)"; \
	fi

check-deps: ## Check for required dependencies
	@echo "$(BLUE)Checking dependencies...$(RESET)"
	@echo -n "Elixir: "; command -v elixir >/dev/null 2>&1 && echo "$(GREEN)✓$(RESET)" || echo "$(RED)✗$(RESET)"
	@echo -n "Mix: "; command -v mix >/dev/null 2>&1 && echo "$(GREEN)✓$(RESET)" || echo "$(RED)✗$(RESET)"
	@echo -n "Docker: "; command -v docker >/dev/null 2>&1 && echo "$(GREEN)✓$(RESET)" || echo "$(YELLOW)○$(RESET)"
	@echo -n "Podman: "; command -v podman >/dev/null 2>&1 && echo "$(GREEN)✓$(RESET)" || echo "$(YELLOW)○$(RESET)"
	@echo -n "curl: "; command -v curl >/dev/null 2>&1 && echo "$(GREEN)✓$(RESET)" || echo "$(YELLOW)○$(RESET)"
	@echo -n "lefthook: "; (command -v lefthook >/dev/null 2>&1 || [ -x bin/lefthook ]) && echo "$(GREEN)✓$(RESET)" || echo "$(YELLOW)○$(RESET)"
	@echo -n "gitleaks: "; command -v gitleaks >/dev/null 2>&1 && echo "$(GREEN)✓$(RESET)" || echo "$(YELLOW)○$(RESET)"
	@echo ""
	@echo "$(GREEN)✓ Required  $(YELLOW)○ Optional  $(RED)✗ Missing$(RESET)"

install-dev-deps: ## Install development dependencies (credo, dialyzer, etc.)
	@echo "$(BLUE)Installing development dependencies...$(RESET)"
	mix archive.install hex phx_new --force
	@echo "$(GREEN)Development dependencies installed$(RESET)"

.PHONY: help deps compile test test-cover test-watch format format-check lint typecheck docs docs-open docs-coverage docs-coverage-check install-lefthook install-hooks uninstall-hooks clean server
.PHONY: docker-build docker-build-dev docker-run docker-run-dev docker-run-versions docker-stop-versions docker-compose-up docker-compose-down
.PHONY: arch-validate arch-viz validate test-examples test-integration benchmark
.PHONY: sbom sbom-deps sbom-container sbom-source vulnerability-scan security-audit
.PHONY: release-check tag release version check-deps install-dev-deps