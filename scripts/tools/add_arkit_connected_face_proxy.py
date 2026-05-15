import argparse
import json
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

FACE_TOKENS = ["eye", "lid", "brow", "nose", "lip", "mouth", "jaw", "cheek", "chin"]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--mask-blend", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--mask-margin", type=float, default=0.018)
    parser.add_argument("--proxy-margin", type=float, default=0.012)
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else sys.argv[1:]
    return parser.parse_args(argv)


def clear_scene() -> None:
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)


def normalized_name(name: str) -> str:
    return name.lower().replace("_", " ").replace("-", " ").strip()


def is_face_part(obj: bpy.types.Object) -> bool:
    name = normalized_name(obj.name)
    if name in {"mesh 0", "arkitfaceproxy"}:
        return False
    return obj.type == "MESH" and any(token in name for token in FACE_TOKENS)


def world_bounds(obj: bpy.types.Object) -> tuple[Vector, Vector]:
    points = [obj.matrix_world @ vertex.co for vertex in obj.data.vertices]
    return (
        Vector((min(point.x for point in points), min(point.y for point in points), min(point.z for point in points))),
        Vector((max(point.x for point in points), max(point.y for point in points), max(point.z for point in points))),
    )


def mask_bounds_from_blend(path: Path) -> list[dict]:
    bpy.ops.wm.open_mainfile(filepath=str(path))
    masks = []
    for obj in bpy.context.scene.objects:
        if not is_face_part(obj):
            continue
        min_v, max_v = world_bounds(obj)
        masks.append({"name": normalized_name(obj.name), "min": min_v, "max": max_v, "diagonal": (max_v - min_v).length})
    if not masks:
        raise RuntimeError(f"No face-part masks found in {path}")
    return masks


def import_source_mesh(path: Path) -> bpy.types.Object:
    clear_scene()
    bpy.ops.import_scene.gltf(filepath=str(path))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError(f"No mesh objects found in {path}")
    return max(meshes, key=lambda obj: len(obj.data.polygons))


def combined_face_bounds(masks: list[dict], margin: float) -> tuple[Vector, Vector]:
    stable_masks = [mask for mask in masks if mask["diagonal"] <= 0.65]
    if not stable_masks:
        stable_masks = masks
    min_v = Vector((min(mask["min"].x for mask in stable_masks), min(mask["min"].y for mask in stable_masks), min(mask["min"].z for mask in stable_masks)))
    max_v = Vector((max(mask["max"].x for mask in stable_masks), max(mask["max"].y for mask in stable_masks), max(mask["max"].z for mask in stable_masks)))
    return min_v - Vector((margin, margin, margin)), max_v + Vector((margin, margin, margin))


def point_in_bounds(point: Vector, min_v: Vector, max_v: Vector) -> bool:
    return min_v.x <= point.x <= max_v.x and min_v.y <= point.y <= max_v.y and min_v.z <= point.z <= max_v.z


def carve_connected_proxy(source: bpy.types.Object, masks: list[dict], proxy_margin: float) -> bpy.types.Object:
    min_v, max_v = combined_face_bounds(masks, proxy_margin)
    source_mesh = source.data
    selected_polygons = []
    for polygon in source_mesh.polygons:
        center = Vector((0.0, 0.0, 0.0))
        for vertex_index in polygon.vertices:
            center += source.matrix_world @ source_mesh.vertices[vertex_index].co
        center /= max(len(polygon.vertices), 1)
        if point_in_bounds(center, min_v, max_v):
            selected_polygons.append(polygon)

    vertex_map: dict[int, int] = {}
    vertices: list[Vector] = []
    faces: list[list[int]] = []
    material_indices: list[int] = []
    source_loop_indices: list[list[int]] = []
    for polygon in selected_polygons:
        face_indices = []
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
            for offset_index, loop_index in enumerate(polygon.loop_indices):
                target_uv.data[loop_index].uv = source_uv.data[source_loop_indices[polygon_index][offset_index]].uv

    return proxy


def clamp01(value: float) -> float:
    return max(0.0, min(1.0, value))


