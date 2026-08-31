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

Dopo un danno non letale il Player lampeggia a intervalli regolari per tutta la
finestra reale di invulnerabilita: il feedback si ferma in pausa e non modifica
hitbox, collisioni o durata del timer gameplay.

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

`Forchettone da Braciere` è la carta danno comune dedicata: cinque rank da
`×1,15` compongono il danno base dell'arma fino a `×2,0113571875`, nel cap
runtime dichiarato per il danno. Non altera frequenza di fuoco, movimento,
pickup o dati condivisi dell'arma; si combina con Gossip e Birra e si azzera a
restart o cambio personaggio.

Le sette icone refresh delle carte sono derivati PNG pixel-art `128×128`
centrati con margine trasparente coerente; ID, pesi, rank, prerequisiti ed
effetti restano invariati. Master e derivati sono tracciati nel
[`manifest upgrade`](../assets/art/icons/upgrades/ASSET-MANIFEST.md).

**Specialità di Barb (PS-012):** Gossip, Colpo Perforante, Raffica Doppia ed
Esplosione Finale sono `UpgradeDefinition` con `is_speciality = true`, definite
sotto `data/upgrades/specialities/`. Non compaiono nel pool di level-up
normale finché non vengono sbloccate come ricompensa dopo la sconfitta di un
Boss: quella ricompensa apre lo stato dedicato `RunController.BARB_REWARD` e
propone fino a tre Specialità ancora bloccate, pescate con RNG deterministico
derivato dal seed della run su uno stream separato da quello del level-up. La
scelta assegna subito il rank `1` e sblocca la carta per il resto della run; i
rank successivi seguono da lì il normale sistema di upgrade ed eleggibilità.
Se tutte le Specialità sono già sbloccate, la ricompensa Boss diventa due
selezioni upgrade bonus consecutive tramite lo stesso pool e le stesse regole
del level-up, senza avanzare livello o XP. Restart e cambio personaggio
azzerano tutti gli sblocchi.

La ricompensa usa una variante visiva dedicata della selezione a tre carte:
header caldo con caricatura pixel-art di Barb e badge `NUOVA SPECIALITÀ`, più
bordo oro/arancio sulle vere Specialità. Quando il catalogo è esaurito, la
stessa cornice e caricatura restano presenti ma titolo e badge diventano
`IL PREMIO DI BARB` / `RICOMPENSA BONUS` e le carte tornano al trattamento
freddo del level-up normale. Questa distinzione è solo presentativa: focus,
input, lock anti-tap, offerta e assegnazione dei rank restano invariati.

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

- **Tipo:** colpo istantaneo su tutti i bersagli vivi, scalato dalla passiva
  (PS-004).
- **Effetto:** fotografa i nemici vivi al momento dell'attivazione; dopo un
  breve preavviso (`warning_seconds`) tutti i bersagli fotografati ricevono
  un'unica istanza di danno. Il danno per bersaglio è `damage` del rank
  corrente moltiplicato per la fascia di carica di Guarigione Ritardata al
  momento dell'attivazione (`×1` sotto il `5%` di HP recuperabili rispetto
  alla vita massima di Zat, `×2` fra `5%` e `12%`, `×3` da `12%` in su). Nemici
  comparsi dopo lo snapshot non vengono colpiti; la quota recuperabile viene
  letta, mai consumata. Non applica knockback, slow o controllo radiale.
- **Parametri iniziali (rank 1):** `cooldown_seconds: 60.0`, `duration_seconds: 0.85`,
  `damage: 12.0`, `tier_multiplier_low/medium/high: 1.0/2.0/3.0`,
  `warning_seconds: 0.35` — fasce `12 / 24 / 36` danni. Soglie di carica
  (`charge_threshold_medium: 0.05`, `charge_threshold_high: 0.12`) e velocità
  di rotazione dell'aura (`aura_rotation_speed_low/medium/high`) vivono in
  `data/friends/zat.tres` (passiva), non nell'attiva.
- **Tell persistente:** un'aura orbitante attorno a Zat (1 fulmine verde in
  fascia bassa, 2 gialli in media, 3 rossi in alta, rotazione crescente) resta
  visibile durante `RUNNING` indipendentemente dall'attivazione: è la lettura
  della quota recuperabile di Guarigione Ritardata (tell mancante colmato da
  PS-004, delegato da PS-003/D3). E' puramente VFX: nessuna Area2D, nessuna
  collisione.
