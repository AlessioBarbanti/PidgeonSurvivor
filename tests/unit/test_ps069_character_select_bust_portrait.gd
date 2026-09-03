extends GutGameplayTest

## PS-069: il selettore personaggi e' ricomposto attorno ai busti prodotti da
## PS-068. Il busto del Friend selezionato e' la rappresentazione primaria, la
## fascia in basso mostra tutti gli otto Friend come miniature busto, e la
## composizione si ricompone dentro la safe area su 16:9, 20:9 e 4:3 senza
## troncare nome, ruolo, passiva o abilita' attiva.
##
## Questo file copre cio' che b18t/b18w non possono coprire: la presenza del
## busto, la sua dominanza rispetto al roster e il fatto che non copra mai
## informazioni essenziali nonostante sconfini sulla fascia roster.

const EXPECTED_IDS: Array[StringName] = [
	&"magno", &"bea", &"zat", &"alea", &"aleo", &"lollo", &"migi", &"marghe",
]
const LAYOUT_PROFILES := [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]
## Guardia sul lato del ritaglio fotocamera del Pixel 9 in landscape: la
## composizione non deve mai occupare questa fascia, oltre alla safe area di
## sistema gia' applicata da `SafeAreaRoot`.
const NOTCH_GUARD_LEFT := 32.0
const BUST_DOMINANCE_RATIO := 3.0
## Poco piu' di `CharacterSelectOverlay.TRANSITION_DURATION`, per leggere la
## fascia a scorrimento concluso.
const TRANSITION_SETTLE_SECONDS := 0.2

const IDENTITY_LABEL_PATHS := [
	"Center/SelectionPanel/Content/MainRow/PortraitStage/IdentityBlock/NameLabel",
	"Center/SelectionPanel/Content/MainRow/PortraitStage/IdentityBlock/RoleLabel",
	"Center/SelectionPanel/Content/MainRow/AbilityCards/PassiveCard/PassiveContent/PassiveText/PassiveTitleLabel",
	"Center/SelectionPanel/Content/MainRow/AbilityCards/PassiveCard/PassiveContent/PassiveText/PassiveDescriptionLabel",
	"Center/SelectionPanel/Content/MainRow/AbilityCards/AbilityCard/AbilityContent/AbilityText/AbilityTitleLabel",
	"Center/SelectionPanel/Content/MainRow/AbilityCards/AbilityCard/AbilityContent/AbilityText/AbilityDescriptionLabel",
]


