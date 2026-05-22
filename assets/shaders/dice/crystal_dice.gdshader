shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D orm_texture : filter_linear_mipmap, repeat_enable;
uniform sampler2D emission_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D flow_mask_texture : filter_linear_mipmap, repeat_enable;
uniform sampler2D height_texture : filter_linear_mipmap, repeat_enable;

uniform float alpha_base : hint_range(0.0, 1.0, 0.01) = 0.42;
uniform float emission_power : hint_range(0.0, 8.0, 0.05) = 1.15;
uniform float fresnel_power : hint_range(0.5, 8.0, 0.05) = 3.2;
uniform float flow_speed : hint_range(0.0, 4.0, 0.01) = 0.18;
uniform vec4 glow_color : source_color = vec4(0.30, 0.95, 1.00, 1.0);
uniform vec4 tint_color : source_color = vec4(0.45, 0.88, 1.00, 1.0);

void fragment() {
	vec2 flow_uv = UV + vec2(TIME * flow_speed, TIME * flow_speed * 0.31);
	vec4 albedo_sample = texture(albedo_texture, UV);
	vec3 orm_sample = texture(orm_texture, UV).rgb;
	vec3 emission_sample = texture(emission_texture, UV).rgb;
	float flow_sample = texture(flow_mask_texture, flow_uv).r;
	float height_sample = texture(height_texture, UV).r;
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), fresnel_power);

	vec3 tinted = mix(albedo_sample.rgb, tint_color.rgb, 0.62);
	ALBEDO = mix(tinted, glow_color.rgb, clamp(flow_sample * 0.18 + height_sample * 0.08, 0.0, 0.35));
	METALLIC = 0.0;
	ROUGHNESS = clamp(orm_sample.g * 0.62 + 0.03, 0.02, 0.55);
	AO = orm_sample.r;
	NORMAL_MAP = texture(normal_texture, UV).rgb;
	EMISSION = (emission_sample + glow_color.rgb * (fresnel * 0.78 + flow_sample * 0.55)) * emission_power;
	ALPHA = clamp(alpha_base * albedo_sample.a + fresnel * 0.22 + flow_sample * 0.10, 0.18, 0.78);
}
