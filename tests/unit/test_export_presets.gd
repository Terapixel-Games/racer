extends "res://tests/framework/TestCase.gd"

const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")

func test_web_export_includes_configured_optimized_racer_assets() -> void:
	var text := FileAccess.get_file_as_string("res://export_presets.cfg")
	assert_true(text.contains('name="Web"'), "Export presets should include a Web preset")
	assert_true(text.contains('export_filter="resources"'), "Web export should keep using the explicit resource allowlist")
	assert_true(not text.contains("assets/source/meshy/2026-04-27-character-track-batch"), "Web export should not allowlist legacy Meshy racer source GLBs")
	for racer_id in RacerRoster.select_order():
		var glb_path := RacerRoster.get_racer_in_kart_model_path_for_profile(racer_id, RacerRoster.RACER_ASSET_PROFILE_MOBILE_DETAIL_PHASE1, false)
		var atlas_path := glb_path.replace(".glb", "_Image_0.jpg")
		assert_true(text.contains(glb_path), "%s optimized GLB should be included in the Web export allowlist" % racer_id)
		assert_true(text.contains(atlas_path), "%s optimized atlas source image should be included in the Web export allowlist" % racer_id)

func test_android_export_excludes_source_asset_tree() -> void:
	var text := FileAccess.get_file_as_string("res://export_presets.cfg")
	assert_true(text.contains('assets/source/*,assets/source/**'), "Android export should exclude source assets so legacy racer GLBs do not ship")
