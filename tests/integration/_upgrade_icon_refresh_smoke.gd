extends SceneTree

const UPGRADE_OVERLAY_SCENE := preload("res://scenes/ui/upgrade_overlay.tscn")
const SWIFT_STEPS := preload("res://data/upgrades/swift_steps.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")
const ANXIETY := preload("res://data/upgrades/anxiety_signature.tres")
const BEER := preload("res://data/upgrades/beer_signature.tres")
const CHRONIC_DELAY := preload("res://data/upgrades/chronic_delay.tres")
const MEAT_FORK_DAMAGE := preload("res://data/upgrades/meat_fork_damage.tres")
const GOSSIP := preload("res://data/upgrades/gossip_projectiles.tres")
const NO_TIME := preload("res://data/upgrades/damage_shockwave.tres")
const SUMMER_GRILL := preload("res://data/upgrades/summer_grill.tres")
const PIERCING_ROUNDS := preload("res://data/upgrades/piercing_rounds.tres")
const DOUBLE_BARREL := preload("res://data/upgrades/double_barrel.tres")
const DEATH_BURST := preload("res://data/upgrades/death_burst.tres")

const VIEWPORTS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1080, 2400), Vector2i(1024, 768)]
const DEFINITIONS: Array[UpgradeDefinition] = [
	SWIFT_STEPS,
	RAPID_FIRE,
	WIDE_MAGNET,
	ANXIETY,
	BEER,
	CHRONIC_DELAY,
	MEAT_FORK_DAMAGE,
	GOSSIP,
	NO_TIME,
	SUMMER_GRILL,
	PIERCING_ROUNDS,
	DOUBLE_BARREL,
	DEATH_BURST,
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for viewport_size in VIEWPORTS:
		await _validate_viewport(viewport_size)
	await _finish()


func _validate_viewport(viewport_size: Vector2i) -> void:
	root.content_scale_size = viewport_size
	root.size = viewport_size
	var overlay := UPGRADE_OVERLAY_SCENE.instantiate() as UpgradeOverlay
	root.add_child(overlay)
	await process_frame
	await process_frame
	var cards := overlay.get_cards()
	_expect(cards.size() == 3, "B27 richiede tre carte a %s." % viewport_size)
	if cards.size() != 3:
		overlay.queue_free()
		await process_frame
		return

	for index in DEFINITIONS.size():
		var definition := DEFINITIONS[index]
		var card := cards[index % cards.size()]
		_expect(card.configure(definition, 0, index % cards.size()), "La carta B27 deve configurare %s." % definition.id)
		var icon := card.get_node_or_null("Margins/Content/IconCenter/Icon") as TextureRect
		_expect(icon != null and icon.texture == definition.icon, "B27 deve mostrare l'icona %s." % definition.id)
		if icon != null and icon.texture != null:
			_expect(icon.texture.get_width() == 128 and icon.texture.get_height() == 128, "B27 deve usare un derivato PNG 128x128 per %s." % definition.id)
			_expect(icon.expand_mode == 3 and icon.stretch_mode == 5, "B27 deve mantenere l'adattamento proporzionale di %s." % definition.id)

	await process_frame
	for card in cards:
		var icon := card.get_node_or_null("Margins/Content/IconCenter/Icon") as TextureRect
		if icon == null:
			continue
		var icon_rect := icon.get_global_rect()
		_expect(icon_rect.size == Vector2(192.0, 192.0), "B27 deve mantenere il target icona 192x192 a %s (ottenuto=%s)." % [viewport_size, icon_rect.size])
		_expect(icon.get_parent() is CenterContainer, "B27 deve centrare ogni icona a %s." % viewport_size)

	overlay.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("B27_UPGRADE_ICON_REFRESH_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B27_UPGRADE_ICON_REFRESH_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
