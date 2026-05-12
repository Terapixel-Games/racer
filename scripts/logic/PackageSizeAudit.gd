extends Resource

class_name PackageSizeAudit

const SOURCE_RACER_ROOT := "res://assets/source/meshy/2026-04-27-character-track-batch"
const OPTIMIZED_RACER_ROOT := "res://assets/optimized/racers"
const WEB_BUILD_ROOT := "res://build/web"
const WEB_PCK_PATH := "res://build/web/index.pck"
const ANDROID_BUILD_ROOT := "res://build/android"
const EXPORT_PRESETS_PATH := "res://export_presets.cfg"

static func collect() -> Dictionary:
	var source_racer_glb_bytes := _sum_files(SOURCE_RACER_ROOT, func(path: String) -> bool:
		return path.ends_with("/racer_in_kart.glb")
	)
	var optimized_racer_lod0_glb_bytes := _sum_files(OPTIMIZED_RACER_ROOT, func(path: String) -> bool:
		return path.ends_with(".glb") and not _is_lod_path(path)
	)
	var optimized_racer_lod_glb_bytes := _sum_files(OPTIMIZED_RACER_ROOT, func(path: String) -> bool:
		return path.ends_with(".glb") and _is_lod_path(path)
	)
	var optimized_racer_lod0_atlas_bytes := _sum_files(OPTIMIZED_RACER_ROOT, func(path: String) -> bool:
		return path.ends_with(".jpg") and not _is_lod_path(path)
	)
	var optimized_racer_lod_atlas_bytes := _sum_files(OPTIMIZED_RACER_ROOT, func(path: String) -> bool:
		return path.ends_with(".jpg") and _is_lod_path(path)
	)
	var optimized_racer_lod_sprite_bytes := _sum_files(OPTIMIZED_RACER_ROOT, func(path: String) -> bool:
		return _is_lod_sprite_path(path)
	)
	var web_build_bytes := _sum_files(WEB_BUILD_ROOT, func(_path: String) -> bool:
		return true
	)
	var web_pck_bytes := _file_size(WEB_PCK_PATH)
	var web_export_categories := web_export_resource_categories()
	var android_package_files := package_files(ANDROID_BUILD_ROOT)
	var android_package_bytes := 0
	var latest_android_package: Dictionary = {}
	for package_file in android_package_files:
		android_package_bytes += int((package_file as Dictionary).get("bytes", 0))
		if latest_android_package.is_empty() or int((package_file as Dictionary).get("modified_time", 0)) > int(latest_android_package.get("modified_time", 0)):
			latest_android_package = package_file
	var optimized_racer_runtime_glb_bytes := optimized_racer_lod0_glb_bytes + optimized_racer_lod_glb_bytes
	var optimized_racer_atlas_bytes := optimized_racer_lod0_atlas_bytes + optimized_racer_lod_atlas_bytes
	var racer_savings_bytes := source_racer_glb_bytes - optimized_racer_lod0_glb_bytes
	var optimized_ratio := 0.0
	if source_racer_glb_bytes > 0:
		optimized_ratio = float(optimized_racer_lod0_glb_bytes) / float(source_racer_glb_bytes)

	return {
		"source_racer_in_kart_glb_bytes": source_racer_glb_bytes,
		"optimized_racer_glb_bytes": optimized_racer_lod0_glb_bytes,
		"optimized_racer_lod0_glb_bytes": optimized_racer_lod0_glb_bytes,
		"optimized_racer_lod_glb_bytes": optimized_racer_lod_glb_bytes,
		"optimized_racer_runtime_glb_bytes": optimized_racer_runtime_glb_bytes,
		"optimized_racer_atlas_source_bytes": optimized_racer_atlas_bytes,
		"optimized_racer_lod0_atlas_source_bytes": optimized_racer_lod0_atlas_bytes,
		"optimized_racer_lod_atlas_source_bytes": optimized_racer_lod_atlas_bytes,
		"optimized_racer_lod_sprite_bytes": optimized_racer_lod_sprite_bytes,
		"optimized_racer_staged_source_bytes": optimized_racer_lod0_glb_bytes + optimized_racer_lod0_atlas_bytes,
		"optimized_racer_staged_lod_bytes": optimized_racer_lod_glb_bytes + optimized_racer_lod_atlas_bytes,
		"optimized_racer_total_staged_bytes": optimized_racer_runtime_glb_bytes + optimized_racer_atlas_bytes + optimized_racer_lod_sprite_bytes,
		"racer_glb_savings_bytes": racer_savings_bytes,
		"optimized_glb_source_ratio": optimized_ratio,
		"web_build_total_bytes": web_build_bytes,
		"web_pck_bytes": web_pck_bytes,
		"web_export_resource_category_bytes": web_export_categories.get("category_bytes", {}),
		"web_export_resource_category_files": web_export_categories.get("category_files", {}),
		"web_export_resource_files_total_bytes": int(web_export_categories.get("total_bytes", 0)),
		"largest_web_build_files": largest_files(WEB_BUILD_ROOT, 8),
		"android_package_total_bytes": android_package_bytes,
		"android_package_files": android_package_files,
		"android_latest_package_path": str(latest_android_package.get("path", "")),
		"android_latest_package_bytes": int(latest_android_package.get("bytes", 0)),
	}

