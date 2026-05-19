# Feature Specification: Screen Capture & Annotation

**Feature Branch**: `001-screen-capture`

**Created**: 2026-05-18

**Status**: Draft

**Input**: User description: "a ideia desse programa é ser uma ferramenta de captura de tela para o Mac. Eu quero algo que seja absolutamente intuitivo, com o mínimo de interface necessária, obviamente usando comandos do teclado, de preferência que sobrescrevam o Command+Shift+4 e o Command+Shift+3, se possível. Eu quero que seja um programa simples que eu consiga fazer anotações depois que a imagem já é capturada e que as imagens sejam salvas automaticamente. Que seja muito integrado, muito simples e fácil de usar, que pareça algo nativo e bem natural, e que seja fácil de manter. Vai ser um projeto que vai acabar sendo compartilhado no GitHub para outras pessoas poderem baixar ou usar, se elas quiserem mexer, mas eu quero que seja algo bem simples. Basicamente, é uma ferramenta de captura de tela pro Mac, com funções de: captura de uma região, captura da tela inteira, captura de uma janela. De preferência, algo bem simples, com uma interface bem natural, sem janelas. Eu quero que, quando acontecer isso, escureça um pouquinho a tela e que a área que eu vou capturar seja mais clara, como se não tivesse esse bloqueio no meio. Só botões que apareçam na tela, numa barrinha, de preferência, mas não quero janelas aparecendo. A única janela que vai aparecer é a da própria imagem. Depois, se eu quiser editar, deve aparecer em algum canto da tela a imagem que capturei, eu clicando nela. Abro ela numa janela e aí eu posso editar com setas, círculos, quadrados, texto, o que seja."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Capture a Screen Region (Priority: P1)

The user presses a keyboard shortcut to start a region capture. The screen dims
slightly, and a crosshair cursor appears. The user drags to select a
rectangular region — the selected area remains clear and undimmed. On release,
the screenshot is captured, auto-saved, and a floating thumbnail appears in the
bottom-right corner of the screen for 5 seconds.

**Why this priority**: Region capture is the most frequent and versatile
screenshot use case. It alone delivers immediate value as an MVP.

**Independent Test**: Press the capture-region shortcut, drag a selection, and
verify a PNG file appears in the save location with only the selected area.

**Acceptance Scenarios**:

1. **Given** the user is on any macOS screen, **When** they press the
   `Cmd+Shift+4` shortcut (or a configurable alternative), **Then** the screen
   dims and a crosshair appears for region selection.
2. **Given** the crosshair is active, **When** the user drags a rectangular
   area and releases, **Then** the selected region is captured, auto-saved as
   PNG, and a thumbnail appears in the bottom-right corner.
3. **Given** the crosshair is active, **When** the user presses Escape,
   **Then** the capture is cancelled, the dim overlay disappears, and no file
   is saved.

---

### User Story 2 - Capture the Full Screen (Priority: P1)

The user presses a keyboard shortcut to capture all visible screens
simultaneously. The screenshot is taken instantly without any selection UI.

**Why this priority**: Full-screen capture is the second most common screenshot
action and is essential for sharing complete screen context.

**Independent Test**: Press the `Cmd+Shift+3` shortcut and verify a PNG file
containing all screen contents appears in the save location.

**Acceptance Scenarios**:

1. **Given** the user is on any macOS screen, **When** they press
   `Cmd+Shift+3`, **Then** all connected displays are captured into a single
   image, auto-saved as PNG, and a thumbnail notification appears.
2. **Given** multiple displays are connected, **When** the user triggers
   full-screen capture, **Then** each display is captured as a separate PNG
   file.

---

### User Story 3 - Capture a Specific Window (Priority: P2)

The user triggers window capture mode. After pressing the shortcut, the user
clicks on any visible window to capture only that window — including its shadow
and rounded corners, matching macOS native behavior.

**Why this priority**: Window capture is a specialized but valuable mode for
documentation, bug reports, and sharing specific app contexts without revealing
the rest of the desktop.

