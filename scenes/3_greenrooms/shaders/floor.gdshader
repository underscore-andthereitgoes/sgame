shader_type spatial;
render_mode cull_back,blend_mix,world_vertex_coords;

uniform float chunk_size = 5.0;
uniform vec3 color_base: source_color;

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

void texturedStuff(in vec2 chunk, inout vec3 normal, out float roughness, out float metallic, out float specular) {
	vec2 rand = random(uvec2(chunk * chunk_size * 100.0));
	normal = normalize(normal + 0.125 * (vec3(rand.x, 0.0, rand.y) * 2.0 - 1.0));
	specular = 0.0;
	roughness = 1.0;
	metallic = 0.0;
}

varying vec2 v;
void vertex() {
	v = VERTEX.xz;
}

void fragment() {
	vec2 grid = fract(v + 0.5);
	vec2 chunk = fract(v / chunk_size + 0.5);
	vec2 rand = random(uvec2(chunk * chunk_size * 100.0));
	ALBEDO = color_base * (0.9 + 0.2 * rand.x);
	texturedStuff(chunk, NORMAL, ROUGHNESS, METALLIC, SPECULAR);
}