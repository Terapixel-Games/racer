#!/usr/bin/env python3
"""Compare racer visual-regression manifests and enforce full/crop thresholds."""

from __future__ import annotations

import argparse
import json
import struct
import zlib
from pathlib import Path
from typing import Any


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def read_png_rgba(path: Path) -> tuple[int, int, bytes]:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError(f"{path} is not a PNG file")

    offset = len(PNG_SIGNATURE)
    width = height = 0
    color_type = -1
    bit_depth = -1
    compressed = bytearray()
    while offset < len(data):
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        chunk_type = data[offset + 4 : offset + 8]
        chunk = data[offset + 8 : offset + 8 + length]
        offset += 12 + length
        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type = struct.unpack(">IIBB", chunk[:10])
        elif chunk_type == b"IDAT":
            compressed.extend(chunk)
        elif chunk_type == b"IEND":
            break

    if bit_depth != 8 or color_type not in (2, 6):
        raise ValueError(f"{path} uses unsupported PNG mode bit_depth={bit_depth} color_type={color_type}")

    channels = 4 if color_type == 6 else 3
    raw = zlib.decompress(bytes(compressed))
    stride = width * channels
    rows: list[bytearray] = []
    previous = bytearray(stride)
    pos = 0
    for _row in range(height):
        filter_type = raw[pos]
        pos += 1
        scanline = bytearray(raw[pos : pos + stride])
        pos += stride
        recon = _unfilter(scanline, previous, channels, filter_type)
        rows.append(recon)
        previous = recon

    rgba = bytearray(width * height * 4)
    out = 0
    for row in rows:
        for x in range(width):
            source = x * channels
            rgba[out : out + 3] = row[source : source + 3]
            rgba[out + 3] = row[source + 3] if channels == 4 else 255
            out += 4
    return width, height, bytes(rgba)


def _unfilter(scanline: bytearray, previous: bytearray, channels: int, filter_type: int) -> bytearray:
    out = bytearray(len(scanline))
    for index, value in enumerate(scanline):
        left = out[index - channels] if index >= channels else 0
        up = previous[index]
        up_left = previous[index - channels] if index >= channels else 0
        if filter_type == 0:
            predicted = 0
        elif filter_type == 1:
            predicted = left
        elif filter_type == 2:
            predicted = up
        elif filter_type == 3:
            predicted = (left + up) // 2
        elif filter_type == 4:
            predicted = _paeth(left, up, up_left)
        else:
            raise ValueError(f"unsupported PNG filter {filter_type}")
        out[index] = (value + predicted) & 0xFF
    return out


def _paeth(left: int, up: int, up_left: int) -> int:
    estimate = left + up - up_left
    left_distance = abs(estimate - left)
    up_distance = abs(estimate - up)
    up_left_distance = abs(estimate - up_left)
    if left_distance <= up_distance and left_distance <= up_left_distance:
        return left
    if up_distance <= up_left_distance:
        return up
    return up_left


def crop_pixels(width: int, rgba: bytes, rect: list[int]) -> tuple[int, int, bytes]:
    x, y, crop_width, crop_height = rect
    out = bytearray(crop_width * crop_height * 4)
    dst = 0
    for row in range(crop_height):
        source = ((y + row) * width + x) * 4
        count = crop_width * 4
        out[dst : dst + count] = rgba[source : source + count]
        dst += count
    return crop_width, crop_height, bytes(out)


def similarity(a: bytes, b: bytes) -> float:
    if len(a) != len(b):
        return 0.0
    if not a:
        return 1.0
    diff = sum(abs(x - y) for x, y in zip(a, b))
    return 1.0 - (diff / (len(a) * 255.0))


def manifest_key(capture: dict[str, Any]) -> str:
    return f"{capture.get('racer_id')}::{capture.get('target')}"


