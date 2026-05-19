# Tasks: Screen Capture & Annotation

**Input**: Design documents from `/specs/001-screen-capture/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Not explicitly requested in the feature specification. Test tasks are omitted. Manual walkthroughs verify each story.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

All source code lives under `Cappy/` at repository root (single Xcode project). Paths follow the structure from plan.md:
- `Cappy/Models/`, `Cappy/Services/`, `Cappy/Views/`, `Cappy/Utilities/`, `Cappy/Resources/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and Xcode project scaffolding

- [x] T001 Create Xcode project `Cappy.xcodeproj` with SwiftUI App lifecycle targeting macOS 14 at repository root
- [x] T002 [P] Configure `Info.plist` with `LSUIElement = YES` (menu bar only, no Dock) in Cappy/Info.plist
- [x] T003 [P] Create `Assets.xcassets` with app icon placeholder in Cappy/Resources/Assets.xcassets

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data models, file I/O, and app entry point that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create Capture model (CaptureMode enum, UUID, Date, fileURL, CGImage) in Cappy/Models/Capture.swift
- [x] T005 Create Annotation model (AnnotationType enum, AnnotationColor enum, id, type, origin, size, color, text, zIndex, endPoint) in Cappy/Models/Annotation.swift
- [x] T006 Create FileService with folder creation (`~/Pictures/Cappy/`) and PNG write via CGImageDestination in Cappy/Services/FileService.swift
- [x] T007 Create ImageExtensions (CGImage → PNG Data, NSImage from CGImage helpers, timestamp filename generation) in Cappy/Utilities/ImageExtensions.swift
- [x] T008 Create `CappyApp.swift` entry point with `MenuBarExtra` scene scaffold (icon only, no menu items yet) and `@main` attribute in Cappy/CappyApp.swift

**Checkpoint**: Foundation ready — models, file saving, and app scaffold exist. User story implementation can now begin in parallel.

---

## Phase 3: User Story 1 - Capture a Screen Region (Priority: P1) 🎯 MVP

**Goal**: User presses shortcut → screen dims → drags region → image captured, saved, thumbnail appears

**Independent Test**: Press `Cmd+Shift+5` (or configured shortcut), drag a region, verify PNG saved to `~/Pictures/Cappy/` with correct content. Thumbnail appears bottom-right.

### Implementation for User Story 1

- [x] T009 [US1] Create CaptureService with region capture method using CGWindowListCreateImage + crop to rect in Cappy/Services/CaptureService.swift
- [x] T010 [US1] Create DimOverlay (NSWindow spanning all screens via AppKit bridge, semi-transparent black fill with selection cutout, crosshair cursor via NSCursor) in Cappy/Views/Capture/DimOverlay.swift
- [x] T011 [US1] Create CaptureToolbar (floating toolbar above overlay with Region/Full Screen/Window buttons, Cancel button) in Cappy/Views/Capture/CaptureToolbar.swift
- [x] T012 [US1] Create ThumbnailView (borderless NSWindow at bottom-right, scaled image preview, 5-second auto-dismiss timer, click handler to open editor) in Cappy/Views/Capture/ThumbnailView.swift
- [x] T013 [US1] Register global keyboard shortcut for region capture using NSEvent.addGlobalMonitorForEvents + fallback logic (Cmd+Shift+5 primary) in CappyApp.swift
- [x] T014 [US1] Wire region capture pipeline: keyboard shortcut / toolbar → DimOverlay drag → CaptureService.region() → FileService.save() → ThumbnailView.show() in CappyApp.swift

**Checkpoint**: Region capture fully functional — the MVP is working. User can capture any screen region via shortcut or toolbar.

---

## Phase 4: User Story 2 - Capture the Full Screen (Priority: P1)

**Goal**: User presses shortcut → all displays captured instantly → saved → thumbnail appears

**Independent Test**: Press full-screen shortcut, verify PNG files with full display contents saved. Multi-display produces separate files.

### Implementation for User Story 2

- [x] T015 [US2] Add fullScreen capture method using CGDisplayCreateImage per display in Cappy/Services/CaptureService.swift
- [x] T016 [US2] Handle multi-display: iterate `NSScreen.screens`, capture each, generate display-suffixed filenames (`_Display2.png`) in Cappy/Services/CaptureService.swift
- [x] T017 [US2] Register global keyboard shortcut for full-screen capture (Cmd+Shift+6 fallback) in CappyApp.swift
- [x] T018 [US2] Wire full-screen capture pipeline: shortcut → CaptureService.fullScreen() → FileService.save() per display → ThumbnailView.show() in CappyApp.swift

