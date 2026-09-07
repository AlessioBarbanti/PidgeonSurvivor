# Catalogo dei powerup

Questo documento raccoglie i powerup correnti e le proposte ancora aperte. Lo
stato operativo delle implementazioni resta nella
[`board`](./cards/README.md); questo file descrive identità, effetti e direzione
visiva del catalogo senza funzionare da backlog parallelo.

## I due registri del catalogo

Il catalogo vive su due registri distinti dentro lo stesso mondo grigliatore, e
il contrasto fra i due è deliberato: è quello che fa leggere una Specialità come
"il pezzo speciale" invece che come l'ennesimo attrezzo.

- Le **carte statistiche ordinarie** stanno su utensili, pirofile, brace e
  condimenti — `A Tutta Brace!`, `Pinza Lunga`, `Forchettone da Braciere`,
  `Il condimento di Barb`, `Pirofila Rinforzata`. Non nominano mai un pezzo di
  carne: è questa regola ad aver rinominato `Bis di Salsiccia` in
  `Ravviva la Brace!` (PS-089).
- Le **Specialità di Barb** portano ognuna il nome di un taglio cotto alla
  griglia. La finzione lo giustifica: mentre il Player difende Barb dal Boss,
  Barb ha il tempo di cucinare, e quello che consegna alla fine è un pezzo di
  carne, la sua specialità.

I primi sette nomi sono stati approvati dal proprietario il 5 settembre 2026
(PS-078); `Pancetta` è stata prodotta il 7 settembre con PS-118. Il registro è
un "menù secco": il nome è il solo taglio, una parola, senza aggettivi, come
una lavagna del grigliatore. Il vincolo è più stretto di
"carne": deve essere una cottura **alla griglia**, motivo per cui candidati
come straccetti, polpette e stracotto sono stati scartati.

| Specialità | ID | Effetto | Perché quel taglio |
|---|---|---|---|
| **Alette** | `beer_signature` | +25% cadenza, ±24° di dispersione | cottura rapida, e i pezzi partono in direzioni diverse |
| **Costine** | `chronic_delay` | rallenta i nemici a intervalli | la cottura lenta sulla brace per eccellenza |
| **Hamburger** | `damage_shockwave` | onda d'urto quando il Player subisce danno | lo schiacciamento sulla piastra *è* l'onda d'urto |
| **Fiorentina** | `death_burst` | i nemici uccisi esplodono | il pezzo grosso, avvolto dalla fiammata |
| **Tagliata** | `double_barrel` | proiettili aggiuntivi a ventaglio | è il pezzo che arriva già diviso in fette |
| **Salsiccia** | `gossip_projectiles` | rimbalzi in catena fra nemici | la salsiccia a nodi è una catena: il colpo passa di anello in anello |
| **Arrosticini** | `piercing_rounds` | il colpo attraversa più bersagli | uno stecco che infilza bocconi in fila |
| **Pancetta** | `ability_charge_stacking` | più cariche dell'abilità attiva | più strisce dello stesso taglio formano una riserva pronta all'uso |

Con un nome di una parola sola il titolo non basta più a comunicare l'effetto:
`description` ed `effect_summary` restano l'unico veicolo testuale e non vanno
accorciati per ragioni estetiche.

`L'Ansia` (`anxiety_signature`) è uscita dal gioco con
[PS-100](./cards/4_to_test/PS-100-rimuovi-ansia-dalle-specialita-di-barb.md):
non è più offerta né dalla ricompensa di Barb né dal level-up ordinario.

L'ottava Specialità reale, `ability_charge_stacking` (cariche multiple
sull'abilità attiva), è entrata col catalogo di run con
[PS-094](./cards/4_to_test/PS-094-specialita-cariche-abilita-attiva.md) ed è
stata tematizzata da
[PS-118](./cards/4_to_test/PS-118-nome-e-icona-nona-specialita-cariche-abilita.md)
come `Pancetta`.

Due conseguenze operative sulla separazione fra i registri:

