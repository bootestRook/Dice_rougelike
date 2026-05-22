from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image
from PIL import ImageStat


ROOT = Path(__file__).resolve().parents[2]
TEXTURE_ROOT = ROOT / "assets" / "textures" / "dice"
PREVIEW_ROOT = ROOT / "assets" / "scenes" / "preview" / "preview_shots"
MATERIAL_IDS = ("bronze", "gold", "crystal")
TEXTURE_NAMES = ("albedo", "normal", "orm", "emission", "height", "flow_mask")
CELL_SIZE = 128


def main() -> int:
    for material_id in MATERIAL_IDS:
        print(f"== {material_id} ==")
        texture_dir = TEXTURE_ROOT / material_id
        for texture_name in TEXTURE_NAMES:
            texture_path = texture_dir / f"{material_id}_dice_{texture_name}.png"
            if not texture_path.exists():
                continue
            image = Image.open(texture_path).convert("RGBA")
            print(f"{texture_name}: {describe_image(image)}")
            if texture_name == "albedo" and material_id == "bronze":
                print(f"  greenish_ratio={greenish_ratio(image):.3f}")
            if texture_name == "orm":
                print(f"  orm={describe_orm(image)}")
            if texture_name == "normal":
                print(f"  normal={describe_normal(image)}")
            import_path = texture_path.with_suffix(texture_path.suffix + ".import")
            print(f"  import={describe_import(import_path)}")
        for light_mode in ("bright", "neutral", "dark"):
            preview_path = PREVIEW_ROOT / f"{material_id}_dice_{light_mode}.png"
            if preview_path.exists():
                preview = Image.open(preview_path).convert("RGBA")
                print(f"preview/{light_mode}: {describe_image(preview)}")
        print()
    return 0


def describe_image(image: Image.Image) -> str:
    stat = ImageStat.Stat(image)
    mean = [value / 255.0 for value in stat.mean]
    stddev = [value / 255.0 for value in stat.stddev]
    return (
        "rgb_mean=%.3f,%.3f,%.3f lum=%.3f rgb_std=%.3f"
        % (mean[0], mean[1], mean[2], luminance(mean), sum(stddev[:3]) / 3.0)
    )


def describe_orm(image: Image.Image) -> str:
    pixels = list(iter_pixels(image))
    count = max(1, len(pixels))
    mean = [sum(pixel[index] for pixel in pixels) / 255.0 / count for index in range(3)]
    metal_high = sum(1 for pixel in pixels if pixel[2] / 255.0 >= 0.98) / count
    rough_low = sum(1 for pixel in pixels if pixel[1] / 255.0 <= 0.28) / count
    return (
        "ao=%.3f rough=%.3f metal=%.3f metal>=.98=%.3f rough<=.28=%.3f"
        % (mean[0], mean[1], mean[2], metal_high, rough_low)
    )


def describe_normal(image: Image.Image) -> str:
    stat = ImageStat.Stat(image)
    mean = [value / 255.0 for value in stat.mean[:3]]
    extrema = [band.getextrema() for band in image.split()[:3]]
    ranges = ["%.3f..%.3f" % (low / 255.0, high / 255.0) for low, high in extrema]
    return "mean=%.3f,%.3f,%.3f ranges=%s" % (mean[0], mean[1], mean[2], ",".join(ranges))


def describe_import(path: Path) -> str:
    if not path.exists():
        return "missing"
    values = read_import_values(path, (
        "compress/normal_map",
        "mipmaps/generate",
        "roughness/mode",
        "process/normal_map_invert_y",
        "process/hdr_as_srgb",
    ))
    return ", ".join(f"{key}={values.get(key, '?')}" for key in values)


def read_import_values(path: Path, keys: Iterable[str]) -> dict[str, str]:
    wanted = tuple(keys)
    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        for key in wanted:
            prefix = f"{key}="
            if line.startswith(prefix):
                values[key] = line[len(prefix):]
    return values


def greenish_ratio(image: Image.Image) -> float:
    pixels = list(iter_pixels(image))
    count = max(1, len(pixels))
    greenish = 0
    for red, green, blue, _alpha in pixels:
        if green > red * 1.08 and green > blue * 1.25:
            greenish += 1
    return greenish / count


def luminance(channels: list[float]) -> float:
    return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722


def iter_pixels(image: Image.Image):
    flattened = getattr(image, "get_flattened_data", None)
    if callable(flattened):
        return flattened()
    return image.getdata()


if __name__ == "__main__":
    raise SystemExit(main())
