shader_type spatial;
render_mode unshaded,cull_back,blend_add;

void vertex() {
}

void fragment() {
	ALBEDO = vec3(256.0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
