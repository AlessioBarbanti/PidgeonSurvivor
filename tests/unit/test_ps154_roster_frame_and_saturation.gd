extends GutGameplayTest

## PS-154: verifica che tutte le card del roster (selezionata e non) usino la
## stessa cornice-asset di `pause_panel_frame.png` e che la gerarchia
## selezionato/non-selezionato sia comunicata da un `ShaderMaterial` di
## desaturazione per bottone, non da uno `StyleBoxFlat` piatto ne' da un
## `modulate` grigio. Il margine nine-slice e' stato ridotto da 56/52 (il
## margine reale dell'asset, corretto ma sovradimensionato per lo slot
## compatto del roster) a 32/28 dopo revisione del proprietario sugli
## screenshot reali: un ritaglio piu' piccolo dello stesso motivo, non un
## nuovo asset dedicato — vedi Decisioni della card. Questo test verifica solo
## che la soglia non regredisca al vecchio valore troncante (22); la resa
## percettiva finale (motivo non troncato a schermo, intensita' del grigio)
## resta un controllo manuale, non automatizzabile in modo affidabile via
## smoke.

const EXPECTED_FRAME_PATH := "res://assets/art/ui/pause/pause_panel_frame.png"
const MIN_ACCEPTABLE_FRAME_MARGIN_LEFT := 28.0
const MIN_ACCEPTABLE_FRAME_MARGIN_TOP := 24.0
const FULL_SATURATION := 1.0
const LOW_SATURATION_CEILING := 0.2


func test_ps154_all_roster_cards_share_the_correct_frame_asset() -> void:
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	add_child_autofree(movement_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await wait_process_frames(2)

	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	assert_true(welcome != null and selector != null, "Il frontend deve essere composto.")
	if welcome == null or selector == null:
		return
	welcome.get_play_button().pressed.emit()
	await wait_process_frames(2)

	for friend_id in selector.get_visible_card_ids():
		var button := selector.get_button(friend_id)
		assert_true(button != null, "Ogni Friend visibile deve avere un bottone.")
		if button == null:
			continue
		var style := button.get_theme_stylebox("normal") as StyleBoxTexture
		assert_true(
			style != null and style.texture != null and style.texture.resource_path == EXPECTED_FRAME_PATH,
			"%s deve usare la cornice-asset condivisa, non uno StyleBoxFlat piatto." % friend_id
		)
		if style == null:
			continue
		assert_true(
			style.texture_margin_left >= MIN_ACCEPTABLE_FRAME_MARGIN_LEFT
			and style.texture_margin_top >= MIN_ACCEPTABLE_FRAME_MARGIN_TOP,
			(
				"%s: il margine e' stato ridotto deliberatamente (32/28), ma non deve tornare al vecchio 22 troncante."
				% friend_id
			)
		)


func test_ps154_selected_card_is_saturated_others_are_desaturated() -> void:
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	add_child_autofree(movement_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await wait_process_frames(2)

	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	assert_true(welcome != null and selector != null, "Il frontend deve essere composto.")
	if welcome == null or selector == null:
		return
	welcome.get_play_button().pressed.emit()
	await wait_process_frames(2)
	await wait_seconds(0.2)

	var selected_id := selector.get_selected_definition().id
	for friend_id in selector.get_visible_card_ids():
		var button := selector.get_button(friend_id)
		if button == null:
			continue
		var material := button.material as ShaderMaterial
		assert_true(
			material != null and material.shader != null,
			"%s deve avere un ShaderMaterial di desaturazione, non un modulate piatto." % friend_id
		)
		if material == null:
			continue
		var saturation: float = material.get_shader_parameter("saturation")
		if friend_id == selected_id:
			assert_eq(saturation, FULL_SATURATION, "Il selezionato deve restare a saturazione piena.")
		else:
			assert_true(
				saturation <= LOW_SATURATION_CEILING,
				"%s: i non selezionati devono essere fortemente desaturati (quasi B/N), non solo attenuati." % friend_id
			)

	selector.navigate_next()
	await wait_seconds(0.2)
	assert_false(selector.has_active_transition(), "La transizione della saturazione non deve lasciare Tween residui.")
	var new_selected_id := selector.get_selected_definition().id
	assert_ne(new_selected_id, selected_id, "La navigazione deve cambiare il selezionato.")
	var new_selected_button := selector.get_button(new_selected_id)
	var previous_button := selector.get_button(selected_id)
	assert_true(new_selected_button != null and previous_button != null, "Entrambi i bottoni coinvolti devono esistere.")
	if new_selected_button == null or previous_button == null:
		return
	var new_material := new_selected_button.material as ShaderMaterial
	var previous_material := previous_button.material as ShaderMaterial
	assert_eq(
		new_material.get_shader_parameter("saturation"), FULL_SATURATION,
		"Il nuovo selezionato deve tornare a saturazione piena dopo la transizione."
	)
	assert_true(
		float(previous_material.get_shader_parameter("saturation")) <= LOW_SATURATION_CEILING,
		"Il precedente selezionato deve desaturarsi dopo aver perso il centro."
	)

	print("PS154_ROSTER_FRAME_AND_SATURATION_SMOKE_OK")
