.PHONY: help install deps lint test run clean docs docker-build docker-run

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@echo '  help            Show this help message'
	@echo '  install         Install Python dependencies'
	@echo '  deps            Install dbt packages'
	@echo '  lint            Run linting'
	@echo '  lint-fix        Fix linting issues'
	@echo '  test            Run dbt tests'
	@echo '  run             Run dbt models'
	@echo '  run-dev         Run dbt models in dev environment'
	@echo '  run-test        Run dbt models in test environment'
	@echo '  run-prod        Run dbt models in production environment'
	@echo '  clean           Clean dbt artifacts'
	@echo '  docs            Generate dbt docs'
	@echo '  docker-build    Build Docker image'
	@echo '  docker-run      Run dbt in Docker'
	@echo '  docker-run-dev  Run dbt in Docker (dev environment)'
	@echo '  docker-run-test Run dbt in Docker (test environment)'
	@echo '  setup           Initial setup'

install: ## Install Python dependencies
	python -m venv transform --upgrade-deps || true
	python -m pip install -r requirements.txt

deps: ## Install dbt packages
	dbt deps

lint: ## Run linting
	pre-commit run --all-files
	sqlfluff lint models/ tests/ macros/

lint-fix: ## Fix linting issues
	pre-commit run --all-files
	sqlfluff fix models/ tests/ macros/

test: ## Run dbt tests
	python -c "from dotenv import load_dotenv; load_dotenv(); import os; os.system('dbt test --profiles-dir profiles')"

run: deps ## Run dbt models
	python -c "from dotenv import load_dotenv; load_dotenv(); import os; os.system('dbt run --profiles-dir profiles')"

run-dev: deps ## Run dbt models in dev environment
	python -c "from dotenv import load_dotenv; load_dotenv(); import os; os.system('dbt run --target dev --profiles-dir profiles')"

run-test: deps ## Run dbt models in test environment
	python -c "from dotenv import load_dotenv; load_dotenv(); import os; os.system('dbt run --target test --profiles-dir profiles')"

run-prod: deps ## Run dbt models in production environment
	python -c "from dotenv import load_dotenv; load_dotenv(); import os; os.system('dbt run --target prod --profiles-dir profiles')"

clean: ## Clean dbt artifacts
	dbt clean --profiles-dir profiles || true

docs: ## Generate dbt docs
	python -c "from dotenv import load_dotenv; load_dotenv(); import os; os.system('dbt docs generate --profiles-dir profiles')"
	python -c "from dotenv import load_dotenv; load_dotenv(); import os; os.system('dbt docs serve --profiles-dir profiles')"

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
