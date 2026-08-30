# Archivio del piano di evoluzione del gameplay — B40–B54

> Proposta storica consolidata il 30 agosto 2026. Le attività correnti sono nel
> [snapshot del development plan](./development-plan-through-b54-2026-08-30.md) e nella [`board`](../cards/README.md).

**Stato:** proposta del 28 agosto 2026. Il proprietario ha approvato e fatto
implementare **B40**, **B41**, **B42**, **B43**, **B44**, **B45**, **B47** e
**B54** lo
stesso giorno; le relative voci sono ora in `development-plan.md`. Le altre
slice restano proposte e non sono avviabili prima della decisione richiesta
nella sezione 9.

## 0. Come si usa questo documento

Questo file è la linea guida di sviluppo per gli interventi di gameplay emersi
dalla revisione di design del 28 agosto 2026. Ha lo stesso registro di
[`development-plan-through-b54-2026-08-30.md`](./development-plan-through-b54-2026-08-30.md): ogni voce è una slice
incrementale con contratti verificabili, file coinvolti, marker di smoke e gate.

Regole di ingaggio:

- Le slice **non riscrivono** i backlog `B03–B39` già chiusi: ne estendono il
  comportamento. Un blocco `COMPLETATO` resta storico.
- Una slice diventa eseguibile solo quando è stata **approvata**, riportata in
  `development-plan.md` sezione 6 e — se tocca l'identità di un personaggio —
  registrata in [`content-approvals.md`](../content-approvals.md) e
  [`characters.md`](../characters.md).
- I valori numerici qui proposti sono **punti di partenza da playtest**, non
  contratti. Diventano autorevoli quando entrano in [`prd.md`](../prd.md) e nei
  `.tres`.
- Vale integralmente la Definition of Done della sezione 8 del piano di
  sviluppo, più i criteri aggiuntivi della sezione 6 di questo documento.

## 1. Perché queste slice, in breve

La revisione ha misurato quattro problemi strutturali. Ogni slice ne risolve uno
o più; la colonna «diagnosi» è il motivo per cui l'intervento esiste.

| Diagnosi | Misura | Conseguenza |
|---|---|---|
| **D1 — Un solo archetipo nemico** | `scenes/actors/` contiene `base_enemy` e il Boss | Rallentare, respingere, stunnare e deviare l'aggro producono lo stesso risultato osservabile: otto kit diventano otto varianti dello stesso gioco |
| **D2 — L'arma non regge le orde** | Build offensiva completa: `40 × 1,15^5 × 1,10^5 = 129,6` DPS → `7,20` kill/s contro `8,33` spawn/s al cap | La build è obbligata (danno + cadenza), ogni altra carta è dominata e il clear dipende solo dall'attiva |
| **D3 — Passive invisibili o nulle** | Marghe `−5%` HP nemico non cambia il numero di colpi necessari; Alea vale `+5,2%` medio; Magno e Migi equivalgono a `1,5–2` rank di carte comuni | Metà del roster non ha un'identità percepibile in partita |
| **D4 — La run non ha arco** | Spawn piatto dopo `02:40`; Boss ricorrente con gli stessi due pattern ogni `240 s` | Dopo tre minuti non cambia più niente: la run è ripetuta, non lunga |

Dettaglio della matematica in sezione 8.

## 2. Backlog proposto

Priorità con la stessa scala del piano: `P1` indispensabile per la prima
pubblicazione, `P2` desiderabile ma rinviabile.

| ID | Attività | Prio | SP | Dipende da | Criterio di accettazione sintetico | Diagnosi |
|---|---|---:|---:|---|---|---|
| B40 | Archetipi nemici e nemico a distanza | P1 | 13 | B28, B37 | Quattro archetipi dichiarati in dati, uno dei quali attacca a distanza con telegraph; spawn per archetipo pesato e seedato; nessuna collisione rigida fra nemici | D1 |
| B41 | Forme d'attacco dell'arma | P1 | 8 | B12, B40 | Perforazione, colpi multipli e almeno una via di clear ad area come carte; kill rate della build completa `≥ 9,6/s` | D2 |
| B42 | Passive misurabili: Marghe e Alea | P1 | 5 | B17A | Nessuna passiva è un no-op aritmetico; entrambe hanno un tell visibile; solo dati e controller passive | D3 |
| B43 | Tempesta di Tuoni con decisione | P1 | 8 | B18E, B18G | L'attiva di Zat richiede posizionamento o tempismo; il suo contributo al Boss scende sotto il `50%` della vita del Boss per finestra | D3 |
| B44 | Tell di stato e fasi: Aleo e Lollo | P2 | 5 | B17A, B18M | Lo stato termico e la fase di iperfocus sono leggibili senza contare i secondi; Cosplay è pianificabile | D3 |
| B45 | Identità dipendenti dai nemici: Bea, Migi, Magno | P2 | 8 | **B40** | Le tre riprogettazioni sono verificabili contro il nemico a distanza; nessun verbo duplicato nel roster | D1, D3 |
| B46 | Eventi d'ondata | P2 | 8 | B37, B40 | Formazioni annunciate e finite nel tempo su cadenza propria, sempre sopravvivibili; determinismo per seed | D4 |
| B47 | Statistiche base per profilo | P2 | 3 | B17A | `FriendDefinition` dichiara scarti di vita, velocità e cadenza; nessun valore hardcoded; reset pulito al cambio profilo | D3 |
| B48 | Record persistenti per personaggio | P2 | 5 | B33 | Tempo, livello e Boss migliori per profilo persistiti in `user://`; nessun potere persistente fra run | — |
| B49 | Texture per gli archetipi nemici speciali | P1 | 8 | B40 | Ogni archetipo speciale usa una texture pixel dedicata, leggibile alla massima densità anche senza affidarsi alla sola palette | D1 |
| B50 | Ostacoli leggibili e delimitatore dell'arena | P1 | 8 | B38 | Il filo dei panni collide solo sulle parti opache; le reti metalliche sono rimosse; un delimitatore discreto e coerente rende riconoscibile il confine dell'arena | — |
| B51 | Correzione direzione Powerslide di Bea | P1 | 3 | B18C, B18D | Lo scatto segue sempre l'ultima direzione vettoriale del Player al momento dell'attivazione, inclusi alto e basso | — |
| B52 | Playfield protetto dai controlli HUD | P1 | 3 | B18Q, B34 | Il Player non può entrare sotto il controllo abilità, compreso il limite inferiore destro della mappa | — |
| B53 | Sospensione delle orde durante il Boss | P1 | 3 | B33 | Lo spawn ordinario si ferma per tutta la presenza di un Boss attivo e riprende pulito alla sua uscita | D4 |
| B54 | Tutorial dal Welcome Screen | P1 | 8 | B18O, B32, B34, B40, B49 | Un pulsante secondario `TUTORIAL` apre da `BOOT` un carosello responsive che spiega obiettivo, comandi, progressione, nemici e Boss senza avviare una run | — |

**Ordine consigliato:** `B40 → B49 → B54 → B50 → B51 → B52 → B53 → B41 → B42 → B43 → B44 → B45 → B46 → B47 → B48`.
B40 è la dipendenza radice: B41, B45 e B46 producono metà del loro valore se
eseguite prima. B42, B43, B44 e B47 sono in gran parte modifiche di dati e
possono avanzare in parallelo a B40 se serve un risultato percepibile subito.
B54 viene dopo B49 per riusare le icone tutorial già prodotte per gli archetipi
speciali e descrivere soltanto comportamenti ormai autorevoli.

### Prossimo passo implementativo consigliato

**B49, B50, B51, B52 e B53 hanno il codice completo**, tutte con lo smoke
Relevant verde:

- **B49 — Texture per gli archetipi nemici speciali.**
  `EnemyArchetypeDefinition.sprite_frames` porta le quattro texture gameplay
  agli archetipi speciali tramite un nodo `EnemySprite` dedicato, con
  fallback sicuro al disegno procedurale per il frammento del divisore
  (privo di asset proprio). Dati e comportamento restano invariati.
- **B51 — Correzione Powerslide di Bea.** Il bug descritto non era più
  riproducibile nel worktree corrente: `fire_z_trail.gd` usava già il
  vettore persistente `get_last_movement_direction()`. Nessuna modifica di
  codice, solo verifica.
- **B52 — Playfield protetto dai controlli HUD.** Nuovo
  `Player.set_hud_exclusion()` traduce l'ingombro a schermo del controllo
  abilità in un rettangolo di mondo (centrato sulla camera corrente, stessa
  tecnica di `EnemySpawner.get_visible_reference_rect()`) ed espelle il
  Player da quella zona con il nuovo `ArenaWorld.push_circle_outside_rect()`.
- **B53 — Sospensione delle orde durante il Boss.** Nuovo
  `EnemySpawner.set_ordinary_spawn_suspended()`, collegato a
  `BossEncounter.boss_spawned`/`boss_defeated` da `movement_slice.gd`.
- **B50 — Ostacoli leggibili e delimitatore dell'arena.** Nuovo
  `StaticObstacle.collision_segments` per collidere solo sulle parti opache
  del filo dei panni; rimosse le due reti metalliche (`FenceWest`/
  `FenceEast`) e la relativa texture; nuovo delimitatore procedurale in
  `ArenaView` (bande derivate dal `world_rect`, texture-ready per l'icona
  ImageGen futura).

Per tutte e cinque resta aperto solo il gate non automatizzabile da qui: la
**verifica percettiva/fisica su Windows e Pixel 9** (orda densa per B49,
joystick+tap abilità simultanei per B52, playtest Boss con orda già presente
per B53, passaggio a piedi lungo tutto il bordo per B50), da completare prima
di chiuderle come `COMPLETATO` nel registro formale.

Il nuovo onboarding B54 è implementato e riportato in `development-plan.md`;
il prossimo passo è il controllo percettivo/input su Windows e Pixel 9. In
parallelo resta da generare l'icona
definitiva del delimitatore d'arena e assegnarla ad
`ArenaView.boundary_texture` (il codice B50 è già pronto a riceverla).
**B45** è stata implementata il 28 agosto 2026: dettaglio nella sezione
dedicata più sotto e in `development-plan.md`.

## 3. Slice di gameplay

### B40 — Archetipi nemici e nemico a distanza

Stato: `COMPLETATO`. È la dipendenza radice dell'intero piano.

**Obiettivo.** Dare al cast qualcosa contro cui essere diverso. Finché esiste un
solo nemico che cammina dritto addosso al Player, ogni verbo difensivo del
roster collassa su «il muro arriva un po' dopo».

Contratti:

- [x] Introdurre `EnemyArchetypeDefinition` in `res://data/enemies/`, sulla
      falsariga di `EnemySpawnProfile`: vita, velocità, raggio di collisione,
      danno da contatto, peso di spawn, finestra temporale di eleggibilità,
      texture e colori. Nessun valore hardcoded negli script.
      → implementato in `scripts/game/enemy_archetype_definition.gd`; il campo
      texture non è presente in questa prima slice (nessuna arte pixel
      disponibile), sostituito da `silhouette_kind` procedurale — vedi sotto.
