# Research: Screen Capture & Annotation

**Feature**: 001-screen-capture
**Date**: 2026-05-18

## Decision: Global Keyboard Shortcuts

**Decision**: Use `KeyboardShortcut` (SwiftUI) for in-app shortcuts. For global
shortcuts, register via `NSEvent.addGlobalMonitorForEvents(matching:.keyDown)`
and `NSEvent.addLocalMonitorForEvents` to intercept before system.

**Rationale**: macOS does not allow apps to override reserved system shortcuts
(`Cmd+Shift+3`, `Cmd+Shift+4`) — they are managed by `screencapture` and the
system. Attempting `CGEvent.tapCreate` for these specific key combos would
require accessibility permissions and may still conflict. Instead:

- **Primary strategy**: Register `Cmd+Shift+5` (region), `Cmd+Shift+6` (full
  screen), `Cmd+Shift+7` (window) as global hotkeys using `NSEvent` monitors.
  These are not reserved by macOS.
- **Attempt override**: On launch, attempt to register `Cmd+Shift+4` and
  `Cmd+Shift+3`. If macOS rejects or they don't fire, fall back silently to the
  primary shortcuts and notify the user once via an alert.
- **`NSEvent.addGlobalMonitorForEvents`** captures key events system-wide but
  requires the app to have Accessibility permissions (System Preferences →
  Privacy & Security → Accessibility). This is acceptable — many screenshot
  tools (CleanShot, Snagit) require the same.

**Alternatives considered**:
- `CGEvent.tapCreate` with `.cgSessionEventTap` — more powerful but requires
  the app to be trusted and may intercept system events in confusing ways.
  Rejected: over-engineering for v1.
- `RegisterEventHotKey` (Carbon) — deprecated. Rejected.
- `keyboardShortcut` SwiftUI modifier — works only when app is frontmost.
  Rejected for global use cases.

## Decision: Screen Capture API

**Decision**: Use `CGWindowListCreateImage` for both full-screen and window
capture. Use `CGDisplayCreateImage` as fallback for full-screen capture on
multi-display setups.

**Rationale**:
- `CGWindowListCreateImage` with `kCGNullWindowID` and
  `kCGWindowListOptionOnScreenOnly` captures the entire screen (all displays
  composited) in a single call.
- `CGDisplayCreateImage(_:)` captures a specific display individually, needed
  for multi-display separate-file output (FR-013).
- Both APIs are synchronous, fast (~10-50ms for a 4K display), and return
  `CGImage` directly.
- `ScreenCaptureKit` (macOS 12.3+) provides stream-based capture with user
  permission prompts. Better for video/screen recording; over-engineering for
  still image capture. Rejected due to Principle IV.

**Alternatives considered**:
- `ScreenCaptureKit` — modern but requires async stream setup, permission
  dialogs, and more complex API surface. Rejected: unnecessary for still
  captures.
- `NSView.bitmapImageRepForCachingDisplay(in:)` — AppKit view-level capture.
  Rejected: cannot capture other apps or the full desktop.

## Decision: Window Capture with Shadow

**Decision**: Use `CGWindowListCreateImage` with
`kCGWindowListOptionIncludingWindow` and the target window ID. Pass
`kCGWindowImageBoundsIgnoreFraming` and
`kCGWindowImageNominalResolution` options to include the window's shadow
and rounded corners.

**Rationale**: `CGWindowListCreateImage` with
`kCGWindowImageBoundsIgnoreFraming` expands the capture rect to include the
shadow that macOS renders around windows. The result is a `CGImage` with
transparent pixels outside the window bounds, matching what the user sees.

To enumerate windows: `CGWindowListCopyWindowInfo(.optionOnScreenOnly,
kCGNullWindowID)` returns an array of dictionaries with window IDs, titles,
owners, and bounds. Filter by `kCGWindowLayer` < 1000 (exclude desktop icons,
menu bar, dock).

**Alternatives considered**:
- `CGWindowListCreateImage` without shadow options — captures only the window
  rect, no shadow. Rejected: violates FR-012 (must include shadow).

## Decision: Full-Screen Dim Overlay

**Decision**: Create a single `NSWindow` (via AppKit bridging from SwiftUI) that
covers only the screen where the mouse cursor currently resides. Use
`NSEvent.mouseLocation` and `NSMouseInRect` to detect the active screen. Set
`level = .screenSaver`, `isOpaque = false`, `backgroundColor = .clear`. The
window is borderless (`styleMask = .borderless`).

**Rationale**: SwiftUI cannot create windows at `.screenSaver` level or
borderless full-screen windows. `NSWindow` bridging is necessary and explicitly
allowed by Constitution Principle II. Using a single active screen (instead of
a union spanning all displays) avoids complex multi-screen coordinate math:
different screen arrangements (stacked, side-by-side, offset) cause the union
rect to have a non-zero origin, making Y-axis coordinate conversion between
SwiftUI (top-left) and macOS screen coords (bottom-left) unpredictable.
Single-screen approach keeps the overlay frame at the screen's native origin
and height, so `flipY` uses only that screen's height.

