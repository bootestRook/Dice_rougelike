from __future__ import annotations

import math
from pathlib import Path
from typing import Dict, Tuple

from PIL import Image
from PIL import ImageDraw
from PIL import ImageFilter


ROOT = Path(__file__).resolve().parents[2]
CELL_SIZE = 128
COLS = 3
ROWS = 2
WIDTH = CELL_SIZE * COLS
HEIGHT = CELL_SIZE * ROWS
TAU = math.tau
STAGE_DISC_SIZE = 768
STAGE_DISC_TEXTURE_DIR = ROOT / "assets" / "textures" / "stage" / "star_disc"
PREVIEW_SHOT_DIR = ROOT / "assets" / "scenes" / "preview" / "preview_shots"


Color = Tuple[float, float, float, float]


STAGE_CONSTELLATION_POINTS: list[Tuple[float, float]] = [
    (-3.85 / 5.30, -1.18 / 5.30),
    (-3.10 / 5.30, -2.12 / 5.30),
    (-2.46 / 5.30, -0.52 / 5.30),
    (-1.66 / 5.30, -1.72 / 5.30),
    (-0.64 / 5.30, -2.76 / 5.30),
    (0.82 / 5.30, -2.48 / 5.30),
    (1.92 / 5.30, -1.58 / 5.30),
    (2.86 / 5.30, -2.38 / 5.30),
    (3.52 / 5.30, -0.82 / 5.30),
    (3.86 / 5.30, 1.10 / 5.30),
    (2.74 / 5.30, 1.94 / 5.30),
    (1.52 / 5.30, 2.66 / 5.30),
    (0.20 / 5.30, 3.34 / 5.30),
    (-1.24 / 5.30, 2.78 / 5.30),
    (-2.42 / 5.30, 1.96 / 5.30),
    (-3.44 / 5.30, 0.74 / 5.30),
    (-4.34 / 5.30, 2.04 / 5.30),
    (4.30 / 5.30, 2.34 / 5.30),
    (4.62 / 5.30, -1.94 / 5.30),
    (-4.58 / 5.30, -2.28 / 5.30),
]
STAGE_CONSTELLATION_CHAINS: list[list[int]] = [
    [0, 2, 3, 4, 5, 6, 8],
    [9, 10, 11, 12, 13, 15],
    [1, 16, 15],
    [17, 10],
    [18, 8],
    [19, 0],
]
STAGE_EXTRA_STARS: list[Tuple[float, float, float, float]] = [
    (
        math.cos(TAU * ((math.sin(i * 17.31) * 43758.5453) % 1.0)) * (0.24 + 0.66 * ((math.sin(i * 9.13 + 2.1) * 24634.6345) % 1.0)),
        math.sin(TAU * ((math.sin(i * 17.31) * 43758.5453) % 1.0)) * (0.24 + 0.66 * ((math.sin(i * 9.13 + 2.1) * 24634.6345) % 1.0)),
        0.0028 + 0.0022 * (i % 2),
        0.58 + 0.22 * (i % 3),
    )
    for i in range(34)
]


MATERIALS: Dict[str, Dict[str, object]] = {
    "bronze": {
        "texture_dir": ROOT / "assets" / "textures" / "dice" / "bronze",
        "base": (0.545098, 0.352941, 0.168627, 1.0),
        "dark": (0.30, 0.17, 0.08, 1.0),
        "edge": (0.72, 0.47, 0.24, 1.0),
        "accent": (0.12, 0.30, 0.23, 1.0),
        "metallic": 0.92,
        "roughness": 0.42,
        "roughness_body": 0.42,
        "roughness_panel": 0.46,
        "roughness_edge": 0.30,
        "normal_strength": 3.5,
    },
    "gold": {
        "texture_dir": ROOT / "assets" / "textures" / "dice" / "gold",
        "base": (0.850980, 0.713725, 0.227451, 1.0),
        "dark": (0.48, 0.35, 0.09, 1.0),
        "edge": (1.0, 0.88, 0.38, 1.0),
        "accent": (0.93, 0.66, 0.16, 1.0),
        "metallic": 0.97,
        "roughness": 0.24,
        "roughness_body": 0.24,
        "roughness_panel": 0.30,
        "roughness_edge": 0.14,
        "normal_strength": 2.9,
    },
    "crystal": {
        "texture_dir": ROOT / "assets" / "textures" / "dice" / "crystal",
        "base": (0.38, 0.86, 1.0, 0.52),
        "dark": (0.05, 0.18, 0.30, 0.42),
        "edge": (0.90, 1.0, 1.0, 0.68),
        "accent": (0.30, 0.96, 1.0, 0.80),
        "metallic": 0.0,
        "roughness": 0.16,
        "normal_strength": 3.0,
    },
}


def main() -> int:
    for material_id, spec in MATERIALS.items():
        print(f"generate textures: {material_id}", flush=True)
        generate_texture_set(material_id, spec)
    print("generate textures: star_disc", flush=True)
    generate_star_disc_texture_set()
    generate_preview_screenshots()
    generate_star_disc_preview_images()
    return 0


