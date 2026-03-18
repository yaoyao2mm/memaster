# Product Strategy

## Positioning

`memaster` should evolve from a NAS-focused media browser into a local-first
personal media index.

The product is not defined by where files are stored. It is defined by a
unified metadata layer that lets a user find memories across many sources
through tags, people, events, and search.

## Core product statement

`memaster` is a local-first media indexing system for personal photos and
videos across mounted folders, local directories, external drives, and NAS
libraries.

## Source model

Supported source types should be treated as connectors:

- Local folders on the current machine
- SMB or NAS mounted folders
- External disks and archive drives
- Exported photo libraries
- Synced cloud folders that appear as local paths

Each source should expose:

- `source_id`
- `source_type`
- `root_path`
- `display_name`
- `status`
- `last_scan_at`
- `scan_mode`

## Product principles

- Local-first by default: indexing, metadata, and retrieval should work without
  requiring a cloud backend.
- Index-first, not copy-first: the system should build a fast local index
  before considering any asset duplication or migration.
- Multi-source from day one: source handling should be generic even if the
  first connector is a mounted path.
- Human correction loops matter: tags, people, and duplicate suggestions should
  improve from explicit user feedback.
- Memory view over file view: the primary experience is semantic retrieval, not
  directory browsing.

## Unified object model

### Source

Represents where assets come from.

### Asset

Represents one original media object and its normalized metadata.

Suggested fields:

- `asset_id`
- `source_id`
- `source_path`
- `content_hash`
- `perceptual_hash`
- `media_type`
- `captured_at`
- `imported_at`
- `width`
- `height`
- `duration_ms`
- `thumbnail_path`

### Derived entities

- `asset_tags`
- `tag_definitions`
- `people_clusters`
- `person_assignments`
- `memory_events`
- `asset_embeddings`
- `duplicate_groups`
- `user_corrections`

## Key user flows

### 1. Add a source

The user adds a local folder, mounted NAS path, or external drive path.

### 2. Build the index

The service scans the source, extracts metadata, computes thumbnails and
embeddings, and stores results in SQLite.

### 3. Review semantic groupings

The user sees smart albums such as cats, portraits, travel, food, screenshots,
and can confirm or correct them.

### 4. Revisit by meaning

The user finds assets through tags, people, event cards, and combined filters
instead of by remembering folder names.

## Roadmap tiers

### MVP must-have

- Generic source management
- Full asset index with source metadata
- Thumbnail generation
- Basic tags and smart albums
- Manual correction flow
- Global asset library
- Filter by source, date, media type, and tag
- Open original file from indexed asset

### V1 good

- Incremental indexing
- Duplicate and near-duplicate grouping
- Tag hierarchy such as `cat > orange cat`
- Better search ranking
- Person confirmation and propagation
- Event grouping for timeline

### V2 defensible

- Embedding-based semantic retrieval
- Cross-source deduplication confidence
- Personal curation signals such as favorites, hides, keep/delete review
- Background watch mode for attached sources
- Optional hybrid enrichment with cloud models

## Recommended next implementation slice

1. Introduce a first-class `Source` model across app, service, and database.
2. Add a source management screen in the Flutter app.
3. Replace single scan entry with `scan source` and `rescan source`.
4. Add a global asset library screen with source and tag filters.
5. Add user-defined tags on top of model-generated tags.
