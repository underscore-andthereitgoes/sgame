shader_type spatial;
render_mode unshaded,blend_mix,cull_disabled,ambient_light_disabled,specular_disabled,diffuse_toon,fog_disabled,shadows_disabled;

uniform sampler2D vptex: repeat_disable, filter_nearest, source_color;

void vertex() {
}

void fragment() {
	ALBEDO = texture(vptex, SCREEN_UV).rgb;
	SPECULAR = 0.0;
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
