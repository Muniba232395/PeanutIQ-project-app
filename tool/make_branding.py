#!/usr/bin/env python3
"""Draws the app icon and splash logo from the Lucide bean + leaf glyphs (the website's Logo).
Needs Pillow and the lucide_icons_flutter package in the pub cache. Output: assets/branding/."""
import glob
import os
from PIL import Image, ImageDraw, ImageFont

FONT = sorted(glob.glob(os.path.expanduser('~/.pub-cache/hosted/pub.dev/lucide_icons_flutter-*/assets/lucide.ttf')))[-1]
BEAN, LEAF = chr(58255), chr(58078)
FOREST = (7, 87, 28, 255)
LIME = (163, 217, 119, 255)
WHITE = (255, 255, 255, 255)


def glyph(ch, size, color, stroke):
    font = ImageFont.truetype(FONT, size)
    img = Image.new('RGBA', (size * 2, size * 2), (0, 0, 0, 0))
    ImageDraw.Draw(img).text((size // 2, size // 2), ch, font=font, fill=color, stroke_width=stroke, stroke_fill=color)
    return img.crop(img.getbbox())


def logo(total, bean_color, leaf_color, fill):
    """Bean with a small leaf at its top-right; the pair fills `fill` of the canvas, centred."""
    bean = glyph(BEAN, 600, bean_color, 7)
    leaf = glyph(LEAF, 330, leaf_color, 5).rotate(12, expand=True, resample=Image.BICUBIC)
    lx, ly = bean.width - int(leaf.width * 0.62), -int(leaf.height * 0.38)
    ox, oy = max(0, -lx), max(0, -ly)
    pair = Image.new('RGBA', (max(bean.width, lx + leaf.width) + ox, max(bean.height, ly + leaf.height) + oy), (0, 0, 0, 0))
    pair.alpha_composite(bean, (ox, oy))
    pair.alpha_composite(leaf, (lx + ox, ly + oy))
    pair = pair.crop(pair.getbbox())
    scale = total * fill / max(pair.size)
    pair = pair.resize((int(pair.width * scale), int(pair.height * scale)), Image.LANCZOS)
    canvas = Image.new('RGBA', (total, total), (0, 0, 0, 0))
    canvas.alpha_composite(pair, ((total - pair.width) // 2, (total - pair.height) // 2))
    return canvas


os.makedirs('assets/branding', exist_ok=True)
icon = Image.new('RGBA', (1024, 1024), FOREST)
icon.alpha_composite(logo(1024, WHITE, LIME, 0.68))
icon.save('assets/branding/icon.png')
logo(1024, WHITE, LIME, 0.5).save('assets/branding/icon_foreground.png')  # adaptive safe zone
logo(768, FOREST, FOREST, 0.6).save('assets/branding/splash_logo.png')
# Android 12+ masks the splash icon to a circle 2/3 of its size, so keep the logo inside it.
logo(1152, FOREST, FOREST, 0.42).save('assets/branding/splash_logo_android12.png')
print('assets/branding written')