def generate_texture_set(material_id: str, spec: Dict[str, object]) -> None:
    texture_dir = Path(spec["texture_dir"])
    texture_dir.mkdir(parents=True, exist_ok=True)
    albedo = Image.new("RGBA", (WIDTH, HEIGHT))
    normal = Image.new("RGBA", (WIDTH, HEIGHT))
    orm = Image.new("RGBA", (WIDTH, HEIGHT))
    emission = Image.new("RGBA", (WIDTH, HEIGHT))
    height = Image.new("RGBA", (WIDTH, HEIGHT))
    flow = Image.new("RGBA", (WIDTH, HEIGHT))

    heights = [[0.0 for _ in range(WIDTH)] for _ in range(HEIGHT)]
    for y in range(HEIGHT):
        for x in range(WIDTH):
            heights[y][x] = height_value(material_id, spec, x, y)

    albedo_px = albedo.load()
    normal_px = normal.load()
    orm_px = orm.load()
    emission_px = emission.load()
    height_px = height.load()
    flow_px = flow.load()

    for y in range(HEIGHT):
        for x in range(WIDTH):
            sample = sample_surface(material_id, spec, x, y, heights[y][x])
            albedo_px[x, y] = to_rgba8(sample["albedo"])
            orm_px[x, y] = to_rgba8(sample["orm"])
            emission_px[x, y] = to_rgba8(sample["emission"])
            h = clamp(heights[y][x])
            height_px[x, y] = to_rgba8((h, h, h, 1.0))
            f = clamp(float(sample["flow"]))
            flow_px[x, y] = to_rgba8((f, f, f, 1.0))
            normal_px[x, y] = normal_color(material_id, spec, x, y, heights)

    albedo.save(texture_dir / f"{material_id}_dice_albedo.png")
    normal.save(texture_dir / f"{material_id}_dice_normal.png")
    orm.save(texture_dir / f"{material_id}_dice_orm.png")
    emission.save(texture_dir / f"{material_id}_dice_emission.png")
    height.save(texture_dir / f"{material_id}_dice_height.png")
    if material_id == "crystal":
        flow.save(texture_dir / f"{material_id}_dice_flow_mask.png")


def generate_preview_screenshots() -> None:
    screenshot_dir = PREVIEW_SHOT_DIR
    screenshot_dir.mkdir(parents=True, exist_ok=True)
    for material_id, spec in MATERIALS.items():
        albedo = Image.open(Path(spec["texture_dir"]) / f"{material_id}_dice_albedo.png").convert("RGBA")
        emission = Image.open(Path(spec["texture_dir"]) / f"{material_id}_dice_emission.png").convert("RGBA")
        for light_mode in ("bright", "neutral", "dark"):
            shot = render_preview_shot(material_id, albedo, emission, light_mode)
            shot.save(screenshot_dir / f"{material_id}_dice_{light_mode}.png")


def generate_star_disc_texture_set() -> None:
    STAGE_DISC_TEXTURE_DIR.mkdir(parents=True, exist_ok=True)
    size = STAGE_DISC_SIZE
    albedo = Image.new("RGBA", (size, size))
    normal = Image.new("RGBA", (size, size))
    orm = Image.new("RGBA", (size, size))
    emission = Image.new("RGBA", (size, size))
    height = Image.new("RGBA", (size, size))

    heights = [[0.0 for _ in range(size)] for _ in range(size)]
    for y in range(size):
        for x in range(size):
            heights[y][x] = star_disc_height_value(x, y)

    albedo_px = albedo.load()
    normal_px = normal.load()
    orm_px = orm.load()
    emission_px = emission.load()
    height_px = height.load()

    for y in range(size):
        for x in range(size):
            sample = sample_star_disc_surface(x, y, heights[y][x])
            albedo_px[x, y] = to_rgba8(sample["albedo"])
            orm_px[x, y] = to_rgba8(sample["orm"])
            emission_px[x, y] = to_rgba8(sample["emission"])
            h = clamp(heights[y][x])
            height_px[x, y] = to_rgba8((h, h, h, 1.0))
            normal_px[x, y] = star_disc_normal_color(x, y, heights)

    albedo.save(STAGE_DISC_TEXTURE_DIR / "star_disc_albedo.png")
    normal.save(STAGE_DISC_TEXTURE_DIR / "star_disc_normal.png")
    orm.save(STAGE_DISC_TEXTURE_DIR / "star_disc_orm.png")
    emission.save(STAGE_DISC_TEXTURE_DIR / "star_disc_emission.png")
    height.save(STAGE_DISC_TEXTURE_DIR / "star_disc_height.png")


