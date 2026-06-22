"""Process raw health timer artwork into app-ready transparent assets."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

try:
    from rembg import remove
except Exception:  # pragma: no cover - optional local dependency.
    remove = None


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "picture" / "part" / "3个定时器"
OUT_ROOT = ROOT / "growth_os" / "assets" / "images" / "health_timer"

WATER_ASSETS = {
    "cat_water_drinking_main.png": "cat_water_drinking_main.png",
    "cat_water_sit.png": "cat_water_sit.png",
    "cat_water_success.png": "cat_water_success.png",
    "cat_avatar_water.png": "cat_avatar_water.png",
    "item_water_bottle..png": "item_water_bottle.png",
    "item_water_cup.png": "item_water_cup.png",
    "item_lemon_slice.png": "item_lemon_slice.png",
    "item_mint_leaf.png": "item_mint_leaf.png",
    "item_ice_cube.png": "item_ice_cube.png",
    "deco_water_drop.png": "deco_water_drop.png",
    "deco_water_splash.png": "deco_water_splash.png",
    "deco_bubble.png": "deco_bubble.png",
    "deco_sparkle.png": "deco_sparkle.png",
    "bubble_message.png": "bubble_message.png",
    "btn_circle_white.png": "btn_circle_white.png",
    "soft_shadow_oval.png": "soft_shadow_oval.png",
}

SLEEP_ASSETS = {
    "cat_sleep_main.png": "cat_sleep_main.png",
    "cat_sleep_ready.png": "cat_sleep_ready.png",
    "cat_sleep_sit.png": "cat_sleep_sit.png",
    "cat_sleep_wakeup.png": "cat_sleep_wakeup.png",
    "cat_avatar_sleep.png": "cat_avatar_sleep.png",
    "item_night_lamp.png": "item_night_lamp.png",
    "item_pillow_sleep.png": "item_pillow_sleep.png",
    "item_sleep_mask.png": "item_sleep_mask.png",
    "item_bunny_doll.png": "item_bunny_doll.png",
    "item_books_sleep.png": "item_books_sleep.png",
    "item_lavender.png": "item_lavender.png",
    "deco_moon.png": "deco_moon.png",
    "deco_star_sleep.png": "deco_star_sleep.png",
    "deco_cloud_hanging.png": "deco_cloud_hanging.png",
    "deco_sparkle.png": "deco_sparkle.png",
    "bubble_message.png": "bubble_message.png",
    "btn_circle_white.png": "btn_circle_white.png",
    "soft_shadow_oval.png": "soft_shadow_oval.png",
}

PROTECTED = {
    "cat_water_drinking_main.png",
    "cat_water_sit.png",
    "cat_water_success.png",
    "cat_avatar_water.png",
    "cat_sleep_main.png",
    "cat_sleep_ready.png",
    "cat_sleep_sit.png",
    "cat_sleep_wakeup.png",
    "cat_avatar_sleep.png",
}


def clean_edge_background(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    arr = np.array(rgba)
    rgb = arr[:, :, :3].astype(np.int16)
    mx = rgb.max(axis=2)
    mn = rgb.min(axis=2)
    candidate = (mn >= 218) & ((mx - mn) <= 34)
    border_ratio = np.mean(
        np.concatenate(
            [candidate[0, :], candidate[-1, :], candidate[:, 0], candidate[:, -1]]
        )
    )
    if border_ratio < 0.30:
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
    cutout = crop_to_content(img, padding=30)
    alpha = cutout.getchannel("A")
    outline_alpha = alpha.filter(ImageFilter.MaxFilter(19))
    outline_alpha = outline_alpha.filter(ImageFilter.GaussianBlur(1.1))
    shadow_alpha = outline_alpha.filter(ImageFilter.GaussianBlur(13))

    canvas = Image.new("RGBA", (cutout.width + 54, cutout.height + 60), (0, 0, 0, 0))
    shadow = Image.new("RGBA", cutout.size, (79, 111, 66, 58))
    shadow.putalpha(shadow_alpha.point(lambda p: round(p * 0.32)))
    canvas.alpha_composite(shadow, (27, 38))

    outline = Image.new("RGBA", cutout.size, (255, 255, 255, 246))
    outline.putalpha(outline_alpha)
    canvas.alpha_composite(outline, (27, 27))
    canvas.alpha_composite(cutout, (27, 27))
    return canvas


def process_one(src_name: str, out_name: str, out_dir: Path) -> None:
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

    out_dir.mkdir(parents=True, exist_ok=True)
    img.save(out_dir / out_name)


def main() -> None:
    water_dir = OUT_ROOT / "water"
    for src, out in WATER_ASSETS.items():
        process_one(src, out, water_dir)
        print(f"processed water/{out}")

    sleep_dir = OUT_ROOT / "sleep"
    for src, out in SLEEP_ASSETS.items():
        process_one(src, out, sleep_dir)
        print(f"processed sleep/{out}")


if __name__ == "__main__":
    main()
