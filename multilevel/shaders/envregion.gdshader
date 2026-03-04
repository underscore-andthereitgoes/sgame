shader_type spatial;
render_mode unshaded,blend_mix,depth_prepass_alpha,cull_back,ambient_light_disabled,specular_disabled,diffuse_toon,fog_disabled,shadows_disabled;

uniform sampler2D vptex: repeat_disable, filter_linear, source_color;

const uint seed1 = 4088845225u;
const uint seed2 = 3896613506u;
const uint seed3 = 2704510847u;
const uint seed4 = 2289698031u;

vec3 get_cell_point(int ix, int iy, int iz) {
	uint a = uint(ix);
	uint b = uint(iy);
	uint c = uint(iz);
	uint w = 32u;
	uint s = 16u;
	a *= seed1;
	b ^= (a << s | a >> w) - s;
	b *= seed2;
	c ^= (b << s | b >> w) - s;
	c *= seed3;
	a ^= (c << s | c >> w) - s;
	a *= seed4;
	float px = fract(abs(float(a) / float(1u << s)));
	float py = fract(abs(float(b) / float(1u << s)));
	float pz = fract(abs(float(c) / float(1u << s)));
	vec3 p = vec3(px, py, pz);
	float n1 = fract(abs(float((a << b) ^ c) / float(1u << s)));
	float n2 = fract(abs(float((c >> a) ^ b) / float(1u << s)));
	float n3 = fract(abs(float((b << c) ^ a) / float(1u << s)));
	p.x = pow(p.x, 0.5 + 0.4 * sin(TAU * (TIME * 0.3 + n1)));
	p.y = pow(p.y, 0.5 + 0.4 * sin(TAU * (TIME * 0.3 + n2)));
	p.z = pow(p.z, 0.5 + 0.4 * sin(TAU * (TIME * 0.3 + n3)));
	return p;
}

float distancefunc(vec3 a, vec3 b) {
	return distance(a, b);
	//return abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z);
	//return max(max(abs(a.x - b.x), abs(a.y - b.y)), abs(a.z - b.z));
	//return abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z) + max(max(abs(a.x - b.x), abs(a.y - b.y)), abs(a.z - b.z));
	//return pow(distance(a, b), 0.3 + sin(TIME * TAU) * 0.2);
}

float get_voronoi_value(vec3 pos) {
	ivec3 middle_cell = ivec3(pos);
	vec3 cell_offset = mod(pos, vec3(1.0));
	float all_cells[27] = {
		distancefunc(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y - 1, middle_cell.z - 1) + vec3(-1.0, -1.0, -1.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y + 0, middle_cell.z - 1) + vec3(-1.0, +0.0, -1.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y + 1, middle_cell.z - 1) + vec3(-1.0, +1.0, -1.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y - 1, middle_cell.z - 1) + vec3(+0.0, -1.0, -1.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y + 0, middle_cell.z - 1) + vec3(+0.0, +0.0, -1.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y + 1, middle_cell.z - 1) + vec3(+0.0, +1.0, -1.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y - 1, middle_cell.z - 1) + vec3(+1.0, -1.0, -1.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y + 0, middle_cell.z - 1) + vec3(+1.0, +0.0, -1.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y + 1, middle_cell.z - 1) + vec3(+1.0, +1.0, -1.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y - 1, middle_cell.z + 0) + vec3(-1.0, -1.0, +0.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y + 0, middle_cell.z + 0) + vec3(-1.0, +0.0, +0.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y + 1, middle_cell.z + 0) + vec3(-1.0, +1.0, +0.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y - 1, middle_cell.z + 0) + vec3(+0.0, -1.0, +0.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y + 0, middle_cell.z + 0) + vec3(+0.0, +0.0, +0.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y + 1, middle_cell.z + 0) + vec3(+0.0, +1.0, +0.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y - 1, middle_cell.z + 0) + vec3(+1.0, -1.0, +0.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y + 0, middle_cell.z + 0) + vec3(+1.0, +0.0, +0.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y + 1, middle_cell.z + 0) + vec3(+1.0, +1.0, +0.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y - 1, middle_cell.z + 1) + vec3(-1.0, -1.0, +1.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y + 0, middle_cell.z + 1) + vec3(-1.0, +0.0, +1.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x - 1, middle_cell.y + 1, middle_cell.z + 1) + vec3(-1.0, +1.0, +1.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y - 1, middle_cell.z + 1) + vec3(+0.0, -1.0, +1.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y + 0, middle_cell.z + 1) + vec3(+0.0, +0.0, +1.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 0, middle_cell.y + 1, middle_cell.z + 1) + vec3(+0.0, +1.0, +1.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y - 1, middle_cell.z + 1) + vec3(+1.0, -1.0, +1.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y + 0, middle_cell.z + 1) + vec3(+1.0, +0.0, +1.0)),
		distancefunc(cell_offset, get_cell_point(middle_cell.x + 1, middle_cell.y + 1, middle_cell.z + 1) + vec3(+1.0, +1.0, +1.0))
	};
	float closest_distance = 1000.0;
	for (int i = 0; i < 27; i++) {
		float d = all_cells[i];
		if (d < closest_distance) {
			closest_distance = d;
		}
	}
	float second_closest_distance = 1000.0;
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
	v = (vec4(VERTEX, 1.0) * MODEL_MATRIX).rgb;
}

void fragment() {
	if (length(VERTEX) < 5.0 || length(VERTEX) < 8.0 && length(VERTEX) < 5.0 + min(3.0, 1.5 * get_voronoi_value(v + vec3(10000.0)))) {
		ALBEDO = texture(vptex, SCREEN_UV).rgb;
		ALPHA = 1.0;
		SPECULAR = 0.0;
		METALLIC = 0.0;
		ROUGHNESS = 1.0;
	} else {
		discard;
	}
}
