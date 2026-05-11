#!/usr/bin/env python3
"""Point racer LOD GLBs at their LOD0 atlas and remove embedded duplicate JPEGs."""

from __future__ import annotations

import json
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RACER_ROOT = ROOT / "assets" / "optimized" / "racers"
PROFILE = "mobile_detail_phase1"
LODS = ("lod1", "lod2")

JSON_CHUNK = 0x4E4F534A
BIN_CHUNK = 0x004E4942


def _pad(data: bytes, alignment: int, fill: bytes) -> bytes:
    pad_len = (-len(data)) % alignment
    return data + fill * pad_len


def _read_glb(path: Path) -> tuple[dict, bytes]:
    data = path.read_bytes()
    magic, version, _length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2:
        raise ValueError(f"{path} is not a GLB v2 file")

    offset = 12
    document: dict | None = None
    binary = b""
    while offset < len(data):
        chunk_length, chunk_type = struct.unpack_from("<II", data, offset)
        offset += 8
        chunk = data[offset : offset + chunk_length]
        offset += chunk_length
        if chunk_type == JSON_CHUNK:
            document = json.loads(chunk.decode("utf-8").rstrip("\x00 \t\r\n"))
        elif chunk_type == BIN_CHUNK:
            binary = chunk

    if document is None:
        raise ValueError(f"{path} has no JSON chunk")
    return document, binary


def _write_glb(path: Path, document: dict, binary: bytes) -> None:
    json_bytes = json.dumps(document, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    json_chunk = _pad(json_bytes, 4, b" ")
    bin_chunk = _pad(binary, 4, b"\x00")
    total_length = 12 + 8 + len(json_chunk)
    if bin_chunk:
        total_length += 8 + len(bin_chunk)

    with path.open("wb") as glb:
        glb.write(struct.pack("<4sII", b"glTF", 2, total_length))
        glb.write(struct.pack("<II", len(json_chunk), JSON_CHUNK))
        glb.write(json_chunk)
        if bin_chunk:
            glb.write(struct.pack("<II", len(bin_chunk), BIN_CHUNK))
            glb.write(bin_chunk)


def _shift_buffer_view_offsets(document: dict, removed_offset: int, removed_length: int, removed_index: int) -> None:
    for accessor in document.get("accessors", []):
        if "bufferView" in accessor and accessor["bufferView"] > removed_index:
            accessor["bufferView"] -= 1

    for mesh in document.get("meshes", []):
        for primitive in mesh.get("primitives", []):
            if "indices" in primitive:
                # Accessor indices are unchanged; included here to make the intent explicit.
                primitive["indices"] = primitive["indices"]

    for buffer_view in document.get("bufferViews", []):
        byte_offset = int(buffer_view.get("byteOffset", 0))
        if byte_offset > removed_offset:
            buffer_view["byteOffset"] = byte_offset - removed_length


def dedupe_lod_glb(path: Path, shared_atlas_uri: str) -> int:
    document, binary = _read_glb(path)
    images = document.get("images", [])
    if not images:
        return 0

    image = images[0]
    if "bufferView" not in image:
        image["uri"] = shared_atlas_uri
        image.pop("mimeType", None)
        return 0

    removed_index = int(image["bufferView"])
    buffer_views = document.get("bufferViews", [])
    removed_view = buffer_views[removed_index]
    removed_offset = int(removed_view.get("byteOffset", 0))
    removed_length = int(removed_view.get("byteLength", 0))

    del buffer_views[removed_index]
    _shift_buffer_view_offsets(document, removed_offset, removed_length, removed_index)
    binary = binary[:removed_offset] + binary[removed_offset + removed_length :]

    image.pop("bufferView", None)
    image.pop("mimeType", None)
    image["uri"] = shared_atlas_uri

    if document.get("buffers"):
        document["buffers"][0]["byteLength"] = len(binary)

    _write_glb(path, document, binary)
    return removed_length


def main() -> None:
    total_removed = 0
    for racer_dir in sorted(path for path in RACER_ROOT.iterdir() if path.is_dir()):
        slug = racer_dir.name
        shared_atlas = f"{slug}_racer_in_kart_{PROFILE}_Image_0.jpg"
        for lod in LODS:
            glb_path = racer_dir / f"{slug}_racer_in_kart_{PROFILE}_{lod}.glb"
            if not glb_path.exists():
                continue
            removed = dedupe_lod_glb(glb_path, shared_atlas)
            total_removed += removed
            print(f"{glb_path.relative_to(ROOT)} removed {removed:,} embedded texture bytes")
    print(f"total removed {total_removed:,} embedded texture bytes")


if __name__ == "__main__":
    main()
