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

**Separazione ordinaria (PS-171/PS-174/PS-178).** I nemici non collidono
fisicamente fra loro: una spinta proporzionale alla sovrapposizione dei
cerchi li separa, con forza e tetto di velocita' comuni in `BaseEnemy`.
La ricerca usa una griglia da 64 px per RunController e si estende in base
ai raggi presenti; le celle seguono il movimento nello stesso tick.
Boss e clone-esca non appartengono alla popolazione indicizzata. Il costo
dipende dai vicini locali: una folla tutta coincidente resta un caso denso.
Questa ottimizzazione non modifica conteggi di spawn, HP, danni o velocita'.

| Archetipo | HP | Velocità | Danno contatto | XP | Ruolo |
|---|---|---|---|---|---|
| Piccione base | 10.0 | 140.0 | 12.0 | — | Riempimento, peso dominante nei primi minuti |
| `swarmer` | 5.0 | 210.0 | 7.0 | 1 | Sciamatore, spawna in gruppi di 3 |
| `ranged` | 9.0 | 110.0 | 7.0 | 2 | Tiratore a distanza, spara appena a tiro |
| `armored` | 31.0 | 70.0 | 15.0 | 3 | Corazzato, lento e con HP alto |
| `splitter` | 15.0 | 130.0 | 10.0 | 2 | Divisore, genera 2 frammenti alla morte |
| `splitter_fragment` | 4.0 | 160.0 | 6.0 | 1 | Solo prodotto dalla morte di `splitter`, mai spawnato ordinariamente |

**PS-123 (2026-09-07).** PS-076 aveva ricalibrato in proporzione (fattore
7/12) solo il piccione base dopo aver infittito lo spawn; questi cinque
valori sono stati ricalibrati con lo stesso fattore, arrotondato all'intero
più vicino (per difetto sui multipli esatti di 0.5, come già fatto per il
piccione: `18→10`, non `18→11`).

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
d'attacco: cooldown → appena il bersaglio è a tiro spara subito un
proiettile (`BossProjectile`, lo stesso script condiviso col Boss) → si
ricarica per `attack_interval` prima del colpo successivo. Nessun tempo di
telegraph né anello disegnato (rimosso su richiesta esplicita del
proprietario, PS-158): l'unico tell è il proiettile stesso in volo.
Parametri: `attack_range 420.0`, `preferred_distance 320.0` (smette di
avvicinarsi entro questa distanza), `attack_interval 2.2s`, danno proiettile
`8.0`, velocità `200.0`. Un proiettile già sparato è indipendente dal
Tiratore che lo ha lanciato: se questo muore in combattimento mentre la run
è ancora in corso, il colpo in volo non viene annullato con lui (solo un
vero restart pulisce anche i proiettili residui). **Garanzia tardo-gioco**:
da `180s`, se sono passati più di `4s` senza uno spawn `ranged`, il prossimo
spawn eleggibile lo forza (`enemy_spawner.gd:344-362`).

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
`title = "PICCIONE MALVAGIO"` (PS-026). Stats: `health_max 1500.0` (PS-182),
`move_speed 85.0`, `collision_radius 46.0`, `contact_damage 25.0`.

**PS-127 (2026-09-07).** Il baseline non è più pensato come la variante
"leggera" da pareggiare in probabilità con gli Evil: è un incontro raro
(vedi `evil_boss_chance` sotto) e deliberatamente più duro di ognuno di loro.
Cicla su **tre** pattern comuni, mai su due (`_resolve_next_pattern_id`,
`first_boss.gd`):

- **Raffica radiale**: `12` proiettili a 360° equidistanti dal centro,
  telegraph `0.75s`, danno `14.0` per proiettile.
- **Area mirata**: la posizione bersaglio si fissa all'inizio del telegraph
  (`1.0s`, posizione del player in quel momento); a fine telegraph chi è
  ancora entro `115.0` unità dal centro subisce `26.0` danni.
