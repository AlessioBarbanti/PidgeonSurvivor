---
name: card-crea
description: Crea una card di modifica o richiesta per Pidgeon Survivor come piccolo file md in docs/cards/, in stile board. Usala quando il proprietario segnala un problema, chiede una modifica, propone un'idea o dice "apri una card", "segnati questa cosa", "aggiungila alla board" — invece di implementare subito.
---

# Crea una card

Questa skill **non implementa**. Trasforma una richiesta in una card piccola,
verificabile e risolvibile da sola in un'altra sessione.

## 1. Capisci la richiesta

1. Leggi [docs/cards/README.md](../../../docs/cards/README.md) e le card
   esistenti: se ne esiste una che copre la stessa cosa, **aggiornala** invece di
   duplicarla.
2. Controlla se il tema appartiene già a una slice del
   [development plan](../../../docs/development-plan.md). In quel caso la card
   deve puntarla nel campo `milestone`, non riscriverne il contratto.
3. Ispeziona rapidamente il codice interessato quanto basta per nominare i file e
   i contratti in gioco. Una card che sbaglia l'ambito costa più di una card che
   non esiste.

## 2. Scrivi la card

- ID progressivo `PS-<numero>` guardando i file esistenti; nome file
  `PS-007-nome-slug.md` in [docs/cards/](../../../docs/cards/).
- Parti da [`_TEMPLATE.md`](../../../docs/cards/_TEMPLATE.md) e compila **tutti**
  i campi del frontmatter. Date in formato `YYYY-MM-DD`.
- Stato iniziale:
  - `PRONTO` se il contratto è chiaro e le dipendenze sono chiuse;
  - `BLOCCATO` se manca una dipendenza: nominala esplicitamente;
  - `DA DEFINIRE` se manca una decisione del proprietario: scrivi la domanda
    precisa da porgli.
- I **criteri di accettazione** sono osservabili e binari. "Il pulsante abilità
  resta premibile mentre il joystick è tenuto" è un criterio; "migliorare il
  touch" non lo è.
- Nella sezione Ambito elenca anche i contratti che non vanno toccati
  (`RunController`, flusso `welcome → tutorial → selezione → run → pausa`,
  registry degli effetti).
- In Verifica proponi il nome dello smoke e il marker; in Gate manuali marca solo
  i gate realmente pertinenti alla modifica.

## 3. Registra e riporta

1. Aggiungi la riga alla tabella in
   [docs/cards/README.md](../../../docs/cards/README.md).
2. Non modificare il development plan per una card: se la richiesta è grande
   abbastanza da meritare una slice B-series, dillo e proponi la promozione.
3. Riporta al proprietario: ID, titolo, stato scelto, e — se lo stato è
   `DA DEFINIRE` o `BLOCCATO` — la domanda o la dipendenza esatta che sblocca.
4. Non implementare nulla in questa sessione se non ti viene chiesto.
