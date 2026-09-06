extends GutGameplayTest

## PS-106 — Integra l'icona del calice Sobrietà di Alea in HUD.
##
## Copre: visibilità condizionata al personaggio equipaggiato (visibile solo
## con Alea, nascosta senza riservare spazio con qualunque altro), aggiornamento
## in tempo reale del riempimento al variare del segnale `alea_sobriety_changed`
## esposto da PS-105 (senza polling), assenza di sovrapposizione con
## `HealthPanel`/`ExperiencePanel`, e azzeramento al restart.
##
## PS-110: l'asset referenziato da `hud.tscn`
## (`assets/art/icons/hud/generated/alea_sobriety_*.png`) è un placeholder
## generato da `tools/generate-art-placeholder.ps1` in attesa di PS-104: la
## card resta `IN ATTESA ASSET` finché non viene sostituito.

const ALEA_ID := &"alea"
const MAGNO_ID := &"magno"


func test_sobriety_icon_hidden_by_default_and_visible_only_for_alea() -> void:
	var slice := await instantiate_movement_slice()
	var hud := slice.get_hud() as GameHud
	var registry := slice.get_friend_registry() as FriendRegistry
	assert_true(hud != null and registry != null, "PS-106 richiede HUD e FriendRegistry.")
	if hud == null or registry == null:
		return

	assert_false(
		hud.is_sobriety_icon_visible(),
		"Con Magno equipaggiato di default il calice non deve comparire."
	)

	var alea := registry.resolve_definition(ALEA_ID)
	assert_true(alea != null, "Il profilo Alea deve esistere.")
	if alea == null:
		return
	hud.set_friend_definition(alea)
	assert_true(hud.is_sobriety_icon_visible(), "Con Alea equipaggiata il calice deve comparire.")

	var magno := registry.resolve_definition(MAGNO_ID)
	assert_true(magno != null, "Il profilo Magno deve esistere.")
	if magno != null:
		hud.set_friend_definition(magno)
		assert_false(
			hud.is_sobriety_icon_visible(), "Tornando a Magno il calice deve sparire di nuovo."
		)


func test_sobriety_icon_follows_passive_signal_in_real_time_and_resets_on_restart() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var registry := slice.get_friend_registry() as FriendRegistry
	var player := slice.get_player() as Player
	var passive := slice.get_friend_passive_controller() as FriendPassiveController
	var hud := slice.get_hud() as GameHud
	assert_true(
		controller != null and registry != null and player != null
		and passive != null and hud != null,
		"PS-106 richiede le dipendenze condivise con PS-105."
	)
	if (
		controller == null or registry == null or player == null
		or passive == null or hud == null
	):
		return

	controller.set_process(false)
	player.set_physics_process(false)
	passive.set_process(false)
	controller.start_run(4242)

	var alea := registry.resolve_definition(ALEA_ID)
	assert_true(alea != null, "Il profilo Alea deve esistere.")
	if alea == null:
		return
	player.set_friend_definition(alea)
	hud.set_friend_definition(alea)
	assert_true(passive.equip_definition(alea), "La passiva deve accettare Alea.")

	assert_almost_eq(
		hud.get_sobriety_fill_ratio(), 0.0, FLOAT_TOLERANCE, "Il calice deve iniziare vuoto."
	)

	var fill_duration: float = alea.get_passive_float(
		&"sobriety_fill_duration", 48.0, AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	passive._process(fill_duration * 0.5)
	assert_almost_eq(
		hud.get_sobriety_fill_ratio(), 0.5, 0.01,
		"PS-106: il riempimento dell'icona deve seguire in tempo reale il segnale di PS-105, senza polling."
	)

	controller.prepare_restart()
	assert_almost_eq(
		hud.get_sobriety_fill_ratio(), 0.0, FLOAT_TOLERANCE,
		"Il restart deve azzerare il riempimento visibile in HUD."
	)


func test_sobriety_icon_does_not_overlap_health_or_experience_panel() -> void:
	var slice := await instantiate_movement_slice()
	var hud := slice.get_hud() as GameHud
	var registry := slice.get_friend_registry() as FriendRegistry
	assert_true(hud != null and registry != null, "PS-106 richiede HUD e FriendRegistry.")
	if hud == null or registry == null:
		return
	var alea := registry.resolve_definition(ALEA_ID)
	assert_true(alea != null, "Il profilo Alea deve esistere.")
	if alea == null:
		return
	hud.set_friend_definition(alea)
	await wait_process_frames(1)

	var sobriety_rect := hud.get_sobriety_icon_rect()
	var xp_rect := hud.get_experience_panel_rect()
	var health_rect := hud.get_health_panel_rect()
	assert_false(sobriety_rect.intersects(xp_rect), "Il calice non deve sovrapporsi alla barra XP.")
	assert_false(sobriety_rect.intersects(health_rect), "Il calice non deve sovrapporsi alla barra HP.")

	print("ALEA_SOBRIETY_HUD_SMOKE_OK")
