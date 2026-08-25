extends Control

const SETUP_VALIDATOR = preload("res://scripts/app/setup_validator.gd")

@onready var _status: Label = %Status


func _ready() -> void:
	var failures: Array[String] = SETUP_VALIDATOR.collect_failures()
	var success: bool = SETUP_VALIDATOR.print_result()
	if failures.is_empty():
		_status.text = "Pidgeon Survivor\nIt's grilling time!\nSetup OK - %s - %s" % [
			SETUP_VALIDATOR.version_text(),
			OS.get_name(),
		]
	else:
		_status.text = "Setup non valido"
		for failure in failures:
			_status.text += "\n- " + failure

	if OS.get_cmdline_user_args().has("--smoke-test"):
		get_tree().quit(0 if success else 1)
