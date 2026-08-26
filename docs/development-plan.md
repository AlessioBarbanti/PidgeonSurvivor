# Piano di sviluppo — Pidgeon Survivor

Fonte: [`prd.md`](./prd.md)  
Decisioni: [`decision-log.md`](./decision-log.md)  
Stato: il ciclo funzionale e visivo B18C–B18W è completato. Tutti i gate automatici, Windows, Android statici e Pixel 9 già registrati restano chiusi; il 25 agosto 2026 il proprietario ha inoltre accettato la chiusura operativa di B18V, senza trasformare in evidenza tecnica le prove emulatore/soak non registrate. B22 è completato con runtime e controllo percettivo sul Pixel 9 il 26 agosto 2026; B23 resta `PRONTO`. B24 è implementato con baseline candidata `1,25×` ed è `IN VERIFICA` fino al confronto percettivo Windows/Pixel 9 in combattimento reale. Le altre slice B25–B33 restano da implementare senza riaprire o riscrivere i backlog già completati.
Obiettivo: trasformare il concept in un MVP completo, verificabile su Windows e Android

Identità pubblica confermata il 24 agosto 2026: `Pidgeon Survivor`, con il
sottotitolo esatto `It's grilling time!`.
Icona applicazione confermata il 25 agosto 2026: master ImageGen senza testo
`assets/art/branding/pidgeon_survivor_app_icon.png`, usato come icona progetto,
Windows e Android classica. Un secondo output ImageGen trasparente e centrato
nella safe area è il foreground adattivo; il background notte è separato.

Fonte di verità operativa: questo documento contiene roadmap, stato e ordine delle prossime attività. Eventuali note temporanee devono essere integrate qui e poi rimosse.

Vincolo aggiuntivo ricevuto l'11 agosto 2026: Windows e Android sono piattaforme obbligatorie.

## 1. Valutazione del PRD

Il PRD definisce bene il cuore del prodotto: arena 2D, movimento e schivata, fuoco automatico, raccolta XP, scelta di tre carte e Boss ispirati agli amici. Il progetto è adatto a un prototipo rapido.

Non è ancora una specifica direttamente implementabile. Mancano infatti alcune regole che influenzano architettura, bilanciamento e stima:

- condizione di vittoria, durata attesa della run, Game Over e restart;
- valore di `N` per i Boss e comportamento delle ondate durante un Boss;
- stacking, cap e prerequisiti degli upgrade;
- danno da contatto, invulnerabilità dopo il colpo e regole dei proiettili;
- dimensioni dell'arena, rapporto tra bordi e viewport e comportamento responsive;
- budget di entità e prestazioni distinti per Windows e Android;
- numero minimo di nemici, Boss, carte e asset per considerare l'MVP finito.

Ci sono inoltre quattro punti tecnici da correggere o precisare:

1. Il targeting è descritto sia come “nemico più vicino” sia come “zona più densa”. Per l'MVP va usato il nemico vivo più vicino.
2. `attack_rate` è definito come secondi fra gli attacchi, ma gli upgrade parlano di aumento percentuale della frequenza. Nel codice è più chiaro usare `shots_per_second` e derivare il cooldown come `1.0 / shots_per_second`.
3. Un file JSON non può contenere una funzione `apply_effect()`. I dati devono dichiarare un `effect_id` e parametri; il codice GDScript applica l'effetto tramite un registry.
4. La formula di spawn proposta raggiunge rapidamente il limite di `0.2 s` se `GameTime` è espresso in secondi. Il coefficiente deve essere configurabile e validato con profiling e playtest, non fissato nel codice.

Nota documentale: il file originale è UTF-8 valido ma fisicamente composto da una sola riga. Va conservato come fonte iniziale e sostituito, dopo le decisioni di prodotto, da una specifica formattata e versionata.

## 2. Baseline consigliata

Queste decisioni sono assunzioni reversibili che consentono di iniziare senza bloccare il lavoro. Vanno confermate prima della produzione dei contenuti definitivi.

| Area | Decisione proposta | Motivazione |
|---|---|---|
| Engine | Godot 4.7.1 Standard + GDScript tipizzato | Versione stabile fissata, scene/componenti, dati tipizzati ed export Windows/Android |
| Renderer | Compatibility | È adatto a un gioco 2D e copre una gamma ampia di GPU desktop e mobile |
| Target obbligatori | Windows x64 e Android | Entrambi fanno parte della Definition of Done di ogni milestone |
| Viewport e orientamento | 1280×720 logico, `canvas_items` + `expand`, landscape bloccato | UI responsive; `ArenaLayout` ricava un playfield 16:9 coerente dentro safe area anche su 18:9, 20:9 e tablet |
| Android SDK/ABI | `minSdk 31` (Android 12), `targetSdk 36`/`compileSdk 36` (Android 16), solo `arm64-v8a` | Android 12 è la baseline operativa scelta per “qualche major prima”; target e ABI sono confermati |
| Distribuzione Android | APK diretto per ora; build Gradle e percorso AAB predisposti, senza pubblicazione Play | Package ID, versioning e firma restano compatibili con una futura migrazione allo store |
| Arena | Camera fissa, Player confinato, anello di spawn appena fuori viewport | Compatibile con inseguimento, muri e rimbalzi |
| Targeting | Nemico vivo più vicino | Corrisponde alla sezione tecnica del PRD ed è facile da verificare |
| Vertical slice | Run obiettivo di 5–7 minuti; Boss a `04:00`; vittoria alla sua sconfitta | Consente di testare tutto il loop senza produrre troppo contenuto |
| Contenuto MVP | 1 Player Magno, 1 arma, 1 abilità attiva, 2 nemici base, 1 Boss con 2 pattern, almeno 6 upgrade | Quantità minima già verificata in M4; B17A amplia la prima pubblicazione a otto personaggi giocabili |
| Curva XP | Soglia iniziale 10 XP, crescita lineare di 5 XP per livello | Baseline B08 leggibile e configurabile da dati, da ribilanciare con il playtest |
| Carte | 3 ID distinti per offerta; una carta può ricomparire in seguito finché non è al rank massimo | Elimina duplicati nella scelta senza esaurire subito il catalogo |
| Roster e abilità attive | Framework e Magno nell'MVP; selezione, otto passive e altre 7 abilità nella fase contenuti | B09A valida il framework; B17A rende giocabili tutti gli otto profili approvati senza riaprire il core loop M4 |
| Salvataggio/meta-progressione | Fuori MVP | Non serve a validare il core loop |
| Contenuti personali | Placeholder fino all'approvazione di nomi, citazioni, immagini e audio | Riduce rilavorazioni e rischi di pubblicazione |

### Perimetro MVP

Incluso:

- menu iniziale minimo, avvio run, sconfitta, vittoria e restart;
- movimento completo da tastiera/controller su Windows e joystick virtuale touch su Android;
- combattimento, danno, invulnerabilità breve e drop XP;
- HUD, level-up in pausa e navigazione delle carte con mouse, tastiera, controller e touch;
- un'abilità attiva completa, con input multipiattaforma, cooldown e feedback HUD;
- sei upgrade, inclusi almeno un modificatore statistico, un effetto temporizzato e un modificatore dei proiettili;
- un Game Director configurabile, un Boss completo e una run chiusa;
- export Windows e Android, test di regressione e budget prestazionale per piattaforma.

Escluso:

- multiplayer, classifiche online e telemetria;
- modalità portrait, mappe procedurali o più armi;
- il roster completo e le altre sette abilità attive, esclusi dal solo MVP M4 ma inclusi nella prima pubblicazione tramite B17A;
- meta-progressione, inventario permanente e salvataggi di run;
- localizzazione completa e contenuti cosmetici non necessari al feedback di gioco.

## 3. Contratti di gameplay da fissare

Le quantità finali saranno dati configurabili. Le seguenti regole, invece, devono essere stabili.

### Player e statistiche

- Il vettore di input viene normalizzato: la diagonale non è più veloce degli assi.
- `health_current` resta sempre nell'intervallo `0..health_max`.
- Una riduzione di vita massima conserva la stessa percentuale di vita corrente, poi applica il clamp.
- La frequenza di fuoco è espressa in colpi al secondo. Un bonus `+25%` moltiplica la frequenza per `1.25`.
- Le statistiche effettive vengono ricalcolate da valori base e modificatori identificati; non vengono mutate ripetutamente in modo irreversibile.
- Dopo il danno da contatto il Player ha un breve tempo di invulnerabilità configurabile.

### Clock e stati della run

Stati minimi: `BOOT`, `RUNNING`, `MANUAL_PAUSE`, `LEVEL_UP`, `BOSS_INTRO`, `VICTORY`, `DEFEAT`.

- Il tempo di run avanza solo in `RUNNING`.
- Spawn, cooldown di gameplay, effetti periodici e scheduler Boss usano il tempo di run, non il tempo reale.
- Durante `LEVEL_UP` fisica e gameplay sono fermi, mentre overlay e input UI continuano a funzionare.
- Solo `RunController` può modificare `SceneTree.paused`; tutte le richieste modali passano da una coda con priorità `DEFEAT/VICTORY → LEVEL_UP → BOSS_INTRO → MANUAL_PAUSE`.
- XP sufficiente a superare più soglie conserva l'overflow e accoda una scelta per ogni livello ottenuto.
- `VICTORY` e `DEFEAT` bloccano definitivamente danni, spawn e progressione fino al restart.
- Su Android, perdita del focus, sospensione dell'app o pressione del tasto Back richiedono una pausa sicura; al ritorno tutti i touch attivi vengono azzerati per evitare movimento bloccato.

### Input e layout multipiattaforma

- Il gameplay riceve un solo `movement_vector`, indipendente dalla sorgente: InputMap da tastiera/gamepad oppure joystick virtuale touch.
- Su Android il joystick virtuale occupa una zona sicura in basso a sinistra; pausa e azioni UI non devono sovrapporsi alla sua area di cattura.
- Il touch identifica ogni dito con il suo indice e gestisce press, drag, release e annullamento; il movimento torna sempre a zero alla perdita del dito o del focus.
- Le tre carte sono normali controlli UI selezionabili sia con focus sia con tap; nessuna informazione o azione può dipendere dal solo hover del mouse.
- HUD e controlli rispettano safe area, notch/display cutout e DPI. L'arena attiva resta in un rettangolo centrale coerente; lo spazio extra dei display ultrawide non cambia la difficoltà.
- L'orientamento Android è landscape. Portrait e rotazione durante la run restano fuori scope per l'MVP.
- Il tasto Back esegue `cancel/back` nell'overlay o apre la pausa; non chiude direttamente l'app durante una run.
- Dopo Home, blocco schermo o perdita del focus, la run rimane in pausa finché l'utente non sceglie esplicitamente di riprendere.
- Se Android termina il processo in background, la run può andare persa: il ripristino della sessione resta fuori MVP insieme ai salvataggi.

### Abilità attive

- Ogni personaggio possiede una sola `AbilityDefinition`, distinta dalle carte upgrade e attivabile tramite l'intenzione `active_ability` di `InputRouter`.
- L'MVP implementa Magno con Onda d'Urto Tellurica come vertical slice; le altre sette definizioni ed effetti vengono completati in B17A.
- B17A espone una selezione pre-run degli otto `FriendDefinition`: il profilo scelto assegna ritratto, passiva runtime e `AbilityDefinition`; il restart conserva il personaggio, mentre “Cambia personaggio” torna alla selezione dopo un terminale.
- L'attiva di Marghe è presentata come `Reggeton time!`: il clone ballerino a tema reggaeton conserva durata, cooldown, deviazione dell'aggro e cleanup dell'originario effetto illusorio.
- Ogni passiva usa parametri versionabili nel relativo `FriendDefinition`, si combina moltiplicativamente con gli upgrade e viene azzerata o ricostruita senza residui a ogni cambio profilo e restart.
- `AbilityController` accetta l'attivazione soltanto in `RUNNING`, con cooldown terminato e requisiti dell'effetto validi. Una richiesta rifiutata non consuma il cooldown.
- Cooldown, durata e tick periodici avanzano sul clock della run e restano fermi in pausa, `LEVEL_UP`, `BOSS_INTRO`, `VICTORY` e `DEFEAT`.
- Lo sparo automatico continua durante un'abilità, salvo un'incompatibilità dichiarata dalla sua definizione.
- Il restart azzera cooldown, effetti, aree persistenti, cloni e connessioni create dall'abilità; nessuna entità può sopravvivere alla run che l'ha generata.
- `AbilityDefinition` è un `Resource` in `res://data/abilities/` con ID, testi, cooldown, durata, area, danno, `effect_id`, parametri e tag di compatibilità.
- `AbilityEffectRegistry` interpreta `effect_id + params`; filtra inoltre le copie di Cosplay Casuale per evitare ricorsione e requisiti non disponibili.
- L'HUD mostra icona, stato pronto e cooldown residuo. Su Android il pulsante touch resta nella safe area, separato dal joystick e utilizzabile in multitouch.

### Spawn e difficoltà

- I nemici nascono in un anello esterno al viewport, a distanza minima dal Player, e possono entrare nell'arena; una fascia interna telegrafata resta l'alternativa se i test sui diversi aspect ratio mostrano problemi ai bordi.
- Le pareti bloccano Player e proiettili rimbalzanti ma non impediscono l'ingresso dei nemici appena generati.
- `spawn_interval = max(min_interval, base_interval - run_time * acceleration)`; tutti i parametri sono esportati in un profilo dati.
- Vanno definiti un cap di nemici vivi e una politica di despawn per entità rimaste fuori dall'area valida.
- Il Boss viene schedulato una sola volta per soglia. Non viene creato un secondo Boss finché il precedente è vivo.
- La prima release introduce con B33 una progressione Boss continua che **sovrascrive solo a valle** la vecchia chiusura del vertical slice: il primo Boss resta previsto a `04:00`, la sua morte non termina la run e il gioco continua. Ogni Boss successivo diventa eleggibile dopo altri `240 s` di gameplay; se alla scadenza il Boss corrente è ancora vivo, il successivo resta in attesa e viene generato immediatamente alla morte del Boss attivo, senza sovrapporre due Boss e senza accumulare una raffica di spawn arretrati.

### Upgrade

- Ogni definizione ha ID univoco, titolo, descrizione, icona, `effect_id`, parametri, peso, rank massimo, tag e prerequisiti opzionali.
- La pesca usa un RNG con seed registrabile, così un errore può essere riprodotto.
- Le tre opzioni hanno ID distinti e sono filtrate per eleggibilità e rank massimo.
- Se restano meno di tre opzioni, entra un upgrade statistico generico ripetibile; l'overlay non deve bloccarsi.
- Gli upgrade temporizzati usano componenti/status locali, non `Engine.time_scale`, per evitare effetti collaterali.

Interpretazione iniziale degli upgrade del PRD:

| Upgrade | Contratto proposto |
|---|---|
| L'Ansia | velocità `×1.35`, vita massima `×0.80`, percentuale di vita conservata, vignetta solo visiva |
| Gossip | il colpo salta da un nemico vivo al successivo entro un raggio configurabile, con danno progressivamente ridotto a ogni salto |
| Ritardo cronico | ogni 12 s di gameplay applica ai nemici uno status `speed ×0.50` per 3 s |
| Birra | frequenza `×1.25`; traiettoria sinusoidale con ampiezza configurabile |
| Non ho tempo | a ogni danno effettivo emette un knockback radiale; non si riattiva durante l'invulnerabilità |

## 4. Architettura Godot proposta

La struttura resta piccola e scene-local. Un `RunController` orchestra la partita; non serve un Event Bus globale per il prototipo.

