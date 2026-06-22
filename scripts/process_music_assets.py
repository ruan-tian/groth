"""Process raw music artwork into app-ready PNG assets."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

try:
    from rembg import remove
except Exception:  # pragma: no cover - optional local dependency.
    remove = None


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "picture" / "music"
OUT = ROOT / "growth_os" / "assets" / "images" / "music"

COVER_PREFIXES = ("music_cover_", "playlist_cover_")
MAX_COVER_EDGE = 768
MAX_CUTOUT_EDGE = 640
PADDING = 28


def resize_to_max(img: Image.Image, max_edge: int) -> Image.Image:
    edge = max(img.width, img.height)
    if edge <= max_edge:
        return img
    scale = max_edge / edge
    size = (round(img.width * scale), round(img.height * scale))
    return img.resize(size, Image.Resampling.LANCZOS)


def light_edge_alpha(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    arr = np.array(rgba)
    rgb = arr[:, :, :3].astype(np.int16)
    mx = rgb.max(axis=2)
    mn = rgb.min(axis=2)
    candidate = (mn >= 216) & ((mx - mn) <= 42)
    border = np.concatenate(
        [candidate[0, :], candidate[-1, :], candidate[:, 0], candidate[:, -1]]
    )
    if border.mean() < 0.28:
        return rgba

    h, w = candidate.shape
    seen = np.zeros_like(candidate, dtype=bool)
    stack: list[tuple[int, int]] = []
    for x in range(w):
        if candidate[0, x]:
            stack.append((0, x))
        if candidate[h - 1, x]:
            stack.append((h - 1, x))
    for y in range(h):
        if candidate[y, 0]:
            stack.append((y, 0))
        if candidate[y, w - 1]:
            stack.append((y, w - 1))

    while stack:
        y, x = stack.pop()
        if y < 0 or x < 0 or y >= h or x >= w or seen[y, x]:
            continue
        if not candidate[y, x]:
            continue
        seen[y, x] = True
        stack.extend(((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)))

    alpha = Image.fromarray((~seen).astype(np.uint8) * 255, "L")
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.6))
    arr[:, :, 3] = np.minimum(arr[:, :, 3], np.array(alpha))
    return Image.fromarray(arr, "RGBA")


def crop_to_content(img: Image.Image) -> Image.Image:
    bbox = img.getchannel("A").getbbox()
    if bbox is None:
        return img
    return img.crop(
        (
            max(0, bbox[0] - PADDING),
            max(0, bbox[1] - PADDING),
            min(img.width, bbox[2] + PADDING),
            min(img.height, bbox[3] + PADDING),
        )
    )


def process_cutout(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    if remove is not None:
        try:
            rgba = remove(rgba).convert("RGBA")
        except Exception:
            rgba = light_edge_alpha(rgba)
    else:
        rgba = light_edge_alpha(rgba)
    rgba = crop_to_content(rgba)
    return resize_to_max(rgba, MAX_CUTOUT_EDGE)


def process_cover(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    return resize_to_max(rgba, MAX_COVER_EDGE)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    files = sorted(SRC.glob("*.png"))
    if not files:
        raise FileNotFoundError(f"No PNG files found in {SRC}")

    for path in files:
        img = Image.open(path)
        if path.name.startswith(COVER_PREFIXES):
            out = process_cover(img)
        else:
            out = process_cutout(img)
        out.save(OUT / path.name)
        print(f"processed {path.name}")


if __name__ == "__main__":
    main()