def generate_star_disc_preview_images() -> None:
    PREVIEW_SHOT_DIR.mkdir(parents=True, exist_ok=True)
    albedo = Image.open(STAGE_DISC_TEXTURE_DIR / "star_disc_albedo.png").convert("RGBA")
    normal = Image.open(STAGE_DISC_TEXTURE_DIR / "star_disc_normal.png").convert("RGBA")
    orm = Image.open(STAGE_DISC_TEXTURE_DIR / "star_disc_orm.png").convert("RGBA")
    emission = Image.open(STAGE_DISC_TEXTURE_DIR / "star_disc_emission.png").convert("RGBA")

    albedo_preview = Image.new("RGBA", albedo.size, (4, 8, 24, 255))
    albedo_preview.alpha_composite(albedo)
    albedo_preview.convert("RGB").save(PREVIEW_SHOT_DIR / "star_disc_albedo_preview.png")
    normal.convert("RGB").save(PREVIEW_SHOT_DIR / "star_disc_normal_preview.png")
    render_star_disc_lit_preview(albedo, normal, orm, emission).save(PREVIEW_SHOT_DIR / "star_disc_lit_preview.png")


def sample_star_disc_surface(x: int, y: int, h: float) -> Dict[str, object]:
    u, v, px, py, radius, angle = star_disc_coord(x, y)
    inside = 1.0 - smoothstep(0.995, 1.018, radius)
    if inside <= 0.0:
        return {
            "albedo": (0.0, 0.0, 0.0, 0.0),
            "orm": (1.0, 0.82, 0.0, 1.0),
            "emission": (0.0, 0.0, 0.0, 1.0),
        }

    noise_low = fbm((x * 0.010 + 18.1, y * 0.010 + 41.7))
    noise_high = fbm((x * 0.052 + 71.3, y * 0.052 + 9.8))
    grain = fbm((x * 0.150 + 3.2, y * 0.025 + 5.8))
    scratch = clamp((1.0 - smoothstep(0.026, 0.075, abs(math.sin((u * 19.0 - v * 6.4 + grain * 2.3) * math.pi)))) * smoothstep(0.62, 0.90, grain))
    edge_shadow = smoothstep(0.74, 0.995, radius)
    outer_gold = max(
        ring_mask(radius, 0.885, 0.006),
        ring_mask(radius, 0.927, 0.004),
        ring_mask(radius, 0.956, 0.008),
    )
    inner_gold = max(
        ring_mask(radius, 0.145, 0.004),
        ring_mask(radius, 0.225, 0.003),
        ring_mask(radius, 0.342, 0.003),
        ring_mask(radius, 0.475, 0.003),
        ring_mask(radius, 0.595, 0.003),
        ring_mask(radius, 0.735, 0.004),
    )
    radial = radial_line_mask(angle, radius, 24, 0.010) * smoothstep(0.16, 0.36, radius) * (1.0 - smoothstep(0.86, 0.96, radius))
    compass = compass_star_mask(radius, angle)
    constellation = constellation_line_mask(px, py)
    star = star_dot_mask(px, py)
    blue_ring = max(ring_mask(radius, 0.675, 0.0025), ring_mask(radius, 0.795, 0.0025))
    gold_detail = clamp(max(outer_gold, inner_gold * 0.64, radial * 0.46, compass * 0.94))
    blue_detail = clamp(max(constellation * 0.72, star, blue_ring * 0.38))

    center_glow = 1.0 - smoothstep(0.0, 0.62, radius)
    base_top = (0.018, 0.052, 0.180, 1.0)
    base_bottom = (0.006, 0.014, 0.056, 1.0)
    color = lerp_color(base_top, base_bottom, clamp(radius * 0.74 + edge_shadow * 0.28))
    color = lerp_color(color, (0.035, 0.115, 0.330, 1.0), clamp(center_glow * 0.36 + noise_low * 0.05))
    color = lerp_color(color, (0.010, 0.018, 0.066, 1.0), clamp(edge_shadow * 0.32 + scratch * 0.10))
    color = lerp_color(color, (0.92, 0.60, 0.25, 1.0), clamp(gold_detail * (0.78 + noise_high * 0.16)))
    color = lerp_color(color, (0.10, 0.47, 1.00, 1.0), clamp(blue_detail * 0.62))
    color = (color[0], color[1], color[2], inside)

    ao = clamp(0.95 - edge_shadow * 0.22 - scratch * 0.05)
    roughness = clamp(0.62 + (noise_low - 0.5) * 0.12 + scratch * 0.08 - gold_detail * 0.17 - blue_detail * 0.10, 0.28, 0.88)
    metallic = clamp(gold_detail * 0.78 + outer_gold * 0.12 + blue_detail * 0.04, 0.0, 0.86)
    emission_blue = clamp(blue_detail * 0.58 + star * 0.55 + blue_ring * 0.20)
    emission_gold = clamp(gold_detail * 0.055)
    emission_color = (
        emission_gold * 1.00 + emission_blue * 0.10,
        emission_gold * 0.62 + emission_blue * 0.38,
        emission_gold * 0.18 + emission_blue * 1.00,
        1.0,
    )
    return {
        "albedo": color,
        "orm": (ao, roughness, metallic, 1.0),
        "emission": emission_color,
    }


