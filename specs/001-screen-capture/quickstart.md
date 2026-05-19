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
open Package.swift
```

There are no third-party package dependencies.

## Build & Run

1. Select the **Cappy** scheme and **My Mac** as the destination.
2. Press `Cmd+R` to build and run.
3. Use the menu bar icon or global shortcuts to capture.

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
| Global hotkeys | Carbon `RegisterEventHotKey` |
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
- Keyboard shortcut registration with system shortcut conflicts

### Debugging Tips

- If a global shortcut does not fire, confirm macOS has not reserved the same
  key combination in System Settings → Keyboard → Keyboard Shortcuts.
- Capture output is always written to `~/Pictures/Cappy/`.
