#!/usr/bin/env python3
"""
Requires Python >= 3.10 (uses `dict | None` type-union syntax).

Pluma MCP Server — lets AI agents (Claude Desktop, Cursor, …) design directly in
the LIVE Pluma app.

Architecture:
    AI (MCP client) ⇄ this stdio MCP server ⇄ HTTP bridge inside Pluma.app (127.0.0.1:9470)

The bridge is started automatically by the app. The killer feature is
pluma_screenshot: the agent gets a PNG of the canvas back, so it can SEE its
edits and iterate like a human designer.

Setup (Claude Desktop / Cursor / any MCP client):
    {
      "mcpServers": {
        "pluma": {
          "command": "python3",
          "args": ["/Users/chayut/project/canvas/scripts/pluma_mcp_server.py"]
        }
      }
    }

No third-party dependencies — pure stdlib MCP (JSON-RPC 2.0 over stdio).
"""

import sys
import os
import json
import urllib.request
import urllib.error

BRIDGE_HOST = "127.0.0.1"
BRIDGE_PORT = int(os.environ.get("PLUMA_PORT", "9470"))
BASE = f"http://{BRIDGE_HOST}:{BRIDGE_PORT}"


# ---------------------------------------------------------------- HTTP helper

def bridge(method: str, path: str, payload: dict | None = None, timeout: float = 30.0) -> dict:
    """Call the Pluma bridge. Returns parsed JSON. Raises BridgeError on failure."""
    url = BASE + path
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        # The app answered but rejected the request — surface ITS error message.
        detail = ""
        try:
            detail = json.loads(e.read().decode()).get("error", "")
        except Exception:
            pass
        raise BridgeError(f"Pluma bridge error {e.code}: {detail or e.reason}") from e
    except urllib.error.URLError as e:
        raise BridgeError(
            f"Cannot reach Pluma at {BASE} ({e.reason}). "
            "Open the Pluma app first — it starts the AI bridge automatically."
        ) from e
    except json.JSONDecodeError as e:
        raise BridgeError(f"Pluma bridge returned invalid JSON: {e}") from e


class BridgeError(Exception):
    pass


# ---------------------------------------------------------------- Tool schemas