static func bytes_to_mb(value: int) -> float:
	return snappedf(float(value) / (1024.0 * 1024.0), 0.1)

static func largest_files(root_path: String, limit: int = 10) -> Array[Dictionary]:
	var files := _collect_files(root_path, func(_path: String) -> bool:
		return true
	)
	files.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("bytes", 0)) > int(b.get("bytes", 0))
	)
	var capped: Array[Dictionary] = []
	for i in range(mini(limit, files.size())):
		capped.append(files[i])
	return capped

static func package_files(root_path: String) -> Array[Dictionary]:
	var files := _collect_files(root_path, func(path: String) -> bool:
		return path.ends_with(".apk") or path.ends_with(".aab")
	)
	files.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("path", "")) < str(b.get("path", ""))
	)
	return files

static func web_export_resource_categories() -> Dictionary:
	var paths := _web_export_resource_paths()
	var category_bytes := {
		"racer_lod0": 0,
		"racer_lod": 0,
		"racer_lod_sprites": 0,
		"racer_textures": 0,
		"environment_assets": 0,
		"ui_assets": 0,
		"addons_scripts": 0,
		"game_scripts": 0,
		"scenes_resources": 0,
		"other": 0,
	}
	var category_files := {}
	for key in category_bytes.keys():
		category_files[key] = []
	var total := 0
	for res_path in paths:
		var category := _web_export_category_for_path(res_path)
		var bytes := _file_size(res_path)
		category_bytes[category] = int(category_bytes.get(category, 0)) + bytes
		total += bytes
		(category_files[category] as Array).append({
			"path": res_path,
			"bytes": bytes,
		})
	return {
		"category_bytes": category_bytes,
		"category_files": category_files,
		"total_bytes": total,
	}

static func _web_export_resource_paths() -> Array[String]:
	var text := FileAccess.get_file_as_string(EXPORT_PRESETS_PATH)
	if text.is_empty():
		return []
	var web_section_start := text.find("[preset.1]")
	if web_section_start < 0:
		return []
	var next_section := text.find("\n[preset.", web_section_start + 1)
	var web_section := text.substr(web_section_start) if next_section < 0 else text.substr(web_section_start, next_section - web_section_start)
	var marker := "export_files=PackedStringArray("
	var start := web_section.find(marker)
	if start < 0:
		return []
	start += marker.length()
	var end := web_section.find(")", start)
	if end < 0:
		return []
	var raw_paths := web_section.substr(start, end - start)
	var out: Array[String] = []
	for raw_part in raw_paths.split(",", false):
		var res_path := raw_part.strip_edges().trim_prefix("\"").trim_suffix("\"")
		if not res_path.is_empty():
			out.append(res_path)
	return out

static func _web_export_category_for_path(path: String) -> String:
	if path.begins_with(OPTIMIZED_RACER_ROOT):
		if _is_lod_sprite_path(path):
			return "racer_lod_sprites"
		if path.ends_with(".jpg") or path.ends_with(".png") or path.ends_with(".webp"):
			return "racer_textures"
		return "racer_lod" if _is_lod_path(path) else "racer_lod0"
	if path.begins_with("res://assets/ui/"):
		return "ui_assets"
	if path.begins_with("res://addons/"):
		return "addons_scripts"
	if path.begins_with("res://scripts/"):
		return "game_scripts"
	if path.begins_with("res://scenes/") or path.ends_with(".tres") or path.ends_with(".tscn"):
		return "scenes_resources"
	if path.begins_with("res://assets/gameplay/") or path.begins_with("res://assets/source/") or path.begins_with("res://assets/models/") or path.begins_with("res://shaders/"):
		return "environment_assets"
	return "other"

static func _is_lod_path(path: String) -> bool:
	return path.contains("_lod1") or path.contains("_lod2")

static func _is_lod_sprite_path(path: String) -> bool:
	return path.contains("_lod2_sprites") and (path.ends_with(".png") or path.ends_with(".json"))

static func _sum_files(root_path: String, predicate: Callable) -> int:
	var total := 0
	for entry in _collect_files(root_path, predicate):
		total += int((entry as Dictionary).get("bytes", 0))
	return total

static func _collect_files(root_path: String, predicate: Callable) -> Array[Dictionary]:
	var root := ProjectSettings.globalize_path(root_path)
	if not DirAccess.dir_exists_absolute(root):
		return []
	var files: Array[Dictionary] = []
	_collect_files_recursive(root, root_path.trim_suffix("/"), predicate, files)
	return files

static func _collect_files_recursive(abs_dir: String, res_dir: String, predicate: Callable, files: Array[Dictionary]) -> void:
	var dir := DirAccess.open(abs_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		if name == "." or name == "..":
			name = dir.get_next()
			continue
		var abs_path := abs_dir.path_join(name)
		var res_path := res_dir.path_join(name)
		if dir.current_is_dir():
			_collect_files_recursive(abs_path, res_path, predicate, files)
		elif predicate.call(res_path):
			files.append({
				"path": res_path,
				"bytes": _file_size(res_path),
				"modified_time": FileAccess.get_modified_time(res_path),
			})
		name = dir.get_next()
	dir.list_dir_end()

static func _file_size(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	var size := file.get_length()
	file.close()
	return size
