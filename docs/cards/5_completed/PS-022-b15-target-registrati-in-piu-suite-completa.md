---
id: PS-022
titolo: Diagnostica i due target registrati in più di test_b15_boss_encounter
tipo: chore
area: tooling
stato: COMPLETATO
priorita: media
dipende_da: []
origine: PS-013
creato: 2026-08-30
aggiornato: 2026-08-31
---

# PS-022 — Diagnostica i due target registrati in più di test_b15_boss_encounter

## Contesto

`tests/unit/test_b15_boss_encounter.gd::test_composed_encounter` fallisce
quando gira dentro la suite completa (65 script GUT in un solo processo) su
due conteggi del `TargetingSystem`:

- riga 107, `Targeting deve contenere Boss e nemico base`: 4 invece di 2;
- riga 160, `Il nemico base deve restare registrato fino al restart`: 3
  invece di 1.

Sempre esattamente **due bersagli registrati in più**. Lo stesso test passa
in isolamento (`Focused` sul solo file). Non è una regressione di
[PS-013](../4_to_test/PS-013-crash-typedarray-seconda-offerta-upgrade.md): le stesse due
asserzioni erano già fallite il 2026-08-29 alle 01:26 nello smoke legacy
equivalente `tests/integration/_boss_encounter_smoke.gd`, che girava in un
processo tutto suo (log `20260829-012625-B18M`,
`regression-_boss_encounter_smoke.log`).

La fixture disattiva `RunController._process` e `EnemySpawner._process`, ma
non tutto ciò che può registrare un bersaglio nel frattempo.

## Comportamento atteso

`test_b15_boss_encounter.gd` produce lo stesso esito in isolamento e dentro
la suite completa, e i conteggi del `TargetingSystem` riflettono solo le
entità che la fixture crea esplicitamente.

## Criteri di accettazione

- [x] Identificato e documentato qui che cosa registra i due bersagli
      aggiuntivi (adds del Boss, spawn residuo, stato non ripulito da un test
      precedente nello stesso processo, o altro). — vedi Decisioni: non è
      stato residuo tra test, è RNG di spawn non seminato dentro questo
      stesso test.
- [x] `test_b15_boss_encounter.gd` passa sia in isolamento sia dentro un
      profilo `Full`, per tre esecuzioni consecutive con `-NoCache`. Vedi
      Verifica per i log e i conteggi JUnit.
- [x] Se la causa è nella fixture, il test viene reso deterministico senza
      allentare le asserzioni sui conteggi. — la causa è nella fixture (vedi
      Decisioni); `assert_eq(..., 2, ...)` e `assert_eq(..., 1, ...)` restano
      invariati.
- [x] Se la causa è nel codice di gioco (registrazione doppia o mancata
      deregistrazione nel `TargetingSystem`), il problema viene descritto qui
      e spostato su una card dedicata. Non applicabile: la causa non è nel
      codice di gioco.

## Ambito

- `tests/unit/test_b15_boss_encounter.gd`;
- in sola lettura, `scripts/game/targeting_system.gd`,
  `scripts/game/boss_encounter.gd`, `scripts/bosses/first_boss.gd` e
  `scripts/game/game_director.gd` per la diagnosi.

Non modificare come soluzione di comodo:

- non sostituire i conteggi esatti con soglie `>=` per far passare il test.

## Verifica

- Test: `tests/unit/test_b15_boss_encounter.gd`.
- Profilo minimo prima della chiusura: `Full` con `-NoCache`, ripetuto.
- Tre `Full -NoCache` consecutive già registrate durante PS-032, con B15 nel
  batch di regressione: `20260831-002336-PS-032`,
  `20260831-004826-PS-032`, `20260831-011251-PS-032`. In ciascun JUnit la
  suite B15 riporta 2 test, zero failure e zero skipped; il primo profilo era
  rosso solo per una flakiness PS-009 estranea, mentre B15 era verde.
- Tre passaggi focused/isolati sull'HEAD corrente: `20260831-225256-PS-039`,
  `20260831-230124-PS-039` e `20260831-233508-PS-022`; ogni JUnit riporta
  2/2 test B15 verdi. Il secondo run è anche un profilo `Full` corrente da
  240/240 test, toolchain e project smoke verdi.
- Nessuno dei log citati contiene `SCRIPT ERROR`, `FATAL EXCEPTION`,
  `SMOKE_FAIL` o `CONTRACT_FAIL`.

## Gate manuali

- [x] Runtime Windows: non richiesto per la sola diagnosi.
- [x] Validazione statica APK: non richiesta.
- [x] Runtime fisico Pixel 9: non richiesto.
- [x] Controllo percettivo richiesto: no.

## Decisioni

- **2026-08-30 — Card separata, aperta durante PS-013.** Emersa nella suite
  completa lanciata per verificare PS-013, ma indipendente da quel fix e
  precedente ad esso; allargare PS-013 avrebbe mescolato due problemi.
