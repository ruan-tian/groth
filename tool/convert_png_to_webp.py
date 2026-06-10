"""Convert alpha PNGs to WebP in batches.

Usage:
    python tool/convert_png_to_webp.py [directory]

If no directory specified, converts all RGBA PNGs > 300KB in assets/.
"""

import sys
import os
from pathlib import Path
from PIL import Image

ASSETS_DIR = Path(__file__).resolve().parent.parent / "assets"
QUALITY = 85
METHOD = 6  # best compression
SIZE_THRESHOLD_KB = 300


def convert_png_to_webp(png_path: Path) -> tuple[int, int] | None:
    """Convert a single PNG to WebP. Returns (old_size, new_size) or None if skipped."""
    try:
        img = Image.open(png_path)
        if img.mode not in ("RGBA", "LA", "PA"):
            return None

        size_old = png_path.stat().st_size
        if size_old < SIZE_THRESHOLD_KB * 1024:
            return None

        webp_path = png_path.with_suffix(".webp")
        img.save(webp_path, "WEBP", quality=QUALITY, method=METHOD)

        size_new = webp_path.stat().st_size

        # Only keep WebP if it's actually smaller
        if size_new >= size_old:
            webp_path.unlink()
            return None

        # Delete original PNG
        png_path.unlink()

        return (size_old, size_new)
    except Exception as e:
        print(f"  ERROR: {png_path.name}: {e}")
        return None


def convert_directory(directory: Path) -> list[tuple[str, int, int]]:
    """Convert all eligible PNGs in a directory. Returns list of (filename, old_kb, new_kb)."""
    results = []
    png_files = sorted(directory.glob("*.png"))

    for png in png_files:
        result = convert_png_to_webp(png)
        if result:
            old_kb = result[0] // 1024
            new_kb = result[1] // 1024
            savings = (1 - result[1] / result[0]) * 100
            print(f"  {png.name}: {old_kb} KB -> {new_kb} KB (-{savings:.0f}%)")
            results.append((png.name, old_kb, new_kb))

    return results


def main():
    if len(sys.argv) > 1:
        target = Path(sys.argv[1])
        if not target.is_absolute():
            target = ASSETS_DIR / target
    else:
        target = ASSETS_DIR

    if not target.exists():
        print(f"Directory not found: {target}")
        sys.exit(1)

    if target.is_file():
        result = convert_png_to_webp(target)
        if result:
            old_kb = result[0] // 1024
            new_kb = result[1] // 1024
            savings = (1 - result[1] / result[0]) * 100
            print(f"{target.name}: {old_kb} KB -> {new_kb} KB (-{savings:.0f}%)")
        else:
            print(f"Skipped: {target}")
        return

    print(f"=== Converting alpha PNGs in {target.relative_to(ASSETS_DIR.parent)} ===\n")

    total_old = 0
    total_new = 0
    count = 0

    if target.is_dir():
        # Check if this directory has PNGs directly
        direct_pngs = list(target.glob("*.png"))
        if direct_pngs:
            results = convert_directory(target)
            for name, old_kb, new_kb in results:
                total_old += old_kb
                total_new += new_kb
                count += 1

        # Also check subdirectories
        for subdir in sorted(target.iterdir()):
            if subdir.is_dir():
                results = convert_directory(subdir)
                if results:
                    print(f"\n  [{subdir.name}] {len(results)} files")
                for name, old_kb, new_kb in results:
                    total_old += old_kb
                    total_new += new_kb
                    count += 1

    print(f"\n=== Summary ===")
    print(f"  Files converted: {count}")
    print(f"  Before: {total_old:,} KB ({total_old/1024:.1f} MB)")
    print(f"  After:  {total_new:,} KB ({total_new/1024:.1f} MB)")
    if total_old > 0:
        savings = (1 - total_new / total_old) * 100
        print(f"  Saved:  {total_old - total_new:,} KB ({savings:.0f}%)")


if __name__ == "__main__":
    main()
