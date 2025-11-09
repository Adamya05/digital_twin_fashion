"""Entry point for the FastAPI backend service."""

from __future__ import annotations

from fastapi import FastAPI

from .routes import router

app = FastAPI(title="Digital Twin Fashion Backend", version="0.1.0")
app.include_router(router, prefix="/api")


@app.get("/health", tags=["health"])
def healthcheck() -> dict[str, str]:
    """Simple health-check endpoint."""

    return {"status": "ok"}