- [x] Quattro archetipi minimi. **Sciamatore** veloce e fragile, in gruppo;
      **corazzato** lento con molta vita; **divisore** che alla morte genera due
      unità minori; **tiratore** che si ferma a distanza e spara un proiettile
      lento preceduto da telegraph. Il piccione attuale resta il profilo base e
      il suo comportamento non cambia.
      → `data/enemies/enemy_archetype_{swarmer,armored,splitter,ranged}.tres`
      più `enemy_archetype_splitter_fragment.tres` per il frammento del
      divisore; il piccione continua a passare da `EnemySpawner.enemy_scene`
      invariato.
- [x] Il **tiratore è obbligatorio** e non rinviabile: è la condizione che rende
      leggibili scudi, i-frame, knockback e zone difensive, cioè metà del
      vocabolario del cast. Riusa il layer proiettili ostili e i contratti di
      telegraph già esistenti per il Boss.
      → `scripts/actors/ranged_enemy.gd` riusa `scripts/bosses/boss_projectile.gd`
      e spara nello stesso contenitore `%BossProjectiles` già passato a
      `BossEncounter`.
- [x] `EnemySpawner` sceglie l'archetipo dall'RNG seedato della run, con pesi
      dati e finestre temporali: il profilo base domina i primi minuti e gli
      altri entrano progressivamente. Due run con lo stesso seed producono la
      stessa sequenza di archetipi.
      → pool pesato con `EnemySpawner.pick_weighted_index` (statica e
      testabile come `pick_sector_combination`), filtrato per
      `eligible_time_start/end`; determinismo verificato in
      `_b40_enemy_archetypes_smoke.gd`.
- [x] Il contratto B37 resta intatto: offset di inseguimento stabile per
      nemico, scheduler dei settori, **nessuna collisione rigida fra nemici**.
      → nessuna modifica a quella logica; verificato da `_b37_density_direction_smoke.gd`
      ancora verde.
- [x] Ogni archetipo è riconoscibile a colpo d'occhio alla densità massima per
      silhouette e movimento, non solo per palette (vincolo di accessibilità già
      in vigore: forma e pattern affiancano sempre il colore).
      → `BaseEnemy.silhouette_kind` e il ramo procedurale di `_draw()`:
      placeholder senza arte pixel dedicata, verifica percettiva su
      Windows/Pixel 9 ancora da eseguire (vedi gate).
- [x] Il cap `max_alive_enemies` e il budget XP frazionario di B28 restano
      autorevoli: il valore XP per archetipo è dato, non ricavato dalla vita.
      → `EnemyArchetypeDefinition.experience_amount` è un campo dichiarato;
      il cluster dello sciamatore e i frammenti del divisore rispettano
      comunque `max_alive_enemies`.
- [x] I proiettili ostili del tiratore mantengono la priorità visiva sopra i VFX
      alleati, come già imposto per il Boss.
      → stesso contenitore/ordine di disegno del Boss (`%BossProjectiles`),
      nessuna modifica alla priorità visiva esistente.

File coinvolti: `scripts/game/enemy_spawn_profile.gd`,
`scripts/game/enemy_spawner.gd`, `scripts/actors/base_enemy.gd`,
`scenes/actors/base_enemy.tscn`, nuove scene per archetipo,
`res://data/enemies/`.

Smoke: `_b40_enemy_archetypes_smoke.gd` → `B40_ENEMY_ARCHETYPES_SMOKE_OK`.
Copre: pesi e finestre temporali rispettati, sequenza deterministica per seed,
il tiratore spara solo entro raggio e con telegraph completo, il divisore genera
esattamente due unità e non ricorsivamente, nessun residuo dopo restart, cap
alive rispettato con tutti gli archetipi attivi.

Gate completati: regressione completa, export Windows, verifica percettiva
Windows e Pixel 9 con orde dense (leggibilità delle silhouette e dei telegraph
a densità massima), profiler su Pixel 9 per la nuova varietà di nodi.

Rischi: saturazione CPU/GPU dovuta a più scene distinte — mitigazione: profilo
prima di aggiungere il quarto archetipo, pooling solo su evidenza, come già
imposto da B28.

### B41 — Forme d'attacco dell'arma

Stato: `COMPLETATO`. Implementata il 28 agosto 2026 su richiesta diretta del
proprietario, senza attendere la decisione di perimetro §9 dato che B40 (sua
unica dipendenza) è già chiusa.

**Obiettivo.** Chiudere il deficit aritmetico di D2 e creare build diverse. Oggi
il mazzo utile è di circa quattordici carte, quasi tutte moltiplicatori, e la
build ottimale è sempre la stessa.

Contratti:

- [x] Aggiungere effetti di **forma** al `WeaponProfile` e alle carte:
      perforazione (il proiettile attraversa `N` bersagli con danno decrescente),
      colpi multipli (`N` proiettili con dispersione dichiarata), e almeno una
      via di **clear ad area** — esplosione alla morte o orbitale — raggiungibile
      **senza** dipendere dall'abilità attiva del personaggio.
      → `WeaponProfile` dichiara `base_pierce_count`, `base_pierce_damage_falloff`,
      `base_multishot_count`, `base_multishot_spread_degrees` (identità neutra,
      `default_weapon_profile.tres` invariato in gioco); tre carte nuove:
      `piercing_rounds` (perforazione, `data/upgrades/piercing_rounds.tres`),
      `double_barrel` (ventaglio deterministico, nessun RNG,
      `data/upgrades/double_barrel.tres`), `death_burst` (esplosione alla morte,
      `data/upgrades/death_burst.tres`). `WeaponController`/`Projectile` portano
      la logica runtime (mai sui `Resource` condivisi), coerente con
      `set_projectile_upgrade_modifiers`/Gossip già esistenti.
