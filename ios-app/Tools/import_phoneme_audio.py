#!/usr/bin/env python3
"""Import the supplied British-English phoneme recordings into the iOS bundle.

The source chart supplies one MP3 per chart button. Each MP3 contains an isolated sound first,
then a long pause and an example word. This importer detects and retains only the first region,
adds conservative silence padding, and encodes a mono AAC `.m4a` for the stable app catalogue.

The source audio must be supplied locally. Generated recordings and the local evidence manifest
are intentionally ignored by git because this repository is public.

Typical use from the repository root:

    python3 ios-app/Tools/import_phoneme_audio.py \
        --source-dir "/path/to/Interactive IPA Chart Audio" \
        --source-pdf "/path/to/The Sound of English 2023.pdf"
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import shutil
import struct
import subprocess
import tempfile
import wave
from dataclasses import dataclass
from pathlib import Path
from statistics import median


SAMPLE_RATE = 48_000
WINDOW_MILLISECONDS = 5
MERGE_GAP_MILLISECONDS = 100
MINIMUM_REGION_MILLISECONDS = 20
LEADING_PADDING_MILLISECONDS = 80
TRAILING_PADDING_MILLISECONDS = 120
MINIMUM_WORD_GAP_MILLISECONDS = 250
MINIMUM_CLIP_MILLISECONDS = 220
MAXIMUM_CLIP_MILLISECONDS = 1_500
AAC_BITRATE = 96_000


@dataclass(frozen=True)
class SourceAsset:
    stable_id: str
    ipa: str
    chart_button: int
    source_filename: str


# The chart's exporter did not keep media filenames aligned with button numbers near the end.
# These mappings come from each button's `data-click-play` target in the purchased PDF's linked
# interactive chart, rather than from assumptions about the SOUND filename.
ASSETS: tuple[SourceAsset, ...] = (
    SourceAsset("c_p", "p", 30, "SOUND 30.mp3"),
    SourceAsset("c_b", "b", 31, "SOUND 31.mp3"),
    SourceAsset("c_t", "t", 32, "SOUND 32.mp3"),
    SourceAsset("c_d", "d", 33, "SOUND 33.mp3"),
    SourceAsset("c_k", "k", 34, "SOUND 34.mp3"),
    SourceAsset("c_g", "ɡ", 35, "SOUND 35.mp3"),
    SourceAsset("c_f", "f", 21, "SOUND 21.mp3"),
    SourceAsset("c_v", "v", 22, "SOUND 22.mp3"),
    SourceAsset("c_th_vl", "θ", 23, "SOUND 23.mp3"),
    SourceAsset("c_th_vd", "ð", 24, "SOUND 24.mp3"),
    SourceAsset("c_s", "s", 25, "SOUND 25.mp3"),
    SourceAsset("c_z", "z", 26, "SOUND 26.mp3"),
    SourceAsset("c_sh", "ʃ", 27, "SOUND 27.mp3"),
    SourceAsset("c_zh", "ʒ", 28, "SOUND 28.mp3"),
    SourceAsset("c_h", "h", 29, "SOUND 29.mp3"),
    SourceAsset("c_tsh", "tʃ", 36, "SOUND 45.mp3"),
    SourceAsset("c_dzh", "dʒ", 37, "SOUND 38.mp3"),
    SourceAsset("c_m", "m", 42, "SOUND 36.mp3"),
    SourceAsset("c_n", "n", 43, "SOUND 37.mp3"),
    SourceAsset("c_ng", "ŋ", 44, "SOUND 42.mp3"),
    SourceAsset("c_l", "l", 41, "SOUND 46.mp3"),
    SourceAsset("c_r", "r", 39, "SOUND 40.mp3"),
    SourceAsset("c_yod", "j", 40, "SOUND 41.mp3"),
    SourceAsset("c_w", "w", 38, "SOUND 39.mp3"),
    SourceAsset("v_fleece", "iː", 1, "SOUND 1.mp3"),
    SourceAsset("v_kit", "ɪ", 2, "SOUND 2.mp3"),
    SourceAsset("v_dress", "ɛ", 3, "SOUND 3.mp3"),
    SourceAsset("v_trap", "a", 5, "SOUND 5.mp3"),
    SourceAsset("v_strut", "ʌ", 9, "SOUND 9.mp3"),
    SourceAsset("v_lot", "ɒ", 13, "SOUND 13a.mp3"),
    SourceAsset("v_foot", "ʊ", 11, "SOUND 11.mp3"),
    SourceAsset("v_goose", "uː", 6, "SOUND 6.mp3"),
    SourceAsset("v_face", "eɪ", 15, "SOUND 15.mp3"),
    SourceAsset("v_price", "ʌɪ", 18, "SOUND 18.mp3"),
    SourceAsset("v_mouth", "aʊ", 16, "SOUND 16.mp3"),
    SourceAsset("v_goat", "əʊ", 17, "SOUND 17.mp3"),
    SourceAsset("v_choice", "ɔɪ", 20, "SOUND 19.mp3"),
    SourceAsset("v_thought", "ɔː", 12, "SOUND 12.mp3"),
    SourceAsset("v_nurse", "əː", 8, "SOUND 8.mp3"),
    SourceAsset("v_palm", "ɑː", 10, "SOUND 10.mp3"),
    SourceAsset("v_square", "ɛː", 4, "SOUND 4.mp3"),
    SourceAsset("v_near", "ɪə", 14, "SOUND 14.mp3"),
    SourceAsset("v_schwa", "ə", 7, "SOUND 7.mp3"),
    SourceAsset("v_cure", "ʊə", 19, "SOUND 20.mp3"),
)


def repository_root() -> Path:
    return Path(__file__).resolve().parents[2]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def run(command: list[str]) -> None:
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(f"Command failed ({' '.join(command)}): {detail}")


def decode_to_wave(source: Path, destination: Path, afconvert: str) -> None:
    run(
        [
            afconvert,
            "-f",
            "WAVE",
            "-d",
            f"LEI16@{SAMPLE_RATE}",
            str(source),
            str(destination),
        ]
    )


def window_levels(samples: tuple[int, ...], frames_per_window: int) -> list[float]:
    levels: list[float] = []
    for offset in range(0, len(samples), frames_per_window):
        window = samples[offset : offset + frames_per_window]
        if not window:
            break
        rms = math.sqrt(sum(sample * sample for sample in window) / len(window))
        levels.append(20 * math.log10(max(rms, 1.0) / 32768.0))
    return levels


def merge_active_regions(active: list[bool]) -> list[tuple[int, int]]:
    maximum_gap = MERGE_GAP_MILLISECONDS // WINDOW_MILLISECONDS
    active_indices = [index for index, is_active in enumerate(active) if is_active]
    if not active_indices:
        return []

    regions: list[tuple[int, int]] = []
    start = active_indices[0]
    previous = start
    for index in active_indices[1:]:
        if index - previous - 1 > maximum_gap:
            regions.append((start, previous + 1))
            start = index
        previous = index
    regions.append((start, previous + 1))

    minimum_windows = max(1, MINIMUM_REGION_MILLISECONDS // WINDOW_MILLISECONDS)
    return [region for region in regions if region[1] - region[0] >= minimum_windows]


def isolated_region(wave_path: Path) -> tuple[int, int, dict[str, float]]:
    with wave.open(str(wave_path), "rb") as source:
        channels = source.getnchannels()
        sample_width = source.getsampwidth()
        sample_rate = source.getframerate()
        frame_count = source.getnframes()
        raw = source.readframes(frame_count)

    if channels != 1 or sample_width != 2 or sample_rate != SAMPLE_RATE:
        raise RuntimeError(
            f"Unexpected decoded format for {wave_path.name}: "
            f"{channels} channel(s), {sample_width * 8}-bit, {sample_rate} Hz"
        )

    samples = struct.unpack(f"<{len(raw) // 2}h", raw)
    frames_per_window = sample_rate * WINDOW_MILLISECONDS // 1000
    levels = window_levels(samples, frames_per_window)
    quietest = sorted(levels)[: max(1, len(levels) // 5)]
    noise_floor = median(quietest)
    threshold = min(-34.0, max(-52.0, noise_floor + 18.0))
    regions = merge_active_regions([level >= threshold for level in levels])
    if len(regions) < 2:
        raise RuntimeError(
            f"Expected an isolated sound and an example word in {wave_path.name}; "
            f"detected {len(regions)} active region(s)"
        )

    first_start_window, first_end_window = regions[0]
    second_start_window, _ = regions[1]
    first_start = first_start_window * frames_per_window
    first_end = min(frame_count, first_end_window * frames_per_window)
    second_start = second_start_window * frames_per_window

    leading_padding = sample_rate * LEADING_PADDING_MILLISECONDS // 1000
    trailing_padding = sample_rate * TRAILING_PADDING_MILLISECONDS // 1000
    minimum_word_gap = sample_rate * MINIMUM_WORD_GAP_MILLISECONDS // 1000
    crop_start = max(0, first_start - leading_padding)
    crop_end = min(frame_count, first_end + trailing_padding, second_start - minimum_word_gap)
    duration_ms = (crop_end - crop_start) * 1000 / sample_rate
    if not MINIMUM_CLIP_MILLISECONDS <= duration_ms <= MAXIMUM_CLIP_MILLISECONDS:
        raise RuntimeError(
            f"Unsafe crop duration for {wave_path.name}: {duration_ms:.0f} ms"
        )

    evidence = {
        "noiseFloorDBFS": round(noise_floor, 2),
        "activityThresholdDBFS": round(threshold, 2),
        "isolatedActivityStartSeconds": round(first_start / sample_rate, 4),
        "isolatedActivityEndSeconds": round(first_end / sample_rate, 4),
        "exampleWordStartSeconds": round(second_start / sample_rate, 4),
        "cropStartSeconds": round(crop_start / sample_rate, 4),
        "cropEndSeconds": round(crop_end / sample_rate, 4),
        "outputDurationSeconds": round((crop_end - crop_start) / sample_rate, 4),
    }
    return crop_start, crop_end, evidence


def write_cropped_wave(source: Path, destination: Path, start: int, end: int) -> None:
    with wave.open(str(source), "rb") as input_wave:
        parameters = input_wave.getparams()
        input_wave.setpos(start)
        frames = input_wave.readframes(end - start)

    with wave.open(str(destination), "wb") as output_wave:
        output_wave.setparams(parameters)
        output_wave.writeframes(frames)


def encode_m4a(source: Path, destination: Path, afconvert: str) -> None:
    run(
        [
            afconvert,
            str(source),
            "-o",
            str(destination),
            "-f",
            "m4af",
            "-d",
            "aac ",
            "-b",
            str(AAC_BITRATE),
            "-q",
            "127",
            "-s",
            "2",
        ]
    )


def validate_asset_table() -> None:
    if len(ASSETS) != 44:
        raise RuntimeError(f"Expected 44 asset mappings, found {len(ASSETS)}")
    stable_ids = [asset.stable_id for asset in ASSETS]
    source_files = [asset.source_filename for asset in ASSETS]
    chart_buttons = [asset.chart_button for asset in ASSETS]
    if len(set(stable_ids)) != len(stable_ids):
        raise RuntimeError("Duplicate stable ID in source mapping")
    if len(set(source_files)) != len(source_files):
        raise RuntimeError("Duplicate source file in source mapping")
    if len(set(chart_buttons)) != len(chart_buttons):
        raise RuntimeError("Duplicate chart button in source mapping")


def import_assets(
    source_dir: Path,
    output_dir: Path,
    afconvert: str,
    source_pdf: Path | None,
    manifest_path: Path,
) -> None:
    validate_asset_table()
    missing = [asset.source_filename for asset in ASSETS if not (source_dir / asset.source_filename).is_file()]
    if missing:
        formatted = "\n  - ".join(missing)
        raise RuntimeError(f"Missing {len(missing)} source file(s):\n  - {formatted}")

    if source_pdf is not None and not source_pdf.is_file():
        raise RuntimeError(f"Source PDF is not a readable file: {source_pdf}")

    output_dir.mkdir(parents=True, exist_ok=True)
    expected_outputs = {f"phoneme_{asset.stable_id}.m4a" for asset in ASSETS}
    actual_outputs = {path.name for path in output_dir.glob("phoneme_*.m4a")}
    unexpected = sorted(actual_outputs - expected_outputs)
    if unexpected:
        raise RuntimeError(f"Unexpected generated recordings in output folder: {unexpected}")

    manifest_assets: list[dict[str, object]] = []
    with tempfile.TemporaryDirectory(prefix="phoneme-audio-import-") as temporary:
        temporary_dir = Path(temporary)
        for asset in ASSETS:
            source = source_dir / asset.source_filename
            decoded = temporary_dir / f"{asset.stable_id}.decoded.wav"
            cropped = temporary_dir / f"{asset.stable_id}.cropped.wav"
            encoded = temporary_dir / f"phoneme_{asset.stable_id}.m4a"
            decode_to_wave(source, decoded, afconvert)
            crop_start, crop_end, evidence = isolated_region(decoded)
            write_cropped_wave(decoded, cropped, crop_start, crop_end)
            encode_m4a(cropped, encoded, afconvert)

            manifest_assets.append(
                {
                    "stableID": asset.stable_id,
                    "ipa": asset.ipa,
                    "chartButton": asset.chart_button,
                    "sourceFilename": asset.source_filename,
                    "sourceSHA256": sha256(source),
                    "outputFilename": encoded.name,
                    "outputSHA256": sha256(encoded),
                    **evidence,
                }
            )
            print(
                f"{asset.stable_id:10s} /{asset.ipa}/  "
                f"{evidence['outputDurationSeconds']:.3f}s  <- {asset.source_filename}"
            )

        # Publish the complete set only after every source decoded and passed the crop checks.
        for asset in ASSETS:
            encoded = temporary_dir / f"phoneme_{asset.stable_id}.m4a"
            os.replace(encoded, output_dir / encoded.name)

    manifest = {
        "datasetID": "en_gb_primary_phonemes_v1",
        "sourceProduct": "Locally supplied British-English phoneme source set",
        "sourceRecord": "Retained privately by the project owner; not stored in public git",
        "generatedAssetsCommittedToPublicGit": False,
        "assetCount": len(manifest_assets),
        "assets": manifest_assets,
    }
    if source_pdf is not None:
        manifest["sourceReferencePDF"] = {
            "filename": source_pdf.name,
            "sha256": sha256(source_pdf),
        }
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    temporary_manifest = manifest_path.with_suffix(".tmp")
    temporary_manifest.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n"
    )
    os.replace(temporary_manifest, manifest_path)
    print(f"\nImported {len(manifest_assets)} recordings into {output_dir}")
    print(f"Local evidence manifest: {manifest_path}")


def parse_arguments() -> argparse.Namespace:
    default_output = (
        repository_root()
        / "ios-app/MaxPuzzles/Resources/PhonemeAudio/en-GB/v1"
    )
    default_manifest = (
        repository_root()
        / "ios-app/LocalAssets/PhonemeAudio/en-GB/v1/import-manifest.local.json"
    )
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source-dir",
        type=Path,
        required=True,
        help="Folder containing the source SOUND … MP3 files",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=default_output,
        help=f"Destination for app-ready m4a files (default: {default_output})",
    )
    parser.add_argument(
        "--source-pdf",
        type=Path,
        help="Optional purchased reference PDF to hash into the private evidence manifest",
    )
    parser.add_argument(
        "--manifest-path",
        type=Path,
        default=default_manifest,
        help=f"Private evidence manifest path (default: {default_manifest})",
    )
    parser.add_argument(
        "--afconvert",
        default=shutil.which("afconvert") or "/usr/bin/afconvert",
        help="Path to Apple's afconvert command",
    )
    return parser.parse_args()


def main() -> None:
    arguments = parse_arguments()
    source_dir = arguments.source_dir.expanduser().resolve()
    source_pdf = (
        arguments.source_pdf.expanduser().resolve()
        if arguments.source_pdf is not None
        else None
    )
    output_dir = arguments.output_dir.expanduser().resolve()
    manifest_path = arguments.manifest_path.expanduser().resolve()
    afconvert = str(Path(arguments.afconvert).expanduser())
    if not source_dir.is_dir():
        raise RuntimeError(f"Source directory does not exist: {source_dir}")
    if not Path(afconvert).is_file():
        raise RuntimeError(f"afconvert was not found: {afconvert}")
    import_assets(source_dir, output_dir, afconvert, source_pdf, manifest_path)


if __name__ == "__main__":
    main()
