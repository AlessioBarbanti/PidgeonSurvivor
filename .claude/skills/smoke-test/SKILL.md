---
name: smoke-test
description: Scrivi, aggiorna o diagnostica uno smoke test di integrazione headless di Pidgeon Survivor in tests/integration/. Usala quando serve una prova deterministica di un comportamento Godot, quando uno smoke fallisce o risulta instabile, o quando una slice deve essere coperta da un marker verificabile.
---

# Smoke test di integrazione

Gli smoke sono l'unica prova automatica del progetto: script `SceneTree`
headless, deterministici, con un marker unico.

## Contratto

- File `tests/integration/_<nome>_smoke.gd`, `extends SceneTree`.
- Un marker unico stampato solo al successo, `<NOME>_SMOKE_OK`. Per una slice
  della serie B usa il prefisso dell'ID (`B45_ROLE_IDENTITY_SMOKE_OK`) così che
  `-Profile Focused` lo scopra da solo.
- In caso di errore: messaggio diagnostico che dice **valore atteso e valore
  osservato**, poi uscita con codice non nullo (`quit(1)`).
- Nessuna dipendenza da tempo reale, ordine casuale non seminato, rete o
  interazione. Avanza i frame in modo esplicito e semina il RNG.
- Verifica solo risorse incluse nel PCK/APK. I `ASSET-MANIFEST.md` e i master
  `hd/` sono documentazione: possono essere controllati da smoke di repository,
  mai da marker runtime.

## Scheletro

```gdscript
extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)


func _initialize() -> void:
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	var slice := MOVEMENT_SLICE_SCENE.instantiate()
	root.add_child(slice)
	await process_frame

	if not _check(slice):
		push_error("B99_SMOKE_FAIL: <atteso> vs <osservato>")
		quit(1)
		return

	print("B99_CONTRACT_SMOKE_OK")
	quit(0)
```

Guarda un vicino reale prima di scrivere: [_b54_tutorial_flow_smoke.gd](../../../tests/integration/_b54_tutorial_flow_smoke.gd)
per il flusso UI, [_game_director_smoke.gd](../../../tests/integration/_game_director_smoke.gd)
per spawn e Boss, [_upgrade_effects_smoke.gd](../../../tests/integration/_upgrade_effects_smoke.gd)
per progressione e stacking.

## Esecuzione

```powershell
# Tramite il runner, con cache e scoperta del marker.
.\tools\run-milestone-checks.ps1 -Milestone B99 -Profile Focused

# Diretto, quando serve il log grezzo o una risoluzione specifica.
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_b99_contract_smoke.gd
```

## Regole di igiene

1. Dopo aver aggiunto uno script con `class_name` o un asset importato,
   rinfresca la cache dell'editor (`-RefreshEditor`) prima dello smoke:
   altrimenti fallisce per risoluzione simboli, non per contratto.
2. Registra il nuovo file in [tools/milestone-test-map.json](../../../tools/milestone-test-map.json)
   associandolo ai percorsi runtime che deve proteggere, altrimenti `Relevant`
   non lo eseguirà mai.
3. Uno smoke instabile è un bug dello smoke: rendi deterministica la causa
   (frame attesi, seed, tolleranze esplicite), non allargare la tolleranza fino
   a farlo passare.
4. Non usare screenshot o smoke al posto di un controllo percettivo, geometrico
   o su device richiesto dal proprietario.
