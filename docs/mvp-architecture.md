# MVP Architecture

## Goal

Deliver the first useful version of a local-first intelligent memory system for
personal media across multiple local and mounted sources.

## Product boundary

The MVP should focus on:

- Generic source management for local and mounted paths
- Media scanning and incremental indexing
- Smart album generation for a small set of valuable categories
- Human correction of labels and people clusters
- A premium browsing experience that feels closer to a memory journal than a file explorer

## Core architecture

### 1. Flutter app

Responsibilities:

- Browse smart albums and recent memories
- Add sources, trigger scans, and show index progress
- Review and correct classification results
- Search by source, person, pet, date, and type

### 2. Local AI service

Recommended runtime:

- Python + FastAPI for the first implementation

Responsibilities:

- Read files from configured local or mounted folders
- Generate thumbnails
- Extract EXIF metadata
- Compute embeddings
- Run content classification
- Run face detection and face clustering
- Persist results into SQLite

### 3. Local database

Recommended storage:

- SQLite

Suggested tables:

- `media_assets`
- `asset_thumbnails`
- `asset_embeddings`
- `face_embeddings`
- `people_clusters`
- `smart_labels`
- `scan_jobs`
- `user_corrections`

### 4. Source connectors

First implementations:

- Access media through a local folder path
- Access media through a user-mounted SMB path on the local machine

Why:

- Keeps the connector abstraction generic from the start
- Avoids reverse engineering vendor app behavior
- Keeps the first version stable and portable
- Makes desktop-first usage straightforward

## Inference approach

### First-wave classifiers

- Cat / pet
- Portrait
- Self
- Food
- Travel / landscape
- Screenshot / document

### Recognition strategy

`Self` should not be guessed as a direct class. It should be produced from:

1. Face detection
2. Face embeddings
3. Face clustering
4. User confirmation that one cluster is "me"
5. Label propagation to future assets

## Product phases

### Phase 1

- Add and manage a source
- Scan a local or mounted directory
- Build media index
- Generate thumbnails
- Show beautiful dashboard, asset library, and album views

### Phase 2

- Add image embeddings
- Add content classification
- Add manual correction flow

### Phase 3

- Add face clustering and identity assignment
- Add semantic search and memory timeline
