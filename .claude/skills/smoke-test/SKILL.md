---
name: smoke-test
description: Scrivi, aggiorna o diagnostica un test GUT deterministico di Pidgeon Survivor in tests/unit/. Usala quando serve una prova automatica di un comportamento Godot, quando un test fallisce o risulta instabile, o quando una slice deve essere coperta da un test verificabile.
---

# Test GUT

I test GUT sono l'unica prova automatica del progetto: script `extends
GutTest` (o `extends GutGameplayTest` per chi instanzia la scena di gioco),
deterministici, eseguiti tutti insieme in un solo processo Godot per profilo
(`addons/gut/`, vendored, MIT).

## Contratto

- File `tests/unit/test_<nome>.gd`. Per una slice della serie B usa il
  prefisso dell'ID nel nome (`test_b45_role_identity.gd`) così che
  `-Profile Focused` lo scopra da solo; se il nome non porta l'ID, basta che
  almeno un messaggio di asserzione lo citi (`Find-FocusedGutTests` fa grep
  sul contenuto, non solo sul nome file).
- `extends GutTest` per logica pura senza scena; `extends GutGameplayTest`
  (base condivisa in [tests/unit/helpers/gameplay_test.gd](../../../tests/unit/helpers/gameplay_test.gd))
  per chi ha bisogno di `instantiate_movement_slice()`, `assert_vector_near`,
  `assert_rect_near`, `assert_rect_inside`, o dei costruttori `make_touch_event`
  /`make_drag_event`/`make_key_event`/`make_joy_button_event`.
- Un metodo `func test_<comportamento>() -> void:` per ogni comportamento
  osservabile indipendente. Fasi che condividono stato mutato in sequenza
  (es. rank che si accumulano, run che passa per più fasi) restano in un solo
  metodo; fasi con fixture indipendenti (ogni `_build_context()` separato
  nell'originale) diventano metodi `test_*` separati per isolamento e
  messaggi di fallimento più chiari.
- Asserzioni con messaggio che dice **cosa deve essere vero**, non un
  confronto grezzo: `assert_eq(actual, expected, "Il rank deve salire di uno.")`,
  non `assert_eq(actual, expected)`.
- Nessuna dipendenza da tempo reale, ordine casuale non seminato, rete o
  interazione. Avanza i frame con `await wait_process_frames(n)` /
  `await wait_physics_frames(n)`, semina il RNG.
- Verifica solo risorse incluse nel PCK/APK. I `ASSET-MANIFEST.md` e i master
  `hd/` sono documentazione: possono essere controllati da un test dedicato,
  mai spacciati per una verifica visiva o su device.
- Un evento (`Input.action_press`, `Input.parse_input_event` con un asse
  fisico) che non torna esplicitamente a neutro prima della fine del test
  persiste nel singleton `Input` per l'intero processo GUT, non solo per la
  durata del test: può corrompere un test successivo che legge la stessa
  azione. Rilascia sempre quello che hai premuto.

## Scheletro

```gdscript
extends GutGameplayTest


func test_definition_is_valid() -> void:
	var definition := load("res://data/bosses/first_boss.tres") as BossDefinition
	assert_true(definition != null and definition.is_valid(), "La definizione deve essere valida.")


func test_composed_behavior() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	assert_true(controller != null, "La scena deve esporre RunController.")
	if controller == null:
		return
	controller.set_process(false)
	# ... asserzioni sul comportamento composto ...
	controller.prepare_restart()
```

Guarda un vicino reale prima di scrivere: [test_b54_tutorial_flow.gd](../../../tests/unit/test_b54_tutorial_flow.gd)
per il flusso UI, [test_b14_game_director.gd](../../../tests/unit/test_b14_game_director.gd)
per spawn e Boss (diviso in tre `test_*` indipendenti), [test_b12_upgrade_effects.gd](../../../tests/unit/test_b12_upgrade_effects.gd)
per progressione e stacking, [test_b44_state_tells.gd](../../../tests/unit/test_b44_state_tells.gd)
per quattro fixture indipendenti nello stesso file.

## Esecuzione

```powershell
# Tramite il runner, con cache e scoperta del test per milestone.
.\tools\run-milestone-checks.ps1 -Milestone B99 -Profile Focused

# Diretto, quando serve il log grezzo o una risoluzione specifica.
godot_console --headless --path . --resolution 1280x720 `
  -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_b99_contract.gd `
  -gexit -gjunit_xml_file=<path>.xml
```

## Regole di igiene

1. Dopo aver aggiunto uno script con `class_name` o un asset importato,
   rinfresca la cache dell'editor (`-RefreshEditor`, o `godot_console
   --headless --editor --path . --quit-after 60`) prima del test: altrimenti
   fallisce per risoluzione simboli, non per contratto. Questo genera anche
   il `.uid` del nuovo file, da mettere in stage insieme allo script.
2. Registra il nuovo file in [tools/milestone-test-map.json](../../../tools/milestone-test-map.json)
   associandolo ai percorsi runtime che deve proteggere, altrimenti `Relevant`
   non lo eseguirà mai.
3. Un test instabile è un bug del test: rendi deterministica la causa (frame
   attesi, seed, tolleranze esplicite, azioni input rilasciate a fine test),
   non allargare la tolleranza fino a farlo passare. Verifica sempre in
   isolamento (`-gtest=` sul solo file) e poi dentro la suite intera
   (`-gdir=res://tests/unit -ginclude_subdirs`): uno stato globale lasciato
   sporco da un test può rompere solo quello successivo nello stesso
   processo, mai visibile eseguendo il file da solo.
4. Non usare screenshot o test automatici al posto di un controllo
   percettivo, geometrico o su device richiesto dal proprietario.
