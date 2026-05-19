# Implementation Plan: Screen Capture & Annotation

**Branch**: `001-screen-capture` | **Date**: 2026-05-18 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-screen-capture/spec.md`

## Summary

Build a macOS-native screenshot tool (menu bar app) with three capture modes
(region, full-screen, window), automatic PNG saving, and an annotation editor
with arrow, rectangle, circle, and text tools. The capture interface uses a
full-screen dim overlay with crosshair selection — zero traditional windows
during capture. The annotation editor opens as a resizable window when the
user clicks the post-capture thumbnail.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, AppKit (for CGWindow/CGDisplay screen capture, NSStatusBar, NSWindow overlay management). No third-party packages.
**Storage**: File system — PNG files saved to `~/Pictures/Cappy/`. No database.
**Testing**: XCTest (unit), manual walkthroughs (UI). Automated UI testing for floating overlay is impractical on macOS.
**Target Platform**: macOS 14 (Sonoma) minimum
**Project Type**: macOS desktop application (menu bar app with optional editor window)
**Performance Goals**: Capture-to-file under 500ms (full-screen/window), under 1s (region, excluding drag time). Annotation rendering at 60fps during drag. Memory ≤200MB idle.
**Constraints**: Max 3 clicks/menu interactions per action. No blocking UI >2s. No windows during capture phase. Global keyboard shortcuts (fallback if system overrides Cmd+Shift+3/4).
**Scale/Scope**: Single-user local app. 5 interaction surfaces: menu bar dropdown, dim overlay+crosshair, window picker, post-capture thumbnail, annotation editor window.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Simple UX (≤3 clicks) | ✅ PASS | All capture modes: 1 shortcut press or ≤2 menu bar clicks. Annotation: 1 click thumbnail + 1 click tool + drag. |
| II. Mac-First with SwiftUI | ✅ PASS | SwiftUI for UI; AppKit bridging only for CGWindow/CGDisplay capture, NSStatusBar, and NSWindow overlays — all allowed by constitution. |
| III. Performance (≤2s) | ✅ PASS | CGDisplayCreateImage and CGWindowListCreateImage are sub-50ms. PNG encoding ~50-100ms. File write async. Annotation drawing via Canvas is GPU-accelerated. |
| IV. Simplicity Over Engineering | ✅ PASS | No database (file system only). No third-party dependencies. No multi-user, networking, or auth. Models are plain structs. |

## Project Structure

### Documentation (this feature)

```text
specs/001-screen-capture/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── keyboard-shortcuts.md
│   └── menu-bar-actions.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
Cappy/
├── CappyApp.swift               # @main App, MenuBarExtra scene, global keyboard shortcuts
├── Models/
│   ├── Capture.swift            # Capture metadata struct
│   └── Annotation.swift         # Annotation model (enum: arrow, rect, circle, text)
├── Services/
│   ├── CaptureService.swift     # CGDisplay/CGWindow screen capture logic
│   ├── AnnotationService.swift  # Annotation CRUD, undo/redo stack
│   └── FileService.swift        # ~/Pictures/Cappy/ management, PNG write
├── Views/
│   ├── Capture/
│   │   ├── DimOverlay.swift     # Full-screen dim overlay with crosshair selection
│   │   ├── CaptureToolbar.swift # Floating toolbar (region/full/window picker)
│   │   └── ThumbnailView.swift  # Post-capture floating thumbnail
│   ├── Annotation/
│   │   ├── AnnotationEditor.swift  # Main editor window (resizable)
│   │   ├── AnnotationCanvas.swift  # Canvas with drawing tools
│   │   └── AnnotationToolbar.swift # Tool picker + color palette
│   └── MenuBar/
│       └── MenuBarView.swift    # Menu bar dropdown content
├── Utilities/
│   └── ImageExtensions.swift    # CGImage → PNG Data, NSImage helpers
├── Resources/
│   └── Assets.xcassets          # App icon, toolbar icons
└── Cappy.xcodeproj              # (or project.pbxproj for SPM-managed)
```

**Structure Decision**: Single Xcode project with SwiftUI App lifecycle. No separate library targets or modules — the app is small enough that modularization would violate Principle IV (Simplicity Over Engineering). Source files are organized by concern (Models, Services, Views) for readability, not by technical module boundaries.

## Complexity Tracking

> No constitution violations. Table intentionally empty.
