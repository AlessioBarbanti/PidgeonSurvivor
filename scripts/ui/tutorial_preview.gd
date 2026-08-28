class_name TutorialPreview
extends Control

## Vetrina illustrata delle pagine tutorial. L'unica animazione è la camminata
## dei piccioni (layout `WALKERS_2_3`): artwork e icone in griglia restano
## immobili. La camminata è una funzione pura della fase normalizzata `[0, 1)`,
## con lo stato in `1` uguale a quello in `0`: il loop non salta fra ultimo e
## primo frame.

const LOOP_PERIOD := 6.0

const GRID_COLUMNS := 2
const GRID_SEPARATION := 18
const GRID_CARD_SIZE := Vector2(176.0, 176.0)
const GRID_ICON_SIZE := Vector2(124.0, 124.0)

const WALKER_TOP_ROW_COUNT := 2
const WALKER_ROW_SEPARATION := 6
const WALKER_COLUMN_SEPARATION := 4
const WALKER_SLOT_SIZE := Vector2(136.0, 182.0)
const WALKER_SPRITE_SIZE := Vector2(108.0, 108.0)
## Corsa massima della camminata; lo slot piu stretto la riduce senza saltare.
const WALKER_TRAVEL := 24.0
const WALKER_TRAVEL_PADDING := 6.0
const WALKER_BOB := 6.0
const WALKER_STEPS_PER_SEGMENT := 12

## Suddivisione del ciclo di camminata: andata, posa leggibile, ritorno, posa.
const WALK_OUT_END := 0.4
const PAUSE_OUT_END := 0.5
const WALK_BACK_END := 0.9

const GOLD := Color(1.0, 0.72, 0.25, 1.0)

@onready var _artwork: TextureRect = %Artwork
@onready var _gallery: CenterContainer = %Gallery

var _animation_active := false
var _phase := 0.0
var _layout := TutorialPageDefinition.ShowcaseLayout.GRID_2X2
var _gallery_icons: Array[TextureRect] = []
var _walkers: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func configure(page: TutorialPageDefinition) -> void:
	_phase = 0.0
	_layout = page.showcase_layout
	_artwork.texture = page.artwork
	_artwork.visible = page.artwork != null
	_gallery.visible = page.artwork == null
	_rebuild_gallery(page)
	_apply_phase(0.0)


## Solo la camminata dei piccioni ha bisogno del clock: sulle altre pagine la
## vetrina è statica e non consuma un frame di processo.
func set_animation_active(active: bool) -> void:
	_animation_active = active and _is_walker_layout()
	set_process(_animation_active)
	if not _animation_active:
		_phase = 0.0
		_apply_phase(0.0)


func is_animation_active() -> bool:
	return _animation_active and is_processing()


## Fase normalizzata del loop, in `[0, 1)`.
func get_animation_phase() -> float:
	return _phase


func set_animation_phase(phase: float) -> void:
	_phase = fposmod(phase, 1.0)
	_apply_phase(_phase)


func get_showcase_layout() -> TutorialPageDefinition.ShowcaseLayout:
	return _layout


func get_showcase_item_count() -> int:
	return _walkers.size() if _is_walker_layout() else _gallery_icons.size()


func get_showcase_textures() -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	if _is_walker_layout():
		for walker in _walkers:
			result.append(walker["source"] as Texture2D)
		return result
	for icon in _gallery_icons:
		result.append(icon.texture)
	return result


## Numero di colonne della matrice di icone, `0` fuori dal layout griglia.
func get_gallery_column_count() -> int:
	if _is_walker_layout() or _gallery.get_child_count() == 0:
		return 0
	var grid := _gallery.get_child(0)
	return (grid as GridContainer).columns if grid is GridContainer else 0


## Conteggio per fila del layout camminatori, es. `[2, 3]`.
func get_walker_row_counts() -> Array[int]:
	var result: Array[int] = []
	if not _is_walker_layout() or _gallery.get_child_count() == 0:
		return result
	for row in _gallery.get_child(0).get_children():
		result.append(row.get_child_count())
	return result


## Etichette testuali nella vetrina: il contratto B54 le vuole assenti.
func get_gallery_label_count() -> int:
	return _count_labels(_gallery)


## Stato animato di ogni elemento, nell'ordine `x, y, scale_x, scale_y, rot, alpha`.
func sample_animation_state() -> PackedFloat32Array:
	var state := PackedFloat32Array()
	if _artwork.visible:
		_append_state(state, _artwork)
	for icon in _gallery_icons:
		_append_state(state, icon)
	for walker in _walkers:
		_append_state(state, walker["sprite"] as TextureRect)
	return state


func sample_animation_state_at(phase: float) -> PackedFloat32Array:
	var restore := _phase
	_apply_phase(fposmod(phase, 1.0))
	var state := sample_animation_state()
	_apply_phase(restore)
	return state


## Scarto massimo dello stato animato lungo un giro completo, inclusa la
## giunzione fra ultimo e primo frame. Un loop continuo resta sotto la soglia.
func measure_loop_discontinuity(samples: int = 240) -> float:
	if samples < 2:
		return 0.0
	var worst := 0.0
	var previous := sample_animation_state_at(0.0)
	for index in range(1, samples + 1):
		var current := sample_animation_state_at(float(index) / float(samples))
		worst = maxf(worst, _state_delta(previous, current))
		previous = current
	return worst


func _process(delta: float) -> void:
	_phase = fposmod(_phase + maxf(delta, 0.0) / LOOP_PERIOD, 1.0)
	_apply_phase(_phase)


func _apply_phase(phase: float) -> void:
	for walker in _walkers:
		_apply_walker_phase(walker, phase)


