extends "res://tests/framework/TestCase.gd"

const MANIFEST_PATH := "res://docs/home_yard_v3_meshy_first_asset_manifest.json"
const EXPECTED_PHASE_IDS := [
	"asset_inventory_and_replacement_triage",
	"concept_reference",
	"street_front_yard",
	"home_exterior",
	"interior_furnishings",
	"backyard",
	"course_identity",
	"full_house_gate",
]
const KENNEY_DECISION := "kenney_keep_review"
const NON_KENNEY_DECISION := "meshy_regenerate"
const REQUIRED_CONCEPT_ARTIFACTS := [
	"whole_house_reference.md",
	"street_front_yard_reference.md",
	"home_exterior_reference.md",
	"interior_layout_reference.md",
	"furnishings_reference.md",
	"backyard_reference.md",
	"course_identity_reference.md",
]

func test_meshy_first_policy_is_explicit() -> void:
	var manifest := _load_manifest()
	assert_equal(manifest.get("map_id", ""), "home_yard_v3", "Manifest should target home_yard_v3.")
	assert_true(str(manifest.get("iterator_goal", "")).find("production-ready home stage") >= 0, "Iterator goal should make the whole home stage primary.")
	assert_true(str(manifest.get("iterator_goal", "")).find("not the purpose of the loop") >= 0, "Iterator goal should keep Meshy subordinate to production readiness.")
	assert_equal(manifest.get("primary_generator", ""), "meshy", "Meshy should be the primary visible asset generator.")
	assert_equal(manifest.get("fallback_generator", ""), "toybox", "Toybox should be the fallback generator.")
	assert_equal(manifest.get("target_format", ""), "glb", "GLB should be the default Godot asset format.")

	var budget: Dictionary = manifest.get("credit_budget", {})
	assert_true(int(budget.get("available_start", 0)) >= 1800, "Manifest should record the intended Meshy credit budget.")
	assert_true(bool(budget.get("requires_confirmation_before_paid_batch", false)), "Paid Meshy batches must require confirmation.")

	var approval_gate: Dictionary = manifest.get("approval_gate", {})
	assert_true(bool(approval_gate.get("requires_confirmation", false)), "Approval gate should require explicit confirmation.")
	assert_true("estimated credits" in approval_gate.get("must_present", []), "Approval gate should require estimated credits.")
	assert_true("exact planned asset list" in approval_gate.get("must_present", []), "Approval gate should require exact planned assets.")

func test_whole_stage_production_domains_are_explicit() -> void:
	var manifest := _load_manifest()
	var domains: Array = manifest.get("production_domains", [])
	var domain_ids: Array = []
	for domain_value in domains:
		var domain: Dictionary = domain_value
		domain_ids.append(str(domain.get("id", "")))
		assert_true(str(domain.get("gate", "")) != "", "Each production domain should define a gate.")

	for required_domain in [
		"stage_concept_and_concept_art",
		"site_and_street_context",
		"front_yard",
		"backyard",
		"home_exterior_shell",
		"transparent_openings",
		"home_interior_layout",
		"home_furnishing_and_room_identity",
		"player_tracks_and_route_readability",
		"course_area_identity",
		"technical_import_and_generation_stability",
		"critical_visual_review",
	]:
		assert_true(required_domain in domain_ids, "Production iterator should cover %s." % required_domain)

	var sequence: Array = manifest.get("production_sequence", [])
	assert_true("concept_and_spatial_contract_review" in sequence, "Production sequence should begin from stage concept and spatial contract review.")
	assert_true("domain_inventory_and_defect_ranking" in sequence, "Production sequence should rank whole-stage defects, not only assets.")
	assert_true("regenerate_stage_artifacts" in sequence, "Production sequence should keep the stage generator-driven.")

func test_prompt_record_template_exists() -> void:
	var manifest := _load_manifest()
	var source_policy: Dictionary = manifest.get("source_policy", {})
	var template_path := str(source_policy.get("prompt_record_template_path", ""))
	assert_true(template_path.ends_with("_prompt_record_template.md"), "Prompt template path should point at the Meshy prompt template.")
	assert_true(FileAccess.file_exists(template_path), "Prompt template should exist at %s." % template_path)
	assert_true(bool(source_policy.get("prompt_records_required", false)), "Prompt records should be required for Meshy assets.")
	assert_equal(source_policy.get("godot_primitive_visible_assets", ""), "banned", "Visible Godot primitive assets should be banned.")

