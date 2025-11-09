"""Application configuration helpers."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Optional


class Settings:
    """Holds runtime configuration for the backend service."""

    def __init__(
        self,
        *,
        up2you_repo_path: Optional[str] = None,
        python_executable: Optional[str] = None,
        default_inference_script: Optional[str] = None,
        default_base_model_path: Optional[str] = None,
        default_segment_model_name: Optional[str] = None,
    ) -> None:
        self.up2you_repo_path: Path = Path(
            up2you_repo_path or os.getenv("UP2YOU_REPO_PATH", "/opt/UP2You")
        )
        self.python_executable: str = python_executable or os.getenv(
            "PYTHON_EXECUTABLE", "python"
        )
        self.default_inference_script: str = default_inference_script or os.getenv(
            "UP2YOU_INFERENCE_SCRIPT", "inference_low_gpu.py"
        )
        self.default_base_model_path: str = default_base_model_path or os.getenv(
            "UP2YOU_BASE_MODEL_PATH", "stabilityai/stable-diffusion-2-1-base"
        )
        self.default_segment_model_name: str = (
            default_segment_model_name
            or os.getenv("UP2YOU_SEGMENT_MODEL_NAME", "ZhengPeng7/BiRefNet")
        )

    def resolve_path(self, value: str) -> Path:
        """Resolve *value* to an absolute path relative to the repo if needed."""

        candidate = Path(value)
        if candidate.is_absolute():
            return candidate
        return self.up2you_repo_path / candidate

    def inference_script_path(self, script_name: Optional[str] = None) -> Path:
        """Return an absolute path to the inference script."""

        script = script_name or self.default_inference_script
        return self.resolve_path(script)


settings = Settings()
