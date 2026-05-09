import math
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets" / "gameplay" / "tracks" / "shared" / "backyard_optimized"
ATLAS_PATH = OUT_DIR / "backyard_atlas.png"

TILES = {
    "wood": (0, 0, (0.58, 0.33, 0.14, 1.0)),
    "dark_wood": (1, 0, (0.33, 0.18, 0.08, 1.0)),
    "red": (2, 0, (0.92, 0.13, 0.09, 1.0)),
    "blue": (3, 0, (0.08, 0.35, 0.88, 1.0)),
    "rope": (0, 1, (0.78, 0.65, 0.42, 1.0)),
    "bone": (1, 1, (0.88, 0.82, 0.62, 1.0)),
    "sand": (2, 1, (0.78, 0.62, 0.36, 1.0)),
    "leaf": (3, 1, (0.16, 0.46, 0.18, 1.0)),
    "mulch": (0, 2, (0.36, 0.16, 0.07, 1.0)),
    "metal": (1, 2, (0.72, 0.72, 0.68, 1.0)),
    "yellow": (2, 2, (0.98, 0.78, 0.16, 1.0)),
    "stone": (3, 2, (0.48, 0.47, 0.43, 1.0)),
    "grass": (0, 3, (0.23, 0.42, 0.18, 1.0)),
    "bucket": (1, 3, (0.9, 0.18, 0.12, 1.0)),
    "plastic": (2, 3, (0.98, 0.82, 0.18, 1.0)),
    "shadow": (3, 3, (0.08, 0.08, 0.08, 1.0)),
}


