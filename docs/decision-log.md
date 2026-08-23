# Decision log

Ultimo aggiornamento: 24 agosto 2026

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
| UI-004 | Baseline operativa | B18B riunisce ritratto, livello, vita, timer e pausa in una fascia alta `64` unità logiche, con linea XP da `8`; la card abilità è `246×94` e i due pulsanti touch restano almeno `44×44` | Il campo di gioco guadagna priorità senza restringere hit target; Boss UI, overlay e terminali mantengono i propri layer e la safe area dinamica |

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
| PROG-007 | Baseline operativa | Le cinque signature B13 sono upgrade a rank singolo interpretati dallo stesso registry: Gossip fotografa numero salti, raggio e falloff al momento dello sparo, mentre Birra fotografa oscillazione e frequenza; ogni istanza conserva gli ID già colpiti | Catena, oscillazione e frequenza si combinano senza mutare il `WeaponProfile`; un bersaglio non riceve due hit dallo stesso colpo e ogni salto applica il danno corrente moltiplicato per il falloff |
| PROG-008 | Baseline operativa | `Ritardo Cronico` schedula pulse sul solo clock `RUNNING` e applica un modificatore identificato locale ai nemici; `Non Ho Tempo` ascolta soltanto il segnale di danno effettivo del Player, applica knockback nel raggio e crea un VFX scene-local; la vignetta è un effetto UI puramente visivo | Pausa e level-up non consumano lo slow, nuovi nemici ereditano il pulse attivo, gli i-frame non duplicano shockwave e restart rimuove status, VFX, vignetta, timer e snapshot runtime |
| PROG-009 | Baseline operativa | B18I collega `ExperienceDropper` ad `ArenaLayout` e clampa ogni drop nel playfield usando come margine il maggiore fra raggio visivo e raggio di raccolta, oggi `18` unità logiche | Una morte fuori arena conserva la ricompensa in una posizione interamente visibile e raggiungibile; DPI e pixel fisici non cambiano il risultato, mentre il restart continua a eliminare tutti i pickup della run |
| PROG-010 | Baseline operativa | `Grigliata estiva` ha cinque rank da `×1,15`, contributo cumulativo massimo nominale `×2,0113571875` e cap dati `×2,05`; ogni applicazione cura esattamente l'aumento positivo di HP massimi | La carta si compone secondo PROG-006, si applica una volta durante la scelta e non preserva la percentuale di vita; morte, restart e cambio personaggio non possono resuscitare o conservare rank e HP della run precedente |
| BAL-003 | Baseline operativa | Profilo B07: BaseEnemy vale 1 XP, Player ha `pickup_radius=160 px`, pickup a `460 px/s` e raccolta a `18 px` | Il magnete è leggibile nella slice e tutti i valori restano esportati per upgrade e bilanciamento successivi |
| BAL-004 | Baseline operativa | Curva B08 lineare e configurabile: soglia livello 1 pari a 10 XP, crescita di 5 XP per livello (`10, 15, 20, …`) | La slice raggiunge presto i primi level-up; il bilanciamento può cambiare nel `.tres` senza modificare il codice |
| BAL-005 | Baseline operativa | I cap provvisori B12 sono `×2` velocità, `×3` raggio pickup, `×3` frequenza e `×5` danno; un aumento di frequenza non riscrive il cooldown già iniziato, ma determina l'intervallo dal colpo successivo | I fallback restano consumabili senza crescita illimitata; i cap sono proprietà esportate della scena e potranno essere ribilanciati senza cambiare la composizione degli effetti |
| BAL-006 | Baseline operativa | Profili B13: Ansia `velocità ×1,35`, `vita massima ×0,80`, vignetta `0,42`; Gossip 2 salti entro `260`, falloff `0,65`; Ritardo `12 s / ×0,50 / 3 s`; Birra `frequenza ×1,25`, ampiezza `18`, `3 Hz`; shockwave raggio `220`, knockback `420` per `0,2 s` | Tutti i valori restano nei cinque `.tres`; il playtest può ribilanciarli senza cambiare codice o contratti di cleanup |

