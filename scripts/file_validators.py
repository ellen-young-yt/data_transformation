"""
File Validation Utilities.

This module provides file validation functions for various file formats
with proper file handling to avoid Windows lockfile issues.
"""

import glob
import json
import sys
from pathlib import Path

from .utils import log_error, log_info, log_success, log_warning


def validate_yaml_files() -> int:
    """
    Validate all YAML files in project.

    Returns:
        Exit code (0 for success, 1 for failure)
    """
    try:
        import yaml
    except ImportError:
        log_error("PyYAML not installed, cannot validate YAML files")
        log_info("Install with: pip install PyYAML")
        return 1

    log_info("Validating YAML files...")

    # Find all YAML files
    yml_files = glob.glob("**/*.yml", recursive=True)
    yaml_files = glob.glob("**/*.yaml", recursive=True)
    all_files = yml_files + yaml_files

    # Filter out excluded directories
    filtered_files = [
        f
        for f in all_files
        if "node_modules" not in f and "dbt_packages" not in f and "transform" not in f
    ]

    if not filtered_files:
        log_warning("No YAML files found")
        return 0

    errors = []
    for file_path in filtered_files:
        try:
            with open(file_path, encoding="utf-8") as f:
                yaml.safe_load(f)
            log_info(f"  ✓ {file_path}")
        except yaml.YAMLError as e:
            log_error(f"  ✗ {file_path}: {e}")
            errors.append((file_path, str(e)))
        except Exception as e:
            log_error(f"  ✗ {file_path}: {e}")
            errors.append((file_path, str(e)))

    # Summary
    if errors:
        log_error(f"Found {len(errors)} invalid YAML file(s)")
        return 1
    else:
        log_success(f"Validated {len(filtered_files)} YAML files")
        return 0


def validate_json_files() -> int:
    """
    Validate all JSON files in project.

    Returns:
        Exit code (0 for success, 1 for failure)
    """
    log_info("Validating JSON files...")

    # Find all JSON files
    all_files = glob.glob("**/*.json", recursive=True)

    # Filter out excluded directories and empty files
    filtered_files = [
        f
        for f in all_files
        if "node_modules" not in f
        and "transform" not in f
        and "dbt_packages" not in f
        and Path(f).exists()
        and Path(f).stat().st_size > 0
    ]

    if not filtered_files:
        log_warning("No JSON files found")
        return 0

    errors = []
    for file_path in filtered_files:
        try:
            with open(file_path, encoding="utf-8") as f:
                json.load(f)
            log_info(f"  ✓ {file_path}")
        except json.JSONDecodeError as e:
            log_error(f"  ✗ {file_path}: {e}")
            errors.append((file_path, str(e)))
        except Exception as e:
            log_error(f"  ✗ {file_path}: {e}")
            errors.append((file_path, str(e)))

    # Summary
    if errors:
        log_error(f"Found {len(errors)} invalid JSON file(s)")
        return 1
    else:
        log_success(f"Validated {len(filtered_files)} JSON files")
        return 0


def validate_toml_files() -> int:
    """
    Validate all TOML files in project.

    Returns:
        Exit code (0 for success, 1 for failure)
    """
    log_info("Validating TOML files...")

    import tomllib

    # Find all TOML files
    all_files = glob.glob("**/*.toml", recursive=True)

    # Filter out excluded directories
    filtered_files = [
        f
        for f in all_files
        if "node_modules" not in f and "transform" not in f and "dbt_packages" not in f
    ]

    if not filtered_files:
        log_warning("No TOML files found")
        return 0

    errors = []
    for file_path in filtered_files:
        try:
            with open(file_path, "rb") as f:
                tomllib.load(f)
            log_info(f"  ✓ {file_path}")
        except tomllib.TOMLDecodeError as e:
            log_error(f"  ✗ {file_path}: {e}")
            errors.append((file_path, str(e)))
        except Exception as e:
            log_error(f"  ✗ {file_path}: {e}")
            errors.append((file_path, str(e)))

    # Summary
    if errors:
        log_error(f"Found {len(errors)} invalid TOML file(s)")
        return 1
    else:
        log_success(f"Validated {len(filtered_files)} TOML files")
        return 0


def validate_all_files() -> int:
    """
    Validate all supported file formats.

    Returns:
        Exit code (0 for success, 1 for failure)
    """
    exit_code = 0

    # Validate YAML
    yaml_exit = validate_yaml_files()
    if yaml_exit != 0:
        exit_code = yaml_exit

    # Validate JSON
    json_exit = validate_json_files()
    if json_exit != 0:
        exit_code = json_exit

    # Validate TOML
    toml_exit = validate_toml_files()
    if toml_exit != 0:
        exit_code = toml_exit

    if exit_code == 0:
        log_success("All file validation checks passed")
    else:
        log_error("Some file validation checks failed")

    return exit_code


def main() -> None:
    """Execute file validation commands from command line."""
    if len(sys.argv) < 2:
        log_error("Usage: python -m scripts.file_validators <command>")
        log_info("Commands:")
        log_info("  yaml    Validate YAML files")
        log_info("  json    Validate JSON files")
        log_info("  toml    Validate TOML files")
        log_info("  all     Validate all supported file formats")
        sys.exit(1)

    command = sys.argv[1]

    if command == "yaml":
        exit_code = validate_yaml_files()
    elif command == "json":
        exit_code = validate_json_files()
    elif command == "toml":
        exit_code = validate_toml_files()
    elif command == "all":
        exit_code = validate_all_files()
    else:
        log_error(f"Unknown command: {command}")
        exit_code = 1

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
