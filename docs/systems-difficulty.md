# Sistemi e curva di difficoltà

Questo documento descrive lo stato attuale dei sistemi che governano una run:
stati di `RunController`, spawn e curva di difficoltà di `GameDirector` ed
`EnemySpawner`, progressione ed economia degli upgrade. Dove il contratto è
già scritto per intero in [`prd.md`](./prd.md), questo documento lo linka
invece di duplicarlo. Non è un backlog: lo stato operativo resta nella
[board](./cards/README.md).

## `RunController` — stati e transizioni

`RunController` ([scripts/game/run_controller.gd](../scripts/game/run_controller.gd))
è l'unica autorità su stato, tempo logico, pausa e restart (contratto già
dichiarato in `CLAUDE.md`). Stati (`RunState`, righe 10-19): `BOOT`,
`RUNNING`, `MANUAL_PAUSE`, `LEVEL_UP`, `BOSS_INTRO`, `BARB_REWARD`,
`VICTORY`, `DEFEAT`.

Transizioni permesse, ciascuna con guardia esplicita nel proprio metodo:

- `start_run(seed)` (:50-59): solo da `BOOT` non bloccato → `RUNNING`; azzera
  `_run_time` ed emette `run_started`.
- `request_manual_pause()` / `resume_run()` (:70-79): solo `RUNNING ↔
  MANUAL_PAUSE`.
- `request_level_up()` / `complete_level_up()` (:82-91): solo `RUNNING →
  LEVEL_UP` e ritorno.
- `request_boss_intro()` / `complete_boss_intro()` (:94-103): solo `RUNNING →
  BOSS_INTRO` e ritorno.
- `request_barb_reward()` / `complete_barb_reward()` (:106-115): solo
  `RUNNING → BARB_REWARD` e ritorno.
- `request_victory()` / `request_defeat()` (:118-124, via
  `_request_terminal_state`): da qualunque stato non-`BOOT` e non già
  terminale → `VICTORY`/`DEFEAT`. Una volta terminale, `_terminal_locked`
  (:180) blocca ogni transizione successiva finché non arriva
  `prepare_restart()`.

**Avanzamento solo in `RUNNING`.** `_process()` (:42-48) incrementa
`_run_time` solo se `is_running()`. `_apply_tree_pause_for_state()` /
`_state_pauses_tree()` (:189-198) impostano `SceneTree.paused = true` per
ogni stato diverso da `BOOT`/`RUNNING`: è questo il meccanismo che congela
cooldown, timer e VFX di gameplay durante `MANUAL_PAUSE`, `LEVEL_UP`,
`BOSS_INTRO`, `BARB_REWARD` e negli stati terminali. `GameDirector`,
`EnemySpawner` e `WaveEventScheduler` girano a `PROCESS_MODE_ALWAYS` e si
autoescludono controllando `RunController.is_running()`.

**Seed e restart.** `_seed` è impostato solo da `start_run(seed)` e letto da
`get_seed()`. `prepare_restart()` (:126-133) azzera `_terminal_locked`,
`_seed`, `_run_time`, forza `BOOT` ed emette `restart_prepared`.
`restart_run(seed)` (:136-140) richiede uno stato terminale, poi incatena
`prepare_restart()` + `start_run(seed)`. Ogni sistema (`GameDirector`,
`EnemySpawner`, `ExperienceSystem`, `UpgradeService`, `WaveEventScheduler`)
osserva `run_started`/`restart_prepared` per reseedare il proprio RNG privato
e azzerare il proprio stato — nessun autoload, coerente col contratto
scene-local di `CLAUDE.md`.

**Nota.** `request_victory()` non è chiamato da nessuno script di
produzione nella vertical slice attuale, solo dai test: lo stato `VICTORY`
esiste nell'API ma oggi non c'è una condizione di vittoria cablata nel
gameplay. `request_defeat()` è invece cablato in
[scripts/game/movement_slice.gd:1742-1747](../scripts/game/movement_slice.gd)
alla morte del Player.

## Spawn e curva di difficoltà

