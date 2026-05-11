extends "res://tests/framework/TestCase.gd"

const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")
const RacerSharedAtlasResearch = preload("res://scripts/logic/RacerSharedAtlasResearch.gd")

func test_shared_atlas_research_audits_current_racer_atlases() -> void:
	var report := RacerSharedAtlasResearch.collect()
	var racers: Array = report.get("racers", [])
	assert_equal(racers.size(), RacerRoster.select_order().size(), "Shared-atlas research should audit the full racer roster")
	assert_true(int(report.get("current_total_atlas_bytes", 0)) > 30 * 1024 * 1024, "Current racer atlas bytes should reflect the staged 2048 atlas set")
	for racer in racers:
		var entry := racer as Dictionary
		assert_true(bool(entry.get("atlas_exists", false)), "%s should have a staged atlas source file" % str(entry.get("id", "")))
		assert_equal(int(entry.get("atlas_width", 0)), 2048, "%s atlas width should stay at the current detail baseline" % str(entry.get("id", "")))
		assert_equal(int(entry.get("atlas_height", 0)), 2048, "%s atlas height should stay at the current detail baseline" % str(entry.get("id", "")))

func test_shared_atlas_research_rejects_preserve_detail_mobile_atlas() -> void:
	var report := RacerSharedAtlasResearch.collect()
	var preserve := _candidate(report, "shared_preserve_2048_4x2")
	assert_equal(int(preserve.get("width", 0)), 8192, "Preserving eight 2048 atlases in a 4x2 shared atlas should require 8192 width")
	assert_equal(int(preserve.get("height", 0)), 4096, "Preserving eight 2048 atlases in a 4x2 shared atlas should require 4096 height")
	assert_true(not bool(preserve.get("mobile_edge_gate_passes", true)), "Preserve-detail shared atlas should fail the 4096 mobile edge gate")
	assert_equal(str(preserve.get("risk", "")), "reject_mobile_texture_limit", "Preserve-detail shared atlas should be rejected for mobile texture limits")

func test_shared_atlas_research_rejects_mobile_safe_detail_loss() -> void:
	var report := RacerSharedAtlasResearch.collect()
	var mobile := _candidate(report, "shared_mobile_4096_4x2")
	assert_true(bool(mobile.get("mobile_edge_gate_passes", false)), "4096 shared atlas should pass the mobile edge gate")
	assert_equal(float(mobile.get("detail_scale", 0.0)), 0.5, "4096 shared atlas should cut per-racer atlas detail to half scale")
	assert_true(not bool(mobile.get("detail_gate_passes", true)), "4096 shared atlas should not pass the LOD0 detail-preservation gate")
	assert_equal(str(report.get("recommendation", "")), "defer_shared_atlas", "Shared atlas should stay deferred until visual gates justify detail loss")
	assert_true(not bool(report.get("production_switch_allowed", true)), "Research pass should not switch production assets")

func _candidate(report: Dictionary, candidate_id: String) -> Dictionary:
	for candidate in report.get("candidates", []):
		var entry := candidate as Dictionary
		if str(entry.get("id", "")) == candidate_id:
			return entry
	fail("Missing candidate: %s" % candidate_id)
	return {}
