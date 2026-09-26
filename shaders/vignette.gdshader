shader_type canvas_item;
// Assombrit doucement les bords de l'écran pour une ambiance chaleureuse.

uniform float strength = 0.45;
uniform vec4 tint : source_color = vec4(0.12, 0.05, 0.02, 1.0);

void fragment() {
	vec2 d = UV - vec2(0.5);
	d.x *= 0.8;
	float v = smoothstep(0.3, 0.75, length(d));
	COLOR = vec4(tint.rgb, v * strength);
}
