from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime
from hashlib import sha1
from pathlib import Path


IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".gif", ".webp", ".heic", ".bmp"}
VIDEO_EXTENSIONS = {".mp4", ".mov", ".m4v", ".avi", ".mkv"}
DOCUMENT_HINTS = {"screenshot", "截屏", "screen shot", "capture", "document", "scan"}


@dataclass(frozen=True, slots=True)
class IndexedAsset:
    asset_id: str
    root_path: str
    relative_path: str
    file_name: str
    extension: str
    media_kind: str
    smart_album_type: str
    thumbnail_path: str
    size_bytes: int
    modified_at: str
    last_scan_job_id: str


class FileIndexer:
    def __init__(self, thumbnailer):
        self._thumbnailer = thumbnailer

    def scan(self, root_path: Path, recursive: bool, scan_job_id: str) -> list[IndexedAsset]:
        walker = root_path.rglob("*") if recursive else root_path.glob("*")
        assets: list[IndexedAsset] = []

        for path in walker:
            if not path.is_file():
                continue
            extension = path.suffix.lower()
            media_kind = self._media_kind(extension)
            if media_kind == "other":
                continue

            stat = path.stat()
            relative_path = path.relative_to(root_path).as_posix()
            album_type = self._album_type(path, media_kind)
            asset_id = self._asset_id(root_path, relative_path)
            assets.append(
                IndexedAsset(
                    asset_id=asset_id,
                    root_path=str(root_path),
                    relative_path=relative_path,
                    file_name=path.name,
                    extension=extension,
                    media_kind=media_kind,
                    smart_album_type=album_type,
                    thumbnail_path=self._thumbnailer.ensure_thumbnail(
                        asset_id=asset_id,
                        label=path.stem.replace("_", " ").replace("-", " "),
                        subtitle=relative_path,
                        album_type=album_type,
                    ),
                    size_bytes=stat.st_size,
                    modified_at=datetime.fromtimestamp(stat.st_mtime, UTC).isoformat(),
                    last_scan_job_id=scan_job_id,
                )
            )

        return assets

    def _asset_id(self, root_path: Path, relative_path: str) -> str:
        digest = sha1(f"{root_path}:{relative_path}".encode("utf-8")).hexdigest()
        return f"asset_{digest[:16]}"

    def _media_kind(self, extension: str) -> str:
        if extension in IMAGE_EXTENSIONS:
            return "image"
        if extension in VIDEO_EXTENSIONS:
            return "video"
        return "other"

    def _album_type(self, path: Path, media_kind: str) -> str:
        lowered = path.as_posix().lower()
        if any(hint in lowered for hint in DOCUMENT_HINTS):
            return "document"
        if media_kind == "video":
            return "video"
        if "cat" in lowered or "kitten" in lowered or "猫" in lowered:
            return "pet"
        if "food" in lowered or "coffee" in lowered or "meal" in lowered:
            return "food"
        if "trip" in lowered or "travel" in lowered or "旅行" in lowered:
            return "travel"
        return "daily"
