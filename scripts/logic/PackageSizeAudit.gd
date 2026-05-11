extends Resource

class_name PackageSizeAudit

const SOURCE_RACER_ROOT := "res://assets/source/meshy/2026-04-27-character-track-batch"
const OPTIMIZED_RACER_ROOT := "res://assets/optimized/racers"
const WEB_BUILD_ROOT := "res://build/web"
const WEB_PCK_PATH := "res://build/web/index.pck"
const ANDROID_BUILD_ROOT := "res://build/android"

static func collect() -> Dictionary:
	var source_racer_glb_bytes := _sum_files(SOURCE_RACER_ROOT, func(path: String) -> bool:
		return path.ends_with("/racer_in_kart.glb")
	)
	var optimized_racer_glb_bytes := _sum_files(OPTIMIZED_RACER_ROOT, func(path: String) -> bool:
		return path.ends_with(".glb")
	)
	var optimized_racer_atlas_bytes := _sum_files(OPTIMIZED_RACER_ROOT, func(path: String) -> bool:
		return path.ends_with(".jpg")
	)
	var web_build_bytes := _sum_files(WEB_BUILD_ROOT, func(_path: String) -> bool:
		return true
	)
	var web_pck_bytes := _file_size(WEB_PCK_PATH)
	var android_package_files := package_files(ANDROID_BUILD_ROOT)
	var android_package_bytes := 0
	var latest_android_package: Dictionary = {}
	for package_file in android_package_files:
		android_package_bytes += int((package_file as Dictionary).get("bytes", 0))
		if latest_android_package.is_empty() or int((package_file as Dictionary).get("modified_time", 0)) > int(latest_android_package.get("modified_time", 0)):
			latest_android_package = package_file
	var racer_savings_bytes := source_racer_glb_bytes - optimized_racer_glb_bytes
	var optimized_ratio := 0.0
	if source_racer_glb_bytes > 0:
		optimized_ratio = float(optimized_racer_glb_bytes) / float(source_racer_glb_bytes)

	return {
		"source_racer_in_kart_glb_bytes": source_racer_glb_bytes,
		"optimized_racer_glb_bytes": optimized_racer_glb_bytes,
		"optimized_racer_atlas_source_bytes": optimized_racer_atlas_bytes,
		"optimized_racer_staged_source_bytes": optimized_racer_glb_bytes + optimized_racer_atlas_bytes,
		"racer_glb_savings_bytes": racer_savings_bytes,
		"optimized_glb_source_ratio": optimized_ratio,
		"web_build_total_bytes": web_build_bytes,
		"web_pck_bytes": web_pck_bytes,
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
