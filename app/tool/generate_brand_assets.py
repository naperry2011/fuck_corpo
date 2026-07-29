"""Generates the shipped FuckCorpo web brand assets.

Replaces `generate_placeholder_icons.py`, which drew a system-font `$` on flat
navy purely so the manifest resolved every icon it declared (BUG-001). These
assets are built from the app's own design language instead: the committed
Playfair Display / Work Sans / Roboto Mono binaries under `assets/fonts/`, the
corporate navy field, the stock-market green mark, and the muted-gold ledger
rule used across the UI.

Outputs, all deterministic:

    web/icons/Icon-192.png              any-purpose PWA icon
    web/icons/Icon-512.png              any-purpose PWA icon
    web/icons/Icon-maskable-192.png     mark inside the 80% safe zone
    web/icons/Icon-maskable-512.png     mark inside the 80% safe zone
    web/icons/apple-touch-icon.png      180x180, iOS home screen
    web/favicon.png                     32x32
    web/social/og-card.png              1200x630 Open Graph / Twitter card

Everything is drawn at 4x and downsampled with LANCZOS, because Flutter web
renders to canvas and these rasters are the only artwork a crawler, an app
launcher, or a link unfurler ever sees.

`app/test/web/brand_assets_test.dart` pins the output sizes and rejects an
empty regeneration.

Run from `app/`:
    python tool/generate_brand_assets.py
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

# Design tokens, from fuckcorpo-design-system.md.
NAVY = (10, 17, 40, 255)
NAVY_LIFT = (19, 28, 61, 255)
SLATE = (30, 39, 73, 255)
GREEN = (0, 181, 89, 255)
GOLD = (255, 214, 10, 255)
MUTED_GOLD = (201, 166, 72, 255)
GRAY = (119, 141, 169, 255)
WHITE = (255, 255, 255, 255)

APP_DIR = Path(__file__).resolve().parent.parent
FONTS_DIR = APP_DIR / "assets" / "fonts"
WEB_DIR = APP_DIR / "web"
ICONS_DIR = WEB_DIR / "icons"
SOCIAL_DIR = WEB_DIR / "social"

DISPLAY = FONTS_DIR / "PlayfairDisplay-Variable.ttf"
BODY = FONTS_DIR / "WorkSans-Variable.ttf"
MONO = FONTS_DIR / "RobotoMono-Variable.ttf"

# Supersampling factor. Small icons are unreadable without it.
SS = 4

# Fraction of the canvas the `$` occupies. Maskable icons stay inside the 80%
# safe zone so Android's circular and squircle crops never clip the mark.
STANDARD_SCALE = 0.60
MASKABLE_SCALE = 0.40


def font(path: Path, size: int, weight: bytes = b"Bold") -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(str(path), size)
    try:
        f.set_variation_by_name(weight)
    except OSError:
        pass  # Static build of the family; the default instance is fine.
    return f


def vertical_gradient(size, top, bottom) -> Image.Image:
    """Navy field with the slight lift the app shell uses behind cards."""
    width, height = size
    img = Image.new("RGBA", (width, height), top)
    draw = ImageDraw.Draw(img)
    for y in range(height):
        t = y / max(height - 1, 1)
        draw.line(
            [(0, y), (width, y)],
            fill=tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)),
        )
    return img


def draw_centered(draw, box, text, fnt, fill):
    """Centers on the glyph's ink box, not on its line metrics."""
    x0, y0, x1, y1 = box
    left, top, right, bottom = draw.textbbox((0, 0), text, font=fnt)
    draw.text(
        (
            x0 + ((x1 - x0) - (right - left)) / 2 - left,
            y0 + ((y1 - y0) - (bottom - top)) / 2 - top,
        ),
        text,
        font=fnt,
        fill=fill,
    )


def trend_polyline(width, height):
    """The upward earnings line the dashboard uses, normalized to a box."""
    points = [0.06, 0.20, 0.14, 0.34, 0.30, 0.52, 0.44, 0.72, 0.66, 0.88, 1.0]
    return [
        (width * i / (len(points) - 1), height * (1 - v))
        for i, v in enumerate(points)
    ]


