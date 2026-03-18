from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query, Request, status

from app.schemas.models import (
    ConfirmPersonRequest,
    CorrectionRequest,
    CorrectionResponse,
    CreateScanJobRequest,
    CreateScanJobResponse,
    HealthResponse,
)

router = APIRouter()


@router.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(status="ok", models={"clip": "ready", "face": "ready"})


def _repository(request: Request):
    return request.app.state.repository


@router.get("/dashboard")
def dashboard(request: Request):
    return _repository(request).dashboard()


@router.get("/albums")
def albums(
    request: Request,
    type: str | None = None,
    sort: str = Query(default="confidence"),
    limit: int | None = Query(default=None, ge=1, le=100),
):
    items = _repository(request).albums(type=type, sort=sort, limit=limit)
    return {"items": items, "total": len(items)}


@router.get("/assets")
def assets(
    request: Request,
    album_type: str | None = Query(default=None),
    limit: int | None = Query(default=None, ge=1, le=500),
):
    items = _repository(request).assets(album_type=album_type, limit=limit)
    return {"items": items, "total": len(items)}


@router.get("/people")
def people(request: Request):
    items = _repository(request).people()
    return {"items": items, "total": len(items)}


@router.post("/people/{cluster_id}/confirm")
def confirm_person(request: Request, cluster_id: str, payload: ConfirmPersonRequest):
    item = _repository(request).confirm_person(cluster_id, payload)
    if item is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cluster not found")
    return {"item": item}


@router.get("/timeline")
def timeline(request: Request, limit: int | None = Query(default=None, ge=1, le=100)):
    items = _repository(request).timeline(limit=limit)
    return {"items": items, "total": len(items)}


@router.get("/timeline/{event_id}/assets")
def timeline_assets(
    request: Request,
    event_id: str,
    limit: int | None = Query(default=120, ge=1, le=500),
):
    items = _repository(request).timeline_assets(event_id=event_id, limit=limit)
    return {"items": items, "total": len(items)}


@router.post("/scan-jobs", response_model=CreateScanJobResponse, status_code=status.HTTP_201_CREATED)
def create_scan_job(request: Request, payload: CreateScanJobRequest) -> CreateScanJobResponse:
    job = _repository(request).create_scan_job(payload)
    return CreateScanJobResponse(job_id=job.job_id, status=job.status)


@router.get("/scan-jobs/{job_id}")
def get_scan_job(request: Request, job_id: str):
    job = _repository(request).get_scan_job(job_id)
    if job is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")
    return job


@router.post("/corrections", response_model=CorrectionResponse, status_code=status.HTTP_202_ACCEPTED)
def create_correction(request: Request, payload: CorrectionRequest):
    return _repository(request).apply_correction(payload)


@router.get("/corrections")
def corrections(request: Request, limit: int | None = Query(default=20, ge=1, le=200)):
    items = _repository(request).list_corrections(limit=limit)
    return {"items": items, "total": len(items)}
