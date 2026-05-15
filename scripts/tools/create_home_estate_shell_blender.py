import math
import json
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets" / "gameplay" / "tracks" / "home_estate_v1" / "meshes"
REVIEW_DIR = ROOT / "docs" / "concepts" / "home_estate_v1" / "reference_frames" / "modern_farmhouse_38_526" / "blender_shell_angles"
BLEND_PATH = OUT_DIR / "modern_farmhouse_shell.blend"
GLB_PATH = OUT_DIR / "modern_farmhouse_shell.glb"
ROOF_TRIM_AUDIT_PATH = REVIEW_DIR / "roof_trim_seam_audit.json"
GABLE_POINT_AUDIT_PATH = REVIEW_DIR / "gable_rake_point_closure_audit.json"
ROOF_AXIS_AUDIT_PATH = REVIEW_DIR / "roof_axis_orientation_audit.json"
ROOF_INTERSECTION_AUDIT_PATH = REVIEW_DIR / "roof_intersection_closure_audit.json"
WALL_FLUSH_AUDIT_PATH = REVIEW_DIR / "wall_plane_flush_audit.json"
ROOF_WALL_EDGE_AUDIT_PATH = REVIEW_DIR / "roof_wall_corner_edge_audit.json"
ENVELOPE_CLASH_AUDIT_PATH = REVIEW_DIR / "envelope_clearance_clash_audit.json"
ROOF_SEAM_REVIEW_CAMERAS = [
    "FrontLeftEaveSeamCamera",
    "FrontRightEaveSeamCamera",
    "RearLeftEaveSeamCamera",
    "RearRightEaveSeamCamera",
    "UndersideLeftEaveSeamCamera",
    "UndersideRightEaveSeamCamera",
]
GABLE_POINT_REVIEW_CAMERAS = [
    "MainFrontGableApexCamera",
    "MainRearGableApexCamera",
    "GarageFrontGableApexCamera",
    "GarageRearGableApexCamera",
    "MasterFrontGableApexCamera",
    "MasterRearGableApexCamera",
    "FrontPorchStreetGableApexCamera",
    "FrontPorchTieInGableApexCamera",
]
ROOF_INTERSECTION_REVIEW_CAMERAS = [
    "RearMasterWingRoofClosureCamera",
    "RearPorchRoofTieInClosureCamera",
    "GarageRearRoofClosureCamera",
    "FrontPorchRoofTieInClosureCamera",
]
WALL_FLUSH_REVIEW_CAMERAS = [
    "RightWallFlushCloseCamera",
    "MasterWingFrontReturnFlushCamera",
    "GarageSideReturnFlushCamera",
]
ROOF_WALL_EDGE_REVIEW_CAMERAS = [
    "RightFrontRoofWallEdgeCamera",
    "RightRearRoofWallEdgeCamera",
    "MasterWingOuterRoofWallEdgeCamera",
    "GarageOuterRoofWallEdgeCamera",
    "PorchRoofWallEdgeCamera",
]
ENVELOPE_CLASH_REVIEW_CAMERAS = [
    "MainRightInteriorCeilingClashCamera",
    "MasterWingInteriorCeilingClashCamera",
    "GarageInteriorCeilingClashCamera",
    "UpperEaveUndersideClashCamera",
]


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def material(name: str, color: tuple[float, float, float, float]) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = 0.68
        if color[3] < 1.0:
            bsdf.inputs["Alpha"].default_value = color[3]
            mat.blend_method = "BLEND"
    return mat


def box(name: str, loc: tuple[float, float, float], size: tuple[float, float, float], mat: bpy.types.Material) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    return obj


def object_bounds(obj: bpy.types.Object) -> tuple[Vector, Vector]:
    corners = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    mins = Vector((min(corner.x for corner in corners), min(corner.y for corner in corners), min(corner.z for corner in corners)))
    maxs = Vector((max(corner.x for corner in corners), max(corner.y for corner in corners), max(corner.z for corner in corners)))
    return mins, maxs


def beam_between(
    name: str,
    p0: tuple[float, float, float],
    p1: tuple[float, float, float],
    thickness: float,
    mat: bpy.types.Material,
    support_edge_id: str,
    neighbor_ids: tuple[str, ...],
    mitre_rule: str,
) -> bpy.types.Object:
    start = Vector(p0)
    end = Vector(p1)
    delta = end - start
    length = delta.length
    if length <= 0.001:
        raise ValueError(f"{name} has no measurable support edge")
    bpy.ops.mesh.primitive_cube_add(size=1, location=(start + end) * 0.5)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = delta.to_track_quat("X", "Z").to_euler()
    obj.dimensions = (length, thickness, thickness)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    obj["support_edge_start"] = tuple(round(v, 3) for v in p0)
    obj["support_edge_end"] = tuple(round(v, 3) for v in p1)
    obj["support_edge_id"] = support_edge_id
    obj["neighbor_ids"] = ",".join(neighbor_ids)
    obj["mitre_rule"] = mitre_rule
    obj["overrun_tolerance"] = 0.0
    obj["minimum_neighbor_overlap"] = round(thickness * 0.45, 3)
    obj["seam_gate_required"] = True
    obj["clearance_class"] = "roof_edge_trim"
    obj["interior_clearance_sensitive"] = False
    return obj


def gable_apex_cap(name: str, apex: tuple[float, float, float], mat: bpy.types.Material, roof_id: str, rake_ids: tuple[str, str], ridge_id: str) -> bpy.types.Object:
    x, y, z = apex
    thickness = 0.9
    half_width = 2.4
    drop = 2.2
    verts = [
        (x, y - thickness * 0.5, z + 0.75),
        (x - half_width, y - thickness * 0.5, z - drop),
        (x + half_width, y - thickness * 0.5, z - drop),
        (x, y + thickness * 0.5, z + 0.75),
        (x - half_width, y + thickness * 0.5, z - drop),
        (x + half_width, y + thickness * 0.5, z - drop),
    ]
    faces = [(0, 1, 2), (3, 5, 4), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)]
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    obj["closure_role"] = "gable_apex_point_cap"
    obj["clearance_class"] = "roof_edge_trim"
    obj["roof_id"] = roof_id
    obj["rake_ids"] = ",".join(rake_ids)
    obj["ridge_id"] = ridge_id
    obj["apex_coordinate"] = (round(x, 3), round(y, 3), round(z, 3))
    return obj


def gable_wall(name: str, x0: float, x1: float, y: float, base_z: float, eave_z: float, ridge_z: float, thickness: float, mat: bpy.types.Material) -> None:
    ridge_x = (x0 + x1) * 0.5
    t0 = y - thickness * 0.5
    t1 = y + thickness * 0.5
    verts = [
        (x0, t0, base_z), (x1, t0, base_z), (x1, t0, eave_z), (ridge_x, t0, ridge_z), (x0, t0, eave_z),
        (x0, t1, base_z), (x1, t1, base_z), (x1, t1, eave_z), (ridge_x, t1, ridge_z), (x0, t1, eave_z),
    ]
    faces = [
        (0, 1, 2, 3, 4), (5, 9, 8, 7, 6),
        (0, 5, 6, 1), (1, 6, 7, 2), (2, 7, 8, 3), (3, 8, 9, 4), (4, 9, 5, 0),
    ]
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    obj["closure_role"] = "gable_infill"


