extends GutGameplayTest

## PS-189: il godmode e' una facilitazione di sola diagnosi prestazionale, che
## sul device prende il posto della cura continua applicata dalla sonda
## headless. Il rischio da coprire e' che resti acceso quando nessuno l'ha
## chiesto: il caso negativo vale quanto quello positivo.

const GODMODE_FLAG := "user://ps189_godmode.flag"


func after_each() -> void:
	_remove_flag()


func test_godmode_is_off_without_flag() -> void:
	var slice := await instantiate_movement_slice()
	var health := _player_health(slice)
	health.clear_invulnerability()
	await wait_process_frames(2)
	assert_false(
		health.is_invulnerable(),
		"Senza flag nessuno deve rinnovare gli i-frame del Player."
	)
	assert_true(health.take_damage(1.0), "Il Player deve poter subire danno.")


func test_godmode_flag_keeps_the_player_untouchable() -> void:
	_write_flag()
	var slice := await instantiate_movement_slice()
	var health := _player_health(slice)
	health.clear_invulnerability()
	await wait_process_frames(2)
	assert_true(
		health.is_invulnerable(),
		"Con il flag gli i-frame devono essere rinnovati a ogni frame."
	)
	assert_false(health.take_damage(1.0), "Il colpo deve essere annullato.")
	# La facilitazione non deve toccare i valori dichiarati del personaggio.
	assert_eq(health.health_current, health.health_max, "HP invariati dalla facilitazione.")


func _player_health(slice: Control) -> HealthComponent:
	var player := slice.call("get_player") as Player
	assert_not_null(player, "La run deve avere un Player.")
	return player.get_health_component()


func _write_flag() -> void:
	var file := FileAccess.open(GODMODE_FLAG, FileAccess.WRITE)
	assert_not_null(file, "Il flag di diagnosi deve essere scrivibile.")
	if file != null:
		file.store_line("ps189")
		file.close()


func _remove_flag() -> void:
	if FileAccess.file_exists(GODMODE_FLAG):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GODMODE_FLAG))