func test_production_gate_has_scoring_and_domain_acceptance() -> void:
	var manifest := _load_manifest()
	var rubric: Dictionary = manifest.get("scoring_rubric", {})
	assert_equal(rubric.get("scale", ""), "0_to_5", "Screenshot rubric should define a 0-5 scale.")
	assert_true(int(rubric.get("minimum_score_per_category", 0)) >= 4, "Production scoring should require at least 4 per category.")
	assert_true(bool(rubric.get("zero_score_blocks_gate", false)), "Any zero score should block the production gate.")
	for category in [
		"layout_clarity",
		"route_readability",
		"third_person_camera_clearance",
		"central_view_occlusion",
		"road_visibility",
		"next_turn_readability",
		"material_quality",
		"scale_consistency",
		"room_identity",
		"shell_closure",
		"yard_and_street_context",
		"furnishing_quality",
		"collision_risk",
		"transparent_window_quality",
		"placeholder_leak_check",
		"performance_health",
	]:
		assert_true(category in rubric.get("categories", []), "Scoring rubric should include %s." % category)

	var acceptance: Dictionary = manifest.get("per_domain_acceptance_tests", {})
	assert_true(bool(acceptance.get("requires_manifest_entry", false)), "Domain gates should require manifest entries.")
	assert_true(bool(acceptance.get("requires_validation_cameras", false)), "Domain gates should require validation cameras.")
	assert_true(bool(acceptance.get("requires_route_clearance_check", false)), "Domain gates should require route clearance checks.")
	assert_true(bool(acceptance.get("requires_screenshot_review_score", false)), "Domain gates should require screenshot scores.")

func test_concept_reference_and_batch_protocol_are_blocking() -> void:
	var manifest := _load_manifest()
	var concept: Dictionary = manifest.get("concept_reference_contract", {})
	assert_equal(concept.get("root", ""), "res://docs/concepts/home_yard_v3/", "Concept references should live under the home_yard_v3 concept folder.")
	assert_true(bool(concept.get("blocks_paid_asset_batches_until_present", false)), "Concept references should block paid asset batches.")
	assert_true("whole_house_reference.md" in concept.get("required_artifacts", []), "Whole-house reference should be required.")
	assert_true("course_identity_reference.md" in concept.get("required_artifacts", []), "Course identity reference should be required.")
	for artifact in REQUIRED_CONCEPT_ARTIFACTS:
		var artifact_path := "%s%s" % [str(concept.get("root", "")), artifact]
		assert_true(FileAccess.file_exists(artifact_path), "Concept artifact should exist: %s." % artifact_path)

	var batch: Dictionary = manifest.get("meshy_batch_protocol", {})
	assert_equal(batch.get("max_batch_scope", ""), "one_course_or_one_production_domain", "Meshy batches should stay scoped.")
	assert_true(bool(batch.get("requires_prompt_review_before_paid_call", false)), "Meshy batches should require prompt review.")
	assert_true(bool(batch.get("requires_cost_confirmation_before_paid_call", false)), "Meshy batches should require cost confirmation.")
	assert_equal(batch.get("default_model", ""), "meshy-6", "Meshy batch model should default to Meshy 6 for this production pass.")
	assert_equal(batch.get("default_target_format", ""), "glb", "Meshy batch target format should default to GLB.")

	var shortcut_policy: Dictionary = manifest.get("shortcut_policy", {})
	assert_equal(shortcut_policy.get("playable_shortcuts_this_pass", true), false, "Playable shortcuts should be deferred for this pass.")
	assert_equal(shortcut_policy.get("route_topology_changes_for_shortcuts", ""), "forbidden", "Shortcut route topology changes should be forbidden.")
	assert_equal(shortcut_policy.get("lap_or_progress_affecting_shortcut_gates", ""), "forbidden", "Shortcut gates should not affect lap/progress.")

