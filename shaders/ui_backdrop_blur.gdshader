shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float blur_lod : hint_range(0.0, 4.0) = 2.2;
uniform vec4 tint_color : source_color = vec4(0.02, 0.04, 0.08, 0.72);

void fragment() {
	vec4 blurred = textureLod(screen_texture, SCREEN_UV, blur_lod);
	COLOR = vec4(blurred.rgb * tint_color.rgb, tint_color.a);
}
