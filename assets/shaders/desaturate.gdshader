shader_type canvas_item;

// PS-154: applicato per nodo (ShaderMaterial non condiviso) cosi' ogni card
// del roster puo' avere una saturazione indipendente, animata in tween.
uniform float saturation : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// COLOR arriva gia' campionato dalla texture e moltiplicato per il
	// vertex/modulate color: non ricampionare TEXTURE qui, altrimenti il
	// modulate verrebbe applicato due volte.
	float luma = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = mix(vec3(luma), COLOR.rgb, saturation);
}
