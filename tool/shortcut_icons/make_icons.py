"""Renders the home-screen shortcut icons from Flutter's Material Icons font
into the iOS asset catalog and Android drawables. Run from the repo root:
    python3 tool/shortcut_icons/make_icons.py
The keys must match kShortcutIcons in lib/data/presets.dart."""
import json
import os
import subprocess
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
flutter_root = json.loads(
    subprocess.check_output(['flutter', '--version', '--machine'], stderr=subprocess.DEVNULL)
)['flutterRoot']
FONT = os.path.join(flutter_root, 'bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')

# key -> Material Icons codepoint (Flutter's Icons.*). egg/shake/chicken/plus
# already exist (hand-made iOS PNGs, Android vectors) and aren't regenerated.
ICONS = {
    'pg_fish': 0xe57e,      # set_meal
    'pg_kebab': 0xf052a,    # kebab_dining
    'pg_dessert': 0xe331,   # icecream
    'pg_bowl': 0xe506,      # ramen_dining
    'pg_burger': 0xe3c2,    # lunch_dining
    'pg_coffee': 0xe178,    # coffee
    'pg_cookie': 0xf04d9,   # cookie
    'pg_gym': 0xe28d,       # fitness_center
    'pg_bolt': 0xe0ee,      # bolt
}
GREEN = (57, 255, 20, 255)


def glyph(cp, px, color):
    """The icon centred in a px*px square, filling about 85% of it."""
    im = Image.new('RGBA', (px, px), (0, 0, 0, 0))
    f = ImageFont.truetype(FONT, int(px * 0.85))
    d = ImageDraw.Draw(im)
    l, t, r, b = d.textbbox((0, 0), chr(cp), font=f)
    d.text(((px - (r - l)) / 2 - l, (px - (b - t)) / 2 - t), chr(cp), font=f, fill=color)
    return im


for key, cp in ICONS.items():
    # iOS: template images (the system tints shortcut icons), 35pt.
    folder = os.path.join(ROOT, 'ios/Runner/Assets.xcassets', f'{key}.imageset')
    os.makedirs(folder, exist_ok=True)
    images = []
    for scale in (1, 2, 3):
        name = f'{key}@{scale}x.png'
        glyph(cp, 35 * scale, (0, 0, 0, 255)).save(os.path.join(folder, name))
        images.append({'filename': name, 'idiom': 'universal', 'scale': f'{scale}x'})
    with open(os.path.join(folder, 'Contents.json'), 'w') as fh:
        json.dump({
            'images': images,
            'info': {'author': 'xcode', 'version': 1},
            'properties': {'template-rendering-intent': 'template'},
        }, fh, indent=2)

    # Android: neon green PNGs per density, 24dp.
    for dpi, px in (('mdpi', 24), ('hdpi', 36), ('xhdpi', 48), ('xxhdpi', 72), ('xxxhdpi', 96)):
        out = os.path.join(ROOT, 'android/app/src/main/res', f'drawable-{dpi}')
        os.makedirs(out, exist_ok=True)
        glyph(cp, px, GREEN).save(os.path.join(out, f'{key}.png'))

print('rendered', len(ICONS), 'icons')
