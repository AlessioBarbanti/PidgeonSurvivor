extends SceneTree

## Utility di sviluppo temporanea (non un test, non parte della pipeline di
## verifica): cattura la Boss Intro per le 9 varianti PS-176 a due risoluzioni
## di riferimento, per il controllo percettivo dell'agente direttore-artistico
## contro i master in `assets/Evil portrais new/`.

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const OUT_DIR := "res://exports/ui-screenshots/ps176-boss-intro"
const LANDSCAPE_16X9 := Vector2i(1280, 720)
const LANDSCAPE_20X9 := Vector2i(2424, 1080)

const EVIL_FRIEND_IDS := ["alea", "aleo", "bea", "lollo", "magno", "marghe", "migi", "zat"]

const STRESS_QUOTE := (
	"Nessuno resiste al profumo della griglia quando la fame vince la " +
	"ragione: stanotte il fuoco brucia piu' forte e nessuno tornera' a " +
	"casa senza aver assaggiato la brace."
)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _capture_for_size("16x9", LANDSCAPE_16X9)
	await _capture_for_size("20x9", LANDSCAPE_20X9)
	print("CAPTURE_DONE")
	quit(0)


func _capture_for_size(tag: String, viewport_size: Vector2i) -> void:
	root.content_scale_size = viewport_size
	root.size = viewport_size
	DisplayServer.window_set_size(viewport_size)
	await _frames(4)

	var slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(slice)
	await _frames(20)

	# Attraversa welcome -> selezione -> play come farebbe un giocatore reale:
	# senza uscire da BOOT la WelcomeScreen resta sopra a tutto, Boss Intro
	# compresa (stesso ordine di `_capture_ui_screenshots.gd`).
	var welcome := slice.call("get_welcome_screen") as WelcomeScreen
	if welcome != null and welcome.get_play_button() != null:
		welcome.get_play_button().emit_signal("pressed")
		await _frames(30)
	var selector := slice.call("get_character_select_overlay") as CharacterSelectOverlay
	if selector != null and selector.get_confirm_button() != null:
		selector.get_confirm_button().emit_signal("pressed")
		await _frames(20)

	var boss_ui := slice.call("get_boss_ui") as BossUI

	DirAccess.make_dir_recursive_absolute(OUT_DIR)

	var baseline := load("res://data/bosses/first_boss.tres") as BossDefinition
	await _shot(boss_ui, baseline, "%s_00_piccione_malvagio" % tag)

	for friend_id in EVIL_FRIEND_IDS:
		var friend := load("res://data/friends/%s.tres" % friend_id) as FriendDefinition
		var evil := BossDefinition.new()
		evil.id = StringName("ps176_%s" % friend_id)
		evil.visual_kind = BossDefinition.VisualKind.EVIL_FRIEND
		evil.friend_profile = friend
		evil.quote_approved = true
		evil.quote = "La fame vince la ragione. Stanotte tocca a te."
		await _shot(boss_ui, evil, "%s_evil_%s" % [tag, friend_id])

	# Un solo scatto con la citazione di stress (167 caratteri): dimostra la
	# rete di sicurezza clip_contents senza gonfiare il pacchetto.
	var stress := BossDefinition.new()
	stress.id = &"ps176_stress"
	stress.visual_kind = BossDefinition.VisualKind.EVIL_FRIEND
	stress.friend_profile = load("res://data/friends/alea.tres") as FriendDefinition
	stress.quote_approved = true
	stress.quote = STRESS_QUOTE
	await _shot(boss_ui, stress, "%s_zz_stress_quote" % tag)

	slice.queue_free()
	await _frames(4)


func _shot(boss_ui: BossUI, definition: BossDefinition, shot_name: String) -> void:
	boss_ui.show_intro(definition)
	await _frames(6)
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, shot_name]
	var error := image.save_png(path)
	print("SHOT %s -> %s (err %d)" % [shot_name, path, error])
	boss_ui.hide_intro()
	await _frames(2)


func _frames(count: int) -> void:
	for _index in count:
		await process_frame
