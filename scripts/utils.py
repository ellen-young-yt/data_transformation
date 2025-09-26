#!/usr/bin/env python3
"""
Simple utilities for dbt data transformation project.

Basic logging, file operations, and constants with environment awareness.
"""

from typing import Optional


def _get_environment_context() -> Optional[str]:
    """Get environment context for enhanced logging."""
    try:
        # Import here to avoid circular imports
        from .environment_manager import env_manager

        return f"{env_manager.environment.value}:{env_manager.execution_context.value}"
    except ImportError:
        return None


def log_info(message: str) -> None:
    """Log info message with environment context."""
    context = _get_environment_context()
    if context:
        print(f"\033[96m[INFO:{context}]\033[0m {message}")
    else:
        print(f"\033[96m[INFO]\033[0m {message}")


def log_success(message: str) -> None:
    """Log success message with environment context."""
    context = _get_environment_context()
    if context:
        print(f"\033[92m[SUCCESS:{context}]\033[0m {message}")
    else:
        print(f"\033[92m[SUCCESS]\033[0m {message}")


def log_warning(message: str) -> None:
    """Log warning message with environment context."""
    context = _get_environment_context()
    if context:
        print(f"\033[93m[WARNING:{context}]\033[0m {message}")
    else:
        print(f"\033[93m[WARNING]\033[0m {message}")


def log_error(message: str) -> None:
    """Log error message with environment context."""
    context = _get_environment_context()
    if context:
        print(f"\033[91m[ERROR:{context}]\033[0m {message}")
    else:
        print(f"\033[91m[ERROR]\033[0m {message}")


def log_step(message: str) -> None:
    """Log step message with environment context."""
    context = _get_environment_context()
    if context:
        print(f"\033[94m[STEP:{context}]\033[0m {message}")
    else:
        print(f"\033[94m[STEP]\033[0m {message}")