def solid_gable_roof(
    name: str,
    x0: float,
    x1: float,
    y0: float,
    y1: float,
    eave_z: float,
    ridge_z: float,
    roof_mat: bpy.types.Material,
    trim_mat: bpy.types.Material,
    overhang: float = 5.0,
    thickness: float = 2.2,
) -> None:
    rx0 = x0 - overhang
    rx1 = x1 + overhang
    ry0 = y0 - overhang
    ry1 = y1 + overhang
    ridge_x = (rx0 + rx1) * 0.5
    top = [
        (rx0, ry0, eave_z),
        (rx0, ry1, eave_z),
        (ridge_x, ry1, ridge_z),
        (ridge_x, ry0, ridge_z),
        (rx1, ry0, eave_z),
        (rx1, ry1, eave_z),
    ]
    bottom = [(x, y, z - thickness) for x, y, z in top]
    verts = top + bottom
    faces = [
        (0, 1, 2, 3),
        (3, 2, 5, 4),
        (6, 9, 8, 7),
        (9, 10, 11, 8),
        (0, 6, 7, 1),
        (1, 7, 8, 2),
        (2, 8, 11, 5),
        (5, 11, 10, 4),
        (4, 10, 9, 3),
        (3, 9, 6, 0),
    ]
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(roof_mat)
    obj["roof_module_id"] = name
    obj["ridge_axis"] = "y"
    obj["span_axis"] = "x"
    obj["roof_axis_rationale"] = "main and cross gables use a front/rear ridge line with gable faces at front and rear"

    beam_between(f"{name}_RidgeCap", (ridge_x, ry0, ridge_z + 0.35), (ridge_x, ry1, ridge_z + 0.35), 0.9, trim_mat, f"{name}:ridge", (f"{name}_RearLeftRake", f"{name}_RearRightRake", f"{name}_FrontLeftRake", f"{name}_FrontRightRake"), "overlap_or_mitre_into_rake_caps")
    beam_between(f"{name}_LeftEaveFascia", (rx0, ry0, eave_z - 0.8), (rx0, ry1, eave_z - 0.8), 1.0, trim_mat, f"{name}:left_eave", (f"{name}_RearLeftRake", f"{name}_FrontLeftRake"), "return_into_rake_boards")
    beam_between(f"{name}_RightEaveFascia", (rx1, ry0, eave_z - 0.8), (rx1, ry1, eave_z - 0.8), 1.0, trim_mat, f"{name}:right_eave", (f"{name}_RearRightRake", f"{name}_FrontRightRake"), "return_into_rake_boards")
    beam_between(f"{name}_FrontLeftRake", (rx0, ry1, eave_z - 0.2), (ridge_x, ry1, ridge_z + 0.15), 0.9, trim_mat, f"{name}:front_left_rake", (f"{name}_LeftEaveFascia", f"{name}_RidgeCap"), "mitre_to_eave_and_ridge")
    beam_between(f"{name}_FrontRightRake", (rx1, ry1, eave_z - 0.2), (ridge_x, ry1, ridge_z + 0.15), 0.9, trim_mat, f"{name}:front_right_rake", (f"{name}_RightEaveFascia", f"{name}_RidgeCap"), "mitre_to_eave_and_ridge")
    beam_between(f"{name}_RearLeftRake", (rx0, ry0, eave_z - 0.2), (ridge_x, ry0, ridge_z + 0.15), 0.9, trim_mat, f"{name}:rear_left_rake", (f"{name}_LeftEaveFascia", f"{name}_RidgeCap"), "mitre_to_eave_and_ridge")
    beam_between(f"{name}_RearRightRake", (rx1, ry0, eave_z - 0.2), (ridge_x, ry0, ridge_z + 0.15), 0.9, trim_mat, f"{name}:rear_right_rake", (f"{name}_RightEaveFascia", f"{name}_RidgeCap"), "mitre_to_eave_and_ridge")
    gable_apex_cap(f"{name}_FrontApexPointCap", (ridge_x, ry1, ridge_z + 0.15), trim_mat, name, (f"{name}_FrontLeftRake", f"{name}_FrontRightRake"), f"{name}_RidgeCap")
    gable_apex_cap(f"{name}_RearApexPointCap", (ridge_x, ry0, ridge_z + 0.15), trim_mat, name, (f"{name}_RearLeftRake", f"{name}_RearRightRake"), f"{name}_RidgeCap")


def solid_gable_roof_x_ridge(
    name: str,
    x0: float,
    x1: float,
    y0: float,
    y1: float,
    eave_z: float,
    ridge_z: float,
    roof_mat: bpy.types.Material,
    trim_mat: bpy.types.Material,
    overhang: float = 5.0,
    thickness: float = 2.2,
) -> None:
    rx0 = x0 - overhang
    rx1 = x1 + overhang
    ry0 = y0 - overhang
    ry1 = y1 + overhang
    ridge_y = (ry0 + ry1) * 0.5
    top = [
        (rx0, ry0, eave_z),
        (rx1, ry0, eave_z),
        (rx1, ridge_y, ridge_z),
        (rx0, ridge_y, ridge_z),
        (rx0, ry1, eave_z),
        (rx1, ry1, eave_z),
    ]
    bottom = [(x, y, z - thickness) for x, y, z in top]
    verts = top + bottom
    faces = [
        (0, 1, 2, 3),
        (3, 2, 5, 4),
        (6, 9, 8, 7),
        (9, 10, 11, 8),
        (0, 6, 7, 1),
        (1, 7, 8, 2),
        (2, 8, 11, 5),
        (5, 11, 10, 4),
        (4, 10, 9, 3),
        (3, 9, 6, 0),
    ]
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(roof_mat)
    obj["roof_module_id"] = name
    obj["ridge_axis"] = "x"
    obj["span_axis"] = "y"
    obj["roof_axis_rationale"] = "covered porch/patio roofs run along the facade only when the reference calls for a lateral porch roof"

    beam_between(f"{name}_RidgeCap", (rx0, ridge_y, ridge_z + 0.35), (rx1, ridge_y, ridge_z + 0.35), 0.9, trim_mat, f"{name}:ridge", (f"{name}_LeftRake", f"{name}_RightRake"), "overlap_or_mitre_into_rake_caps")
    beam_between(f"{name}_FrontEaveFascia", (rx0, ry1, eave_z - 0.8), (rx1, ry1, eave_z - 0.8), 1.0, trim_mat, f"{name}:front_eave", (f"{name}_LeftRake", f"{name}_RightRake"), "return_into_rake_boards")
    beam_between(f"{name}_RearEaveFascia", (rx0, ry0, eave_z - 0.8), (rx1, ry0, eave_z - 0.8), 1.0, trim_mat, f"{name}:rear_eave", (f"{name}_LeftRake", f"{name}_RightRake"), "return_into_rake_boards")
    beam_between(f"{name}_LeftRake", (rx0, ry0, eave_z - 0.2), (rx0, ridge_y, ridge_z + 0.15), 0.9, trim_mat, f"{name}:left_rake", (f"{name}_RearEaveFascia", f"{name}_RidgeCap", f"{name}_FrontEaveFascia"), "mitre_to_eave_and_ridge")
    beam_between(f"{name}_RightRake", (rx1, ry0, eave_z - 0.2), (rx1, ridge_y, ridge_z + 0.15), 0.9, trim_mat, f"{name}:right_rake", (f"{name}_RearEaveFascia", f"{name}_RidgeCap", f"{name}_FrontEaveFascia"), "mitre_to_eave_and_ridge")