**Checkpoint**: Full-screen capture works. User Stories 1 AND 2 both independently functional.

---

## Phase 5: User Story 3 - Capture a Specific Window (Priority: P2)

**Goal**: User activates window picker → hovers to highlight windows → clicks one → captures window with shadow

**Independent Test**: Activate window capture mode, click a Finder window, verify PNG contains the window with shadow and rounded corners.

### Implementation for User Story 3

- [x] T019 [US3] Add window enumeration method using CGWindowListCopyWindowInfo (filter visible, non-desktop windows, layer < 1000) in Cappy/Services/CaptureService.swift
- [x] T020 [US3] Add window capture method using CGWindowListCreateImage with kCGWindowImageBoundsIgnoreFraming for shadow inclusion in Cappy/Services/CaptureService.swift
- [x] T021 [US3] Add window picker mode to DimOverlay: highlight window under cursor (draw colored border rect), click to capture, Escape to cancel in Cappy/Views/Capture/DimOverlay.swift
- [x] T022 [US3] Register global keyboard shortcut for window capture (Cmd+Shift+7 fallback) in CappyApp.swift
- [x] T023 [US3] Wire window capture pipeline: shortcut → DimOverlay.windowPickerMode → user click → CaptureService.window(id) → FileService.save() → ThumbnailView.show() in CappyApp.swift

**Checkpoint**: All three capture modes (region, full-screen, window) now functional.

---

## Phase 6: User Story 4 - Annotate a Captured Screenshot (Priority: P2)

**Goal**: Click thumbnail → annotation editor opens → draw arrows/rectangles/circles/text → save annotated PNG

**Independent Test**: Capture any screenshot, click thumbnail, draw an arrow and type text, save. Verify annotated PNG includes all drawn elements.

### Implementation for User Story 4

- [ ] T024 [US4] Create AnnotationService with annotations array, addAnnotation, removeAnnotation, updateAnnotation, undo/redo with capped stacks (20 entries), and commitToImage (render to CGImage) in Cappy/Services/AnnotationService.swift
- [ ] T025 [US4] Create AnnotationCanvas using SwiftUI Canvas + GraphicsContext: render ArrowShape, Rectangle, Ellipse, and Text annotations from AnnotationService state in Cappy/Views/Annotation/AnnotationCanvas.swift
- [ ] T026 [US4] Create AnnotationToolbar with tool selector (arrow, rectangle, circle, text) and color palette picker (red, yellow, blue, green, white, black) in Cappy/Views/Annotation/AnnotationToolbar.swift
- [ ] T027 [US4] Create AnnotationEditor as a resizable SwiftUI Window scene displaying the capture image with overlaid AnnotationCanvas and AnnotationToolbar in Cappy/Views/Annotation/AnnotationEditor.swift
- [ ] T028 [US4] Add Cmd+Z / Cmd+Shift+Z keyboard shortcuts for undo/redo within AnnotationEditor
- [ ] T029 [US4] Implement save flow: AnnotationService.commitToImage() → FileService.overwrite(capture.fileURL) on Cmd+S or editor close in Cappy/Views/Annotation/AnnotationEditor.swift
- [ ] T030 [US4] Wire ThumbnailView click → open AnnotationEditor window with the captured image; handle Dock icon show/hide via NSApp.setActivationPolicy in CappyApp.swift

**Checkpoint**: Annotation editor works. User can draw arrows, rectangles, circles, text; undo/redo; save annotated images.

---

## Phase 7: User Story 5 - Quick Capture from Menu Bar (Priority: P3)

**Goal**: Click menu bar icon → dropdown shows capture modes → select mode → capture executes

**Independent Test**: Click menu bar icon, select "Capture Region", verify region capture flow starts identically to keyboard shortcut.

### Implementation for User Story 5

- [ ] T031 [US5] Build menu bar dropdown in Cappy/Views/MenuBar/MenuBarView.swift: Capture Region, Capture Full Screen, Capture Window items with keyboard shortcut labels
- [ ] T032 [US5] Wire menu bar actions to capture modes (call same handlers as keyboard shortcuts) in CappyApp.swift
- [ ] T033 [US5] Add "Open Screenshots Folder" menu item that opens `~/Pictures/Cappy/` in Finder via NSWorkspace.shared.open
- [ ] T034 [US5] Add "Keyboard Shortcuts" info item (shows alert with current shortcut assignments) and "About Cappy" item (standard about window) in Cappy/Views/MenuBar/MenuBarView.swift