def bbox_weight(point: Vector, min_v: Vector, max_v: Vector, margin: float) -> float:
    expanded_min = min_v - Vector((margin, margin, margin))
    expanded_max = max_v + Vector((margin, margin, margin))
    if not point_in_bounds(point, expanded_min, expanded_max):
        return 0.0
    if point_in_bounds(point, min_v, max_v):
        return 1.0
    distances = [
        abs(point.x - min_v.x),
        abs(point.x - max_v.x),
        abs(point.y - min_v.y),
        abs(point.y - max_v.y),
        abs(point.z - min_v.z),
        abs(point.z - max_v.z),
    ]
    return clamp01(1.0 - min(distances) / max(margin, 0.0001))


def mask_relevance(shape_name: str, mask_name: str) -> float:
    is_left = "left" in mask_name
    is_right = "right" in mask_name
    side_match = (shape_name.endswith("Left") and is_left) or (shape_name.endswith("Right") and is_right)
    if shape_name.startswith("Eye"):
        if "eye" not in mask_name and "lid" not in mask_name:
            return 0.0
        return 1.0 if not (shape_name.endswith("Left") or shape_name.endswith("Right")) or side_match else 0.0
    if shape_name.startswith("Brow"):
        if "brow" not in mask_name:
            return 0.0
        return 1.0 if shape_name == "BrowInnerUp" or side_match else 0.0
    if shape_name.startswith("Nose"):
        return 1.0 if "nose" in mask_name else 0.0
    if shape_name.startswith("Cheek"):
        if "cheek" in mask_name:
            return 1.0 if shape_name == "CheekPuff" or side_match else 0.0
        if "mouth corner" in mask_name:
            return 0.45 if shape_name == "CheekPuff" or side_match else 0.0
        if shape_name == "CheekPuff" and ("jaw" in mask_name or "lip" in mask_name or "nose" in mask_name):
            return 0.18
        return 0.0
    if shape_name.startswith("Jaw"):
        return 1.0 if "jaw" in mask_name else 0.25 if "lower lip" in mask_name else 0.0
    if shape_name.startswith("Mouth") or shape_name == "TongueOut":
        if "mouth corner" in mask_name and (shape_name.endswith("Left") or shape_name.endswith("Right")):
            return 1.0 if side_match else 0.0
        if "lip" in mask_name or "jaw" in mask_name or "mouth" in mask_name:
            if shape_name.endswith("Left") or shape_name.endswith("Right"):
                return 0.55 if side_match else 0.0
            return 1.0
    return 0.0


