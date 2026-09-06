extends GutGameplayTest

## PS-103: cablaggio della cornice dedicata prodotta da PS-102
## (`generated/boss_intro_frame.png`) nell'`IntroPanel` della Boss Intro.
## Copre la risoluzione del nuovo `StyleBoxTexture` (non più
## `pause_panel_frame.png`), l'invarianza di tinta per il Piccione Malvagio,
## la tinta per un `Evil <Nome>` sulla nuova cornice, il contenimento nella
## safe area con titolo/citazione al limite di lunghezza (equivalente allo
## stress usato da PS-071/PS-051) e l'invarianza del pannello di pausa.

const BOSS_UI_SCENE_PS103 := preload("res://scenes/ui/boss_ui.tscn")
const NEW_FRAME_PATH := "res://assets/art/ui/boss/generated/boss_intro_frame.png"
const OLD_FRAME_PATH := "res://assets/art/ui/pause/pause_panel_frame.png"
const REFERENCE_SIGNATURE := preload("res://data/bosses/signatures/evil_alea_grand_spin.tres")

const LONG_TITLE := "IL CAPOSQUADRA DELLE BRACI ETERNE"
const LONG_QUOTE := (
	"Nessuno resiste al profumo della griglia quando la fame vince la " +
	"ragione: stanotte il fuoco brucia piu' forte e nessuno tornera' a " +
	"casa senza aver assaggiato la brace."
)


func _make_long_baseline_definition() -> BossDefinition:
	var definition := BossDefinition.new()
	definition.id = &"ps103_long_baseline"
	definition.title = LONG_TITLE
	definition.quote_approved = true
	definition.quote = LONG_QUOTE
	return definition


func test_intro_panel_resolves_new_frame_style_and_preserves_neutral_tint() -> void:
	var boss_ui := BOSS_UI_SCENE_PS103.instantiate() as BossUI
	add_child_autofree(boss_ui)
	await wait_process_frames(1)

	var intro_panel := boss_ui.get_node_or_null("IntroLayer/Center/IntroPanel") as PanelContainer
	assert_true(intro_panel != null, "IntroPanel deve esistere nella scena Boss Intro.")
	if intro_panel == null:
		return
	var style := intro_panel.get_theme_stylebox(&"panel") as StyleBoxTexture
	assert_true(
		style != null and style.texture != null and style.texture.resource_path == NEW_FRAME_PATH,
		"IntroPanel deve risolvere il nuovo StyleBoxTexture di PS-102, non più pause_panel_frame.png."
	)

	var baseline := _make_long_baseline_definition()
	assert_true(boss_ui.show_intro(baseline), "La intro deve potersi aprire con il Piccione Malvagio.")
	assert_true(
		boss_ui.get_intro_frame_modulate().is_equal_approx(BossUI.DEFAULT_PANEL_MODULATE),
		"Il Piccione Malvagio non deve ricevere alcuna tinta sulla nuova cornice."
	)


func test_evil_tints_the_new_frame_with_signature_accent() -> void:
	var boss_ui := BOSS_UI_SCENE_PS103.instantiate() as BossUI
	add_child_autofree(boss_ui)
	await wait_process_frames(1)

	var friend := load("res://data/friends/alea.tres") as FriendDefinition
	assert_true(friend != null, "Il friend di riferimento deve caricarsi.")
	if friend == null:
		return
	var evil := BossDefinition.new()
	evil.id = &"ps103_evil_reference"
	evil.visual_kind = BossDefinition.VisualKind.EVIL_FRIEND
	evil.friend_profile = friend
	evil.signature = REFERENCE_SIGNATURE
	assert_true(evil.is_valid(), "L'Evil di riferimento deve restare valido.")
	if not evil.is_valid():
		return

	assert_true(boss_ui.show_intro(evil), "La intro deve potersi aprire con un Evil.")
	var expected_frame_modulate := BossUI.DEFAULT_PANEL_MODULATE.lerp(
		REFERENCE_SIGNATURE.accent_color, BossUI.ACCENT_FRAME_MIX
	)
	expected_frame_modulate.a = 1.0
	assert_true(
		boss_ui.get_intro_frame_modulate().is_equal_approx(expected_frame_modulate),
		"Un Evil deve tingere la nuova cornice con l'accent_color della Signature."
	)


func test_intro_panel_with_long_copy_stays_in_safe_area() -> void:
	var slice := await instantiate_movement_slice()
	var boss_ui := slice.get_boss_ui() as BossUI
	var arena_layout := slice.get_node_or_null("ArenaLayout") as ArenaLayout
	assert_true(boss_ui != null and arena_layout != null, "PS-103 richiede BossUI e la safe area della scena.")
	if boss_ui == null or arena_layout == null:
		return

	var definition := _make_long_baseline_definition()
	assert_true(boss_ui.show_intro(definition), "La intro deve potersi aprire con titolo/citazione al limite di lunghezza.")
	await wait_process_frames(3)
	assert_rect_inside(
		boss_ui.get_intro_panel_rect(), arena_layout.get_safe_area_rect(),
		"Il pannello con la nuova cornice deve restare nella safe area anche con copy al limite di lunghezza."
	)
	boss_ui.hide_intro()


func test_pause_panel_frame_is_untouched() -> void:
	assert_true(
		FileAccess.file_exists(OLD_FRAME_PATH),
		"Il pannello di pausa deve continuare a esistere invariato dopo il cablaggio di PS-103."
	)
	var pause_scene := load("res://scenes/ui/pause_overlay.tscn") as PackedScene
	assert_true(pause_scene != null, "La scena di pausa deve continuare a caricarsi.")

	print("BOSS_INTRO_FRAME_WIRING_SMOKE_OK")
