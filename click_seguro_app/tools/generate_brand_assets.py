#!/usr/bin/env python3
"""Render the official SVG into app, launcher and splash assets.

Requires Python 3, Pillow, libcairo and librsvg (no network access).
Run from any directory: python3 tools/generate_brand_assets.py
The original SVG remains the source of truth; its paths and colors are unchanged.
"""

import ctypes as c
import json
from pathlib import Path
from tempfile import TemporaryDirectory

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/branding/click_seguro_logo.svg"
BACKGROUND = "#FFFDFB"


class Rectangle(c.Structure):
    _fields_ = [(name, c.c_double) for name in ("x", "y", "width", "height")]


def render_source(output):
    cairo = c.CDLL("libcairo.so.2")
    rsvg = c.CDLL("librsvg-2.so.2")
    gobject = c.CDLL("libgobject-2.0.so.0")
    cairo.cairo_image_surface_create.argtypes = [c.c_int, c.c_int, c.c_int]
    cairo.cairo_image_surface_create.restype = c.c_void_p
    cairo.cairo_create.argtypes = [c.c_void_p]
    cairo.cairo_create.restype = c.c_void_p
    cairo.cairo_surface_write_to_png.argtypes = [c.c_void_p, c.c_char_p]
    cairo.cairo_surface_write_to_png.restype = c.c_int
    cairo.cairo_destroy.argtypes = [c.c_void_p]
    cairo.cairo_surface_destroy.argtypes = [c.c_void_p]
    rsvg.rsvg_handle_new_from_data.argtypes = [c.c_char_p, c.c_size_t, c.c_void_p]
    rsvg.rsvg_handle_new_from_data.restype = c.c_void_p
    rsvg.rsvg_handle_render_document.argtypes = [
        c.c_void_p, c.c_void_p, c.POINTER(Rectangle), c.c_void_p
    ]
    rsvg.rsvg_handle_render_document.restype = c.c_int
    gobject.g_object_unref.argtypes = [c.c_void_p]
    data = SOURCE.read_bytes()
    handle = rsvg.rsvg_handle_new_from_data(data, len(data), None)
    if not handle:
        raise RuntimeError("Invalid official SVG")
    surface = cairo.cairo_image_surface_create(0, 1024, 1024)
    context = cairo.cairo_create(surface)
    try:
        if not rsvg.rsvg_handle_render_document(
            handle, context, c.byref(Rectangle(0, 0, 1024, 1024)), None
        ):
            raise RuntimeError("Could not render official SVG")
        if cairo.cairo_surface_write_to_png(surface, str(output).encode()):
            raise RuntimeError("Could not write logo PNG")
    finally:
        cairo.cairo_destroy(context)
        cairo.cairo_surface_destroy(surface)
        gobject.g_object_unref(handle)


def write_icon(source, path, size, scale=0.72, opaque=True):
    canvas = Image.new("RGBA", (size, size), BACKGROUND if opaque else (0, 0, 0, 0))
    mark_size = round(size * scale)
    mark = source.resize((mark_size, mark_size), Image.Resampling.LANCZOS)
    canvas.alpha_composite(mark, ((size - mark_size) // 2,) * 2)
    path.parent.mkdir(parents=True, exist_ok=True)
    (canvas.convert("RGB") if opaque else canvas).save(path)


def main():
    with TemporaryDirectory() as temporary:
        png = Path(temporary) / "logo.png"
        render_source(png)
        source = Image.open(png).convert("RGBA")
        source.save(ROOT / "assets/branding/click_seguro_logo.png")

        res = ROOT / "android/app/src/main/res"
        for density, factor in {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2,
                                "xxhdpi": 3, "xxxhdpi": 4}.items():
            write_icon(source, res / f"mipmap-{density}/ic_launcher.png", round(48 * factor))
            write_icon(source, res / f"mipmap-{density}/ic_launcher_foreground.png",
                       round(108 * factor), scale=0.60, opaque=False)
            write_icon(source, res / f"drawable-{density}/launch_logo.png",
                       round(144 * factor), scale=1, opaque=False)

        icons = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
        for item in json.loads((icons / "Contents.json").read_text())["images"]:
            size = round(float(item["size"].split("x")[0]) * float(item["scale"][:-1]))
            write_icon(source, icons / item["filename"], size)
        launch = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
        for factor, suffix in [(1, ""), (2, "@2x"), (3, "@3x")]:
            write_icon(source, launch / f"LaunchImage{suffix}.png",
                       144 * factor, scale=1, opaque=False)

        for size in (192, 512):
            for name in (f"Icon-{size}.png", f"Icon-maskable-{size}.png"):
                write_icon(source, ROOT / "web/icons" / name, size, scale=0.60)
        write_icon(source, ROOT / "web/favicon.png", 64, scale=0.88)
    print("Official logo, launcher icons and launch images generated.")


if __name__ == "__main__":
    main()
