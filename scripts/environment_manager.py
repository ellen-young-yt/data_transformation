"""
Environment Manager for dbt Data Transformation Project.

This module provides centralized environment management functionality that:
- Detects the current execution context (local, CI/CD, Docker)
- Manages environment-specific configurations
- Handles cross-platform path formatting
- Provides unified access to environment variables and settings
"""

import os
import platform
import shutil
import subprocess
import sys
from enum import Enum, auto
from pathlib import Path
from typing import Dict, Optional, Union

from .utils import log_error, log_info, log_step, log_success, log_warning


class Platform(Enum):
    """Platform enumeration for type-safe platform detection."""

    WINDOWS = auto()
    LINUX = auto()
    MACOS = auto()
    UNKNOWN = auto()


class ExecutionContext(Enum):
    """Execution context enumeration for type-safe context detection."""

    LOCAL = auto()  # Local development environment
    DOCKER = auto()  # Docker container
    GITHUB_ACTIONS = auto()  # GitHub Actions CI/CD
    ECS = auto()  # AWS ECS/Fargate


class Environment(Enum):
    """Enumeration of supported deployment environments."""

    DEV = "dev"
    STAGING = "staging"
    PROD = "prod"


class ExecutionMode(Enum):
    """Enumeration of dbt execution modes."""

    LOCAL = "local"  # Native dbt execution
    DOCKER = "docker"  # Docker-based execution


