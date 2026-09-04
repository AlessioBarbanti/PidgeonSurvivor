extends GutTest

const UPGRADE_OVERLAY_SCENE := preload("res://scenes/ui/upgrade_overlay.tscn")
const SWIFT_STEPS := preload("res://data/upgrades/swift_steps.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")
const ANXIETY := preload("res://data/upgrades/anxiety_signature.tres")
const BEER := preload("res://data/upgrades/beer_signature.tres")
const CHRONIC_DELAY := preload("res://data/upgrades/chronic_delay.tres")
const MEAT_FORK_DAMAGE := preload("res://data/upgrades/meat_fork_damage.tres")
const GOSSIP := preload("res://data/upgrades/specialities/gossip_projectiles.tres")
const NO_TIME := preload("res://data/upgrades/damage_shockwave.tres")
const SUMMER_GRILL := preload("res://data/upgrades/summer_grill.tres")
const PIERCING_ROUNDS := preload("res://data/upgrades/specialities/piercing_rounds.tres")
const DOUBLE_BARREL := preload("res://data/upgrades/specialities/double_barrel.tres")
const DEATH_BURST := preload("res://data/upgrades/specialities/death_burst.tres")

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


## La dimensione a schermo dell'icona e' decisa dal layout della carta
## (`scenes/ui/upgrade_card.tscn`) e cambia quando il layout cambia: PS-047 ha
## compattato le carte e il vecchio target fisso 192x192 e' rimasto indietro
## di un design. Cio' che B27 deve proteggere non e' il numero, ma che
## l'icona resti quadrata e **identica su ogni viewport**: e' l'invariante che
## si romperebbe davvero se una schermata la stirasse o la schiacciasse.
var _icon_size_reference := Vector2.ZERO


func test_upgrade_card_icons_stay_centered_and_scaled_across_viewports() -> void:
	_icon_size_reference = Vector2.ZERO
	for viewport_size: Vector2i in VIEWPORTS:
		await _assert_viewport(viewport_size)


func _assert_viewport(viewport_size: Vector2i) -> void:
	get_tree().root.content_scale_size = viewport_size
	get_tree().root.size = viewport_size
	var overlay := UPGRADE_OVERLAY_SCENE.instantiate() as UpgradeOverlay
	add_child(overlay)
	await wait_process_frames(2)
	var cards := overlay.get_cards()
	assert_eq(cards.size(), 3, "B27 richiede tre carte a %s." % viewport_size)
	if cards.size() != 3:
		overlay.queue_free()
		await wait_process_frames(1)
		return

	for index in DEFINITIONS.size():
		var definition := DEFINITIONS[index]
		var card := cards[index % cards.size()]
		assert_true(
			card.configure(definition, 0, index % cards.size()), "La carta B27 deve configurare %s." % definition.id
		)
		var icon := card.get_node_or_null("Margins/Content/IconCenter/Icon") as TextureRect
		assert_true(
			icon != null and icon.texture == definition.icon, "B27 deve mostrare l'icona %s." % definition.id
		)
		if icon != null and icon.texture != null:
			assert_true(
				icon.texture.get_width() == 128 and icon.texture.get_height() == 128,
				"B27 deve usare un derivato PNG 128x128 per %s." % definition.id
			)
			assert_true(
				icon.expand_mode == 3 and icon.stretch_mode == 5,
				"B27 deve mantenere l'adattamento proporzionale di %s." % definition.id
			)

	await wait_process_frames(1)
	for card in cards:
		var icon := card.get_node_or_null("Margins/Content/IconCenter/Icon") as TextureRect
		if icon == null:
			continue
		var icon_rect := icon.get_global_rect()
		assert_true(
			icon_rect.size.x > 0.0 and is_equal_approx(icon_rect.size.x, icon_rect.size.y),
			"B27 deve mantenere l'icona quadrata a %s (ottenuto=%s)." % [viewport_size, icon_rect.size]
		)
		if _icon_size_reference == Vector2.ZERO:
			_icon_size_reference = icon_rect.size
		else:
			assert_eq(
				icon_rect.size,
				_icon_size_reference,
				"B27 deve mantenere la stessa icona su ogni viewport a %s (atteso=%s, ottenuto=%s)."
					% [viewport_size, _icon_size_reference, icon_rect.size]
			)
		assert_true(icon.get_parent() is CenterContainer, "B27 deve centrare ogni icona a %s." % viewport_size)

	overlay.queue_free()
	await wait_process_frames(1)
