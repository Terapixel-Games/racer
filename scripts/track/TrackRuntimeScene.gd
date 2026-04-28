@tool
extends Node3D
class_name TrackRuntimeScene

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")

@export var definition: TrackDefinition
@export var rebuild_on_ready := true

var build_result: Dictionary = {}

func _ready() -> void:
	if rebuild_on_ready:
		rebuild()

func rebuild() -> Dictionary:
	for child in get_children():
		if child.name == "BuiltTrack":
			child.queue_free()
	build_result = {}
	if definition == null:
		return build_result
	var built := TrackRuntimeBuilder.build(definition)
	var node := built.get("node", null) as Node3D
	if node != null:
		node.name = "BuiltTrack"
		add_child(node)
	build_result = built
	return build_result
