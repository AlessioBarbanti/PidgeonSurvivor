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

## 2. Se la richiesta tocca l'arte, consulta prima il game-art-designer

Non scrivere tu "Comportamento atteso" e "Criteri di accettazione" quando la
richiesta:

- è ambigua o soggettiva sulla direzione visiva (es. "il personaggio deve
  essere meno vistoso", "più minaccioso", "più coerente con le altre
  schermate") — non è ancora chiaro *cosa* cambiare concretamente (scala?
  palette? posa? animazione?), oppure
- implica generare un asset che dovrà contenere o comporsi con contenuto
  variabile a runtime (un ritratto, un'icona, del testo) o integrarsi in un
  layout Godot esistente (nine-slice, safe area, overlay).

In questi casi invoca l'agente `game-art-designer` in modalità
pianificazione (vedi `.claude/agents/game-art-designer.md`) **prima** di
redigere quelle due sezioni. Il sotto-agente non può interpellare
direttamente il proprietario (`AskUserQuestion` non è disponibile ai
sotto-agenti, PS-111): ti restituirà le domande mirate sulla direzione
(idealmente come opzioni concrete già analizzate) e, se prevede nuova arte
da integrare, la scomposizione in pezzi/geometria di consegna. Poni tu quelle
domande al proprietario con `AskUserQuestion`, poi rispondi al sotto-agente
con `SendMessage` perché finalizzi la card. Scrivi
"Comportamento atteso"/"Criteri di accettazione" solo a quel punto, con le
risposte già in mano.

Non serve questo passaggio quando la richiesta è già concreta e non tocca
arte (es. "sposta questo pulsante a destra", "cambia questo numero"), o
quando riusa arte esistente senza ambiguità (es. "usa lo stesso stile del
pulsante di pausa anche qui").

L'esecutore Codex (`.codex/agents/game-art-designer.toml`) resta comunque un
puro produttore: non è mai lui a rispondere a queste domande, e non va
invocato in questa fase.

## 3. Scrivi la card

- ID progressivo `PS-<numero>` guardando ricorsivamente i file esistenti; nome
  file `PS-007-nome-slug.md` nella cartella della fase sotto
  [docs/cards/](../../../docs/cards/).
- Parti da [`_TEMPLATE.md`](../../../docs/cards/_TEMPLATE.md) e compila **tutti**
  i campi del frontmatter. Date in formato `YYYY-MM-DD`.
- Stato iniziale:
  - `PRONTO` se il contratto è chiaro e le dipendenze sono chiuse: salva in
    `2_to_do/`;
  - `BLOCCATO` se manca una dipendenza: nominala esplicitamente e salva in
    `2_to_do/`;
  - `DA DEFINIRE` se manca una decisione del proprietario: scrivi la domanda
    precisa da porgli e salva in `1_idea/`.
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
- Quando la richiesta implica sia produrre nuova arte sia usarla in gioco
  (wiring in un `.tres`, una scena o un registry), il default è **due card
  collegate** (PS-090): una `tipo: art` che si ferma a master, derivato,
  manifest e art review, e una `feat`/`fix`/`ux`/`chore` di integrazione che
  la referenzia via `dipende_da`. Scrivi una sola card mista solo se
  l'integrazione è banale a sufficienza da restare un singolo criterio di
  accettazione esplicitamente marcato come tale — non come scelta di default.

## 4. Registra e riporta

1. Aggiungi la riga alla tabella in
   [docs/cards/README.md](../../../docs/cards/README.md), con il link alla
   cartella della fase corretta.
2. Controlla che metadati, dipendenze e riga della board restino allineati.
3. Qualunque dimensione del lavoro resta una card: non promuoverla a B-series.
4. Riporta al proprietario: ID, titolo, stato scelto, e — se lo stato è
   `DA DEFINIRE` o `BLOCCATO` — la domanda o la dipendenza esatta che sblocca.
5. Non implementare nulla in questa sessione se non ti viene chiesto.
