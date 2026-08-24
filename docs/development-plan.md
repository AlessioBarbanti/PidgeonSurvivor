# Piano di sviluppo — Friendship Survival: Arena Bullet Heaven

Fonte: [`prd.md`](./prd.md)  
Decisioni: [`decision-log.md`](./decision-log.md)  
Stato: il ciclo operativo corrente è B18C–B18M. B18C, B18D, B18F, B18I, B18K e B18L sono completati con tutti i gate automatici, Windows e Pixel 9 chiusi. B18E, B18G e B18J sono in verifica con implementazione, regressioni, Windows ed export Android statico chiusi, ma attendono il rispettivo gate Pixel 9. B18H e B18M hanno contratti sufficienti per iniziare. B19 resta bloccato fino al freeze dell'intero ciclo e alla chiusura dei gate Windows/Android pertinenti
Obiettivo: trasformare il concept in un MVP completo, verificabile su Windows e Android; Web resta un target secondario

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
| Renderer | Compatibility | È adatto a un gioco 2D e copre una gamma ampia di GPU desktop e mobile; conserva anche l'opzione Web |
| Target obbligatori | Windows x64 e Android | Entrambi fanno parte della Definition of Done di ogni milestone |
| Target secondario | Web/itch.io | È una milestone opzionale dopo l'MVP e non blocca Windows/Android |
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

La baseline condivisa usa Godot 4.7.1 Standard, GDScript e renderer Compatibility. Il preset Windows produce una build x64; il preset Android usa Gradle, package ID `com.ilgioco.friendshipsurvival`, `minSdk 31`, `targetSdk 36`, `compileSdk 36` e ABI release `arm64-v8a`. Produce APK di test/release e deve poter generare un AAB senza caricarlo su Google Play. JDK, Android SDK e firma vengono configurati in M0 senza salvare keystore o credenziali nel repository: [documentazione export Android](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html). Godot gestisce touch tramite `InputEventScreenTouch` e `InputEventScreenDrag`, mentre l'InputMap resta il contratto per tastiera/gamepad: [documentazione input](https://docs.godotengine.org/en/stable/tutorials/inputs/input_examples.html).

Android 12/API 31 è il minimo supportato, mentre Android 16/API 36 è il target di compilazione e comportamento. L'SDK Platform 36 e i Build Tools 36.x devono essere presenti nella toolchain: [setup Android 16](https://developer.android.com/about/versions/16/setup-sdk). Il valore API 36 prepara anche ai requisiti Google Play applicabili dal 31 agosto 2026, pur senza rendere lo store parte della prima release: [requisito ufficiale Google Play](https://developer.android.com/google/play/requirements/target-sdk).

