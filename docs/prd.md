# Documento di Requisiti di Progetto (PDR)

**Nome ufficiale:** Pidgeon Survivor

**Sottotitolo ufficiale:** It's grilling time!
**Genere:** Action 2D / Bullet Heaven / Arena Survival minimale  
**Piattaforme:** Windows x64 e Android ARM64; Web browser come target secondario  
**Engine:** Godot Engine 4.7.1 con GDScript

## 1. Visione generale del progetto

Il gioco è un action survival 2D minimale in stile Bullet Heaven, ambientato in
un'unica arena a schermata fissa o con camera chiusa. Il giocatore controlla un
personaggio che si muove nell'arena, schiva i nemici e spara automaticamente.

L'elemento distintivo è l'integrazione satirica di citazioni, tormentoni e tratti
caratteriali degli amici del creatore. Questi elementi definiscono personaggi,
potenziamenti, abilità attive e Boss.

Ogni personaggio giocabile possiede una propria abilità attiva, complementare
agli attacchi automatici e distinta dalle carte potenziamento ottenute salendo
di livello.

## 2. Core game loop

1. Il giocatore si muove nell'arena e schiva le ondate di nemici.
2. Il personaggio spara ciclicamente al nemico vivo più vicino.
3. Il giocatore usa manualmente l'abilità attiva del personaggio quando è pronta.
4. I nemici sconfitti lasciano cadere “Caffè” o “Gocce di Pressione”, che
   forniscono punti esperienza.
5. Al riempimento della barra XP, il gioco va in pausa e mostra tre carte
   potenziamento casuali basate sulle citazioni degli amici.
6. Ogni `N` minuti appare un Boss, versione caricaturale di un amico, con pattern
   d'attacco unici e una citazione a tutto schermo.

## 3. Logiche di funzionamento e architettura tecnica

### 3.1. Giocatore (Player)

**Input:** movimento a otto direzioni tramite tastiera, controller o joystick
virtuale; azione dedicata `active_ability` tramite tastiera, controller o
pulsante touch.

**Attributi principali:**

- `health_max` / `health_current`;
- `move_speed`;
- `attack_rate` (secondi fra un attacco automatico e il successivo);
- `damage_multiplier`;
- `pickup_radius` (area di raccolta automatica XP);
- `active_ability_id`.

**Logica di sparo automatico:**

1. Ogni `attack_rate` secondi individua i nodi vivi nel gruppo `Enemies`.
2. Calcola la distanza dal Player.
3. Istanzia il proiettile orientato verso il nemico più vicino.

L'uso dell'abilità attiva non sostituisce lo sparo automatico, salvo che una
specifica abilità dichiari esplicitamente un comportamento incompatibile.

### 3.2. Nemici (Enemies) e spawner

**IA nemica minimale:** i nemici si muovono in linea retta verso le coordinate
del bersaglio corrente. Normalmente il bersaglio è il Player; abilità che
manipolano l'aggro possono sostituirlo temporaneamente.

**Enemy Spawner:**

- un timer ciclico genera nemici fuori dal campo visivo, ai bordi dell'arena;
- il tasso di spawn aumenta in base al tempo di gioco trascorso;
- la formula iniziale è
  `SpawnInterval = max(0.2, BaseInterval - (GameTime * 0.01))`.

Se un nemico muore fuori dal playfield mentre sta entrando, il relativo drop XP
viene ricondotto da `ArenaLayout` dentro l'arena. Il clamp include il raggio di
raccolta del pickup, espresso in unità logiche del mondo, così l'oggetto resta
interamente visibile e raggiungibile su ogni aspect ratio.

### 3.3. Sistema di level up e upgrade (Carte Amici)

Le definizioni dei potenziamenti sono dati e contengono almeno:

- `id`: identificativo univoco;
- `title`: nome o citazione dell'amico;
- `description`: effetto mostrato al giocatore;
- `effect_id` e parametri: effetto applicato dal codice al Player o alle armi.

Al level up il sistema estrae tre elementi casuali non duplicati dalla lista e
mostra la UI di pausa. Le carte potenziamento non sostituiscono e non
determinano l'abilità attiva propria del personaggio.