def tile_uv(tile_name):
    col, row, _color = TILES[tile_name]
    tile_size = 1.0 / 4.0
    pad = 0.012
    u0 = col * tile_size + pad
    v0 = 1.0 - (row + 1) * tile_size + pad
    u1 = (col + 1) * tile_size - pad
    v1 = 1.0 - row * tile_size - pad
    return [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def make_material():
    material = bpy.data.materials.new("BackyardAtlasUV")
    material.diffuse_color = (1, 1, 1, 1)
    return material


def create_atlas():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    size = 1024
    image = bpy.data.images.new("backyard_atlas", width=size, height=size, alpha=True)
    pixels = [0.0] * (size * size * 4)
    tile_px = size // 4
    for tile_name, (col, row, color) in TILES.items():
        for y in range(row * tile_px, (row + 1) * tile_px):
            for x in range(col * tile_px, (col + 1) * tile_px):
                shade = 1.0
                if (x // 16 + y // 16) % 2 == 0:
                    shade = 0.93
                idx = (y * size + x) * 4
                pixels[idx] = color[0] * shade
                pixels[idx + 1] = color[1] * shade
                pixels[idx + 2] = color[2] * shade
                pixels[idx + 3] = color[3]
    image.pixels = pixels
    image.filepath_raw = str(ATLAS_PATH)
    image.file_format = "PNG"
    image.save()


def add_box(name, loc, size, tile_name, yaw=0.0):
    sx, sy, sz = size
    verts = [
        (-sx / 2, -sy / 2, -sz / 2),
        (sx / 2, -sy / 2, -sz / 2),
        (sx / 2, sy / 2, -sz / 2),
        (-sx / 2, sy / 2, -sz / 2),
        (-sx / 2, -sy / 2, sz / 2),
        (sx / 2, -sy / 2, sz / 2),
        (sx / 2, sy / 2, sz / 2),
        (-sx / 2, sy / 2, sz / 2),
    ]
    faces = [
        (0, 1, 2, 3),
        (4, 7, 6, 5),
        (0, 4, 5, 1),
        (1, 5, 6, 2),
        (2, 6, 7, 3),
        (3, 7, 4, 0),
    ]
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    uv_layer = mesh.uv_layers.new(name="UVMap")
    uv = tile_uv(tile_name)
    for poly in mesh.polygons:
        for i, loop_index in enumerate(poly.loop_indices):
            uv_layer.data[loop_index].uv = uv[i % 4]
    obj = bpy.data.objects.new(name, mesh)
    obj.location = loc
    obj.rotation_euler[2] = math.radians(yaw)
    obj.data.materials.append(bpy.data.materials["BackyardAtlasUV"])
    bpy.context.collection.objects.link(obj)
    return obj


def add_cross_brace(name, loc, length, tile_name, yaw=0.0, rise=0.0):
    obj = add_box(name, loc, (0.18, length, 0.18), tile_name, yaw)
    obj.rotation_euler[0] = math.radians(rise)
    return obj


def export_glb(asset_name):
    filepath = OUT_DIR / f"{asset_name}.glb"
    bpy.ops.export_scene.gltf(
        filepath=str(filepath),
        export_format="GLB",
        export_image_format="NONE",
        export_materials="PLACEHOLDER",
        export_animations=False,
        use_selection=False,
    )


def start_asset():
    clear_scene()
    make_material()


def build_playground_structure():
    start_asset()
    for x in [-2.4, 2.4]:
        for y in [-1.4, 1.4]:
            add_box("post", (x, y, 1.6), (0.28, 0.28, 3.2), "wood")
    add_box("deck", (0, 0, 1.55), (5.4, 3.3, 0.35), "dark_wood")
    add_box("roof", (0, 0, 3.55), (6.0, 3.8, 0.28), "red", 0)
    add_box("slide", (3.6, -0.1, 0.85), (3.3, 1.25, 0.22), "blue", 0)
    add_box("ladder_a", (-3.0, -1.05, 0.9), (0.18, 0.18, 1.9), "rope", -18)
    add_box("ladder_b", (-3.0, 1.05, 0.9), (0.18, 0.18, 1.9), "rope", 18)
    for y in [-1.2, 0.0, 1.2]:
        add_box("ladder_rung", (-3.0, y, 0.6 + abs(y) * 0.15), (0.2, 1.8, 0.18), "rope")
    for y in [-1.7, 1.7]:
        add_box("rail", (0, y, 2.15), (5.5, 0.16, 0.25), "yellow")
    export_glb("playground_structure_low")


def build_swing_set():
    start_asset()
    add_box("top_beam", (0, 0, 3.2), (5.8, 0.22, 0.22), "dark_wood")
    for x in [-2.6, 2.6]:
        add_cross_brace("leg_a", (x, -0.9, 1.55), 3.2, "wood", 0, 14 if x < 0 else -14)
        add_cross_brace("leg_b", (x, 0.9, 1.55), 3.2, "wood", 0, -14 if x < 0 else 14)
    for x in [-1.2, 1.2]:
        add_box("rope_l", (x - 0.35, 0, 2.0), (0.08, 0.08, 2.2), "rope")
        add_box("rope_r", (x + 0.35, 0, 2.0), (0.08, 0.08, 2.2), "rope")
        add_box("seat", (x, 0, 0.9), (1.0, 0.45, 0.12), "blue")
    export_glb("swing_set_low")


def build_sandbox_fossil():
    start_asset()
    add_box("spine", (0, 0, 0.9), (5.5, 0.18, 0.18), "bone")
    for i, x in enumerate([-2.0, -1.2, -0.4, 0.4, 1.2, 2.0]):
        add_box("rib_l", (x, -0.45, 1.05), (0.16, 1.05, 0.16), "bone", 22)
        add_box("rib_r", (x, 0.45, 1.05), (0.16, 1.05, 0.16), "bone", -22)
    add_box("skull", (-3.25, 0, 1.0), (0.95, 0.72, 0.52), "bone")
    add_box("jaw", (-3.55, 0, 0.55), (0.72, 0.5, 0.18), "bone")
    add_box("tail", (3.1, 0, 0.92), (1.35, 0.14, 0.14), "bone", 12)
    add_box("sand_base", (0, 0, 0.1), (6.2, 2.4, 0.2), "sand")
    export_glb("sandbox_fossil_low")


def build_garden_log_bush():
    start_asset()
    add_box("log", (-1.1, 0, 0.45), (2.4, 0.55, 0.55), "dark_wood", 10)
    add_box("log_cut_a", (-2.35, 0, 0.45), (0.18, 0.62, 0.62), "wood", 10)
    add_box("log_cut_b", (0.15, 0, 0.45), (0.18, 0.62, 0.62), "wood", 10)
    add_box("bush_core", (1.25, 0, 0.75), (1.35, 1.15, 1.15), "leaf")
    add_box("bush_lobe_a", (0.75, -0.55, 0.62), (0.85, 0.75, 0.85), "leaf")
    add_box("bush_lobe_b", (1.75, 0.45, 0.62), (0.9, 0.8, 0.8), "leaf")
    export_glb("garden_log_bush_low")


def main():
    create_atlas()
    build_playground_structure()
    build_swing_set()
    build_sandbox_fossil()
    build_garden_log_bush()


if __name__ == "__main__":
    main()
