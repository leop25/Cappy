# Data Model: Screen Capture & Annotation

**Feature**: 001-screen-capture
**Date**: 2026-05-18

## Entities

### Capture

Represents a single screenshot taken by the user.

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `id` | `UUID` | Unique identifier | Auto-generated |
| `mode` | `CaptureMode` | region / fullScreen / window | Required |
| `sourceRect` | `CGRect?` | Screen coordinates of captured area | Nil for full-screen captures |
| `sourceWindowID` | `CGWindowID?` | Window ID if mode == window | Nil otherwise |
| `timestamp` | `Date` | When the capture was taken | Auto-set on capture |
| `fileURL` | `URL` | Path to saved PNG file | Set after save succeeds |
| `image` | `CGImage` | Raw captured image data | Held in memory until saved + thumbnail dismissed |

**State transitions**:

```
[Trigger Capture] → Capturing (image in memory)
                  → Saving (writing PNG to disk)
                  → Saved (fileURL set, thumbnail visible)
                  → [Thumbnail dismissed] → Complete
                  → [User clicks thumbnail] → Editing (annotation session active)
```

### Annotation

A single drawing element placed on a capture during editing.

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `id` | `UUID` | Unique identifier | Auto-generated |
| `type` | `AnnotationType` | arrow / rectangle / circle / text | Required |
| `origin` | `CGPoint` | Top-left anchor (or start point for arrow) | Required |
| `size` | `CGSize` | Width and height (ignored for arrow) | Required for shapes |
| `endPoint` | `CGPoint?` | Arrow tip position | Required for arrow type |
| `color` | `AnnotationColor` | red / yellow / blue / green / white / black | Default: red |
| `text` | `String?` | Text content | Required for text type |
| `zIndex` | `Int` | Drawing order (higher = on top) | Auto-increment on creation |

**enum AnnotationType**: `.arrow`, `.rectangle`, `.circle`, `.text`

**enum AnnotationColor**: `.red`, `.yellow`, `.blue`, `.green`, `.white`, `.black`

### AnnotationSession

Tracks the state of one editing session for a capture.

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `captureID` | `UUID` | Link to the Capture being edited | Required |
| `annotations` | `[Annotation]` | Ordered list of annotations | Empty on session start |
| `undoStack` | `[[Annotation]]` | Snapshots for undo | Each entry is a full copy of `annotations` before an action |
| `redoStack` | `[[Annotation]]` | Snapshots for redo | Cleared when a new action is performed |
| `selectedTool` | `AnnotationType` | Currently active drawing tool | Default: arrow |
| `selectedColor` | `AnnotationColor` | Currently active color | Default: red |

**Operations**:

- `addAnnotation(_:)` — push current annotations to undoStack, add new annotation, clear redoStack
- `removeAnnotation(id:)` — push to undoStack, remove by ID, clear redoStack
- `updateAnnotation(id:, ...)` — push to undoStack, modify fields, clear redoStack
- `undo()` — push current annotations to redoStack, pop from undoStack, restore
- `redo()` — push current annotations to undoStack, pop from redoStack, restore
- `commitToImage()` — render all annotations onto the capture image, return new CGImage

**State transitions**:

```
[Session Created] → Editing
                  → [Undo] → Editing (annotations rolled back)
                  → [Redo] → Editing (annotations restored)
                  → [Save] → Committed (image overwritten, session discarded)
                  → [Close without save] → Discarded (original preserved)
```

## Validation Rules

- Annotation `size.width` and `size.height` must be ≥ 1px when type is rectangle or circle (prevents invisible zero-size annotations).
- Annotation `text` must be non-empty when type is text.
- `undoStack` is capped at 20 entries (oldest removed when cap exceeded), matching SC-005.
- At most one `AnnotationSession` exists per `Capture` at any time (if thumbnail is clicked again while editor is open, bring editor window to front rather than create a second session).
- File URLs must be within the designated save directory (`~/Pictures/Cappy/`). The app must not write outside this sandbox.
