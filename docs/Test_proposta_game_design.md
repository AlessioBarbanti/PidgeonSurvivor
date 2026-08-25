# Pidgeon Survivor — Documento guida di sviluppo

## 1. Scopo del documento

Questo documento raccoglie le principali **logiche di gioco e regole di business** di Pidgeon Survivor.

Non rappresenta ancora un Game Design Document definitivo. Il progetto si trova in una fase embrionale e diversi sistemi devono ancora essere progettati, testati e bilanciati.

Lo scopo principale è mantenere una fonte unica in cui distinguere chiaramente:

* meccaniche già definite;
* comportamenti attesi dei sistemi;
* caratteristiche dei personaggi;
* logiche che dovranno essere implementate;
* elementi ancora da decidere;
* possibili estensioni future.

Quando una meccanica non è ancora stata definita, il documento deve evitarne per quanto possibile l'implementazione concettuale prematura.

---

# 2. Concept generale

**Pidgeon Survivor** è un action roguelite a orde nel quale il giocatore controlla uno dei membri di un gruppo di amici, trasformato in un personaggio giocabile.

Ogni partita consiste in una successione di **ondate di nemici**.

Il giocatore deve:

* muoversi all'interno della mappa;
* evitare o gestire le orde;
* sopravvivere alle diverse ondate;
* utilizzare le capacità specifiche del proprio personaggio;
* diventare progressivamente più potente nel corso della partita;
* affrontare nemici e situazioni sempre più difficili.

La struttura generale deve produrre una progressiva escalation.

Le prime ondate devono essere relativamente gestibili, mentre quelle successive devono aumentare la pressione attraverso quantità, caratteristiche e comportamenti dei nemici.

---

# 3. Loop principale della partita

Il ciclo fondamentale attualmente previsto è:

**Scelta del personaggio → Inizio ondata → Combattimento → Fine ondata → Level Up → Potenziamento → Ondata successiva**

Questo costituisce il cuore della partita.

## Durante un'ondata

Il giocatore controlla il proprio personaggio e cerca di sopravvivere ai nemici presenti.

Durante questa fase il focus è principalmente su:

* movimento;
* posizionamento;
* gestione dello spazio;
* utilizzo dell'abilità attiva;
* sfruttamento delle caratteristiche del personaggio;
* gestione delle diverse tipologie di nemici.

## Fine dell'ondata

Quando l'ondata viene completata, la fase di combattimento termina o viene temporaneamente interrotta.

Il personaggio effettua quindi automaticamente un **Level Up**.

Non esiste, almeno nella struttura attuale, una meccanica basata sulla raccolta di gemme esperienza lasciate dai nemici.

La progressione del livello è quindi direttamente collegata alla progressione delle ondate.

### Regola attuale

**1 ondata completata = 1 Level Up**

Questa regola potrà eventualmente essere modificata durante il bilanciamento, ma rappresenta la logica di riferimento iniziale.

---

# 4. Sistema di Level Up

Il Level Up rappresenta il momento principale in cui il giocatore sviluppa il proprio personaggio durante una partita.

Alla fine di ogni ondata viene presentata una scelta di potenziamento.

Il funzionamento preciso del sistema non è ancora definito.

Potrà eventualmente comprendere:

* miglioramenti delle statistiche;
* miglioramenti delle capacità del personaggio;
* nuovi effetti;
* modificatori;
* sistemi offensivi;
* sistemi difensivi;
* elementi legati alla build.

La regola fondamentale è che ogni Level Up deve offrire al giocatore **una decisione significativa**.

Il sistema non deve essere definito prematuramente intorno al concetto di armi, poiché il funzionamento delle armi e dell'equipaggiamento è ancora da progettare.

---

# 5. Sistema delle ondate

Le ondate costituiscono la principale unità di progressione di una partita.

Ogni ondata può essere descritta attraverso parametri quali:

* durata;
* quantità di nemici;
* frequenza di spawn;
* tipologie di nemici;
* salute dei nemici;
* danno dei nemici;
* velocità dei nemici;
* presenza di élite;
* presenza di miniboss;
* presenza di boss;
* eventuali modificatori specifici.

Con il procedere della partita, le ondate devono diventare progressivamente più difficili.

