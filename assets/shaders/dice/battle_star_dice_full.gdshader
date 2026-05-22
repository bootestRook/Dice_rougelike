shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_albedo : source_color = vec4(0.04, 0.16, 0.56, 1.0);
uniform vec4 edge_color : source_color = vec4(0.55, 0.84, 1.0, 1.0);
uniform vec4 emission_color : source_color = vec4(0.10, 0.48, 1.0, 1.0);
uniform float metallic_value : hint_range(0.0, 1.0, 0.01) = 0.24;
uniform float roughness_value : hint_range(0.02, 1.0, 0.01) = 0.30;
uniform float emission_energy : hint_range(0.0, 3.0, 0.01) = 0.62;
uniform float emission_mask_power : hint_range(0.0, 2.0, 0.01) = 1.10;
uniform float fake_normal_strength : hint_range(0.0, 1.0, 0.01) = 0.32;
uniform float panel_shadow_strength : hint_range(0.0, 1.0, 0.01) = 0.36;
uniform float micro_detail_strength : hint_range(0.0, 0.20, 0.01) = 0.055;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float line_mask(float value, float center, float width, float feather) {
	return 1.0 - smoothstep(width, width + feather, abs(value - center));
}

float corner_spark(vec2 uv, vec2 corner) {
	vec2 d = abs(uv - corner);
	float arm = 1.0 - smoothstep(0.025, 0.13, min(d.x, d.y));
	float diagonal = 1.0 - smoothstep(0.000, 0.040, abs(d.x - d.y));
	return clamp(arm * diagonal, 0.0, 1.0);
}

void fragment() {
	vec2 face_uv = fract(UV * vec2(3.0, 2.0));
	float face_edge_distance = min(min(face_uv.x, 1.0 - face_uv.x), min(face_uv.y, 1.0 - face_uv.y));
	float bevel_edge_mask = 1.0 - smoothstep(0.018, 0.145, face_edge_distance);
	float inset_border_mask = line_mask(face_edge_distance, 0.168, 0.010, 0.020);
	float inset_shadow_mask = 1.0 - smoothstep(0.095, 0.235, face_edge_distance);
	float cross_detail = line_mask(abs(face_uv.x - 0.5), 0.0, 0.004, 0.018) * line_mask(abs(face_uv.y - 0.5), 0.0, 0.004, 0.018);
	float glint = 0.0;
	glint = max(glint, corner_spark(face_uv, vec2(0.18, 0.18)));
	glint = max(glint, corner_spark(face_uv, vec2(0.82, 0.18)));
	glint = max(glint, corner_spark(face_uv, vec2(0.18, 0.82)));
	glint = max(glint, corner_spark(face_uv, vec2(0.82, 0.82)));

	float grain_a = hash21(UV * 180.0) - 0.5;
	float grain_b = hash21(floor(UV * 54.0)) - 0.5;
	float fake_normal_detail = (grain_a * 0.65 + grain_b * 0.35) * fake_normal_strength;
	float view_dot = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fresnel = pow(1.0 - view_dot, 2.7);
	float top_light = clamp(0.72 + NORMAL.y * 0.22 - abs(NORMAL.x) * 0.13 + fresnel * 0.06, 0.46, 1.08);

	float emission_mask = clamp(
		bevel_edge_mask * 0.28 +
		inset_border_mask * 0.88 +
		glint * 0.44 +
		cross_detail * 0.15,
		0.0,
		1.0
	) * emission_mask_power;
	float panel_shadow = inset_shadow_mask * panel_shadow_strength;
	vec3 body = base_albedo.rgb * top_light;
	body *= 1.0 + fake_normal_detail * micro_detail_strength * 10.0;
	body *= 1.0 - panel_shadow;
	body = mix(body, edge_color.rgb, clamp(bevel_edge_mask * 0.10 + inset_border_mask * 0.08, 0.0, 0.22));

	ALBEDO = mix(body, edge_color.rgb, clamp(emission_mask * 0.055, 0.0, 0.18));
	METALLIC = metallic_value;
	ROUGHNESS = clamp(roughness_value + grain_b * 0.035, 0.04, 0.96);
	SPECULAR = 0.78;
	EMISSION = emission_color.rgb * emission_energy * emission_mask + edge_color.rgb * fresnel * 0.18;
	ALPHA = base_albedo.a;
}