def displacement_for_shape(name: str, coord: tuple[float, float, float]) -> Vector:
    x, _y, _z = coord
    side = "Left" if name.endswith("Left") else "Right"
    side_out = 1.0 if side == "Left" else -1.0
    if name == "JawOpen":
        return Vector((0.000, -0.022, -0.065))
    if name == "JawForward":
        return Vector((0.000, -0.050, 0.000))
    if name in ["JawLeft", "JawRight"]:
        return Vector((0.038 * (1.0 if name == "JawLeft" else -1.0), 0.000, 0.000))
    if name == "MouthClose":
        return Vector((0.000, 0.000, 0.024))
    if name in ["MouthFunnel", "MouthPucker"]:
        return Vector(((0.5 - x) * 0.048, -0.026, 0.000))
    if name in ["MouthLeft", "MouthRight"]:
        return Vector((0.044 * (1.0 if name == "MouthLeft" else -1.0), 0.000, 0.000))
    if name.startswith("MouthSmile"):
        return Vector((0.026 * side_out, 0.000, 0.038))
    if name.startswith("MouthFrown"):
        return Vector((0.018 * side_out, 0.000, -0.038))
    if name.startswith("MouthDimple"):
        return Vector((0.018 * side_out, 0.020, 0.000))
    if name.startswith("MouthStretch"):
        return Vector((0.050 * side_out, 0.000, 0.000))
    if name == "MouthRollLower":
        return Vector((0.000, -0.012, 0.020))
    if name == "MouthRollUpper":
        return Vector((0.000, -0.012, -0.018))
    if name == "MouthShrugLower":
        return Vector((0.000, 0.000, 0.034))
    if name == "MouthShrugUpper":
        return Vector((0.000, 0.000, -0.026))
    if name.startswith("MouthPress"):
        return Vector((-0.016 * side_out, 0.016, -0.008))
    if name.startswith("MouthLowerDown"):
        return Vector((0.008 * side_out, 0.000, -0.042))
    if name.startswith("MouthUpperUp"):
        return Vector((0.008 * side_out, 0.000, 0.042))
    if name.startswith("EyeBlink") or name.startswith("EyeSquint"):
        return Vector((0.000, 0.000, -0.036))
    if name.startswith("EyeWide"):
        return Vector((0.000, 0.000, 0.034))
    if "EyeLookDown" in name:
        return Vector((0.000, 0.000, -0.018))
    if "EyeLookUp" in name:
        return Vector((0.000, 0.000, 0.018))
    if "EyeLookIn" in name:
        return Vector((-0.016 * side_out, 0.000, 0.000))
    if "EyeLookOut" in name:
        return Vector((0.016 * side_out, 0.000, 0.000))
    if name.startswith("BrowDown"):
        return Vector((0.000, 0.000, -0.038))
    if name == "BrowInnerUp":
        return Vector(((0.5 - x) * 0.018, 0.000, 0.046))
    if name.startswith("BrowOuterUp"):
        return Vector((0.008 * side_out, 0.000, 0.046))
    if name == "CheekPuff":
        return Vector(((x - 0.5) * 0.060, -0.016, 0.016))
    if name.startswith("CheekSquint"):
        return Vector((0.016 * side_out, 0.000, 0.030))
    if name.startswith("NoseSneer"):
        return Vector((0.010 * side_out, -0.010, 0.030))
    if name == "TongueOut":
        return Vector((0.000, -0.050, -0.008))
    return Vector((0.0, 0.0, 0.0))


def normalized_coord(point: Vector, min_v: Vector, max_v: Vector) -> tuple[float, float, float]:
    size = max_v - min_v
    return (
        (point.x - min_v.x) / max(size.x, 0.0001),
        (point.y - min_v.y) / max(size.y, 0.0001),
        (point.z - min_v.z) / max(size.z, 0.0001),
    )


def add_shape_keys(proxy: bpy.types.Object, masks: list[dict], mask_margin: float) -> dict[str, int]:
    bpy.context.view_layer.objects.active = proxy
    proxy.select_set(True)
    if proxy.data.shape_keys:
        proxy.shape_key_clear()
    proxy.shape_key_add(name="Basis", from_mix=False)
    proxy_min, proxy_max = world_bounds(proxy)
    basis_coords = [vertex.co.copy() for vertex in proxy.data.vertices]
    moved_counts: dict[str, int] = {}
    for shape_name in ARKIT_BLEND_SHAPE_NAMES:
        key = proxy.shape_key_add(name=shape_name, from_mix=False)
        moved = 0
        for index, base in enumerate(basis_coords):
            world = proxy.matrix_world @ base
            weight = 0.0
            for mask in masks:
                relevance = mask_relevance(shape_name, mask["name"])
                if relevance <= 0.0:
                    continue
                weight = max(weight, relevance * bbox_weight(world, mask["min"], mask["max"], mask_margin))
            if weight <= 0.002:
                continue
            coord = normalized_coord(world, proxy_min, proxy_max)
            key.data[index].co = base + displacement_for_shape(shape_name, coord) * weight
            moved += 1
        key.value = 0.0
        moved_counts[shape_name] = moved
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
    masks = mask_bounds_from_blend(Path(args.mask_blend))
    source = import_source_mesh(Path(args.input))
    proxy = carve_connected_proxy(source, masks, args.proxy_margin)
    moved_counts = add_shape_keys(proxy, masks, args.mask_margin)
    export_glb(Path(args.output))

    source_min, source_max = world_bounds(source)
    proxy_min, proxy_max = world_bounds(proxy)
    report = {
        "source": args.input,
        "mask_blend": args.mask_blend,
        "output": args.output,
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
        "mask_names": [mask["name"] for mask in masks],
        "method": "Connected face proxy carved from optimized Rexx mesh; vertex-group blend file used as morph masks.",
    }
    report_path = Path(args.report)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