TOOLS = [
    {
        "name": "pluma_status",
        "description": "Check the Pluma app connection and get current project info (name, page count, active page, element count). Always call this first.",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "pluma_get_page",
        "description": "Get every element on a page with full geometry & style details (id, type, position, size, text, colors, font…).",
        "inputSchema": {
            "type": "object",
            "properties": {
                "page": {"type": "integer", "description": "1-based page number (default: active page)"}
            },
        },
    },
    {
        "name": "pluma_screenshot",
        "description": "Render a page to PNG and return it as an image so you can SEE the design. ALWAYS screenshot after making edits to verify your work visually before telling the user you're done.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "page": {"type": "integer", "description": "1-based page number (default: active page)"},
                "scale": {"type": "number", "description": "Resolution scale 0.25–2.0 (default 1.0; use 0.5 for quick checks, 1.0+ for text-heavy pages)"},
            },
        },
    },
    {
        "name": "pluma_add_element",
        "description": "Add a new element to the canvas. Types: text, rectangle, circle, star, arrow, diamond, heart, speech (speech bubble), line, pill, hexagon, lightning, database (cylinder), chevron, cross, sticky (sticky note), code (code block — prefer pluma_add_code_block), image (needs imageBase64). Any ShapeKind name also works.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "type": {"type": "string", "description": "text | rectangle | circle | star | arrow | diamond | heart | speech | line | pill | hexagon | lightning | database | chevron | cross | sticky | code | image"},
                "text": {"type": "string", "description": "Text content (text/sticky types)"},
                "x": {"type": "number"}, "y": {"type": "number"},
                "width": {"type": "number"}, "height": {"type": "number"},
                "fill": {"type": "string", "description": "Hex color like #FF0000, or 'pattern' for a patterned fill (shape fill / sticky background)"},
                "pattern": {"type": "string", "description": "When fill='pattern': halftone | halftoneFade | crosshatch | dots | grid | diagonalStripes | newspaperColumns"},
                "patternScale": {"type": "number", "description": "Pattern spacing in px (8–64, default 24)"},
                "patternColor": {"type": "string", "description": "Pattern ink color hex (default: derived from base)"},
                "baseColor": {"type": "string", "description": "Base fill color under the pattern (default #FAF9F7)"},
                "color": {"type": "string", "description": "Hex text color"},
                "fontSize": {"type": "number"}, "fontWeight": {"type": "number", "description": "100–900"},
                "fontFamily": {"type": "string"}, "align": {"type": "string", "description": "Left | Center | Right | Justified"},
                "rotation": {"type": "number"}, "opacity": {"type": "number", "description": "0–1"},
                "name": {"type": "string", "description": "Layer name"},
                "page": {"type": "integer", "description": "1-based page (default: active)"},
                "imageBase64": {"type": "string", "description": "Base64 PNG/JPEG for image type"},
            },
            "required": ["type"],
        },
    },
    {
        "name": "pluma_update_element",
        "description": "Update any properties of an existing element by id (position, size, text, colors, font, rotation, opacity…). Only provided keys change.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "id": {"type": "string", "description": "Element id (from pluma_get_page)"},
                "props": {
                    "type": "object",
                    "description": "Properties to change: x, y, width, height, rotation, opacity, text, fill (hex or 'pattern'), pattern, patternScale, patternColor, baseColor, color, fontSize, fontWeight, fontFamily, align, letterSpacing, lineSpacing, cornerRadius, name, visible, locked. Text boxes also: insetLeft, insetRight, insetTop, insetBottom (px margins), anchor (Top|Center|Bottom). For code blocks: code, language, theme, title.",
                },
            },
            "required": ["id", "props"],
        },
    },
    {
        "name": "pluma_delete_element",
        "description": "Delete an element by id (connected arrows are removed too).",
        "inputSchema": {
            "type": "object",
            "properties": {"id": {"type": "string"}},
            "required": ["id"],
        },
    },
    {
        "name": "pluma_duplicate_element",
        "description": "Duplicate an element (offset by 24px). Returns the new element with its new id.",
        "inputSchema": {
            "type": "object",
            "properties": {"id": {"type": "string"}},
            "required": ["id"],
        },
    },
    {
        "name": "pluma_reorder_element",
        "description": "Change stacking order: action = front | back | forward | backward.",
        "inputSchema": {
            "type": "object",
            "properties": {"id": {"type": "string"}, "action": {"type": "string", "enum": ["front", "back", "forward", "backward"]}},
            "required": ["id", "action"],
        },
    },
    {
        "name": "pluma_add_code_block",
        "description": "Add a syntax-highlighted code snippet card (IDE-style window with traffic lights). Great for docs, READMEs, architecture slides. Languages: swift, python, javascript, typescript, rust, go, html, css, json, sql, cpp, bash. Themes: Carbon Dark, VS Code Dark, Monokai Pro, Dracula, Xcode Light, Paper Craft, Nordic Frost.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "code": {"type": "string", "description": "Source code to display"},
                "language": {"type": "string", "description": "Language name or extension: python, py, swift, js, ts, rs, go, html, css, json, sql, cpp, bash, sh"},
                "theme": {"type": "string", "description": "Theme name (default: VS Code Dark)"},
                "title": {"type": "string", "description": "Window title, e.g. 'api.py'"},
                "lineNumbers": {"type": "boolean"},
                "fontSize": {"type": "number"},
                "x": {"type": "number"}, "y": {"type": "number"},
                "width": {"type": "number"}, "height": {"type": "number", "description": "Card height in px (default: auto-sized to line count)"},
                "page": {"type": "integer", "description": "1-based page (default: active)"},
            },
            "required": ["code"],
        },
    },
    {
        "name": "pluma_clear_page",
        "description": "Delete ALL elements on a page (default: active page). Use before rebuilding a layout. Undoable.",
        "inputSchema": {
            "type": "object",
            "properties": {"page": {"type": "integer"}},
        },
    },
    {
        "name": "pluma_connect_elements",
        "description": "Create an anchored connector arrow between two elements (whiteboard). The arrow follows the elements when they move.",
        "inputSchema": {
            "type": "object",
            "properties": {"from": {"type": "string"}, "to": {"type": "string"}},
            "required": ["from", "to"],
        },
    },
    {
        "name": "pluma_add_page",
        "description": "Add a new page to the project (optionally named).",
        "inputSchema": {
            "type": "object",
            "properties": {"name": {"type": "string"}},
        },
    },
    {
        "name": "pluma_select_page",
        "description": "Switch the active page (1-based).",
        "inputSchema": {
            "type": "object",
            "properties": {"page": {"type": "integer"}},
            "required": ["page"],
        },
    },
    {
        "name": "pluma_undo",
        "description": "Undo the last change.",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "pluma_redo",
        "description": "Redo.",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "pluma_save",
        "description": "Save the project to disk immediately (autosave also runs continuously).",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "pluma_list_templates",
        "description": "List all built-in templates (resumes, whiteboards, presentations, social posts…) with ids for pluma_apply_template.",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "pluma_apply_template",
        "description": "Replace the current project's content with a built-in template by id.",
        "inputSchema": {
            "type": "object",
            "properties": {"id": {"type": "string", "description": "Template id from pluma_list_templates"}},
            "required": ["id"],
        },
    },
    {
        "name": "pluma_design_guide",
        "description": "Best practices for designing on the Pluma canvas with AI: canvas coordinate system, recommended fonts, color pairing, layout recipes (title bars, cards, grids), sticky-note boards, and the screenshot-verify loop.",
        "inputSchema": {"type": "object", "properties": {}},
    },
]


