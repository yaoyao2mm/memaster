# memaster

memaster is a local-first memory layer for personal media.

It sits on top of local folders, mounted NAS paths, and other file-based
libraries, then turns those raw assets into:

- smart albums
- people clusters
- editable labels and correction loops
- event-style timeline cards
- a searchable local asset index

The current repository ships a Flutter desktop/mobile app plus a local FastAPI
service that handles indexing, metadata, thumbnails, and demo intelligence
workflows.

[GitHub Repository](https://github.com/yaoyao2mm/memaster)

## Why This Exists

Most personal media tools are still organized like file browsers. memaster is
trying to behave more like a personal memory system:

- source-first, not folder-first
- semantic organization, not manual directory naming
- local-first execution, not cloud-required
- user correction as part of the product loop, not an afterthought

The goal is not just to browse files. The goal is to help the user revisit
people, trips, pets, food, documents, and daily life as coherent memories.

## What Works Today

Current demo capabilities:

- local and mounted-folder source management
- real scan jobs against selected sources
- SQLite-backed asset index
- smart album aggregation
- asset-level tag editing
- album correction persistence
- people confirmation workflows
- event-style timeline views
- thumbnail pipeline for demo assets
- app-managed local backend bootstrap on startup

## Screenshots

The current macOS demo already covers the main product loop:

- add a source
- auto-start the local service
- build an index
- inspect assets
- confirm people
- revisit grouped memories

| Smart albums | People |
| --- | --- |
| ![macOS smart albums demo](assets/readme/albums-demo.png) | ![macOS people demo](assets/readme/people-demo.png) |
| Timeline | Organize |
| ![macOS timeline demo](assets/readme/timeline-demo.png) | ![macOS organize demo](assets/readme/organize-demo.png) |

## Product Shape

memaster is currently centered on a simple but opinionated flow:

1. Connect a local folder or mounted NAS path
2. Run a scan job and build the local index
3. Browse the unified asset library
4. Review smart albums and people clusters
5. Correct labels where the system is wrong
6. Revisit those assets as event-driven memories

This repository is not aiming to be a generic DAM or cloud photo platform.

## Tech Stack

- UI: Flutter
- Local service: Python + FastAPI
- Storage: SQLite
- Thumbnails: local file pipeline
- Future inference direction: ONNX Runtime + CLIP/SigLIP + InsightFace

## Project Layout

- `lib/`: Flutter application
- `service/`: local FastAPI service
- `assets/readme/`: README screenshots
- `scripts/`: local dev and packaging scripts
- `docs/`: product, architecture, API, and distribution notes

## Quick Start

### 1. Run the app

```bash
flutter pub get
flutter run -d macos
```

The app will try to auto-start the local service on launch.

In development, backend startup now prefers:

1. `service/.venv/bin/python`
2. `uv run ...` when available

That means you usually do not need to manually start the backend if the local
runtime already exists.

### 2. If you want to start the backend yourself

```bash
./scripts/start-backend.sh
```

Or directly:

```bash
cd service
uv sync
uv run uvicorn app.main:app --reload --port 4318
```

### 3. Run the whole stack from the repo root

```bash
./scripts/start-stack.sh
```

Useful helpers:

```bash
./scripts/restart-stack.sh
./scripts/status-stack.sh
./scripts/start-frontend.sh
```

## First Demo Flow

Use this if you want to see the product loop quickly:

1. Launch the macOS app
2. Let the app auto-start the local service
3. Add your first local folder or mounted NAS path in onboarding
4. Wait for the first scan to finish
5. Open `资产库` to confirm assets were indexed
6. Open `智能相册`, `人物`, and `时间轴`
7. Open `整理` to inspect source and task status

Example mounted source path:

```text
/Volumes/UGREEN/HomeMedia
```

## Development Notes

### Backend bootstrap behavior

The Flutter app is expected to start the local service automatically during app
bootstrap.

If that fails, check:

- `service/.venv`
- whether `uv` exists in PATH
- the generated service log:

```text
~/Library/Application Support/memaster/logs/service.log
```

### Local service health endpoint

```text
http://127.0.0.1:4318/health
```

### Tests

```bash
/Users/john/flutter/bin/flutter analyze
/Users/john/flutter/bin/flutter test
```

## Distribution

Build a macOS bundle with the local service embedded:

```bash
./scripts/build-macos-distribution.sh
```

Outputs:

- `dist/memaster.app`
- `dist/memaster.dmg`

More detail:

- [docs/distribution.md](docs/distribution.md)

## Documentation

- [docs/local-ai-api.md](docs/local-ai-api.md)
- [docs/mvp-architecture.md](docs/mvp-architecture.md)
- [docs/product-strategy.md](docs/product-strategy.md)
- [docs/ui-direction.md](docs/ui-direction.md)
- [docs/roadmap.md](docs/roadmap.md)
- [docs/distribution.md](docs/distribution.md)

## Status

memaster is still an MVP-stage local product prototype, but the repository now
already demonstrates the full source -> scan -> index -> review -> correct
loop with a polished Flutter shell and a real local backend.