- [x] Obiettivo numerico verificabile: una build completa e coerente raggiunge
      un kill rate **`≥ 1,15 ×`** il rate di spawn al cap, cioè `≥ 9,6 kill/s`
      con i valori attuali. Sotto quella soglia il giocatore perde per
      aritmetica invece che per errore.
      → `WeaponController.calculate_full_build_kill_rate_per_second()` (funzione
      statica pura, stesso metodo zero-overkill dell'appendice) verificata dallo
      smoke con danno/cadenza al rank `5` storico più perforazione e ventaglio al
      cap runtime: risultato ampiamente sopra soglia, margine voluto per lasciare
      spazio a più build valide (valori di partenza da playtest, non bilanciati
      in questa slice).
- [x] Le nuove carte rispettano lo stacking moltiplicativo e i cap runtime già
      chiusi da PROG-006 e B12; non mutano i `Resource` condivisi e si azzerano
      a restart o cambio personaggio.
      → nuovi cap dichiarativi su `UpgradeEffectRegistry`
      (`max_weapon_pierce_count`, `max_weapon_multishot_count`,
      `max_weapon_death_burst_damage_multiplier`, `max_gossip_chain_jumps`);
      `WeaponController.reset_projectile_shape_modifiers()` azzera tutto a
      restart, verificato dallo smoke.
- [x] Introdurre una **gerarchia di rarità** sui pesi, oggi tutti `1.0`. È
      preferibile ad aggiungere altre carte piatte: rende le offerte memorabili e
      dà spazio a carte forti senza alzare la potenza media.
      → le tre carte forma entrano a `weight` `0.4–0.55` e Gossip rivalutato a
      `0.6`; le carte piatte esistenti restano a `1.0` invariate, creando la
      prima gerarchia a due fasce sui pesi.
- [x] Ogni nuova carta deve cambiare **come** si gioca, non **quanto** si fa.
      Una carta a rank multipli che offre solo un moltiplicatore va considerata
      riempitivo e non entra.
      → perforazione, ventaglio ed esplosione sono capacità qualitative (non
      moltiplicatori di uno stat esistente); i rank successivi al primo ne
      scalano l'estensione, non ne cambiano la natura.
- [x] `Gossip` va rivalutato in questo contesto: oggi è `max_rank 1` ed è
      l'unica carta con comportamento ad area. Con le forme disponibili può
      diventare un ramo a rank multipli.
      → `gossip_projectiles.tres` passa a `max_rank 3`, `repeatable = true`,
      parametro `chain_jumps_per_rank` (il rank `1` riproduce esattamente il
      valore storico `chain_jumps = 2`, nessuna regressione).

File coinvolti: `scripts/combat/weapon_profile.gd`, `scripts/combat/weapon_controller.gd`,
`scripts/combat/projectile.gd`, `scripts/progression/upgrade_effect_registry.gd`,
`data/upgrades/{piercing_rounds,double_barrel,death_burst,gossip_projectiles}.tres`,
`data/weapons/default_weapon_profile.tres`, `scenes/game/movement_slice.tscn`.

Smoke: `_b41_weapon_shapes_smoke.gd` → `B41_WEAPON_SHAPES_SMOKE_OK`. Copre: la
perforazione applica il danno una sola volta per bersaglio per proiettile, i
colpi multipli rispettano la dispersione seedata (dichiarata, deterministica —
nessun RNG), l'effetto ad area non colpisce due volte lo stesso nemico nello
stesso tick né il bersaglio fuori raggio, stacking e cap runtime, azzeramento a
restart, e un test aritmetico che verifica la soglia dei `9,6 kill/s`. Verificata
anche la regressione toccata (`_signature_upgrades_smoke`, `_damage_upgrade_smoke`,
`_upgrade_service_smoke`, `_upgrade_icon_refresh_smoke`, `_combat_slice_smoke`,
`_powerup_first_wave_smoke`, `_summer_grill_smoke`, `_upgrade_effects_smoke`,
`_complete_run_smoke`, `_level_progression_smoke`, `_ability_ranks_smoke`,
`_ability_visuals_smoke`): tutte verdi. Tre smoke pre-esistenti e scollegati da
questa slice (`_complete_roster_abilities_smoke`, `_player_survival_smoke`,
`_hud_smoke`) falliscono già nel worktree per lo stesso bonus vita massima di
Magno non azzerato al restart composto documentato da B40 (lavoro B47 in corso,
non toccato da questa slice).

Gate completati: regressione completa, export Windows e verifica percettiva su
Pixel 9 con densità massima — le nuove forme non coprono telegraph e proiettili
ostili. I placeholder procedurali sono stati sostituiti il 28 agosto con tre
icone ImageGen dedicate: spiedino con tre bocconi, doppia Costina e Coppa esplosiva.
Master HD, pipeline alpha/nearest-neighbor e hash sono registrati in
`assets/art/icons/upgrades/ASSET-MANIFEST.md`; il confronto percettivo delle
carte sul dispositivo è valido.

Il refresh supera lo smoke B41 dedicato e lo smoke B27 delle icone. La
regressione Relevant è `22/23`: resta rosso soltanto lo smoke B30 sullo sprite
visivo del nemico base, separato dai tre asset B41.

Rischi: comportamenti emergenti da combinazioni di forme. Mitigazione già
prevista dal registro rischi del piano: modificatori identificati, componenti
isolati, test a coppie e seed riproducibile. La perforazione e la catena Gossip
non compongono sullo stesso proiettile: se entrambe sono attive la catena ha
precedenza (scelta di implementazione, non ancora playtestata).

### B42 — Passive misurabili: Marghe e Alea

Stato: `COMPLETATO`. Non dipende da B40; è la slice a costo più basso con
risultato percepibile immediato.

**Obiettivo.** Rimuovere le due passive che non fanno ciò che il testo dichiara.
Entrambe le modifiche sono in gran parte `passive_parameters` più il controller
delle passive.

Contratti:

- [x] **Marghe.** `enemy_health_multiplier: 0.95` è un no-op dimostrabile: porta
      i nemici da `18` a `17,1` HP, ma con `10` danni a colpo servono due colpi
      in entrambi i casi, e con la build danno completa (`20,11`) ne serve uno in
      entrambi i casi. Cambia qualcosa solo se il danno per colpo cade nelle
      finestre `(17,1 ; 18]` o `(8,55 ; 9]`. Sostituire con un effetto della
      stessa fantasia — l'indebolimento — ma osservabile: un'aura che fa
      **subire più danno** ai nemici vicini, oppure i nemici uccisi vicino al
      Player che «si mettono a ballare», stun breve contagioso ai vicini.
- [x] **Alea.** Il valore atteso attuale è
      `(5/12) × (0,75 × 1,20 + 0,25 × 0,90) + (7/12) × 1,00 = 1,052`, cioè
      `+5,2%` medio: non si nota e non si gioca. Alzare la posta in entrambe le
      direzioni — buff grossi, malus veri — e dare al giocatore un modo di
      **influenzare il tiro**, per esempio i kill che caricano la probabilità
      positiva del prossimo effetto. Un personaggio che è il gioco d'azzardo deve
      far sentire la scommessa.
- [x] Entrambe ricevono un **tell obbligatorio**: icona di stato e/o aura che
      dichiari quando l'effetto è attivo e quale faccia è uscita. Una passiva
      senza tell non è un'identità.
- [x] Criterio di accettazione trasversale: nessuna passiva può essere
      approssimabile entro il `±20%` da due rank o meno di una carta comune
      esistente, e ognuna deve cambiare almeno un esito osservabile — un colpo in
      meno per uccidere, un colpo in più sopravvissuto — nella configurazione
      tipica della run.
- [x] Ogni nuova sorgente di casualità passa dall'RNG seedato della run.

File coinvolti: `scripts/content/friend_passive_controller.gd`,
`data/friends/marghe.tres`, `data/friends/alea.tres`, il livello VFX/HUD per i
tell.

Smoke: `_b42_measurable_passives_smoke.gd` → `B42_MEASURABLE_PASSIVES_SMOKE_OK`.
Copre: la passiva di Marghe cambia il numero di colpi necessari in almeno una
configurazione documentata, il tiro di Alea è deterministico per seed e la
carica dai kill si applica e si azzera, entrambi i tell si accendono e si
spengono con lo stato, nessun residuo fra run.

Gate completati: export Windows, verifica percettiva su Pixel 9 (i tell sono
leggibili a densità massima), aggiornamento di `characters.md` e
`content-approvals.md` perché cambia l'identità dichiarata di due profili.

### B43 — Tempesta di Tuoni con decisione

Stato: `COMPLETATO`.

**Obiettivo.** L'attiva di Zat è oggi un pulsante, non una decisione, e
appiattisce ogni scontro con il Boss.

Misura del problema: contro nemici da `18` HP, `50–70%` della vita massima *a
tutti* è un wipe dello schermo senza mirare e senza posizionarsi. Sul Boss da
`2400` HP il rank `1` fa `480` danni a lancio con cooldown `60 s`, cioè circa
`1920` danni nella finestra da `240 s`; il rank `5` fa `672` danni con cooldown
`50 s`, cioè `~3360` danni — **oltre il `140%` della vita del Boss, a
prescindere dalla build del giocatore**.

Contratti:

- [x] Riprogettare l'attiva in una delle due direzioni, a scelta del
      proprietario:
      **(a) tempesta vera** — colpi ripetuti su posizioni telegrafate lungo
      alcuni secondi, così il valore sta nel portarci sopra orde e Boss;
      **(b) risorsa guadagnata** — resta un wipe, ma **si carica col danno
      subito**, il che si sposa con la fantasia della passiva e la rende una
      risorsa da meritare invece che un timer.
      → scelta **(a)**: cinque fulmini telegrafati (rank 1) su posizioni
      fotografate all'attivazione con l'RNG seedato della run; il primo cade
      sempre sull'origine, i successivi a spirale nel raggio di tempesta.
- [x] Criterio numerico: il contributo dell'attiva alla vita del Boss deve
      scendere **sotto il `50%`** per finestra Boss al rank `5`, così che la
      build del giocatore torni a essere la variabile dominante.
      → `boss_max_health_damage_ratio` scende a `0,008–0,01` per fulmine;
      `ThunderStorm.calculate_boss_window_contribution_ratio()` verifica il
      tetto aritmetico nel caso peggiore a tutti i rank in
      `_b43_lightning_storm_smoke.gd`.
- [x] La passiva di Zat — `35%` del danno recuperabile dopo `3 s` — **non si
      tocca**: premia il disingaggio, ha una soglia chiara ed è leggibile. È
      buon design già in produzione.
- [x] Restano invariati tutti i contratti di accessibilità di B18E: flash
      singolo con alpha massimo `0,55` su Windows e `0,40` su Android, chiuso
      entro `0,30 s`, e l'opzione persistente **Flash ridotti** ad alpha `0,15`.
      Se la direzione (a) moltiplica gli impatti, il budget di flash complessivo
      per attivazione non può crescere.
      → un solo flash si accende, sul primo fulmine soltanto; i fulmini
      successivi hanno solo VFX locali, coperto da `_zat_thunder_storm_smoke.gd`
      aggiornato e da `_b43_lightning_storm_smoke.gd`.
- [x] I cinque rank restano snapshot completi e immutabili come da B18G; un
      effetto già avviato conserva lo snapshot dell'attivazione.
- [x] Verificare l'impatto su **Cosplay Casuale**: Lollo copia questa abilità e
      la modifica ne cambia il valore relativo.
      → Cosplay risolve il rank copiato (`1–3`) tramite lo stesso registry, che
      condivide RNG e `ArenaLayout`; la copia produce quindi una tempesta più
      piccola e meno fulmini, coerente con l'anzianità di rank più bassa già
      prevista per Cosplay. Nessuna modifica necessaria a `cosplay_accent.gd`;
      verificato da `_ability_visuals_smoke.gd` e dal roster completo.

File coinvolti: `scripts/abilities/lightning_storm.gd`,
`data/abilities/zat_lightning_storm.tres`,
`data/upgrades/ability_rank_zat_lightning_storm.tres`,
`docs/prd.md` sezione 3.4 e tabella B18G.

Smoke: `_b43_lightning_storm_smoke.gd` → `B43_LIGHTNING_STORM_SMOKE_OK`.
Estende lo smoke B18E esistente: bersagli risolti all'impatto, nessun impatto
tardivo dopo pausa/morte/restart, budget di flash entro i limiti di
accessibilità, e un test aritmetico sul tetto di contributo al Boss.

Gate completati: regressione completa, export Windows, **verifica manuale su
Pixel 9 con flash normali e ridotti** (gate già obbligatorio per questa abilità)
e playtest del Boss: la build torna a contare.

### B44 — Tell di stato e fasi: Aleo e Lollo

Stato: `PRONTO`.

**Obiettivo.** Due passive concettualmente buone che il giocatore non riesce a
leggere o a giocare.

Contratti:

- [x] **Aleo — tell termico.** Nulla sullo schermo dichiara oggi in quale
      modalità si trovi il Player. Aggiungere un tell inequivocabile: aura ciano
      per la fase fredda contro aura arancio per quella calda, leggibile a colpo
      d'occhio e alla densità massima.
      → Implementato come tinta dello sprite del personaggio
      (`FriendPassiveController.TINT_ALEO_HOT/COLD`, applicata via
      `Player.set_passive_state_tint`); verificato in smoke e per rendering
      diretto (screenshot Windows del 28 agosto 2026).
- [x] **Aleo — simmetria delle due fasi.** Le due metà oggi si contraddicono:
      sopra il `50%` HP si guadagna offesa (`×1,20` danno inflitto), sotto si
      guadagna difesa (`−25%` danno subito). Stare in salute è quindi *sempre*
      meglio e la fase fredda è quella che si cerca di evitare: la soglia non
      produce una scelta ma un premio di consolazione. Rendere la fase fredda
      **anche offensiva** — i brinati che muoiono esplodono, oppure i rallentati
      subiscono danno aumentato — così scendere sotto metà vita diventa tattica.
      → Implementato come aura fredda che erode periodicamente i nemici
      brinati nel raggio (`cold_aura_damage_per_second`), oltre a rallentarli;
      coperto dallo smoke esistente.
- [x] **Lollo — fase distratta giocabile.** La distrazione occupa in media il
      `42,9%` del tempo (`4,5 s` medi contro `6 s` di iperfocus) e non ha
      contromisure: è una tassa passiva. Dare un modo di accorciarla — un numero
      di kill, un pickup raccolto — così diventa un'interazione. La passiva è
      l'unica del roster che si sente già oggi e per il resto non va toccata.
      → Implementato: ogni kill accorcia la distrazione residua di
      `distraction_seconds_per_kill`, senza toccare l'iperfocus.
- [x] **Lollo — Cosplay pianificabile.** Copiare al rank `1–3` mentre tutte le
      altre attive arrivano al rank `5` rende l'attiva di Lollo
      strutturalmente la più debole a fine run, e per giunta a caso. Far sì che
      l'abilità copiata **si mantenga fino al lancio successivo**, mostrata
      nell'HUD («prossimo cosplay: Zat»), così il giocatore può pianificarci
      sopra invece di subire una slot machine.
      → La scelta è risolta in anticipo e sopravvive al cooldown
      (`AbilityEffectRegistry.prepare_pending_cosplay`/
      `get_pending_cosplay_ability_id`). Il tell HUD non usa testo: il layout
      del pulsante è congelato da B18K (niente etichetta nome), quindi
      `AbilityController.get_pending_cosplay_icon()` sostituisce l'icona
      generica di Cosplay con quella dell'abilità che verrà copiata —
      aggiunto in questa sessione e coperto dallo smoke esteso.
- [x] Restano invariati i filtri anti-ricorsione e di compatibilità di Cosplay e
      la regola per cui non trasferisce rank.
      → Non toccati: `_get_cosplay_candidates` e la logica di rank restano
      quelli preesistenti.
- [x] Le fasi restano legate al clock di gameplay: pausa, level-up, `BOSS_INTRO`
      e stati terminali non le fanno avanzare.
      → Coperto dallo smoke per l'aura di Aleo (nessun avanzamento durante
      pausa manuale); `FriendPassiveController._process` è già gated su
      `RunController.is_running()` per l'intero controller, Lollo incluso.

File coinvolti: `scripts/content/friend_passive_controller.gd`,
`scripts/abilities/ability_controller.gd`, `scripts/abilities/cosplay_accent.gd`,
`data/friends/aleo.tres`, `data/friends/lollo.tres`,
`data/abilities/lollo_random_cosplay.tres`, HUD dell'abilità attiva.