La curva di difficoltà "ordinaria" (densità, accelerazione, pesi per
archetipo, pressione late-run) vive in `EnemySpawnProfile`
([scripts/game/enemy_spawn_profile.gd](../scripts/game/enemy_spawn_profile.gd),
dati in `data/spawn_profiles/default_enemy_spawn_profile.tres`) ed è
applicata da `EnemySpawner`. Il contratto numerico completo è già scritto in
`prd.md`, sezioni **Densità B28/PS-076** ([prd.md:644-656](./prd.md)) e
**Pressione late-run PS-007** ([prd.md:658-669](./prd.md)): cap nemici vivi,
intervallo di spawn, accelerazione, scala del budget XP, evoluzione dei pesi
per archetipo fra `01:00` e `05:00` e garanzia tiratore da `03:00`. Non
duplicato qui.

Quattro archetipi correnti (`data/enemies/enemy_archetype_*.tres`, selezione
pesata in `enemy_spawner.gd:_pick_archetype`, righe 316-342):

| Archetipo | Peso base | Moltiplicatore late-run | Eleggibile da |
|---|---|---|---|
| `swarmer` | 1.4 | 2.2 | `25s` |
| `ranged` | 1.2 | 2.5 | `15s` |
| `armored` | 0.9 | 1.4 | `40s` |
| `splitter` | 1.0 | 1.6 | `50s` |

Selezione dei settori di spawn (N/E/S/O) con rotazione temporizzata:
`EnemySpawnProfile` (righe 80-96, `sector_hold_duration_min/max`,
`sector_multi_chance`, `sector_spike_chance`), applicata in
`enemy_spawner.gd:_roll_active_sectors` (righe 676-701).

**Eventi d'ondata PS-008** sono un layer separato e finito, non una seconda
curva ordinaria: gestiti da `WaveEventScheduler` /
`WaveEventDefinition` ([scripts/game/wave_event_scheduler.gd](../scripts/game/wave_event_scheduler.gd),
dati in `data/wave_events/`). Contratto completo già in `prd.md`, sezione
**Eventi d'ondata PS-008** ([prd.md:661-679](./prd.md)): nessun evento prima
di `02:30`, un solo evento attivo alla volta, intervallo `45-90s`, tre eventi
baseline (Accerchiamento, Stormo laterale, Nido di tiratori). Uno stato
`IDLE → TELEGRAPH? → ACTIVE → IDLE` governa ciascun evento
(`wave_event_scheduler.gd:22, 53-59`); durante un Boss attivo lo scheduler si
interrompe secondo `boss_maturation_policy` del profilo (`postpone` o
`discard`).

Nessuno scaling di questa sezione è legato al danno o alla potenza della
build del Player: dipende solo dal tempo logico trascorso in `RUNNING`.

## Soglie Boss e ricorrenza

`GameDirector` ([scripts/game/game_director.gd](../scripts/game/game_director.gd),
profilo `data/director_profiles/default_game_director_profile.tres`) possiede
soglie e scheduling dei Boss, non la UI (contratto già in `CLAUDE.md`):

- `boss_thresholds_seconds = [120]`: il primo Boss viene richiesto a `02:00`
  di clock logico ([prd.md:295](./prd.md)).
- `recurring_boss_window_seconds = 240.0` (default dello script
  `game_director_profile.gd:9`, non sovrascritto nel `.tres` corrente): dopo
  l'ultimo Boss delle soglie fisse, un nuovo Boss è richiesto ogni `240s`
  (`_evaluate_recurring_schedule`, `game_director.gd:321-329`). È questo il
  meccanismo per cui "i Boss ricorrono" e la loro morte non chiude la run
  (B33, vedi `CLAUDE.md`).
- Warning e countdown (`boss_warning_lead_seconds=15.0`,
  `boss_countdown_seconds=5.0`) sono descritti in
  [prd.md:295-304](./prd.md): copy, colore d'urgenza, congelamento in pausa,
  soppressione durante un Boss già attivo.
- Un Boss attivo sospende lo spawn ordinario
  (`EnemySpawner.set_ordinary_spawn_suspended(true)`, B53) e impedisce
  l'avvio di nuovi eventi d'ondata.