- `tests/unit/test_ps089_ordinary_catalog_meat_audit.gd` fallisce se una carta
  ordinaria nomina un taglio di carne. La sua lista di parole vietate include
  gli otto tagli qui sopra e va estesa se una nuova Specialità ne introduce
  altri, altrimenti il catalogo ordinario potrebbe riprenderseli.
- Le proposte non ancora implementate `Pancetta Croccante` e `Spiedo Passante`
  violano la regola: sono letteralmente carne alla griglia in un registro che
  non dovrebbe averla. Vanno rinominate prima di diventare carte runtime,
  oppure la regola va rivista esplicitamente.

---

## Modifiche ai potenziamenti esistenti

Questa sezione raccoglie esclusivamente le modifiche proposte ai powerup già
presenti nel catalogo attivo. La direzione visiva comune resta quella dei
**grigliatori**: carne, utensili da barbecue, pirofile, brace, condimenti e
oggetti da cucina. I piccioni restano associati ai nemici e non devono essere
il soggetto principale delle icone dei powerup positivi.

### A Tutta Brace!

**ID esistente:** `rapid_fire`  

L'icona di questa abilità è nel file `upgrade_a_tutta_brace.png`.

**Nome attuale:** `Ritmo Serrato`  
**Effetto:** invariato — `+10%` frequenza dello sparo automatico per rango.

- rinominare `Ritmo Serrato` in **A Tutta Brace!**;
- mantenere un'icona chiaramente legata alla grigliata, evitando armi moderne o
  elementi meccanici fuori tema;
- privilegiare una **brace molto viva** con una rapida sequenza di
  scintille/fiammate, così da comunicare ritmo e intensità senza sembrare un
  bonus generico alla velocità;
- rango nominale `5`, ripetibile all'infinito.

---

### Pinza Lunga

**ID esistente:** `wide_magnet`  

L'icona di questa abilità è nel file `upgrade_pinza_lunga.png`.

**Nome attuale:** `Campo Ampio`  
**Effetto:** invariato — `+15%` raggio di raccolta XP per rango.

- rinominare `Campo Ampio` in **Pinza Lunga**;
- usare come identità visiva una **pinza da barbecue volutamente molto lunga**
  che raggiunge un cristallo XP distante;
- l'icona deve comunicare chiaramente **raccolta a distanza**, senza piccioni e
  senza ricorrere a magneti o simboli tecnologici;
- il powerup modifica soltanto il raggio di pickup e non il valore dei
  cristalli raccolti.

---

## Nuovi potenziamenti

I seguenti powerup ampliano il catalogo senza duplicare le statistiche già
presenti. Salvo indicazione diversa, sono pensati come passivi ripetibili
all'infinito. Il valore `max_rank = 5` resta il rango nominale/configurato
della carta, non un limite effettivo alla scelta o allo stacking. I valori sono
proposte di bilanciamento e restano configurabili.

### Via dalla Griglia!

**ID proposto:** `projectile_speed`  

L'icona di questa abilità è nel file `upgrade_via_dalla_griglia.png`.

**Effetto proposto:** `weapon_projectile_speed_multiplier`  
**Ruolo:** velocità dei proiettili

- `+10%` velocità dei proiettili alleati per rango;
- rango nominale `5`; ripetibile all'infinito;
- stacking moltiplicativo;
- cap iniziale consigliato `3,0×`;
- non modifica danno, frequenza di sparo, lifetime o comportamento speciale;
- non influenza i proiettili dei Boss o degli altri nemici.

**Descrizione carta:** “Aumenta del 10% la velocità dei proiettili per rango.”

**Identità visiva:** carne o spiedino appena tolto dalla griglia e scagliato in
avanti con una forte sensazione di movimento, scie di brace e calore. Deve
comunicare rapidità senza introdurre razzi, motori o tecnologia fuori tema.

---

### Ravviva la Brace!

**ID proposto:** `ability_cooldown`  

