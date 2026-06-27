"""Pet center image batch processor: rembg + crop + resize + organize."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(r"F:\opencode\GROS")
SRC = ROOT / "picture" / "home"
DST = ROOT / "growth_os" / "assets" / "images" / "pet_center"
CACHE = ROOT / ".cache" / "numba"
CACHE.mkdir(parents=True, exist_ok=True)
os.environ.setdefault("NUMBA_CACHE_DIR", str(CACHE))

from rembg import remove


@dataclass(frozen=True)
class Rule:
    out_dir: str
    out_name: str
    size: tuple[int, int]
    fmt: str
    remove_bg: bool
    cover: bool = False
    clean_edges: bool = True


RULES: dict[str, Rule] = {
    "bg_pet_morning..png": Rule(
        "backgrounds", "bg_pet_morning.webp", (1200, 800), "WEBP", False, True
    ),
    "e5bg_pet_afternoon.png": Rule(
        "backgrounds", "bg_pet_afternoon.webp", (1200, 800), "WEBP", False, True
    ),
    "bg_pet_evening.png": Rule(
        "backgrounds", "bg_pet_evening.webp", (1200, 800), "WEBP", False, True
    ),
    "bg_pet_night.png": Rule(
        "backgrounds", "bg_pet_night.webp", (1200, 800), "WEBP", False, True
    ),
    "fg_pet_ground.png": Rule(
        "foregrounds", "fg_pet_ground.webp", (1200, 300), "WEBP", True
    ),
    "fg_pet_furniture.png": Rule(
        "foregrounds", "fg_pet_furniture.webp", (1200, 300), "WEBP", True
    ),
    "pet_center_idle.png": Rule("pets", "pet_center_idle.png", (768, 768), "PNG", True),
    "pet_center_wave.png": Rule("pets", "pet_center_wave.png", (768, 768), "PNG", True),
    "pet_center_read.png": Rule("pets", "pet_center_read.png", (768, 768), "PNG", True),
    "pet_center_sleep.png": Rule("pets", "pet_center_sleep.png", (768, 768), "PNG", True),
    "pet_center_happy.png": Rule("pets", "pet_center_happy.png", (768, 768), "PNG", True),
    "pet_center_think.png": Rule("pets", "pet_center_think.png", (768, 768), "PNG", True),
    "deco_book.png": Rule("deco", "deco_book.png", (96, 96), "PNG", True),
    "eco_pencil.png": Rule("deco", "deco_pencil.png", (96, 96), "PNG", True),
    "deco_target.png": Rule("deco", "deco_target.png", (96, 96), "PNG", True),
    "deco_star.png": Rule("deco", "deco_star.png", (96, 96), "PNG", True),
    "deco_trophy.png": Rule("deco", "deco_trophy.png", (96, 96), "PNG", True),
    "deco_heart.png": Rule("deco", "deco_heart.png", (96, 96), "PNG", True),
    "deco_plant.png": Rule("deco", "deco_plant.png", (96, 96), "PNG", True),
    "deco_lamp.png": Rule("deco", "deco_lamp.png", (96, 96), "PNG", True),
    "particle_heart.png": Rule(
        "particles", "particle_heart.png", (32, 32), "PNG", True
    ),
    "particle_star.png": Rule("particles", "particle_star.png", (32, 32), "PNG", True),
    "particle_sparkle.png": Rule(
        "particles", "particle_sparkle.png", (32, 32), "PNG", True
    ),
    "particle_petals.png": Rule(
        "particles", "particle_petals.png", (32, 32), "PNG", True
    ),
    "bubble_pet_tip.png": Rule("effects", "bubble_pet_tip.png", (512, 256), "PNG", True),
    "soft_shadow_pet.png": Rule(
        "effects", "soft_shadow_pet.png", (512, 240), "PNG", False
    ),
    "light_room_glow.png": Rule(
        "effects", "light_room_glow.webp", (1200, 800), "WEBP", True, False, False
    ),
}


def crop_cover(img: Image.Image, target: tuple[int, int]) -> Image.Image:
    tw, th = target
    scale = max(tw / img.width, th / img.height)
    nw, nh = round(img.width * scale), round(img.height * scale)
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - tw) // 2
    top = (nh - th) // 2
    return resized.crop((left, top, left + tw, top + th))


def crop_alpha(img: Image.Image, pad: int) -> Image.Image:
    if img.mode != "RGBA":
        return img
    bbox = img.getchannel("A").getbbox()
    if bbox is None:
        return img
    left, top, right, bottom = bbox
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(img.width, right + pad)
    bottom = min(img.height, bottom + pad)
    return img.crop((left, top, right, bottom))


def clean_transparent_edges(img: Image.Image) -> Image.Image:
    if img.mode != "RGBA":
        return img

    alpha = img.getchannel("A")
    alpha = alpha.point(lambda a: 0 if a < 64 else min(255, round((a - 64) * 255 / 191)))
    alpha = alpha.filter(ImageFilter.GaussianBlur(radius=0.25))

    r, g, b, _ = img.split()
    cleaned = Image.merge("RGBA", (r, g, b, alpha))

    # Remove color pollution in almost-transparent pixels.
    pixels = cleaned.load()
    for y in range(cleaned.height):
        for x in range(cleaned.width):
            pr, pg, pb, pa = pixels[x, y]
            if pa < 8:
                pixels[x, y] = (255, 255, 255, 0)
            elif pa < 80:
                pixels[x, y] = (pr, pg, pb, max(0, pa - 10))
    return cleaned


def fit_inside(img: Image.Image, target: tuple[int, int]) -> Image.Image:
    tw, th = target
    scale = min(tw / img.width, th / img.height)
    nw, nh = max(1, round(img.width * scale)), max(1, round(img.height * scale))
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    offset = ((tw - nw) // 2, (th - nh) // 2)
    canvas.paste(resized, offset, resized if resized.mode == "RGBA" else None)
    return canvas


def remove_background(img: Image.Image) -> Image.Image:
    result = remove(img)
    if isinstance(result, tuple):
        result = result[0]
    return result.convert("RGBA")


def process_one(src_path: Path, rule: Rule) -> Path:
    out_dir = DST / rule.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    img = Image.open(src_path).convert("RGBA")
    if rule.remove_bg:
        img = remove_background(img)
        img = crop_alpha(img, pad=10)
        if rule.clean_edges:
            img = clean_transparent_edges(img)

    if rule.cover:
        img = crop_cover(img.convert("RGB"), rule.size)
    else:
        img = fit_inside(img, rule.size)

    out_path = out_dir / rule.out_name
    save_kwargs = {}
    if rule.fmt == "WEBP":
        save_kwargs.update({"quality": 86, "method": 6, "lossless": False})
    img.save(out_path, format=rule.fmt, **save_kwargs)
    return out_path


def main() -> None:
    processed = 0
    for filename, rule in RULES.items():
        src_path = SRC / filename
        if not src_path.exists():
            print(f"MISS {filename}")
            continue
        out_path = process_one(src_path, rule)
        with Image.open(out_path) as check:
            alpha = "A" in check.getbands()
            print(
                f"OK {filename} -> {out_path.relative_to(DST)} "
                f"{check.width}x{check.height} {check.mode} alpha={alpha}"
            )
        processed += 1

    print(f"Done: {processed}/{len(RULES)} processed")


if __name__ == "__main__":
    main()