**PS-126 — pressione oltre il minuto 5 (run endless, PS-055).** Nessuna
curva di questa sezione o della precedente continua a crescere oltre
`late_run_curve_full_seconds` (300s): pesi, intervallo di spawn e cap sono
già al loro estremo, mentre la build del giocatore continua a scalare
(carte ripetibili senza tetto di rango). Due leve indipendenti tengono viva
la pressione oltre quel punto:

- `EnemySpawnProfile.get_post_curve_pressure_multiplier(run_time)`
  (`enemy_spawn_profile.gd`): `1.0` fino a `late_run_curve_full_seconds`,
  poi cresce linearmente di `post_curve_growth_per_minute` (default `0.15`,
  cioè `+15%` ogni minuto oltre la soglia) ogni minuto successivo. Applicato
  a HP e danno da contatto di ogni nemico spawnato (piccione base incluso)
  in `EnemySpawner._finalize_spawned_enemy`, mai alla cadenza o ai pesi. Il
  valore risultante è anche assegnato a `BaseEnemy.pressure_multiplier`, che
  `RangedEnemy` legge per scalare il danno del proprio proiettile
  (`ranged_projectile_damage`) allo sparo: senza questo, il tiratore —
  l'archetipo più pesato in late run — sarebbe rimasto piatto mentre gli
  altri diventavano più duri.
- `GameDirectorProfile.get_boss_recurrence_multiplier(schedule_index)`
  (`game_director_profile.gd`): `1.0` alla prima occorrenza, poi cresce di
  `boss_recurrence_growth_per_occurrence` (default `1.2`) per ogni
  ricorrenza successiva. Applicato in
  `BossEncounter._apply_recurrence_scaling`, dopo `configure_signature()`,
  a: HP e danno da contatto del Boss; danno della raffica radiale, del
  colpo mirato e della Scia di Piume del baseline (PS-127)
  (`FirstBoss._spawn_radial_volley`/`_execute_targeted_blast`/
  `_spawn_feather_projectile`, via `pressure_multiplier`); danno di ogni
  Signature Evil, composto con
  l'eventuale carica del Tuono di Evil Zat invece di sostituirla
  (`FirstBoss._spawn_signature_area`, `damage_scale *= pressure_multiplier`).
  Non tocca `resolve_variant()` né l'identità delle Signature. Estendere la
  scala alle Signature ha anche corretto un'applicazione parziale
  preesistente di `BossSignatureArea._damage_scale`: prima veniva letto solo
  da `_apply_instant_burst` (Tuono di Zat), non dagli altri tre modi
  (fronte, periodico, due fasi), quindi la stessa leva sarebbe rimasta
  inerte per 5 Signature su 6.

Entrambi i tassi di crescita sono un punto di partenza numerico dichiarato
nella card, non un valore tarato percettivamente: il gate manuale resta
aperto finché non viene giocata una run reale abbastanza lunga da
attraversarli.

Per il sistema Boss/Evil/Signature vero e proprio vedi
[`enemies-bosses.md`](./enemies-bosses.md).

## Progressione ed economia degli upgrade

`ExperienceSystem` ([scripts/progression/experience_system.gd](../scripts/progression/experience_system.gd))
accumula XP solo mentre `RUNNING` (righe 70-75) e apre `RunController.LEVEL_UP`
tramite `_start_next_level_up` (righe 211-229) quando la curva XP lo richiede.
Curva XP lineare in `ExperienceCurve` (righe 13-30, dati
`data/progression/default_experience_curve.tres`):
`base_experience_required=10`, `experience_growth_per_level=5`
(`10 + 5 × (livello - 1)`).

La ricompensa XP per kill non è fissa: segue la stessa scala già descritta
in `prd.md` per la **Densità B28** (`1,50 × intervallo_corrente /
intervallo_riferimento`), con il credito frazionario accumulato in
`ExperienceSystem` ed erogato solo come XP intero. Il reddito XP al secondo
che ne risulta (`xp_per_evento × 1,5 / intervallo_riferimento(t)`) è già
monotono crescente per costruzione, indipendentemente dalla curva di spawn
reale: PS-125 aveva proposto di "correggere" un presunto crollo del valore
per-kill, ma quel valore è una quantità diversa dal reddito XP/s ed è
scartata come card (vedi `docs/cards/6_rejected/PS-125-*.md`) dopo una
riverifica che ha mostrato come il fix avrebbe alterato il pacing reale
invece di ripararne uno rotto.