def load_manifest(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as file:
        return json.load(file)


def compare_manifests(baseline_path: Path, candidate_path: Path) -> dict[str, Any]:
    baseline = load_manifest(baseline_path)
    candidate = load_manifest(candidate_path)
    baseline_root = baseline_path.parent
    candidate_root = candidate_path.parent
    threshold = float(candidate.get("detail_score_threshold", baseline.get("detail_score_threshold", 0.99)))
    full_threshold = float(candidate.get("full_score_threshold", baseline.get("full_score_threshold", 0.99)))

    baseline_by_key = {manifest_key(capture): capture for capture in baseline.get("captures", [])}
    candidate_by_key = {manifest_key(capture): capture for capture in candidate.get("captures", [])}
    comparisons: list[dict[str, Any]] = []
    failed_attempts: list[dict[str, Any]] = []

    for key in sorted(candidate_by_key):
        candidate_capture = candidate_by_key[key]
        baseline_capture = baseline_by_key.get(key)
        result: dict[str, Any] = {
            "key": key,
            "racer_id": candidate_capture.get("racer_id"),
            "target": candidate_capture.get("target"),
            "candidate_file": candidate_capture.get("file", ""),
            "baseline_file": baseline_capture.get("file", "") if baseline_capture else "",
            "selected_asset_profile": candidate_capture.get("selected_asset_profile", ""),
            "model_path": candidate_capture.get("model_path", ""),
            "model_bytes": int(candidate_capture.get("model_bytes", 0)),
            "full_score": 0.0,
            "detail_scores": {},
            "passed": False,
            "errors": [],
        }
        if baseline_capture is None:
            result["errors"].append("missing baseline capture")
            failed_attempts.append(result)
            comparisons.append(result)
            continue

        try:
            base_width, base_height, base_pixels = read_png_rgba(_resolve_image(baseline_root, str(baseline_capture.get("file", ""))))
            cand_width, cand_height, cand_pixels = read_png_rgba(_resolve_image(candidate_root, str(candidate_capture.get("file", ""))))
            if (base_width, base_height) != (cand_width, cand_height):
                result["errors"].append("image dimensions differ")
                failed_attempts.append(result)
                comparisons.append(result)
                continue
            full_score = similarity(base_pixels, cand_pixels)
            result["full_score"] = full_score
            if full_score < full_threshold:
                result["errors"].append("full render score below threshold")

            crop_errors = 0
            for crop in candidate_capture.get("crops", []):
                crop_id = str(crop.get("id", "crop"))
                rect = [int(value) for value in crop.get("pixel_rect", [])]
                if len(rect) != 4:
                    result["detail_scores"][crop_id] = 0.0
                    result["errors"].append(f"{crop_id} crop missing pixel_rect")
                    crop_errors += 1
                    continue
                _, _, base_crop = crop_pixels(base_width, base_pixels, rect)
                _, _, cand_crop = crop_pixels(cand_width, cand_pixels, rect)
                score = similarity(base_crop, cand_crop)
                result["detail_scores"][crop_id] = score
                if score < threshold:
                    result["errors"].append(f"{crop_id} detail score below threshold")
                    crop_errors += 1
            result["passed"] = full_score >= full_threshold and crop_errors == 0
        except Exception as exc:  # noqa: BLE001 - report generation should preserve failure detail.
            result["errors"].append(str(exc))

        if not result["passed"]:
            failed_attempts.append(result)
        comparisons.append(result)

    return {
        "schema_version": 1,
        "baseline_manifest": str(baseline_path),
        "candidate_manifest": str(candidate_path),
        "detail_score_threshold": threshold,
        "full_score_threshold": full_threshold,
        "comparisons": comparisons,
        "failed_attempts": failed_attempts,
        "status": "passed" if not failed_attempts else "failed",
    }


def _resolve_image(root: Path, raw: str) -> Path:
    path = Path(raw)
    if path.is_absolute():
        return path
    return root / path


def main() -> int:
    parser = argparse.ArgumentParser(description="Compare racer visual-regression manifests.")
    parser.add_argument("--baseline", required=True, type=Path)
    parser.add_argument("--candidate", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    args = parser.parse_args()

    report = compare_manifests(args.baseline, args.candidate)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    with args.report.open("w", encoding="utf-8") as file:
        json.dump(report, file, indent=2)
        file.write("\n")
    print(json.dumps({"status": report["status"], "failed_attempts": len(report["failed_attempts"])}, indent=2))
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
