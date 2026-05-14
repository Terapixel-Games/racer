import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def import_glb(path: Path) -> list[bpy.types.Object]:
    bpy.ops.import_scene.gltf(filepath=str(path))
    return [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]


def combined_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    points: list[Vector] = []
    for obj in objects:
        for corner in obj.bound_box:
            points.append(obj.matrix_world @ Vector(corner))
    min_v = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    max_v = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return min_v, max_v


def look_at(camera: bpy.types.Object, target: Vector) -> None:
    direction = target - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def render_view(output: Path, center: Vector, size: Vector, direction: Vector) -> None:
    camera_data = bpy.data.cameras.new("ReviewCamera")
    camera = bpy.data.objects.new("ReviewCamera", camera_data)
    bpy.context.collection.objects.link(camera)
    radius = max(size.x, size.y, size.z) * 2.2
    camera.location = center + direction.normalized() * radius
    camera_data.lens = 55
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = max(size.x, size.y, size.z) * 1.25
    look_at(camera, center)
    bpy.context.scene.camera = camera
    bpy.context.scene.render.filepath = str(output)
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(camera, do_unlink=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output-dir", required=True)
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else sys.argv[1:]
    args = parser.parse_args(argv)

    input_path = Path(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    clear_scene()
    objects = import_glb(input_path)
    min_v, max_v = combined_bounds(objects)
    center = (min_v + max_v) * 0.5
    size = max_v - min_v

    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    if hasattr(bpy.context.scene, "eevee"):
        bpy.context.scene.eevee.taa_render_samples = 16
    bpy.context.scene.render.resolution_x = 960
    bpy.context.scene.render.resolution_y = 960
    bpy.context.scene.view_settings.view_transform = "Standard"
    world = bpy.context.scene.world or bpy.data.worlds.new("World")
    bpy.context.scene.world = world
    world.color = (0.78, 0.78, 0.78)

    light_data = bpy.data.lights.new("KeyLight", "AREA")
    light = bpy.data.objects.new("KeyLight", light_data)
    bpy.context.collection.objects.link(light)
    light.location = center + Vector((0.0, -3.0, 5.0))
    light_data.energy = 700
    light_data.size = 4.0

    views = {
        "front_z_plus": Vector((0, 0, 1)),
        "back_z_minus": Vector((0, 0, -1)),
        "right_x_plus": Vector((1, 0, 0)),
        "left_x_minus": Vector((-1, 0, 0)),
        "top_y_plus": Vector((0, 1, 0)),
        "three_quarter": Vector((1, -1, 1)),
    }
    for name, direction in views.items():
        render_view(output_dir / f"{input_path.stem}_{name}.png", center, size, direction)


if __name__ == "__main__":
    main()
