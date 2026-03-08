#!/usr/bin/env python3
"""Create 1200×630 og-image.png for social sharing (WeChat, Twitter, etc.)"""
from PIL import Image, ImageDraw, ImageFont
import os

W, H = 1200, 630
BG = "#faf9f6"      # warm paper
ACCENT = "#2563eb"  # blue
TEXT = "#1c1917"    # dark
MUTED = "#57534e"   # gray

script_dir = os.path.dirname(os.path.abspath(__file__))
docs_dir = os.path.join(script_dir, "..", "docs")
icon_path = os.path.join(docs_dir, "icon.png")
out_path = os.path.join(docs_dir, "og-image.png")

img = Image.new("RGB", (W, H), BG)
draw = ImageDraw.Draw(img)

# Load and place icon (centered left third)
icon = Image.open(icon_path).convert("RGBA")
icon_size = 180
icon = icon.resize((icon_size, icon_size), Image.LANCZOS)
icon_x = 120
icon_y = (H - icon_size) // 2
img.paste(icon, (icon_x, icon_y), icon)

# Try system fonts, fallback to default
try:
    title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 72)
    tag_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 36)
except Exception:
    title_font = ImageFont.load_default()
    tag_font = ImageFont.load_default()

# App name
title = "Word Journal"
title_x = icon_x + icon_size + 80
title_y = H // 2 - 80
draw.text((title_x, title_y), title, fill=TEXT, font=title_font)

# Tagline
tagline = "Look up words instantly. Build your vocabulary."
tag_x = title_x
tag_y = title_y + 90
draw.text((tag_x, tag_y), tagline, fill=MUTED, font=tag_font)

# macOS badge
badge = "macOS 13+ · Free"
badge_y = H - 80
draw.text((title_x, badge_y), badge, fill=MUTED, font=tag_font)

img.save(out_path, "PNG", optimize=True)
print(f"Created {out_path} ({W}x{H})")