Rinominata da `Bis di Salsiccia` il 4 settembre 2026 (PS-089, poi corretta
in `Ravviva la Brace!` lo stesso giorno su richiesta del proprietario): un
pezzo di carne è ora un soggetto riservato alle Specialità di Barb. L'icona
runtime attuale (`bis_di_salsiccia.png`) ritrae ancora letteralmente una
salsiccia e resta fuori dall'ambito di questa rinomina testuale; una nuova
icona è materia di una card `tipo: art` dedicata (vedi Decisioni di PS-089,
card PS-092).

**Effetto proposto:** `active_ability_cooldown_multiplier`  
**Ruolo:** frequenza d'uso dell'abilità attiva

- ogni rango moltiplica il cooldown base per `0,92` (`-8%` circa);
- rango nominale `5`; ripetibile all'infinito;
- ripetibile;
- cap consigliato: il cooldown non può scendere sotto `0,65×` del valore base;
- modifica soltanto il cooldown dell'abilità equipaggiata;
- un'abilità già attivata conserva il proprio snapshot: il nuovo rango vale
  dall'attivazione successiva.

**Descrizione carta:** “Riduce dell'8% il tempo di ricarica dell'abilità per rango.”

**Identità visiva:** un cumulo di braci che si riaccende — scintille e un
bagliore che torna vivo, come dopo un colpo di mantice o un ventaglio.
Deve comunicare immediatamente il concetto di **ricarica pronta di nuovo**,
mai carne (riservata alle Specialità di Barb, PS-078/PS-089), evitando
orologi, timer o simboli tecnici. Vedi anche [PS-092](./cards/2_to_do/PS-092-nuova-icona-ravviva-la-brace.md).

---

### Punto di Cottura

*(PS-093, 2026-09-06 — rinominata da "Salamoia Bolognese": `salamoia` è in
lista nera per il catalogo ordinario, PS-089, riservata alle Specialità di
Barb. Il meccanismo è implementato e mergiato in `main`. PS-108, 2026-09-07 —
la carta è ora cablata nel catalogo pescabile live, vedi sotto.)*

**ID:** `cooking_point_crit`, in `data/upgrades/cooking_point_crit.tres`.

**Effetto:** `weapon_critical_chance`, in `WeaponController`/
`UpgradeEffectRegistry`.  
**Ruolo:** colpi critici dell'arma automatica

- `+5` punti percentuali di probabilità critica per rango;
- rango nominale `5`; ripetibile;
- danno critico `1,75×`;
- cap totale `35%` (`WeaponController.MAXIMUM_CRITICAL_CHANCE`), somma dello
  scarto base per personaggio e della carta;
- si applica all'arma automatica del Player, non alle abilità.

**Descrizione carta:** “Colpisce il punto perfetto: aumenta di 5 punti
percentuali la probabilità di colpo critico per rango.”

**Stato icona (PS-107, 2026-09-07):** il vecchio master HD orfano
(`upgrade_salamoia_bolognese.png`, bocciato in art review durante PS-093:
composizione a tre nuclei visivi separati, illeggibile a 48×48, confondibile
con "Il condimento di Barb") resta sul disco come storico, non toccato.
Rigenerato un nuovo master a tema "colpo critico/punto di cottura perfetto":
un unico cluster bistecca+termometro da cucina, sonda infilata nella carne,
quadrante analogico con arco rosso-arancio-verde e ago fermo sulla zona verde,
glint ciano-bianco isolato come unico elemento univoco di "colpo perfetto".
Master (`assets/art/icons/upgrades/hd/upgrade_cooking_point_crit.png`) e
derivato (`assets/art/icons/upgrades/generated/cooking_point_crit.png`,
`128×128`) esistono a manifest e leggibili anche a 48×48 (vedi
`ASSET-MANIFEST.md` e [PS-107](./cards/4_to_test/PS-107-rigenera-icona-punto-di-cottura.md)
per dettaglio prompt e verifica). Il controllo percettivo del proprietario
sulla direzione bistecca+termometro resta un gate aperto in PS-107, ma non
blocca il cablaggio: **PS-108, 2026-09-07 — la carta è ora referenziata in
`data/upgrades/cooking_point_crit.tres` (`icon`) e presente in
`UpgradeRegistry.definitions`** ([scenes/game/movement_slice.tscn](../scenes/game/movement_slice.tscn)):
pescabile a level-up in ogni run, catalogo ordinario.

