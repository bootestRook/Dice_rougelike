shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float albedo_texture_enabled : hint_range(0.0, 1.0, 1.0) = 0.0;

uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_texture_enabled : hint_range(0.0, 1.0, 1.0) = 0.0;

uniform sampler2D orm_texture : filter_linear_mipmap, repeat_enable;
uniform float orm_texture_enabled : hint_range(0.0, 1.0, 1.0) = 0.0;

uniform sampler2D emission_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float emission_texture_enabled : hint_range(0.0, 1.0, 1.0) = 0.0;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy : hint_range(0.0, 8.0, 0.01) = 0.0;

uniform sampler2D height_texture : filter_linear_mipmap, repeat_enable;
uniform float height_texture_enabled : hint_range(0.0, 1.0, 1.0) = 0.0;
uniform float heightmap_scale : hint_range(0.0, 0.20, 0.001) = 0.0;

uniform sampler2D face_albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float face_layer_enabled : hint_range(0.0, 1.0, 1.0) = 0.0;
uniform float face_layer_strength : hint_range(0.0, 1.0, 0.01) = 1.0;

uniform float metallic_value : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float roughness_value : hint_range(0.02, 1.0, 0.01) = 0.55;

void fragment() {
	vec4 base_sample = base_albedo;
	if (albedo_texture_enabled > 0.5) {
		base_sample *= texture(albedo_texture, UV);
	}

	vec3 albedo = base_sample.rgb;
	if (face_layer_enabled > 0.5) {
		vec4 face_layer = texture(face_albedo_texture, UV);
		float layer_alpha = clamp(face_layer.a * face_layer_strength, 0.0, 1.0);
		albedo = mix(albedo, face_layer.rgb, layer_alpha);
	}

	ALBEDO = albedo;
	ALPHA = base_sample.a;

	if (normal_texture_enabled > 0.5) {
		NORMAL_MAP = texture(normal_texture, UV).rgb;
	}

	if (orm_texture_enabled > 0.5) {
		vec3 orm = texture(orm_texture, UV).rgb;
		AO = orm.r;
		ROUGHNESS = orm.g;
		METALLIC = orm.b;
	} else {
		ROUGHNESS = roughness_value;
		METALLIC = metallic_value;
	}

	if (emission_texture_enabled > 0.5) {
		EMISSION = texture(emission_texture, UV).rgb * emission_color.rgb * emission_energy;
	} else {
		EMISSION = emission_color.rgb * emission_energy;
	}
}
