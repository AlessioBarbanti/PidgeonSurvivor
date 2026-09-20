---
id: PS-195
titolo: Rendi casuale il personaggio evidenziato al primo ingresso nel selettore
tipo: ux
area: ui
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-09-18
aggiornato: 2026-09-20
---

# PS-195 — Rendi casuale il personaggio evidenziato al primo ingresso nel selettore

## Contesto

Il proprietario segnala che, premendo "Nuova Partita", il personaggio
evidenziato all'apertura del selettore è sempre Magno. Vorrebbe che fosse
casuale a ogni avvio.

In [scripts/game/movement_slice.gd:1133-1146](../../../scripts/game/movement_slice.gd)
(`_show_character_selection`), il personaggio passato a
`CharacterSelectOverlay.show_selection()` è
`current_friend.id if current_friend != null else &"magno"`: quando
`_player` non ha ancora un `FriendDefinition` assegnato in quella sessione
(nessun personaggio scelto dall'avvio dell'app), il codice cade sul
letterale `&"magno"` invece di scegliere fra tutto il roster. Questa stessa
funzione è condivisa da tutti e tre gli ingressi nel selettore
(`_on_welcome_play_requested`, `_on_tutorial_play_requested`,
`_on_change_character_requested` da CAMBIA PERSONAGGIO in pausa,
[movement_slice.gd:1329, 1367, 1386](../../../scripts/game/movement_slice.gd)),
ma solo il ramo del fallback (`current_friend == null`) produce sempre lo
stesso risultato: quando `current_friend` non è null, il selettore mostra
già correttamente l'ultimo personaggio giocato, non Magno.

**Decisione già presa col proprietario (2026-09-18)**: la casualità si
applica solo al fallback (nessun personaggio ancora scelto in sessione), non
sovrascrive mai l'ultimo personaggio giocato quando si riapre il selettore
via CAMBIA PERSONAGGIO o si ritenta una nuova partita nella stessa sessione
app.

## Comportamento atteso