def window(name: str, loc: tuple[float, float, float], size: tuple[float, float, float], glass_mat, trim_mat) -> None:
    box(f"{name}_Glass", loc, size, glass_mat)
    width, depth, height = size
    x, y, z = loc
    if width > depth:
        box(f"{name}_TopTrim", (x, y, z + height * 0.5 + 0.65), (width + 1.6, depth + 0.3, 0.8), trim_mat)
        box(f"{name}_BottomTrim", (x, y, z - height * 0.5 - 0.65), (width + 1.6, depth + 0.3, 0.8), trim_mat)
        box(f"{name}_LeftTrim", (x - width * 0.5 - 0.65, y, z), (0.8, depth + 0.3, height + 1.6), trim_mat)
        box(f"{name}_RightTrim", (x + width * 0.5 + 0.65, y, z), (0.8, depth + 0.3, height + 1.6), trim_mat)
    else:
        box(f"{name}_TopTrim", (x, y, z + height * 0.5 + 0.65), (width + 0.3, depth + 1.6, 0.8), trim_mat)
        box(f"{name}_BottomTrim", (x, y, z - height * 0.5 - 0.65), (width + 0.3, depth + 1.6, 0.8), trim_mat)
        box(f"{name}_LeftTrim", (x, y - depth * 0.5 - 0.65, z), (width + 0.3, 0.8, height + 1.6), trim_mat)
        box(f"{name}_RightTrim", (x, y + depth * 0.5 + 0.65, z), (width + 0.3, 0.8, height + 1.6), trim_mat)


def add_wall_shell(prefix: str, center: tuple[float, float], size: tuple[float, float], z_center: float, height: float, mat: bpy.types.Material, thickness: float = 4.0) -> None:
    cx, cy = center
    sx, sy = size
    box(f"{prefix}_FrontWall", (cx, cy + sy * 0.5, z_center), (sx, thickness, height), mat)
    box(f"{prefix}_RearWall", (cx, cy - sy * 0.5, z_center), (sx, thickness, height), mat)
    box(f"{prefix}_LeftWall", (cx - sx * 0.5, cy, z_center), (thickness, sy, height), mat)
    box(f"{prefix}_RightWall", (cx + sx * 0.5, cy, z_center), (thickness, sy, height), mat)


def add_board_batten(prefix: str, x0: float, x1: float, y: float, z0: float, z1: float, trim_mat: bpy.types.Material) -> None:
    count = max(3, int(abs(x1 - x0) / 18))
    for i in range(count + 1):
        t = i / count
        x = x0 + (x1 - x0) * t
        box(f"{prefix}_Batten_{i:02d}", (x, y, (z0 + z1) * 0.5), (0.8, 0.7, abs(z1 - z0)), trim_mat)


def add_corner_return(name: str, loc: tuple[float, float, float], size: tuple[float, float, float], mat: bpy.types.Material, wall_plane_id: str) -> None:
    obj = box(name, loc, size, mat)
    obj["wall_plane_id"] = wall_plane_id
    obj["closure_role"] = "wall_corner_return"
    obj["clearance_class"] = "exterior_only"
    obj["interior_clearance_sensitive"] = True


def add_roof_wall_edge_backer(name: str, loc: tuple[float, float, float], size: tuple[float, float, float], mat: bpy.types.Material, wall_plane_id: str, roof_edge_id: str) -> None:
    obj = box(name, loc, size, mat)
    obj["wall_plane_id"] = wall_plane_id
    obj["roof_edge_id"] = roof_edge_id
    obj["closure_role"] = "roof_wall_edge_backer"
    obj["clearance_class"] = "exterior_only"
    obj["interior_clearance_sensitive"] = True


