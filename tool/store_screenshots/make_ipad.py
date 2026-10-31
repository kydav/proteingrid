"""Protein Grid iPad screenshots (13", 2064x2752). Raw iPad shots in ipad/raw0-5.png."""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

D = os.path.dirname(os.path.abspath(__file__))
W, H = 2064, 2752
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
    return Image.open(os.path.join(D, 'ipad', f'raw{i}.png')).convert('RGB')


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
    size = 100
    f = font(PIX, size)
    y = top
    for line in lines:
        # Shrink a line that would run off the edge.
        s = size
        while ImageDraw.Draw(im).textlength(line, font=font(PIX, s)) > W - 140:
            s -= 4
        glow_text(im, (W // 2, y), line, font(PIX, s), accent)
        y += int(s * 1.5)
    ImageDraw.Draw(im).text(
        (W // 2, y + 30), sub, font=font(VT, 104), fill=MUTED, anchor='mm'
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
    out = os.path.join(D, 'out', 'ipad')
    os.makedirs(out, exist_ok=True)
    im.convert('RGB').save(os.path.join(out, name), optimize=True)


# iPad raws: 0 Neon Vector, 1 Arcade Cabinet, 2 home menu, 3 Block Meter goal
# hit, 4 log sheet, 5 History.
TAB = 1500  # tablet width on the canvas


def callout(im, shot, box, width, top, accent=GREEN):
    """A zoomed piece of [shot], framed and glowing, over the tablet."""
    card = shot.crop(box)
    card = card.resize((width, int(card.height * width / card.width)), Image.LANCZOS)
    cw, ch = card.size
    framed = Image.new('RGBA', (cw + 28, ch + 28), (0, 0, 0, 0))
    ImageDraw.Draw(framed).rounded_rectangle(
        [0, 0, cw + 27, ch + 27], 40, fill=BG + (255,), outline=accent + (255,), width=7
    )
    framed.paste(rounded(card, 30), (14, 14), rounded(card, 30))
    cx = (W - framed.width) // 2
    g = Image.new('RGBA', im.size, (0, 0, 0, 0))
    ImageDraw.Draw(g).rounded_rectangle(
        [cx, top, cx + framed.width, top + framed.height], 40, fill=accent + (170,)
    )
    g = g.filter(ImageFilter.GaussianBlur(50))
    im.paste(g, (0, 0), g)
    im.paste(framed, (cx, top), framed)

# 1. THE GRID
im = background(GREEN)
y = caption(im, ['YOUR YEAR, ONE GRID'], 'Hit your goal. Light up the day.', GREEN, top=260)
phone(im, raw(5), W // 2, y + 50, TAB, GREEN)
callout(im, raw(5), (40, 420, 2024, 844), 1860, 1650)
save(im, '01_grid.png')

# 2. One-tap logging
im = background(GREEN)
y = caption(im, ['LOG PROTEIN IN ONE TAP'], 'Your usual amounts, one button each.', GREEN, top=260)
phone(im, raw(4), W // 2, y + 50, TAB, GREEN)
callout(im, raw(4), (392, 2288, 1672, 2752), 1700, 2040)
save(im, '02_log.png')

# 3. Goal hit
im = background(GREEN)
y = caption(im, ['HIT YOUR GOAL.', 'EVERY DAY.'], 'Fill the meter. Keep the streak.', GREEN, top=260)
phone(im, raw(3), W // 2, y + 50, 1400, GREEN)
save(im, '03_goal.png')

# 4. Home-screen quick actions: zoom in on the icon and its menu.
im = background(GREEN)
y = caption(im, ['LOG FROM YOUR', 'HOME SCREEN'], 'Long-press the icon. Done.', GREEN, top=260)
menu = raw(2).crop((380, 300, 1700, 1620))
phone(im, menu, W // 2, y + 80, 1500, GREEN)
save(im, '04_home.png')

# 5. Looks: Arcade Cabinet + Neon Vector side by side.
im = background(MAGENTA)
y = caption(im, ['PICK YOUR LOOK'], 'Block Meter · Arcade · Neon Vector', AMBER, top=260)
phone(im, raw(1), int(W * 0.30), y + 160, 1000, AMBER, tilt=4)
phone(im, raw(0), int(W * 0.70), y + 90, 1000, CYAN, tilt=-4)
save(im, '05_looks.png')

# 6. Private
im = background(GREEN)
glow_text(im, (W // 2, 380), 'NO ACCOUNT.', font(PIX, 120), GREEN)
glow_text(im, (W // 2, 600), 'NO ADS.', font(PIX, 120), GREEN)
glow_text(im, (W // 2, 820), 'JUST YOUR PROTEIN.', font(PIX, 104), AMBER)
d = ImageDraw.Draw(im)
for i, line in enumerate([
    'Your log stays on your device.',
    'Open it, tap once, get on with your day.',
]):
    d.text((W // 2, 1050 + i * 120), line, font=font(VT, 100), fill=MUTED, anchor='mm')
pattern = [
    '110111110111', '011101110111', '111110111101', '101111101111',
    '111111011101', '011111110111',
]
cell, gap = 120, 24
gw = 12 * cell + 11 * gap
x0, y0 = (W - gw) // 2, 1400
for r, row in enumerate(pattern):
    for c, on in enumerate(row):
        x, yy = x0 + c * (cell + gap), y0 + r * (cell + gap)
        if on == '1':
            g = Image.new('RGBA', im.size, (0, 0, 0, 0))
            ImageDraw.Draw(g).rectangle([x, yy, x + cell, yy + cell], fill=GREEN + (160,))
            g = g.filter(ImageFilter.GaussianBlur(20))
            im.paste(g, (0, 0), g)
        ImageDraw.Draw(im).rectangle(
            [x, yy, x + cell, yy + cell], fill=GREEN if on == '1' else (20, 40, 18)
        )
glow_text(im, (W // 2, 2500), 'PROTEIN GRID', font(PIX, 90), GREEN)
save(im, '06_private.png')
print('done')
