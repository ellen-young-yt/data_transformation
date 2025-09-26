"""
Complete Setup Orchestration Manager.

This module handles the complete initial setup for the dbt data transformation project
with environment awareness and cross-platform compatibility.
"""

import shutil
import subprocess
import sys

from .environment_manager import env_manager
from .utils import log_error, log_info, log_step, log_success, log_warning


class SetupManager:
    """Manager for complete project setup orchestration."""

    def __init__(self) -> None:
        """Initialize the setup manager."""
        self.env_manager = env_manager
        self.env_manager.setup_environment()

    def install_python_dependencies(self, force: bool = False) -> int:
        """
        Install Python dependencies using environment manager.

        Args:
            force: Force reinstallation

        Returns:
            Exit code
        """
        log_step("Installing Python dependencies...")

        try:
            if force:
                log_info("Force flag enabled, cleaning existing environment...")
                self.env_manager.clean_environment()

            # Use environment manager to install dependencies
            self.env_manager.install_dependencies()
            log_success("Python dependencies installed successfully")
            return 0

        except Exception as e:
            log_error(f"Python dependency installation failed: {e}")
            return 1

    def install_dbt_packages(self, force: bool = False) -> int:
        """
        Install dbt package dependencies.

        Args:
            force: Force reinstallation of packages

        Returns:
            Exit code
        """
        log_step("Installing dbt packages...")

        try:
            # Import and use DBTCommandRunner
            from .dbt_commands import DBTCommandRunner

            runner = DBTCommandRunner()
            exit_code = runner.install_deps(force=force)

            if exit_code == 0:
                log_success("dbt packages installed successfully")
            else:
                log_error("dbt package installation failed")

            return exit_code

        except Exception as e:
            log_error(f"dbt package installation failed: {e}")
            return 1

    def setup_pre_commit_hooks(self) -> int:
        """
        Set up pre-commit hooks.

        Returns:
            Exit code
        """
        log_step("Setting up pre-commit hooks...")

        try:
            # Check if pre-commit is available
            precommit_executable = shutil.which("pre-commit")
            if not precommit_executable:
                log_warning("pre-commit not found, skipping hook installation")
                log_info("Install pre-commit with: pip install pre-commit")
                return 0

            # Install pre-commit hooks
            command = [precommit_executable, "install"]

            log_step(f"Running: {' '.join(command)}")
            _ = subprocess.run(
                command,
                check=True,
                cwd=self.env_manager.project_root,
                shell=False,
            )

            log_success("Pre-commit hooks installed successfully")
            return 0

        except subprocess.CalledProcessError as e:
            log_error(
                f"Pre-commit hook installation failed with exit code {e.returncode}"
            )
            return e.returncode
        except Exception as e:
            log_error(f"Pre-commit hook installation failed: {e}")
            return 1

    def validate_environment_config(self) -> int:
        """
        Validate environment configuration.

        Returns:
            Exit code
        """
        log_step("Validating environment configuration...")

        exit_code = 0

        # Check for .env file
        env_file = self.env_manager.project_root / ".env"
        env_example = self.env_manager.project_root / ".env.example"

        if not env_file.exists():
            if env_example.exists():
                log_warning(".env file not found")
                log_info("Copy .env.example to .env and fill in your credentials")
                exit_code = 1
            else:
                log_warning("Neither .env nor .env.example found")
                exit_code = 1
        else:
            log_success(".env file found")

        # Check for essential dbt files
        dbt_project = self.env_manager.project_root / "dbt_project.yml"
        profiles_dir = self.env_manager.project_root / "profiles"

        if not dbt_project.exists():
            log_error("dbt_project.yml not found")
            exit_code = 1
        else:
            log_success("dbt_project.yml found")

        if not profiles_dir.exists():
            log_warning("profiles directory not found")
            log_info("dbt profiles may need to be configured")
        else:
            log_success("profiles directory found")

        # Check for Docker files if Docker commands are used
        dockerfile = self.env_manager.project_root / "Dockerfile"
        docker_compose = self.env_manager.project_root / "docker-compose.yml"

        if dockerfile.exists():
            log_success("Dockerfile found")
        if docker_compose.exists():
            log_success("docker-compose.yml found")

        if exit_code == 0:
            log_success("Environment configuration validation passed")
        else:
            log_warning("Environment configuration validation found issues")

        return exit_code

    def run_initial_tests(self) -> int:
        """
        Run initial validation tests.

        Returns:
            Exit code
        """
        log_step("Running initial validation tests...")

        try:
            # Import and use DBTCommandRunner for parsing
            from .dbt_commands import DBTCommandRunner

            runner = DBTCommandRunner()

            # Test dbt parsing
            log_step("Testing dbt project parsing...")
            try:
                runner.run_dbt_command("parse", target="dev")
                log_success("dbt project parsing successful")
            except subprocess.CalledProcessError as e:
                log_error(f"dbt project parsing failed with exit code {e.returncode}")
                return e.returncode

            # Test dbt compilation
            log_step("Testing dbt compilation...")
            try:
                runner.run_dbt_command("compile", target="dev")
                log_success("dbt compilation successful")
            except subprocess.CalledProcessError as e:
                log_warning(f"dbt compilation failed with exit code {e.returncode}")
                log_info(
                    "This may be expected if database credentials are not configured"
                )

            log_success("Initial validation tests completed")
            return 0

        except Exception as e:
            log_error(f"Initial validation tests failed: {e}")
            return 1

    def display_setup_summary(self) -> None:
        """Display setup completion summary and next steps."""
        log_success("Setup complete!")
        log_info("")
        log_info("Next steps:")
        log_info("1. Copy .env.example to .env and fill in your credentials")
        log_info("2. Run 'make lint' to check your code quality")
        log_info("3. Run 'make test-unit' to run pre-deployment tests")
        log_info("4. Run 'make compile' to compile your dbt models")
        log_info("")
        log_info("Available commands:")
        log_info("  make help           Show available commands")
        log_info("  make lint           Run linting checks")
        log_info("  make compile        Compile dbt models")
        log_info("  make run-dev        Run models in dev environment")
        log_info("  make test-unit      Run pre-deployment tests")
        log_info("  make docs           Generate and serve documentation")

    def run_complete_setup(
        self,
        force_python: bool = False,
        force_dbt: bool = False,
        skip_tests: bool = False,
    ) -> int:
        """
        Run complete project setup.

        Args:
            force_python: Force Python dependency reinstallation
            force_dbt: Force dbt package reinstallation
            skip_tests: Skip initial validation tests

        Returns:
            Exit code
        """
        log_step("Starting complete project setup...")

        exit_code = 0

        # Install Python dependencies
        python_exit = self.install_python_dependencies(force=force_python)
        if python_exit != 0:
            log_error("Python dependency installation failed, aborting setup")
            return python_exit

        # Install dbt packages
        dbt_exit = self.install_dbt_packages(force=force_dbt)
        if dbt_exit != 0:
            log_warning("dbt package installation failed, continuing setup")
            exit_code = dbt_exit

        # Setup pre-commit hooks
        precommit_exit = self.setup_pre_commit_hooks()
        if precommit_exit != 0:
            log_warning("Pre-commit hook setup failed, continuing setup")

        # Validate environment
        validation_exit = self.validate_environment_config()
        if validation_exit != 0:
            log_warning("Environment validation found issues, continuing setup")

        # Run initial tests unless skipped
        if not skip_tests:
            test_exit = self.run_initial_tests()
            if test_exit != 0:
                log_warning("Initial tests failed, setup may need configuration")

        # Display summary
        self.display_setup_summary()

        if exit_code == 0:
            log_success("Complete setup finished successfully")
        else:
            log_warning("Setup completed with some issues")

        return exit_code