def build_shell() -> None:
    clear_scene()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)

    siding = material("warm_white_board_and_batten", (0.88, 0.86, 0.78, 1.0))
    siding_shadow = material("shadowed_white_siding", (0.69, 0.73, 0.70, 1.0))
    roof = material("dark_standing_seam_roof", (0.035, 0.04, 0.04, 1.0))
    roof_light = material("sunlit_dark_roof", (0.17, 0.19, 0.19, 1.0))
    trim = material("black_metal_trim", (0.02, 0.025, 0.025, 1.0))
    glass = material("smoky_blue_transparent_glass", (0.18, 0.35, 0.45, 0.58))
    stone = material("gray_stone_plinth", (0.48, 0.46, 0.40, 1.0))
    porch = material("warm_concrete_and_porch_slab", (0.64, 0.62, 0.56, 1.0))
    green = material("foundation_planting_green", (0.18, 0.32, 0.16, 1.0))

    # X = width, Y = front/back, Z = height. Wall panels keep the shell hollow for interior route views.
    add_wall_shell("MainTwoStory", (18, 0), (166, 238), 27, 54, siding)
    add_wall_shell("GarageWing", (-104, 4), (104, 250), 22, 44, siding_shadow)
    add_wall_shell("MasterSideWing", (126, 44), (58, 112), 23, 46, siding)
    box("MainFirstFloorDeck", (18, 0, 2), (170, 242, 4), stone)
    box("GarageFirstFloorDeck", (-104, 4, 2), (108, 254, 4), stone)
    box("MasterFirstFloorDeck", (126, 44, 2), (62, 116, 4), stone)

    box("FrontCoveredPorchSlab", (34, 135, 2.4), (138, 42, 4.8), porch)
    box("RearCoveredPorchSlab", (54, -132, 2.4), (132, 42, 4.8), porch)
    box("FrontStonePlinth", (-8, 128, 5), (288, 5, 10), stone)
    box("RearStonePlinth", (8, -128, 5), (268, 5, 10), stone)

    gable_wall("MainFrontGableWall", -65, 101, 121, 52, 54, 78, 3.2, siding)
    gable_wall("MainRearGableWall", -65, 101, -121, 52, 54, 78, 3.2, siding_shadow)
    gable_wall("GarageFrontGableWall", -156, -52, 129, 42, 46, 70, 3.2, siding_shadow)
    gable_wall("GarageRearGableWall", -156, -52, -121, 42, 46, 70, 3.2, siding_shadow)
    gable_wall("MasterFrontGableWall", 97, 155, 101, 44, 48, 68, 3.2, siding)
    gable_wall("MasterRearGableWall", 97, 155, -12, 44, 48, 68, 3.2, siding_shadow)
    gable_wall("FrontPorchOuterGableWall", -24, 44, 154, 32, 37, 52, 2.4, siding)
    gable_wall("FrontPorchTieInGableWall", -24, 44, 116, 32, 37, 52, 2.4, siding_shadow)
    box("FrontPorchRightReturnWall", (47, 135, 22), (3.2, 38, 36), siding)
    box("FrontPorchLeftReturnWall", (-27, 135, 22), (3.2, 38, 36), siding)
    box("RearPorchOuterGableWall", (47, -154, 35), (120, 2.4, 6), siding_shadow)
    box("RearPorchTieInGableWall", (47, -116, 35), (120, 2.4, 6), siding)

    solid_gable_roof("MainHouseGableRoof", -65, 101, -121, 121, 55, 82, roof_light, trim, overhang=4.5)
    solid_gable_roof("GarageCrossGableRoof", -156, -52, -121, 129, 47, 72, roof, trim, overhang=4.0)
    solid_gable_roof("MasterWingGableRoof", 97, 155, -12, 101, 49, 70, roof_light, trim, overhang=3.5)
    solid_gable_roof("FrontPorchGableRoof", -24, 44, 116, 154, 37, 52, roof_light, trim, overhang=2.5)
    solid_gable_roof_x_ridge("RearPorchGableRoof", -12, 106, -154, -116, 37, 52, roof_light, trim, overhang=2.5)

    for x in (-26, 20, 70):
        box(f"FrontPorchColumn_{int(x)}", (x, 134, 21), (4.5, 4.5, 37), siding)
    for x in (18, 58, 98):
        box(f"RearPorchColumn_{int(x)}", (x, -132, 21), (4.5, 4.5, 37), siding)

    box("FrontDoorBlackPanel", (-10, 121.8, 17), (18, 2.2, 30), trim)
    box("FrontDoorTransomGlass", (-10, 123, 35), (20, 1.2, 5), glass)
    for i, x in enumerate((-134, -104, -74)):
        box(f"GarageDoor_{i + 1}", (x, 130.5, 15), (22, 2.2, 28), siding)
        box(f"GarageDoor_{i + 1}_BlackWindowBand", (x, 132, 25), (18, 1.2, 4), trim)
        box(f"GarageDoor_{i + 1}_HeaderTrim", (x, 132, 31), (24, 1.5, 2), trim)

    window("GreatRoomFrontWindow", (52, 121.8, 26), (54, 1.2, 24), glass, trim)
    window("KitchenFrontWindow", (-50, 121.8, 24), (30, 1.2, 20), glass, trim)
    window("UpperFrontGableWindow", (18, 121.8, 61), (26, 1.2, 20), glass, trim)
    window("GarageSideWindow", (-156.8, 20, 24), (1.2, 26, 18), glass, trim)
    window("MasterSideWindow", (156.8, 42, 24), (1.2, 32, 20), glass, trim)
    window("RearPorchDoorGlass", (54, -121.8, 22), (36, 1.2, 26), glass, trim)

    add_board_batten("FrontSiding", -62, 98, 123.2, 8, 48, trim)
    add_board_batten("GarageFrontSiding", -154, -54, 132.2, 8, 38, trim)
    add_board_batten("RearSiding", -62, 98, -123.2, 8, 48, trim)
    add_corner_return("MasterWingFrontRightCornerReturn", (157.4, 100, 26), (1.2, 3.2, 44), trim, "master_wing_right_exterior_plane")
    add_corner_return("MasterWingRearRightCornerReturn", (157.4, -12, 26), (1.2, 3.2, 44), trim, "master_wing_right_exterior_plane")
    add_corner_return("MainHouseFrontRightCornerReturn", (103.4, 121, 29), (1.2, 3.2, 50), trim, "main_house_right_exterior_plane")
    add_corner_return("GarageFrontLeftCornerReturn", (-158.4, 128, 24), (1.2, 3.2, 40), trim, "garage_left_exterior_plane")
    add_roof_wall_edge_backer("MainRightEaveWallTopBacker", (104.6, 0, 53.8), (1.0, 242, 1.6), trim, "main_house_right_exterior_plane", "MainHouseGableRoof:right_eave")
    add_roof_wall_edge_backer("MainRightFrontRakeCornerBacker", (104.6, 121.4, 55.2), (1.0, 3.6, 4.8), trim, "main_house_right_exterior_plane", "MainHouseGableRoof:front_right_rake")
    add_roof_wall_edge_backer("MainRightRearRakeCornerBacker", (104.6, -121.4, 55.2), (1.0, 3.6, 4.8), trim, "main_house_right_exterior_plane", "MainHouseGableRoof:rear_right_rake")
    add_roof_wall_edge_backer("MasterWingRightEaveWallTopBacker", (158.6, 44, 47.8), (1.0, 116, 1.6), trim, "master_wing_right_exterior_plane", "MasterWingGableRoof:right_eave")
    add_roof_wall_edge_backer("GarageLeftEaveWallTopBacker", (-159.6, 4, 45.8), (1.0, 254, 1.6), trim, "garage_left_exterior_plane", "GarageCrossGableRoof:left_eave")

    box("FrontCurvedWalkProxy", (-22, 180, 0.6), (34, 70, 1.2), porch)
    box("DrivewayProxy", (-116, 184, 0.5), (96, 78, 1.0), porch)
    box("FoundationPlantingFront", (40, 126, 3.5), (120, 8, 7), green)

    bpy.context.scene.world.color = (0.78, 0.84, 0.92)
    bpy.ops.object.light_add(type="SUN", location=(0, 0, 140))
    sun = bpy.context.object
    sun.name = "ReferenceSun"
    sun.rotation_euler = (math.radians(45), 0, math.radians(-35))
    sun.data.energy = 4.0
    bpy.ops.object.light_add(type="AREA", location=(0, 170, 120))
    fill = bpy.context.object
    fill.name = "SoftFrontFill"
    fill.data.energy = 700
    fill.data.size = 220


def add_review_camera(name: str, loc: tuple[float, float, float], target: tuple[float, float, float], ortho_scale: float = 310) -> bpy.types.Object:
    bpy.ops.object.camera_add(location=loc)
    camera = bpy.context.object
    camera.name = name
    direction = Vector(target) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 24
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = ortho_scale
    return camera