`Grigliata estiva` è una carta comune a cinque rank. Ogni rank moltiplica gli
HP massimi per `×1,15`, fino al contributo cumulativo `×2,0113571875` e con cap
dati `×2,05`. Quando il massimo cresce, il Player recupera immediatamente
esattamente la differenza positiva fra nuovo e vecchio massimo; non viene
preservata la percentuale di vita e un Player morto non viene resuscitato.
L'effetto si compone moltiplicativamente con passive e altri upgrade e si azzera
con restart o cambio personaggio.

### 3.4. Sistema delle abilità attive

Ogni personaggio ha una sola abilità attiva assegnata dalla propria definizione.
L'abilità può essere eseguita soltanto durante lo stato di gioco attivo, quando
il suo cooldown è terminato e i requisiti specifici sono validi. Un'attivazione
accettata avvia il cooldown; una richiesta rifiutata non lo consuma.

Cooldown, durata ed effetti periodici avanzano sul tempo di gameplay e restano
fermi durante level up, pausa, introduzione del Boss e schermate finali. Il
sistema emette lo stato di disponibilità e il tempo residuo per l'HUD, senza
consentire alla UI di applicare direttamente gli effetti di gameplay.

Le abilità sono `Resource` versionabili in `res://data/abilities/`. Ogni
definizione contiene almeno:

- `id` (stringa);
- `title`;
- `description`;
- `cooldown_seconds` (float);
- `duration_seconds` (float, opzionale);
- `area_radius` (unità logiche del mondo, opzionale);
- `damage` (valore o formula, opzionale);
- `effects` (lista di `effect_id` e relativi parametri);
- `tags` (filtri e compatibilità).

Parametri specifici come distanza del dash, forza di knockback e intervallo dei
tick restano nella definizione dell'abilità. La logica GDScript interpreta gli
`effect_id`; i file dati non contengono funzioni eseguibili.

Un registro `abilities_registry` espone le definizioni valide a runtime. Il
registro permette di risolvere gli ID, creare gli effetti e filtrare le abilità
in base ai tag di compatibilità, in particolare per gli effetti di copia.

#### Magno — Onda d'Urto Tellurica

- **Tipo:** area radiale.
- **Effetto:** infligge danno e knockback ai nemici nel raggio.
- **Parametri iniziali:** `cooldown_seconds: 8.0`, `area_radius: 220`,
  `damage: 20`, `knockback_force: 300`, `stun_duration: 0.2` opzionale.
- **Nota tecnica:** applicare separatamente danno e forza radiale; i layer di
  collisione devono escludere gli oggetti statici.

#### Bea — Powerslide

- **Tipo:** teletrasporto direzionale con area persistente.
- **Effetto:** fotografa l'ultimo vettore di movimento non nullo del Player,
  lo teletrasporta in linea retta e lascia una traccia di fuoco che infligge
  danno periodico ai nemici lungo il percorso.
- **Parametri iniziali:** `cooldown_seconds: 10.0`, `dash_distance: 320`,
  `trail_duration: 4.0`, `trail_tick_interval: 0.25`, `tick_damage: 6`.
- **Nota tecnica:** la distanza è un'unità logica del mondo Godot, non pixel
  fisici. Il vettore di movimento è distinto dal lato orizzontale usato per
  l'animazione; la posizione del joystick dopo l'attivazione non modifica il
  percorso. Pausa e stati non `RUNNING` congelano scia e cooldown.

#### Zat — Tempesta di Tuoni

- **Tipo:** danno globale percentuale con impatto ritardato.
- **Effetto:** dopo un preavviso di `0,45 s`, un singolo tuono produce un
  flash sull'intero viewport logico e colpisce una volta tutti i nemici vivi
  validi al momento dell'impatto, inclusi quelli entrati dopo l'attivazione.
- **Parametri iniziali:** `cooldown_seconds: 60.0`,
  `normal_max_health_damage_ratio: 0.50`,
  `boss_max_health_damage_ratio: 0.20`, `warning_seconds: 0.45`.
- **Accessibilità:** flash singolo con alpha massimo `0,55` su Windows e `0,40`
  su Android, chiuso entro `0,30 s`; l'opzione persistente **Flash ridotti** usa
  alpha `0,15`, nessuna tenuta e conserva preavviso, onde, audio e danno.
