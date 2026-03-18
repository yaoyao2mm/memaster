from __future__ import annotations

import sqlite3
from contextlib import contextmanager
from pathlib import Path


SCHEMA = """
CREATE TABLE IF NOT EXISTS media_sources (
    source_id TEXT PRIMARY KEY,
    source_type TEXT NOT NULL,
    display_name TEXT NOT NULL,
    root_path TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'ready',
    last_scan_at TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS scan_jobs (
    job_id TEXT PRIMARY KEY,
    source_id TEXT,
    title TEXT NOT NULL,
    status TEXT NOT NULL,
    progress REAL NOT NULL,
    detail TEXT NOT NULL,
    source_name TEXT,
    root_path TEXT NOT NULL,
    mode TEXT NOT NULL,
    recursive INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS media_assets (
    asset_id TEXT PRIMARY KEY,
    source_id TEXT,
    source_name TEXT,
    root_path TEXT NOT NULL,
    relative_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    extension TEXT NOT NULL,
    media_kind TEXT NOT NULL,
    smart_album_type TEXT NOT NULL,
    thumbnail_path TEXT,
    size_bytes INTEGER NOT NULL,
    modified_at TEXT NOT NULL,
    imported_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_scan_job_id TEXT NOT NULL,
    UNIQUE(root_path, relative_path)
);

CREATE INDEX IF NOT EXISTS idx_media_assets_album_type
ON media_assets (smart_album_type);

CREATE INDEX IF NOT EXISTS idx_media_assets_last_scan_job_id
ON media_assets (last_scan_job_id);

CREATE TABLE IF NOT EXISTS user_corrections (
    correction_id TEXT PRIMARY KEY,
    asset_id TEXT NOT NULL,
    kind TEXT NOT NULL,
    from_value TEXT NOT NULL,
    to_value TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_corrections_asset_id
ON user_corrections (asset_id);

CREATE TABLE IF NOT EXISTS asset_tags (
    asset_id TEXT NOT NULL,
    tag TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(asset_id, tag)
);

CREATE INDEX IF NOT EXISTS idx_asset_tags_asset_id
ON asset_tags (asset_id);

CREATE TABLE IF NOT EXISTS people_clusters (
    cluster_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    asset_count INTEGER NOT NULL,
    trait TEXT NOT NULL,
    color TEXT NOT NULL,
    review_state TEXT NOT NULL,
    is_self INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
"""


class Database:
    def __init__(self, db_path: Path):
        self._db_path = db_path
        self.init()

    @contextmanager
    def connection(self):
        conn = sqlite3.connect(self._db_path)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
            conn.commit()
        finally:
            conn.close()

    def init(self) -> None:
        with self.connection() as conn:
            conn.executescript(SCHEMA)
            scan_job_columns = {
                row["name"]
                for row in conn.execute("PRAGMA table_info(scan_jobs)").fetchall()
            }
            if "source_id" not in scan_job_columns:
                conn.execute("ALTER TABLE scan_jobs ADD COLUMN source_id TEXT")
            if "source_name" not in scan_job_columns:
                conn.execute("ALTER TABLE scan_jobs ADD COLUMN source_name TEXT")
            columns = {
                row["name"]
                for row in conn.execute("PRAGMA table_info(media_assets)").fetchall()
            }
            if "thumbnail_path" not in columns:
                conn.execute("ALTER TABLE media_assets ADD COLUMN thumbnail_path TEXT")
            if "source_id" not in columns:
                conn.execute("ALTER TABLE media_assets ADD COLUMN source_id TEXT")
            if "source_name" not in columns:
                conn.execute("ALTER TABLE media_assets ADD COLUMN source_name TEXT")
            conn.execute(
                "CREATE INDEX IF NOT EXISTS idx_media_assets_source_id ON media_assets (source_id)"
            )
