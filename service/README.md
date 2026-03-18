# memaster Local AI Service

This service is the local process that the Flutter app should talk to for:

- NAS scan jobs
- Dashboard data
- Smart albums
- People clusters
- Memory timeline

## Run

```bash
cd service
uv sync
uv run uvicorn app.main:app --reload --port 4318
```

Optional environment variables:

```bash
export LOCAL_AI_DB_PATH="$PWD/data/memory.db"
export LOCAL_AI_DEFAULT_SCAN_ROOT="/Volumes/UGREEN/HomeMedia"
```

## Test

```bash
cd service
uv run pytest
```
