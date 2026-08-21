shader_type canvas_item;

const vec4 replacement_color = vec4(1.0, 1.0, 1.0, 1.0);
const float outline_threshold = 0.05;
const float hue_threshold = 0.01;

uniform bool use_extra_color_1 = false;
uniform bool use_extra_color_2 = false;
uniform vec4 extra_replace_color_1 : hint_color = vec4(1.0, 0.0, 1.0, 1.0);
uniform vec4 extra_replace_color_2 : hint_color = vec4(1.0, 0.0, 1.0, 1.0);

uniform bool use_outline = false;

uniform vec4 color : hint_color = vec4(1.0);
uniform vec4 extra_color_1 : hint_color = vec4(1.0);
uniform vec4 extra_color_2 : hint_color = vec4(1.0);
uniform vec4 outline_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform float max_color_distance = 0.01;


vec3 rgb_to_hsl(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}



bool same_color(vec3 color1, vec3 color2) {
	return distance(color1, color2) < max_color_distance;
}


bool same_hue(vec4 col1, vec4 col2) {
	vec3 hsl1 = rgb_to_hsl(col1.rgb);
	vec3 hsl2 = rgb_to_hsl(col2.rgb);
	return abs(hsl1.x - hsl2.x) <= hue_threshold;
}


bool is_outline_color(vec4 col) {
	return (col.r < outline_threshold) && (col.g < outline_threshold) && (col.b < outline_threshold);
}


bool is_greyscale(vec4 col) {
	return max(max(col.r, col.g), col.b) - min(min(col.r, col.g), col.b) < 0.01;
}


void shaded_replace(inout vec4 col, in vec4 from, in vec4 to) {
	float upper = max(max(from.r, from.g), from.b);
	float light = rgb_to_hsl(col.rgb).z / upper;
	col.rgb = to.rgb * light;
}


void fragment() {
	vec4 src = texture(TEXTURE, UV);
	COLOR = src;
	
	if (use_outline && is_outline_color(src)) {
		COLOR.rgb = outline_color.rgb;
	}
	else if (is_greyscale(src)) {
		shaded_replace(COLOR, replacement_color, color);
	}
	else {
		bool consider_extra_1 = use_extra_color_1 && same_hue(src, extra_replace_color_1);
		bool consider_extra_2 = use_extra_color_2 && same_hue(src, extra_replace_color_2);
		if (consider_extra_1 && consider_extra_2) {
			vec3 src_hsl = rgb_to_hsl(src.rgb);
			vec3 replace_1_hsl = rgb_to_hsl(extra_replace_color_1.rgb);
			vec3 replace_2_hsl = rgb_to_hsl(extra_replace_color_2.rgb);
			if (distance(src_hsl.xyz, replace_1_hsl.xyz) < distance(src_hsl.xyz, replace_2_hsl.xyz)) {
				shaded_replace(COLOR, extra_replace_color_1, extra_color_1);
			}
			else {
				shaded_replace(COLOR, extra_replace_color_2, extra_color_2);
			}
		}
		else if (consider_extra_1) {
			shaded_replace(COLOR, extra_replace_color_1, extra_color_1);
		}
		else if (consider_extra_2) {
			shaded_replace(COLOR, extra_replace_color_2, extra_color_2);
		}
	}
}