M0 include uno spike obbligatorio con Godot 4.7.1: Gradle deve rispettare `min_sdk=31` e `target_sdk=36`, proprietà previste dall'exporter Android, e produrre un APK ARM64 installabile. Se la combinazione fra template e toolchain non compila con API 36, si aggiorna l'export template o la successiva patch stabile; non si abbassa silenziosamente il target: [proprietà exporter Android](https://docs.godotengine.org/en/stable/classes/class_editorexportplatformandroid.html).

Il preset Web resta disponibile in Compatibility e single-thread, senza C#, thread o GDExtension nell'MVP: [documentazione export Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html). L'overlay di level-up usa `PROCESS_MODE_WHEN_PAUSED`, secondo il modello di pausa ufficiale: [documentazione pausa](https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html).

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
| M5 — Release multipiattaforma | Roster giocabile, contenuti, audiovisivo, identità visiva, controlli, QA e packaging | B17, B17A, B18–B18M, B19–B20 | 113 | Otto personaggi selezionabili con passive e abilità proprie; ciclo B18C–B18M chiuso e build Windows/Android installabili da ambiente pulito |
| M6 — Web opzionale | Export single-thread e pubblicazione itch.io | B21 | 3 | Build browser verificata senza bloccare la release nativa |

Totali di pianificazione: 94 SP per l'MVP feature-complete fino a M4, 207 SP per la candidata Windows/Android con roster completo e ciclo B18C–B18M, più ulteriori 3 SP opzionali per Web/itch.io. Le stime delle nuove slice sono iniziali e vanno ricalibrate dopo i primi smoke e playtest sui valori ora congelati.

Gate di prodotto:

- dopo M1: verificare che movimento, leggibilità e “feel” del fuoco siano divertenti prima di ampliare i sistemi;
- dopo M2: playtest del loop XP e dell'Onda d'Urto con tastiera, controller e touch, inclusi cooldown e pausa;
- dopo M3: playtest del loop XP/carte e controllo delle combinazioni con l'abilità attiva;
- dopo M4: freeze del core loop; M5 integra il roster completo sul framework validato, con selezione pre-run, passive, altre sette abilità, correzioni, accessibilità e release work;
- prima di B19: freeze dell'intero ciclo B18C–B18M, inclusi HUD e controlli touch definitivi, abilità corrette, rank, nemici, upgrade, asset e confinamento XP, così hardening e profiling misurano la presentazione destinata alla release.

## 6. Backlog ordinato

Priorità: `P0` indispensabile per l'MVP, `P1` indispensabile per la prima pubblicazione, `P2` differibile.

| ID | Attività | Prio | SP | Dipende da | Criterio di accettazione sintetico |
|---|---|---:|---:|---|---|
| B01 | Chiudere decisioni e parametri di prodotto | P0 | 3 | — | Decisioni gameplay aperte chiuse; piattaforma registrata come API 31–36, ARM64, landscape, APK diretto e Play-ready |
| B02 | Bootstrap, InputMap, lifecycle e preset export | P0 | 5 | B01 | `com.ilgioco.friendshipsurvival`: Gradle/API 36 genera APK ARM64 min API 31; Windows avviabile |
| B03 | Movimento Player, touch e limiti arena | P0 | 5 | B02 | Tastiera/controller/joystick touch, diagonale normalizzata, input azzerato su focus loss, Player confinato |
| B04 | Nemico base, ArenaLayout e spawner | P0 | 5 | B02–B03 | Confini/spawn derivati dal rect dinamico, inseguimento, cap e stop fuori da `RUNNING` |
| B05 | Targeting, arma, proiettile e danno | P0 | 5 | B03–B04 | Bersaglio vivo più vicino, nessun tiro senza target, una hit processata una volta |
| B06 | Salute Player, contatto, Game Over e restart | P0 | 5 | B03–B05 | Invulnerabilità coerente, HP clamped, restart senza nodi/timer residui |
| B06A | Android Back, focus e lifecycle | P0 | 3 | B02–B03, B06 | Back/pausa, Home, lock e resume azzerano l'input; la run non riparte da sola |
| B07 | Drop, magnete e raccolta XP | P0 | 3 | B05 | Una morte genera un drop; accredito singolo entro `pickup_radius` |
| B08 | Livelli, soglie, overflow e coda | P0 | 5 | B07 | Nessun XP perso; un'offerta per ogni livello guadagnato |
| B09 | HUD responsive, safe area, vita, XP e timer | P0 | 5 | B06, B08 | Anchor/Container corretti su 16:9–20:9 e 4:3; clock fermo fuori da `RUNNING` |
| B09A | Framework abilità attive e Onda d'Urto Tellurica | P0 | 8 | B03, B05–B06A, B09 | Input tastiera/controller/touch, `AbilityDefinition`, registry, cooldown/HUD e area danno+knockback verificati; pausa e restart non lasciano stato residuo |
| B10 | Resource upgrade, registry e pesca | P0 | 5 | B01, B08 | ID validati, seed riproducibile, 3 offerte eleggibili uniche e fallback |
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
| B19 | Hardening Windows/Android e performance | P0 | 8 | B16, B17A, B18–B18M | Android 12 minimo e Android 16 target, aspect ratio, touch, lifecycle, abilità e soak rispettano il budget sulla presentazione finale |
| B20 | Packaging Windows e Android | P0 | 5 | B16, B19 | ZIP Windows e APK release firmato avviabili; AAB Gradle generabile senza upload Play |

Parallelizzazione sicura:

- dopo B01, il catalogo dati B10 può procedere mentre si implementa il combattimento B03–B06;
- B09A parte soltanto dopo B09 e non modifica il perimetro di B07–B09;
- dopo la stabilizzazione delle dimensioni UI e degli schemi dati, B17A procede per profilo completo (selezione + passiva + attiva) in piccoli lotti, mentre gli asset B18 restano sostituibili;
- B18D consuma la direzione B18C senza riaprire `InputRouter`; B18F estende il tipo area senza cambiare le aree statiche; B18I riusa il clamp circolare di `ArenaLayout` senza cambiare spawn o magnete;
- B18K e B18L possono procedere dopo i gate correnti con contratti touch separati ma una verifica multitouch comune; B18G e B18J condividono il framework level-up senza accoppiare i relativi dati; la produzione originale B18H e i VFX procedurali B18M possono avanzare in parallelo;
- profiling, soak e matrice finale B19 non iniziano prima del freeze B18C–B18M e dei gate fisici combinati;
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
  `SCRIPT ERROR` o `FATAL EXCEPTION` precedono il freeze visivo per B19.

### Ciclo operativo B18C–B18M

Questo è il ciclo da completare prima di B19. Gli stati hanno il seguente
significato:

- `DA DEFINIRE`: mancano decisioni o asset che cambiano l'implementazione;
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
| B18E | Tuoni di Zat | IN VERIFICA | Gate automatici, Windows e Android statico chiusi; runtime Pixel 9 ancora da verificare |
| B18F | Abilità inseguitrice di Alea | COMPLETATO | Gate Windows e Pixel 9 chiusi il 24 agosto 2026 |
| B18G | Rank delle abilità principali | IN VERIFICA | Gate automatici, Windows e Android statico chiusi; runtime Pixel 9 ancora da verificare |
| B18H | Nemici piccione | PRONTO | Produzione degli sprite originali base e speciale |
| B18I | XP confinato nell'arena | COMPLETATO | Gate chiusi; commit dedicato `e58cbd0` |
| B18J | Grigliata estiva | IN VERIFICA | Gate automatici, Windows, Android statico e cold launch Pixel 9 chiusi; interazione manuale ancora da verificare |
| B18K | Pulsante abilità con icona e cooldown circolare | COMPLETATO | Gate chiusi; commit dedicato `81b47f6` |
| B18L | Joystick dinamico | COMPLETATO | Gate chiusi, inclusa regressione lock/resume; commit dedicato `d6625d7` |
| B18M | Migliorie grafiche delle abilità | PRONTO | Produzione VFX procedurali e manifest degli asset originali |

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

Stato: `IN VERIFICA`.

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
- [ ] Gate Pixel 9: multitouch, flash standard/ridotto, 20:9, lifecycle e
  cleanup reale.

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

Stato: `IN VERIFICA`.

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
- [ ] Gate Pixel 9: tap reali sui passaggi rank, scomparsa al cap, nuovo profilo
  dalla successiva attivazione, lifecycle, restart e cambio personaggio puliti.

Dettagli ed evidenze: [`b18g-verification.md`](./b18g-verification.md).

#### B18H — Nemici piccione

Stato: `PRONTO`.

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

Stato: `IN VERIFICA`.

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
- [x] Resource `summer_grill.tres`, effect ID dedicato, icona SVG originale e
  composizione col registry upgrade integrati senza mutare le risorse condivise.
- [x] Smoke `B18J_SUMMER_GRILL_SMOKE_OK`, regressione completa `30/30`, project
  smoke, export e runtime Windows, export Android statico ARM64.
- [ ] Gate Pixel 9: tap reali sui cinque rank, cura del delta, composizione con
  `L'Ansia`, cap, lifecycle, restart e cambio personaggio puliti.

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

Stato: `PRONTO`.

- [x] La baseline di release usa VFX originali disegnati con primitive Godot,
  shader semplici e, soltanto quando serve, sprite originali del progetto. Non
  è richiesta una ricerca di pacchetti animati esterni.
- [x] Le otto icone SVG correnti sono definitive per questa release; Powerslide
  conserva il pittogramma Pinhead CC0 già registrato. B18M può rifinirne
  spessori e palette senza cambiare silhouette, viewBox o hit target B18K.
- [x] Linguaggio VFX: Magno usa crepe e anelli tellurici; Bea scia a nastro con
  scintille; Zat nube e onde del tuono, preavviso e flash accessibile; Alea archi
  rotanti; Aleo pozza grigio-ciano con bordo e bolle; Lollo confetti più palette
  dell'abilità copiata; Migi anelli concentrici e particelle lente; Marghe clone,
  cassa e note musicali. Gli effetti alleati restano sotto telegraph e proiettili
  ostili e non comunicano collisioni più ampie di quelle reali.
- [x] Ogni nuovo file grafico deve essere registrato in un manifest con percorso,
  origine, autore, licenza, trasformazioni e SHA-256. Per asset originali si usa
  `origine: progetto IL GIOCO`, senza attribuzione esterna.
- [x] Non esistono asset mancanti che richiedano generazione per la baseline,
  quindi un file prompt non è un gate. Se in futuro si usa un generatore, prompt,
  modello, data, output scelto e modifiche vanno versionati prima dell'import.
- [x] Budget Android per una singola attivazione: massimo `1` overlay fullscreen,
  `64` particelle vive e `2` draw call/materiali aggiuntivi per famiglia; il
  profiling B19 può ridurre il budget senza modificare gameplay o timing.

Gate comuni del ciclo:

- smoke dedicati per direzione/animazione, Bea, Zat, Alea, rank, Grigliata
  estiva, pulsante abilità e joystick dinamico;
- nessun `SCRIPT ERROR` o `FATAL EXCEPTION`, anche con exit code `0`;
- verifica Windows e Android, distinguendo sempre export statico da runtime;
- su Android reale, movimento col joystick con un dito e attivazione
  dell'abilità con il secondo;
- pausa, ripresa esplicita, focus, Home/lock, Back e restart per ogni effetto
  temporizzato o inseguitore;
- verifica 16:9, 20:9 e 4:3 per UI, posizioni, direzioni, aree e flash.

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

### Test di integrazione

- `kill → drop → pickup → level-up → pausa → scelta → resume`;
- danno ripetuto, invulnerabilità, morte e restart;
- Onda d'Urto da tastiera, controller e touch: una sola attivazione per pressione, danno e knockback nel raggio, HUD sincronizzato;
- pausa, level-up, focus loss e restart durante cooldown o area persistente senza consumo di tempo, input bloccato o entità residue;
- per ciascuno degli otto profili: selezione, applicazione della passiva, attiva corretta, combinazione con almeno un upgrade e seconda run senza stato residuo;
- combinazioni fra catena Gossip, traiettoria oscillante e frequenza aumentata;
- slow periodico mentre entra o muore un nemico;
- Boss e nemici base presenti insieme;
- HUD B18B compatto con XP, vita, timer, pausa e abilità sincronizzati durante resize, level-up, Boss intro, pausa e terminali;
- B18E: preavviso, flash a viewport intero, ingresso tardivo dei nemici, danno percentuale, pausa e cleanup su due run;
- B18G/B18J: offerta e applicazione dei rank, Grigliata estiva, cap, overflow di livello e seconda run pulita;
- B18I: drop XP da centro, lati, angoli e morti fuori arena a 16:9, 20:9 e 4:3;
- B18K: icona selezionata, riempimento circolare, secondi residui e transizione pronta/in cooldown senza cambiare il target touch;
- B18L: creazione al primo tocco valido, ownership, rilascio, esclusione HUD/overlay e abilità attivata con il secondo dito;
- hit flash, reazione, morte e abilità pronta non cambiano danno, collisioni, cooldown o cleanup della run;
- joystick touch più pausa, cambio dito e annullamento del touch senza direzioni bloccate;
- Home/blocco schermo durante combattimento e level-up, con ripresa solo su conferma;
- due run consecutive senza segnali doppi o riferimenti alla run precedente.

### Matrice manuale minima

| Area | Casi |
|---|---|
| Windows | Tastiera, controller, finestra, resize, fullscreen e perdita focus |
| Android device | Device fisico Android 12 vicino al minimo e device/emulatore Android 16; joystick dinamico, tap, drag, deadzone, ownership, multitouch reale, cambio dito e pulsante abilità mentre il joystick è attivo |
| Android lifecycle | Back, Home, lock/unlock, chiamata/interruzione, background/resume e input azzerato |
| Layout | 16:9, 18:9, 20:9, cutout/notch e tablet/emulatore 4:3; HUD B18B compatto, flash B18E a viewport intero, controlli B18K/B18L nella safe area e nessuna sovrapposizione con Boss UI/overlay |
| Packaging | Installazione pulita/aggiornamento APK ARM64, firma release e generazione AAB senza upload |
| Web opzionale | Chromium e Firefox soltanto in B21 |
| Stabilità | 5 restart rapidi; soak termico 20 minuti su Android; ondate al cap entità |
| Gameplay | selezione di tutti gli otto personaggi, vittoria, sconfitta, level-up multiplo, rank abilità, Grigliata estiva, abilità pronta/in cooldown e Boss durante elevata densità |

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
| HUD compatto riduce usabilità touch | Media | Alta | Ingombro visivo ridotto senza restringere hit area; target da almeno `44–48` unità logiche e gate multitouch fisico prima di B19 |
| Flash di Zat è fastidioso o poco accessibile | Media | Alta | Intensità mobile e modalità ridotta definite prima di B18E; verifica su device fisico e flash limitato nel tempo |
| Sprite piccione o VFX originali non risultano leggibili sul campo | Media | Media | Silhouette e palette congelate, fixture base/speciale, priorità dei layer e confronto Windows/Android prima del freeze; asset esterni non necessari |
| Citazioni o immagini non approvate | Bassa | Alta | Registro B17 obbligatorio, getter con fallback e citazioni/audio personali assenti finché non vengono forniti |
| Targeting lineare degrada con molte entità | Media | Media | Cap e profiler; target cache, poi partizionamento soltanto su evidenza |
| Il PRD resta ambiguo durante il coding | Alta | Media | Decision log breve, contratti sopra e aggiornamento della specifica prima di M1 |

## 10. Prossima iterazione

Ordine operativo immediato:

1. creare commit dedicati per B18I, B18K e B18L, includendo nel commit B18L la
   regressione lock/resume emersa e chiusa sul Pixel 9; i gate tecnici e manuali
   delle tre slice sono già chiusi;
2. chiudere i gate manuali residui B18B a 20:9 e 4:3;
3. chiudere il gate Pixel 9 di B18E già implementato: multitouch, flash standard/ridotto, 20:9, lifecycle e cleanup reale;
4. chiudere i gate Pixel 9 di B18G e B18J già implementati: tap reali sui rank, aumento HP `×1,15` con cura del delta, stacking, cap, lifecycle e reset della run;
5. completare B18H e B18M dalla direzione originale approvata: piccioni base/speciale, VFX procedurali e icone coerenti, con manifest e budget Android;
6. eseguire il gate combinato B17A–B18M su Windows e Pixel 9, il gate percettivo B18 con Boss a `04:00`/`2400 HP` e la matrice 16:9/20:9/4:3; avviare B19 solo dopo il freeze documentato dell'intero ciclo.

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
Confinamento dei drop XP nel playfield e gate residuo Android sono registrati
in [`b18i-verification.md`](./b18i-verification.md).
Grigliata estiva, cura del delta e gate residuo Android sono registrati in
[`b18j-verification.md`](./b18j-verification.md).
Pulsante-icona, cooldown radiale, timer centrale e gate residuo Android B18K
sono registrati in [`b18k-verification.md`](./b18k-verification.md).
Joystick dinamico, ownership del primo dito e gate fisico condiviso B18K/B18L
sono registrati in [`b18l-verification.md`](./b18l-verification.md).
