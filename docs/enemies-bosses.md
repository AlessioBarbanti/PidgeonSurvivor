# Nemici e Boss

Questo documento descrive gli archetipi nemici correnti e il sistema Boss
(baseline, varianti `Evil <Nome>`, Signature Ability). Non è un backlog: lo
stato operativo resta nella [board](./cards/README.md). Per la curva di
spawn nel tempo e la cadenza degli incontri Boss vedi
[systems-difficulty.md](./systems-difficulty.md).

## Archetipi nemici comuni

Sorgente dati: `data/enemies/*.tres` (`EnemyArchetypeDefinition`, schema in
[scripts/game/enemy_archetype_definition.gd](../scripts/game/enemy_archetype_definition.gd)).
Logica di movimento/combattimento comune in
[scripts/actors/base_enemy.gd](../scripts/actors/base_enemy.gd); sottoclassi
dedicate per `splitter_enemy.gd` e `ranged_enemy.gd`. Selezione e spawn in
[scripts/game/enemy_spawner.gd](../scripts/game/enemy_spawner.gd), pesi e
curva in `EnemySpawnProfile` (dettagli in
[systems-difficulty.md](./systems-difficulty.md)).

| Archetipo | HP | Velocità | Danno contatto | XP | Ruolo |
|---|---|---|---|---|---|
| Piccione base | 10.0 | 140.0 | 12.0 | — | Riempimento, peso dominante nei primi minuti |
| `swarmer` | 9.0 | 210.0 | 12.0 | 1 | Sciamatore, spawna in gruppi di 3 |
| `ranged` | 16.0 | 110.0 | 12.0 | 2 | Tiratore a distanza, telegrafa e spara |
| `armored` | 54.0 | 70.0 | 26.0 | 3 | Corazzato, lento e con HP alto |
| `splitter` | 26.0 | 130.0 | 18.0 | 2 | Divisore, genera 2 frammenti alla morte |
| `splitter_fragment` | 7.0 | 160.0 | 10.0 | 1 | Solo prodotto dalla morte di `splitter`, mai spawnato ordinariamente |

Fonti: `scenes/actors/base_enemy.tscn` (piccione base, righe 65-116),
`data/enemies/enemy_archetype_swarmer.tres`,
`data/enemies/enemy_archetype_armored.tres`,
`data/enemies/enemy_archetype_ranged.tres`,
`data/enemies/enemy_archetype_splitter.tres`,
`data/enemies/enemy_archetype_splitter_fragment.tres` (righe 41-51 di
ciascun file per stats/XP).

**Piccione base.** Non ha un `EnemyArchetypeDefinition` proprio: la scena non
applica alcun `apply_archetype_definition`. Peso nel pool pesato
`base_archetype_weight = 6.0` (default script
`enemy_spawn_profile.gd:102`, non sovrascritto nel `.tres`), ridotto a
`× 0.33` a curva late-run piena (vedi
[systems-difficulty.md](./systems-difficulty.md)).

**Sciamatore (`swarmer`).** `spawn_weight 1.4`, moltiplicatore late-run
`2.2`, eleggibile da `25s`; `spawn_cluster_size 3` fa generare tre istanze
insieme (`enemy_spawner.gd:263-269`). Nessuna sottoclasse dedicata, usa
`BaseEnemy` puro su `scenes/actors/configurable_enemy.tscn`.

**Corazzato (`armored`).** `spawn_weight 0.9`, moltiplicatore late-run
`1.4`, eleggibile da `40s`; nessuna meccanica oltre HP/danno elevati e
velocità ridotta. `BaseEnemy` puro.

