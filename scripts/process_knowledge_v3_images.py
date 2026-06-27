"""Process Knowledge Cards V3 companion assets into transparent WebP files."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(r"F:\opencode\GROS")
SRC = ROOT / "picture"
DST = ROOT / "growth_os" / "assets" / "images" / "knowledge_cards" / "v3"
CACHE = ROOT / ".cache" / "numba"
CACHE.mkdir(parents=True, exist_ok=True)
os.environ["NUMBA_CACHE_DIR"] = str(CACHE)
os.environ["NUMBA_DISABLE_CACHE"] = "1"

from rembg import remove


@dataclass(frozen=True)
class Rule:
    source: str
    output: str
    size: tuple[int, int]


RULES = [
    Rule("study_reading.png", "tiantian_reading.webp", (160, 160)),
    Rule("study_focus.png", "tiantian_focus.webp", (160, 160)),
    Rule("ai_thinking.png", "tiantian_thinking.webp", (160, 160)),
    Rule("ai_pointing.png", "tiantian_pointing.webp", (160, 160)),
    Rule("common_thinking.png", "tiantian_empty.webp", (160, 160)),
    Rule("common_happy.png", "tiantian_success.webp", (160, 160)),
]


def crop_alpha(img: Image.Image, pad: int = 12) -> Image.Image:
    if img.mode != "RGBA":
        img = img.convert("RGBA")
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


def clean_edges(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    r, g, b, a = img.split()
    a = a.point(lambda value: 0 if value < 36 else value)
    a = a.filter(ImageFilter.GaussianBlur(0.22))
    cleaned = Image.merge("RGBA", (r, g, b, a))
    pixels = cleaned.load()
    for y in range(cleaned.height):
        for x in range(cleaned.width):
            pr, pg, pb, pa = pixels[x, y]
            if pa < 12:
                pixels[x, y] = (255, 255, 255, 0)
            elif pa < 72:
                # Desaturate semi-transparent fringe so blue/white source
                # backgrounds do not halo on the paper UI.
                gray = round((pr + pg + pb) / 3)
                pixels[x, y] = (
                    round(pr * 0.72 + gray * 0.28),
                    round(pg * 0.72 + gray * 0.28),
                    round(pb * 0.72 + gray * 0.28),
                    pa,
                )
    return cleaned


def fit_inside(img: Image.Image, target: tuple[int, int]) -> Image.Image:
    tw, th = target
    scale = min(tw / img.width, th / img.height)
    nw = max(1, round(img.width * scale))
    nh = max(1, round(img.height * scale))
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", target, (0, 0, 0, 0))
    canvas.paste(resized, ((tw - nw) // 2, (th - nh) // 2), resized)
    return canvas


def process(rule: Rule) -> Path:
    src = SRC / rule.source
    if not src.exists():
        raise FileNotFoundError(src)
    img = Image.open(src).convert("RGBA")
    img = remove(img)
    if isinstance(img, tuple):
        img = img[0]
    img = crop_alpha(img.convert("RGBA"))
    img = clean_edges(img)
    img = fit_inside(img, rule.size)
    DST.mkdir(parents=True, exist_ok=True)
    out = DST / rule.output
    img.save(out, "WEBP", quality=88, method=6, lossless=False)
    return out


def main() -> None:
    for rule in RULES:
        out = process(rule)
        with Image.open(out) as check:
            print(f"OK {rule.source} -> {out.name} {check.size} {check.mode}")


if __name__ == "__main__":
    main()
