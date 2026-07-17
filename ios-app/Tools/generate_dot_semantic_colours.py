#!/usr/bin/env python3
"""Build semantic colour-by-number masks for the downloaded dot-to-dot pack.

The line-art atlases are the source of truth for geometry.  AI-authored colour guides are
used only to infer which *closed region* receives which colour.  Consequently the generated
masks always meet the original worksheet lines exactly, even when a guide redraw differs by a
few pixels.

Typical use from the repository root:

    python3 ios-app/Tools/generate_dot_semantic_colours.py \
        --guides /tmp/maxpuzzles-semantic-colour \
        --preview-dir /tmp/maxpuzzles-semantic-preview

Inputs are guide-00.png ... guide-20.png, four pictures per guide in reading order.  Outputs
are five alpha-mask atlases per worksheet sheet plus a self-contained generated Swift lookup.
Pillow, NumPy and OpenCV are required.
"""

from __future__ import annotations

import argparse
import colorsys
import json
import math
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont


TILE_SIZE = 512
ATLAS_COLUMNS = 5
ATLAS_ROWS = 3
MAX_SWATCHES = 5
MIN_COMPONENT_AREA = 8
MIN_LABEL_AREA = 48

FORCED_FOREGROUND_COUNTS: dict[str, int] = {
    # The cream eye highlights are deliberately kept with their parent features.  The child's
    # meaningful giraffe choices are yellow body, brown spots/hooves, pink features and blue sky.
    "Giraffe": 3,
}

SHEETS: tuple[tuple[str, str, int], ...] = (
    ("d1d2", "D1/D2", 15),
    ("d3", "D3", 15),
    ("d4", "D4", 15),
    ("d5", "D5", 15),
    ("d6", "D6", 15),
    ("d7", "D7", 9),
)