**Tiratore (`ranged`).** Script dedicato `RangedEnemy extends BaseEnemy`
([scripts/actors/ranged_enemy.gd](../scripts/actors/ranged_enemy.gd)).
`spawn_weight 1.2`, moltiplicatore late-run `2.5`, eleggibile da `15s`. Ciclo
d'attacco: cooldown → telegraph (`0.6s`, anello disegnato) → verifica di
nuovo il range a fine telegraph → proiettile (`BossProjectile`, lo stesso
script condiviso col Boss). Parametri: `attack_range 420.0`,
`preferred_distance 320.0` (smette di avvicinarsi entro questa distanza),
`attack_interval 2.2s`, danno proiettile `8.0`, velocità `200.0`. **Garanzia
tardo-gioco**: da `180s`, se sono passati più di `4s` senza uno spawn
`ranged`, il prossimo spawn eleggibile lo forza
(`enemy_spawner.gd:344-362`).

**Divisore (`splitter`).** Script dedicato `SplitterEnemy extends BaseEnemy`
([scripts/actors/splitter_enemy.gd](../scripts/actors/splitter_enemy.gd)).
`spawn_weight 1.0`, moltiplicatore late-run `1.6`, eleggibile da `50s`. Alla
morte genera `split_fragment_count = 2` frammenti nella posizione di morte,
rispettando comunque `max_alive_enemies`. Il frammento (`splitter_fragment`)
ha `spawn_weight 0.0` ed è escluso dal pool ordinario per costruzione
(`is_eligible_at`); non può avere a sua volta un `split_fragment_definition`
non nullo (`enemy_archetype_definition.gd:147-151`), quindi la divisione non
è mai ricorsiva.

## Sistema Boss

File: `scripts/bosses/boss_definition.gd` (dati),
`scripts/bosses/boss_encounter.gd` (orchestrazione e risoluzione varianti),
`scripts/bosses/first_boss.gd` (`FirstBoss extends BaseEnemy`, istanza in
gioco), `scripts/bosses/boss_signature_definition.gd` /
`boss_signature_catalog.gd` / `boss_signature_registry.gd` (Signature
Ability).

### Baseline "Piccione Malvagio"

`data/bosses/first_boss.tres`: `id = "special_pigeon"`,
`title = "PICCIONE MALVAGIO"` (PS-026). Stats: `health_max 2400.0`,
`move_speed 85.0`, `collision_radius 46.0`, `contact_damage 25.0`.

Due pattern comuni, alternati senza Signature
(`_resolve_next_pattern_id`, `first_boss.gd:459-461`):

- **Raffica radiale**: `12` proiettili a 360° equidistanti dal centro,
  telegraph `0.75s`, danno `14.0` per proiettile.
- **Area mirata**: la posizione bersaglio si fissa all'inizio del telegraph
  (`1.0s`, posizione del player in quel momento); a fine telegraph chi è
  ancora entro `115.0` unità dal centro subisce `26.0` danni.

Con una Signature disponibile (variante Evil), il ciclo diventa a tre:
radiale → area mirata → Signature (`first_boss.gd:462-467`).

### Baseline vs `Evil <Nome>`

Risoluzione in `BossEncounter.resolve_variant`
(`boss_encounter.gd:161-201`): `evil_boss_chance = 0.5` (PS-037), RNG
deterministico seedato da seed-run + indice soglia
(`seed = run_seed ^ EVENT_SEED_SALT ^ ((schedule_index+1) *
SCHEDULE_SEED_FACTOR)`). Sotto soglia resta baseline; sopra soglia estrae un
`FriendDefinition` a caso fra gli otto profili validi di `FriendRegistry` e
duplica il `BossDefinition` in Evil (id `evil_<friend_id>`, colori e
telegraph dedicati magenta/viola, Signature risolta dal catalogo).

Profili confermati (uno-a-uno con `data/bosses/signatures/*.tres`): Alea,
Aleo, Bea, Lollo, Magno, Marghe, Migi, Zat — vedi
[characters.md](./characters.md) per identità e ruolo di ciascuno.

### Boss Intro: identità individuale (PS-051)

`BossUI.show_intro()` ([scripts/ui/boss_ui.gd](../scripts/ui/boss_ui.gd))
distingue le due varianti invece di mostrare soltanto titolo, citazione e CTA:

- **Piccione Malvagio**: mostra il proprio `portrait`
  (`BossDefinition.get_safe_portrait()`), nessuna icona Signature (non ha
  Signature) e nessun trattamento cromatico personale — titolo e cornice
  restano sul colore neutro.
