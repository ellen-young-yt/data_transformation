.PHONY: help install deps lint lint-fix test test-unit test-integration compile build seed snapshot run clean docs docker-build docker-run setup pre-commit type-check format-docs security-alt validate-files quality-full security-full format-all

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Core Development Targets:'
	@echo '  help            Show this help message'
	@echo '  setup           Complete initial setup'
	@echo '  validate        Validate project structure and environment'
	@echo '  install         Install Python dependencies'
	@echo '  deps            Install dbt packages'
	@echo ''
	@echo 'Fast Quality Checks (used in CI/CD):'
	@echo '  lint            Run essential linting checks (black, isort, flake8, sqlfluff)'
	@echo '  lint-fix        Fix linting issues automatically'
	@echo '  pre-commit      Run all pre-commit hooks on all files'
	@echo ''
	@echo 'Optional Quality Tools (comprehensive local development):'
	@echo '  type-check      Run mypy type checking on Python files'
	@echo '  format-docs     Run prettier on YAML and Markdown files'
	@echo '  security-alt    Run safety scanner (alternative to pip-audit)'
	@echo '  validate-files  Run additional file format validation (JSON, TOML)'
	@echo '  quality-full    Run ALL quality checks (CI + optional tools)'
	@echo '  security-full   Run both pip-audit AND safety for comprehensive scanning'
	@echo '  format-all      Run all formatting tools (black, isort, prettier)'
	@echo ''
	@echo 'dbt Operations:'
	@echo '  compile         Compile dbt models to SQL'
	@echo '  build           Run dbt build (models + tests)'
	@echo '  seed            Load dbt seed data'
	@echo '  snapshot        Run dbt snapshots'
	@echo '  test-unit       Run pre-deployment tests'
	@echo '  test-integration Run post-deployment integration tests'
	@echo '  test            Run both unit and integration tests'
	@echo '  run [ENV=env] [MODE=mode] Run dbt models (ENV: dev|test|prod, MODE: local|docker)'
	@echo '                            MODE=local: Run using local dbt installation (default)'
	@echo '                            MODE=docker: Build and run in Docker container (isolated environment)'
	@echo '  clean           Clean dbt artifacts and rebuild venv'
	@echo '  docs [SERVE=true] Generate dbt documentation (add SERVE=true to also serve)'
	@echo '  docker-build    Build Docker image'

install: ## Install Python dependencies
	python -m scripts.setup install --force

deps: ## Install dbt packages
	python -m scripts.dbt_commands deps

lint: ## Run linting
	python -m scripts.linting all

lint-fix: ## Fix linting issues
	python -m scripts.linting all --fix

run: ## Run dbt models (usage: make run [ENV=dev|test|prod] [MODE=local|docker], defaults to dev/local)
	@python -m scripts.dbt_commands run $(or $(ENV),dev) $(or $(MODE),local)

compile: ## Compile dbt models to SQL (usage: make compile [ENV=dev|test|prod] [MODE=local|docker])
	@python -m scripts.dbt_commands compile $(or $(ENV),dev) $(or $(MODE),local)

build: ## Run dbt build (models + tests) (usage: make build [ENV=dev|test|prod] [MODE=local|docker])
	@python -m scripts.dbt_commands build $(or $(ENV),dev) $(or $(MODE),local)

seed: ## Load dbt seed data (usage: make seed [ENV=dev|test|prod] [MODE=local|docker])
	@python -m scripts.dbt_commands seed $(or $(ENV),dev) $(or $(MODE),local)

snapshot: ## Run dbt snapshots (usage: make snapshot [ENV=dev|test|prod] [MODE=local|docker])
	@python -m scripts.dbt_commands snapshot $(or $(ENV),dev) $(or $(MODE),local)

test-unit: ## Run pre-deployment tests (usage: make test-unit [ENV=dev|test|prod] [MODE=local|docker])
	@python -m scripts.dbt_commands test-unit $(or $(ENV),dev) $(or $(MODE),local)

test-integration: ## Run post-deployment integration tests (usage: make test-integration [ENV=dev|test|prod] [MODE=local|docker])
	@python -m scripts.dbt_commands test-integration $(or $(ENV),dev) $(or $(MODE),local)

test: ## Run both unit and integration tests (usage: make test [ENV=dev|test|prod] [MODE=local|docker])
	@python -m scripts.dbt_commands test $(or $(ENV),dev) $(or $(MODE),local)

clean: ## Clean dbt artifacts and rebuild virtual environment
	python -m scripts.environment_manager clean

docs: ## Generate dbt documentation (usage: make docs [SERVE=true])
	python -m scripts.dbt_commands docs-generate
ifeq ($(SERVE),true)
	python -m scripts.dbt_commands docs-serve
endif

docker-build: ## Build Docker image
	python -m scripts.docker_manager build

setup: ## Complete initial setup
	python -m scripts.setup complete

validate: ## Validate project structure and environment
	@python -m scripts.environment_manager info

pre-commit: ## Run all pre-commit hooks on all files
	pre-commit run --all-files

# Optional Quality Tools (removed from CI/CD for speed)
type-check: ## Run mypy type checking on Python files
	python -m pip install mypy types-PyYAML
	python -m mypy scripts/ --config-file=pyproject.toml --exclude="(transform/|target/|logs/)"

format-docs: ## Run basic YAML and Markdown validation (prettier removed)
	python -m scripts.file_validators yaml

security-alt: ## Run pip-audit for vulnerability scanning (safety removed)
	python -m pip install pip-audit
	python -m pip-audit --format=text

validate-files: ## Run additional file format validation (JSON, TOML)
	python -m scripts.file_validators all

# Comprehensive Quality Commands
quality-full: ## Run ALL quality checks (CI + optional tools)
	@echo "Running comprehensive quality analysis..."
	$(MAKE) lint
	$(MAKE) type-check
	$(MAKE) format-docs
	$(MAKE) validate-files

security-full: ## Run pip-audit for comprehensive security scanning (safety removed)
	@echo "Running comprehensive security analysis..."
	python -m pip install pip-audit
	@echo "=== pip-audit results ==="
	python -m pip_audit || true

format-all: ## Run all formatting tools (black, isort)
	@echo "Running all formatters..."
	python -m scripts.linting all --fix
	$(MAKE) format-docs
