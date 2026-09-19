---
id: PS-193
titolo: Aumenta la cadenza d'attacco del Boss per non farlo sentire una pausa dalle ondate
tipo: fix
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: []
origine:
creato: 2026-09-18
aggiornato: 2026-09-20
---

# PS-193 — Aumenta la cadenza d'attacco del Boss per non farlo sentire una pausa dalle ondate

## Contesto

Il proprietario segnala che le run si sentono troppo frenetiche rispetto al
Boss, che sembra "tranquillo" — quasi un riposo dalle ondate invece del picco
di tensione della run.

Un Boss attivo sospende del tutto lo spawn ordinario
([scripts/game/enemy_spawner.gd:60-61](../../../scripts/game/enemy_spawner.gd),
flag impostato in
[scripts/game/movement_slice.gd:1197-1202](../../../scripts/game/movement_slice.gd)
sui segnali `boss_spawned`/`boss_defeated`, contratto B53 confermato voluto
da [PS-119](../5_completed/PS-119-fix-spawn-non-sospeso-boss-ricorrente-con-evento-attivo.md)):
il campo si svuota e resta vuoto per tutta la durata dello scontro. In quella
finestra, il ritmo di minaccia lo fa solo il Boss stesso.

Il Boss risolve un attacco ogni `baseline_pattern_interval = 1.6s` (+
telegraph `0.75-1.0s`) sul Piccione Malvagio, ogni `pattern_interval = 2.5s`
(+ telegraph) su una variante Evil
([data/bosses/first_boss.tres:19-45](../../../data/bosses/first_boss.tres),
ciclo in
[scripts/bosses/first_boss.gd:564-595](../../../scripts/bosses/first_boss.gd)).
Il 90% degli incontri è Evil
(`evil_boss_chance = 0.9`,
[scripts/bosses/boss_encounter.gd:25](../../../scripts/bosses/boss_encounter.gd)),
quindi il ciclo più lento (~3.25-3.5s+ fra un colpo e il successivo) è la
norma, non l'eccezione. Le ondate ordinarie, allo stesso `run_time=120s`
(ingresso del primo Boss), generano un nemico ogni ~0.14s
([scripts/game/enemy_spawn_profile.gd:165-170](../../../scripts/game/enemy_spawn_profile.gd),
valori in
[data/spawn_profiles/default_enemy_spawn_profile.tres](../../../data/spawn_profiles/default_enemy_spawn_profile.tres)) —
un rapporto di densità di minaccia di circa 17-25× fra ondata e Boss.

Nessun documento dichiara il Boss come "picco di tensione":
[docs/prd.md:333](../../prd.md) lo descrive solo come pattern "leggibili e
schivabili". La linea di design delle ondate è invece stata spinta
ripetutamente verso più frenesia
([PS-076](../5_completed/PS-076-aumenta-densita-nemica-a-schermo.md), motivata
da "troppo poco frenetica"), e
[PS-124](../5_completed/PS-124-eventi-ondata-che-riducono-la-pressione.md) ha
già sancito il principio — un layer che sostituisce lo spawn ordinario deve
generare più pressione di quella che toglie, mai meno — ma solo per gli
eventi d'ondata, mai per l'incontro Boss stesso. Non è un bug rispetto a un
contratto esistente: è un vuoto di specifica che questa card colma.

## Comportamento atteso

Durante un incontro Boss (baseline o Evil), il tempo che intercorre fra un
attacco risolto e il successivo è sensibilmente più breve dell'attuale, cosa
che il Boss "occupa" attivamente la finestra in cui ha sospeso le ondate
invece di lasciarla vuota fra un colpo e l'altro. Il differenziale per cui il
Piccione Malvagio baseline attacca più spesso di ogni Evil
([PS-127](../5_completed/PS-127-piccione-malvagio-boss-raro-e-piu-difficile-degli-evil.md))
resta osservabile. Nessuna sovrapposizione di telegraph viene introdotta: resta
un solo preavviso alla volta, come oggi.

## Criteri di accettazione

- [x] Il tempo medio fra un attacco risolto e il successivo, sul baseline, è
      ridotto rispetto al valore attuale (~2.35-2.6s), con il nuovo valore
      dichiarato esplicitamente in `Decisioni` insieme alla motivazione.