- **Nota tecnica:** cooldown, preavviso e aura avanzano soltanto in `RUNNING`;
  pausa, morte, cambio profilo e restart non producono impatti tardivi o VFX
  residui. Nessun flash fullscreen: il tell immediato sono i decal tinti per
  fascia disegnati su ogni bersaglio fotografato.

#### Alea — Gran Piroetta

- **Tipo:** attacco melee rotante.
- **Effetto:** colpisce ripetutamente i nemici attorno al personaggio per tutta
  la durata.
- **Parametri iniziali:** `cooldown_seconds: 9.0`, `duration_seconds: 1.2`,
  `damage_per_hit: 5`, `hits_per_second: 12`, `area_radius: 140`.
- **Nota tecnica:** l'area si ricentra sulla posizione corrente del Player per
  tutta la durata e applica il danno con aggiornamenti periodici; pausa e stati
  non `RUNNING` congelano posizione, durata e tick.

#### Aleo — Shock Termico

- **Tipo:** area bifase di controllo e detonazione.
- **Effetto:** una fase fredda brina i nemici nell'area e li rallenta, poi la
  stessa area detona di calore; i bersagli ancora brinati subiscono il danno
  moltiplicato.
- **Parametri iniziali:** `cooldown_seconds: 12.0`, `area_radius: 200`,
  `duration_seconds: 1.2` (fase fredda), `damage: 14`, `slow_factor: 0.45`,
  `shock_multiplier: 2.0`, `bloom_seconds: 0.35`.
- **Nota tecnica:** la fase fredda applica un modificatore di velocità per
  bersaglio e lo rimuove alla detonazione o all'uscita dall'area; pausa e stati
  non `RUNNING` congelano fase, durata e detonazione.

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
danno/durata/raggio/sbalzo per Aleo; rank copiato, cooldown e anti-ripetizione per
Lollo; durata/raggio/slow per Migi; durata e cooldown del clone per Marghe.
Cosplay non trasferisce rank: risolve temporaneamente il profilo copiato al rank
`1`, `2` o `3` previsto dal proprio rank, con filtri anti-ricorsione e di
compatibilità invariati.

### 3.5. Boss, vittoria e chiusura della run

