from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import shutil

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "KokoTegami" / "Assets.xcassets"
OUT = ROOT / "screenshots_new"
OUT.mkdir(exist_ok=True)

W, H = 1290, 2796
NIGHT = (8, 12, 19)
DEEP = (16, 26, 41)
PANEL = (24, 36, 52)
CREAM = (245, 239, 227)
MUTED = (152, 169, 187)
GOLD = (217, 185, 120)
WAX = (185, 64, 52)
TEAL = (98, 215, 212)


def font(size, bold=False):
    path = "C:/Windows/Fonts/YuGothB.ttc" if bold else "C:/Windows/Fonts/YuGothM.ttc"
    return ImageFont.truetype(path, size)


def cover(path, size):
    img = Image.open(path).convert("RGB")
    sw, sh = size
    scale = max(sw / img.width, sh / img.height)
    nw, nh = int(img.width * scale), int(img.height * scale)
    img = img.resize((nw, nh), Image.Resampling.LANCZOS)
    return img.crop(((nw - sw) // 2, (nh - sh) // 2, (nw + sw) // 2, (nh + sh) // 2))


def bg():
    img = Image.new("RGB", (W, H), NIGHT)
    px = img.load()
    for y in range(H):
        for x in range(W):
            t = x / W * 0.35 + y / H * 0.65
            px[x, y] = (int(7 + 28 * t), int(11 + 25 * t), int(18 + 28 * t))
    return img


def text(d, xy, s, size, fill=CREAM, bold=False, anchor=None, max_width=None, gap=8):
    f = font(size, bold)
    if max_width is None:
        d.text(xy, s, font=f, fill=fill, anchor=anchor)
        return
    lines, cur = [], ""
    for ch in s:
        test = cur + ch
        if d.textlength(test, font=f) <= max_width or not cur:
            cur = test
        else:
            lines.append(cur)
            cur = ch
    if cur:
        lines.append(cur)
    x, y = xy
    for line in lines:
        d.text((x, y), line, font=f, fill=fill)
        y += size + gap


def round_rect(d, box, fill, radius=32, outline=None, width=2):
    d.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def status(d, title="ここに手紙を置いてきた。"):
    text(d, (76, 58), "9:41", 34, CREAM, True)
    d.rounded_rectangle((1075, 64, 1180, 94), radius=14, outline=(245, 239, 227, 170), width=3)
    d.rounded_rectangle((1082, 71, 1145, 87), radius=8, fill=(245, 239, 227, 210))
    d.ellipse((1188, 72, 1206, 90), fill=(245, 239, 227, 160))
    text(d, (76, 132), title, 42, CREAM, True)
    d.line((76, 206, W - 76, 206), fill=(255, 255, 255, 35), width=2)


def badge(d, x, y, label, fill=(255, 255, 255, 22), fg=CREAM):
    f = font(30, True)
    w = int(d.textlength(label, font=f)) + 46
    round_rect(d, (x, y, x + w, y + 58), fill, radius=26)
    d.text((x + 23, y + 12), label, font=f, fill=fg)
    return x + w + 12


def tabs(d, active=0):
    y = H - 190
    round_rect(d, (52, y, W - 52, H - 58), (8, 12, 18, 236), radius=42, outline=(255, 255, 255, 35))
    labels = [("地図", "M"), ("書く", "P"), ("読む", "R"), ("履歴", "H")]
    step = (W - 104) // 4
    for i, (label, initial) in enumerate(labels):
        cx = 52 + step * i + step // 2
        c = GOLD if i == active else MUTED
        d.ellipse((cx - 28, y + 25, cx + 28, y + 81), fill=(217, 185, 120, 44) if i == active else (255, 255, 255, 12))
        text(d, (cx, y + 34), initial, 26, c, True, anchor="ma")
        text(d, (cx, y + 94), label, 28, c, True, anchor="ma")


def envelope_mark(d, cx, cy, size, stroke, width=4):
    x0, y0 = cx - size // 2, cy - size // 2
    x1, y1 = cx + size // 2, cy + size // 2
    d.rectangle((x0, y0, x1, y1), outline=stroke, width=width)
    d.line((x0, y0, cx, cy + size // 5, x1, y0), fill=stroke, width=width)
    d.line((x0, y1, cx, cy + size // 5, x1, y1), fill=stroke, width=width)


def hero():
    img = bg()
    d = ImageDraw.Draw(img, "RGBA")
    status(d)
    art = cover(ASSET / "letter-hero.imageset" / "letter-hero.png", (W - 152, 650))
    img.paste(art, (76, 260))
    d.rectangle((76, 260, W - 76, 910), fill=(0, 0, 0, 86))
    d.rectangle((76, 570, W - 76, 910), fill=(0, 0, 0, 145))
    badge(d, 116, 320, "SECRET LETTER MAP", (217, 185, 120, 46), GOLD)
    text(d, (116, 640), "街に、\n読まれる日を待つ手紙を。", 68, CREAM, True)
    text(d, (116, 810), "10m以内に近づいた人だけが開ける、場所に残す匿名のメッセージ。", 30, (245,239,227,210), max_width=1080)
    for i, (k, v) in enumerate([("書ける", "1通"), ("街の手紙", "128通"), ("開封距離", "10m")]):
        x = 76 + i * 390
        round_rect(d, (x, 980, x + 350, 1122), (255,255,255,18), radius=24, outline=(255,255,255,28))
        text(d, (x + 32, 1012), k, 30, MUTED, True)
        text(d, (x + 32, 1055), v, 52, CREAM, True)
    tabs(d, 0)
    return img


def map_screen():
    img = bg()
    d = ImageDraw.Draw(img, "RGBA")
    status(d)
    art = cover(ASSET / "letter-map.imageset" / "letter-map.png", (W - 152, 1260))
    img.paste(art, (76, 260))
    d.rectangle((76, 260, W - 76, 1520), fill=(0,0,0,55))
    badge(d, 110, 300, "手紙の近くに行くと開封できます", (0,0,0,120), CREAM)
    pins = [(305, 595, True), (760, 760, False), (990, 1120, False), (520, 1220, False)]
    for x, y, near in pins:
        color = WAX if near else GOLD
        d.ellipse((x-42, y-42, x+42, y+42), fill=(*color, 230), outline=(245,239,227,180), width=4)
        envelope_mark(d, x, y, 34, CREAM if near else NIGHT, width=3)
    round_rect(d, (76, 1590, W - 76, 1748), (24,36,52,235), radius=28, outline=(255,255,255,28))
    text(d, (116, 1630), "この場所に手紙を置く", 44, GOLD, True)
    text(d, (116, 1692), "今日の分が残っています", 30, MUTED)
    tabs(d, 0)
    return img


def compose():
    img = bg()
    d = ImageDraw.Draw(img, "RGBA")
    status(d, "手紙を書く")
    text(d, (76, 260), "今いる場所に、\n短い気持ちを残す。", 64, CREAM, True)
    text(d, (76, 430), "300文字まで。名前はいりません。場所だけが宛先です。", 32, MUTED, max_width=1020)
    round_rect(d, (76, 570, W - 76, 1130), (255, 247, 233, 255), radius=28, outline=(217,185,120,180), width=3)
    text(d, (126, 630), "今日ここで見た夕焼けが、誰かの帰り道にも残りますように。", 44, (38,36,33), False, max_width=990, gap=12)
    text(d, (W - 130, 1058), "36/300", 28, (100, 103, 106), anchor="ra")
    round_rect(d, (250, 1220, W - 250, 1326), (217,185,120,255), radius=24)
    text(d, (W // 2, 1248), "置いてくる", 42, NIGHT, True, anchor="ma")
    tabs(d, 1)
    return img


def discover():
    img = bg()
    d = ImageDraw.Draw(img, "RGBA")
    status(d, "手紙を見つけた")
    icon = cover(ASSET / "AppIcon.appiconset" / "AppIcon.png", (360, 360))
    icon = icon.filter(ImageFilter.GaussianBlur(0.1))
    img.paste(icon, ((W - 360)//2, 310))
    d.ellipse(((W-420)//2, 280, (W+420)//2, 700), outline=(217,185,120,95), width=4)
    text(d, (W // 2, 780), "10m以内に入りました", 56, CREAM, True, anchor="ma")
    text(d, (W // 2, 858), "開封すると手紙は消え、あなたは1通書けます。", 32, MUTED, anchor="ma")
    round_rect(d, (300, 1010, W - 300, 1120), (217,185,120,255), radius=26)
    text(d, (W // 2, 1040), "読む", 44, NIGHT, True, anchor="ma")
    round_rect(d, (76, 1260, W - 76, 1520), (24,36,52,235), radius=30, outline=(255,255,255,28))
    text(d, (116, 1310), "近くまで歩いた人だけが受け取れる", 42, CREAM, True)
    text(d, (116, 1380), "ただの投稿ではなく、その場所に行く理由が生まれます。", 32, MUTED, max_width=1000)
    tabs(d, 2)
    return img


def read():
    img = bg()
    d = ImageDraw.Draw(img, "RGBA")
    status(d, "開封した手紙")
    round_rect(d, (96, 320, W - 96, 1050), (255,247,233,255), radius=30, outline=(217,185,120,190), width=3)
    text(d, (150, 390), "大丈夫。今日ここまで歩いてきたあなたは、ちゃんと前に進んでいます。", 48, (38,36,33), False, max_width=970, gap=16)
    text(d, (W - 150, 960), "2026.05.08", 30, (100,103,106), anchor="ra")
    text(d, (96, 1140), "読んだら消えるから、\n言葉が少し特別になる。", 62, CREAM, True)
    text(d, (96, 1305), "開封した人には、次の誰かへ手紙を残す権利が渡ります。", 32, MUTED, max_width=1040)
    tabs(d, 2)
    return img


screens = [hero(), map_screen(), compose(), discover(), read()]
for i, img in enumerate(screens, 1):
    p = OUT / f"kokotegami_{i}.png"
    img.save(p, quality=95)
    shutil.copyfile(p, ROOT / f"ss_new_{i}.png")
    print(p)
