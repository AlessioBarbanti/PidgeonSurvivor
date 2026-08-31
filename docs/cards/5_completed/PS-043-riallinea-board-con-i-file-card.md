---
id: PS-043
titolo: Riallineare la board ai file-card realmente presenti
tipo: chore
area: docs
stato: COMPLETATO
priorita: alta
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-043 — Riallineare la board ai file-card realmente presenti

## Contesto

La review del 31 agosto 2026 ha rilevato che
[docs/cards/README.md](../README.md) elenca 38 righe mentre sotto
`docs/cards/` esistono 41 file-card. Tre card attive non compaiono nella board:
[PS-025](../2_to_do/PS-025-aumenta-dimensioni-avvertimento-boss.md),
[PS-028](../2_to_do/PS-028-rendi-piroetta-alea-circolare.md) e
[PS-029](../2_to_do/PS-029-rendi-tell-stato-personaggi-piu-visibili.md).

Il disallineamento va anche nella direzione opposta: la board conteneva righe
per PS-010 e PS-011 mentre i due file non erano più presenti sotto
`docs/cards/`.

La board è dichiarata "sola fonte di verità operativa": finché è incompleta,
qualunque scelta di priorità parte da dati sbagliati.

## Comportamento atteso

La tabella della board contiene esattamente una riga per ogni file-card
presente sotto `docs/cards/`, con link alla cartella di fase corretta e
metadati (tipo, area, stato, priorità, dipendenze) identici al frontmatter del
file.

## Criteri di accettazione

- [x] Il numero di righe della tabella in `docs/cards/README.md` è uguale al
      numero di file `PS-*.md` sotto `docs/cards/` (escluso `_TEMPLATE.md`).
- [x] PS-025, PS-028 e PS-029 hanno una riga nella board.
- [x] Nessuna riga della board punta a un file inesistente; la situazione di
      PS-010 e PS-011 è risolta ripristinando i file oppure registrando
      esplicitamente in questa card cosa ne è stato deciso.
- [x] Per ogni riga, il percorso del link punta alla cartella che corrisponde
      allo stato dichiarato nel frontmatter (`idea`/`to_do`/`to_test`/`completed`).
- [x] Per ogni riga, titolo, tipo, area, stato, priorità e `dipende_da`
      coincidono con il frontmatter del file corrispondente.
- [x] Le righe restano ordinate per ID crescente come oggi.
- [x] Nessun file-card viene rinominato, spostato o modificato nel contenuto
      per far tornare la board.

## Ambito

- `docs/cards/README.md`.
- Solo il frontmatter dei file-card, e solo se contiene un errore evidente
  rispetto alla cartella in cui il file già si trova.

Non toccare:

- il contenuto delle card (contesto, criteri, decisioni);
- lo stato reale di una card per comodità di allineamento;
- il vocabolario degli stati e la struttura delle quattro cartelle.

## Verifica

- Nessuno smoke: la card non tocca il runtime.
- Controllo automatico eseguito con uno script di audit temporaneo che
  confronta riga per riga la tabella con il frontmatter dei file: esito finale
  `righe senza file: 0`, `file senza riga: 0`, `disallineamenti: nessuno`,
  `file 53 / righe 53`.
- Profilo minimo prima della chiusura: nessuno (card solo documentale).

## Gate manuali

- [ ] Runtime Windows — non pertinente.
- [ ] Validazione statica APK — non pertinente.
- [ ] Runtime fisico Pixel 9 — non pertinente.
- [x] Controllo percettivo richiesto: no

## Decisioni

- **2026-08-31 — La board si adegua ai file, non viceversa.** Le tre card
  mancanti erano lavoro reale già aperto: sono state registrate, non chiuse
  d'ufficio.
- **2026-08-31 — PS-010 e PS-011 sono ritirate su decisione del proprietario.**
  I due file erano già stati eliminati dal worktree; alla domanda esplicita il
  proprietario ha confermato che la cancellazione era voluta. Le due righe sono
  state rimosse dalla board e i file non vengono ripristinati. Le uniche
  ricorrenze rimaste dei due ID sono esempi di riga di comando in
  `docs/setup.md` e `docs/verification-workflow.md`, dove il valore serve solo
  come argomento del parametro `-Milestone`.
- **2026-08-31 — I titoli della board sono stati riallineati al frontmatter.**
  Ventuno righe portavano una variante all'infinito del titolo mentre la card
  usa la forma imperativa richiesta da `_TEMPLATE.md`; per PS-017 e PS-033 la
  differenza era anche di contenuto. Il file-card resta la fonte, la board
  l'indice.
- **2026-08-31 — Nessun controllo automatico permanente.** L'audit è stato
  eseguito con uno script usa-e-getta fuori dal repository: aggiungere un gate
  al runner sarebbe una card separata, non un'estensione silenziosa di questa.

## Documenti sincronizzati

- [x] `docs/cards/README.md`: tabella rigenerata dai frontmatter, 53 righe.
- [x] `docs/cards/1_idea/PS-055-filosofia-della-vittoria.md`: rimossi i due
      riferimenti a PS-010, che non esiste più.

## Note

Verifica rapida del disallineamento, riutilizzabile in futuro:

```powershell
(Get-ChildItem docs/cards -Recurse -Filter 'PS-*.md').Count
(Select-String -Path docs/cards/README.md -Pattern '^\| \[PS-').Count
```

Un conteggio uguale è condizione necessaria ma non sufficiente: il confronto
riga per riga con il frontmatter resta l'unico controllo che intercetta titoli,
stati o cartelle divergenti.

Se il disallineamento si ripete, valutare in una card separata un controllo
automatico nel runner; questa card non lo introduce.
