from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from app.api.routes import router
from app.core.database import Database
from app.core.settings import Settings, load_settings
from app.services.indexer import FileIndexer
from app.services.repository import MemoryRepository
from app.services.thumbnailer import Thumbnailer


def create_app(
    *,
    settings: Settings | None = None,
    repository: MemoryRepository | None = None,
    bootstrap: bool = False,
) -> FastAPI:
    settings = settings or load_settings()
    repository = repository or MemoryRepository(
        db=Database(settings.db_path),
        indexer=FileIndexer(Thumbnailer(settings.thumbnails_dir)),
    )
    repository.ensure_reference_data()
    if bootstrap:
        repository.ensure_seed_data(settings.default_scan_root)

    app = FastAPI(
        title="memaster Local AI Service",
        version="0.1.0",
        summary="Local-first API for NAS memories",
    )
    app.state.repository = repository
    app.state.settings = settings
    app.include_router(router)
    app.mount("/thumbs", StaticFiles(directory=settings.thumbnails_dir), name="thumbs")
    return app


app = create_app()