DESIGN_GUIDE = """# Designing in Pluma with AI — Practical Guide

## Coordinate system
- Origin (0,0) is the TOP-LEFT of the page. x grows right, y grows down.
- Get page size from pluma_status / pluma_get_page (e.g. 1920x1080 deck, 1240x1754 A4, 1080x1080 square).
- Center something horizontally: x = (pageWidth - elementWidth) / 2.

## The golden loop
1. pluma_status → see project & page size.
2. pluma_get_page → see what's already there (don't duplicate!).
3. Make edits (pluma_add_element / pluma_update_element …).
4. **pluma_screenshot → LOOK at it.** Fix overlaps, contrast, alignment.
5. Repeat until it looks right, then pluma_save.

## Layout recipes
- **Title slide**: big bold text (fontSize 64–96, fontWeight 800–900) centered at ~38% height, subtitle (fontSize 24–28, weight 400, muted color) below.
- **Content slide**: title top-left (x=70, y=60, fontSize 40), body text blocks with generous margins (≥70px), max ~90 chars/line.
- **Card grid**: rounded rectangles (rectangle type) with 24–40px gaps; put a heading + 2–3 line body inside each card area.
- **Sticky-note board**: sticky type, 220x200, pastel fills (#FEF08A yellow, #D1FAE5 mint, #E0F2FE sky, #FCE7F3 pink), grid with 40px gaps, short phrases (≤8 words).
- **Flow / mindmap**: shapes + pluma_connect_elements arrows between them.
- **Code docs slide**: pluma_add_code_block with title like 'api.py' — the card renders as an IDE window with syntax colors. Pair with a database cylinder (type=database) and arrows for architecture diagrams.

## Typography
- Display/serif headings: "Playfair Display" (800–900).
- Clean UI/body: "Inter" (400–700).
- Handwritten sticky notes: "Indie Flower" (700).
- Hierarchy: title 1.6–2× the subtitle size; body ≥16px on posters, ≥12px on A4.

## Color
- One accent + neutrals wins: e.g. accent #C2410C (terracotta) or #0D9488 (teal) with #1C1917 ink on #FAFAF9 paper.
- Ensure contrast: dark text on light backgrounds, white text on saturated fills.
- Use fills with opacity via darker/lighter hex tints instead of stacking elements.

## Common pitfalls
- Don't place elements off-canvas (keep x ≥ 40, y ≥ 40, x+w ≤ pageWidth-40).
- Text boxes need height ≈ fontSize * 1.4 * expected lines.
- After moving things, connectors auto-follow (they stay glued).
- Screenshot at scale 0.5 for quick layout checks; scale 1.0+ to read text.
"""


# ---------------------------------------------------------------- MCP plumbing

def tool_result(text: str, isError: bool = False, images: list[dict] | None = None) -> dict:
    content: list[dict] = []
    if images:
        content.extend(images)
    content.append({"type": "text", "text": text})
    return {"content": content, "isError": isError}


