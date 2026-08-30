---
name: card-crea
description: Crea una card di modifica o richiesta per Pidgeon Survivor come piccolo file md nella cartella di fase sotto docs/cards/, in stile board. Usala quando il proprietario segnala un problema, chiede una modifica, propone un'idea o dice "apri una card", "segnati questa cosa", "aggiungila alla board" — invece di implementare subito.
---

# Crea una card

Questa skill **non implementa**. Trasforma una richiesta in una card piccola,
verificabile e risolvibile da sola in un'altra sessione.

## 1. Capisci la richiesta

1. Leggi [docs/cards/README.md](../../../docs/cards/README.md) e le card
   esistenti: se ne esiste una che copre la stessa cosa, **aggiornala** invece di
   duplicarla.
2. Cerca richieste equivalenti, decisioni già prese e riferimenti storici nelle
   card e nei documenti durevoli. Non creare roadmap o decision log paralleli.
3. Ispeziona rapidamente il codice interessato quanto basta per nominare i file e
   i contratti in gioco. Una card che sbaglia l'ambito costa più di una card che
   non esiste.

## 2. Scrivi la card

- ID progressivo `PS-<numero>` guardando ricorsivamente i file esistenti; nome
  file `PS-007-nome-slug.md` nella cartella della fase sotto
  [docs/cards/](../../../docs/cards/).
- Parti da [`_TEMPLATE.md`](../../../docs/cards/_TEMPLATE.md) e compila **tutti**
  i campi del frontmatter. Date in formato `YYYY-MM-DD`.
- Stato iniziale:
  - `PRONTO` se il contratto è chiaro e le dipendenze sono chiuse: salva in
    `to_do/`;
  - `BLOCCATO` se manca una dipendenza: nominala esplicitamente e salva in
    `to_do/`;
  - `DA DEFINIRE` se manca una decisione del proprietario: scrivi la domanda
    precisa da porgli e salva in `idea/`.
- Compila `dipende_da` con soli ID card; usa `origine` esclusivamente per un
  riferimento storico B-series, mai come seconda fonte del contratto.
- I **criteri di accettazione** sono osservabili e binari. "Il pulsante abilità
  resta premibile mentre il joystick è tenuto" è un criterio; "migliorare il
  touch" non lo è.
- Nella sezione Ambito elenca anche i contratti che non vanno toccati
  (`RunController`, flusso `welcome → tutorial → selezione → run → pausa`,
  registry degli effetti).
- In Verifica proponi il nome dello smoke e il marker; in Gate manuali marca solo
  i gate realmente pertinenti alla modifica.
- In `Decisioni` registra le scelte già confermate, quelle aperte e ciò che la
  card sostituisce. In `Documenti sincronizzati` elenca i contratti durevoli che
  dovranno ricevere il solo risultato finale.

## 3. Registra e riporta

1. Aggiungi la riga alla tabella in
   [docs/cards/README.md](../../../docs/cards/README.md), con il link alla
   cartella della fase corretta.
2. Controlla che metadati, dipendenze e riga della board restino allineati.
3. Qualunque dimensione del lavoro resta una card: non promuoverla a B-series.
4. Riporta al proprietario: ID, titolo, stato scelto, e — se lo stato è
   `DA DEFINIRE` o `BLOCCATO` — la domanda o la dipendenza esatta che sblocca.
5. Non implementare nulla in questa sessione se non ti viene chiesto.
