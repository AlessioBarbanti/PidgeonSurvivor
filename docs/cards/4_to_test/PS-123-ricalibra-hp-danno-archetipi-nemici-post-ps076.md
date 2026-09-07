---
id: PS-123
titolo: Ricalibra HP e danno degli archetipi nemici dopo la densificazione di PS-076
tipo: fix
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: []
origine:
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-123 — Ricalibra HP e danno degli archetipi nemici dopo la densificazione di PS-076

## Contesto

PS-076 ha densificato lo spawn (`base_spawn_interval` 0.60→0.35,
`min_spawn_interval` 0.12→0.07, `spawn_acceleration` 0.003→0.00175, fattore
12/7) dichiarando "rischio e budget XP equivalenti", e ha effettivamente
ricalibrato in proporzione HP e danno da contatto del piccione base
(`scenes/actors/base_enemy.tscn`, HP 18→10, contatto 20→12).

I quattro archetipi introdotti da PS-095/altre card
([data/enemies/enemy_archetype_swarmer.tres](../../../data/enemies/enemy_archetype_swarmer.tres),
`..._ranged.tres`, `..._armored.tres`, `..._splitter.tres`,
`..._splitter_fragment.tres`) non sono mai stati toccati dallo stesso
rescale: il loro `health_max`/`contact_damage` è identico a prima di PS-076.
Un'analisi quantitativa di bilanciamento (sessione 2026-09-07,
`analista-bilanciamento`) ha calcolato il flusso HP nemico in ingresso
(corpi/s × HP, pesi late-run inclusi) confrontando la curva pre/post PS-076:

| t | HP/s pre-PS-076 | HP/s ora | rapporto |
|---|---|---|---|
| 0:00 | 30.0 | 28.6 | 0.95× (piccione, corretto) |
| 1:00 | 57.5 | 79.9 | 1.39× |
| 2:40 | 212.7 | 318.3 | 1.50× |
| 5:00+ | 228.1 | 370.2 | 1.62× |

Il budget XP resta effettivamente invariato (`get_experience_reward_scale()`
compensa la frequenza 1:1). Il problema è solo il lato HP/danno degli
archetipi non piccione, che dal minuto 5 dominano il pool (a 5:00 il
piccione base è solo il 18.1% degli eventi di spawn).

## Comportamento atteso

Il flusso HP nemico in ingresso a ogni istante della curva late-run resta
entro una tolleranza ragionevole del flusso pre-PS-076 (la densificazione
cambia solo la cadenza degli incontri, non il totale di HP/danno da
smaltire), coerentemente con quanto già vero per il piccione base.

## Criteri di accettazione

- [x] `health_max` e `contact_damage` di `enemy_archetype_swarmer.tres`,
      `..._ranged.tres`, `..._armored.tres`, `..._splitter.tres` e
      `..._splitter_fragment.tres` sono scalati per lo stesso fattore 7/12
      già applicato al piccione base in PS-076. Valori finali (arrotondati
      all'intero più vicino, per difetto sui multipli esatti di 0.5 come già
      fatto per il piccione): swarmer HP 9→5 / danno 12→7; ranged HP 16→9 /
      danno 12→7; armored HP 54→31 / danno 26→15; splitter HP 26→15 / danno
      18→10; fragment HP 7→4 / danno 10→6. Vedi Decisioni per il dettaglio
      dell'arrotondamento.
- [x] Un test GUT verifica i valori esatti attesi per ciascun archetipo e,
      separatamente, che quei valori siano davvero derivati dal fattore 7/12
      applicato ai valori storici pre-PS-076 (non solo scelti a mano
      scollegati dal riferimento) — approccio più diretto e deterministico
      della simulazione del flusso HP/s pesato originariamente proposta in
      Verifica, che avrebbe duplicato la logica di selezione pesata dello
      spawner dentro il test stesso.
- [x] Il piccione base non viene toccato (già corretto da PS-076) — verificato
      dallo stesso test instanziando `base_enemy.tscn`.
