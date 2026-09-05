---
id: PS-097
titolo: Applica a UpgradeOverlay/BarbRewardOverlay la correzione dell'await orfano di PS-096
tipo: fix
area: tooling
stato: IN VERIFICA
priorita: bassa
dipende_da: [PS-096]
origine: PS-096
creato: 2026-09-05
aggiornato: 2026-09-05
---

# PS-097 — Applica a UpgradeOverlay/BarbRewardOverlay la correzione dell'await orfano di PS-096

## Contesto

[PS-096](../4_to_test/PS-096-await-orfano-grow-to-fit-content-upgrade-card.md)
ha diagnosticato e corretto un errore motore ripetuto in full suite:
`UpgradeCard._grow_to_fit_content()` usava `await get_tree().process_frame`
(due volte) in modo "fire-and-forget" subito dopo `configure()`; se il nodo
veniva liberato (es. `add_child_autofree` a fine test) mentre la coroutine
era ancora sospesa su quel segnale, Godot produceva
`ERROR: Resumed function '_grow_to_fit_content()' after await, but class
instance is gone` — un errore che il consueto guardiano `is_inside_tree()`
non può prevenire, perché scatta nel tentativo stesso di riprendere la
funzione, prima che il suo corpo torni a eseguire. La correzione ha sostituito
i due `await` con due connessioni one-shot a `process_frame`, che si
disconnettono da sole senza errore quando il bersaglio viene liberato.

Verificando la correzione con l'intera suite (`-gdir=res://tests/unit`), gli
errori su `upgrade_card.gd` sono scesi a zero, ma sono emersi **due
occorrenze gemelle dello stesso pattern**, non coperte dall'ambito di
PS-096:

```
ERROR: Resumed function '_defer_reflow_top_margin()' after await, but class
instance is gone. At script: res://scripts/ui/upgrade_overlay.gd:345
ERROR: Resumed function '_defer_reflow_top_margin()' after await, but class
instance is gone. At script: res://scripts/ui/barb_reward_overlay.gd:365
```

Entrambe le funzioni (origine PS-063) hanno la stessa forma:

```gdscript
func _defer_reflow_top_margin() -> void:
	await get_tree().process_frame               # due volte in entrambi i file
	await get_tree().process_frame
	if is_instance_valid(self) and is_inside_tree():
		_reflow_top_margin()
```

chiamata in modo fire-and-forget subito dopo aver mostrato il modal, stesso
principio di `UpgradeCard._grow_to_fit_content()`: stessa causa, stessa
correzione.

## Comportamento atteso

Nessun `ERROR: Resumed function ... after await, but class instance is gone`
compare più nei log durante una corsa `Full` di `tests/unit/`, né da
`upgrade_overlay.gd` né da `barb_reward_overlay.gd`. `_reflow_top_margin()`
continua a essere ricalcolato un paio di frame dopo l'apertura del modal,
esattamente come oggi (PS-063), senza cambi di comportamento percepibile in
gioco.

## Criteri di accettazione

- [x] `UpgradeOverlay._defer_reflow_top_margin()` e
      `BarbRewardOverlay._defer_reflow_top_margin()` non usano più
      `await get_tree().process_frame` fire-and-forget: applicano lo stesso
      schema a connessioni one-shot introdotto da PS-096 in
      `UpgradeCard._grow_to_fit_content()` (o uno schema equivalente che
      risolve la stessa classe di errore).
- [x] Una corsa `Full` di `tests/unit/` non produce più alcuna occorrenza di
      `Resumed function ... after await, but class instance is gone` per
      questi due file.
      *Confermato: 0 occorrenze in tutto il log (era 2 prima della
      correzione, oltre alle 41 già risolte da PS-096).*
- [x] Il ricalcolo del margine superiore dopo l'apertura del modal (PS-063)
      resta invariato nel comportamento osservabile: nessuna regressione sui
      test esistenti che coprono `UpgradeOverlay`/`BarbRewardOverlay`.
      *310/310 test verdi in `Full`, 23641 assert, stesso totale della corsa
      precedente (PS-096).*

## Ambito

- File attesi: `scripts/ui/upgrade_overlay.gd`,
  `scripts/ui/barb_reward_overlay.gd`.
- Non toccare: `scripts/ui/upgrade_card.gd` — già corretto da PS-096; questa
  card applica lo stesso schema, non lo rivede.

## Verifica