- **Nota tecnica:** bersagli e danno sono risolti all'impatto. Cooldown,
  preavviso e flash avanzano soltanto in `RUNNING`; pausa, morte, cambio profilo
  e restart non producono impatti tardivi o overlay residui.

#### Alea — Gran Piroetta

- **Tipo:** attacco melee rotante.
- **Effetto:** colpisce ripetutamente i nemici attorno al personaggio per tutta
  la durata.
- **Parametri iniziali:** `cooldown_seconds: 9.0`, `duration_seconds: 1.2`,
  `damage_per_hit: 5`, `hits_per_second: 12`, `area_radius: 140`.
- **Nota tecnica:** l'area si ricentra sulla posizione corrente del Player per
  tutta la durata e applica il danno con aggiornamenti periodici; pausa e stati
  non `RUNNING` congelano posizione, durata e tick.

#### Aleo — Colata di Cemento

- **Tipo:** area di controllo sul terreno.
- **Effetto:** rallenta i nemici e infligge danno nel tempo.
- **Parametri iniziali:** `cooldown_seconds: 12.0`, `area_radius: 200`,
  `duration_seconds: 4.0`, `slow_factor: 0.5`, `dot_tick: 0.5`,
  `dot_damage: 3`.

#### Lollo — Cosplay Casuale

- **Tipo:** copia di un'altra abilità attiva.
- **Effetto:** attiva l'abilità di un altro personaggio scelto casualmente.
- **Parametri iniziali:** `cooldown_seconds: 14.0`.
- **Nota tecnica:** interrogare `abilities_registry` ed escludere Cosplay
  Casuale e qualsiasi abilità i cui tag o requisiti non siano compatibili con il
  personaggio e con la scena corrente.

#### Migi — Rallentamento Zen

- **Tipo:** area di controllo attorno al personaggio.
- **Effetto:** rallenta i nemici presenti nell'area.
- **Parametri iniziali:** `cooldown_seconds: 11.0`, `area_radius: 260`,
  `duration_seconds: 3.5`, `slow_factor: 0.4`.

#### Marghe — Reggeton time!

- **Tipo:** esca illusoria a tema reggaeton.
- **Effetto:** genera un clone che balla reggaeton e attira temporaneamente
  l'aggro dei nemici.
- **Parametri iniziali:** `cooldown_seconds: 13.0`, `duration_seconds: 3.0`,
  `illusion_lifetime_on_death: true`.
- **Nota tecnica:** definire raggio e priorità dell'aggro e rendere configurabile
  se il clone sia invulnerabile o possa essere distrutto prima della scadenza.

I valori numerici sono una baseline di bilanciamento e devono poter essere
modificati nei `Resource` senza cambiare il codice.

#### Rank delle abilità attive

Ogni personaggio inizia la run con la propria attiva al rank `1`. Il level-up
può offrire soltanto i rank `2–5` dell'abilità equipaggiata; usa un solo ID per
offerta, esclude i duplicati e rimuove la carta al cap. Ogni rank è uno snapshot
completo nei dati: effetti e cooldown già avviati conservano lo snapshot
dell'attivazione, mentre il nuovo rank vale dall'uso successivo. Restart e
cambio personaggio riportano l'attiva al rank `1`.

I valori completi e cumulativi sono la tabella B18G del piano di sviluppo. Le
progressioni sono: danno/raggio/knockback per Magno; danno/distanza/scia per Bea;
percentuali e cooldown per Zat; danno/durata/raggio/frequenza per Alea;
danno/durata/raggio/slow per Aleo; rank copiato, cooldown e anti-ripetizione per
Lollo; durata/raggio/slow per Migi; durata e cooldown del clone per Marghe.
Cosplay non trasferisce rank: risolve temporaneamente il profilo copiato al rank
`1`, `2` o `3` previsto dal proprio rank, con filtri anti-ricorsione e di
compatibilità invariati.

### 3.5. Boss, vittoria e chiusura della run

Il primo Boss viene richiesto dal `GameDirector` a `04:00` di clock logico e
convive con le ondate ordinarie. L'introduzione porta la run in `BOSS_INTRO`,
ferma clock e gameplay e mostra nella safe area nome, barra HP e una citazione.
Una citazione personale non approvata non viene mai mostrata: la UI usa il
placeholder sicuro dichiarato nel `BossDefinition`.

