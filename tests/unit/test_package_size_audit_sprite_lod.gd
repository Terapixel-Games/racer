extends "res://tests/framework/TestCase.gd"

const PackageSizeAudit = preload("res://scripts/logic/PackageSizeAudit.gd")

func test_package_size_audit_reports_sprite_backed_lod_bytes() -> void:
	var audit := PackageSizeAudit.collect()
	var category_bytes: Dictionary = audit.get("web_export_resource_category_bytes", {})
	assert_true(category_bytes.has("racer_lod_sprites"), "Web export diagnostics should split sprite-backed racer LOD assets into their own category")
	assert_true(int(category_bytes.get("racer_lod_sprites", 0)) > 0, "Rexx sprite-backed LOD2 export bytes should be measurable")
	assert_true(int(audit.get("optimized_racer_lod_sprite_bytes", 0)) > 0, "Package audit should report staged sprite-backed racer LOD bytes")
