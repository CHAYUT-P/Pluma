# ⚡ CanvaNative (Lightweight Native macOS Graphic Studio)

A high-performance, native macOS graphic design application built from scratch in pure **Swift & SwiftUI** with **CoreGraphics** and **Metal** acceleration.

Designed specifically to eliminate the notorious memory bloat and sluggishness of web/Electron-based design tools.

---

## 🚀 Performance Comparison

| Metric | Web / Electron Canva | **CanvaNative** |
| :--- | :--- | :--- |
| **RAM Usage** | **~6,000 MB – 10,000 MB (10 GB)** | **~35 MB – 50 MB** |
| **Launch Time** | 5 – 15 seconds | **< 0.2 seconds (Instant)** |
| **Frame Rate** | 30 – 60 FPS (with lag spikes) | **120 FPS ProMotion Native** |
| **Offline Mode** | Limited / Cloud dependent | **100% Offline & Private** |
| **Battery Impact** | Heavy thermal throttling & fan spin | **Near-zero CPU/battery draw** |

---

## ✨ Features

### 1. Vector & Layout Canvas Engine
- **Infinite Zoom & Pan**: Sub-pixel zoom from 10% to 400%, spacebar pan, trackpad pinch & smooth scroll.
- **Smart Alignment Snapping**: Dynamic smart guides (magenta/pink alignment lines) that snap to artboard centers, edges, and adjacent elements.
- **8-Handle Precision Transform**: Interactive resize handles with optional aspect ratio lock (`Shift+Drag`), and an orbital rotation wheel with angle snapping (0°, 45°, 90°, 180°, 270°).
- **Multi-Selection & Marquee**: Drag-select multiple elements across the canvas, or `Shift+Click` to toggle selection.
- **Multi-Page Artboards**: Work across multiple pages with page tabs, duplicate, add, and reorder.

### 2. Rich Element Types
- **Shapes & Vector Graphics**: Rectangles (adjustable corner radius), Circles/Ellipses, Stars (custom point count), Polygons (custom sides), Diamonds, Hearts, Arrows, Speech Bubbles, Badges, Lines.
- **Advanced Fills**: Solid Colors, Multi-Stop Linear Gradients, Radial Glow Gradients, Frosted Glass (Glassmorphism), and Dot/Grid Pattern fills.
- **Typography Engine**: Access to macOS system fonts, custom font size, weight (300 to 900), letter spacing (tracking), line height, text alignments, shadow/neon glow effects, and underline/italic styling.
- **Image & Photo Filters**: Real-time CoreImage filters (Brightness, Contrast, Saturation, Blur, Sepia, Grayscale, Invert, Vignette), corner radii, and borders.
- **SF Symbols Library**: Searchable built-in library of thousands of SF Symbols organized into categories with custom color tints.
- **Freehand Pen & Brush**: Smooth bezier curve drawing tool with adjustable stroke width and color.

### 3. Built-In Starter Templates (30+)
- 🧠 **Whiteboards**: Product Strategy Mindmap • System Architecture Flowchart • Agile Sticky Board • Kanban Delivery Board • SWOT Analysis • User Journey Map
- 📄 **Resumes & CVs (10)**: Tech/AI Lead • Executive & Board Director • Creative Director • Ivy League Academic • Growth Marketing • Two-Column Minimal • Bold Impact Creative • Healthcare/Clinical • Student & Internship • Sales Manager
- 🚀 **Presentations**: Curatorial Gallery • Artisan Portfolio • Product Vision Keynote (full 5-slide decks)
- 📰 **A4 Documents**: Retro Newspaper • Metropolitan Broadsheet • Haute Couture Lookbook • VC Investment Memo • Bauhaus Review • Letterpress Poster • Nordic Invoice
- 📱 **Social**: Square posts, Stories, YouTube thumbnails, Flash-sale promos, Business cards

### 4. PowerPoint / Canva Import (High-Fidelity)
- **.pptx**: Exact EMU→px geometry, theme colors & gradients, placeholder inheritance from layouts/masters, tables, SmartArt fallback, shadows, connectors, grouped shapes, vertical text, autofit.
- **Native charts render**: bar / column / line / area / pie charts from embedded `c:chart` XML are re-rendered with axes, gridlines, series colors, labels and legends.
- **Images that actually come through**: EMF/WMF embedded bitmaps are extracted and decoded (most Office decks store pictures this way), plus PNG/JPEG/GIF/WebP/TIFF. Undecodable images get a visible placeholder instead of silently disappearing.
- **Text that stays in place**: paragraphs are measured with real font metrics (wrapping included) and merged into editable text boxes — no more overlapping or drifting lines. Wingdings/Symbol bullet glyphs are mapped to real Unicode.
- **Canva exports**: PDF (multi-page, 2× retina), SVG, and PPTX all import; ZIP of images becomes one page per image.
- Clear error dialog if a file can't be read — never a silent failure.

