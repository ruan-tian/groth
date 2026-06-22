"""Generate premium plan module illustration backgrounds.

The generated assets intentionally contain no UI copy. Flutter renders all text
and buttons so localization, accessibility, and layout stay deterministic.
"""

from __future__ import annotations

from pathlib import Path
from typing import NamedTuple

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "growth_os"
OUT_ROOT = APP / "assets" / "images" / "plan_modules"
PET_ROOT = APP / "assets" / "pet"


class ModuleSpec(NamedTuple):
    name: str
    primary: str
    soft: str
    accent: str
    pet: Path
    timer: Path


MODULES = [
    ModuleSpec(
        "study",
        "#5D68F2",
        "#EEF2FF",
        "#F8C46B",
        PET_ROOT / "study" / "study_reading.png",
        OUT_ROOT / "study" / "timer" / "study_timer.webp",
    ),
    ModuleSpec(
        "fitness",
        "#FF7A2F",
        "#FFF1E8",
        "#55C985",
        PET_ROOT / "fitness" / "fitness_lifting.png",
        OUT_ROOT / "fitness" / "timer" / "fitness_timer.webp",
    ),
    ModuleSpec(
        "journal",
        "#FF7EAA",
        "#FFF0F6",
        "#F2B65C",
        PET_ROOT / "journal" / "journal_writing.png",
        OUT_ROOT / "journal" / "timer" / "journal_timer.webp",
    ),
    ModuleSpec(
        "diet",
        "#F59E0B",
        "#FFF7E0",
        "#6FCF97",
        PET_ROOT / "diet" / "diet_drink.png",
        OUT_ROOT / "diet" / "timer" / "diet_timer.webp",
    ),
    ModuleSpec(
        "sleep",
        "#8B5CF6",
        "#F4F0FF",
        "#FFB8C6",
        PET_ROOT / "sleep" / "sleep_yawn.png",
        OUT_ROOT / "sleep" / "timer" / "sleep_timer.webp",
    ),
]


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(round(a[i] * (1 - t) + b[i] * t) for i in range(3))


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def make_gradient(size: tuple[int, int], left: str, right: str) -> Image.Image:
    w, h = size
    left_rgb = hex_to_rgb(left)
    right_rgb = hex_to_rgb(right)
    img = Image.new("RGB", size)
    px = img.load()
    for x in range(w):
        t = x / max(1, w - 1)
        color = mix(left_rgb, right_rgb, t)
        for y in range(h):
            px[x, y] = color
    return img.convert("RGBA")