func test_asset_lifecycle_and_replacement_provenance_are_required() -> void:
	var manifest := _load_manifest()
	var lifecycle: Array = manifest.get("asset_lifecycle_states", [])
	for state in [
		"planned",
		"prompt_approved",
		"generated",
		"imported",
		"optimized",
		"placed",
		"camera_validated",
		"accepted",
		"rejected",
		"superseded",
	]:
		assert_true(state in lifecycle, "Asset lifecycle should include %s." % state)

	var provenance: Dictionary = manifest.get("replacement_provenance_contract", {})
	assert_true(bool(provenance.get("required", false)), "Replacement provenance should be required.")
	assert_true(str(provenance.get("mapping_path", "")).ends_with("replacement_provenance.json"), "Replacement provenance should have a mapping file.")
	assert_true(FileAccess.file_exists(str(provenance.get("mapping_path", ""))), "Replacement provenance mapping file should exist.")
	for required_field in [
		"old_asset_path",
		"old_origin",
		"replacement_asset_path",
		"replacement_origin",
		"replacement_reason",
		"decision_state",
		"validation_result",
	]:
		assert_true(required_field in provenance.get("each_mapping_requires", []), "Replacement mapping should require %s." % required_field)

func test_route_collision_windows_drift_and_performance_gates_exist() -> void:
	var manifest := _load_manifest()
	var route: Dictionary = manifest.get("route_collision_clearance_contract", {})
	assert_true(float(route.get("minimum_lateral_clearance_m", 0.0)) >= 0.75, "Route lateral clearance should be measurable.")
	assert_true(float(route.get("minimum_vertical_clearance_m", 0.0)) >= 0.5, "Route vertical clearance should be measurable.")
	assert_equal(route.get("camera_model", ""), "third_person_chase_camera", "Home-yard route clearance should target the third-person chase camera.")
	assert_true(bool(route.get("requires_runtime_aabb_measurement", false)), "Route clearance should require runtime AABB measurement.")
	assert_true(bool(route.get("chase_camera_swept_volume_required", false)), "Route clearance should include the chase-camera swept volume.")
	assert_true(bool(route.get("visual_only_props_may_fail_occlusion", false)), "Visual-only props should still fail when they block third-person readability.")
	assert_equal(route.get("visual_only_collision", ""), "disabled_or_isolated_from_gameplay", "Visual-only collision should be disabled or isolated.")
	assert_true("no_unplanned_collision_intersections" in route.get("checks", []), "Route checks should reject unplanned collision intersections.")
	assert_true("no_unplanned_runtime_aabb_intersections" in route.get("checks", []), "Route checks should reject runtime AABB intersections.")
	assert_true("chase_camera_swept_volume_clearance" in route.get("checks", []), "Route checks should include third-person chase camera clearance.")

	var windows: Dictionary = manifest.get("transparent_window_material_gate", {})
	assert_true(bool(windows.get("required", false)), "Transparent window gate should be required.")
	assert_true(bool(windows.get("alpha_or_transmission_required", false)), "Window gate should require alpha or glass transmission.")
	assert_true(bool(windows.get("opaque_color_patch_blocks_gate", false)), "Opaque window patches should block production.")

	var drift: Dictionary = manifest.get("generator_scene_drift_guard", {})
	assert_true(bool(drift.get("final_scene_must_be_generator_driven", false)), "Final scene should remain generator-driven.")
	assert_true(bool(drift.get("manual_visible_scene_edits_block_gate", false)), "Manual visible scene edits should block the gate.")
	assert_true(str(drift.get("generator_path", "")).ends_with("GenerateHomeYardV3Map.gd"), "Drift guard should name the generator.")

	var performance: Dictionary = manifest.get("performance_budget", {})
	assert_equal(performance.get("target_profile", ""), "mobile_detail_phase1", "Performance gate should target the mobile detail profile.")
	assert_true(int(performance.get("total_stage_triangles_max", 0)) > 0, "Performance gate should include a total triangle budget.")
	assert_true(int(performance.get("unique_texture_size_max_px", 0)) <= 2048, "Performance gate should cap unique texture size.")

