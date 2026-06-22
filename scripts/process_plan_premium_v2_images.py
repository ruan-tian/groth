"""Compose premium v2 plan cards from the local illustration library.

The output images are card backgrounds only. Flutter still owns all Chinese
copy, buttons, pet state, and accessibility. The composition intentionally uses
fewer props than the raw library contains: every module gets a clean left text
zone, one contained hero illustration on the right, and only edge decorations.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps

try:
    from scipy import ndimage
except Exception:  # pragma: no cover - local script fallback.
    ndimage = None


ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "growth_os"
PICTURE = ROOT / "picture"
PART = PICTURE / "part"
NEW = PART / "日记" / "新版"
OUT_ROOT = APP / "assets" / "images" / "plan_modules"


Box = tuple[int, int, int, int]
Crop = tuple[float, float, float, float]


@dataclass(frozen=True)
class Decoration:
    path: Path
    box: Box
    alpha: float = 1.0
    behind: bool = False


@dataclass(frozen=True)
class ModuleSpec:
    name: str
    primary: str
    soft: str
    hero_art: Path
    hero_box: Box
    hero_crop: Crop | None = None
    hero_cutout: bool = False
    hero_flip: bool = False
    banner_decorations: tuple[Decoration, ...] = ()
    hero_decorations: tuple[Decoration, ...] = ()


MODULES = [
    ModuleSpec(
        name="study",
        primary="#5D68F2",
        soft="#F0F3FF",
        hero_art=NEW / "学习定时器1.png",
        hero_crop=(0.42, 0.02, 1.0, 0.98),
        hero_box=(570, 34, 1162, 522),
        banner_decorations=(
            Decoration(PART / "开的可爱书本.png", (46, 248, 178, 350), 0.32),
            Decoration(PART / "台灯.png", (976, 46, 1110, 178), 0.18, True),
        ),
        hero_decorations=(
            Decoration(PART / "可爱铅笔.png", (500, 396, 602, 500), 0.24),
            Decoration(PART / "盆栽草.png", (1062, 344, 1170, 510), 0.22, True),
        ),
    ),
    ModuleSpec(
        name="fitness",
        primary="#FF7A2F",
        soft="#FFF0E4",
        hero_art=PART / "健身页面的开始训练图.png",
        hero_box=(594, 28, 1152, 520),
        hero_cutout=True,
        banner_decorations=(
            Decoration(PART / "矮草和花.png", (42, 254, 168, 354), 0.32),
            Decoration(PART / "水壶.png", (1000, 210, 1138, 350), 0.22),
        ),
        hero_decorations=(
            Decoration(PART / "卷起来的瑜伽垫.png", (590, 414, 820, 520), 0.22, True),
            Decoration(PART / "两个小哑铃.png", (1012, 394, 1138, 514), 0.28),
        ),
    ),
    ModuleSpec(
        name="journal",
        primary="#FF7EAA",
        soft="#FFF0F6",
        hero_art=PICTURE / "journal_writing.png",
        hero_box=(676, 50, 1120, 520),
        hero_cutout=True,
        banner_decorations=(
            Decoration(PART / "粉玫瑰.png", (42, 238, 162, 352), 0.24),
            Decoration(PART / "可爱书签.png", (1006, 54, 1088, 156), 0.22),
        ),
        hero_decorations=(
            Decoration(PART / "可爱笔记本.png", (534, 372, 672, 512), 0.30),
            Decoration(PART / "粉色的花.png", (1068, 350, 1170, 510), 0.22, True),
        ),
    ),
    ModuleSpec(
        name="diet",
        primary="#F59E0B",
        soft="#FFF8D7",
        hero_art=NEW / "喝水定时1.png",
        hero_crop=(0.42, 0.02, 1.0, 0.98),
        hero_box=(568, 30, 1164, 524),
        banner_decorations=(
            Decoration(PART / "可爱点心.png", (44, 246, 178, 354), 0.28),
            Decoration(PART / "微笑的花.png", (1004, 54, 1130, 178), 0.20, True),
        ),
        hero_decorations=(
            Decoration(PART / "提壶.png", (1040, 372, 1166, 512), 0.24),
            Decoration(PART / "三叶草丛.png", (516, 410, 650, 520), 0.20, True),
        ),
    ),
    ModuleSpec(
        name="sleep",
        primary="#8B5CF6",
        soft="#F5F0FF",
        hero_art=NEW / "睡觉定时器.png",
        hero_crop=(0.40, 0.00, 1.0, 1.0),
        hero_box=(604, 28, 1168, 520),
        banner_decorations=(
            Decoration(PART / "蜡烛.png", (58, 246, 150, 352), 0.30),
            Decoration(PART / "粉色闹钟.png", (1004, 214, 1138, 350), 0.20),
        ),
        hero_decorations=(
            Decoration(PART / "眼罩.png", (542, 404, 662, 500), 0.22),
            Decoration(PART / "可爱枕头.png", (1036, 372, 1164, 510), 0.22, True),
        ),
    ),
]


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def load_rgba(path: Path) -> Image.Image:
    if not path.exists():
        raise FileNotFoundError(path)
    return Image.open(path).convert("RGBA")


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def make_gradient(size: tuple[int, int], left: str, right: str) -> Image.Image:
    w, h = size
    l = np.array(hex_to_rgb(left), dtype=np.float32)
    r = np.array(hex_to_rgb(right), dtype=np.float32)
    t = np.linspace(0.0, 1.0, w, dtype=np.float32)
    colors = (l[None, :] * (1.0 - t[:, None]) + r[None, :] * t[:, None]).astype(
        np.uint8
    )
    arr = np.zeros((h, w, 4), dtype=np.uint8)
    arr[:, :, :3] = colors[None, :, :]
    arr[:, :, 3] = 255
    return Image.fromarray(arr, "RGBA")


def add_paper_texture(img: Image.Image, opacity: int = 12) -> None:
    layer = Image.new("RGBA", img.size, (255, 255, 255, 0))
    draw = ImageDraw.Draw(layer)
    w, h = img.size
    for y in range(0, h, 8):
        draw.line((0, y, w, y), fill=(255, 255, 255, opacity))
    for x in range(0, w, 13):
        draw.line((x, 0, x, h), fill=(126, 90, 64, max(1, opacity // 7)))
    img.alpha_composite(layer)


def remove_edge_checkerboard(img: Image.Image) -> Image.Image:
    """Remove only light checkerboard pixels connected to the image edge."""
    rgba = img.convert("RGBA")
    arr = np.array(rgba)
    rgb = arr[:, :, :3].astype(np.int16)
    mx = rgb.max(axis=2)
    mn = rgb.min(axis=2)
    candidate = (mn >= 214) & ((mx - mn) <= 30)

    border_ratio = np.mean(
        np.concatenate(
            [candidate[0, :], candidate[-1, :], candidate[:, 0], candidate[:, -1]]
        )
    )
    if border_ratio < 0.35:
        return rgba

    if ndimage is not None:
        seed = np.zeros(candidate.shape, dtype=bool)
        seed[0, :] = candidate[0, :]
        seed[-1, :] = candidate[-1, :]
        seed[:, 0] = candidate[:, 0]
        seed[:, -1] = candidate[:, -1]
        background = ndimage.binary_propagation(seed, mask=candidate)
        soft = ndimage.gaussian_filter(background.astype(np.float32), sigma=0.65)
        arr[:, :, 3] = (arr[:, :, 3].astype(np.float32) * (1.0 - soft)).astype(
            np.uint8
        )
    else:
        alpha = Image.fromarray((~candidate).astype(np.uint8) * 255, "L")
        alpha = alpha.filter(ImageFilter.GaussianBlur(0.65))
        arr[:, :, 3] = np.minimum(arr[:, :, 3], np.array(alpha))
    return Image.fromarray(arr, "RGBA")


def crop_ratio(img: Image.Image, crop: Crop | None) -> Image.Image:
    if crop is None:
        return img
    left, top, right, bottom = crop
    return img.crop(
        (
            round(img.width * left),
            round(img.height * top),
            round(img.width * right),
            round(img.height * bottom),
        )
    )


def crop_to_content(img: Image.Image, padding: int = 18) -> Image.Image:
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


def soft_edge_panel(img: Image.Image, radius: int = 46, blur: int = 8) -> Image.Image:
    panel = img.convert("RGBA")
    mask = Image.new("L", panel.size, 0)
    draw = ImageDraw.Draw(mask)
    inset = blur + 2
    draw.rounded_rectangle(
        (inset, inset, panel.width - inset, panel.height - inset),
        radius=radius,
        fill=255,
    )
    mask = mask.filter(ImageFilter.GaussianBlur(blur))
    panel.putalpha(ImageChops.multiply(panel.getchannel("A"), mask))
    return panel


def protected_cutout_from_image(
    source: Image.Image,
    outline: int = 9,
    shadow: int = 16,
    padding: int = 18,
) -> Image.Image:
    cutout = crop_to_content(remove_edge_checkerboard(source), padding=padding)
    alpha = cutout.getchannel("A")
    outline_alpha = alpha.filter(ImageFilter.MaxFilter(outline * 2 + 1))
    outline_alpha = outline_alpha.filter(ImageFilter.GaussianBlur(0.8))

    canvas = Image.new(
        "RGBA",
        (cutout.width + shadow * 2, cutout.height + shadow * 2),
        (255, 255, 255, 0),
    )

    shadow_alpha = outline_alpha.filter(ImageFilter.GaussianBlur(shadow * 0.55))
    shadow_layer = Image.new("RGBA", cutout.size, (92, 64, 42, 90))
    shadow_layer.putalpha(shadow_alpha.point(lambda p: round(p * 0.34)))
    canvas.alpha_composite(shadow_layer, (shadow, shadow + 8))

    outline_layer = Image.new("RGBA", cutout.size, (255, 255, 255, 245))
    outline_layer.putalpha(outline_alpha)
    canvas.alpha_composite(outline_layer, (shadow, shadow))
    canvas.alpha_composite(cutout, (shadow, shadow))
    return canvas


def protected_cutout(path: Path, outline: int = 7, shadow: int = 12) -> Image.Image:
    return protected_cutout_from_image(load_rgba(path), outline=outline, shadow=shadow)


def fit_contain(img: Image.Image, box: Box) -> Image.Image:
    max_w = box[2] - box[0]
    max_h = box[3] - box[1]
    scale = min(max_w / img.width, max_h / img.height)
    return img.resize(
        (max(1, round(img.width * scale)), max(1, round(img.height * scale))),
        Image.Resampling.LANCZOS,
    )


def paste_in_box(
    base: Image.Image,
    img: Image.Image,
    box: Box,
    alpha: float = 1.0,
    align: tuple[float, float] = (0.5, 0.5),
) -> None:
    item = fit_contain(img, box)
    if alpha < 1.0:
        item = item.copy()
        item.putalpha(item.getchannel("A").point(lambda p: round(p * alpha)))
    x = box[0] + round((box[2] - box[0] - item.width) * align[0])
    y = box[1] + round((box[3] - box[1] - item.height) * align[1])
    base.alpha_composite(item, (x, y))


def add_star(draw: ImageDraw.ImageDraw, x: int, y: int, size: int, color) -> None:
    draw.line((x - size, y, x + size, y), fill=color, width=3)
    draw.line((x, y - size, x, y + size), fill=color, width=3)
    draw.line((x - size // 2, y - size // 2, x + size // 2, y + size // 2), fill=color, width=2)
    draw.line((x - size // 2, y + size // 2, x + size // 2, y - size // 2), fill=color, width=2)


def add_background_shapes(img: Image.Image, spec: ModuleSpec, hero: bool) -> None:
    layer = Image.new("RGBA", img.size, (255, 255, 255, 0))
    draw = ImageDraw.Draw(layer, "RGBA")
    primary = hex_to_rgb(spec.primary)
    soft = hex_to_rgb(spec.soft)
    w, h = img.size

    draw.ellipse((w * 0.50, -h * 0.18, w * 1.16, h * 1.18), fill=(*soft, 130))
    draw.ellipse((w * 0.64, h * 0.08, w * 1.06, h * 1.12), fill=(*primary, 22))
    draw.rounded_rectangle(
        (22, 24, w - 22, h - 24),
        radius=38 if hero else 34,
        outline=(*primary, 26),
        width=3,
    )

    if hero:
        draw.rounded_rectangle((34, 40, 540, 506), radius=44, fill=(255, 255, 255, 84))
        draw.line((62, h - 54, 494, h - 54), fill=(*primary, 26), width=4)
        for x, y, size in [(82, 78, 13), (505, 120, 8), (1114, 82, 12)]:
            add_star(draw, x, y, size, (*primary, 62))
    else:
        draw.rounded_rectangle((514, 60, 1052, 320), radius=58, fill=(255, 255, 255, 110))
        draw.ellipse((42, 62, 232, 318), fill=(255, 255, 255, 118))
        draw.ellipse((62, 94, 212, 292), outline=(*primary, 22), width=4)
        for x, y, size in [(86, 62, 10), (1084, 72, 12), (1112, 304, 8)]:
            add_star(draw, x, y, size, (*primary, 58))
    img.alpha_composite(layer)


def prepare_hero_art(spec: ModuleSpec) -> Image.Image:
    art = crop_ratio(load_rgba(spec.hero_art), spec.hero_crop)
    if spec.hero_flip:
        art = ImageOps.mirror(art)
    if spec.hero_cutout:
        return protected_cutout_from_image(art, outline=10, shadow=18, padding=22)
    return soft_edge_panel(art, radius=50, blur=10)


def add_decorations(
    scene: Image.Image,
    decorations: tuple[Decoration, ...],
    behind: bool,
) -> None:
    for decoration in decorations:
        if decoration.behind != behind or not decoration.path.exists():
            continue
        item = protected_cutout(decoration.path, outline=5, shadow=9)
        paste_in_box(scene, item, decoration.box, decoration.alpha, align=(0.5, 0.92))


def add_card_polish(img: Image.Image, spec: ModuleSpec, radius: int) -> None:
    layer = Image.new("RGBA", img.size, (255, 255, 255, 0))
    draw = ImageDraw.Draw(layer, "RGBA")
    w, h = img.size
    primary = hex_to_rgb(spec.primary)
    draw.rounded_rectangle(
        (1, 1, w - 2, h - 2),
        radius=radius,
        outline=(*primary, 34),
        width=3,
    )
    draw.rounded_rectangle((0, 0, w, h), radius=radius, fill=(255, 255, 255, 16))
    img.alpha_composite(layer)


def save_webp_card(img: Image.Image, path: Path, radius: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    out = Image.new("RGBA", img.size, (255, 255, 255, 0))
    out.alpha_composite(img)
    out.putalpha(rounded_mask(out.size, radius))
    out.save(path, "WEBP", quality=95, method=6)


def build_banner(spec: ModuleSpec) -> None:
    scene = make_gradient((1200, 380), "#FFFEFB", spec.soft)
    add_paper_texture(scene)
    add_background_shapes(scene, spec, hero=False)
    add_decorations(scene, spec.banner_decorations, behind=True)
    add_decorations(scene, spec.banner_decorations, behind=False)
    add_card_polish(scene, spec, radius=34)
    save_webp_card(scene, OUT_ROOT / spec.name / "premium_v2" / "pet_banner.webp", 34)


def build_hero(spec: ModuleSpec) -> None:
    scene = make_gradient((1200, 560), "#FFFEFA", spec.soft)
    add_paper_texture(scene)
    add_background_shapes(scene, spec, hero=True)
    add_decorations(scene, spec.hero_decorations, behind=True)
    paste_in_box(scene, prepare_hero_art(spec), spec.hero_box, alpha=0.98, align=(0.55, 0.92))
    add_decorations(scene, spec.hero_decorations, behind=False)
    add_card_polish(scene, spec, radius=38)
    save_webp_card(scene, OUT_ROOT / spec.name / "premium_v2" / "hero_scene.webp", 38)


def main() -> None:
    for spec in MODULES:
        build_banner(spec)
        build_hero(spec)
        print(f"generated premium_v2 {spec.name}")


if __name__ == "__main__":
    main()
