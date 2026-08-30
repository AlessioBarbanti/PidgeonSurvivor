---
id: PS-007
titolo: Impedisci che la late run diventi AFK
tipo: feat
area: gameplay
stato: PRONTO
priorita: alta
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-007 — Impedisci che la late run diventi AFK

## Contesto

Con una build offensiva abbastanza sviluppata, la pressione delle orde può diventare inferiore alla capacità di clear automatico del Player.

Il risultato osservato è che, nella parte avanzata della run, il giocatore può arrivare a restare fermo e guardare il gioco eliminare automaticamente i nemici.

Il piano gameplay aveva già identificato lo stesso problema come **D4 — la run non ha arco**: dopo circa `02:40` la progressione dello spawn tende ad appiattirsi e la run cambia troppo poco nel tempo.

## Comportamento atteso

Dopo la fase iniziale della run, una build forte deve continuare a far sentire il Player potente, ma non deve eliminare la necessità di:

* muoversi;
* leggere la composizione dell'orda;
* reagire ai nemici speciali;
* scegliere dove posizionarsi;
* gestire l'abilità attiva;
* prepararsi agli incontri Boss.

La difficoltà late-run deve crescere soprattutto tramite **pressione qualitativa**, non esclusivamente aumentando HP e danno dei nemici.

Strumenti ammessi includono:

* maggiore presenza relativa degli archetipi speciali già esistenti;
* combinazioni più pericolose fra tiratori, corazzati, divisori e sciami;
* pressione proveniente da più direzioni;
* finestre temporanee con densità o composizioni particolari;
* eventi d'ondata definiti separatamente da PS-008;
* Signature Ability dei Boss definite da PS-006;
* variazioni dello spawn che costringano a riposizionarsi.

Una build offensiva completa deve continuare a produrre un vantaggio evidente: la soluzione non deve annullare i powerup o trasformare ogni nemico in una spugna di HP.

## Scenario di riferimento AFK

Introdurre uno scenario riproducibile di playtest per misurare il problema.

Baseline:

* tempo run: `>= 03:00`;
* build offensiva di riferimento con danno e frequenza di fuoco elevati;
* Player posizionato in una zona non protetta dagli ostacoli;
* nessun movimento;
* nessuna abilità attiva utilizzata;
* seed fisso;
* gameplay lasciato avanzare per `10 s`.

Lo scenario deve produrre almeno una **pressione significativa** entro la finestra:

* il Player subisce almeno un danno effettivo;

oppure

* un attacco/proiettile/area pericolosa raggiunge la sua posizione e richiede movimento per essere evitato.

Il test non richiede che il Player muoia.

L'obiettivo è impedire la situazione:

**build forte → resto fermo → nessuna minaccia raggiunge il Player.**

## Criteri di accettazione

* [ ] Dopo `03:00` la composizione delle orde continua a evolvere in modo osservabile.
* [ ] La progressione late-run non consiste esclusivamente nell'aumento degli HP nemici.
* [ ] Lo scenario AFK di riferimento produce una minaccia significativa entro `10 s`.
* [ ] La minaccia dello scenario AFK richiede movimento per essere evitata.
* [ ] Una build offensiva forte continua a eliminare i nemici comuni più efficacemente di una build neutra.
* [ ] Aumentare il danno del Player continua a produrre un vantaggio osservabile.
* [ ] I nemici speciali non vengono sostituiti da semplici varianti con più HP.
* [ ] Il tiratore resta una fonte di pressione rilevante anche quando il clear dei nemici melee è molto elevato.
* [ ] La pressione late-run può arrivare contemporaneamente da più di una tipologia di nemico.
* [ ] Non viene introdotto scaling dinamico nascosto basato direttamente sul danno o sui powerup posseduti dal Player.
* [ ] La stessa run e lo stesso seed producono la stessa sequenza delle componenti randomizzate.
* [ ] Pausa, level-up e Boss intro non fanno avanzare scheduler o escalation.
* [ ] Restart ripristina completamente la curva di difficoltà iniziale.

## Ambito

Sistemi che possono essere modificati:

* `GameDirector`;
* profili di spawn;
* pesi e finestre temporali degli archetipi;
* composizione delle orde;
* scheduler di pressione late-run;
* parametri dati dei nemici quando necessario;
* integrazione futura con PS-008.

Non modificare come soluzione primaria:

* potenza dei powerup offensivi già ottenuti;
* targeting automatico del Player;
* funzionamento delle abilità dei personaggi;
* HP dei nemici come unica leva di difficoltà;
* statistiche del Player tramite scaling nascosto;
* probabilità delle carte in funzione della forza corrente della build.

La difficoltà deve essere una proprietà della progressione della run, non una penalizzazione invisibile perché il giocatore ha costruito una buona build.

## Verifica

* Smoke: `tests/integration/_late_run_pressure_smoke.gd` → marker `LATE_RUN_PRESSURE_SMOKE_OK`
* Copertura minima:

  * curva iniziale invariata;
  * evoluzione della composizione dopo `03:00`;
  * archetipi speciali eleggibili secondo le finestre previste;
  * scenario AFK con seed fisso;
  * determinismo;
  * congelamento degli scheduler fuori da `RUNNING`;
  * reset completo della curva.
* Profilo minimo prima della chiusura: `Relevant`

Lo smoke automatico deve verificare i contratti di spawn e la presenza di una sorgente di minaccia nello scenario di riferimento. La valutazione sul fatto che la run sia effettivamente meno passiva resta anche un gate di playtest.

## Gate manuali

* [ ] Runtime Windows
* [ ] Validazione statica APK
* [ ] Runtime fisico Pixel 9
* [ ] Playtest con build offensiva forte oltre `03:00`.
* [ ] Restando volontariamente fermi per `10 s`, il Player deve essere costretto a reagire o subire una minaccia concreta.
* [ ] Muovendosi e giocando correttamente, la stessa situazione deve restare sopravvivibile.
* [ ] Una build forte continua a trasmettere una sensazione evidente di potenza.
* [ ] L'aumento di difficoltà non viene percepito principalmente come aumento artificiale degli HP.
* [ ] Tiratori e altri archetipi speciali restano leggibili durante orde dense.
* [ ] Il Player non viene costretto a movimento continuo senza possibilità di scelta.
* [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-08-30 — Pressione qualitativa prima dei soli aumenti numerici.** La
  late run deve creare movimento e decisioni, non soltanto più HP o danno.
- **2026-08-30 — PS-008 è uno strumento, non il criterio di chiusura.** Gli
  eventi d'ondata da soli non dimostrano che lo scenario AFK sia risolto.
- **Baseline da playtest — finestra AFK di 10 secondi.** Il valore può cambiare
  sulla base delle prove reali.

## Documenti sincronizzati

- [ ] `prd.md`: arco della run e pressione late-game risultanti.
- [ ] Nota di verifica con scenario AFK ripetibile e risultati misurati.

## Note

PS-007 definisce **il risultato da ottenere**, non una singola soluzione tecnica.

PS-008 — eventi d'ondata è uno degli strumenti previsti per aumentare la pressione e creare un arco nella run, ma PS-007 non deve essere considerata completata automaticamente quando PS-008 viene implementata.

Il problema non è che una build forte uccida molti nemici. Questo comportamento è desiderato.

Il problema è che la potenza offensiva possa eliminare completamente la necessità di giocare.

Principio di riferimento:

**late run più difficile = nuove decisioni e nuova pressione, non soltanto numeri più grandi.**

La baseline `10 s` dello scenario AFK è un valore iniziale da playtest e può essere modificata sulla base delle prove reali.
