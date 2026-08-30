---
id: PS-003
titolo: Conferma il funzionamento di Guarigione Ritardata
tipo: chore
area: gameplay
stato: PRONTO
priorita: alta
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-003 — Conferma il funzionamento di Guarigione Ritardata

## Contesto

La passiva di Zat, **Guarigione Ritardata**, converte una parte del danno subito in salute recuperabile e la restituisce se Zat riesce a evitare ulteriori colpi per un certo periodo.

Prima di basare Tempesta di Tuoni sulla quantità di HP recuperabili è necessario confermare esattamente il comportamento runtime della passiva e verificare che coincida con il comportamento desiderato.

## Comportamento atteso

Confermare e documentare almeno questi aspetti:

* quale percentuale del danno ricevuto diventa recuperabile;
* dopo quanto tempo senza subire danni inizia il recupero;
* se il recupero avviene istantaneamente o progressivamente;
* quanto dura il recupero completo;
* cosa succede alla quota recuperabile se Zat viene colpita nuovamente;
* se nuovi danni si sommano alla quota già recuperabile;
* quale sia il limite massimo di HP recuperabili accumulabili;
* cosa accade se Zat riceve un colpo letale mentre possiede HP recuperabili;
* come vengono gestiti heal esterni o variazioni degli HP massimi;
* se pausa, level-up e Boss intro congelano correttamente attesa e recupero;
* se restart e cambio personaggio azzerano completamente lo stato della passiva.

Al termine della verifica il comportamento effettivo deve essere registrato come contratto autorevole prima di collegarlo a PS-004.

## Criteri di accettazione

* [ ] È confermata la percentuale di ogni hit che diventa HP recuperabili.
* [ ] È confermato il tempo necessario senza nuovi danni prima dell'inizio della guarigione.
* [ ] È confermato se la guarigione è istantanea o progressiva.
* [ ] Se progressiva, sono confermati durata e ritmo del recupero.
* [ ] È documentato cosa succede alla quota recuperabile quando Zat viene colpita durante l'attesa.
* [ ] È documentato cosa succede alla quota recuperabile quando Zat viene colpita durante il recupero.
* [ ] È confermato se più hit accumulano HP recuperabili e con quale limite.
* [ ] È verificato il comportamento in caso di danno letale.
* [ ] È verificata l'interazione con eventuali cure e modifiche degli HP massimi.
* [ ] Attesa e guarigione non avanzano durante stati non `RUNNING`.
* [ ] Restart e cambio personaggio eliminano completamente gli HP recuperabili e ogni timer associato.
* [ ] Il comportamento confermato è compatibile con la lettura degli HP recuperabili richiesta da PS-004.
* [ ] Eventuali differenze tra comportamento runtime e comportamento desiderato sono registrate esplicitamente prima di modificare il codice.

## Ambito

Sistemi da verificare:

* `FriendDefinition` di Zat;
* controller delle passive;
* `HealthComponent` del Player;
* timer e stato runtime di Guarigione Ritardata;
* pause e transizioni del `RunController`;
* restart e cambio personaggio.

Non modificare durante questa card:

* Tempesta di Tuoni;
* valori o meccaniche della passiva prima della conclusione della verifica;
* comportamento delle passive degli altri personaggi.

Questa card serve prima di tutto a **stabilire il contratto corrente**. Eventuali correzioni emerse dalla verifica devono essere eseguite tramite una card separata o tramite un aggiornamento esplicito di questa card.

## Verifica

* Smoke: `tests/integration/_zat_delayed_healing_contract_smoke.gd` → marker `ZAT_DELAYED_HEALING_CONTRACT_SMOKE_OK`
* Copertura minima:

  * singolo colpo;
  * più colpi consecutivi;
  * nuovo colpo durante l'attesa;
  * nuovo colpo durante il recupero;
  * pausa durante l'attesa;
  * pausa durante il recupero;
  * danno letale;
  * restart;
  * cambio personaggio.
* Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

* [ ] Runtime Windows
* [ ] Runtime fisico Pixel 9
* [ ] Verificare visivamente che la salute recuperabile sia comprensibile durante una run reale.
* [ ] Verificare che un nuovo colpo produca il comportamento atteso sia durante l'attesa sia durante la guarigione.
* [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-08-30 — Nessun dettaglio della passiva viene assunto.** Percentuali,
  tempi, accumulo e casi limite devono essere confermati prima di diventare
  contratto.
- **2026-08-30 — PS-004 resta bloccata da questa verifica.** Il danno di
  Tempesta di Tuoni non può dipendere da uno stato ancora ambiguo.

## Documenti sincronizzati

- [ ] `characters.md`: contratto finale di Guarigione Ritardata.
- [ ] PS-004: termini e dati confermati da usare come dipendenza.

## Note

Il comportamento descritto attualmente per Zat è:

**parte del danno subito resta recuperabile; se Zat evita altri colpi per alcuni secondi, quella quota torna indietro.**

Questa card non assume ulteriori dettagli finché non vengono verificati nel runtime e nei dati.

PS-003 è prerequisito di **PS-004 — Lega Tempesta di Tuoni al danno recuperabile**, perché la nuova potenza del Tuono dipende dalla quantità corrente di HP recuperabili.
