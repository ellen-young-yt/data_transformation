.PHONY: help install deps lint test run clean docs docker-build docker-run

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install Python dependencies
	@if [ ! -d "venv" ]; then \
		echo "Creating virtual environment..."; \
		python -m venv venv; \
	fi
	@echo "Installing Python dependencies..."
	@if [ -f "venv/Scripts/activate" ]; then \
		venv/Scripts/activate && pip install -r requirements.txt; \
	elif [ -f "venv/bin/activate" ]; then \
		venv/bin/activate && pip install -r requirements.txt; \
	else \
		pip install -r requirements.txt; \
	fi

deps: ## Install dbt packages
	dbt deps

lint: ## Run linting
	pre-commit run --all-files
	sqlfluff lint models/ tests/ macros/

lint-fix: ## Fix linting issues
	pre-commit run --all-files
	sqlfluff fix models/ tests/ macros/

test: ## Run dbt tests
	dbt test

run: deps ## Run dbt models
	dbt run

run-dev: deps ## Run dbt models in dev environment
	dbt run --target dev

run-test: deps ## Run dbt models in test environment
	dbt run --target test

run-prod: deps ## Run dbt models in production environment
	dbt run --target prod

clean: ## Clean dbt artifacts
	dbt clean

docs: ## Generate dbt docs
	dbt docs generate
	dbt docs serve

docker-build: ## Build Docker image
	docker build -t data-transformation .

docker-run: ## Run dbt in Docker
	docker-compose up data-transformation

docker-run-dev: ## Run dbt in Docker (dev environment)
	docker-compose up data-transformation-dev

docker-run-test: ## Run dbt in Docker (test environment)
	docker-compose up data-transformation-test

setup: install deps ## Initial setup
	@echo "Setup complete! Don't forget to:"
	@echo "1. Copy env.example to .env and fill in your credentials"
	@echo "2. Run 'make lint' to check your code"
	@echo "3. Run 'make test' to test your models"
