shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture;
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

const vec2 OFFSETS[4] = {
	vec2(-1, 0), vec2(0, -1), vec2(0, 1), vec2(1, 0)
};

void fragment() {
	vec4 canvas_group_texture = texture(screen_texture, SCREEN_UV);
	COLOR = canvas_group_texture;

	vec2 size = SCREEN_PIXEL_SIZE;
	float outline = 0.0;

	for (int i = 0; i < OFFSETS.length(); i++) {
		outline += texture(screen_texture, SCREEN_UV + size * OFFSETS[i]).a;
	}
	outline = min(outline, 1.0);

	vec4 color = texture(screen_texture, SCREEN_UV);
	COLOR = mix(color, line_color, outline - color.a);
}