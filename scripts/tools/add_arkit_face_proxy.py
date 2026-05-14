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
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else sys.argv[1:]
    return parser.parse_args(argv)


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def import_glb(path: Path) -> list[bpy.types.Object]:
    bpy.ops.import_scene.gltf(filepath=str(path))
    return [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]


def largest_mesh(objects: list[bpy.types.Object]) -> bpy.types.Object:
    return max(objects, key=lambda obj: len(obj.data.polygons))


def world_bounds(obj: bpy.types.Object) -> tuple[Vector, Vector]:
    points = [obj.matrix_world @ vertex.co for vertex in obj.data.vertices]
    min_v = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    max_v = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return min_v, max_v


def keep_face_center(center: Vector, bounds_min: Vector, bounds_max: Vector) -> bool:
    size = bounds_max - bounds_min
    x = (center.x - bounds_min.x) / max(size.x, 0.0001)
    y = (center.y - bounds_min.y) / max(size.y, 0.0001)
    z = (center.z - bounds_min.z) / max(size.z, 0.0001)
    centered_z = abs(z - 0.5)
    return x > 0.37 and y > 0.36 and centered_z < 0.35


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


def add_shape_keys(proxy: bpy.types.Object) -> dict[str, int]:
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
            weight = region_weight(shape_name, coord)
            if weight <= 0.002:
                continue
            delta = displacement_for_shape(shape_name, coord) * weight
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
        "method": "Non-destructive face/head proxy carved from Rexx head region; original mesh preserved.",
    }
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
