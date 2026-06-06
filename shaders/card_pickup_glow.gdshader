shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.92, 0.35, 1.0);
uniform float pulse_speed = 3.5;
uniform float glow_strength = 0.55;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);
	float edge = smoothstep(0.25, 0.02, length(UV - vec2(0.5)));
	vec3 glow = glow_color.rgb * edge * glow_strength * pulse;
	COLOR = vec4(base.rgb + glow, base.a);
}
