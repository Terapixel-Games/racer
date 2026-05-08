import os
import re
import sys

import bpy
from mathutils import Vector


REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SOURCE_PATH = os.path.join(
	REPO_ROOT,
	"assets",
	"gameplay",
	"tracks",
	"attic",
	"props",
	"source",
	"jack_in_the_box_source.glb",
)
OUT_DIR = os.path.join(
	REPO_ROOT,
	"assets",
	"gameplay",
	"tracks",
	"attic",
	"props",
	"jack_parts",
)
COMBINED_OUT = os.path.join(OUT_DIR, "jack_in_the_box_parts.glb")
PRINT_VERBOSE_ISLANDS = False
PRINT_SPRING_DIAGNOSTICS = False
PRINT_CRANK_DIAGNOSTICS = False
PRINT_LID_DIAGNOSTICS = False


def clear_scene() -> None:
	bpy.ops.object.select_all(action="SELECT")
	bpy.ops.object.delete()


def import_source() -> list[bpy.types.Object]:
	bpy.ops.import_scene.gltf(filepath=SOURCE_PATH)
	meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
	if not meshes:
		raise RuntimeError("No mesh objects imported from jack source GLB")
	return meshes


def separate_loose(meshes: list[bpy.types.Object]) -> list[bpy.types.Object]:
	for obj in meshes:
		obj.select_set(False)
	for obj in meshes:
		bpy.context.view_layer.objects.active = obj
		obj.select_set(True)
		bpy.ops.object.mode_set(mode="EDIT")
		bpy.ops.mesh.select_all(action="SELECT")
		bpy.ops.mesh.separate(type="LOOSE")
		bpy.ops.object.mode_set(mode="OBJECT")
		obj.select_set(False)
	return [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]


def world_bounds(obj: bpy.types.Object) -> tuple[Vector, Vector, Vector]:
	points = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
	min_v = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
	max_v = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
	center = (min_v + max_v) * 0.5
	return min_v, max_v, center


def object_volume(obj: bpy.types.Object) -> float:
	min_v, max_v, _center = world_bounds(obj)
	size = max_v - min_v
	return abs(size.x * size.y * size.z)


def sanitize(name: str) -> str:
	return re.sub(r"[^a-zA-Z0-9_]+", "_", name).strip("_")


def pascal_case(name: str) -> str:
	return "".join(part.capitalize() for part in name.split("_"))


def duplicate_group(name: str, objects: list[bpy.types.Object]) -> bpy.types.Object:
	if not objects:
		raise RuntimeError(f"No objects available for {name}")
	for obj in bpy.context.scene.objects:
		obj.select_set(False)
	for obj in objects:
		obj.select_set(True)
	bpy.context.view_layer.objects.active = objects[0]
	bpy.ops.object.duplicate()
	dupes = [obj for obj in bpy.context.selected_objects if obj.type == "MESH"]
	bpy.context.view_layer.objects.active = dupes[0]
	if len(dupes) > 1:
		bpy.ops.object.join()
	merged = bpy.context.view_layer.objects.active
	merged.name = name
	merged.data.name = name + "Mesh"
	return merged


