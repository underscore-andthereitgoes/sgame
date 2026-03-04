shader_type spatial;
render_mode blend_add,cull_back,ambient_light_disabled,diffuse_toon,specular_disabled,unshaded;

uniform float factor = -1.0;

const int seed1 = 5350415;
const int seed2 = 5034716;
const int seed3 = 8601993;
const int seed4 = 3977604;

vec3 get_cell_point(int ix, int iy, int iz) {
	int a = ix;
	int b = iy;
	int c = iz;
	int w = 32;
	int s = 16;
	a *= seed1;
	b ^= (a << s | a >> w) - s;
	b *= seed2;
	c ^= (b << s | b >> w) - s;
	c *= seed3;
	a ^= (c << s | c >> w) - s;
	a *= seed4;
	float px = fract(abs(float(a) / float(1 << s)));
	float py = fract(abs(float(b) / float(1 << s)));
	float pz = fract(abs(float(c) / float(1 << s)));
	return vec3(px, py, pz);
}

float get_voronoi_value(vec3 pos) {
	ivec3 middle_cell = ivec3(pos);
	vec3 cell_offset = mod(pos, vec3(1.0));
	float all_cells[27] = {
		distance(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y - 1, middle_cell.z - 1) + vec3(-1.0, -1.0, -1.0)),
		distance(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y + 0, middle_cell.z - 1) + vec3(-1.0, +0.0, -1.0)),
		distance(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y + 1, middle_cell.z - 1) + vec3(-1.0, +1.0, -1.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y - 1, middle_cell.z - 1) + vec3(+0.0, -1.0, -1.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y + 0, middle_cell.z - 1) + vec3(+0.0, +0.0, -1.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y + 1, middle_cell.z - 1) + vec3(+0.0, +1.0, -1.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y - 1, middle_cell.z - 1) + vec3(+1.0, -1.0, -1.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y + 0, middle_cell.z - 1) + vec3(+1.0, +0.0, -1.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y + 1, middle_cell.z - 1) + vec3(+1.0, +1.0, -1.0)),
		distance(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y - 1, middle_cell.z + 0) + vec3(-1.0, -1.0, +0.0)),
		distance(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y + 0, middle_cell.z + 0) + vec3(-1.0, +0.0, +0.0)),
		distance(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y + 1, middle_cell.z + 0) + vec3(-1.0, +1.0, +0.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y - 1, middle_cell.z + 0) + vec3(+0.0, -1.0, +0.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y + 0, middle_cell.z + 0) + vec3(+0.0, +0.0, +0.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y + 1, middle_cell.z + 0) + vec3(+0.0, +1.0, +0.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y - 1, middle_cell.z + 0) + vec3(+1.0, -1.0, +0.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y + 0, middle_cell.z + 0) + vec3(+1.0, +0.0, +0.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y + 1, middle_cell.z + 0) + vec3(+1.0, +1.0, +0.0)),
		distance(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y - 1, middle_cell.z + 1) + vec3(-1.0, -1.0, +1.0)),
		distance(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y + 0, middle_cell.z + 1) + vec3(-1.0, +0.0, +1.0)),
		distance(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y + 1, middle_cell.z + 1) + vec3(-1.0, +1.0, +1.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y - 1, middle_cell.z + 1) + vec3(+0.0, -1.0, +1.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y + 0, middle_cell.z + 1) + vec3(+0.0, +0.0, +1.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y + 1, middle_cell.z + 1) + vec3(+0.0, +1.0, +1.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y - 1, middle_cell.z + 1) + vec3(+1.0, -1.0, +1.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y + 0, middle_cell.z + 1) + vec3(+1.0, +0.0, +1.0)),
		distance(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y + 1, middle_cell.z + 1) + vec3(+1.0, +1.0, +1.0))
	};
	float closest_distance = 10.0;
	for (int i = 0; i < 27; i++) {
		float d = all_cells[i];
		if (d < closest_distance) {
			closest_distance = d;
		}
	}
	float second_closest_distance = 10.0;
	for (int i = 0; i < 27; i++) {
		float d = all_cells[i];
		if (d > closest_distance && d < second_closest_distance) {
			second_closest_distance = d;
		}
	}
	return second_closest_distance - closest_distance;
}

varying vec3 v;
void vertex() {
	v = VERTEX;
}

void fragment() {
	if (factor <= 0.0) discard;
	vec3 cell_pos = (v + vec3(200.0)) * 2.0;
	float voronoi = get_voronoi_value(cell_pos);
	if (voronoi > 1.0 - factor) {
		ALBEDO = vec3(1.0 + 9.0 * clamp(1.0 - voronoi, 0.0, 1.0));
	} else discard;
}
