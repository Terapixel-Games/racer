import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


ARKIT_BLEND_SHAPE_NAMES = [
    "EyeBlinkLeft",
    "EyeLookDownLeft",
    "EyeLookInLeft",
    "EyeLookOutLeft",
    "EyeLookUpLeft",
    "EyeSquintLeft",
    "EyeWideLeft",
    "EyeBlinkRight",
    "EyeLookDownRight",
    "EyeLookInRight",
    "EyeLookOutRight",
    "EyeLookUpRight",
    "EyeSquintRight",
    "EyeWideRight",
    "JawForward",
    "JawRight",
    "JawLeft",
    "JawOpen",
    "MouthClose",
    "MouthFunnel",
    "MouthPucker",
    "MouthRight",
    "MouthLeft",
    "MouthSmileLeft",
    "MouthSmileRight",
    "MouthFrownLeft",
    "MouthFrownRight",
    "MouthDimpleLeft",
    "MouthDimpleRight",
    "MouthStretchLeft",
    "MouthStretchRight",
    "MouthRollLower",
    "MouthRollUpper",
    "MouthShrugLower",
    "MouthShrugUpper",
    "MouthPressLeft",
    "MouthPressRight",
    "MouthLowerDownLeft",
    "MouthLowerDownRight",
    "MouthUpperUpLeft",
    "MouthUpperUpRight",
    "BrowDownLeft",
    "BrowDownRight",
    "BrowInnerUp",
    "BrowOuterUpLeft",
    "BrowOuterUpRight",
    "CheekPuff",
    "CheekSquintLeft",
    "CheekSquintRight",
    "NoseSneerLeft",
    "NoseSneerRight",
    "TongueOut",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--face-forward-axis", default="+X")
    parser.add_argument("--proxy-offset", type=float, default=0.0035)
    parser.add_argument("--max-proxy-polygons", type=int, default=18000)
    parser.add_argument("--proxy-source", default="")
    parser.add_argument("--proxy-source-mode", choices=["auto", "proxy", "parts"], default="auto")
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else sys.argv[1:]
    return parser.parse_args(argv)


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def import_glb(path: Path) -> list[bpy.types.Object]:
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    return [obj for obj in bpy.context.scene.objects if obj.type == "MESH" and obj not in before]


def largest_mesh(objects: list[bpy.types.Object]) -> bpy.types.Object:
    return max(objects, key=lambda obj: len(obj.data.polygons))


def world_bounds(obj: bpy.types.Object) -> tuple[Vector, Vector]:
    points = [obj.matrix_world @ vertex.co for vertex in obj.data.vertices]
    min_v = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    max_v = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return min_v, max_v


def keep_face_center(center: Vector, bounds_min: Vector, bounds_max: Vector) -> bool:
    # Rexx ships as a single combined mesh, so the ARKit proxy needs an
    # explicit face-feature gate. These source-space bounds were calibrated
    # from rendered landmarks on the real eye/mouth/teeth area; broader head
    # boxes overlap rear kart hardware and put morphs on the tire/engine.
    return -0.26 <= center.x <= 0.36 and -0.15 <= center.y <= 0.62 and 0.05 <= center.z <= 0.48


def carve_face_proxy(source: bpy.types.Object, offset: float) -> bpy.types.Object:
    bounds_min, bounds_max = world_bounds(source)
    source_mesh = source.data
    selected_polygons = []
    for polygon in source_mesh.polygons:
        center = Vector((0.0, 0.0, 0.0))
        for vertex_index in polygon.vertices:
            center += source.matrix_world @ source_mesh.vertices[vertex_index].co
        center /= max(len(polygon.vertices), 1)
        if keep_face_center(center, bounds_min, bounds_max):
            selected_polygons.append(polygon)

    vertex_map: dict[int, int] = {}
    vertices: list[Vector] = []
    faces: list[list[int]] = []
    material_indices: list[int] = []
    source_loop_indices: list[list[int]] = []
    for polygon in selected_polygons:
        face_indices: list[int] = []
        for vertex_index in polygon.vertices:
            if vertex_index not in vertex_map:
                vertex_map[vertex_index] = len(vertices)
                vertices.append(source_mesh.vertices[vertex_index].co.copy())
            face_indices.append(vertex_map[vertex_index])
        faces.append(face_indices)
        material_indices.append(polygon.material_index)
        source_loop_indices.append(list(polygon.loop_indices))

    proxy_mesh = bpy.data.meshes.new("ARKitFaceProxyMesh")
    proxy_mesh.from_pydata([tuple(vertex) for vertex in vertices], [], faces)
    proxy_mesh.update()
    proxy = bpy.data.objects.new("ARKitFaceProxy", proxy_mesh)
    proxy.matrix_world = source.matrix_world.copy()
    bpy.context.collection.objects.link(proxy)
    for material in source_mesh.materials:
        proxy_mesh.materials.append(material)
    for index, polygon in enumerate(proxy_mesh.polygons):
        polygon.material_index = material_indices[index]

    if source_mesh.uv_layers:
        source_uv = source_mesh.uv_layers.active
        target_uv = proxy_mesh.uv_layers.new(name=source_uv.name)
        for polygon_index, polygon in enumerate(proxy_mesh.polygons):
            source_loops = source_loop_indices[polygon_index]
            for offset_index, loop_index in enumerate(polygon.loop_indices):
                target_uv.data[loop_index].uv = source_uv.data[source_loops[offset_index]].uv

    proxy_mesh.update()

    for vertex in proxy_mesh.vertices:
        vertex.co += vertex.normal.normalized() * offset
    return proxy


def decimate_proxy(proxy: bpy.types.Object, max_polygons: int) -> None:
    if max_polygons <= 0 or len(proxy.data.polygons) <= max_polygons:
        return
    bpy.ops.object.select_all(action="DESELECT")
    proxy.select_set(True)
    bpy.context.view_layer.objects.active = proxy
    modifier = proxy.modifiers.new("ARKitProxyDecimate", "DECIMATE")
    modifier.ratio = max(0.02, min(1.0, max_polygons / max(len(proxy.data.polygons), 1)))
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def proxy_from_authored_source(path: Path) -> bpy.types.Object:
    meshes = import_glb(path)
    if not meshes:
        raise RuntimeError(f"No mesh objects found in proxy source: {path}")
    preferred = next((obj for obj in meshes if obj.name == "ARKitFaceProxy"), None)
    proxy = preferred if preferred is not None else max(meshes, key=lambda obj: len(obj.data.polygons))
    proxy.name = "ARKitFaceProxy"
    proxy.data.name = "ARKitFaceProxyMesh"
    for obj in meshes:
        if obj != proxy:
            bpy.data.objects.remove(obj, do_unlink=True)
    return proxy


def normalized_name(name: str) -> str:
    return name.lower().replace("_", " ").replace("-", " ").strip()


def is_face_part(obj: bpy.types.Object) -> bool:
    name = normalized_name(obj.name)
    if name in {"mesh 0", "arkitfaceproxy"}:
        return False
    tokens = ["eye", "lid", "brow", "nose", "lip", "mouth", "jaw", "cheek", "chin"]
    return any(token in name for token in tokens)


def proxy_from_authored_parts(path: Path) -> tuple[bpy.types.Object, list[str]]:
    meshes = import_glb(path)
    if not meshes:
        raise RuntimeError(f"No mesh objects found in proxy source: {path}")
    parts = [obj for obj in meshes if is_face_part(obj)]
    if not parts:
        raise RuntimeError(f"No named face parts found in proxy source: {path}")

    material_slots: list[bpy.types.Material] = []
    material_lookup: dict[str, int] = {}
    vertices: list[Vector] = []
    faces: list[list[int]] = []
    material_indices: list[int] = []
    part_names_by_vertex: list[str] = []
    uv_by_loop: list[list[tuple[float, float]]] = []
    has_uvs = any(part.data.uv_layers.active is not None for part in parts)

    for part in parts:
        mesh = part.data
        vertex_offset = len(vertices)
        part_name = normalized_name(part.name)
        for vertex in mesh.vertices:
            vertices.append(part.matrix_world @ vertex.co)
            part_names_by_vertex.append(part_name)

        for polygon in mesh.polygons:
            faces.append([vertex_offset + vertex_index for vertex_index in polygon.vertices])
            material = mesh.materials[polygon.material_index] if polygon.material_index < len(mesh.materials) else None
            material_key = material.name if material is not None else ""
            if material_key not in material_lookup:
                material_lookup[material_key] = len(material_slots)
                material_slots.append(material)
            material_indices.append(material_lookup[material_key])
            if has_uvs:
                active_uv = mesh.uv_layers.active
                if active_uv is None:
                    uv_by_loop.append([(0.0, 0.0) for _vertex_index in polygon.vertices])
                else:
                    uv_by_loop.append([tuple(active_uv.data[loop_index].uv) for loop_index in polygon.loop_indices])

    proxy_mesh = bpy.data.meshes.new("ARKitFaceProxyMesh")
    proxy_mesh.from_pydata([tuple(vertex) for vertex in vertices], [], faces)
    proxy_mesh.update()
    proxy = bpy.data.objects.new("ARKitFaceProxy", proxy_mesh)
    bpy.context.collection.objects.link(proxy)
    for material in material_slots:
        proxy_mesh.materials.append(material)
    for index, polygon in enumerate(proxy_mesh.polygons):
        polygon.material_index = material_indices[index]
    if has_uvs:
        target_uv = proxy_mesh.uv_layers.new(name="UVMap")
        for polygon_index, polygon in enumerate(proxy_mesh.polygons):
            for offset_index, loop_index in enumerate(polygon.loop_indices):
                target_uv.data[loop_index].uv = uv_by_loop[polygon_index][offset_index]

    for obj in meshes:
        bpy.data.objects.remove(obj, do_unlink=True)
    return proxy, part_names_by_vertex


def existing_shape_key_moved_counts(proxy: bpy.types.Object) -> dict[str, int]:
    if proxy.data.shape_keys is None:
        return {}
    basis = proxy.data.shape_keys.key_blocks.get("Basis")
    if basis is None:
        return {}
    moved_counts: dict[str, int] = {}
    for shape_name in ARKIT_BLEND_SHAPE_NAMES:
        key = proxy.data.shape_keys.key_blocks.get(shape_name)
        if key is None:
            continue
        moved = 0
        for i, point in enumerate(key.data):
            if (point.co - basis.data[i].co).length > 0.00001:
                moved += 1
        moved_counts[shape_name] = moved
    return moved_counts


def clamp01(value: float) -> float:
    return max(0.0, min(1.0, value))


def smoothstep(edge0: float, edge1: float, value: float) -> float:
    t = clamp01((value - edge0) / max(edge1 - edge0, 0.0001))
    return t * t * (3.0 - 2.0 * t)


def gaussian3(coord: tuple[float, float, float], center: tuple[float, float, float], sigma: tuple[float, float, float]) -> float:
    total = 0.0
    for c, m, s in zip(coord, center, sigma):
        total += ((c - m) / max(s, 0.0001)) ** 2
    return math.exp(-0.5 * total)


def normalized_coord(co: Vector, bounds_min: Vector, bounds_max: Vector) -> tuple[float, float, float]:
    size = bounds_max - bounds_min
    return (
        (co.x - bounds_min.x) / max(size.x, 0.0001),
        (co.y - bounds_min.y) / max(size.y, 0.0001),
        (co.z - bounds_min.z) / max(size.z, 0.0001),
    )


def side_center(side: str) -> float:
    return 0.68 if side == "Left" else 0.32


def side_sign(side: str) -> float:
    return 1.0 if side == "Left" else -1.0


def region_weight(name: str, coord: tuple[float, float, float]) -> float:
    x, y, z = coord
    lower_face = smoothstep(0.45, 0.72, x) * smoothstep(0.15, 0.50, y) * (1.0 - smoothstep(0.55, 0.75, y))
    mouth_center = gaussian3(coord, (0.86, 0.34, 0.50), (0.16, 0.16, 0.22))
    nose = gaussian3(coord, (0.95, 0.50, 0.50), (0.12, 0.13, 0.18))
    brow_center = gaussian3(coord, (0.73, 0.74, 0.50), (0.18, 0.12, 0.34))
    cheek_center = gaussian3(coord, (0.76, 0.48, 0.50), (0.18, 0.18, 0.45))
    if name.startswith("Jaw"):
        return lower_face
    if name.startswith("Mouth") or name == "TongueOut":
        if name.endswith("Left") or name.endswith("Right"):
            side = "Left" if name.endswith("Left") else "Right"
            return gaussian3(coord, (0.84, 0.34, side_center(side)), (0.16, 0.14, 0.18))
        return mouth_center
    if name.startswith("Eye"):
        side = "Left" if "Left" in name else "Right"
        return gaussian3(coord, (0.78, 0.64, side_center(side)), (0.15, 0.13, 0.16))
    if name.startswith("Brow"):
        if name.endswith("Left") or name.endswith("Right"):
            side = "Left" if name.endswith("Left") else "Right"
            return gaussian3(coord, (0.76, 0.75, side_center(side)), (0.16, 0.12, 0.18))
        return brow_center
    if name.startswith("Cheek"):
        if name.endswith("Left") or name.endswith("Right"):
            side = "Left" if name.endswith("Left") else "Right"
            return gaussian3(coord, (0.77, 0.49, side_center(side)), (0.17, 0.16, 0.20))
        return cheek_center
    if name.startswith("Nose"):
        if name.endswith("Left") or name.endswith("Right"):
            side = "Left" if name.endswith("Left") else "Right"
            return gaussian3(coord, (0.96, 0.49, side_center(side)), (0.11, 0.12, 0.18))
        return nose
    return 0.0


def displacement_for_shape(name: str, coord: tuple[float, float, float]) -> Vector:
    x, y, z = coord
    side = "Left" if name.endswith("Left") else "Right"
    side_out = side_sign(side)
    if name == "JawOpen":
        return Vector((0.020, -0.090, 0.000))
    if name == "JawForward":
        return Vector((0.045, 0.000, 0.000))
    if name == "JawLeft" or name == "JawRight":
        return Vector((0.000, 0.000, 0.040 * side_sign("Left" if name == "JawLeft" else "Right")))
    if name == "MouthClose":
        return Vector((-0.015, 0.035, 0.000))
    if name in ["MouthFunnel", "MouthPucker"]:
        toward_center_z = (0.5 - z) * 0.08
        return Vector((0.030, 0.000, toward_center_z))
    if name == "MouthLeft" or name == "MouthRight":
        return Vector((0.000, 0.000, 0.045 * side_sign("Left" if name == "MouthLeft" else "Right")))
    if name.startswith("MouthSmile"):
        return Vector((-0.010, 0.045, 0.025 * side_out))
    if name.startswith("MouthFrown"):
        return Vector((0.000, -0.045, 0.020 * side_out))
    if name.startswith("MouthDimple"):
        return Vector((-0.030, 0.000, 0.028 * side_out))
    if name.startswith("MouthStretch"):
        return Vector((0.000, 0.000, 0.060 * side_out))
    if name == "MouthRollLower" or name == "MouthRollUpper":
        return Vector((-0.030, 0.015 if name.endswith("Upper") else -0.015, 0.000))
    if name == "MouthShrugLower":
        return Vector((0.000, 0.040, 0.000))
    if name == "MouthShrugUpper":
        return Vector((0.000, -0.030, 0.000))
    if name.startswith("MouthPress"):
        return Vector((-0.020, -0.010, -0.018 * side_out))
    if name.startswith("MouthLowerDown"):
        return Vector((0.000, -0.055, 0.010 * side_out))
    if name.startswith("MouthUpperUp"):
        return Vector((0.000, 0.055, 0.010 * side_out))
    if name.startswith("EyeBlink") or name.startswith("EyeSquint"):
        return Vector((0.000, -0.040, 0.000))
    if name.startswith("EyeWide"):
        return Vector((0.000, 0.045, 0.000))
    if "EyeLookDown" in name:
        return Vector((0.000, -0.025, 0.000))
    if "EyeLookUp" in name:
        return Vector((0.000, 0.025, 0.000))
    if "EyeLookIn" in name:
        return Vector((0.000, 0.000, -0.020 * side_out))
    if "EyeLookOut" in name:
        return Vector((0.000, 0.000, 0.020 * side_out))
    if name.startswith("BrowDown"):
        return Vector((0.000, -0.045, 0.000))
    if name == "BrowInnerUp":
        return Vector((0.000, 0.055, 0.000))
    if name.startswith("BrowOuterUp"):
        return Vector((0.000, 0.055, 0.015 * side_out))
    if name == "CheekPuff":
        return Vector((0.018, 0.000, (z - 0.5) * 0.090))
    if name.startswith("CheekSquint"):
        return Vector((0.000, 0.040, 0.020 * side_out))
    if name.startswith("NoseSneer"):
        return Vector((0.012, 0.045, 0.018 * side_out))
    if name == "TongueOut":
        return Vector((0.060, -0.010, 0.000))
    return Vector((0.0, 0.0, 0.0))


def part_weight(shape_name: str, part_name: str, coord: tuple[float, float, float]) -> float:
    x, _y, z = coord
    is_left = "left" in part_name
    is_right = "right" in part_name
    side_match = (shape_name.endswith("Left") and is_left) or (shape_name.endswith("Right") and is_right)
    if shape_name.startswith("Eye"):
        if "eye" not in part_name and "lid" not in part_name:
            return 0.0
        if shape_name.endswith("Left") or shape_name.endswith("Right"):
            return 1.0 if side_match else 0.0
        return 1.0
    if shape_name.startswith("Brow"):
        if "brow" not in part_name:
            return 0.0
        if shape_name == "BrowInnerUp":
            return 1.0 - abs(x - 0.5) * 1.5
        if shape_name.endswith("Left") or shape_name.endswith("Right"):
            return 1.0 if side_match else 0.0
        return 1.0
    if shape_name.startswith("Nose"):
        if "nose" not in part_name:
            return 0.0
        if shape_name.endswith("Left"):
            return clamp01((x - 0.30) * 4.0)
        if shape_name.endswith("Right"):
            return clamp01((0.70 - x) * 4.0)
        return 1.0
    if shape_name.startswith("Cheek"):
        if "cheek" in part_name:
            if shape_name.endswith("Left") or shape_name.endswith("Right"):
                return 1.0 if side_match else 0.0
            return 1.0
        if "mouth corner" in part_name:
            return 0.35 if side_match else 0.0
        if shape_name == "CheekPuff" and ("jaw" in part_name or "lip" in part_name or "nose" in part_name):
            return 0.25
        return 0.0
    if shape_name.startswith("Jaw"):
        return 1.0 if "jaw" in part_name else 0.25 if "lower lip" in part_name else 0.0
    if shape_name.startswith("Mouth") or shape_name == "TongueOut":
        if "mouth corner" in part_name and (shape_name.endswith("Left") or shape_name.endswith("Right")):
            return 1.0 if side_match else 0.0
        if "lip" in part_name or "jaw" in part_name or "mouth" in part_name:
            if shape_name.endswith("Left") or shape_name.endswith("Right"):
                return 0.5 if side_match else 0.0
            if "upper" in part_name and ("Lower" in shape_name or shape_name == "MouthShrugLower"):
                return 0.0
            if "lower" in part_name and ("Upper" in shape_name or shape_name == "MouthShrugUpper"):
                return 0.0
            return 1.0
    return region_weight(shape_name, coord)


def part_displacement_for_shape(name: str, coord: tuple[float, float, float]) -> Vector:
    x, _y, _z = coord
    side = "Left" if name.endswith("Left") else "Right"
    side_out = 1.0 if side == "Left" else -1.0
    if name == "JawOpen":
        return Vector((0.000, -0.025, -0.075))
    if name == "JawForward":
        return Vector((0.000, -0.055, 0.000))
    if name in ["JawLeft", "JawRight"]:
        return Vector((0.045 * (1.0 if name == "JawLeft" else -1.0), 0.000, 0.000))
    if name == "MouthClose":
        return Vector((0.000, 0.000, 0.028))
    if name in ["MouthFunnel", "MouthPucker"]:
        return Vector(((0.5 - x) * 0.055, -0.030, 0.000))
    if name in ["MouthLeft", "MouthRight"]:
        return Vector((0.050 * (1.0 if name == "MouthLeft" else -1.0), 0.000, 0.000))
    if name.startswith("MouthSmile"):
        return Vector((0.030 * side_out, 0.000, 0.045))
    if name.startswith("MouthFrown"):
        return Vector((0.020 * side_out, 0.000, -0.045))
    if name.startswith("MouthDimple"):
        return Vector((0.020 * side_out, 0.025, 0.000))
    if name.startswith("MouthStretch"):
        return Vector((0.060 * side_out, 0.000, 0.000))
    if name == "MouthRollLower":
        return Vector((0.000, -0.015, 0.025))
    if name == "MouthRollUpper":
        return Vector((0.000, -0.015, -0.020))
    if name == "MouthShrugLower":
        return Vector((0.000, 0.000, 0.040))
    if name == "MouthShrugUpper":
        return Vector((0.000, 0.000, -0.030))
    if name.startswith("MouthPress"):
        return Vector((-0.018 * side_out, 0.020, -0.010))
    if name.startswith("MouthLowerDown"):
        return Vector((0.010 * side_out, 0.000, -0.050))
    if name.startswith("MouthUpperUp"):
        return Vector((0.010 * side_out, 0.000, 0.050))
    if name.startswith("EyeBlink") or name.startswith("EyeSquint"):
        return Vector((0.000, 0.000, -0.042))
    if name.startswith("EyeWide"):
        return Vector((0.000, 0.000, 0.040))
    if "EyeLookDown" in name:
        return Vector((0.000, 0.000, -0.020))
    if "EyeLookUp" in name:
        return Vector((0.000, 0.000, 0.020))
    if "EyeLookIn" in name:
        return Vector((-0.018 * side_out, 0.000, 0.000))
    if "EyeLookOut" in name:
        return Vector((0.018 * side_out, 0.000, 0.000))
    if name.startswith("BrowDown"):
        return Vector((0.000, 0.000, -0.045))
    if name == "BrowInnerUp":
        return Vector(((0.5 - x) * 0.020, 0.000, 0.055))
    if name.startswith("BrowOuterUp"):
        return Vector((0.010 * side_out, 0.000, 0.055))
    if name == "CheekPuff":
        return Vector(((x - 0.5) * 0.075, -0.020, 0.020))
    if name.startswith("CheekSquint"):
        return Vector((0.018 * side_out, 0.000, 0.035))
    if name.startswith("NoseSneer"):
        return Vector((0.012 * side_out, -0.012, 0.035))
    if name == "TongueOut":
        return Vector((0.000, -0.060, -0.010))
    return Vector((0.0, 0.0, 0.0))


def add_shape_keys(proxy: bpy.types.Object, part_names_by_vertex: list[str] | None = None) -> dict[str, int]:
    bpy.context.view_layer.objects.active = proxy
    proxy.select_set(True)
    if proxy.data.shape_keys:
        proxy.shape_key_clear()
    proxy.shape_key_add(name="Basis", from_mix=False)
    bounds_min, bounds_max = world_bounds(proxy)
    moved_counts: dict[str, int] = {}
    basis_coords = [vertex.co.copy() for vertex in proxy.data.vertices]
    for shape_name in ARKIT_BLEND_SHAPE_NAMES:
        key = proxy.shape_key_add(name=shape_name, from_mix=False)
        key.value = 0.0
        moved = 0
        for i, base in enumerate(basis_coords):
            world = proxy.matrix_world @ base
            coord = normalized_coord(world, bounds_min, bounds_max)
            if part_names_by_vertex is not None:
                weight = part_weight(shape_name, part_names_by_vertex[i], coord)
                delta = part_displacement_for_shape(shape_name, coord) * weight
            else:
                weight = region_weight(shape_name, coord)
                delta = displacement_for_shape(shape_name, coord) * weight
            if weight <= 0.002:
                continue
            key.data[i].co = base + delta
            moved += 1
        moved_counts[shape_name] = moved
    for key in proxy.data.shape_keys.key_blocks:
        key.value = 0.0 if key.name != "Basis" else 1.0
    return moved_counts


def export_glb(output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=str(output_path),
        export_format="GLB",
        use_selection=False,
        export_morph=True,
        export_materials="EXPORT",
        export_image_format="AUTO",
    )


def main() -> None:
    args = parse_args()
    input_path = Path(args.input)
    output_path = Path(args.output)
    report_path = Path(args.report)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    clear_scene()
    meshes = import_glb(input_path)
    source = largest_mesh(meshes)
    if args.proxy_source:
        proxy_source_path = Path(args.proxy_source)
        source_meshes = import_glb(proxy_source_path)
        has_proxy = any(obj.name == "ARKitFaceProxy" for obj in source_meshes)
        face_parts = [obj for obj in source_meshes if is_face_part(obj)]
        for obj in source_meshes:
            bpy.data.objects.remove(obj, do_unlink=True)
        use_parts = args.proxy_source_mode == "parts" or (args.proxy_source_mode == "auto" and not has_proxy and len(face_parts) > 1)
        if use_parts:
            proxy, part_names_by_vertex = proxy_from_authored_parts(proxy_source_path)
            moved_counts = add_shape_keys(proxy, part_names_by_vertex)
        else:
            proxy = proxy_from_authored_source(proxy_source_path)
            moved_counts = add_shape_keys(proxy) if proxy.data.shape_keys is None else existing_shape_key_moved_counts(proxy)
    else:
        proxy = carve_face_proxy(source, args.proxy_offset)
        decimate_proxy(proxy, args.max_proxy_polygons)
        moved_counts = add_shape_keys(proxy)
    export_glb(output_path)

    source_min, source_max = world_bounds(source)
    proxy_min, proxy_max = world_bounds(proxy)
    report = {
        "source": str(input_path),
        "output": str(output_path),
        "target_mesh": source.name,
        "proxy_mesh": proxy.name,
        "source_vertex_count": len(source.data.vertices),
        "source_polygon_count": len(source.data.polygons),
        "proxy_vertex_count": len(proxy.data.vertices),
        "proxy_polygon_count": len(proxy.data.polygons),
        "source_bounds": {"min": list(source_min), "max": list(source_max)},
        "proxy_bounds": {"min": list(proxy_min), "max": list(proxy_max)},
        "shape_key_count": len(ARKIT_BLEND_SHAPE_NAMES),
        "moved_vertex_counts": moved_counts,
        "method": "Named face-part proxy with generated ARKit shape keys." if args.proxy_source else "Non-destructive face/head proxy carved from Rexx head region; original mesh preserved.",
    }
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