- **Scia di Piume**: terzo pattern nativo, esclusivo del baseline (mai
  aggiunto al ciclo degli Evil). Un ventaglio di `6` linee oblique
  (`feather_line_count`, mai allineate agli assi dell'arena, orientamento
  seedato da run+soglia+utilizzo) attraversa il campo dall'origine del Boss:
  ogni linea è una coppia di raggi opposti, quindi il ventaglio produce `12`
  direzioni. Tutte le linee telegrafano insieme (`0.9s`) e a fine preavviso
  sparano insieme una sequenza continua di `20` "battiti" (una piuma per
  ogni direzione a ogni battito, stessa `BossProjectile` condivisa col
  Tiratore), uno ogni `0.08s` — un solo slot del ciclo pattern, non
  allungato in più turni.

Il cooldown fra un pattern e l'altro è proprio del baseline
(`baseline_pattern_interval = 0.9s`, contro `pattern_interval = 1.4s`
ereditato dagli Evil): il baseline attacca più spesso di qualunque Evil a
parità di soglia.

**PS-193 (2026-09-20).** Un Boss attivo sospende del tutto lo spawn ordinario
(B53/PS-119), quindi è l'unico a fare il ritmo in quella finestra e deve
occuparla. I cooldown sono scesi da `1.6s`/`2.5s` a `0.9s`/`1.4s` e
`initial_attack_delay` da `1.5s` a `1.0s`; le durate di telegraph restano
invariate, perché sono il budget di leggibilità con cui il colpo si schiva.
L'intervallo medio fra un attacco risolto e il successivo passa così da
~2.48s a ~1.78s sul baseline e da ~3.48s a ~2.38s su un Evil. Resta un solo
preavviso alla volta: un nuovo pattern non parte mentre il Boss è in
Powerslide o in Piroetta.

**Specchio a doppio attacco.** Sceso sotto `split_health_ratio` (metà vita),
il baseline non genera una seconda entità: apre una seconda origine
"fantasma" che vaga attorno a sé (PS-194: sceglie un punto dell'anello fra
`split_ghost_min_distance` e `split_ghost_distance` e ci cammina verso a
`split_ghost_wander_speed`, cambiando meta prima di arrivarci, con percorso
seedato dal seed di run) e ripete da lì ogni pattern normale (raffica,
area mirata, Scia di Piume), raddoppiando la densità di proiettili/aree da
schivare senza raddoppiare gli HP totali dell'incontro né toccare
l'invariante "un solo Boss attivo" di `BossEncounter`/`GameDirector`.
Attivazione irreversibile per l'intero incontro, mai per gli Evil.

Con una Signature disponibile (variante Evil), il ciclo resta quello
esistente e **non cambia**: radiale → area mirata → Signature
(`first_boss.gd`). Nessuna delle modifiche PS-127 sopra (terzo pattern
aggiuntivo, cooldown ridotto, specchio a doppio attacco) si applica agli
Evil.

### Presentazione degli attacchi (PS-141/PS-144)

Ogni preavviso e ogni area attiva del Boss si disegnano con le stampe raster
di `BossAttackVisuals` (`scripts/bosses/boss_attack_visuals.gd`): anello di
pericolo, deflagrazione, mirino e nastro di corsia, più il VFX della Signature
annunciata. Convenzione valida anche per i pattern futuri:

- niente `draw_arc`, `draw_circle` o `draw_line` come rappresentazione di un
  attacco: erano il motivo per cui i telegraph si leggevano come wireframe di
  debug;
- l'intensità (opacità del tratto) sale con il countdown da `0.42` a `1.0`
  (`BossAttackVisuals.intensity`), mentre **la geometria resta congelata**:
  il confine del pericolo non avanza con il preavviso;
- i quattro raster sono in grigio neutro e vengono modulati dal colore
  runtime — `telegraph_color` del baseline o `EVIL_TELEGRAPH_COLOR` — così la
  distinzione Boss/Evil resta quella di sempre; i motivi Signature restano
  invece in tinta nativa, con il segnale perimetrale nel colore ostile;
- l'anello è ancorato al raggio autorevole del pattern (`ring_rect` deriva il
  quad dal raggio di gameplay), le corsie della Scia di Piume all'inviluppo
  reale del colpo (raggio della piuma più raggio del Player);
- un nastro di corsia viene ripetuto vicino alla proporzione nativa
  (`corridor_tiles`) invece di essere stirato per tutta la lunghezza.

### Baseline vs `Evil <Nome>`