def classify_parts(objects: list[bpy.types.Object]) -> dict[str, list[bpy.types.Object]]:
	min_z = min(world_bounds(obj)[0].z for obj in objects)
	max_z = max(world_bounds(obj)[1].z for obj in objects)
	height = max(max_z - min_z, 0.001)
	box_top = min_z + height * 0.46

	parts: dict[str, list[bpy.types.Object]] = {
		"box_base": [],
		"lid": [],
		"crank": [],
		"spring": [],
		"clown_head": [],
	}
	for obj in objects:
		obj_min, obj_max, center = world_bounds(obj)
		size = obj_max - obj_min
		volume = object_volume(obj)
		if _looks_like_spring_coil(center, size, min_z, height):
			parts["spring"].append(obj)
		elif center.z <= box_top:
			if _looks_like_crank_piece(center, size, height):
				parts["crank"].append(obj)
			else:
				parts["box_base"].append(obj)
		elif _looks_like_lid_piece(center, size, min_z, height):
			parts["lid"].append(obj)
		else:
			parts["clown_head"].append(obj)

	if not parts["lid"]:
		candidates = [obj for obj in parts["box_base"] if world_bounds(obj)[2].z > min_z + height * 0.34]
		if candidates:
			parts["lid"] = candidates
			parts["box_base"] = [obj for obj in parts["box_base"] if obj not in candidates]
	if not parts["crank"]:
		candidates = sorted(parts["box_base"], key=lambda obj: abs(world_bounds(obj)[2].x), reverse=True)
		if candidates:
			parts["crank"] = candidates[:1]
			parts["box_base"] = [obj for obj in parts["box_base"] if obj not in parts["crank"]]
	if not parts["spring"]:
		candidates = sorted(parts["clown_head"], key=lambda obj: object_volume(obj))
		if candidates:
			parts["spring"] = candidates[:1]
			parts["clown_head"] = [obj for obj in parts["clown_head"] if obj not in parts["spring"]]
	if not parts["clown_head"]:
		remaining = [obj for obj in objects if obj not in parts["box_base"] and obj not in parts["lid"] and obj not in parts["crank"] and obj not in parts["spring"]]
		parts["clown_head"] = remaining
	return parts


def _looks_like_box_panel(size: Vector, total_height: float) -> bool:
	thin_axis = min(size.x, size.y, size.z)
	long_axis = max(size.x, size.y, size.z)
	mid_axis = sorted([size.x, size.y, size.z])[1]
	if long_axis <= total_height * 0.12:
		return False
	if thin_axis <= total_height * 0.05 and mid_axis >= total_height * 0.08:
		return True
	return size.z >= total_height * 0.14 and size.x <= total_height * 0.16 and size.y <= total_height * 0.16


def _looks_like_spring_coil(center: Vector, size: Vector, min_z: float, total_height: float) -> bool:
	radius_xy = max(abs(center.x), abs(center.y))
	low_coil = (
		radius_xy <= 0.16
		and center.z >= min_z + total_height * 0.40
		and center.z <= min_z + total_height * 0.46
		and size.x >= total_height * 0.018
		and size.y >= total_height * 0.018
		and size.x <= total_height * 0.075
		and size.y <= total_height * 0.06
		and size.z <= total_height * 0.032
	)
	upper_coil = (
		radius_xy <= 0.16
		and center.z >= min_z + total_height * 0.46
		and center.z <= min_z + total_height * 0.56
		and size.x >= total_height * 0.018
		and size.y >= total_height * 0.010
		and size.x <= total_height * 0.075
		and size.y <= total_height * 0.065
		and size.z <= total_height * 0.045
	)
	tall_center_spring = size.z > total_height * 0.24 and radius_xy < 0.34
	return low_coil or upper_coil or tall_center_spring


def _looks_like_lid_piece(center: Vector, size: Vector, min_z: float, total_height: float) -> bool:
	if not _looks_like_box_panel(size, total_height):
		return False
	if center.z <= min_z + total_height * 0.46:
		return False
	if center.y < -0.08:
		return False
	return center.y >= 0.08 or center.x <= -0.10 or center.x >= 0.22


def _looks_like_crank_piece(center: Vector, size: Vector, total_height: float) -> bool:
	return (
		center.y <= -0.52
		and center.x >= 0.30
		and size.x <= total_height * 0.10
		and size.y <= total_height * 0.07
		and size.z <= total_height * 0.08
	)


def export_combined_parts(parts: dict[str, list[bpy.types.Object]]) -> None:
	os.makedirs(OUT_DIR, exist_ok=True)
	part_objects: list[bpy.types.Object] = []
	for name, objects in parts.items():
		part = duplicate_group(pascal_case(name) + "Part", objects)
		part_objects.append(part)
		print(f"prepared {part.name}: {len(objects)} source islands")
	for obj in bpy.context.scene.objects:
		obj.select_set(False)
	for part in part_objects:
		part.select_set(True)
	bpy.context.view_layer.objects.active = part_objects[0]
	bpy.ops.export_scene.gltf(filepath=COMBINED_OUT, export_format="GLB", use_selection=True)
	print(f"exported split runtime GLB -> {COMBINED_OUT}")


