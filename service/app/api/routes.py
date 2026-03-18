from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query, Request, status

from app.schemas.models import (
    AssetTagRequest,
    ConfirmPersonRequest,
    CorrectionRequest,
    CorrectionResponse,
    CreateScanJobRequest,
    CreateScanJobResponse,
    CreateSourceRequest,
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


@router.get("/sources")
def sources(request: Request):
    items = _repository(request).list_sources()
    return {"items": items, "total": len(items)}


@router.post("/sources", status_code=status.HTTP_201_CREATED)
def create_source(request: Request, payload: CreateSourceRequest):
    item = _repository(request).create_source(payload)
    return {"item": item}


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
    source_id: str | None = Query(default=None),
    limit: int | None = Query(default=None, ge=1, le=500),
):
    items = _repository(request).assets(album_type=album_type, source_id=source_id, limit=limit)
    return {"items": items, "total": len(items)}


@router.post("/assets/{asset_id}/tags")
def add_asset_tag(request: Request, asset_id: str, payload: AssetTagRequest):
    item = _repository(request).add_asset_tag(asset_id, payload)
    if item is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Asset not found")
    return {"item": item}


@router.delete("/assets/{asset_id}/tags/{tag}")
def remove_asset_tag(request: Request, asset_id: str, tag: str):
    item = _repository(request).remove_asset_tag(asset_id, tag)
    if item is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Asset not found")
    return {"item": item}


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
    try:
        job = _repository(request).create_scan_job(payload)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
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
