---
id: PS-008
titolo: Introduci eventi d'ondata
tipo: feat
area: gameplay
stato: PRONTO
priorita: alta
dipende_da: []
origine: B46
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-008 — Introduci eventi d'ondata

## Contesto

La progressione ordinaria dello spawn tende a produrre una run continua e poco segmentata.

Servono eventi brevi e riconoscibili che modifichino temporaneamente direzione, composizione o ritmo delle orde. Gli eventi contribuiscono a ridurre il comportamento AFK definito da PS-007.

## Comportamento atteso

Durante la run possono attivarsi eventi d'ondata separati dallo spawn ordinario.

Ogni evento:

* ha durata finita;
* usa una formazione o composizione riconoscibile;
* termina automaticamente;
* lascia poi riprendere lo spawn ordinario;
* è deterministico rispetto al seed della run;
* offre sempre una possibilità concreta di lettura e reazione;
* non richiede necessariamente un telegraph preventivo.

Principio generale:

**leggibilità obbligatoria, telegraph opzionale.**

Il telegraph è richiesto soltanto quando la formazione potrebbe creare una minaccia immediata prima che il Player abbia il tempo materiale di reagire.

Non è ammesso il caso:

**sorpresa → danno inevitabile.**

Baseline iniziale:

* nessun evento prima di `02:30`;
* non più di un evento attivo contemporaneamente;
* frequenza degli eventi configurabile.

Introdurre almeno tre eventi.

### Accerchiamento

Nemici generati temporaneamente da più settori attorno al Player.

Richiede telegraph preventivo perché la formazione può ridurre contemporaneamente più vie di fuga.

Deve sempre lasciare almeno una risposta di movimento leggibile.

### Stormo laterale

Un gruppo compatto di nemici entra prevalentemente da un lato dell'arena.

Non richiede telegraph preventivo.

I primi nemici che entrano costituiscono il segnale dell'evento. Distanza e velocità devono lasciare al Player tempo sufficiente per reagire.

### Nido di tiratori

Per una finestra limitata aumenta sensibilmente la presenza relativa dei tiratori.

Non richiede telegraph globale.

La composizione dell'orda comunica l'evento e ogni tiratore mantiene il proprio telegraph individuale prima di sparare.

Durante un evento lo spawn ordinario può continuare a ritmo ridotto oppure essere temporaneamente sostituito, secondo configurazione dell'evento.

Alla fine dell'evento lo spawn ordinario riprende senza recuperare spawn arretrati.

Gli eventi non possono iniziare durante un Boss. Un evento maturato durante uno scontro Boss viene scartato o rinviato secondo una regola dati esplicita, senza accumulare una coda di eventi arretrati.

## Criteri di accettazione

* [ ] Esistono almeno tre eventi distinti: Accerchiamento, Stormo laterale e Nido di tiratori.
* [ ] Nessun evento può iniziare prima della soglia temporale configurata.
* [ ] Non possono essere attivi due eventi contemporaneamente.
* [ ] Ogni evento possiede una durata finita.
* [ ] Ogni evento offre una finestra di reazione sufficiente prima di produrre una minaccia inevitabile.
* [ ] Gli eventi che possono creare una minaccia immediata usano un telegraph preventivo.
* [ ] Gli eventi senza telegraph sono leggibili tramite comparsa, posizione o comportamento dei nemici.
* [ ] Accerchiamento usa un telegraph preventivo.
* [ ] Accerchiamento non chiude simultaneamente tutte le vie di fuga.
* [ ] Stormo laterale può iniziare senza telegraph dedicato.
* [ ] Stormo laterale lascia tempo materiale per reagire dopo la comparsa dei primi nemici.
* [ ] Nido di tiratori può iniziare senza telegraph globale.
* [ ] I tiratori mantengono il proprio telegraph individuale durante Nido di tiratori.
* [ ] Nido di tiratori non produce sovrapposizioni di attacchi inevitabili.
* [ ] La densità complessiva continua a rispettare `max_alive_enemies`.
* [ ] Alla fine dell'evento lo spawn ordinario riprende senza recuperare spawn arretrati.
* [ ] Nessun evento inizia mentre un Boss è attivo.
* [ ] Non si accumula una coda incontrollata di eventi durante un Boss.
* [ ] Lo stesso seed produce la stessa sequenza di eventi e formazioni.
* [ ] Pausa, level-up e Boss Intro congelano scheduler e telegraph eventualmente attivi.
* [ ] Restart elimina completamente evento, scheduler, telegraph e stato residuo.