# These are deliberately subject-specific.  The CV pipeline decides the masks and colours;
# these labels make the resulting activity intelligible to children and auditable by adults.
# Roles are ordered by total coloured area (largest foreground semantic first).
ROLE_HINTS: dict[str, tuple[str, ...]] = {
    "Giraffe": ("body", "spots", "features", "highlights"),
    "Sailboat": ("sails", "hull", "mast and trim", "life ring"),
    "Octopus": ("body", "suckers", "features", "highlights"),
    "Rocket": ("body", "fins and nose", "window", "flame"),
    "Tiger": ("coat", "stripes", "muzzle", "features"),
    "Submarine": ("hull", "windows", "trim", "propeller"),
    "Hamster": ("fur", "tummy", "ears and paws", "features"),
    "Ocean Ship": ("hull", "sails", "decks", "flags and trim"),
    "Bumblebee": ("body", "stripes", "wings", "features"),
    "Helicopter": ("fuselage", "windows", "rotors", "trim"),
    "Dump Truck": ("truck body", "tipper", "wheels", "windows"),
    "Steam Train": ("engine", "carriage", "wheels", "steam and trim"),
    "Tractor": ("tractor body", "wheels", "cab", "trim"),
    "Aeroplane": ("fuselage", "wings", "windows", "tail and trim"),
    "Bus": ("bus body", "windows", "wheels", "lights and trim"),
    "Stingray": ("body", "underside", "spots", "features"),
    "Elephant": ("body", "ears", "tusks", "features"),
    "Whale": ("body", "belly", "water spout", "features"),
    "Tapir": ("coat", "face", "feet", "features"),
    "Scooter": ("scooter body", "seat", "wheels", "lights and trim"),
    "Pelican": ("feathers", "beak", "feet", "features"),
    "Ostrich": ("feathers", "neck and legs", "beak", "features"),
    "Fox": ("fur", "chest and tail tip", "ears and paws", "features"),
    "Farm Tractor": ("tractor body", "wheels", "cab", "trim"),
    "Lion": ("coat", "mane", "muzzle", "features"),
    "Jellyfish": ("bell", "tentacles", "spots", "features"),
    "Turtle": ("shell", "skin", "shell pattern", "features"),
    "Shark": ("body", "belly", "fins", "features"),
    "Monkey": ("fur", "face and tummy", "ears and paws", "features"),
    "Llama": ("wool", "face", "blanket", "features"),
    "Cow": ("coat", "patches", "muzzle and udder", "features"),
    "Koala": ("fur", "ears and tummy", "nose", "features"),
    "Dancing Octopus": ("body", "suckers", "features", "highlights"),
    "Little Fish": ("body", "fins", "scales", "features"),
    "Walrus": ("body", "muzzle", "tusks", "features"),
    "Hedgehog": ("spines", "face and tummy", "feet", "features"),
    "Pearl Shell": ("shell", "inner shell", "pearl", "highlights"),
    "Tropical Island": ("sea", "sand", "palms", "island details"),
    "Owl": ("feathers", "wings", "eyes", "beak and feet"),
    "Frog": ("body", "tummy", "spots", "features"),
    "Rooster": ("feathers", "comb", "tail", "beak and feet"),
    "Duckling": ("feathers", "beak and feet", "wing", "features"),
    "Pineapple": ("flesh", "leaves", "skin texture", "highlights"),
    "Broccoli": ("florets", "stalk", "shadows", "highlights"),
    "Crocodile": ("body", "belly", "scales", "features"),
    "Anteater": ("coat", "stripe", "snout and feet", "features"),
    "Mouse": ("fur", "ears and paws", "tummy", "features"),
    "Cherries": ("fruit", "leaves", "stems", "highlights"),
    "Pig": ("body", "snout and ears", "hooves", "features"),
    "Red Panda": ("fur", "face markings", "tail rings", "features"),
    "Helping Hand": ("skin", "nails", "palm details", "highlights"),
    "Raccoon": ("fur", "mask and rings", "tummy", "features"),
    "Grasshopper": ("body", "wings", "legs", "features"),
    "Butterfly": ("wings", "wing pattern", "body", "features"),
    "Wiggly Worm": ("body", "segments", "cheeks", "features"),
    "Onion": ("bulb", "leaves", "roots", "highlights"),
    "Lotus Flower": ("petals", "centre", "leaves", "highlights"),
    "Sweetcorn": ("kernels", "husk", "silk", "highlights"),
    "Pea Pod": ("pod", "peas", "stem", "highlights"),
    "Shrimp": ("shell", "segments", "legs", "features"),
    "Ant": ("body", "legs", "antennae", "features"),
    "Parrot": ("feathers", "wings", "beak", "features"),
    "Flamingo": ("feathers", "beak", "legs", "features"),
    "Cottage": ("walls", "roof", "door and windows", "garden details"),
    "Potted Flower": ("petals", "centre", "leaves", "flower pot"),
    "Hatching Chick": ("chick", "eggshell", "beak", "features"),
    "Rain Cloud": ("cloud", "raindrops", "lightning", "features"),
    "Penguin": ("black feathers", "white tummy", "beak and feet", "features"),
    "Chameleon": ("body", "stripes", "eye", "features"),
    "Rabbit": ("fur", "ears and tummy", "nose and paws", "features"),
    "Mushroom": ("cap", "spots", "stalk", "grass"),
    "Sandcastle": ("sand", "flags", "doors and windows", "shell details"),
    "Caterpillar": ("body segments", "feet", "antennae", "features"),
    "Ice Cream": ("ice cream", "cone", "sprinkles", "wafer texture"),
    "Birthday Cake": ("icing", "cake layers", "candles", "decorations"),
    "Ladybird": ("wing cases", "spots", "head and legs", "features"),
    "Gorilla": ("fur", "face and chest", "hands and feet", "features"),
    "Cupcake": ("icing", "cake case", "sprinkles", "cherry"),
    "Ice Lolly": ("ice lolly", "stick", "stripes", "highlights"),
    "Strawberry": ("fruit", "leaves", "seeds", "highlights"),
    "Hot Chocolate": ("mug", "hot chocolate", "cream", "marshmallows"),
    "Milkshake": ("shake", "cup", "cream", "straw and decorations"),
    "Doughnut": ("dough", "icing", "sprinkles", "highlights"),
    "Zebra": ("white coat", "black stripes", "muzzle", "features"),
}


@dataclass(frozen=True)
class PuzzleSource:
    sheet_key: str
    sheet_name: str
    slot: int
    title: str
    global_index: int


@dataclass
class Region:
    component_id: int
    area: int
    mask: np.ndarray
    pole: tuple[int, int]
    sampled_rgb: np.ndarray
    cluster: int = -1


@dataclass
class Swatch:
    identifier: int
    name: str
    rgb: tuple[int, int, int]
    mask: np.ndarray
    label_points: list[tuple[float, float]]
    is_background: bool

    @property
    def hex(self) -> str:
        return "".join(f"{channel:02X}" for channel in self.rgb)


@dataclass
class PuzzlePlan:
    source: PuzzleSource
    swatches: list[Swatch]


def repository_root() -> Path:
    return Path(__file__).resolve().parents[2]


def parse_titles(source_file: Path) -> dict[tuple[str, int], str]:
    source = source_file.read_text(encoding="utf-8")
    pattern = re.compile(
        r'\.init\(sheet: "([^"]+)", slot: (\d+), title: "([^"]+)"'
    )
    titles = {(sheet, int(slot)): title for sheet, slot, title in pattern.findall(source)}
    expected = sum(count for _, _, count in SHEETS)
    if len(titles) != expected:
        raise RuntimeError(f"Expected {expected} puzzle titles, found {len(titles)} in {source_file}")
    return titles


