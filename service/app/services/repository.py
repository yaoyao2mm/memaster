from __future__ import annotations

from dataclasses import asdict, dataclass
from datetime import UTC, datetime
from pathlib import Path
from uuid import uuid4

from app.core.data import PEOPLE
from app.core.database import Database
from app.schemas.models import (
    AlbumItem,
    AssetItem,
    CorrectionRequest,
    CreateSourceRequest,
    ConfirmPersonRequest,
    CorrectionResponse,
    CreateScanJobRequest,
    DashboardResponse,
    PersonItem,
    SourceItem,
    ScanJobItem,
    StatItem,
    TimelineItem,
    CorrectionItem,
)
from app.services.indexer import FileIndexer, IndexedAsset


ALBUM_META = {
    "pet": ("可爱的小猫", "系统按文件名和路径线索归到宠物素材", "#FFE0B2", "CAT"),
    "travel": ("旅行与风景", "根据目录和命名习惯聚合出的旅行内容", "#CDEFEA", "TRIP"),
    "daily": ("日常记录", "没有明显事件标签的日常照片与视频", "#FFD9E4", "LIFE"),
    "document": ("截图与文档", "基于命名线索识别的截图、扫描件和文档素材", "#E2E8F0", "DOC"),
    "video": ("视频片段", "从 NAS 中发现的视频素材集合", "#D6E4FF", "VID"),
    "food": ("美食与咖啡", "根据路径和文件名归纳的饮食记录", "#FFE6B8", "FOOD"),
}