La vertical slice alterna due pattern leggibili e schivabili: una raffica
radiale preceduta da raggi di avviso e un'esplosione sull'ultima posizione
marcata del Player. Durate, danni, velocità, numero di proiettili e raggi sono
parametri dati; raggi e velocità sono unità logiche del mondo Godot, non pixel
fisici del display.

La morte atomica del Boss assegna una sola ricompensa XP e richiede `VICTORY`,
che blocca clock, danni, spawn e progressione. La schermata finale mostra Boss,
tempo e ricompensa e consente una nuova run in-place. Il restart elimina Boss,
proiettili, offerte, XP, cooldown ed effetti appartenenti alla run precedente.

### 3.5A. Evoluzioni post-release: Boss Evil e Difesa Grigliata

Dopo la release B20, il Boss di riferimento diventa il piccione speciale B18H.
B22 aggiunge una sostituzione configurabile, con probabilità iniziale `25%` e
scelta deterministica dal seed della run: al posto del piccione speciale può
apparire un `Evil <Nome>` estratto casualmente dagli otto profili. In questa
prima versione Evil riusa lo sprite del relativo Player con palette viola scura
e accenti magenta ad alto contrasto; mantiene statistiche, hitbox e i due
pattern del piccione Boss. Le abilità del personaggio non sono ancora disponibili
ai Boss Evil e richiedono una successiva slice dati/comportamentale.

B23 introduce una seconda modalità, **Difesa Grigliata**, accanto alla
Sopravvivenza attuale. La modalità mette al centro del playfield una griglia con
carne, con salute configurabile e HUD proprio; i nemici possono selezionarla e
danneggiarla. La run termina in `DEFEAT` se la vita del Player o della griglia
raggiunge zero. La modalità eredita per la prima versione progressione, pausa,
lifecycle, Boss a `04:00` e vittoria dopo il Boss, ma conserva stato, seed,
cleanup e target selection separati per evitare residui tra modalità e restart.
La selezione della modalità resta in `BOOT`, integrata nel flusso di conferma
del profilo e non avvia mai una run da sola.

### 3.6. Catalogo amici e controparti Evil

Gli otto profili approvati sono Magno, Bea, Zat, Alea, Aleo, Lollo, Migi e
Marghe. Ogni profilo dichiara in un `FriendDefinition` identità, ruolo, passiva,
parametri runtime della passiva, attiva, ID abilità, ritratto sostituibile e la
controparte Boss denominata `Evil <Nome>`. Il Player della vertical slice M4 è
Magno; B17A rende selezionabili e giocabili tutti gli otto profili prima della
run. Il primo incontro Boss continua a usare Evil Bea.

Una welcome screen precede la selezione e non inizializza alcuna run. `GIOCA`
apre il selettore, mentre le impostazioni restano raggiungibili sia da questa
schermata sia dalla pausa; volume effetti, mute e Flash ridotti usano le stesse
autorità persistenti nei due frontend. Back chiude prima le impostazioni e dal
selettore riapre la welcome. La selezione resta in `BOOT`: nessun clock, spawn o
input di gameplay avanza finché il giocatore non conferma un profilo. La
selezione usa un carosello ciclico di otto profili con personaggio centrale e
due mini-card adiacenti complete. Frecce, click, tastiera, D-pad/stick e swipe cambiano lo
stesso indice senza confermare; la run parte soltanto dal CTA dedicato. Le pose
idle del carosello sono derivati `256×256` delle sorgenti HD del cast, mentre i
master `1536×1024` restano esclusi dagli export.

Il raffinamento B18W usa un fondale notturno incorniciato, Back separato in alto
a sinistra, card squadrate, frecce metalliche/oro, card centrale dominante e un
kit laterale compatto per passiva e abilità, entrambe con icona e titolo dorato.
Ogni profilo usa una propria icona passiva raster `128×128` derivata da un master
RGBA escluso dagli export; prompt, sorgente, trasformazione e hash sono nel
manifest delle passive.
Il sottotitolo istruttivo è rimosso e `KIT DI <NOME>` collega esplicitamente il
pannello al profilo. Nome e ruolo formano un blocco compatto immediatamente
sotto il carosello e il CTA segue senza vuoti verticali. In basso rimane un solo CTA ornamentale compatto: la base ImageGen non
contiene testo e Godot sovrappone dinamicamente `Gioca con <Nome>`, con
maiuscola naturale. Il CTA non può coprire la cornice e non modifica le regole
di navigazione o conferma del carosello.

