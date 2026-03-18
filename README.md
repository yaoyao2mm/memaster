# memaster

memaster is a Flutter-first, local-first memory layer for personal media. It
turns local folders, mounted NAS paths, and other file-based sources into smart
albums, people clusters, correction loops, and event-style memory cards.

[GitHub Repository](https://github.com/yaoyao2mm/memaster)

## Current state

This repository contains:

- A polished Flutter UI skeleton for the first desktop/mobile MVP
- Product and architecture notes for a multi-source media index
- A design direction derived from Horizon UI and Apple-style software
- A local FastAPI service skeleton for indexing and smart-memory APIs

## Demo flow

1. Launch the macOS app
2. Let the app auto-start the local indexing service
3. Add the first local or mounted source in onboarding
4. Wait for the first scan job to build the index
5. Open `资产库` to inspect results, add tags, and locate originals
6. Open `智能相册` / `人物` / `时间轴` for higher-level views

## macOS demo preview

The current desktop demo already covers the main loop of the product:
scan a local or mounted folder, let the system group assets into semantic albums,
confirm people clusters, and revisit those materials again through event-style
timeline cards.

| Smart albums | People |
| --- | --- |
| ![macOS smart albums demo](assets/readme/albums-demo.png) | ![macOS people demo](assets/readme/people-demo.png) |
| Timeline | Organize |
| ![macOS timeline demo](assets/readme/timeline-demo.png) | ![macOS organize demo](assets/readme/organize-demo.png) |

## Planned product shape

`memaster` is not a generic file browser. It is a personal memory layer on top
of your media sources:

- Connect local folders, mounted NAS paths, and other file-based libraries
- Scan and index photos and videos
- Build smart albums such as cats, portraits, self, travel, food
- Let the user correct labels and train the system over time
- Turn media into searchable memories instead of folders

## Recommended stack

- UI: Flutter
- Local service: Python + FastAPI
- Storage: SQLite
- Vision inference: ONNX Runtime + CLIP/SigLIP + InsightFace

## Implemented demo capabilities

- Real scan jobs against local or mounted folders
- SQLite-backed asset index
- Smart album aggregation
- Asset-level label correction with persistence
- People confirmation with persistence
- Timeline memory cards with event asset drill-down
- Demo thumbnail pipeline for assets

## Local API service

For internal development only:

```bash
cd service
uv sync
uv run uvicorn app.main:app --reload --port 4318
```

Or from the repository root:

```bash
./scripts/start-backend.sh
```

## Flutter demo

For internal development only:

```bash
flutter pub get
flutter run -d macos
```

Or from the repository root:

```bash
./scripts/start-frontend.sh
```

## Stack control scripts

Run both services in the background:

```bash
./scripts/start-stack.sh
```

Restart both services:

```bash
./scripts/restart-stack.sh
```

Check whether both services are running:

```bash
./scripts/status-stack.sh
```

## macOS distribution

Build a trial bundle that embeds the local service:

```bash
./scripts/build-macos-distribution.sh
```

This produces:

- `dist/memaster.app`
- `dist/memaster.dmg`

More detail: [docs/distribution.md](docs/distribution.md)

## Trigger a real scan from Flutter

1. Launch the app and let it auto-start the local service
2. Choose a local folder or mount your UGREEN NAS over SMB so it appears as a local path such as `/Volumes/UGREEN/HomeMedia`
3. Complete the first-run onboarding
4. Open the `资产库` page to confirm the index exists
5. Open the `整理` page to inspect source and scan status

## Repository structure

- `lib/`: Flutter app
- `service/`: local FastAPI service
- `docs/`: product, API, and roadmap notes
- `.github/`: issue and PR templates
