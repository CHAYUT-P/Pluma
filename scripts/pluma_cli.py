#!/usr/bin/env python3
"""
Pluma CLI Engine
Command-line utility for inspecting, creating, editing, and automating Pluma canvas projects.
"""

import sys
import os
import json
import uuid
import argparse
import subprocess
from datetime import datetime, timezone

PROJECTS_DIR = os.path.expanduser("~/Library/Application Support/CanvaNative/Projects")

def ensure_projects_dir():
    os.makedirs(PROJECTS_DIR, exist_ok=True)

def list_projects():
    ensure_projects_dir()
    projects = []
    for fname in os.listdir(PROJECTS_DIR):
        if fname.endswith(".canv"):
            path = os.path.join(PROJECTS_DIR, fname)
            try:
                with open(path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    pages = data.get("pages", [])
                    first_page = pages[0] if pages else {}
                    projects.append({
                        "id": data.get("id"),
                        "name": data.get("name", "Untitled"),
                        "modifiedAt": data.get("modifiedAt"),
                        "width": first_page.get("width", 1080),
                        "height": first_page.get("height", 1080),
                        "pageCount": len(pages),
                        "file": path
                    })
            except Exception as e:
                continue
    return sorted(projects, key=lambda p: p.get("modifiedAt", ""), reverse=True)

def load_project(project_id_or_name):
    ensure_projects_dir()
    for fname in os.listdir(PROJECTS_DIR):
        if fname.endswith(".canv"):
            path = os.path.join(PROJECTS_DIR, fname)
            try:
                with open(path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    if data.get("id") == project_id_or_name or data.get("name", "").lower() == project_id_or_name.lower():
                        return data, path
            except Exception:
                continue
    return None, None

def save_project(project_data, path=None):
    ensure_projects_dir()
    proj_id = project_data.get("id") or str(uuid.uuid4()).upper()
    project_data["id"] = proj_id
    project_data["modifiedAt"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    if "createdAt" not in project_data:
        project_data["createdAt"] = project_data["modifiedAt"]
    
    if not path:
        path = os.path.join(PROJECTS_DIR, f"{proj_id}.canv")

    # Write-then-rename: a crash mid-write must never truncate a good .canv.
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(project_data, f, indent=2)
    os.replace(tmp, path)
    return project_data, path

# --- .canv schema helpers -----------------------------------------------------
# These emit the exact JSON the app's Codable models decode. Field names, enum
# raw values, and the {"case": {"_0": value}} payload wrapper all match
# Sources/Models/*.swift — a file missing a strictly-decoded key fails to open.

def hex_to_col(h):
    if isinstance(h, str) and h.startswith("#") and len(h) == 7:
        return {
            "red": int(h[1:3], 16) / 255.0,
            "green": int(h[3:5], 16) / 255.0,
            "blue": int(h[5:7], 16) / 255.0,
            "opacity": 1.0,
        }
    return {"red": 0.0, "green": 0.0, "blue": 0.0, "opacity": 1.0}

def solid_fill(h):
    """FillStyle: every field is strictly decoded."""
    return {
        "type": "Solid Color",
        "solidColor": hex_to_col(h),
        "gradientStops": [],
        "gradientAngle": 90.0,
        "patternStyle": "Grid Lines",
        "patternScale": 24.0,
        "glassBlur": 20.0,
        "glassOpacity": 0.65,
    }

def stroke_style(h, width):
    return {
        "isEnabled": width > 0,
        "color": hex_to_col(h),
        "lineWidth": float(width),
        "dashPattern": "Solid",
    }

def no_shadow():
    return {
        "isEnabled": False,
        "color": {"red": 0.0, "green": 0.0, "blue": 0.0, "opacity": 0.25},
        "radius": 8.0,
        "x": 0.0,
        "y": 4.0,
    }

# ShapeKind raw values (Sources/Models/CanvasElement.swift). CLI accepts the
# camelCase API names as well as the exact raw values.
SHAPE_KINDS = {
    "rectangle": "Rectangle", "roundedrectangle": "Rounded Card",
    "pill": "Pill / Capsule", "washitape": "Washi Tape",
    "postagestamp": "Postage Stamp", "waxseal": "Wax Seal",
    "tornpaper": "Torn Paper", "oxfordborder": "Newspaper Rule",
    "circle": "Circle / Stamp", "triangle": "Triangle",
    "star": "Star Badge", "sparklestar": "4-Point Sparkle",
    "starburst": "Sunburst Badge", "polygon": "Hexagon",
    "hexagon": "Hexagon", "diamond": "Diamond", "heart": "Heart",
    "flower": "Petal Flower", "arrow": "Arrow", "chevron": "Chevron Arrow",
    "speechbubble": "Speech Bubble", "quotebubble": "Quote Callout",
    "bannerribbon": "Ribbon Banner", "bookmark": "Bookmark Notch",
    "arch": "Arch Doorway", "shield": "Shield Badge", "tag": "Price Tag",
    "ticket": "Ticket / Coupon", "cross": "Plus / Cross", "plus": "Plus / Cross",
    "lightning": "Lightning Bolt", "crescentmoon": "Crescent Moon",
    "donut": "Ring / Donut", "database": "Database Cylinder",
    "parallelogram": "Parallelogram", "trapezoid": "Trapezoid",
    "cloud": "Cloud", "badge": "Embossed Seal", "line": "Line / Hairline",
}

def shape_kind(name):
    key = name.replace(" ", "").replace("/", "").replace("-", "").lower()
    if key in SHAPE_KINDS:
        return SHAPE_KINDS[key]
    # exact raw-value match (e.g. "Rounded Card")
    for raw in SHAPE_KINDS.values():
        if name == raw:
            return raw
    return "Rounded Card"

def base_element(elem_id, name, payload, x, y, width, height, z_index):
    return {
        "id": elem_id,
        "name": name,
        "payload": payload,
        "x": float(x), "y": float(y),
        "width": float(width), "height": float(height),
        "rotation": 0.0, "opacity": 1.0,
        "isLocked": False, "isVisible": True,
        "shadow": no_shadow(),
        "zIndex": z_index,
        "backdropBlur": 0.0,
    }

def create_project(name="Untitled Design", width=1080, height=1080, bg_color="#FFFFFF"):
    proj_id = str(uuid.uuid4()).upper()
    page_id = str(uuid.uuid4()).upper()
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    project = {
        "id": proj_id,
        "name": name,
        "createdAt": now,
        "modifiedAt": now,
        "pages": [
            {
                "id": page_id,
                "name": "Page 1",
                "width": float(width),
                "height": float(height),
                "background": solid_fill(bg_color),
                "isTransparent": False,
                "elements": []
            }
        ]
    }
    return save_project(project)

def add_text_element(project_data, page_index=0, text="New Text", font="Playfair Display", size=36, weight=700, color="#18181B", x=100, y=100, width=500, height=60, alignment="left"):
    pages = project_data.get("pages", [])
    if page_index >= len(pages):
        page_index = 0

    elem_id = str(uuid.uuid4()).upper()
    max_z = max([e.get("zIndex", 0) for e in pages[page_index].get("elements", [])] + [0])

    align = {"left": "Left", "center": "Center", "right": "Right", "justified": "Justified"}.get(alignment.lower(), "Left")
    element = base_element(
        elem_id, f"Text: {text[:20]}",
        {"text": {"_0": {
            "text": text,
            "fontFamily": font,
            "fontSize": float(size),
            "fontWeight": float(weight),
            "isItalic": False,
            "isUnderlined": False,
            "alignment": align,
            "textColor": hex_to_col(color),
            "useGradient": False,
            "textGradient": solid_fill(color),
            "letterSpacing": 0.0,
            "lineSpacing": 4.0,
            "effectKind": "None",
            "effectColor": hex_to_col("#000000"),
            "effectWidth": 1.0,
            "outlineColor": hex_to_col("#000000"),
            "outlineWidth": 0.0,
            "isCurved": False,
            "curveAngle": 0.0,
            "cardBorderWidth": 0.0,
            "cardCornerRadius": 0.0,
            "cardPadding": 0.0,
        }}},
        x, y, width, height, max_z + 1)
    pages[page_index]["elements"].append(element)
    return elem_id

def add_shape_element(project_data, page_index=0, kind="roundedRectangle", fill_color="#C2410C", stroke_color="#000000", stroke_width=0, corner_radius=12, x=100, y=100, width=200, height=200):
    pages = project_data.get("pages", [])
    if page_index >= len(pages):
        page_index = 0

    elem_id = str(uuid.uuid4()).upper()
    max_z = max([e.get("zIndex", 0) for e in pages[page_index].get("elements", [])] + [0])

    raw_kind = shape_kind(kind)
    element = base_element(
        elem_id, f"Shape: {raw_kind}",
        {"shape": {"_0": {
            "kind": raw_kind,
            "cornerRadius": float(corner_radius),
            "starPoints": 5,
            "polygonSides": 6,
            "fill": solid_fill(fill_color),
            "stroke": stroke_style(stroke_color, stroke_width),
        }}},
        x, y, width, height, max_z + 1)
    pages[page_index]["elements"].append(element)
    return elem_id

def main():
    parser = argparse.ArgumentParser(description="Pluma Automation CLI Engine")
    subparsers = parser.add_subparsers(dest="command")

    # list
    subparsers.add_parser("list", help="List all Pluma projects")

    # create
    create_p = subparsers.add_parser("create", help="Create a new Pluma project")
    create_p.add_argument("--name", default="New Design")
    create_p.add_argument("--width", type=float, default=1080)
    create_p.add_argument("--height", type=float, default=1080)
    create_p.add_argument("--bg", default="#FFFFFF")

    # get
    get_p = subparsers.add_parser("get", help="Get project JSON")
    get_p.add_argument("id_or_name")

    # add-text
    text_p = subparsers.add_parser("add-text", help="Add text to project")
    text_p.add_argument("id_or_name")
    text_p.add_argument("--text", required=True)
    text_p.add_argument("--font", default="Playfair Display")
    text_p.add_argument("--size", type=float, default=32)
    text_p.add_argument("--weight", type=int, default=700)
    text_p.add_argument("--color", default="#18181B")
    text_p.add_argument("--x", type=float, default=100)
    text_p.add_argument("--y", type=float, default=100)
    text_p.add_argument("--w", type=float, default=600)
    text_p.add_argument("--h", type=float, default=50)

    # add-shape
    shape_p = subparsers.add_parser("add-shape", help="Add shape to project")
    shape_p.add_argument("id_or_name")
    shape_p.add_argument("--kind", default="roundedRectangle")
    shape_p.add_argument("--fill", default="#C2410C")
    shape_p.add_argument("--stroke", default="#000000")
    shape_p.add_argument("--stroke-w", type=float, default=0)
    shape_p.add_argument("--x", type=float, default=100)
    shape_p.add_argument("--y", type=float, default=100)
    shape_p.add_argument("--w", type=float, default=200)
    shape_p.add_argument("--h", type=float, default=200)

    # open
    open_p = subparsers.add_parser("open", help="Open Pluma app")

    args = parser.parse_args()

    if args.command == "list":
        projects = list_projects()
        print(json.dumps(projects, indent=2))
    elif args.command == "create":
        proj, path = create_project(args.name, args.width, args.height, args.bg)
        print(json.dumps({"status": "created", "id": proj["id"], "file": path}, indent=2))
    elif args.command == "get":
        proj, path = load_project(args.id_or_name)
        if proj:
            print(json.dumps(proj, indent=2))
        else:
            print(json.dumps({"error": f"Project '{args.id_or_name}' not found"}), file=sys.stderr)
            sys.exit(1)
    elif args.command == "add-text":
        proj, path = load_project(args.id_or_name)
        if not proj:
            print(json.dumps({"error": "Project not found"}), file=sys.stderr)
            sys.exit(1)
        elem_id = add_text_element(proj, 0, args.text, args.font, args.size, args.weight, args.color, args.x, args.y, args.w, args.h)
        save_project(proj, path)
        print(json.dumps({"status": "added_text", "element_id": elem_id, "project_id": proj["id"]}, indent=2))
    elif args.command == "add-shape":
        proj, path = load_project(args.id_or_name)
        if not proj:
            print(json.dumps({"error": "Project not found"}), file=sys.stderr)
            sys.exit(1)
        elem_id = add_shape_element(proj, 0, args.kind, args.fill, args.stroke, args.stroke_w, 12, args.x, args.y, args.w, args.h)
        save_project(proj, path)
        print(json.dumps({"status": "added_shape", "element_id": elem_id, "project_id": proj["id"]}, indent=2))
    elif args.command == "open":
        # Prefer the installed app; fall back to the repo build during dev.
        candidates = ["/Applications/Pluma.app", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Pluma.app")]
        target = next((c for c in candidates if os.path.isdir(c)), candidates[0])
        subprocess.run(["open", target], check=False)
        print(json.dumps({"status": "opened_app", "path": target}))
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