La
presentazione iniziale usa un fondale pixel-art con otto archetipi fittizi che
comunicano passive e abilità, più piccioni ai bordi e centro protetto senza UI
incorporata. Il logo fornito dal proprietario e i pulsanti Godot ad alto
contrasto restano elementi separati e responsive; entrando nelle impostazioni
il logo scompare per non coprire i personaggi. Questo
asset frontend resta distinto dallo sfondo arena B18S. Il profilo
scelto assegna ritratto, passiva e abilità; un restart rapido conserva la scelta,
mentre l'azione “Cambia personaggio” da vittoria, sconfitta o menu di pausa torna
alla selezione dopo aver ripulito la run. Da una run attiva la scelta richiede
conferma; annullarla mantiene la pausa e non riprende implicitamente. Passive e
upgrade si compongono senza mutare i dati base.

Baseline iniziali delle passive, tutte configurabili nei `.tres`:

| Profilo | Parametri runtime B17A |
|---|---|
| Magno | velocità di movimento `×1,15` |
| Bea | probabilità di evasione `15%` |
| Zat | `35%` del danno recuperabile dopo `3 s`, recupero in `4 s` |
| Alea | effetto ogni `12 s` per `5 s`; `75%` positivo (`×1,20`) e `25%` negativo (`×0,90`) su movimento o fuoco |
| Aleo | riduzione danno `15%`; resistenza knockback `×0,50` quando una sorgente applica spostamento al Player |
| Lollo | movimento `×1,10`, frequenza di fuoco `×1,15` |
| Migi | riduzione danno `10%`; sotto `35%` HP scudo da un colpo per `4 s`, cooldown `20 s` |
| Marghe | salute massima dei nemici base `×0,95`; Boss esclusi dalla baseline |

Il `FriendRegistry` rifiuta ID amico, ID abilità e nomi Evil ambigui. Copy e
ritratti vengono esposti attraverso getter sicuri: se manca l'approvazione
ritornano fallback neutri. L'approvazione richiede approvatore, data ISO e
riferimento; gli stati correnti sono registrati in `content-approvals.md`.

I ritratti B17 sono placeholder top-down CC0 ritagliati da un atlas. Possono
essere sostituiti nei `.tres` senza cambiare codice. Citazioni personali e audio
non forniti non vengono inventati e restano rispettivamente sul placeholder
neutro o silenziosi.

Gli sprite gameplay B18U sono invece otto strisce originali ImageGen `96×32`,
una per profilo, derivate dalla direzione visuale approvata nella welcome B18O.
Ogni striscia contiene passo A, idle e passo B su celle `32×32`; il Player usa
nearest-neighbor, alterna quattro fasi di camminata e conserva facing e ultima
direzione B18C. Le sorgenti trasparenti `1536×1024` sono conservate per riuso
artistico ma escluse da import ed export. La sostituzione non modifica origine,
scala, hitbox, velocità, collisioni, passive, abilità o timing gameplay.

## 4. Idee per i potenziamenti (Citazioni e Amici)

### “L'Ansia”

Effetto: `+35%` velocità di movimento e `-20%` vita massima. Applica un leggero
effetto di vignettatura scura ai bordi dello schermo.

### “Gossip”

Effetto: quando un proiettile colpisce un nemico può saltare a un altro bersaglio
vivo vicino, applicando un danno progressivamente ridotto a ogni salto.

### “Ritardo Cronico”

Effetto: ogni 12 secondi rallenta tutti i nemici a schermo del `50%` per tre
secondi.

### “Birra”

Effetto: aumenta la frequenza di sparo del `25%`, ma rende la traiettoria dei
proiettili leggermente oscillante.

### “Non Ho Tempo Per Questo”

Effetto: quando il Player subisce danno, crea un'onda d'urto che respinge tutti i
nemici vicini.

