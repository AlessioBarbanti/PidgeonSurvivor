---
id: PS-111
titolo: Correggi PS-109 - AskUserQuestion non è disponibile ai sotto-agenti
tipo: fix
area: tooling
stato: COMPLETATO
priorita: media
dipende_da: [PS-109]
origine: prova pratica del workflow PS-109/PS-110 su PS-104/PS-106, 2026-09-06
creato: 2026-09-06
aggiornato: 2026-09-06
---

# PS-111 — Correggi PS-109: AskUserQuestion non è disponibile ai sotto-agenti

## Contesto

[PS-109](./PS-109-consulta-game-art-designer-prima-di-fissare-criteri-art.md)
ha dato al game-art-designer lato Claude lo strumento `AskUserQuestion` per
interpellare direttamente il proprietario in modalità pianificazione. Il
proprietario ha chiesto una prova pratica su un caso reale (PS-104/PS-106,
l'ambiguità sul numero di stati di riempimento del calice Sobrietà di Alea):
invocato come sotto-agente tramite lo strumento `Agent`, il game-art-designer
ha ricevuto l'errore `AskUserQuestion is not available inside subagents` e ha
correttamente rifiutato di procedere decidendo lui stesso la direzione,
rigirando invece la domanda (con l'analisi già pronta) all'orchestratore.
Il comportamento dell'agente è stato corretto — non ha inventato un consenso
implicito — ma il design scritto in PS-109 presuppone una capacità che non
esiste in questo ambiente.

## Comportamento atteso

Il game-art-designer in modalità pianificazione non tenta più di
interpellare direttamente il proprietario: prepara le domande/opzioni (con
l'analisi tecnica a supporto) nel proprio report finale, e restituisce il
turno all'orchestratore. È l'orchestratore (la sessione `card-crea` che l'ha
invocato) a porre la domanda con `AskUserQuestion` e a rigirargli la
risposta con `SendMessage` perché finalizzi la card. Il risultato osservabile
per il proprietario non cambia — viene comunque interpellato prima che la
card diventi `PRONTO` — cambia solo chi, tecnicamente, gli pone la domanda.

## Criteri di accettazione

- [x] `.claude/agents/game-art-designer.md` non elenca più `AskUserQuestion`
      fra i propri strumenti (non utilizzabile, fuorviante lasciarlo).
- [x] La sezione "Modalità pianificazione" descrive il flusso corretto:
      il sotto-agente prepara domande/opzioni nel report finale invece di
      usare `AskUserQuestion`; l'orchestratore le pone al proprietario e
      rimanda la risposta con `SendMessage` prima che il sotto-agente
      finalizzi la card.
- [x] `.claude/skills/card-crea/SKILL.md` riflette lo stesso flusso corretto
      (chi pone la domanda, come arriva la risposta al sotto-agente).
- [x] `docs/cards/README.md` sincronizza la regola di delega (PS-109) con
      questa correzione.
- [x] Verificato che il flusso corretto funziona davvero: nella prova
      pratica su PS-104/PS-106, l'orchestratore ha posto la domanda
      rigirata dal sotto-agente, ricevuto la risposta dal proprietario, e
      rimandato la risposta al sotto-agente (stesso `agentId`, tramite
      `SendMessage`) che ha finalizzato PS-104 con la decisione presa.

## Ambito

- `.claude/agents/game-art-designer.md`.
- `.claude/skills/card-crea/SKILL.md`.
- `docs/cards/README.md`.

Non toccare:

- `.agents/skills/game-art-designer/SKILL.md` (contratto condiviso
  Claude/Codex): il suo confine "non interpellare il proprietario" resta
  corretto così com'è — descrive la modalità produzione, che non è
  interessata da questa correzione.
- `.codex/agents/game-art-designer.toml`: mai stato interessato, Codex non
  ha mai avuto accesso ad `AskUserQuestion` né alla modalità pianificazione.
- PS-109, PS-110: restano storiche sotto il contratto con cui sono state
  scritte; questa card ne corregge un dettaglio tecnico, non le riapre.

## Verifica

- Nessuno smoke GUT: cambia solo documentazione di processo. Verifica per
  prova pratica reale (non solo lettura incrociata): l'intera catena
  orchestratore → domanda al proprietario → risposta → `SendMessage` al
  sotto-agente → finalizzazione della card ha funzionato end-to-end su
  PS-104 durante la stessa sessione in cui è stato scoperto il problema.
- Profilo minimo prima della chiusura: nessuno (nessun codice o dato di
  runtime cambia).

## Gate manuali

- [ ] Runtime Windows: non applicabile
- [ ] Validazione statica APK: non applicabile
- [ ] Runtime fisico Pixel 9: non applicabile
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-09-06 — Scoperta durante una prova pratica richiesta dal
  proprietario, non da un'ispezione a priori.** Nessuna delle letture
  incrociate fatte in chiusura di PS-109 aveva rivelato il limite: serviva
  un'invocazione reale del sotto-agente per emergere. Motivo in più per non
  considerare "verificato" un cambio di workflow multi-agente senza almeno
  una prova end-to-end su un caso reale.
- **2026-09-06 — L'agente ha reagito correttamente all'errore.** Non ha
  deciso lui stesso la direzione né si è bloccato: ha preparato l'analisi e
  rigirato la domanda all'orchestratore. Questo comportamento resta il
  contratto voluto; PS-111 lo rende esplicito invece di lasciarlo emergere
  per caso ogni volta.
- **Sostituisce:** la sola menzione di `AskUserQuestion` come strumento
  diretto del sotto-agente in PS-109; il resto del design (chi decide cosa,
  quando si consulta, il confine con l'esecutore Codex) resta invariato.

## Documenti sincronizzati

- [x] `docs/cards/README.md`: regola di delega corretta.

## Note

Card gemella di [PS-109](./PS-109-consulta-game-art-designer-prima-di-fissare-criteri-art.md)
e [PS-110](./PS-110-placeholder-asset-e-stato-in-attesa-asset.md): stessa
linea di lavoro, corretta alla prima prova pratica invece di scoprirla in
produzione. La prova stessa (PS-104/PS-106) resta la card che l'ha originata.
