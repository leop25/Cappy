<!--
  Sync Impact Report
  ==================
  Version change: [unversioned template] → 1.0.0 (initial ratified constitution)
  Type: MAJOR — all placeholders filled, first concrete version
  Modified principles: 4 new principles defined (replacing 5 placeholder slots)
  Added sections:
    - Platform & Technology Standards
    - Development Workflow
  Removed sections: None
  Templates requiring updates:
    - .specify/templates/plan-template.md ✅ no changes needed (dynamic gates)
    - .specify/templates/spec-template.md ✅ no changes needed
    - .specify/templates/tasks-template.md ✅ no changes needed
    - .specify/templates/checklist-template.md ✅ no changes needed
  Follow-up TODOs: None
-->

# Cappy Constitution

## Core Principles

### I. Simple UX

Every primary user action MUST be completable in three clicks or fewer from the
point the user initiates it. Navigation depth and feature discoverability MUST
not sacrifice this constraint. If an action appears to require more than three
clicks, the interaction design MUST be revised until it satisfies this rule.

**Rationale**: Cappy is a productivity tool on macOS. Users expect macOS-grade
smoothness — short paths to completion reduce cognitive load and make the app
feel fast and trustworthy.

### II. Mac-First with SwiftUI

Cappy is a macOS-native application. All UI MUST be built with SwiftUI and
target the latest two major macOS releases. Platform-specific APIs (AppKit
bridging, menu bar integration, keyboard shortcuts, Services menu) are
permitted when SwiftUI alone is insufficient, but SwiftUI MUST be the default
choice. Cross-platform abstractions (Catalyst, multiplatform Swift packages)
MUST NOT add overhead to the Mac experience.

**Rationale**: Focusing on a single platform eliminates the complexity and
compromises of cross-platform UI frameworks. SwiftUI provides modern,
declarative UI with first-class Mac support.

### III. Performance

No user-triggered action (button tap, search, navigation, data save) MAY block
the UI for more than two seconds. Operations that could exceed this limit MUST
be moved off the main actor (async/await, structured concurrency). A loading
indicator MUST appear within 200 ms for any async operation. Background work
(launch, indexing, sync) MUST NOT degrade interactive responsiveness.

**Rationale**: Perceived performance is user experience. A two-second ceiling
keeps the app feeling instant while giving developers a clear, measurable
target.

### IV. Simplicity Over Engineering

Prefer the simplest solution that meets the requirement. Do not introduce
abstractions, design patterns, or dependencies unless a concrete, current need
justifies them. YAGNI (You Aren't Gonna Need It) is a design constraint:
speculative generality, premature optimization, and over-configuration are
prohibited. Code MUST be correct first, then fast, then elegant — in that
order.

**Rationale**: Over-engineering increases maintenance cost, onboarding time,
and bug surface. Simple code is easier to change, test, and delete.

## Platform & Technology Standards

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (AppKit bridging permitted when necessary)
- **Target**: macOS 14 (Sonoma) minimum
- **Concurrency**: Swift structured concurrency (async/await, actors)
- **Persistence**: SwiftData or direct Codable-file storage; avoid heavyweight
  database solutions unless data volume demonstrably requires them
- **Testing**: XCTest (unit), XCUITest or manual walkthroughs (UI)
- **Dependencies**: zero or minimal third-party packages. Every dependency MUST
  be justified in the plan document with a "why native/Swift-only is
  insufficient" note.

## Development Workflow

- Feature work begins with a specification (`/speckit.specify`) and an
  implementation plan (`/speckit.plan`).
- Constitution compliance MUST be verified at the start of every plan (see
  "Constitution Check" gate in `plan-template.md`).
- All implementation tasks are generated via `/speckit.tasks` and tracked as
  independent, testable user stories.
- Code review MUST confirm adherence to all four Core Principles before merge.

## Governance

This constitution supersedes all other development practices. Amendments
require a documented proposal, review against the four Core Principles, and
approval by the project maintainer. Any amendment that weakens a principle MUST
include a migration plan for affected code.

Versioning follows semantic versioning:
- **MAJOR**: Principle removal or redefinition that breaks backward compatibility.
- **MINOR**: New principle or section added, or materially expanded guidance.
- **PATCH**: Clarifications, wording fixes, non-semantic refinements.

All feature specifications (spec.md), implementation plans (plan.md), and pull
requests MUST include a constitution compliance check. Complexity that violates
a principle MUST be explicitly justified in the plan's Complexity Tracking
table.

**Version**: 1.0.0 | **Ratified**: 2026-05-18 | **Last Amended**: 2026-05-18
