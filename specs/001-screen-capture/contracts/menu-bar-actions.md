# UI Contract: Menu Bar Actions

**Feature**: 001-screen-capture
**Contract Type**: User Interaction Surface

## Menu Bar Entry

Cappy presents an icon in the macOS menu bar. Clicking the icon opens a
dropdown menu.

### Menu Structure

```
┌─────────────────────────────┐
│ 📷 Cappy                    │  ← App name (non-clickable header)
├─────────────────────────────┤
│ ✂️  Capture Region    ⇧⌘5  │  ← Triggers region capture
│ 🖥️  Capture Full Screen ⇧⌘6│  ← Triggers full-screen capture
│ 🪟  Capture Window    ⇧⌘7  │  ← Triggers window capture
├─────────────────────────────┤
│ 📁 Open Screenshots Folder  │  ← Opens ~/Pictures/Cappy/ in Finder
├─────────────────────────────┤
│ ⓘ  Keyboard Shortcuts       │  ← Shows current shortcut assignments
│ ℹ️  About Cappy              │  ← Shows version info
│ 🚪 Quit Cappy          ⌘Q   │  ← Quits the application
└─────────────────────────────┘
```

### Action Specifications

#### Capture Region
- **Interaction**: Click menu item
- **Clicks from menu bar**: 2 (open menu → click item)
- **Result**: Dim overlay appears with crosshair cursor. User drags to select
  region.
- **Precondition**: App has screen recording or accessibility permission.
- **Error handling**: If permission missing, show system permission prompt.

#### Capture Full Screen
- **Interaction**: Click menu item
- **Clicks from menu bar**: 2
- **Result**: All displays captured immediately. Thumbnail appears.
- **Precondition**: Same as Region.
- **Error handling**: Same as Region.

#### Capture Window
- **Interaction**: Click menu item
- **Clicks from menu bar**: 2 → then click target window (3 total)
- **Result**: Cursor changes to window picker mode. Clicking a window captures it.
- **Precondition**: Same as Region. At least one visible window.
- **Error handling**: If no windows visible, show subtle tooltip: "No windows
  found."

#### Open Screenshots Folder
- **Interaction**: Click menu item
- **Result**: `Finder` opens at `~/Pictures/Cappy/`. Folder is created if it
  does not exist.
- **Precondition**: None.

#### Keyboard Shortcuts
- **Interaction**: Click menu item
- **Result**: Shows a small popover or alert listing current shortcut
  assignments.
- **Precondition**: None.

#### About Cappy
- **Interaction**: Click menu item
- **Result**: Standard macOS About window with app version and credits.
- **Precondition**: None.

#### Quit
- **Interaction**: Click menu item or press `Cmd+Q`
- **Result**: App terminates. Any open annotation editor prompts to save
  unsaved changes before quitting.
- **Precondition**: None.
