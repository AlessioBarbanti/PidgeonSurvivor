# Decision log

Ultimo aggiornamento: 17 agosto 2026  
Ambito: decisioni che modificano scope, architettura, compatibilità o rilascio

## Stati

- **Confermata**: approvata esplicitamente dal proprietario del progetto.
- **Baseline operativa**: assunzione reversibile adottata per non bloccare il lavoro.
- **Aperta**: deve essere chiusa prima del gate indicato.

## Decisioni di piattaforma

| ID | Stato | Decisione | Conseguenza |
|---|---|---|---|
| PLAT-001 | Confermata | Windows x64 e Android nativo sono target obbligatori | Ogni milestone P0 richiede smoke test su entrambi |
| PLAT-002 | Confermata | Web/itch.io non blocca la release nativa | Resta nella milestone opzionale M6 |
| TECH-001 | Baseline operativa | [Godot 4.7.1 Standard](https://godotengine.org/download/archive/4.7.1-stable/), GDScript tipizzato, renderer Compatibility | Versione stabile fissata; un solo codice e renderer comune per Windows/Android |
| AND-001 | Baseline operativa | Minimo Android 12, API 31 | Interpreta “qualche major prima” come quattro versioni sotto Android 16 |
| AND-002 | Confermata | Target Android 16, API 36 | `targetSdk=36` e test dei cambiamenti di comportamento Android 16 |
| AND-003 | Confermata | Compilazione Android 16 | `compileSdk=36`, SDK Platform 36 e Build Tools 36.x nella toolchain |
| AND-004 | Confermata | ABI release `arm64-v8a` | APK/AAB pubblicabili contengono ARM64; niente ARM32 |
| AND-005 | Confermata | Orientamento landscape | Portrait e rotazione durante la run sono fuori MVP |
| DIST-001 | Confermata | Prima distribuzione tramite APK diretto, non Google Play | Nessun account, listing o upload Play nella prima release |
| DIST-002 | Confermata | Progetto predisposto per Google Play | Gradle, package ID stabile, versioning, icone adattive, firma esterna e generazione AAB senza upload |
| SEC-001 | Confermata | Keystore e credenziali non entrano nel repository | Percorsi e password passano tramite ambiente/configurazione locale; il keystore release richiede backup separato |
| APP-001 | Baseline operativa | Package ID di sviluppo `com.ilgioco.friendshipsurvival` | Non richiede una scelta dell'utente ora; si verifica e congela prima della prima release pubblica |
| APP-002 | Baseline operativa | Versione iniziale `0.1.0`, `versionCode=1` | Base semplice per APK e futura migrazione AAB |
| TEST-001 | Baseline operativa | Profili Android 12 e 16 predefiniti; il primo telefono collegato viene rilevato via adb | Non è necessario conoscere in anticipo modello, RAM o versione del dispositivo |

## Contratto Android

| Campo | Valore |
|---|---|
| OS minimo | Android 12 |
| `minSdk` | 31 |
| OS target | Android 16 |
| `targetSdk` | 36 |
| `compileSdk` | 36 |
| ABI release | `arm64-v8a` |
| Orientamento | Landscape bloccato |
| Renderer | Compatibility |
| Engine | Godot 4.7.1 Standard |
| Package ID sviluppo | `com.ilgioco.friendshipsurvival` |
| Versione iniziale | `0.1.0` (`versionCode=1`) |
| Artefatto previsto | APK ARM64 firmato |
| Predisposizione futura | AAB Gradle generabile, nessun upload Play |

Un preset debug può includere temporaneamente `x86_64` soltanto per un emulatore di sviluppo. Gli artefatti release restano ARM64.

## Predisposizione Google Play

“Predisposto” significa che, senza cambiare architettura o package identity, il progetto dispone di:

- build Gradle attiva;
- package ID definitivo e immutabile prima della prima build firmata;
- `versionCode` intero crescente e `versionName` semantico;
- icona principale, adaptive foreground/background e icona monocromatica opzionale;
- configurazione AAB verificabile localmente;
- release keystore esterno al repository, con backup e procedura di recupero;
- nessun permesso Android non necessario;
- documentazione dei passaggi di firma e build.

Non comprende account sviluppatore, scheda store, policy, privacy form, closed testing o pubblicazione.

## Decisioni di input e layout

| ID | Stato | Decisione | Conseguenza |
|---|---|---|---|
| INP-001 | Baseline operativa | `InputRouter` è l'unica sorgente di movimento del Player | Tastiera, controller e touch espongono lo stesso vettore limitato a lunghezza 1 |
| INP-002 | Baseline operativa | Il touch ha priorità mentre il joystick possiede un dito | Input simultanei opposti non si annullano; al rilascio torna automaticamente InputMap |
| INP-003 | Baseline operativa | Focus loss e app pause chiudono il gate; il riarmo richiede app valida e tutte le sorgenti neutrali | Uno stick held non può riavviare il movimento al resume; il futuro RunController resta autorità sul gate `enabled` |
| INP-004 | Baseline operativa | `PlatformLifecycle` traduce Escape/Start, pulsante touch, Android Back, focus loss e app pause verso `RunController`; le interruzioni possono sospendere ma mai riprendere automaticamente | `MANUAL_PAUSE` mostra un overlay always-process e richiede Back/cancel o `RIPRENDI`; gli altri modali conservano la propria priorità e ogni touch viene azzerato |
| UI-001 | Baseline operativa | Gameplay e controlli derivano da viewport e safe area dinamici; i controlli edge aggiungono padding per le gesture | Nessuna coordinata 1280×720 è usata come limite runtime; cutout e gesture bar restano fuori dalla hit area del joystick |
| UI-002 | Baseline operativa | Il HUD B09 è figlio full-rect di `SafeAreaRoot`, usa Container e osserva i segnali di salute, progressione e clock senza polling o stato gameplay proprio | Vita e XP si aggiornano atomicamente; il timer è centrato su 16:9–20:9 e 4:3 e resta fermo ogni volta che `RunController` non è in `RUNNING` |
| UI-003 | Baseline operativa | `UpgradeOverlay` è always-process dentro `SafeAreaRoot`, presenta l'offerta autorevole di `UpgradeService` con tre `Button` a focus circolare e disarma tutte le carte prima di inoltrare una conferma | Mouse, frecce/WASD, tasti 1–3, controller e touch condividono lo stesso percorso atomico; il joystick viene azzerato/nascosto in `LEVEL_UP` e ripristinato solo alla chiusura dell'offerta |

## Decisioni di combattimento

| ID | Stato | Decisione | Conseguenza |
|---|---|---|---|
| COMBAT-001 | Baseline operativa | Il targeting mantiene un registro alimentato dallo spawner e sceglie il nemico vivo più vicino tramite distanza al quadrato; a parità prevale il primo registrato | Nessuna scansione del `SceneTree`; una morte esce dal targeting nello stesso frame |
| COMBAT-002 | Baseline operativa | L'arma avanza il cooldown solo in `RUNNING`, non consuma la prontezza senza target e crea al massimo un proiettile per tick | Pause e frame lunghi non generano recuperi a raffica; un target nuovo può essere colpito subito |
| COMBAT-003 | Baseline operativa | Ogni proiettile base è monouso e il danno è accettato solo in `RUNNING`; movimento, lifetime e danno sono snapshot del profilo al momento del tiro | Callback duplicate, pause e stati terminali non possono applicare una seconda hit |
| COMBAT-004 | Baseline operativa | Il nemico usa una `Hurtbox` dedicata, separata dal body di movimento, e un `HealthComponent` con clamp e morte atomica | B04 conserva inseguimento e overlap; salute e segnali sono riutilizzabili in B06 e B15 |
| COMBAT-005 | Baseline operativa | Il contatto usa un'`Area2D` del nemico contro il layer `Player Body`; la prima hit non letale apre l'invulnerabilità e gli overlap successivi vengono respinti fino alla scadenza | Nemici sovrapposti non sommano danni nello stesso frame; pausa e terminali non consumano la finestra né applicano hit |
| BAL-001 | Baseline operativa | Profilo B05: 4 colpi/s, 10 danni, proiettile 900 px/s, lifetime 2 s, raggio 6 px, volata 32 px; BaseEnemy 40 HP | Quattro hit rendono flash e barra vita visibili prima della morte; valori esportati restano ribilanciabili dai dati |
| BAL-002 | Baseline operativa | Profilo B06: Player 100 HP, BaseEnemy 20 danni da contatto, invulnerabilità post-hit 0,75 s | Un overlap persistente richiede cinque hit effettive; i valori sono esportati nelle scene e restano ribilanciabili |

## Decisioni di progressione

| ID | Stato | Decisione | Conseguenza |
|---|---|---|---|
| PROG-001 | Baseline operativa | Solo il segnale atomico `BaseEnemy.died` genera XP; despawn e cleanup non danno ricompense, e un ID nemico può produrre al massimo un drop | Segnali duplicati nello stesso frame non duplicano pickup o accrediti; la ricompensa resta distinta dalla rimozione tecnica |
| PROG-002 | Baseline operativa | Il pickup si attiva entro il `pickup_radius` del Player, avanza e si raccoglie solo in `RUNNING`; `ExperienceSystem` è l'unica autorità sull'accredito e resetta al restart | Pausa e terminali fermano magnete e progressione; soglie e overflow restano indipendenti dai pickup |
| PROG-003 | Baseline operativa | `ExperienceSystem` conserva XP totali e XP nella soglia corrente, accoda il livello di ogni scelta guadagnata e mantiene `LEVEL_UP` fino a esaurimento della coda | Un salto di più soglie non perde XP né frame di pausa fra due offerte; B10 può generare una pesca per ogni evento `level_up_started` |
| PROG-004 | Baseline operativa | `UpgradeDefinition` dichiara ID ed `effect_id` snake_case, testi, icona, parametri, peso, rank massimo, tag e prerequisiti; `UpgradeRegistry` esclude definizioni nulle, non valide, duplicate o con prerequisiti assenti | Il catalogo resta sostituibile senza codice e nessun ID ambiguo o riferimento rotto entra nella pesca |
| PROG-005 | Baseline operativa | `UpgradeService` usa uno stream RNG scene-local derivato dal seed della run, pesca pesata senza reinserimento e conserva i rank solo per la run corrente; tre fallback statistici con ID diversi sono ripetibili | Lo stesso seed e le stesse scelte riproducono la sequenza, ogni offerta ha tre ID unici e il level-up non si blocca quando le primarie raggiungono il cap |
| PROG-006 | Baseline operativa | `UpgradeEffectRegistry` ricostruisce ogni statistica effettiva come valore base per il prodotto dei moltiplicatori elevati ai rispettivi rank, poi applica un cap; Player e arma conservano i valori runtime separati dai `Resource` | Lo stacking è deterministico e idempotente, i profili condivisi non vengono mutati e restart/nuova run riportano tutti i moltiplicatori a identità |
| BAL-003 | Baseline operativa | Profilo B07: BaseEnemy vale 1 XP, Player ha `pickup_radius=160 px`, pickup a `460 px/s` e raccolta a `18 px` | Il magnete è leggibile nella slice e tutti i valori restano esportati per upgrade e bilanciamento successivi |
| BAL-004 | Baseline operativa | Curva B08 lineare e configurabile: soglia livello 1 pari a 10 XP, crescita di 5 XP per livello (`10, 15, 20, …`) | La slice raggiunge presto i primi level-up; il bilanciamento può cambiare nel `.tres` senza modificare il codice |
| BAL-005 | Baseline operativa | I cap provvisori B12 sono `×2` velocità, `×3` raggio pickup, `×3` frequenza e `×5` danno; un aumento di frequenza non riscrive il cooldown già iniziato, ma determina l'intervallo dal colpo successivo | I fallback restano consumabili senza crescita illimitata; i cap sono proprietà esportate della scena e potranno essere ribilanciati senza cambiare la composizione degli effetti |

## Decisioni di sconfitta e restart

| ID | Stato | Decisione | Conseguenza |
|---|---|---|---|
| RUN-001 | Baseline operativa | La morte del Player richiede `DEFEAT`; `RunController` blocca il terminale e l'`EndScreen` always-process espone `RIPROVA` a mouse, tastiera, controller e touch | Danno, clock, spawn e movimento restano fermi mentre l'UI continua a ricevere input |
| RUN-002 | Baseline operativa | Il restart avviene in-place solo da uno stato terminale e ripristina vita massima base, HP, i-frame, input, posizione, seed, scheduler, targeting, nemici e proiettili | Due run consecutive non condividono nodi, cooldown o timer; non serve ricaricare la scena per B06 |

## Decisioni sulle abilità attive

| ID | Stato | Decisione | Conseguenza |
|---|---|---|---|
| ABIL-001 | Confermata | Ogni personaggio possiede un'abilità attiva distinta dagli upgrade e complementare allo sparo automatico | L'MVP deve validare input, cooldown, HUD e runtime dell'abilità, non soltanto catalogarne i dati |
| ABIL-002 | Confermata | B09A implementa il framework e l'Onda d'Urto Tellurica di Magno dopo B09; B17A completa le altre sette abilità | B07–B09 restano focalizzati sulla progressione; la prima release contiene il catalogo completo sul framework già verificato |
| ABIL-003 | Baseline operativa | Cooldown ed effetti avanzano solo in `RUNNING`; richieste rifiutate non consumano cooldown e il restart elimina ogni stato o entità dell'abilità | Pausa, level-up, lifecycle e due run consecutive sono gate obbligatori per B09A e B17A |
| ABIL-004 | Baseline operativa | L'Onda d'Urto Tellurica usa il profilo PRD: cooldown 8 s, raggio 220 unità mondo, 20 danni, knockback 300 per 0,2 s | I valori vivono nel `Resource`; risoluzione e DPI non modificano la distanza gameplay, mentre il bilanciamento resta regolabile senza codice |
| ABIL-005 | Baseline operativa | `InputRouter` espone una sola intenzione `active_ability` da Space, face button sud o pulsante touch; `AbilityController` valida stato/cooldown e delega `effect_id` al registry scene-local | Una pressione held produce una sola richiesta; HUD ed effetti non applicano direttamente regole di attivazione e il restart elimina le connessioni/entità della run |

I preset di export escludono esplicitamente `exports/**` e `android/build/**`
dal filtro `all_resources`, così anteprime e output generati locali non vengono
reimpacchettati nel PCK o nell'APK.

## Matrice minima di verifica

| Profilo | Scopo |
|---|---|
| Windows x64 | Gameplay, tastiera/controller, resize e fullscreen |
| Android 12/API 31 fisico | Compatibilità minima, touch, prestazioni e lifecycle |
| Android 16/API 36 fisico o emulato | Comportamenti target, layout e packaging |
| Formato 16:9 | Baseline visiva |
| Formato 20:9 con cutout | Safe area e joystick touch |
| Tablet/emulazione 4:3 | Layout responsive |

I profili emulatori iniziali sono:

- minimo: API 31, 4 GB RAM, schermo 720×1600 ruotato in landscape;
- target: API 36, 6 GB RAM, schermo 1080×2400 ruotato in landscape;
- layout: tablet 4:3 per safe area e responsive UI.

L'emulatore verifica logica e layout ma non sostituisce il telefono fisico per frame pacing, temperatura, batteria e touch reale.

## Stato toolchain locale

Rilevazione del 12 agosto 2026:

| Componente | Stato | Azione |
|---|---|---|
| Android SDK | Presente e configurato in Godot | Nessuna |
| SDK Platform | `android-31` e `android-36` presenti | Nessuna |
| Build Tools | `36.1.0` presente | Nessuna |
| adb | Presente, versione 36.0.2 e aggiunto al PATH utente | Nessuna |
| Java | Microsoft OpenJDK 17.0.20 configurato in Godot e `JAVA_HOME` | Java 8 globale resta installato ma non è usato dalla build |
| Godot | 4.7.1 Standard installato, template verificati e pin WinGet attivo | Rimuovere il pin solo durante una migrazione pianificata |
| Android Command-line Tools | Presenti, `sdkmanager` 22.0 | Nessuna |
| NDK/CMake | NDK 29.0.14206865 e CMake 3.10.2.4988404 presenti | Nessuna |
| Gradle locale | Template 4.7.1, Gradle 8.11.1, AGP 8.6.1 | Rigenerare insieme a ogni upgrade Godot |
| Artefatti M0 | Windows x64, APK ARM64 e AAB debug generati | Vedere `m0-verification.md` |
| Dispositivo fisico | Pixel 9 ARM64, Android 17/API 37; installazione, avvio, Back/Home/resume e landscape verificati | Aggiungere un profilo Android 12/API 31 per il minimo supportato |

## Decisioni ancora aperte

| ID | Entro | Decisione richiesta |
|---|---|---|
| OPEN-004 | Prima di B20 | Identità e posizione sicura del release keystore |
| OPEN-005 | Prima di B20 | Nome pubblico definitivo e icone dell'app |

Restano inoltre aperte le decisioni di gameplay elencate in B01 del piano di sviluppo: durata della run, valori Boss e bilanciamento finale di curva XP, danno e cap degli upgrade. La regola di stacking è chiusa da PROG-006.