- **`Evil <Nome>`**: mostra il ritratto risolto dal `FriendDefinition`
  (`friend_profile.get_public_evil_portrait()`), l'icona della Signature
  attiva (`BossSignatureDefinition.icon`) e tinge nome e cornice con
  l'`accent_color` della Signature, mescolato a bianco per restare leggibile.

Ritratto, icona o Signature mancanti fanno ricomporre la intro sugli elementi
restanti (slot nascosto, mai una texture nulla visibile o uno spazio vuoto
dedicato). La CTA "AFFRONTA" non cambia mai stile o colore in base al Boss. I
sedici asset coinvolti (otto `evil_portrait`, otto icone Signature) sono
segnaposto procedurali temporanei — stato dettagliato in
[visual-audio-identity.md](./visual-audio-identity.md); la sostituzione
definitiva è compito di
[PS-052](./cards/2_to_do/PS-052-genera-ritratti-evil-e-icone-signature.md).

### Signature Ability per profilo

Una sola Signature per profilo Evil, associata via `friend_id`
(`BossSignatureCatalog.resolve_for_friend`). Otto `effect_id`
(`boss_signature_registry.gd:11-18`):

| Profilo | Signature | `AreaMode` | Forma persistente (commento sorgente) |
|---|---|---|---|
| Magno | Onda d'Urto Tellurica | `EXPANDING_FRONT` | Fronte anulare che si espande dall'origine: danno e knockback una sola volta, quando il fronte attraversa il Player |
| Bea | Powerslide | `TRAIL_CORRIDOR` | Corridoio statico lungo la traiettoria del Powerslide: danno nel tempo |
| Zat | Tempesta di Tuoni | `INSTANT_BURST` | Colpo radiale istantaneo all'esecuzione, con coda solo visiva |
| Alea | Gran Piroetta | `FOLLOWING_CONTACT` | Aura ancorata al Boss che pulsa danno da contatto (Signature che muove il Boss stesso) |
| Aleo | Shock Termico | `TWO_PHASE_BURST` | Area statica in due fasi: prima rallenta, poi detona |
| Migi | Rallentamento Zen | `FOLLOWING_SLOW_ABSORB` | Aura ancorata al Boss: rallenta il Player e assorbe i proiettili alleati, senza mai infliggere danno |
| Lollo | Cosplay Casuale | `NONE` | Nessuna area propria: copia con RNG seedato la Signature di un altro profilo |
| Marghe | Reggaeton Time! | `NONE` | Nessuna area propria: spawna un clone (`clone_health`, `clone_offset`) invece di un'area |

Sette `AreaMode` distinti (`boss_signature_registry.gd:26-42`) coprono gli
otto `effect_id`: `NONE` è condiviso da Cosplay Casuale e Reggaeton Time!,
le uniche due Signature che non lasciano un'area persistente. **Cosplay
Casuale** è l'unica eccezione strutturale ulteriore: sceglie a runtime fra i
candidati copiabili escludendo sempre se stessa (`select_copy`,
`boss_signature_registry.gd:132-148`, seed da run+soglia+indice d'uso; la
regola di esclusione è che `RANDOM_COSPLAY` non è mai `is_copyable`, riga
78-81).

Valori numerici (telegraph `0.9-1.3s`, durata `1.0-6.0s`, danno `0-30` con
Cosplay/Reggaeton a `0` perché non infliggono danno diretto, raggio area
`0-420`) vivono in `data/bosses/signatures/*.tres` e non sono duplicati qui.
Due card di bilanciamento sono ancora aperte e **non riflesse** nei valori
correnti: `docs/cards/2_to_do/PS-024-riduci-danno-onda-urto-magno.md` e
`docs/cards/2_to_do/PS-025-aumenta-dimensioni-avvertimento-boss.md`.

### Cadenza incontri

