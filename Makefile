.PHONY: help install deps lint lint-fix test test-unit test-integration compile build seed snapshot run clean docs docker-build docker-run setup pre-commit

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@echo '  help            Show this help message'
	@echo '  setup           Complete initial setup'
	@echo '  validate        Validate project structure and environment'
	@echo '  install         Install Python dependencies'
	@echo '  deps            Install dbt packages'
	@echo '  lint            Run all linting checks'
	@echo '  lint-fix        Fix linting issues automatically'
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
	@echo '  pre-commit      Run all pre-commit hooks on all files'

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
