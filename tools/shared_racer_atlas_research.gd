extends SceneTree

const RacerSharedAtlasResearch = preload("res://scripts/logic/RacerSharedAtlasResearch.gd")

func _init() -> void:
	var report := RacerSharedAtlasResearch.collect()
	print(JSON.stringify(report, "\t"))
	quit(0)
