"""Journal image batch processor: organize, crop, resize, and keep alpha."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

from PIL import Image, ImageChops, ImageFilter, ImageOps


ROOT = Path(r"F:\opencode\GROS")
SRC = ROOT / "picture"
DST = ROOT / "growth_os" / "assets" / "images" / "journal"
CACHE = ROOT / ".cache" / "numba"
CACHE.mkdir(parents=True, exist_ok=True)
os.environ.setdefault("NUMBA_CACHE_DIR", str(CACHE))


@dataclass(frozen=True)
class Rule:
    source: Path
    out_dir: str
    out_name: str
    size: tuple[int, int]
    fmt: str
    transparent: bool
    cover: bool = False
    remove_bg: bool = True


RULES = [
    Rule(
        SRC / "part" / "日记" / "新版" / "开始底图.png",
        "backgrounds",
        "journal_today_bg.webp",
        (1200, 520),
        "WEBP",
        False,
        True,
        False,
    ),
    Rule(
        SRC / "part" / "日记" / "新版" / "写日记1.png",
        "backgrounds",
        "journal_banner_writing.webp",
        (1200, 520),
        "WEBP",
        False,
        True,
        False,
    ),
    Rule(
        SRC / "journal_writing.png",
        "cats",
        "journal_cat_writing.png",
        (768, 768),
        "PNG",
        True,
    ),
    Rule(
        SRC / "journal_thinking.png",
        "cats",
        "journal_cat_thinking.png",
        (768, 768),
        "PNG",
        True,
    ),
    Rule(
        SRC / "journal_book.png",
        "cats",
        "journal_cat_book.png",
        (768, 768),
        "PNG",
        True,
    ),
    Rule(
        SRC / "journal_done.png",
        "cats",
        "journal_cat_done.png",
        (768, 768),
        "PNG",
        True,
    ),
    Rule(
        SRC / "empty_journal.png",
        "status",
        "journal_empty.png",
        (512, 512),
        "PNG",
        True,
    ),
    Rule(
        SRC / "part" / "可爱铅笔.png",
        "decor",
        "journal_pencil.png",
        (256, 256),
        "PNG",
        True,
    ),
    Rule(
        SRC / "part" / "可爱笔记本.png",
        "decor",
        "journal_notebook.png",
        (256, 256),
        "PNG",
        True,
    ),
    Rule(
        SRC / "part" / "开的可爱书本.png",
        "decor",
        "journal_open_book.png",
        (256, 256),
        "PNG",
        True,
    ),
]


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


def crop_alpha(img: Image.Image, pad: int = 10) -> Image.Image:
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


def remove_background(
    img: Image.Image,
    rembg_remove: Callable[[Image.Image], Image.Image] | None,
) -> Image.Image:
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


def process_one(
    rule: Rule,
    rembg_remove: Callable[[Image.Image], Image.Image] | None,
) -> Path:
    out_dir = DST / rule.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)
    img = Image.open(rule.source).convert("RGBA")

    if rule.transparent and rule.remove_bg:
        img = remove_background(img, rembg_remove)
        img = crop_alpha(img)

    if rule.cover:
        img = crop_cover(img.convert("RGB"), rule.size)
    else:
        img = fit_inside(img, rule.size)

    out_path = out_dir / rule.out_name
    kwargs = {"quality": 86, "method": 6} if rule.fmt == "WEBP" else {}
    img.save(out_path, format=rule.fmt, **kwargs)
    return out_path


def main() -> None:
    rembg_remove = load_rembg()
    processed = 0
    for rule in RULES:
        if not rule.source.exists():
            print(f"MISS {rule.source}")
            continue
        out_path = process_one(rule, rembg_remove)
        with Image.open(out_path) as check:
            has_alpha = "A" in check.getbands()
            if rule.transparent and not has_alpha:
                raise RuntimeError(f"{out_path} has no alpha channel")
            print(
                f"OK {rule.source.name} -> {out_path.relative_to(DST)} "
                f"{check.width}x{check.height} {check.mode} alpha={has_alpha}"
            )
        processed += 1
    print(f"Done: {processed}/{len(RULES)} processed")


if __name__ == "__main__":
    main()