Smoke: `_b44_state_tells_smoke.gd` → `B44_STATE_TELLS_SMOKE_OK`. Copre: il tell
termico segue la soglia in entrambe le direzioni, la fase fredda applica anche
l'effetto offensivo, la riduzione della distrazione si accumula e si azzera, il
cosplay memorizzato sopravvive al cooldown e viene esposto all'HUD, tutto si
ferma fuori da `RUNNING` e non lascia residui.

Gate: regressione completa, export Windows, verifica percettiva su Pixel 9 —
i due tell devono essere distinguibili con orde dense e VFX attivi.
→ Regressione B44 `Relevant` eseguita il 28 agosto 2026: 29/30 smoke passano;
`_complete_roster_abilities_smoke` fallisce su "Il pannello roster deve
restare nella safe area". La causa non è collegata a B44: sia quel file di
smoke sia `scripts/game/arena_world.gd` risultano già modificati da altro
lavoro in corso non ancora committato (verosimilmente il draft B52 o il
refresh recente dei ritratti/carosello), da isolare a parte prima di poter
dichiarare la regressione completa pulita. Export Windows e verifica
percettiva Pixel 9 restano da fare.

### B45 — Identità dipendenti dai nemici: Bea, Migi, Magno

Stato: `COMPLETATO`. Implementata il 28 agosto 2026 su richiesta diretta del
proprietario, con attenzione particolare a Migi.

Contratti:

- [x] **Bea — Sesto Senso Equino.** Il `15%` di evasione era RNG invisibile: non
      si percepiva mai e quando salvava la run il giocatore non lo sapeva.
      Sostituito con un effetto deterministico, mantenendo il `passive_title`
      **Sesto Senso Equino**:
      a cooldown dichiarato (`dodge_cooldown: 9.0`), il primo colpo che
      starebbe colpendo Bea viene annullato; Bea scarta automaticamente lontano
      dalla fonte del pericolo (`shove_distance: 90.0`) e riceve un breve
      i-frame (`iframe_duration: 0.4`).
      → `FriendPassiveController._trigger_instinctive_dodge()` sostituisce il
      tiro RNG in `resolve_incoming_damage()`; `Player.take_contact_damage()`
      guadagna un parametro opzionale `source_position` (passato da
      `ContactDamage`, `BossProjectile.try_hit()` e `FirstBoss._execute_targeted_blast()`)
      per calcolare la direzione di fuga.
- [x] Il Sesto Senso Equino ha un tell obbligatorio — nuovo
      `InstinctiveDodgeAccent` (sagoma a ferro di cavallo + scia viola
      procedurali, cablato da `movement_slice.gd` sul segnale
      `instinctive_dodge_triggered`) — e una durata di invulnerabilità
      dichiarata concessa da `HealthComponent.grant_invulnerability()` (nuovo,
      necessario perché un colpo annullato non passa da `take_damage()`). Se
      non esiste una destinazione sicura, `Player.try_shove_to_safe_position()`
      non sposta Bea (confinamento mondo/HUD via `ArenaWorld` più un controllo
      contro gli ostacoli statici, gruppo `static_obstacles`): il colpo resta
      comunque annullato e l'i-frame comunque concesso. Il cooldown impedisce
      salvataggi concatenati. Cue audio `GameAudio.DODGE` predisposto, in
      attesa di un asset (non ancora nella lista di `has_complete_cue_set()`).
- [x] Il **Powerslide** resta la manovra volontaria, lunga e offensiva:
      nessuna modifica a `fire_z_trail.gd`, nessuna seconda carica.
- [x] **Migi.** La riduzione danno del `10%` equivaleva a meno di due rank di
      `reinforced_roasting_tray` (`0,94² = 0,884`, cioè `11,6%`), e il
      Rallentamento Zen duplicava il verbo della fase fredda di Aleo e della
      carta Ritardo Cronico. Redesign a **tre scale dello stesso verbo,
      assorbire**, mantenendo il soprannome parodico «Tartarughina»:
      **(1) guscio piccolo** — la riduzione flat diventa un accumulo di
      cariche (`shell_charge_max: 2`, `shell_charge_regen_seconds: 12.0`) che
      annullano un colpo intero invece di scalarlo di una percentuale
      invisibile; **(2) guscio grande** — lo scudo d'emergenza sotto soglia HP
      resta invariato nei numeri ma riceve finalmente un tell (il segnale
      `shield_changed` non aveva alcun consumer in tutto il repo); **(3) guscio
      condiviso** — Rallentamento Zen (nuovo `AreaMode.FOLLOWING_SLOW_ABSORB`
      in `AbilityAreaEffect`) continua a rallentare e in più assorbe
      (`BossProjectile.expire()`, già pubblico e idempotente) i proiettili
      ostili nel raggio, compresi quelli del Boss — scelta deliberata, da
      confermare in playtest se troppo forte. Entrambi i livelli passivi
      riusano il sistema di tint già in produzione per Aleo/Lollo/Alea.
      Diventa una funzione che nessuna carta replica — «la tasca sicura da cui
      combatti» — e ha senso solo dopo B40.
- [x] **Magno.** La passiva `×1,15` velocità equivaleva a circa un rank e
      mezzo di `swift_steps`. Resa **espressiva**: `Player` traccia
      `_momentum_ratio` (0..1), che sale muovendosi entro una soglia angolare
      dalla direzione precedente e decade cambiando bruscamente o fermandosi;
      la passiva interpola fra `move_speed_multiplier: 1.0` e
      `max_move_speed_multiplier: 1.35` in base al momentum corrente, letto
      ogni frame. L'Onda d'Urto Tellurica legge `source.get_momentum_ratio()`
      al lancio (stesso pattern già usato da `FireZTrail` per la direzione
      persistente) e scala danno/knockback fra il valore dichiarato e
      `momentum_damage_bonus_max`/`momentum_knockback_bonus_max` (`0,5`/`0,4`
      su tutti i rank). Tell: scia procedurale disegnata da `Player._draw()`,
      attiva solo quando la passiva equipaggiata è quella di Magno.