class EnvironmentManager:
    """
    Centralized environment management for the dbt project.

    Handles environment detection, configuration management, and cross-platform
    compatibility for the data transformation project.
    """

    def __init__(self, env_override: Optional[str] = None):
        """
        Initialize the environment manager.

        Args:
            env_override: Optional environment override (dev, staging, prod)
        """
        # Detection (computed once at initialization)
        self._platform = self._detect_platform()
        self._execution_context = self._detect_execution_context()
        self._environment = self._determine_environment(env_override)

        # Paths
        self._project_root = self._detect_project_root()

    @property
    def project_root(self) -> Path:
        """Get the project root directory."""
        return self._project_root

    @property
    def execution_context(self) -> ExecutionContext:
        """Get the current execution context."""
        return self._execution_context

    @property
    def environment(self) -> Environment:
        """Get the current environment."""
        return self._environment

    @property
    def platform(self) -> Platform:
        """Get the current platform."""
        return self._platform

    def get_dbt_profile_dir(self) -> str:
        """Get the dbt profiles directory path."""
        if self._execution_context in (ExecutionContext.DOCKER, ExecutionContext.ECS):
            return "/var/task/profiles"
        return str(self.project_root / "profiles")

    def get_dbt_project_dir(self) -> str:
        """Get the dbt project directory path."""
        if self._execution_context in (ExecutionContext.DOCKER, ExecutionContext.ECS):
            return "/var/task"
        return str(self.project_root)

    def get_virtual_env_path(self) -> Path:
        """Get the virtual environment path."""
        venv_name = "transform"
        if self._platform == Platform.WINDOWS:
            return self.project_root / venv_name / "Scripts"
        return self.project_root / venv_name / "bin"

    def get_python_executable(self) -> str:
        """Get the Python executable path."""
        if self._execution_context in (ExecutionContext.DOCKER, ExecutionContext.ECS):
            return "python"

        venv_path = self.get_virtual_env_path()
        if self._platform == Platform.WINDOWS:
            return str(venv_path / "python.exe")
        return str(venv_path / "python")

    def get_pip_executable(self) -> str:
        """Get the pip executable path."""
        if self._execution_context in (ExecutionContext.DOCKER, ExecutionContext.ECS):
            return "pip"

        venv_path = self.get_virtual_env_path()
        if self._platform == Platform.WINDOWS:
            return str(venv_path / "pip.exe")
        return str(venv_path / "pip")

    def get_sqlfluff_executable(self) -> str:
        """Get the sqlfluff executable path."""
        if self._execution_context in (ExecutionContext.DOCKER, ExecutionContext.ECS):
            return "sqlfluff"

        venv_path = self.get_virtual_env_path()
        if self._platform == Platform.WINDOWS:
            return str(venv_path / "sqlfluff.exe")
        return str(venv_path / "sqlfluff")

    def get_dbt_executable(self) -> str:
        """Get the dbt executable path from virtual environment."""
        if self._execution_context in (ExecutionContext.DOCKER, ExecutionContext.ECS):
            return "dbt"

        venv_path = self.get_virtual_env_path()
        if self._platform == Platform.WINDOWS:
            return str(venv_path / "dbt.exe")
        return str(venv_path / "dbt")

    def get_venv_executable(self, executable_name: str) -> str:
        """Get any executable path from virtual environment."""
        if self._execution_context in (ExecutionContext.DOCKER, ExecutionContext.ECS):
            return executable_name

        venv_path = self.get_virtual_env_path()
        if self._platform == Platform.WINDOWS:
            return str(venv_path / f"{executable_name}.exe")
        return str(venv_path / executable_name)

    def get_dbt_target(self) -> str:
        """Get the appropriate dbt target for the current environment."""
        if self.environment == Environment.DEV:
            return "dev"
        elif self.environment == Environment.STAGING:
            return "test"  # staging uses test target in current setup
        elif self.environment == Environment.PROD:
            return "prod"
        else:
            # This should never happen with proper enum usage
            raise ValueError(f"Unknown environment: {self.environment}")

    # === DOCKER AND EXECUTION MODE METHODS ===

    def get_docker_service_name(self, base_name: str = "data-transformation") -> str:
        """
        Get Docker service name for current environment.

        Args:
            base_name: Base name for the service

        Returns:
            Environment-specific Docker service name
        """
        if self.environment == Environment.DEV:
            return f"{base_name}-dev"
        elif self.environment == Environment.STAGING:
            return f"{base_name}-test"  # staging uses test service
        elif self.environment == Environment.PROD:
            return base_name  # production uses base name
        else:
            # Fallback for any unexpected environment values
            return base_name

    def supports_docker_execution(self) -> bool:
        """
        Check if docker execution is available and appropriate.

        Returns:
            True if Docker execution is supported in current context
        """
        # Docker execution typically not available in CI/CD or already in Docker
        if self._execution_context in (
            ExecutionContext.GITHUB_ACTIONS,
            ExecutionContext.DOCKER,
            ExecutionContext.ECS,
        ):
            return False

        # Check if docker is available in PATH
        return shutil.which("docker") is not None

    def get_execution_mode(self, requested_mode: Optional[str] = None) -> ExecutionMode:
        """
        Determine execution mode (local/docker) based on context and request.

        Args:
            requested_mode: Explicitly requested mode (local/docker)

        Returns:
            Execution mode enum value

        Raises:
            ValueError: If requested mode is invalid or unsupported
        """
        # Validate requested mode
        if requested_mode:
            try:
                mode_enum = ExecutionMode(requested_mode)
            except ValueError:
                valid_modes = [mode.value for mode in ExecutionMode]
                raise ValueError(
                    f"Invalid execution mode '{requested_mode}'. Must be one of: {valid_modes}"
                )
        else:
            # Default to local execution
            mode_enum = ExecutionMode.LOCAL

        # Validate requested mode is supported
        if mode_enum == ExecutionMode.DOCKER:
            if not self.supports_docker_execution():
                if self._execution_context == ExecutionContext.GITHUB_ACTIONS:
                    raise ValueError(
                        "Docker execution not supported in CI/CD environment"
                    )
                elif self._execution_context in (
                    ExecutionContext.DOCKER,
                    ExecutionContext.ECS,
                ):
                    raise ValueError(
                        "Docker execution not supported when already running in container"
                    )
                else:
                    raise ValueError("Docker not available in PATH")

        return mode_enum

    def get_environment_variables(self) -> Dict[str, str]:
        """Get environment-specific variables."""
        base_vars = {
            "DBT_PROFILES_DIR": self.get_dbt_profile_dir(),
            "DBT_PROJECT_DIR": self.get_dbt_project_dir(),
            "DBT_TARGET": self.get_dbt_target(),
            "ENVIRONMENT": self.environment.value,
            "EXECUTION_CONTEXT": self.execution_context.name.lower(),
            "PLATFORM": self.platform.name.lower(),
        }

        # Add context-specific variables
        if self._execution_context == ExecutionContext.DOCKER:
            base_vars.update(
                {
                    "DBT_PROFILES_DIR": "/var/task/profiles",
                    "DBT_PROJECT_DIR": "/var/task",
                }
            )

        return base_vars

    def format_path(self, path: Union[str, Path]) -> str:
        """
        Format a path appropriately for the current platform.

        Args:
            path: Path to format

        Returns:
            Formatted path string
        """
        path_obj = Path(path)

        if self._execution_context in (ExecutionContext.DOCKER, ExecutionContext.ECS):
            # Use forward slashes for Docker/ECS
            return str(path_obj).replace("\\", "/")

        return str(path_obj)

    def get_secrets_config(self) -> Dict[str, str]:
        """Get secrets configuration based on environment."""
        base_config = {
            "secret_name": f"ellen-young-yt/{self.environment.value}/snowflake/credentials",
            "aws_region": os.getenv(
                "AWS_REGION", "us-east-2"
            ),  # Default to us-east-2, allow override
        }

        if self.environment == Environment.DEV:
            base_config[
                "secret_name"
            ] = "ellen-young-yt/dev/snowflake/credentials"  # pragma: allowlist secret  # nosec
        elif self.environment == Environment.STAGING:
            base_config[
                "secret_name"
            ] = "ellen-young-yt/staging/snowflake/credentials"  # pragma: allowlist secret  # nosec
        elif self.environment == Environment.PROD:
            base_config[
                "secret_name"
            ] = "ellen-young-yt/prod/snowflake/credentials"  # pragma: allowlist secret  # nosec

        return base_config

    # === DETECTION METHODS ===

    def _detect_platform(self) -> Platform:
        """Detect the current platform."""
        system = platform.system().lower()
        if system == "windows":
            return Platform.WINDOWS
        elif system == "linux":
            return Platform.LINUX
        elif system == "darwin":
            return Platform.MACOS
        else:
            return Platform.UNKNOWN

    def _detect_project_root(self) -> Path:
        """Detect the project root directory."""
        current = Path.cwd()

        # Look for dbt_project.yml to identify the root
        for path in [current] + list(current.parents):
            if (path / "dbt_project.yml").exists():
                return path

        # Fallback to current directory
        return current

    def _detect_execution_context(self) -> ExecutionContext:
        """Detect the current execution context."""
        # Check for ECS metadata
        if os.getenv("AWS_EXECUTION_ENV") == "AWS_ECS_FARGATE" or os.getenv(
            "ECS_CONTAINER_METADATA_URI"
        ):
            return ExecutionContext.ECS

        # Check for GitHub Actions
        if os.getenv("GITHUB_ACTIONS") == "true":
            return ExecutionContext.GITHUB_ACTIONS

        # Check for Docker
        if os.path.exists("/.dockerenv") or os.getenv("DOCKER_CONTAINER") == "true":
            return ExecutionContext.DOCKER

        # Default to local
        return ExecutionContext.LOCAL

    def _determine_environment(self, override: Optional[str]) -> Environment:
        """Determine the current environment."""
        if override:
            try:
                return Environment(override.lower())
            except ValueError:
                pass

        # Check environment variable
        env_var = os.getenv("ENVIRONMENT", "").lower()
        if env_var:
            try:
                return Environment(env_var)
            except ValueError:
                pass

        # Enhanced GitHub Actions environment detection
        if self._execution_context == ExecutionContext.GITHUB_ACTIONS:
            # Get GitHub Actions inputs from environment variables
            event_name = os.getenv(
                "INPUT_EVENT_NAME", os.getenv("GITHUB_EVENT_NAME", "")
            )
            ref_name = os.getenv("INPUT_REF_NAME", os.getenv("GITHUB_REF_NAME", ""))
            base_ref = os.getenv("INPUT_BASE_REF", "")
            manual_environment = os.getenv("INPUT_MANUAL_ENVIRONMENT", "")

            # Determine target branch based on event type (matches bash script logic)
            target_branch = ""
            if event_name == "workflow_dispatch" and manual_environment:
                # Manual deployment with explicit environment
                target_branch = manual_environment
            elif event_name == "pull_request" and base_ref:
                # For PRs, use the target branch (base)
                target_branch = base_ref
            elif ref_name:
                # For push events, use the current branch
                target_branch = ref_name
            else:
                # Fallback to legacy GITHUB_REF parsing
                github_ref = os.getenv("GITHUB_REF", "")
                if "main" in github_ref:
                    return Environment.PROD
                elif "staging" in github_ref:
                    return Environment.STAGING
                elif "develop" in github_ref:
                    return Environment.DEV

            # Map target branch to environment (matches bash script logic)
            if target_branch in ["main", "prod"]:
                return Environment.PROD
            elif target_branch in ["staging", "test"]:
                return Environment.STAGING
            else:  # develop, dev, or any other branch
                return Environment.DEV

        # Default to dev
        return Environment.DEV

    def load_dotenv(self) -> None:
        """Load environment variables from .env file if available."""
        try:
            from dotenv import load_dotenv

            env_file = self.project_root / ".env"
            if env_file.exists():
                load_dotenv(env_file)
                log_info(f"Loaded environment variables from {env_file}")
        except ImportError:
            # dotenv not available, skip
            pass

    def load_aws_secrets(self) -> bool:
        """
        Load secrets from AWS Secrets Manager.

        Returns:
            True if secrets were loaded successfully, False otherwise
        """
        # Only load AWS secrets for staging/production or when explicitly requested
        if (
            self.environment == Environment.DEV
            and not os.getenv("USE_AWS_SECRETS", "").lower() == "true"
        ):
            return False

        try:
            import json

            import boto3

            secrets_config = self.get_secrets_config()
            secret_name = secrets_config["secret_name"]
            aws_region = secrets_config["aws_region"]

            log_step(f"Loading secrets from AWS Secrets Manager: {secret_name}")

            # Create a Secrets Manager client
            session = boto3.session.Session()
            client = session.client(
                service_name="secretsmanager", region_name=aws_region
            )

            # Retrieve the secret
            response = client.get_secret_value(SecretId=secret_name)
            secret_data = json.loads(response["SecretString"])

            # Set environment variables
            for key, value in secret_data.items():
                # Handle special cases for key-pair authentication
                if key.lower() in ["private_key", "privatekey"]:
                    env_key = "SNOWFLAKE_PRIVATE_KEY"
                elif key.lower() in ["private_key_passphrase", "passphrase"]:
                    env_key = "SNOWFLAKE_PRIVATE_KEY_PASSPHRASE"
                else:
                    env_key = f"SNOWFLAKE_{key.upper()}"

                os.environ[env_key] = str(value)

            log_success(f"Successfully loaded {len(secret_data)} secrets from AWS")
            return True

        except ImportError:
            log_warning("boto3 not available, cannot load AWS secrets")
            return False
        except Exception as e:
            log_warning(f"Failed to load AWS secrets: {e}")
            return False

    def _ensure_virtual_environment(self) -> None:
        """
        Ensure we're running in the project's virtual environment.

        If not already in venv and venv exists, re-execute the current script
        using the venv's Python interpreter.
        """
        # Check if we're already in the virtual environment
        venv_python = self.get_python_executable()
        current_python = sys.executable

        # Normalize paths for comparison
        venv_python_normalized = os.path.normpath(os.path.abspath(venv_python))
        current_python_normalized = os.path.normpath(os.path.abspath(current_python))

        # If we're already using the venv Python, nothing to do
        if venv_python_normalized == current_python_normalized:
            return

        # If venv doesn't exist, skip auto-activation
        if not os.path.exists(venv_python):
            log_warning(f"Virtual environment not found at {venv_python}")
            log_info(
                "Run 'make install' or 'make setup' to create the virtual environment"
            )
            return

        # Re-execute current script with venv Python
        log_info(f"Auto-activating virtual environment: {venv_python}")

        try:
            # Detect if we were called as a module (python -m scripts.module_name)
            # This happens when sys.argv[0] ends with a .py file in the scripts directory
            script_path = Path(sys.argv[0])
            if script_path.suffix == ".py" and script_path.parent.name == "scripts":
                # Convert back to module syntax
                module_name = f"scripts.{script_path.stem}"
                cmd = [venv_python, "-m", module_name] + sys.argv[1:]
            else:
                # Direct script execution
                cmd = [venv_python] + sys.argv

            log_info(f"Re-executing with venv: {' '.join(cmd)}")

            # Execute and exit with the same code
            result = subprocess.run(cmd, cwd=self.project_root)
            sys.exit(result.returncode)

        except Exception as e:
            log_warning(f"Failed to auto-activate virtual environment: {e}")
            log_info("Continuing with current Python interpreter")

    def setup_environment(self) -> None:
        """Set up the environment with necessary configurations."""
        log_step(
            f"Setting up environment: {self.environment.value} ({self.execution_context.value})"
        )

        # Auto-activate virtual environment if not already active
        self._ensure_virtual_environment()

        # Load .env file first to get USE_AWS_SECRETS setting
        self.load_dotenv()

        # Try AWS secrets for staging/prod or when explicitly requested
        secrets_loaded = self.load_aws_secrets()

        # Set environment variables (won't override AWS secrets)
        env_vars = self.get_environment_variables()
        for key, value in env_vars.items():
            os.environ.setdefault(key, value)

        # Validate we have required credentials
        self._validate_credentials(secrets_loaded)

    def _validate_credentials(self, aws_secrets_loaded: bool) -> None:
        """
        Validate that required Snowflake credentials are available.

        Args:
            aws_secrets_loaded: Whether AWS secrets were successfully loaded
        """
        required_vars = ["SNOWFLAKE_ACCOUNT", "SNOWFLAKE_USER"]
        missing_vars = []

        for var in required_vars:
            if not os.getenv(var):
                missing_vars.append(var)

        if missing_vars:
            log_warning(f"Missing required credentials: {', '.join(missing_vars)}")
            if self.environment == Environment.DEV:
                log_info(
                    "For development, create a .env file with your Snowflake credentials"
                )
                log_info("Copy .env.example to .env and fill in your values")
            else:
                log_info(
                    f"For {self.environment.value}, ensure AWS Secrets Manager is configured"
                )
        else:
            source = "AWS Secrets Manager" if aws_secrets_loaded else ".env file"
            log_success(f"Snowflake credentials loaded from {source}")

    # === DEBUG/INFO METHODS ===

    def get_environment_info(self) -> str:
        """Get a human-readable description of the current environment."""
        platform_name = self.platform.name.title()
        context_name = self.execution_context.name.replace("_", " ").title()
        environment_name = self.environment.value.upper()
        return (
            f"{platform_name} platform in {context_name} context ({environment_name})"
        )

    def print_info(self) -> None:
        """Print environment information for debugging."""
        log_info("Environment Manager Info:")
        log_info(f"  Description: {self.get_environment_info()}")
        log_info(f"  Project Root: {self.project_root}")
        log_info(f"  Environment: {self.environment.value}")
        log_info(f"  Execution Context: {self.execution_context.name.lower()}")
        log_info(f"  Platform: {self.platform.name.lower()}")
        log_info(f"  dbt Target: {self.get_dbt_target()}")
        log_info(f"  dbt Profiles Dir: {self.get_dbt_profile_dir()}")
        log_info(f"  dbt Project Dir: {self.get_dbt_project_dir()}")
        log_info(f"  Docker Service Name: {self.get_docker_service_name()}")
        log_info(f"  Supports Docker: {self.supports_docker_execution()}")

    def output_github_actions_format(self) -> None:
        """Output environment configuration in GitHub Actions format."""
        # Get GitHub Actions specific values
        event_name = os.getenv("INPUT_EVENT_NAME", os.getenv("GITHUB_EVENT_NAME", ""))
        is_pull_request = event_name == "pull_request"
        is_production = self.environment == Environment.PROD

        # Skip integration tests for dev environment (matches bash script logic)
        skip_integration_tests = self.environment == Environment.DEV

        # Build configuration dictionary
        config = {
            "environment": self.environment.value,
            "dbt-target": self.get_dbt_target(),
            "is-production": str(is_production).lower(),
            "is-pull-request": str(is_pull_request).lower(),
            "skip-integration-tests": str(skip_integration_tests).lower(),
            "aws-region": "us-east-2",
            "aws-account-id": "891612547191",
            "ecr-repository": "data-transformation",
        }

        # Write to GitHub Actions outputs
        github_output = os.getenv("GITHUB_OUTPUT")
        if github_output:
            try:
                with open(github_output, "a") as f:
                    for key, value in config.items():
                        f.write(f"{key}={value}\n")
                log_info("Environment configuration written to GitHub outputs")
            except Exception as e:
                log_error(f"Failed to write GitHub outputs: {e}")
                raise

        # Write to GitHub Actions environment variables
        github_env = os.getenv("GITHUB_ENV")
        if github_env:
            try:
                with open(github_env, "a") as f:
                    f.write(f"ENVIRONMENT={config['environment']}\n")
                    f.write(f"DBT_TARGET={config['dbt-target']}\n")
                    f.write(f"AWS_REGION={config['aws-region']}\n")
                    f.write(f"AWS_ACCOUNT_ID={config['aws-account-id']}\n")
                    f.write(f"ECR_REPOSITORY_NAME={config['ecr-repository']}\n")
                    f.write("USE_AWS_SECRETS=true\n")
                    f.write(f"IS_PRODUCTION={config['is-production']}\n")
                log_info("Environment variables written to GitHub environment")
            except Exception as e:
                log_error(f"Failed to write GitHub environment: {e}")
                raise

        # Write to GitHub Actions step summary (optional)
        github_step_summary = os.getenv("GITHUB_STEP_SUMMARY")
        if github_step_summary:
            try:
                with open(github_step_summary, "a") as f:
                    f.write("## Environment Configuration\n")
                    f.write(f"- **Event**: {event_name}\n")
                    f.write(f"- **Environment**: {config['environment']}\n")
                    f.write(f"- **dbt Target**: {config['dbt-target']}\n")
                    f.write(f"- **Is Production**: {config['is-production']}\n")
                    f.write(f"- **Is Pull Request**: {config['is-pull-request']}\n")
                    f.write(
                        f"- **Skip Integration Tests**: {config['skip-integration-tests']}\n"
                    )
                    f.write(f"- **AWS Region**: {config['aws-region']}\n")
                log_info("Environment summary written to GitHub step summary")
            except Exception as e:
                log_warning(f"Failed to write GitHub step summary: {e}")
                # Don't raise on summary failure, it's optional

        # Log configuration for debugging
        log_info("GitHub Actions environment configuration:")
        for key, value in config.items():
            log_info(f"  {key}: {value}")

    def install_dependencies(self) -> int:
        """
        Install Python dependencies with platform-specific handling.

        Returns:
            Exit code
        """
        import subprocess

        log_step("Installing Python dependencies...")

        # Create virtual environment
        venv_dir = self.project_root / "transform"
        pip_path = self.get_virtual_env_path() / (
            "pip.exe" if self._platform == Platform.WINDOWS else "pip"
        )

        try:
            log_step("Creating virtual environment...")
            if venv_dir.exists() and pip_path.exists():
                log_info(
                    "Virtual environment already exists and is properly configured"
                )
            else:
                if venv_dir.exists():
                    log_info(
                        "Virtual environment exists but is incomplete, removing..."
                    )
                    # Force remove on Windows
                    if self._platform == Platform.WINDOWS:
                        subprocess.run(
                            ["taskkill", "/F", "/IM", "python.exe"], capture_output=True
                        )
                        subprocess.run(
                            ["rmdir", "/S", "/Q", str(venv_dir)],
                            capture_output=True,
                            shell=False,
                        )
                    else:
                        shutil.rmtree(venv_dir)

                python_exe = shutil.which("python") or sys.executable
                subprocess.run(
                    [python_exe, "-m", "venv", str(venv_dir), "--upgrade-deps"],
                    check=True,
                    cwd=self.project_root,
                    shell=False,
                )
                log_success("Virtual environment created")
        except subprocess.CalledProcessError as e:
            log_warning(f"Virtual environment creation had issues: {e}")
            # If venv creation failed, remove the directory to avoid partial state
            if venv_dir.exists():
                try:
                    shutil.rmtree(venv_dir)
                except Exception as e:
                    log_warning(f"Could not clean up partial virtual environment: {e}")

        # Install requirements
        try:
            log_step("Installing requirements...")
            pip_cmd = self.get_pip_executable()

            # Verify pip executable exists
            if not Path(pip_cmd).exists():
                raise FileNotFoundError(
                    f"pip not found at expected location: {pip_cmd}"
                )

            log_info(f"Using pip: {pip_cmd}")
            subprocess.run(
                [pip_cmd, "install", "-r", "requirements.txt"],
                check=True,
                cwd=self.project_root,
                shell=False,
            )
            log_success("Dependencies installed successfully")
            return 0
        except FileNotFoundError as e:
            log_error(f"pip executable not found: {e}")
            log_error("Virtual environment may not be properly created")
            return 1
        except subprocess.CalledProcessError as e:
            log_error(f"Failed to install dependencies: {e}")
            return e.returncode

    def clean_environment(self) -> int:
        """
        Clean dbt artifacts and rebuild virtual environment.

        Returns:
            Exit code
        """
        import shutil
        import subprocess

        log_step("Cleaning environment...")

        # Clean dbt artifacts - don't fail the whole process if this has issues
        try:
            dbt_executable = self.get_dbt_executable()
            if Path(dbt_executable).exists():
                result = subprocess.run(
                    [
                        dbt_executable,
                        "clean",
                        "--profiles-dir",
                        self.get_dbt_profile_dir(),
                    ],
                    capture_output=True,
                    cwd=self.project_root,
                    shell=False,
                )
                if result.returncode == 0:
                    log_success("dbt artifacts cleaned")
                else:
                    log_info("dbt clean completed (may have shown warnings)")
            else:
                log_info("dbt not found, skipping artifact cleanup")
        except Exception as e:
            log_info(f"Skipping dbt clean: {e}")

        # Remove virtual environment
        venv_dir = self.project_root / "transform"
        if venv_dir.exists():
            try:
                # Force remove on Windows
                if self._platform == Platform.WINDOWS:
                    subprocess.run(
                        ["taskkill", "/F", "/IM", "python.exe"], capture_output=True
                    )
                    result = subprocess.run(
                        ["rmdir", "/S", "/Q", str(venv_dir)],
                        capture_output=True,
                        shell=False,
                    )
                    if result.returncode != 0:
                        # Fallback to shutil if rmdir fails
                        shutil.rmtree(venv_dir)
                else:
                    shutil.rmtree(venv_dir)
                log_success("Virtual environment removed")
            except Exception as e:
                log_warning(f"Could not remove virtual environment: {e}")
                log_info(
                    "You may need to close any Python processes and run 'make clean' again"
                )

        log_success("Environment cleaned")
        return 0


def main() -> None:
    """Execute environment management commands from command line."""
    if len(sys.argv) < 2:
        log_error("Usage: python -m scripts.environment_manager <command> [args...]")
        log_info("Commands: install, clean, info, github-actions")
        sys.exit(1)

    command = sys.argv[1]
    env_mgr = EnvironmentManager()

    if command == "install":
        exit_code = env_mgr.install_dependencies()
    elif command == "clean":
        exit_code = env_mgr.clean_environment()
    elif command == "info":
        env_mgr.print_info()
        exit_code = 0
    elif command == "github-actions":
        env_mgr.output_github_actions_format()
        exit_code = 0
    else:
        log_error(f"Unknown command: {command}")
        exit_code = 1

    sys.exit(exit_code)


# Global instance for easy access
env_manager = EnvironmentManager()


if __name__ == "__main__":
    main()