def star_disc_height_value(x: int, y: int) -> float:
    _u, _v, px, py, radius, angle = star_disc_coord(x, y)
    inside = 1.0 - smoothstep(0.998, 1.018, radius)
    if inside <= 0.0:
        return 0.50
    noise_low = fbm((x * 0.011 + 18.1, y * 0.011 + 41.7))
    noise_high = fbm((x * 0.063 + 21.7, y * 0.063 + 8.1))
    scratch = clamp((1.0 - smoothstep(0.026, 0.085, abs(math.sin((x * 0.015 - y * 0.006 + noise_high * 2.4) * math.pi)))) * smoothstep(0.62, 0.90, noise_high))
    outer_gold = max(ring_mask(radius, 0.885, 0.006), ring_mask(radius, 0.927, 0.004), ring_mask(radius, 0.956, 0.008))
    inner_gold = max(
        ring_mask(radius, 0.145, 0.004),
        ring_mask(radius, 0.225, 0.003),
        ring_mask(radius, 0.342, 0.003),
        ring_mask(radius, 0.475, 0.003),
        ring_mask(radius, 0.595, 0.003),
        ring_mask(radius, 0.735, 0.004),
    )
    radial = radial_line_mask(angle, radius, 24, 0.010) * smoothstep(0.16, 0.36, radius) * (1.0 - smoothstep(0.86, 0.96, radius))
    compass = compass_star_mask(radius, angle)
    constellation = constellation_line_mask(px, py)
    star = star_dot_mask(px, py)
    h = 0.52 + (noise_low - 0.5) * 0.035 + (noise_high - 0.5) * 0.018
    h += max(outer_gold * 0.105, inner_gold * 0.070)
    h += radial * 0.035
    h += compass * 0.110
    h += constellation * 0.038
    h += star * 0.055
    h -= scratch * 0.028
    h -= smoothstep(0.88, 1.0, radius) * 0.040
    return clamp(h)


def star_disc_normal_color(x: int, y: int, heights: list[list[float]]) -> Tuple[int, int, int, int]:
    size = STAGE_DISC_SIZE
    strength = 7.4
    l = heights[y][max(0, x - 1)]
    r = heights[y][min(size - 1, x + 1)]
    u = heights[max(0, y - 1)][x]
    d = heights[min(size - 1, y + 1)][x]
    nx = (l - r) * strength
    ny = (u - d) * strength
    nz = 1.0
    length = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
    return to_rgba8((nx / length * 0.5 + 0.5, ny / length * 0.5 + 0.5, nz / length * 0.5 + 0.5, 1.0))


def render_star_disc_lit_preview(albedo: Image.Image, normal: Image.Image, orm: Image.Image, emission: Image.Image) -> Image.Image:
    width, height = 1280, 720
    preview = Image.new("RGBA", (width, height), (4, 8, 24, 255))
    draw = ImageDraw.Draw(preview, "RGBA")
    for y in range(height):
        t = y / float(height - 1)
        draw.line([(0, y), (width, y)], fill=to_rgba8(lerp_color((0.020, 0.034, 0.090, 1.0), (0.003, 0.007, 0.026, 1.0), t)))
    draw.ellipse((250, 545, 1030, 680), fill=(0, 0, 0, 86))

    out = preview.load()
    albedo_px = albedo.load()
    normal_px = normal.load()
    orm_px = orm.load()
    emission_px = emission.load()
    cx, cy = width * 0.5, height * 0.52
    rx, ry = width * 0.36, height * 0.295
    light_a = normalize3((-0.34, -0.48, 0.81))
    light_b = normalize3((0.42, 0.28, 0.86))
    view = (0.0, 0.0, 1.0)
    for y in range(height):
        local_y = (y - cy) / ry
        if local_y < -1.05 or local_y > 1.05:
            continue
        for x in range(width):
            local_x = (x - cx) / rx
            radius = math.hypot(local_x, local_y)
            if radius > 1.0:
                continue
            sx = min(STAGE_DISC_SIZE - 1, max(0, int((local_x * 0.5 + 0.5) * (STAGE_DISC_SIZE - 1))))
            sy = min(STAGE_DISC_SIZE - 1, max(0, int((local_y * 0.5 + 0.5) * (STAGE_DISC_SIZE - 1))))
            ar, ag, ab, aa = albedo_px[sx, sy]
            if aa <= 0:
                continue
            nr, ng, nb, _na = normal_px[sx, sy]
            normal_vec = normalize3((nr / 255.0 * 2.0 - 1.0, ng / 255.0 * 2.0 - 1.0, nb / 255.0 * 2.0 - 1.0))
            ao, roughness, metallic, _oa = tuple(channel / 255.0 for channel in orm_px[sx, sy])
            er, eg, eb, _ea = emission_px[sx, sy]
            diffuse = max(0.0, dot3(normal_vec, light_a)) * 0.82 + max(0.0, dot3(normal_vec, light_b)) * 0.34 + 0.24
            half_a = normalize3((light_a[0] + view[0], light_a[1] + view[1], light_a[2] + view[2]))
            spec_power = 10.0 + (1.0 - roughness) * 82.0
            specular = (max(0.0, dot3(normal_vec, half_a)) ** spec_power) * (0.08 + metallic * 0.72)
            rim = smoothstep(0.78, 1.0, radius)
            edge_dark = 1.0 - rim * 0.34
            lit = (
                clamp((ar / 255.0) * diffuse * ao * edge_dark + specular + er / 255.0 * 0.72),
                clamp((ag / 255.0) * diffuse * ao * edge_dark + specular * 0.74 + eg / 255.0 * 0.72),
                clamp((ab / 255.0) * diffuse * ao * edge_dark + specular * 0.42 + eb / 255.0 * 0.72),
                aa / 255.0,
            )
            br, bg, bb, ba = out[x, y]
            out[x, y] = to_rgba8(blend_rgba((br / 255.0, bg / 255.0, bb / 255.0, ba / 255.0), lit))
    edge = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    edge_draw = ImageDraw.Draw(edge, "RGBA")
    edge_draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), outline=(210, 142, 70, 128), width=3)
    edge_draw.ellipse((cx - rx * 0.93, cy - ry * 0.93, cx + rx * 0.93, cy + ry * 0.93), outline=(72, 138, 255, 72), width=2)
    preview.alpha_composite(edge.filter(ImageFilter.GaussianBlur(2)))
    preview.alpha_composite(edge)
    return preview.convert("RGB")


