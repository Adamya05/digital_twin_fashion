"""API routes exposed by the backend service."""

from __future__ import annotations

from fastapi import APIRouter, HTTPException, status

from .models import JobCreatedResponse, JobRequest, JobStatusResponse
from .services.up2you_runner import job_manager

router = APIRouter()


@router.post(
    "/jobs",
    response_model=JobCreatedResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Launch a new UP2You inference job",
)
def launch_job(request: JobRequest) -> JobCreatedResponse:
    """Schedule a new job asynchronously."""

    return job_manager.create_job(request)


@router.get(
    "/jobs/{job_id}",
    response_model=JobStatusResponse,
    summary="Get the status of an inference job",
)
def get_job(job_id: str) -> JobStatusResponse:
    """Return progress details for a job."""

    status_record = job_manager.get_status(job_id)
    if status_record is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job not found",
        )
    return status_record
