"""Focus timer image batch processor: rembg + crop + resize + organize."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

from PIL import Image, ImageChops, ImageFilter, ImageOps


ROOT = Path(r"F:\opencode\GROS")
SRC = ROOT / "picture" / "tomato_clock"
DST = ROOT / "growth_os" / "assets" / "images" / "focus"
CACHE = ROOT / ".cache" / "numba"
CACHE.mkdir(parents=True, exist_ok=True)
os.environ.setdefault("NUMBA_CACHE_DIR", str(CACHE))


@dataclass(frozen=True)
class Rule:
    out_dir: str
    out_name: str
    size: tuple[int, int]
    fmt: str
    transparent: bool
    cover: bool = False
    remove_bg: bool = True


RULES: dict[str, Rule] = {
    "bg_focus_overview.png": Rule(
        "backgrounds", "bg_focus_overview.webp", (1200, 420), "WEBP", False, True, False
    ),
    "bg_focus_session_portrait.png": Rule(
        "backgrounds", "bg_focus_session_portrait.webp", (1080, 1920), "WEBP", False, True, False
    ),
    "bg_focus_session_landscape.png": Rule(
        "backgrounds", "bg_focus_session_landscape.webp", (1920, 1080), "WEBP", False, True, False
    ),
    "g_focus_desk_portrait.png": Rule(
        "foregrounds", "fg_focus_desk_portrait.png", (1080, 500), "PNG", True
    ),
    "fg_focus_desk_landscape.png": Rule(
        "foregrounds", "fg_focus_desk_landscape.png", (1920, 420), "PNG", True
    ),
    "focus_cat_idle.png": Rule("cats", "focus_cat_idle.png", (768, 768), "PNG", True),
    "focus_cat_reading.png": Rule("cats", "focus_cat_reading.png", (768, 768), "PNG", True),
    "focus_cat_writing.png": Rule("cats", "focus_cat_writing.png", (768, 768), "PNG", True),
    "focus_cat_thinking.png": Rule("cats", "focus_cat_thinking.png", (768, 768), "PNG", True),
    "focus_cat_rest.png": Rule("cats", "focus_cat_rest.png", (768, 768), "PNG", True),
    "focus_cat_done.png": Rule("cats", "focus_cat_done.png", (768, 768), "PNG", True),
    "icon_focus_pomodoro.png": Rule("icons", "icon_focus_pomodoro.png", (128, 128), "PNG", True),
    "d5e0icon_focus_deep.png": Rule("icons", "icon_focus_deep.png", (128, 128), "PNG", True),
    "icon_focus_ultra.png": Rule("icons", "icon_focus_ultra.png", (128, 128), "PNG", True),
    "icon_focus_custom.png": Rule("icons", "icon_focus_custom.png", (128, 128), "PNG", True),
    "icon_sound_rain.png": Rule("sounds", "icon_sound_rain.png", (128, 128), "PNG", True),
    "icon_sound_ocean.png": Rule("sounds", "icon_sound_ocean.png", (128, 128), "PNG", True),
    "icon_sound_forest.png": Rule("sounds", "icon_sound_forest.png", (128, 128), "PNG", True),
    "icon_sound_cafe.png": Rule("sounds", "icon_sound_cafe.png", (128, 128), "PNG", True),
    "icon_sound_white_noise.png": Rule("sounds", "icon_sound_white_noise.png", (128, 128), "PNG", True),
    "icon_sound_none.png": Rule("sounds", "icon_sound_none.png", (128, 128), "PNG", True),
    "light_focus_room_glow.png": Rule("lights", "light_focus_room_glow.png", (1080, 1920), "PNG", True),
    "light_focus_ring_glow.png": Rule("lights", "light_focus_ring_glow.png", (512, 512), "PNG", True),
    "light_focus_rest_glow.png": Rule("lights", "light_focus_rest_glow.png", (512, 512), "PNG", True),
    "particle_focus_sparkle.png": Rule("particles", "particle_focus_sparkle.png", (32, 32), "PNG", True),
    "particle_focus_leaf.png": Rule("particles", "particle_focus_leaf.png", (64, 64), "PNG", True),
    "particle_focus_heart.png": Rule("particles", "particle_focus_heart.png", (32, 32), "PNG", True),
    "particle_focus_tomato.png": Rule("particles", "particle_focus_tomato.png", (64, 64), "PNG", True),
    "particle_focus_star.png": Rule("particles", "particle_focus_star.png", (32, 32), "PNG", True),
    "particle_focus_rain.png": Rule("particles", "particle_focus_rain.png", (64, 64), "PNG", True),
    "focus_success_badge.png": Rule("status", "focus_success_badge.png", (256, 256), "PNG", True),
    "focus_break_cup.png": Rule("status", "focus_break_cup.png", (256, 256), "PNG", True),
    "focus_interrupt_warning.png": Rule("status", "focus_interrupt_warning.png", (256, 256), "PNG", True),
    "focus_exp_reward.png": Rule("status", "focus_exp_reward.png", (256, 256), "PNG", True),
}


def load_rembg() -> Callable[[Image.Image], Image.Image] | None:
    try:
        from rembg import remove

        return remove
    except Exception as exc:
        print(f"rembg unavailable, using fallback alpha mask: {exc}")
        return None


def crop_cover(img: Image.Image, target: tuple[int, int]) -> Image.Image:
    tw, th = target
    scale = max(tw / img.width, th / img.height)
    nw, nh = round(img.width * scale), round(img.height * scale)
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - tw) // 2
    top = (nh - th) // 2
    return resized.crop((left, top, left + tw, top + th))


def crop_alpha(img: Image.Image, pad: int = 8) -> Image.Image:
    if img.mode != "RGBA":
        return img
    bbox = img.getchannel("A").getbbox()
    if bbox is None:
        return img
    left, top, right, bottom = bbox
    return img.crop(
        (
            max(0, left - pad),
            max(0, top - pad),
            min(img.width, right + pad),
            min(img.height, bottom + pad),
        )
    )


def fit_inside(img: Image.Image, target: tuple[int, int]) -> Image.Image:
    tw, th = target
    scale = min(tw / img.width, th / img.height)
    nw = max(1, round(img.width * scale))
    nh = max(1, round(img.height * scale))
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", target, (0, 0, 0, 0))
    offset = ((tw - nw) // 2, (th - nh) // 2)
    canvas.paste(resized, offset, resized if resized.mode == "RGBA" else None)
    return canvas


def fallback_remove_bg(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    rgb = rgba.convert("RGB")
    bg = Image.new("RGB", rgb.size, (248, 247, 242))
    diff = ImageChops.difference(rgb, bg).convert("L")
    alpha = ImageOps.autocontrast(diff)
    alpha = alpha.point(lambda v: 0 if v < 18 else min(255, round((v - 18) * 1.7)))
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.55))
    r, g, b, _ = rgba.split()
    return Image.merge("RGBA", (r, g, b, alpha))


def clean_alpha_edges(img: Image.Image) -> Image.Image:
    if img.mode != "RGBA":
        return img
    alpha = img.getchannel("A")
    alpha = alpha.point(lambda a: 0 if a < 10 else a)
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.2))
    r, g, b, _ = img.split()
    return Image.merge("RGBA", (r, g, b, alpha))


def remove_background(img: Image.Image, rembg_remove: Callable[[Image.Image], Image.Image] | None) -> Image.Image:
    if rembg_remove is None:
        return fallback_remove_bg(img)
    try:
        result = rembg_remove(img.convert("RGBA"))
        if isinstance(result, tuple):
            result = result[0]
        return result.convert("RGBA")
    except Exception as exc:
        print(f"  rembg failed, fallback used: {exc}")
        return fallback_remove_bg(img)


def process_one(src_path: Path, rule: Rule, rembg_remove: Callable[[Image.Image], Image.Image] | None) -> Path:
    out_dir = DST / rule.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)
    img = Image.open(src_path).convert("RGBA")

    if rule.transparent and rule.remove_bg:
        img = remove_background(img, rembg_remove)
        img = crop_alpha(img, 10)
        img = clean_alpha_edges(img)

    if rule.cover:
        img = crop_cover(img.convert("RGB"), rule.size)
    else:
        img = fit_inside(img, rule.size)

    out_path = out_dir / rule.out_name
    save_kwargs = {}
    if rule.fmt == "WEBP":
        save_kwargs = {"quality": 86, "method": 6}
    img.save(out_path, format=rule.fmt, **save_kwargs)
    return out_path


def main() -> None:
    rembg_remove = load_rembg()
    processed = 0
    for filename, rule in RULES.items():
        src_path = SRC / filename
        if not src_path.exists() and filename == "focus_exp_reward.png":
            src_path = ROOT / "picture" / "event_exp_gain.png"
        if not src_path.exists():
            print(f"MISS {filename}")
            continue
        out_path = process_one(src_path, rule, rembg_remove)
        with Image.open(out_path) as check:
            has_alpha = "A" in check.getbands()
            if rule.transparent and not has_alpha:
                raise RuntimeError(f"{out_path} has no alpha channel")
            print(
                f"OK {filename} -> {out_path.relative_to(DST)} "
                f"{check.width}x{check.height} {check.mode} alpha={has_alpha}"
            )
        processed += 1
    print(f"Done: {processed}/{len(RULES)} processed")


if __name__ == "__main__":
    main()
