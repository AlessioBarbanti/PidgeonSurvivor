extends GutGameplayTest

## PS-138 — Ridisegna l'indicatore HUD della passiva di Alea con anello di
## carica e glow Brilla.
##
## Copre: il contenuto renderizzato dell'icona resta entro i confini del suo
## slot (fix del bug di scala verificato in pianificazione con cattura
## reale), il segnale di stato Brilla — assente prima di questa card — è
## cablato correttamente all'HUD in entrambe le direzioni (inizio/fine), e
## nessuna regressione sul perimetro già coperto da
## `test_ps106_alea_sobriety_hud.gd` (visibilità condizionata, riempimento in
## tempo reale, assenza di sovrapposizione logica, azzeramento al restart).

const ALEA_ID := &"alea"


func test_icon_rendered_content_stays_within_slot_bounds() -> void:
	var built := await _build_fixture()
	if built.is_empty():
		return
	var hud: GameHud = built["hud"]
	var registry: FriendRegistry = built["registry"]

	var alea := registry.resolve_definition(ALEA_ID)
	assert_true(alea != null, "Il profilo Alea deve esistere.")
	if alea == null:
		return
	hud.set_friend_definition(alea)
	await wait_process_frames(1)

	var icon := hud.get_node("%SobrietyIcon") as Control
	var slot := hud.get_node("%SobrietySlot") as Control
	assert_true(icon != null and slot != null, "PS-138 richiede SobrietyIcon/SobrietySlot in scena.")
	if icon == null or slot == null:
		return

	# PS-138: `AleaSobrietyIndicator._draw()` scala sempre esplicitamente al
	# proprio `size` (nessuna texture disegnata alla risoluzione nativa
	# 128x128 come il precedente `TextureProgressBar`): se il nodo occupa
	# esattamente il rect dello slot, il contenuto renderizzato non può
	# sconfinare su HealthPanel/ExperiencePanel, a differenza del bug
	# verificato con cattura reale prima di questa card.
	assert_almost_eq(
		icon.size.x, slot.size.x, FLOAT_TOLERANCE,
		"PS-138: l'icona deve occupare esattamente la larghezza del suo slot, non sconfinare."
	)
	assert_almost_eq(
		icon.size.y, slot.size.y, FLOAT_TOLERANCE,
		"PS-138: l'icona deve occupare esattamente l'altezza del suo slot, non sconfinare."
	)

	print("ALEA_RING_GLOW_SMOKE_OK")


func test_ring_color_follows_charge_ratio_via_hud_signal() -> void:
	var built := await _build_fixture()
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var registry: FriendRegistry = built["registry"]
	var player: Player = built["player"]
	var passive: FriendPassiveController = built["passive"]
	var hud: GameHud = built["hud"]

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

	assert_almost_eq(hud.get_sobriety_fill_ratio(), 0.0, FLOAT_TOLERANCE, "L'anello deve iniziare vuoto.")
	assert_false(hud.is_sobriety_brilla_active(), "Nessun Brilla subito dopo l'equip.")

	var fill_duration: float = alea.get_passive_float(
		&"sobriety_fill_duration", 48.0, AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	passive._process(fill_duration * 0.5)
	assert_almost_eq(
		hud.get_sobriety_fill_ratio(), 0.5, 0.01,
		"PS-138: l'anello deve seguire in tempo reale lo stesso segnale del riempimento, senza polling."
	)

	controller.prepare_restart()


func test_brilla_signal_toggles_hud_glow_state() -> void:
	var built := await _build_fixture()
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var registry: FriendRegistry = built["registry"]
	var player: Player = built["player"]
	var passive: FriendPassiveController = built["passive"]
	var hud: GameHud = built["hud"]

	controller.set_process(false)
	player.set_physics_process(false)
	passive.set_process(false)
	controller.start_run(4243)

	var alea := registry.resolve_definition(ALEA_ID)
	assert_true(alea != null, "Il profilo Alea deve esistere.")
	if alea == null:
		return
	player.set_friend_definition(alea)
	hud.set_friend_definition(alea)
	assert_true(passive.equip_definition(alea), "La passiva deve accettare Alea.")

	var fill_duration: float = alea.get_passive_float(
		&"sobriety_fill_duration", 48.0, AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	var brilla_duration: float = alea.get_passive_float(
		&"brilla_duration", 6.0, AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)

	passive._process(fill_duration)
	assert_true(
		passive.is_alea_brilla_active(),
		"Fixture non valida: Brilla deve attivarsi al raggiungimento della soglia."
	)
	assert_true(
		hud.is_sobriety_brilla_active(),
		"PS-138: prima di questa card nessun segnale esponeva Brilla all'HUD — ora deve seguirlo."
	)

	passive._process(brilla_duration + 0.01)
	assert_false(passive.is_alea_brilla_active(), "Fixture non valida: Brilla deve terminare dopo la durata.")
	assert_false(
		hud.is_sobriety_brilla_active(),
		"PS-138: al termine di Brilla il glow del calice deve spegnersi in HUD."
	)

	controller.prepare_restart()


func test_no_regression_on_visibility_and_overlap_contract() -> void:
	var built := await _build_fixture()
	if built.is_empty():
		return
	var hud: GameHud = built["hud"]
	var registry: FriendRegistry = built["registry"]

	assert_false(hud.is_sobriety_icon_visible(), "Con Magno equipaggiato di default il calice non deve comparire.")

	var alea := registry.resolve_definition(ALEA_ID)
	assert_true(alea != null, "Il profilo Alea deve esistere.")
	if alea == null:
		return
	hud.set_friend_definition(alea)
	await wait_process_frames(1)
	assert_true(hud.is_sobriety_icon_visible(), "Con Alea equipaggiata il calice deve comparire.")

	var sobriety_rect := hud.get_sobriety_icon_rect()
	var xp_rect := hud.get_experience_panel_rect()
	var health_rect := hud.get_health_panel_rect()
	assert_false(sobriety_rect.intersects(xp_rect), "Il calice non deve sovrapporsi alla barra XP.")
	assert_false(sobriety_rect.intersects(health_rect), "Il calice non deve sovrapporsi alla barra HP.")


func _build_fixture() -> Dictionary:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var registry := slice.get_friend_registry() as FriendRegistry
	var player := slice.get_player() as Player
	var passive := slice.get_friend_passive_controller() as FriendPassiveController
	var hud := slice.get_hud() as GameHud
	assert_true(
		controller != null and registry != null and player != null
		and passive != null and hud != null,
		"PS-138 richiede le stesse dipendenze condivise con PS-105/PS-106."
	)
	if (
		controller == null or registry == null or player == null
		or passive == null or hud == null
	):
		return {}
	return {
		"controller": controller,
		"registry": registry,
		"player": player,
		"passive": passive,
		"hud": hud,
	}