**Checkpoint**: Menu bar integration complete. All capture modes accessible via mouse with 2-3 clicks.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Edge cases, error handling, and final integration

- [ ] T035 [P] Add Escape key handler to cancel active capture (dismiss overlay, no file saved) in Cappy/Views/Capture/DimOverlay.swift
- [ ] T036 [P] Add disk space check before save; show notification if save fails due to insufficient space in Cappy/Services/FileService.swift
- [ ] T037 [P] Handle Accessibility permission: check on launch via AXIsProcessTrusted, prompt with alert + System Preferences button if needed in CappyApp.swift
- [ ] T038 [P] Handle quit-with-unsaved-editor: prompt save/discard/cancel dialog when Cmd+Q while annotation editor has unsaved changes in CappyApp.swift
- [ ] T039 Run quickstart.md validation: build, run, capture region, annotate, verify save location

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **US1 - Region (Phase 3)**: Depends on Foundational (Phase 2)
- **US2 - Full Screen (Phase 4)**: Depends on US1 for CaptureService/ThumbnailView/FileService integration patterns; can start in parallel with US1 if models/services are ready
- **US3 - Window (Phase 5)**: Depends on US1 (reuses DimOverlay, CaptureService base)
- **US4 - Annotation (Phase 6)**: Depends on US1 (needs ThumbnailView click handler + FileService)
- **US5 - Menu Bar (Phase 7)**: Depends on US1, US2, US3 (calls capture mode handlers)
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) — No dependencies on other stories. Foundation for others.
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) — Independent of US1. Reuses CaptureService and FileService.
- **User Story 3 (P2)**: Can start after US1 (Phase 3) — Needs DimOverlay and CaptureService pattern.
- **User Story 4 (P2)**: Can start after US1 (Phase 3) — Needs ThumbnailView and FileService.
- **User Story 5 (P3)**: Can start after US1+US2+US3 — Wires menu items to capture handlers.

### Within Each User Story

- Models → Services → Views → Shortcuts → Pipeline wiring
- Core implementation before integration

### Parallel Opportunities

- T002, T003 can run in parallel (different files)
- T004, T005 can run in parallel (different model files)
- T006, T007 can run in parallel (different files)
- T009, T010, T011, T012 can run in parallel (different files, defined interface via Capture model)
- T035, T036, T037, T038 can all run in parallel (different files, independent concerns)
- US1 and US2 can begin in parallel once Foundational completes (both P1)

---

## Parallel Example: User Story 1

```bash
# Launch views and service in parallel (different files):
Task: "Create CaptureService with region capture in Cappy/Services/CaptureService.swift"
Task: "Create DimOverlay in Cappy/Views/Capture/DimOverlay.swift"
Task: "Create CaptureToolbar in Cappy/Views/Capture/CaptureToolbar.swift"
Task: "Create ThumbnailView in Cappy/Views/Capture/ThumbnailView.swift"

# Then wire together (depends on all above):
Task: "Register global keyboard shortcut for region capture in CappyApp.swift"
Task: "Wire region capture pipeline in CappyApp.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1 (Region Capture)
4. **STOP and VALIDATE**: Press shortcut, drag region, verify PNG saved at `~/Pictures/Cappy/`
5. Demo ready — region capture with thumbnail

### Incremental Delivery

1. Setup + Foundational → Core ready
2. Add US1 (Region) → Test → MVP!
3. Add US2 (Full Screen) → Test → All capture except window
4. Add US3 (Window) → Test → All capture modes complete
5. Add US4 (Annotation) → Test → Full editing workflow
6. Add US5 (Menu Bar) → Test → Mouse-friendly access
7. Polish → Final release

### Single Developer Strategy

1. Phases 1-2: Setup + Foundational (all files, sequential)
2. Phase 3: US1 (Region) — complete MVP
3. Phase 4: US2 (Full Screen) — quick win, adds second mode
4. Phase 5: US3 (Window) — completes capture modes
5. Phase 6: US4 (Annotation) — the largest phase
6. Phase 7: US5 (Menu Bar) — quick integration phase
7. Phase 8: Polish — edge cases and hardening

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- No test tasks generated — tests were not explicitly requested in the feature specification
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