- [x] Verifica trasversale: nessun verbo del roster è duplicato. Bea ora nega
      un colpo a cooldown lungo (evento singolo), Migi nega colpi a cariche
      frequenti più uno scudo d'emergenza (difesa personale ricorrente) più
      un'area che assorbe proiettili (unica nel roster), Magno scala con il
      movimento (nessun'altra passiva lo fa). Rallentamento Zen continua a
      condividere il verbo "rallenta" con Aleo/Ritardo Cronico ma non è più
      l'unico verbo della sua identità.
- [x] Ogni personaggio resta giocabile fino alla fine della run senza
      contare sull'attiva perfetta: l'attiva amplifica un piano (scudo di
      Migi, slancio di Magno, riposizionamento di Bea), non lo sostituisce.

File coinvolti: `scripts/content/friend_passive_controller.gd`,
`scripts/actors/player.gd`, `scripts/components/health_component.gd`,
`scripts/components/contact_damage.gd`, `scripts/bosses/boss_projectile.gd`,
`scripts/bosses/first_boss.gd`, `scripts/game/obstacles/static_obstacle.gd`,
`scripts/abilities/ability_area_effect.gd`,
`scripts/abilities/ability_effect_registry.gd`,
`scripts/abilities/instinctive_dodge_accent.gd` (nuovo),
`scripts/audio/game_audio.gd`, `scripts/vfx/presentation_timings.gd`,
`scripts/game/movement_slice.gd`, `data/friends/{bea,migi,magno}.tres`,
`data/abilities/{migi_zen_slowdown,magno_earthquake_shockwave}.tres`.

Smoke: `_b45_role_identity_smoke.gd` → `B45_ROLE_IDENTITY_SMOKE_OK`, verde.
Copre: il Sesto Senso Equino di Bea annulla il primo colpo eleggibile, concede
l'i-frame, rispetta il cooldown e rifiuta un input di scarto senza direzione
valida senza spostare il Player; le cariche del guscio di Migi bloccano colpi
interi, si ricaricano nel tempo dichiarato e non lasciano residui al restart;
la zona di Migi assorbe un proiettile ostile fixture e per costruzione non può
mai assorbire un proiettile alleato (gruppi distinti); lo slancio di Magno si
accumula muovendosi dritto, decade cambiando direzione o fermandosi, e la sua
saturazione fa infliggere all'Onda d'Urto Tellurica più del danno dichiarato
al rank equipaggiato. Regressione toccata e aggiornata:
`_complete_roster_abilities_smoke.gd` (guscio a cariche invece della vecchia
riduzione flat, cooldown di Bea invece del tiro RNG, rampa di slancio di
Magno), `_b47_base_stats_smoke.gd`, `_ability_visuals_smoke.gd` (manifest VFX
con il nuovo hash di `ability_area_effect.gd` e la voce per il nuovo
`instinctive_dodge_accent.gd`) e `_character_select_refinement_smoke.gd`
(testi di Magno accorciati per il vincolo di dimensione uguale fra le due
card). Restano rosse tre smoke pre-esistenti e scollegate da questa slice
(`_complete_roster_abilities_smoke.gd` per il pannello roster fuori safe area
in headless, `_player_survival_smoke.gd` e `_hud_smoke.gd` per il bonus vita
massima di Magno non azzerato al restart, già noto da B40/B41): confermato
che falliscono identicamente sulla baseline pre-B45.

Gate: regressione completa, export Windows, **verifica manuale su Pixel 9** —
Sesto Senso Equino e i-frame del Powerslide vanno provati con touch reale; playtest
contro il tiratore per confermare che le tre identità si distinguano.

### B46 — Eventi d'ondata

Stato: `PRONTO`. Dipende da B37 (esiste già lo scheduler dei settori) e da B40
per la varietà di archetipi.

**Obiettivo.** Dare un arco alla run. Oggi lo spawn è piatto dopo `02:40` e i
Boss si ripetono ogni `240 s` con gli stessi due pattern: al minuto 10 non è
successo niente di nuovo dal minuto 3.

Contratti:

- [ ] Un evento è una **formazione riconoscibile, annunciata e finita nel
      tempo**: anello che si chiude, colonna compatta da un lato, ondata di soli
      sciamatori, comparsa di un gruppo di corazzati.
- [ ] Gli eventi ricorrono su una **cadenza propria**, indipendente dalla
      finestra Boss di `240 s` di B33, così che i minuti fra un Boss e l'altro
      non siano piatti. Non possono sovrapporsi a `BOSS_INTRO`.
- [ ] Ogni evento deve poter essere **sopravvissuto giocando bene**, non
      soltanto assorbito: deve esistere un varco, una direzione sicura o una
      finestra temporale. È il criterio che B37 ha già aperto come playtest
      («varco apribile») e che qui va chiuso.
- [ ] L'evento riusa lo scheduler dei settori di B37 e il suo RNG seedato: due
      run con lo stesso seed producono la stessa sequenza di eventi.
- [ ] L'annuncio dell'evento rispetta la priorità visiva già in vigore: non
      copre telegraph né proiettili ostili, e non introduce un overlay
      fullscreen oltre a quello di Zat.
- [ ] Cap `max_alive_enemies` e budget XP frazionario di B28 restano
      autorevoli anche durante un evento.

File coinvolti: `scripts/game/game_director.gd`,
`scripts/game/enemy_spawner.gd`, `scripts/game/game_director_profile.gd`,
`data/director_profiles/`, nuovo `res://data/wave_events/`.

Smoke: `_b46_wave_events_smoke.gd` → `B46_WAVE_EVENTS_SMOKE_OK`. Copre: cadenza
indipendente dalla finestra Boss, nessuna sovrapposizione con `BOSS_INTRO`,
sequenza deterministica per seed, esistenza di almeno un settore libero per ogni
formazione, cap alive rispettato, nessun residuo dopo restart.

Gate: regressione completa, export Windows, profiler e verifica percettiva su
Pixel 9 durante il picco di un evento.

### B47 — Statistiche base per profilo

Stato: `PRONTO`. Slice piccola, quasi interamente dati.

**Obiettivo.** Oggi `FriendDefinition` non ha campi di statistiche base: tutti e
otto i profili partono con `100` HP, stessa velocità e stessa arma. La
differenziazione comincia solo con passiva e attiva.

Contratti:

- [x] Aggiungere a `FriendDefinition` un gruppo `Base Stats` con scarti
      dichiarativi su vita, velocità di movimento e cadenza di fuoco, tutti con
      default neutro `1.0` così che i profili non aggiornati restino identici a
      oggi.
      → `base_health_multiplier`/`base_move_speed_multiplier`/
      `base_fire_rate_multiplier` in `friend_definition.gd`, con
      `_sanitize_base_stat_multiplier` che normalizza valori non finiti o
      fuori `[MINIMUM_BASE_STAT_MULTIPLIER, MAXIMUM_BASE_STAT_MULTIPLIER]` al
      neutro/ai limiti.
- [x] Gli scarti compongono **moltiplicativamente** con passive e upgrade,
      secondo la regola di stacking già chiusa da PROG-006, e non mutano i
      `Resource` condivisi.
      → Catena verificata: `Player.get_base_move_speed()` = base condivisa ×
      `_character_move_speed_multiplier` (passiva + scarto, impostato da
      `friend_passive_controller.gd:686`), poi `_recalculate_effective_stats()`
      applica sopra il moltiplicatore upgrade (`move_speed = get_base_move_speed()
      * _move_speed_multiplier`). Stessa struttura per il fuoco:
      `WeaponController.get_effective_shots_per_second()` = base ×
      `_character_fire_rate_multiplier` (scarto) × `_fire_rate_multiplier`
      (upgrade).
- [x] Restart e cambio personaggio riportano le statistiche al profilo
      selezionato senza residui, come già imposto per passive e rank.
      → `Player.reset_character_stat_multipliers()` /
      `WeaponController.reset_character_stat_multipliers()`, coperti dallo
      smoke (cambio Magno → Alea, poi rimozione profilo torna alla baseline
      di scena).
- [x] Gli scarti restano **piccoli e leggibili** — l'ordine di grandezza è
      `±10–15%` — e sono coerenti col ruolo dichiarato in `characters.md`:
      Magno più duro e più lento del nominale, Bea più fragile e più rapida, e
      così via.
      → Valori dichiarati in `data/friends/*.tres`: Magno `1.15/0.95/1.0`,
      Bea `0.9/1.1/1.0`, Zat `1.1/0.95/1.0`, Aleo `1.1/0.95/1.05`, Lollo
      `0.9/1.05/1.05`, Migi `1.15/0.9/0.95`, Marghe `0.95/1.0/1.1`, Alea
      resta il profilo neutro `1.0/1.0/1.0`. Tutti dentro `±15%` e coerenti
      con `characters.md`.
- [x] La selezione mostra gli scarti sulle card del carosello soltanto se ciò
      non riapre il layout congelato di B18W/B34: in caso contrario, rinviare la
      presentazione a una slice UI dedicata.
      → Rinviato: nessun riferimento agli scarti in `scripts/ui/`, il
      carosello resta quello congelato da B18W/B34.

File coinvolti: `scripts/content/friend_definition.gd`,
`scripts/content/friend_registry.gd`, `scripts/actors/player.gd`,
`data/friends/*.tres`.

Smoke: `_b47_base_stats_smoke.gd` → `B47_BASE_STATS_SMOKE_OK`. Copre: default
neutro per un profilo senza scarti, composizione moltiplicativa con passiva e
upgrade, cap runtime rispettati, reset completo a restart e cambio profilo.

Gate: regressione completa, export Windows, playtest di confronto fra almeno tre
profili.
→ Regressione B47 `Relevant` eseguita il 28 agosto 2026: 29/30 smoke passano;
stesso fallimento non collegato già osservato per B44
(`_complete_roster_abilities_smoke`, "pannello roster fuori dalla safe area",
causa in lavoro non committato estraneo a questa slice). Export Android debug
(`exports/android/pidgeon-survivor-debug.apk`, SHA-256
`F30BDD4AF0AC1E8EAAA8BA8B4EDFC81F79DC38CABD62063F03071DFAB85BC20F`) e
installazione/cold launch reali sul Pixel 9 completati lo stesso giorno:
`B18O_WELCOME_SHOWN` e `B17A_READY os=Android ... seed=0` in logcat, 60 FPS
stabili nei campioni `B18V_PERF_SAMPLE`, schermata welcome interamente
leggibile a `2424×1080`. Export Windows e playtest di confronto fra profili
restano da fare.

### B48 — Record persistenti per personaggio

Stato: `RIFIUTATO`.

**Obiettivo.** Dare un motivo di rigiocare senza introdurre potere persistente.
In un gioco che è una presa in giro degli amici del proprietario, la classifica
**è** la battuta.

Contratti:

- [ ] Persistere per ciascun profilo tempo migliore, livello massimo raggiunto e
      numero di Boss uccisi, in `user://` con la stessa disciplina già usata da
      `audio_settings.cfg` e `touch_control_settings.cfg`.
- [ ] **Nessun potere persistente fra run**: la slice non incrina il contratto
      B18G, per cui il rank resta nella run e non esiste meta-progressione. Si
      registra un risultato, non si sblocca una statistica.
- [ ] I record sono mostrati nella welcome o nella selezione senza riaprire il
      layout congelato di B18W/B34, e nella schermata terminale della run.
- [ ] Un file assente, corrotto o di versione precedente non impedisce l'avvio:
      fallback a record vuoti, come per le altre autorità persistenti.
- [ ] I record seguono il profilo, non il dispositivo: nessun dato personale
      oltre al nome del profilo già approvato.

File coinvolti: `scripts/app/` per l'autorità persistente,
`scripts/game/run_controller.gd` per l'aggancio ai terminali, UI di welcome,
selezione e schermate finali.

Smoke: `_b48_profile_records_smoke.gd` → `B48_PROFILE_RECORDS_SMOKE_OK`. Copre:
scrittura al termine della run, aggiornamento solo in miglioramento, file
mancante o corrotto gestito con fallback, nessun effetto sulle statistiche di
gameplay della run successiva.

Gate: regressione completa, export Windows, verifica su Pixel 9 di persistenza
attraverso chiusura, lock e riavvio dell'app.

### B49 — Texture per gli archetipi nemici speciali

Stato: `PRONTO`. Dipende da B40: sostituisce esclusivamente le silhouette
procedurali provvisorie degli archetipi speciali, senza ribilanciarne dati o
comportamento.

**Obiettivo.** Rendere riconoscibili sciamatore, corazzato, divisore e tiratore
anche nella lettura rapida di un'orda, con texture pixel coerenti con l'arena e
con il piccione base. La texture non deve essere l'unico canale distintivo:
silhouette e movimento restano parte del contratto B40.

Contratti:

- [x] Preparare le quattro **icone tutorial** degli archetipi in
      `assets/art/icons/enemies/generated/`:
      `enemy_{swarmer,armored,splitter,ranged}.png` (`128×128` RGBA). I master
      sono in `assets/art/icons/enemies/hd/`; sono asset UI per il tutorial e
      non devono essere usati come texture nell'arena.
- [x] Preparare le quattro texture gameplay nello stesso formato dei piccioni
      esistenti: `assets/art/enemies/pigeons/pigeon_{swarmer,armored,splitter,ranged}.png`,
      strip RGBA `144×48` con tre pose (`ali su`, `neutra`, `ali giù`). I master
      e le sorgenti chroma sono in `assets/art/enemies/pigeons/hd/`, esclusi da
      import ed export.
- [x] Assegnare le texture gameplay ai rispettivi archetipi speciali; le
      varianti e gli eventuali frammenti del divisore non devono essere
      scambiabili a colpo d'occhio con il piccione base o con un altro
      archetipo.
      → `EnemyArchetypeDefinition.sprite_frames` (nuovo campo, opzionale)
      porta lo `SpriteFrames` dedicato di ciascun archetipo speciale, montato
      su un nodo `EnemySprite` aggiunto a `configurable_enemy.tscn`,
      `splitter_enemy.tscn` e `ranged_enemy.tscn`; `apply_archetype_definition`
      lo assegna a runtime. `BaseEnemy.has_visual_sprite()` ora richiede anche
      `sprite_frames != null`, cosicché il frammento del divisore — stessa
      scena condivisa, nessuna texture propria — resti sul disegno procedurale
      invece di apparire vuoto o di ereditare a sorpresa una texture altrui.
- [x] Conservare hitbox, raggi, velocità, vita, danno, pesi, finestre di spawn,
      XP e comportamento dichiarati in B40: è una sostituzione artistica, non
      una modifica nascosta al gameplay.
      → Verificato per confronto diretto dei quattro `.tres` in
      `data/enemies/`: `sprite_frames` è l'unico campo aggiunto rispetto a
      B40, nessun valore di bilanciamento è cambiato.
- [ ] Registrare asset sorgente, prompt o autore, trasformazioni, licenza e
      hash nel manifest; verificare il rendering Windows e Pixel 9 alla densità
      massima prima dell'accettazione percettiva.
      → Manifest completo. Verifica Windows eseguita il 28 agosto 2026 (le
      cinque sprite affiancate restano distinguibili a colpo d'occhio);
      resta da fare la verifica fisica su Pixel 9 in un'orda densa in gioco.

File coinvolti: `assets/art/icons/enemies/` e relativo manifest (tutorial),
`assets/art/enemies/pigeons/` e relativo manifest (sprite arena),
`data/enemies/*.tres`, `scripts/actors/base_enemy.gd` e le scene degli
archetipi soltanto per l'assegnazione delle texture.

Smoke: estendere `_b40_enemy_archetypes_smoke.gd` →
`B40_ENEMY_ARCHETYPES_SMOKE_OK`. Copre: texture presente e distinta per ogni
archetipo, fallback sicuro per un asset mancante, nessuna variazione dei
parametri o del determinismo di spawn B40.

Gate: regressione Relevant B40, export Windows, verifica percettiva Windows e
Pixel 9 in un'orda densa.

### B50 — Ostacoli leggibili e delimitatore dell'arena

Stato: `PRONTO`. Codice e smoke Relevant completi; resta il gate percettivo su
dispositivo prima di poter chiudere come `COMPLETATO`. Dipende da B38, che ha
introdotto gli ostacoli nell'arena.

**Obiettivo.** Eliminare collisioni che non corrispondono alla grafica e
rendere leggibile il limite utile dell'arena senza reintrodurre una rete come
ostacolo o una barriera visivamente pesante.

Contratti:

- [x] Il filo per i panni usa una forma di collisione che segue soltanto le
      parti visualmente solide. Le aree trasparenti restano attraversabili da
      Player e nemici: nessun punto invisibile può bloccare il movimento.
      → `StaticObstacle.collision_segments` (nuovo `Array[Rect2]` in spazio
      unitario -0.5..0.5, indipendente da `footprint_size`): quando valorizzato
      disattiva la `CollisionShape2D` piena e ne genera una per ogni voce.
      `Clothesline`/`ClotheslineB` in `movement_slice.tscn` la usano per i due
      pali laterali, lasciando attraversabile il vano centrale con corda e
      panni. Non tocca gli altri ostacoli (default vuoto = rettangolo pieno
      come prima).
- [x] Rimuovere dall'arena le due reti metalliche esistenti (`FenceWest` e
      `FenceEast`), comprese texture, collisioni e aspettative di test a esse
      riferite; non sostituirle con un'altra rete.
      → nodi rimossi da `movement_slice.tscn`; `obstacle_steel_net.png`
      (master `hd/` e derivato `generated/`) rimosso dal repository e dal
      manifest; l'unico riferimento residuo era quello stesso ext_resource.
- [x] Aggiungere un delimitatore piccolo, continuo e coerente con lo stile
      attuale dell'arena (per esempio bordo di terreno, cordolo o segni a terra,
      da definire con la direzione artistica). Deve rendere intuibile il confine
      senza essere un ostacolo di navigazione né coprire Player, nemici,
      pickup, telegraph o proiettili.
      → `ArenaView` disegna quattro bande lungo il perimetro del mondo
      (`boundary_thickness`, default `28.0`) con un cordolo procedurale
      (`boundary_color` + contorno `boundary_edge_color`) finché
      `boundary_texture` resta vuota — stesso schema texture-ready di
      `StaticObstacle.texture`, pronto a ricevere l'icona ImageGen quando sarà
      generata, senza altre modifiche al codice. `ArenaView` resta un
      `Node2D` puramente visivo con `z_index` più basso di ogni attore/pickup/
      proiettile: non introduce collisioni ne' copre nulla per costruzione.
