shader_type particles;

const uint seedA0 = 2944585674u;
const uint seedB0 = 3313278996u;

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
	return float(fract(float(randu(a, b) % 10000u) / 10000.0));
}

void start() {
	uint seedA = NUMBER;
	uint seedB = RANDOM_SEED;
	vec2 xz = (vec2(randf(seedA, seedB), randf(seedA, seedB)) - 0.5) * vec2(60.0, 60.0);
	TRANSFORM = mat4(
		vec4(1.0, 0.0, 0.0, 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(0.0, 0.0, 1.0, 0.0),
		vec4(xz.x, 80.0 + randf(seedA, seedB) * 40.0, xz.y, 1.0)
	);
	VELOCITY = vec3(0.0, -100.0, 0.0);
}

void process() {
	// Called every frame on existing particles (according to the Fixed FPS property).
}
