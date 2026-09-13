---
id: PS-167
titolo: Elimina la dominante gialla dagli artwork
tipo: art
area: arte
stato: DA DEFINIRE
priorita: bassa
dipende_da: [PS-084]
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-11
---

# PS-167 — Elimina la dominante gialla dagli artwork

## Contesto

Il playtest percepisce una dominante giallo/seppia ricorrente negli artwork, abbastanza forte da ricordare un filtro notturno. Il progetto usa però famiglie separate per ritratti Player, ritratti Evil, carousel, sprite di gameplay, UI e fondali; ciascuna deriva da master e pipeline differenti. La prima stesura chiedeva di correggere genericamente gli «artwork principali» e demandava l'inventario alla fase di esecuzione, in contrasto con PS-109: una card `art` non può diventare `PRONTO` senza asset esatti, direzione e geometria di consegna già decisi.

## Domande da chiudere con proprietario e Game Art Designer

1. In quali schermate/asset è visibile il difetto: ritratti Player, Evil, carousel, sprite, fondali o UI? Servono screenshot nominati come evidenza, non l'intero albero `assets/art/` per presunzione.
2. Il risultato desiderato è una correzione cromatica dei master esistenti o una rigenerazione? Le due strade hanno rischi diversi su identità, trasparenza e provenienza.
3. Quale campione minimo va prodotto per primo e approvato prima di propagare il trattamento?
4. Quali bianchi, incarnati, metalli o accenti freddi costituiscono i riferimenti interni positivi, senza rimuovere il calore intenzionale di brace e griglia?

## Vincoli già accertati

- Conservare silhouette, accessori e reference approvate descritte in `docs/characters/<id>.md` (PS-084).
- Ogni candidato resta fuori dai percorsi runtime, in `_review`, finché il proprietario non lo promuove esplicitamente.
- La card `art` produce master/candidato/derivato di review e aggiorna il manifest; sostituzione e wiring runtime appartengono a una card di integrazione separata (PS-090).
- Verificare alpha reale, dimensioni e leggibilità alla scala finale; un confronto colore su master HD non basta.

## Ambito

- Nessuna produzione finché l'inventario degli asset affetti e la strategia non sono approvati.
- Dopo la decisione, riscrivere Comportamento atteso e criteri con percorsi esatti, master, derivati, manifest e campione di review.

## Verifica

- Da definire con l'elenco degli asset. Nessun GUT o gate runtime nella card `art` non cablata; restano obbligatori audit statico degli asset e approvazione percettiva del proprietario.

## Decisioni

- **2026-09-11 — Riclassificata `DA DEFINIRE`.** «Tutti gli artwork principali» non è uno scope eseguibile e non distingue fra famiglie di asset indipendenti.
- **2026-09-11 — PS-109 e PS-112 sono regole di workflow, non prerequisiti di prodotto.** Rimossi da `dipende_da`; PS-084 resta il riferimento durevole alla direzione del cast.
- **2026-09-11 — Separata da PS-168.** Questa idea riguarda temperatura/white balance; forma, volumi e materiali restano un problema distinto.
- **2026-09-11 — Priorità bassa finché lo scope non è nominato.** Il finding visivo è credibile, ma una revisione estesa del cast viene dopo la stabilizzazione del gameplay e non parte senza campioni e percorsi esatti.

## Documenti sincronizzati

- [ ] `docs/visual-audio-identity.md`, `docs/characters/<id>.md` e manifest soltanto dopo l'approvazione di una direzione concreta.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. La formulazione «olio giallo ovunque» resta evidenza percettiva, non un criterio tecnico né un'autorizzazione a modificare tutto il catalogo.