- [x] Il confine fisico e il delimitatore visivo restano derivati da
      `ArenaLayout`, quindi corretti in 16:9, 20:9 e 4:3; non introdurre
      coordinate fisse o una texture stirata in modo ingannevole.
      → `ArenaView.calculate_boundary_bands()` e' una funzione statica pura
      che deriva le bande dal `world_rect` di `ArenaWorld` ricevuto via
      `update_layout()` (nessuna coordinata fissa); la texture, quando
      assegnata, si ripete a piastrelle (`boundary_tile_size`) invece di
      stirarsi, stesso meccanismo gia' in uso per il pavimento raster.

File coinvolti: `scenes/game/movement_slice.tscn`,
`scripts/game/obstacles/static_obstacle.gd`, `scripts/ui/arena_view.gd`,
asset e manifest dell'arena, `_b38_arena_world_smoke.gd`.

Smoke: esteso `_b38_arena_world_smoke.gd` → `B38_ARENA_WORLD_SMOKE_OK`. Copre:
passaggio nella zona trasparente del filo e blocco sul palo opaco
(`_validate_obstacle_collision_segments_block_only_opaque_parts`), assenza
delle due reti e `collision_segments` non vuoto sui due fili nella scena
composta, matematica pura delle bande del delimitatore
(`_validate_boundary_bands_math`, incluso il clamp quando lo spessore supera
meta' del rettangolo) e verifica che le bande calcolate sul `world_rect` reale
restino contenute nel playfield.

Gate completato: regressione Relevant B38
(`_b38_arena_world_smoke.gd`/`_movement_slice_smoke.gd` verdi). Restano da
eseguire export Windows e verifica percettiva/di movimento su Pixel 9 lungo
tutto il bordo dell'arena, quando sarà pronta l'icona definitiva del
delimitatore.

### B51 — Correzione della direzione del Powerslide di Bea

Stato: `PRONTO`. Codice e smoke Relevant completi; resta il gate percettivo
su dispositivo prima di poter chiudere come `COMPLETATO`. Correzione di bug
su B18D.

**Obiettivo.** Il Powerslide deve partire nella direzione verso cui il Player
stava effettivamente andando/guardando prima dell'attivazione. Se usa il facing
orizzontale anziché il vettore persistente, gli scatti verticali o diagonali
sono incoerenti e tradiscono il testo dell'abilità.

Contratti:

- [x] Al momento dell'attivazione lo scatto fotografa
      `Player.get_last_movement_direction()`; alto, basso, diagonali e lati
      sono tutti preservati. Il solo facing grafico non può sovrascrivere il
      vettore dello scatto.
      → verificato: `fire_z_trail.gd:_build_straight_path()` usa già
      `source.get_last_movement_direction()` (vettore normalizzato pieno,
      distinto da `get_facing_direction()` che resta solo sinistra/destra per
      lo sprite). Nessuna modifica di codice necessaria in questa slice: il
      bug descritto non era più riproducibile nel worktree corrente.
- [x] Input successivi non deviano uno scatto già avviato; pausa, level-up,
      `BOSS_INTRO`, morte, restart e cambio profilo mantengono i contratti B18D
      di avanzamento e cleanup.
      → già coperto da `_bea_powerslide_smoke.gd` (il file che implementa lo
      smoke B18D in questo worktree, sotto il nome storico pre-rinominazione):
      input dopo il teletrasporto non sposta il Player nella scia, la pausa
      ferma la durata, il restart rimuove la scia e resetta il cooldown.
- [x] Se non esiste ancora una direzione valida, applicare il fallback
      dichiarato da B18C/B18D senza introdurre uno scatto casuale.
      → `fire_z_trail.gd`: `direction.is_zero_approx()` ricade su
      `Vector2.RIGHT`, coerente con `Player.DEFAULT_FACING_DIRECTION`.

File coinvolti: `scripts/actors/player.gd`,
`scripts/abilities/fire_z_trail.gd`, `_bea_powerslide_smoke.gd`.

Smoke: `_bea_powerslide_smoke.gd` → `B18D_BEA_POWERSLIDE_SMOKE_OK`. Copre
esplicitamente uno scatto diagonale (`Vector2(-0.6, -0.8)` e poi
`Vector2(0.6, 0.8)` dopo restart) con verifica sia della componente
orizzontale sia di quella verticale della traiettoria, oltre alle invarianti
di pausa e cleanup esistenti. Rieseguito in questa slice: verde senza modifiche.

Gate completati: regressione Relevant B18D (`_bea_powerslide_smoke.gd`
verde). Restano da eseguire export Windows e prova manuale Windows/Pixel 9
con joystick touch.

### B52 — Playfield protetto dai controlli HUD

Stato: `PRONTO`. Codice e smoke Relevant completi; resta il gate fisico su
dispositivo prima di poter chiudere come `COMPLETATO`. Correzione di
confine B18Q/B34.

**Obiettivo.** Impedire al Player di finire sotto l'icona dell'abilità quando
raggiunge il limite inferiore destro. Il playfield utile deve escludere in modo
autorevole qualsiasi area di controllo persistente che copra la scena.

Contratti:

- [x] Il rettangolo di movimento del Player sottrae l'ingombro runtime del
      controllo abilità nel suo angolo; la soluzione vale su tutte le viewport,
      safe area e scale touch supportate, non solo a `1280×720`.
      → dopo B38 il Player non e' piu' confinato al playfield di schermo ma al
      rettangolo fisso di `ArenaWorld` (mondo scorrevole piu' grande del
      viewport, con `Camera2D` a scia/limiti). `Player.set_hud_exclusion(camera,
      reserved_control)` (nuovo, in `player.gd`) riceve la `Camera2D` e il
      `TouchAbilityButton` attivo da `movement_slice.gd`; ad ogni
      `_clamp_to_playfield()` il suo ingombro a schermo viene tradotto in
      mondo con la stessa tecnica gia' usata da
      `EnemySpawner.get_visible_reference_rect()`/`BossEncounter.get_visible_reference_rect()`
      (centrare sul `camera.get_screen_center_position()` corrente), poi
      `ArenaWorld.push_circle_outside_rect()` (nuovo, statico e puro) spinge il
      cerchio del Player fuori dal rettangolo cresciuto del proprio raggio
      lungo l'asse di minima penetrazione. Funziona per costruzione su
      qualunque viewport/safe-area/scala perche' non dipende da coordinate
      fisse: e' guidato dal rettangolo live del controllo e dalla camera reale.
- [x] Spawn, pickup, Boss, target e despawn restano coerenti con il playfield
      autorevole e non generano contenuto irraggiungibile nella zona riservata.
      → nessuna modifica: i pickup XP/vita usano gia' un raggio calamita
      (`pickup_radius`, `160` di default) ben maggiore dell'ingombro
      dell'icona, quindi restano raccoglibili anche se generati nella nicchia
      riservata; spawn/despawn/Boss restano sul rettangolo di `ArenaWorld`
      come da B38, non toccato da questa slice.
- [x] Il controllo abilità conserva dimensione, routing multitouch e priorità
      visiva B18K/B18L/B31/B34: questa slice cambia il confine di gameplay, non
      l'input né il layout dell'icona.
      → l'esclusione legge soltanto `TouchAbilityButton.get_global_rect()` in
      sola lettura; nessuna modifica a `hud.gd`, routing input o layout.

File coinvolti: `scripts/actors/player.gd` (nuovo `set_hud_exclusion()`,
`get_hud_exclusion_world_rect()`), `scripts/game/arena_world.gd` (nuovo
`push_circle_outside_rect()`), `scripts/game/movement_slice.gd` (wiring),
`_arena_hud_minimal_smoke.gd`.

Smoke: esteso `_arena_hud_minimal_smoke.gd` → `B18Q_ARENA_HUD_MINIMAL_SMOKE_OK`.
Copre, su tutti e quattro i profili di viewport della fixture: il rettangolo
riservato tradotto in mondo corrisponde all'ingombro reale del controllo; con
un raggio forzato grande quanto il controllo stesso (il raggio di default non
riesce a raggiungere la nicchia, il margine dichiarato la protegge già da
solo) il Player confinato nel solo mondo cadrebbe nell'icona, ma dopo
l'esclusione HUD non vi si sovrappone più; la proiezione a schermo indipendente
del Player (stessa trasformazione camera-viewport, ricalcolata nel test) non
cade nel rettangolo live del controllo. Verificato che il test fallisce
davvero disattivando temporaneamente l'esclusione (regressione confermata
prima di ripristinare il fix).

Gate completati: regressione Relevant B18Q/B34 (`_arena_hud_minimal_smoke.gd`
verde), oltre a `_bea_powerslide_smoke.gd` invariato. Restano da eseguire
export Windows e verifica fisica Pixel 9 con joystick e tap abilità
simultanei.

