extends "res://tests/framework/TestCase.gd"

const PackageSizeAudit = preload("res://scripts/logic/PackageSizeAudit.gd")

func test_package_size_audit_tracks_racer_optimization_savings() -> void:
	var audit := PackageSizeAudit.collect()
	var source_bytes := int(audit.get("source_racer_in_kart_glb_bytes", 0))
	var optimized_bytes := int(audit.get("optimized_racer_glb_bytes", 0))
	var lod_bytes := int(audit.get("optimized_racer_lod_glb_bytes", 0))
	var savings_bytes := int(audit.get("racer_glb_savings_bytes", 0))
	assert_true(source_bytes > 400 * 1024 * 1024, "Source racer GLBs should still represent the large baseline")
	assert_true(optimized_bytes > 200 * 1024 * 1024, "Optimized racer GLBs should be staged for runtime")
	assert_equal(optimized_bytes, int(audit.get("optimized_racer_lod0_glb_bytes", 0)), "Legacy optimized GLB metric should track LOD0 for stable savings reports")
	assert_true(optimized_bytes < source_bytes, "Optimized racer GLBs should be smaller than source racer GLBs")
	assert_true(float(audit.get("optimized_glb_source_ratio", 1.0)) <= 0.5, "Optimized racer GLBs should stay at or below half of source GLB size")
	assert_true(savings_bytes > 200 * 1024 * 1024, "Racer GLB optimization should retain more than 200 MB of savings")
	assert_true(lod_bytes >= 0, "Optional LOD GLB cost should be reported separately from LOD0 savings")
	assert_equal(int(audit.get("optimized_racer_lod_atlas_source_bytes", -1)), 0, "LOD GLBs should reuse LOD0 atlas source images instead of staging duplicate LOD atlas images")

func test_package_size_audit_reports_web_build_when_present() -> void:
	var audit := PackageSizeAudit.collect()
	var largest_files: Array = audit.get("largest_web_build_files", [])
	assert_true(int(audit.get("web_pck_bytes", 0)) >= 0, "Web PCK bytes should always be reported")
	if int(audit.get("web_build_total_bytes", 0)) > 0:
		assert_true(int(audit.get("web_pck_bytes", 0)) > 0, "Existing Web build should report index.pck size")
		assert_true(not largest_files.is_empty(), "Existing Web build should include largest-file diagnostics")
		assert_equal(str((largest_files[0] as Dictionary).get("path", "")), "res://build/web/index.pck", "The PCK should be the largest current Web build artifact")

func test_package_size_audit_reports_web_export_resource_categories() -> void:
	var audit := PackageSizeAudit.collect()
	var category_bytes: Dictionary = audit.get("web_export_resource_category_bytes", {})
	assert_true(category_bytes.has("racer_lod0"), "Web export diagnostics should split LOD0 racer assets into their own category")
	assert_true(category_bytes.has("racer_lod"), "Web export diagnostics should split staged racer LOD assets into their own category")
	assert_true(category_bytes.has("racer_textures"), "Web export diagnostics should report racer texture source bytes separately")
	assert_true(category_bytes.has("environment_assets"), "Web export diagnostics should report track/environment asset bytes separately")
	assert_true(category_bytes.has("ui_assets"), "Web export diagnostics should report UI/headshot bytes separately")
	assert_true(category_bytes.has("addons_scripts"), "Web export diagnostics should report addon script bytes separately")
	assert_true(category_bytes.has("game_scripts"), "Web export diagnostics should report game script bytes separately")
	assert_true(int(audit.get("web_export_resource_files_total_bytes", 0)) > 0, "Web export resource allowlist should have measurable source bytes")
	assert_true(int(category_bytes.get("racer_lod0", 0)) > 0, "LOD0 racer export bytes should be measurable")
	assert_true(int(category_bytes.get("racer_lod", 0)) > 0, "Staged LOD racer export bytes should be measurable")

func test_package_size_audit_reports_android_packages_when_present() -> void:
	var audit := PackageSizeAudit.collect()
	var package_files: Array = audit.get("android_package_files", [])
	assert_true(int(audit.get("android_package_total_bytes", 0)) >= 0, "Android package bytes should always be reported")
	if not package_files.is_empty():
		var package_total := 0
		for package_file in package_files:
			var path := str((package_file as Dictionary).get("path", ""))
			var bytes := int((package_file as Dictionary).get("bytes", 0))
			assert_true(path.ends_with(".apk") or path.ends_with(".aab"), "Android package diagnostics should include APK/AAB artifacts only")
			assert_true(bytes > 0, "Existing Android package artifacts should report nonzero size")
			package_total += bytes
		assert_equal(int(audit.get("android_package_total_bytes", 0)), package_total, "Android package total should match reported package artifacts")
		assert_true(str(audit.get("android_latest_package_path", "")).ends_with(".apk") or str(audit.get("android_latest_package_path", "")).ends_with(".aab"), "Latest Android package should identify an APK/AAB path")
		assert_true(int(audit.get("android_latest_package_bytes", 0)) > 0, "Latest Android package should report nonzero size")

func test_package_size_audit_formats_megabytes_for_reports() -> void:
	assert_equal(PackageSizeAudit.bytes_to_mb(1536 * 1024), 1.5, "Byte-to-MB formatting should use binary megabytes rounded to one decimal")
