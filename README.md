# memaster

An opinionated Flutter-first app for intelligent NAS memories.

## Current state

This repository contains:

- A polished Flutter UI skeleton for the first desktop/mobile MVP
- Product and architecture notes for the NAS memory workflow
- A design direction derived from Horizon UI and Apple-style software
- A local FastAPI service skeleton for indexing and smart-memory APIs

## Planned product shape

`memaster` is not a generic NAS file browser. It is a personal memory layer on top of NAS media:

- Connect to a NAS over SMB or a mounted network folder
- Scan and index photos and videos
- Build smart albums such as cats, portraits, self, travel, food
- Let the user correct labels and train the system over time
- Turn media into searchable memories instead of folders

## Recommended stack

- UI: Flutter
- Local service: Python + FastAPI
- Storage: SQLite
- Vision inference: ONNX Runtime + CLIP/SigLIP + InsightFace

## Run status

The workspace where this was created does not currently have Flutter installed, so the UI code could not be executed here.

Once Flutter is available, the next step is:

```bash
flutter pub get
flutter run -d macos
```

## Local API service

```bash
cd service
uv sync
uv run uvicorn app.main:app --reload --port 4318
```

## Trigger a real scan from Flutter

1. Mount your UGREEN NAS over SMB so it appears as a local path such as `/Volumes/UGREEN/HomeMedia`
2. Start the local API service
3. Launch the Flutter app
4. Open the `整理` page
5. Paste the mounted path and click `开始扫描`
