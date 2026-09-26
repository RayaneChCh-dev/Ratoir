shader_type spatial;

uniform vec3 color_a : source_color = vec3(0.78, 0.72, 0.62);
uniform vec3 color_b : source_color = vec3(0.62, 0.55, 0.45);
uniform float tile_size = 1.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 cell = floor(world_pos.xz / tile_size);
	float checker = mod(cell.x + cell.y, 2.0);
	ALBEDO = mix(color_a, color_b, checker);
	ROUGHNESS = 0.9;
}
