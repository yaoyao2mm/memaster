from __future__ import annotations

from html import escape
from pathlib import Path


PALETTES = {
    "pet": ("#FFE4BF", "#F4B77A", "#67452B"),
    "travel": ("#D7F5EC", "#8AD8C6", "#1F4E57"),
    "daily": ("#F9DDE8", "#F2A9C1", "#603448"),
    "document": ("#E8EEF8", "#C1D0E8", "#324357"),
    "video": ("#DCE7FF", "#8EA7FF", "#1F2B5A"),
    "food": ("#FFECC9", "#F6C46B", "#6C461F"),
}


class Thumbnailer:
    def __init__(self, thumbnails_dir: Path):
        self._thumbnails_dir = thumbnails_dir

    def ensure_thumbnail(self, *, asset_id: str, label: str, subtitle: str, album_type: str) -> str:
        file_name = f"{asset_id}.svg"
        target = self._thumbnails_dir / file_name
        if not target.exists():
            start, end, ink = PALETTES.get(album_type, PALETTES["daily"])
            svg = f"""<svg width="320" height="240" viewBox="0 0 320 240" fill="none" xmlns="http://www.w3.org/2000/svg">
<defs>
  <linearGradient id="g" x1="0" y1="0" x2="320" y2="240" gradientUnits="userSpaceOnUse">
    <stop stop-color="{start}"/>
    <stop offset="1" stop-color="{end}"/>
  </linearGradient>
</defs>
<rect width="320" height="240" rx="28" fill="url(#g)"/>
<circle cx="258" cy="52" r="44" fill="white" fill-opacity="0.34"/>
<circle cx="66" cy="188" r="58" fill="white" fill-opacity="0.20"/>
<rect x="24" y="24" width="92" height="34" rx="17" fill="white" fill-opacity="0.55"/>
<text x="40" y="46" fill="{ink}" font-size="16" font-family="Arial, sans-serif" font-weight="700">{escape(album_type.upper())}</text>
<text x="24" y="162" fill="{ink}" font-size="28" font-family="Arial, sans-serif" font-weight="700">{escape(label[:18])}</text>
<text x="24" y="190" fill="{ink}" fill-opacity="0.76" font-size="15" font-family="Arial, sans-serif">{escape(subtitle[:28])}</text>
</svg>"""
            target.write_text(svg, encoding="utf-8")
        return file_name