---

### Spiedo Passante

**ID proposto:** `skewer_pierce`  

L'icona di questa abilità è nel file `upgrade_spiedo_passante.png`.

**Effetto proposto:** `weapon_pierce_count`  
**Ruolo:** penetrazione dei proiettili

- `+1` nemico attraversabile per rango;
- rango nominale `5`; ripetibile all'infinito;
- ripetibile;
- ogni bersaglio successivo riceve l'`85%` del danno inflitto al bersaglio
  precedente;
- la penetrazione avviene prima di eventuali effetti di `Gossip`, così le due
  meccaniche restano distinte e possono convivere;
- cap iniziale: `5` attraversamenti aggiuntivi dalla sola carta.

**Descrizione carta:** “I proiettili attraversano un nemico aggiuntivo per rango.”

**Identità visiva:** un lungo spiedo da griglia che attraversa più pezzi di
carne in fila. Deve comunicare immediatamente il concetto di attraversamento.

---

### Pirofila Rinforzata

**ID proposto:** `reinforced_roasting_tray`  

L'icona di questa abilità è nel file `upgrade_pirofila_rinforzata.png`.

**Effetto proposto:** `player_damage_taken_multiplier`  
**Ruolo:** difesa

- ogni rango moltiplica il danno ricevuto per `0,94` (`-6%` circa);
- rango nominale `5`; ripetibile all'infinito;
- ripetibile;
- stacking moltiplicativo;
- cap consigliato: non scendere sotto `0,70×` del danno originale tramite
  questa famiglia di modificatori;
- non modifica invulnerabilità, knockback o vita massima.

**Descrizione carta:** “Riduce del 6% i danni subiti per rango.”

**Identità visiva:** una pirofila d'alluminio assurdamente rinforzata, con
bordo spesso, placche, rivetti e ammaccature. Deve essere immediatamente
leggibile come powerup difensivo e distinta dalla pirofila con carne fumante già
presente nel gioco.

---

### Slow Cooker

**ID proposto:** `slow_cooker_duration`  

L'icona di questa abilità è nel file `upgrade_slow_cooker.png`.

**Effetto proposto:** `active_ability_duration_multiplier`  
**Ruolo:** durata degli effetti persistenti compatibili

- `+10%` durata per rango;
- rango nominale `5`; ripetibile all'infinito;
- ripetibile;
- viene offerto soltanto se l'abilità equipaggiata possiede un effetto
  persistente la cui durata può essere aumentata;
- non modifica cooldown, frequenza dei tick o danno per singolo tick;
- non viene offerto per abilità istantanee o prive di una durata significativa.

**Descrizione carta:** “Aumenta del 10% la durata degli effetti compatibili per rango.”

**Identità visiva:** una slow cooker compatta piena di carne in cottura, con
vapore caldo e una manopola ben visibile. Deve comunicare immediatamente
l'idea di una cottura che dura a lungo.

---

### Il condimento di Barb

**ID proposto:** `barb_seasoning_xp`  

L'icona di questa abilità è nel file `upgrade_condimento_di_barb.png`.

**Effetto proposto:** `xp_value_multiplier`  
**Ruolo:** esperienza ottenuta

- `+10%` XP ottenuta dai cristalli per rango;
- rango nominale `5`; ripetibile all'infinito;
- ripetibile;
- stacking moltiplicativo;
- cap iniziale consigliato `2,0×`;
- aumenta il valore dell'XP ricevuta, non il raggio di raccolta;
- resta quindi completamente distinto da `Pinza Lunga`.

**Descrizione carta:** “Aumenta del 10% l'esperienza ottenuta dai cristalli per rango.”

**Identità visiva:** un barattolino o una ciotola di condimento da grigliata
riconoscibile come “speciale della casa”, con spezie e pochi accenti luminosi.
Deve sembrare un condimento reale reso importante dall'estetica arcade, non
una pozione magica.

