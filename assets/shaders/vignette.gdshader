shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 centered_uv = UV * 2.0 - 1.0;
	centered_uv.x *= 0.78;
	float edge = smoothstep(0.42, 1.08, length(centered_uv));
	COLOR = vec4(0.005, 0.008, 0.018, edge * intensity);
}