La difficoltà non dovrebbe però derivare solamente dall'aumento numerico della salute o del danno.

Possono contribuire anche:

* nuove combinazioni di nemici;
* maggiore densità;
* nemici più veloci;
* attacchi a distanza;
* unità con comportamenti speciali;
* nemici capaci di controllare determinate zone della mappa;
* cambiamenti nel ritmo dello spawn.

---

# 6. Nemici

I nemici rappresentano la pressione principale esercitata sul giocatore.

La maggior parte degli avversari deve cercare di raggiungere o danneggiare il personaggio controllato.

Nel tempo potranno esistere diverse categorie.

## Nemici comuni

Costituiscono la maggioranza delle orde.

Generalmente:

* sono numerosi;
* hanno comportamenti relativamente semplici;
* creano pressione attraverso la quantità.

## Nemici speciali

Possiedono comportamenti differenti rispetto all'inseguimento standard.

Potrebbero, ad esempio:

* attaccare a distanza;
* effettuare cariche;
* esplodere;
* rallentare il giocatore;
* creare ostacoli;
* evocare altri nemici;
* proteggere le altre unità.

## Élite

Versioni più pericolose e resistenti dei nemici normali.

Possono comparire all'interno di determinate ondate e rappresentare una minaccia prioritaria.

## Boss

Nemici principali di una determinata fase della partita.

I boss dovrebbero richiedere una maggiore attenzione al movimento, al posizionamento e all'utilizzo delle abilità.

Il loro funzionamento dettagliato è ancora da definire.

---

# 7. Sistema dei personaggi

Ogni personaggio rappresenta uno degli amici su cui è basato il progetto.

La scelta del personaggio non deve essere puramente estetica.

Ogni personaggio possiede almeno:

**una Passiva**, sempre attiva;

**una Attiva**, utilizzabile direttamente dal giocatore.

Queste due caratteristiche definiscono il nucleo della sua identità di gameplay.

L'obiettivo è fare in modo che scegliere un personaggio significhi scegliere anche un particolare **stile di gioco**.

---

# 8. Magno

## Ruolo

Mobilità e controllo delle orde.

## Passiva — Flusso Aerodinamico

Aumenta la velocità di movimento base.

Magno può quindi:

* riposizionarsi più facilmente;
* attraversare aperture nelle orde;
* mantenere maggiore distanza dai nemici;
* evitare situazioni pericolose.

## Attiva — Onda d'Urto Tellurica

Genera una potente onda d'urto circolare intorno al personaggio.

L'onda:

* infligge danni;
* colpisce i nemici nelle vicinanze;
* respinge gli avversari.

È principalmente uno strumento di controllo e di emergenza quando Magno viene circondato.

---

# 9. Bea

## Ruolo

Evasione e riposizionamento.

## Passiva — Sesto Senso Equino

Conferisce una probabilità di evitare completamente un colpo ricevuto.

## Attiva — Powerslide

Bea si teletrasporta rapidamente in linea retta lasciando dietro di sé una scia di fuoco.

La scia:

* rimane temporaneamente sul terreno;
* danneggia i nemici che la attraversano;
* permette contemporaneamente a Bea di riposizionarsi.

---

# 10. Zat

## Ruolo

Gestione del danno e sopravvivenza attraverso il recupero.

## Passiva — Guarigione Ritardata

Una parte dei danni ricevuti non viene sottratta definitivamente alla salute.

Il danno viene invece trasformato in una quantità recuperabile gradualmente nel tempo.

Per recuperarla, Zat deve riuscire a evitare ulteriori danni per un determinato periodo.

La meccanica deve creare un'alternanza tra:

**momenti di rischio → fuga o riposizionamento → recupero.**

## Attiva — Tempesta di Tuoni

Genera un tuono che colpisce i nemici presenti sul campo dopo un breve preavviso.

⚡ L'attiva è principalmente orientata al danno e alla gestione di grandi quantità di avversari.

---

# 11. Alea

## Ruolo

Progressione e crescita.

## Passiva — Metodo di Insegnamento

Il funzionamento originale della passiva era collegato all'aumento dell'esperienza ottenuta.

Poiché la progressione non utilizza più gemme esperienza e il Level Up avviene al termine delle ondate, questa passiva **deve essere riprogettata o reinterpretata**.