- [x] Il tempo medio fra un attacco risolto e il successivo, su una variante
      Evil, è ridotto rispetto al valore attuale (~3.25-3.5s+), con il nuovo
      valore dichiarato esplicitamente in `Decisioni`.
- [x] Il baseline continua ad attaccare più spesso di ogni Evil a parità di
      soglia (nessuna regressione sul contratto PS-127), anche se i valori
      assoluti cambiano.
- [x] `health_max` del Boss non viene toccato da questa card (resta ambito
      esclusivo di [PS-182](../5_completed/PS-182-primo-boss-troppa-vita.md)).
- [x] Nessun nuovo caso di telegraph sovrapposti: la guardia
      `is_signature_motion_active()` in
      [scripts/bosses/first_boss.gd:594](../../../scripts/bosses/first_boss.gd)
      resta intatta.
- [ ] Verificato in gioco reale, su almeno un incontro baseline e uno Evil,
      che il ritmo si senta come "il Boss è impegnativo" e non come una pausa
      dalle ondate. **Aperto**: è un giudizio di playtest del proprietario, non
      riducibile a un numero. La misura strumentale è nelle Note.

## Ambito

- `data/bosses/first_boss.tres`: `pattern_interval`,
  `baseline_pattern_interval`, `initial_attack_delay` e/o le tre durate di
  telegraph (`radial_telegraph_duration`, `targeted_telegraph_duration`,
  `feather_line_telegraph_duration`) — la leva numerica per accorciare il
  ciclo cooldown→telegraph→esecuzione.
- Non toccare:
  - `health_max` (ambito di PS-182);
  - la presentazione visiva del telegraph (ambito di
    [PS-141](../4_to_test/PS-141-arricchisci-telegraph-attacchi-boss.md));
  - il bug per cui il telegraph a volte non si risolve in un colpo (ambito di
    [PS-181](../3_in_sprint/PS-181-telegraph-boss-a-volte-non-spara.md));
  - la sospensione dello spawn ordinario durante il Boss
    (`EnemySpawner.set_ordinary_spawn_suspended`, B53/PS-119): resta totale,
    non va riattivata né modulata in parallelo;
  - la regola "un solo telegraph alla volta" (`first_boss.gd:591-594`);
  - `data/friends/*.tres`: le varianti Evil ereditano `pattern_interval` dal
    baseline via `resolve_variant()`/`is_evil_variant()`, non hanno un campo
    proprio da toccare;
  - `EnemySpawnProfile` e gli eventi d'ondata (`data/wave_events/*.tres`),
    fuori ambito.

## Verifica

- Smoke: `tests/unit/test_ps193_boss_attack_cadence.gd` → marker
  `PS193_BOSS_ATTACK_CADENCE_SMOKE_OK` — asserisce i nuovi valori di
  `pattern_interval`/`baseline_pattern_interval`/telegraph rispetto agli
  attuali, che il differenziale baseline-più-veloce-degli-Evil resti positivo,
  e che il ciclo di rotazione pattern (`_resolve_next_pattern_id`) e la
  guardia anti-sovrapposizione restino invariati.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [x] Runtime Windows — run reale con renderer Windows
      (`tools/_capture_boss_split_wander_ps194.gd`): 17.12s di combattimento
      Boss baseline con i nuovi valori, 8 preavvisi aperti, intervallo medio
      osservato 2.45s sul tempo logico del `RunController`, run sempre in
      `RUNNING`, nessun `SCRIPT ERROR`. Non è una partita giocata: il giudizio
      sul ritmo resta al gate percettivo.
- [ ] Validazione statica APK — non pertinente, solo tuning numerico su dati
      esistenti
- [ ] Runtime fisico Pixel 9 — **aperto**: nessun device collegato
      (`adb devices` vuoto)
- [ ] Controllo percettivo richiesto: sì — "il Boss si sente impegnativo, non
      una pausa" è un giudizio di playtest reale su almeno un incontro
      baseline e uno Evil, non un numero isolato

## Decisioni

- **2026-09-18 — Aperta da feedback diretto del proprietario** ("le run sono
  troppo frenetiche in confronto al boss ... quasi il boss ti riposa dalle
  ondate"), confermato da ricognizione quantitativa (rapporto di densità
  minaccia ondata/Boss ~17-25×, nessun contratto esistente che leghi la
  cadenza Boss alla densità delle ondate che sospende).