def star_disc_coord(x: int, y: int) -> Tuple[float, float, float, float, float, float]:
    u = x / float(STAGE_DISC_SIZE - 1)
    v = y / float(STAGE_DISC_SIZE - 1)
    px = u * 2.0 - 1.0
    py = v * 2.0 - 1.0
    radius = math.hypot(px, py)
    angle = math.atan2(py, px)
    if angle < 0.0:
        angle += TAU
    return u, v, px, py, radius, angle


def ring_mask(radius: float, ring_radius: float, width: float) -> float:
    return 1.0 - smoothstep(width, width * 2.65, abs(radius - ring_radius))


def radial_line_mask(angle: float, radius: float, count: int, width: float) -> float:
    if radius <= 0.001:
        return 0.0
    unit = angle / TAU * float(count)
    nearest = abs(unit - round(unit))
    return 1.0 - smoothstep(width, width * 2.6, nearest)


def compass_star_mask(radius: float, angle: float) -> float:
    if radius > 0.24:
        return 0.0
    spike = abs(math.cos(angle * 4.0)) ** 9.0
    limit = 0.052 + 0.176 * spike
    return 1.0 - smoothstep(limit, limit + 0.018, radius)


def star_dot_mask(px: float, py: float) -> float:
    result = 0.0
    for index, point in enumerate(STAGE_CONSTELLATION_POINTS):
        radius = 0.0048 + 0.0016 * (index % 3)
        result = max(result, 1.0 - smoothstep(radius, radius * 3.2, math.hypot(px - point[0], py - point[1])))
    for sx, sy, radius, intensity in STAGE_EXTRA_STARS:
        result = max(result, (1.0 - smoothstep(radius, radius * 3.4, math.hypot(px - sx, py - sy))) * intensity)
    return clamp(result)


def constellation_line_mask(px: float, py: float) -> float:
    result = 0.0
    point = (px, py)
    for chain in STAGE_CONSTELLATION_CHAINS:
        for index in range(len(chain) - 1):
            a = STAGE_CONSTELLATION_POINTS[chain[index]]
            b = STAGE_CONSTELLATION_POINTS[chain[index + 1]]
            dist = segment_distance(point, a, b)
            result = max(result, 1.0 - smoothstep(0.0026, 0.0080, dist))
    return clamp(result)


def segment_distance(p: Tuple[float, float], a: Tuple[float, float], b: Tuple[float, float]) -> float:
    ab = (b[0] - a[0], b[1] - a[1])
    ap = (p[0] - a[0], p[1] - a[1])
    denom = ab[0] * ab[0] + ab[1] * ab[1]
    if denom <= 0.000001:
        return math.hypot(ap[0], ap[1])
    t = clamp((ap[0] * ab[0] + ap[1] * ab[1]) / denom)
    closest = (a[0] + ab[0] * t, a[1] + ab[1] * t)
    return math.hypot(p[0] - closest[0], p[1] - closest[1])


def normalize3(v: Tuple[float, float, float]) -> Tuple[float, float, float]:
    length = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]) or 1.0
    return (v[0] / length, v[1] / length, v[2] / length)