## Decisioni di sconfitta e restart

| ID | Stato | Decisione | Conseguenza |
|---|---|---|---|
| RUN-001 | Baseline operativa | La morte del Player richiede `DEFEAT`; `RunController` blocca il terminale e l'`EndScreen` always-process espone `RIPROVA` a mouse, tastiera, controller e touch | Danno, clock, spawn e movimento restano fermi mentre l'UI continua a ricevere input |
| RUN-002 | Baseline operativa | Il restart avviene in-place solo da uno stato terminale e ripristina vita massima base, HP, i-frame, input, posizione, seed, scheduler, targeting, nemici e proiettili | Due run consecutive non condividono nodi, cooldown o timer; non serve ricaricare la scena per B06 |
| RUN-003 | Baseline operativa | La morte atomica del Boss accredita una sola volta la ricompensa XP e richiede `VICTORY`, che ha priorità su eventuali level-up generati dalla ricompensa; `NUOVA RUN` riusa lo stesso restart in-place di `DEFEAT` | Il terminale mostra Boss, tempo e ricompensa senza lasciare un'offerta sopra la vittoria; cinque cicli vittoria/restart non condividono XP, offerte, cooldown, effetti o entità |

## Decisioni sulle abilità attive

| ID | Stato | Decisione | Conseguenza |
|---|---|---|---|
| ABIL-001 | Confermata | Ogni personaggio possiede un'abilità attiva distinta dagli upgrade e complementare allo sparo automatico | L'MVP deve validare input, cooldown, HUD e runtime dell'abilità, non soltanto catalogarne i dati |
| ABIL-002 | Confermata | B09A implementa il framework e l'Onda d'Urto Tellurica di Magno dopo B09; B17A completa le altre sette abilità | B07–B09 restano focalizzati sulla progressione; la prima release contiene il catalogo completo sul framework già verificato |
| ABIL-003 | Baseline operativa | Cooldown ed effetti avanzano solo in `RUNNING`; richieste rifiutate non consumano cooldown e il restart elimina ogni stato o entità dell'abilità | Pausa, level-up, lifecycle e due run consecutive sono gate obbligatori per B09A e B17A |
| ABIL-004 | Baseline operativa | L'Onda d'Urto Tellurica usa il profilo PRD: cooldown 8 s, raggio 220 unità mondo, 20 danni, knockback 300 per 0,2 s | I valori vivono nel `Resource`; risoluzione e DPI non modificano la distanza gameplay, mentre il bilanciamento resta regolabile senza codice |
| ABIL-005 | Baseline operativa | `InputRouter` espone una sola intenzione `active_ability` da Space, face button sud o pulsante touch; `AbilityController` valida stato/cooldown e delega `effect_id` al registry scene-local | Una pressione held produce una sola richiesta; HUD ed effetti non applicano direttamente regole di attivazione e il restart elimina le connessioni/entità della run |
| ABIL-006 | Baseline operativa | Powerslide di Bea fotografa `Player.get_last_movement_direction()` all'attivazione, teletrasporta in linea retta per `320` unità logiche e lascia la scia per `4 s`; il joystick successivo non modifica il percorso | La posizione viene clampata all'arena, la direzione vettoriale è distinta dal flip orizzontale del Player, teletrasporto e tick avanzano soltanto in `RUNNING`, mentre morte, cambio profilo e restart ripuliscono l'effetto |
| ABIL-007 | Baseline operativa | Gran Piroetta di Alea usa `FOLLOWING_PULSE_DAMAGE`: l'area resta centrata sulla posizione corrente del Player per tutti gli `1,2 s` e i tick colpiscono attorno alla nuova posizione | Pausa congela posizione, durata e tick; termine, restart e cambio profilo rimuovono l'effetto senza alterare le aree statiche di altre abilità |
| ABIL-008 | Baseline operativa | Tempesta di Fulmini di Zat usa al rank 1 cooldown `60 s`, preavviso `0,45 s` e un solo impatto su tutti i nemici vivi: `50%` degli HP massimi ai normali e `20%` ai Boss. Il flash fullscreen ha alpha massimo `0,55` Windows/`0,40` Android; **Flash ridotti** usa `0,15` senza fase di tenuta | I bersagli entrati prima dell'impatto sono inclusi e ciascuno viene processato una volta; il singolo pulse resta leggibile senza strobing, non cambia danno in modalità ridotta e viene congelato o ripulito dai normali gate lifecycle |
| ABIL-009 | Baseline operativa | Le otto attive partono al rank `1` e hanno snapshot dichiarativi completi fino al rank `5`; il level-up offre soltanto il prossimo rank dell'attiva equipaggiata, una volta per offerta, e la esclude al cap | Gli effetti e cooldown in corso conservano lo snapshot di attivazione; Cosplay risolve un rank copiato limitato senza trasferire progressione e restart/cambio profilo riportano ogni attiva al rank iniziale |
| ROSTER-001 | Confermata | B17A include il roster giocabile completo: selezione pre-run degli otto amici, ritratto, passiva runtime e abilità propria | Il criterio non è più il solo catalogo di sette attive; ogni `FriendDefinition` deve produrre un Player meccanicamente distinto e verificabile |
| ROSTER-002 | Baseline operativa | La selezione avviene in `BOOT`; restart rapido conserva il profilo e “Cambia personaggio” da un terminale ripulisce la run e riapre il selettore | Clock, spawn e input gameplay non avanzano dietro il selettore; nessun cooldown, status, area o clone attraversa il cambio profilo |
| ROSTER-003 | Baseline operativa | Le passive hanno ID e parametri nei `FriendDefinition`, usano il solo clock `RUNNING` e si compongono moltiplicativamente con gli upgrade | B17A testa gli otto profili, la combinazione con almeno un upgrade e due run consecutive senza stato residuo |
| BAL-008 | Baseline operativa | Passive B17A: Magno movimento `×1,15`; Bea evasione `15%`; Zat recupera `35%` dopo `3 s` in `4 s`; Alea `12 s / 5 s / 75% / ×1,20 o ×0,90`; Aleo danno `-15%`; Lollo movimento `×1,10` e fuoco `×1,15`; Migi danno `-10%`, soglia `35%`, scudo un colpo `4 s / 20 s`; Marghe nemici base HP `×0,95`, Boss esclusi | I valori sono nei `FriendDefinition`; Aleo conserva anche resistenza knockback `×0,50`, applicabile quando il combattimento introduce una sorgente di spostamento del Player |

