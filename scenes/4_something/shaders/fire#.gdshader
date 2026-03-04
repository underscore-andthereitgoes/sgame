shader_type fog;

const uint seedA = 3313278996u;
const uint seedB = 2944585674u;

uint randu(inout uint a, inout uint b) {
	uint t = a;
	uint s = b;
	a = s;
	t ^= t << 23u;
	t ^= t >> 18u;
	t ^= s ^ (s >> 5u);
	b = t;
	return s + t;
}

float randf(inout uint a, inout uint b) {
	return float(fract(float(randu(a, b) % 1048576u) / 1048576.0));
}

vec3 randNormalVec3(inout uint a, inout uint b) {
	return normalize(pow(vec3(randf(a, b), randf(a, b), randf(a, b)), vec3(3.0)) - 0.5);
}

uvec2 dualSeedXYZ(ivec3 pos) {
	uint a = uint(pos.x);
	uint b = uint(pos.y);
	uint c = uint(pos.z);
	c = randu(a, b);
	return uvec2(
		randu(c, a),
		randu(b, c)
	);
}

vec3 randomGridGradient(ivec3 ixyz) {
	uvec2 dualSeed = dualSeedXYZ(ixyz);
	return randNormalVec3(dualSeed.x, dualSeed.y);
}

float perlin(vec3 xyz) {
	ivec3[2] c = { ivec3(floor(xyz)), ivec3(ceil(xyz)) };
	vec3 f = fract(xyz);
	float sx = 0.0;
	for (uint x = 0u; x < 2u; x++) {
		float dx = abs(float(x) - f.x);
		float sy = 0.0;
		for (uint y = 0u; y < 2u; y++) {
			float dy = abs(float(y) - f.y);
			float sz = 0.0;
			for (uint z = 0u; z < 2u; z++) {
				float dz = abs(float(z) - f.z);
				ivec3 p = ivec3(
					c[x].x,
					c[y].y,
					c[z].z
				);
				vec3 corner = vec3(uvec3(x, y, z));
				float d = dot(randomGridGradient(p), (f - corner));
				sz += d * dz;
			}
			sy += sz * dy;
		}
		sx += sy * dx;
	}
	return sx;
}

void fog() {
	DENSITY = perlin(UVW * 4.0);
	ALBEDO = vec3(1.0);
	EMISSION = vec3(1.0);
}
