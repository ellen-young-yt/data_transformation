"""
Docker Operations Manager.

This module handles Docker and Docker Compose operations with environment awareness.
"""

import shutil
import subprocess
import sys
from pathlib import Path
from typing import Optional, Union

from .environment_manager import env_manager
from .utils import log_error, log_info, log_step, log_success


class DockerManager:
    """Manager for Docker and Docker Compose operations."""

    def __init__(self) -> None:
        """Initialize the Docker manager."""
        self.env_manager = env_manager
        self.env_manager.setup_environment()

    def build_image(
        self, tag: Optional[str] = None, dockerfile: str = "Dockerfile"
    ) -> int:
        """
        Build Docker image.

        Args:
            tag: Tag for the image (default: data-transformation)
            dockerfile: Path to Dockerfile

        Returns:
            Exit code
        """
        if tag is None:
            tag = "data-transformation"

        log_step(f"Building Docker image: {tag}")

        try:
            # Check if docker is available
            docker_executable = shutil.which("docker")
            if not docker_executable:
                raise FileNotFoundError("docker executable not found in PATH")

            # Test if Docker daemon is running
            try:
                subprocess.run(
                    [docker_executable, "version"],
                    check=True,
                    capture_output=True,
                    cwd=self.env_manager.project_root,
                    shell=False,
                )
            except subprocess.CalledProcessError:
                log_error("Docker daemon is not running")
                log_info("Please start Docker Desktop and try again")
                log_info("On Windows: Start Docker Desktop from the Start menu")
                return 1

            # Build command
            command = [docker_executable, "build", "-t", tag, "-f", dockerfile, "."]

            # Execute command
            log_step(f"Running: {' '.join(command)}")
            _ = subprocess.run(
                command,
                check=True,
                cwd=self.env_manager.project_root,
                shell=False,
            )

            log_success(f"Docker image '{tag}' built successfully")
            return 0

        except FileNotFoundError as e:
            log_error(f"Docker not found: {e}")
            log_info("Ensure Docker is installed and available in PATH")
            return 1
        except subprocess.CalledProcessError as e:
            log_error(f"Docker build failed with exit code {e.returncode}")
            if "pipe/dockerDesktopLinuxEngine" in str(e):
                log_info(
                    "Docker Desktop is not running. Please start Docker Desktop and try again."
                )
            return e.returncode

    def run_dbt_in_container(
        self, dbt_command: str, target: str, image_tag: str = "data-transformation"
    ) -> int:
        """
        Run a dbt command directly in a Docker container.

        Args:
            dbt_command: The dbt command to run (e.g., 'run', 'compile', 'test')
            target: The dbt target environment
            image_tag: Docker image tag to use

        Returns:
            Exit code
        """
        log_step(f"Running dbt {dbt_command} in Docker container")

        try:
            # Check if docker is available
            docker_executable = shutil.which("docker")
            if not docker_executable:
                raise FileNotFoundError("docker executable not found in PATH")

            # Convert Windows paths to Docker-compatible format
            project_root = self.env_manager.project_root
            docker_profiles_path = self._convert_to_docker_path(
                project_root / "profiles"
            )

            # Build the docker run command using container's built-in packages
            command = [
                docker_executable,
                "run",
                "--rm",
                # Only mount profiles - use container's pre-built project and packages
                "-v",
                f"{docker_profiles_path}:/var/task/profiles",
                "--env-file",
                ".env",
                "-e",
                "DBT_PROFILES_DIR=/var/task/profiles",  # pragma: allowlist secret
                "-e",
                "DBT_PROJECT_DIR=/var/task",
                "-w",
                "/var/task",
                image_tag,
                "dbt",
                dbt_command,
                "--target",
                target,
                "--profiles-dir",
                "/var/task/profiles",
            ]

            # Execute command
            log_step(f"Running: {' '.join(command)}")
            _ = subprocess.run(
                command,
                check=True,
                cwd=self.env_manager.project_root,
                shell=False,
            )

            log_success(f"dbt {dbt_command} completed successfully in container")
            return 0

        except FileNotFoundError as e:
            log_error(f"Docker not found: {e}")
            return 1
        except subprocess.CalledProcessError as e:
            log_error(
                f"Docker container execution failed with exit code {e.returncode}"
            )
            return e.returncode
        except Exception as e:
            log_error(f"Unexpected error running container: {e}")
            return 1

    def _convert_to_docker_path(self, path: Union[str, Path]) -> str:
        """
        Convert Windows paths to Docker-compatible paths.

        Args:
            path: Path object or string to convert

        Returns:
            Docker-compatible path string
        """
        path_str = str(path)
        # Convert Windows backslashes to forward slashes
        docker_path = path_str.replace("\\", "/")
        # Handle Windows drive letters (C: -> /c)
        if len(docker_path) > 1 and docker_path[1] == ":":
            drive_letter = docker_path[0].lower()
            docker_path = f"/{drive_letter}{docker_path[2:]}"
        return docker_path


def main() -> None:
    """Execute Docker commands from command line."""
    if len(sys.argv) < 2:
        log_error("Usage: python -m scripts.docker_manager <command> [args...]")
        log_info("Commands:")
        log_info("  build [tag] [dockerfile]  Build Docker image")
        sys.exit(1)

    command = sys.argv[1]
    args = sys.argv[2:]

    docker_mgr = DockerManager()

    if command == "build":
        exit_code = docker_mgr.build_image(
            args[0] if args else None, args[1] if len(args) > 1 else "Dockerfile"
        )
    else:
        log_error(f"Unknown command: {command}")
        exit_code = 1

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
