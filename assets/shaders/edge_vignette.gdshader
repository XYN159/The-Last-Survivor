shader_type canvas_item;

// 守护点扣血时的泛红：只染屏幕左右两边和底边，中间和顶栏留空，
// 不盖住路线、残影和顶栏的生命数字。透明度仍由 ColorRect 的 color.a 控制。

uniform vec2 rect_size = vec2(1080.0, 1920.0);
uniform float side_px = 96.0;
uniform float top_px = 0.0;
uniform float bottom_px = 56.0;

float band(float distance_px, float width_px) {
	if (width_px <= 0.0) {
		return 0.0;
	}
	return 1.0 - smoothstep(0.0, width_px, distance_px);
}

void fragment() {
	vec2 pixel = UV * rect_size;
	float left = band(pixel.x, side_px);
	float right = band(rect_size.x - pixel.x, side_px);
	float top = band(pixel.y, top_px);
	float bottom = band(rect_size.y - pixel.y, bottom_px);
	COLOR.a *= max(max(left, right), max(top, bottom));
}
