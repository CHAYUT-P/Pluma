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

2. **Available MCP Tools**:
   - `pluma_list_projects`: Lists existing projects and their dimensions.
   - `pluma_create_project`: Initializes a new canvas project.
   - `pluma_get_project`: Inspects layer tree, typography, and positions.
   - `pluma_add_text`: Adds typography with custom font family, size, weight, and color.
   - `pluma_add_shape`: Adds vector shapes, cards, pills, and divider lines.
   - `pluma_open_app`: Focuses `Pluma.app` on macOS.

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