Descritta per intero in [systems-difficulty.md](./systems-difficulty.md):
primo Boss a `02:00`, ricorrenza ogni `240s`, warning HUD dedicato. I Boss
non passano dallo spawner ordinario, quindi non hanno la scala XP di
`EnemySpawnProfile.get_experience_reward_scale()` applicata ai nemici
comuni.

## Eventi d'ondata (PS-008)

Layer separato e finito che compone temporaneamente pesi/settori dello
spawn ordinario, senza introdurre una seconda curva parallela. Contratto
completo già descritto in [prd.md](./prd.md) e
[systems-difficulty.md](./systems-difficulty.md); qui solo il riepilogo dei
tre eventi baseline (`data/wave_events/*.tres`):

| Evento | Durata | Telegraph | Formazione | Effetto sullo spawn ordinario |
|---|---|---|---|---|
| Accerchiamento | 10s | 2.5s (richiesto) | 8 `swarmer`, uno ogni 0.35s | Sostituito |
| Stormo laterale | 8s | Nessuno | 10 `swarmer`, uno ogni 0.25s | Ridotto (×1.5 intervallo) |
| Nido di tiratori | 14s | Nessuno (ogni tiratore mantiene il proprio) | Peso `ranged` ×4 nel pool esistente | Invariato |

Card: [docs/cards/4_to_test/PS-008-eventi-di-ondata.md](./cards/4_to_test/PS-008-eventi-di-ondata.md),
`IN VERIFICA` — i valori sopra sono quelli correnti nel codice/dati, ma la
loro validità di design (leggibilità percettiva) non è ancora confermata dal
proprietario.

## Ricompensa della sconfitta del Boss

La sconfitta di un Boss **non assegna esperienza**. L'unica ricompensa è la
Specialità di Barb (PS-012): `movement_slice._on_boss_defeated_for_barb_reward`
è collegato a `BossEncounter.boss_defeated` e chiama
`UpgradeService.queue_barb_reward()`, che apre lo stato `BARB_REWARD` (o accoda
l'offerta se la run non è `RUNNING` nello stesso istante). A Specialità
esaurite subentra il fallback a due bonus upgrade consecutivi già previsto da
PS-012 (`UpgradeService.BARB_BONUS_SELECTIONS`), pescati dallo **stesso pool**
del level-up ordinario (`UpgradeRegistry.get_eligible_definitions`).

La distinzione è deliberata e va preservata: il fallback concede due
**potenziamenti**, non esperienza né livelli. `select_barb_bonus_upgrade()` alza
solo il rank dell'upgrade scelto ed emette `upgrade_selected(..., 0)` con livello
`0`; non tocca `ExperienceSystem`. Accreditare XP al posto dei potenziamenti
falserebbe le altre metriche che dipendono dalla curva di esperienza (ritmo dei
level-up ordinari, scala di difficoltà, letture di bilanciamento), che devono
restare guidate dal solo drop dei nemici comuni.

Il Boss non passa dallo spawner ordinario, quindi non riceve nemmeno il drop XP
automatico di `ExperienceDropper`, riservato ai nemici osservati tramite
`EnemySpawner.enemy_spawned` (vedi
[systems-difficulty.md](./systems-difficulty.md)). L'`experience_amount = 50`
dichiarato su `scenes/actors/first_boss.tscn:31` è ereditato da `BaseEnemy` ma
resta **inerte**: nessun consumatore lo legge per il Boss.

**Nota storica.** `BossDefinition` dichiarava un campo `experience_reward` (50 in
`data/bosses/first_boss.tres`) letto da `BossEncounter._on_boss_died()`. PS-006 lo
rimosse insieme al meccanismo che lo leggeva, lasciando però due handler di
`movement_slice.gd` collegati con arità sbagliata al segnale `boss_defeated` — un
errore a runtime a ogni morte del Boss. PS-039 corresse l'arità e ripristinò la
concessione XP, interpretando la rimozione come regressione. PS-034 ha poi
stabilito, su richiesta esplicita del proprietario, che la rimozione era voluta:
la concessione XP è stata revocata, l'arità corretta da PS-039 resta.