def dot3(a: Tuple[float, float, float], b: Tuple[float, float, float]) -> float:
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def render_preview_shot(material_id: str, albedo: Image.Image, emission: Image.Image, light_mode: str) -> Image.Image:
    width, height = 1280, 720
    background_top, background_bottom, light_power, emission_power = lighting_profile(light_mode)
    shot = Image.new("RGBA", (width, height), to_rgba8(background_bottom))
    draw = ImageDraw.Draw(shot, "RGBA")
    for y in range(height):
        t = y / float(height - 1)
        draw.line([(0, y), (width, y)], fill=to_rgba8(lerp_color(background_top, background_bottom, t)))
    draw.ellipse((395, 545, 965, 645), fill=(0, 0, 0, 76 if light_mode != "bright" else 42))

    face_sources = {
        1: crop_face(albedo, 1),
        2: crop_face(albedo, 2),
        3: crop_face(albedo, 3),
    }
    emission_sources = {
        1: crop_face(emission, 1),
        2: crop_face(emission, 2),
        3: crop_face(emission, 3),
    }
    faces = [
        (face_sources[2], emission_sources[2], [(520, 250), (800, 300), (800, 555), (520, 505)], light_power * 0.95),
        (face_sources[3], emission_sources[3], [(800, 300), (980, 210), (980, 465), (800, 555)], light_power * 0.72),
        (face_sources[1], emission_sources[1], [(520, 250), (700, 160), (980, 210), (800, 300)], light_power * 1.18),
    ]
    for face_image, emission_image, points, shade in faces:
        paste_parallelogram(shot, face_image, emission_image, points, shade, emission_power, material_id == "crystal")

    edge = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    edge_draw = ImageDraw.Draw(edge, "RGBA")
    edge_color = (230, 255, 255, 120) if material_id == "crystal" else (255, 232, 176, 70)
    for points in [face[2] for face in faces]:
        edge_draw.line(points + [points[0]], fill=edge_color, width=3)
    if material_id == "crystal":
        glow = edge.filter(ImageFilter.GaussianBlur(8))
        shot.alpha_composite(glow)
    shot.alpha_composite(edge)
    return shot.convert("RGB")


def crop_face(atlas: Image.Image, value: int) -> Image.Image:
    index = value - 1
    col = index % COLS
    row = index // COLS
    box = (col * CELL_SIZE, row * CELL_SIZE, (col + 1) * CELL_SIZE, (row + 1) * CELL_SIZE)
    return atlas.crop(box).resize((256, 256), Image.Resampling.BICUBIC)


def paste_parallelogram(
    target: Image.Image,
    face: Image.Image,
    emission: Image.Image,
    points: list[Tuple[int, int]],
    shade: float,
    emission_power: float,
    translucent: bool,
) -> None:
    face_px = face.load()
    emission_px = emission.load()
    target_px = target.load()
    ox, oy = points[0]
    ax, ay = points[1][0] - ox, points[1][1] - oy
    bx, by = points[3][0] - ox, points[3][1] - oy
    determinant = ax * by - ay * bx
    if abs(determinant) < 0.0001:
        return
    min_x = max(0, min(p[0] for p in points))
    max_x = min(target.size[0] - 1, max(p[0] for p in points))
    min_y = max(0, min(p[1] for p in points))
    max_y = min(target.size[1] - 1, max(p[1] for p in points))
    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            px = x - ox
            py = y - oy
            u = (px * by - py * bx) / determinant
            v = (ax * py - ay * px) / determinant
            if u < 0.0 or u > 1.0 or v < 0.0 or v > 1.0:
                continue
            sx = min(255, max(0, int(u * 255)))
            sy = min(255, max(0, int(v * 255)))
            r, g, b, a = face_px[sx, sy]
            er, eg, eb, _ea = emission_px[sx, sy]
            alpha = (0.58 if translucent else 1.0) * (a / 255.0)
            lit = (
                clamp((r / 255.0) * shade + (er / 255.0) * emission_power),
                clamp((g / 255.0) * shade + (eg / 255.0) * emission_power),
                clamp((b / 255.0) * shade + (eb / 255.0) * emission_power),
                alpha,
            )
            br, bg, bb, ba = target_px[x, y]
            out = blend_rgba((br / 255.0, bg / 255.0, bb / 255.0, ba / 255.0), lit)
            target_px[x, y] = to_rgba8(out)


def lighting_profile(light_mode: str) -> Tuple[Color, Color, float, float]:
    if light_mode == "bright":
        return (0.78, 0.80, 0.84, 1.0), (0.52, 0.55, 0.60, 1.0), 1.25, 0.30
    if light_mode == "dark":
        return (0.030, 0.032, 0.044, 1.0), (0.065, 0.068, 0.088, 1.0), 0.74, 0.85
    return (0.18, 0.18, 0.22, 1.0), (0.10, 0.11, 0.14, 1.0), 0.92, 0.62


def blend_rgba(bottom: Color, top: Color) -> Color:
    alpha = clamp(top[3])
    inv = 1.0 - alpha
    return (
        top[0] * alpha + bottom[0] * inv,
        top[1] * alpha + bottom[1] * inv,
        top[2] * alpha + bottom[2] * inv,
        1.0,
    )


