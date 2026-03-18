from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True, slots=True)
class Settings:
    db_path: Path
    default_scan_root: Path
    thumbnails_dir: Path


def load_settings() -> Settings:
    service_root = Path(__file__).resolve().parents[2]
    db_path = Path(os.getenv("LOCAL_AI_DB_PATH", service_root / "data" / "memory.db"))
    default_scan_root = Path(
        os.getenv("LOCAL_AI_DEFAULT_SCAN_ROOT", service_root.parent)
    )
    thumbnails_dir = Path(
        os.getenv("LOCAL_AI_THUMBNAILS_DIR", service_root / "data" / "thumbnails")
    )
    db_path.parent.mkdir(parents=True, exist_ok=True)
    thumbnails_dir.mkdir(parents=True, exist_ok=True)
    return Settings(
        db_path=db_path,
        default_scan_root=default_scan_root,
        thumbnails_dir=thumbnails_dir,
    )
