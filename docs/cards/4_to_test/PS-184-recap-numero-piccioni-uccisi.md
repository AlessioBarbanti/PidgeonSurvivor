---
id: PS-184
titolo: Mostra il numero di piccioni uccisi nel recap di fine partita
tipo: feat
area: ui
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-09-15
aggiornato: 2026-09-20
---

# PS-184 — Mostra il numero di piccioni uccisi nel recap di fine partita

## Contesto

Il recap di fine partita (`EndScreen`, sia in sconfitta che in vittoria)
mostra già livello raggiunto, Boss sconfitti, tempo di run e i tre upgrade
di rango più alto (`RunSummary`, PS-053), ma non quanti nemici sono stati
uccisi durante la run. Il proprietario vuole quel numero nel recap.

## Comportamento atteso

Il recap di fine partita (sia `GAME OVER` sia `VITTORIA`) mostra, accanto
alle statistiche già presenti, il numero totale di nemici uccisi nella run
appena conclusa.

## Criteri di accettazione

- [x] La riga statistiche del recap (`EndScreen`, sia sconfitta sia
      vittoria) mostra il numero di piccioni uccisi nella run appena
      conclusa, con concordanza singolare/plurale corretta ("1 piccione
      ucciso" / "N piccioni uccisi"), coerente con la concordanza già
      applicata in PS-166.
- [x] Il conteggio include ogni nemico (`BaseEnemy` e sue sottoclassi,
      Boss compreso — il Boss stesso è un piccione nella finzione di
      gioco) che muore per danno, cioè ogni emissione del segnale
      `BaseEnemy.died`. Non include i nemici rimossi da despawn/cleanup
      fuori arena (`EnemySpawner.cleanup_outside_despawn_rect`), che non
      sono uccisioni.
- [x] Il conteggio riparte da zero a ogni nuovo avvio di run
      (`RunController.run_started`), stesso momento in cui si azzera
      `_defeated_boss_count` in `MovementSlice`.
- [x] Il conteggio compare correttamente sia dopo una sconfitta sia dopo
      una vittoria (`EndScreen.show_defeat` e `show_victory`), non solo in
      uno dei due casi.

## Ambito

- [scripts/game/run_summary.gd](../../../scripts/game/run_summary.gd): nuovo
  campo intero sullo snapshot (es. `enemies_defeated`), sullo stesso
  pattern di `bosses_defeated`.
- [scripts/game/movement_slice.gd](../../../scripts/game/movement_slice.gd):
  nuovo contatore di run, incrementato collegandosi al segnale `died` di
  ogni nemico via `EnemySpawner.enemy_spawned` (stesso pattern già usato da
  `ExperienceDropper._on_enemy_spawned` per agganciarsi per-istanza), reset
  in `_on_run_started_for_summary`, letto in `_build_run_summary`.
- [scripts/ui/end_screen.gd](../../../scripts/ui/end_screen.gd):
  `_apply_summary`/`_stats_label`, nuovo helper di formattazione sullo
  stesso pattern di `_format_boss_count`.
- **Non toccare**: `RunController` (stato/tempo/arbitraggio), il conteggio
  di `_defeated_boss_count` esistente (resta una statistica separata, non
  va fusa nel nuovo contatore), `EnemySpawner`/`cleanup_outside_despawn_rect`
  (nessuna nuova semantica di despawn), il flusso
  `welcome → tutorial → selezione → run → pausa`.

## Verifica

- Estendere `tests/unit/test_ps053_run_summary.gd`
  (`test_run_summary_reflects_character_level_boss_and_top_upgrades`, che
  già guida una run reale fino a un Boss sconfitto) con
  un'asserzione sul nuovo testo del conteggio uccisioni, più un caso
  dedicato che spawna anche un nemico ordinario e ne verifica la morte nel
  conteggio finale. Marker esistente `RUN_SUMMARY_SMOKE_OK` resta valido
  come marker di riferimento.
- `scripts/game/run_summary.gd` è già mappato a
  `tests/unit/test_ps053_run_summary.gd` in
  [tools/milestone-test-map.json](../../../tools/milestone-test-map.json);
  aggiungere la stessa mappatura per `scripts/ui/end_screen.gd` se non già
  presente.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows — **aperto**: gli automatici girano su Windows ed
      esercitano il vero `EndScreen` dentro `MovementSlice`, ma nessuno ha
      ancora *guardato* la riga nel gioco avviato a mano
- [ ] Validazione statica APK: non richiesta (nessuna modifica a manifest o
      export)
- [ ] Runtime fisico Pixel 9 (percorso: completare una run reale fino al
      terminale e leggere il recap) — **aperto**: `adb devices` non vede
      alcun device collegato
- [ ] Controllo percettivo richiesto: sì — verificare che la riga
      statistiche non vada a capo in modo scomodo o esca dal layout con
      numeri a più cifre, sia in landscape stretto che largo — **aperto**:
      spetta all'agente `direttore-artistico`, che il proprietario invoca
      esplicitamente

## Decisioni

- **2026-09-15 — Il conteggio include il Boss.** `FirstBoss` estende
  `BaseEnemy` ed è a tutti gli effetti un piccione (il baseline si chiama
  "Piccione Malvagio"): includerlo nel totale evita un'eccezione
  ad-hoc nel segnale `died` e resta coerente con la finzione del gioco.
  `bosses_defeated` resta comunque una statistica separata e già esistente
  nel recap: le due cifre convivono, non si sostituiscono.
- **2026-09-20 — I Boss arrivano da `boss_defeated`, non dallo spawner.**
  `BossEncounter` aggiunge il Boss direttamente a `_enemy_parent` (non passa
  da `EnemySpawner`, come già annota `BaseEnemy` a proposito di
  `experience_reward_scale`): agganciarsi solo a `enemy_spawned` avrebbe
  perso ogni Boss. Il conteggio usa quindi due sorgenti — l'aggancio
  per-istanza a `died` per i nemici ordinari e l'handler
  `_on_boss_defeated_for_summary` già esistente per i Boss — invece di
  introdurre un nuovo segnale aggregato.
- **2026-09-20 — `CONNECT_ONE_SHOT` sul `died` per-istanza.** `ExperienceDropper`
  si difende da un `died` duplicato con un dizionario di id; qui basta la
  connessione one-shot del motore, che si sgancia da sola e non lascia stato
  da azzerare al restart.
- **2026-09-15 — Non contare i despawn.** Un nemico rimosso perché uscito
  dal despawn rect (`cleanup_outside_despawn_rect`) non è stato ucciso dal
  giocatore: contarlo gonfierebbe il numero senza che corrisponda a
  un'azione reale, ed è comunque un evento distinto da `BaseEnemy.died`
  (quel percorso libera il nodo senza passare da `_on_died()`).

## Documenti sincronizzati

- [x] Nessuno atteso: statistica di sola UI, non cambia un contratto di
      prodotto o un catalogo. Da rivalutare se la card, in fase di
      implementazione, rivelasse un contratto degno di `docs/ui-ux-flow.md`.

## Note

Richiesta diretta del proprietario, senza segnalazione di bug collegata.

Comandi di verifica eseguiti:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-184 -Profile Focused `
  -FocusedSmoke tests/unit/test_ps053_run_summary.gd
.\tools\run-milestone-checks.ps1 -Milestone PS-184 -Profile Relevant `
  -FocusedSmoke tests/unit/test_ps053_run_summary.gd
.\tools\run-milestone-checks.ps1 -Milestone PS-184 -Profile Full
```

Esiti: `Focused` PASS (4/4 test, 39 assert), `Relevant` PASS (62/62 script,
189/189 test), `Full` PASS (158/158 script, 496/496 test, toolchain PASS).
Nessun `SCRIPT ERROR` né `FATAL EXCEPTION` nei log. Marker `RUN_SUMMARY_SMOKE_OK`
presente. Nuovo caso di test:
`test_run_summary_counts_only_enemies_killed_by_damage`.

La mappatura `scripts/ui/end_screen.gd` → `tests/unit/test_ps053_run_summary.gd`
era già presente in `tools/milestone-test-map.json`: nessuna modifica necessaria.
