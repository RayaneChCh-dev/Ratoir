shader_type canvas_item;
// Floute l'image du jeu derrière les écrans d'accueil / de résultats, puis la teinte.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur_lod = 3.5;
uniform vec4 tint_top : source_color = vec4(0.42, 0.24, 0.3, 0.72);
uniform vec4 tint_bottom : source_color = vec4(0.86, 0.6, 0.45, 0.62);

void fragment() {
	vec3 scene = textureLod(screen_tex, SCREEN_UV, blur_lod).rgb;
	vec4 tint = mix(tint_top, tint_bottom, UV.y);
	COLOR = vec4(mix(scene, tint.rgb, tint.a), 1.0);
}
