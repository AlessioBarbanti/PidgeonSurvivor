---
id: PS-112
titolo: Vieta l'accesso diretto a ImageGen al game-art-designer lato Claude
tipo: fix
area: tooling
stato: COMPLETATO
priorita: media
dipende_da: []
origine: risoluzione pratica di PS-107, 2026-09-07
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-112 — Vieta l'accesso diretto a ImageGen al game-art-designer lato Claude

## Contesto

Durante la risoluzione di [PS-107](../2_to_do/PS-107-rigenera-icona-punto-di-cottura.md)
(rigenerazione dell'icona di Punto di Cottura), l'orchestratore ha invocato il
game-art-designer lato Claude in modalità produzione, che ha usato il proprio
accesso diretto ai tool MCP ImageGen (`generate_image`/`edit_image`/
`generate_image_set`) per generare il nuovo master. Questo era un
comportamento esplicitamente documentato e intenzionale
(`.agents/skills/game-art-designer/SKILL.md` elencava "su Claude i tool MCP
..." come percorso valido al pari di quello Codex), non un bug.

Il proprietario ha chiesto conto della scelta e ha espresso una preferenza
netta osservandola in pratica: la generazione vera e propria deve passare
sempre dal processo Codex esterno — lo stesso che ha prodotto realmente
l'asset di [PS-104](../5_completed/PS-104-icona-calice-sobrieta-alea.md) in
un'altra sessione mentre si lavorava su altro — mai dall'accesso diretto
ImageGen del sotto-agente Claude. Ha però scelto esplicitamente di non
interrompere la generazione già in corso su PS-107 ("lasciamo correre per
stavolta"): questa card corregge il comportamento futuro, non retroattivamente
quell'istanza.

## Comportamento atteso

Il game-art-designer lato Claude non ha più accesso ai tool MCP ImageGen. In
modalità produzione, se una card richiede nuova sintesi visiva e non esiste
già un master prodotto da Codex da rifinire/integrare, l'agente si ferma e
segnala che la generazione è di competenza del processo Codex esterno, senza
tentare di generarla con altri mezzi né bloccarsi in attesa indefinita — fa
comunque tutto il resto che non richiede sintesi (identificazione di scena e
funzione, famiglia visiva, mini art direction, geometria di consegna). Il
resto della modalità produzione (art review su asset già generati,
derivazione deterministica via `process-*.ps1`, manifest, integrazione,
criterio di completamento) resta invariato e disponibile su entrambi gli
agenti.

## Criteri di accettazione

- [x] `.claude/agents/game-art-designer.md`: la riga `tools:` non elenca più
      i tre tool MCP ImageGen.
- [x] La sezione dedicata (ex "Interfaccia ImageGen attiva") è riscritta per
      chiarire che il sotto-agente Claude non genera mai direttamente, e
      descrive cosa fare quando una card richiede nuova sintesi non ancora
      prodotta da Codex (fermarsi, fare il resto del lavoro non-sintesi,
      segnalare esplicitamente nel report e nella card).
- [x] `.agents/skills/game-art-designer/SKILL.md` (contratto condiviso
      Claude/Codex): la frase sull'interfaccia ImageGen attiva è corretta per
      riflettere che la sintesi è riservata a Codex; le trasformazioni
      deterministiche (`process-*.ps1`) restano su entrambi.
- [x] `docs/cards/README.md`: la regola di delega delle card `tipo: art`
      (introdotta insieme a PS-109) riporta esplicitamente il vincolo.
- [x] La generazione già avviata su PS-107 con l'accesso diretto non viene
      interrotta retroattivamente, per richiesta esplicita del proprietario:
      questa card non riapre né invalida quell'istanza.
- [ ] Verifica end-to-end su un caso reale futuro: un'invocazione produzione
      del game-art-designer Claude su una card che richiede nuova sintesi si
      ferma correttamente e segnala Codex invece di generare comunque — non
      ancora osservato in pratica (a differenza di PS-111, che aveva la prova
      nella stessa sessione in cui è stato scoperto il problema). Lasciato
      esplicitamente aperto, non spuntato per abitudine.

## Ambito

- `.claude/agents/game-art-designer.md`.
- `.agents/skills/game-art-designer/SKILL.md`.
- `docs/cards/README.md`.

Non toccare:

- `.codex/agents/game-art-designer.toml`: Codex resta l'unico esecutore di
  sintesi, nessun cambio di comportamento richiesto lì.
- PS-107: già in corso di risoluzione con l'accesso diretto quando è emersa
  questa decisione; non viene fermata né riaperta da questa card.
- PS-109/PS-110/PS-111: restano storiche sotto il contratto con cui sono
  state scritte; nessuna riguardava l'accesso diretto a ImageGen.

## Verifica

- Nessuno smoke GUT: cambia solo documentazione di processo/istruzioni di
  agente, nessun runtime di gioco coinvolto.
- Non ancora verificato end-to-end (vedi criterio aperto sopra): serve
  un'invocazione reale futura del game-art-designer Claude su una card `art`
  che richieda sintesi nuova, per confermare che si ferma davvero invece di
  aggirare il vincolo.

## Gate manuali

- [ ] Runtime Windows: non applicabile
- [ ] Validazione statica APK: non applicabile
- [ ] Runtime fisico Pixel 9: non applicabile
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-09-07 — Scoperta osservando una risoluzione reale, non da
  ispezione a priori.** Il comportamento era documentato e intenzionale fin
  da quando l'agente Claude ha ricevuto i tool ImageGen; è stato messo in
  discussione solo dopo che il proprietario lo ha visto applicato su PS-107.
- **2026-09-07 — Il proprietario ha scelto di non interrompere la
  generazione già in corso su PS-107.** La card corregge solo le
  invocazioni successive; non tratta l'istanza in corso come una violazione
  da rimediare.
- **Sostituisce:** la menzione dell'accesso diretto Claude a ImageGen in
  `.claude/agents/game-art-designer.md` e in
  `.agents/skills/game-art-designer/SKILL.md`; il resto del contratto
  (confini, art review, criterio di completamento, modalità pianificazione)
  resta invariato.

## Documenti sincronizzati

- [x] `docs/cards/README.md`: regola di delega corretta con il vincolo.

## Note

Non è una card gemella di PS-109/PS-110/PS-111 nello stesso senso (quelle
correggevano il flusso di consultazione pre-`PRONTO`): questa restringe
invece chi, tecnicamente, può eseguire la sintesi in modalità produzione. Va
letta insieme a quelle per il quadro completo del ciclo di vita di una card
`art`.
