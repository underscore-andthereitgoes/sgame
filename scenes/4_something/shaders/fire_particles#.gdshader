shader_type particles;

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

void start() {
	USERDATA1.x = uintBitsToFloat(RANDOM_SEED);
	USERDATA1.y = uintBitsToFloat(1u);
	VELOCITY = vec3(0.0, -1.0, 0.0);
	TRANSFORM = mat4(
		vec4(1.0, 0.0, 0.0, 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(0.0, 0.0, 1.0, 0.0),
		vec4(0.0, 0.0, 0.0, 1.0)
	);
}

void process() {
	if (RESTART) {
		USERDATA1.x = uintBitsToFloat(RANDOM_SEED);
		USERDATA1.y = uintBitsToFloat(1u);
	}
	uint a = NUMBER; //floatBitsToUint(USERDATA1.x);
	uint b = RANDOM_SEED; //floatBitsToUint(USERDATA1.y);
	VELOCITY.xz += vec2(randf(a, b), randf(b, a)) * 0.1 - 0.2;
	USERDATA1.x = uintBitsToFloat(a);
	USERDATA1.y = uintBitsToFloat(b);
}