def add_review_cameras() -> None:
    target = (0, 10, 32)
    cameras = [
        ("FrontStreetReviewCamera", (0, 430, 68), target, 330),
        ("RearYardReviewCamera", (0, -430, 68), target, 330),
        ("LeftSideReviewCamera", (-430, 0, 72), target, 330),
        ("RightSideReviewCamera", (430, 0, 72), target, 330),
        ("FrontThreeQuarterReviewCamera", (270, 330, 120), target, 330),
        ("RearThreeQuarterReviewCamera", (-270, -330, 120), target, 330),
        ("RooflineReviewCamera", (250, 170, 190), target, 300),
        ("UndersideOverhangReviewCamera", (220, 190, 24), (0, 50, 42), 210),
        ("FrontLeftEaveSeamCamera", (-74, 132, 54), (-70, 118, 56), 42),
        ("FrontRightEaveSeamCamera", (112, 132, 54), (106, 118, 56), 42),
        ("RearLeftEaveSeamCamera", (-74, -132, 54), (-70, -118, 56), 42),
        ("RearRightEaveSeamCamera", (112, -132, 54), (106, -118, 56), 42),
        ("UndersideLeftEaveSeamCamera", (-74, 112, 44), (-70, 118, 55), 36),
        ("UndersideRightEaveSeamCamera", (112, 112, 44), (106, 118, 55), 36),
        ("MainFrontGableApexCamera", (18, 150, 78), (18, 125, 82), 34),
        ("MainRearGableApexCamera", (18, -150, 78), (18, -125, 82), 34),
        ("GarageFrontGableApexCamera", (-104, 154, 68), (-104, 132, 72), 34),
        ("GarageRearGableApexCamera", (-104, -146, 68), (-104, -124, 72), 34),
        ("MasterFrontGableApexCamera", (126, 124, 66), (126, 104, 70), 30),
        ("MasterRearGableApexCamera", (126, -34, 66), (126, -15, 70), 30),
        ("FrontPorchStreetGableApexCamera", (10, 178, 54), (10, 154, 52), 30),
        ("FrontPorchTieInGableApexCamera", (10, 96, 54), (10, 116, 52), 30),
        ("RearMasterWingRoofClosureCamera", (188, -56, 72), (126, -12, 52), 72),
        ("RearPorchRoofTieInClosureCamera", (122, -186, 62), (54, -120, 42), 88),
        ("GarageRearRoofClosureCamera", (-190, -150, 68), (-104, -116, 50), 92),
        ("FrontPorchRoofTieInClosureCamera", (122, 186, 62), (54, 120, 42), 88),
        ("RightWallFlushCloseCamera", (214, 76, 42), (154, 72, 32), 62),
        ("MasterWingFrontReturnFlushCamera", (190, 128, 38), (156, 100, 28), 48),
        ("GarageSideReturnFlushCamera", (-210, 138, 38), (-156, 120, 26), 56),
        ("RightFrontRoofWallEdgeCamera", (142, 154, 64), (104, 120, 54), 38),
        ("RightRearRoofWallEdgeCamera", (142, -154, 64), (104, -120, 54), 38),
        ("MasterWingOuterRoofWallEdgeCamera", (198, 106, 60), (158, 78, 48), 44),
        ("GarageOuterRoofWallEdgeCamera", (-204, 130, 58), (-158, 104, 46), 48),
        ("PorchRoofWallEdgeCamera", (124, 158, 54), (100, 122, 38), 46),
        ("MainRightInteriorCeilingClashCamera", (98, 78, 48), (104, 78, 54), 36),
        ("MasterWingInteriorCeilingClashCamera", (150, 78, 44), (158, 78, 48), 34),
        ("GarageInteriorCeilingClashCamera", (-150, 78, 42), (-158, 78, 46), 42),
        ("UpperEaveUndersideClashCamera", (138, 108, 50), (104, 120, 54), 34),
    ]
    for name, loc, aim, scale in cameras:
        add_review_camera(name, loc, aim, scale)
    bpy.context.scene.camera = bpy.data.objects["FrontThreeQuarterReviewCamera"]


def render_review_set() -> None:
    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    bpy.context.scene.render.resolution_x = 1280
    bpy.context.scene.render.resolution_y = 800
    for camera in [obj for obj in bpy.context.scene.objects if obj.type == "CAMERA"]:
        bpy.context.scene.camera = camera
        bpy.context.scene.render.filepath = str(REVIEW_DIR / f"{camera.name}.png")
        bpy.ops.render.render(write_still=True)


def write_roof_trim_seam_audit() -> None:
    trim_entries = []
    failures = []
    for obj in bpy.context.scene.objects:
        if not bool(obj.get("seam_gate_required", False)):
            continue
        neighbor_ids = [item for item in str(obj.get("neighbor_ids", "")).split(",") if item]
        entry = {
            "id": obj.name,
            "support_edge_id": str(obj.get("support_edge_id", "")),
            "support_edge_start": list(obj.get("support_edge_start", [])),
            "support_edge_end": list(obj.get("support_edge_end", [])),
            "neighbor_ids": neighbor_ids,
            "mitre_rule": str(obj.get("mitre_rule", "")),
            "overrun_tolerance": float(obj.get("overrun_tolerance", 0.0)),
            "minimum_neighbor_overlap": float(obj.get("minimum_neighbor_overlap", 0.0)),
            "status": "pass",
        }
        if not entry["support_edge_id"]:
            entry["status"] = "fail"
            failures.append(f"{obj.name} missing support_edge_id")
        if len(neighbor_ids) == 0:
            entry["status"] = "fail"
            failures.append(f"{obj.name} missing neighbor trim ids")
        if not entry["mitre_rule"]:
            entry["status"] = "fail"
            failures.append(f"{obj.name} missing mitre_rule")
        trim_entries.append(entry)
    close_camera_files = [f"{camera_id}.png" for camera_id in ROOF_SEAM_REVIEW_CAMERAS]
    audit = {
        "gate": "roof_trim_seam_audit",
        "acceptance": "all close seam cameras must exist and be reviewed as pass before production shell acceptance",
        "close_seam_review_cameras": close_camera_files,
        "trim_entries": trim_entries,
        "failures": failures,
        "status": "pass" if len(failures) == 0 and len(trim_entries) > 0 else "fail",
    }
    if len(trim_entries) == 0:
        audit["failures"].append("no trim entries declared seam_gate_required")
    ROOF_TRIM_AUDIT_PATH.write_text(json.dumps(audit, indent=2) + "\n", encoding="utf-8")


