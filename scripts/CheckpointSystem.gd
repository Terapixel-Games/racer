extends Node3D

signal checkpoint_valid(body:Node, checkpoint_index:int, transform:Transform3D)
signal finish_line_crossed(body:Node)

@export var lap_gate_index := 0
@export var checkpoint_count := 3

var rules := CheckpointRules.new()
var last_valid_transform := {}

func _ready() -> void:
	rules = CheckpointRules.new(checkpoint_count, lap_gate_index)
	for area in get_children():
		if area is Area3D:
			if area.has_signal("body_entered"):
				area.body_entered.connect(_on_body_entered.bind(area))

func _on_body_entered(body:Node, area:Area3D) -> void:
	if not (body is CharacterBody3D):
		return
	if area is FinishLineArea:
		rules.on_finish_line_crossed()
		emit_signal("finish_line_crossed", body)
	elif area is CheckpointArea:
		if rules.on_checkpoint_passed(area.checkpoint_index):
			last_valid_transform[body] = area.global_transform
			emit_signal("checkpoint_valid", body, area.checkpoint_index, area.global_transform)

func get_last_valid(body:Node) -> Transform3D:
	return last_valid_transform.get(body, global_transform)
