"""App Store header (3840x1646) and search-result image (1920x1280)."""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

D = os.path.dirname(os.path.abspath(__file__))
BG = (5, 8, 7)
GREEN = (57, 255, 20)
MUTED = (143, 209, 138)
AMBER = (255, 166, 26)
CYAN = (34, 230, 255)
PIX = os.path.join(D, 'PressStart2P.ttf')
VT = os.path.join(D, 'VT323.ttf')


def font(path, size):
    return ImageFont.truetype(path, size)


def raw(i):
    return Image.open(os.path.join(D, f'raw{i}.png')).convert('RGB')


def background(w, h, glow_box):
    im = Image.new('RGB', (w, h), BG)
    d = ImageDraw.Draw(im)
    step = max(32, w // 60)
    grid = tuple(int(c * 0.07 + b * 0.93) for c, b in zip(GREEN, BG))
    for x in range(0, w, step):
        d.line([(x, 0), (x, h)], fill=grid, width=2)
    for y in range(0, h, step):
        d.line([(0, y), (w, y)], fill=grid, width=2)
    glow = Image.new('RGB', (w, h), (0, 0, 0))
    ImageDraw.Draw(glow).ellipse(glow_box, fill=GREEN)
    glow = glow.filter(ImageFilter.GaussianBlur(w // 12))
    return Image.blend(im, glow, 0.14)


def glow_text(im, xy, text, fnt, color, anchor='lm', spread=20):
    layer = Image.new('RGBA', im.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).text(xy, text, font=fnt, fill=color + (255,), anchor=anchor)
    bloom = layer.filter(ImageFilter.GaussianBlur(spread))
    im.paste(bloom, (0, 0), bloom)
    im.paste(bloom, (0, 0), bloom)
    im.paste(layer, (0, 0), layer)


def rounded(img, radius):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *img.size], radius, fill=255)
    out = Image.new('RGBA', img.size)
    out.paste(img, (0, 0), mask)
    return out


def phone(im, shot, cx, top, width, accent, tilt=0):
    h = int(shot.height * width / shot.width)
    r = int(width * 0.085)
    s = rounded(shot.resize((width, h), Image.LANCZOS), r)
    pad = max(8, width // 55)
    frame = Image.new('RGBA', (width + pad * 2, h + pad * 2), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle(
        [0, 0, frame.width - 1, frame.height - 1], r + pad,
        fill=(14, 18, 16, 255), outline=accent + (255,), width=max(3, width // 200),
    )
    frame.paste(s, (pad, pad), s)
    if tilt:
        frame = frame.rotate(tilt, resample=Image.BICUBIC, expand=True)
    x = cx - frame.width // 2
    glow = Image.new('RGBA', im.size, (0, 0, 0, 0))
    tint = Image.new('RGBA', frame.size, accent + (255,))
    tint.putalpha(frame.split()[3].point(lambda a: 140 if a else 0))
    glow.paste(tint, (x, top), tint)
    glow = glow.filter(ImageFilter.GaussianBlur(width // 12))
    im.paste(glow, (0, 0), glow)
    im.paste(frame, (x, top), frame)


def pixel_grid(im, x0, y0, cell, gap, pattern):
    for r, row in enumerate(pattern):
        for c, on in enumerate(row):
            x, y = x0 + c * (cell + gap), y0 + r * (cell + gap)
            if on == '1':
                g = Image.new('RGBA', im.size, (0, 0, 0, 0))
                ImageDraw.Draw(g).rectangle([x, y, x + cell, y + cell], fill=GREEN + (150,))
                g = g.filter(ImageFilter.GaussianBlur(cell // 5))
                im.paste(g, (0, 0), g)
            ImageDraw.Draw(im).rectangle(
                [x, y, x + cell, y + cell], fill=GREEN if on == '1' else (20, 40, 18)
            )


PATTERN = ['110111110111', '011101110111', '111110111101', '101111101111', '111111011101']

out = os.path.join(D, 'out', 'banners')
os.makedirs(out, exist_ok=True)

# Header 3840x1646: words left, phones right. The middle 2/3 carries the
# message, in case the edges are cropped on smaller screens.
W, H = 3840, 1646
im = background(W, H, [W * 0.45, -H * 0.2, W * 1.1, H * 1.2])
glow_text(im, (300, 460), 'PROTEIN', font(PIX, 170), GREEN)
glow_text(im, (300, 680), 'GRID', font(PIX, 170), GREEN)
d = ImageDraw.Draw(im)
for i, line in enumerate(['Your year of protein,', 'one square a day.']):
    d.text((306, 880 + i * 110), line, font=font(VT, 120), fill=MUTED, anchor='lm')
pixel_grid(im, 306, 1120, 52, 14, PATTERN)
phone(im, raw(5), 2420, 260, 560, CYAN, tilt=5)
phone(im, raw(2), 2960, 130, 620, GREEN)
phone(im, raw(4), 3460, 260, 560, AMBER, tilt=-5)
im.save(os.path.join(out, 'header_3840x1646.png'), optimize=True)

# Search result 1920x1280: the Grid front and centre, with the promise.
W, H = 1920, 1280
im = background(W, H, [W * 0.35, -H * 0.1, W * 1.05, H * 1.1])
glow_text(im, (120, 260), 'YOUR YEAR,', font(PIX, 86), GREEN)
glow_text(im, (120, 390), 'ONE GRID', font(PIX, 86), GREEN)
d = ImageDraw.Draw(im)
for i, line in enumerate(['One tap to log protein.', 'Hit your goal, light up the day.']):
    d.text((126, 520 + i * 70), line, font=font(VT, 62), fill=MUTED, anchor='lm')
pixel_grid(im, 126, 700, 54, 12, PATTERN)
glow_text(im, (126, 1110), 'NO ACCOUNT · NO ADS', font(VT, 58), AMBER, spread=10)
phone(im, raw(2), 1480, 90, 520, GREEN)
im.save(os.path.join(out, 'search_1920x1280.png'), optimize=True)
print('done')