## Ambito

* `GameDirector`.
* `EnemySpawner`.
* Scheduler degli eventi.
* Definizioni dati degli eventi.
* Settori e formazioni di spawn.
* Telegraph world/HUD per i soli eventi che lo richiedono.
* Integrazione con stato Boss.
* Cleanup e reset.
* Test di integrazione dedicato.

Non modificare:

* comportamento interno degli archetipi esistenti;
* statistiche del Player;
* powerup;
* Signature Ability degli Evil;
* targeting automatico;
* cap massimo dei nemici vivi;
* regole generali di pausa.

Non introdurre nuovi archetipi nemici come requisito di questa card.

## Verifica

* Smoke: `tests/integration/_wave_events_smoke.gd` → marker `WAVE_EVENTS_SMOKE_OK`
* Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

* [ ] Runtime Windows
* [ ] Validazione statica APK
* [ ] Runtime fisico Pixel 9 (percorso: run oltre `02:30` → incontra Accerchiamento → Stormo laterale → Nido di tiratori)
* [ ] Controllo percettivo richiesto: sì
* [ ] Accerchiamento è leggibile prima della chiusura dell'orda.
* [ ] Stormo laterale sorprende senza risultare ingiusto.
* [ ] Nido di tiratori è riconoscibile senza un banner dedicato.
* [ ] I telegraph individuali dei tiratori restano leggibili durante l'evento.
* [ ] Nessun evento produce danno prima che il Player abbia avuto una possibilità concreta di reagire.
* [ ] Gli eventi spezzano percettivamente il ritmo della run.
* [ ] Una build forte resta avvantaggiata ma non può ignorare sistematicamente gli eventi.
* [ ] Gli eventi contribuiscono a ridurre il comportamento AFK definito da PS-007.

## Decisioni

- **2026-08-30 — Leggibilità obbligatoria, telegraph condizionale.** Il
  telegraph serve quando senza preavviso la formazione produrrebbe danno
  inevitabile.
- **2026-08-30 — Eventi deterministici e non sovrapposti.** La prima baseline
  consente un solo evento attivo e conserva la riproducibilità del seed.
- **Baseline da playtest — primo evento dopo 02:30 e almeno tre tipologie.**

- **2026-08-30 — Confine con la curva ordinaria PS-007.** Gli eventi
  compongono temporaneamente i pesi e i settori effettivi di `EnemySpawnProfile`
  e, quando terminano, restituiscono il controllo alla curva late-run. PS-008
  non duplica la garanzia del tiratore ne' rende PS-007 dipendente dagli eventi.

## Documenti sincronizzati

- [ ] `prd.md`: regole finali degli eventi d'ondata.
- [ ] Nota di verifica con seed, composizioni e leggibilità osservata.

## Note

PS-008 è uno strumento per raggiungere l'obiettivo di PS-007, ma il completamento di questa card non implica automaticamente che il problema AFK sia risolto.

Gli eventi devono cambiare temporaneamente **come il giocatore si muove e reagisce**, non soltanto aumentare il numero di nemici.

Il telegraph viene usato solo quando necessario per rendere equa la minaccia.

Baseline iniziale:

* primo evento dopo `02:30`;
* almeno tre tipologie;
* massimo un evento contemporaneo.

Frequenza, durata e composizioni restano valori configurabili da playtest.

L'implementazione deve riusare le API dati PS-007 per pesi effettivi e
probabilita' multisettore; un evento puo' applicare un override temporaneo, ma
non deve mantenere una seconda curva ordinaria parallela.
