extends GutGameplayTest

## PS-059: verifica che il pannello delle carte upgrade (offerta normale,
## BARB_SPECIALITY, BARB_BONUS) e l'header della ricompensa Barb restino
## percepibilmente più chiari del Dimmer che li precede, cosi' il modal non
## risulti "tutto nero" come segnalato dal proprietario. Non verifica pixel
## resi a schermo: legge i Color effettivi delle risorse di stile. La resa
## percettiva reale resta un gate manuale (vedi card).

const UPGRADE_OVERLAY_SCENE := preload("res://scenes/ui/upgrade_overlay.tscn")
const BARB_OVERLAY_SCENE := preload("res://scenes/ui/barb_reward_overlay.tscn")
const UPGRADE_CARD_SCENE := preload("res://scenes/ui/upgrade_card.tscn")

# Soglia indicativa della card: differenza di luminanza percepita (scala 0-1,
# luma 0.299R+0.587G+0.114B sui componenti diretti del Color) fra il pannello
# e il Dimmer che gli sta dietro.
const MIN_LUMA_DELTA := 0.05


func test_ps059_normal_and_bonus_card_panel_is_lighter_than_dimmer() -> void:
	var overlay := UPGRADE_OVERLAY_SCENE.instantiate() as UpgradeOverlay
	add_child_autofree(overlay)
	await wait_process_frames(1)
	var dimmer := overlay.get_node("Dimmer") as ColorRect
	assert_true(dimmer != null, "UpgradeOverlay deve avere un nodo Dimmer.")
	if dimmer == null:
		return

	var card := UPGRADE_CARD_SCENE.instantiate() as UpgradeCard
	add_child_autofree(card)
	await wait_process_frames(1)
	var normal_style := card.get_theme_stylebox(&"normal") as StyleBoxFlat
	assert_true(normal_style != null, "UpgradeCard deve avere uno StyleBoxFlat per lo stato normal.")
	if normal_style == null:
		return

	_assert_lighter_than_dimmer(
		normal_style.bg_color, dimmer.color, "Pannello carta (offerta normale / BARB_BONUS)"
	)


func test_ps059_barb_speciality_card_panel_is_lighter_than_dimmer() -> void:
	var overlay := BARB_OVERLAY_SCENE.instantiate() as BarbRewardOverlay
	add_child_autofree(overlay)
	await wait_process_frames(1)
	var dimmer := overlay.get_node("Dimmer") as ColorRect
	assert_true(dimmer != null, "BarbRewardOverlay deve avere un nodo Dimmer.")
	if dimmer == null:
		return

	var header_panel := overlay.get_node_or_null(
		"SafeMargins/Layout/HeaderPanel"
	) as PanelContainer
	assert_true(header_panel != null, "BarbRewardOverlay deve avere HeaderPanel.")
	if header_panel != null:
		var header_style := header_panel.get_theme_stylebox(&"panel") as StyleBoxFlat
		assert_true(header_style != null, "HeaderPanel deve avere uno StyleBoxFlat.")
		if header_style != null:
			_assert_lighter_than_dimmer(header_style.bg_color, dimmer.color, "Header ricompensa Barb")

	var card := UPGRADE_CARD_SCENE.instantiate() as UpgradeCard
	add_child_autofree(card)
	await wait_process_frames(1)
	card.set_speciality_treatment(true)
	var speciality_style := card.get_theme_stylebox(&"normal") as StyleBoxFlat
	assert_true(
		speciality_style != null, "La carta con trattamento Speciality deve avere uno stile normal."
	)
	if speciality_style != null:
		_assert_lighter_than_dimmer(
			speciality_style.bg_color, dimmer.color, "Pannello carta (BARB_SPECIALITY)"
		)

	print("UPGRADE_MODAL_CONTRAST_SMOKE_OK")


func _assert_lighter_than_dimmer(panel_color: Color, dimmer_color: Color, label: String) -> void:
	var panel_luma := _luma(panel_color)
	var dimmer_luma := _luma(dimmer_color)
	assert_true(
		panel_luma - dimmer_luma >= MIN_LUMA_DELTA,
		(
			"%s: luma %.4f troppo vicina al Dimmer (%.4f), delta minimo richiesto %.2f."
			% [label, panel_luma, dimmer_luma, MIN_LUMA_DELTA]
		)
	)


func _luma(c: Color) -> float:
	return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
