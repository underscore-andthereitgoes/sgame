shader_type spatial;
render_mode blend_mix,cull_back;

uniform float total_width;
uniform float inner_width;

varying flat int b;
varying float d;
void vertex() {
	VERTEX.x -= fract(TIME / total_width) * total_width - total_width * 0.5;
	b = 0;
	if (VERTEX.x > inner_width / 2.0 || VERTEX.x < inner_width / -2.0) {
		b = 1;
		VERTEX.x = clamp(VERTEX.x, inner_width * -0.5, inner_width * 0.5);
	}
	d = pow(abs(VERTEX.x) / (inner_width * 0.5), 1.5);
}

void fragment() {
	if (b != 0) discard;
	ALBEDO = vec3(1.0 - pow(d, 2.0), 1.0 - d, 1.0 - pow(d, 3.0));
	ROUGHNESS = 0.4 * (1.0 - d);
	METALLIC = d;
	SPECULAR = 1.0;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
