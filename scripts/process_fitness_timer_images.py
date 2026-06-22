"""Process raw fitness timer artwork into app-ready transparent assets."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageFilter, ImageOps

try:
    from rembg import remove
except Exception:  # pragma: no cover - optional local dependency.
    remove = None


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "picture" / "part" / "3个定时器"
OUT = ROOT / "growth_os" / "assets" / "images" / "fitness_timer"

ASSETS = {
    "cat_avatar_default..png": "cat_avatar_default.png",
    "bubble_message.png": "bubble_message.png",
    "deco_heart.png": "deco_heart.png",
    "deco_star.png": "deco_star.png",
    "deco_sparkle.png": "deco_sparkle.png",
    "btn_circle_white.png": "btn_circle_white.png",
    "soft_shadow_oval.png": "soft_shadow_oval.png",
    "cat_fitness_dumbbell_main.png": "cat_fitness_dumbbell_main.png",
    "cat_fitness_plank.png": "cat_fitness_plank.png",
    "cat_fitness_rest.png": "cat_fitness_rest.png",
    "cat_avatar_fitness.png": "cat_avatar_fitness.png",
    "item_dumbbell.png": "item_dumbbell.png",
    "item_yoga_mat.png": "item_yoga_mat.png",
    "item_kettlebell.png": "item_kettlebell.png",
    "item_towel.png": "item_towel.png",
    "item_sport_bottle.png": "item_sport_bottle.png",
    "deco_fitness_sweat.png": "deco_fitness_sweat.png",
}

PROTECTED = {
    "cat_fitness_dumbbell_main.png",
    "cat_fitness_plank.png",
    "cat_fitness_rest.png",
    "cat_avatar_fitness.png",
    "cat_avatar_default.png",
}


def clean_edge_background(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    arr = np.array(rgba)
    rgb = arr[:, :, :3].astype(np.int16)
    mx = rgb.max(axis=2)
    mn = rgb.min(axis=2)
    candidate = (mn >= 218) & ((mx - mn) <= 32)
    border_ratio = np.mean(
        np.concatenate(
            [candidate[0, :], candidate[-1, :], candidate[:, 0], candidate[:, -1]]
        )
    )
    if border_ratio < 0.30:
        return rgba

    # Simple flood fill from the border, limited to light checker/white pixels.
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
        if y < 0 or x < 0 or y >= h or x >= w or seen[y, x] or not candidate[y, x]:
            continue
        seen[y, x] = True
        stack.extend(((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)))

    alpha = Image.fromarray((~seen).astype(np.uint8) * 255, "L")
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.5))
    arr[:, :, 3] = np.minimum(arr[:, :, 3], np.array(alpha))
    return Image.fromarray(arr, "RGBA")


def crop_to_content(img: Image.Image, padding: int = 24) -> Image.Image:
    bbox = img.getchannel("A").getbbox()
    if bbox is None:
        return img
    return img.crop(
        (
            max(0, bbox[0] - padding),
            max(0, bbox[1] - padding),
            min(img.width, bbox[2] + padding),
            min(img.height, bbox[3] + padding),
        )
    )


def add_sticker_protection(img: Image.Image) -> Image.Image:
    cutout = crop_to_content(img, padding=28)
    alpha = cutout.getchannel("A")
    outline_alpha = alpha.filter(ImageFilter.MaxFilter(17))
    outline_alpha = outline_alpha.filter(ImageFilter.GaussianBlur(1.0))
    shadow_alpha = outline_alpha.filter(ImageFilter.GaussianBlur(12))

    canvas = Image.new("RGBA", (cutout.width + 48, cutout.height + 54), (0, 0, 0, 0))
    shadow = Image.new("RGBA", cutout.size, (92, 64, 42, 60))
    shadow.putalpha(shadow_alpha.point(lambda p: round(p * 0.34)))
    canvas.alpha_composite(shadow, (24, 34))

    outline = Image.new("RGBA", cutout.size, (255, 255, 255, 245))
    outline.putalpha(outline_alpha)
    canvas.alpha_composite(outline, (24, 24))
    canvas.alpha_composite(cutout, (24, 24))
    return canvas


def process_one(src_name: str, out_name: str) -> None:
    path = SRC / src_name
    img = Image.open(path).convert("RGBA")
    if remove is not None:
        try:
            img = remove(img).convert("RGBA")
        except Exception:
            img = clean_edge_background(img)
    else:
        img = clean_edge_background(img)
    img = crop_to_content(img)
    if out_name in PROTECTED:
        img = add_sticker_protection(img)
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / out_name)


def main() -> None:
    for src, out in ASSETS.items():
        process_one(src, out)
        print(f"processed {out}")


if __name__ == "__main__":
    main()
