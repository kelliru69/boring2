shader_type canvas_item;
render_mode blend_mix, unshaded;

// Techo de brillo por píxel: activa Glow HDR sin acumulación infinita hacia blanco.
uniform float max_brightness : hint_range(0.5, 3.0, 0.01) = 1.8;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	COLOR = tex_color * COLOR;
	COLOR.rgb = clamp(COLOR.rgb, 0.0, max_brightness);
}