- Riprodurre/confermare con una corsa `Full` di `tests/unit/` (non basta
  l'esecuzione isolata dei singoli file, come già osservato in PS-096) e
  controllare che le due occorrenze spariscano dal log.
- Profilo minimo prima della chiusura: `Full`.
- **Eseguito 2026-09-05 (sandbox Linux remoto, Godot 4.7.1 via
  `tools/setup-remote-sandbox.sh`):**
  - Catena `Relevant` combinata per `upgrade_overlay.gd`/
    `barb_reward_overlay.gd` (regole `scripts/upgrades/*` e
    `barb_reward_overlay.gd`/`upgrade_card.gd` di
    `tools/milestone-test-map.json`): `test_b10_upgrade_service.gd`,
    `test_b11_upgrade_overlay.gd`, `test_b12_upgrade_effects.gd`,
    `test_b13_signature_upgrades.gd`, `test_b18j_summer_grill.gd`,
    `test_b27_upgrade_icon_refresh.gd`, `test_b41_weapon_shapes.gd`,
    `test_ps012_barb_specialities.gd`,
    `test_ps036_barb_reward_visual_identity.gd`,
    `test_ps046_level_up_modal_isolation.gd`,
    `test_ps047_upgrade_card_hierarchy.gd`,
    `test_ps059_upgrade_modal_contrast.gd`,
    `test_ps077_barb_speciality_pool_expansion.gd`,
    `test_ps089_ordinary_catalog_meat_audit.gd` → `38/38 passed`, `1859`
    assert.
  - Profilo `Full` (intera `tests/unit/`) → `310/310 passed`, `23641`
    assert, zero `SCRIPT ERROR`/`FATAL EXCEPTION`, **zero** occorrenze di
    `Resumed function ... after await, but class instance is gone` in tutto
    il log (erano 2 su questi due file prima della correzione, sopra alle
    41 già risolte da PS-096).

## Gate manuali

- [ ] Runtime Windows — non eseguito in questa sessione (solo sandbox Linux
      headless, nessun accesso a un ambiente Windows).
- [ ] Validazione statica APK — non eseguita in questa sessione.
- [ ] Runtime fisico Pixel 9 (percorso: non applicabile, è un problema di
      soli test/log) — n/a, nessun comportamento percettibile in gioco
      cambia.
- [ ] Controllo percettivo richiesto: no

Gate Windows/APK lasciati esplicitamente aperti (nessun ambiente disponibile
in questa sessione), stesso principio già applicato in PS-096: la
correzione è puro ordine di dispatch di una coroutine GDScript, identico su
ogni piattaforma che esegue lo stesso motore.

## Decisioni

- **2026-09-05 — Aperta come effetto collaterale della verifica di PS-096,
  non come sua estensione.** Il contratto di card-risolvi impone di isolare
  problemi adiacenti in una card separata invece di allargare quella in
  corso; l'ambito di PS-096 è dichiarato esplicitamente limitato a
  `upgrade_card.gd`.
- **2026-09-05 — Dipende da PS-096.** Riusa lo schema di correzione appena
  validato lì (connessioni one-shot a `process_frame` invece di `await`
  fire-and-forget); non ha senso implementarla prima che PS-096 sia
  verificata.
- **2026-09-05 — Correzione applicata identica a entrambi i file.**
  `UpgradeOverlay._defer_reflow_top_margin()` e
  `BarbRewardOverlay._defer_reflow_top_margin()` avevano entrambe due
  `await get_tree().process_frame` (il Contesto originale della card
  riportava erroneamente "x1" per `barb_reward_overlay.gd`, corretto qui:
  la lettura iniziale era troncata sul secondo `await`). Riscritte entrambe
  come catena di due connessioni one-shot a `process_frame`
  (`_on_first_reflow_frame_elapsed`, `_on_second_reflow_frame_elapsed`),
  stesso schema di PS-096, senza toccare `_reflow_top_margin()` né alcun
  altro comportamento osservabile.
- **2026-09-05 — Nessuna nuova occorrenza gemella trovata.** La corsa `Full`
  post-correzione non mostra alcuna occorrenza residua dell'errore in
  nessun altro file: la classe di bug risulta esaurita per questi tre
  punti (`upgrade_card.gd` via PS-096, questi due via PS-097).

## Documenti sincronizzati

- [ ] Nessuno atteso: è una correzione di affidabilità dei test/log, non un
      contratto di prodotto.

## Note

Comandi usati per la scoperta (sandbox Linux remoto, Godot 4.7.1 via
`tools/setup-remote-sandbox.sh`):

```
xvfb-run --auto-servernum --server-args="-screen 0 1280x720x24" \
  godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/unit -gexit
```