Il primo Boss viene richiesto dal `GameDirector` a `02:00` di clock logico.
Da `01:45` l'HUD mostra sotto il timer run `LA GRIGLIA STA FACENDO UN
PROFUMINO...`; negli ultimi cinque secondi il copy diventa `BOSS IN 5` fino a
`BOSS IN 1` e usa il colore rosso di urgenza. La stessa sequenza anticipa ogni
Boss ricorrente sulla sua scadenza autorevole, calcolata dallo spawn effettivo
precedente. Il warning deriva dallo stesso clock `RUNNING`, resta congelato in
pausa e durante il level up, non intercetta input e scompare quando parte
`BOSS_INTRO`. Non viene mostrato mentre un Boss è attivo o quando uno spawn è
già pendente. L'introduzione ferma clock e gameplay e mostra nella safe area
nome, barra HP e una citazione.
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

### 3.5A. Evoluzioni prima del packaging finale: Boss Evil e Difesa Grigliata

Prima del packaging finale B20, il Boss di riferimento diventa il piccione
speciale B18H. B22 aggiunge una sostituzione configurabile, con probabilità
iniziale `25%` e
scelta deterministica da seed della run più indice della soglia: al posto del
piccione speciale può apparire un `Evil <Nome>` estratto casualmente dagli otto
profili. In questa
prima versione Evil riusa lo sprite del relativo Player con palette viola scura
e accenti magenta ad alto contrasto; mantiene statistiche, hitbox e i due
pattern del piccione Boss. Le abilità del personaggio non sono ancora disponibili
ai Boss Evil e richiedono una successiva slice dati/comportamentale.

B23 introduce una seconda modalità, **Difesa Grigliata**, accanto alla
Sopravvivenza attuale. La modalità mette al centro del playfield una griglia con
carne, con salute configurabile e HUD proprio; i nemici possono selezionarla e
danneggiarla. La run termina in `DEFEAT` se la vita del Player o della griglia
raggiunge zero. La modalità eredita per la prima versione progressione, pausa,
lifecycle, Boss a `02:00` con warning PS-005 e vittoria dopo il Boss, ma conserva
stato, seed,
cleanup e target selection separati per evitare residui tra modalità e restart.
La selezione della modalità resta in `BOOT`, integrata nel flusso di conferma
del profilo e non avvia mai una run da sola.

B20 viene eseguito dopo B22 e B23 e confeziona entrambe le funzionalità nella
prima release Windows/Android; non viene rimosso perché resta responsabile di
ZIP Windows, firma APK e generazione AAB.

### 3.6. Catalogo amici e controparti Evil

Gli otto profili approvati sono Magno, Bea, Zat, Alea, Aleo, Lollo, Migi e
Marghe. Ogni profilo dichiara in un `FriendDefinition` identità, ruolo, passiva,
parametri runtime della passiva, attiva, ID abilità, ritratto sostituibile e la
controparte Boss denominata `Evil <Nome>`. Il Player della vertical slice M4 è
Magno; B17A rende selezionabili e giocabili tutti gli otto profili prima della
run. Da B22 ogni incontro parte dal piccione speciale baseline e può risolversi
in uno degli otto Evil secondo probabilità dati e seed della run.

Una welcome screen precede la selezione e non inizializza alcuna run. `GIOCA`
usa la stessa placca pixel-fantasy senza testo del CTA `Gioca con <Nome>` del
carosello B18W, ma conserva copy nativo della welcome; un ingranaggio da almeno
`60×60` nella safe area in alto a destra apre le impostazioni. Le impostazioni restano raggiungibili sia da questa
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
due card laterali compatte per passiva e abilità, ciascuna con icona, label,
titolo dorato e descrizione.
Ogni profilo usa una propria icona passiva raster `128×128` derivata da un master
RGBA escluso dagli export; prompt, sorgente, trasformazione e hash sono nel
manifest delle passive.
Il sottotitolo istruttivo e `KIT DI <NOME>` sono rimossi. Ogni card abilità usa
icona a sinistra centrata rispetto al blocco testuale a destra; nome e ruolo
formano un blocco compatto immediatamente
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

Ogni profilo dichiara inoltre tre scarti di partenza (B47) su salute,
velocità di movimento e cadenza di fuoco. Il default è neutro `×1,0`, i
valori restano nell'intervallo `0,5–2,0`, vengono normalizzati se malformati
e compongono moltiplicativamente con passive e upgrade senza mutare i dati
base condivisi di Player e arma. Gli scarti si azzerano a restart e cambio
personaggio come ogni altro contributo di profilo.

Baseline iniziali delle passive, tutte configurabili nei `.tres`:

| Profilo | Parametri runtime B17A |
|---|---|
| Magno | velocità di movimento `×1,15` |
| Bea | probabilità di evasione `15%` |
| Zat | `35%` del danno recuperabile dopo `3 s`, recupero in `4 s` |
| Alea | effetto ogni `10 s` per `5 s`; `60%` positivo (`×1,50`) e negativo (`×0,70`) su movimento o fuoco; ogni kill carica `+1%` di probabilità positiva fino al cap `95%`, e il tiro spende l'intera carica accumulata (B42) |
| Aleo | sopra il `50%` HP danno inflitto `×1,20`; sotto il `50%` HP danno subito `-25%`, nemici entro `140 px` rallentati a `×0,70` e brinati per `12` danni al secondo con tick da `0,25 s` (B44) |
| Lollo | iperfocus `4-8 s` (movimento `×1,35`, fuoco `×1,45`) alternato a distrazione `3-6 s` (movimento `×0,85`, fuoco `×0,80`); durata di ogni fase estratta casualmente. Ogni kill accorcia la sola distrazione di `0,15 s`, mai l'iperfocus (B44) |
| Migi | riduzione danno `10%`; sotto `35%` HP scudo da un colpo per `4 s`, cooldown `20 s` |
| Marghe | i nemici entro `200` unità logiche subiscono danno `×1,30` da ogni fonte, arma e abilità comprese; Boss esclusi dalla baseline. Sostituisce la riduzione di salute massima `×0,95` pre-B42, che a `18` HP non cambiava il numero di colpi necessari (B42) |

Il `FriendRegistry` rifiuta ID amico, ID abilità e nomi Evil ambigui. Copy e
ritratti vengono esposti attraverso getter sicuri: se manca l'approvazione
ritornano fallback neutri. L'approvazione richiede approvatore, data ISO e
riferimento.

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
hitbox, velocità, collisioni, passive, abilità o timing gameplay. B24 aggiunge
separatamente un moltiplicatore esclusivamente presentazionale alla scala base
dello sprite: il candidato `1,25×` porta `CharacterSprite` da `1,65` a `2,0625`,
senza scalare il `CharacterBody2D`, il raggio collisione `24`, l'origine di fuoco,
i raggi, il clamp arena o qualsiasi coordinata/statistica gameplay. Il valore
resta configurabile e sarà congelato soltanto dopo confronto percettivo su
Windows e Pixel 9 con orde dense, Boss, VFX e bordi del playfield.

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

Effetto: aumenta la frequenza di sparo del `25%`, ma ogni nuovo proiettile
riceve una dispersione angolare casuale di `±24°`: il colpo non è più garantito
sul bersaglio mirato. La sequenza resta riproducibile per seed della run.

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
  la loro larghezza visiva e separato di `20` unità logiche dal bordo superiore/destro
  della safe area;
- solo cronometro leggermente ingrandito, centrato e trasparente sotto le due
  barre, senza label `Tempo` né sfondo;
- icona dell'abilità attiva come unico controllo visivo touch, separata dal
  joystick e posizionata nella safe area con lo stesso inset esterno di `20`
  unità, sommato ai margini obbligatori di gesture;
- indicatore radiale leggibile del cooldown residuo e feedback visivo/sonoro
  quando l'abilità torna disponibile.

La baseline B31 del pulsante touch coincide con l'icona dell'abilità equipaggiata
e misura `128×128` unità logiche. B18P espone tre taglie persistenti e indipendenti:
abilità `100/125/150%`, con default `160×160` e icona `105`, e joystick
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
esclusivamente presentazionali. B18R centralizza il burst abilità a `1,20 s`,
le reazioni Player/nemico a `0,30`/`0,26 s`, la morte a `0,78 s` e l'impulso di
prontezza a `0,60 s`; i flash restano brevi a `0,075–0,08 s`. Le code visive
sono nodi sibling non interattivi e non prolungano collisioni, danno, tick,
 cooldown o raggi né lasciano apparire attiva un'area già conclusa.

**Coerenza UI B34:** pausa, HUD e controlli touch usano blu notte per fondi,
oro/arancio per azioni, crema per testo primario, grigio freddo per testo
secondario, cyan soltanto per sistema/selezione e rosa/rosso per salute o
pericolo. Bordi e CTA sono squadrati/pixelati con ombre leggere; la pausa usa
azioni primarie e secondarie distinte, mentre slider e toggle restano controlli
nativi accessibili ma disegnati nella stessa grammatica. XP, HP, timer, inset,
target pausa, dimensioni dell'abilità, cooldown, acquisizione joystick,
deadzone, multitouch e tutti gli stati di `RunController` restano invariati.
Il medaglione dell'abilità è un sibling non interattivo dietro al pulsante
icona B18K, quindi non acquisisce touch né introduce una card o copy aggiuntivi.
La selezione mantiene due card kit gemelle per altezza, padding e allineamento,
con emblemi più presenti e spazio interno ridotto; il blocco nome/ruolo/CTA
resta compatto. Pausa, ingranaggio, frecce e medaglione condividono il bordo
scuro/oro e bevel pixelato, mentre il joystick conserva la variante trasparente
con la stessa palette. Il padding esterno di pausa e abilità deriva dalla stessa
configurazione B31 su 16:9, 20:9 e 4:3.

**Tutorial B54:** la welcome mostra `TUTORIAL` sotto `GIOCA` come azione
secondaria. Apre in `BOOT` un carosello di sei pagine su scopo della run,
movimento e sparo automatico, abilità attiva, XP e carte, archetipi nemici e
Boss. Frecce, indicatori, swipe, tastiera/controller e Back condividono un solo
indice; l'ultima pagina apre il selettore senza creare la run. Copy e visual
sono dati separati dal layout. Obiettivo, movimento e Boss usano artwork
editoriali originali dedicati; abilità, progressione e nemici riusano le icone
runtime già approvate. Il solo movimento delle visual è presentazionale, non
usa nodi gameplay o RNG e si ferma fuori dal tutorial; i concetti restano
comprensibili anche senza animazione, audio o colore. Sulla prima pagina il
controllo sinistro è `ESCI` e torna alla welcome; sulle successive diventa
`INDIETRO`. Back di sistema chiude sempre il tutorial. Gli
elementi decorativi della welcome possono estendersi nel viewport, ma i target
interattivi restano nella safe area; il pannello tutorial e tutti i suoi
controlli restano safe-area su 16:9, 20:9 e 4:3.

**Hardening B18V:** `PerformanceProfile` è scene-local e fisso a 60 FPS, con
stress da 150 nemici, 200 proiettili e 200 pickup sia su Windows sia su mobile.
L'overlay diagnostico debug è invisibile di default e si abilita soltanto con
`--performance-overlay`: mostra FPS/frame time, memoria, nodi, entità, VFX,
voci audio e profilo. `--b18v-stress` emette `B18V_PERF_SAMPLE` e marker finali
B18V. I soli fallback consentiti, nell'ordine, sono FIFO dei feedback transitori
(300 Windows, 150 Android) e scala interna mobile fissa `0,85`, previa nuova
verifica percettiva; non sono ammessi qualità dinamica né cambi a durate, raggi,
cooldown, danni, spawn o pool audio da 12 voci.

**Densità B28:** il profilo ordinario usa cap `140`, intervallo `0,60 → 0,12 s`,
accelerazione `0,003`, delay iniziale `0,50 s` e nemici base da `24 HP`. Il
budget XP non segue ciecamente il numero di kill: allo spawn ogni nemico base
riceve `1,50 × intervallo_corrente / intervallo_riferimento_pre_B28`; il dropper
accumula il credito frazionario e consegna solo XP intero. Boss, ricompensa Boss,
pattern e telegraph restano fuori da questa scala. Pooling o altre ottimizzazioni
sono ammessi soltanto dopo evidenza profiler Windows e Pixel 9.

**Pressione late-run PS-007:** dopo l'ingresso di tutti gli archetipi, il
profilo ordinario evolve in modo continuo fra `01:00` e `05:00`: il peso
relativo del piccione base scende fino al `33%` del valore iniziale, mentre i
moltiplicatori dati favoriscono progressivamente sciamatori, corazzati,
divisori e soprattutto tiratori. Anche la probabilita' di usare piu' settori
sale, senza cambiare HP, danno, targeting, powerup o statistiche del Player.
Da `03:00`, se il pool non ha generato un tiratore negli ultimi `4 s`, il
prossimo spawn eleggibile lo garantisce; il colpo conserva telegraph, velocita'
e danno dichiarati dall'archetipo. La curva usa soltanto il tempo logico in
`RUNNING`, e determinismo, pausa e restart restano quelli di `EnemySpawner`.
Gli eventi d'ondata PS-008 sono un layer finito ulteriore e non sostituiscono
questa progressione ordinaria.

**Eventi d'ondata PS-008:** durante la run possono attivarsi, separatamente
dallo spawn ordinario, formazioni finite e riconoscibili che compongono
temporaneamente pesi e settori effettivi di `EnemySpawner` (le stesse API
dati di PS-007), senza mai introdurre una seconda curva ordinaria parallela.
Baseline: nessun evento prima di `02:30`, un solo evento attivo alla volta,
frequenza configurabile (default `45–90 s` di intervallo fra un evento e il
successivo). Il principio è leggibilità obbligatoria, telegraph opzionale: il
telegraph è richiesto solo quando la formazione potrebbe creare una minaccia
immediata prima che il Player abbia il tempo materiale di reagire. Tre eventi
baseline: **Accerchiamento** (nemici da tutti i settori, richiede telegraph),
**Stormo laterale** (gruppo compatto da un solo lato, nessun telegraph, i
primi arrivi sono il segnale) e **Nido di tiratori** (aumento temporaneo del
peso relativo del tiratore nel pool ordinario esistente, nessun telegraph
globale, ogni tiratore mantiene il proprio telegraph individuale). Un evento
non può mai iniziare mentre un Boss è attivo (dalla richiesta alla sua
uscita); un evento maturato in quella finestra viene interrotto secondo una
regola dati esplicita del profilo scheduler (`postpone` ritenta appena il
Boss libera lo scheduler, `discard` lo scarta e ripianifica), e non si
accumula mai più di un evento in attesa. Scheduler e telegraph avanzano solo
in `RUNNING` e si azzerano su restart, con RNG proprio riseedato sul seed di
run: stesso seed, stessa sequenza di eventi e formazioni.

**Audio:** gli eventi di combattimento, progressione, abilità, Boss e terminali
usano cue brevi su un bus SFX polifonico. La run usa inoltre il loop CC0
`Super Wreck Roadway (loop)` di Umplix su un bus `Music` separato,
attenuato di `12 dB` rispetto agli SFX e fermato fuori da `RUNNING`; pausa e
modal riprendono dalla posizione corrente, mentre terminale e restart lo
puliscono. Il menu offre volume audio lineare e mute, applicati a entrambi i bus
anche durante la pausa e persistiti in `user://audio_settings.cfg`. Le voci
personali restano separate da questi effetti generici e silenziose finché non
vengono fornite e approvate.

## 6. Perimetro funzionale consolidato

Questa sezione descrive le aree funzionali del prodotto, non priorità o lavoro
aperto. Stati, dipendenze e ordine di sviluppo vivono esclusivamente nella
[`board delle card`](./cards/README.md).

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