- [x] Nessuna modifica a `base_spawn_interval`, `min_spawn_interval`,
      `spawn_acceleration`, pesi archetipo o `max_alive_enemies`.

## Ambito

- `data/enemies/enemy_archetype_swarmer.tres`, `..._ranged.tres`,
  `..._armored.tres`, `..._splitter.tres`, `..._splitter_fragment.tres`:
  solo i campi `health_max`/`contact_damage`.

Non toccare:

- `scripts/game/enemy_spawn_profile.gd` e le curve di spawn/pesi;
- `get_experience_reward_scale()` — non toccata da questa card; una card
  collegata ([PS-125](../6_rejected/PS-125-scala-xp-costante-lungo-la-curva-late-run.md))
  ne aveva proposto una modifica basata su una diagnosi rivelatasi sbagliata
  ed è stata scartata: questa funzione resta quella storica pre-batch;
- `scenes/actors/base_enemy.tscn` (piccione base, già corretto da PS-076).

## Verifica

- Smoke: `tests/unit/test_ps123_archetype_hp_rescale.gd` → marker
  `PS123_ARCHETYPE_HP_RESCALE_SMOKE_OK` — verifica i valori esatti di
  `health_max`/`contact_damage` dei cinque archetipi contro i valori attesi,
  verifica che quei valori siano coerenti col fattore 7/12 applicato al
  riferimento storico, e verifica che il piccione base resti invariato.
- Profilo minimo prima della chiusura: `Relevant` — eseguito insieme a
  PS-124/PS-126 (stesso batch), 53/53 verdi, nessun `SCRIPT ERROR`/
  `FATAL EXCEPTION` nei log. PS-125 era nello stesso batch alla prima
  esecuzione (54/54) ma è stata scartata dopo una riverifica indipendente.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run fino ad almeno 5 minuti,
      confrontare la sensazione di pressione con la baseline pre-PS-076 se
      possibile)
- [ ] Controllo percettivo richiesto: sì — nemici più fragili non devono
      leggersi come "troppo facili" rispetto alla cadenza più alta

## Decisioni

- **2026-09-07 — Aperta da un'analisi di bilanciamento quantitativa**, non
  da una segnalazione soggettiva. I numeri (flusso HP/s calcolato dai
  `.tres` reali, pesi late-run inclusi) sono nel report della sessione
  `analista-bilanciamento` del 2026-09-07; il fattore di correzione proposto
  (7/12) rispecchia esattamente quello già usato per il piccione in
  PS-076, per coerenza interna della stessa card.
- **2026-09-07 — Convenzione di arrotondamento.** `18×7/12=10.5` in PS-076 è
  stato arrotondato per difetto a `10` (non per eccesso a `11`), mentre
  `20×7/12=11.67` arrotonda senza ambiguità a `12`: PS-076 ha quindi
  scelto "arrotondamento normale, ma per difetto sui multipli esatti di
  0.5" invece dell'arrotondamento matematico standard. Questa card applica
  la stessa convenzione ai cinque archetipi per coerenza con l'unico
  precedente nel repository, invece di introdurne una diversa.

## Documenti sincronizzati

- [x] `docs/systems-difficulty.md`: nessuna modifica necessaria — la
      sezione "Spawn e curva di difficoltà" rimanda al contratto numerico di
      `prd.md` senza duplicare i valori per archetipo.
- [x] `docs/enemies-bosses.md`: tabella HP/danno/velocità aggiornata con i
      cinque valori ricalibrati e nota sulla card.

## Note

Il report segnala anche che, dopo il minuto 5, nessuna metrica di pressione
cresce più (curve congelate a `late_run_curve_full_seconds=300s`) mentre la
build del giocatore continua a scalare: quel problema è distinto e più
ampio, tracciato separatamente in [PS-126](../1_idea/PS-126-nessuna-scala-difficolta-oltre-5-minuti.md).