func test_import_dependency_failure_and_commit_protocols_exist() -> void:
	var manifest := _load_manifest()
	var importing: Dictionary = manifest.get("import_instability_automation", {})
	assert_true(str(importing.get("helper_script", "")).ends_with("resolve-godot-editor-dialogs.ps1"), "Import automation should name the dialog helper.")
	assert_true(str(importing.get("headless_import_command", "")).find("--import") >= 0, "Import automation should include the headless import command.")
	assert_true("editor_state_readiness_ready" in importing.get("post_recovery_checks", []), "Import recovery should recheck editor readiness.")

	var dependency_order: Array = manifest.get("dependency_order", [])
	for step in [
		"concept_reference_before_asset_batches",
		"floor_plan_before_shell",
		"shell_before_windows_doors_and_trim",
		"room_layout_before_furnishings",
		"route_contract_before_prop_placement",
		"collision_review_after_placement",
		"validation_cameras_after_placement",
		"screenshot_scoring_after_camera_validation",
		"commit_after_tests_and_visual_gate",
	]:
		assert_true(step in dependency_order, "Dependency order should include %s." % step)

	var failures: Dictionary = manifest.get("meshy_failure_handling", {})
	assert_true(int(failures.get("max_prompt_attempts_before_strategy_change", 0)) >= 2, "Meshy failures should allow prompt retries before strategy change.")
	assert_equal(failures.get("fallback_after_repeated_failure", ""), "toybox_or_kenney_keep_review", "Repeated Meshy failure should have a defined fallback.")
	assert_true(bool(failures.get("requires_rejection_notes", false)), "Rejected Meshy assets should require notes.")

	var commit_plan: Dictionary = manifest.get("commit_staging_plan", {})
	assert_true("source_asset_batch_and_prompt_records" in commit_plan.get("commit_units", []), "Commit plan should include asset batch and prompt records.")
	assert_true("full_house_production_gate" in commit_plan.get("commit_units", []), "Commit plan should include the full-house gate.")
	assert_true(bool(commit_plan.get("block_mixed_unrelated_dirty_work", false)), "Commit plan should block mixed unrelated dirty work.")
	assert_true(bool(commit_plan.get("requires_tests_before_commit", false)), "Commit plan should require tests before commit.")

func test_production_phase_order_is_locked() -> void:
	var manifest := _load_manifest()
	var phase_ids: Array = []
	for phase_value in manifest.get("phases", []):
		var phase: Dictionary = phase_value
		phase_ids.append(str(phase.get("id", "")))
	assert_equal(phase_ids, EXPECTED_PHASE_IDS, "Whole-house production phases should stay in the agreed order.")

func test_mesh_budget_matches_game_ready_limits() -> void:
	var manifest := _load_manifest()
	var mesh_budget: Dictionary = manifest.get("mesh_budget", {})
	assert_true(int(mesh_budget.get("small_prop_triangles_max", 999999)) <= 2000, "Small props should stay under 2k triangles.")
	assert_true(int(mesh_budget.get("medium_prop_triangles_max", 999999)) <= 8000, "Medium props should stay under 8k triangles.")
	assert_true(int(mesh_budget.get("hero_landmark_triangles_max", 999999)) <= 20000, "Hero landmarks should stay under 20k triangles.")
	assert_equal(mesh_budget.get("over_budget_action", ""), "remesh_or_regenerate_before_integration", "Over-budget Meshy assets should be remeshed or regenerated.")

func test_visible_asset_triage_defaults_non_kenney_to_meshy_regeneration() -> void:
	var manifest := _load_manifest()
	var triage_entries: Array = manifest.get("current_visible_asset_triage", [])
	assert_true(triage_entries.size() > 0, "Manifest should include current visible asset triage entries.")

	var non_kenney_count := 0
	var kenney_count := 0
	for entry_value in triage_entries:
		var entry: Dictionary = entry_value
		_assert_complete_triage_entry(entry)
		var source_family := str(entry.get("current_source_family", ""))
		assert_true(source_family != "godot_primitive", "Visible Godot primitives should not be allowed in triage.")
		assert_true(str(entry.get("decision", "")) != "carry_forward_unreviewed", "Visible assets should never be carried forward without review.")
		if source_family == "kenney":
			kenney_count += 1
			assert_equal(entry.get("decision", ""), KENNEY_DECISION, "Kenney assets should be review-gated keeps.")
			assert_equal(entry.get("replacement_default", true), false, "Kenney assets should not default to replacement.")
			assert_true(str(entry.get("asset_path", "")).find("/kenney/") >= 0, "Kenney triage entries should point to Kenney source paths.")
		else:
			non_kenney_count += 1
			assert_equal(entry.get("decision", ""), NON_KENNEY_DECISION, "Non-Kenney visible assets should default to Meshy regeneration.")
			assert_true(bool(entry.get("replacement_default", false)), "Non-Kenney visible assets should default to replacement.")

	assert_true(kenney_count > 0, "Manifest should include Kenney keep-review examples.")
	assert_true(non_kenney_count > 0, "Manifest should include non-Kenney regeneration candidates.")

