shader_type canvas_item;
render_mode blend_add, unshaded;

// Additive por partícula con techo — brillo vivo sin bloom de pantalla completa.
uniform float max_brightness : hint_range(0.2, 1.5, 0.01) = 0.85;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV) * COLOR;
	tex_color.rgb *= tex_color.a;
	tex_color.rgb = min(tex_color.rgb, vec3(max_brightness));
	COLOR = tex_color;
}