L'identità concettuale di Alea deve comunque rimanere collegata alla capacità di:

* apprendere più rapidamente;
* ottenere un vantaggio nella progressione;
* sfruttare meglio i Level Up.

### Stato

**DA DEFINIRE.**

Una possibile direzione futura potrebbe riguardare una maggiore qualità, quantità o efficacia delle scelte offerte durante il Level Up, ma la meccanica definitiva non è ancora stabilita.

## Attiva — Gran Piroetta

Alea esegue una rotazione rapida ad ampio raggio.

Durante la rotazione colpisce ripetutamente i nemici circostanti.

È un'abilità principalmente orientata:

* al danno ravvicinato;
* alla pulizia dello spazio;
* alla gestione delle situazioni in cui Alea viene circondata.

---

# 12. Aleo

## Ruolo

Resistenza e controllo del territorio.

## Passiva — Struttura Solida

Riduce una percentuale dei danni subiti e aumenta la resistenza agli effetti di spostamento.

Aleo è quindi naturalmente più difficile da abbattere.

## Attiva — Colata di Cemento

Crea una zona di cemento sul terreno.

I nemici che entrano nella zona:

* vengono fortemente rallentati;
* ricevono un leggero danno nel tempo.

La capacità consente ad Aleo di modificare temporaneamente il campo di battaglia.

---

# 13. Lollo

## Ruolo

Velocità, caos e imprevedibilità.

## Passiva — Iperattività ADHD

Aumenta:

* velocità di movimento;
* rapidità delle azioni offensive.

L'eventuale componente di movimento imprevedibile è ancora da valutare durante il prototipo, perché non deve compromettere il controllo diretto del personaggio.

## Attiva — Cosplay Casuale

Quando utilizza la propria attiva, Lollo assume un costume ispirato casualmente a un altro personaggio.

Utilizza quindi **l'abilità attiva del personaggio selezionato casualmente**.

Ogni utilizzo può quindi produrre un effetto differente.

Il sistema deve leggere l'elenco delle abilità disponibili degli altri personaggi e selezionarne casualmente una valida.

---

# 14. Migi

## Ruolo

Difesa e controllo delle orde.

## Passiva — Guscio Empatico

Aumenta la capacità difensiva del personaggio.

Quando la salute scende sotto una determinata soglia viene inoltre generato uno scudo temporaneo.

Lo scudo deve essere sottoposto a un sistema di cooldown o a una limitazione equivalente per evitare attivazioni continue.

## Attiva — Rallentamento Zen

Genera una zona intorno a Migi nella quale i nemici vengono fortemente rallentati.

L'obiettivo dell'abilità è creare temporaneamente uno spazio sicuro nel quale:

* riposizionarsi;
* evitare di essere circondati;
* recuperare il controllo della situazione.

---

# 15. Marghe

## Ruolo

Indebolimento e manipolazione dell'aggro.

## Passiva — Sorriso Contagioso

Riduce la salute massima dei nemici presenti nella partita.

Valore iniziale concettuale:

**-5% salute massima dei nemici.**

L'effetto sui boss dovrà essere valutato separatamente durante il bilanciamento.

## Attiva — Reggeton time!

Marghe genera nella propria ultima posizione un clone che balla reggaeton.

I nemici che stavano inseguendo Marghe cambiano temporaneamente bersaglio e si dirigono verso la copia.

La meccanica permette di:

* interrompere l'inseguimento;
* creare spazio;
* attraversare una zona pericolosa;
* riposizionarsi.

La durata dell'illusione e le regole precise con cui viene gestito l'aggro dovranno essere definite durante l'implementazione.

---

# 16. Abilità attive

Le abilità attive rappresentano uno degli elementi centrali dell'identità dei personaggi.

A differenza di eventuali sistemi offensivi automatici, vengono attivate direttamente dal giocatore.

Ogni abilità deve avere almeno:

* un effetto;
* una durata, quando necessaria;
* un cooldown;
* eventuali parametri di danno;
* eventuali parametri di area;
* eventuali effetti secondari.

Una delle principali decisioni del giocatore deve essere **quando utilizzare l'abilità**.

L'attiva non deve essere semplicemente un pulsante da utilizzare appena disponibile.

Idealmente deve esistere un vantaggio nel conservarla per situazioni particolarmente pericolose.

