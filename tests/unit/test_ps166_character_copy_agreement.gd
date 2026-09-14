extends GutGameplayTest

## PS-166: due copy dinamici applicavano una concordanza maschile fissa a un
## nome che puo' essere femminile (Evil <Nome>). Verifica che la riga di
## redenzione del Barb Reward e il riepilogo di vittoria restino corretti sia
## con un nome maschile sia con uno femminile, senza introdurre un metadato
## di genere su `FriendDefinition`, e che le stringhe generiche sul
## sostantivo «Boss» (non legate al genere del personaggio) restino invariate.

const BARB_OVERLAY_SCENE := preload("res://scenes/ui/barb_reward_overlay.tscn")
const TOUCH_JOYSTICK_SCENE := preload("res://scenes/ui/touch_joystick.tscn")
const END_SCREEN_SCENE := preload("res://scenes/ui/end_screen.tscn")


func test_barb_reward_redemption_text_is_gender_neutral() -> void:
	for entry in [["Magno", "maschile"], ["Marghe", "femminile"]]:
		var friend_name: String = entry[0]
		var label: String = entry[1]
		var fixture := await _create_overlay_fixture(9166)
		var controller := fixture.controller as RunController
		var service := fixture.service as UpgradeService
		var overlay := fixture.overlay as BarbRewardOverlay
		var fixture_root := fixture.root as Control

		overlay.set_redeemed_friend_name(friend_name)
		service.queue_barb_reward()
		await wait_process_frames(2)
		var text := overlay.get_redemption_text()
		assert_eq(
			text, "%s è di nuovo tra noi, grazie a Barb!" % friend_name,
			"PS-166: la riga di redenzione con nome %s (%s) deve restare grammaticalmente neutra."
				% [friend_name, label]
		)
		assert_false(
			text.contains("tornato") or text.contains("tornata"),
			"PS-166: nessuna forma concordata al genere ('tornato'/'tornata') deve comparire (nome %s)."
				% friend_name
		)

		controller.prepare_restart()
		fixture_root.queue_free()
		await wait_process_frames(1)


func test_end_screen_victory_summary_is_gender_neutral() -> void:
	for entry in [["Piccione Malvagio", "neutro"], ["Evil Magno", "maschile"], ["Evil Marghe", "femminile"]]:
		var boss_title: String = entry[0]
		var label: String = entry[1]
		var end_screen := END_SCREEN_SCENE.instantiate() as EndScreen
		add_child_autofree(end_screen)
		await wait_process_frames(1)

		var summary := RunSummary.new()
		summary.character_name = "Prova"
		summary.level = 3
		summary.bosses_defeated = 1
		summary.run_time = 754.0
		end_screen.show_victory(summary, boss_title)

		var text := end_screen.get_summary_text()
		assert_true(
			text.begins_with("Hai sconfitto %s in " % boss_title),
			"PS-166: il riepilogo di vittoria con titolo %s (%s) deve restare corretto (testo=%s)."
				% [boss_title, label, text]
		)
		assert_false(
			text.contains("sconfitto in") and text.begins_with(boss_title),
			"PS-166: il vecchio schema '<Titolo> sconfitto in ...' non deve piu' comparire (titolo %s)."
				% boss_title
		)


func test_generic_boss_count_line_is_unaffected() -> void:
	# PS-166 criterio 3: le stringhe sul sostantivo generico «Boss» (non
	# legate al genere del personaggio) restano invariate.
	var end_screen := END_SCREEN_SCENE.instantiate() as EndScreen
	add_child_autofree(end_screen)
	await wait_process_frames(1)

	var summary_one := RunSummary.new()
	summary_one.bosses_defeated = 1
	end_screen.show_defeat(summary_one)
	assert_true(
		end_screen.get_stats_text().contains("1 Boss sconfitto"),
		"PS-166: il conteggio singolare generico non deve cambiare."
	)

	var summary_many := RunSummary.new()
	summary_many.bosses_defeated = 3
	end_screen.show_defeat(summary_many)
	assert_true(
		end_screen.get_stats_text().contains("3 Boss sconfitti"),
		"PS-166: il conteggio plurale generico non deve cambiare."
	)
	print("PS166_CHARACTER_COPY_AGREEMENT_SMOKE_OK")


func _create_overlay_fixture(seed_value: int) -> Dictionary:
	var fixture_root := Control.new()
	fixture_root.name = "Ps166BarbFixture"
	fixture_root.process_mode = Node.PROCESS_MODE_ALWAYS
	fixture_root.position = Vector2(20.0, 20.0)
	fixture_root.size = Vector2(1240.0, 680.0)

	var controller := RunController.new()
	controller.name = "RunController"
	controller.set_process(false)
	var experience := ExperienceSystem.new()
	experience.name = "ExperienceSystem"
	var curve := ExperienceCurve.new()
	curve.base_experience_required = 1
	curve.experience_growth_per_level = 0
	experience.experience_curve = curve
	var registry := UpgradeRegistry.new()
	registry.name = "UpgradeRegistry"
	registry.definitions = [
		_make_filler(&"ps166_filler_a"),
		_make_filler(&"ps166_filler_b"),
		_make_filler(&"ps166_filler_c"),
	]
	var service := UpgradeService.new()
	service.name = "UpgradeService"
	var joystick := TOUCH_JOYSTICK_SCENE.instantiate() as TouchJoystick
	joystick.name = "TouchJoystick"
	joystick.debug_mode_in_editor = true
	var overlay := BARB_OVERLAY_SCENE.instantiate() as BarbRewardOverlay
	overlay.name = "BarbRewardOverlay"

	fixture_root.add_child(controller)
	fixture_root.add_child(experience)
	fixture_root.add_child(registry)
	fixture_root.add_child(service)
	fixture_root.add_child(joystick)
	fixture_root.add_child(overlay)
	add_child_autofree(fixture_root)
	await wait_process_frames(2)

	experience.set_run_controller(controller)
	assert_true(registry.rebuild_registry(), "La fixture PS-166 deve avere un catalogo valido.")
	assert_true(service.configure(registry, controller, experience), "La fixture PS-166 deve configurare il service.")
	assert_true(overlay.configure(service, joystick), "La fixture PS-166 deve configurare l'overlay.")
	assert_true(controller.start_run(seed_value), "La fixture PS-166 deve avviare la run.")
	return {
		"root": fixture_root,
		"controller": controller,
		"service": service,
		"overlay": overlay,
	}


func _make_filler(upgrade_id: StringName) -> UpgradeDefinition:
	var definition := UpgradeDefinition.new()
	definition.id = upgrade_id
	definition.title = String(upgrade_id)
	definition.description = "Potenziamento bonus per la verifica PS-166."
	definition.effect_id = &"smoke_effect"
	definition.weight = 1.0
	definition.max_rank = 5
	definition.repeatable = true
	definition.tags = [&"test"]
	return definition
