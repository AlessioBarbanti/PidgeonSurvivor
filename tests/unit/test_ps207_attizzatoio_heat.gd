extends GutGameplayTest

## PS-207 — L'Attizzatoio di Lollo si arroventa col volo: danno ×0,7 alla
## bocca, ×1,5 dopo 500 px, colore dalla brace scura al bianco rovente e scia
## che si allunga con la velocità. Le altre armi restano come prima.

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/projectile.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const ATTIZZATOIO: WeaponDefinition = preload("res://data/weapons/attizzatoio.tres")
const WEAPONS_DIR := "res://data/weapons/"
const SHOT_DAMAGE := 20.0
const STEP := 1.0 / 120.0
const FACTOR_TOLERANCE := 0.01

var _fixture: Node2D
var _controller: RunController


func before_each() -> void:
	_fixture = Node2D.new()
	_controller = RunController.new()
	_controller.set_process(false)
	_fixture.add_child(_controller)
	add_child_autofree(_fixture)
	assert_true(_controller.start_run(2207), "La fixture deve avviare la run.")


func test_damage_heats_up_with_distance() -> void:
	var parameters := ATTIZZATOIO.effect_parameters
	assert_eq(float(parameters.get("heat_start_damage_factor", 0.0)), 0.7, "Danno iniziale nei dati.")
	assert_eq(float(parameters.get("heat_end_damage_factor", 0.0)), 1.5, "Danno finale nei dati.")
	assert_eq(float(parameters.get("heat_full_distance", 0.0)), 500.0, "Distanza di arroventamento nei dati.")

	var projectile := _spawn(ATTIZZATOIO)
	var start := projectile.global_position
	assert_true(projectile.is_heated(), "L'Attizzatoio deve arroventarsi.")
	assert_almost_eq(projectile._current_hit_damage(), SHOT_DAMAGE * 0.7, SHOT_DAMAGE * FACTOR_TOLERANCE, "Alla bocca: 70%.")
	var cold_color := _sprite_color(projectile)
	var cold_trail := projectile.get_heat_trail_length()

	_fly_to(projectile, 250.0)
	var flown := projectile.global_position.distance_to(start)
	assert_almost_eq(flown, 250.0, 10.0, "Il colpo deve aver volato ~250 px.")
	assert_almost_eq(
		projectile.get_heat_damage_factor(), lerpf(0.7, 1.5, flown / 500.0), FACTOR_TOLERANCE,
		"Il fattore segue i px volati."
	)
	assert_almost_eq(projectile.get_heat_damage_factor(), 1.1, 0.02, "A 250 px: circa 110%.")

	_fly_to(projectile, 500.0)
	assert_almost_eq(projectile.get_heat_damage_factor(), 1.5, FACTOR_TOLERANCE, "A 500 px: 150%.")
	_fly_to(projectile, 700.0)
	assert_almost_eq(projectile._current_hit_damage(), SHOT_DAMAGE * 1.5, SHOT_DAMAGE * FACTOR_TOLERANCE, "Oltre: resta 150%.")

	var hot_color := _sprite_color(projectile)
	assert_true(hot_color.r > cold_color.r and hot_color.g > cold_color.g * 2.0, "Da brace scura a bianco rovente.")
	assert_true(cold_color.is_equal_approx(Projectile.HEAT_COLD_COLOR), "Parte brace scura.")
	assert_true(hot_color.is_equal_approx(Projectile.HEAT_HOT_COLOR), "Arriva bianco rovente.")
	assert_true(projectile.get_heat_trail_length() > cold_trail * 1.5, "La scia si allunga con la velocità.")
	print("PS207_HEAT_CURVE flown250=%.1f cold_trail=%.1f hot_trail=%.1f" % [
		flown, cold_trail, projectile.get_heat_trail_length()
	])


