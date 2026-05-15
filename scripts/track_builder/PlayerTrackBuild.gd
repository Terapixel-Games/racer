extends Resource
class_name PlayerTrackBuild

const SCHEMA_VERSION := 1

@export var schema_version := SCHEMA_VERSION
@export var build_id := ""
@export var owner_user_id := ""
@export var home_map_id := "home_yard_v3"
@export var home_map_version := ""
@export var display_name := "Home Build"
@export var piece_library_version := "home_builder_v1"
@export var piece_inventory: Dictionary = {}
@export var pieces: Array[Dictionary] = []
@export var anchor_ids: Array[String] = []
@export var route_cells: Array[Vector3i] = []
@export var route_points: Array[Vector3] = []
@export var navigation_status := "unchecked"
@export var race_status := "unchecked"
@export var validation_errors: Array[String] = []
@export var promotion_metadata: Dictionary = {}

func to_payload() -> Dictionary:
	return {
		"schema_version": schema_version,
		"build_id": build_id,
		"owner_user_id": owner_user_id,
		"home_map_id": home_map_id,
		"home_map_version": home_map_version,
		"display_name": display_name,
		"piece_library_version": piece_library_version,
		"piece_inventory": piece_inventory.duplicate(true),
		"pieces": pieces.duplicate(true),
		"anchor_ids": anchor_ids.duplicate(),
		"route_cells": _vector3i_array_to_json(route_cells),
		"route_points": _vector3_array_to_json(route_points),
		"navigation_status": navigation_status,
		"race_status": race_status,
		"validation_errors": validation_errors.duplicate(),
		"promotion_metadata": promotion_metadata.duplicate(true),
	}

static func from_payload(payload: Dictionary) -> PlayerTrackBuild:
	var build := PlayerTrackBuild.new()
	build.schema_version = int(payload.get("schema_version", SCHEMA_VERSION))
	build.build_id = str(payload.get("build_id", ""))
	build.owner_user_id = str(payload.get("owner_user_id", ""))
	build.home_map_id = str(payload.get("home_map_id", "home_yard_v3"))
	build.home_map_version = str(payload.get("home_map_version", ""))
	build.display_name = str(payload.get("display_name", "Home Build"))
	build.piece_library_version = str(payload.get("piece_library_version", "home_builder_v1"))
	build.piece_inventory = payload.get("piece_inventory", {}) if payload.get("piece_inventory", {}) is Dictionary else {}
	build.pieces = _dictionary_array_from_value(payload.get("pieces", []))
	build.anchor_ids = _string_array_from_value(payload.get("anchor_ids", []))
	build.route_cells = _vector3i_array_from_value(payload.get("route_cells", []))
	build.route_points = _vector3_array_from_value(payload.get("route_points", []))
	build.navigation_status = str(payload.get("navigation_status", "unchecked"))
	build.race_status = str(payload.get("race_status", "unchecked"))
	build.validation_errors = _string_array_from_value(payload.get("validation_errors", []))
	build.promotion_metadata = payload.get("promotion_metadata", {}) if payload.get("promotion_metadata", {}) is Dictionary else {}
	return build

static func _dictionary_array_from_value(value: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				out.append((item as Dictionary).duplicate(true))
	return out

static func _string_array_from_value(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item in value:
			out.append(str(item))
	return out

static func _vector3i_array_to_json(points: Array[Vector3i]) -> Array:
	var out: Array = []
	for point in points:
		out.append([point.x, point.y, point.z])
	return out

static func _vector3_array_to_json(points: Array[Vector3]) -> Array:
	var out: Array = []
	for point in points:
		out.append([point.x, point.y, point.z])
	return out

static func _vector3i_array_from_value(value: Variant) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	if value is Array:
		for item in value:
			out.append(_vector3i_from_value(item))
	return out

static func _vector3_array_from_value(value: Variant) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if value is Array:
		for item in value:
			out.append(_vector3_from_value(item, Vector3.ZERO))
	return out

static func _vector3i_from_value(value: Variant) -> Vector3i:
	if value is Vector3i:
		return value
	if value is Vector3:
		return Vector3i(roundi(value.x), roundi(value.y), roundi(value.z))
	if value is Array and value.size() >= 3:
		return Vector3i(int(value[0]), int(value[1]), int(value[2]))
	if value is Dictionary:
		return Vector3i(int(value.get("x", 0)), int(value.get("y", 0)), int(value.get("z", 0)))
	return Vector3i.ZERO

static func _vector3_from_value(value: Variant, fallback: Vector3) -> Vector3:
	if value is Vector3:
		return value
	if value is Vector3i:
		return Vector3(float(value.x), float(value.y), float(value.z))
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", fallback.x)), float(value.get("y", fallback.y)), float(value.get("z", fallback.z)))
	return fallback
