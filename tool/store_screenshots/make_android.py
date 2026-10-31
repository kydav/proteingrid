"""Protein Grid Google Play screenshots (1080x1920) and feature graphic (1024x500). Raw Android shots in android/raw0-4.png."""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

D = os.path.dirname(os.path.abspath(__file__))
W, H = 1080, 1920
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
    return Image.open(os.path.join(D, 'android', f'raw{i}.png')).convert('RGB')


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
    size = 56
    f = font(PIX, size)
    y = top
    for line in lines:
        # Shrink a line that would run off the edge.
        s = size
        while ImageDraw.Draw(im).textlength(line, font=font(PIX, s)) > W - 100:
            s -= 4
        glow_text(im, (W // 2, y), line, font(PIX, s), accent)
        y += int(s * 1.55)
    ImageDraw.Draw(im).text(
        (W // 2, y + 30), sub, font=font(VT, 62), fill=MUTED, anchor='mm'
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
    out = os.path.join(D, 'out', 'android')
    os.makedirs(out, exist_ok=True)
    im.convert('RGB').save(os.path.join(out, name), optimize=True)


# Android raws: 0 Neon Vector, 1 Arcade Cabinet, 2 History, 3 Block Meter
# goal hit, 4 log sheet, 5 launcher long-press menu. Phones run off the bottom edge, as is usual on Play.
PH = 820

im = background(GREEN)
y = caption(im, ['YOUR YEAR,', 'ONE GRID'], 'Hit your goal. Light up the day.', GREEN, top=130)
phone(im, raw(2), W // 2, y + 20, PH, GREEN)
save(im, '01_grid.png')

im = background(GREEN)
y = caption(im, ['LOG PROTEIN', 'IN ONE TAP'], 'Your usual amounts, one button each.', GREEN, top=130)
# The log sheet sits at the bottom of the screen: show the lower part.
shot = raw(4)
phone(im, shot.crop((0, 700, 1080, 2400)), W // 2, y + 20, PH, GREEN)
save(im, '02_log.png')

im = background(GREEN)
y = caption(im, ['HIT YOUR GOAL.', 'EVERY DAY.'], 'Fill the meter. Keep the streak.', GREEN, top=130)
phone(im, raw(3), W // 2, y + 20, PH, GREEN)
save(im, '03_goal.png')

im = background(GREEN)
y = caption(im, ['LOG FROM YOUR', 'HOME SCREEN'], 'Long-press the icon. Done.', GREEN, top=130)
# Zoom in on the icon and its shortcut menu.
phone(im, raw(5).crop((180, 1060, 1080, 2080)), W // 2, y + 60, 900, GREEN)
save(im, '04_home.png')

im = background(MAGENTA)
y = caption(im, ['PICK YOUR', 'LOOK'], 'Block Meter · Arcade · Neon Vector', AMBER, top=130)
phone(im, raw(1), int(W * 0.30), y + 90, 560, AMBER, tilt=4)
phone(im, raw(0), int(W * 0.70), y + 40, 560, CYAN, tilt=-4)
save(im, '05_looks.png')

im = background(GREEN)
glow_text(im, (W // 2, 260), 'NO ACCOUNT.', font(PIX, 66), GREEN)
glow_text(im, (W // 2, 390), 'NO ADS.', font(PIX, 66), GREEN)
glow_text(im, (W // 2, 520), 'JUST YOUR', font(PIX, 66), AMBER)
glow_text(im, (W // 2, 620), 'PROTEIN.', font(PIX, 66), AMBER)
d = ImageDraw.Draw(im)
for i, line in enumerate([
    'Your log stays on your phone.',
    'Open it, tap once, get on with your day.',
]):
    d.text((W // 2, 790 + i * 70), line, font=font(VT, 56), fill=MUTED, anchor='mm')
pattern = ['1101111101', '0111011101', '1111101111', '1011111011', '1111110111']
cell, gap = 76, 14
gw = 10 * cell + 9 * gap
x0, y0 = (W - gw) // 2, 1000
for r, row in enumerate(pattern):
    for c, on in enumerate(row):
        x, yy = x0 + c * (cell + gap), y0 + r * (cell + gap)
        if on == '1':
            g = Image.new('RGBA', im.size, (0, 0, 0, 0))
            ImageDraw.Draw(g).rectangle([x, yy, x + cell, yy + cell], fill=GREEN + (160,))
            g = g.filter(ImageFilter.GaussianBlur(14))
            im.paste(g, (0, 0), g)
        ImageDraw.Draw(im).rectangle(
            [x, yy, x + cell, yy + cell], fill=GREEN if on == '1' else (20, 40, 18)
        )
glow_text(im, (W // 2, 1720), 'PROTEIN GRID', font(PIX, 52), GREEN)
save(im, '06_private.png')

# Play feature graphic, 1024x500: name, promise, and the Grid.
FW, FH = 1024, 500
im = Image.new('RGB', (FW, FH), BG)
d = ImageDraw.Draw(im)
gc = tuple(int(c * 0.07 + b * 0.93) for c, b in zip(GREEN, BG))
for x in range(0, FW, 24):
    d.line([(x, 0), (x, FH)], fill=gc, width=1)
for yy in range(0, FH, 24):
    d.line([(0, yy), (FW, yy)], fill=gc, width=1)
glow_text(im, (70, 150), 'PROTEIN', font(PIX, 56), GREEN, anchor='lm', spread=12)
glow_text(im, (70, 230), 'GRID', font(PIX, 56), GREEN, anchor='lm', spread=12)
d = ImageDraw.Draw(im)
d.text((72, 320), 'One tap protein tracker.', font=font(VT, 44), fill=MUTED, anchor='lm')
d.text((72, 370), 'Your year, one grid.', font=font(VT, 44), fill=AMBER, anchor='lm')
pat = ['11011111', '01110111', '11111011', '10111110', '11101111', '01111101']
cell, gap = 40, 9
x0, y0 = FW - 70 - (8 * cell + 7 * gap), (FH - (6 * cell + 5 * gap)) // 2
for r, row in enumerate(pat):
    for c, on in enumerate(row):
        x, yy = x0 + c * (cell + gap), y0 + r * (cell + gap)
        if on == '1':
            g = Image.new('RGBA', im.size, (0, 0, 0, 0))
            ImageDraw.Draw(g).rectangle([x, yy, x + cell, yy + cell], fill=GREEN + (150,))
            g = g.filter(ImageFilter.GaussianBlur(9))
            im.paste(g, (0, 0), g)
        ImageDraw.Draw(im).rectangle(
            [x, yy, x + cell, yy + cell], fill=GREEN if on == '1' else (20, 40, 18)
        )
save(im, 'feature_1024x500.png')
print('done')
