# Opus Studio

Opus Studio is an experimental Procreate-style painting environment built with SwiftUI and Metal for macOS. This repository is intentionally organized as a Swift Package so the project can be built from the command line with `swift build` or opened directly in Xcode using the "Open Package" workflow.

## Current capabilities

- SwiftUI chrome with a minimalist, Apple-native aesthetic.
- Metal-backed canvas that supports panning, zooming, and pressure-sensitive brush strokes.
- Tool column for brush, eraser, color picker (placeholder), and hand tools.
- Inspector with collapsible sections for the layer stack, brush settings, and an interim Coolorus-inspired color wheel placeholder.
- Undo/redo hooks exposed via both the inspector and standard macOS keyboard shortcuts.

## Project layout

```
Sources/OpusApp/
├── App/                // SwiftUI scene entry points and window shell
├── Canvas/             // Rendering pipeline, interaction handling, and drawing models
├── Shaders/            // Metal shader functions
└── UI/                 // SwiftUI components for tools and inspectors
```

## Building and running

This package targets macOS 13 and later.

1. Open the project in Xcode 15 or newer (`File` → `Open Package…` → select the repository folder).
2. Choose the `OpusApp` scheme and build/run on a macOS destination.

From the command line, you can also run `swift build` on macOS. (Linux builds are not supported because the project depends on AppKit, SwiftUI, and Metal.)

## Roadmap

- Replace the color wheel placeholder with a fully interactive HSV radial selector inspired by Coolorus.
- Introduce a full layer stack with blend modes, reordering, and masking tools.
- Expand the brush engine with textures, spacing, smudge, and customizable pressure curves.
- Persist documents and integrate with Files/Drag & Drop workflows.