**Independent Test**: Press the window-capture shortcut, click a Finder window,
and verify the resulting PNG contains only that window with shadow.

**Acceptance Scenarios**:

1. **Given** the user presses the window-capture shortcut (e.g.,
   `Cmd+Shift+4` then Space), **When** they click on a visible window, **Then**
   only that window — including shadow — is captured and auto-saved.
2. **Given** window capture mode is active and the user moves the cursor over
   different windows, **When** the cursor hovers, **Then** the window under the
   cursor is highlighted to indicate which window will be captured.

---

### User Story 4 - Annotate a Captured Screenshot (Priority: P2)

After a screenshot is captured, the user clicks the floating thumbnail to open
the annotation editor. The editor displays the image in a resizable window
where the user can draw arrows, circles, rectangles, and add text overlays
before saving the annotated version.

**Why this priority**: Annotations transform a raw screenshot into a
communication tool. Without them, the user must open another app to mark up
images, breaking the workflow the tool aims to simplify.

**Independent Test**: Capture a screenshot, click the thumbnail, draw an arrow
and a rectangle, type a text annotation, and save. Verify the saved PNG
includes all drawn elements on top of the original capture.

**Acceptance Scenarios**:

1. **Given** a screenshot was just captured and the thumbnail is visible,
   **When** the user clicks the thumbnail, **Then** the annotation editor opens
   with the screenshot displayed.
2. **Given** the annotation editor is open, **When** the user selects the arrow
   tool and drags across the image, **Then** an arrow is drawn from the drag
   start point to the end point.
3. **Given** the annotation editor is open, **When** the user selects the
   rectangle tool and drags, **Then** a rectangle is drawn on the image.
4. **Given** the annotation editor is open, **When** the user selects the text
   tool and clicks on the image, **Then** a text input appears at that location
   and the typed text is rendered on the image.
5. **Given** annotations have been added, **When** the user saves (Cmd+S) or
   closes the editor, **Then** the annotated image replaces the original
   auto-saved file.
6. **Given** the user wants to discard annotations, **When** they close the
   editor without saving, **Then** the original unannotated screenshot is
   preserved.

---

### User Story 5 - Quick Capture from Menu Bar (Priority: P3)

The user clicks the Cappy icon in the macOS menu bar to access capture modes
without remembering keyboard shortcuts. A dropdown offers: Capture Region,
Capture Full Screen, Capture Window.

**Why this priority**: Menu bar access provides discoverability for new users
and an alternative for those who prefer mouse-driven workflows, but keyboard
shortcuts cover the primary use case.

**Independent Test**: Click the menu bar icon, select "Capture Region", and
verify the region capture flow starts identically to the keyboard shortcut.

**Acceptance Scenarios**:

1. **Given** Cappy is running, **When** the user clicks the menu bar icon,
   **Then** a dropdown menu shows the three capture options.
2. **Given** the menu bar dropdown is open, **When** the user selects "Capture
   Full Screen", **Then** the full-screen capture executes immediately.

---

### Edge Cases

