#!/usr/bin/env python3
"""Audit Growth OS assets for optimization opportunities.

Scans the assets/ directory and reports:
1. Duplicate images (by SHA-256 hash)
2. PNGs > 300KB without alpha channel (WebP conversion candidates)
3. PNGs with alpha channel (must verify transparency compatibility)

Usage:
    python tool/audit_assets.py
"""

import hashlib
import os
import struct
import sys
from collections import defaultdict
from pathlib import Path

ASSETS_DIR = Path(__file__).resolve().parent.parent / "assets"
SIZE_THRESHOLD_KB = 300


def file_hash(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def png_has_alpha(path: Path) -> bool:
    """Check if a PNG file has an alpha channel by reading its IHDR chunk."""
    try:
        with open(path, "rb") as f:
            sig = f.read(8)
            if sig != b"\x89PNG\r\n\x1a\n":
                return False
            # Read IHDR chunk length and type
            _length = struct.unpack(">I", f.read(4))[0]
            chunk_type = f.read(4)
            if chunk_type != b"IHDR":
                return False
            _width = struct.unpack(">I", f.read(4))[0]
            _height = struct.unpack(">I", f.read(4))[0]
            bit_depth = struct.unpack(">B", f.read(1))[0]
            color_type = struct.unpack(">B", f.read(1))[0]
            # Color types with alpha:
            # 4 = Grayscale + Alpha
            # 6 = RGBA
            return color_type in (4, 6)
    except Exception:
        return False


def scan_assets():
    if not ASSETS_DIR.exists():
        print(f"Assets directory not found: {ASSETS_DIR}")
        sys.exit(1)

    png_files = []
    webp_files = []
    other_files = []

    for root, _dirs, files in os.walk(ASSETS_DIR):
        for fname in files:
            fpath = Path(root) / fname
            ext = fpath.suffix.lower()
            if ext == ".png":
                png_files.append(fpath)
            elif ext == ".webp":
                webp_files.append(fpath)
            else:
                other_files.append(fpath)

    print(f"=== Asset Audit Report ===\n")
    print(f"PNG files:  {len(png_files)}")
    print(f"WebP files: {len(webp_files)}")
    print(f"Other files: {len(other_files)}")
    print()

    # --- Duplicate detection ---
    hash_map = defaultdict(list)
    for f in png_files + webp_files:
        h = file_hash(f)
        hash_map[h].append(f)

    duplicates = {h: paths for h, paths in hash_map.items() if len(paths) > 1}
    if duplicates:
        print(f"--- Duplicate Images ({len(duplicates)} groups) ---")
        for h, paths in sorted(duplicates.items(), key=lambda x: -len(x[1])):
            print(f"\n  Hash: {h[:16]}...")
            for p in paths:
                size_kb = p.stat().st_size / 1024
                print(f"    {p.relative_to(ASSETS_DIR)} ({size_kb:.0f} KB)")
        print()
    else:
        print("--- No duplicate images found ---\n")

    # --- Large PNGs without alpha (WebP candidates) ---
    large_no_alpha = []
    large_with_alpha = []
    small_pngs = []

    for f in png_files:
        size_kb = f.stat().st_size / 1024
        has_alpha = png_has_alpha(f)
        if size_kb >= SIZE_THRESHOLD_KB:
            if has_alpha:
                large_with_alpha.append((f, size_kb))
            else:
                large_no_alpha.append((f, size_kb))
        else:
            small_pngs.append((f, size_kb, has_alpha))

    print(f"--- Large PNGs WITHOUT alpha (WebP candidates): {len(large_no_alpha)} ---")
    for f, size_kb in sorted(large_no_alpha, key=lambda x: -x[1]):
        print(f"  {size_kb:>8.0f} KB  {f.relative_to(ASSETS_DIR)}")
    if large_no_alpha:
        total = sum(s for _, s in large_no_alpha)
        print(f"\n  Total: {total:.0f} KB ({total/1024:.1f} MB)")

    print(f"\n--- Large PNGs WITH alpha (verify transparency): {len(large_with_alpha)} ---")
    for f, size_kb in sorted(large_with_alpha, key=lambda x: -x[1]):
        print(f"  {size_kb:>8.0f} KB  {f.relative_to(ASSETS_DIR)}")
    if large_with_alpha:
        total = sum(s for _, s in large_with_alpha)
        print(f"\n  Total: {total:.0f} KB ({total/1024:.1f} MB)")

    # --- Summary ---
    total_png_kb = sum(f.stat().st_size for f in png_files) / 1024
    total_webp_kb = sum(f.stat().st_size for f in webp_files) / 1024
    print(f"\n--- Summary ---")
    print(f"  PNG total:  {total_png_kb:.0f} KB ({total_png_kb/1024:.1f} MB)")
    print(f"  WebP total: {total_webp_kb:.0f} KB ({total_webp_kb/1024:.1f} MB)")
    if large_no_alpha:
        potential_savings = sum(s for _, s in large_no_alpha) * 0.7
        print(f"  Potential savings (WebP conversion): ~{potential_savings:.0f} KB ({potential_savings/1024:.1f} MB)")


if __name__ == "__main__":
    scan_assets()
