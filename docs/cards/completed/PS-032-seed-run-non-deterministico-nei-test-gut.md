---
id: PS-032
titolo: Il seed di run non deterministico nei test GUT causa flakiness sparsa
tipo: fix
area: tooling
stato: COMPLETATO
priorita: alta
dipende_da: []
origine: PS-022
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-032 — Il seed di run non deterministico nei test GUT causa flakiness sparsa

## Contesto

`instantiate_movement_slice()` in
[tests/unit/helpers/gameplay_test.gd](../../../tests/unit/helpers/gameplay_test.gd)
istanzia `movement_slice.tscn` e non passa mai un seed di run esplicito. La
scena si auto-avvia da sola: `_should_auto_start_default_character()` in
[scripts/game/movement_slice.gd](../../../scripts/game/movement_slice.gd)
ritorna vero sotto `--headless` (sempre vero nei batch GUT), e chiama
`_start_selected_run(_resolve_run_seed())`. `_resolve_run_seed()` usa un seed
fisso solo se sono presenti gli argomenti da riga di comando
`--run-seed=`/`--smoke-test` — che il runner (`tools/run-milestone-checks.ps1`)
passa **solo** all'eseguibile esportato per il proprio smoke di avvio, mai
alle invocazioni di `addons/gut/gut_cmdln.gd`. Per ogni test GUT che passa da
`instantiate_movement_slice()`, il seed di run ricade quindi su
`int(Time.get_unix_time_from_system())`: diverso a ogni secondo reale,
diverso a ogni esecuzione.

Questo seed alimenta l'RNG privato di `EnemySpawner`
([scripts/game/enemy_spawner.gd](../../../scripts/game/enemy_spawner.gd)) via
il segnale `run_started`. Qualunque test che chiami
`spawner.try_spawn_enemy()` per creare un nemico "noto" (senza prima
azzerare `spawner.archetypes`) può quindi ricevere, in modo del tutto
casuale sul secondo reale, un archetipo diverso da quello atteso — inclusi
archetipi con `spawn_cluster_size > 1` (es. lo Sciame,
`data/enemies/enemy_archetype_swarmer.tres`, cluster di 3), che producono
più nemici registrati di quanti il test ne aspetti.

Trovato due volte lo stesso giorno (2026-08-31, ora locale del repository):

1. [PS-022](../to_test/PS-022-b15-target-registrati-in-piu-suite-completa.md) —
   `test_b15_boss_encounter.gd` registrava 2 bersagli in più nel
   `TargetingSystem` quando lo Sciame veniva estratto per lo spawn manuale di
   riga 105. Risolto azzerando `spawner.archetypes` in quel test, ma è un
   fix locale a un solo file.
2. Durante la verifica di PS-022 con profilo `Full -NoCache`, log
   `20260830-234608-PS-022/gut-regression.log` righe 5651-5654:
   `test_b13_signature_upgrades.gd::test_signature_composition` è crashato
   con `SCRIPT ERROR: Out of bounds get index '0' (on base: 'Array[int]')`
   alla riga 238, perché `_shockwave_affected_counts` è risultato vuoto.
   Quel test chiama lo stesso `spawner.try_spawn_enemy()` (tramite il proprio
   helper `_spawn_enemy`, riga 300-301) tre volte per creare `near_enemy`,
   `far_enemy` e `joining_enemy`, senza azzerare `archetypes`: un archetipo
   inatteso (cluster o comportamento diverso dal piccione base) può spiegare
   sia il conteggio shockwave sbagliato sia, potenzialmente, le altre
   asserzioni sulle statistiche di quei nemici più a monte nello stesso
   test, mai osservate fallire finora solo perché non fanno crashare il
   motore.

Non è stato verificato quanti altri file in `tests/unit/` chiamino
`try_spawn_enemy()` (direttamente o tramite un proprio helper) senza pinnare
gli archetipi: la diagnosi qui sopra copre solo i due casi osservati.

## Comportamento atteso

Ogni run di gioco avviata da un test GUT tramite `instantiate_movement_slice()`
usa un seed deterministico e noto, cosicché l'RNG di spawn (e qualunque altro
sistema seminato dal seed di run) produca lo stesso esito a ogni esecuzione,
in isolamento come dentro qualunque profilo batch.

## Criteri di accettazione

