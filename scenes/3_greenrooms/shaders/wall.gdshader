shader_type spatial;
render_mode cull_back,blend_mix,world_vertex_coords;

uniform float pattern_width = 0.2;
uniform float pattern_height = 0.4;
uniform vec3 color_base: source_color;
uniform vec3 color_accent: source_color;

const uint seed1 = 431177559u;
const uint seed2 = 1521601453u;
const uint seed3 = 4169071299u;

vec2 random(uint ix, uint iy) {
	uint a = ix;
	uint b = iy;
	uint w = 32u;
	uint s = 16u;
	a *= seed1;
	b ^= (a << s | a >> w) - s;
	b *= seed2;
	a ^= (b << s | b >> w) - s;
	a *= seed3;
	float px = mod(float(a) / float(1u << s), 1.0);
	float py = mod(float(b) / float(1u << s), 1.0);
	return vec2(px, py);
}

vec2 random(uvec2 ixy) {
	return random(ixy.x, ixy.y);
}

void texturedStuff(in vec2 randpos, inout vec3 normal, out float roughness, out float metallic, out float specular) {
	vec2 rand = random(uvec2(randpos));
	normal = normalize(normal + 0.125 * (vec3(rand.x, 0.0, rand.y) * 2.0 - 1.0));
	specular = 0.0;
	roughness = 1.0;
	metallic = 0.0;
}

lowp float samplePattern(vec2 pattern_xy) {
	float dhalf = distance(pattern_xy.x, 0.5);
	if (dhalf > 0.35 && dhalf < 0.45) return 1.0;
	if (dhalf > 0.3) return 0.0;
	float ny = (1.0 - pattern_xy.y) * 2.0;
	if (ny < dhalf + 0.6 && ny > dhalf + 0.4) return 0.0;
	if (ny < dhalf + 1.0 && ny > dhalf) return 1.0;
	return 0.0;
}

varying vec2 v2;
void vertex() {
	v2 = vec2(VERTEX.x + VERTEX.z, VERTEX.y);
}

void fragment() {
	vec2 randpos = fract(v2 / 50.0) * 5000.0;
	vec2 rand = random(uvec2(randpos));
	ALBEDO = mix(color_base, color_accent, samplePattern(fract(v2 / vec2(pattern_width, pattern_height)))) * (0.95 + 0.1 * rand.x);
	texturedStuff(randpos, NORMAL, ROUGHNESS, METALLIC, SPECULAR);
}