def main() -> None:
	clear_scene()
	meshes = import_source()
	objects = separate_loose(meshes)
	print(f"separated source into {len(objects)} mesh islands")
	if PRINT_VERBOSE_ISLANDS:
		for obj in sorted(objects, key=lambda item: world_bounds(item)[2].z):
			min_v, max_v, center = world_bounds(obj)
			print(f"island {sanitize(obj.name)} center={tuple(round(v, 4) for v in center)} min={tuple(round(v, 4) for v in min_v)} max={tuple(round(v, 4) for v in max_v)}")
	parts = classify_parts(objects)
	for name, group in parts.items():
		print(f"{name}: {len(group)} islands")
	if PRINT_SPRING_DIAGNOSTICS:
		print("spring bucket:")
		for obj in sorted(parts["spring"], key=lambda item: world_bounds(item)[2].z, reverse=True):
			min_v, max_v, center = world_bounds(obj)
			size = max_v - min_v
			print(f"  {sanitize(obj.name)} volume={object_volume(obj):.5f} center={tuple(round(v, 4) for v in center)} size={tuple(round(v, 4) for v in size)} min={tuple(round(v, 4) for v in min_v)} max={tuple(round(v, 4) for v in max_v)}")
		print("centered clown spring candidates:")
		candidates = []
		for obj in parts["clown_head"]:
			min_v, max_v, center = world_bounds(obj)
			radius_xy = max(abs(center.x), abs(center.y))
			if radius_xy <= 0.34:
				candidates.append(obj)
		for obj in sorted(candidates, key=lambda item: world_bounds(item)[2].z, reverse=True)[:80]:
			min_v, max_v, center = world_bounds(obj)
			size = max_v - min_v
			print(f"  {sanitize(obj.name)} volume={object_volume(obj):.5f} center={tuple(round(v, 4) for v in center)} size={tuple(round(v, 4) for v in size)} min={tuple(round(v, 4) for v in min_v)} max={tuple(round(v, 4) for v in max_v)}")
	if PRINT_CRANK_DIAGNOSTICS:
		print("crank bucket:")
		for obj in sorted(parts["crank"], key=object_volume, reverse=True)[:80]:
			min_v, max_v, center = world_bounds(obj)
			size = max_v - min_v
			print(f"  {sanitize(obj.name)} volume={object_volume(obj):.5f} center={tuple(round(v, 4) for v in center)} size={tuple(round(v, 4) for v in size)} min={tuple(round(v, 4) for v in min_v)} max={tuple(round(v, 4) for v in max_v)}")
	if PRINT_LID_DIAGNOSTICS:
		print("lid bucket:")
		for obj in sorted(parts["lid"], key=lambda item: world_bounds(item)[2].z, reverse=True)[:120]:
			min_v, max_v, center = world_bounds(obj)
			size = max_v - min_v
			print(f"  {sanitize(obj.name)} volume={object_volume(obj):.5f} center={tuple(round(v, 4) for v in center)} size={tuple(round(v, 4) for v in size)} min={tuple(round(v, 4) for v in min_v)} max={tuple(round(v, 4) for v in max_v)}")
		print("panel-like clown candidates:")
		candidates = []
		for obj in parts["clown_head"]:
			min_v, max_v, center = world_bounds(obj)
			size = max_v - min_v
			if center.z > 0.10 and _looks_like_box_panel(size, 1.8991):
				candidates.append(obj)
		for obj in sorted(candidates, key=object_volume, reverse=True)[:80]:
			min_v, max_v, center = world_bounds(obj)
			size = max_v - min_v
			print(f"  {sanitize(obj.name)} volume={object_volume(obj):.5f} center={tuple(round(v, 4) for v in center)} size={tuple(round(v, 4) for v in size)} min={tuple(round(v, 4) for v in min_v)} max={tuple(round(v, 4) for v in max_v)}")
	export_combined_parts(parts)


if __name__ == "__main__":
	try:
		main()
	except Exception as exc:
		print(f"split failed: {exc}", file=sys.stderr)
		raise
