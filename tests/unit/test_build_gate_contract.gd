extends "res://tests/framework/TestCase.gd"

func test_build_gate_runs_required_phase6_checks() -> void:
	var script := FileAccess.get_file_as_string("res://scripts/run-build-gate.ps1")
	assert_true(script.contains("run-tests.ps1"), "Build gate should run the public unit/UAT test runner")
	assert_true(script.contains("package_size_audit.gd"), "Build gate should run PackageSizeAudit after export")
	assert_true(script.contains("--export-release"), "Build gate should create a fresh release export before auditing package size")
	assert_true(script.contains("RacerVisualRegressionCapture.gd"), "Build gate should smoke-check racer visual regression inputs when racer assets change")
	assert_true(script.contains("500000000"), "Build gate should enforce the current Web PCK budget")

func test_build_gate_blocks_known_racer_package_regressions() -> void:
	var script := FileAccess.get_file_as_string("res://scripts/run-build-gate.ps1")
	assert_true(script.contains("assets/source/meshy/2026-04-27-character-track-batch"), "Build gate should fail if legacy Meshy racer sources enter the Web export allowlist")
	assert_true(script.contains("assets/source/*,assets/source/**"), "Build gate should fail if Android stops excluding source assets")
	assert_true(script.contains("optimized_racer_lod0_glb_bytes"), "Build gate should require optimized LOD0 racer GLBs")
	assert_true(script.contains("optimized_racer_lod_glb_bytes"), "Build gate should require staged racer LOD GLBs")
	assert_true(script.contains("optimized_racer_lod_atlas_source_bytes"), "Build gate should fail if duplicate LOD atlas source images return")

func test_github_actions_runs_phase6_build_gate() -> void:
	var workflow := FileAccess.get_file_as_string("res://.github/workflows/godot-tests.yml")
	assert_true(workflow.contains("build-gate:"), "Godot CI should include a Phase 6 build-gate job")
	assert_true(workflow.contains("Install Godot Headless + Export Templates"), "Build gate job should install export templates for a real Web export")
	assert_true(workflow.contains("run-build-gate.ps1"), "Build gate job should call the shared local gate script")
