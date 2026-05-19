# UI Contract: Keyboard Shortcuts

**Feature**: 001-screen-capture
**Contract Type**: User Input Binding

## Shortcut Registry

Cappy registers three global keyboard shortcuts. The primary shortcuts are used
if the system permits; fallback shortcuts are used otherwise.

| Action | Primary Shortcut | Fallback Shortcut | Behavior |
|--------|-----------------|-------------------|----------|
| Capture Region | `Cmd+Shift+4` | `Cmd+Shift+5` | Opens dim overlay + crosshair cursor |
| Capture Full Screen | `Cmd+Shift+3` | `Cmd+Shift+6` | Immediately captures all displays |
| Capture Window | `Cmd+Shift+4` then `Space` | `Cmd+Shift+7` | Enters window selection mode |

## Registration Rules

1. On launch, attempt to register all three primary shortcuts via
   `NSEvent.addGlobalMonitorForEvents`.
2. If a primary shortcut registration fails (system conflict) or the shortcut
   fires but the system handler takes precedence, fall back to the fallback
   shortcut.
3. On first launch with fallback active, show a macOS alert informing the user
   which shortcuts are available and that they differ from system defaults.
4. The user can view current shortcut assignments via the menu bar dropdown
   (Menu → "Keyboard Shortcuts" info item).
5. Shortcuts are not user-configurable in v1.

## Accessibility Permission

To use global key event monitoring, Cappy requires Accessibility permission
(System Preferences → Privacy & Security → Accessibility).

1. On first launch, if Accessibility permission is not granted, Cappy shows an
   alert: "Cappy needs Accessibility access to detect global keyboard
   shortcuts. Please enable it in System Preferences." with a button opening
   System Preferences.
2. Without Accessibility permission:
   - Global keyboard shortcuts do not work.
   - Menu bar capture modes still function.
   - The alert does not reappear after dismissal (user can re-enable later via
     System Preferences).

## Shortcut Conflict Resolution

- **Escape**: In region or window capture mode, Escape cancels the capture. The
  overlay dismisses, and no file is saved. This shortcut does not require
  global registration — it is handled locally while the overlay is active.
- **Cmd+S**: In the annotation editor, saves annotated image and closes the
  editor.
- **Cmd+Z / Cmd+Shift+Z**: In the annotation editor, undo / redo last
  annotation action.
