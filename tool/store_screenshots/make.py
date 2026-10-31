"""Protein Grid App Store screenshots (6.9" 1320x2868 + 6.5" 1284x2778)."""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

D = os.path.dirname(os.path.abspath(__file__))
W, H = 1320, 2868
BG = (5, 8, 7)
GREEN = (57, 255, 20)
MUTED = (143, 209, 138)
AMBER = (255, 166, 26)
MAGENTA = (255, 59, 213)
CYAN = (34, 230, 255)

PIX = os.path.join(D, 'PressStart2P.ttf')
VT = os.path.join(D, 'VT323.ttf')


def font(path, size):
    return ImageFont.truetype(path, size)


def raw(i):
    return Image.open(os.path.join(D, f'raw{i}.png')).convert('RGB')


def background(accent):
    """Near-black with a faint pixel grid and a soft glow behind the phone."""
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    step = 44
    grid = tuple(int(c * 0.07 + b * 0.93) for c, b in zip(accent, BG))
    for x in range(0, W, step):
        d.line([(x, 0), (x, H)], fill=grid, width=2)
    for y in range(0, H, step):
        d.line([(0, y), (W, y)], fill=grid, width=2)
    glow = Image.new('RGB', (W, H), (0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([W * 0.1, H * 0.35, W * 0.9, H * 0.95], fill=accent)
    glow = glow.filter(ImageFilter.GaussianBlur(220))
    return Image.blend(im, Image.eval(glow, lambda v: v), 0.16)


def glow_text(im, xy, text, fnt, color, anchor='mm', spread=18):
    """Text with a neon bloom under it."""
    layer = Image.new('RGBA', im.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).text(xy, text, font=fnt, fill=color + (255,), anchor=anchor)
    bloom = layer.filter(ImageFilter.GaussianBlur(spread))
    im.paste(bloom, (0, 0), bloom)
    im.paste(bloom, (0, 0), bloom)
    im.paste(layer, (0, 0), layer)


def caption(im, lines, sub, accent, top=170):
    size = 70
    f = font(PIX, size)
    y = top
    for line in lines:
        # Shrink a line that would run off the edge.
        s = size
        while ImageDraw.Draw(im).textlength(line, font=font(PIX, s)) > W - 140:
            s -= 4
        glow_text(im, (W // 2, y), line, font(PIX, s), accent)
        y += int(s * 1.55)
    ImageDraw.Draw(im).text(
        (W // 2, y + 30), sub, font=font(VT, 78), fill=MUTED, anchor='mm'
    )
    return y + 100


def rounded(img, radius):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *img.size], radius, fill=255)
    out = Image.new('RGBA', img.size)
    out.paste(img, (0, 0), mask)
    return out


def phone(im, shot, center_x, top, width, accent, tilt=0):
    """The screenshot as a phone: rounded, framed, glowing."""
    h = int(shot.height * width / shot.width)
    s = rounded(shot.resize((width, h), Image.LANCZOS), int(width * 0.085))
    pad = 18
    frame = Image.new('RGBA', (width + pad * 2, h + pad * 2), (0, 0, 0, 0))
    fd = ImageDraw.Draw(frame)
    fd.rounded_rectangle(
        [0, 0, frame.width - 1, frame.height - 1],
        int(width * 0.085) + pad,
        fill=(14, 18, 16, 255),
        outline=accent + (255,),
        width=5,
    )
    frame.paste(s, (pad, pad), s)
    if tilt:
        frame = frame.rotate(tilt, resample=Image.BICUBIC, expand=True)
    # Glow behind.
    glow = Image.new('RGBA', im.size, (0, 0, 0, 0))
    gx = center_x - frame.width // 2
    alpha = frame.split()[3].point(lambda a: 150 if a else 0)
    tint = Image.new('RGBA', frame.size, accent + (255,))
    tint.putalpha(alpha)
    glow.paste(tint, (gx, top), tint)
    glow = glow.filter(ImageFilter.GaussianBlur(45))
    im.paste(glow, (0, 0), glow)
    im.paste(frame, (gx, top), frame)


def save(im, name):
    out = os.path.join(D, 'out')
    os.makedirs(os.path.join(out, '6.9'), exist_ok=True)
    os.makedirs(os.path.join(out, '6.5'), exist_ok=True)
    im.convert('RGB').save(os.path.join(out, '6.9', name), optimize=True)
    # 6.5": scale to height, center-crop the sides.
    s = im.convert('RGB').resize((int(W * 2778 / H), 2778), Image.LANCZOS)
    x = (s.width - 1284) // 2
    s.crop((x, 0, x + 1284, 2778)).save(os.path.join(out, '6.5', name), optimize=True)


# 1. THE GRID
im = background(GREEN)
y = caption(im, ['YOUR YEAR,', 'ONE GRID'], 'Hit your goal. Light up the day.', GREEN)
phone(im, raw(2), W // 2, y + 40, 1000, GREEN)
# Zoomed callout of the Grid card, floating over the phone.
card = raw(2).crop((60, 720, 1260, 1360)).resize((1200, 640), Image.LANCZOS)
cw, ch = card.size
framed = Image.new('RGBA', (cw + 24, ch + 24), (0, 0, 0, 0))
ImageDraw.Draw(framed).rounded_rectangle(
    [0, 0, cw + 23, ch + 23], 34, fill=BG + (255,), outline=GREEN + (255,), width=6
)
framed.paste(rounded(card, 26), (12, 12), rounded(card, 26))
cx, cy = (W - framed.width) // 2, 1880
g = Image.new('RGBA', im.size, (0, 0, 0, 0))
ImageDraw.Draw(g).rounded_rectangle(
    [cx, cy, cx + framed.width, cy + framed.height], 34, fill=GREEN + (170,)
)
g = g.filter(ImageFilter.GaussianBlur(40))
im.paste(g, (0, 0), g)
im.paste(framed, (cx, cy), framed)
save(im, '01_grid.png')

# 2. One-tap logging
im = background(GREEN)
y = caption(im, ['LOG PROTEIN', 'IN ONE TAP'], 'Your usual amounts, one button each.', GREEN)
phone(im, raw(1), W // 2, y + 40, 1000, GREEN)
save(im, '02_log.png')

# 3. Goal hit
im = background(GREEN)
y = caption(im, ['HIT YOUR GOAL.', 'EVERY DAY.'], 'Fill the meter. Keep the streak.', GREEN)
phone(im, raw(0), W // 2, y + 40, 1000, GREEN)
save(im, '03_goal.png')

# 4. Home-screen quick actions: just the menu, not the keyboard.
im = background(GREEN)
y = caption(im, ['LOG FROM YOUR', 'HOME SCREEN'], 'Long-press the icon. Done.', GREEN)
home = raw(3).crop((0, 0, 1320, 1880))
phone(im, home, W // 2, y + 60, 1100, GREEN)
save(im, '04_home.png')

# 5. Looks: Arcade Cabinet + Neon Vector side by side.
im = background(MAGENTA)
y = caption(im, ['PICK YOUR', 'LOOK'], 'Block Meter · Arcade · Neon Vector', AMBER)
phone(im, raw(4), int(W * 0.30), y + 110, 680, AMBER, tilt=4)
phone(im, raw(5), int(W * 0.70), y + 60, 680, CYAN, tilt=-4)
save(im, '05_looks.png')

# 6. Private: big promises, a little grid art.
im = background(GREEN)
glow_text(im, (W // 2, 330), 'NO ACCOUNT.', font(PIX, 84), GREEN)
glow_text(im, (W // 2, 500), 'NO ADS.', font(PIX, 84), GREEN)
glow_text(im, (W // 2, 670), 'JUST YOUR', font(PIX, 84), AMBER)
glow_text(im, (W // 2, 800), 'PROTEIN.', font(PIX, 84), AMBER)
d = ImageDraw.Draw(im)
for i, line in enumerate([
    'Your log stays on your phone.',
    'Open it, tap once, get on with your day.',
]):
    d.text((W // 2, 1000 + i * 90), line, font=font(VT, 76), fill=MUTED, anchor='mm')
pattern = [
    '1101111101', '0111011101', '1111101111', '1011111011',
    '1111110111', '0111111101', '1110111111',
]
cell, gap = 92, 18
gw = 10 * cell + 9 * gap
x0, y0 = (W - gw) // 2, 1280
for r, row in enumerate(pattern):
    for c, on in enumerate(row):
        x, yy = x0 + c * (cell + gap), y0 + r * (cell + gap)
        color = GREEN if on == '1' else (20, 40, 18)
        if on == '1':
            g = Image.new('RGBA', im.size, (0, 0, 0, 0))
            ImageDraw.Draw(g).rectangle([x, yy, x + cell, yy + cell], fill=GREEN + (160,))
            g = g.filter(ImageFilter.GaussianBlur(16))
            im.paste(g, (0, 0), g)
        ImageDraw.Draw(im).rectangle([x, yy, x + cell, yy + cell], fill=color)
glow_text(im, (W // 2, 2560), 'PROTEIN GRID', font(PIX, 64), GREEN)
save(im, '06_private.png')

print('done')