## 5. Interfaccia utente ed estetica

**HUD in-game:**

- barra dell'esperienza a tutta larghezza in alto, più corposa e arrotondata,
  senza numeri e con il solo tag fisso `XP` a sinistra;
- barra della vita a tutta larghezza subito sotto, senza ritratto Player,
  livello o numeri, più corposa e arrotondata, con il solo tag fisso `HP` a
  sinistra;
- pulsante pausa flottante a destra nella fascia delle barre, senza interrompere
  la loro larghezza visiva;
- solo cronometro leggermente ingrandito, centrato e trasparente sotto le due
  barre, senza label `Tempo` né sfondo;
- icona dell'abilità attiva come unico controllo visivo touch, separata dal
  joystick e posizionata nella safe area;
- indicatore radiale leggibile del cooldown residuo e feedback visivo/sonoro
  quando l'abilità torna disponibile.

La baseline B18K del pulsante touch coincide con l'icona dell'abilità equipaggiata
e misura `64×64` unità logiche. B18P espone tre taglie persistenti e indipendenti:
abilità `100/125/150%`, con default `80×80` e icona `53`, e joystick
`85/100/115%`, con default invariato al `100%`. Icona e hit target crescono
insieme; i valori esterni all'intervallo o intermedi vengono normalizzati alla
taglia sicura più vicina. Durante il cooldown una
maschera radiale rappresenta la
frazione residua e mostra al centro i secondi interi arrotondati per eccesso;
allo zero maschera e numero spariscono e un anello luminoso comunica che
l'icona è nuovamente attivabile. Nome, label di stato, card e rettangolo del
pulsante non vengono disegnati: fuori dal cooldown resta visibile soltanto
l'icona. Il feedback osserva lo stesso clock gameplay di `AbilityController`:
pausa, level up, Boss intro e terminali non consumano tempo, mentre il restart
riparte senza residui.

**Schermata level up:** pausa totale del gameplay con overlay scuro e tre
riquadri selezionabili con mouse, tastiera, controller o touch.

**Stile visivo:** 2D minimale, con pixel art o forme geometriche pulite e colori
ad alto contrasto per un prototipo rapido. Area, direzione e durata delle abilità
devono essere leggibili anche durante le ondate più dense.
Le aree e i VFX alleati sono renderizzati sotto attori e attacchi; telegraph e
proiettili ostili hanno priorità visiva e non possono essere coperti da un'abilità.
Forma, contorno e pattern affiancano sempre il colore come segnali distintivi.

Il nemico ordinario non è più una sfera: usa un piccione-uccello originale del
progetto, grigio-blu con collo verde/viola, becco arancio, bordo scuro e due fasi
d'ala su canvas trasparente `48×48`. Una variante speciale antracite, magenta e
oro con la stessa silhouette viene prodotta per fixture e profili futuri, ma non
entra nello spawn corrente e non modifica statistiche, collisioni o AI.

Le otto attive usano emblemi PNG originali, pixel-art e trasparenti, prodotti con
OpenAI ImageGen e leggibili anche nel controllo HUD da `42 px`. La stessa texture
compare in un breve burst di attivazione specifico per abilità; nome, card e
sfondo rettangolare restano assenti. I VFX di area restano originali e
principalmente procedurali: anelli/crepe per Magno, nastro e scintille per Bea,
nube/onde e flash accessibile per Zat, archi rotanti per Alea, pozza e bolle per
Aleo, confetti e palette copiata per Lollo, anelli e particelle lente per Migi,
clone/cassa/note per Marghe. Ogni asset su file viene registrato con origine,
autore, licenza, prompt, trasformazioni e SHA-256.
L'implementazione usa un solo nodo `CanvasItem` per famiglia, più il breve
accento figlio di Cosplay e un solo emblema animato, zero materiali custom e il
solo overlay fullscreen di Zat; per attivazione resta entro `64` elementi
particellari logici. Collisioni, raggi, danni, durate e cooldown non dipendono
dalla presentazione.

Il Player usa sprite laterali destra/sinistra: durante qualsiasi movimento
alterna i frame di camminata, al neutro mostra la posa ferma e conserva l'ultima
direzione orizzontale non nulla. La direzione è parte del contratto gameplay del
Player: le abilità direzionali possono usarla senza leggere la posizione
istantanea del joystick quando vengono attivate.

