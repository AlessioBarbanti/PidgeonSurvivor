# Contratto immagini di riferimento per ImageGen

Le immagini di riferimento possono essere usate sia per modificare un'immagine
esistente sia per guidare una nuova generazione. La documentazione ufficiale
raccomanda un piccolo insieme di riferimenti quando servono ruoli distinti,
come contenuto, stile, composizione o linee guida.

## Distingui l'intento

- **Generazione guidata:** il risultato è un nuovo asset; i riferimenti
  definiscono regole visive, non un'immagine da modificare.
- **Editing:** almeno un riferimento è il target da trasformare e deve essere
  identificato esplicitamente come tale.

Le istruzioni e lo schema dell'interfaccia ImageGen attiva hanno sempre la
precedenza sul presente contratto. Usa soltanto il meccanismo di input che
l'interfaccia consente per quel tipo di operazione. Se non consente di allegare
riferimenti a una nuova generazione, ispezionali con `view_image` e traduci nel
prompt le caratteristiche osservabili necessarie; non forzare parametri
riservati all'editing.

## Seleziona e descrivi i riferimenti

- Usa il set minimo sufficiente e non includere automaticamente tutte le
  immagini recenti.
- Assegna a ogni riferimento un ruolo esplicito: `style`, `composition`,
  `scale`, `subject` oppure `edit target`.
- Dichiara cosa trasferire e cosa non copiare. Esempio: “riferimento 1 per
  palette e tratto; non copiare soggetto, testo o composizione”.
- Quando l'interfaccia lo consente, usa percorsi espliciti o il numero minimo
  di immagini recenti necessario a includere tutti e soli i riferimenti scelti.

## Verifica e provenienza

Controlla che il candidato non abbia ereditato per errore soggetti, loghi,
testo, sfondi o dettagli estranei. Nel manifest registra il prompt finale e i
riferimenti di progetto materialmente usati, specificandone il ruolo. Non
inventare licenze o provenienze non dimostrate.

## Reference fotografiche del cast

Le fotografie personali autorizzate dal proprietario come `subject reference`
per le caricature pixel-art del cast vivono in
`docs/characters/references/<id>/`, mai in un percorso runtime. Il documento
`docs/characters/<id>.md`, quando esiste, riassume quale reference è
associata a ciascun personaggio e il suo ruolo dichiarato. Usale solo come
`subject`, mai come `edit target` per un output fotorealistico, e solo se la
card autorizza esplicitamente un soggetto reale (vedi i confini in
`.agents/skills/game-art-designer/SKILL.md`).

Riferimento: <https://learn.chatgpt.com/docs/image-generation>
