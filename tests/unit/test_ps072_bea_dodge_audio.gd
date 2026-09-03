extends GutGameplayTest

## PS-072 — Il Sesto Senso Equino di Bea (`instinctive_dodge_triggered`) deve
## riprodurre il cue `GameAudio.DODGE` in sincrono con l'accento visivo
## esistente (`InstinctiveDodgeAccent`, gia' approvato e non toccato qui).
## Nessun altro personaggio deve mai generare il cue, e il rispetto delle
## impostazioni audio (mute/volume) resta quello generico di `play_cue`.


func test_bea_dodge_plays_the_dodge_cue() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var passive: FriendPassiveController = context["passive"]
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var audio: GameAudio = context["audio"]
	var controller: RunController = context["controller"]

	assert_true(audio.has_complete_cue_set(), "PS-072: il set di cue deve risultare completo con DODGE integrato.")
	assert_not_null(
		audio.get_stream_for_cue(GameAudio.DODGE), "PS-072: il cue DODGE deve avere uno stream importato."
	)

	var bea := registry.resolve_definition(&"bea")
	assert_true(bea != null, "Il profilo Bea deve esistere.")
	if bea == null:
		return
	player.set_friend_definition(bea)
	assert_true(passive.equip_definition(bea), "La passiva deve accettare Bea.")

	var cues_played: Array[StringName] = []
	audio.cue_played.connect(func(cue_id: StringName) -> void: cues_played.append(cue_id))

	assert_almost_eq(
		passive.resolve_incoming_damage(20.0), 0.0, FLOAT_TOLERANCE,
		"Il primo colpo eleggibile deve essere annullato dallo scarto."
	)
	assert_true(
		GameAudio.DODGE in cues_played,
		"Lo scatto del Sesto Senso Equino deve riprodurre il cue DODGE in sincrono con l'accento visivo."
	)

	controller.prepare_restart()


func test_other_friends_never_trigger_the_dodge_cue() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var passive: FriendPassiveController = context["passive"]
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var audio: GameAudio = context["audio"]
	var controller: RunController = context["controller"]

	var migi := registry.resolve_definition(&"migi")
	assert_true(migi != null, "Il profilo Migi deve esistere.")
	if migi == null:
		return
	player.set_friend_definition(migi)
	assert_true(passive.equip_definition(migi), "La passiva deve accettare Migi.")

	var cues_played: Array[StringName] = []
	audio.cue_played.connect(func(cue_id: StringName) -> void: cues_played.append(cue_id))

	passive.resolve_incoming_damage(20.0)
	assert_true(
		cues_played.is_empty(),
		"Un personaggio senza Sesto Senso Equino non deve mai generare il cue DODGE."
	)

	controller.prepare_restart()


func test_dodge_cue_respects_mute_and_zero_volume() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var passive: FriendPassiveController = context["passive"]
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var audio: GameAudio = context["audio"]
	var controller: RunController = context["controller"]

	var bea := registry.resolve_definition(&"bea")
	if bea == null:
		return
	player.set_friend_definition(bea)
	passive.equip_definition(bea)

	var initial_volume := audio.get_effects_volume()
	var initial_muted := audio.is_muted()

	audio.set_muted(true, false)
	var cues_muted: Array[StringName] = []
	audio.cue_played.connect(func(cue_id: StringName) -> void: cues_muted.append(cue_id))
	passive.resolve_incoming_damage(20.0)
	assert_true(cues_muted.is_empty(), "Con audio disattivato non deve essere udibile alcun cue DODGE.")

	audio.set_muted(false, false)
	passive._process(9.0)
	audio.set_effects_volume(0.0, false)
	var cues_silent: Array[StringName] = []
	audio.cue_played.connect(func(cue_id: StringName) -> void: cues_silent.append(cue_id))
	passive.resolve_incoming_damage(20.0)
	assert_true(cues_silent.is_empty(), "Con volume a zero non deve essere udibile alcun cue DODGE.")

	audio.set_effects_volume(initial_volume, false)
	audio.set_muted(initial_muted, false)
	controller.prepare_restart()

	print("BEA_DODGE_AUDIO_SMOKE_OK")


func _build_context() -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	var audio := movement_slice.get_game_audio() as GameAudio
	if controller == null or registry == null or player == null or passive == null or audio == null:
		assert_true(false, "La scena di run deve esporre le dipendenze PS-072.")
		return {}

	controller.set_process(false)
	passive.set_process(false)
	controller.start_run(4711)
	return {
		"slice": movement_slice,
		"controller": controller,
		"registry": registry,
		"player": player,
		"passive": passive,
		"audio": audio,
	}
