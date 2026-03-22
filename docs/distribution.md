# Distribution

## Goal

Ship a single macOS app to trial users.

The user should not install Python, run `uvicorn`, or start a separate backend
manually. The Flutter app and the local indexing service remain separate
internally, but they are distributed as one desktop bundle.

## Packaging model

- Frontend: Flutter macOS app
- Backend: bundled FastAPI service under `Contents/Resources/service`
- Python runtime: bundled from a managed CPython runtime prepared during the
  packaging step
- User data: created on first launch under the app sandbox container

## User-visible startup flow

1. User launches the macOS app
2. App checks `http://127.0.0.1:4318/health`
3. If needed, app starts the bundled local service
4. If no source exists, app opens the first-run onboarding flow
5. User adds a first local or mounted folder source
6. App creates the first scan job and opens the main shell

## Writable runtime directories

The app should write mutable files outside the bundle.

Current macOS target:

- `~/Library/Containers/com.memaster.app/Data/Library/Application Support/memaster/memory.db`
- `~/Library/Containers/com.memaster.app/Data/Library/Application Support/memaster/thumbnails/`
- `~/Library/Containers/com.memaster.app/Data/Library/Application Support/memaster/logs/service.log`

## Build artifacts

### Build a release app and DMG

```bash
./scripts/build-macos-distribution.sh
```

Output:

- `dist/memaster.app`
- `dist/memaster.dmg`

### Build only the app bundle

```bash
CREATE_DMG=0 ./scripts/build-macos-distribution.sh
```

## What the packaging script does

1. Runs `flutter build macos`
2. Copies the release `.app` into `dist/`
3. Embeds `service/` into `Contents/Resources/service`
4. Embeds a managed CPython runtime into `Contents/Resources/service/.venv`
5. Installs the local service package and its production dependencies into that runtime
6. Re-signs the app bundle after packaging changes
7. Optionally creates a DMG with `hdiutil`

## Current limitations

- The app is not code-signed or notarized yet.
- The embedded service path is wired for macOS trial distribution first.
- Windows and Linux packaging are not implemented yet.

## Next release-hardening steps

1. Sign and notarize the app bundle
2. Add a release verification script that checks the embedded service
3. Replace direct process spawning with a more formal launch monitor if needed
4. Add a visible diagnostics entry for logs and health state