def sample_surface(material_id: str, spec: Dict[str, object], x: int, y: int, h: float) -> Dict[str, object]:
    uv = cell_uv(x, y)
    seed = seed_offset(material_id)
    noise_low = fbm((x * 0.012 + seed[0], y * 0.012 + seed[1]))
    noise_high = fbm((x * 0.055 + seed[0] * 1.7, y * 0.055 + seed[1] * 1.7))
    edge = edge_mask(uv)
    center_distance = max(abs(uv[0] - 0.5), abs(uv[1] - 0.5))
    panel = 1.0 - smoothstep(0.30, 0.48, center_distance)
    scratch = scratch_mask(material_id, uv, x, y)
    crack = crack_mask(material_id, uv, x, y)

    patina = 0.0
    if material_id == "bronze":
        patina_seed = smoothstep(0.66, 0.88, noise_low)
        patina_gate = clamp(edge * 0.42 + scratch * 0.86)
        patina = clamp(patina_seed * patina_gate)
    dirt = clamp((1.0 - noise_low) * 0.36 + scratch * 0.18)

    color = lerp_color(spec["base"], spec["dark"], dirt * (0.34 if material_id == "gold" else 0.40))
    color = lerp_color(color, spec["edge"], clamp(edge * (0.34 + noise_high * 0.18), 0.0, 0.72))
    if material_id == "bronze":
        color = lerp_color(color, spec["accent"], patina * 0.48)
    elif material_id == "gold":
        color = lerp_color(color, spec["accent"], clamp(scratch * 0.14 + (1.0 - edge) * 0.04, 0.0, 0.18))
    else:
        flow = flow_value(uv, x, y)
        color = lerp_color(color, spec["accent"], clamp(flow * 0.42 + crack * 0.30, 0.0, 0.70))
        color = (color[0], color[1], color[2], 0.46 + edge * 0.14)

    roughness_body = float(spec.get("roughness_body", spec["roughness"]))
    roughness_panel = float(spec.get("roughness_panel", roughness_body))
    roughness_edge = float(spec.get("roughness_edge", roughness_body))
    roughness = lerp(lerp(roughness_body, roughness_panel, panel), roughness_edge, edge)
    metallic = float(spec["metallic"])
    ao = clamp(0.92 - scratch * 0.08 - crack * 0.14)
    if material_id == "bronze":
        roughness = clamp(roughness + patina * 0.055 + scratch * 0.035, 0.24, 0.58)
        metallic = clamp(metallic - patina * 0.13 - dirt * 0.025, 0.72, 0.94)
    elif material_id == "gold":
        roughness = clamp(roughness + dirt * 0.045 + scratch * 0.025, 0.12, 0.38)
        metallic = clamp(metallic - dirt * 0.025 - scratch * 0.018, 0.90, 0.99)
    else:
        roughness = clamp(roughness + crack * 0.18, 0.04, 0.46)
        metallic = 0.0

    flow = 0.0
    emission_color = (0.0, 0.0, 0.0, 1.0)
    if material_id == "bronze":
        e = clamp(patina * 0.18, 0.0, 0.22)
        emission_color = mul_color((0.02, 0.16, 0.10, 1.0), e)
    elif material_id == "gold":
        e = clamp(edge * 0.07 + scratch * 0.015, 0.0, 0.14)
        emission_color = mul_color((1.0, 0.50, 0.12, 1.0), e)
    else:
        flow = flow_value(uv, x, y)
        e = clamp(flow * 0.86 + edge * 0.22)
        emission_color = mul_color((0.34, 0.96, 1.0, 1.0), e)

    return {
        "albedo": color,
        "orm": (ao, roughness, metallic, 1.0),
        "emission": emission_color,
        "height": h,
        "flow": flow,
    }


def height_value(material_id: str, spec: Dict[str, object], x: int, y: int) -> float:
    uv = cell_uv(x, y)
    seed = seed_offset(material_id)
    noise_low = fbm((x * 0.018 + seed[0], y * 0.018 + seed[1]))
    noise_high = fbm((x * 0.070 + seed[0] * 0.67, y * 0.070 + seed[1] * 0.67))
    edge = edge_mask(uv)
    scratch = scratch_mask(material_id, uv, x, y)
    crack = crack_mask(material_id, uv, x, y)
    h = 0.52 + (noise_low - 0.5) * 0.10 + (noise_high - 0.5) * 0.035
    h += edge * (0.075 if material_id == "crystal" else 0.12)
    h -= scratch * (0.010 if material_id == "crystal" else 0.035)
    h += crack * (0.13 if material_id == "crystal" else 0.0)
    return clamp(h)


def normal_color(material_id: str, spec: Dict[str, object], x: int, y: int, heights: list[list[float]]) -> Tuple[int, int, int, int]:
    strength = float(spec["normal_strength"])
    l = heights[y][max(0, x - 1)]
    r = heights[y][min(WIDTH - 1, x + 1)]
    u = heights[max(0, y - 1)][x]
    d = heights[min(HEIGHT - 1, y + 1)][x]
    nx = (l - r) * strength
    ny = (u - d) * strength
    nz = 1.0
    length = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
    return to_rgba8((nx / length * 0.5 + 0.5, ny / length * 0.5 + 0.5, nz / length * 0.5 + 0.5, 1.0))


