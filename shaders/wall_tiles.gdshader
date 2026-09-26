shader_type spatial;
// Carrelage mural terracotta (mur du fond et murs latéraux) : dalles légèrement variées, joints foncés.

uniform vec3 tile_a : source_color = vec3(0.93, 0.56, 0.36);
uniform vec3 tile_b : source_color = vec3(0.87, 0.47, 0.3);
uniform vec3 grout : source_color = vec3(0.62, 0.33, 0.21);
uniform float tile_size = 0.6;
uniform float grout_width = 0.03;
// Plinthe en bas du mur (hauteur en mètres).
uniform vec3 baseboard : source_color = vec3(0.55, 0.33, 0.22);
uniform float baseboard_height = 0.25;

varying vec3 world_pos;
varying vec3 world_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Plan du carrelage selon l'orientation de la face (mur du fond : XY, murs latéraux : ZY).
	vec2 plane = abs(world_normal.x) > 0.5 ? world_pos.zy : world_pos.xy;
	if (abs(world_normal.y) > 0.5) {
		plane = world_pos.xz;
	}
	vec2 uv = plane / tile_size;
	uv.x += 0.5 * mod(floor(uv.y), 2.0);  // pose décalée
	vec2 cell = floor(uv);
	vec2 f = fract(uv);
	vec3 base = mix(tile_a, tile_b, step(0.5, hash(cell)));
	base *= 0.92 + 0.12 * hash(cell + 7.0);
	float edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
	float g = 1.0 - smoothstep(grout_width * 0.5, grout_width, edge);
	vec3 col = mix(base, grout, g);
	col = mix(col, baseboard, step(world_pos.y, baseboard_height));
	ALBEDO = col;
	ROUGHNESS = 0.8;
}