def write_gable_rake_point_closure_audit() -> None:
    required = []
    roof_camera_map = {
        "MainHouseGableRoof": ("MainFrontGableApexCamera", "MainRearGableApexCamera"),
        "GarageCrossGableRoof": ("GarageFrontGableApexCamera", "GarageRearGableApexCamera"),
        "MasterWingGableRoof": ("MasterFrontGableApexCamera", "MasterRearGableApexCamera"),
        "FrontPorchGableRoof": ("FrontPorchStreetGableApexCamera", "FrontPorchTieInGableApexCamera"),
    }
    for roof_id, camera_pair in roof_camera_map.items():
        required.append({
            "id": f"{roof_id}_front_apex",
            "roof_id": roof_id,
            "rake_ids": [f"{roof_id}_FrontLeftRake", f"{roof_id}_FrontRightRake"],
            "ridge_cap_id": f"{roof_id}_RidgeCap",
            "apex_cap_id": f"{roof_id}_FrontApexPointCap",
            "review_camera_ids": [camera_pair[0]],
        })
        required.append({
            "id": f"{roof_id}_rear_apex",
            "roof_id": roof_id,
            "rake_ids": [f"{roof_id}_RearLeftRake", f"{roof_id}_RearRightRake"],
            "ridge_cap_id": f"{roof_id}_RidgeCap",
            "apex_cap_id": f"{roof_id}_RearApexPointCap",
            "review_camera_ids": [camera_pair[1]],
        })

    tolerance = 0.1
    failures = []
    entries = []
    object_names = {obj.name for obj in bpy.context.scene.objects}
    camera_files = [f"{camera_id}.png" for camera_id in GABLE_POINT_REVIEW_CAMERAS]
    for item in required:
        missing_rakes = [mesh_id for mesh_id in item["rake_ids"] if mesh_id not in object_names]
        missing_cap = [] if item["apex_cap_id"] in object_names else [item["apex_cap_id"]]
        missing_ridge = [] if item["ridge_cap_id"] in object_names else [item["ridge_cap_id"]]
        missing_cameras = [camera_id for camera_id in item["review_camera_ids"] if camera_id not in object_names]
        status = "pass"
        endpoint_spread = 0.0
        apex_points = []
        for rake_id in item["rake_ids"]:
            obj = bpy.data.objects.get(rake_id)
            if obj == None:
                continue
            points = [Vector(obj.get("support_edge_start", (0, 0, 0))), Vector(obj.get("support_edge_end", (0, 0, 0)))]
            apex_points.append(max(points, key=lambda p: p.z))
        if len(apex_points) == 2:
            endpoint_spread = (apex_points[0] - apex_points[1]).length
        if missing_rakes or missing_cap or missing_ridge or missing_cameras:
            status = "fail"
            failures.append(f'{item["id"]} missing rakes={",".join(missing_rakes)} cap={",".join(missing_cap)} ridge={",".join(missing_ridge)} cameras={",".join(missing_cameras)}')
        if endpoint_spread > tolerance:
            status = "fail"
            failures.append(f'{item["id"]} rake endpoints spread={endpoint_spread:.3f} tolerance={tolerance:.3f}')
        entry = dict(item)
        entry["endpoint_convergence_tolerance"] = tolerance
        entry["measured_rake_endpoint_spread"] = round(endpoint_spread, 3)
        entry["point_closure_policy"] = "gable apex must include a cap/mitre mesh so squared rake and ridge bars resolve as a visible point"
        entry["status"] = status
        entries.append(entry)

    audit = {
        "gate": "gable_rake_point_closure_audit",
        "acceptance": "all gable apexes must converge and include a visible point cap or mitred closure mesh",
        "close_apex_review_cameras": camera_files,
        "gable_apexes": entries,
        "failures": failures,
        "status": "pass" if len(failures) == 0 else "fail",
    }
    GABLE_POINT_AUDIT_PATH.write_text(json.dumps(audit, indent=2) + "\n", encoding="utf-8")


def write_roof_axis_orientation_audit() -> None:
    required = [
        {"id": "MainHouseGableRoof", "expected_ridge_axis": "y", "expected_span_axis": "x", "review_camera_ids": ["FrontThreeQuarterReviewCamera", "RightSideReviewCamera"]},
        {"id": "GarageCrossGableRoof", "expected_ridge_axis": "y", "expected_span_axis": "x", "review_camera_ids": ["FrontStreetReviewCamera", "LeftSideReviewCamera"]},
        {"id": "MasterWingGableRoof", "expected_ridge_axis": "y", "expected_span_axis": "x", "review_camera_ids": ["RightSideReviewCamera", "RearThreeQuarterReviewCamera"]},
        {"id": "FrontPorchGableRoof", "expected_ridge_axis": "y", "expected_span_axis": "x", "module_role": "front_entry_gable", "max_span_width": 82.0, "review_camera_ids": ["FrontStreetReviewCamera", "RightSideReviewCamera", "FrontPorchRoofTieInClosureCamera"]},
        {"id": "RearPorchGableRoof", "expected_ridge_axis": "x", "expected_span_axis": "y", "review_camera_ids": ["RearYardReviewCamera", "RightSideReviewCamera"]},
    ]
    failures = []
    entries = []
    object_names = {obj.name for obj in bpy.context.scene.objects}
    for item in required:
        obj = bpy.data.objects.get(item["id"])
        missing_cameras = [camera_id for camera_id in item["review_camera_ids"] if camera_id not in object_names]
        status = "pass"
        measured_ridge_axis = ""
        measured_span_axis = ""
        rationale = ""
        measured_width = 0.0
        measured_depth = 0.0
        if obj == None:
            status = "fail"
            failures.append(f'{item["id"]} roof module missing')
        else:
            measured_ridge_axis = str(obj.get("ridge_axis", ""))
            measured_span_axis = str(obj.get("span_axis", ""))
            rationale = str(obj.get("roof_axis_rationale", ""))
            measured_width = round(float(obj.dimensions.x), 3)
            measured_depth = round(float(obj.dimensions.y), 3)
            if measured_ridge_axis != item["expected_ridge_axis"] or measured_span_axis != item["expected_span_axis"]:
                status = "fail"
                failures.append(f'{item["id"]} axis ridge={measured_ridge_axis} span={measured_span_axis} expected ridge={item["expected_ridge_axis"]} span={item["expected_span_axis"]}')
            if "max_span_width" in item and measured_width > float(item["max_span_width"]):
                status = "fail"
                failures.append(f'{item["id"]} width={measured_width:.3f} exceeds max entry-gable width={float(item["max_span_width"]):.3f}')
        if missing_cameras:
            status = "fail"
            failures.append(f'{item["id"]} missing roof-axis review cameras={",".join(missing_cameras)}')
        entry = dict(item)
        entry["measured_ridge_axis"] = measured_ridge_axis
        entry["measured_span_axis"] = measured_span_axis
        entry["measured_width"] = measured_width
        entry["measured_depth"] = measured_depth
        entry["reference_rationale"] = rationale
        entry["status"] = status
        entries.append(entry)
    audit = {
        "gate": "roof_axis_orientation_audit",
        "acceptance": "roof modules must use the ridge/span axis declared by the house reference and floor-plan role",
        "roof_modules": entries,
        "failures": failures,
        "status": "pass" if len(failures) == 0 else "fail",
    }
    ROOF_AXIS_AUDIT_PATH.write_text(json.dumps(audit, indent=2) + "\n", encoding="utf-8")


def write_roof_intersection_closure_audit() -> None:
    required = [
        {
            "id": "master_wing_rear_gable_closure",
            "owner_roof_ids": ["MasterWingGableRoof", "MainHouseGableRoof"],
            "intersection_type": "side_wing_rear_gable_return",
            "closure_mesh_ids": ["MasterRearGableWall"],
            "review_camera_ids": ["RearMasterWingRoofClosureCamera"],
        },
        {
            "id": "garage_rear_gable_closure",
            "owner_roof_ids": ["GarageCrossGableRoof", "MainHouseGableRoof"],
            "intersection_type": "garage_rear_gable_return",
            "closure_mesh_ids": ["GarageRearGableWall"],
            "review_camera_ids": ["GarageRearRoofClosureCamera"],
        },
        {
            "id": "front_porch_roof_tie_in_closure",
            "owner_roof_ids": ["FrontPorchGableRoof", "MainHouseGableRoof"],
            "intersection_type": "porch_tie_in_gable_closure",
            "closure_mesh_ids": ["FrontPorchOuterGableWall", "FrontPorchTieInGableWall", "FrontPorchRightReturnWall", "FrontPorchLeftReturnWall"],
            "review_camera_ids": ["FrontPorchRoofTieInClosureCamera"],
        },
        {
            "id": "rear_porch_roof_tie_in_closure",
            "owner_roof_ids": ["RearPorchGableRoof", "MainHouseGableRoof"],
            "intersection_type": "porch_tie_in_gable_closure",
            "closure_mesh_ids": ["RearPorchOuterGableWall", "RearPorchTieInGableWall"],
            "review_camera_ids": ["RearPorchRoofTieInClosureCamera"],
        },
    ]
    failures = []
    entries = []
    object_names = {obj.name for obj in bpy.context.scene.objects}
    camera_files = [f"{camera_id}.png" for camera_id in ROOF_INTERSECTION_REVIEW_CAMERAS]
    for item in required:
        missing_meshes = [mesh_id for mesh_id in item["closure_mesh_ids"] if mesh_id not in object_names]
        missing_cameras = [camera_id for camera_id in item["review_camera_ids"] if camera_id not in object_names]
        status = "pass"
        if missing_meshes or missing_cameras:
            status = "fail"
            failures.append(f'{item["id"]} missing meshes={",".join(missing_meshes)} cameras={",".join(missing_cameras)}')
        entry = dict(item)
        entry["status"] = status
        entries.append(entry)
    audit = {
        "gate": "roof_intersection_closure_audit",
        "acceptance": "all roof intersections must have closure meshes and close review cameras before shell acceptance",
        "close_intersection_review_cameras": camera_files,
        "intersections": entries,
        "failures": failures,
        "status": "pass" if len(failures) == 0 else "fail",
    }
    ROOF_INTERSECTION_AUDIT_PATH.write_text(json.dumps(audit, indent=2) + "\n", encoding="utf-8")