@dataclass(slots=True)
class MemoryRepository:
    db: Database
    indexer: FileIndexer
    thumbnails_base_url: str = "/thumbs"

    def ensure_seed_data(self, default_scan_root: Path) -> None:
        self._ensure_people_seed()
        source = self.ensure_source(
            CreateSourceRequest(
                source_type="mounted_folder",
                display_name="Default Library",
                root_path=str(default_scan_root),
            )
        )
        jobs = self.list_scan_jobs()
        if jobs:
            return
        self.create_scan_job(
            CreateScanJobRequest(
                source_id=source.source_id,
                recursive=False,
                mode="incremental",
            ),
            allow_missing=True,
        )

    def ensure_source(self, payload: CreateSourceRequest) -> SourceItem:
        existing = self.get_source_by_path(payload.root_path)
        if existing is not None:
            return existing
        return self.create_source(payload)

    def create_source(self, payload: CreateSourceRequest) -> SourceItem:
        root_path = Path(payload.root_path).expanduser()
        source_id = f"source_{uuid4().hex[:8]}"
        status = "ready" if root_path.exists() else "missing"
        with self.db.connection() as conn:
            conn.execute(
                """
                INSERT INTO media_sources (
                    source_id, source_type, display_name, root_path, status
                ) VALUES (?, ?, ?, ?, ?)
                """,
                (
                    source_id,
                    payload.source_type,
                    payload.display_name,
                    str(root_path),
                    status,
                ),
            )
        source = self.get_source(source_id)
        assert source is not None
        return source

    def list_sources(self) -> list[SourceItem]:
        with self.db.connection() as conn:
            rows = conn.execute(
                """
                SELECT source_id, source_type, display_name, root_path, status, last_scan_at
                FROM media_sources
                ORDER BY datetime(updated_at) DESC, display_name ASC
                """
            ).fetchall()
        return [SourceItem.model_validate(dict(row)) for row in rows]

    def get_source(self, source_id: str) -> SourceItem | None:
        with self.db.connection() as conn:
            row = conn.execute(
                """
                SELECT source_id, source_type, display_name, root_path, status, last_scan_at
                FROM media_sources
                WHERE source_id = ?
                """,
                (source_id,),
            ).fetchone()
        return SourceItem.model_validate(dict(row)) if row else None

    def get_source_by_path(self, root_path: str) -> SourceItem | None:
        with self.db.connection() as conn:
            row = conn.execute(
                """
                SELECT source_id, source_type, display_name, root_path, status, last_scan_at
                FROM media_sources
                WHERE root_path = ?
                """,
                (str(Path(root_path).expanduser()),),
            ).fetchone()
        return SourceItem.model_validate(dict(row)) if row else None

    def create_scan_job(
        self,
        payload: CreateScanJobRequest,
        *,
        allow_missing: bool = False,
    ) -> ScanJobItem:
        source = self.get_source(payload.source_id)
        if source is None:
            raise ValueError("Unknown source")
        root_path = Path(source.root_path).expanduser()
        job_id = f"scan_{uuid4().hex[:8]}"
        created_at = datetime.now(UTC).isoformat()
        queued = {
            "job_id": job_id,
            "source_id": source.source_id,
            "title": f"{source.display_name} 扫描任务",
            "status": "queued",
            "progress": 0.0,
            "detail": f"{root_path} 已加入队列",
            "source_name": source.display_name,
            "root_path": str(root_path),
            "mode": payload.mode,
            "recursive": 1 if payload.recursive else 0,
            "created_at": created_at,
            "updated_at": created_at,
        }
        with self.db.connection() as conn:
            conn.execute(
                """
                INSERT INTO scan_jobs (
                    job_id, source_id, title, status, progress, detail, source_name, root_path, mode, recursive, created_at, updated_at
                ) VALUES (
                    :job_id, :source_id, :title, :status, :progress, :detail, :source_name, :root_path, :mode, :recursive, :created_at, :updated_at
                )
                """,
                queued,
            )

        if not root_path.exists():
            status = "completed" if allow_missing else "queued"
            detail = f"{root_path} 不存在，尚未扫描"
            self._update_source_status(source.source_id, root_path)
            return self._update_job(job_id, status=status, progress=0.0, detail=detail)

        assets = self.indexer.scan(
            root_path,
            payload.recursive,
            job_id,
            source_id=source.source_id,
            source_name=source.display_name,
        )
        self._persist_assets(assets)
        self._update_source_status(source.source_id, root_path, scanned=True)
        return self._update_job(
            job_id,
            status="completed",
            progress=1.0,
            detail=f"已扫描 {len(assets)} 个媒体文件",
        )

    def get_scan_job(self, job_id: str) -> ScanJobItem | None:
        with self.db.connection() as conn:
            row = conn.execute(
                """
                SELECT job_id, source_id, source_name, title, status, progress, detail, root_path, mode
                FROM scan_jobs
                WHERE job_id = ?
                """,
                (job_id,),
            ).fetchone()
        return ScanJobItem.model_validate(dict(row)) if row else None

    def list_scan_jobs(self) -> list[ScanJobItem]:
        with self.db.connection() as conn:
            rows = conn.execute(
                """
                SELECT job_id, source_id, source_name, title, status, progress, detail, root_path, mode
                FROM scan_jobs
                ORDER BY datetime(created_at) DESC
                """
            ).fetchall()
        return [ScanJobItem.model_validate(dict(row)) for row in rows]

    def dashboard(self) -> DashboardResponse:
        jobs = self.list_scan_jobs()
        albums = self.albums(limit=4)
        stats = self._stats(jobs)
        signals = self._signals()
        timeline = self.timeline(limit=3)
        return DashboardResponse(
            stats=stats,
            sources=self.list_sources(),
            smart_albums=albums,
            signals=signals,
            recent_events=timeline,
            scan_jobs=jobs,
            people=self.people(),
        )

    def albums(self, type: str | None = None, sort: str = "confidence", limit: int | None = None) -> list[AlbumItem]:
        with self.db.connection() as conn:
            rows = conn.execute(
                """
                SELECT smart_album_type, COUNT(*) AS asset_count
                FROM media_assets
                GROUP BY smart_album_type
                """
            ).fetchall()

        counts = {row["smart_album_type"]: row["asset_count"] for row in rows}
        items = [
            self._album_item(album_type, count)
            for album_type, count in counts.items()
            if count > 0 and album_type in ALBUM_META
        ]
        if type:
            items = [item for item in items if item.type == type]
        if sort == "count":
            items.sort(key=lambda item: int(item.count.replace(",", "").replace(" 张", "")), reverse=True)
        else:
            items.sort(key=lambda item: item.confidence, reverse=True)
        if limit is not None:
            items = items[:limit]
        return items

    def assets(
        self,
        album_type: str | None = None,
        source_id: str | None = None,
        limit: int | None = None,
    ) -> list[AssetItem]:
        query = """
            SELECT asset_id, source_id, source_name, file_name, relative_path, media_kind, smart_album_type, thumbnail_path, size_bytes, modified_at, root_path
            FROM media_assets
        """
        params: list[object] = []
        clauses: list[str] = []
        if album_type:
            clauses.append("smart_album_type = ?")
            params.append(album_type)
        if source_id:
            clauses.append("source_id = ?")
            params.append(source_id)
        if clauses:
            query += f" WHERE {' AND '.join(clauses)}"
        query += " ORDER BY datetime(modified_at) DESC, file_name ASC"
        if limit is not None:
            query += " LIMIT ?"
            params.append(limit)

        with self.db.connection() as conn:
            rows = conn.execute(query, params).fetchall()
        return [
            AssetItem.model_validate(
                {
                    **dict(row),
                    "thumbnail_url": self._thumbnail_url(dict(row).get("thumbnail_path")),
                }
            )
            for row in rows
        ]

    def apply_correction(self, payload: CorrectionRequest) -> CorrectionResponse:
        correction_id = f"cor_{uuid4().hex[:8]}"
        with self.db.connection() as conn:
            conn.execute(
                """
                INSERT INTO user_corrections (
                    correction_id, asset_id, kind, from_value, to_value
                ) VALUES (?, ?, ?, ?, ?)
                """,
                (
                    correction_id,
                    payload.asset_id,
                    payload.kind,
                    payload.from_value,
                    payload.to,
                ),
            )
            if payload.kind == "album_label":
                conn.execute(
                    """
                    UPDATE media_assets
                    SET smart_album_type = ?
                    WHERE asset_id = ?
                    """,
                    (payload.to, payload.asset_id),
                )

        return CorrectionResponse(
            accepted=True,
            asset_id=payload.asset_id,
            kind=payload.kind,
            from_value=payload.from_value,
            to=payload.to,
        )

    def list_corrections(self, limit: int | None = None) -> list[CorrectionItem]:
        query = """
            SELECT correction_id, asset_id, kind, from_value, to_value, created_at
            FROM user_corrections
            ORDER BY datetime(created_at) DESC
        """
        params: list[object] = []
        if limit is not None:
            query += " LIMIT ?"
            params.append(limit)
        with self.db.connection() as conn:
            rows = conn.execute(query, params).fetchall()
        return [CorrectionItem.model_validate(dict(row)) for row in rows]

    def people(self) -> list[PersonItem]:
        with self.db.connection() as conn:
            rows = conn.execute(
                """
                SELECT cluster_id, name, asset_count, trait, color, review_state, is_self
                FROM people_clusters
                ORDER BY is_self DESC, asset_count DESC, name ASC
                """
            ).fetchall()
        return [
            PersonItem(
                id=row["cluster_id"],
                name=row["name"],
                asset_count=row["asset_count"],
                trait=row["trait"],
                color=row["color"],
                review_state=row["review_state"],
                is_self=bool(row["is_self"]),
            )
            for row in rows
        ]

    def confirm_person(self, cluster_id: str, payload: ConfirmPersonRequest) -> PersonItem | None:
        with self.db.connection() as conn:
            existing = conn.execute(
                """
                SELECT cluster_id, asset_count, trait, color
                FROM people_clusters
                WHERE cluster_id = ?
                """,
                (cluster_id,),
            ).fetchone()
            if existing is None:
                return None
            if payload.is_self:
                conn.execute("UPDATE people_clusters SET is_self = 0 WHERE is_self = 1")
            conn.execute(
                """
                UPDATE people_clusters
                SET name = ?, review_state = 'confirmed', is_self = ?, updated_at = CURRENT_TIMESTAMP
                WHERE cluster_id = ?
                """,
                (payload.name, 1 if payload.is_self else 0, cluster_id),
            )
        items = self.people()
        return next((item for item in items if item.id == cluster_id), None)

    def timeline(self, limit: int | None = None) -> list[TimelineItem]:
        with self.db.connection() as conn:
            rows = conn.execute(
                """
                SELECT
                    smart_album_type,
                    COUNT(*) AS asset_count,
                    MAX(modified_at) AS latest_modified_at
                FROM media_assets
                GROUP BY smart_album_type
                ORDER BY datetime(latest_modified_at) DESC, asset_count DESC
                """
            ).fetchall()

        items = [
            TimelineItem(
                id=f"memory_{row['smart_album_type']}",
                date=self._format_memory_date(row["latest_modified_at"]),
                title=f"{self._album_title(row['smart_album_type'])} 记忆卡",
                description=f"最近整理出 {row['asset_count']} 个 {self._album_title(row['smart_album_type'])} 素材。",
                tag=self._album_title(row["smart_album_type"]),
            )
            for row in rows
        ]

        if not items:
            items = [
                TimelineItem(
                    id="event_bootstrap",
                    date=datetime.now().strftime("%m 月 %d 日"),
                    title="等待首次扫描",
                    description="先创建一个扫描任务，系统才会开始建立你的记忆索引。",
                    tag="引导",
                )
            ]
        return items[:limit] if limit is not None else items

    def timeline_assets(self, event_id: str, limit: int | None = None) -> list[AssetItem]:
        if not event_id.startswith("memory_"):
            return []
        album_type = event_id.removeprefix("memory_")
        return self.assets(album_type=album_type, limit=limit)

    def scan_summary(self) -> list[StatItem]:
        return self._stats(self.list_scan_jobs())

    def _persist_assets(self, assets: list[IndexedAsset]) -> None:
        with self.db.connection() as conn:
            conn.executemany(
                """
                INSERT INTO media_assets (
                    asset_id, source_id, source_name, root_path, relative_path, file_name, extension, media_kind,
                    smart_album_type, thumbnail_path, size_bytes, modified_at, last_scan_job_id
                ) VALUES (
                    :asset_id, :source_id, :source_name, :root_path, :relative_path, :file_name, :extension, :media_kind,
                    :smart_album_type, :thumbnail_path, :size_bytes, :modified_at, :last_scan_job_id
                )
                ON CONFLICT(root_path, relative_path) DO UPDATE SET
                    source_id=excluded.source_id,
                    source_name=excluded.source_name,
                    file_name=excluded.file_name,
                    extension=excluded.extension,
                    media_kind=excluded.media_kind,
                    smart_album_type=excluded.smart_album_type,
                    thumbnail_path=excluded.thumbnail_path,
                    size_bytes=excluded.size_bytes,
                    modified_at=excluded.modified_at,
                    last_scan_job_id=excluded.last_scan_job_id,
                    imported_at=CURRENT_TIMESTAMP
                """,
                [asdict(asset) for asset in assets],
            )

    def _update_job(self, job_id: str, *, status: str, progress: float, detail: str) -> ScanJobItem:
        with self.db.connection() as conn:
            conn.execute(
                """
                UPDATE scan_jobs
                SET status = ?, progress = ?, detail = ?, updated_at = CURRENT_TIMESTAMP
                WHERE job_id = ?
                """,
                (status, progress, detail, job_id),
            )
        job = self.get_scan_job(job_id)
        assert job is not None
        return job

    def _stats(self, jobs: list[ScanJobItem]) -> list[StatItem]:
        with self.db.connection() as conn:
            total_assets = conn.execute("SELECT COUNT(*) FROM media_assets").fetchone()[0]
            total_images = conn.execute(
                "SELECT COUNT(*) FROM media_assets WHERE media_kind = 'image'"
            ).fetchone()[0]
            total_videos = conn.execute(
                "SELECT COUNT(*) FROM media_assets WHERE media_kind = 'video'"
            ).fetchone()[0]
            recent_added = conn.execute(
                """
                SELECT COUNT(*)
                FROM media_assets
                WHERE datetime(imported_at) >= datetime('now', '-1 day')
                """
            ).fetchone()[0]
        return [
            StatItem(label="已索引素材", value=f"{total_assets:,}", delta=f"图片 {total_images} / 视频 {total_videos}"),
            StatItem(label="智能相册", value=str(len(self.albums())), delta="基于路径和类型聚合"),
            StatItem(label="待确认人物", value=str(self._needs_review_people()), delta="人脸聚类待接入"),
            StatItem(label="今日新增", value=str(recent_added), delta=jobs[0].mode if jobs else "等待扫描"),
        ]

    def _signals(self) -> list[StatItem]:
        with self.db.connection() as conn:
            by_type = conn.execute(
                """
                SELECT smart_album_type, COUNT(*) AS asset_count
                FROM media_assets
                GROUP BY smart_album_type
                ORDER BY asset_count DESC
                LIMIT 3
                """
            ).fetchall()
        if not by_type:
            return [
                StatItem(label="索引状态", value="待初始化"),
                StatItem(label="最近扫描", value="0"),
                StatItem(label="人物待确认", value=str(self._needs_review_people())),
            ]
        return [
            StatItem(label=f"{self._album_title(row['smart_album_type'])}", value=str(row["asset_count"]))
            for row in by_type
        ]

    def _album_item(self, album_type: str, count: int) -> AlbumItem:
        title, description, color, cover = ALBUM_META[album_type]
        confidence = min(0.98, 0.7 + min(count, 1000) / 5000)
        return AlbumItem(
            id=f"album_{album_type}",
            title=title,
            count=f"{count:,} 张",
            description=description,
            color=color,
            cover_label=cover,
            confidence=confidence,
            type=album_type,
        )

    def _album_title(self, album_type: str) -> str:
        return ALBUM_META.get(album_type, (album_type, "", "", ""))[0]

    def _timeline_tag(self, mode: str) -> str:
        return {
            "incremental": "扫描",
            "full": "全量",
            "thumbnail": "缩略图",
            "people": "人物",
        }.get(mode, "任务")

    def _needs_review_people(self) -> int:
        return sum(1 for item in self.people() if item.review_state == "needs_review")

    def _format_memory_date(self, raw: str | None) -> str:
        if not raw:
            return datetime.now().strftime("%m 月 %d 日")
        try:
            dt = datetime.fromisoformat(raw.replace("Z", "+00:00"))
            return dt.strftime("%m 月 %d 日")
        except ValueError:
            return datetime.now().strftime("%m 月 %d 日")

    def _thumbnail_url(self, thumbnail_path: str | None) -> str | None:
        if not thumbnail_path:
            return None
        return f"{self.thumbnails_base_url}/{thumbnail_path}"

    def _update_source_status(self, source_id: str, root_path: Path, *, scanned: bool = False) -> None:
        status = "ready" if root_path.exists() else "missing"
        with self.db.connection() as conn:
            conn.execute(
                """
                UPDATE media_sources
                SET status = ?, last_scan_at = CASE WHEN ? THEN CURRENT_TIMESTAMP ELSE last_scan_at END,
                    updated_at = CURRENT_TIMESTAMP
                WHERE source_id = ?
                """,
                (status, 1 if scanned else 0, source_id),
            )

    def _ensure_people_seed(self) -> None:
        with self.db.connection() as conn:
            count = conn.execute("SELECT COUNT(*) FROM people_clusters").fetchone()[0]
            if count > 0:
                return
            conn.executemany(
                """
                INSERT INTO people_clusters (
                    cluster_id, name, asset_count, trait, color, review_state, is_self
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                [
                    (
                        item.id,
                        item.name,
                        item.asset_count,
                        item.trait,
                        item.color,
                        item.review_state,
                        1 if item.is_self else 0,
                    )
                    for item in PEOPLE
                ],
            )
