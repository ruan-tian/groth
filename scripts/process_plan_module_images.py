"""Plan module image processor for the 5-module visual headers."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(r"F:\opencode\GROS")
SRC = ROOT / "picture" / "part" / "日记" / "新版"
DST = ROOT / "growth_os" / "assets" / "images" / "plan_modules"


@dataclass(frozen=True)
class Rule:
    source: str
    module: str
    kind: str
    out_name: str
    size: tuple[int, int]


RULES: list[Rule] = [
    *[
        Rule(f"学习{i}.png", "study", "hero", f"study_hero_{i}.webp", (1200, 520))
        for i in range(1, 5)
    ],
    Rule("学习定时器1.png", "study", "timer", "study_timer.webp", (1200, 520)),
    *[
        Rule(f"运动{i}.png", "fitness", "hero", f"fitness_hero_{i}.webp", (1200, 520))
        for i in range(1, 5)
    ],
    Rule("运动定时器.png", "fitness", "timer", "fitness_timer.webp", (1200, 520)),
    *[
        Rule(f"写日记{i}.png", "journal", "hero", f"journal_hero_{i}.webp", (1200, 520))
        for i in range(1, 5)
    ],
    Rule("开始底图.png", "journal", "timer", "journal_timer.webp", (1200, 520)),
    *[
        Rule(f"饮食{i}.png", "diet", "hero", f"diet_hero_{i}.webp", (1200, 520))
        for i in range(1, 5)
    ],
    Rule("喝水定时1.png", "diet", "timer", "diet_timer.webp", (1200, 520)),
    *[
        Rule(f"睡觉{i}.png", "sleep", "hero", f"sleep_hero_{i}.webp", (1200, 520))
        for i in range(1, 5)
    ],
    Rule("睡觉定时器.png", "sleep", "timer", "sleep_timer.webp", (1200, 520)),
]


def crop_cover(img: Image.Image, target: tuple[int, int]) -> Image.Image:
    tw, th = target
    scale = max(tw / img.width, th / img.height)
    nw, nh = round(img.width * scale), round(img.height * scale)
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - tw) // 2
    top = (nh - th) // 2
    return resized.crop((left, top, left + tw, top + th))


def fit_contain_with_blur(img: Image.Image, target: tuple[int, int]) -> Image.Image:
    tw, th = target
    base = crop_cover(img, target).filter(ImageFilter.GaussianBlur(radius=18))
    overlay = Image.new("RGB", target, (255, 252, 247))
    base = Image.blend(base, overlay, 0.28)

    scale = min(tw / img.width, th / img.height)
    nw, nh = round(img.width * scale), round(img.height * scale)
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (tw - nw) // 2
    top = (th - nh) // 2
    base.paste(resized, (left, top))
    return base


def process(rule: Rule) -> Path:
    src = SRC / rule.source
    if not src.exists():
        raise FileNotFoundError(src)
    out_dir = DST / rule.module / rule.kind
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / rule.out_name
    with Image.open(src) as img:
        out = fit_contain_with_blur(img.convert("RGB"), rule.size)
        out.save(out_path, format="WEBP", quality=86, method=6)
    return out_path


def main() -> None:
    for rule in RULES:
        out = process(rule)
        with Image.open(out) as check:
            print(f"OK {rule.source} -> {out.relative_to(DST)} {check.size} {check.mode}")


if __name__ == "__main__":
    main()