def call_tool(name: str, args: dict) -> dict:
    if name == "pluma_status":
        r = bridge("GET", "/health")
        return tool_result(json.dumps(r, indent=1))

    if name == "pluma_get_page":
        page = args.get("page")
        path = f"/page?page={page}" if page else "/page"
        r = bridge("GET", path)
        return tool_result(json.dumps(r, indent=1))

    if name == "pluma_screenshot":
        page = args.get("page")
        scale = args.get("scale", 1.0)
        qs = f"scale={scale}"
        if page:
            qs += f"&page={page}"
        r = bridge("GET", f"/screenshot?{qs}", timeout=60.0)
        png_b64 = r.get("png_base64", "")
        image_content = [{
            "type": "image",
            "data": png_b64,
            "mimeType": "image/png",
        }]
        return tool_result(
            f"Screenshot of page {r.get('page')} ({r.get('width')}x{r.get('height')}px). "
            "Inspect it visually and fix any layout problems you notice.",
            images=image_content,
        )

    if name == "pluma_add_element":
        r = bridge("POST", "/element/add", args)
        el = r.get("element", {})
        return tool_result(f"Added {el.get('type')} element id={r.get('id')} at ({el.get('x')},{el.get('y')}) size {el.get('width')}x{el.get('height')}. Screenshot to verify.")

    if name == "pluma_add_code_block":
        args = dict(args)
        args["type"] = "code"
        args.setdefault("width", 560)
        r = bridge("POST", "/element/add", args)
        el = r.get("element", {})
        return tool_result(
            f"Added code block id={r.get('id')} ({el.get('language')}, theme '{el.get('theme')}') "
            f"at ({el.get('x')},{el.get('y')}). Screenshot to verify."
        )

    if name == "pluma_clear_page":
        r = bridge("POST", "/page/clear", args)
        return tool_result(f"Cleared page {r.get('page')} — removed {r.get('removed')} elements.")

    if name == "pluma_update_element":
        r = bridge("POST", "/element/update", args)
        return tool_result("Updated element: " + json.dumps(r.get("element", {}), indent=1))

    if name == "pluma_delete_element":
        bridge("POST", "/element/delete", args)
        return tool_result("Element deleted (and any attached connectors).")

    if name == "pluma_duplicate_element":
        r = bridge("POST", "/element/duplicate", args)
        return tool_result(f"Duplicated → new id {r.get('element', {}).get('id')}")

    if name == "pluma_reorder_element":
        bridge("POST", "/element/reorder", args)
        return tool_result(f"Reordered ({args.get('action')}).")

    if name == "pluma_connect_elements":
        r = bridge("POST", "/connect", args)
        return tool_result(f"Connector created id={r.get('element', {}).get('id')} — it now follows both elements.")

    if name == "pluma_add_page":
        r = bridge("POST", "/page/add", args)
        return tool_result(f"Added page → now {r.get('pages')} pages, active page {r.get('activePage')}.")

    if name == "pluma_select_page":
        r = bridge("POST", "/page/select", args)
        return tool_result(f"Active page is now {r.get('activePage')}.")

    if name == "pluma_undo":
        bridge("POST", "/undo")
        return tool_result("Undone.")

    if name == "pluma_redo":
        bridge("POST", "/redo")
        return tool_result("Redone.")

    if name == "pluma_save":
        r = bridge("POST", "/save")
        return tool_result(f"Saved '{r.get('saved')}'.")

    if name == "pluma_list_templates":
        r = bridge("GET", "/templates")
        lines = [f"- {t['id']}: {t['title']} [{t['category']}]" for t in r.get("templates", [])]
        return tool_result("Templates:\n" + "\n".join(lines))

    if name == "pluma_apply_template":
        r = bridge("POST", "/template", args)
        return tool_result(f"Applied '{r.get('applied')}' → {r.get('pages')} pages. Screenshot to see it.")

    if name == "pluma_design_guide":
        return tool_result(DESIGN_GUIDE)

    return tool_result(f"Unknown tool: {name}", isError=True)


# ---------------------------------------------------------------- JSON-RPC loop

def send(msg: dict):
    sys.stdout.write(json.dumps(msg) + "\n")
    sys.stdout.flush()


def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
        except json.JSONDecodeError:
            continue

        method = req.get("method")
        msg_id = req.get("id")

        if method == "initialize":
            send({
                "jsonrpc": "2.0", "id": msg_id,
                "result": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {"tools": {}},
                    "serverInfo": {"name": "pluma", "version": "2.1.0"},
                },
            })
        elif method == "notifications/initialized":
            pass
        elif method == "ping":
            send({"jsonrpc": "2.0", "id": msg_id, "result": {}})
        elif method == "tools/list":
            send({"jsonrpc": "2.0", "id": msg_id, "result": {"tools": TOOLS}})
        elif method == "tools/call":
            params = req.get("params", {})
            name = params.get("name", "")
            args = params.get("arguments", {}) or {}
            try:
                result = call_tool(name, args)
                send({"jsonrpc": "2.0", "id": msg_id, "result": result})
            except BridgeError as e:
                send({"jsonrpc": "2.0", "id": msg_id, "result": tool_result(str(e), isError=True)})
            except Exception as e:  # noqa: BLE001
                send({"jsonrpc": "2.0", "id": msg_id,
                      "result": tool_result(f"pluma tool error: {e}", isError=True)})
        elif method == "resources/list":
            send({"jsonrpc": "2.0", "id": msg_id, "result": {"resources": []}})
        elif method == "prompts/list":
            send({"jsonrpc": "2.0", "id": msg_id, "result": {"prompts": []}})
        elif msg_id is not None:
            send({"jsonrpc": "2.0", "id": msg_id,
                  "error": {"code": -32601, "message": f"Method not found: {method}"}})


if __name__ == "__main__":
    main()