- **2026-08-30 — Causa isolata: seed di spawn non fissato dalla fixture, non
  stato residuo tra test.** `instantiate_movement_slice()` fa partire la run
  tramite `_should_auto_start_default_character()` in
  [scripts/game/movement_slice.gd](../../../scripts/game/movement_slice.gd),
  vero sotto `--headless` (`DisplayServer.get_name() == "headless"`), che
  chiama `_start_selected_run(_resolve_run_seed())`. `_resolve_run_seed()`
  cade sul fallback `int(Time.get_unix_time_from_system())` perché il batch
  GUT del runner non passa `--smoke-test`/`--run-seed=` (quegli flag esistono
  solo per l'eseguibile esportato, vedi `tools/run-milestone-checks.ps1` riga
  ~1085). Il seed reale del turno arriva quindi da `Time.get_unix_time_from_system()`
  — diverso ogni secondo — e alimenta l'RNG privato di
  `EnemySpawner` ([scripts/game/enemy_spawner.gd](../../../scripts/game/enemy_spawner.gd))
  via `_on_run_started`. La riga 105 del test (prima della correzione) chiamava
  `spawner.try_spawn_enemy()` con quell'RNG non seminato dal test: se
  `_pick_archetype()` estrae lo Sciame
  (`data/enemies/enemy_archetype_swarmer.tres`, `spawn_cluster_size = 3`,
  eleggibile da 25s e con `late_run_weight_multiplier` che lo rinforza a
  120s), quella singola chiamata registra **3** bersagli invece di 1 — le
  "due unità in più" osservate, che restano registrate anche dopo la morte
  del Boss perché non sono legate al suo ciclo di vita. Non è flakiness
  isolamento-vs-suite: è puramente probabilistico sul secondo reale in cui
  gira il test, quindi può (raramente) fallire anche in isolamento e passare
  anche dentro `Full`. `WaveEventScheduler` è stato escluso come causa:
  `min_start_seconds = 150.0` nel profilo dati resta sempre sopra i 120.01s
  di run_time usati dal test, quindi il suo scheduler non parte mai in questo
  scenario. `GameDirector` non ha un proprio `_process`/`_physics_process`:
  è puramente reattivo al segnale di `RunController`, quindi disattivarlo non
  serviva.
- **2026-08-30 — Fix nella fixture: azzerare `spawner.archetypes` prima dello
  spawn deliberato dell'"ordinary_enemy".** Con `archetypes = []`,
  `_pick_archetype()` ritorna sempre `null` e `try_spawn_enemy()` produce
  sempre esattamente il piccione base (nessun cluster), qualunque sia il seed
  del turno. Non serviva un fix nel codice di gioco: il comportamento di
  gioco (cluster di spawn per archetipi come lo Sciame) è corretto e voluto,
  solo il test doveva neutralizzare quella variabile per un'asserzione a
  conteggio esatto.
- **2026-08-31 — Segnalazione collaterale: il seed di run non deterministico
  è un problema più ampio.** Verificando questa card con `-Profile Full
  -NoCache`, `test_b13_signature_upgrades.gd` è crashato per lo stesso
  meccanismo (`try_spawn_enemy()` con RNG non pinnato) in un file
  completamente diverso. Aperta [PS-032](./PS-032-seed-run-non-deterministico-nei-test-gut.md)
  per il fix strutturale; qui resta solo il fix locale a
  `test_b15_boss_encounter.gd`.
- **2026-08-30 — Segnalazione collaterale: fragilità del runner sui warning
  `git diff` con CRLF.** Durante la verifica, `run-milestone-checks.ps1` è
  crashato su `git.exe : warning: ... CRLF will be replaced by LF ...`
  perché lo script gira con `$ErrorActionPreference = 'Stop'` e PowerShell
  5.1 trasforma l'output stderr di un comando nativo reindirizzato
  (`2>$null`) in un `NativeCommandError` terminante anche a exit code `0`
  (causa nota, non specifica di questa card). Sbloccato normalizzando a LF
  l'unico file CRLF nell'albero di lavoro
  (`docs/cards/4_to_test/PS-009-trasparenza-dialog-boss.md`, residuo da
  [PS-009](../4_to_test/PS-009-trasparenza-dialog-boss.md)), non toccando lo
  script. Il runner resta comunque fragile su qualunque file CRLF futuro:
  vale la pena una card dedicata se ricapita, ma è fuori ambito qui.

## Note

Evidenze:

- fallimento nella suite completa: log `20260830-133544-PS-013`,
  `gut-regression.log` righe 854-858 (159/160 test verdi, solo questo rosso);
- passaggio in isolamento lo stesso giorno: log `20260830-135304-PS-013`;
- stesso fallimento prima del fix PS-013 e prima della migrazione a GUT: log
  `20260829-012625-B18M`, `regression-_boss_encounter_smoke.log` righe 48-53.

Frequenza osservata il 2026-08-30: **un fallimento su tre** esecuzioni della
suite completa. Verde in `20260830-140828-PS-021` e in `20260830-144237-PS-023`
(69/69), rosso in `20260830-133544-PS-013`. Chi riprende la card non si aspetti
di riprodurlo al primo colpo: serve ripetere con `-NoCache`.

**Chiusura 2026-08-31.** Il fix locale era già presente nel commit
`d67b16b` insieme al lavoro PS-034/PS-032. La validazione sopra conferma che
non serve un'ulteriore modifica al runtime o alle asserzioni esatte.