---

# 17. Cooldown

Ogni abilità attiva dispone di un tempo di ricarica.

Il cooldown rappresenta una delle principali leve di bilanciamento.

Un'abilità particolarmente forte potrà avere:

* cooldown maggiore;
* durata inferiore;
* area più limitata;
* condizioni particolari.

Il valore preciso dei cooldown non è ancora definito.

---

# 18. Sistema di combattimento automatico

Il progetto prevede un sistema nel quale almeno una parte dell'offensiva del personaggio possa avvenire automaticamente.

Il funzionamento preciso non è ancora stato deciso.

In particolare devono ancora essere definite le logiche relative a:

* armi;
* numero di armi disponibili;
* acquisizione delle armi;
* miglioramento delle armi;
* eventuali evoluzioni;
* attacchi automatici;
* sistemi alternativi alle armi tradizionali.

### Stato

**SISTEMA DA PROGETTARE.**

Per il momento il documento non assume che il giocatore possieda necessariamente un inventario di armi o che il Level Up debba essere basato sull'acquisizione di nuove armi.

---

# 19. Sistema di build

Il concetto generale di build rimane importante, ma la sua implementazione non è ancora definita.

Durante una partita il giocatore dovrà progressivamente modificare o potenziare il proprio personaggio.

Possibili elementi della futura build potrebbero includere:

* statistiche;
* modificatori;
* abilità;
* effetti passivi;
* potenziamenti specifici del personaggio;
* sistemi offensivi;
* sistemi difensivi;
* effetti legati alle abilità attive.

La struttura definitiva verrà progettata dopo aver validato il loop base di:

**movimento → combattimento → ondata → Level Up.**

---

# 20. Statistiche

Le statistiche definitive del gioco non sono ancora stabilite.

Potrebbero essere utilizzati valori come:

* salute massima;
* movimento;
* danno;
* velocità di attacco;
* difesa;
* rigenerazione;
* area degli effetti;
* durata degli effetti;
* cooldown;
* probabilità di schivata;
* knockback;
* resistenza al knockback.

Le statistiche dovrebbero essere introdotte solamente quando hanno una funzione concreta all'interno dei sistemi effettivamente implementati.

---

# 21. Mappe

Le partite si svolgono all'interno di mappe nelle quali vengono generate le orde.

Le mappe potranno eventualmente differenziarsi attraverso:

* dimensioni;
* struttura;
* ostacoli;
* zone aperte;
* passaggi stretti;
* elementi interattivi;
* nemici esclusivi;
* eventi;
* boss.

Una possibile direzione tematica consiste nell'utilizzare luoghi e riferimenti collegati al gruppo di amici.

Il sistema dettagliato delle mappe è ancora da definire.

---

# 22. Progressione permanente

È possibile prevedere in futuro una progressione esterna alla singola partita.

Questa potrebbe consentire lo sblocco di:

* personaggi;
* mappe;
* contenuti;
* modificatori;
* miglioramenti;
* elementi estetici;
* modalità aggiuntive.

### Stato

**DA DEFINIRE.**

Il sistema non è necessario per il primo prototipo del gameplay.

---

# 23. Priorità di sviluppo

La prima versione giocabile dovrebbe concentrarsi sulle meccaniche fondamentali.

## Priorità 1 — Movimento

Il personaggio deve:

* muoversi correttamente;
* interagire con i limiti della mappa;
* essere facilmente controllabile.

## Priorità 2 — Nemici

Deve esistere almeno un nemico base capace di:

* comparire;
* individuare il giocatore;
* inseguirlo;
* danneggiarlo;
* ricevere danni;
* morire.

## Priorità 3 — Sistema delle ondate

Deve essere possibile:

* iniziare un'ondata;
* generare nemici;
* rilevare il completamento;
* passare alla fase successiva;
* aumentare progressivamente la difficoltà.

## Priorità 4 — Level Up

Alla fine dell'ondata:

* il personaggio sale di livello;
* viene aperta una fase di scelta;
* il giocatore seleziona un potenziamento;
* la partita continua con l'ondata successiva.

Il contenuto dei potenziamenti può inizialmente essere estremamente semplice.

## Priorità 5 — Personaggi

Implementare progressivamente:

