extends GutGameplayTest

## PS-025: verifica che l'avvertimento Boss sia visibilmente più grande della
## versione precedente (font_size), restando dentro la safe area, sotto il
## cronometro e senza sovrapporsi a XP, HP, pausa o controllo abilità, su
## 16:9, 20:9 e 4:3. Il countdown numerico riusa la stessa etichetta, quindi
## eredita automaticamente l'aumento. La lettura percettiva reale resta un
## gate manuale (vedi card).

const PREVIOUS_FONT_SIZE := 16
const WARNING_START_SECONDS := 105.0
const ASPECT_PROFILES: Dictionary = {
	"16:9": Vector2i(1280, 720),
	"20:9": Vector2i(1600, 720),
	"4:3": Vector2i(960, 720),
}


func test_ps025_boss_warning_is_larger_and_contained() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var director := movement_slice.get_game_director() as GameDirector
	var hud := movement_slice.get_hud() as GameHud
	var arena_layout := movement_slice.get_arena_layout() as ArenaLayout
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	assert_true(
		(
			controller != null and director != null and hud != null
			and arena_layout != null and spawner != null
		),
		"PS-025 richiede RunController, GameDirector, HUD, ArenaLayout ed EnemySpawner dalla scena composta."
	)
	if controller == null or director == null or hud == null or arena_layout == null or spawner == null:
		return

	controller.set_process(false)
	spawner.set_process(false)
	_advance_to(controller, WARNING_START_SECONDS)
	assert_true(hud.is_boss_warning_visible(), "A 01:45 di clock RUNNING l'avvertimento deve essere visibile.")

	assert_true(
		hud.get_boss_warning_font_size() > PREVIOUS_FONT_SIZE,
		(
			"Il font dell'avvertimento (%d) deve essere piu' grande della versione precedente (%d)."
			% [hud.get_boss_warning_font_size(), PREVIOUS_FONT_SIZE]
		)
	)

	for aspect_name in ASPECT_PROFILES:
		var viewport_size: Vector2i = ASPECT_PROFILES[aspect_name]
		get_tree().root.content_scale_size = viewport_size
		get_tree().root.size = viewport_size
		await wait_process_frames(2)
		arena_layout.refresh_layout()
		await wait_process_frames(1)
		_assert_contained(hud, arena_layout, aspect_name)


func _assert_contained(hud: GameHud, arena_layout: ArenaLayout, profile_name: String) -> void:
	var warning_rect := hud.get_boss_warning_rect()
	assert_rect_inside(
		warning_rect, arena_layout.get_safe_area_rect(),
		"%s: l'avvertimento deve restare nella safe area." % profile_name
	)
	var timer_rect := hud.get_timer_slot_rect()
	assert_true(
		warning_rect.position.y >= timer_rect.end.y - 0.5,
		(
			"%s: l'avvertimento deve iniziare sotto il cronometro (timer=%s, avvertimento=%s)."
			% [profile_name, timer_rect, warning_rect]
		)
	)
	for occupied_rect in [
		hud.get_experience_panel_rect(),
		hud.get_health_panel_rect(),
		hud.get_pause_button_rect(),
		hud.get_ability_panel_rect(),
	]:
		assert_false(
			warning_rect.intersects(occupied_rect),
			"%s: l'avvertimento non deve sovrapporsi a XP, HP, pausa o controllo abilità." % profile_name
		)


func _advance_to(controller: RunController, target_time: float) -> void:
	controller._process(maxf(target_time - controller.get_run_time(), 0.0))