def add_paper_texture(img: Image.Image, opacity: int = 24) -> None:
    w, h = img.size
    texture = Image.new("RGBA", img.size, (255, 255, 255, 0))
    draw = ImageDraw.Draw(texture)
    for y in range(0, h, 4):
        alpha = opacity if (y // 4) % 2 == 0 else opacity // 3
        draw.line((0, y, w, y + 1), fill=(255, 255, 255, alpha))
    for x in range(0, w, 6):
        alpha = opacity // 4
        draw.line((x, 0, x, h), fill=(120, 70, 30, alpha))
    img.alpha_composite(texture)


def add_doodles(img: Image.Image, spec: ModuleSpec) -> None:
    draw = ImageDraw.Draw(img)
    primary = (*hex_to_rgb(spec.primary), 76)
    accent = (*hex_to_rgb(spec.accent), 104)
    white = (255, 255, 255, 150)
    w, h = img.size

    for x, y, s, color in [
        (64, 52, 13, white),
        (105, 84, 9, accent),
        (w - 88, 64, 16, primary),
        (w - 142, h - 46, 9, white),
        (w // 2 + 18, 44, 10, accent),
    ]:
        draw.line((x - s, y, x + s, y), fill=color, width=2)
        draw.line((x, y - s, x, y + s), fill=color, width=2)

    for x, y in [(42, h - 58), (w - 98, h - 44), (w - 62, h - 86)]:
        draw.arc((x, y, x + 34, y + 44), 205, 330, fill=(*hex_to_rgb(spec.accent), 90), width=2)
        draw.line((x + 17, y + 28, x + 17, y + 46), fill=(*hex_to_rgb(spec.accent), 80), width=2)

    for x, y in [(88, h - 78), (w - 118, 88)]:
        draw.arc((x, y, x + 18, y + 18), 200, 40, fill=primary, width=2)
        draw.arc((x + 16, y, x + 34, y + 18), 140, 340, fill=primary, width=2)
        draw.line((x + 1, y + 11, x + 17, y + 28), fill=primary, width=2)
        draw.line((x + 33, y + 11, x + 17, y + 28), fill=primary, width=2)


def paste_contained(base: Image.Image, source_path: Path, box: tuple[int, int, int, int], alpha: float = 1.0) -> None:
    source = Image.open(source_path).convert("RGBA")
    max_w = box[2] - box[0]
    max_h = box[3] - box[1]
    scale = min(max_w / source.width, max_h / source.height)
    new_size = (max(1, round(source.width * scale)), max(1, round(source.height * scale)))
    source = source.resize(new_size, Image.Resampling.LANCZOS)
    if alpha < 1:
        layer_alpha = source.getchannel("A").point(lambda p: round(p * alpha))
        source.putalpha(layer_alpha)
    x = box[0] + (max_w - source.width) // 2
    y = box[1] + (max_h - source.height) // 2
    base.alpha_composite(source, (x, y))


def draw_ground(draw: ImageDraw.ImageDraw, spec: ModuleSpec, y: int, x0: int, x1: int) -> None:
    # Kept for simple line work only; translucent fills are composited by callers.
    draw.arc((x0 - 20, y - 44, x1 + 40, y + 90), 205, 330, fill=(255, 255, 255, 110), width=3)


def add_ground(base: Image.Image, spec: ModuleSpec, y: int, x0: int, x1: int) -> None:
    layer = Image.new("RGBA", base.size, (255, 255, 255, 0))
    draw = ImageDraw.Draw(layer)
    draw.ellipse((x0, y, x1, y + 32), fill=(*hex_to_rgb(spec.primary), 42))
    draw.arc((x0 - 20, y - 44, x1 + 40, y + 90), 205, 330, fill=(255, 255, 255, 120), width=3)
    base.alpha_composite(layer)


def add_hero_props(img: Image.Image, spec: ModuleSpec) -> None:
    draw = ImageDraw.Draw(img)
    primary = (*hex_to_rgb(spec.primary), 150)
    accent = (*hex_to_rgb(spec.accent), 130)
    brown = (133, 92, 62, 120)

    if spec.name == "study":
        draw.rounded_rectangle((664, 392, 806, 424), radius=8, fill=(255, 255, 255, 170), outline=primary, width=3)
        draw.line((682, 405, 788, 405), fill=primary, width=2)
        draw.rounded_rectangle((818, 374, 886, 430), radius=12, fill=(255, 255, 255, 160), outline=accent, width=3)
        draw.line((834, 392, 870, 392), fill=accent, width=2)
    elif spec.name == "fitness":
        draw.rounded_rectangle((650, 386, 716, 448), radius=18, fill=(255, 255, 255, 155), outline=primary, width=3)
        draw.rectangle((674, 368, 692, 388), fill=primary)
        draw.line((740, 418, 832, 418), fill=brown, width=8)
        draw.rounded_rectangle((724, 398, 752, 438), radius=10, fill=accent, outline=brown, width=2)
        draw.rounded_rectangle((820, 398, 848, 438), radius=10, fill=accent, outline=brown, width=2)
    elif spec.name == "journal":
        draw.rounded_rectangle((646, 374, 816, 446), radius=18, fill=(255, 255, 255, 165), outline=primary, width=3)
        for yy in (394, 412, 430):
            draw.line((672, yy, 790, yy), fill=(*hex_to_rgb(spec.primary), 90), width=2)
        draw.line((832, 380, 886, 432), fill=accent, width=8)
    elif spec.name == "diet":
        draw.ellipse((650, 386, 778, 442), fill=(255, 255, 255, 170), outline=accent, width=3)
        draw.ellipse((680, 398, 748, 430), fill=(*hex_to_rgb(spec.accent), 70))
        draw.rounded_rectangle((812, 352, 858, 448), radius=18, fill=(255, 255, 255, 150), outline=primary, width=3)
        draw.line((828, 374, 844, 374), fill=primary, width=3)
    elif spec.name == "sleep":
        draw.arc((660, 360, 780, 462), 75, 285, fill=primary, width=10)
        for x, y, r in [(820, 374, 9), (858, 340, 6), (884, 398, 5)]:
            draw.ellipse((x - r, y - r, x + r, y + r), fill=accent)


def save_card(img: Image.Image, path: Path, radius: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    out = Image.new("RGBA", img.size, (255, 255, 255, 0))
    out.alpha_composite(img)
    out.putalpha(rounded_mask(img.size, radius))
    out.save(path, "WEBP", quality=92, method=6)


def make_pet_banner(spec: ModuleSpec) -> None:
    img = make_gradient((1200, 380), "#FFFFFF", spec.soft)
    add_paper_texture(img, 18)
    add_doodles(img, spec)
    draw = ImageDraw.Draw(img)
    add_ground(img, spec, 304, 110, 424)
    # The live pet image is rendered by Flutter from PetViewState.
    # This background only provides the illustrated world and reserved zones.
    # Right-side soft speech-card glow. The actual bubble remains Flutter-rendered.
    draw.rounded_rectangle((525, 86, 1020, 292), radius=54, fill=(255, 255, 255, 138))
    draw.polygon([(525, 176), (486, 194), (525, 212)], fill=(255, 255, 255, 138))
    save_card(img, OUT_ROOT / spec.name / "premium" / "pet_banner.webp", 34)


def make_hero_scene(spec: ModuleSpec) -> None:
    img = make_gradient((1200, 560), spec.soft, "#FFFFFF")
    tint = Image.new("RGBA", img.size, (*hex_to_rgb(spec.primary), 22))
    img.alpha_composite(tint)
    add_paper_texture(img, 26)
    add_doodles(img, spec)
    add_ground(img, spec, 448, 650, 1084)
    add_hero_props(img, spec)
    paste_contained(img, spec.pet, (720, 58, 1082, 450), alpha=1)
    # Quiet left-side light wash so Flutter title/button have a reserved zone.
    left_wash = Image.new("RGBA", img.size, (255, 255, 255, 0))
    wash_draw = ImageDraw.Draw(left_wash)
    wash_draw.rounded_rectangle((44, 58, 536, 444), radius=52, fill=(255, 255, 255, 86))
    left_wash = left_wash.filter(ImageFilter.GaussianBlur(12))
    img.alpha_composite(left_wash)
    save_card(img, OUT_ROOT / spec.name / "premium" / "hero_scene.webp", 38)


def main() -> None:
    for spec in MODULES:
        make_pet_banner(spec)
        make_hero_scene(spec)
        print(f"generated {spec.name}")


if __name__ == "__main__":
    main()
