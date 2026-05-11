shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_toon, specular_toon;

uniform vec4 shallow_color : source_color = vec4(0.28, 0.82, 1.0, 0.62);
uniform vec4 deep_color : source_color = vec4(0.03, 0.24, 0.78, 0.72);
uniform vec4 foam_color : source_color = vec4(0.9, 1.0, 1.0, 0.9);
uniform float wave_strength : hint_range(0.0, 1.0) = 0.12;
uniform float wave_speed : hint_range(0.0, 6.0) = 1.25;
uniform float foam_cutoff : hint_range(0.0, 1.0) = 0.64;
uniform float foam_scale : hint_range(1.0, 60.0) = 18.0;
uniform float edge_clarity : hint_range(0.0, 1.0) = 0.45;
uniform float highlight_strength : hint_range(0.0, 1.0) = 0.22;
uniform float normal_tilt : hint_range(0.0, 1.0) = 0.18;

varying float wave_height;

float wave_noise(vec2 p) {
	return sin(p.x * 1.7 + TIME * wave_speed)
		+ sin((p.y * 2.3 + p.x * 0.4) - TIME * wave_speed * 1.4)
		+ sin((p.x - p.y) * 0.9 + TIME * wave_speed * 0.8);
}

void vertex() {
	float wave = wave_noise(UV * foam_scale) * wave_strength;
	wave_height = wave;
	VERTEX.y += wave;
	NORMAL = normalize(NORMAL + vec3(wave * normal_tilt, 0.0, -wave * normal_tilt));
}

void fragment() {
	float depth_mix = clamp(UV.y + sin((UV.x + TIME * 0.08) * 6.283) * 0.08, 0.0, 1.0);
	vec4 water = mix(shallow_color, deep_color, depth_mix);
	float foam_wave = wave_noise(UV * foam_scale + vec2(TIME * 0.15, -TIME * 0.1)) * 0.5 + 0.5;
	float rim = 1.0 - smoothstep(0.0, 0.12, min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)));
	float crest = smoothstep(0.0, wave_strength * 1.5 + 0.001, wave_height);
	float foam = max(smoothstep(foam_cutoff, 1.0, foam_wave) * 0.36, rim * (0.52 + edge_clarity * 0.32));
	vec4 color = mix(water, foam_color, foam);
	color.rgb += foam_color.rgb * crest * highlight_strength;
	ALBEDO = color.rgb;
	ROUGHNESS = 0.18;
	SPECULAR = 0.55;
	ALPHA = color.a;
}
