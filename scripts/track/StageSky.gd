extends RefCounted
class_name StageSky

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const StageSkyShader = preload("res://shaders/StageSky.gdshader")

const DEFAULT_PRESET_ID := "default_clear"

static func build_world_environment(definition: TrackDefinition) -> WorldEnvironment:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = build_sky(definition)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 0.8
	environment.ambient_light_energy = _ambient_energy(definition)
	environment.glow_enabled = true
	environment.glow_intensity = 0.04

	var env_node := WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	env_node.environment = environment
	return env_node

static func build_directional_light(definition: TrackDefinition) -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.name = "SunLight"
	var time_of_day := _time_of_day(definition)
	var angle := time_of_day * TAU
	var y := -maxf(sin(angle), 0.18)
	var direction := Vector3(cos(angle) * 0.45, y, 0.35).normalized()
	light.transform.basis = Basis.looking_at(direction, Vector3.UP)
	light.light_energy = _light_energy(definition)
	light.light_color = _sun_color(definition)
	light.shadow_enabled = true
	return light

static func build_sky(definition: TrackDefinition) -> Sky:
	var sky := Sky.new()
	if definition == null or definition.sky_preset_id.strip_edges().is_empty():
		var procedural := ProceduralSkyMaterial.new()
		procedural.sky_horizon_color = Color(0.58, 0.72, 0.9)
		procedural.ground_horizon_color = Color(0.64, 0.62, 0.58)
		sky.sky_material = procedural
		return sky
	var material := ShaderMaterial.new()
	material.shader = StageSkyShader
	material.set_shader_parameter("sky_top_color", definition.sky_top_color)
	material.set_shader_parameter("sky_horizon_color", definition.sky_horizon_color)
	material.set_shader_parameter("ground_haze_color", _haze_color(definition))
	material.set_shader_parameter("sun_color", _sun_color(definition))
	material.set_shader_parameter("time_of_day", _time_of_day(definition))
	material.set_shader_parameter("cloud_amount", clampf(definition.sky_cloud_amount, 0.0, 1.0))
	material.set_shader_parameter("cloud_speed", maxf(definition.sky_cloud_speed, 0.0))
	material.set_shader_parameter("haze_amount", clampf(definition.sky_haze_amount, 0.0, 1.0))
	material.set_shader_parameter("storm_darkness", _storm_darkness(definition))
	sky.sky_material = material
	return sky

static func _time_of_day(definition: TrackDefinition) -> float:
	return clampf(definition.sky_time_of_day if definition != null else 0.5, 0.0, 1.0)

static func _light_energy(definition: TrackDefinition) -> float:
	if definition == null:
		return 2.4
	return maxf(definition.sky_light_energy, 0.0)

static func _ambient_energy(definition: TrackDefinition) -> float:
	return clampf(_light_energy(definition) * 0.46, 0.35, 1.35)

static func _storm_darkness(definition: TrackDefinition) -> float:
	var weather := definition.sky_weather.to_lower() if definition != null else ""
	return 0.75 if weather.contains("storm") else 0.0

static func _sun_color(definition: TrackDefinition) -> Color:
	var weather := definition.sky_weather.to_lower() if definition != null else ""
	var time_of_day := _time_of_day(definition)
	if weather.contains("storm") or time_of_day >= 0.78 or time_of_day <= 0.18:
		return Color(0.62, 0.7, 1.0)
	if time_of_day >= 0.62:
		return Color(1.0, 0.68, 0.42)
	if time_of_day <= 0.32:
		return Color(1.0, 0.86, 0.62)
	return Color(1.0, 0.94, 0.78)

static func _haze_color(definition: TrackDefinition) -> Color:
	if definition == null:
		return Color(0.55, 0.57, 0.60)
	return definition.sky_horizon_color.lerp(Color(0.55, 0.56, 0.58), 0.35)
