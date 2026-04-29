@tool
extends Marker3D
class_name AudioZoneAuthoring

@export var zone_id := ""
@export var audio_id := ""
@export_file("*.wav", "*.ogg", "*.mp3") var audio_path := ""
@export_enum("ambient", "oneshot") var zone_kind := "ambient"
@export var radius := 12.0
@export var volume_db := -6.0

func to_audio_zone() -> Dictionary:
	return {
		"id": zone_id if not zone_id.strip_edges().is_empty() else str(name),
		"audio_id": audio_id,
		"audio_path": audio_path,
		"zone_kind": zone_kind,
		"radius": radius,
		"volume_db": volume_db,
		"position": [position.x, position.y, position.z],
	}