def write_wall_plane_flush_audit() -> None:
    required = [
        {
            "id": "main_house_right_wall_plane",
            "owner_wall_id": "MainTwoStory_RightWall",
            "axis": "x",
            "face": "max",
            "expected_plane": 103.0,
            "flush_member_ids": ["MainTwoStory_RightWall"],
            "cover_mesh_ids": ["MainHouseFrontRightCornerReturn"],
            "review_camera_ids": ["RightWallFlushCloseCamera"],
        },
        {
            "id": "master_wing_right_wall_plane",
            "owner_wall_id": "MasterSideWing_RightWall",
            "axis": "x",
            "face": "max",
            "expected_plane": 157.0,
            "flush_member_ids": ["MasterSideWing_RightWall"],
            "cover_mesh_ids": ["MasterWingFrontRightCornerReturn", "MasterWingRearRightCornerReturn"],
            "review_camera_ids": ["RightWallFlushCloseCamera", "MasterWingFrontReturnFlushCamera"],
        },
        {
            "id": "garage_left_wall_plane",
            "owner_wall_id": "GarageWing_LeftWall",
            "axis": "x",
            "face": "min",
            "expected_plane": -158.0,
            "flush_member_ids": ["GarageWing_LeftWall"],
            "cover_mesh_ids": ["GarageFrontLeftCornerReturn"],
            "review_camera_ids": ["GarageSideReturnFlushCamera"],
        },
    ]
    tolerance = 0.05
    failures = []
    entries = []
    object_names = {obj.name for obj in bpy.context.scene.objects}
    camera_files = [f"{camera_id}.png" for camera_id in WALL_FLUSH_REVIEW_CAMERAS]
    axis_index = {"x": 0, "y": 1, "z": 2}
    for item in required:
        status = "pass"
        measured_faces = {}
        missing_members = [mesh_id for mesh_id in item["flush_member_ids"] if mesh_id not in object_names]
        missing_covers = [mesh_id for mesh_id in item["cover_mesh_ids"] if mesh_id not in object_names]
        missing_cameras = [camera_id for camera_id in item["review_camera_ids"] if camera_id not in object_names]
        if missing_members or missing_covers or missing_cameras:
            status = "fail"
            failures.append(f'{item["id"]} missing members={",".join(missing_members)} covers={",".join(missing_covers)} cameras={",".join(missing_cameras)}')
        for mesh_id in item["flush_member_ids"]:
            obj = bpy.data.objects.get(mesh_id)
            if obj == None:
                continue
            mins, maxs = object_bounds(obj)
            coord = maxs[axis_index[item["axis"]]] if item["face"] == "max" else mins[axis_index[item["axis"]]]
            measured_faces[mesh_id] = round(coord, 3)
            if abs(coord - item["expected_plane"]) > tolerance:
                status = "fail"
                failures.append(f'{item["id"]} {mesh_id} face={coord:.3f} expected={item["expected_plane"]:.3f}')
        entry = dict(item)
        entry["tolerance"] = tolerance
        entry["measured_faces"] = measured_faces
        entry["cover_policy"] = "corner returns may stand proud only as measured seam covers; wall slabs must remain on the declared plane"
        entry["status"] = status
        entries.append(entry)
    audit = {
        "gate": "wall_plane_flush_audit",
        "acceptance": "all exterior wall slabs must match declared face planes and visible corners must have return covers plus close review cameras",
        "close_flush_review_cameras": camera_files,
        "wall_planes": entries,
        "failures": failures,
        "status": "pass" if len(failures) == 0 else "fail",
    }
    WALL_FLUSH_AUDIT_PATH.write_text(json.dumps(audit, indent=2) + "\n", encoding="utf-8")


