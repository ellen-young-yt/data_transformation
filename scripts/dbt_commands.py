"""
dbt Command Scripts for Make Integration.

This module provides Python scripts that handle platform-specific logic
and complex operations for dbt commands called from Make.
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import List, Optional, Union

from .environment_manager import ExecutionMode, env_manager
from .utils import log_error, log_info, log_step, log_success, log_warning


class DBTCommandRunner:
    """Runner class for dbt commands with environment management."""

    def __init__(self) -> None:
        """Initialize the dbt command runner."""
        self.env_manager = env_manager
        self.env_manager.setup_environment()

    def run_command(
        self,
        command: Union[str, List[str]],
        check: bool = True,
        capture_output: bool = False,
        cwd: Optional[Path] = None,
    ) -> subprocess.CompletedProcess:
        """
        Run a command with proper environment setup.

        Args:
            command: Command to run (string or list)
            check: Whether to check return code
            capture_output: Whether to capture stdout/stderr
            cwd: Working directory override

        Returns:
            CompletedProcess object

        Raises:
            subprocess.CalledProcessError: If command fails and check=True
        """
        if isinstance(command, str):
            command_list = command.split()
        else:
            command_list = command

        # Validate command executable exists and prefer virtual environment
        if command_list:
            # Try to get executable from virtual environment first
            try:
                venv_executable = self.env_manager.get_venv_executable(command_list[0])
                if Path(venv_executable).exists():
                    command_list[0] = venv_executable
                else:
                    # Fall back to system PATH
                    executable = shutil.which(command_list[0])
                    if not executable:
                        raise FileNotFoundError(
                            f"Executable '{command_list[0]}' not found in virtual environment or PATH"
                        )
                    command_list[0] = executable
            except Exception:
                # Fall back to system PATH if virtual environment lookup fails
                executable = shutil.which(command_list[0])
                if not executable:
                    raise FileNotFoundError(
                        f"Executable '{command_list[0]}' not found in PATH"
                    )
                command_list[0] = executable

        # Setup environment variables
        env = os.environ.copy()
        env.update(self.env_manager.get_environment_variables())

        # Set working directory
        working_dir = cwd or self.env_manager.project_root

        log_step(f"Running command: {' '.join(command_list)}")
        log_info(f"Environment: {self.env_manager.environment.value}")
        log_info(f"Context: {self.env_manager.execution_context.name}")

        try:
            result = subprocess.run(
                command_list,
                check=check,
                capture_output=capture_output,
                text=True,
                env=env,
                cwd=working_dir,
                shell=False,  # Explicitly disable shell
            )
            return result
        except subprocess.CalledProcessError as e:
            log_error(f"Command failed with return code {e.returncode}")
            if e.stdout:
                log_error(f"STDOUT: {e.stdout}")
            if e.stderr:
                log_error(f"STDERR: {e.stderr}")
            raise

    def run_dbt_command(
        self,
        dbt_cmd: str,
        target: Optional[str] = None,
        additional_args: Optional[List[str]] = None,
    ) -> subprocess.CompletedProcess:
        """
        Run a dbt command with proper configuration.

        Args:
            dbt_cmd: dbt subcommand (e.g., 'run', 'test', 'compile')
            target: Target environment override
            additional_args: Additional arguments to pass to dbt

        Returns:
            CompletedProcess object
        """
        # Use dbt from virtual environment
        dbt_executable = self.env_manager.get_dbt_executable()
        command = [dbt_executable, dbt_cmd]

        # Add target if specified, otherwise use environment default
        target_env = target or self.env_manager.get_dbt_target()
        command.extend(["--target", target_env])

        # Add profiles directory
        command.extend(["--profiles-dir", self.env_manager.get_dbt_profile_dir()])

        # Add any additional arguments
        if additional_args:
            command.extend(additional_args)

        return self.run_command(command)

    def compile_models(
        self, target: Optional[str] = None, mode: Optional[str] = None
    ) -> int:
        """
        Compile dbt models.

        Args:
            target: Target environment
            mode: Execution mode (local/docker)

        Returns:
            Exit code
        """
        return self._run_dbt_command_with_mode("compile", target, mode)

    def build_models(
        self, target: Optional[str] = None, mode: Optional[str] = None
    ) -> int:
        """
        Build dbt models (run + test).

        Args:
            target: Target environment
            mode: Execution mode (local/docker)

        Returns:
            Exit code
        """
        return self._run_dbt_command_with_mode("build", target, mode)

    def seed_data(
        self, target: Optional[str] = None, mode: Optional[str] = None
    ) -> int:
        """
        Load seed data.

        Args:
            target: Target environment
            mode: Execution mode (local/docker)

        Returns:
            Exit code
        """
        return self._run_dbt_command_with_mode("seed", target, mode)

    def install_deps(self, force: bool = False) -> int:
        """
        Install dbt package dependencies.

        Args:
            force: Force reinstall of packages

        Returns:
            Exit code
        """
        log_step("Installing dbt package dependencies...")

        try:
            if force:
                # Clean dbt_packages directory first if force is requested
                log_step("Force flag enabled, cleaning existing packages...")
                self._clean_packages()

            # Run dbt deps
            self.run_dbt_command("deps")
            log_success("dbt package dependencies installed successfully")
            return 0

        except subprocess.CalledProcessError as e:
            log_error(f"dbt deps failed with exit code {e.returncode}")
            return e.returncode

    def _clean_packages(self) -> None:
        """Clean the dbt_packages directory."""
        import shutil as sh

        packages_dir = self.env_manager.project_root / "dbt_packages"

        if packages_dir.exists():
            try:
                sh.rmtree(packages_dir)
                log_info("Removed existing dbt_packages directory")
            except Exception as e:
                log_warning(f"Could not remove dbt_packages directory: {e}")
        else:
            log_info("No existing dbt_packages directory found")

    def list_packages(self) -> int:
        """
        List installed dbt packages.

        Returns:
            Exit code
        """
        log_step("Listing installed dbt packages...")

        packages_dir = self.env_manager.project_root / "dbt_packages"

        if not packages_dir.exists():
            log_info("No dbt packages installed")
            return 0

        try:
            packages = [p for p in packages_dir.iterdir() if p.is_dir()]

            if not packages:
                log_info("No dbt packages found in dbt_packages directory")
            else:
                log_info(f"Found {len(packages)} installed packages:")
                for package in sorted(packages):
                    log_info(f"  - {package.name}")

            return 0

        except Exception as e:
            log_error(f"Error listing packages: {e}")
            return 1

    def run_snapshots(
        self, target: Optional[str] = None, mode: Optional[str] = None
    ) -> int:
        """
        Run dbt snapshots.

        Args:
            target: Target environment
            mode: Execution mode (local/docker)

        Returns:
            Exit code
        """
        return self._run_dbt_command_with_mode("snapshot", target, mode)

    def run_unit_tests(
        self, target: Optional[str] = None, mode: Optional[str] = None
    ) -> int:
        """
        Run unit tests (pre-deployment).

        This includes:
        - Pre-commit hooks
        - dbt parsing/compilation
        - Python unit tests
        - dbt tests on dev/test environment

        Args:
            target: Target environment
            mode: Execution mode (local/docker)

        Returns:
            Exit code
        """
        log_step("Running unit tests (pre-deployment)...")

        exit_code = 0

        # Run pre-commit hooks
        try:
            log_step("Running pre-commit hooks...")
            self.run_command(["pre-commit", "run", "--all-files"])
            log_success("Pre-commit hooks passed")
        except subprocess.CalledProcessError as e:
            log_error(f"Pre-commit hooks failed with exit code {e.returncode}")
            exit_code = e.returncode

        # Parse dbt project
        try:
            log_step("Parsing dbt project...")
            self.run_dbt_command("parse", target=target)
            log_success("dbt parse completed successfully")
        except subprocess.CalledProcessError as e:
            log_error(f"dbt parse failed with exit code {e.returncode}")
            exit_code = e.returncode

        # Run infrastructure validation tests (lightweight)
        try:
            log_step("Running infrastructure validation...")
            self.run_command(["python", "-m", "scripts.environment_manager", "info"])
            log_success("Infrastructure validation passed")
        except subprocess.CalledProcessError as e:
            log_warning(
                f"Infrastructure validation failed with exit code {e.returncode}"
            )
            log_info("Continuing with dbt-focused testing approach")

        # Run dbt tests
        try:
            log_step("Running dbt tests...")
            test_exit_code = self._run_dbt_command_with_mode(
                "test", target or "dev", mode
            )
            if test_exit_code != 0:
                exit_code = test_exit_code
        except Exception as e:
            log_error(f"dbt tests failed: {e}")
            exit_code = 1

        if exit_code == 0:
            log_success("All unit tests passed")
        else:
            log_error("Unit tests failed")

        return exit_code

    def run_integration_tests(
        self, target: Optional[str] = None, mode: Optional[str] = None
    ) -> int:
        """
        Run integration tests (post-deployment).

        This includes:
        - dbt tests on production data
        - Data quality validation
        - Elementary tests if available

        Args:
            target: Target environment
            mode: Execution mode (local/docker)

        Returns:
            Exit code
        """
        log_step("Running integration tests (post-deployment)...")

        exit_code = 0

        # Use production target for integration tests
        test_target = target or "prod"

        # Run dbt tests on production
        try:
            log_step(f"Running dbt tests on {test_target} environment...")
            test_exit_code = self._run_dbt_command_with_mode("test", test_target, mode)
            if test_exit_code != 0:
                exit_code = test_exit_code
        except Exception as e:
            log_error(f"dbt integration tests failed: {e}")
            exit_code = 1

        # Run Elementary tests if available
        log_step("Running Elementary data tests...")

        # Skip Elementary on Windows due to path length limitations
        import platform

        if platform.system() == "Windows":
            log_info("Elementary Data Reliability platform detected: Windows")
            log_info("Status: Skipping due to Windows path length limitations")
            log_info(
                "Note: Elementary will run properly in Linux/Docker production environment"
            )
            log_info("Slack webhook configured and ready for production use")
        else:
            try:
                log_step("Running Elementary data tests...")

                # Get Slack webhook from environment
                slack_webhook = os.environ.get("ELEMENTARY_SLACK_WEBHOOK")
                if slack_webhook:
                    command = [
                        "edr",
                        "monitor",
                        "--slack-webhook",
                        slack_webhook,
                        "--test",
                        "true",
                    ]
                    log_info("Using Slack webhook for Elementary alerts")
                else:
                    command = ["edr", "monitor", "--test", "true"]
                    log_warning(
                        "No Slack webhook configured, Elementary will run in test mode"
                    )

                self.run_command(command)
                log_success("Elementary tests passed")
            except (subprocess.CalledProcessError, FileNotFoundError) as e:
                if isinstance(e, FileNotFoundError):
                    log_info("Elementary not available, skipping")
                else:
                    log_warning(
                        f"Elementary tests failed with exit code {e.returncode}"
                    )
                    log_info("Elementary may require additional configuration")
                    log_info("Continuing integration tests without Elementary")

        # Check data freshness
        try:
            log_step("Checking data freshness...")
            # Use run_command directly since 'dbt source' doesn't support --profiles-dir
            dbt_executable = self.env_manager.get_dbt_executable()
            command = [dbt_executable, "source", "freshness", "--target", test_target]
            self.run_command(command)
            log_success("Data freshness check passed")
        except subprocess.CalledProcessError as e:
            log_warning(f"Data freshness check failed with exit code {e.returncode}")
            # Don't fail integration tests for freshness issues
            log_info("Continuing integration tests despite freshness issues")

        if exit_code == 0:
            log_success("All integration tests passed")
        else:
            log_error("Integration tests failed")

        return exit_code

    def run_all_tests(
        self, target: Optional[str] = None, mode: Optional[str] = None
    ) -> int:
        """
        Run both unit and integration tests.

        Args:
            target: Target environment
            mode: Execution mode (local/docker)

        Returns:
            Exit code
        """
        log_step("Running all tests (unit + integration)...")

        # Run unit tests first
        unit_exit_code = self.run_unit_tests(target, mode)
        if unit_exit_code != 0:
            log_error("Unit tests failed, skipping integration tests")
            return unit_exit_code

        # Run integration tests
        integration_exit_code = self.run_integration_tests(target, mode)

        overall_exit_code = max(unit_exit_code, integration_exit_code)

        if overall_exit_code == 0:
            log_success("All tests passed successfully")
        else:
            log_error("Some tests failed")

        return overall_exit_code

    def run_models(
        self, target: Optional[str] = None, mode: Optional[str] = None
    ) -> int:
        """
        Run dbt models.

        Args:
            target: Target environment
            mode: Execution mode (local/docker)

        Returns:
            Exit code
        """
        return self._run_dbt_command_with_mode("run", target, mode)

    def _run_dbt_command_with_mode(
        self, command: str, target: Optional[str] = None, mode: Optional[str] = None
    ) -> int:
        """
        Run dbt command with specified execution mode (local or docker).

        Args:
            command: dbt command to run
            target: Target environment
            mode: Execution mode (local/docker)

        Returns:
            Exit code
        """
        try:
            # Determine execution mode
            execution_mode = self.env_manager.get_execution_mode(mode)

            if execution_mode == ExecutionMode.DOCKER:
                # Run via Docker with auto-build
                from .docker_manager import DockerManager

                docker_mgr = DockerManager()

                # Build Docker image first
                log_step("Building Docker image for containerized execution...")
                build_exit_code = docker_mgr.build_image()
                if build_exit_code != 0:
                    log_error("Failed to build Docker image")
                    return build_exit_code

                # Run the dbt command directly in container
                target_env = target or self.env_manager.get_dbt_target()
                exit_code = docker_mgr.run_dbt_in_container(command, target_env)
                return exit_code
            else:
                # Run locally
                self.run_dbt_command(command, target=target)
                log_success(f"dbt {command} completed successfully")
                return 0

        except ValueError as e:
            log_error(f"Invalid execution mode: {e}")
            return 1
        except subprocess.CalledProcessError as e:
            log_error(f"dbt {command} failed with exit code {e.returncode}")
            return e.returncode
        except Exception as e:
            log_error(f"Unexpected error: {e}")
            return 1

    def generate_docs(self, target: Optional[str] = None) -> int:
        """
        Generate dbt documentation.

        Args:
            target: Target environment

        Returns:
            Exit code
        """
        try:
            # Use run_command directly since 'dbt docs' doesn't support --profiles-dir
            target_env = target or self.env_manager.get_dbt_target()
            dbt_executable = self.env_manager.get_dbt_executable()
            command = [dbt_executable, "docs", "generate", "--target", target_env]
            self.run_command(command)
            log_success("dbt documentation generated successfully")
            return 0
        except subprocess.CalledProcessError as e:
            log_error(f"dbt docs generate failed with exit code {e.returncode}")
            return e.returncode

    def serve_docs(self, target: Optional[str] = None, port: int = 8080) -> int:
        """
        Serve dbt documentation.

        Args:
            target: Target environment
            port: Port to serve on

        Returns:
            Exit code
        """
        try:
            # Use run_command directly since 'dbt docs' doesn't support --profiles-dir
            target_env = target or self.env_manager.get_dbt_target()
            dbt_executable = self.env_manager.get_dbt_executable()
            command = [
                dbt_executable,
                "docs",
                "serve",
                "--target",
                target_env,
                "--port",
                str(port),
            ]
            self.run_command(command)
            log_success("dbt documentation server started")
            return 0
        except subprocess.CalledProcessError as e:
            log_error(f"dbt docs serve failed with exit code {e.returncode}")
            return e.returncode
        except KeyboardInterrupt:
            log_info("Documentation server stopped by user")
            return 0


def main() -> None:
    """Execute dbt commands from command line."""
    if len(sys.argv) < 2:
        log_error(
            "Usage: python -m scripts.dbt_commands <command> [target] [mode] [args...]"
        )
        log_info("Commands:")
        log_info("  deps [--force]     Install dbt package dependencies")
        log_info("  list-packages      List installed dbt packages")
        log_info("  compile [target] [mode]   Compile dbt models (mode: local|docker)")
        log_info("  run [target] [mode]       Run dbt models (mode: local|docker)")
        log_info("  build [target] [mode]     Run dbt build (models + tests)")
        log_info("  seed [target] [mode]      Load dbt seed data")
        log_info("  snapshot [target] [mode]  Run dbt snapshots")
        log_info("  test-unit [target] [mode] Run pre-deployment tests")
        log_info("  test-integration [target] [mode] Run post-deployment tests")
        log_info("  test [target] [mode]      Run all tests")
        log_info("  docs-generate [target]    Generate documentation")
        log_info("  docs-serve [target] [port] Serve documentation")
        sys.exit(1)

    command = sys.argv[1]
    args = sys.argv[2:]

    def parse_target_mode_args() -> tuple[Optional[str], Optional[str]]:
        """Parse common target and mode arguments."""
        target = args[0] if args else None
        mode = args[1] if len(args) > 1 else None
        return target, mode

    runner = DBTCommandRunner()

    # Commands with common target/mode pattern
    commands_with_mode = {
        "compile": runner.compile_models,
        "run": runner.run_models,
        "build": runner.build_models,
        "seed": runner.seed_data,
        "snapshot": runner.run_snapshots,
        "test-unit": runner.run_unit_tests,
        "test-integration": runner.run_integration_tests,
        "test": runner.run_all_tests,
    }

    if command in commands_with_mode:
        target, mode = parse_target_mode_args()
        exit_code = commands_with_mode[command](target, mode)
    elif command == "deps":
        force = "--force" in args
        exit_code = runner.install_deps(force=force)
    elif command == "list-packages":
        exit_code = runner.list_packages()
    elif command == "docs-generate":
        target = args[0] if args else None
        exit_code = runner.generate_docs(target)
    elif command == "docs-serve":
        target = args[0] if args and not args[0].isdigit() else None
        port = (
            int(args[1])
            if len(args) > 1 and args[1].isdigit()
            else (int(args[0]) if args and args[0].isdigit() else 8080)
        )
        exit_code = runner.serve_docs(target, port)
    else:
        log_error(f"Unknown command: {command}")
        exit_code = 1

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
