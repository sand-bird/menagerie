shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
	vec4 canvas_group_texture = texture(screen_texture, SCREEN_UV);
	COLOR = canvas_group_texture;
}