## Onda ping-pong in `[0, 1]`, continua e con derivata nulla ai due estremi.
func _rise(phase: float) -> float:
	return 0.5 * (1.0 - cos(TAU * phase))


func _apply_walker_phase(walker: Dictionary, phase: float) -> void:
	var sprite := walker["sprite"] as TextureRect
	var slot := walker["slot"] as Control
	if not is_instance_valid(sprite) or not is_instance_valid(slot):
		return
	var local_phase := fposmod(phase + float(walker["offset"]), 1.0)
	var travel := 0.0
	var walk_progress := -1.0
	var facing_right := true
	if local_phase < WALK_OUT_END:
		walk_progress = local_phase / WALK_OUT_END
		travel = smoothstep(0.0, 1.0, walk_progress)
	elif local_phase < PAUSE_OUT_END:
		travel = 1.0
	elif local_phase < WALK_BACK_END:
		walk_progress = (local_phase - PAUSE_OUT_END) / (WALK_BACK_END - PAUSE_OUT_END)
		travel = 1.0 - smoothstep(0.0, 1.0, walk_progress)
		facing_right = false
	else:
		facing_right = false

	var bob := 0.0
	var frame := 0
	if walk_progress >= 0.0:
		var stepped := walk_progress * float(WALKER_STEPS_PER_SEGMENT)
		bob = -WALKER_BOB * _rise(stepped * 0.5)
		frame = int(stepped) % int(walker["frame_count"])

	var span := clampf(
		slot.size.x - WALKER_SPRITE_SIZE.x - WALKER_TRAVEL_PADDING,
		0.0,
		WALKER_TRAVEL
	)
	sprite.position = Vector2(
		(slot.size.x - WALKER_SPRITE_SIZE.x - span) * 0.5 + span * travel,
		(slot.size.y - WALKER_SPRITE_SIZE.y) * 0.5 + bob
	)
	sprite.flip_h = not facing_right
	var atlas := walker["atlas"] as AtlasTexture
	var region := atlas.region
	region.position.x = float(frame) * region.size.x
	atlas.region = region


func _append_state(state: PackedFloat32Array, control: Control) -> void:
	state.append(control.position.x)
	state.append(control.position.y)
	state.append(control.scale.x)
	state.append(control.scale.y)
	state.append(control.rotation)
	state.append(control.modulate.a)


func _state_delta(first: PackedFloat32Array, second: PackedFloat32Array) -> float:
	if first.size() != second.size():
		return INF
	var worst := 0.0
	for index in first.size():
		worst = maxf(worst, absf(first[index] - second[index]))
	return worst


func _count_labels(node: Node) -> int:
	var total := 0
	for child in node.get_children():
		if child is Label or child is RichTextLabel:
			total += 1
		total += _count_labels(child)
	return total


func _is_walker_layout() -> bool:
	return _layout == TutorialPageDefinition.ShowcaseLayout.WALKERS_2_3


func _on_walker_slot_resized() -> void:
	_apply_phase(_phase)


func _rebuild_gallery(page: TutorialPageDefinition) -> void:
	for child in _gallery.get_children():
		_gallery.remove_child(child)
		child.queue_free()
	_gallery_icons.clear()
	_walkers.clear()
	if page.showcase_textures.is_empty():
		return
	if page.showcase_layout == TutorialPageDefinition.ShowcaseLayout.WALKERS_2_3:
		_gallery.add_child(_build_walker_rows(page.showcase_textures))
		return
	_gallery.add_child(_build_icon_grid(page.showcase_textures))


func _build_icon_grid(textures: Array[Texture2D]) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", GRID_SEPARATION)
	grid.add_theme_constant_override("v_separation", GRID_SEPARATION)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for texture in textures:
		grid.add_child(_build_icon_card(texture))
	return grid


func _build_icon_card(texture: Texture2D) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = GRID_CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _make_card_style())

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(center)

	var icon := TextureRect.new()
	icon.custom_minimum_size = GRID_ICON_SIZE
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(icon)
	_gallery_icons.append(icon)
	return card


func _build_walker_rows(textures: Array[Texture2D]) -> VBoxContainer:
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", WALKER_ROW_SEPARATION)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top_row := _build_walker_row()
	var bottom_row := _build_walker_row()
	rows.add_child(top_row)
	rows.add_child(bottom_row)
	for index in textures.size():
		var row := top_row if index < WALKER_TOP_ROW_COUNT else bottom_row
		row.add_child(_build_walker_slot(textures[index], index))
	return rows


func _build_walker_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", WALKER_COLUMN_SEPARATION)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return row


func _build_walker_slot(source: Texture2D, index: int) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = WALKER_SLOT_SIZE
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.clip_contents = true

	var frame_size := _frame_size_for(source)
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(Vector2.ZERO, frame_size)

	var sprite := TextureRect.new()
	sprite.texture = atlas
	sprite.size = WALKER_SPRITE_SIZE
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(sprite)
	slot.resized.connect(_on_walker_slot_resized)

	_walkers.append({
		"slot": slot,
		"sprite": sprite,
		"atlas": atlas,
		"source": source,
		"frame_count": maxi(1, int(round(source.get_width() / maxf(frame_size.x, 1.0)))),
		## Sfasamento fisso: le cinque camminate restano leggibili senza RNG.
		"offset": float(index) * 0.11,
	})
	return slot


func _frame_size_for(source: Texture2D) -> Vector2:
	var height := float(source.get_height())
	var width := float(source.get_width())
	if height <= 0.0 or width <= 0.0:
		return Vector2(48.0, 48.0)
	return Vector2(minf(height, width), height)


func _make_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.055, 0.085, 0.94)
	style.border_color = Color(GOLD, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0.0, 3.0)
	return style