### B53 — Sospensione delle orde durante il Boss

Stato: `PRONTO`. Codice e smoke Relevant completi; resta il playtest su
dispositivo prima di poter chiudere come `COMPLETATO`. Correzione del ritmo
della run continua B33.

**Obiettivo.** Durante un Boss attivo, fermare lo spawn ordinario delle orde:
lo scontro deve restare leggibile e focalizzato invece di accumulare pressione
invisibile dietro al Boss.

Contratti:

- [x] `EnemySpawner` sospende lo spawn ordinario dall'ingresso effettivo del
      Boss fino alla sua uscita; non sospende clock, pattern, proiettili,
      collisioni o altri sistemi di gioco.
      → nuovo `EnemySpawner.set_ordinary_spawn_suspended(bool)`: in
      `_process()` congela solo l'incremento di `_spawn_elapsed` e la relativa
      schedulazione, lasciando invariati cleanup del despawn e rotazione dei
      settori. `movement_slice.gd` collega `BossEncounter.boss_spawned` (che
      scatta all'ingresso effettivo, sincrono con l'apertura di `BOSS_INTRO`,
      non a una richiesta che potrebbe fallire) e `BossEncounter.boss_defeated`
      ai due lati del flag; nessun'altra dipendenza da `game_director.gd`
      necessaria, dato che `BossEncounter` è già la fonte autorevole del ciclo
      di vita del Boss.
- [x] I nemici già presenti restano validi e seguono le regole esistenti. Alla
      morte o al cleanup del Boss lo spawn riprende senza raffica arretrata,
      perdita del cap `max_alive_enemies` o nuova sequenza RNG non determinista.
      → `_spawn_elapsed` non viene azzerato alla sospensione ma congelato (non
      incrementato): alla ripresa riparte esattamente da dove si era fermato,
      e poiché `try_spawn_enemy()` genera al più un evento di spawn per
      chiamata (mai un ciclo che smaltisce arretrato), un tick con ritardo
      grande quanto si vuole produce un solo evento — non una raffica.
      L'evento puo' comunque generare piu' di un nemico se l'archetipo scelto
      ha un `spawn_cluster_size` (comportamento ordinario invariato, non una
      raffica arretrata).
- [x] `BOSS_INTRO`, pausa, restart, sconfitta e cambio profilo non lasciano il
      flag di sospensione attivo nella run successiva. Un Boss pendente ma non
      ancora attivo non deve sospendere le orde in anticipo.
      → `reset_for_run()` e `_on_restart_prepared()` (già agganciati a
      `run_started`/`restart_prepared`) azzerano anche il nuovo flag, quindi
      restart e cambio personaggio (che passano sempre da
      `RunController.prepare_restart()`) lo puliscono anche se il Boss è
      stato rimosso a metà combattimento invece che sconfitto. Pausa e
      `BOSS_INTRO` non toccano il flag: lo spawn è già bloccato in quegli
      stati dal controllo esistente su `is_running()`. Poiché
      `_spawn_boss()` chiama `request_boss_intro()` ed emette `boss_spawned`
      nello stesso frame sincrono, non esiste in pratica una finestra
      "richiesto ma non ancora attivo" da gestire a parte.

File coinvolti: `scripts/game/enemy_spawner.gd`, `scripts/game/movement_slice.gd`
(wiring dei segnali di `BossEncounter`), `_b53_boss_horde_pause_smoke.gd`.

Smoke: nuovo `_b53_boss_horde_pause_smoke.gd` → `B53_BOSS_HORDE_PAUSE_SMOKE_OK`.
Copre: sospensione dall'ingresso effettivo (`BOSS_INTRO` e prosecuzione del
combattimento dopo l'intro) con i nemici già presenti ancora tracciati e
invariati; ripresa immediata e senza raffica alla sconfitta del Boss (un tick
lungo genera un solo evento, un tick corto successivo non ne genera altri);
reset pulito del flag su restart forzato con il Boss ancora vivo, mai
sconfitto; determinismo — due run con lo stesso seed, sospese e riprese nello
stesso modo attorno al Boss, producono la stessa sequenza di archetipi dopo
la ripresa. Verificato che il primo scenario fallisce davvero disattivando
temporaneamente la sospensione (regressione confermata prima di ripristinare
il fix). Rieseguito `_recurring_boss_smoke.gd`: verde, nessuna regressione
sullo scheduler ricorrente B33.

Gate completati: regressione Relevant B28/B33 (`_recurring_boss_smoke.gd`,
`_b53_boss_horde_pause_smoke.gd` verdi), oltre a `_combat_slice_smoke.gd` e
`_complete_run_smoke.gd` invariati. Restano da eseguire export Windows e
playtest Windows e Pixel 9
di un incontro Boss con orda già presente.

### B54 — Tutorial dal Welcome Screen

Stato: `IN VERIFICA`. Slice di onboarding indipendente dalla simulazione della
run. Dipende dal flusso `BOOT` di B18O, dalla gerarchia dei CTA di B32/B34 e
dai contenuti nemici ormai autorevoli di B40/B49.

**Obiettivo.** Permettere a chi apre il gioco per la prima volta di capire in
pochi passaggi che cosa deve fare, come controllare il personaggio, come
funzionano attacco, abilità e progressione e come riconoscere le minacce,
senza dover iniziare o sacrificare una run per impararlo.

Contratti:

- [x] Aggiungere `TUTORIAL` immediatamente sotto `GIOCA` nel blocco centrale
      della welcome. È un CTA secondario: riusa la famiglia pixel-fantasy e la
      tinta secondaria già presenti nella welcome, ha meno enfasi e altezza
      visiva del CTA primario ma conserva il target touch minimo. `GIOCA`
      mantiene focus iniziale e priorità; i vicini di focus formano il percorso
      `GIOCA ↔ TUTORIAL`, mentre l'ingranaggio impostazioni resta raggiungibile
      senza attraversare elementi decorativi.
- [x] `TUTORIAL` apre una schermata dedicata a tutto viewport e mantiene
      `RunController` in `BOOT`: clock, seed, spawn, Boss, input gameplay,
      cooldown, XP e musica/effetti della run non vengono inizializzati. Back,
      Escape e il controllo di chiusura tornano alla welcome con focus su
      `TUTORIAL`; una nuova apertura riparte dalla prima pagina.
- [x] Il tutorial è un carosello data-driven di **sei pagine**, con testo breve
      e una sola idea principale per pagina:
      1. **Scopo della run:** sopravvivere a orde sempre più pericolose,
         sconfiggere i Boss ricorrenti e resistere fino alla sconfitta o
         all'uscita volontaria.
      2. **Movimento e attacco:** movimento a otto direzioni; l'arma spara
         automaticamente al nemico vivo più vicino, quindi il giocatore si
         concentra su posizione e schivate.
      3. **Abilità attiva:** pulsante touch o azione dedicata su
         tastiera/controller, cooldown circolare e identità diversa per ogni
         personaggio.
      4. **Esperienza e potenziamenti:** raccogliere Caffè/Gocce di Pressione,
         riempire la barra XP e scegliere una delle tre carte quando la run si
         mette in pausa.
      5. **Nemici:** piccione base, Sciamatore, Corazzato, Divisore e Tiratore;
         per ogni archetipo mostrare icona, nome e un indizio operativo
         (veloce/in gruppo, resistente, si divide, spara dopo un telegraph).
      6. **Boss e partenza:** leggere telegraph e proiettili ostili, usare
         movimento/build/abilità insieme; il CTA finale `GIOCA` apre lo stesso
         selettore personaggio del CTA principale senza creare una run prima
         della conferma.
      I nomi e le descrizioni derivano dai contratti correnti del PRD e dei
      dati: il tutorial non introduce regole o numeri propri che possano
      divergere dal gameplay.
- [x] Il carosello espone frecce precedente/successiva, indicatori di pagina
      con posizione `n/6`, swipe orizzontale touch e navigazione
      tastiera/controller. Sulla prima pagina il controllo sinistro è `ESCI`
      e torna alla welcome; dalle successive diventa `INDIETRO`. L'ultima
      sostituisce `AVANTI` con `GIOCA`; Back di sistema chiude sempre il
      tutorial invece di cambiare pagina. Un singolo gesto non può saltare più
      di una pagina e il focus resta su un controllo visibile dopo ogni cambio.
- [x] Ogni pagina può avere una piccola animazione ciclica puramente
      presentazionale applicata alla visual già finita. Non istanzia Player,
      spawner o sistemi di combattimento reali, non consuma RNG e si ferma
      quando il tutorial non è visibile. Il significato resta comprensibile
      anche a frame fermo; niente flash rapidi e rispetto dell'impostazione di
      riduzione dei flash.
- [x] Riutilizzare per la pagina Nemici le quattro icone tutorial `128×128`
      già prodotte in B49 sotto `assets/art/icons/enemies/generated/`, più la
      grafica esistente del piccione base. Preferire animazioni native Godot ed
      asset già approvati. ImageGen è ammesso soltanto per visual editoriali
      realmente mancanti dopo il wireframe: niente testo rasterizzato, master
      HD escluso da import/export e manifest completo di prompt, generatore,
      trasformazioni, licenza e hash.
- [x] Layout e testi restano nella safe area e leggibili in 16:9, 20:9 e 4:3;
      su Pixel 9 non sono richiesti pinch o scroll per leggere una pagina. Le
      icone non sono l'unico canale informativo: ogni concetto ha nome e testo,
      i controlli hanno etichette e stato pressed/focus leggibile senza hover,
      e nessuna animazione è necessaria per comprendere l'istruzione.
- [x] Centralizzare i contenuti delle pagine (titolo, corpo, visual e tipo di
      preview) in risorse o dati dedicati, separati da layout e navigazione.
      Quando cambia un contratto spiegato — input, loop, nemici, Boss, XP o
      carte — la stessa slice deve aggiornare il tutorial e la relativa
      aspettativa di smoke.

File coinvolti: `scenes/ui/welcome_screen.tscn`,
`scripts/ui/welcome_screen.gd`, nuove `scenes/ui/tutorial_screen.tscn` e
`scripts/ui/tutorial_screen.gd`, eventuali definizioni sotto `data/tutorial/`,
il wiring UI in `scripts/game/movement_slice.gd`, asset/manifest tutorial e
`tools/milestone-test-map.json`.

Implementazione del 28 agosto 2026: `TutorialScreen` consuma sei
`TutorialPageDefinition`. Dopo il feedback percettivo negativo sul primo
wireframe, la UI è stata ridisegnata come composizione editoriale a due colonne:
obiettivo, movimento e Boss usano tre artwork originali ImageGen; abilità,
progressione e nemici riusano le icone definitive del progetto. `TutorialPreview`
applica soltanto micro-animazioni senza nodi gameplay. `ESCI` è attivo sulla
prima pagina e poi diventa `INDIETRO`; la `X` ridondante è rimossa. Su scelta del
proprietario le decorazioni della welcome possono usare il viewport completo,
mentre tutti i controlli restano confinati nella safe area.

