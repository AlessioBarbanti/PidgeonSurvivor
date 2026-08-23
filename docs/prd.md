# Documento di Requisiti di Progetto (PDR)

**Nome progetto (provvisorio):** Friendship Survival: Arena Bullet Heaven  
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

### 3.3. Sistema di level up e upgrade (Carte Amici)

Le definizioni dei potenziamenti sono dati e contengono almeno:

- `id`: identificativo univoco;
- `title`: nome o citazione dell'amico;
- `description`: effetto mostrato al giocatore;
- `effect_id` e parametri: effetto applicato dal codice al Player o alle armi.

Al level up il sistema estrae tre elementi casuali non duplicati dalla lista e
mostra la UI di pausa. Le carte potenziamento non sostituiscono e non
determinano l'abilità attiva propria del personaggio.

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

#### Bea — Scia di Fuoco Z

- **Tipo:** dash con area persistente.
- **Effetto:** esegue uno scatto e lascia una traccia che infligge danno
  periodico ai nemici che la attraversano.
- **Parametri iniziali:** `cooldown_seconds: 10.0`, `dash_distance: 320`,
  `trail_duration: 2.0`, `trail_tick_interval: 0.25`, `tick_damage: 6`.
- **Nota tecnica:** la traccia è un'area istanziata che rileva entrata e uscita
  dei nemici e applica i tick periodici.

#### Zat — Tempesta di Fulmini

- **Tipo:** danno multiplo ad area con bersagli casuali.
- **Effetto:** genera una serie di fulmini contro nemici casuali entro il raggio.
- **Parametri iniziali:** `cooldown_seconds: 12.0`, `strikes: 6`,
  `strike_damage: 8`, `strike_interval: 0.08`, `targeting_radius: 800`.
- **Nota tecnica:** sincronizzare i VFX con ogni colpo e usare il pooling per gli
  effetti se il profiling lo richiede.

#### Alea — Gran Piroetta

- **Tipo:** attacco melee rotante.
- **Effetto:** colpisce ripetutamente i nemici attorno al personaggio per tutta
  la durata.
- **Parametri iniziali:** `cooldown_seconds: 9.0`, `duration_seconds: 1.2`,
  `damage_per_hit: 5`, `hits_per_second: 12`, `area_radius: 140`.
- **Nota tecnica:** applicare il danno con aggiornamenti periodici per evitare
  controlli di collisione eccessivi.

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

### 3.6. Catalogo amici e controparti Evil

Gli otto profili approvati sono Magno, Bea, Zat, Alea, Aleo, Lollo, Migi e
Marghe. Ogni profilo dichiara in un `FriendDefinition` identità, ruolo, passiva,
parametri runtime della passiva, attiva, ID abilità, ritratto sostituibile e la
controparte Boss denominata `Evil <Nome>`. Il Player della vertical slice M4 è
Magno; B17A rende selezionabili e giocabili tutti gli otto profili prima della
run. Il primo incontro Boss continua a usare Evil Bea.

La selezione resta in `BOOT`: nessun clock, spawn o input di gameplay avanza
finché il giocatore non conferma un profilo. Il profilo scelto assegna ritratto,
passiva e abilità; un restart rapido conserva la scelta, mentre l'azione
“Cambia personaggio” da vittoria o sconfitta torna alla selezione dopo aver
ripulito la run. Passive e upgrade si compongono senza mutare i dati base.

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

- barra della vita in alto a sinistra;
- barra dell'esperienza in alto, a tutta larghezza;
- timer di gioco in alto al centro;
- icona e nome dell'abilità attiva;
- indicatore leggibile del cooldown residuo e feedback visivo/sonoro quando
  l'abilità torna disponibile;
- pulsante dell'abilità attiva su dispositivi touch, separato dal joystick e
  posizionato nella safe area.

**Schermata level up:** pausa totale del gameplay con overlay scuro e tre
riquadri selezionabili con mouse, tastiera, controller o touch.

**Stile visivo:** 2D minimale, con pixel art o forme geometriche pulite e colori
ad alto contrasto per un prototipo rapido. Area, direzione e durata delle abilità
devono essere leggibili anche durante le ondate più dense.
Le aree e i VFX alleati sono renderizzati sotto attori e attacchi; telegraph e
proiettili ostili hanno priorità visiva e non possono essere coperti da un'abilità.
Forma, contorno e pattern affiancano sempre il colore come segnali distintivi.

Il Player usa sprite laterali destra/sinistra: durante qualsiasi movimento
alterna i frame di camminata, al neutro mostra la posa ferma e conserva l'ultima
direzione orizzontale non nulla. La direzione è parte del contratto gameplay del
Player: le abilità direzionali possono usarla senza leggere la posizione
istantanea del joystick quando vengono attivate.

La presentazione B18B usa una fascia superiore compatta da `64` unità logiche,
seguita da una linea XP da `8`; ritratto, livello e vita occupano il lato sinistro,
il timer resta centrato e pausa usa un target touch da almeno `44` unità. La card
dell'abilità misura `246×94` unità logiche e conserva lo stesso minimo touch.
Il joystick mantiene area di acquisizione `224×224` e raggio input `84`, ma viene
disegnato con raggio `68` e opacità ridotta a riposo. Il pavimento è procedurale e
irregolare, privo di griglia o bordo ciano regolari; flash, squash, hit spark,
particelle di morte e impulso di prontezza sono esclusivamente presentazionali.

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

Le descrizioni narrative, i ruoli e le passive dei personaggi sono mantenuti in
[`characters.md`](./characters.md); questo documento è la fonte dei contratti e
dei parametri iniziali delle loro abilità attive.