def write_roof_wall_corner_edge_audit() -> None:
    required = [
        {
            "id": "main_right_front_roof_wall_corner",
            "wall_plane_id": "main_house_right_exterior_plane",
            "roof_edge_id": "MainHouseGableRoof:front_right_rake",
            "fascia_or_rake_ids": ["MainHouseGableRoof_FrontRightRake", "MainHouseGableRoof_RightEaveFascia"],
            "soffit_or_backer_ids": ["MainRightEaveWallTopBacker", "MainRightFrontRakeCornerBacker"],
            "review_camera_ids": ["RightFrontRoofWallEdgeCamera"],
        },
        {
            "id": "main_right_rear_roof_wall_corner",
            "wall_plane_id": "main_house_right_exterior_plane",
            "roof_edge_id": "MainHouseGableRoof:rear_right_rake",
            "fascia_or_rake_ids": ["MainHouseGableRoof_RearRightRake", "MainHouseGableRoof_RightEaveFascia"],
            "soffit_or_backer_ids": ["MainRightEaveWallTopBacker", "MainRightRearRakeCornerBacker"],
            "review_camera_ids": ["RightRearRoofWallEdgeCamera"],
        },
        {
            "id": "master_wing_outer_eave_wall_edge",
            "wall_plane_id": "master_wing_right_exterior_plane",
            "roof_edge_id": "MasterWingGableRoof:right_eave",
            "fascia_or_rake_ids": ["MasterWingGableRoof_RightEaveFascia"],
            "soffit_or_backer_ids": ["MasterWingRightEaveWallTopBacker"],
            "review_camera_ids": ["MasterWingOuterRoofWallEdgeCamera"],
        },
        {
            "id": "garage_outer_eave_wall_edge",
            "wall_plane_id": "garage_left_exterior_plane",
            "roof_edge_id": "GarageCrossGableRoof:left_eave",
            "fascia_or_rake_ids": ["GarageCrossGableRoof_LeftEaveFascia"],
            "soffit_or_backer_ids": ["GarageLeftEaveWallTopBacker"],
            "review_camera_ids": ["GarageOuterRoofWallEdgeCamera"],
        },
        {
            "id": "front_porch_right_tie_in_edge",
            "wall_plane_id": "front_porch_right_return_plane",
            "roof_edge_id": "FrontPorchGableRoof:front_right_rake",
            "fascia_or_rake_ids": ["FrontPorchGableRoof_FrontRightRake", "FrontPorchGableRoof_RightEaveFascia"],
            "soffit_or_backer_ids": ["FrontPorchRightReturnWall"],
            "review_camera_ids": ["PorchRoofWallEdgeCamera"],
        },
        {
            "id": "front_porch_left_tie_in_edge",
            "wall_plane_id": "front_porch_left_return_plane",
            "roof_edge_id": "FrontPorchGableRoof:front_left_rake",
            "fascia_or_rake_ids": ["FrontPorchGableRoof_FrontLeftRake", "FrontPorchGableRoof_LeftEaveFascia"],
            "soffit_or_backer_ids": ["FrontPorchLeftReturnWall"],
            "review_camera_ids": ["PorchRoofWallEdgeCamera"],
        },
    ]
    failures = []
    entries = []
    object_names = {obj.name for obj in bpy.context.scene.objects}
    camera_files = [f"{camera_id}.png" for camera_id in ROOF_WALL_EDGE_REVIEW_CAMERAS]
    for item in required:
        missing_trim = [mesh_id for mesh_id in item["fascia_or_rake_ids"] if mesh_id not in object_names]
        missing_backers = [mesh_id for mesh_id in item["soffit_or_backer_ids"] if mesh_id not in object_names]
        missing_cameras = [camera_id for camera_id in item["review_camera_ids"] if camera_id not in object_names]
        status = "pass"
        if missing_trim or missing_backers or missing_cameras:
            status = "fail"
            failures.append(f'{item["id"]} missing trim={",".join(missing_trim)} backers={",".join(missing_backers)} cameras={",".join(missing_cameras)}')
        entry = dict(item)
        entry["minimum_overlap"] = 0.5
        entry["endpoint_tolerance"] = 0.1
        entry["edge_policy"] = "roof-wall perimeter must include fascia/rake plus soffit/backer return; visible black slits or floating edge bars fail visual review"
        entry["status"] = status
        entries.append(entry)
    audit = {
        "gate": "roof_wall_corner_edge_audit",
        "acceptance": "all exposed roof-wall corners and long eave edges must have trim, backer returns, and close edge-sweep cameras",
        "close_edge_review_cameras": camera_files,
        "roof_wall_edges": entries,
        "failures": failures,
        "status": "pass" if len(failures) == 0 else "fail",
    }
    ROOF_WALL_EDGE_AUDIT_PATH.write_text(json.dumps(audit, indent=2) + "\n", encoding="utf-8")


def bounds_overlap(bounds_min: Vector, bounds_max: Vector, volume: dict) -> bool:
    vmin = volume["min"]
    vmax = volume["max"]
    return (
        bounds_min.x < vmax[0] and bounds_max.x > vmin[0]
        and bounds_min.y < vmax[1] and bounds_max.y > vmin[1]
        and bounds_min.z < vmax[2] and bounds_max.z > vmin[2]
    )


def write_envelope_clearance_clash_audit() -> None:
    clearance_volumes = [
        {
            "id": "main_two_story_finished_interior",
            "description": "Finished main-house room volume inside the exterior wall faces and below the roof-wall closure zone.",
            "min": [-63.0, -119.0, 4.0],
            "max": [101.0, 119.0, 53.0],
        },
        {
            "id": "master_wing_finished_interior",
            "description": "Finished master wing room volume inside the right exterior wall face.",
            "min": [99.0, -10.0, 4.0],
            "max": [153.0, 99.0, 46.5],
        },
        {
            "id": "garage_finished_interior",
            "description": "Finished garage/service volume inside the left exterior wall face.",
            "min": [-154.0, -119.0, 4.0],
            "max": [-54.0, 127.0, 44.5],
        },
        {
            "id": "upper_route_camera_clearance",
            "description": "Interior/route camera sweep near upper eave and wall top; exterior-only seals may not dominate this view.",
            "min": [-60.0, -112.0, 38.0],
            "max": [100.0, 112.0, 57.0],
        },
    ]
    failures = []
    entries = []
    object_names = {obj.name for obj in bpy.context.scene.objects}
    camera_files = [f"{camera_id}.png" for camera_id in ENVELOPE_CLASH_REVIEW_CAMERAS]
    missing_cameras = [camera_id for camera_id in ENVELOPE_CLASH_REVIEW_CAMERAS if camera_id not in object_names]
    if missing_cameras:
        failures.append(f"missing envelope clash review cameras={','.join(missing_cameras)}")

    for obj in bpy.context.scene.objects:
        clearance_class = str(obj.get("clearance_class", ""))
        if clearance_class == "":
            continue
        mins, maxs = object_bounds(obj)
        overlaps = []
        for volume in clearance_volumes:
            if bounds_overlap(mins, maxs, volume):
                overlaps.append(volume["id"])
        status = "pass"
        if clearance_class == "exterior_only" and overlaps:
            status = "fail"
            failures.append(f"{obj.name} exterior_only overlaps clearance volumes={','.join(overlaps)}")
        entry = {
            "id": obj.name,
            "closure_role": str(obj.get("closure_role", obj.get("support_edge_id", ""))),
            "clearance_class": clearance_class,
            "bounds_min": [round(mins.x, 3), round(mins.y, 3), round(mins.z, 3)],
            "bounds_max": [round(maxs.x, 3), round(maxs.y, 3), round(maxs.z, 3)],
            "checked_clearance_volume_ids": [volume["id"] for volume in clearance_volumes],
            "overlapping_clearance_volume_ids": overlaps,
            "overlap_policy": "exterior_only shell seal pieces must not intersect finished room, ceiling, route, or camera-clearance volumes",
            "status": status,
        }
        entries.append(entry)

    if len(entries) == 0:
        failures.append("no clearance-classified shell closure pieces were audited")

    audit = {
        "gate": "envelope_clearance_clash_audit",
        "acceptance": "shell closure fixes must be proven from both exterior and interior/camera clearance volumes before acceptance",
        "clearance_volumes": clearance_volumes,
        "close_clash_review_cameras": camera_files,
        "audited_shell_pieces": entries,
        "failures": failures,
        "status": "pass" if len(failures) == 0 else "fail",
    }
    ENVELOPE_CLASH_AUDIT_PATH.write_text(json.dumps(audit, indent=2) + "\n", encoding="utf-8")


def export_assets() -> None:
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
    bpy.ops.export_scene.gltf(
        filepath=str(GLB_PATH),
        export_format="GLB",
        export_apply=True,
        export_yup=True,
    )


def main() -> None:
    build_shell()
    add_review_cameras()
    write_roof_trim_seam_audit()
    write_gable_rake_point_closure_audit()
    write_roof_axis_orientation_audit()
    write_roof_intersection_closure_audit()
    write_wall_plane_flush_audit()
    write_roof_wall_corner_edge_audit()
    write_envelope_clearance_clash_audit()
    render_review_set()
    export_assets()


if __name__ == "__main__":
    main()
