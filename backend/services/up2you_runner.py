"""Helpers for launching UP2You inference jobs."""

from __future__ import annotations

import subprocess
import threading
import uuid
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

from ..config import settings
from ..models import JobCreatedResponse, JobRequest, JobState, JobStatus


class JobManager:
    """Manages lifecycle and bookkeeping for UP2You jobs."""

    def __init__(self) -> None:
        self._jobs: Dict[str, JobStatus] = {}
        self._lock = threading.RLock()

    def create_job(self, payload: JobRequest) -> JobCreatedResponse:
        """Create a job and return an immediate response."""

        job_id = str(uuid.uuid4())
        command = self._build_command(payload)
        created_at = datetime.utcnow()
        status = JobStatus(
            job_id=job_id,
            state=JobState.QUEUED,
            command=command,
            created_at=created_at,
        )
        with self._lock:
            self._jobs[job_id] = status

        thread = threading.Thread(
            target=self._run_job, args=(job_id, payload, command), daemon=True
        )
        thread.start()

        return JobCreatedResponse(
            job_id=job_id,
            state=status.state,
            command=command,
            created_at=created_at,
        )

    def get_status(self, job_id: str) -> Optional[JobStatus]:
        """Return the latest status for *job_id*."""

        with self._lock:
            return self._jobs.get(job_id)

    # Internal helpers -------------------------------------------------
    def _build_command(self, payload: JobRequest) -> List[str]:
        script_path = settings.inference_script_path(payload.inference_script)
        command: List[str] = [settings.python_executable, str(script_path)]

        command.extend(["--data_dir", str(self._resolve_path(payload.data_dir))])
        command.extend(["--output_dir", str(self._resolve_path(payload.output_dir))])

        base_model = payload.base_model_path or settings.default_base_model_path
        command.extend(["--base_model_path", base_model])

        segment_model = (
            payload.segment_model_name or settings.default_segment_model_name
        )
        command.extend(["--segment_model_name", segment_model])

        if payload.extra_args:
            command.extend(payload.extra_args)

        return command

    def _resolve_path(self, value: str) -> Path:
        return settings.resolve_path(value)

    def _run_job(
        self, job_id: str, payload: JobRequest, command: List[str]
    ) -> None:
        start_time = datetime.utcnow()
        log_path = self._resolve_path(payload.output_dir) / f"{job_id}.log"
        log_path.parent.mkdir(parents=True, exist_ok=True)

        with self._lock:
            status = self._jobs[job_id]
            status.state = JobState.RUNNING
            status.started_at = start_time
            status.log_path = str(log_path)
            self._jobs[job_id] = status

        try:
            with log_path.open("w", encoding="utf-8") as log_file:
                process = subprocess.Popen(
                    command,
                    cwd=str(settings.up2you_repo_path),
                    stdout=log_file,
                    stderr=subprocess.STDOUT,
                )
                exit_code = process.wait()
        except Exception as exc:  # pragma: no cover - defensive programming
            exit_code = -1
            message = f"Job crashed with error: {exc!r}"
        else:
            message = "Job finished successfully" if exit_code == 0 else "Job failed"

        finished_at = datetime.utcnow()
        with self._lock:
            status = self._jobs[job_id]
            status.state = JobState.SUCCEEDED if exit_code == 0 else JobState.FAILED
            status.completed_at = finished_at
            status.exit_code = exit_code
            status.message = message
            self._jobs[job_id] = status


job_manager = JobManager()
