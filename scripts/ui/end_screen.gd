class_name EndScreen
extends Control

signal restart_requested()
signal change_character_requested()

## Dimensione dell'icona upgrade nella riga di riepilogo (PS-053).
const UPGRADE_CHIP_ICON_SIZE := Vector2(48, 48)

@onready var _title_label: Label = %TitleLabel
@onready var _summary_label: Label = %SummaryLabel
@onready var _character_portrait: TextureRect = %CharacterPortrait
@onready var _character_name_label: Label = %CharacterNameLabel
@onready var _stats_label: Label = %StatsLabel
@onready var _upgrades_row: HBoxContainer = %UpgradesRow
@onready var _restart_button: Button = %RestartButton
@onready var _change_character_button: Button = %ChangeCharacterButton

var _accepting_restart := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_restart_button.pressed.connect(_on_restart_button_pressed)
	_change_character_button.pressed.connect(_on_change_character_button_pressed)
	hide_end_screen()


func show_defeat(summary: RunSummary) -> void:
	_title_label.text = "GAME OVER"
	_summary_label.text = "Hai resistito per %s" % format_run_time(summary.run_time)
	_restart_button.text = "RIPROVA"
	_apply_summary(summary)
	_show_terminal_screen()


func show_victory(
	summary: RunSummary,
	boss_title: String
) -> void:
	var safe_boss_title := boss_title.strip_edges()
	if safe_boss_title.is_empty():
		safe_boss_title = "BOSS"
	_title_label.text = "VITTORIA"
	_summary_label.text = "%s sconfitto in %s" % [
		safe_boss_title,
		format_run_time(summary.run_time),
	]
	_restart_button.text = "NUOVA RUN"
	_apply_summary(summary)
	_show_terminal_screen()


func _show_terminal_screen() -> void:
	_accepting_restart = true
	visible = true
	_restart_button.disabled = false
	_change_character_button.disabled = false
	_restart_button.call_deferred("grab_focus")


func hide_end_screen() -> void:
	_accepting_restart = false
	visible = false
	if is_instance_valid(_restart_button):
		_restart_button.disabled = true
	if is_instance_valid(_change_character_button):
		_change_character_button.disabled = true


func is_accepting_restart() -> bool:
	return _accepting_restart and visible


func get_restart_button() -> Button:
	return _restart_button if is_instance_valid(_restart_button) else null


func get_change_character_button() -> Button:
	return _change_character_button if is_instance_valid(_change_character_button) else null


func get_title_text() -> String:
	return _title_label.text if is_instance_valid(_title_label) else ""


func get_summary_text() -> String:
	return _summary_label.text if is_instance_valid(_summary_label) else ""


func get_character_name_text() -> String:
	return _character_name_label.text if is_instance_valid(_character_name_label) else ""


func get_character_portrait_texture() -> Texture2D:
	return _character_portrait.texture if is_instance_valid(_character_portrait) else null


func get_stats_text() -> String:
	return _stats_label.text if is_instance_valid(_stats_label) else ""


func get_upgrade_chip_count() -> int:
	return _upgrades_row.get_child_count() if is_instance_valid(_upgrades_row) else 0


## Titolo e rango, nell'ordine in cui compaiono nella riga (PS-053): l'ordine
## e' il contratto osservabile dell'ordinamento deterministico del riepilogo.
func get_upgrade_chip_summaries() -> Array[String]:
	var summaries: Array[String] = []
	if not is_instance_valid(_upgrades_row):
		return summaries
	for chip in _upgrades_row.get_children():
		if chip.has_meta(&"summary_text"):
			summaries.append(str(chip.get_meta(&"summary_text")))
	return summaries


static func format_run_time(run_time: float) -> String:
	var safe_time := maxf(run_time, 0.0) if is_finite(run_time) else 0.0
	var total_seconds := int(floor(safe_time))
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]


func _unhandled_input(event: InputEvent) -> void:
	if (
		not is_accepting_restart()
		or not event.is_action_pressed(&"ui_accept")
	):
		return
	get_viewport().set_input_as_handled()
	_emit_restart_requested()


func _on_restart_button_pressed() -> void:
	_emit_restart_requested()


func _on_change_character_button_pressed() -> void:
	if not is_accepting_restart():
		return
	_accepting_restart = false
	_restart_button.disabled = true
	_change_character_button.disabled = true
	change_character_requested.emit()


func _emit_restart_requested() -> void:
	if not is_accepting_restart():
		return
	_accepting_restart = false
	_restart_button.disabled = true
	_change_character_button.disabled = true
	restart_requested.emit()


func _apply_summary(summary: RunSummary) -> void:
	if is_instance_valid(_character_name_label):
		_character_name_label.text = summary.character_name
	if is_instance_valid(_character_portrait):
		_character_portrait.texture = summary.character_portrait
		_character_portrait.visible = summary.character_portrait != null
	if is_instance_valid(_stats_label):
		_stats_label.text = "Livello %d · %s" % [summary.level, _format_boss_count(summary.bosses_defeated)]
	_rebuild_upgrades_row(summary.top_upgrades)


func _format_boss_count(count: int) -> String:
	return "1 Boss sconfitto" if count == 1 else "%d Boss sconfitti" % count


func _rebuild_upgrades_row(entries: Array[RunSummary.UpgradeEntry]) -> void:
	if not is_instance_valid(_upgrades_row):
		return
	for child in _upgrades_row.get_children():
		_upgrades_row.remove_child(child)
		child.queue_free()
	_upgrades_row.visible = not entries.is_empty()
	for entry in entries:
		_upgrades_row.add_child(_build_upgrade_chip(entry))


func _build_upgrade_chip(entry: RunSummary.UpgradeEntry) -> Control:
	var chip := VBoxContainer.new()
	chip.alignment = BoxContainer.ALIGNMENT_CENTER
	chip.add_theme_constant_override(&"separation", 2)

	var icon := TextureRect.new()
	icon.custom_minimum_size = UPGRADE_CHIP_ICON_SIZE
	icon.texture = entry.definition.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(icon)

	var title_label := Label.new()
	title_label.theme_type_variation = &"BodyM"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.text = entry.definition.title
	chip.add_child(title_label)

	var rank_label := Label.new()
	rank_label.theme_type_variation = &"ValueNumeric"
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.text = "Rango %d" % entry.rank
	chip.add_child(rank_label)

	chip.set_meta(&"summary_text", "%s (Rango %d)" % [entry.definition.title, entry.rank])
	return chip
