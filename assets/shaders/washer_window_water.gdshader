shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_toon, specular_toon;

uniform vec4 shallow_color : source_color = vec4(0.20, 0.62, 0.92, 0.56);
uniform vec4 deep_color : source_color = vec4(0.02, 0.14, 0.52, 0.78);
uniform vec4 foam_color : source_color = vec4(0.72, 0.93, 1.0, 0.56);
uniform float wave_speed : hint_range(0.0, 6.0) = 0.9;
uniform float foam_cutoff : hint_range(0.0, 1.0) = 0.67;
uniform float foam_scale : hint_range(1.0, 60.0) = 13.0;
uniform float aperture_radius : hint_range(0.1, 0.8) = 0.47;
uniform float aperture_softness : hint_range(0.001, 0.2) = 0.025;
uniform float fill_level : hint_range(0.0, 1.0) = 0.96;
uniform float fill_softness : hint_range(0.001, 0.2) = 0.055;
uniform float fill_wave : hint_range(0.0, 0.2) = 0.045;
uniform vec2 window_center = vec2(0.12855, 0.0);
uniform vec2 window_radius = vec2(0.087, 0.087);

varying vec3 local_vertex;

float wave_noise(vec2 p) {
	return sin(p.x * 1.7 + TIME * wave_speed)
		+ sin((p.y * 2.3 + p.x * 0.4) - TIME * wave_speed * 1.4)
		+ sin((p.x - p.y) * 0.9 + TIME * wave_speed * 0.8);
}

void vertex() {
	local_vertex = VERTEX;
}

void fragment() {
	vec2 p = vec2(
		(local_vertex.x - window_center.x) / max(window_radius.x, 0.001),
		(local_vertex.z - window_center.y) / max(window_radius.y, 0.001)
	);
	vec2 window_uv = p * 0.5 + vec2(0.5);
	float circle = 1.0 - smoothstep(aperture_radius * 2.0, aperture_radius * 2.0 + aperture_softness, length(p));
	float surface = fill_level
		+ sin(window_uv.x * 10.0 + TIME * wave_speed) * fill_wave
		+ sin(window_uv.x * 21.0 - TIME * wave_speed * 0.7) * fill_wave * 0.45;
	float fill = 1.0 - smoothstep(surface, surface + fill_softness, window_uv.y);
	float mask = circle * fill;
	if (mask <= 0.01) {
		discard;
	}

	float swirl = wave_noise(p * foam_scale * 0.28 + vec2(TIME * 0.12, -TIME * 0.08)) * 0.5 + 0.5;
	float depth_mix = clamp(window_uv.y + sin((window_uv.x + TIME * 0.08) * 6.283) * 0.08 + swirl * 0.18, 0.0, 1.0);
	vec4 water = mix(shallow_color, deep_color, depth_mix);
	float foam_wave = wave_noise(p * foam_scale + vec2(TIME * 0.15, -TIME * 0.1)) * 0.5 + 0.5;
	float foam = smoothstep(foam_cutoff, 1.0, foam_wave) * 0.42;
	vec4 color = mix(water, foam_color, foam);
	ALBEDO = color.rgb;
	ROUGHNESS = 0.22;
	SPECULAR = 0.45;
	ALPHA = color.a * mask;
}
