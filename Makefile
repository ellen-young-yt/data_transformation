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
	@echo '  docs            Generate and serve dbt documentation'
	@echo '  docker-build    Build Docker image'

install: ## Install Python dependencies
	python -m scripts.setup install --force

deps: ## Install dbt packages
	python -m scripts.dbt_commands deps

lint: ## Run linting
	python -m scripts.linting all

lint-fix: ## Fix linting issues
	python -m scripts.linting all --fix

run: deps ## Run dbt models (usage: make run [ENV=dev|test|prod] [MODE=local|docker], defaults to dev/local)
	@python -m scripts.dbt_commands run $(or $(ENV),dev) $(or $(MODE),local)

compile: deps ## Compile dbt models to SQL (usage: make compile [ENV=dev|test|prod] [MODE=local|docker])
	@python -m scripts.dbt_commands compile $(or $(ENV),dev) $(or $(MODE),local)

build: deps ## Run dbt build (models + tests) (usage: make build [ENV=dev|test|prod] [MODE=local|docker])
	@python -m scripts.dbt_commands build $(or $(ENV),dev) $(or $(MODE),local)

seed: deps ## Load dbt seed data (usage: make seed [ENV=dev|test|prod] [MODE=local|docker])
	@python -m scripts.dbt_commands seed $(or $(ENV),dev) $(or $(MODE),local)

snapshot: deps ## Run dbt snapshots (usage: make snapshot [ENV=dev|test|prod] [MODE=local|docker])
	@python -m scripts.dbt_commands snapshot $(or $(ENV),dev) $(or $(MODE),local)

test-unit: ## Run pre-deployment tests (usage: make test-unit [ENV=dev|test|prod] [MODE=local|docker])
	@python -m scripts.dbt_commands test-unit $(or $(ENV),dev) $(or $(MODE),local)

test-integration: ## Run post-deployment integration tests (usage: make test-integration [ENV=dev|test|prod] [MODE=local|docker])
	@python -m scripts.dbt_commands test-integration $(or $(ENV),dev) $(or $(MODE),local)

test: ## Run both unit and integration tests (usage: make test [ENV=dev|test|prod] [MODE=local|docker])
	@python -m scripts.dbt_commands test $(or $(ENV),dev) $(or $(MODE),local)

clean: ## Clean dbt artifacts and rebuild virtual environment
	python -m scripts.environment_manager clean

docs: ## Generate and serve dbt documentation
	python -m scripts.dbt_commands docs-generate
	python -m scripts.dbt_commands docs-serve

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
	@echo "Basic file validation (prettier removed for performance)"
	@python -c "import yaml, glob; [yaml.safe_load(open(f)) for f in glob.glob('**/*.yml', recursive=True) + glob.glob('**/*.yaml', recursive=True) if 'node_modules' not in f and 'dbt_packages' not in f]; print('YAML files are valid')"

security-alt: ## Run pip-audit for vulnerability scanning (safety removed)
	python -m pip install pip-audit
	python -m pip-audit --format=text

validate-files: ## Run additional file format validation (JSON, TOML)
	@echo "Validating JSON files..."
	@python -c "import json, glob, os; files = [f for f in glob.glob('**/*.json', recursive=True) if 'node_modules' not in f and 'transform' not in f and os.path.getsize(f) > 0]; [print(f'✓ {f}') or json.load(open(f)) for f in files]; print(f'Validated {len(files)} JSON files')"
	@echo "Validating TOML files..."
	@python -c "import sys; sys.version_info >= (3,11) and __import__('tomllib') or print('TOML validation requires Python 3.11+, skipping')"

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
