# Pluma

A native macOS design studio — a lightweight, offline alternative to Canva, written in Swift and SwiftUI.

Pluma covers slides, A4 documents, resumes, social posts and infinite whiteboards in one editor. It imports PowerPoint and Canva exports, exports PNG / JPEG / PDF / SVG / PPTX, and includes a local AI bridge so Claude, Cursor or any MCP client can design on the live canvas.

- **Native**: SwiftUI + AppKit + CoreGraphics, no web view or Electron.
- **Offline & private**: projects live on your Mac; nothing is uploaded.
- **No dependencies**: a single Swift package, macOS 14+.

---

## Contents

- [Getting started](#getting-started)
- [The editor](#the-editor)
- [Features](#features)
- [Keyboard shortcuts](#keyboard-shortcuts)
- [AI bridge & MCP server](#ai-bridge--mcp-server)
- [Command-line tool](#command-line-tool)
- [Development](#development)
- [Project layout](#project-layout)

---

## Getting started

Requirements: macOS 14 (Sonoma) or later and a Swift 5.10+ toolchain (Xcode 15.3+ or the Command Line Tools).

```bash
git clone https://github.com/CHAYUT-P/Pluma.git
cd Pluma

# Run a debug build straight from the package
swift run

# Or build a release .app and install it into /Applications
./scripts/build_app.sh
open /Applications/Pluma.app
```

`build_app.sh` builds in release mode, bundles the app icon and the MCP server, ad-hoc signs the bundle, quits any running Pluma and replaces `/Applications/Pluma.app`. Pass `--keep-local` to also keep a copy of `Pluma.app` in the project folder.

---

## The editor

```
┌──────────────────────────────────────────────────────────────────────────┐
│ Home · title · page size · undo/redo │ tools · layout │ import · ▶ · Export│  toolbar
├──────────────────────────────────────────────────────────────────────────┤
│ contextual bar — font, size, color, alignment, opacity, arrange …         │
├──────┬───────────┬──────────────────────────────────────┬────────────────┤
│ rail │  drawer   │               canvas                 │   inspector    │
│      │           │                                      │                │
│      │           │   ┌ filmstrip ───────── zoom ┐       │                │
└──────┴───────────┴──────────────────────────────────────┴────────────────┘
```

- **Toolbar**: select (V), hand (H), text (T), shape (R), code block (C) and pen (P). The ink dot beside the pen opens its width and color settings. The layout menu switches between **Slide**, **Document** and **Whiteboard**.
- **Left rail**: Templates · Shapes · Text · Media · Icons · Brand · Background · Pages · Layers · Code. Toggle it with ⌘1.
- **Inspector**: page settings when nothing is selected; otherwise Fill, Border, Typography, Image, Code, Position and Opacity & Shadow for the selection. Each section collapses and remembers its state. Toggle it with ⌘2.
- **Bottom rail**: page filmstrip and zoom controls (Slide and Document modes).

### Layout modes

| Mode | Use it for | Behaviour |
| :--- | :--- | :--- |
| **Slide** | Decks, social posts | One page at a time, centered above the filmstrip |
| **Document** | A4 documents, resumes, reports | All pages in a vertical scroll |
| **Whiteboard** | Mind maps, flowcharts, sticky boards | Boundless dot-grid board with a quick-add palette |

---

## Features

### Canvas
- Zoom with ⌘-scroll or pinch (focal, under the cursor), pan with two-finger scroll, Space-drag or the hand tool.
- Smart guides that snap to page edges, centers and neighbouring elements; rulers with draggable guides (⌘R); optional grid.
- Rotation-aware 8-handle transform; corner drags scale text with the box.
- Marquee and Shift-click multi-select, groups (⌘G / ⇧⌘G), locking (⌘L — locked elements are click-through), alignment and distribution, flip, z-order, arrow-key nudging.
- Anchored connectors (`L`) that follow the elements they join.
- Undo/redo for every edit; a slider or color drag is a single undo step.

### Elements
- **Shapes**: rectangles, ellipses, stars, polygons, arrows, speech bubbles, badges, lines and stationery shapes (washi tape, postage stamp, wax seal, torn paper…), with solid, gradient, glass and pattern fills, borders and corner radius.
- **Text**: macOS system fonts, weight, tracking, line height, alignment, outline / neon / shadow / pill effects, curved text. Boxes auto-fit their height.
- **Images**: CoreImage adjustments (brightness, contrast, saturation, blur, sepia, grayscale…), shaped photo frames, and on-device background removal with Vision.
- **Icons**: searchable SF Symbols library with tinting.
- **Code blocks**: syntax-highlighted snippets (Swift, Python, TypeScript, Rust, JSON…) with editor themes.
- **Developer kit** (Code tab): terminal and browser windows, database and server symbols, API chips, status badges, keycaps, and diagram stamps (request flow, CI/CD pipeline, kanban, git branches).
- **Pen**: freehand strokes with smoothing; width and ink set from the toolbar.
- **QR codes**: vector QR generator with custom colors.

### Templates
40+ built-in templates across whiteboards (mind map, architecture flowchart, sticky board, kanban, SWOT, user journey), resumes and CVs, presentation decks, A4 documents (newspaper, broadsheet, lookbook, investment memo, invoice, annual report…) and social posts.

### Import
- **PowerPoint (.pptx)**: geometry, theme colors and gradients, layout/master placeholder inheritance, tables, groups, connectors, shadows, autofit text, native charts (bar, column, line, area, pie) and embedded EMF/WMF pictures.
- **Canva exports**: multi-page PDF, SVG and PPTX.
- **Images and ZIPs**: a ZIP of images becomes one page per image.
- **Pluma projects**: `.canv` / `.pluma` files.

### Export
- **PNG** at 1×–4× with optional transparency, **JPEG** with adjustable quality, vector **PDF**, **SVG** and **PPTX**.
- Export every page as numbered PNGs in one step.
- Copy the page as PNG (⇧⌘C) or as SVG for Figma (⌥⌘C).
- Full-screen presentation mode (⌥⌘P).

### Projects
Projects autosave to `~/Library/Application Support/CanvaNative/Projects/` as `.canv` JSON files. The Home dashboard lists recent projects, templates and size presets.

---

## Keyboard shortcuts

| Shortcut | Action |
| :--- | :--- |
| `V` / `H` | Select tool / Hand tool |
| `T` · `R` · `O` · `C` | Add text · rectangle · ellipse · code block |
| `P` | Toggle the pen |
| `L` | Connect selected elements |
| `F` | Zoom to selection (or fit the page) |
| `Space` + drag | Pan the canvas |
| `↑ ↓ ← →` | Nudge 1 px (`Shift` for 10 px) |
| `⌫` / `Esc` | Delete selection / Deselect or stop editing |
| `⌘Z` / `⇧⌘Z` | Undo / Redo |
| `⌘C` · `⌘V` · `⌘D` · `⌘A` | Copy · Paste · Duplicate · Select all |
| `⌘G` / `⇧⌘G` | Group / Ungroup |
| `⌘L` | Lock / unlock |
| `⌘]` / `⌥⌘]` | Bring forward / Bring to front |
| `⌘[` / `⌥⌘[` | Send backward / Send to back |
| `⌘=` · `⌘-` · `⌘0` | Zoom in · Zoom out · 100% |
| `⌘1` / `⌘2` | Toggle left panel / inspector |
| `⌘R` | Toggle rulers & guides |
| `⌘K` | Command palette |
| `⌘E` | Export |
| `⇧⌘C` / `⌥⌘C` | Copy page as PNG / as SVG for Figma |
| `⌥⌘P` | Present full screen |
| `⌘N` / `⇧⌘H` | New canvas / Back to Home |

---

## AI bridge & MCP server

While Pluma runs, it serves a small HTTP API on `127.0.0.1:9470` (localhost only). `scripts/pluma_mcp_server.py` is a dependency-free MCP server that wraps it, so an AI assistant can read the page, take screenshots and edit the open design live.

**Connect Claude Desktop, Cursor or another MCP client.** Click the ✨ button in the toolbar to copy the config, or add it by hand:

```json
{
  "mcpServers": {
    "pluma": {
      "command": "python3",
      "args": ["/Applications/Pluma.app/Contents/Resources/pluma_mcp_server.py"]
    }
  }
}
```

**Tools (19):** `status`, `get_page`, `screenshot`, `add_element`, `update_element`, `delete_element`, `duplicate_element`, `reorder_element`, `add_code_block`, `clear_page`, `connect_elements`, `add_page`, `select_page`, `undo`, `redo`, `save`, `list_templates`, `apply_template`, `design_guide` (all prefixed `pluma_`).

You can also call the HTTP API directly — `GET /help` lists every route:

```bash
curl -s localhost:9470/health
curl -s -X POST localhost:9470/template -d '{"id":"annual_report"}'
```

| Variable | Effect |
| :--- | :--- |
| `PLUMA_BRIDGE=0` | Disable the bridge |
| `PLUMA_PORT=<port>` | Use another port (set it for the MCP server too) |

---

## Command-line tool

`scripts/pluma_cli.py` works on project files directly, without the app running:

```bash
python3 scripts/pluma_cli.py list
python3 scripts/pluma_cli.py create --help
python3 scripts/pluma_cli.py add-text --help
python3 scripts/pluma_cli.py open
```

Commands: `list`, `create`, `get`, `add-text`, `add-shape`, `open`.

---

## Development

```bash
swift build      # debug build
swift test       # unit tests (Tests/PlumaTests)
```

The tests cover the object model (z-order, clipboard, alignment, groups, locking, undo, pages, snapping), the PPTX importer, and the render path (paint-order cache and single-publish edits).

Environment variables that are useful during development:

| Variable | Effect |
| :--- | :--- |
| `PLUMA_STORAGE_ROOT=<dir>` | Store projects in `<dir>` instead of Application Support, so test runs never touch real projects |
| `PLUMA_APPEARANCE=light\|dark` | Force the app appearance without changing the system setting |

```bash
PLUMA_STORAGE_ROOT=/tmp/pluma-scratch PLUMA_APPEARANCE=dark swift run
```

Editor colors and type come from `Sources/Views/Components/PlumaTheme.swift`; use its tokens rather than hard-coded hex values so light and dark mode stay consistent.

---

## Project layout

```
Sources/
  CanvaApp.swift            App entry point, menus and commands
  Bridge/                   Localhost HTTP bridge used by the MCP server
  Engine/                   Export, snapping and vector geometry
  Models/                   Project, page, element and style models; storage
  Templates/                Built-in template catalog
  Utilities/                Importers (PPTX, PDF, SVG), text measurement, thumbnails, presets
  ViewModels/               CanvasDocumentViewModel (editor state, undo history)
  Views/                    Toolbar, canvas, left drawer tabs, inspector, modals
Tests/PlumaTests/           XCTest suites
Resources/                  App icon and textures
scripts/                    build_app.sh, MCP server, CLI, icon generators
```