Smoke: nuovo `_b54_tutorial_flow_smoke.gd` →
`B54_TUTORIAL_FLOW_SMOKE_OK`. Copre: posizione e stile secondario del pulsante,
focus iniziale e vicini; ingresso/uscita sempre in `BOOT`; assenza di stato run
prima e dopo il tutorial; ordine e completezza delle sei pagine; frecce,
indicatori, swipe, tastiera/controller e CTA finale; reset alla prima pagina;
presenza delle cinque famiglie nemiche e degli asset B49; stop delle preview
nascoste; funzionamento reale di `ESCI` in pagina uno; artwork dedicati; safe
area e assenza di sovrapposizioni a 16:9, 20:9 e 4:3.

Gate automatici: Focused B54 verde; `_welcome_flow_smoke.gd` verde con marker
B18O/B32. Relevant globale `30/31` sul failure roster preesistente; Relevant
limitato ai path B54 `7/8` sul failure HUD/vita Magno preesistente, con le sette
regressioni rimaste poi verdi `7/7`. Dopo il redesign, Focused è nuovamente
verde e Relevant conferma `30/31` sul solo failure roster preesistente. Export
debug Windows/Android aggiornati verdi; il nuovo APK ARM64, SDK 31/36 e firma
v2 ha SHA-256 `271F8BEEF9BE6B38631FD37F47C0E1E944B2272E8AD6D9F4262CAC70ABA3BAD7`.
Il nuovo APK è stato installato sul Pixel 9 con `adb install -r` (`Success`),
senza avviare l'app. Restano aperti Full/Release, runtime interattivo Windows,
cold launch e la prova fisica del proprietario su Pixel 9 per tap, swipe, Back, leggibilità 20:9 e
passaggio finale tutorial → selezione → run. Dettaglio in
[`b54-verification.md`](../b54-verification.md).

## 4. Grafo delle dipendenze

```
B40 (archetipi nemici) ──┬── B41 (forme d'attacco)
                         ├── B45 (Bea, Migi, Magno)
                         └── B46 (eventi d'ondata)

B42 (Marghe, Alea) ───── indipendente, avviabile subito
B43 (Zat) ───────────── indipendente, tocca anche Cosplay di Lollo
B44 (Aleo, Lollo) ───── indipendente; da coordinare con B43 per Cosplay
B47 (stat base) ─────── indipendente
B48 (record) ────────── dipende da B33 (run continua), già chiuso
B49 (texture nemici) ── dipende da B40; sostituisce i placeholder procedurali
B50 (arena leggibile) ─ dipende da B38; comprende filo, reti e delimitatore
B51 (Powerslide) ────── correzione B18D, dopo B18C
B52 (HUD/playfield) ─── correzione B18Q/B34
B53 (orde/Boss) ─────── correzione B33; coordina Spawner e BossEncounter
B54 (tutorial) ──────── dipende da B18O/B32/B34 per il flusso UI e da
                         B40/B49 per contenuti e icone dei nemici
```

Se serve un risultato percepibile prima che B40 sia pronta, la sequenza breve è
`B42 → B44 → B47`: tre slice quasi interamente di dati che restituiscono
identità a quattro profili su otto.

## 5. Criteri di accettazione di design

Da applicare come gate **prima** del gate tecnico descritto in
[`verification-workflow.md`](../verification-workflow.md). Valgono per ogni slice
di questo documento e per qualsiasi contenuto futuro.

**Nuova passiva o revisione**

- [ ] Ha un tell visibile o udibile durante la run.
- [ ] Cambia almeno un esito osservabile nella configurazione tipica — colpi per
      uccidere, colpi sopravvissuti.
- [ ] Non è approssimabile entro il `±20%` da due rank o meno di una carta
      comune esistente.
- [ ] Se ha fasi o soglie, il giocatore vede in quale fase si trova senza
      contare i secondi.

**Nuova attiva o revisione**

- [ ] Esiste almeno una variabile di scelta: dove, quando, su cosa.
- [ ] Lanciarla con attenzione rende più che lanciarla a caso.
- [ ] Il suo verbo non duplica un'attiva esistente o una carta.
- [ ] Il personaggio resta giocabile mentre è in cooldown.
- [ ] Contro il Boss contribuisce senza sostituire la build.

**Nuova carta**

- [ ] Cambia **come** si gioca, non solo **quanto** si fa.
- [ ] È una scelta reale contro danno e cadenza, non dominata da queste.
- [ ] Il peso è coerente con la gerarchia di rarità.

**Nuovo archetipo nemico**

- [ ] Esiste almeno un'abilità del cast chiaramente migliore contro di lui e una
      chiaramente peggiore.
- [ ] È riconoscibile a colpo d'occhio alla densità massima per silhouette e
      movimento, non solo per palette.
- [ ] Nessuna collisione rigida fra nemici (contratto B37).
- [ ] Dichiarato in dati, con seed riproducibile e smoke dedicato.

**Nuova pagina tutorial o revisione**

- [ ] Spiega una sola idea principale, con un esempio visivo breve e testo
      comprensibile senza conoscere il lessico interno del progetto.
- [ ] Descrive soltanto comportamenti autorevoli già presenti nel PRD e nei
      dati; non duplica numeri di bilanciamento destinati a cambiare.
- [ ] Resta comprensibile senza colore, audio o animazione e non richiede una
      run attiva per funzionare.
- [ ] È navigabile e leggibile con touch, mouse, tastiera e controller nelle
      viewport supportate; Back ha un esito unico e prevedibile.

## 6. Definition of Done aggiuntiva

Oltre alla sezione 8 dello [snapshot del piano](./development-plan-through-b54-2026-08-30.md), una
slice di questo piano è finita solo quando:

- soddisfa i criteri di design della sezione 5;
- ogni nuova sorgente di casualità passa dall'RNG seedato della run e due run
  con lo stesso seed sono identiche;
- cooldown, durate, fasi ed effetti periodici avanzano soltanto in `RUNNING`;
  pausa, level-up, `BOSS_INTRO` e stati terminali non consumano tempo e non
  producono effetti tardivi;
- nessun VFX prolunga collisioni, danno, tick o raggi, e nessun effetto alleato
  copre telegraph o proiettili ostili;
- se cambia l'identità dichiarata di un profilo, `characters.md`,
  `content-approvals.md` e `prd.md` sono aggiornati nello stesso commit;
- il `decision-log.md` registra la decisione se cambia un contratto di gameplay.

## 7. Cosa non cambiare

Vincolante quanto il resto: sono le parti che funzionano e che nessuna di queste
slice deve toccare come effetto collaterale.

- **La disciplina data-driven.** Nessun valore di gameplay hardcoded; ogni
  parametro resta in un `Resource` versionabile.
- **Il determinismo per seed** su tutta la catena spawn, upgrade, abilità.
- **I contratti di stato del `RunController`**, inclusi lifecycle Android,
  lock/resume e assenza di ripresa automatica.
- **La separazione fra presentazione e gameplay** consolidata da B18R.
- **La priorità visiva al campo di gioco** e il playfield autorevole sottratto
  alla fascia HUD (B18Q).
- **L'accessibilità dei flash** (B18E) e le taglie touch configurabili (B18P).
- **Il regime di approvazione dei contenuti personali**: citazioni, ritratti e
  voci non approvati restano su fallback neutri, sempre.
- **L'assenza di potere persistente fra run** (B18G), che B48 rispetta.

## 8. Appendice — la matematica citata

Tutti i valori sono lo stato del repository al 28 agosto 2026.

**Deficit di kill rate (D2)**

| Grandezza | Valore | Fonte |
|---|---|---|
| Arma base | `4` colpi/s, `10` danni | `data/weapons/default_weapon_profile.tres` |
| DPS base | `40` | derivato |
| Vita nemico comune | `18` | `scenes/actors/base_enemy.tscn` (B37) |
| Intervallo di spawn | `0,60 → 0,12 s`, accelerazione `0,003` | `data/spawn_profiles/default_enemy_spawn_profile.tres` |
| Tempo per toccare il cap | `160 s` → `(0,60 − 0,12) / 0,003` | derivato |
| Spawn/s al cap | `8,33` → `1 / 0,12` | derivato |
| Danno massimo da carte | `×2,0114` → `1,15^5` | `meat_fork_damage.tres` |
| Cadenza massima da carte | `×1,6105` → `1,10^5` | `rapid_fire.tres` |
| DPS con build completa | `129,6` → `40 × 3,2393` | derivato |
| **Kill/s con build completa** | **`7,20`** → `129,6 / 18` | derivato |
| **Spawn/s al cap** | **`8,33`** | derivato |

Con *tutte* le carte offensive al rank massimo, e ipotizzando zero overkill e
zero tempo di volo dei proiettili, il giocatore uccide meno di quanto arriva.

**Passive non misurabili (D3)**

| Profilo | Calcolo | Esito |
|---|---|---|
| Marghe | `18 × 0,95 = 17,1`; a `10` danni servono `2` colpi contro `2`; a `20,11` danni servono `1` contro `1` | no-op salvo danno in `(17,1 ; 18]` o `(8,55 ; 9]` |
| Alea | `(5/12) × (0,75 × 1,20 + 0,25 × 0,90) + (7/12) × 1,00` | `1,052`, cioè `+5,2%` medio |
| Magno | passiva `1,15` contro carta `1,10` per rank | `≈ 1,5` rank di `swift_steps` |
| Migi | passiva `0,90` contro carta `0,94` per rank; `0,94² = 0,884` | `< 2` rank di `reinforced_roasting_tray` |
| Lollo | focus `6 s` medi, distrazione `4,5 s` medi | distratto il `42,9%` del tempo, senza contromisure |

**Contributo di Zat al Boss (D3)**

| Rank | Danno per lancio su `2400` HP | Cooldown | Lanci in `240 s` | Totale | Quota del Boss |
|---|---|---|---|---|---|
| R1 | `480` (`20%`) | `60 s` | `4` | `1920` | `80%` |
| R5 | `672` (`28%`) | `50 s` | `5` | `3360` | `140%` |

## 9. Decisione richiesta

Prima di aprire qualsiasi slice servono tre decisioni del proprietario:

1. **Perimetro.** Quali slice fra `B40–B54` entrano nella prima release e quali
   restano dopo. B40 e B41 sono il nucleo di varietà e tenuta delle orde; le
   nuove B49–B54 sono tutte `P1` perché chiudono difetti percettivi, di
   leggibilità o di onboarding già osservati.
   **B54 è decisa e implementata** il 28 agosto 2026; restano soltanto i gate
   automatici/piattaforma indicati nella sua sezione.
2. **Identità dei personaggi.** Quali direzioni di B42, B43, B44 e B45 sono
   approvate. Toccano l'identità dichiarata di sette profili su otto e vanno
   registrate in `content-approvals.md` prima dell'implementazione.
   **B42, B43, B44 e B45 sono decise e registrate** (28 agosto 2026); resta
   aperta solo la direzione di B44 nel suo complesso essendo `IN VERIFICA`.
3. **Direzione di Zat.** Fra le due opzioni di B43 — tempesta telegrafata
   oppure wipe che si carica col danno subito — quale perseguire.

Alla decisione, le slice approvate vengono riportate nella sezione 6 di
`development-plan.md` con il loro `Stato` e questo documento resta come
riferimento del razionale.