* passive;
* attive;
* cooldown;
* differenze statistiche.

Per il primo prototipo non è necessario implementare immediatamente tutti gli otto personaggi.

## Priorità 6 — Sistema offensivo

Solamente dopo aver validato il loop principale dovrà essere progettato in maniera più approfondita il sistema relativo a:

* attacchi;
* armi;
* build;
* evoluzioni;
* sinergie.

---

# 24. Principi di progettazione

Durante lo sviluppo dovrebbero essere mantenuti alcuni principi fondamentali.

### Controlli semplici

Il giocatore deve poter comprendere rapidamente come muoversi e utilizzare il personaggio.

### Profondità attraverso le decisioni

La complessità deve derivare principalmente da:

* posizionamento;
* gestione delle orde;
* scelta dei potenziamenti;
* utilizzo delle abilità;
* costruzione progressiva del personaggio.

### Personaggi realmente differenti

Ogni personaggio deve modificare concretamente il modo di giocare.

Non devono essere semplicemente variazioni statistiche dello stesso personaggio.

### Progressione leggibile

Il giocatore deve percepire chiaramente l'aumento di potenza tra un'ondata e quella successiva.

### Escalation

La partita deve diventare progressivamente più caotica e difficile.

### Evitare sistemi prematuri

Una meccanica non ancora validata non deve essere trattata come definitiva solamente perché presente nel documento.

---

# 25. Decisioni attualmente confermate

Le seguenti logiche possono essere considerate parte della direzione attuale del progetto:

* il gioco è strutturato intorno a orde;
* il giocatore controlla direttamente il movimento;
* esistono più personaggi;
* ogni personaggio possiede una passiva unica;
* ogni personaggio possiede un'abilità attiva unica;
* le abilità attive utilizzano un cooldown;
* completare un'ondata provoca un Level Up;
* non esistono gemme esperienza da raccogliere;
* il Level Up permette di sviluppare il personaggio;
* le ondate aumentano progressivamente di difficoltà;
* il funzionamento dettagliato di armi e build non è ancora definito.

---

# 26. Questioni aperte

I principali sistemi ancora da progettare sono:

* cosa viene offerto esattamente durante un Level Up;
* quante opzioni vengono mostrate;
* come funzionano gli attacchi base;
* se esisteranno delle vere e proprie armi;
* quante capacità offensive può avere contemporaneamente un personaggio;
* come vengono migliorate durante la partita;
* se esistono evoluzioni;
* durata delle singole ondate;
* numero totale di ondate;
* condizioni di vittoria;
* condizioni precise di sconfitta;
* struttura dei boss;
* sistemi di ricompensa;
* progressione permanente;
* funzionamento delle mappe;
* bilanciamento delle passive;
* bilanciamento delle attive;
* sistema definitivo della passiva di Alea.

Questo elenco deve essere aggiornato durante lo sviluppo man mano che vengono prese nuove decisioni.

---

# 27. Obiettivo del primo prototipo

Il primo prototipo non deve dimostrare l'intero gioco.

Deve rispondere soprattutto a una domanda:

**“È divertente muoversi all'interno di un'orda, sopravvivere, utilizzare l'abilità del proprio personaggio e diventare più forte dopo ogni ondata?”**

Una prima versione può quindi essere composta semplicemente da:

**1 mappa + 1 personaggio + 1 nemico base + sistema di ondate + 1 abilità attiva + Level Up semplice.**

Se questo loop risulta divertente, gli altri sistemi possono essere costruiti progressivamente sopra questa base.

---

# 28. Identità del progetto

Pidgeon Survivor deve mantenere come elemento centrale il fatto che i personaggi siano versioni reinterpretate ed esagerate di persone reali appartenenti allo stesso gruppo di amici.

Le meccaniche possono quindi nascere da:

* personalità;
* abitudini;
* passioni;
* professioni;
* caratteristiche riconoscibili;
* battute interne;
* episodi condivisi.

L'obiettivo non è solamente creare personaggi differenti dal punto di vista meccanico.

Ogni personaggio dovrebbe essere riconoscibile dal gruppo anche semplicemente osservandone **il modo in cui gioca**.

Questa relazione tra personalità reale e gameplay rappresenta una delle principali identità di Pidgeon Survivor.
