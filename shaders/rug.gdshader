shader_type spatial;
// Tapis de cuisine : coins arrondis, liseré clair, petit motif losange.

uniform vec4 base_color : source_color = vec4(0.36, 0.62, 0.46, 1.0);
uniform vec4 border_color : source_color = vec4(0.9, 0.95, 0.86, 1.0);
uniform vec2 rug_size = vec2(1.5, 3.0);

float rounded_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = (UV - 0.5) * rug_size;
	float d = rounded_box(p, rug_size * 0.5, 0.18);
	if (d > 0.0) {
		discard;
	}
	vec3 col = base_color.rgb;
	// Double liseré.
	float band = step(-0.13, d) * step(d, -0.09) + step(-0.05, d);
	// Motif losange discret.
	vec2 m = abs(fract(p * 2.2) - 0.5);
	float diamond = step(m.x + m.y, 0.12);
	col = mix(col, col * 1.15, diamond * step(d, -0.2));
	col = mix(col, border_color.rgb, clamp(band, 0.0, 1.0));
	// Frange qui assombrit un peu le bord.
	col *= 0.92 + 0.08 * smoothstep(0.0, -0.3, d);
	ALBEDO = col;
	ROUGHNESS = 0.95;
}