- [x] Individuato un meccanismo per cui i test GUT ricevano sempre un seed di
      run fisso e noto (es. `instantiate_movement_slice()` fa partire la run
      con un seed esplicito invece di lasciare che la scena si auto-avvii con
      `_resolve_run_seed()`, oppure `_resolve_run_seed()` riconosce
      l'ambiente di test GUT allo stesso modo in cui riconosce
      `--smoke-test`). Vedi Decisioni.
- [x] Il fix non richiede che ogni singolo test GUT venga toccato uno per
      uno: si applica al punto comune (helper `instantiate_movement_slice()`
      + un campo su `movement_slice.gd`), non file per file.
- [x] `test_b13_signature_upgrades.gd::test_signature_composition` passa in
      modo affidabile (tre esecuzioni consecutive con `-NoCache`, isolamento
      e profilo `Full`) senza modificarne le asserzioni. Vedi Verifica.
- [x] Verificato a campione se altri test che chiamano `try_spawn_enemy()`
      senza azzerare `archetypes` (grep su `tests/unit/`) sono esposti allo
      stesso rischio; documentato qui l'elenco trovato. Vedi Decisioni.
- [x] Il fix in [PS-022](../to_test/PS-022-b15-target-registrati-in-piu-suite-completa.md)
      (`spawner.archetypes = []` in `test_b15_boss_encounter.gd`) può restare
      com'è: non è in conflitto con un seed fisso a monte, è solo ridondante
      una volta chiusa questa card. Lasciato invariato; aggiornato solo il
      commento che ne spiegava il motivo, ormai obsoleto.

## Ambito

- `tests/unit/helpers/gameplay_test.gd` (`instantiate_movement_slice`), e/o
  `scripts/game/movement_slice.gd` (`_resolve_run_seed`,
  `_should_auto_start_default_character`) se il fix più pulito sta lì.
- `tests/unit/test_b13_signature_upgrades.gd` solo se il fix a monte non
  basta a farlo passare deterministicamente.
