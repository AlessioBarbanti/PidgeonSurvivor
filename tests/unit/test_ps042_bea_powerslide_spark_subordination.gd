extends GutTest

## PS-042 — Le scintille della Powerslide di Bea non devono mai leggere piu'
## opache del nastro di fuoco su cui poggiano, ed evitano il giallo piatto
## a favore di una tinta della palette di `fire_trail.png`. Asserisce sulle
## costanti esposte da `FireZTrail`, non sul testo del sorgente ne' su un
## rendering, per restare deterministico (vedi Verifica della card).
## Il controllo percettivo sull'uniformita' della fiammata resta un gate
## manuale del proprietario.

const LEGACY_SPARK_COLOR := Color(1.0, 0.88, 0.36)
const LEGACY_SPARK_SIZE_MIN := 2.0
const LEGACY_SPARK_SIZE_MAX := 4.0


func test_spark_alpha_never_reaches_stamp_alpha() -> void:
	var max_spark_alpha := FireZTrail.SPARK_ALPHA_BASE + FireZTrail.SPARK_ALPHA_SWING
	assert_true(
		max_spark_alpha < FireZTrail.STAMP_ALPHA,
		"L'alpha massimo di una scintilla (%.3f) deve restare sotto quello del nastro (%.3f)."
			% [max_spark_alpha, FireZTrail.STAMP_ALPHA]
	)


func test_spark_tint_is_no_longer_flat_yellow() -> void:
	assert_ne(
		FireZTrail.SPARK_COLOR,
		LEGACY_SPARK_COLOR,
		"La tinta della scintilla deve abbandonare il giallo piatto originale."
	)


func test_spark_size_is_smaller_than_before() -> void:
	var new_size_min := FireZTrail.SPARK_SIZE_BASE
	var new_size_max := FireZTrail.SPARK_SIZE_BASE + 2.0 * FireZTrail.SPARK_SIZE_STEP
	assert_true(
		new_size_min < LEGACY_SPARK_SIZE_MIN and new_size_max < LEGACY_SPARK_SIZE_MAX,
		"Il range di dimensione (%.2f-%.2f) deve restare sotto quello precedente (%.1f-%.1f)."
			% [new_size_min, new_size_max, LEGACY_SPARK_SIZE_MIN, LEGACY_SPARK_SIZE_MAX]
	)


func test_visual_family_and_particle_budget_are_unchanged() -> void:
	assert_eq(
		FireZTrail.VISUAL_FAMILY_ID,
		&"powerslide_ribbon_and_sparks",
		"La famiglia visiva deve restare la stessa: le scintille restano, non spariscono."
	)
	assert_eq(
		FireZTrail.VISUAL_PARTICLE_COUNT,
		16,
		"Il conteggio delle particelle non e' nell'ambito di questa card."
	)


func test_legacy_straight_edged_polyline_has_not_returned() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/abilities/fire_z_trail.gd")
	assert_true(not source.is_empty(), "Deve essere possibile leggere lo script della Powerslide.")
	assert_true(
		not source.contains("draw_polyline"),
		"PS-027: il bordo dritto rimosso non deve tornare con questa card."
	)