func test_real_hit_and_speciality_damage_carry_the_heat() -> void:
	var projectile := _spawn(ATTIZZATOIO)
	assert_true(projectile.configure_shape_effects(3, 0.8, false, 0.0, 0.0), "Perforazione di Barb.")
	_fly_to(projectile, 500.0)
	var damages: Array[float] = []
	projectile.hit_processed.connect(func(_target: BaseEnemy, hit_damage: float) -> void: damages.append(hit_damage))
	for index in 2:
		var enemy := ENEMY_SCENE.instantiate() as BaseEnemy
		_fixture.add_child(enemy)
		enemy.set_physics_process(false)
		enemy.get_health_component().set_health_max(1000.0)
		enemy.get_health_component().reset_to_max()
		assert_true(projectile.try_hit(enemy), "Il colpo perforante deve colpire il nemico %d." % index)
	assert_eq(damages.size(), 2, "Due colpi registrati.")
	if damages.size() == 2:
		assert_almost_eq(damages[0], SHOT_DAMAGE * 1.5, 0.05, "Primo colpo: arroventato.")
		assert_almost_eq(damages[1], SHOT_DAMAGE * 0.8 * 1.5, 0.05, "Il calo della perforazione resta, sotto l'arroventamento.")

	var chained := _spawn(ATTIZZATOIO)
	var targeting := TargetingSystem.new()
	_fixture.add_child(targeting)
	assert_true(chained.configure_signature_effects(true, 2, 0.8, 100.0, 0.0, targeting), "Catena di Barb.")
	assert_almost_eq(chained._current_hit_damage(), SHOT_DAMAGE * 0.7, 0.05, "Anche la catena parte fredda.")
	print("PS207_SPECIALITIES_OK")


func test_other_weapons_are_unchanged() -> void:
	var checked := 0
	for file_name in DirAccess.get_files_at(WEAPONS_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var definition := load(WEAPONS_DIR + file_name) as WeaponDefinition
		if definition == null or definition.id == ATTIZZATOIO.id:
			continue
		var projectile := _spawn(definition)
		if projectile == null:
			continue
		checked += 1
		assert_false(projectile.is_heated(), "%s non si arroventa." % definition.id)
		projectile._physics_process(0.3)
		assert_almost_eq(projectile._current_hit_damage(), SHOT_DAMAGE, FLOAT_TOLERANCE, "%s: danno invariato." % definition.id)
		assert_eq(_sprite_color(projectile), Color.WHITE, "%s: colore invariato." % definition.id)
		assert_eq(projectile.get_heat_trail_length(), 0.0, "%s: nessuna scia di calore." % definition.id)
	assert_true(checked >= 8, "Controllate le altre armi (%d)." % checked)
	print("PS207_ATTIZZATOIO_HEAT_OK")


func _spawn(definition: WeaponDefinition) -> Projectile:
	var projectile := PROJECTILE_SCENE.instantiate() as Projectile
	_fixture.add_child(projectile)
	projectile.set_physics_process(false)
	assert_true(projectile.initialize(
		Vector2.RIGHT, SHOT_DAMAGE, definition.projectile_speed, definition.projectile_lifetime,
		definition.projectile_radius, _controller
	), "%s: initialize." % definition.id)
	var trajectory := StringName(definition.effect_parameters.get("trajectory", Projectile.TRAJECTORY_STRAIGHT))
	var parameters := definition.effect_parameters.duplicate()
	if trajectory == Projectile.TRAJECTORY_ORBIT and not parameters.has("radius"):
		parameters["radius"] = 60.0
	if not projectile.configure_trajectory(trajectory, parameters, _fixture):
		assert_true(false, "%s: traiettoria non configurabile." % definition.id)
		return null
	return projectile


func _fly_to(projectile: Projectile, distance: float) -> void:
	while projectile._distance_travelled < distance and not projectile.is_spent():
		projectile._physics_process(STEP)


func _sprite_color(projectile: Projectile) -> Color:
	return projectile._projectile_sprite.modulate