## Decisioni Game Director e Boss

| ID | Stato | Decisione | Conseguenza |
|---|---|---|---|
| DIR-001 | Baseline operativa | `GameDirectorProfile` è l'autorità scene-local sul profilo di spawn ordinario e sulle soglie Boss positive, finite, ordinate e uniche; la vertical slice usa una sola soglia a 240 secondi di clock logico della run | Spawn e calendario restano configurabili da `.tres`; secondi reali, risoluzione, DPI e pause non cambiano la soglia `04:00` |
| DIR-002 | Baseline operativa | `GameDirector` accoda una sola volta ogni soglia attraversata e mantiene al massimo un evento Boss richiesto o registrato come vivo; l'uscita del Boss sblocca il successivo, mentre restart elimina Boss tracciato, coda, lock e soglie consumate | Salti di clock non perdono eventi, un Boss vivo impedisce duplicati e due run consecutive non condividono stato dello scheduler; `BossEncounter` implementa intro, UI e istanziazione senza trasferire queste responsabilità al Director |
| BOSS-001 | Baseline operativa | `BossDefinition` contiene identità, statistiche, ricompensa, cadenza, due pattern e colori; `BossEncounter` consuma l'evento del Director, crea il Boss nel playfield, lo registra nel targeting e governa intro e cleanup | Il Boss resta contenuto sostituibile senza codice; una citazione con `quote_approved=false` viene sostituita obbligatoriamente dal placeholder sicuro nella UI |
| BOSS-002 | Baseline operativa | Il primo Boss alterna raffica radiale e area mirata, entrambe telegrafate e avanzate soltanto in `RUNNING`; le ondate ordinarie continuano durante lo scontro | Intro, pausa, level-up e terminali non consumano i telegraph; Boss e nemici base condividono hurtbox, salute e targeting senza percorsi speciali nell'arma |
| BOSS-003 | Confermata | Ogni amico possiede una controparte Boss denominata `Evil <Nome>`; la vertical slice seleziona Evil Bea come primo incontro dati | Gli otto nomi Evil vivono nei profili B17; futuri Boss possono riusare identità e ritratto sostituendo il `friend_profile`, senza ramificazioni nel codice |
| BAL-007 | Baseline operativa | Profilo Boss B15–B16: soglia `04:00`, `2400 HP`, velocità `85`, contatto `25`, ricompensa `50 XP`; raffica `12` proiettili (`0,75 s`, danno `14`, velocità `270`) e area mirata (`1 s`, raggio `115`, danno `26`) | Raggi e velocità sono unità logiche mondo, non pixel fisici; a danno base `40 DPS`, 2400 HP aggiungono circa 60 s teorici e collocano la vittoria attorno a `05:00`, prima del playtest con upgrade |

