extends SceneTree

const PackageSizeAudit = preload("res://scripts/logic/PackageSizeAudit.gd")

func _init() -> void:
	var audit := PackageSizeAudit.collect()
	print(JSON.stringify(audit, "\t"))
	quit(0)
