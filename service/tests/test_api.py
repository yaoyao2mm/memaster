from pathlib import Path

from fastapi.testclient import TestClient

from app.core.database import Database
from app.core.settings import Settings
from app.main import create_app
from app.services.indexer import FileIndexer
from app.services.repository import MemoryRepository
from app.services.thumbnailer import Thumbnailer


def make_client(tmp_path: Path) -> TestClient:
    media_root = tmp_path / "media"
    media_root.mkdir()
    (media_root / "cat_sleeping.jpg").write_bytes(b"cat")
    (media_root / "trip_beach.png").write_bytes(b"trip")
    (media_root / "screen_shot_001.png").write_bytes(b"screen")
    (media_root / "clip.mov").write_bytes(b"video")

    settings = Settings(
        db_path=tmp_path / "memory.db",
        default_scan_root=media_root,
        thumbnails_dir=tmp_path / "thumbs",
    )
    settings.thumbnails_dir.mkdir()
    repository = MemoryRepository(
        db=Database(settings.db_path),
        indexer=FileIndexer(Thumbnailer(settings.thumbnails_dir)),
    )
    app = create_app(settings=settings, repository=repository, bootstrap=True)
    return TestClient(app)


def test_health(tmp_path: Path):
    client = make_client(tmp_path)
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_dashboard_shape(tmp_path: Path):
    client = make_client(tmp_path)
    response = client.get("/dashboard")
    assert response.status_code == 200
    payload = response.json()
    assert len(payload["stats"]) >= 4
    assert len(payload["sources"]) >= 1
    assert len(payload["smart_albums"]) >= 3
    assert len(payload["people"]) >= 1
    assert payload["stats"][0]["value"] == "4"


def test_sources_and_scan_job(tmp_path: Path):
    client = make_client(tmp_path)
    second_root = tmp_path / "second"
    second_root.mkdir()
    (second_root / "coffee.jpg").write_bytes(b"coffee")

    create_source = client.post(
        "/sources",
        json={
            "source_type": "local_folder",
            "display_name": "Second Library",
            "root_path": str(second_root),
        },
    )
    assert create_source.status_code == 201
    source_id = create_source.json()["item"]["source_id"]

    response = client.post(
        "/scan-jobs",
        json={
            "source_id": source_id,
            "recursive": True,
            "mode": "incremental",
        },
    )
    assert response.status_code == 201
    job_id = response.json()["job_id"]

    job_response = client.get(f"/scan-jobs/{job_id}")
    assert job_response.status_code == 200
    assert job_response.json()["source_id"] == source_id
    assert job_response.json()["root_path"] == str(second_root)

    source_assets = client.get("/assets", params={"source_id": source_id}).json()
    assert source_assets["total"] == 1
    assert source_assets["items"][0]["file_name"] == "coffee.jpg"

    duplicate_source = client.post(
        "/sources",
        json={
            "source_type": "local_folder",
            "display_name": "Duplicate Name",
            "root_path": str(second_root),
        },
    )
    assert duplicate_source.status_code == 201
    assert duplicate_source.json()["item"]["source_id"] == source_id


def test_confirm_person(tmp_path: Path):
    client = make_client(tmp_path)
    response = client.post(
        "/people/person_unknown_a/confirm",
        json={"name": "我", "is_self": True},
    )
    assert response.status_code == 200
    assert response.json()["item"]["name"] == "我"
    assert response.json()["item"]["is_self"] is True


def test_assets_filter(tmp_path: Path):
    client = make_client(tmp_path)
    default_source = client.get("/sources").json()["items"][0]["source_id"]
    response = client.get("/assets", params={"album_type": "pet", "source_id": default_source})
    assert response.status_code == 200
    payload = response.json()
    assert payload["total"] == 1
    assert payload["items"][0]["file_name"] == "cat_sleeping.jpg"
    assert payload["items"][0]["thumbnail_url"].endswith(".svg")


def test_album_correction_updates_asset(tmp_path: Path):
    client = make_client(tmp_path)
    before = client.get("/assets", params={"album_type": "pet"}).json()
    assert before["total"] == 1
    asset_id = before["items"][0]["asset_id"]

    correction = client.post(
        "/corrections",
        json={
            "asset_id": asset_id,
            "kind": "album_label",
            "from": "pet",
            "to": "travel",
        },
    )
    assert correction.status_code == 202

    after_pet = client.get("/assets", params={"album_type": "pet"}).json()
    after_travel = client.get("/assets", params={"album_type": "travel"}).json()
    assert after_pet["total"] == 0
    assert any(item["asset_id"] == asset_id for item in after_travel["items"])


def test_recent_corrections_list(tmp_path: Path):
    client = make_client(tmp_path)
    asset_id = client.get("/assets", params={"album_type": "pet"}).json()["items"][0]["asset_id"]
    client.post(
        "/corrections",
        json={"asset_id": asset_id, "kind": "album_label", "from": "pet", "to": "daily"},
    )
    response = client.get("/corrections", params={"limit": 5})
    assert response.status_code == 200
    payload = response.json()
    assert payload["total"] >= 1
    assert payload["items"][0]["asset_id"] == asset_id


def test_timeline_assets(tmp_path: Path):
    client = make_client(tmp_path)
    timeline = client.get("/timeline").json()
    assert timeline["total"] >= 1
    event_id = timeline["items"][0]["id"]
    assets = client.get(f"/timeline/{event_id}/assets").json()
    assert assets["total"] >= 1
