# memaster

<p align="center">
  <strong>A local-first memory layer for personal media.</strong>
</p>

<p align="center">
  memaster turns local folders and mounted NAS paths into a searchable memory system with smart albums,
  people clusters, timeline views, and a bundled desktop indexing service.
</p>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Flutter-54C5F8?style=flat-square">
  <img alt="Focus" src="https://img.shields.io/badge/focus-local--first%20media-172033?style=flat-square">
  <img alt="Backend" src="https://img.shields.io/badge/backend-FastAPI%20%2B%20SQLite-8FB4FF?style=flat-square">
  <img alt="Desktop" src="https://img.shields.io/badge/macOS-embedded%20service-BBF4D2?style=flat-square&labelColor=172033&color=BBF4D2">
</p>

## Why It Exists

Most personal media tools still behave like file browsers.
memaster is trying to behave more like a personal memory system:

- source-first, not folder-first
- semantic organization, not manual directory naming
- local-first execution, not cloud-required
- user correction as part of the product loop, not an afterthought

The goal is not just to browse files.
The goal is to help the user revisit people, trips, pets, food, documents, and daily life as coherent memories.

## Highlights

- Local and mounted-folder source management
- Real scan jobs against selected folders
- SQLite-backed local asset index
- Smart album aggregation
- People confirmation workflows
- Timeline-style memory views
- Asset tag editing and correction persistence
- Bundled local FastAPI service for the macOS app
- Custom desktop shell with a lightweight memaster title bar

## Screenshots

The current macOS demo already covers the main product loop:

- add a source
- auto-start the local service
- build the local index
- inspect assets
- confirm people
- revisit grouped memories

| Smart albums | People |
| --- | --- |
| ![macOS smart albums demo](assets/readme/albums-demo.png) | ![macOS people demo](assets/readme/people-demo.png) |
| Timeline | Organize |
| ![macOS timeline demo](assets/readme/timeline-demo.png) | ![macOS organize demo](assets/readme/organize-demo.png) |

## Platform Support

| Platform | Status | Notes |
| --- | --- | --- |
| macOS | Best supported | Custom desktop shell, embedded backend, real packaging flow |
| iOS | Early scaffold | Flutter app exists, but bundled local service flow is not productized |
| Android | Early scaffold | Flutter app exists, but bundled local service flow is not productized |
| Windows | Not packaged yet | App structure exists, distribution flow not finished |
| Linux | Not packaged yet | App structure exists, distribution flow not finished |

## Run

```bash
flutter pub get
flutter run -d macos
```

The app will try to auto-start the local service on launch.

In development, backend startup prefers:

1. `service/.venv/bin/python`
2. `uv run ...` when available

That means you usually do not need to start the backend manually if the local runtime already exists.

### Start the backend yourself

```bash
./scripts/start-backend.sh
```

Or directly:

```bash
cd service
uv sync
uv run uvicorn app.main:app --reload --port 4318
```

### Run the full local stack

```bash
./scripts/start-stack.sh
```

Useful helpers:

```bash
./scripts/restart-stack.sh
./scripts/status-stack.sh
./scripts/start-frontend.sh
```

## Install On macOS Without An Apple Developer Account

The packaged macOS app is currently unsigned for public distribution.
If macOS blocks it on first launch, remove the quarantine flag in Terminal:

```bash
xattr -dr com.apple.quarantine /Applications/memaster.app
```

If the app lives somewhere else, replace the path with the actual app location.

## Local Service Notes

### Health endpoint

```text
http://127.0.0.1:4318/health
```

### Development data path

```text
~/Library/Application Support/memaster/
```

### Packaged macOS app data path

```text
~/Library/Containers/com.memaster.app/Data/Library/Application Support/memaster/
```

The packaged app restores data from previous memaster locations into the new container on first launch.

## Distribution

Build a macOS bundle with the local service embedded:

```bash
./scripts/build-macos-distribution.sh
```

Outputs:

- `dist/memaster.app`
- `dist/memaster.dmg`

The current macOS packaging flow:

- embeds the FastAPI service under `Contents/Resources/service`
- embeds a managed CPython runtime into the app bundle
- installs production service dependencies into that runtime
- re-signs the rebuilt app bundle after packaging changes
- restores local memaster data into the new sandbox container on first launch

More detail:

- [docs/distribution.md](docs/distribution.md)

## Verify

```bash
flutter analyze
flutter test
```

## Documentation

- [docs/local-ai-api.md](docs/local-ai-api.md)
- [docs/mvp-architecture.md](docs/mvp-architecture.md)
- [docs/product-strategy.md](docs/product-strategy.md)
- [docs/ui-direction.md](docs/ui-direction.md)
- [docs/roadmap.md](docs/roadmap.md)
- [docs/distribution.md](docs/distribution.md)

## Todo

This section highlights the areas that still need the most product and release work.

- [x] Rebrand the desktop app to `memaster`
- [x] Replace the native desktop title bar with a custom shell header
- [x] Bundle a local backend into the macOS app
- [x] Restore previous local memaster data into the new app container
- [ ] Improve the onboarding and source setup flow for first-time users
- [ ] Expand the library and memory views beyond the current MVP demo depth
- [ ] Harden desktop distribution with proper signing and notarization
- [ ] Finish Windows and Linux packaging paths

## Project Direction

memaster is intentionally opinionated:

- local-first over cloud-first
- memory views over raw file browsing
- correction loops over one-shot automation
- desktop utility over heavyweight DAM complexity

That keeps the product focused on helping people revisit their own media as memories instead of as folders.