def puzzle_sources(titles: dict[tuple[str, int], str]) -> list[PuzzleSource]:
    result: list[PuzzleSource] = []
    global_index = 0
    for sheet_key, sheet_name, count in SHEETS:
        for slot in range(1, count + 1):
            result.append(
                PuzzleSource(
                    sheet_key=sheet_key,
                    sheet_name=sheet_name,
                    slot=slot,
                    title=titles[(sheet_name, slot)],
                    global_index=global_index,
                )
            )
            global_index += 1
    return result


def guide_cell(guide: np.ndarray, quadrant: int) -> np.ndarray:
    height, width = guide.shape[:2]
    half_width = width // 2
    half_height = height // 2
    column = quadrant % 2
    row = quadrant // 2
    x0 = column * half_width
    y0 = row * half_height
    x1 = width if column == 1 else half_width
    y1 = height if row == 1 else half_height
    return guide[y0:y1, x0:x1]


def registration_offset(line_mask: np.ndarray, guide_rgb: np.ndarray) -> tuple[int, int]:
    """Find a conservative translation between guide and original without warping geometry."""
    resized = cv2.resize(guide_rgb, (TILE_SIZE, TILE_SIZE), interpolation=cv2.INTER_AREA)
    grey = cv2.cvtColor(resized, cv2.COLOR_RGB2GRAY)
    edges = cv2.Canny(grey, 70, 170)
    if np.count_nonzero(edges) < 100:
        return (0, 0)

    edge_distance = cv2.distanceTransform((edges == 0).astype(np.uint8), cv2.DIST_L2, 3)
    ys, xs = np.where(line_mask)
    if len(xs) > 4_000:
        stride = max(1, len(xs) // 4_000)
        xs = xs[::stride]
        ys = ys[::stride]

    def score(dx: int, dy: int) -> float:
        shifted_x = xs + dx
        shifted_y = ys + dy
        valid = (
            (shifted_x >= 0)
            & (shifted_x < TILE_SIZE)
            & (shifted_y >= 0)
            & (shifted_y < TILE_SIZE)
        )
        distances = edge_distance[shifted_y[valid], shifted_x[valid]]
        if distances.size == 0:
            return math.inf
        # A trimmed mean ignores guide embellishments absent from the source drawing.
        cutoff = np.percentile(distances, 70)
        return float(np.mean(distances[distances <= cutoff]))

    baseline = score(0, 0)
    best_score = baseline
    best = (0, 0)
    for dy in range(-12, 13, 2):
        for dx in range(-12, 13, 2):
            candidate = score(dx, dy)
            if candidate < best_score:
                best_score = candidate
                best = (dx, dy)
    # AI guides are intentionally registered already.  Reject weak matches that can be caused by
    # background texture rather than by the subject outline.
    return best if best_score < baseline * 0.88 else (0, 0)


def pole_of_inaccessibility(mask: np.ndarray) -> tuple[int, int]:
    distance = cv2.distanceTransform(mask.astype(np.uint8), cv2.DIST_L2, 5)
    y, x = np.unravel_index(int(np.argmax(distance)), distance.shape)
    return int(x), int(y)


def sample_guide_colour(
    guide_rgb: np.ndarray,
    pole: tuple[int, int],
    offset: tuple[int, int],
) -> np.ndarray:
    resized = cv2.resize(guide_rgb, (TILE_SIZE, TILE_SIZE), interpolation=cv2.INTER_AREA)
    x = int(np.clip(pole[0] + offset[0], 0, TILE_SIZE - 1))
    y = int(np.clip(pole[1] + offset[1], 0, TILE_SIZE - 1))
    radius = 4
    patch = resized[
        max(0, y - radius) : min(TILE_SIZE, y + radius + 1),
        max(0, x - radius) : min(TILE_SIZE, x + radius + 1),
    ].reshape(-1, 3)
    # Use the median so antialiased outlines and small specular highlights cannot dominate.
    return np.median(patch, axis=0).astype(np.uint8)


def border_colour(guide_rgb: np.ndarray) -> np.ndarray:
    resized = cv2.resize(guide_rgb, (TILE_SIZE, TILE_SIZE), interpolation=cv2.INTER_AREA)
    depth = 22
    border = np.concatenate(
        (
            resized[:depth].reshape(-1, 3),
            resized[-depth:].reshape(-1, 3),
            resized[depth:-depth, :depth].reshape(-1, 3),
            resized[depth:-depth, -depth:].reshape(-1, 3),
        ),
        axis=0,
    )
    return np.median(border, axis=0).astype(np.uint8)


def rgb_to_lab(colours: np.ndarray) -> np.ndarray:
    shaped = np.asarray(colours, dtype=np.uint8).reshape(1, -1, 3)
    return cv2.cvtColor(shaped, cv2.COLOR_RGB2LAB).reshape(-1, 3).astype(np.float32)


def estimate_cluster_count(colours: np.ndarray) -> int:
    """Estimate three or four foreground semantics by agglomerating guide colours."""
    labs = rgb_to_lab(colours)
    clusters: list[list[int]] = [[index] for index in range(len(labs))]

    def centroid(cluster: Sequence[int]) -> np.ndarray:
        return np.mean(labs[list(cluster)], axis=0)

    while len(clusters) > 1:
        best_pair: tuple[int, int] | None = None
        best_distance = math.inf
        for left in range(len(clusters)):
            for right in range(left + 1, len(clusters)):
                distance = float(np.linalg.norm(centroid(clusters[left]) - centroid(clusters[right])))
                if distance < best_distance:
                    best_distance = distance
                    best_pair = (left, right)
        if best_pair is None or best_distance >= 20:
            break
        left, right = best_pair
        clusters[left].extend(clusters[right])
        del clusters[right]

    return int(np.clip(len(clusters), 3, 4))


def cluster_regions(
    regions: list[Region], forced_count: int | None = None
) -> tuple[list[np.ndarray], list[int]]:
    colours = np.stack([region.sampled_rgb for region in regions])
    estimate = forced_count if forced_count is not None else estimate_cluster_count(colours)
    cluster_count = min(estimate, len(regions), MAX_SWATCHES - 1)
    if cluster_count < 3:
        raise RuntimeError("Artwork does not contain enough closed semantic regions")

    labs = rgb_to_lab(colours)
    cv2.setRNGSeed(0x4D4158)
    _, labels, centres = cv2.kmeans(
        labs,
        cluster_count,
        None,
        (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 100, 0.2),
        12,
        cv2.KMEANS_PP_CENTERS,
    )
    raw_labels = labels.reshape(-1).tolist()

    cluster_areas = [0 for _ in range(cluster_count)]
    cluster_colours: list[np.ndarray] = []
    for cluster in range(cluster_count):
        members = [index for index, label in enumerate(raw_labels) if label == cluster]
        cluster_areas[cluster] = sum(regions[index].area for index in members)
        weights = np.array([math.sqrt(regions[index].area) for index in members], dtype=np.float64)
        values = np.stack([regions[index].sampled_rgb for index in members]).astype(np.float64)
        representative = np.average(values, axis=0, weights=weights)
        cluster_colours.append(np.clip(np.rint(representative), 0, 255).astype(np.uint8))

    ordered = sorted(range(cluster_count), key=lambda index: cluster_areas[index], reverse=True)
    remap = {old: new for new, old in enumerate(ordered)}
    ordered_colours = [cluster_colours[index] for index in ordered]
    ordered_labels = [remap[label] for label in raw_labels]
    return ordered_colours, ordered_labels


def colour_descriptor(rgb: Sequence[int]) -> str:
    red, green, blue = (channel / 255 for channel in rgb)
    hue, saturation, value = colorsys.rgb_to_hsv(red, green, blue)
    degrees = hue * 360

    if value < 0.25:
        return "Charcoal-grey"
    if saturation < 0.11:
        if value > 0.90:
            return "Pearl-white"
        if value > 0.68:
            return "Silver-grey"
        if value > 0.38:
            return "Stone-grey"
        return "Charcoal-grey"
    if degrees < 12 or degrees >= 348:
        return "Cherry-red" if saturation > 0.58 else "Soft-rose"
    if degrees < 28:
        if value < 0.76 or (saturation > 0.58 and value < 0.86):
            return "Warm-brown"
        return "Tangerine-orange"
    if degrees < 46:
        return "Amber-orange"
    if degrees < 68:
        return "Golden-yellow"
    if degrees < 92:
        return "Lime-green"
    if degrees < 160:
        return "Leaf-green"
    if degrees < 190:
        return "Turquoise"
    if degrees < 218:
        return "Sky-blue"
    if degrees < 255:
        return "Ocean-blue"
    if degrees < 285:
        return "Violet-purple"
    if degrees < 320:
        return "Berry-purple"
    return "Soft-pink"


def make_open_hand_plan(
    source: PuzzleSource, tile_rgba: np.ndarray, guide_rgb: np.ndarray
) -> PuzzlePlan:
    """Handle the one intentionally open drawing using its semantic guide masks.

    Every other picture has closed worksheet regions.  The hand ends at an open wrist, so a flood
    fill cannot distinguish it from the page.  Its guide adds exactly the child-friendly semantics
    that the open drawing implies: skin, nails, bracelet and sleeve.  Those masks are registered to
    the original 512px tile and the untouched original stroke is removed from every fill layer.
    """
    guide = cv2.resize(guide_rgb, (TILE_SIZE, TILE_SIZE), interpolation=cv2.INTER_AREA)
    hsv = cv2.cvtColor(guide, cv2.COLOR_RGB2HSV)
    hue = hsv[:, :, 0].astype(np.int16) * 2
    saturation = hsv[:, :, 1].astype(np.float32) / 255
    value = hsv[:, :, 2].astype(np.float32) / 255

    # Hue/value gates follow semantic materials rather than arbitrary geometric partitions.
    nail = (((hue >= 325) | (hue <= 8)) & (saturation >= 0.28) & (value >= 0.66))
    bracelet = ((hue >= 38) & (hue <= 67) & (saturation >= 0.52) & (value >= 0.62))
    sleeve = ((hue >= 205) & (hue <= 250) & (saturation >= 0.52) & (value <= 0.97))
    skin = ((hue >= 18) & (hue <= 43) & (saturation >= 0.22) & (value >= 0.56))

    original_line = tile_rgba[:, :, 3] > 24
    protected_line = cv2.dilate(
        original_line.astype(np.uint8), np.ones((3, 3), np.uint8), iterations=1
    ).astype(bool)

    def clean(mask: np.ndarray, minimum_area: int) -> np.ndarray:
        result = cv2.morphologyEx(
            mask.astype(np.uint8), cv2.MORPH_OPEN, np.ones((3, 3), np.uint8)
        )
        result = cv2.morphologyEx(result, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
        count, labels, stats, _ = cv2.connectedComponentsWithStats(result, 8)
        keep = np.zeros_like(result, dtype=bool)
        for component in range(1, count):
            if int(stats[component, cv2.CC_STAT_AREA]) >= minimum_area:
                keep |= labels == component
        return keep & ~protected_line

    semantic_masks = [
        clean(skin, 120),
        clean(nail, 35),
        clean(bracelet, 80),
        clean(sleeve, 120),
    ]
    union = np.logical_or.reduce(semantic_masks)
    background = ~union & ~protected_line
    names = ("skin", "fingernails", "bracelet", "sleeve")
    used_names: set[str] = set()
    swatches: list[Swatch] = []
    for index, (role, mask) in enumerate(zip(names, semantic_masks), start=1):
        if not np.any(mask):
            raise RuntimeError(f"Helping Hand guide did not yield a {role} mask")
        values = guide[mask]
        rgb_array = np.median(values, axis=0).astype(np.uint8)
        pole = pole_of_inaccessibility(mask)
        swatches.append(
            Swatch(
                identifier=index,
                name=unique_name(
                    f"{colour_descriptor(rgb_array)} helping hand {role}", used_names
                ),
                rgb=tuple(int(channel) for channel in rgb_array),
                mask=mask,
                label_points=[((pole[0] + 0.5) / TILE_SIZE, (pole[1] + 0.5) / TILE_SIZE)],
                is_background=False,
            )
        )

    # Four foreground materials plus the exterior exactly meet the five-swatch activity limit.
    background_rgb = border_colour(guide_rgb)
    background_pole = pole_of_inaccessibility(background)
    swatches.append(
        Swatch(
            identifier=len(swatches) + 1,
            name=unique_name(
                f"{colour_descriptor(background_rgb)} helping hand background", used_names
            ),
            rgb=tuple(int(channel) for channel in background_rgb),
            mask=background,
            label_points=[
                (
                    (background_pole[0] + 0.5) / TILE_SIZE,
                    (background_pole[1] + 0.5) / TILE_SIZE,
                )
            ],
            is_background=True,
        )
    )
    return PuzzlePlan(source=source, swatches=swatches)


def unique_name(base: str, previous: set[str]) -> str:
    if base not in previous:
        previous.add(base)
        return base
    suffix = 2
    while f"{base} {suffix}" in previous:
        suffix += 1
    result = f"{base} {suffix}"
    previous.add(result)
    return result


def make_plan(source: PuzzleSource, tile_rgba: np.ndarray, guide_rgb: np.ndarray) -> PuzzlePlan:
    if source.title == "Helping Hand":
        return make_open_hand_plan(source, tile_rgba, guide_rgb)

    alpha = tile_rgba[:, :, 3]
    original_line = alpha > 24
    # Seal only sub-pixel antialias gaps.  Dilation keeps fill safely beneath the untouched line art.
    line = cv2.morphologyEx(
        original_line.astype(np.uint8), cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8)
    )
    line = cv2.dilate(line, np.ones((3, 3), np.uint8), iterations=1).astype(bool)

    count, labels, stats, _ = cv2.connectedComponentsWithStats((~line).astype(np.uint8), 8)
    border_ids = set(int(value) for value in labels[0])
    border_ids.update(int(value) for value in labels[-1])
    border_ids.update(int(value) for value in labels[:, 0])
    border_ids.update(int(value) for value in labels[:, -1])
    border_ids.discard(0)
    background_mask = np.isin(labels, list(border_ids))

    offset = registration_offset(original_line, guide_rgb)
    regions: list[Region] = []
    for component_id in range(1, count):
        if component_id in border_ids:
            continue
        area = int(stats[component_id, cv2.CC_STAT_AREA])
        if area < MIN_COMPONENT_AREA:
            continue
        mask = labels == component_id
        pole = pole_of_inaccessibility(mask)
        regions.append(
            Region(
                component_id=component_id,
                area=area,
                mask=mask,
                pole=pole,
                sampled_rgb=sample_guide_colour(guide_rgb, pole, offset),
            )
        )

    if len(regions) < 3:
        raise RuntimeError(f"{source.sheet_name} slot {source.slot} has only {len(regions)} regions")

    foreground_colours, assignments = cluster_regions(
        regions, forced_count=FORCED_FOREGROUND_COUNTS.get(source.title)
    )
    for region, cluster in zip(regions, assignments):
        region.cluster = cluster

    role_hints = ROLE_HINTS.get(
        source.title, ("main shape", "details", "features", "highlights")
    )
    subject = source.title.lower()
    used_names: set[str] = set()
    swatches: list[Swatch] = []
    for cluster, rgb in enumerate(foreground_colours):
        member_regions = [region for region in regions if region.cluster == cluster]
        mask = np.zeros((TILE_SIZE, TILE_SIZE), dtype=bool)
        for region in member_regions:
            mask |= region.mask

        label_regions = sorted(member_regions, key=lambda region: region.area, reverse=True)
        eligible = [region for region in label_regions if region.area >= MIN_LABEL_AREA]
        if not eligible:
            eligible = label_regions[:1]
        # Repeated details such as giraffe spots need repeated numerals, but never overwhelm a page.
        label_points = [
            ((region.pole[0] + 0.5) / TILE_SIZE, (region.pole[1] + 0.5) / TILE_SIZE)
            for region in eligible[:16]
        ]
        descriptor = colour_descriptor(rgb)
        role = role_hints[min(cluster, len(role_hints) - 1)]
        name = unique_name(f"{descriptor} {subject} {role}", used_names)
        swatches.append(
            Swatch(
                identifier=cluster + 1,
                name=name,
                rgb=tuple(int(channel) for channel in rgb),
                mask=mask,
                label_points=label_points,
                is_background=False,
            )
        )

    background_rgb = border_colour(guide_rgb)
    background_name = unique_name(
        f"{colour_descriptor(background_rgb)} {subject} background", used_names
    )
    background_pole = pole_of_inaccessibility(background_mask)
    swatches.append(
        Swatch(
            identifier=len(swatches) + 1,
            name=background_name,
            rgb=tuple(int(channel) for channel in background_rgb),
            mask=background_mask,
            label_points=[
                (
                    (background_pole[0] + 0.5) / TILE_SIZE,
                    (background_pole[1] + 0.5) / TILE_SIZE,
                )
            ],
            is_background=True,
        )
    )

    if not 4 <= len(swatches) <= MAX_SWATCHES:
        raise RuntimeError(
            f"{source.sheet_name} slot {source.slot} generated {len(swatches)} swatches"
        )
    return PuzzlePlan(source=source, swatches=swatches)


def atlas_path(assets: Path, sheet_key: str) -> Path:
    return assets / f"dot_reference_{sheet_key}.imageset" / f"dot_reference_{sheet_key}.png"


def load_atlases(assets: Path) -> dict[str, np.ndarray]:
    result: dict[str, np.ndarray] = {}
    for sheet_key, _, _ in SHEETS:
        path = atlas_path(assets, sheet_key)
        image = np.array(Image.open(path).convert("RGBA"))
        expected = (ATLAS_ROWS * TILE_SIZE, ATLAS_COLUMNS * TILE_SIZE, 4)
        if image.shape != expected:
            raise RuntimeError(f"Unexpected atlas shape {image.shape} for {path}; expected {expected}")
        result[sheet_key] = image
    return result


def tile_from_atlas(atlas: np.ndarray, slot: int) -> np.ndarray:
    index = slot - 1
    column = index % ATLAS_COLUMNS
    row = index // ATLAS_COLUMNS
    return atlas[
        row * TILE_SIZE : (row + 1) * TILE_SIZE,
        column * TILE_SIZE : (column + 1) * TILE_SIZE,
    ]


def write_mask_assets(assets: Path, plans: Sequence[PuzzlePlan]) -> None:
    grouped: dict[str, list[PuzzlePlan]] = {}
    for plan in plans:
        grouped.setdefault(plan.source.sheet_key, []).append(plan)

    for sheet_key, _, _ in SHEETS:
        sheet_plans = grouped.get(sheet_key, [])
        if not sheet_plans:
            continue
        for layer in range(1, MAX_SWATCHES + 1):
            atlas = np.zeros(
                (ATLAS_ROWS * TILE_SIZE, ATLAS_COLUMNS * TILE_SIZE, 4), dtype=np.uint8
            )
            atlas[:, :, :3] = 255
            for plan in sheet_plans:
                swatch = next(
                    (candidate for candidate in plan.swatches if candidate.identifier == layer), None
                )
                if swatch is None:
                    continue
                index = plan.source.slot - 1
                column = index % ATLAS_COLUMNS
                row = index // ATLAS_COLUMNS
                atlas[
                    row * TILE_SIZE : (row + 1) * TILE_SIZE,
                    column * TILE_SIZE : (column + 1) * TILE_SIZE,
                    3,
                ] = swatch.mask.astype(np.uint8) * 255

            asset_name = f"dot_colour_mask_{sheet_key}_{layer}"
            image_set = assets / f"{asset_name}.imageset"
            image_set.mkdir(parents=True, exist_ok=True)
            Image.fromarray(atlas, "RGBA").save(
                image_set / f"{asset_name}.png", optimize=True, compress_level=9
            )
            contents = {
                "images": [
                    {
                        "filename": f"{asset_name}.png",
                        "idiom": "universal",
                        "scale": "1x",
                    },
                    {"idiom": "universal", "scale": "2x"},
                    {"idiom": "universal", "scale": "3x"},
                ],
                "info": {"author": "xcode", "version": 1},
                "properties": {"preserves-vector-representation": True},
            }
            (image_set / "Contents.json").write_text(
                json.dumps(contents, indent=2) + "\n", encoding="utf-8"
            )


def swift_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def write_swift(path: Path, plans: Sequence[PuzzlePlan]) -> None:
    lines = [
        "// Generated by ios-app/Tools/generate_dot_semantic_colours.py. Do not hand-edit.",
        "import CoreGraphics",
        "import Foundation",
        "",
        "struct DotSemanticColourSwatch: Identifiable {",
        "    let id: Int",
        "    let name: String",
        "    let hex: String",
        "    let maskArt: DotPuzzleReferenceArt",
        "    let labelPoints: [CGPoint]",
        "    let isBackground: Bool",
        "}",
        "",
        "struct DotSemanticColourPlan {",
        "    let swatches: [DotSemanticColourSwatch]",
        "    var regionCount: Int { swatches.count }",
        "}",
        "",
        "enum DownloadedDotPuzzleColourArtwork {",
        "    static func plan(sheet: String, slot: Int) -> DotSemanticColourPlan? {",
        '        plans["\\(sheet):\\(slot)"]',
        "    }",
        "",
        "    private static let plans: [String: DotSemanticColourPlan] = [",
    ]
    for plan in plans:
        source = plan.source
        column = (source.slot - 1) % ATLAS_COLUMNS
        row = (source.slot - 1) // ATLAS_COLUMNS
        lines.append(f'        "{swift_escape(source.sheet_name)}:{source.slot}": .init(swatches: [')
        for swatch in plan.swatches:
            labels = ", ".join(
                f"CGPoint(x: {x:.5f}, y: {y:.5f})" for x, y in swatch.label_points
            )
            lines.extend(
                (
                    "            .init(",
                    f"                id: {swatch.identifier},",
                    f'                name: "{swift_escape(swatch.name)}",',
                    f'                hex: "{swatch.hex}",',
                    "                maskArt: .init(",
                    f'                    assetName: "dot_colour_mask_{source.sheet_key}_{swatch.identifier}",',
                    f"                    column: {column}, row: {row}, columns: {ATLAS_COLUMNS}, rows: {ATLAS_ROWS}",
                    "                ),",
                    f"                labelPoints: [{labels}],",
                    f"                isBackground: {'true' if swatch.is_background else 'false'}",
                    "            ),",
                )
            )
        lines.append("        ]),")
    lines.extend(("    ]", "}", ""))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def write_preview(path: Path, plan: PuzzlePlan, line_rgba: np.ndarray) -> None:
    canvas = np.full((TILE_SIZE, TILE_SIZE, 3), 255, dtype=np.uint8)
    for swatch in reversed(plan.swatches):
        canvas[swatch.mask] = np.asarray(swatch.rgb, dtype=np.uint8)

    # Reapply the exact original line alpha in black, never the guide's lines.
    alpha = line_rgba[:, :, 3:4].astype(np.float32) / 255
    canvas = np.rint(canvas * (1 - alpha)).astype(np.uint8)
    image = Image.fromarray(canvas, "RGB")
    draw = ImageDraw.Draw(image)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/SFNSRounded.ttf", 13)
    except OSError:
        font = ImageFont.load_default()
    for swatch in plan.swatches:
        for x, y in swatch.label_points:
            centre = (int(x * TILE_SIZE), int(y * TILE_SIZE))
            radius = 9
            draw.ellipse(
                (
                    centre[0] - radius,
                    centre[1] - radius,
                    centre[0] + radius,
                    centre[1] + radius,
                ),
                fill="white",
                outline="black",
                width=1,
            )
            text = str(swatch.identifier)
            box = draw.textbbox((0, 0), text, font=font)
            draw.text(
                (centre[0] - (box[2] - box[0]) / 2, centre[1] - (box[3] - box[1]) / 2 - 1),
                text,
                fill="black",
                font=font,
            )
    image.save(path, optimize=True)


def write_previews(
    directory: Path, plans: Sequence[PuzzlePlan], atlases: dict[str, np.ndarray]
) -> None:
    directory.mkdir(parents=True, exist_ok=True)
    for plan in plans:
        filename = f"{plan.source.global_index:02d}-{plan.source.sheet_key}-{plan.source.slot:02d}.png"
        write_preview(
            directory / filename,
            plan,
            tile_from_atlas(atlases[plan.source.sheet_key], plan.source.slot),
        )

    thumbs = []
    for path in sorted(directory.glob("[0-9][0-9]-*.png")):
        thumb = Image.open(path).resize((192, 192), Image.Resampling.LANCZOS)
        thumbs.append((path.stem, thumb))
    columns = 7
    rows = math.ceil(len(thumbs) / columns)
    montage = Image.new("RGB", (columns * 192, rows * 216), "white")
    draw = ImageDraw.Draw(montage)
    for index, (label, thumb) in enumerate(thumbs):
        x = (index % columns) * 192
        y = (index // columns) * 216
        montage.paste(thumb, (x, y))
        draw.text((x + 4, y + 195), label, fill="black")
    montage.save(directory / "semantic-colour-montage.png", optimize=True)


def validate(plans: Sequence[PuzzlePlan], expected_count: int) -> None:
    if len(plans) != expected_count:
        raise RuntimeError(f"Generated {len(plans)} plans; expected {expected_count}")
    keys = {(plan.source.sheet_name, plan.source.slot) for plan in plans}
    if len(keys) != len(plans):
        raise RuntimeError("Duplicate sheet/slot plan")
    signatures: set[tuple[str, ...]] = set()
    for plan in plans:
        if not 4 <= len(plan.swatches) <= MAX_SWATCHES:
            raise RuntimeError(f"Invalid swatch count for {plan.source.title}")
        if [swatch.identifier for swatch in plan.swatches] != list(
            range(1, len(plan.swatches) + 1)
        ):
            raise RuntimeError(f"Non-contiguous identifiers for {plan.source.title}")
        if sum(swatch.is_background for swatch in plan.swatches) != 1:
            raise RuntimeError(f"Invalid background count for {plan.source.title}")
        for swatch in plan.swatches:
            coverage = int(np.count_nonzero(swatch.mask))
            if coverage <= 0 or coverage >= TILE_SIZE * TILE_SIZE:
                raise RuntimeError(f"Invalid mask coverage for {plan.source.title}/{swatch.name}")
            if not swatch.label_points:
                raise RuntimeError(f"Missing label point for {plan.source.title}/{swatch.name}")
            if any(not (0 <= x <= 1 and 0 <= y <= 1) for x, y in swatch.label_points):
                raise RuntimeError(f"Invalid label point for {plan.source.title}/{swatch.name}")
        signature = tuple(swatch.name for swatch in plan.swatches)
        if signature in signatures:
            raise RuntimeError(f"Duplicate semantic signature for {plan.source.title}")
        signatures.add(signature)


def main() -> None:
    root = repository_root()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--guides", type=Path, required=True)
    parser.add_argument(
        "--assets",
        type=Path,
        default=root / "ios-app/MaxPuzzles/Resources/Assets.xcassets",
    )
    parser.add_argument(
        "--puzzle-source",
        type=Path,
        default=root / "ios-app/MaxPuzzles/Modules/DotToDot/DownloadedDotPuzzles.swift",
    )
    parser.add_argument(
        "--swift-output",
        type=Path,
        default=root
        / "ios-app/MaxPuzzles/Modules/DotToDot/DownloadedDotPuzzleColourArtwork.generated.swift",
    )
    parser.add_argument("--preview-dir", type=Path)
    parser.add_argument(
        "--allow-partial",
        action="store_true",
        help="Process only currently available guide batches (useful while guides generate).",
    )
    args = parser.parse_args()

    titles = parse_titles(args.puzzle_source)
    sources = puzzle_sources(titles)
    atlases = load_atlases(args.assets)
    plans: list[PuzzlePlan] = []
    for source in sources:
        batch = source.global_index // 4
        quadrant = source.global_index % 4
        guide_path = args.guides / f"guide-{batch:02d}.png"
        if not guide_path.exists():
            if args.allow_partial:
                continue
            raise FileNotFoundError(f"Missing colour guide: {guide_path}")
        guide = np.array(Image.open(guide_path).convert("RGB"))
        tile = tile_from_atlas(atlases[source.sheet_key], source.slot)
        plan = make_plan(source, tile, guide_cell(guide, quadrant))
        plans.append(plan)
        print(
            f"{source.global_index + 1:02d}/84 {source.title}: "
            + ", ".join(f"{swatch.id if False else swatch.identifier}={swatch.name} #{swatch.hex}" for swatch in plan.swatches)
        )

    expected = len(plans) if args.allow_partial else len(sources)
    validate(plans, expected)
    write_mask_assets(args.assets, plans)
    write_swift(args.swift_output, plans)
    if args.preview_dir:
        write_previews(args.preview_dir, plans, atlases)
    print(f"Generated {len(plans)} semantic plans and mask atlases.")


if __name__ == "__main__":
    main()