def render_icon(size: int, path: Path, scale: float, with_chart: bool) -> None:
    n = size * SS
    img = vertical_gradient((n, n), NAVY, NAVY_LIFT)
    draw = ImageDraw.Draw(img)

    if with_chart:
        # A faint rising line across the lower third: the same "number goes up"
        # motif as the dashboard, kept low-contrast so the mark stays dominant.
        layer = Image.new("RGBA", (n, n), (0, 0, 0, 0))
        ldraw = ImageDraw.Draw(layer)
        pts = [(x, n * 0.72 + y * 0.26) for x, y in trend_polyline(n, n)]
        ldraw.polygon(
            pts + [(n, n), (0, n)],
            fill=(GREEN[0], GREEN[1], GREEN[2], 26),
        )
        ldraw.line(pts, fill=(GREEN[0], GREEN[1], GREEN[2], 80), width=max(2, n // 64))
        img.alpha_composite(layer)

    draw_centered(
        draw,
        (0, -n * 0.06, n, n * 0.94),
        "$",
        font(DISPLAY, int(n * scale), b"Black"),
        GREEN,
    )

    path.parent.mkdir(parents=True, exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(path, "PNG")
    print(f"wrote {path.relative_to(APP_DIR)} ({size}x{size})")


def render_social_card(path: Path) -> None:
    """1200x630 Open Graph card.

    Flutter web paints to canvas, so a shared link unfurls with nothing from the
    app itself. This image is the entire preview. It reads as a subverted
    corporate document: confidential stamp, serif wordmark, gold rule, ticker.
    """
    width, height = 1200, 630
    w, h = width * SS, height * SS
    img = vertical_gradient((w, h), NAVY, (16, 24, 53, 255))
    draw = ImageDraw.Draw(img)

    pad = 72 * SS

    # Rising earnings line, bled off the right edge behind the copy.
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ldraw = ImageDraw.Draw(layer)
    pts = [(x * 0.55 + w * 0.45, y * 0.62 + h * 0.16) for x, y in trend_polyline(w, h)]
    ldraw.polygon(pts + [(w, h), (w * 0.45, h)], fill=(GREEN[0], GREEN[1], GREEN[2], 26))
    ldraw.line(pts, fill=(GREEN[0], GREEN[1], GREEN[2], 120), width=5 * SS)
    img.alpha_composite(layer)

    # Confidential stamp.
    stamp = font(MONO, 22 * SS, b"Medium")
    draw.text(
        (pad, pad),
        "C O N F I D E N T I A L   / /   I N T E R N A L   U S E   O N L Y",
        font=stamp,
        fill=MUTED_GOLD,
    )

    # Wordmark. Green `$`, white name, matching the navbar brand lockup.
    mark = font(DISPLAY, 116 * SS, b"Black")
    y = pad + 74 * SS
    draw.text((pad, y), "$", font=mark, fill=GREEN)
    dollar_w = draw.textlength("$", font=mark)
    draw.text((pad + dollar_w + 26 * SS, y), "FUCKCORPO", font=mark, fill=WHITE)

    # Gold ledger rule.
    rule_y = y + 168 * SS
    draw.rectangle([pad, rule_y, pad + 220 * SS, rule_y + 6 * SS], fill=GOLD)

    # Subtitle.
    body = font(BODY, 34 * SS, b"Medium")
    draw.text(
        (pad, rule_y + 44 * SS),
        "Get paid to shit. Track the money you earn",
        font=body,
        fill=WHITE,
    )
    draw.text(
        (pad, rule_y + 92 * SS),
        "on company time.",
        font=body,
        fill=WHITE,
    )

    # Ticker band, the strip that runs under the navbar in-app.
    band_h = 96 * SS
    draw.rectangle([0, h - band_h, w, h], fill=SLATE)
    draw.rectangle([0, h - band_h, w, h - band_h + 3 * SS], fill=(*GOLD[:3], 90))

    label = font(MONO, 22 * SS, b"Medium")
    label_text = "QUARTERLY EARNINGS REPORT"
    label_x = w - pad - draw.textlength(label_text, font=label)

    tick = font(MONO, 26 * SS, b"Bold")
    ty = h - band_h + (band_h - 26 * SS) / 2 - 4 * SS
    x = pad
    for symbol, change in (
        ("$POOP", "+420.69%"),
        ("$FLUSH", "+12.40%"),
        ("$BADGE", "+8.10%"),
    ):
        # Stop before the right-hand label rather than overprinting it.
        entry_w = (
            draw.textlength(symbol, font=tick)
            + draw.textlength(change, font=tick)
            + 60 * SS
        )
        if x + entry_w > label_x - 40 * SS:
            break
        draw.text((x, ty), symbol, font=tick, fill=WHITE)
        x += draw.textlength(symbol, font=tick) + 16 * SS
        # Roboto Mono has no dependable triangle glyph, so draw the arrow.
        a = 11 * SS
        cy = ty + 16 * SS
        draw.polygon([(x, cy + a * 0.7), (x + a, cy - a * 0.7), (x + 2 * a, cy + a * 0.7)], fill=GREEN)
        x += 2 * a + 12 * SS
        draw.text((x, ty), change, font=tick, fill=GREEN)
        x += draw.textlength(change, font=tick) + 48 * SS

    draw.text((label_x, ty + 3 * SS), label_text, font=label, fill=GRAY)

    path.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").resize((width, height), Image.LANCZOS).save(
        path, "PNG", optimize=True
    )
    print(f"wrote {path.relative_to(APP_DIR)} ({width}x{height})")


def main() -> None:
    render_icon(192, ICONS_DIR / "Icon-192.png", STANDARD_SCALE, with_chart=True)
    render_icon(512, ICONS_DIR / "Icon-512.png", STANDARD_SCALE, with_chart=True)
    render_icon(192, ICONS_DIR / "Icon-maskable-192.png", MASKABLE_SCALE, with_chart=False)
    render_icon(512, ICONS_DIR / "Icon-maskable-512.png", MASKABLE_SCALE, with_chart=False)
    render_icon(180, ICONS_DIR / "apple-touch-icon.png", STANDARD_SCALE, with_chart=True)
    render_icon(32, WEB_DIR / "favicon.png", 0.74, with_chart=False)
    render_social_card(SOCIAL_DIR / "og-card.png")


if __name__ == "__main__":
    main()
