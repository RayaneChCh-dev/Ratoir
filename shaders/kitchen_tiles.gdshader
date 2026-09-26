shader_type spatial;
// Carrelage de cuisine chaleureux : grandes dalles sombres légèrement variées, joints plus foncés.

uniform vec3 tile_a : source_color = vec3(0.82, 0.64, 0.48);
uniform vec3 tile_b : source_color = vec3(0.76, 0.58, 0.43);
uniform vec3 grout : source_color = vec3(0.58, 0.42, 0.3);
uniform float tile_size = 0.7;
uniform vec2 grid_origin = vec2(-4.9, -6.3);
uniform float grout_width = 0.03;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = (world_pos.xz - grid_origin) / tile_size;
	vec2 cell = floor(uv);
	vec2 f = fract(uv);
	float checker = mod(cell.x + cell.y, 2.0);
	vec3 base = mix(tile_a, tile_b, checker);
	base *= 0.94 + 0.1 * hash(cell);
	// Léger dégradé dans chaque dalle, comme un reflet.
	base *= 1.0 + 0.08 * (f.x - f.y);
	float edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
	float g = 1.0 - smoothstep(grout_width * 0.5, grout_width, edge);
	ALBEDO = mix(base, grout, g);
	ROUGHNESS = mix(0.45, 0.95, g);
	SPECULAR = 0.35;
}