- What happens when the user triggers region capture but drags a 1-pixel-wide selection? The selection is treated as valid and captured at actual size.
- What happens when no windows are visible during window capture mode? The mode remains active; the user can press Escape to cancel.
- What happens when the save location runs out of disk space? The user sees a notification that the screenshot could not be saved, and the original capture data is held in memory until space is freed or the user dismisses it.
- What happens when the user triggers multiple captures in rapid succession? Each capture saves as a separate file with incrementing filenames; thumbnails stack in the corner.
- What happens when the thumbnail expires (5 seconds)? It fades out; the screenshot is still accessible via Finder at the save location.
- What happens when the annotation window is already open and a new screenshot is captured? The new capture saves normally; a new thumbnail appears. The existing editor window is unaffected.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide three capture modes: region selection, full screen, and single window.
- **FR-002**: The system MUST register global keyboard shortcuts for each capture mode. The default shortcuts MUST attempt to use `Cmd+Shift+4` (region), `Cmd+Shift+3` (full screen), and `Cmd+Shift+4` then Space (window). If the system prevents overriding these shortcuts, the system MUST provide configurable alternatives and inform the user.
- **FR-003**: During region capture, the system MUST dim all screens and display a crosshair cursor. The area inside the user's drag selection MUST remain at full brightness.
- **FR-004**: All captures MUST be automatically saved as PNG files to a designated folder immediately upon capture, with no save dialog.
- **FR-005**: After each capture, the system MUST display a floating thumbnail in the bottom-right corner of the screen that persists for 5 seconds before fading out.
- **FR-006**: The system MUST provide a menu bar icon that gives mouse-driven access to all three capture modes.
- **FR-007**: The capture interface (crosshair, dim overlay, floating toolbar if any) MUST operate without opening a traditional window. Only the annotation editor may open a window.
- **FR-008**: The annotation editor MUST open when the user clicks the post-capture thumbnail. It MUST display the captured image in a resizable window.
- **FR-009**: The annotation editor MUST provide drawing tools: arrow, rectangle, circle (ellipse), and text.
- **FR-010**: Annotations MUST be editable: the user can undo and redo individual annotation actions (draw, move, resize, delete, change color) during the editing session.
- **FR-011**: Saving from the annotation editor MUST overwrite the original auto-saved PNG with the annotated version. Closing without saving MUST preserve the original.
- **FR-012**: Window capture MUST include the window's shadow and rounded corners, matching the visual appearance the user sees on screen.
- **FR-013**: Multi-display setups MUST be handled correctly: full-screen capture produces one file per display, region capture works across display boundaries, and window capture works on any display.

### Key Entities

- **Capture**: Represents a single screenshot. Attributes: capture mode (region/full-screen/window), source rectangle or window reference, timestamp, resulting file path.
- **Annotation**: A vector drawing element placed on top of a capture. Types: arrow, rectangle, circle, text. Attributes: type, position, size, color, text content (for text type), z-order.
- **Annotation Session**: An editing session tied to one capture. Holds the list of annotations and the undo/redo stack.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user unfamiliar with Cappy can capture their first screenshot within 10 seconds of launching the app, using either the keyboard shortcut or menu bar.
- **SC-002**: Time from capture shortcut press to saved PNG file on disk is under 500 milliseconds for full-screen and window captures, and under 1 second for region captures (excluding user drag time).
- **SC-003**: 90% of users can add at least one annotation (arrow, rectangle, circle, or text) to a screenshot without consulting help or documentation.
- **SC-004**: Each capture mode (region, full screen, window) is accessible in 2 clicks or fewer from the menu bar, or a single keyboard shortcut.
- **SC-005**: The annotation editor supports undo/redo of at least the last 20 annotation actions within a single editing session.
- **SC-006**: The application uses no more than 200 MB of memory during normal operation (one annotation editor open, idle).

## Assumptions

- The default save location is a `Cappy` folder inside the user's Pictures directory (`~/Pictures/Cappy/`). Users can change this in preferences but no preferences UI exists in v1 — the folder is simply created on first launch.
- Capture files are named using the pattern `Cappy_YYYY-MM-DD_HH-MM-SS.png` to ensure uniqueness and chronological sorting.
- The annotation color palette is limited to red, yellow, blue, green, white, and black. Red is the default.
- macOS may not allow third-party apps to override `Cmd+Shift+3` and `Cmd+Shift+4` system shortcuts. In that case, Cappy registers `Cmd+Shift+5` (region), `Cmd+Shift+6` (full screen), and `Cmd+Shift+7` (window) as fallbacks, and notifies the user on first launch.
- Multi-display full-screen capture produces separate files per display, named with a display suffix (e.g., `Cappy_2026-05-18_14-30-00_Display2.png`).
- The app runs as a menu bar app (no Dock icon) to stay unobtrusive, but may show a Dock icon when the annotation editor window is open.