---

### Pancetta Croccante

**ID proposto:** `crispy_bacon_burn`  

L'icona di questa abilità è nel file `upgrade_pancetta_croccante.png`.

**Effetto proposto:** `weapon_burn_chance`  
**Ruolo:** danno nel tempo / Scottatura

- `+10` punti percentuali di probabilità di applicare **Scottatura** per rango;
- rango nominale `5`; ripetibile all'infinito;
- ripetibile;
- la Scottatura infligge danno nel tempo per alcuni secondi;
- una nuova applicazione sullo stesso nemico rinnova la durata, senza creare
  stack illimitati dello stesso effetto;
- la probabilità si applica ai colpi dell'arma automatica del Player;
- non modifica direttamente il danno base, la frequenza di sparo o la
  probabilità di critico;
- il danno e la durata della Scottatura devono restare parametri configurabili
  separatamente dal powerup.

**Descrizione carta:** “I colpi hanno il 10% di probabilità in più per rango di applicare Scottatura.”

**Identità visiva:** strisce di pancetta molto croccanti su una griglia rovente,
con bordi leggermente bruciacchiati, piccole scintille e brace. L'icona deve
comunicare immediatamente calore e bruciatura senza usare fiamme magiche o
elementi legati ai piccioni.

### Ordine consigliato di introduzione

#### Stato prima ondata — completata

Il 27 agosto 2026 sono entrati nel catalogo runtime `Via dalla Griglia!`,
`Pirofila Rinforzata`, `Il condimento di Barb` e `Ravviva la Brace!`
(rinominata da `Bis di Salsiccia` il 4 settembre 2026, PS-089). I quattro
effetti sono moltiplicatori configurabili, ricostruiti dai rank e azzerati a
restart o cambio personaggio; velocità proiettile e cooldown sono snapshot
dell'azione successiva, mentre difesa e XP agiscono sugli eventi successivi.
`A Tutta Brace!` e `Pinza Lunga` aggiornano inoltre rispettivamente nome e
icona delle carte storiche `rapid_fire` e `wide_magnet`. Il proprietario ha
accettato operativamente la prima ondata il 30 agosto 2026 senza richiedere
nuove prove. La seconda ondata resta una proposta non implementata.

Prima ondata:

1. **Via dalla Griglia!** — modifica una statistica semplice e leggibile;
2. **Pirofila Rinforzata** — introduce una scelta difensiva diretta;
3. **Il condimento di Barb** — aggiunge una scelta di progressione XP distinta
   dal pickup range;
4. **Ravviva la Brace!** — introduce il cooldown come nuova statistica
   universale delle abilità attive.

Seconda ondata:

1. **Salamoia Bolognese** — apre una build critica;
2. **Pancetta Croccante** — introduce una build basata su Scottatura e danno
   nel tempo;
3. **Spiedo Passante** — aggiunge una nuova interazione con orde dense e
   `Gossip`;
4. **Slow Cooker** — aggiunge una carta condizionale per le sole abilità che
   possono realmente beneficiarne.

### Vincoli comuni

- nessun powerup positivo usa un piccione come simbolo principale;
- tutti i valori restano dati configurabili e non hardcoded;
- restart e cambio personaggio azzerano integralmente i nuovi modificatori;
- i powerup ripetibili possono essere scelti all'infinito; `5` è il rango
  nominale della definizione e non un limite effettivo;
- una carta condizionale come `Slow Cooker` non entra nella pesca quando non
  può produrre alcun beneficio;
- i nuovi powerup non modificano implicitamente statistiche di nemici o Boss;
- le icone devono essere leggibili senza testo e appartenere visivamente al
  mondo dei grigliatori;
- evitare sovrapposizioni semantiche tra icone: in particolare le due pirofile
  devono essere immediatamente distinguibili per contenuto, silhouette e
  trattamento visivo.

Queste due sezioni costituiscono una proposta di design e non modificano il
catalogo runtime finché le relative `UpgradeDefinition` e gli effetti non
vengono implementati.