Risoluzione in `BossEncounter.resolve_variant`
(`boss_encounter.gd`): `evil_boss_chance = 0.9` (PS-127, prima `0.5` da
PS-037 — il baseline è ora raro al 10% invece che paritario), RNG
deterministico seedato da seed-run + indice soglia
(`seed = run_seed ^ EVENT_SEED_SALT ^ ((schedule_index+1) *
SCHEDULE_SEED_FACTOR)`), applicato a ogni soglia Boss inclusa la prima.
Sotto soglia resta baseline; sopra soglia estrae un `FriendDefinition` a
caso fra gli otto profili validi di `FriendRegistry` e duplica il
`BossDefinition` in Evil (id `evil_<friend_id>`, colori e telegraph dedicati
magenta/viola, Signature risolta dal catalogo).

**Varietà delle identità Evil (PS-162):** l'estrazione esclude gli Evil già
incontrati più di recente in questa run (cronologia scene-local in
`BossEncounter`, azzerata al restart), con una finestra pari a
`min(profili_eleggibili - 1, incontri_già_registrati)`. Effetto pratico con
otto profili: nessuna ripetizione fra due incontri consecutivi, e i primi
otto incontri di una run esplorano sempre tutti e otto i profili prima che
uno possa ripetersi. La selezione resta interamente deterministica per
seed + `schedule_index`.

Profili confermati (uno-a-uno con `data/bosses/signatures/*.tres`): Alea,
Aleo, Bea, Lollo, Magno, Marghe, Migi, Zat — vedi
[characters.md](./characters.md) per identità e ruolo di ciascuno.

### Boss Intro: ritratto fluttuante (PS-176, sostituisce PS-051/PS-102/PS-103)

`BossUI.show_intro()` ([scripts/ui/boss_ui.gd](../scripts/ui/boss_ui.gd))
mostra il ritratto Boss (Evil `<Nome>` o Piccione Malvagio) per intero, in
`contain`, senza alcun pannello o cornice esterna: l'unica ornamentazione
visibile (ali, catene, gemme, cornice dorata) è quella già dipinta dentro il
file `1536×1024` fornito dal proprietario. La citazione
(`BossDefinition.get_safe_quote()`) è sovrapposta al ritratto tramite ancore
percentuali dentro il cartiglio scuro già dipinto nell'immagine, con un inset
di sicurezza lontano dai bordi. Titolo (nome Boss) e icona Signature non sono
più mostrati nella Boss Intro (rimossi dalla scena). Il bottone "AFFRONTA"
compare sotto il ritratto, mai sovrapposto.

- **Piccione Malvagio**: mostra `assets/art/characters/piccione_malvagio/generated/portrait.png`,
  risolto da `BossDefinition.get_safe_portrait()`.
- **`Evil <Nome>`**: mostra il ritratto risolto dal `FriendDefinition`
  (`friend_profile.get_public_evil_portrait()`).

Un ritratto mancante fa nascondere l'intero blocco ritratto+citazione senza
lasciare spazio vuoto dedicato. Gli otto `evil_portrait` e il ritratto del
Piccione Malvagio sono gli asset definitivi integrati da PS-176 (in
precedenza da [PS-052](./cards/5_completed/PS-052-genera-ritratti-evil-e-icone-signature.md)
per gli Evil e da PS-128/PS-129 per il baseline, entrambi sostituiti). Lo
stato artistico dettagliato resta in
[visual-audio-identity.md](./visual-audio-identity.md).

**Fascia HUD attenuata durante la Boss Intro (PS-180).** `GameHud` attenua
(non nasconde) la propria fascia superiore (timer, barre XP/HP, pausa — già
disabilitata in questo stato) mentre `RunController` è in `BOSS_INTRO`,
liberando lo spazio verticale che il ritratto usa per crescere: `BossUI` non
riserva più il margine che teneva libera quella fascia. L'arte opaca del
ritratto copre comunque la fascia dov'è più larga di lei; ai lati, dove le
barre occupano quasi tutta la larghezza dello schermo, restano visibili ma
attenuate — stesso trattamento (`GameHud.ABILITY_FADED_ALPHA`) già usato per
il controllo abilità sotto al Player, mai un nascondimento totale come negli
altri modali (level-up, ricompensa Barb e pausa restano invariati, HUD
sempre a piena opacità). La citazione condivisa da tutte le varianti
(PS-101) va a capo su più righe: senza questo spazio andava in clipping su
device reale a risoluzione fisica.

