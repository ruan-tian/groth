"""Weather image batch processor 鈥?rembg + resize + organize."""

import os
from pathlib import Path

from PIL import Image
from rembg import remove

# 鈹€鈹€ Config 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

SRC = Path(r"F:\opencode\GROS\picture\weather")
DST = Path(r"F:\opencode\GROS\growth_os\assets\images\weather")

# 鈹€鈹€ Processing rules: (subdir, remove_bg, size, format, suffix)
# suffix: if set, replaces original extension; None keeps original concept

RULES = {
    # 鈹€鈹€鈹€ cats 鈹€鈹€鈹€
    "cat": (DST / "cats", True, (768, 768), "PNG"),
    # 鈹€鈹€鈹€ backgrounds 鈹€鈹€鈹€
    "bg_": (DST / "backgrounds", False, (1200, 600), "WEBP"),
    # 鈹€鈹€鈹€ foregrounds 鈹€鈹€鈹€
    "fg_": (DST / "foregrounds", True, (1200, 600), "WEBP"),
    # 鈹€鈹€鈹€ particles 鈹€鈹€鈹€
    "particle_": (DST / "particles", True, (128, 128), "PNG"),
    # 鈹€鈹€鈹€ lights 鈹€鈹€鈹€
    "light_": (DST / "lights", False, (512, 512), "WEBP"),
    "sun_glow": (DST / "lights", False, (512, 512), "WEBP"),
    # 鈹€鈹€鈹€ props 鈹€鈹€鈹€
    "prop_": (DST / "props", True, (512, 512), "PNG"),
    # 鈹€鈹€鈹€ common / icons 鈹€鈹€鈹€
    "bubble_tail": (DST / "common", True, (256, 128), "PNG"),
    "chip_glow": (DST / "common", False, (800, 200), "WEBP"),
    "deco_": (DST / "common", True, (128, 128), "PNG"),
    "icon_": (DST / "common", False, (64, 64), "PNG"),
    "highlight_overlay": (DST / "common", False, (1200, 600), "WEBP"),
    "glass_noise_overlay": (DST / "common", False, (1200, 600), "WEBP"),
    "soft_shadow_mask": (DST / "common", False, (512, 512), "WEBP"),
}


def match_rule(name: str):
    """Return (dest_dir, remove_bg, size, fmt) for filename stem."""
    base = Path(name).stem.lower()
    for prefix, rule in RULES.items():
        if base.startswith(prefix):
            return rule
    return None


def crop_to_content(img: Image.Image, pad: int = 4) -> Image.Image:
    """Crop transparent PNG to visible content."""
    if img.mode != "RGBA":
        return img
    alpha = img.split()[-1]
    bbox = alpha.getbbox()
    if bbox is None:
        return img
    l, t, r, b = bbox
    l = max(0, l - pad)
    t = max(0, t - pad)
    r = min(img.width, r + pad)
    b = min(img.height, b + pad)
    return img.crop((l, t, r, b))


def fit_inside(img: Image.Image, target: tuple[int, int]) -> Image.Image:
    """Scale image to fit inside target, centered on transparent canvas."""
    tw, th = target
    iw, ih = img.size
    scale = min(tw / iw, th / ih)
    nw, nh = int(iw * scale), int(ih * scale)
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    ox, oy = (tw - nw) // 2, (th - nh) // 2
    canvas.paste(resized, (ox, oy), resized if resized.mode == "RGBA" else None)
    return canvas


def process_one(path: Path) -> bool:
    rule = match_rule(path.name)
    if rule is None:
        print(f"  SKIP (no rule): {path.name}")
        return False

    dest_dir, remove_bg, size, fmt = rule

    try:
        img = Image.open(path).convert("RGBA")

        if remove_bg:
            try:
                result = remove(img)
                img = result[0] if isinstance(result, tuple) else result
                if img.getbbox():
                    img = crop_to_content(img)
            except Exception as e:
                print(f"    (rembg skipped: {e})")

        img = fit_inside(img, size)
        out_name = f"{Path(path.name).stem}.{fmt.lower()}"
        out_path = dest_dir / out_name
        img.save(out_path, format=fmt)

        kb = out_path.stat().st_size / 1024
        print(f"  OK  {out_name}  ({int(kb)} KB)")
        return True
    except Exception as e:
        print(f"  鉁? {path.name}: {e}")
        return False


def main():
    files = sorted(SRC.glob("*.*"))
    files = [f for f in files if f.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}]
    print(f"Found {len(files)} images\n")

    ok = 0
    for f in files:
        if process_one(f):
            ok += 1

    print(f"\nDone: {ok}/{len(files)} processed")


if __name__ == "__main__":
    main()
