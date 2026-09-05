---
id: PS-096
titolo: Diagnostica l'await orfano di UpgradeCard._grow_to_fit_content in full suite
tipo: fix
area: tooling
stato: IN VERIFICA
priorita: bassa
dipende_da: []
origine: PS-095
creato: 2026-09-04
aggiornato: 2026-09-05
---

# PS-096 — Diagnostica l'await orfano di UpgradeCard._grow_to_fit_content in full suite

## Contesto

Durante la verifica di [PS-095](../4_to_test/PS-095-audita-spawn-nemici-sempre-fuori-vista.md)
(profilo `Full`, l'intera cartella `tests/unit/`), `test_b27_upgrade_icon_refresh.gd`
(`test_upgrade_card_icons_stay_centered_and_scaled_across_viewports`) ha
fallito con una raffica di errori motore ripetuti:

```
ERROR: Resumed function '_grow_to_fit_content()' after await, but class
instance is gone. At script: res://scripts/ui/upgrade_card.gd:77
```

Lo stesso test, eseguito **da solo** con lo stesso profilo, passa in modo
pulito (185 assert verdi). Il fallimento dipende quindi dall'ordine/contesto
di esecuzione nella suite completa, non dal contenuto del test né da
`scripts/game/enemy_spawner.gd` (l'unico file toccato da PS-095): nessun
test della catena `Relevant` di PS-095 tocca `UpgradeCard` o
`upgrade_card.gd`.

## Comportamento atteso

`test_b27_upgrade_icon_refresh.gd` passa in modo deterministico sia isolato
sia dentro una corsa `Full` dell'intera cartella `tests/unit/`, senza errori
`SCRIPT ERROR`/`FATAL EXCEPTION` residui da coroutine riprese su istanze
liberate.

## Criteri di accettazione

- [x] La causa dell'await orfano in `UpgradeCard._grow_to_fit_content()`
      (`scripts/ui/upgrade_card.gd:77`) è identificata: quale altro test
      (o quale ordine di esecuzione) lascia un nodo `UpgradeCard` in attesa
      su un `await` e poi lo libera prima che la coroutine riprenda.
      *Vedi Decisioni: la causa è generica (qualunque test che libera una
      carta configurata via `add_child_autofree` prima che la coroutine
      concluda), non un singolo test specifico.*
- [x] `test_b27_upgrade_icon_refresh.gd` passa in modo ripetibile dentro una
      corsa `Full` di `tests/unit/`, non solo isolato.
      *Confermato: `Full` → 310/310, zero occorrenze dell'errore su
      `upgrade_card.gd`.*
- [x] Se la causa è nel test (setup/teardown che libera nodi con coroutine
      pendenti), la correzione resta nel test o nel suo fixture. Se la causa
      è in `UpgradeCard`/`upgrade_card.gd` (manca una guardia
      `is_instance_valid`/`tree_exiting` prima di riprendere dopo l'await),
      la correzione resta lì.
      *La causa è in `upgrade_card.gd`: vedi Decisioni.*

## Ambito

- File attesi: `tests/unit/test_b27_upgrade_icon_refresh.gd`,
  `scripts/ui/upgrade_card.gd`.
- Non toccare: `scripts/game/enemy_spawner.gd` e gli altri file di PS-095 —
  il problema è preesistente e indipendente da quella card.

## Verifica

- Riprodurre con una corsa `Full` di `tests/unit/` (non basta l'esecuzione
  isolata del singolo file) e confermare che l'errore sparisce.
- Profilo minimo prima della chiusura: `Full`.
- **Eseguito 2026-09-05 (sandbox Linux remoto, Godot 4.7.1 via
  `tools/setup-remote-sandbox.sh`):**
  - `test_b27_upgrade_icon_refresh.gd` isolato → `1/1 passed`, 185 assert
    (già verde prima e dopo, come atteso).
  - `test_b27_upgrade_icon_refresh.gd`, `test_b11_upgrade_overlay.gd`,
    `test_ps036_barb_reward_visual_identity.gd`,
    `test_ps046_level_up_modal_isolation.gd`,
    `test_ps047_upgrade_card_hierarchy.gd`, `test_ps059_upgrade_modal_contrast.gd`
    (catena `Relevant` per `scripts/ui/upgrade_card.gd` da
    `tools/milestone-test-map.json`) → `15/15 passed`, `567` assert.
  - Profilo `Full` (intera `tests/unit/`) → `310/310 passed`, `23641`
    assert, zero `SCRIPT ERROR`/`FATAL EXCEPTION`, **zero** occorrenze di
    `Resumed function '_grow_to_fit_content()' ... upgrade_card.gd` (erano
    41 prima della correzione).

## Gate manuali

- [ ] Runtime Windows — non eseguito in questa sessione (solo sandbox Linux
      headless, nessun accesso a un ambiente Windows).
- [ ] Validazione statica APK — non eseguita in questa sessione.
- [ ] Runtime fisico Pixel 9 (percorso: non applicabile, è un problema di
      soli test) — n/a, nessun comportamento percettibile in gioco cambia.
- [ ] Controllo percettivo richiesto: no

Gate Windows/APK lasciati esplicitamente aperti (nessun ambiente disponibile
in questa sessione), coerente con l'onestà dei gate del progetto, anche se
la correzione non tocca alcun percorso di codice specifico per piattaforma:
è puro ordine di dispatch di una coroutine GDScript, identico su ogni
piattaforma che esegue lo stesso motore.

## Decisioni

- **2026-09-04 — Aperta come effetto collaterale scoperto, non come parte di
  PS-095.** Il contratto di card-risolvi impone di isolare problemi
  adiacenti in una card separata invece di allargare quella in corso;
  PS-095 tocca solo `enemy_spawner.gd` e non ha relazione con `UpgradeCard`.
- **2026-09-05 — Causa: `await` fire-and-forget su un segnale del
  `SceneTree`, non un test specifico.** `_grow_to_fit_content()` chiamava
  `await get_tree().process_frame` due volte in modo "fire-and-forget"
  subito dopo `configure()`, senza che nulla ne tracciasse il completamento.
  `add_child_autofree()` di GUT libera i nodi di un test con `.free()`
  **sincrono** (non `queue_free()` differito) alla fine dello stesso test:
  qualunque test che chiama `UpgradeCard.configure()` (direttamente o
  tramite `UpgradeOverlay`) senza attendere almeno 2 frame di processo prima
  di terminare libera la carta mentre la sua coroutine è ancora sospesa.
  Quando ciò accade esattamente durante l'emissione del segnale globale
  `process_frame` a cui la coroutine è agganciata, il tentativo di
  riprendere la funzione fallisce con l'errore diagnosticato — un guardiano
  `is_inside_tree()` dopo l'`await` non basta perché il crash avviene nel
  meccanismo stesso di ripresa della coroutine, prima che il corpo della
  funzione torni a eseguire. Non è stato possibile isolare un singolo test
  "colpevole" in un repro minimale (tentativi con nodi sintetici e con
  `UpgradeCard` reale, sia con `queue_free()` sia con `.free()` immediati,
  non hanno riprodotto l'errore fuori dal contesto della suite completa):
  la causa resta quindi caratterizzata a livello di classe di bug
  (fire-and-forget + `add_child_autofree`), verificata sul sintomo reale
  (corsa `Full`) invece che su un repro isolato.
- **2026-09-05 — Correzione: connessioni one-shot a `process_frame` invece
  di `await` ripetuto.** `_grow_to_fit_content()` è stata riscritta come
  catena di due passi (`_on_first_grow_frame_elapsed`,
  `_on_second_grow_frame_elapsed`) collegati con
  `get_tree().process_frame.connect(_metodo, CONNECT_ONE_SHOT)` invece di
  `await get_tree().process_frame`. Una connessione a segnale, quando
  l'oggetto bersaglio viene liberato, si disconnette da sola senza invocare
  nulla — a differenza della ripresa di una coroutine sospesa su `await`,
  che tenta di eseguire su un'istanza già distrutta. Il guardiano
  `is_instance_valid(self) and is_inside_tree()` resta a inizio di ciascun
  passo per lo stesso motivo di prima (nodo ancora vivo ma fuori
  dall'albero). Verificato: 41 → 0 occorrenze dell'errore su
  `upgrade_card.gd` in una corsa `Full`, nessuna regressione (310/310
  test verdi, stesso conteggio assert totale della corsa precedente).
- **2026-09-05 — Trovate due occorrenze gemelle fuori scope, aperte come
  PS-097.** La stessa correzione ha smascherato lo stesso identico pattern
  in `UpgradeOverlay._defer_reflow_top_margin()` e
  `BarbRewardOverlay._defer_reflow_top_margin()` (origine PS-063), non
  coperte dall'ambito di questa card (limitato a `upgrade_card.gd`).
  Aperta [PS-097](../2_to_do/PS-097-await-orfano-defer-reflow-top-margin.md)
  invece di allargare questa.

## Documenti sincronizzati

- [ ] Nessuno atteso: è una correzione di affidabilità dei test, non un
      contratto di prodotto.

## Note

Riprodotto con:
```
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```
in un sandbox Linux headless (Godot 4.7.1, `tools/setup-remote-sandbox.sh`).
Non riprodotto con:
```
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_b27_upgrade_icon_refresh.gd -gexit
```
(1/1 passed, 185 assert), né con vari tentativi di repro minimale isolato
(nodi sintetici e `UpgradeCard` reale, liberati con `queue_free()`/`.free()`
subito dopo l'avvio della coroutine, anche ripetuti su 20 istanze in un
unico file di test): l'errore emerge solo nel contesto della suite `Full`
completa (104 script). La verifica di questa card si è quindi appoggiata
sulla corsa `Full` reale come prova, invece che su un repro isolato.