**Scelta upgrade.** `UpgradeService`
([scripts/progression/upgrade_service.gd](../scripts/progression/upgrade_service.gd))
genera, a ogni `level_up_started`, un'offerta di `3` carte (`generate_offer`,
righe 115-129) pescate senza reinserimento e pesate su `UpgradeDefinition.weight`
(`_draw_weighted_without_replacement`, righe 331-354), filtrando le carte di
rango abilità non equipaggiate e le "Specialità" non ancora sbloccate (righe
357-371).

**Ricompensa Barb (PS-012).** Alla morte di un Boss,
`UpgradeService.queue_barb_reward()` apre `RunController.BARB_REWARD`: prima
lo sblocco di una Specialità del roster Barb (offerta di `3`), poi — quando
tutte le Specialità sono già sbloccate — `2` scelte upgrade bonus (righe
397-419).

**Dati vs logica.** `UpgradeDefinition`
([scripts/progression/upgrade_definition.gd](../scripts/progression/upgrade_definition.gd))
dichiara solo `effect_id: StringName` e `effect_parameters: Dictionary`
(righe 13-14) più i metadati di eleggibilità (`prerequisites`, `max_rank`,
`repeatable`, `is_speciality`); la logica applicativa vive interamente in
`UpgradeEffectRegistry`, che fa `match definition.effect_id:` per validare e
applicare l'effetto. Le abilità attive seguono lo stesso schema:
`AbilityDefinition` + `AbilityEffectRegistry`. Nessuna logica nei file dati,
come da contratto `CLAUDE.md`.

## Pressione late-run e assenza di AFK

Non esiste un sistema unico "anti-AFK": l'obiettivo è dichiarato dalla card
`PS-007` ([docs/cards/4_to_test/PS-007-impedire-run-AFK-lategame.md](./cards/4_to_test/PS-007-impedire-run-AFK-lategame.md),
`IN VERIFICA`) e delegato interamente alla curva qualitativa descritta sopra
(peso piccione in calo, moltiplicatori late-run, garanzia tiratore, settori
multipli), più il layer opzionale degli eventi d'ondata `PS-008`
([docs/cards/4_to_test/PS-008-eventi-di-ondata.md](./cards/4_to_test/PS-008-eventi-di-ondata.md),
`IN VERIFICA`). Principio dichiarato nella card: *"late run più difficile =
nuove decisioni e nuova pressione, non soltanto numeri più grandi"*. Entrambe
le card hanno gate di playtest percettivo ancora aperti: il risultato
automatico è verde, quello percettivo no.

## Sparo manuale e responsabilità del DPS (PS-085)

`WeaponController` ([scripts/combat/weapon_controller.gd](../scripts/combat/weapon_controller.gd))
espone una modalità di sparo Manuale alternativa all'Automatico
(`FireModeSettings`, impostazione persistente da welcome/pausa): il
personaggio spara solo mentre il giocatore mira attivamente
(`_manual_aim_active`, aggiornato da `InputRouter.manual_aim_changed`), non
più sempre appena un bersaglio è a portata e il cooldown è scaduto. Nessun
dato di bilanciamento (danno, cadenza, upgrade) cambia fra le due modalità:
cambia solo chi decide *quando* e *dove* parte il colpo.

Questo sposta parte della responsabilità del DPS effettivo sul giocatore: il
tempo speso "non mirando" (per riposizionarsi, osservare l'orda o
prepararsi ad attivare l'abilità) è tempo senza danno, un margine che
l'Automatico non lascia mai scoprire. Le curve di spawn e i moltiplicatori
late-run descritti sopra restano tarati sul DPS dell'Automatico, l'unico
comportamento storicamente misurato: la modalità Manuale è dichiarata come
scelta del giocatore, non ancora bilanciata né validata su questa curva. Un
eventuale riequilibrio (o una guardia esplicita) resta materia di una card
dedicata, se il playtest percettivo del Manuale mostrasse un DPS
significativamente diverso da quello assunto qui.
