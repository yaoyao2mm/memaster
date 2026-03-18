from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: Literal["ok"]
    models: dict[str, str]


class SourceItem(BaseModel):
    source_id: str
    source_type: Literal["local_folder", "mounted_folder"]
    display_name: str
    root_path: str
    status: Literal["ready", "missing"]
    last_scan_at: str | None = None


class StatItem(BaseModel):
    label: str
    value: str
    delta: str | None = None


class AlbumItem(BaseModel):
    id: str
    title: str
    count: str
    description: str
    color: str
    cover_label: str
    confidence: float = Field(ge=0, le=1)
    type: str


class PersonItem(BaseModel):
    id: str
    name: str
    asset_count: int
    trait: str
    color: str
    review_state: Literal["confirmed", "needs_review"]
    is_self: bool = False


class CorrectionItem(BaseModel):
    correction_id: str
    asset_id: str
    kind: str
    from_value: str = Field(alias="from")
    to: str = Field(alias="to_value")
    created_at: str

    model_config = {"populate_by_name": True}


class TimelineItem(BaseModel):
    id: str
    date: str
    title: str
    description: str
    tag: str


class ScanJobItem(BaseModel):
    job_id: str
    title: str
    status: Literal["queued", "running", "completed"]
    progress: float = Field(ge=0, le=1)
    detail: str
    source_id: str | None = None
    source_name: str | None = None
    root_path: str
    mode: str


class AssetItem(BaseModel):
    asset_id: str
    source_id: str | None = None
    source_name: str | None = None
    file_name: str
    relative_path: str
    media_kind: str
    smart_album_type: str
    thumbnail_url: str | None = None
    tags: list[str] = Field(default_factory=list)
    size_bytes: int
    modified_at: str
    root_path: str


class DashboardResponse(BaseModel):
    stats: list[StatItem]
    sources: list[SourceItem] = Field(default_factory=list)
    smart_albums: list[AlbumItem]
    signals: list[StatItem]
    recent_events: list[TimelineItem]
    scan_jobs: list[ScanJobItem]
    people: list[PersonItem]


class CreateSourceRequest(BaseModel):
    source_type: Literal["local_folder", "mounted_folder"] = "local_folder"
    display_name: str
    root_path: str


class CreateScanJobRequest(BaseModel):
    source_id: str
    recursive: bool = True
    mode: Literal["incremental", "full", "thumbnail", "people"] = "incremental"


class CreateScanJobResponse(BaseModel):
    job_id: str
    status: Literal["queued", "completed"]


class ConfirmPersonRequest(BaseModel):
    name: str
    is_self: bool = False


class CorrectionRequest(BaseModel):
    asset_id: str
    kind: str
    from_value: str = Field(alias="from")
    to: str

    model_config = {"populate_by_name": True}


class CorrectionResponse(BaseModel):
    accepted: bool
    asset_id: str
    kind: str
    from_value: str = Field(alias="from")
    to: str

    model_config = {"populate_by_name": True}


class AssetTagRequest(BaseModel):
    tag: str