### 5. Page Thumbnails & Navigation (Canva-style)
- **Pages tab** shows a live mini-preview of every page (auto-refreshes after every confirmed move/resize/edit).
- **Page Overview Grid** (grid button in the page dock): all pages as thumbnails — click to jump, hover for duplicate/delete, **drag to reorder**, **double-click the name to rename**.
- Floating page dock with prev/next, page counter, and quick add.

### 6. Whiteboard Mode (Figma/Miro Style)
- Infinite dot-grid board with viewport culling for silky panning.
- **Quick-add palette**: select, pen, sticky note, text, shape, arrow, star, connect, undo.
- **Anchored connectors** (`L`): arrows glue two elements together and follow them when moved, resized, or rotated.
- **Double-click empty space → instant sticky note** at that point, ready to type.

### 6b. Precision Tools
- **Rulers & guides** (⌘R): drag from a ruler to create a guide; guides snap elements while dragging; drag off-page or double-click to remove.
- **⌘K command palette**: search every command, page, and tool.
- **Zoom to selection** (`F`), arrow-key nudging, group shortcuts (⌘G / ⇧⌘G).
- **Export all pages** as numbered 2× PNGs to a folder in one click; copy any single element as an image.

### 7. High-Resolution Native Export
- **PNG**: 1x, 2x HD, 3x Retina, 4x Ultra resolution with transparent background support.
- **JPEG**: Adjustable compression quality (0.5 to 1.0) and high DPI output.
- **PDF**: Crisp vector PDF document generation.
- **SVG**: Standards-compliant vector markup output.
- **PPTX**: export decks back to PowerPoint format.
- **Native Clipboard Copy (`⇧⌘C`)**: Instantly copy high-res PNG to clipboard to paste directly into Slack, Figma, Twitter, or Keynote.
- **Project Files (`.canv`)**: Save and reload entire design projects locally.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `V` | Selection Tool |
| `T` | Add Text |
| `R` | Add Rectangle / Shape |
| `O` | Add Circle |
| `P` | Toggle Draw / Brush Tool |
| `L` | Connect selected elements (anchored connector chain) |
| `F` | Zoom to selection (fit page when nothing selected) |
| `↑ ↓ ← →` | Nudge selection 1px (hold `Shift` for 10px) |
| `⌘K` | Command palette (search every action, page, template) |
| `⌘R` | Toggle rulers & draggable guides |
| `⌘G` / `⇧⌘G` | Group / Ungroup selection |
| `⌘Z` | Undo |
| `⇧⌘Z` | Redo |
| `⌘C` | Copy Element |
| `⌘V` | Paste Element |
| `⌘D` | Duplicate Element |
| `⌘A` | Select All Elements |
| `Delete` / `⌫` | Delete Selected |
| `⌘]` | Bring Forward |
| `⌥⌘]` | Bring to Front |
| `⌘[` | Send Backward |
| `⌥⌘[` | Send to Back |
| `⇧⌘C` | Copy HD Image to Clipboard |
| `⌘E` | Open Export Modal |
| `⌘+` / `⌘-` | Zoom In / Zoom Out |
| `⌘0` | Zoom to 100% |

---

## 🤖 AI-Ready (MCP Server)

Pluma ships with a built-in **AI bridge**: a localhost-only HTTP server (127.0.0.1:9470, auto-started with the app) plus a dependency-free MCP server so Claude Desktop, Cursor, or any MCP client can design **directly in the live app** — including **seeing the canvas via screenshots**.

**Connect Claude Desktop / Cursor:** click the ✨ button in Pluma's toolbar (copies the config), or add manually:

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

**17 AI tools:** status • get page • **screenshot (vision!)** • add element (text/shapes/sticky/code/image) • update • delete • duplicate • reorder • connect (anchored arrows) • add/select page • undo/redo • save • list/apply templates • design guide.

Example prompts: *"Make me a 5-slide pitch deck for a coffee startup"*, *"Add a pricing section with three cards"*, *"Rearrange this board into columns and connect the flow"* — the AI edits the live canvas, screenshots its work, and fixes layout issues on its own.

Disable with `PLUMA_BRIDGE=0`; change port with `PLUMA_PORT` (then set the same env for the MCP server).

---

## 🛠️ How to Build & Run

### Quick Launch via Terminal
```bash
# Run directly in development mode
swift run

# Or build the release .app bundle
./scripts/build_app.sh

# Launch the standalone macOS app
open CanvaNative.app
```

### Install into `/Applications`
```bash
./scripts/build_app.sh
cp -R CanvaNative.app /Applications/
```
# Pluma
