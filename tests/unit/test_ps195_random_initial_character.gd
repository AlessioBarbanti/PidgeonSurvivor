extends GutGameplayTest

## PS-195 — Al primo ingresso nel selettore in una sessione app (nessun
## FriendDefinition ancora assegnato al Player) il personaggio evidenziato e'
## scelto a caso nel roster invece di essere sempre Magno. Quando un
## personaggio e' gia' stato scelto nella sessione, resta lui: la casualita'
## vale solo per il fallback.

## Aperture ripetute del selettore: con un fallback fisso se ne osserverebbe
## un solo id. Con una scelta uniforme su k >= 2 id la probabilita' di vedere
## comunque un solo id e' k^-23, cioe' sotto il rumore di un test flaky.
const FIRST_ENTRY_OPENINGS := 24
const REOPENINGS := 8


func test_first_character_selection_highlight_is_random_in_roster() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	assert_true(
		controller != null and selector != null and registry != null and player != null,
		"PS-195 richiede selettore, registry e player composti."
	)
	if controller == null or selector == null or registry == null or player == null:
		return

	controller.set_process(false)

	var roster_ids: Array[StringName] = []
	for definition in registry.get_definitions():
		roster_ids.append(definition.id)
	assert_true(roster_ids.size() > 1, "Il criterio ha senso solo su un roster con piu' personaggi.")
	if roster_ids.size() <= 1:
		return

	var observed_ids: Dictionary = {}
	for _opening in range(FIRST_ENTRY_OPENINGS):
		# L'auto-avvio dei test equipaggia gia' un personaggio: azzerarlo e'
		# l'unico modo di riprodurre il primo ingresso dall'avvio dell'app.
		player.friend_definition = null
		movement_slice._show_character_selection()
		var highlighted := selector.get_selected_definition()
		assert_true(highlighted != null, "Il selettore deve sempre evidenziare un personaggio.")
		if highlighted == null:
			return
		assert_true(
			roster_ids.has(highlighted.id),
			"L'id evidenziato deve appartenere al roster (era %s)." % highlighted.id
		)
		observed_ids[highlighted.id] = true

	assert_true(
		observed_ids.size() > 1,
		"Il primo ingresso deve variare il personaggio evidenziato, non restare sempre lo stesso."
	)

	print("PS195_RANDOM_INITIAL_CHARACTER_SMOKE_OK")


func test_character_selection_keeps_the_character_already_chosen() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	assert_true(
		controller != null and selector != null and registry != null and player != null,
		"PS-195 richiede selettore, registry e player composti."
	)
	if controller == null or selector == null or registry == null or player == null:
		return

	controller.set_process(false)

	# Un personaggio diverso dal vecchio fallback fisso: se la casualita'
	# sovrascrivesse la scelta di sessione, qui si vedrebbe.
	var chosen: FriendDefinition = null
	for definition in registry.get_definitions():
		if definition.id != &"magno":
			chosen = definition
			break
	assert_true(chosen != null, "Serve un personaggio diverso da Magno nel roster.")
	if chosen == null:
		return
	assert_true(player.set_friend_definition(chosen), "Il personaggio scelto deve essere assegnabile.")

	for _reopening in range(REOPENINGS):
		movement_slice._show_character_selection()
		var highlighted := selector.get_selected_definition()
		assert_true(highlighted != null, "Il selettore deve sempre evidenziare un personaggio.")
		if highlighted == null:
			return
		assert_eq(
			highlighted.id, chosen.id,
			"Con un personaggio gia' scelto il selettore deve restare su quello."
		)


func test_random_pick_survives_a_single_character_roster() -> void:
	var movement_slice := await instantiate_movement_slice()
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	assert_true(registry != null, "PS-195 richiede il registry dei personaggi.")
	if registry == null:
		return

	var definitions := registry.get_definitions()
	assert_true(not definitions.is_empty(), "Il roster di partenza non puo' essere vuoto.")
	if definitions.is_empty():
		return

	var only_definition: FriendDefinition = definitions[0]
	var single_roster: Array[FriendDefinition] = [only_definition]
	registry.definitions = single_roster
	assert_true(registry.rebuild_registry(), "Un roster da un solo personaggio deve restare valido.")

	for _attempt in range(REOPENINGS):
		assert_eq(
			movement_slice._pick_random_friend_id(), only_definition.id,
			"Con un solo personaggio valido la scelta casuale deve restituire proprio quello."
		)
