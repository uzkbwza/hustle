shader_type canvas_item;

const vec4 replacement_color = vec4(1.0, 1.0, 1.0, 1.0);
const float super_dim_amount = 0.35;

uniform bool use_extra_color_1 = false;
uniform bool use_extra_color_2 = false;
uniform vec4 extra_replace_color_1 : hint_color  = vec4(1.0, 0.0, 1.0, 1.0);
uniform vec4 extra_replace_color_2 : hint_color  = vec4(1.0, 0.0, 1.0, 1.0);

uniform vec4 color: hint_color = vec4(1.0);
uniform vec4 extra_color_1: hint_color = vec4(1.0);
uniform vec4 extra_color_2: hint_color = vec4(1.0);

uniform float max_color_distance = 0.01;

uniform bool super_dim = false;
uniform bool use_outline = false;

uniform vec4 outline_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);

bool same_color(vec3 color1, vec3 color2) {
	return distance(color1, color2) < max_color_distance;
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	COLOR = col;
	if (same_color(col.rgb, replacement_color.rgb)) {
		COLOR.rgb = color.rgb;
		COLOR.a = texture(TEXTURE, UV).a;
	}
	
	if (use_outline && col.a == 0.0) {
	float size_x = 1.0 / float(textureSize(TEXTURE, 0).x);
	float size_y = 1.0 / float(textureSize(TEXTURE, 0).y);

	float alpha = 0.0;

	vec4 right = texture(TEXTURE, UV + vec2(size_x, 0.0));
	vec4 left = texture(TEXTURE, UV + vec2(-size_x, 0.0));
	vec4 down = texture(TEXTURE, UV + vec2(0.0, size_y));
	vec4 up = texture(TEXTURE, UV + vec2(0.0, -size_y));

	vec4 down_right = texture(TEXTURE, UV + vec2(size_x, size_y));
	vec4 down_left = texture(TEXTURE, UV + vec2(-size_x, size_y));
	vec4 up_left = texture(TEXTURE, UV + vec2(-size_x, -size_y));
	vec4 up_right = texture(TEXTURE, UV + vec2(size_x, -size_y));

	alpha += float(right.a > 0.0 && same_color(right.rgb, replacement_color.rgb));
	alpha += float(left.a > 0.0 && same_color(left.rgb, replacement_color.rgb));
	alpha += float(down.a > 0.0 && same_color(down.rgb, replacement_color.rgb));
	alpha += float(up.a > 0.0 && same_color(up.rgb, replacement_color.rgb));

	alpha += float(down_right.a > 0.0 && same_color(down_right.rgb, replacement_color.rgb));
	alpha += float(down_left.a > 0.0 && same_color(down_left.rgb, replacement_color.rgb));
	alpha += float(up_left.a > 0.0 && same_color(up_left.rgb, replacement_color.rgb));
	alpha += float(up_right.a > 0.0 && same_color(up_right.rgb, replacement_color.rgb));

	if (alpha > 0.0) {
		COLOR = vec4(outline_color.rgb, outline_color.a);
		}
	}
	
	if (use_extra_color_1 && same_color(col.rgb, extra_replace_color_1.rgb)) {
		COLOR.rgb = extra_color_1.rgb;
		COLOR.a = texture(TEXTURE, UV).a;
	}
	if (use_extra_color_2 && same_color(col.rgb, extra_replace_color_2.rgb)) {
		COLOR.rgb = extra_color_2.rgb;
		COLOR.a = texture(TEXTURE, UV).a;
	}
}