- **2026-09-18 — Leva scelta: cadenza d'attacco del Boss, non densità delle
  ondate.** Ridurre la frenesia delle ondate ordinarie contraddirebbe una
  direzione di design già presa deliberatamente in senso opposto (PS-076).
  Riattivare lo spawn ordinario durante il Boss in parallelo regredirebbe il
  contratto B53/PS-119. L'unica leva compatibile con i contratti esistenti è
  rendere il Boss stesso più occupante nella finestra che già monopolizza.
- **Valori numerici esatti lasciati aperti** a chi implementa: dichiararli
  qui con la motivazione (es. percentuale di riduzione scelta) prima della
  chiusura, come già fatto in PS-124 per un problema dello stesso tipo.
- **2026-09-20 — Valori scelti: cooldown giù del ~44%, telegraph intatti.**
  `baseline_pattern_interval` 1.6→0.9, `pattern_interval` 2.5→1.4,
  `initial_attack_delay` 1.5→1.0. La leva è il solo cooldown: le durate di
  telegraph sono il budget di leggibilità con cui il colpo si schiva (PRD:
  "pattern leggibili e schivabili") e accorciarle avrebbe tolto tempo di
  reazione invece di togliere tempo morto. L'intervallo medio fra un attacco
  risolto e il successivo (cooldown + telegraph, la stessa metrica con cui la
  card misura lo stato attuale) passa da ~2.48s a ~1.78s sul baseline
  (-28%) e da ~3.48s a ~2.38s su un Evil (-32%). Il differenziale PS-127
  resta: 0.9 < 1.4 sul cooldown, 1.78s < 2.38s sulla media.

- **2026-09-20 — La Scia di Piume resta l'eccezione alla metrica.** Durante lo
  stream (20 lanci × 0.08s = 1.6s) il cooldown non scorre, quindi quello slot
  costa più della media: è tempo in cui il Boss sta già attaccando senza
  sosta, non tempo morto, e non è stato toccato.

- **Interazione con PS-182 da tenere presente in playtest**: se health_max
  scende (PS-182) e la cadenza sale (questa card), l'effetto combinato sulla
  durata percepita dello scontro potrebbe essere maggiore della somma delle
  due modifiche singole — non è una dipendenza rigida (`dipende_da` resta
  vuoto, le due leve sono indipendenti), ma il gate percettivo di entrambe
  dovrebbe idealmente osservare l'effetto combinato se arrivano vicine nello
  sprint.

## Documenti sincronizzati

- [x] `docs/enemies-bosses.md` — valori aggiornati nella riga del cooldown e
      nuovo paragrafo PS-193 con la motivazione e le medie risultanti.
- [x] `docs/systems-difficulty.md:130-132` — riletto: il contratto di
      sospensione dello spawn non è cambiato e il testo resta accurato, quindi
      nessuna modifica.

## Note

Verifica eseguita il 2026-09-20 (nessun `SCRIPT ERROR` nei log):

```powershell
.	oolsun-milestone-checks.ps1 -Milestone PS-193 -Profile Relevant `
  -FocusedSmoke tests/unit/test_ps193_boss_attack_cadence.gd
.	oolsun-milestone-checks.ps1 -Milestone PS-194 -Profile Full
```

`Relevant` PASS (focused 1/1, regression 20/20), `Full` PASS (regression
158/158, toolchain 1/1). Marker: `PS193_BOSS_ATTACK_CADENCE_SMOKE_OK`.

Misura strumentale in run reale (non sostituisce il playtest): 8 preavvisi in
17.12s di tempo logico su Boss baseline, media 2.45s fra un preavviso e il
successivo. È più alta della media analitica 1.78s perché la finestra include
lo stream della Scia di Piume, 1.6s in cui il Boss attacca in continuo e il
cooldown non scorre. Log: `exports/ps194-capture.log`.

Diagnosi raccolta da ricognizione read-only (agente `ricognitore-progetto`,
sessione 2026-09-18), su segnalazione diretta del proprietario. Card correlate
ma non equivalenti: PS-182 (HP/durata scontro), PS-141 (qualità presentazione
telegraph), PS-181 (affidabilità telegraph), PS-163 (Boss reattivo al
personaggio, DA DEFINIRE), PS-126 (scala HP/danno oltre il minuto 5, non
cadenza), PS-124 (stesso principio di design, applicato agli eventi d'ondata).
