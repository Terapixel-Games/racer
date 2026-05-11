shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float blur : hint_range(0.0, 8.0) = 3.2;
uniform float warp_intensity : hint_range(0.0, 1.0) = 0.26;
uniform float strength_x : hint_range(0.0, 50.0) = 11.0;
uniform float strength_y : hint_range(0.0, 50.0) = 11.0;
uniform float offset_x : hint_range(-1.0, 1.0) = 0.0;
uniform float offset_y : hint_range(-1.0, 1.0) = 0.0;

uniform float corner_radius : hint_range(0.0, 1.0) = 0.3;
uniform float edge_smoothness : hint_range(0.5, 3.0) = 1.05;

uniform vec4 tint : source_color = vec4(0.92, 0.97, 1.0, 0.20);
uniform vec4 edge_highlight : source_color = vec4(1.0, 1.0, 1.0, 0.34);
uniform float edge_width : hint_range(0.0, 10.0) = 1.4;
uniform float chromatic_strength : hint_range(0.0, 5.0) = 1.0;
uniform float inner_shadow : hint_range(0.0, 1.0) = 0.16;
uniform float sheen_strength : hint_range(0.0, 1.0) = 0.18;
uniform float sample_guard : hint_range(0.0, 4.0) = 1.0;

float rounded_box(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void fragment() {
    vec2 uv_panel = UV;
    vec2 uv_screen = SCREEN_UV;
    float dx = dFdx(uv_panel.x);
    float dy = dFdy(uv_panel.y);

    dx = sign(dx) * max(abs(dx), 0.0001);
    dy = sign(dy) * max(abs(dy), 0.0001);

    vec2 size = abs(vec2(1.0 / dx, 1.0 / dy));
    size = clamp(size, vec2(1.0), vec2(4096.0));

    vec2 half_size = size * 0.5;
    vec2 pixel = uv_panel * size;
    vec2 centered = pixel - half_size;

    float max_r = min(half_size.x, half_size.y);
    float r = corner_radius * max_r;

    float sdf = rounded_box(centered, half_size, r);
    float alpha = 1.0 - smoothstep(-edge_smoothness, edge_smoothness, sdf);
    if (alpha < 0.001) {
        discard;
    }

    float max_dist = max(min(half_size.x, half_size.y) * 0.5, 0.0001);
    float w = clamp(-sdf / max_dist, 0.0, 1.0);

    vec2 uv_dir = length(centered) > 0.001 ? normalize(centered) : vec2(0.0, 1.0);

    float exp_x = exp(-strength_x * pow(w + offset_x, 2.0));
    float exp_y = exp(-strength_y * pow(w + offset_y, 2.0));
    vec2 warp_offset = uv_dir * vec2(exp_x, exp_y) * warp_intensity / 10.0;
    vec2 screen_texel = 1.0 / max(vec2(textureSize(screen_texture, 0)), vec2(1.0));
    vec2 guard = screen_texel * sample_guard;
    vec2 warped_uv = clamp(uv_screen - warp_offset, guard, vec2(1.0) - guard);

    float edge_proximity = 1.0 - w;
    vec2 chroma_offset = uv_dir * edge_proximity * chromatic_strength * screen_texel;

    float bg_r = textureLod(screen_texture, clamp(warped_uv - chroma_offset, guard, vec2(1.0) - guard), blur).r;
    float bg_g = textureLod(screen_texture, warped_uv, blur).g;
    float bg_b = textureLod(screen_texture, clamp(warped_uv + chroma_offset, guard, vec2(1.0) - guard), blur).b;
    vec3 bg = vec3(bg_r, bg_g, bg_b);

    vec3 color = mix(bg, tint.rgb, tint.a);

    float edge = 1.0 - smoothstep(0.0, edge_width, -sdf);
    edge *= step(sdf, 0.0);
    color = mix(color, edge_highlight.rgb, edge * edge_highlight.a);

    float top_sheen = smoothstep(0.52, 0.0, uv_panel.y) * smoothstep(0.04, 0.55, uv_panel.x) * smoothstep(0.96, 0.45, uv_panel.x);
    float lower_shadow = smoothstep(0.45, 1.0, uv_panel.y) * smoothstep(0.0, 0.8, w);
    color += edge_highlight.rgb * top_sheen * sheen_strength * w;
    color *= 1.0 - lower_shadow * inner_shadow * 0.35;

    COLOR = vec4(color, alpha);
}