func test_area_manifests_capture_validation_camera_contracts() -> void:
	var manifest := _load_manifest()
	var area_manifests: Array = manifest.get("area_manifests", [])
	assert_true(area_manifests.size() >= 8, "Area manifests should cover the full house and public courses.")
	for area_value in area_manifests:
		var area: Dictionary = area_value
		assert_true(str(area.get("area", "")) != "", "Area manifest should name an area.")
		var manifest_path := str(area.get("manifest_path", ""))
		assert_true(manifest_path.begins_with("res://assets/source/meshy/home_yard_v3/"), "Area manifest should live under the Meshy home_yard_v3 source tree.")
		assert_true(FileAccess.file_exists(manifest_path), "Area manifest file should exist at %s." % manifest_path)
		var parsed_area := _load_json_file(manifest_path)
		assert_equal(str(parsed_area.get("area", "")), str(area.get("area", "")), "Area manifest should identify its area.")
		assert_true((parsed_area.get("required_assets", []) as Array).size() > 0, "Area manifest should list required assets.")
		assert_true((parsed_area.get("validation_requirements", []) as Array).size() > 0, "Area manifest should list validation requirements.")
		assert_true(parsed_area.has("blocked_items"), "Area manifest should record blocked items, even when empty.")
		assert_true(area.get("required_reviews", []).size() > 0, "Area manifest should list critical review topics.")
		assert_true(area.get("validation_cameras", []).size() > 0, "Area manifest should list validation cameras.")

func test_beta_gate_specs_and_review_template_exist() -> void:
	var specs := _load_json_file("res://docs/validation/home_yard_v3/beta_gate_specs.json")
	assert_equal(str(specs.get("map_id", "")), "home_yard_v3", "Beta gate specs should target home_yard_v3.")
	var validators: Array = specs.get("executable_validators_to_add", [])
	assert_true(validators.size() >= 10, "Beta gate specs should enumerate missing executable validators.")
	for validator_value in validators:
		var validator: Dictionary = validator_value
		assert_true(str(validator.get("id", "")) != "", "Validator spec should have an id.")
		assert_true(str(validator.get("test_path", "")).begins_with("res://tests/"), "Validator spec should name its future test path.")
		assert_true(str(validator.get("pass", "")) != "", "Validator spec should define pass behavior.")
	assert_true(FileAccess.file_exists("res://docs/validation/home_yard_v3/beta_gate_existing_tests.md"), "Existing test inventory should exist.")
	assert_true(FileAccess.file_exists("res://docs/validation/home_yard_v3/screenshot_reviews/_template.md"), "Screenshot review template should exist.")

func _load_manifest() -> Dictionary:
	return _load_json_file(MANIFEST_PATH)

func _load_json_file(path: String) -> Dictionary:
	assert_true(FileAccess.file_exists(path), "JSON file should exist at %s." % path)
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "JSON file should be readable: %s." % path)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	assert_true(parsed is Dictionary, "JSON file should parse to an object: %s." % path)
	if parsed is Dictionary:
		return parsed
	return {}

func _assert_complete_triage_entry(entry: Dictionary) -> void:
	assert_true(str(entry.get("asset_id", "")) != "", "Triage entry should have an asset id.")
	assert_true(str(entry.get("asset_path", "")).begins_with("res://"), "Triage entry should have a res:// asset path.")
	assert_true(str(entry.get("area", "")) != "", "Triage entry should have an area.")
	assert_equal(entry.get("visible", false), true, "Triage entry should explicitly describe visible assets.")
	assert_true(str(entry.get("current_source_family", "")) != "", "Triage entry should classify current source family.")
	assert_true(str(entry.get("decision", "")) != "", "Triage entry should have a replacement decision.")
	assert_true(str(entry.get("target_prompt_slug", "")) != "", "Triage entry should have a target prompt slug.")
	assert_true(str(entry.get("validation_camera", "")) != "", "Triage entry should have a validation camera.")
	assert_true(str(entry.get("route_clearance", "")) != "", "Triage entry should have route clearance status.")