def main() -> None:
    """Execute setup commands from command line."""
    if len(sys.argv) < 2:
        log_error("Usage: python -m scripts.setup <command> [args...]")
        log_info("Commands:")
        log_info("  install [--force]          Install Python dependencies")
        log_info("  deps [--force]             Install dbt packages")
        log_info("  precommit                  Setup pre-commit hooks")
        log_info("  validate                   Validate environment configuration")
        log_info("  test                       Run initial validation tests")
        log_info(
            "  complete [--force-python] [--force-dbt] [--skip-tests]  Run complete setup"
        )
        sys.exit(1)

    command = sys.argv[1]
    args = sys.argv[2:]

    setup_mgr = SetupManager()

    if command == "install":
        force = "--force" in args
        exit_code = setup_mgr.install_python_dependencies(force=force)
    elif command == "deps":
        force = "--force" in args
        exit_code = setup_mgr.install_dbt_packages(force=force)
    elif command == "precommit":
        exit_code = setup_mgr.setup_pre_commit_hooks()
    elif command == "validate":
        exit_code = setup_mgr.validate_environment_config()
    elif command == "test":
        exit_code = setup_mgr.run_initial_tests()
    elif command == "complete":
        force_python = "--force-python" in args
        force_dbt = "--force-dbt" in args
        skip_tests = "--skip-tests" in args
        exit_code = setup_mgr.run_complete_setup(
            force_python=force_python, force_dbt=force_dbt, skip_tests=skip_tests
        )
    else:
        log_error(f"Unknown command: {command}")
        exit_code = 1

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
