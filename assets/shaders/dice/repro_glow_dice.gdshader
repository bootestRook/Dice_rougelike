shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.16, 0.42, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(0.65, 0.88, 1.0, 1.0);
uniform vec4 emission_color : source_color = vec4(0.18, 0.56, 1.0, 1.0);
uniform float metallic : hint_range(0.0, 1.0, 0.01) = 0.18;
uniform float roughness : hint_range(0.02, 1.0, 0.01) = 0.34;
uniform float emission_strength : hint_range(0.0, 4.0, 0.01) = 0.12;
uniform float fresnel_strength : hint_range(0.0, 5.0, 0.01) = 0.62;
uniform float fresnel_power : hint_range(0.5, 8.0, 0.05) = 3.0;
uniform float surface_variation : hint_range(0.0, 0.20, 0.01) = 0.035;
uniform float face_detail_strength : hint_range(0.0, 2.0, 0.01) = 1.0;
uniform float edge_line_strength : hint_range(0.0, 2.0, 0.01) = 1.0;
uniform float corner_glint_strength : hint_range(0.0, 2.0, 0.01) = 0.45;
uniform float side_shadow_strength : hint_range(0.0, 1.0, 0.01) = 0.36;
uniform sampler2D face_albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float face_layer_enabled : hint_range(0.0, 1.0, 1.0) = 0.0;
uniform float face_layer_strength : hint_range(0.0, 1.0, 0.01) = 1.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float ring_line(float value, float center, float width, float feather) {
	return 1.0 - smoothstep(width, width + feather, abs(value - center));
}

float corner_glint(vec2 uv, vec2 corner) {
	vec2 d = abs(uv - corner);
	float diagonal = abs(d.x - d.y);
	float arm = 1.0 - smoothstep(0.020, 0.115, min(d.x, d.y));
	float taper = 1.0 - smoothstep(0.000, 0.030, diagonal);
	return clamp(arm * taper, 0.0, 1.0);
}

void fragment() {
	float view_dot = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fresnel = pow(1.0 - view_dot, fresnel_power);
	vec2 face_uv = fract(UV * vec2(3.0, 2.0));
	float face_edge_distance = min(min(face_uv.x, 1.0 - face_uv.x), min(face_uv.y, 1.0 - face_uv.y));
	float bevel_edge = 1.0 - smoothstep(0.020, 0.135, face_edge_distance);
	float inset_line = ring_line(face_edge_distance, 0.145, 0.010, 0.018);
	float inner_shadow = 1.0 - smoothstep(0.080, 0.205, face_edge_distance);
	float star_cross = ring_line(abs(face_uv.x - 0.5), 0.0, 0.004, 0.016) * ring_line(abs(face_uv.y - 0.5), 0.0, 0.004, 0.016);
	float corner_marks = 0.0;
	corner_marks = max(corner_marks, corner_glint(face_uv, vec2(0.18, 0.18)));
	corner_marks = max(corner_marks, corner_glint(face_uv, vec2(0.82, 0.18)));
	corner_marks = max(corner_marks, corner_glint(face_uv, vec2(0.18, 0.82)));
	corner_marks = max(corner_marks, corner_glint(face_uv, vec2(0.82, 0.82)));
	float fine_grain = hash21(UV * 176.0) - 0.5;
	float soft_panel_noise = hash21(floor(UV * 48.0)) - 0.5;
	float detail_mask = clamp(inset_line * 0.70 + bevel_edge * 0.42 + corner_marks * corner_glint_strength + star_cross * 0.14, 0.0, 1.0);
	float side_weight = smoothstep(0.16, 0.92, abs(NORMAL.x));
	float vertical_weight = smoothstep(-0.12, 0.82, NORMAL.y);
	float face_light_rolloff = clamp(0.74 + vertical_weight * 0.24 - side_weight * 0.20 + fresnel * 0.05, 0.48, 1.04);
	vec3 body = base_color.rgb * face_light_rolloff * (1.0 + (fine_grain + soft_panel_noise * 0.35) * surface_variation);
	body *= 1.0 - inner_shadow * side_shadow_strength * face_detail_strength;
	body = mix(body, edge_color.rgb, clamp((bevel_edge * 0.08 + inset_line * 0.06) * edge_line_strength, 0.0, 0.22));
	vec3 final_albedo = mix(body, edge_color.rgb, clamp(fresnel * 0.025 + detail_mask * 0.045 * face_detail_strength, 0.0, 0.20));
	if (face_layer_enabled > 0.5) {
		vec4 face_layer = texture(face_albedo_texture, UV);
		float layer_alpha = clamp(face_layer.a * face_layer_strength, 0.0, 1.0);
		vec3 shaded_face = face_layer.rgb * face_light_rolloff;
		final_albedo = mix(final_albedo, shaded_face, layer_alpha);
	}
	ALBEDO = final_albedo;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = 0.72;
	EMISSION = emission_color.rgb * emission_strength * (0.18 + fresnel * 0.42) + edge_color.rgb * (fresnel * fresnel_strength * 0.28 + detail_mask * 0.035 * face_detail_strength);
	ALPHA = base_color.a;
}