def cell_uv(x: int, y: int) -> Tuple[float, float]:
    return ((x % CELL_SIZE) / float(CELL_SIZE - 1), (y % CELL_SIZE) / float(CELL_SIZE - 1))


def edge_mask(uv: Tuple[float, float]) -> float:
    edge_distance = min(uv[0], 1.0 - uv[0], uv[1], 1.0 - uv[1])
    return (1.0 - smoothstep(0.018, 0.135, edge_distance)) ** 1.65


def scratch_mask(material_id: str, uv: Tuple[float, float], x: int, y: int) -> float:
    seed = seed_offset(material_id)
    grain = fbm((x * 0.060 + seed[0] * 2.1, y * 0.018 + seed[1] * 2.1))
    line_a = abs(math.sin((uv[0] * 18.0 + uv[1] * 7.0 + grain * 2.8 + seed[0]) * math.pi))
    line_b = abs(math.sin((uv[0] * -9.0 + uv[1] * 21.0 + seed[1]) * math.pi))
    scratch = 1.0 - smoothstep(0.030, 0.090, min(line_a, line_b))
    return clamp(scratch * smoothstep(0.50, 0.86, grain))


def crack_mask(material_id: str, uv: Tuple[float, float], x: int, y: int) -> float:
    if material_id != "crystal":
        return 0.0
    seed = seed_offset(material_id)
    diagonal = abs(fract((uv[0] * 2.35 + uv[1] * 1.65 + fbm((x * 0.015 + seed[0], y * 0.015 + seed[1]))) * 4.0) - 0.5)
    fine = 1.0 - smoothstep(0.025, 0.085, diagonal)
    gate = smoothstep(0.47, 0.80, fbm((x * 0.033 + seed[0] * 1.9, y * 0.033 + seed[1] * 1.9)))
    return clamp(fine * gate)


def flow_value(uv: Tuple[float, float], x: int, y: int) -> float:
    noise = fbm((x * 0.019 + 9.1, y * 0.019 + 4.7))
    band = math.sin((uv[0] * 3.4 + uv[1] * 4.8 + noise * 1.7) * TAU)
    ribbon = smoothstep(0.58, 0.98, band * 0.5 + 0.5)
    vein = smoothstep(0.62, 0.91, crack_mask("crystal", uv, x, y))
    return clamp(max(ribbon * 0.82, vein))


def seed_offset(material_id: str) -> Tuple[float, float]:
    return {"bronze": (12.37, 4.91), "gold": (31.20, 16.84), "crystal": (7.73, 27.51)}[material_id]


def fbm(p: Tuple[float, float]) -> float:
    value = 0.0
    amplitude = 0.5
    frequency = 1.0
    for _ in range(3):
        value += smooth_noise((p[0] * frequency, p[1] * frequency)) * amplitude
        frequency *= 2.03
        amplitude *= 0.5
    return clamp(value)


def smooth_noise(p: Tuple[float, float]) -> float:
    ix = math.floor(p[0])
    iy = math.floor(p[1])
    fx = fract(p[0])
    fy = fract(p[1])
    ux = fx * fx * (3.0 - 2.0 * fx)
    uy = fy * fy * (3.0 - 2.0 * fy)
    a = hash21(ix, iy)
    b = hash21(ix + 1.0, iy)
    c = hash21(ix, iy + 1.0)
    d = hash21(ix + 1.0, iy + 1.0)
    return lerp(lerp(a, b, ux), lerp(c, d, ux), uy)


def hash21(x: float, y: float) -> float:
    return fract(math.sin(x * 127.1 + y * 311.7) * 43758.5453123)


def smoothstep(edge0: float, edge1: float, x: float) -> float:
    if edge0 == edge1:
        return 0.0
    t = clamp((x - edge0) / (edge1 - edge0))
    return t * t * (3.0 - 2.0 * t)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def lerp_color(a: Color, b: Color, t: float) -> Color:
    t = clamp(t)
    return tuple(lerp(float(a[i]), float(b[i]), t) for i in range(4))  # type: ignore[return-value]


def mul_color(color: Color, scalar: float) -> Color:
    return (color[0] * scalar, color[1] * scalar, color[2] * scalar, 1.0)


def distance(a: Tuple[float, float], b: Tuple[float, float]) -> float:
    return math.hypot(a[0] - b[0], a[1] - b[1])


def fract(value: float) -> float:
    return value - math.floor(value)


def clamp(value: float, low: float = 0.0, high: float = 1.0) -> float:
    return max(low, min(high, value))


def to_rgba8(color: Color) -> Tuple[int, int, int, int]:
    return tuple(int(round(clamp(float(channel)) * 255.0)) for channel in color)  # type: ignore[return-value]


if __name__ == "__main__":
    raise SystemExit(main())
