shader_type spatial;
// Parquet de la salle du restaurant (autour de la cuisine).

uniform vec3 wood_a : source_color = vec3(0.34, 0.2, 0.12);
uniform vec3 wood_b : source_color = vec3(0.26, 0.15, 0.09);
uniform float plank_width = 0.5;
uniform float plank_length = 3.0;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float row = floor(world_pos.z / plank_width);
	float offset = hash(vec2(row, 3.0)) * plank_length;
	float col = floor((world_pos.x + offset) / plank_length);
	float n = hash(vec2(row, col));
	vec3 base = mix(wood_a, wood_b, n);
	// Veinage.
	float grain = sin(world_pos.x * 9.0 + n * 20.0 + sin(world_pos.z * 3.0) * 2.0) * 0.5 + 0.5;
	base *= 0.92 + grain * 0.1;
	float fz = fract(world_pos.z / plank_width);
	float fx = fract((world_pos.x + offset) / plank_length);
	float seam = step(fz, 0.04) + step(fx, 0.008);
	base = mix(base, base * 0.55, clamp(seam, 0.0, 1.0));
	ALBEDO = base;
	ROUGHNESS = 0.7;
}