### Perché diventano Evil: la fame (PS-101)

Ogni `Evil <Nome>` non è cattivo per natura: ha fame. È il solo aggancio
narrativo alla trasformazione, coerente col tono leggero del gioco e col
tema griglia (`Barb`, `docs/prd.md` §3.3): il Player affronta l'amico per
fermarlo, non per punirlo, e la Specialità di Barb che il Boss lascia in
premio lo sfama e lo fa tornare come prima.

- La citazione resta **unica e condivisa** fra il Piccione Malvagio e tutti
  gli otto `Evil <Nome>`: `BossDefinition.get_safe_quote()` non fa alcun
  branch sul `friend_profile` (a differenza di `get_safe_title()`/
  `get_safe_portrait()`, che invece risolvono l'identità per amico) — la
  variante Evil eredita semplicemente il campo `quote` del Boss baseline via
  `duplicate(true)` in `BossEncounter.resolve_variant()`. Il proprietario ha
  scartato esplicitamente otto citazioni distinte per profilo in favore di
  una sola, a tema fame, valida per qualunque volto.
- La citazione vive in `data/bosses/first_boss.tres` (`quote`,
  `quote_approved`), a tema fame e **approvata** dal proprietario
  (`quote_approved = true`): `get_safe_quote()` la mostra per il Piccione
  Malvagio e per ogni `Evil <Nome>`, invece del fallback
  `safe_quote_placeholder`.
- Alla morte di un `Evil <Nome>`, `BossEncounter.get_last_defeated_friend_name()`
  espone il nome "buono" dell'amico appena redento (stringa vuota per il
  Piccione Malvagio, che non ha nessun amico da salvare). `BarbRewardOverlay`
  lo mostra in una riga sempre **positiva verso Barb**, mai un ammonimento
  sulla fame: "`<Nome>` è di nuovo tra noi, grazie a Barb!" (PS-166: forma
  neutra rispetto al genere del nome interpolato) quando un amico è
  stato redento, altrimenti la riga generica
  `BarbRewardOverlay.BARB_GENERIC_REWARD_LINE` ("Con Barb alla griglia, va
  sempre a finire bene!").

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
| Accerchiamento | 10s | 2.5s (richiesto) | 100 `swarmer`, uno ogni 0.1s | Ridotto (×1.15 intervallo) |
| Stormo laterale | 8s | Nessuno | 60 `swarmer`, uno ogni 0.1s | Ridotto (×1.1 intervallo) |
| Nido di tiratori | 14s | Nessuno | Peso `ranged` ×4 nel pool esistente | Invariato |

**PS-124 (2026-09-07).** I valori originali di Accerchiamento (`ordinary_spawn_mode`
*Sostituito*, 8 `swarmer` ogni 0.35s) e Stormo laterale (10 `swarmer` ogni
0.25s, ×1.5 intervallo) generavano meno nemici, nella propria finestra, di
quanti ne avrebbe generati lo spawn ordinario sostituito: un evento
telegrafato come minaccia si leggeva come una pausa. I nuovi valori
generano deliberatamente più corpi del riferimento ordinario equivalente
(margine ~1.3-1.5×, verificato da
[tests/unit/test_ps124_wave_event_pressure.gd](../tests/unit/test_ps124_wave_event_pressure.gd)).
Nido di tiratori non è cambiato: cambiava già solo la qualità della
minaccia, non la quantità.

Card: [docs/cards/5_completed/PS-008-eventi-di-ondata.md](./cards/5_completed/PS-008-eventi-di-ondata.md),
`COMPLETATO`; il ribilanciamento quantitativo di Accerchiamento e Stormo
laterale è tracciato separatamente in
[docs/cards/4_to_test/PS-124-eventi-ondata-che-riducono-la-pressione.md](./cards/4_to_test/PS-124-eventi-ondata-che-riducono-la-pressione.md).
Il gate percettivo su questi due eventi resta aperto lì.

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
