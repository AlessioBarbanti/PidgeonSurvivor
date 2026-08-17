class_name VignetteEffect
extends ColorRect

@export_range(0.0, 1.0, 0.01) var intensity := 0.0:
	set(value):
		intensity = clampf(value, 0.0, 1.0) if is_finite(value) else 0.0
		_apply_intensity()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_intensity()


func set_intensity(value: float) -> bool:
	if not is_finite(value) or value < 0.0 or value > 1.0:
		return false
	intensity = value
	return true


func reset_effect() -> void:
	intensity = 0.0


func _apply_intensity() -> void:
	visible = intensity > 0.0001
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter(&"intensity", intensity)
