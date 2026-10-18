---
name: pluma-designer
description: Comprehensive skill for automating, generating, and styling graphics, presentations, pitch decks, resumes, and marketing banners directly in Pluma via MCP tools and CLI.
---

# Pluma AI Designer Skill

This skill equips the agent to act as an autonomous graphic designer, art director, and layout specialist for **Pluma**.

## Capabilities

1. **Autonomous Design Generation**:
   - Create pitch decks (16:9, 1920×1080), executive resumes (A4, 1240×1754), Instagram posts (1080×1080), YouTube thumbnails (1280×720), and code snippet graphics (1200×675).
   - Lay out hierarchy: Title $\rightarrow$ Subtitle $\rightarrow$ Body paragraphs $\rightarrow$ Metric badges $\rightarrow$ Accent rules.

2. **Available MCP Tools** (via `scripts/pluma_mcp_server.py` → live app bridge on 127.0.0.1:9470):
   - `pluma_status`: App connection + project info. Always call first.
   - `pluma_get_page`: Every element on a page (id, geometry, styles, text).
   - `pluma_screenshot`: PNG render of a page — use it to SEE and iterate on edits.
   - `pluma_add_element`: text, shapes (rectangle/circle/star/arrow/diamond/database…), sticky, image; supports `fill:"pattern"` + `pattern`/`patternScale`/`patternColor`/`baseColor` for halftone & crosshatch fills.
   - `pluma_add_code_block`: syntax-highlighted code card (12 languages, 7 themes).
   - `pluma_update_element` / `pluma_delete_element` / `pluma_duplicate_element` / `pluma_reorder_element`.
   - `pluma_connect_elements`: anchored arrows that follow elements.
   - `pluma_add_page` / `pluma_select_page` / `pluma_clear_page`.
   - `pluma_undo` / `pluma_redo` / `pluma_save` — all bridge edits are undoable.
   - `pluma_list_templates` / `pluma_apply_template`, `pluma_design_guide`.

3. **Pluma CLI Alternative**:
   ```bash
   python3 scripts/pluma_cli.py list
   python3 scripts/pluma_cli.py create --name "AI Pitch Deck" --width 1920 --height 1080 --bg "#18181B"
   python3 scripts/pluma_cli.py add-text "AI Pitch Deck" --text "Next-Gen AI" --font "Playfair Display" --size 48 --color "#C2410C" --x 100 --y 100
   python3 scripts/pluma_cli.py open
   ```

## Design Guidelines for AI Generated Canvases

- **Terracotta & Warm Ink Palette**: Use `#C2410C` (terracotta primary accent), `#18181B` (deep charcoal text), `#FAF7F0` (vintage parchment), `#F5F5F4` (soft grey card fills).
- **Typography Pairing**:
  - Headings: `Playfair Display`, `Bodoni 72`, `Didot`, or `Inter` (Bold/Black).
  - Body: `Georgia`, `Charter`, `Inter`, or `Avenir Next`.
  - Monospace / Specs: `SF Mono` or `Menlo`.
