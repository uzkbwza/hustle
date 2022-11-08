shader_type canvas_item;

const vec4 replacement_color = vec4(1.0, 1.0, 1.0, 1.0);
const float super_dim_amount = 0.35;

uniform vec4 color: hint_color = vec4(1.0);

uniform float max_color_distance = 0.01;

uniform bool super_dim = false;

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
	if (super_dim) {
		COLOR.rgb *= super_dim_amount;
	}
}