## Decisioni sui contenuti

| ID | Stato | Decisione | Conseguenza |
|---|---|---|---|
| CONTENT-001 | Confermata | Il proprietario approva nomi, ruoli, passive, attive e titoli correnti degli otto amici in data 17 agosto 2026 | La conferma è registrata in ogni `FriendDefinition` e in `content-approvals.md`; citazioni e audio non forniti non vengono inventati |
| CONTENT-002 | Baseline operativa | `FriendDefinition` separa copy, ID abilità, controparte Evil, asset e record di approvazione; `FriendRegistry` rifiuta identità ambigue e la scena usa soltanto getter pubblici con fallback | Testi e ritratti possono essere sostituiti nei `.tres`; rimuovere un'approvazione nasconde il contenuto, mentre un flag senza autore/data/riferimento invalida il catalogo |
| CONTENT-003 | Confermata | L'attiva di Marghe diventa `Reggeton time!`, con un clone ballerino a tema reggaeton | Il retheme modifica titolo, copy e VFX ma mantiene gli ID tecnici, il cooldown di `13 s`, la durata di `3 s`, la deviazione dell'aggro e il cleanup B17A |
| ASSET-001 | Baseline operativa | B17 usa come placeholder il foglio top-down 32×32 di Eldiran, CC0 1.0, conservando sorgente, derivato trasparente, licenza e SHA-256 | Sedici ritagli hero/Evil sono distribuibili anche in progetti privati; B18 può sostituirli senza modificare codice o contratti gameplay |
| ASSET-002 | Baseline operativa | B18 usa pittogrammi SVG originali per le otto attive e le famiglie di upgrade; i quattordici cue provengono dai pacchetti Kenney Interface Sounds, Impact Sounds e Music Jingles, tutti CC0 1.0, con licenze, mapping e SHA-256 conservati | Nessuna icona gameplay usa più il logo generico; il subset audio è ridotto ai soli file runtime e resta redistribuibile su Windows e Android |
| ASSET-003 | Baseline operativa | B18D sostituisce l'icona provvisoria di Bea con `inline_skate.svg` della libreria Pinhead `v15.17.0`, CC0 1.0, conservando originale, derivato runtime, sorgente, licenza e SHA-256 | Powerslide usa un pittogramma esplicito e redistribuibile; la cornice e la palette del derivato restano coerenti con le altre icone abilità |
| ASSET-004 | Baseline operativa | B18H produce internamente due piccioni originali su canvas trasparente `48×48`: base grigio-blu con collo verde/viola e speciale antracite con collare magenta e accenti oro; posa neutra e due fasi d'ala condividono silhouette e bordo scuro | Il base sostituisce la sfera ordinaria senza cambiare fisica o spawn; lo speciale resta disponibile per fixture e profili futuri ma non introduce oggi una variante gameplay o una dipendenza di licenza esterna |
| AUDIO-001 | Baseline operativa | `GameAudio` è scene-local, ascolta segnali atomici, usa un pool di dodici `AudioStreamPlayer` sul bus `SFX` e persiste volume lineare più mute in `user://audio_settings.cfg` | Sparo e hit sono rate-limited solo nella presentazione, senza cambiare cadenze o danni; pausa e terminali possono completare i cue perché il mixer usa `PROCESS_MODE_ALWAYS` |
| AUDIO-002 | Baseline operativa | Con il display driver `headless`, `GameAudio` valida stream, mute, rate-limit e segnali senza istanziare playback OGG; Windows e Android continuano a usare il pool reale | Gli smoke non lasciano playback o risorse audio pendenti allo shutdown e non fingono una verifica percettiva che il driver headless non può eseguire |
| VISUAL-001 | Baseline operativa | I VFX alleati usano riempimenti traslucidi e pattern geometrici a `z_index=0`; nemici/telegraph, Player e proiettili salgono rispettivamente a `2`, `4`, `6`, mentre i proiettili Boss restano a `10` | Un'area persistente non può nascondere attori o attacchi ostili; forma e priorità di rendering mantengono leggibile il pericolo anche senza affidarsi soltanto al colore |
| VISUAL-002 | Baseline operativa | B18B sostituisce griglia e bordo ciano con variazioni tonali, giunti, macchie e crepe procedurali; `CombatFeedback` a `z_index=3` disegna hit spark, anelli e particelle di morte, mentre Player/nemici applicano flash `0,075–0,08 s` e squash solo nel draw | Il polish non modifica transform fisici, collisioni, danno o cooldown; il feedback si pulisce al restart e resta sotto Player e proiettili prioritari |
| VISUAL-003 | Baseline operativa | B18C usa per ogni `FriendDefinition` una posa laterale destra e quattro fasi di camminata; dove il foglio CC0 offre più ritagli li alterna, mentre Lollo, Migi e Marghe animano l'unica posa valida con bob/inclinazione. Il Player ribalta gli sprite per la sinistra, non disegna più corpo circolare o cannoncino e conserva separatamente lato orizzontale e vettore dell'ultimo movimento | Il neutro e il movimento verticale non cancellano il vettore; pausa e focus azzerano il movimento senza cambiarlo, una nuova run riparte verso destra e le abilità scelgono il getter coerente con la propria direzione |
| VISUAL-004 | Baseline operativa | B18M conserva le otto icone correnti e produce i VFX di release con primitive Godot, shader semplici e asset originali del progetto; ogni abilità ha il linguaggio visivo elencato nel piano e ogni file nuovo entra in un manifest con origine, autore, licenza, modifiche e SHA-256 | Nessun pacchetto animato o prompt generativo blocca l'implementazione; gli effetti alleati restano sotto i pericoli e rispettano per attivazione il budget Android di un overlay fullscreen, 64 particelle e due draw call/materiali aggiuntivi per famiglia |

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

La vertical slice ha ora una durata e valori Boss di baseline; restano aperti la loro conferma tramite playtest a parametri finali e il bilanciamento definitivo di curva XP, danno e cap degli upgrade. La regola di stacking è chiusa da PROG-006.
Tutti i punti di refinement B18C–B18M che modificano l'implementazione sono chiusi;
restano soltanto implementazione e gate di verifica indicati nel piano di sviluppo.