La presentazione B18Q sostituisce la precedente fascia compatta con XP e vita a
tutta larghezza, più corpose e arrotondate, prive di ritratto, livello e valori
numerici; i soli tag fissi `XP` e `HP` identificano le barre a sinistra. La pausa
resta un controllo flottante a destra e il solo cronometro, più grande e senza
sfondo, è centrato sotto le due barre. Il pulsante abilità B18K parte da `64×64`
unità logiche e B18P ne sostituisce il
default con una misura fisicamente più accessibile, regolabile nelle impostazioni.
Il joystick B18L non usa più
una zona fissa: il primo tocco valido nella safe area ne determina l'origine,
che resta posseduta dallo stesso dito fino a rilascio o cancellazione. HUD,
pulsante abilità, Boss UI e overlay non sono origini valide; un secondo dito
resta libero di attivare l'abilità. Deadzone e raggio input restano quelli della
baseline (`84`), mentre il disegno usa raggio `68` e sparisce al neutro. Il
profilo B18P scala insieme controllo, base visiva, manopola, deadzone assoluta e
raggio di trascinamento senza restringere l'acquisizione dinamica o bloccare il
secondo dito. Le impostazioni di welcome e pausa aggiornano il runtime senza
riavvio e persistono in `user://touch_control_settings.cfg`. Il
lock Android può esporre per pochi frame una finestra portrait anche se il gioco
è bloccato in landscape: quel layout transitorio non modifica il playfield già
stabile e non riclampa il Player mentre la run è sospesa. Dopo sblocco la run
resta in pausa fino a `RIPRENDI` e conserva posizione, direzione e input neutro.
Il playfield autorevole inizia sotto l'intera fascia HUD composta da XP, vita,
pausa e cronometro: Player, pickup, spawn, Boss, telegraph e target non possono
finire dietro l'interfaccia. Il
pavimento B18S usa uno sfondo raster originale prodotto con ImageGen, responsive
e a basso contrasto, privo di griglia, bordo ciano, testo, personaggi o falsi
ostacoli; le variazioni procedurali restano un fallback presentazionale.
Flash, squash, hit spark, particelle di morte e impulso di prontezza sono
esclusivamente presentazionali. B18R allunga le animazioni one-shot e i burst
troppo brevi per essere percepiti, ma non prolunga collisioni, danno, tick o
cooldown e non lascia apparire attiva un'area già conclusa.

**Audio:** gli eventi di combattimento, progressione, abilità, Boss e terminali
usano cue brevi su un bus SFX polifonico. Il menu di pausa offre volume lineare e
mute, applicati anche durante la pausa e persistiti in `user://audio_settings.cfg`.
Le voci personali restano separate da questi effetti generici e silenziose finché
non vengono fornite e approvate.

## 6. Roadmap di sviluppo

1. **Fondazioni del combattimento:** movimento Player, spawner nemici base,
   collisioni e sparo automatico al nemico più vicino.
2. **Loop XP:** drop degli oggetti XP, barra di livello e contatore.
3. **UI upgrade:** schermata di pausa al level up e applicazione di due o tre
   potenziamenti di prova.
4. **Sistema abilità attive:** azione multipiattaforma, cooldown sul tempo di
   gameplay, HUD, `abilities_registry` e una prima abilità completa come vertical
   slice.
5. **Roster Amici:** selezione pre-run degli otto `FriendDefinition`, passive
   parametriche e `Resource` in `res://data/abilities/` per le otto abilità;
   database definitivo di citazioni e potenziamenti, grafica, VFX e audio
   dedicati restano contenuti sostituibili.
6. **Esperienza e presentazione di release:** welcome screen, cambio personaggio
   dalla pausa, controlli touch scalabili, playfield separato dal HUD, timing
   visivi più leggibili, carosello e sfondo ImageGen; hardening B18V prima del
   packaging.

Le descrizioni narrative, i ruoli e le passive dei personaggi sono mantenuti in
[`characters.md`](./characters.md); questo documento è la fonte dei contratti e
dei parametri iniziali delle loro abilità attive.
