"""Draw the overlap mark used for the app and web icons.

Requires Pillow. Run from the repository root with `python tools/build_icons.py`.
"""

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SIZE = 1024
BACKGROUND = (31, 53, 87, 255)
RING = (244, 247, 251, 255)
OVERLAP = (174, 200, 242, 255)


def draw_icon() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shape = Image.new("L", (SIZE, SIZE))
    ImageDraw.Draw(shape).rounded_rectangle((0, 0, 1023, 1023), radius=205, fill=255)
    image.paste(BACKGROUND, (0, 0, SIZE, SIZE), shape)

    left = (168, 292, 674, 798)
    right = (350, 292, 856, 798)
    left_mask = Image.new("L", (SIZE, SIZE))
    right_mask = Image.new("L", (SIZE, SIZE))
    ImageDraw.Draw(left_mask).ellipse(left, fill=255)
    ImageDraw.Draw(right_mask).ellipse(right, fill=255)
    lens = ImageChops.multiply(left_mask, right_mask)
    image.paste(OVERLAP, (0, 0, SIZE, SIZE), lens)

    draw = ImageDraw.Draw(image)
    draw.ellipse(left, outline=RING, width=35)
    draw.ellipse(right, outline=RING, width=35)
    return image


def save(image: Image.Image, name: str, pixels: int) -> None:
    path = ROOT / name
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((pixels, pixels), Image.Resampling.LANCZOS).save(path)


if __name__ == "__main__":
    icon = draw_icon()
    for density, pixels in {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }.items():
        save(icon, f"android/app/src/main/res/mipmap-{density}/ic_launcher.png", pixels)
    for pixels in (192, 512):
        save(icon, f"web/icons/Icon-{pixels}.png", pixels)
        save(icon, f"web/icons/Icon-maskable-{pixels}.png", pixels)
    save(icon, "web/favicon.png", 64)