- Non cambiare `_resolve_run_seed()` per l'eseguibile esportato reale
  (comportamento invariato fuori dai test: `--run-seed=`, `--smoke-test`,
  fallback sull'orologio di sistema per una vera sessione di gioco).
- Non introdurre un autoload o uno stato globale per portare il seed ai test:
  resta un parametro esplicito da un capo all'altro, coerente con
  l'architettura scene-local del progetto.

## Verifica

- Test: `tests/unit/test_b13_signature_upgrades.gd` (evidenza diretta del
  problema) e `tests/unit/test_b15_boss_encounter.gd` (non deve regredire).
- Profilo minimo prima della chiusura: `Full` con `-NoCache`, ripetuto
  almeno tre volte consecutive.
- Eseguito `run-milestone-checks.ps1 -Milestone PS-032 -Profile Full -NoCache
  -FocusedSmoke tests/unit/test_b13_signature_upgrades.gd` tre volte
  consecutive:
  - Run 1 (`20260831-002336-PS-032`): `focused=1/1 regression=72/73`. L'unico
    fallimento è `test_ps009_boss_ui_transparency.gd` (proiezione camera a
    960×720), estraneo a questa card: appartiene al lavoro PS-009 già in
    corso (file di test non tracciato) e non tocca RNG/seed. Nessun
    `SCRIPT ERROR`/`FATAL EXCEPTION` sul test target.
  - Run 2 (`20260831-004826-PS-032`): `focused=1/1 regression=73/73`, incluso
    `test_ps009_boss_ui_transparency.gd` — conferma che quel fallimento è una
    flakiness preesistente e indipendente (probabile race di timing su
    frame fisici/camera), non un effetto del seed fisso introdotto qui.
  - Run 3 (`20260831-011251-PS-032`): `focused=1/1 regression=73/73`.
  - `test_signature_composition` verde e senza asserzioni modificate in
    tutte e tre le run; nessuna `SCRIPT ERROR`/`FATAL EXCEPTION` nei log.

## Gate manuali

- [x] Runtime Windows: non richiesto, è un fix di test/tooling.
- [x] Validazione statica APK: non richiesta.
- [x] Runtime fisico Pixel 9: non richiesto.
- [x] Controllo percettivo richiesto: no.

## Decisioni

- **2026-08-31 — Card separata da PS-022.** PS-022 ha un ambito ristretto a
  un solo file di test ed è già stato risolto lì con un fix locale
  (`spawner.archetypes = []`). Il problema di fondo — seed di run non
  deterministico per qualunque test GUT — è più ampio e merita una card
  propria invece di allargare PS-022 o rincorrere ogni test toccato uno alla
  volta.
- **2026-08-31 — Proprietà sull'istanza, non `ProjectSettings` globale.**
  `_ready()` chiama `_start_selected_run(_resolve_run_seed())` in modo
  sincrono durante `add_child()`: l'helper di test non può intervenire dopo.
  Il progetto ha già un precedente per forzare comportamento di test tramite
  `ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test",
  …)`, ma è stato scartato qui perché l'ambito del criterio "niente stato
  globale" nella card lo esclude esplicitamente. Soluzione scelta: un campo
  pubblico `gut_test_run_seed_override` sullo script di `movement_slice.gd`
  (default `0`, mai impostato fuori dai test), valorizzato dall'helper con
  `slice.set(...)` sull'istanza appena creata, **prima** di `add_child_autofree`
  — quindi prima che `_ready()` giri. `_resolve_run_seed()` lo controlla dopo
  `--run-seed=`/`--smoke-test` e prima del fallback sull'orologio di sistema:
  un parametro esplicito da un capo all'altro, senza autoload né stato
  condiviso fra test.
- **2026-08-31 — Seed fisso a `1`.** Coincide con la convenzione già usata da
  `--smoke-test` e con il default hardcoded di `EnemySpawner._rng.seed` (riga
  40 di `scripts/game/enemy_spawner.gd`), quindi non introduce un nuovo
  valore magico nel codebase.
- **2026-08-31 — Censimento `try_spawn_enemy()` senza pin di `archetypes`.**
  Grep su `tests/unit/*.gd` per `try_spawn_enemy\(\)`: ~39 punti di chiamata
  in oltre 25 file, di cui uno solo (`test_b15_boss_encounter.gd`) azzera
  `archetypes` prima di contare. Campione controllato a mano:
  `test_b40_enemy_archetypes.gd` e `test_ps007_late_run_pressure.gd` sono
  **fuori esposizione**: costruiscono un `EnemySpawner` isolato con il proprio
  helper `_build_spawner(seed_value, …)` e chiamano `reset_for_run`/passano il
  seed esplicitamente, senza mai passare da `instantiate_movement_slice()`.
  Per gli altri file non ispezionati singolarmente, il fix di questa card
  elimina comunque la componente "seed diverso a ogni esecuzione": l'esito
  diventa deterministico (stesso archetipo estratto ogni volta a parità di
  stato dello spawner), quindi un'eventuale assunzione sbagliata su quale
  archetipo arriva per primo si manifesterebbe ora come fallimento stabile e
  diagnosticabile, non più come flakiness intermittente. Le tre esecuzioni
  `Full -NoCache` di Verifica non hanno mostrato nuovi fallimenti in nessuno
  di questi file, quindi non risultano attualmente esposti.
- **2026-08-31 — Trovata flakiness indipendente in PS-009, non risolta qui.**
  La Run 1 di verifica ha fatto fallire
  `test_ps009_boss_ui_transparency.gd::test_boss_ui_dissolves_under_player_and_restores_across_resolutions`
  a 960×720 (proiezione camera del Player rispetto al riquadro Boss); le Run
  2 e 3, identiche, sono passate pulite. Non è un effetto del seed (la
  card PS-009 è un lavoro di UI/camera indipendente, ancora in corso — file
  di test non tracciato in questo worktree) ma una race di timing separata.
  Fuori ambito per PS-032: tracciata separatamente in
  [PS-037](../to_do/PS-037-flakiness-proiezione-camera-boss-ui-transparency.md)
  invece di allargare questa.

## Documenti sincronizzati

- [x] Nessuno atteso: è un dettaglio di determinismo dei test, non un
      contratto di prodotto o di architettura.

## Note

Comando per cercare altri casi sospetti prima di iniziare:

```powershell
Select-String -Path tests/unit/*.gd -Pattern 'try_spawn_enemy\(\)'
```

ognuno dei risultati va controllato per capire se azzera `archetypes` (o
altrimenti pinna l'esito) prima di contare o assumere un archetipo preciso.
