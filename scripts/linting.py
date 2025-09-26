"""
Centralized Linting Manager.

This module handles all code quality and linting operations with environment awareness.
"""

import os
import shutil
import subprocess
import sys
from typing import List, Optional

from .environment_manager import env_manager
from .utils import log_error, log_info, log_step, log_success, log_warning


class LintingManager:
    """Manager for all linting and code quality operations."""

    def __init__(self) -> None:
        """Initialize the linting manager."""
        self.env_manager = env_manager
        self.env_manager.setup_environment()

    def run_pre_commit(self, all_files: bool = True, fix: bool = False) -> int:
        """
        Run pre-commit hooks.

        Args:
            all_files: Run on all files (default) or only staged files
            fix: Attempt to fix issues automatically

        Returns:
            Exit code
        """
        log_step("Running pre-commit hooks...")

        try:
            # Check if pre-commit is available
            precommit_executable = shutil.which("pre-commit")
            if not precommit_executable:
                raise FileNotFoundError("pre-commit executable not found in PATH")

            # Build command
            command = [precommit_executable, "run"]

            if all_files:
                command.append("--all-files")

            if fix:
                # pre-commit runs fixes by default, no special flag needed
                log_info("Running pre-commit with auto-fix enabled")

            # Execute command
            log_step(f"Running: {' '.join(command)}")
            _ = subprocess.run(
                command,
                check=True,
                cwd=self.env_manager.project_root,
                shell=False,
            )

            log_success("Pre-commit hooks completed successfully")
            return 0

        except FileNotFoundError as e:
            log_error(f"pre-commit not found: {e}")
            log_info("Ensure pre-commit is installed: pip install pre-commit")
            return 1
        except subprocess.CalledProcessError as e:
            log_error(f"Pre-commit hooks failed with exit code {e.returncode}")
            return e.returncode

    def run_sqlfluff(self, fix: bool = False, paths: Optional[List[str]] = None) -> int:
        """
        Run SQLFluff linting.

        Args:
            fix: Attempt to fix issues automatically
            paths: Specific paths to lint (default: models, tests, macros)

        Returns:
            Exit code
        """
        action = "fix" if fix else "lint"
        log_step(f"Running SQLFluff {action}...")

        try:
            # Use sqlfluff from virtual environment
            sqlfluff_executable = self.env_manager.get_sqlfluff_executable()

            # Fallback to system PATH if venv executable doesn't exist
            if not os.path.exists(sqlfluff_executable):
                sqlfluff_path = shutil.which("sqlfluff")
                if not sqlfluff_path:
                    raise FileNotFoundError("sqlfluff executable not found in PATH")
                sqlfluff_executable = sqlfluff_path

            # Default paths
            if paths is None:
                paths = ["models/", "tests/", "macros/"]

            # Build command
            command = [sqlfluff_executable, action]
            command.extend(paths)
            # Use dbt templater as configured in .sqlfluff
            # command.extend(["--templater=raw"])

            # Execute command
            log_step(f"Running: {' '.join(command)}")
            _ = subprocess.run(
                command,
                check=True,
                cwd=self.env_manager.project_root,
                shell=False,
            )

            log_success(f"SQLFluff {action} completed successfully")
            return 0

        except FileNotFoundError as e:
            log_error(f"SQLFluff not found: {e}")
            log_info("Ensure SQLFluff is installed: pip install sqlfluff")
            return 1
        except subprocess.CalledProcessError as e:
            if e.returncode == 1 and not fix:
                log_warning("SQLFluff found linting issues")
                log_info("Run with --fix to attempt automatic fixes")
            else:
                log_error(f"SQLFluff {action} failed with exit code {e.returncode}")
            return e.returncode

    def run_all_linting(self, fix: bool = False) -> int:
        """
        Run all linting tools.

        Args:
            fix: Attempt to fix issues automatically

        Returns:
            Exit code
        """
        log_step("Running comprehensive linting suite...")

        exit_code = 0

        # Run pre-commit hooks
        precommit_exit = self.run_pre_commit(all_files=True, fix=fix)
        if precommit_exit != 0:
            exit_code = precommit_exit

        # Run SQLFluff
        sqlfluff_exit = self.run_sqlfluff(fix=fix)
        if sqlfluff_exit != 0:
            exit_code = sqlfluff_exit

        if exit_code == 0:
            log_success("All linting checks passed")
        else:
            log_error("Some linting checks failed")

        return exit_code


def main() -> None:
    """Execute linting commands from command line."""
    if len(sys.argv) < 2:
        log_error("Usage: python -m scripts.linting <command> [args...]")
        log_info("Commands:")
        log_info("  precommit [--fix]  Run pre-commit hooks")
        log_info("  sqlfluff [--fix] [paths...] Run SQLFluff linting")
        log_info("  all [--fix]        Run all linting tools")
        sys.exit(1)

    command = sys.argv[1]
    args = sys.argv[2:]
    fix = "--fix" in args

    # Remove --fix from args for path processing
    if fix:
        args = [arg for arg in args if arg != "--fix"]

    linting_mgr = LintingManager()

    if command == "precommit":
        exit_code = linting_mgr.run_pre_commit(all_files=True, fix=fix)
    elif command == "sqlfluff":
        paths = args if args else None
        exit_code = linting_mgr.run_sqlfluff(fix=fix, paths=paths)
    elif command == "all":
        exit_code = linting_mgr.run_all_linting(fix=fix)
    else:
        log_error(f"Unknown command: {command}")
        exit_code = 1

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