func test_character_select_bust_portrait_contract() -> void:
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	add_child_autofree(movement_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await wait_process_frames(2)

	var controller := movement_slice.get_run_controller() as RunController
	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	var friends := movement_slice.get_friend_registry() as FriendRegistry
	var abilities := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var arena_layout := movement_slice.get_node("ArenaLayout") as ArenaLayout
	assert_true(
		controller != null and welcome != null and selector != null and friends != null
		and abilities != null and arena_layout != null,
		"PS-069 richiede il frontend composto con entrambi i registry."
	)
	if (
		controller == null or welcome == null or selector == null or friends == null
		or abilities == null or arena_layout == null
	):
		return

	welcome.get_play_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(
		selector.visible and controller.get_state() == RunController.RunState.BOOT,
		"Il selettore PS-069 deve aprirsi in BOOT."
	)

	_assert_roster_is_complete(selector)
	await _assert_bust_synchronises(selector, friends, abilities)
	_assert_bust_dominates(selector)
	_assert_circular_navigation_unchanged(selector)
	await _assert_ability_cards_are_stable(selector)
	await _assert_layout_profiles(selector, arena_layout)

	assert_true(
		controller.get_seed() == 0 and is_zero_approx(controller.get_run_time()),
		"Sfogliare il roster non deve avviare la run."
	)
	selector.get_confirm_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(controller.is_running(), "Il CTA deve restare l'unica via d'uscita da BOOT.")

	if is_instance_valid(controller):
		controller.prepare_restart()
	print("CHARACTER_SELECT_BUST_PORTRAIT_SMOKE_OK")


func _assert_roster_is_complete(selector: CharacterSelectOverlay) -> void:
	assert_eq(
		selector.get_definition_ids(), EXPECTED_IDS,
		"Il roster deve conservare l'ordine dichiarativo degli otto Friend."
	)
	assert_eq(
		selector.get_visible_card_ids().size(), 7,
		"La fascia roster deve mostrare sette Friend attorno al selezionato."
	)
	var carousel_rect := selector.get_carousel_rect()
	assert_true(
		carousel_rect.encloses(selector.get_center_card_rect()),
		"La miniatura selezionata deve restare intera dentro la fascia roster."
	)
	assert_true(
		absf(selector.get_center_card_rect().get_center().x - carousel_rect.get_center().x) <= 1.0,
		"La fascia deve scorrere tenendo il Friend selezionato al centro."
	)
	assert_true(
		selector.get_center_card_rect().size.x > selector.get_preview_card_rect(1).size.x,
		"La miniatura selezionata deve essere piu' larga delle altre."
	)


func _assert_bust_synchronises(
	selector: CharacterSelectOverlay,
	friends: FriendRegistry,
	abilities: AbilityEffectRegistry
) -> void:
	for expected_id in EXPECTED_IDS:
		var definition := friends.resolve_definition(expected_id)
		var ability := abilities.resolve_definition(definition.active_ability_id)
		var bust := selector.get_bust_portrait_texture()
		assert_eq(
			selector.get_selected_definition().id, expected_id,
			"%s deve essere il Friend selezionato." % expected_id
		)
		assert_eq(
			bust, definition.get_public_portrait(),
			"%s deve esporre il proprio busto come rappresentazione primaria." % expected_id
		)
		assert_true(
			bust != null
			and bust.resource_path == "res://assets/art/characters/%s/generated/portrait.png" % expected_id,
			"%s deve usare il derivato runtime PS-068, non un segnaposto." % expected_id
		)
		assert_true(
			bust != definition.get_public_selection_portrait(),
			"%s non deve piu' usare la figura intera come ritratto principale." % expected_id
		)
		assert_eq(
			selector.get_roster_icon_source(expected_id), definition.get_public_portrait(),
			"%s deve ritagliare il proprio busto nella miniatura del roster." % expected_id
		)
		var headshot := selector.get_button(expected_id).icon as AtlasTexture
		assert_true(
			headshot != null
			and headshot.region == CharacterSelectOverlay.ROSTER_HEADSHOT_REGION,
			"%s deve usare la stessa regione headshot degli altri Friend." % expected_id
		)
		var copy := selector.get_displayed_copy()
		assert_eq(
			copy.name, definition.get_public_display_name().to_upper(),
			"%s deve aggiornare il nome insieme al busto." % expected_id
		)
		assert_eq(
			copy.role, definition.get_public_role(),
			"%s deve aggiornare il ruolo insieme al busto." % expected_id
		)
		assert_eq(
			copy.passive_title, definition.get_public_passive_title().to_upper(),
			"%s deve aggiornare la passiva insieme al busto." % expected_id
		)
		assert_eq(
			copy.ability_title, definition.get_public_active_ability_title().to_upper(),
			"%s deve aggiornare l'abilita' insieme al busto." % expected_id
		)
		assert_eq(
			selector.get_ability_icon(), ability.icon,
			"%s deve aggiornare l'icona abilita' insieme al busto." % expected_id
		)
		assert_eq(
			selector.get_confirm_button().text,
			"GIOCA CON %s" % definition.get_public_display_name().to_upper(),
			"%s deve aggiornare il CTA insieme al busto." % expected_id
		)
		assert_true(
			absf(selector.get_passive_card_rect().size.y - selector.get_ability_card_rect().size.y)
			<= 1.0,
			(
				"%s: le card Passiva e Abilita' devono restare della stessa altezza (%s contro %s)."
				% [
					expected_id,
					selector.get_passive_card_rect().size.y,
					selector.get_ability_card_rect().size.y,
				]
			)
		)
		assert_eq(
			selector.get_visible_card_ids().size(), 7,
			"%s deve conservare la stessa finestra di sette miniature." % expected_id
		)
		assert_true(
			absf(
				selector.get_center_card_rect().get_center().x
				- selector.get_carousel_rect().get_center().x
			) <= 1.0,
			"%s selezionato deve trovarsi al centro della fascia roster." % expected_id
		)
		selector.navigate_next()
		# La fascia scorre con un tween: la posizione va letta a transizione
		# conclusa, non a meta' scorrimento.
		await wait_seconds(TRANSITION_SETTLE_SECONDS)
	assert_eq(
		selector.get_selected_definition().id, &"magno",
		"Otto avanzamenti devono chiudere il ciclo sul primo Friend."
	)


func _assert_bust_dominates(selector: CharacterSelectOverlay) -> void:
	var bust_rect := selector.get_bust_portrait_rect()
	var center_rect := selector.get_center_card_rect()
	var ability_rect := selector.get_ability_panel_rect()
	var confirm_rect := selector.get_confirm_button().get_global_rect()
	var back_rect := selector.get_back_button().get_global_rect()
	var identity_rect := selector.get_identity_block_rect()
	assert_true(
		bust_rect.get_area() >= BUST_DOMINANCE_RATIO * center_rect.get_area(),
		"Il busto deve dominare le miniature del roster: %s contro %s." % [bust_rect, center_rect]
	)
	assert_true(
		selector.get_portrait_stage_rect().encloses(
			Rect2(bust_rect.position, Vector2(bust_rect.size.x, 1.0))
		),
		"Il busto non deve uscire lateralmente dalla propria colonna."
	)
	assert_false(
		bust_rect.intersects(ability_rect), "Il busto non deve coprire i pannelli Passiva/Abilita'."
	)
	assert_false(bust_rect.intersects(confirm_rect), "Il busto non deve coprire il CTA.")
	assert_false(bust_rect.intersects(back_rect), "Il busto non deve coprire il Back.")
	assert_false(
		identity_rect.intersects(ability_rect),
		"Il blocco identita' non deve invadere l'area del kit."
	)
	assert_true(
		identity_rect.position.x < bust_rect.get_center().x,
		"Nome e ruolo devono restare nello stesso blocco visivo del busto, alla sua sinistra."
	)


func _assert_circular_navigation_unchanged(selector: CharacterSelectOverlay) -> void:
	selector.navigate_previous()
	assert_eq(
		selector.get_selected_definition().id, &"marghe",
		"PRECEDENTE dal primo Friend deve continuare a fare wrap sull'ultimo."
	)
	selector.navigate_next()
	assert_eq(
		selector.get_selected_definition().id, &"magno",
		"SUCCESSIVO dall'ultimo Friend deve continuare a fare wrap sul primo."
	)
	selector.get_next_button().pressed.emit()
	assert_eq(
		selector.get_selected_definition().id, &"bea", "La freccia deve navigare senza confermare."
	)
	selector.get_previous_button().pressed.emit()
	assert_eq(
		selector.get_selected_definition().id, &"magno", "La freccia opposta deve tornare indietro."
	)


## PS-069: passiva e abilita' hanno testi di lunghezza diversa per Friend.
## L'altezza della colonna e' derivata dal layout, non dal testo del Friend
## corrente: sfogliare il roster non deve far ballare le due card.
func _assert_ability_cards_are_stable(selector: CharacterSelectOverlay) -> void:
	var reference := Rect2()
	for friend_id in EXPECTED_IDS:
		var button := selector.get_button(friend_id)
		if button == null:
			continue
		button.pressed.emit()
		await wait_seconds(TRANSITION_SETTLE_SECONDS)
		var ability_rect := selector.get_ability_panel_rect()
		if reference == Rect2():
			reference = ability_rect
			continue
		assert_almost_eq(
			ability_rect.size, reference.size, Vector2.ONE,
			"%s: la colonna Passiva/Abilita' deve conservare la stessa misura (%s vs %s)."
			% [friend_id, ability_rect.size, reference.size]
		)
		assert_almost_eq(
			ability_rect.position, reference.position, Vector2.ONE,
			"%s: la colonna Passiva/Abilita' non deve spostarsi cambiando Friend." % friend_id
		)


func _assert_layout_profiles(
	selector: CharacterSelectOverlay, arena_layout: ArenaLayout
) -> void:
	for profile in LAYOUT_PROFILES:
		get_tree().root.content_scale_size = profile
		get_tree().root.size = profile
		arena_layout.refresh_layout()
		await wait_process_frames(2)
		var safe_area := arena_layout.get_safe_area_rect()
		var panel_rect := selector.get_selection_panel_rect()
		var bust_rect := selector.get_bust_portrait_rect()
		var ability_rect := selector.get_ability_panel_rect()
		var carousel_rect := selector.get_carousel_rect()
		var confirm_rect := selector.get_confirm_button().get_global_rect()
		var back_rect := selector.get_back_button().get_global_rect()
		assert_true(
			safe_area.encloses(panel_rect),
			"%s: il pannello %s deve restare nella safe area %s." % [profile, panel_rect, safe_area]
		)
		assert_true(
			safe_area.encloses(bust_rect), "%s: il busto deve restare nella safe area." % profile
		)
		assert_true(
			panel_rect.position.x - safe_area.position.x >= NOTCH_GUARD_LEFT - 0.5,
			"%s: il lato notch deve conservare la guardia; pannello %s in safe area %s." % [
				profile, panel_rect, safe_area
			]
		)
		assert_true(
			bust_rect.end.y <= carousel_rect.end.y + 0.5,
			"%s: il busto non deve superare la fascia roster." % profile
		)
		assert_true(
			ability_rect.end.y <= carousel_rect.position.y + 0.5,
			"%s: le card Passiva/Abilita' non devono sovrapporsi alla fascia roster." % profile
		)
		assert_false(
			ability_rect.intersects(carousel_rect),
			"%s: le card Passiva/Abilita' non devono sovrapporsi alla fascia roster." % profile
		)
		# PS-069: la riga dorata dell'identita' attraversa la schermata come
		# separatore; la colonna informativa deve fermarsi sopra, non tagliarla.
		var rule_rect := selector.get_identity_rule_rect()
		assert_true(
			ability_rect.end.y <= rule_rect.position.y + 0.5,
			"%s: le card Passiva/Abilita' (fino a %.0f) devono restare sopra la riga dorata (%.0f)."
			% [profile, ability_rect.end.y, rule_rect.position.y]
		)
		assert_true(
			ability_rect.position.y <= bust_rect.position.y + 0.5,
			"%s: le card devono partire dal bordo superiore del busto, non a meta' altezza." % profile
		)
		assert_false(
			ability_rect.intersects(rule_rect),
			"%s: le card Passiva/Abilita' non devono toccare la riga dorata." % profile
		)
		assert_false(
			bust_rect.intersects(confirm_rect), "%s: il busto non deve coprire il CTA." % profile
		)
		assert_true(
			carousel_rect.encloses(selector.get_center_card_rect()),
			"%s: la miniatura selezionata deve restare intera." % profile
		)
		assert_true(
			selector.get_preview_card_rect(1).size.x >= 44.0
			and selector.get_preview_card_rect(-1).size.x >= 44.0,
			"%s: le miniature adiacenti devono restare toccabili." % profile
		)
		assert_true(
			safe_area.encloses(back_rect) and safe_area.encloses(confirm_rect),
			"%s: Back e CTA devono restare nella safe area." % profile
		)
		await _assert_copy_is_not_truncated(selector, profile)
	get_tree().root.content_scale_size = LAYOUT_PROFILES[0]
	get_tree().root.size = LAYOUT_PROFILES[0]
	arena_layout.refresh_layout()
	await wait_process_frames(2)


func _assert_copy_is_not_truncated(
	selector: CharacterSelectOverlay, profile: Vector2i
) -> void:
	for expected_id in EXPECTED_IDS:
		selector.get_button(expected_id).pressed.emit()
		await wait_process_frames(2)
		for label_path in IDENTITY_LABEL_PATHS:
			var label := selector.get_node_or_null(label_path) as Label
			assert_not_null(label, "%s: il testo deve esistere: %s." % [profile, label_path])
			if label == null:
				continue
			assert_true(
				label.get_visible_line_count() == label.get_line_count(),
				"%s: %s non deve troncare il testo di %s." % [profile, label_path, expected_id]
			)
			_assert_label_words_fit(label, profile, label_path, expected_id)
	selector.get_button(&"magno").pressed.emit()
	await wait_process_frames(2)


## Il word-wrap di Godot e' greedy: accumula parole su una riga finche'
## entrano, poi va a capo — quindi molte righe finiscono naturalmente vicine
## al bordo per costruzione (e' cosi' che un wrap funziona, non un difetto).
## Una singola parola piu' larga della Label esce sicuramente dal bordo: e'
## l'unico invariante che si puo' testare senza rifare da zero il motore di
## wrap di Godot. Non cattura differenze di metrica del font fra motori (il
## caso reale su device, PS-069, dove "TERMOSTATO INTERNO" — due parole, non
## una — restava sulla stessa riga a 89,6% della colonna con le metriche
## desktop, ma usciva dal bordo su device): per quello la mitigazione e' il
## margine reale di `ABILITY_CARDS_WIDTH`, non questo test.
func _assert_label_words_fit(
	label: Label, profile: Vector2i, label_path: String, friend_id: StringName
) -> void:
	if label.size.x <= 0.0:
		return
	var font := label.get_theme_font(&"font")
	var font_size := label.get_theme_font_size(&"font_size")
	if font == null:
		return
	for word in label.text.split(" ", false):
		var word_width := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		assert_true(
			word_width <= label.size.x + 0.5,
			(
				"%s: '%s' (%.1fpx) esce dal bordo di %s (%.1fpx) per %s."
				% [profile, word, word_width, label_path, label.size.x, friend_id]
			)
		)
