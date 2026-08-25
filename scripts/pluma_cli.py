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
        
    with open(path, "w", encoding="utf-8") as f:
        json.dump(project_data, f, indent=2)
    return project_data, path

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
                "background": {
                    "type": "solid",
                    "solidColor": {
                        "red": int(bg_color[1:3], 16) / 255.0,
                        "green": int(bg_color[3:5], 16) / 255.0,
                        "blue": int(bg_color[5:7], 16) / 255.0,
                        "alpha": 1.0
                    }
                },
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
    
    r = int(color[1:3], 16) / 255.0 if color.startswith("#") and len(color) == 7 else 0.0
    g = int(color[3:5], 16) / 255.0 if color.startswith("#") and len(color) == 7 else 0.0
    b = int(color[5:7], 16) / 255.0 if color.startswith("#") and len(color) == 7 else 0.0
    
    elem_id = str(uuid.uuid4()).upper()
    max_z = max([e.get("zIndex", 0) for e in pages[page_index].get("elements", [])] + [0])
    
    element = {
        "id": elem_id,
        "name": f"Text: {text[:20]}",
        "payload": {
            "text": {
                "text": text,
                "fontFamily": font,
                "fontSize": float(size),
                "fontWeight": int(weight),
                "isItalic": False,
                "alignment": {"left": "Left", "center": "Center", "right": "Right"}.get(alignment.lower(), "Left"),
                "textColor": {"red": r, "green": g, "blue": b, "alpha": 1.0},
                "letterSpacing": 0.0,
                "lineSpacing": 4.0,
                "isUppercase": False,
                "isUnderline": False,
                "isStrikethrough": False,
                "effectKind": "none",
                "effectColor": {"red": 0.0, "green": 0.0, "blue": 0.0, "alpha": 1.0},
                "effectOffset": 2.0,
                "effectBlur": 0.0,
                "effectThickness": 1.0
            }
        },
        "x": float(x),
        "y": float(y),
        "width": float(width),
        "height": float(height),
        "rotation": 0.0,
        "opacity": 1.0,
        "isLocked": False,
        "isHidden": False,
        "zIndex": max_z + 1
    }
    pages[page_index]["elements"].append(element)
    return elem_id

def add_shape_element(project_data, page_index=0, kind="roundedRectangle", fill_color="#C2410C", stroke_color="#000000", stroke_width=0, corner_radius=12, x=100, y=100, width=200, height=200):
    pages = project_data.get("pages", [])
    if page_index >= len(pages):
        page_index = 0
        
    def hex_to_col(h):
        if h.startswith("#") and len(h) == 7:
            return {"red": int(h[1:3], 16)/255.0, "green": int(h[3:5], 16)/255.0, "blue": int(h[5:7], 16)/255.0, "alpha": 1.0}
        return {"red": 0.0, "green": 0.0, "blue": 0.0, "alpha": 1.0}

    elem_id = str(uuid.uuid4()).upper()
    max_z = max([e.get("zIndex", 0) for e in pages[page_index].get("elements", [])] + [0])
    
    element = {
        "id": elem_id,
        "name": f"Shape: {kind}",
        "payload": {
            "shape": {
                "kind": kind,
                "cornerRadius": float(corner_radius),
                "starPoints": 5,
                "polygonSides": 6,
                "fill": {
                    "type": "solid",
                    "solidColor": hex_to_col(fill_color)
                },
                "stroke": {
                    "isEnabled": stroke_width > 0,
                    "color": hex_to_col(stroke_color),
                    "lineWidth": float(stroke_width),
                    "dashPattern": []
                }
            }
        },
        "x": float(x),
        "y": float(y),
        "width": float(width),
        "height": float(height),
        "rotation": 0.0,
        "opacity": 1.0,
        "isLocked": False,
        "isHidden": False,
        "zIndex": max_z + 1
    }
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
        os.system("open /Users/chayut/project/canvas/Pluma.app")
        print(json.dumps({"status": "opened_app"}))
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