```text
res://
├── project.godot
├── scenes/
│   ├── app/main.tscn
│   ├── game/run.tscn
│   ├── arena/arena.tscn
│   ├── actors/player.tscn
│   ├── actors/enemy_base.tscn
│   ├── actors/boss_base.tscn
│   ├── abilities/ability_area.tscn
│   ├── combat/projectile.tscn
│   ├── pickups/experience_pickup.tscn
│   └── ui/{hud,touch_controls,upgrade_overlay,end_screen}.tscn
├── scripts/
│   ├── app/
│   ├── game/{run_controller,game_director,arena_layout}.gd
│   ├── input/{input_router,touch_joystick,platform_lifecycle}.gd
│   ├── platform/performance_profile.gd
│   ├── actors/
│   ├── abilities/{ability_controller,ability_effect_registry}.gd
│   ├── components/{health,hitbox,hurtbox,status_controller}.gd
│   ├── combat/{weapon_controller,targeting,projectile}.gd
│   ├── progression/{experience,upgrade_service,upgrade_effect_registry}.gd
│   └── ui/
├── data/
│   ├── abilities/
│   ├── upgrades/
│   ├── enemies/
│   ├── bosses/
│   ├── spawn_profiles/
│   ├── platform_profiles/
│   └── layouts/
├── assets/{art,audio,fonts}/
├── tests/{unit,integration}/
└── exports/
```

### Scene principale della run

```text
Run
├── Systems
│   ├── RunController
│   ├── InputRouter
│   ├── PlatformLifecycle
│   ├── ArenaLayout
│   ├── PerformanceProfile
│   ├── GameDirector
│   ├── EnemyRegistry
│   ├── TargetingSystem
│   ├── ExperienceSystem
│   ├── AbilityEffectRegistry
│   └── UpgradeService
├── Arena
├── Actors
│   └── Player
│       └── AbilityController
├── Enemies
├── Projectiles
├── Pickups
└── UI (CanvasLayer)
    ├── SafeAreaContainer
    │   ├── HUD
    │   ├── TouchControls
    │   ├── UpgradeOverlay
    │   └── EndScreen
    └── FullscreenEffects
```

Flusso principale degli eventi:

```text
Enemy.died
  → genera ExperiencePickup
  → pickup.collected
  → ExperienceSystem.add_experience
  → ExperienceSystem.level_up_queued
  → LEVEL_UP + pausa
  → UpgradeService crea 3 offerte
  → UI conferma una carta
  → UpgradeEffectRegistry applica l'effetto
  → eventuale prossimo level-up accodato, altrimenti RUNNING
```

Flusso di un'abilità attiva:

```text
InputRouter.active_ability_requested
  → AbilityController.try_activate
  → verifica RUNNING, cooldown e requisiti
  → AbilityEffectRegistry applica effect_id + params
  → AbilityController avvia cooldown e notifica HUD
  → RunController sospende, riprende o azzera il ciclo con lo stato della run
```

### Responsabilità

- `RunController`: unica autorità per stato e pausa; gestisce clock, arbitraggio dei modali, vittoria/sconfitta, seed e restart.
- `GameDirector`: profilo di spawn, curve di difficoltà e soglie Boss; non gestisce la UI.
- `InputRouter`: unifica tastiera, gamepad e touch in intenzioni di movimento, abilità attiva e UI; `TouchControls` è visibile solo su dispositivi touch/Android.
- `PlatformLifecycle`: traduce Back, focus loss, sospensione e ripresa in richieste al `RunController`; non riprende mai automaticamente una run.
- `ArenaLayout`: deriva playfield, fascia di spawn e safe rect dalla viewport corrente; nessun sistema usa coordinate `1280×720` hardcoded.
- `PerformanceProfile`: seleziona risoluzione interna, VFX, particelle e limiti visivi per piattaforma senza cambiare automaticamente il bilanciamento.
- `EnemyRegistry` e `TargetingSystem`: mantengono i bersagli vivi e restituiscono quello più vicino senza scansioni del SceneTree.
- `ExperienceSystem`: conserva XP, soglie, overflow, livello e numero di scelte in coda.
- `Player`: movimento e composizione dei componenti, senza conoscere cataloghi o HUD.
- `AbilityController`: possiede l'abilità equipaggiata, valida l'attivazione, avanza il cooldown sul clock di gameplay ed elimina lo stato runtime al restart.
- `AbilityEffectRegistry`: risolve `effect_id + params`, crea gli effetti scene-local e applica i filtri di compatibilità senza incorporare logica nei file dati.
- `WeaponController`: cooldown, selezione bersaglio e creazione del proiettile.
- `HealthComponent`: vita, danno, invulnerabilità e segnale `died` condivisi fra Player, nemici e Boss.
- `UpgradeService`: filtri, pesi, rank, scelta deterministica e fallback.
- `UpgradeEffectRegistry`: traduce `effect_id + params` in modificatori/componenti di gameplay.
- UI: osserva segnali, mostra cooldown/prontezza e invia intenzioni; non modifica direttamente statistiche o nodi nemici.

Per `AbilityDefinition`, `UpgradeDefinition`, `EnemyDefinition`, `BossDefinition` e `SpawnProfile` sono preferibili `Resource` custom salvate come `.tres`: sono tipizzate, editabili nell'Inspector e versionabili. JSON resta utile solo se i contenuti devono essere gestiti fuori da Godot. In entrambi i casi, la logica degli effetti rimane in GDScript.

La baseline condivisa usa Godot 4.7.1 Standard, GDScript e renderer Compatibility. Il preset Windows produce una build x64; il preset Android usa Gradle, package ID `com.ilgioco.pidgeonsurvivor`, `minSdk 31`, `targetSdk 36`, `compileSdk 36` e ABI release `arm64-v8a`. Produce APK di test/release e deve poter generare un AAB senza caricarlo su Google Play. JDK, Android SDK e firma vengono configurati in M0 senza salvare keystore o credenziali nel repository: [documentazione export Android](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html). Godot gestisce touch tramite `InputEventScreenTouch` e `InputEventScreenDrag`, mentre l'InputMap resta il contratto per tastiera/gamepad: [documentazione input](https://docs.godotengine.org/en/stable/tutorials/inputs/input_examples.html).

Android 12/API 31 è il minimo supportato, mentre Android 16/API 36 è il target di compilazione e comportamento. L'SDK Platform 36 e i Build Tools 36.x devono essere presenti nella toolchain: [setup Android 16](https://developer.android.com/about/versions/16/setup-sdk). Il valore API 36 prepara anche ai requisiti Google Play applicabili dal 31 agosto 2026, pur senza rendere lo store parte della prima release: [requisito ufficiale Google Play](https://developer.android.com/google/play/requirements/target-sdk).

