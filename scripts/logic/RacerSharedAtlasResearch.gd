extends Resource

class_name RacerSharedAtlasResearch

const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")

const CURRENT_PROFILE := RacerRoster.RACER_ASSET_PROFILE_MOBILE_DETAIL_PHASE1
const SOURCE_ATLAS_SIZE := 2048
const MOBILE_MAX_ATLAS_EDGE := 4096
const DETAIL_SCALE_GATE := 1.0

static func collect() -> Dictionary:
	var racers := _collect_racers()
	var atlas_count := racers.size()
	var total_atlas_bytes := 0
	var total_pixels := 0
	for racer in racers:
		total_atlas_bytes += int((racer as Dictionary).get("atlas_bytes", 0))
		total_pixels += int((racer as Dictionary).get("atlas_pixels", 0))

	var candidates := [
		_current_per_racer_candidate(atlas_count, total_atlas_bytes, total_pixels),
		_shared_candidate("shared_preserve_2048_4x2", 4, 2, SOURCE_ATLAS_SIZE, atlas_count, total_atlas_bytes, total_pixels),
		_shared_candidate("shared_mobile_4096_4x2", 4, 2, 1024, atlas_count, total_atlas_bytes, total_pixels),
	]

	var selected := "current_per_racer_atlas"
	var recommendation := "defer_shared_atlas"
	var reason := "A shared atlas that preserves 2048 detail exceeds the mobile 4096 texture-edge gate; the mobile-safe shared candidate requires 0.5x per-racer texture detail before visual comparison."

	return {
		"profile": CURRENT_PROFILE,
		"racer_count": atlas_count,
		"mobile_max_atlas_edge": MOBILE_MAX_ATLAS_EDGE,
		"detail_scale_gate": DETAIL_SCALE_GATE,
		"current_total_atlas_bytes": total_atlas_bytes,
		"current_total_atlas_pixels": total_pixels,
		"racers": racers,
		"candidates": candidates,
		"selected_strategy": selected,
		"recommendation": recommendation,
		"recommendation_reason": reason,
		"production_switch_allowed": false,
	}

static func _collect_racers() -> Array[Dictionary]:
	var racers: Array[Dictionary] = []
	for racer_id in RacerRoster.select_order():
		var glb_path := RacerRoster.get_racer_in_kart_model_path_for_profile(racer_id, CURRENT_PROFILE, false)
		var atlas_path := glb_path.replace(".glb", "_Image_0.jpg")
		var image_size := _image_size(atlas_path)
		racers.append({
			"id": racer_id,
			"model_path": glb_path,
			"atlas_path": atlas_path,
			"atlas_exists": FileAccess.file_exists(atlas_path),
			"atlas_bytes": _file_size(atlas_path),
			"atlas_width": int(image_size.x),
			"atlas_height": int(image_size.y),
			"atlas_pixels": int(image_size.x) * int(image_size.y),
		})
	return racers

static func _current_per_racer_candidate(atlas_count: int, total_atlas_bytes: int, total_pixels: int) -> Dictionary:
	return {
		"id": "current_per_racer_atlas",
		"atlas_count": atlas_count,
		"columns": 1,
		"rows": atlas_count,
		"cell_size": SOURCE_ATLAS_SIZE,
		"width": SOURCE_ATLAS_SIZE,
		"height": SOURCE_ATLAS_SIZE,
		"max_edge": SOURCE_ATLAS_SIZE,
		"detail_scale": 1.0,
		"estimated_source_bytes": total_atlas_bytes,
		"estimated_source_savings_bytes": 0,
		"texture_pixels": total_pixels,
		"mobile_edge_gate_passes": true,
		"detail_gate_passes": true,
		"requires_uv_remap": false,
		"requires_material_rebind": false,
		"risk": "baseline",
	}

static func _shared_candidate(
	id: String,
	columns: int,
	rows: int,
	cell_size: int,
	atlas_count: int,
	total_atlas_bytes: int,
	total_pixels: int
) -> Dictionary:
	var width := columns * cell_size
	var height := rows * cell_size
	var max_edge := maxi(width, height)
	var shared_pixels := width * height
	var detail_scale := float(cell_size) / float(SOURCE_ATLAS_SIZE)
	var estimated_bytes := int(round(float(total_atlas_bytes) * (float(shared_pixels) / float(maxi(total_pixels, 1)))))
	return {
		"id": id,
		"atlas_count": 1,
		"source_atlas_count": atlas_count,
		"columns": columns,
		"rows": rows,
		"cell_size": cell_size,
		"width": width,
		"height": height,
		"max_edge": max_edge,
		"detail_scale": detail_scale,
		"estimated_source_bytes": estimated_bytes,
		"estimated_source_savings_bytes": total_atlas_bytes - estimated_bytes,
		"texture_pixels": shared_pixels,
		"mobile_edge_gate_passes": max_edge <= MOBILE_MAX_ATLAS_EDGE,
		"detail_gate_passes": detail_scale >= DETAIL_SCALE_GATE,
		"requires_uv_remap": true,
		"requires_material_rebind": true,
		"risk": _shared_candidate_risk(max_edge, detail_scale),
	}

static func _shared_candidate_risk(max_edge: int, detail_scale: float) -> String:
	if max_edge > MOBILE_MAX_ATLAS_EDGE:
		return "reject_mobile_texture_limit"
	if detail_scale < DETAIL_SCALE_GATE:
		return "reject_detail_loss_until_visual_gate_passes"
	return "research_candidate"

static func _image_size(path: String) -> Vector2i:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return Vector2i.ZERO
	var bytes := file.get_buffer(file.get_length())
	file.close()
	if bytes.size() < 4 or bytes[0] != 0xff or bytes[1] != 0xd8:
		return Vector2i.ZERO
	var index := 2
	while index + 9 < bytes.size():
		if bytes[index] != 0xff:
			index += 1
			continue
		var marker := bytes[index + 1]
		index += 2
		if marker == 0xd9 or marker == 0xda:
			break
		if index + 1 >= bytes.size():
			break
		var segment_length := _read_u16(bytes, index)
		if segment_length < 2 or index + segment_length > bytes.size():
			break
		if marker in [0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf]:
			var height := _read_u16(bytes, index + 3)
			var width := _read_u16(bytes, index + 5)
			return Vector2i(width, height)
		index += segment_length
	return Vector2i.ZERO

static func _read_u16(bytes: PackedByteArray, index: int) -> int:
	if index + 1 >= bytes.size():
		return 0
	return (int(bytes[index]) << 8) | int(bytes[index + 1])

static func _file_size(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	var size := file.get_length()
	file.close()
	return size