Quando il selettore personaggi si apre e `_player` non ha ancora un
`FriendDefinition` assegnato in quella sessione (primo ingresso dall'avvio
dell'app), il personaggio evidenziato è scelto casualmente fra l'intero
roster (`FriendRegistry.get_definitions()`), non è più sempre Magno. In ogni
altro caso (un personaggio è già stato scelto/giocato in questa sessione), il
selettore continua a evidenziare l'ultimo personaggio giocato, invariato.

## Criteri di accettazione

- [x] Al primo ingresso nel selettore in una sessione app (nessun
      `FriendDefinition` ancora assegnato a `_player`), il personaggio
      evidenziato varia fra le aperture (non è deterministicamente sempre
      Magno o sempre lo stesso id).
- [x] Il personaggio scelto casualmente è sempre uno di quelli restituiti da
      `FriendRegistry.get_definitions()` (lo stesso roster già mostrato nel
      carosello, nessun id fuori roster o non valido).
- [x] Quando `_player` ha già un `FriendDefinition` assegnato (dopo la prima
      selezione/partita nella sessione), riaprire il selettore (CAMBIA
      PERSONAGGIO, o una nuova "Nuova Partita" successiva nella stessa
      sessione) continua a evidenziare l'ultimo personaggio giocato — nessuna
      regressione.
- [x] Se il roster ha un solo personaggio valido, il comportamento resta
      corretto (nessun errore di indice/RNG su lista di taglia 1).

## Ambito

- `scripts/game/movement_slice.gd`: `_show_character_selection()`
  (righe 1133-1146) — sostituire il letterale `&"magno"` con un id scelto
  casualmente da `_friend_registry.get_definitions()` solo nel ramo
  `current_friend == null`.
- Non toccare:
  - `scripts/ui/character_select_overlay.gd`: `show_selection()` e il suo
    fallback interno (`_definitions[0]` se l'id risolto è nullo) restano
    invariati, sono una rete di sicurezza indipendente da questa card;
  - il ramo `current_friend != null` (ultimo personaggio giocato ha sempre
    precedenza sulla casualità);
  - `FriendRegistry` e il roster stesso (nessun nuovo personaggio, nessuna
    modifica ai criteri di validità/pubblicazione).
- Nota: al momento dell'apertura del selettore `RunController` è ancora in
  `BOOT` e `get_seed()` non ha ancora un seed di run significativo
  (`prepare_restart` lo azzera prima di questo punto,
  [run_controller.gd:126-133](../../../scripts/game/run_controller.gd)): la
  scelta casuale è un dettaglio puramente di presentazione UI, non fa parte
  del contratto deterministico della run e non deve essere legata al seed di
  run.

## Verifica

- Smoke: `tests/unit/test_ps195_random_initial_character.gd` → marker
  `PS195_RANDOM_INITIAL_CHARACTER_SMOKE_OK` — chiama
  `_show_character_selection()` più volte con `_player` senza
  `FriendDefinition` assegnato e verifica che l'id evidenziato non sia
  sempre lo stesso (su un roster con più di un personaggio) e sia sempre un
  id valido del roster; verifica poi che, dopo aver assegnato un
  `FriendDefinition`, riaprire il selettore evidenzi quello stesso id in
  modo stabile.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows — **aperto**: gli automatici girano su Windows e
      pilotano il vero `CharacterSelectOverlay` dentro `MovementSlice`, ma
      nessuno ha ancora aperto il gioco a mano e premuto NUOVA PARTITA
- [x] Validazione statica APK — non pertinente (nessuna modifica a manifest
      o export)
- [ ] Runtime fisico Pixel 9 — non essenziale per dichiarazione della card
      stessa; comunque non eseguito, `adb devices` non vede device collegati
- [x] Controllo percettivo richiesto: no — criterio osservabile e binario
      (id casuale nel roster vs sempre lo stesso), non un giudizio di feel

## Decisioni

- **2026-09-20 — `Array.pick_random()` invece di un indice calcolato a mano.**
  Un `randi() % size` scritto a mano è il posto naturale per l'errore di
  indice su roster di taglia 1 che il quarto criterio teme; `pick_random()`
  lo rende strutturalmente impossibile ed è già nello stdlib del motore.
  Nessuna chiamata a `randomize()`: Godot 4 semina il generatore globale
  all'avvio, e questa scelta non fa parte del contratto deterministico
  della run.
- **2026-09-20 — Fallback a `&"magno"` solo su roster vuoto.** Se
  `get_definitions()` torna vuoto non c'è nulla da estrarre; in quel caso il
  codice torna al letterale di prima, e `show_selection()` esce comunque
  subito perché `_buttons_by_id` è vuoto. Nessun percorso nuovo da coprire.
- **2026-09-18 — Ambito confermato col proprietario**: casualità solo sul
  fallback "nessun personaggio ancora scelto in sessione", mai sovrascrive
  l'ultimo personaggio giocato in CAMBIA PERSONAGGIO o in una nuova partita
  successiva nella stessa sessione app.

## Documenti sincronizzati

- Nessuno: comportamento di presentazione UI, non un contratto descritto in
  `prd.md`/`ui-ux-flow.md`.

## Note

Comandi di verifica eseguiti:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-195 -Profile Focused `
  -FocusedSmoke tests/unit/test_ps195_random_initial_character.gd -RefreshEditor
.\tools\run-milestone-checks.ps1 -Milestone PS-195 -Profile Relevant `
  -FocusedSmoke tests/unit/test_ps195_random_initial_character.gd
.\tools\run-milestone-checks.ps1 -Milestone PS-195 -Profile Full
```

Esiti: `Focused` PASS (3/3 test, 81 assert), `Relevant` PASS (34/34 script,
106/106 test), `Full` PASS (159/159 script, 500/500 test, toolchain PASS).
Nessun `SCRIPT ERROR` né `FATAL EXCEPTION` nei log. Marker
`PS195_RANDOM_INITIAL_CHARACTER_SMOKE_OK` presente.

Il nuovo smoke è stato aggiunto alla regola di `scripts/game/movement_slice.gd`
in `tools/milestone-test-map.json`.

Il primo caso apre il selettore 24 volte azzerando ogni volta
`player.friend_definition`: il vecchio fallback fisso avrebbe prodotto un solo
id osservato, quindi il test fallisce davvero sul codice di prima.

Segnalato dal proprietario nella stessa sessione di PS-193/PS-194, problema
indipendente (selettore personaggi, non sistema Boss).
