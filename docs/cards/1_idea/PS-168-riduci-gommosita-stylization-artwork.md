---
id: PS-168
titolo: Riduci la gommosità della stilizzazione dei personaggi
tipo: art
area: arte
stato: DA DEFINIRE
priorita: bassa
dipende_da: [PS-167]
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-11
---

# PS-168 — Riduci la gommosità della stilizzazione dei personaggi

## Contesto

Il playtest descrive alcuni personaggi come morbidi, gonfi o «gommosi», con materiali e volumi troppo generici. Questo finding non coincide con PS-116/PS-132: quelle card trattano risoluzione nativa e qualità della derivazione degli sprite di gameplay, mentre qui il possibile difetto è nella direzione dei master/ritratti stessi. La prima stesura non identificava però quali famiglie o personaggi mostrino davvero il problema e fissava tre ritratti campione senza sceglierli.

La valutazione va fatta dopo aver separato l'effetto della dominante cromatica di PS-167; altrimenti temperatura colore, materiali e volumi verrebbero giudicati insieme.

## Domande da chiudere con proprietario e Game Art Designer

1. Il difetto è nei ritratti Player, nei ritratti Evil, nei carousel, negli sprite di gameplay o in più famiglie? Indicare file/screenshot esatti.
2. Quali tre personaggi rappresentano davvero morfologie e materiali diversi per il campione iniziale?
3. Quali attributi osservabili vanno corretti — silhouette, volume del volto, pelle, tessuti, capelli, outline — e quali tratti approvati devono restare invariati?
4. Il trattamento richiede editing dei master esistenti o nuova sintesi? Quale campione deve approvare il proprietario prima di estenderlo al cast?

## Vincoli già accertati

- Non imitare né chiedere di «allontanarsi da» uno stile proprietario specifico: tradurre i riferimenti del feedback in attributi osservabili.
- Conservare riconoscibilità, accessori e reference autorizzate in `docs/characters/<id>.md`.
- Non riaprire PS-116/PS-132: risoluzione, canvas e downscale sono fuori scope salvo evidenza che il difetto dipenda davvero da quella pipeline.
- Candidati non cablati in `_review`; promozione e integrazione seguono una card separata dopo approvazione esplicita.

## Ambito

- Nessuna produzione finché superfici, campione e trattamento non sono approvati.
- Dopo la decisione, fissare percorsi, geometrie, prompt/edit instructions, manifest e criteri percettivi specifici.

## Verifica

- Da definire col campione. Nessun GUT o gate runtime per la card `art` non integrata; confronto a scala finale e approvazione del proprietario restano obbligatori.

## Decisioni

- **2026-09-11 — Riclassificata `DA DEFINIRE`.** La card non può scegliere i tre campioni o la tecnica durante l'esecuzione.
- **2026-09-11 — PS-116/PS-132 sono confinanti ma non duplicati.** Questa idea riguarda la grammatica visiva dei master, non il numero di pixel o la derivazione.
- **2026-09-11 — Dipende da PS-167 per la valutazione percettiva.** La forma non va giudicata attraverso un cast ancora alterato da una dominante globale non risolta.
- **2026-09-11 — Priorità bassa.** È una revisione ampia e soggettiva della direzione artistica: si affronta dopo il gameplay e soltanto sul campione approvato successivo a PS-167.

## Documenti sincronizzati

- [ ] `docs/visual-audio-identity.md`, `docs/characters/<id>.md` e manifest pertinenti solo dopo una direzione approvata.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno.
