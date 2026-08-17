# Piano di sviluppo — Friendship Survival: Arena Bullet Heaven

Fonte: [`prd.md`](./prd.md)  
Decisioni: [`decision-log.md`](./decision-log.md)  
Stato: B18B è implementato senza nuovi asset obbligatori: fascia HUD compatta, linea XP, card abilità ridotta, joystick solo visivamente più piccolo, pavimento procedurale e combat feedback presentazionale. Import, project smoke, 21 smoke ed export Windows/Android sono verdi senza errori o leak; il confronto Windows 16:9 e l'avvio sul Pixel 9 Android 17/API 37 sono registrati. Il freeze per B19 attende ancora i controlli percettivi gameplay 20:9/4:3, densità elevata e il gate multitouch fisico
Obiettivo: trasformare il concept in un MVP completo, verificabile su Windows e Android; Web resta un target secondario

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
| M5 — Release multipiattaforma | Roster giocabile, contenuti, audiovisivo, identità visiva, QA e packaging | B17, B17A, B18, B18B, B19–B20 | 62 | Otto personaggi selezionabili con passive e abilità proprie; direzione visiva coerente e build Windows/Android installabili da ambiente pulito |
| M6 — Web opzionale | Export single-thread e pubblicazione itch.io | B21 | 3 | Build browser verificata senza bloccare la release nativa |

Totali di pianificazione: 94 SP per l'MVP feature-complete fino a M4, 156 SP per la candidata Windows/Android con roster completo e pass di identità visiva, più ulteriori 3 SP opzionali per Web/itch.io. Le stime vanno ricalibrate con la velocità osservata in M1–M2.

Gate di prodotto:

- dopo M1: verificare che movimento, leggibilità e “feel” del fuoco siano divertenti prima di ampliare i sistemi;
- dopo M2: playtest del loop XP e dell'Onda d'Urto con tastiera, controller e touch, inclusi cooldown e pausa;
- dopo M3: playtest del loop XP/carte e controllo delle combinazioni con l'abilità attiva;
- dopo M4: freeze del core loop; M5 integra il roster completo sul framework validato, con selezione pre-run, passive, altre sette abilità, correzioni, accessibilità e release work;
- prima di B19: freeze di HUD, controlli visivi, arena e combat feedback dopo B18B, così hardening e profiling misurano la presentazione destinata alla release.

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
| B19 | Hardening Windows/Android e performance | P0 | 8 | B16, B17A, B18B | Android 12 minimo e Android 16 target, aspect ratio, touch, lifecycle, abilità e soak rispettano il budget sulla presentazione finale |
| B20 | Packaging Windows e Android | P0 | 5 | B16, B19 | ZIP Windows e APK release firmato avviabili; AAB Gradle generabile senza upload Play ||

Parallelizzazione sicura:

- dopo B01, il catalogo dati B10 può procedere mentre si implementa il combattimento B03–B06;
- B09A parte soltanto dopo B09 e non modifica il perimetro di B07–B09;
- dopo la stabilizzazione delle dimensioni UI e degli schemi dati, B17A procede per profilo completo (selezione + passiva + attiva) in piccoli lotti, mentre gli asset B18 restano sostituibili;
- B18B congela gerarchia e ingombri visivi prima di B19; profiling, soak e matrice finale non iniziano su una UI destinata a essere ridisegnata;
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
- ridurre il raggio visivo del joystick da `84` a circa `68` unità logiche e la
  sua opacità a riposo, conservando invariati area touch e comportamento;
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
- scheduler Boss con pausa, salti di soglia e restart;
- priorità delle sorgenti `InputRouter`, deadzone, normalizzazione e reset completo del touch;
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
- hit flash, reazione, morte e abilità pronta non cambiano danno, collisioni, cooldown o cleanup della run;
- joystick touch più pausa, cambio dito e annullamento del touch senza direzioni bloccate;
- Home/blocco schermo durante combattimento e level-up, con ripresa solo su conferma;
- due run consecutive senza segnali doppi o riferimenti alla run precedente.

### Matrice manuale minima

| Area | Casi |
|---|---|
| Windows | Tastiera, controller, finestra, resize, fullscreen e perdita focus |
| Android device | Device fisico Android 12 vicino al minimo e device/emulatore Android 16; tap, drag, deadzone, multitouch, cambio dito e pulsante abilità mentre il joystick è attivo |
| Android lifecycle | Back, Home, lock/unlock, chiamata/interruzione, background/resume e input azzerato |
| Layout | 16:9, 18:9, 20:9, cutout/notch e tablet/emulatore 4:3; HUD B18B compatto, nessun controllo fuori safe area e nessuna sovrapposizione con Boss UI/overlay |
| Packaging | Installazione pulita/aggiornamento APK ARM64, firma release e generazione AAB senza upload |
| Web opzionale | Chromium e Firefox soltanto in B21 |
| Stabilità | 5 restart rapidi; soak termico 20 minuti su Android; ondate al cap entità |
| Gameplay | selezione di tutti gli otto personaggi, vittoria, sconfitta, level-up multiplo, abilità pronta/in cooldown e Boss durante elevata densità |

## 8. Definition of Done

Un'attività è finita solo quando:

- soddisfa i criteri di accettazione e i test pertinenti sono verdi;
- non introduce errori runtime, segnali duplicati o warning nuovi non motivati;
- i parametri di bilanciamento sono dati configurabili, non costanti disperse negli script;
- il Player legge soltanto `InputRouter`; InputMap e touch producono lo stesso contratto di movimento;
- l'abilità attiva riceve soltanto l'intenzione di `InputRouter`, usa parametri da `AbilityDefinition` e non avanza fuori da `RUNNING`;
- la feature P0 è verificata sia con tastiera/controller su Windows sia con touch su Android;
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
| Citazioni o immagini non approvate | Bassa | Alta | Registro B17 obbligatorio, getter con fallback e citazioni/audio personali assenti finché non vengono forniti |
| Targeting lineare degrada con molte entità | Media | Media | Cap e profiler; target cache, poi partizionamento soltanto su evidenza |
| Il PRD resta ambiguo durante il coding | Alta | Media | Decision log breve, contratti sopra e aggiornamento della specifica prima di M1 |

## 10. Prossima iterazione

Ordine operativo immediato:

1. chiudere i gate manuali B18B sul gameplay 20:9 e 4:3 con Boss UI, level-up, pausa, terminali e densità elevata; il 16:9, la selezione Pixel 9 e i contratti geometrici sono già verificati;
2. completare sul Pixel 9 i gate combinati B17A–B18B: cambio personaggio, keyguard, dash, area persistente, Cosplay Casuale e attivazioni ripetute mantenendo il joystick con l'altro dito;
3. completare il gate percettivo B18 sul mix audio e svolgere una run reale con Boss a `04:00`/`2400 HP`, registrando durata e correzioni di bilanciamento sulla presentazione congelata;
4. congelare B18B dopo i controlli fisici, conservando export e log già verdi come baseline tecnica;
5. avviare B19 soltanto dopo il freeze B18B, chiudendo controller fisico, Android 12/API 31, Android 16/API 36, profiling e soak sulla build visivamente definitiva.

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
