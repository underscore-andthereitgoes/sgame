shader_type spatial;
render_mode world_vertex_coords,fog_disabled,unshaded;

uniform vec3 color1 = vec3(0.8);
uniform vec3 color2 = vec3(1.0);
uniform float decrease_normal = 0.125;
uniform vec3 checkercube_size = vec3(2.0);

varying vec3 v;

void vertex() {
	v = VERTEX - NORMAL * decrease_normal;
}

void fragment() {
	int a = fract(v.x / checkercube_size.x) < 0.5 ? 0 : 1;
	int b = fract(v.y / checkercube_size.y) < 0.5 ? 0 : 1;
	int c = fract(v.z / checkercube_size.z) < 0.5 ? 0 : 1;
	if ((a ^ b ^ c) == 1) {
		ALBEDO = color1;
	} else {
		ALBEDO = color2;
	}
}