M0 include uno spike obbligatorio con Godot 4.7.1: Gradle deve rispettare `min_sdk=31` e `target_sdk=36`, proprietà previste dall'exporter Android, e produrre un APK ARM64 installabile. Se la combinazione fra template e toolchain non compila con API 36, si aggiorna l'export template o la successiva patch stabile; non si abbassa silenziosamente il target: [proprietà exporter Android](https://docs.godotengine.org/en/stable/classes/class_editorexportplatformandroid.html).

L'overlay di level-up usa `PROCESS_MODE_WHEN_PAUSED`, secondo il modello di pausa ufficiale: [documentazione pausa](https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html).

### Prestazioni

Il `TargetingSystem` mantiene un registro degli avversari attivi, aggiornato allo spawn e alla morte, e confronta le distanze al quadrato. Questo evita di ricostruire `get_nodes_in_group()` a ogni colpo pur mantenendo semplice la prima implementazione. L'ordine di ottimizzazione deve essere:

1. rimuovere allocazioni e riferimenti non validi;
2. aggiornare il target a frequenza controllata invece che per ogni frame o per ogni proiettile;
3. introdurre pooling per proiettili, pickup e nemici se il profiler lo giustifica;
4. usare partizionamento spaziale soltanto se la scansione lineare supera il budget.

Budget iniziale da validare e poi fissare su dispositivi di riferimento dichiarati:

- target 60 FPS su Windows e su un telefono Android di fascia media; il profilo mobile riduce prima risoluzione interna, VFX, particelle e overdraw;
- profilo Windows di stress: 150 nemici, 200 proiettili e 200 pickup contemporanei;
- profilo Android di stress iniziale: gli stessi cap del gameplay Windows; un eventuale cap più basso richiede una decisione di bilanciamento esplicita, non un fallback invisibile;
- nessuna crescita continua di nodi o memoria in un soak test di 20 minuti;
- nessun input touch bloccato dopo interruzioni e nessun frame spike visibile quando muore un gruppo numeroso o si apre il level-up;
- un overlay debug mostra FPS/frame time, entità attive e profilo di qualità su entrambe le piattaforme.

## 5. Roadmap e gate

Le stime sono in story point Fibonacci e servono per priorità e confronto, non come calendario. Dopo M1 si misura la velocità reale del team. Per un singolo sviluppatore con asset placeholder, l'ordine di grandezza è 6–10 settimane per una release Windows/Android rifinita; la produzione di grafica/audio definitivi e la pubblicazione sugli store sono separate.

| Milestone | Risultato | Backlog | SP | Gate di uscita |
|---|---|---:|---:|---|
| M0 — Fondazioni | Decisioni, progetto e build vuota | B01–B02 | 8 | La stessa scena parte in Godot 4.7.1, Windows e su emulatore/device Android |
| M1 — Combat slice | Movimento, touch, lifecycle, nemico, fuoco, danno e restart | B03–B06A | 23 | Loop di 3 minuti giocabile sia su Windows sia su Android |
| M2 — Progressione e attiva | Drop, XP, HUD, livelli e prima abilità attiva | B07–B09A | 21 | `kill → pickup → level` affidabile; Onda d'Urto attivabile e leggibile su Windows/Android |
| M3 — Carte | Catalogo, overlay touch e primi upgrade | B10–B12 | 18 | Loop completo fino a più scelte consecutive anche tramite tap |
| M4 — Boss e run chiusa | Upgrade signature, Director, Boss e finali | B13–B16 | 24 | MVP completo, inclusa un'abilità attiva, dall'avvio a vittoria o sconfitta |
| M5 — Release multipiattaforma | Roster giocabile, contenuti, audiovisivo, identità visiva, controlli e QA | B17, B17A, B18–B18W | 157 | Otto personaggi selezionabili con passive e abilità proprie; ciclo B18C–B18W chiuso e build Windows/Android di verifica disponibili |
| M6 — Boss variabili | Piccione speciale Boss e varianti Evil | B22 | 13 | Ogni incontro Boss è riproducibile dal seed e può sostituire il piccione speciale con un Evil leggibile e bilanciato |
| M7 — Difesa Grigliata | Seconda modalità con obiettivo centrale | B23 | 21 | Una griglia con carne ha vita, attira i nemici e determina sconfitta o vittoria insieme alle regole della modalità |
| M8 — Polish gameplay/UI/audio | Scala Player, HUD pulito, upgrade danno, icone, densità orde, musica, Boss/UI e run continua | B24–B33 | 44 | Il gioco ha maggiore densità e leggibilità, asset upgrade coerenti, musica con licenza registrata e Boss ricorrenti senza chiudere la run |

Totali di pianificazione: 94 SP per l'MVP feature-complete fino a M4, 251 SP
per la candidata Windows/Android con roster completo e ciclo
B18C–B18W, 285 SP dopo B22–B23 e 329 SP dopo il pass B24–B33. Le stime delle nuove slice
sono iniziali e vanno ricalibrate dopo i primi smoke e playtest sui valori ora
congelati.

Gate di prodotto:

- dopo M1: verificare che movimento, leggibilità e “feel” del fuoco siano divertenti prima di ampliare i sistemi;
- dopo M2: playtest del loop XP e dell'Onda d'Urto con tastiera, controller e touch, inclusi cooldown e pausa;
- dopo M3: playtest del loop XP/carte e controllo delle combinazioni con l'abilità attiva;
- dopo M4: freeze del core loop; M5 integra il roster completo sul framework validato, con selezione pre-run, passive, altre sette abilità, correzioni, accessibilità e release work;
- prima di B18V: freeze funzionale e visivo di B18C–B18U e B18W, inclusi flusso welcome/selezione/pausa, carosello profili, raffinamento della selezione, sprite del cast, HUD e controlli touch configurabili, playfield separato dal HUD, animazioni, sfondo, abilità, rank, nemici, upgrade, asset e confinamento XP, così hardening e profiling misurano la presentazione destinata alla release. Il freeze è chiuso dal 25 agosto 2026.

## 6. Backlog ordinato

Priorità: `P0` indispensabile per l'MVP, `P1` indispensabile per la prima pubblicazione.

| ID | Attività | Prio | SP | Dipende da | Criterio di accettazione sintetico |
|---|---|---:|---:|---|---|
| B01 | Chiudere decisioni e parametri di prodotto | P0 | 3 | — | Decisioni gameplay aperte chiuse; piattaforma registrata come API 31–36, ARM64, landscape, APK diretto e Play-ready |
| B02 | Bootstrap, InputMap, lifecycle e preset export | P0 | 5 | B01 | `com.ilgioco.pidgeonsurvivor`: Gradle/API 36 genera APK ARM64 min API 31; Windows avviabile |
| B03 | Movimento Player, touch e limiti arena | P0 | 5 | B02 | Tastiera/controller/joystick touch, diagonale normalizzata, input azzerato su focus loss, Player confinato |
| B04 | Nemico base, ArenaLayout e spawner | P0 | 5 | B02–B03 | Confini/spawn derivati dal rect dinamico, inseguimento, cap e stop fuori da `RUNNING` |
| B05 | Targeting, arma, proiettile e danno | P0 | 5 | B03–B04 | Bersaglio vivo più vicino, nessun tiro senza target, una hit processata una volta |
| B06 | Salute Player, contatto, Game Over e restart | P0 | 5 | B03–B05 | Invulnerabilità coerente, HP clamped, restart senza nodi/timer residui |
| B06A | Android Back, focus e lifecycle | P0 | 3 | B02–B03, B06 | Back/pausa, Home, lock e resume azzerano l'input; la run non riparte da sola |
| B07 | Drop, magnete e raccolta XP | P0 | 3 | B05 | Una morte genera un drop; accredito singolo entro `pickup_radius` |
| B08 | Livelli, soglie, overflow e coda | P0 | 5 | B07 | Nessun XP perso; un'offerta per ogni livello guadagnato |
| B09 | HUD responsive, safe area, vita, XP e timer | P0 | 5 | B06, B08 | Anchor/Container corretti su 16:9–20:9 e 4:3; clock fermo fuori da `RUNNING` |
| B09A | Framework abilità attive e Onda d'Urto Tellurica | P0 | 8 | B03, B05–B06A, B09 | Input tastiera/controller/touch, `AbilityDefinition`, registry, cooldown/HUD e area danno+knockback verificati; pausa e restart non lasciano stato residuo |
| B10 | Resource upgrade, registry e pesca | P0 | 5 | B01, B08 | ID validati, seed riproducibile e 3 offerte eleggibili uniche |
| B11 | Overlay e navigazione completa | P0 | 8 | B09–B10 | Mouse/tastiera/controller/touch, target ampi, joystick nascosto e una sola scelta applicata |
| B12 | Tre upgrade semplici di prova | P0 | 5 | B05, B10–B11 | Velocità, frequenza/danno e pickup rispettano stacking e cap |
| B13 | Upgrade signature del PRD | P0 | 8 | B12 | Catena Gossip, slow, oscillazione Birra, shockwave e vignetta combinabili senza conflitti |
| B14 | Game Director e scheduler Boss | P0 | 3 | B04, B09 | Una sola attivazione per soglia; pausa e restart non duplicano eventi |
| B15 | Primo Boss completo | P0 | 8 | B05–B06, B14 | Due pattern telegrafati, HP, citazione sicura, morte e ricompensa |
| B16 | Vittoria, bilanciamento e run completa | P0 | 5 | B09A, B12, B15 | Cinque run consecutive terminano correttamente senza stato residuo, inclusi cooldown ed effetti dell'abilità |
| B17 | Contenuti definitivi degli amici | P1 | 5 | B10, B15 | Testi e asset sostituibili senza codice; approvazioni registrate |
| B17A | Roster giocabile completo e sette attive restanti | P1 | 34 | B09A, B13, B16, B17 | Otto amici selezionabili prima della run con ritratto, passiva parametrica e abilità propria; le sette nuove `AbilityDefinition`, Cosplay Casuale, combinazione con upgrade, cambio personaggio e cleanup su due run sono verificati |
| B18 | Art, VFX, audio, contrasto e volume | P1 | 5 | B09A, B11, B15 | Feedback leggibile; controlli volume/mute; nessun effetto o abilità nasconde gli attacchi |
| B18B | Identità visiva, HUD compatto e combat feedback | P1 | 5 | B17A, B18 | HUD e controlli lasciano priorità al campo di gioco; arena non sembra una vista debug; colpi, danni e morti hanno feedback leggibile e coerente senza richiedere nuovi asset nella prima iterazione |
| B18C | Player animato e direzione persistente | P1 | 5 | B17A, B18B | Cannoncino e fondo circolare rimossi; gli otto profili animano fasi laterali durante il movimento, mostrano una posa ferma al neutro ed espongono lato orizzontale e vettore dell'ultimo movimento alle abilità |
| B18D | Powerslide direzionale di Bea | P1 | 5 | B17A, B18C | Nome e icona inline-skate; teletrasporto rettilineo nella direzione persistente e scia dati da 4 s; pausa, input successivo e restart non deviano né lasciano effetti residui |
| B18E | Tuoni di Zat | P1 | 5 | B17A, B18B | Preavviso e flash accessibile sull'intero viewport precedono il danno ritardato a tutti i nemici validi; cooldown, pausa, Boss e cleanup rispettano i dati approvati |
| B18F | Gran Piroetta inseguitrice di Alea | P1 | 3 | B17A | L'area segue il Player per tutta la durata; pausa, termine, restart e cambio profilo non lasciano posizione o stato residuo |
| B18G | Rank delle abilità principali | P1 | 8 | B10–B13, B17A | Tutte le otto abilità hanno cinque rank dichiarativi specifici, entrano nel level-up senza duplicati e si azzerano fra le run |
| B18H | Nemici piccione | P1 | 3 | B04, B17, B18B | Le sfere rosse sono sostituite da asset uccello approvati per variante base e speciale senza cambiare comportamento, collisioni, danno o spawn |
| B18I | XP confinato nell'arena | P1 | 3 | B04, B07 | Un drop nato fuori arena viene clampato nel playfield includendo il proprio raggio; centro, lati, angoli, 16:9/20:9/4:3 e restart sono verificati |
| B18J | Potenziamento Grigliata estiva | P1 | 3 | B06, B10–B12 | Ogni rank aumenta gli HP massimi e cura subito la differenza; stacking, cap, pausa e reset usano dati dichiarativi e non lasciano residui |
| B18K | Pulsante abilità con icona e cooldown circolare | P1 | 3 | B09A, B17A, B18B | L'icona selezionata è il target touch; riempimento circolare e secondi residui comunicano il cooldown senza ridurre il target sotto 44–48 unità logiche |
| B18L | Joystick dinamico | P1 | 5 | B03, B06A, B18B | Il primo tocco valido crea e possiede il joystick fino al rilascio; HUD e overlay sono esclusi e un secondo dito può attivare l'abilità |
| B18M | Migliorie grafiche delle abilità | P1 | 8 | B17A, B18E–B18F, B18H, B18K | Le otto abilità usano icone e VFX originali coerenti, registrati nel manifest e compatibili con priorità visive e budget Android |
| B18N | Cambia personaggio dal menu pausa | P1 | 3 | B06A, B17A | La pausa offre `CAMBIA PERSONAGGIO`; dopo conferma ripulisce in modo atomico la run e torna alla selezione senza clock, input o stato residuo |
| B18O | Welcome screen | P1 | 3 | B17A | All'avvio compare una schermata di benvenuto multipiattaforma prima della selezione; nessuna run viene inizializzata finché il giocatore non prosegue |
| B18P | Dimensioni configurabili dei controlli touch | P1 | 5 | B18K–B18L, B18O | Dimensione dell'icona abilità e del joystick regolabili e persistenti; il nuovo default rende l'abilità più facile da premere senza rompere safe area o multitouch |
| B18Q | Arena separata dal HUD minimo | P1 | 5 | B04, B09, B18B | XP e vita sono due barre piene e corpose con soli tag fissi `XP`/`HP`, senza ritratto o numeri; pausa e cronometro flottanti restano sopra un playfield che non accoglie Player, pickup, Boss, spawn o target |
| B18R | Durata e leggibilità di animazioni e VFX | P1 | 5 | B18C, B18M | Animazioni e feedback visivi restano percepibili più a lungo, senza alterare timing gameplay né mostrare aree attive oltre la loro durata reale |
| B18S | Sfondo arena ImageGen | P1 | 5 | B18Q, B18R | Uno sfondo raster originale generato con ImageGen migliora l'arena senza griglia, falsi ostacoli o perdita di contrasto; prompt, trasformazioni, licenza e hash sono registrati |
| B18T | Carosello selezione personaggi | P1 | 5 | B17A, B18O | Carosello implementato: profilo centrale, anteprime, swipe e navigazione multipiattaforma, sempre in `BOOT` fino alla conferma |
| B18U | Sprite del cast coerenti | P1 | 13 | B17A, B18C, B18M, B18T | Otto sprite Player originali rendono riconoscibili in gioco i ruoli della direzione visuale del cast, senza cambiare hitbox, movimento, passive o abilità |
| B18V | Hardening Windows/Android e performance | P0 | 8 | B16, B17A, B18–B18U, B18W | Android 12 minimo e Android 16 target, aspect ratio, touch, lifecycle, abilità e soak rispettano il budget sulla presentazione finale |
| B18W | Raffinamento della selezione personaggi | P1 | 5 | B18T, B18U, B18O | Il carosello esistente mette al centro il personaggio e le abilità, separa Back dalle frecce e riduce l'effetto da pannello di configurazione senza riaprire le regole `BOOT` |
| B22 | Boss piccione speciale e varianti Evil | P1 | 13 | B17A, B18H, B18U | Il piccione speciale è il Boss baseline; a ogni incontro il seed può sostituirlo con un `Evil <Nome>` dalla palette viola scura, senza ancora assegnargli l'abilità del profilo |
| B23 | Modalità Difesa Grigliata | P1 | 21 | B04–B16, B22 | Accanto a Sopravvivenza, una modalità difende una griglia centrale con carne e vita propria; nemici, terminali, pause, restart e layout restano coerenti |
| B24 | Scala visiva del Player | P1 | 3 | B18U, B18Q | Aumentare la resa runtime del personaggio senza cambiare hitbox o bilanciamento; leggibile su 16:9, 20:9 e 4:3 anche ad alta densità |
| B25 | Rimuovere la vita circolare sopra il Player | P1 | 3 | B18Q, B24 | Eliminare l'indicatore tondo ridondante sopra il personaggio; la barra HP globale resta l'unica fonte primaria della vita Player |
| B26 | Potenziamento danno dedicato | P1 | 3 | B10–B13 | Aggiungere una carta normale ripetibile che aumenta esplicitamente il danno dell'arma, con stacking, cap dell'effetto, reset e combinazione con passive/upgrade verificati |
| B27 | Refresh icone dei potenziamenti via ImageGen esterno | P1 | 5 | B10–B13, B18J | Sostituire le icone dei potenziamenti con un set pixel-art coerente già fornito; master e derivati runtime vengono tracciati nel manifest |
| B28 | Densità orde e TTK più bullet-hell | P1 | 8 | B04–B05, B14, B18V | Aumentare sensibilmente i nemici contemporanei e ridurre la vita media dei nemici base, mantenendo 60 FPS target e leggibilità di Player, pickup, proiettili e telegraph |
| B29 | Musica di sottofondo | P1 | 3 | B18 | Integrare una traccia loop adatta al tono arcade con licenza compatibile e provenienza registrata; volume/mute persistenti e loop senza stacchi percepibili |
| B30 | Boss senza aura circolare viola | P1 | 3 | B22 | Rimuovere l'aura/anello viola tondo attorno ai Boss; l'identità Evil resta affidata alla sfumatura/palette viola dello sprite e agli altri segnali già approvati |
| B31 | Padding esterno pausa e abilità | P1 | 3 | B18K, B18P, B18Q | Aumentare il margine di pausa e pulsante abilità dai bordi esterni/safe area senza ridurre target touch o rompere multitouch e aspect ratio |
| B32 | Welcome CTA coerente e impostazioni a ingranaggio | P1 | 5 | B18O, B18W | Il CTA arancione della welcome riusa la stessa placca pixel-fantasy di `Gioca con <Nome>`; Impostazioni diventa un pulsante ingranaggio in alto a destra, responsive e accessibile |
| B33 | Run continua e Boss ricorrenti | P1 | 8 | B14–B16, B22, B23 | La morte del primo Boss non chiude la run; Boss successivi seguono finestre da 240 s e, se una finestra scade con un Boss vivo, il prossimo spawna solo alla sua morte, senza Boss sovrapposti o burst arretrati |

Parallelizzazione sicura:

- dopo B01, il catalogo dati B10 può procedere mentre si implementa il combattimento B03–B06;
- B09A parte soltanto dopo B09 e non modifica il perimetro di B07–B09;
- dopo la stabilizzazione delle dimensioni UI e degli schemi dati, B17A procede per profilo completo (selezione + passiva + attiva) in piccoli lotti, mentre gli asset B18 restano sostituibili;
- B18D consuma la direzione B18C senza riaprire `InputRouter`; B18F estende il tipo area senza cambiare le aree statiche; B18I riusa il clamp circolare di `ArenaLayout` senza cambiare spawn o magnete;
- B18K e B18L possono procedere dopo i gate correnti con contratti touch separati ma una verifica multitouch comune; B18G e B18J condividono il framework level-up senza accoppiare i relativi dati; la produzione originale B18H e i VFX procedurali B18M possono avanzare in parallelo;
- B18N–B18O consolidano il flusso welcome → selezione → run → pausa; B18T realizza il carosello e B18W ne raffina il solo selettore senza riaprire le regole di avvio della run. B18P e B18Q stabilizzano controlli e playfield prima del passaggio percettivo B18R–B18S;
- profiling, soak e matrice finale B18V iniziano sulla baseline congelata B18C–B18U/B18W dopo la chiusura dei gate fisici combinati;
- B13 va integrato un effetto alla volta, con test combinatori, non come blocco unico a fine milestone.

### B18B — Identità visiva e priorità al campo di gioco

Direzione approvata: interfaccia leggibile e professionale, contenuto caricaturale
e volutamente assurdo. La grammatica visiva è pixel-art arcade, non cyber-tech
seria: pannelli scuri semplici, ciano riservato a sistema/informazioni, rosa a
vita e danno, giallo-arancio ad abilità e cooldown, con pochi bordi colorati.

Prima iterazione, senza introdurre nuovi asset obbligatori:

- riunire il HUD in una fascia superiore compatta alta circa `64–72` unità
  logiche: ritratto, livello e vita a sinistra, timer al centro e pausa a destra;
- trasformare la progressione XP in una linea alta `6–8` unità logiche sotto la
  fascia; non mostrare `ONDATA` finché il Director non possiede vere ondate
  numerate;
- ridurre il raggio visivo del joystick da `84` a circa `68` unità logiche; la
  prima baseline conserva area touch e comportamento, poi B18L sostituisce la
  zona fissa con l'origine dinamica senza cambiare deadzone o raggio input;
- ridurre la card dell'abilità da circa `320×128` a `230–250×88–96` unità
  logiche, mantenendo icona, stato, cooldown e un target touch ampio;
- eliminare griglia regolare e grande rettangolo ciano dell'arena; introdurre
  via codice variazioni tonali, giunti, macchie e crepe molto leggere, senza
  ostacoli o dettagli che competano con attori, pickup e telegraph;
- aggiungere hit flash temporizzato (`0,06–0,08 s`), reazione/squash al colpo,
  pop e particelle alla morte, feedback del danno Player, scia del proiettile e
  impulso quando l'abilità torna pronta;
- mantenere il protagonista corrente come riferimento qualitativo. Nuovi sprite
  pixel-art dei nemici vengono valutati dopo questa iterazione, sulla base del
  miglioramento ancora necessario.

Vincoli e gate di uscita:

- tutte le misure sopra sono unità logiche del viewport Godot, non pixel fisici
  del display, e non modificano collisioni, raggi o altre distanze gameplay;
- icona pausa e pulsante abilità conservano target touch di almeno `44–48`
  unità logiche; la riduzione del joystick è solo visiva e non restringe la sua
  area di acquisizione;
- HUD, Boss UI, overlay e controlli non si sovrappongono e restano nella safe
  area a 16:9, 18:9, 20:9 e 4:3;
- su device fisico il Player continua a muoversi tenendo il joystick con un dito
  mentre il secondo attiva ripetutamente l'abilità;
- hit, proiettili ostili e telegraph restano distinguibili durante Boss, abilità
  persistenti e densità elevata;
- smoke, screenshot prima/dopo, export Windows/Android e log privi di
  `SCRIPT ERROR` o `FATAL EXCEPTION` precedono il freeze visivo per B18V.

I gate manuali e percettivi residui B18B a 20:9 e 4:3 sono stati chiusi il
25 agosto 2026 insieme al freeze visivo del ciclo.

### Ciclo operativo B18C–B18W

Questo è il ciclo progressivo B18C–B18W. Gli stati hanno il seguente
significato:

- `DA DEFINIRE`: mancano decisioni o asset che cambiano l'implementazione;
- `BLOCCATO`: contratto definito, ma una dipendenza obbligatoria non è ancora chiusa;
- `PRONTO`: requisiti sufficienti per iniziare;
- `IN CORSO`: implementazione aperta nel worktree;
- `IN VERIFICA`: codice e test automatici completati, gate manuali ancora aperti;
- `VERIFICATO`: tutti i gate pertinenti sono chiusi e le evidenze sono registrate,
  ma il worktree attende ancora il commit dedicato;
- `COMPLETATO`: tutti i gate pertinenti sono chiusi, le evidenze sono registrate
  e la modifica appartiene a un commit dedicato.

| ID | Blocco | Stato | Dipendenze o gate aperti |
|---|---|---|---|
| B18C | Player animato e direzione persistente | COMPLETATO | Gate Windows e Pixel 9 chiusi il 24 agosto 2026 |
| B18D | Powerslide di Bea | COMPLETATO | Gate Windows e Pixel 9 chiusi il 24 agosto 2026 |
| B18E | Tuoni di Zat | COMPLETATO | Gate automatici, Windows, Android statico e verifica manuale Pixel 9 chiusi il 25 agosto 2026 |
| B18F | Abilità inseguitrice di Alea | COMPLETATO | Gate Windows e Pixel 9 chiusi il 24 agosto 2026 |
| B18G | Rank delle abilità principali | COMPLETATO | Gate automatici, Windows, Android statico e verifica manuale Pixel 9 chiusi il 25 agosto 2026 |
| B18H | Nemici piccione | COMPLETATO | Gate automatici, Windows e Pixel 9 chiusi il 24 agosto 2026 |
| B18I | XP confinato nell'arena | COMPLETATO | Gate chiusi; commit dedicato `e58cbd0` |
| B18J | Grigliata estiva | COMPLETATO | Gate automatici, Windows, Android statico e interazione manuale Pixel 9 chiusi il 25 agosto 2026 |
| B18K | Pulsante abilità con icona e cooldown circolare | COMPLETATO | Gate chiusi; commit dedicato `81b47f6` |
| B18L | Joystick dinamico | COMPLETATO | Gate chiusi, inclusa regressione lock/resume; commit dedicato `d6625d7` |
| B18M | Migliorie grafiche delle abilità | COMPLETATO | Refresh ImageGen: automatici, Windows, APK statico e controllo percettivo Pixel 9 chiusi il 25 agosto 2026 |
| B18N | Cambia personaggio dal menu pausa | COMPLETATO | Gate automatici, Windows, APK statico e runtime Pixel 9 chiusi il 24 agosto 2026 |
| B18O | Welcome screen | COMPLETATO | Gate automatici, Windows, APK statico e controllo percettivo 20:9 della variante finale sul Pixel 9 chiusi il 24 agosto 2026 |
| B18P | Dimensioni configurabili dei controlli touch | COMPLETATO | Gate automatici, Windows, APK statico e multitouch reale Pixel 9 chiusi il 25 agosto 2026 |
| B18Q | Arena separata dal HUD minimo | COMPLETATO | Automatici, Windows, APK statico, percorso Pixel 9 20:9 e confronto percettivo manuale multi-aspect chiusi il 25 agosto 2026 |
| B18R | Durata e leggibilità di animazioni e VFX | COMPLETATO | Timing centralizzati e separati dal gameplay; `42/42`, Windows, Android e verifica umana Windows/Pixel 9 chiusi il 25 agosto 2026 |
| B18S | Sfondo arena ImageGen | COMPLETATO | Asset, automatici, Windows, APK, Pixel 9 e confronto percettivo a luminosità controllata chiusi il 25 agosto 2026 |
| B18T | Carosello selezione personaggi | COMPLETATO | Implementazione, `40/40`, Windows, APK, percorso Pixel 9, tap manuale e confronto fisico chiusi il 25 agosto 2026 |
| B18U | Sprite del cast coerenti | COMPLETATO | Otto sprite e sorgenti HD tracciati; automatici, Windows, APK, percorso reale e gate percettivo in movimento chiusi il 25 agosto 2026 |
| B18V | Hardening Windows/Android e performance | COMPLETATO | Profili, diagnostica, stress, smoke, regressione, runtime Windows e APK statico verdi; chiusura operativa accettata dal proprietario il 25 agosto 2026 con distinzione dalle prove non registrate |
| B18W | Raffinamento della selezione personaggi | COMPLETATO | Due card laterali separate per passiva/attiva sostituiscono il kit; automatici, APK finale e confronto percettivo Pixel 9 accettati il 26 agosto 2026 |
| B22 | Boss piccione speciale e varianti Evil | COMPLETATO | Automatici, Windows, APK statico e percorso fisico Pixel 9 chiusi il 26 agosto 2026; l'hang host post-`[ DONE ]` dell'exporter resta distinto dall'artefatto valido |
| B23 | Modalità Difesa Grigliata | PRONTO | Contratto e prerequisiti chiusi; è il prossimo backlog operativo |
| B24 | Scala visiva del Player | IN VERIFICA | Baseline candidata `1,25×` applicata solo allo sprite; automatici `44/44`, Windows runtime e APK statico verdi, confronto percettivo Windows/Pixel 9 aperto |
| B25 | Rimuovere la vita circolare sopra il Player | IN VERIFICA | Indicatore Player rimosso; conserva la barra HP globale e restano i gate percettivi Windows/Pixel 9 |
| B26 | Potenziamento danno dedicato | IN VERIFICA | `Forchettone da Braciere` è ripetibile a `×1,15`; le quattro carte statistiche normali sostituiscono i fallback rimossi |
| B27 | Refresh icone dei potenziamenti via ImageGen esterno | IN VERIFICA | Dieci master forniti sono derivati in PNG `128×128`, tracciati nel manifest e fuori dagli export |
| B28 | Densità orde e TTK più bullet-hell | IN VERIFICA | Tuning, budget XP e smoke dedicato implementati; profiling runtime Windows/Pixel 9 a 60 FPS ancora aperto |
| B29 | Musica di sottofondo | IN VERIFICA | `Super Wreck Roadway (loop)` CC0 di Umplix è integrata su bus Music separato; il cambio asset non riesegue automatici, Windows o APK su richiesta, ascolto Windows/Pixel 9 aperto |
| B30 | Boss senza aura circolare viola | PRONTO | Rimuove solo l'anello/aura; palette Evil B22 e telegraph gameplay restano invariati |
| B31 | Padding esterno pausa e abilità | PRONTO | Correzione safe-area/presentazione, target touch invariati |
| B32 | Welcome CTA coerente e impostazioni a ingranaggio | IN VERIFICA | `GIOCA` riusa la placca pixel-fantasy B18W, fluttua senza riquadro esterno e non disegna outline focus; Impostazioni è un ingranaggio safe-area da `60×60`; focused/relevant e APK statico verdi, Pixel 9 accettato dal proprietario, restano Windows e Full |
| B33 | Run continua e Boss ricorrenti | PRONTO | Nuovo contratto di run che supersede a valle la vittoria al primo Boss del vertical slice storico |

#### B18C — Player animato e direzione persistente

Stato: `COMPLETATO`.

- [x] Rimuovere il cannoncino visibile e il vecchio fondo circolare azzurro.
- [x] Animare il personaggio durante il movimento e mostrare una posa ferma al
  neutro.
- [x] Determinare destra/sinistra dall'ultimo movimento orizzontale non nullo e
  conservare la direzione al neutro o durante il movimento verticale.
- [x] Esporre alle abilità sia il lato tramite `Player.get_facing_direction()`
  sia il vettore tramite `Player.get_last_movement_direction()`.
- [x] Coprire Lollo, Migi e Marghe con un gait procedurale, perché il foglio CC0
  contiene per loro una sola posa laterale valida.
- [x] Smoke dedicato, suite completa `22/22`, project smoke ed export/smoke
  Windows senza errori runtime.
- [x] Conferma visiva finale Windows dopo le correzioni a cannoncino/background:
  posa neutra, movimento e flip verificati sulla build corrente.
- [x] Test Android reale su Pixel 9: animazione, direzione persistente, pausa,
  lock/resume, restart e multitouch approvati il 24 agosto 2026.

Dettagli ed evidenze: [`b18c-verification.md`](./b18c-verification.md).

#### B18D — Powerslide di Bea

Stato: `COMPLETATO`.

- [x] Rinominare l'attiva da **Scia di Fuoco Z** a **Powerslide** e sostituire
  l'icona con il pattino inline Pinhead CC0, registrandone provenienza e licenza.
- [x] Fotografare origine e `Player.get_last_movement_direction()`
  all'attivazione, quindi teletrasportare in linea retta senza rileggere il
  joystick.
- [x] Lasciare dietro al teletrasporto una scia rettilinea da `4 s`, senza
  zig-zag; distanza (`dash_distance`) e danno (`damage`) restano dati.
- [x] Teletrasporto, scia e cooldown avanzano solo in `RunController.RUNNING` e
  vengono ripuliti al restart.
- [x] Smoke dedicato per direzione persistente, pausa e due run; suite `23/23`,
  project smoke, export e smoke Windows con `B18D_CONTRACT_OK`.
- [x] Export statico APK ARM64, che non equivale a verifica runtime Android.
- [x] Verifica manuale Windows approvata il 24 agosto 2026.
- [x] Test Android reale: joystick con un dito, Powerslide con il secondo,
  scia rettilinea indipendente dall'input successivo, pausa e restart approvati
  sul Pixel 9 il 24 agosto 2026.

Dettagli ed evidenze: [`b18d-verification.md`](./b18d-verification.md).

#### B18E — Tuoni di Zat

Stato: `COMPLETATO`.

Sequenza richiesta:

1. attivazione;
2. breve preavviso visivo;
3. flash bianco tipo tuono su tutto il viewport logico;
4. applicazione ritardata del danno a tutti i nemici validi;
5. rimozione del flash e chiusura dell'effetto.

Contratto definitivo:

- [x] Colpisce anche i nemici entrati nell'arena dopo l'attivazione ma prima
  dell'impatto.
- [x] Infligge il `50%` della vita massima ai nemici e il `20%` ai Boss.
- [x] Il flash copre l'intero viewport logico.
- [x] Il cooldown di rank `1` è `60 s` di gameplay; il preavviso dura `0,45 s`,
  l'impatto avviene una sola volta e il flash si chiude entro `0,30 s` senza
  pulsazioni ripetute.
- [x] Il flash usa alpha massimo `0,55` su Windows e `0,40` su Android, con
  salita `0,06 s`, tenuta `0,06 s` e dissolvenza `0,18 s`.
- [x] L'opzione persistente **Flash ridotti** porta l'alpha massimo a `0,15`,
  elimina la tenuta e conserva preavviso, onde del tuono, audio e danno.
  È modificabile dal menu pausa e non cambia il bilanciamento.
- [x] Target e percentuali sono fotografati all'impatto, non all'attivazione;
  ogni bersaglio vivo viene processato una volta. Cooldown, preavviso e flash
  avanzano soltanto in `RUNNING` e vengono rimossi a morte, cambio profilo o
  restart.
- [x] Smoke dedicato `B18E_ZAT_THUNDER_STORM_SMOKE_OK`, regressione completa
  `28/28`, project smoke, export e runtime Windows, export Android statico.
- [x] Gate Pixel 9: multitouch, flash standard/ridotto, 20:9, lifecycle e
  cleanup reale verificati manualmente il 25 agosto 2026.

Dettagli ed evidenze: [`b18e-verification.md`](./b18e-verification.md).

#### B18F — Abilità inseguitrice di Alea

Stato: `COMPLETATO`.

- [x] Centrare l'effetto sul personaggio per tutta la durata, aggiornandolo
  dalla posizione corrente del `Player` anziché dal punto di lancio.
- [x] Verificare pausa, cambio di direzione, termine, restart e cambio profilo
  con uno smoke dedicato.
- [x] Suite completa e project smoke `24/24`, export e smoke Windows.
- [x] Verifica manuale Windows approvata il 24 agosto 2026.
- [x] Export e controlli statici APK Android ARM64.
- [x] Runtime Android reale: joystick con un dito, attivazione con il secondo e
  area centrata su Alea durante il movimento approvati sul Pixel 9 il 24 agosto
  2026.

Dettagli ed evidenze: [`b18f-verification.md`](./b18f-verification.md).

#### B18G — Rank delle abilità principali

Stato: `COMPLETATO`.

- [x] Ogni attiva parte al rank `1`; il level-up può offrire soltanto i quattro
  passaggi `2–5` dell'abilità equipaggiata. Al rank `5` la carta non è più
  eleggibile.
- [x] La carta usa un solo ID autorevole derivato dall'abilità selezionata e non
  può comparire due volte nella stessa offerta.
- [x] Il rank resta solo nella run; non introduce meta-progressione.
- [x] Ogni abilità ha una progressione specifica, anche mista: danno, area,
  durata, cooldown, numero di colpi o altri effetti.
- [x] Ogni rank è uno snapshot completo dichiarato nel `Resource`; non muta il
  profilo condiviso. Un effetto o cooldown già iniziato conserva lo snapshot
  dell'attivazione, mentre il nuovo rank vale dall'attivazione successiva.

Valori autorevoli (`cd` in secondi; distanze e raggi in unità logiche mondo):

| Attiva | R1 | R2 | R3 | R4 | R5 |
|---|---|---|---|---|---|
| Onda d'Urto Tellurica | `cd 8`, danno `20`, raggio `220`, knockback `300` | danno `26` | raggio `260` | `cd 7`, stun `0,25` | danno `36`, raggio `280`, knockback `380` |
| Powerslide | `cd 10`, distanza `320`, scia `4 s`, danno `6`, larghezza `40` | danno `8` | distanza `380`, larghezza `48` | `cd 9`, scia `5 s` | distanza `440`, danno `11`, larghezza `56` |
| Tempesta di Tuoni | `cd 60`, normali `50%`, Boss `20%` | normali `55%` | `cd 55`, Boss `22%` | normali `60%`, Boss `24%` | `cd 50`, normali `70%`, Boss `28%` |
| Gran Piroetta | `cd 9`, `1,2 s`, danno `5`, `12 hit/s`, raggio `140` | danno `6` | `1,4 s`, raggio `165` | `cd 8`, `14 hit/s` | `1,6 s`, danno `8`, raggio `180` |
| Colata di Cemento | `cd 12`, `4 s`, danno `3/0,5 s`, raggio `200`, velocità nemici `×0,50` | danno `4/0,5 s` | `5 s`, raggio `230` | `cd 11`, velocità `×0,40` | `6 s`, danno `6/0,5 s`, raggio `250` |
| Cosplay Casuale | `cd 14`, copia rank `1` | `cd 13` | copia rank `2` | `cd 12`, non ripete l'ultima abilità se esiste un'alternativa | `cd 11`, copia rank `3`, stessa regola anti-ripetizione |
| Rallentamento Zen | `cd 11`, `3,5 s`, raggio `260`, velocità nemici `×0,40` | `4,5 s` | raggio `300` | `cd 10`, velocità `×0,32` | `6 s`, raggio `340`, velocità `×0,25` |
| Reggeton time! | `cd 13`, clone `3 s` | clone `4 s` | `cd 12` | clone `5 s` | `cd 10`, clone `6 s` |

Le celle successive ereditano i valori non citati dalla colonna precedente.
Cosplay risolve il profilo copiato al rank indicato, sempre con i filtri di
compatibilità e anti-ricorsione; non assegna rank alle altre abilità.

- [x] Cinque snapshot completi e immutabili dichiarati per ciascuna delle otto
  abilità; applicazione runtime senza mutare le risorse condivise.
- [x] Una sola carta autorevole per l'abilità equipaggiata, quattro passaggi
  `2–5`, ID unico, cap, reset e cambio personaggio integrati nel level-up.
- [x] Cooldown ed effetto già iniziati conservano lo snapshot di attivazione;
  Cosplay copia il rank dichiarato e applica l'anti-ripetizione dai rank `4–5`.
- [x] Smoke `B18G_ABILITY_RANKS_SMOKE_OK`, regressione completa `29/29`, project
  smoke, export e runtime Windows, export Android statico ARM64.
- [x] Gate Pixel 9: tap reali sui passaggi rank, scomparsa al cap, nuovo profilo
  dalla successiva attivazione, lifecycle, restart e cambio personaggio puliti,
  verificati manualmente il 25 agosto 2026.

Dettagli ed evidenze: [`b18g-verification.md`](./b18g-verification.md).

#### B18H — Nemici piccione

Stato: `COMPLETATO`.

- [x] Sostituire le sfere rosse con piccioni intesi come uccelli visibili.
- [x] Comportamento, collisioni, danno e spawn restano invariati salvo nuova
  decisione esplicita.
- [x] Produrre internamente due sprite originali senza dipendenze di terzi:
  **base**, piccione grigio-blu con petto chiaro, collo verde/viola e becco
  arancio; **speciale**, stessa silhouette con piumaggio antracite, collare
  magenta e accenti oro. Canvas sorgente `48×48`, silhouette leggibile a `40`
  unità logiche, sfondo trasparente e bordo scuro da almeno `2` texel.
- [x] Entrambe le varianti hanno posa neutra e due fasi d'ala; il flip segue il
  verso orizzontale di inseguimento. L'animazione è solo presentazionale e si
  ferma fuori da `RUNNING`.
- [x] La variante base sostituisce il nemico ordinario. La speciale è un asset
  pronto per profili futuri e fixture visuali, ma non entra nello spawn corrente
  e non introduce statistiche o probabilità nascoste.
- [x] Asset originali OpenAI-assisted registrati con prompt, trasformazioni e
  SHA-256; smoke `B18H_PIGEON_ENEMIES_SMOKE_OK`, regressione `31/31`, project
  smoke, export e runtime Windows completati senza errori.
- [x] Export APK ARM64, controlli statici API `31`/`36` e firma v2 completati.
- [x] Runtime Pixel 9 a 20:9: piccioni leggibili, flip coerente, cold launch e
  log del processo puliti il 24 agosto 2026.

Dettagli ed evidenze: [`b18h-verification.md`](./b18h-verification.md).

#### B18I — XP confinato nell'arena

Stato: `COMPLETATO`.

- [x] Correggere tramite il playfield di `ArenaLayout` la posizione dell'XP
  generato da una morte fuori arena.
- [x] Garantire una posizione valida e raggiungibile includendo il raggio del
  pickup.
- [x] Verificare centro, bordi, angoli, 16:9, 20:9, 4:3 e restart con
  `B18I_XP_ARENA_CONFINEMENT_SMOKE_OK`.
- [x] Regressione completa, project smoke, export e runtime Windows.
- [x] Export e controlli statici APK Android ARM64.
- [x] Runtime Android reale su Pixel 9 ARM64: drop ai bordi interamente interni
  e raggiungibili, raccolta e cleanup al restart approvati il 24 agosto 2026.

Dettagli ed evidenze: [`b18i-verification.md`](./b18i-verification.md).

#### B18J — Potenziamento Grigliata estiva

Stato: `COMPLETATO`.

- [x] `Grigliata estiva` è una carta comune con `max_rank = 5`; ogni rank
  moltiplica gli HP massimi per `×1,15`. Il contributo cumulativo è quindi
  `×1,15`, `×1,3225`, `×1,520875`, `×1,74900625`, `×2,0113571875`.
- [x] Il contributo della sola carta ha cap dati `×2,05`; la formula si compone
  moltiplicativamente con passive e altri upgrade secondo `PROG-006`.
- [x] A ogni rank si fotografa il vecchio massimo, si ricalcola il nuovo e si
  cura esattamente `max(0, nuovo_massimo - vecchio_massimo)`. Non si preserva la
  percentuale di vita e non si resuscita un Player morto.
- [x] La scelta viene applicata atomicamente una sola volta durante `LEVEL_UP`;
  pausa e lifecycle non la riapplicano. Restart e cambio personaggio riportano
  rank, moltiplicatore, massimo e vita ai valori iniziali della nuova run.
- [x] Resource `summer_grill.tres`, effect ID dedicato, icona raster B27 e
  composizione col registry upgrade integrati senza mutare le risorse condivise.
- [x] Smoke `B18J_SUMMER_GRILL_SMOKE_OK`, regressione completa `30/30`, project
  smoke, export e runtime Windows, export Android statico ARM64.
- [x] Gate Pixel 9: tap reali sui cinque rank, cura del delta, composizione con
  `L'Ansia`, cap, lifecycle, restart e cambio personaggio puliti, verificati
  manualmente il 25 agosto 2026.

Dettagli ed evidenze: [`b18j-verification.md`](./b18j-verification.md).

#### B18K — Pulsante abilità con cooldown circolare

Stato: `COMPLETATO`.

- [x] Usare l'icona dell'abilità selezionata come superficie di attivazione.
- [x] Mostrare un riempimento circolare durante il cooldown.
- [x] Mostrare il tempo residuo al centro.
- [x] Quando l'abilità è pronta, rimuovere il timer e rendere l'icona chiaramente
  attivabile.
- [x] Rimuovere nome, label di stato, card e sfondo rettangolare: fuori dal
  cooldown deve restare visibile soltanto l'icona.
- [x] Conservare un target touch di `64×64` unità logiche.
- [x] Smoke dedicato, regressione `26/26`, project smoke, export e runtime
  Windows con `B18K_CONTRACT_OK`; layout 16:9, 20:9 e 4:3 verificati.
- [x] Export APK ARM64 e controlli statici API `31`/`36` e firma v2.
- [x] Runtime touch Android reale: pausa, restart, cooldown circolare e
  attivazioni ripetute col secondo dito mentre il joystick possiede il primo
  approvati sul Pixel 9 il 24 agosto 2026.

Dettagli ed evidenze: [`b18k-verification.md`](./b18k-verification.md).

#### B18L — Joystick dinamico

Stato: `COMPLETATO`.

- [x] Il primo dito che tocca un'area di gioco valida determina origine e
  comparsa del joystick.
- [x] Calcolare il movimento rispetto all'origine e mantenere l'ownership dello
  stesso dito.
- [x] Nascondere il joystick al rilascio e ricrearlo al tocco successivo.
- [x] Ignorare i tocchi iniziati sopra HUD, Boss UI, pulsante abilità o overlay.
- [x] Conservare l'attivazione dell'abilità con un secondo dito senza lasciare
  al `Control` una hit area GUI che lo intercetti.
- [x] Smoke dedicato per ownership, secondo dito, neutral-to-rearm, pausa,
  focus, cancellazione touch, restart e layout 16:9, 20:9 e 4:3.
- [x] Regressione completa `27/27`, project smoke, export e runtime Windows con
  `B18L_CONTRACT_OK`; export APK ARM64 e build Gradle pulita.
- [x] Installazione e cold launch su Pixel 9 Android 17/API 37, drag floating a
  un dito, Back, Home/ritorno, pausa esplicita e log runtime puliti.
- [x] Gate manuale Pixel 9: due dita fisiche joystick più abilità, ripresa dopo
  sblocco sicuro e restart senza direzioni o grafica residue. La prima prova ha
  rilevato uno spostamento causato dal passaggio portrait transitorio del lock;
  la correzione è coperta da smoke e la controprova fisica conserva la posizione.

Dettagli ed evidenze: [`b18l-verification.md`](./b18l-verification.md).

#### B18M — Migliorie grafiche delle abilità

Stato: `COMPLETATO` dopo il refresh ImageGen.

- [x] La baseline di release conserva VFX originali disegnati con primitive
  Godot e aggiunge otto emblemi PNG RGBA `256×256` prodotti con OpenAI ImageGen
  built-in. I vecchi derivati SVG runtime sono stati rimossi; la sorgente
  Pinhead CC0 resta soltanto come storico documentato.
- [x] Gli emblemi sostituiscono le icone in HUD e carte rank senza cambiare il
  target B18K `64×64`; nome, label, card e sfondo rettangolare restano assenti.
- [x] La stessa texture entra in un burst scene-local, introdotto da B18M a
  `0,72 s` e portato a `1,20 s` da B18R, con profilo
  distinto per abilità: impatto, scorrimento, tuono, rotazione, caduta, reveal,
  respiro o beat. Il burst avanza soltanto in `RUNNING`; B18R ne separa la coda
  non interattiva dall'effetto gameplay senza modificare gameplay o input.
- [x] Linguaggio VFX: Magno usa crepe e anelli tellurici; Bea scia a nastro con
  scintille; Zat nube e onde del tuono, preavviso e flash accessibile; Alea archi
  rotanti; Aleo pozza grigio-ciano con bordo e bolle; Lollo confetti più palette
  dell'abilità copiata; Migi anelli concentrici e particelle lente; Marghe clone,
  cassa e note musicali. Gli effetti alleati restano sotto telegraph e proiettili
  ostili e non comunicano collisioni più ampie di quelle reali.
- [x] Manifest aggiornato con generatore, prompt condiviso e soggetti specifici,
  data, origine, autore, licenza, crop, margine, downscale, ottimizzazione e
  SHA-256 per ogni PNG.
- [x] Budget Android per una singola attivazione: massimo `1` overlay fullscreen,
  `64` particelle vive, `1` emblema ImageGen e `2` materiali aggiuntivi per
  famiglia; il profiling B18V può ridurre il budget senza modificare gameplay o
  timing.
- [x] Implementare le otto grammatiche con primitive `CanvasItem`: anelli e
  crepe, nastro e scintille, nube e onde, archi, pozza e bolle, confetti nella
  palette copiata, anelli e moti zen, clone/cassa/note. Collisioni, raggio,
  danno, durata, cooldown e priorità di rendering restano invariati.
- [x] Registrare sorgenti procedurali e icone definitive in
  [`assets/art/vfx/ASSET-MANIFEST.md`](../assets/art/vfx/ASSET-MANIFEST.md), con
  origine, autore, licenza, trasformazioni e SHA-256 verificati dallo smoke.
- [x] Refresh ImageGen: smoke `B18M_ABILITY_VISUALS_SMOKE_OK`, regressione
  completa `32/32`, project smoke, export e runtime Windows con
  `B18M_CONTRACT_OK`; export APK ARM64, API `31`/`36`, firma v2 e sola ABI
  `arm64-v8a` chiusi.
- [x] Controllo percettivo Pixel 9 a 20:9 delle nuove icone a `42 px` e degli
  otto burst in movimento/densità elevata completato il 25 agosto 2026. Il gate
  B18L resta l'evidenza autorevole separata per il multitouch.

Dettagli ed evidenze: [`b18m-verification.md`](./b18m-verification.md).

#### B18N — Cambia personaggio dal menu pausa

Stato: `COMPLETATO`.

- [x] Aggiungere `CAMBIA PERSONAGGIO` al solo menu di pausa manuale, con focus e
  target touch coerenti con `RIPRENDI`; l'azione è disponibile con mouse,
  tastiera, controller e touch.
- [x] Chiedere conferma prima di abbandonare una run attiva. Back/cancel chiude
  la conferma e lascia la run in pausa; non può provocare una ripresa implicita.
- [x] Dopo la conferma, riusare lo stesso cleanup autorevole del cambio profilo
  terminale e tornare al selettore in `BOOT`: nemici, Boss, proiettili, XP,
  offerte, rank, cooldown, status, VFX, input e seed della run non sopravvivono.
- [x] Smoke dedicato su pausa → annulla → riprendi e pausa → conferma →
  selezione → nuova run; regressione completa, Windows export e Pixel 9 con log
  privi di `SCRIPT ERROR`, `FATAL EXCEPTION` e touch bloccati.

Dettagli ed evidenze: [`b18n-verification.md`](./b18n-verification.md).

#### B18O — Welcome screen

Stato: `COMPLETATO`.

- [x] Mostrare all'avvio una welcome screen prima della selezione personaggio,
  senza inizializzare clock, spawn, input gameplay o stato della run.
- [x] Esporre almeno `GIOCA` e accesso alle impostazioni, con layout safe-area,
  focus iniziale e navigazione tramite mouse, tastiera, controller, touch e Back.
- [x] `GIOCA` apre il selettore; solo la conferma del personaggio crea la run.
  Tornare indietro dal selettore riapre la welcome screen senza stato residuo.
- [x] Smoke del flusso welcome → selezione → run e ritorno, matrice
  16:9/20:9/4:3, export Windows/Android e cold launch reale su Pixel 9.
- [x] Refresh visuale: reference pixel-art ripulita con ImageGen in un fondale
  privo di UI raster e con gli otto archetipi fuori dal centro; logo fornito dal
  proprietario e pulsanti arcade restano elementi distinti e responsive. Le
  impostazioni nascondono il logo per non coprire il cast; prompt, origini, crop
  e hash sono registrati senza anticipare B18S.
- [x] Ripetere sul Pixel 9 il controllo percettivo 20:9 della variante finale:
  Migi donna con occhiali e capelli neri, Marghe dai capelli neri molto lunghi e
  corporatura morbida, Bea senza casco con capo viola e capelli lunghi ricci,
  Lollo dai capelli scuri in costume retrofuturista e Zat con caschetto e divisa
  bianco-ciano da infermiera.
- [x] Verificare sul Pixel 9 la ricomposizione dalla reference e il logo finale:
  welcome e impostazioni mantengono tutti gli otto volti fuori dai pannelli,
  con centro leggibile e target interamente nella safe area.

Dettagli ed evidenze: [`b18o-verification.md`](./b18o-verification.md).

#### B18P — Dimensioni configurabili dei controlli touch

Stato: `COMPLETATO`.

- [x] Aggiungere nelle impostazioni, raggiungibili da welcome screen e pausa,
  due regolazioni indipendenti e persistenti per dimensione icona abilità e
  joystick; valori non validi nel file utente vengono clampati a un intervallo
  sicuro.
- [x] Aumentare il default dell'abilità rispetto alla baseline B18K `64×64` con
  icona da `42`, facendo crescere insieme immagine e hit target. Il valore finale
  viene congelato dopo il controllo fisico, perché l'attuale baseline è troppo
  piccola e difficile da premere.
- [x] Per il joystick scalare coerentemente base, manopola, deadzone e raggio di
  trascinamento; l'origine resta dinamica nell'intera safe area utile e la scala
  non restringe l'acquisizione né intercetta il secondo dito.
- [x] Applicare le modifiche in anteprima e senza riavvio, senza sovrapporre HUD,
  Boss UI, gesture edge o icona abilità agli estremi supportati.
- [x] Smoke di persistenza, clamp e geometria; matrice 16:9/20:9/4:3 e prova
  Pixel 9 con joystick tenuto da un dito e attivazioni ripetute dell'abilità col
  secondo per ogni scala supportata.

Dettagli ed evidenze: [`b18p-verification.md`](./b18p-verification.md).

#### B18Q — Arena e HUD minimo a barre

Stato: `COMPLETATO`; implementazione, smoke dedicato, regressione completa
`41/41`, project smoke, Windows, APK statico, percorso runtime Pixel 9 20:9 e
confronto percettivo manuale 16:9, 18:9, 20:9 e 4:3 chiusi.

- [x] Ridurre il HUD superiore a due sole barre senza icona Player, livello o
  valori numerici: esperienza a tutta larghezza in alto e vita a tutta larghezza
  immediatamente sotto. Le barre sono più corpose, arrotondate e mostrano
  soltanto i tag fissi `XP` e `HP` sul bordo sinistro. Il pulsante pausa resta flottante a
  destra nella stessa fascia, senza spezzare o ridurre la larghezza visiva delle
  barre e con target touch invariato.
- [x] Mostrare soltanto il cronometro, leggermente più grande, centrato e
  flottante sotto le due barre: rimuovere la label `Tempo` e ogni sfondo/card
  del timer. Il cronometro conserva il clock autorevole e resta fermo fuori da
  `RunController.RUNNING`.
- [x] Fare derivare ad `ArenaLayout` il playfield dalla safe area meno l'intera
  fascia superiore occupata dalle due barre, pausa e cronometro; nessun limite
  usa coordinate fisse 1280×720.
- [x] Usare il nuovo rect autorevole per clamp di Player e drop XP, spawn,
  despawn, ingressi, Boss, telegraph e target di attacchi: nessuna entità di
  gameplay può finire dietro vita o XP.
- [x] Conservare l'invariante lock/resume B18L: layout portrait transitori non
  riclappano il Player e il rect landscape stabile viene applicato prima della
  ripresa esplicita.
- [x] Smoke dedicato su centro, lati, angoli, pickup e Boss; assert di barre a
  tutta larghezza, soli tag `XP`/`HP`, assenza di ritratto, valori e label
  `Tempo`, timer trasparente e pausa raggiungibile. Smoke, runtime Windows e
  percorso Pixel 9 20:9 via ADB sono verdi.
- [x] Verifica percettiva e runtime manuale con interazione fisica a 16:9,
  18:9, 20:9 e 4:3 su Windows e Android fisico completata il 25 agosto 2026.

Dettagli ed evidenze: [`b18q-verification.md`](./b18q-verification.md).

#### B18R — Durata e leggibilità di animazioni e VFX

Stato: `COMPLETATO`.

- [x] Centralizzare i timing puramente presentazionali e allungare le animazioni
  one-shot oggi difficili da percepire: burst abilità B18M, entrate/uscite,
  reazioni, morte e impulso di prontezza. Walk cycle e animazioni continue
  restano sincronizzati al relativo stato.
- [x] Portare i burst principali oltre la breve baseline B18M da `0,72 s`: il
  valore finale `1,20 s` è stato approvato nel confronto percettivo umano
  Windows/Pixel 9; hit flash resta breve a `0,075–0,08 s`.
- [x] Separare durata visiva e regole gameplay: danno, tick, cooldown, raggio e
  collisioni non cambiano. Un'area non può apparire attiva dopo la fine reale;
  le code usano dissolvenze sibling chiaramente non interattive.
- [x] Pausa, level-up, Boss intro e terminali congelano o ripuliscono gli effetti
  secondo il loro contratto; restart e cambio personaggio non lasciano tween,
  timer o nodi residui.
- [x] Smoke deterministico sui timing e due run consecutive, regressione `42/42`,
  runtime Windows, APK Android, percorso reale Pixel 9 e gate percettivo umano
  chiusi il 25 agosto 2026.

Dettagli ed evidenze: [`b18r-verification.md`](./b18r-verification.md).

#### B18S — Sfondo arena ImageGen

Stato: `COMPLETATO`.

- [x] Usare OpenAI ImageGen built-in per produrre varianti originali dello
  sfondo raster dell'arena, coerenti con la pixel-art arcade caricaturale e prive
  di testo, personaggi, oggetti interattivi, griglia debug, bordo ciano o falsi
  ostacoli.
- [x] Progettare l'asset per crop/tile responsive a 16:9–20:9 e 4:3, con texture
  a basso contrasto dietro il playfield; attori, pickup, telegraph e proiettili
  ostili mantengono sempre la priorità visiva.
- [x] Salvare nel repository soltanto la variante scelta e gli eventuali
  derivati runtime. Registrare nel manifest generatore, prompt finale, data,
  autore, licenza del progetto, trasformazioni e SHA-256; non lasciare asset
  consumati dal progetto nella sola cartella di output del generatore.
- [x] Preferire ImageGen anche per futuri nuovi asset raster quando è adatto al
  risultato; continuare a usare primitive Godot o sorgenti native per UI,
  geometrie deterministiche e grafica vettoriale già appartenente a un sistema.
- [x] Verifica prima/dopo su Windows e Pixel 9 a luminosità diverse, regressione
  performance/import/export e conferma che lo sfondo non suggerisca collisioni
  o zone percorribili diverse dal playfield B18Q. Confronto prima/dopo Windows,
  regressione, import/export e runtime Pixel 9 20:9 sono verdi; il controllo
  percettivo finale a luminosità fisica controllata è stato completato il
  25 agosto 2026 dopo la chiusura di B18Q e B18R.

Dettagli ed evidenze: [`b18s-verification.md`](./b18s-verification.md).

#### B18T — Carosello selezione personaggi

Stato: `COMPLETATO`; implementazione, smoke dedicato, regressione `40/40`,
project smoke, Windows, APK statico, percorso runtime Pixel 9 20:9, tap manuale
sulle anteprime e confronto percettivo fisico chiusi. Il raffinamento di
gerarchia approvato è tracciato separatamente in B18W.

- [x] Sostituire la griglia/elenco di profili del selettore con un carosello
  ciclico di otto `FriendDefinition`: il profilo corrente è centrale e mostra
  ritratto, nome, passiva e abilità; i due profili adiacenti restano visibili
  come mini-card scure complete, senza tagli, testi illeggibili o hit target
  sovrapposti.
- [x] Consentire il cambio profilo con frecce/tasti, D-pad o stick/controller,
  click sulle anteprime e swipe orizzontale touch. Tutti i percorsi aggiornano
  lo stesso indice e focus; un drag non deve attivare accidentalmente conferma
  o Back.
- [x] Conservare un'azione di conferma separata, sempre nella safe area e con
  target minimo `44×44` unità logiche: solo la sua attivazione avvia la run.
  `ui_cancel`/Back torna alla welcome e nessuna navigazione del carosello fa
  avanzare clock, spawn, input di gameplay, seed o stato runtime fuori da
  `RunController.BOOT`.
- [x] Usare transizioni brevi e rispettose di pausa/focus, senza creare nodi o
  tween residui; il carosello deve ricostruirsi correttamente dopo “Cambia
  personaggio” da pausa, vittoria o sconfitta.
- [x] Aggiungere smoke deterministico per wrap-around, tutte le otto schede,
  equivalenza input, swipe contro tap, conferma e ritorno alla welcome; coprire
  16:9, 20:9 e 4:3 con assert di safe area, profilo centrale e assenza di
  sovrapposizione dei controlli.
- [x] Eseguire regressione completa, project smoke, export Windows/Android e
  percorso runtime Pixel 9: cold launch → welcome → carosello → conferma → run,
  Back dal carosello e ritorno al carosello da pausa.
- [x] Tap manuale sulle anteprime e confronto percettivo fisico sul Pixel 9
  chiusi il 25 agosto 2026; gli screenshot 20:9 e i percorsi touch/D-pad ADB
  erano già verdi.
  La regressione fisica da evento emulato verifica Magno → Bea con D-pad e Bea
  → Zat con un solo tap, senza doppio avanzamento.

Dettagli ed evidenze: [`b18t-verification.md`](./b18t-verification.md).

#### B18W — Raffinamento della selezione personaggi

Stato: `COMPLETATO`; la revisione corrente sostituisce il kit con due card
laterali. Smoke e regressioni pertinenti sono verdi; APK finale e confronto
percettivo fisico sul nuovo layout sono accettati il 26 agosto 2026.

- [x] Spostare `← Indietro` in alto a sinistra, con stile e icona chiaramente
  diversi dalle frecce di navigazione del carosello; rimuovere il grande
  pulsante `INDIETRO` inferiore. Back/`ui_cancel` conserva il ritorno alla
  welcome e non può confermare o riavviare una run.
- [x] Dare al profilo selezionato priorità visiva: card e sprite centrali
  leggermente più grandi, anteprime laterali più discrete e frecce integrate ai
  lati del carosello. Ridurre il testo istruttivo sotto `Scegli il personaggio`
  al minimo necessario, senza sostituire i percorsi accessibili da mouse,
  tastiera, controller, click o swipe.
- [x] Mantenere sotto il carosello il nome, più evidente del ruolo, e una breve
  descrizione di ruolo. Mostrare **PASSIVA** e **ABILITÀ** in due card laterali
  separate, ciascuna con icona centrata a sinistra e label, nome completo e
  descrizione a destra: i nomi assurdi approvati, incluso `Reggeton time!`,
  sono enfatizzati e non abbreviati.
- [x] Lasciare in basso un solo CTA dominante, in arancione caldo della welcome:
  `Gioca con <Nome>` con maiuscola naturale, ad esempio `Gioca con Magno`.
  Ciano resta riservato a selezione, focus e bordi; il CTA conserva target
  minimo `44×44` unità logiche e resta l'unica azione che avvia la run.
- [x] Verificare la gerarchia `← Indietro → Scegli il personaggio → carosello
  → nome/ruolo → pannello abilità → Gioca con <Nome>` a 16:9, 20:9 e 4:3, con
  assert di safe area, assenza di sovrapposizioni e card centrale predominante.
  Aggiungere smoke per focus, Back, frecce, swipe contro tap, CTA e aggiornamento
  atomico di nome, ruolo, passiva, abilità e icona per tutti gli otto profili.
- [x] Chiudere con regressione, project smoke, export Windows/Android e verifica
  percettiva Windows/Pixel 9: la selezione deve comunicare prima personaggio e
  abilità, non apparire come un pannello di configurazione, e conservare BOOT,
  multitouch e lifecycle.

  Regressione, project smoke, export e percorso ADB sono verdi; la valutazione
  manuale fisica è stata completata il 25 agosto 2026. Il CTA usa una placca
  ImageGen senza testo larga al massimo il `55%` del pannello e conserva almeno
  `30` unità logiche dalla cornice inferiore; `Gioca con <Nome>` resta testo
  dinamico nativo. Il pass aggiuntivo pixel-fantasy rimuove il sottotitolo,
  squadra card e pannello, rende complete le anteprime, sostituisce i cerchi
  cyan con frecce metalliche/oro, aggiunge `KIT DI <NOME>` e tratta passiva e
  attiva con icone e titoli dorati equivalenti. Tutti gli otto profili usano una
  passiva raster dedicata, elaborata dai master RGBA con la stessa pipeline di
  Magno e tracciata nel manifest delle passive. Nome e ruolo sono ora un unico
  blocco con distanza `6–12` unità; il kit è largo `380` unità e il CTA segue il
  ruolo entro `34`, eliminando il vuoto verticale centrale.

Dettagli ed evidenze: [`b18w-verification.md`](./b18w-verification.md).

#### B18U — Sprite del cast coerenti

Stato: `COMPLETATO`; implementazione, regressione aggiornata `40/40`, project
smoke, Windows, APK statico, dipendenza funzionale B18T/B18W, controllo
percettivo fisico del cast in movimento e ad alta densità sul Pixel 9 a 20:9 e
confronto finale 16:9/4:3 chiusi.

- [x] Sostituire gli sprite Player provvisori degli otto `FriendDefinition` con
  asset raster originali coerenti con la sezione [Direzione visuale del cast](./characters.md#direzione-visuale-del-cast): Magno tellurico con richiami bovini, Bea pattinatrice, Zat infermiera elettrica, Alea ballerina, Aleo muratore, Lollo cosplayer retrofuturista, Migi con scudo a guscio e Marghe ballerina reggaeton con clone d'ombra.
- [x] Rappresentare esclusivamente archetipi fittizi: nessuno sprite deve
  riprodurre persone reali, loghi o marchi. Il simbolo medico generico a cuore
  di Zat resta consentito; silhouette, palette e posa devono essere leggibili
  alle dimensioni runtime e distinguibili da nemici, pickup, telegraph e VFX.
- [x] Conservare per ogni profilo idle e movimento previsti da B18C, compreso
  facing orizzontale e ultima direzione vettoriale; hitbox, origine, velocità,
  collisioni, passive, `AbilityDefinition` e timing gameplay restano invariati.
- [x] Usare ImageGen per i nuovi raster quando adatto e registrare per ciascun
  asset prompt, generatore, data, trasformazioni, licenza di progetto e
  SHA-256 nel manifest; import, sprite sheet, downscale e margini devono essere
  deterministici e non introdurre texture runtime non tracciate.
- [x] Aggiungere smoke che esercita gli otto profili, idle/movimento,
  sostituzione dopo il carosello, restart e cambio personaggio senza riferimenti
  o frame residui; verificare che la geometria di collisione sia identica alla
  baseline B18C.
- [x] Eseguire regressione completa, project smoke, export Windows/Android e
  controllo percettivo Windows/Pixel 9 su 16:9, 20:9 e 4:3: il cast deve essere
  leggibile in movimento, durante abilità e ad alta densità senza degradare
  performance o multitouch.

  La parte automatica, il runtime Windows, il packaging Android statico e il
  percorso reale welcome → carosello → run sul Pixel 9 sono verdi; l'APK
  contiene soltanto `arm64-v8a` e non include le sorgenti HD. Il confronto
  percettivo del cast durante movimento, abilità e alta densità, distinto dalla
  verifica frontend B18T, è stato completato il 25 agosto 2026.

Le strisce runtime `96×32`, le sorgenti trasparenti `1536×1024` conservate in
`assets/art/characters/players/hd/`, i prompt, le correzioni rispetto alla
welcome B18O, le trasformazioni e gli hash sono registrati nel
[manifest B18U](../assets/art/characters/players/ASSET-MANIFEST.md).

Dettagli ed evidenze: [`b18u-verification.md`](./b18u-verification.md).

#### B18V — Hardening Windows/Android e performance

Stato: `COMPLETATO`; il freeze funzionale e visivo B18C–B18U/B18W e i relativi
gate fisici preesistenti sono chiusi. Il contratto B18V è implementato e la parte
automatica è verde. Il 25 agosto 2026 il proprietario ha accettato come conclusa
la milestone: emulatore API 31/API 36 e soak Pixel 9 non registrati restano
distinti dalle evidenze effettivamente raccolte e non vengono dichiarati eseguiti.

- [x] Eseguire regressione completa, project smoke ed export puliti da ambiente
  documentato; cercare nei log `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` e
  `CONTRACT_FAIL` senza affidarsi al solo exit code. Focused smoke B18V, 43 smoke
  di regressione, project smoke, export Windows, runtime Windows e ispezione APK
  sono verdi; dettagli in [`b18v-verification.md`](./b18v-verification.md).
- [x] Chiudere la matrice Windows, Android 12/API 31 e Android 16/API 36 con
  16:9, 18:9, 20:9, cutout e 4:3, inclusi welcome, selezione, pausa, controlli
  scalati, lifecycle, abilità, Boss, vittoria, sconfitta e cambio personaggio.
- [x] Profilare densità massima, CPU/GPU, memoria, audio e VFX sulla
  presentazione congelata; completare soak termico Android da 20 minuti e almeno
  cinque restart/cambi profilo senza crescita o stato residuo.
- [x] Definire e applicare soltanto budget presentazionali configurabili quando
  necessario: profili fissi 60 FPS, stress 150/200/200 e coda FIFO dei feedback
  transitori (300 Windows, 150 mobile); gameplay, timing autorevoli e contenuti
  approvati non cambiano durante l'hardening senza una nuova decisione registrata.
- [x] Registrare evidenze fisiche distinte dai controlli APK statici; la chiusura
  B18V rimuove il blocco tecnico di B20, mentre l'ordine di prodotto lo
  posticipa ulteriormente dopo B22 e B23.

Gate comuni del ciclo:

- smoke dedicati per direzione/animazione, Bea, Zat, Alea, rank, Grigliata
  estiva, pulsante abilità, joystick dinamico, flusso welcome/pausa, carosello,
  sprite del cast, scale touch, playfield riservato, timing visivi e sfondo;
- nessun `SCRIPT ERROR` o `FATAL EXCEPTION`, anche con exit code `0`;
- verifica Windows e Android, distinguendo sempre export statico da runtime;
- su Android reale, movimento col joystick con un dito e attivazione
  dell'abilità con il secondo;
- pausa, ripresa esplicita, focus, Home/lock, Back e restart per ogni effetto
  temporizzato o inseguitore;
- verifica 16:9, 20:9 e 4:3 per UI, posizioni, direzioni, aree e flash.

### Espansioni B22–B33

B22 e B23 restano nella sequenza già pianificata; B24–B33 aggiungono un pass ulteriore di gameplay, UI, asset e audio. Le nuove funzionalità riaprono soltanto i gate pertinenti, inclusi Android fisico, performance e verifica percettiva. I blocchi già marcati `COMPLETATO` rimangono storici e non vengono riscritti: B24–B33 sono backlog nuovi e incrementali.

#### B22 — Boss piccione speciale e varianti Evil

Stato: `COMPLETATO`; B20 non è più una dipendenza.

- [x] Rendere il piccione speciale B18H il `BossDefinition` baseline della
  release confezionata in B20. A ogni soglia Boss, risolvere dal seed una scelta
  unica e riproducibile: probabilità configurabile `evil_boss_chance`, default `25%`,
  di sostituirlo con uno degli otto `Evil <Nome>` casuali.
- [x] Per B22 l'Evil riusa sprite, hitbox, salute, ricompensa e due pattern del
  piccione Boss; applicare soltanto una palette viola scura con accenti magenta
  ad alto contrasto. Nessuna abilità, passiva, citazione personale o audio del
  profilo viene attribuita all'Evil finché non esiste una slice dedicata.
- [x] Mantenere il limite di un solo Boss richiesto/attivo e i contratti di
  `BOSS_INTRO`, pausa, level-up, vittoria, sconfitta, restart e cambio profilo.
  UI, telegraph e palette devono distinguere Boss, piccioni base e Player anche
  con flash ridotti e densità elevata.
- [x] Aggiungere smoke per probabilità `0/1`, scelta seed-riproducibile,
  copertura degli otto Evil, fallback al piccione speciale, una sola ricompensa
  e due run senza residui; poi regressione, export Windows/Android e verifica
  percettiva/touch su Pixel 9.

Dettagli ed evidenze: [`b22-verification.md`](./b22-verification.md).

#### B23 — Modalità Difesa Grigliata

Stato: `PRONTO`; B22 è chiuso e i prerequisiti della modalità sono disponibili.

- [ ] Introdurre `GameModeDefinition` con **Sopravvivenza** come default e
  **Difesa Grigliata** come seconda scelta in `BOOT`, integrata alla conferma
  del profilo: la navigazione della modalità non avvia clock, spawn o input di
  gameplay e Back conserva il flusso welcome → selezione → run.
- [ ] In Difesa Grigliata, creare nel centro del playfield autorevole una
  griglia con carne e `HealthComponent` proprio. La sua salute è configurabile,
  appare nel HUD fuori dal playfield e non può sovrapporsi a Player, Boss UI,
  controlli touch, telegraph o overlay.
- [ ] Estendere il targeting nemico in modo dati: i nemici possono scegliere e
  colpire l'obiettivo, mentre il Player continua a poterli attirare/uccidere.
  La run termina in `DEFEAT` se Player o griglia arrivano a zero; per la prima
  versione Boss a `04:00`, vittoria e progressione restano quelli di
  Sopravvivenza, senza riparazioni implicite dell'obiettivo.
- [ ] Isolare per modalità seed, obiettivo, HUD, target, spawn e cleanup;
  pausa, focus, Home/lock, cambio personaggio, terminali e restart non possono
  lasciare nodi, danni, aggro o vita dell'obiettivo nella run successiva.
- [ ] Aggiungere smoke per entrambe le modalità, morte Player/obiettivo,
  selezione target, Boss, pause e due restart; eseguire regressione completa,
  export Windows/Android e prova Pixel 9 con joystick tenuto e abilità attivata
  dal secondo dito durante la difesa.

#### B24 — Scala visiva del Player

Stato: `COMPLETATO`.

- [x] Aumentare la dimensione visuale degli otto Player in gameplay partendo da un
  moltiplicatore configurabile; baseline candidata `1,25×`, ancora da congelare
  con confronto percettivo Windows/Pixel 9.
- [x] Non modificare hitbox, velocità, collisioni, raggi, origine dei proiettili o
  coordinate gameplay: la modifica è esclusivamente presentazionale.
- [x] Verificare leggibilità e assenza di clipping a 16:9, 20:9 e 4:3, durante
  orde dense, Boss, VFX e vicinanza ai bordi del playfield.

Implementazione del 26 agosto 2026: `Player.visual_scale_multiplier` è un export
configurabile limitato a `1,00–2,00×`; il valore candidato `1,25×` moltiplica la
sola scala base `1,65` di `CharacterSprite`, per una resa effettiva `2,0625`.
`CharacterBody2D`, collision shape (`raggio 24`), `WeaponController`, clamp arena,
statistiche e coordinate restano invariati. Lo squash di danno continua a
comporsi sopra la scala visuale senza propagarsi alla fisica.

Lo smoke `B24_PLAYER_VISUAL_SCALE_SMOKE_OK` copre gli otto profili, configurazione
`1,20/1,25/1,30×`, feedback danno, hitbox/origine di fuoco e vicinanza ai quattro
bordi su 16:9, 18:9, 20:9 e 4:3. Focused, regressione integrale `44/44`, export e
runtime Windows, build Gradle e APK statico ARM64 sono verdi. Restano aperti il
confronto percettivo umano su Windows e il percorso fisico Pixel 9 con orde
dense, Boss e VFX; `adb` non rilevava dispositivi il 26 agosto 2026. Evidenza in
[`b24-verification.md`](./b24-verification.md).

#### B25 — Rimuovere la vita circolare sopra il Player

Stato: `IN VERIFICA`.

- [x] Rimuovere la barra/indicatore circolare della vita ancorato sopra o attorno
  al Player: è ridondante rispetto alla barra `HP` globale B18Q.
- [x] Conservare feedback di danno, invulnerabilità, hit flash e lampeggio
  ritmico del solo sprite per tutta la finestra di invulnerabilità; nessun
  evento di salute dipende dall'indicatore rimosso.
- [ ] Verificare percettivamente che la vita resti immediatamente leggibile sulla
  barra superiore durante Boss, level-up, pausa e densità elevate.

Implementazione del 27 agosto 2026: `Player` non disegna più l'arco salute
locale e non conserva proprietà di presentazione residue per quell'indicatore.
`HealthComponent` continua a emettere i segnali atomici verso `GameHud`, la cui
barra `HP` B18Q resta l'unica fonte primaria della vita Player. Restano aperti i
controlli percettivi Windows/Pixel 9 in combattimento reale.

#### B26 — Potenziamento danno dedicato

Stato: `IN VERIFICA`.

- [x] Aggiungere `Forchettone da Braciere`, carta dedicata `×1,15` al danno base.
- [x] Rendere ripetibili le quattro carte statistiche normali e rimuovere le tre
  Resource fallback duplicate; rank e modificatori si azzerano a restart/cambio personaggio.
- [x] La carta entra nella pesca ordinaria senza duplicati e modifica soltanto il danno.
- [x] Smoke su stacking, selezione oltre il rank nominale, `Gossip`, `Birra`, Boss e reset.

#### B27 — Sostituzione icone dei potenziamenti

Stato: `IN VERIFICA`.

- [x] Usare i dieci master definitivi in `assets/art/icons/upgrades/hd/`.
- [x] Derivare PNG runtime `128×128` con pipeline deterministica, trasparenza e margini coerenti.
- [x] Sostituire ogni riferimento alle icone SVG upgrade con i derivati PNG, senza mutare gli ID effetto.
- [x] Conservare i master fuori da import/export e registrare mapping e hash nel manifest.
- [x] Smoke a `16:9`, `20:9` e `4:3`; resta il gate percettivo umano.


#### B28 — Densità orde e TTK più bullet-hell

Stato: `IN VERIFICA`.

- [x] Ribilanciare `SpawnProfile` per mostrare molte più unità contemporanee e
  ridurre la vita media dei nemici base: il combattimento deve privilegiare orde
  numerose, kill frequenti e pressione spaziale rispetto a pochi bersagli spugnosi.
- [x] Conservare i Boss come bersagli più resistenti e leggibili; il tuning dei
  nemici base non deve banalizzare pattern, telegraph o identità dei Boss.
- [ ] Ripetere profiling 60 FPS su Windows e Pixel 9 con densità reale della nuova
  baseline; introdurre pooling/ottimizzazioni soltanto se il profiler lo richiede.
- [x] L'aumento delle kill non deve
  accelerare accidentalmente la progressione oltre il ritmo desiderato.

Implementazione iniziale del 26 agosto 2026, ricalibrata il 27 agosto: il profilo ordinario passa da cap `80` a
`140`, intervallo `1,00 → 0,25 s` a `0,60 → 0,12 s` (accelerazione `0,003`) e
delay iniziale `0,50 s`; la vita `BaseEnemy` passa da `40` a `24`. Il profilo
conserva la curva di spawn pre-B28 come riferimento e assegna a ogni nemico
ordinario un credito XP frazionario `1,50 × intervallo_corrente / intervallo_riferimento`.
`ExperienceDropper` somma il credito e genera pickup soltanto per le unità intere:
il budget XP al secondo è il `150%` della baseline, senza tornare a un XP intero
per kill; Boss e la loro ricompensa dichiarata restano a scala `1,0`. Non è stato introdotto pooling:
lo stress B18V a `150` nemici, `200` proiettili e `200` pickup resta sopra il
nuovo cap reale di `140`.

`B28_HORDE_DENSITY_SMOKE_OK` verifica valori, TTK, protezione Boss/telegraph,
nuovo budget XP e credito reale su cinque kill. Sono verdi anche le
regressioni isolate di spawn, combattimento, piccioni, XP, abilità, HUD arena,
roster, pausa/cambio, Boss e hardening performance. Il runner `Relevant` completo
resta bloccato da `_ability_selection_icon_scale_smoke.gd`, che non trova le
icone abilità/passiva già mancanti nel worktree e non è causato da B28.
L'export Windows è verde; il profiling runtime non è chiuso perché il wrapper
console dell'export termina con `CreateProcess error 193`. Sul Pixel 9 il
pacchetto APK presente è installabile e il percorso welcome → selezione → run è
stato esercitato, senza errori fatali nei log; il profiling frame-time a 60 FPS
con baseline B28 resta aperto, come anche la conferma di freschezza dell'APK
dopo un export Android che ha riportato la scomparsa del daemon Gradle. Evidenza:
[`b28-verification.md`](./b28-verification.md).

#### B29 — Musica di sottofondo

Stato: `IN VERIFICA`.

- [x] Integrare una musica loop per la run, coerente con il tono pixel-art arcade
  e sufficientemente ritmica da sostenere orde più dense senza coprire SFX e cue.
- [x] Integrare il brano selezionato: **Super Wreck Roadway (loop)** di
  **Umplix**, pubblicato su OpenGameArt con licenza **CC0**; la fonte pubblica
  elenca il loop WAV, mentre l'OGG runtime è stato fornito dal proprietario:
  <https://opengameart.org/content/super-wreck-roadway>.
- [x] Scaricare solo dalla fonte ufficiale e registrare autore, URL, licenza,
  data di acquisizione, file originale e SHA-256 nel manifest audio. Anche se
  CC0 non richiede attribuzione, mantenere il credito nel file crediti del progetto.
- [x] Lo smoke `B29_BACKGROUND_MUSIC_SMOKE_OK` verifica loop configurato, mixer
  separato con musica sotto gli SFX, mute, pausa/resume, modal e cleanup su due
  run consecutive.
- [ ] Completare l'ascolto percettivo del loop senza click/stacchi e del mix a
  densità B28 su Windows e Pixel 9; installare e provare l'APK corrente prima di
  chiudere il gate Android fisico. Evidenza: [`b29-verification.md`](./b29-verification.md).

#### B30 — Boss senza aura circolare viola

Stato: `PRONTO`.

- [ ] Rimuovere il cerchio/aura viola che avvolge visivamente i Boss.
- [ ] Per gli `Evil <Nome>` conservare la palette/sfumatura viola scura e magenta
  dello sprite approvata in B22 come identificatore principale.
- [ ] Non rimuovere telegraph, hit flash, segnali di attacco o altri feedback che
  comunicano meccaniche; la modifica riguarda soltanto l'aura decorativa costante.
- [ ] Confronto percettivo con piccioni base, Player e VFX ad alta densità.

#### B31 — Padding esterno pausa e abilità

Stato: `PRONTO`.

- [ ] Aumentare il margine visivo del pulsante pausa e del pulsante abilità dai
  bordi esterni della safe area; evitare elementi che sembrano appoggiati alla cornice.
- [ ] Usare inset configurabili e coerenti tra 16:9, 18:9, 20:9, cutout e 4:3,
  senza coordinate schermo fisse.
- [ ] Conservare dimensione/scala configurabile, target touch e multitouch B18P;
  joystick e gesture edge non devono sovrapporsi ai nuovi margini.

#### B32 — Welcome CTA coerente e impostazioni a ingranaggio

Stato: `IN VERIFICA`.

- [x] Sostituire la grafica sottostante al CTA arancione `GIOCA` della welcome con
  la stessa famiglia/placca pixel-fantasy usata da `Gioca con <Nome>` in B18W;
  il testo resta nativo e specifico della welcome.
- [x] Rimuovere il grande pulsante `IMPOSTAZIONI` dal blocco centrale e sostituirlo
  con un pulsante a **ingranaggio** in alto a destra, dentro safe area scostato dal bordo.
- [x] Conservare navigazione focus, tastiera/controller/touch e Back senza
  disegnare un riquadro focus; l'ingranaggio mantiene target touch minimo e
  stato pressed leggibile anche senza hover.
- [x] Verificare automaticamente che logo, cast, CTA e ingranaggio non si sovrappongano a 16:9,
  20:9 e 4:3 e che il flusso welcome → impostazioni → welcome resti in `BOOT`.

Evidenza: [`b32-verification.md`](./b32-verification.md). Restano distinti il
controllo percettivo/input Windows e il percorso touch reale su Android.

#### B33 — Run continua e Boss ricorrenti

Stato: `PRONTO`.

Questa slice è **incrementale** e non modifica retroattivamente i backlog B14–B16
né B22 già completati: ne estende il comportamento per la prima release.

- [ ] Il primo Boss resta eleggibile a `04:00`, ma la sua morte assegna ricompensa
  e ritorna a `RUNNING`: **non** genera più `VICTORY` e non termina la run.
- [ ] Ogni Boss successivo ha una finestra base di `240 s` di gameplay rispetto
  allo spawn del Boss precedente. Il clock si ferma negli stessi stati già
  previsti dal `RunController`.
- [ ] Se la finestra scade mentre il Boss corrente è vivo, impostare una sola
  richiesta `pending_boss`; non creare il nuovo Boss finché quello attivo non è morto.
- [ ] Alla morte del Boss attivo, se `pending_boss` è vero, generare subito il
  prossimo incontro e calcolare la finestra seguente da quel nuovo spawn. Non
  accumulare più Boss arretrati anche se il combattimento precedente è durato
  oltre più finestre da quattro minuti.
- [ ] In Sopravvivenza la run diventa continua fino a `DEFEAT` o uscita esplicita;
  `VICTORY` resta disponibile al framework per modalità/obiettivi futuri ma non
  viene emessa dalla semplice morte di un Boss.
- [ ] Difesa Grigliata eredita lo stesso scheduler ricorrente: Player o griglia a
  zero causano `DEFEAT`, mentre la morte di un Boss non chiude la modalità.
- [ ] Aggiungere test per morte Boss prima/dopo la soglia, Boss vivo oltre `08:00`,
  pausa/level-up durante la finestra, restart e seed; mai più di un Boss attivo.

## 7. Strategia di test

### Test unitari o di logica pura

- clamp della formula di spawn e comportamento ai limiti;
- selezione del bersaglio più vicino, inclusi bersagli morti nello stesso frame;
- curva XP, overflow e level-up multipli;
- tre carte con ID distinti, filtro dei rank massimi e fallback;
- composizione dei modificatori, stacking, cap e rimozione degli effetti temporanei;
- attivazione accettata/rifiutata, avanzamento del cooldown soltanto in `RUNNING` e segnale di prontezza emesso una sola volta;
- risoluzione di `AbilityDefinition`, parametri e tag; Cosplay Casuale non copia sé stessa né abilità incompatibili;
- risoluzione `FriendDefinition → passiva → AbilityDefinition`, selezione degli otto ID e seed deterministico per passive/copie casuali;
- valori e cap dei cinque rank per ciascuna abilità, eleggibilità senza duplicati e reset completo fra due run;
- Tuoni di Zat: finestra preavviso/impatto, selezione dei nemici validi e danno percentuale distinto per Boss;
- Grigliata estiva: aumento di `health_max`, cura esatta della differenza, stacking e cap;
- scheduler Boss con pausa, salti di soglia e restart;
- priorità delle sorgenti `InputRouter`, deadzone, normalizzazione, ownership del dito, aree touch escluse e reset completo del touch;
- calcolo di playfield/safe rect da viewport 16:9, 18:9, 20:9 e 4:3;
- transizioni Back, focus loss e resume senza avanzamento del clock;
- stesso seed → stessa sequenza di offerte e spawn configurati.
- B26: moltiplicatore danno, stacking, cap e reset del nuovo upgrade;
- B28: profilo densità/HP e cap configurabili senza valori hardcoded;
- B33: una sola richiesta Boss pending, nessun overlap e nuova finestra calcolata dallo spawn effettivo del Boss successivo.

### Test di integrazione

- `kill → drop → pickup → level-up → pausa → scelta → resume`;
- danno ripetuto, invulnerabilità, morte e restart;
- Onda d'Urto da tastiera, controller e touch: una sola attivazione per pressione, danno e knockback nel raggio, HUD sincronizzato;
- pausa, level-up, focus loss e restart durante cooldown o area persistente senza consumo di tempo, input bloccato o entità residue;
- per ciascuno degli otto profili: selezione, applicazione della passiva, attiva corretta, combinazione con almeno un upgrade e seconda run senza stato residuo;
- combinazioni fra catena Gossip, traiettoria oscillante e frequenza aumentata;
- slow periodico mentre entra o muore un nemico;
- Boss e nemici base presenti insieme;
- HUD B18Q minimo con barre XP/vita, pausa e solo cronometro sincronizzati durante resize, level-up, Boss intro, pausa e terminali;
- B18E: preavviso, flash a viewport intero, ingresso tardivo dei nemici, danno percentuale, pausa e cleanup su due run;
- B18G/B18J: offerta e applicazione dei rank, Grigliata estiva, cap, overflow di livello e seconda run pulita;
- B18I: drop XP da centro, lati, angoli e morti fuori arena a 16:9, 20:9 e 4:3;
- B18K: icona selezionata, riempimento circolare, secondi residui e transizione pronta/in cooldown senza cambiare il target touch;
- B18L: creazione al primo tocco valido, ownership, rilascio, esclusione HUD/overlay e abilità attivata con il secondo dito;
- hit flash, reazione, morte e abilità pronta non cambiano danno, collisioni, cooldown o cleanup della run;
- joystick touch più pausa, cambio dito e annullamento del touch senza direzioni bloccate;
- Home/blocco schermo durante combattimento e level-up, con ripresa solo su conferma;
- due run consecutive senza segnali doppi o riferimenti alla run precedente.
- B24/B25: Player più grande con hitbox invariata e assenza dell'indicatore vita circolare;
- B26/B27: carta danno e nuovo set icone leggibili, senza modificare la logica di pesca;
- B28: orde più dense con TTK inferiore, XP/level-up ancora nel ritmo approvato e 60 FPS target;
- B29: loop musicale, mixer, mute, pausa/resume e cleanup audio;
- B30/B31/B32: Boss senza aura decorativa, padding safe-area dei controlli e welcome coerente su input multipiattaforma;
- B33: primo Boss non termina la run, secondo Boss ritardato se il primo è vivo e spawn immediato alla sua morte senza sovrapposizione.

### Matrice manuale minima

| Area | Casi |
|---|---|
| Windows | Tastiera, controller, finestra, resize, fullscreen e perdita focus |
| Android device | Device fisico Android 12 vicino al minimo e device/emulatore Android 16; joystick dinamico, tap, drag, deadzone, ownership, multitouch reale, cambio dito e pulsante abilità mentre il joystick è attivo |
| Android lifecycle | Back, Home, lock/unlock, chiamata/interruzione, background/resume e input azzerato |
| Layout | 16:9, 18:9, 20:9, cutout/notch e tablet/emulatore 4:3; HUD B18Q con barre XP/vita, pausa e cronometro flottanti, flash B18E a viewport intero, controlli B18K/B18L nella safe area e nessuna sovrapposizione con Boss UI/overlay |
| Stabilità | 5 restart rapidi; soak termico 20 minuti su Android; ondate al cap entità |
| Gameplay | selezione di tutti gli otto personaggi, vittoria, sconfitta, level-up multiplo, rank abilità, Grigliata estiva, abilità pronta/in cooldown e Boss durante elevata densità |
| Polish B24–B32 | scala Player, HUD senza vita circolare, icone upgrade, musica, Boss senza aura, padding controlli e welcome CTA/ingranaggio a 16:9, 20:9 e 4:3 |
| Boss ricorrenti B33 | run oltre il primo Boss, finestra 240 s, Boss pending e nessuna sovrapposizione anche con combattimenti lunghi |

## 8. Definition of Done

Un'attività è finita solo quando:

- soddisfa i criteri di accettazione e i test pertinenti sono verdi;
- non introduce errori runtime, segnali duplicati o warning nuovi non motivati;
- i parametri di bilanciamento sono dati configurabili, non costanti disperse negli script;
- il Player legge soltanto `InputRouter`; InputMap e touch producono lo stesso contratto di movimento;
- l'abilità attiva riceve soltanto l'intenzione di `InputRouter`, usa parametri da `AbilityDefinition` e non avanza fuori da `RUNNING`;
- ogni feature P0 o P1 destinata alla release è verificata sia con tastiera/controller su Windows sia con touch su Android;
- UI, HUD e controlli non usano coordinate schermo fisse e rispettano la safe area;
- la scena può essere riavviata senza conservare nodi, timer o stato della run precedente;
- una build Windows e un APK vengono verificati al termine di ogni milestone;
- documentazione e decision log vengono aggiornati se cambia un contratto di gameplay.

## 9. Rischi e mitigazioni

| Rischio | Prob. | Impatto | Mitigazione |
|---|---:|---:|---|
| Orde/VFX saturano CPU, GPU o termiche Android | Alta | Alta | Profiling su device da M1, Compatibility, overdraw ridotto e pooling mirato |
| Aspect ratio, DPI e cutout rompono UI o arena | Media | Alta | `ArenaLayout`, safe area, Container/anchor e matrice 16:9–20:9/4:3 |
| Lifecycle Android lascia clock/input in stato errato | Media | Alta | `PlatformLifecycle`, reset touch e test Back/Home/lock a ogni milestone |
| Toolchain Godot/Gradle non compila subito con API 36 | Media | Alta | Spike in M0, Platform/Build Tools 36.x e aggiornamento dei template senza abbassare il target |
| Firma o futuri requisiti Play cambiano | Media | Alta | Package ID stabile, keystore fuori repo con backup, AAB smoke e verifica store prima della futura pubblicazione |
| Upgrade combinati creano comportamenti emergenti errati | Alta | Alta | Modificatori identificati, componenti isolati, test a coppie e seed riproducibile |
| Abilità attive lasciano aree, cloni o cooldown fra pausa e restart | Media | Alta | `AbilityController` scene-local, cleanup esplicito, clock della run e smoke test di due run consecutive |
| Pausa globale blocca anche l'overlay | Media | Alta | `UpgradeOverlay` processato durante la pausa e test integrato già in M3 |
| Boss e contenuti arrivano troppo tardi | Media | Alta | Boss framework in P0; placeholder e pattern grezzi prima degli asset finali |
| Art/audio allargano lo scope | Alta | Media | Budget contenuti esplicito e feature freeze dopo M4 |
| HUD compatto riduce usabilità touch | Media | Alta | B18P ingrandisce il default e rende configurabili icona abilità e joystick senza restringere acquisizione o multitouch; gate fisico prima di B18V |
| HUD e linea XP coprono l'arena attiva | Media | Alta | B18Q sottrae la fascia superiore dal rect autorevole di `ArenaLayout` e verifica tutti i consumatori a 16:9–20:9/4:3 |
| Animazioni troppo brevi non comunicano l'azione | Media | Media | B18R centralizza e allunga i timing presentazionali, con confronto percettivo Windows/Pixel 9 senza alterare il gameplay |
| Sfondo generato riduce leggibilità o suggerisce ostacoli falsi | Media | Alta | B18S impone texture a basso contrasto, assenza di elementi semantici, manifest completo e confronto prima/dopo sul campo reale |
| Flash di Zat è fastidioso o poco accessibile | Media | Alta | Intensità mobile e modalità ridotta definite prima di B18E; verifica su device fisico e flash limitato nel tempo |
| Sprite piccione o VFX originali non risultano leggibili sul campo | Media | Media | Silhouette e palette congelate, fixture base/speciale, priorità dei layer e confronto Windows/Android prima del freeze; asset esterni non necessari |
| Citazioni o immagini non approvate | Bassa | Alta | Registro B17 obbligatorio, getter con fallback e citazioni/audio personali assenti finché non vengono forniti |
| Targeting lineare degrada con molte entità | Media | Media | Cap e profiler; target cache, poi partizionamento soltanto su evidenza |
| Il PRD resta ambiguo durante il coding | Alta | Media | Decision log breve, contratti sopra e aggiornamento della specifica prima di M1 |
| Aumento densità B28 satura CPU/GPU o rende il campo illeggibile | Alta | Alta | Tuning dati graduale, profiler Windows/Pixel 9, pooling solo su evidenza e priorità visiva a Player/telegraph |
| Musica esterna viene importata senza tracciamento licenza | Bassa | Alta | Preferenza CC0, download dalla fonte ufficiale, manifest audio con URL/licenza/hash e copia del testo licenza quando applicabile |
| Scheduler B33 accumula Boss arretrati o crea overlap | Media | Alta | Una sola flag pending, finestra successiva dallo spawn effettivo, smoke su combattimenti oltre più soglie |

## 10. Prossima iterazione

Ordine operativo immediato:

1. chiudere il confronto percettivo B24 su Windows e Pixel 9, congelando o correggendo il candidato `1,25×`;
2. procedere a B23, completando implementazione e gate della modalità Difesa Grigliata;
3. proseguire con B25–B33 mantenendo ogni slice separata dai backlog già completati: B25 (HUD Player), B26–B27 (upgrade e icone), B28 (densità/TTK), B29–B32 (audio e polish UI/Boss/welcome), B33 (run continua e scheduler Boss).

I gate manuali e percettivi precedentemente elencati per B18B, B18E, B18G,
B18J, B18M, B18Q, B18S, B18T, B18U e B18W sono chiusi dal 25 agosto 2026 e
non fanno più parte della prossima iterazione.

Il setup host e gli artefatti generati il 12 agosto 2026 sono registrati in
[`m0-verification.md`](./m0-verification.md).
Il vertical slice di movimento e il gate sul Pixel 9 sono registrati in
[`b03-verification.md`](./b03-verification.md).
Il nemico base, lo spawner dinamico e il gate B04 su Windows e Pixel 9 sono
registrati in [`b04-verification.md`](./b04-verification.md).
Targeting, arma, proiettile, danno e lo stato del gate B05 sono registrati in
[`b05-verification.md`](./b05-verification.md).
Salute Player, contatto, Game Over, restart e lo stato del gate B06 sono
registrati in [`b06-verification.md`](./b06-verification.md).
Back, pausa manuale, focus, lifecycle e lo stato del gate B06A sono registrati
in [`b06a-verification.md`](./b06a-verification.md).
Drop, magnete, accredito XP singolo e lo stato del gate B07 sono registrati in
[`b07-verification.md`](./b07-verification.md).
Livelli, soglie, overflow, coda delle scelte e lo stato del gate B08 sono
registrati in [`b08-verification.md`](./b08-verification.md).
HUD responsive, safe area, vita, XP, timer e lo stato del gate B09 sono
registrati in [`b09-verification.md`](./b09-verification.md).
Framework abilità attive, Onda d'Urto Tellurica e lo stato del gate B09A sono
registrati in [`b09a-verification.md`](./b09a-verification.md).
Resource upgrade, registry, rank, pesca deterministica e lo stato del gate B10
sono registrati in [`b10-verification.md`](./b10-verification.md).
Overlay safe-area, navigazione multipiattaforma e stato del gate B11 sono
registrati in [`b11-verification.md`](./b11-verification.md).
Stacking, cap e applicazione runtime degli upgrade statistici B12 sono
registrati in [`b12-verification.md`](./b12-verification.md).
Catena Gossip, slow periodico, oscillazione Birra, shockwave reattiva, vignetta
e lo stato del gate B13 sono registrati in
[`b13-verification.md`](./b13-verification.md).
Game Director, profilo di spawn, scheduler a soglia singola e stato del gate B14
sono registrati in [`b14-verification.md`](./b14-verification.md).
Primo Boss, intro sicura, due pattern, HP, morte e ricompensa sono registrati in
[`b15-verification.md`](./b15-verification.md).
Vittoria, bilanciamento iniziale, cinque run consecutive e stato del gate B16
sono registrati in [`b16-verification.md`](./b16-verification.md).
Catalogo degli otto amici, controparti Evil, approvazioni e sprite CC0
sostituibili sono registrati in [`b17-verification.md`](./b17-verification.md) e
[`content-approvals.md`](./content-approvals.md).
Roster selezionabile, passive runtime, otto abilità attive e stato del gate
fisico B17A sono registrati in [`b17a-verification.md`](./b17a-verification.md).
Icone dedicate, gerarchia VFX, cue CC0, mixer persistente e stato del gate B18
sono registrati in [`b18-verification.md`](./b18-verification.md).
HUD compatto, arena procedurale, feedback di combattimento e gate residui B18B
sono registrati in [`b18b-verification.md`](./b18b-verification.md).
Animazione laterale del Player, ultima direzione valida e gate B18C sono
registrati in [`b18c-verification.md`](./b18c-verification.md).
Powerslide direzionale di Bea, asset CC0 e gate B18D sono registrati in
[`b18d-verification.md`](./b18d-verification.md).
Gran Piroetta inseguitrice di Alea e gate residuo Android sono registrati in
[`b18f-verification.md`](./b18f-verification.md).
Rank dichiarativi delle otto abilità, integrazione level-up e gate residuo
Android sono registrati in [`b18g-verification.md`](./b18g-verification.md).
Piccioni base/speciale, animazione presentazionale e gate Windows/Pixel 9 sono
registrati in [`b18h-verification.md`](./b18h-verification.md).
Confinamento dei drop XP nel playfield e gate residuo Android sono registrati
in [`b18i-verification.md`](./b18i-verification.md).
Grigliata estiva, cura del delta e gate residuo Android sono registrati in
[`b18j-verification.md`](./b18j-verification.md).
Pulsante-icona, cooldown radiale, timer centrale e gate residuo Android B18K
sono registrati in [`b18k-verification.md`](./b18k-verification.md).
Joystick dinamico, ownership del primo dito e gate fisico condiviso B18K/B18L
sono registrati in [`b18l-verification.md`](./b18l-verification.md).
Cambio personaggio dalla pausa, conferma modale e cleanup atomico B18N sono
registrati in [`b18n-verification.md`](./b18n-verification.md).
Welcome, impostazioni iniziali, ritorno dal selettore e cold launch B18O sono
registrati in [`b18o-verification.md`](./b18o-verification.md).
Timing centralizzati, code visive non interattive e gate percettivo B18R sono
registrati in [`b18r-verification.md`](./b18r-verification.md).
Sfondo arena ImageGen, crop responsive, manifest e gate residui B18S sono
registrati in [`b18s-verification.md`](./b18s-verification.md).
Scala visuale B24, invarianti gameplay, matrice responsive ed esito dei gate
automatici/piattaforma sono registrati in
[`b24-verification.md`](./b24-verification.md).
CTA welcome B32, ingranaggio safe-area e gate rimanenti sono registrati in
[`b32-verification.md`](./b32-verification.md).
