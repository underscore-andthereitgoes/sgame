shader_type spatial;
render_mode unshaded,shadows_disabled,cull_back,specular_disabled,world_vertex_coords;

uniform sampler2D vptex: filter_nearest, repeat_disable;
uniform mat4 viewmat;
uniform mat4 projectionmat;

varying vec4 v;

void vertex() {
	v = projectionmat * viewmat * vec4(VERTEX, 1.0);
}

void fragment() {
	vec2 uv = (v.xy / v.w) * vec2(0.5, -0.5) + 0.5;
	ALBEDO = texture(vptex, uv).rgb;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