The overlay renders:
1. A semi-transparent black fill (opacity 0.45) over the entire screen rect.
2. A "cutout" rect (the user's drag selection) drawn using SwiftUI `Canvas` with
   `Path` + `FillStyle(eoFill: true)`. The even-odd fill rule creates a hole
   where the selection rect overlaps the full-screen fill — no blend modes
   needed.
3. A thin white border (`0.5pt`) around the selection rect for visual feedback.

**Crosshair cursor**: `NSCursor.crosshair.push()` on show, `.pop()` on dismiss.

**Capture timing**: The overlay window is ordered out (`orderOut`) before the
capture callback fires. The `onComplete` closure is dispatched via
`DispatchQueue.main.async` to allow the window server one frame to remove the
overlay visually. This prevents the dimmed overlay from appearing in the
captured screenshot.

**Alternatives considered**:
- Union of all `NSScreen.screens` frames — rejected: coordinate conversion
  errors with multi-display setups where union origin ≠ (0,0).
- Multiple per-screen `NSWindow` instances — more complex coordinate math.
  Rejected.
- `CGDisplayCapture` — locks the display. Rejected: too invasive.
- SwiftUI `Window` with `.windowStyle(.hiddenTitleBar)` — cannot span screens
  or achieve screenSaver level. Rejected.

## Decision: Menu Bar App

**Decision**: Use SwiftUI `MenuBarExtra` scene (macOS 13+) for the menu bar
entry. Set `LSUIElement = true` in `Info.plist` to hide from Dock.

**Rationale**: `MenuBarExtra` is the simplest way to create a menu bar app in
SwiftUI. It provides a customizable icon, built-in dropdown menu behavior, and
handles click-to-open without manual `NSStatusItem` management.

The annotation editor window opens as a regular `Window` scene (not a
`WindowGroup`) so the Dock icon appears only when the editor is visible
(handled via `NSApp.setActivationPolicy(.regular)` when opening the editor,
reverting to `.accessory` when closing it). This matches the spec's assumption
about Dock behavior.

**Alternatives considered**:
- `NSStatusItem` + `NSMenu` (AppKit) — more control but more boilerplate.
  Rejected: `MenuBarExtra` is sufficient for v1.
- `NSStatusItem` + custom `NSView` — needed for custom dropdowns. Rejected:
  standard menu behavior is enough.

## Decision: Annotation Rendering

**Decision**: Use SwiftUI `Canvas` with `GraphicsContext` for vector annotation
drawing. Each annotation is a model struct; the canvas resolves paths and text
at draw time. Undo/redo uses an array-based history stack.

**Rationale**:
- `Canvas` with `GraphicsContext` provides GPU-accelerated 2D drawing with
  first-class SwiftUI integration. No need for `CALayer` or Core Graphics
  manual drawing.
- Annotations are stored as model data (not rendered pixel layers), enabling:
  - Undo/redo by removing from the array
  - Non-destructive editing (original image unchanged until save)
  - Resolution-independent output (annotations scale with image size)
- Drawing tools:
  - **Arrow**: `Path` with line + arrowhead computed from endpoints
  - **Rectangle**: `Path(roundedRect:)`
  - **Circle**: `Path(ellipseIn:)`
  - **Text**: `context.draw(Text(string).foregroundColor(color), at: point)`

**Alternatives considered**:
- `PencilKit` (PKCanvasView) — designed for freehand drawing on iPad. Works on
  macOS but over-engineering for 4 shape-based tools. Rejected.
- Core Graphics manual rendering into a bitmap context — more control but much
  more code. Rejected: `Canvas` is simpler and sufficient.

## Decision: Floating Thumbnail

**Decision**: After capture, create a small `NSWindow` (borderless,
`.floating` level) positioned at the bottom-right of the screen. Display the
captured `NSImage` scaled down. Auto-dismiss after 5 seconds via
`DispatchQueue.main.asyncAfter`. Clicking opens the annotation editor.

**Rationale**: This mimics the native macOS screenshot thumbnail behavior. The
window is temporary and non-intrusive. Using `.floating` level ensures it's
above normal windows but below the overlay.

For the "screenshot sound": Play the default system screenshot sound effect
using `NSSound(named: "capture")` or equivalent system sound — or use
`AudioServicesPlaySystemSound` with `kSystemSoundID_Screenshot` if available.

**Alternatives considered**:
- SwiftUI `Window` with `.windowStyle(.hiddenTitleBar)` — cannot control
  window level precisely, and SwiftUI window lifecycle adds complexity.
  Rejected.

## Decision: File Management

**Decision**: Use `FileManager` to create `~/Pictures/Cappy/` on first launch.
Write captured `CGImage` as PNG using `CGImageDestination` with
`kUTTypePNG`. Filename format: `Cappy_YYYY-MM-DD_HH-MM-SS.png`.

**Rationale**:
- `CGImageDestination` is the simplest way to encode a `CGImage` to PNG
  Data and write to disk. No third-party library needed.
- Timestamp filenames guarantee uniqueness and chronological sort order.
- `~/Pictures/Cappy/` is the macOS-idiomatic location for user-created
  screenshots (adjacent to the system's `~/Pictures/Screenshots/`).

For the annotated file: On save, render the annotated canvas to a new
`CGImage` (using `ImageRenderer` or `Canvas.render`), encode as PNG, and
overwrite the original file.

**Alternatives considered**:
- `NSBitmapImageRep` — works but more verbose for PNG export. Rejected:
  `CGImageDestination` is more direct.
- HEIC format — smaller files but less universal. Rejected: PNG is the spec
  requirement and universally supported.
