"""Pydantic models used by the backend service."""

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field


class JobState(str, Enum):
    """Possible lifecycle states for an UP2You job."""

    QUEUED = "queued"
    RUNNING = "running"
    SUCCEEDED = "succeeded"
    FAILED = "failed"


class JobRequest(BaseModel):
    """Incoming payload for launching an UP2You inference job."""

    data_dir: str = Field(..., description="Directory containing source photos")
    output_dir: str = Field(..., description="Directory where artifacts will be written")
    base_model_path: Optional[str] = Field(
        None, description="Override default base diffusion model path"
    )
    segment_model_name: Optional[str] = Field(
        None, description="Override default segmentation model name"
    )
    inference_script: Optional[str] = Field(
        None, description="Choose a custom UP2You inference script"
    )
    extra_args: List[str] = Field(
        default_factory=list,
        description="Additional CLI arguments forwarded to the script",
    )


class JobStatus(BaseModel):
    """Status metadata reported back to API consumers."""

    job_id: str
    state: JobState
    command: List[str]
    created_at: datetime
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    exit_code: Optional[int] = None
    log_path: Optional[str] = None
    message: Optional[str] = None


class JobCreatedResponse(BaseModel):
    """Response body returned right after a job is accepted."""

    job_id: str
    state: JobState
    command: List[str]
    created_at: datetime


class JobStatusResponse(JobStatus):
    """Full job state response model."""

    pass
