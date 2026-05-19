# Quickstart: Screen Capture & Annotation

**Feature**: 001-screen-capture
**Date**: 2026-05-18

## Prerequisites

- macOS 14 (Sonoma) or later
- Xcode 15.0+ (Swift 5.9 toolchain)
- Git (for version control)

## Setup

```bash
# Clone the repository
git clone <repo-url>
cd Cappy

# Open in Xcode
open Cappy.xcodeproj
```

Xcode auto-resolves Swift package dependencies (none for v1).

## Build & Run

1. Select the **Cappy** scheme and **My Mac** as the destination.
2. Press `Cmd+R` to build and run.
3. On first launch, macOS prompts for **Accessibility** permission. Grant it to
   enable global keyboard shortcuts.

## Development Quick Reference

### Project Layout

```
Cappy/
├── CappyApp.swift              # App entry: MenuBarExtra + keyboard shortcuts
├── Models/
│   ├── Capture.swift           # Capture metadata
│   └── Annotation.swift        # Annotation types + colors
├── Services/
│   ├── CaptureService.swift    # CGDisplay/CGWindow capture
│   ├── AnnotationService.swift # Undo/redo + annotation CRUD
│   └── FileService.swift       # PNG I/O + folder management
├── Views/
│   ├── Capture/
│   │   ├── DimOverlay.swift    # Full-screen dim + region selection
│   │   ├── CaptureToolbar.swift
│   │   └── ThumbnailView.swift
│   ├── Annotation/
│   │   ├── AnnotationEditor.swift
│   │   ├── AnnotationCanvas.swift
│   │   └── AnnotationToolbar.swift
│   └── MenuBar/
│       └── MenuBarView.swift
├── Utilities/
│   └── ImageExtensions.swift
└── Resources/
    └── Assets.xcassets
```

### Key APIs Used

| Purpose | API |
|---------|-----|
| Full-screen capture | `CGDisplayCreateImage(_:)` |
| Window capture | `CGWindowListCreateImage` + `CGWindowListCopyWindowInfo` |
| PNG encoding | `CGImageDestinationCreateWithURL` with `kUTTypePNG` |
| Global hotkeys | `NSEvent.addGlobalMonitorForEvents(matching:)` |
| Dim overlay window | `NSWindow` (borderless, `.screenSaver` level) via AppKit bridging |
| Menu bar | SwiftUI `MenuBarExtra` scene |
| Annotation drawing | SwiftUI `Canvas` with `GraphicsContext` |
| File save location | `FileManager` → `~/Pictures/Cappy/` |

### Testing

```bash
# Run unit tests
xcodebuild test -scheme Cappy -destination 'platform=macOS'

# Run a single test class
xcodebuild test -scheme Cappy -destination 'platform=macOS' \
  -only-testing:CappyTests/CaptureServiceTests
```

UI testing for the capture overlay is impractical via XCUITest due to its
full-screen, system-level nature. Manual testing is required for:
- Region drag selection across display boundaries
- Window picker hover highlighting
- Keyboard shortcut registration with system shortcuts
- Accessibility permission prompts

### Debugging Tips

- Set `CAPPY_DEBUG_OVERLAY=1` environment variable in Xcode scheme to make the
  dim overlay semi-transparent instead of dim, allowing inspection behind it.
- Log capture times: `CaptureService` prints the time from trigger to file
  written for every capture (visible in Xcode console).
- Thumbnail auto-dismiss can be disabled for debugging by setting
  `CAPPY_DEBUG_THUMBNAIL=1` (thumbnail stays until clicked).
