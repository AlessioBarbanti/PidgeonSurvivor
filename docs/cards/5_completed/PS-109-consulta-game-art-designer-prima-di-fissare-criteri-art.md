---
id: PS-109
titolo: Consulta il game-art-designer prima di fissare i criteri di una card che tocca l'arte
tipo: chore
area: tooling
stato: COMPLETATO
priorita: media
dipende_da: [PS-090]
origine: conversazione del proprietario 2026-09-06
creato: 2026-09-06
aggiornato: 2026-09-06
---

# PS-109 — Consulta il game-art-designer prima di fissare i criteri di una card che tocca l'arte

## Contesto

Dopo [PS-090](./PS-090-separa-generazione-integrazione-card-art.md)
una card `tipo: art` si ferma alla produzione e una card di integrazione
separata la cabla in gioco. Ma **nessuna delle due fasi consulta chi ha
competenza artistica/tecnica prima che i criteri della card vengano
fissati**: `card-crea` scrive da sola "Comportamento atteso"/"Criteri di
accettazione", spesso partendo da una richiesta ambigua e soggettiva del
proprietario (es. "il personaggio deve essere meno vistoso"), e decide da
sola se serve nuova arte o basta riusare quella esistente, senza interpellare
nessuno.

Il caso concreto che ha originato questa card:
[PS-102](./PS-102-cornice-dedicata-boss-intro.md) →
[PS-103](../4_to_test/PS-103-integra-cornice-boss-intro.md). L'asset della
cornice Boss Intro è stato consegnato come un'unica immagine composita, senza
alcun dato di geometria (dove sta il foro del ritratto, quali margini sono
sicuri per il testo). L'agente Game Art Designer lo ha eseguito correttamente
rispetto alla card scritta — ma nessuno aveva deciso, prima della
generazione, che l'asset dovesse essere consegnato a pezzi pensati per
l'integrazione. La scoperta del problema è arrivata solo durante il wiring
(PS-103), con reverse engineering dei pixel via script ad-hoc e sei
iterazioni di tuning a tentoni contro la safe area — lavoro interamente
evitabile se la scomposizione fosse stata decisa a monte.

## Comportamento atteso

Quando una richiesta tocca l'aspetto grafico in modo ambiguo (direzione
soggettiva non ancora decisa) o implica un asset che dovrà contenere/comporsi
con contenuto variabile a runtime (ritratto, icona, testo) o integrarsi in un
layout esistente, `card-crea` **non fissa da sola** "Comportamento
atteso"/"Criteri di accettazione": delega prima la consultazione al
game-art-designer lato Claude (il solo che può interpellare il proprietario),
che pone le domande mirate sulla direzione e — se prevede nuova arte da
integrare — decide anche la scomposizione in pezzi/geometria di consegna,
prima che la card diventi `PRONTO`.

L'esecutore Codex resta e resterà un puro produttore: riceve solo card già
complete di direzione, genera gli asset richiesti e non fa nient'altro — non
pone mai domande al proprietario né decide da solo la direzione artistica.

## Criteri di accettazione

- [x] `.claude/skills/card-crea/SKILL.md` dichiara il nuovo passaggio: se la
      richiesta è ambigua sulla direzione visiva o implica un asset da
      integrare con contenuto variabile a runtime, non scrive da sola
      "Comportamento atteso"/"Criteri di accettazione", ma delega prima al
      game-art-designer in modalità pianificazione.
- [x] `.claude/agents/game-art-designer.md` distingue esplicitamente due
      modalità: **pianificazione** (invocata da `card-crea`, prima che la
      card sia `PRONTO`: usa `AskUserQuestion` per interpellare il
      proprietario, decide scomposizione in pezzi/geometria, non genera
      nulla) e **produzione** (quella già esistente, invariata, su una card
      già `PRONTO` e completa). Ha in dotazione lo strumento
      `AskUserQuestion`.
- [x] `.agents/skills/game-art-designer/SKILL.md` (contratto condiviso
      Claude/Codex, produzione) dichiara esplicitamente che l'esecutore non
      interpella mai il proprietario per decisioni di direzione artistica:
      se la card lascia margini realmente ambigui su questo, si ferma e lo
      segnala invece di deciderlo lui stesso.
- [x] `.codex/agents/game-art-designer.toml` riafferma lo stesso confine
      (nessuna domanda al proprietario, nessuna decisione di direzione non
      già fissata dalla card).
- [x] `docs/cards/README.md` sincronizza la regola di delega esistente
      (PS-090) con questo nuovo passaggio preventivo.

## Ambito

- `.claude/skills/card-crea/SKILL.md`
- `.claude/agents/game-art-designer.md`
- `.agents/skills/game-art-designer/SKILL.md`
- `.codex/agents/game-art-designer.toml`
- `docs/cards/README.md`

Non toccare:

- `.claude/skills/asset-pipeline/SKILL.md`: derivazione tecnica (script,
  manifest), non decisione di direzione — non pertinente a questa card.
- `card-risolvi`: il flusso di risoluzione/produzione a valle non cambia.
- Le card `art` già prodotte ([PS-102](./PS-102-cornice-dedicata-boss-intro.md)
  compresa): restano storiche sotto il contratto con cui sono state
  lavorate, non vanno riaperte per questa regola.

## Verifica

- Nessuno smoke GUT: questa card cambia solo documentazione di processo, non
  runtime. La verifica è una lettura incrociata delle cinque fonti toccate:
  non si contraddicono e la nuova regola resta seguibile da una sessione che
  parte da zero.
- Profilo minimo prima della chiusura: nessuno (nessun codice o dato di
  runtime cambia).

## Gate manuali

- [ ] Runtime Windows: non applicabile
- [ ] Validazione statica APK: non applicabile
- [ ] Runtime fisico Pixel 9: non applicabile
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-09-06 — Origine pratica, non teorica.** La sessione di oggi
  (PS-102 → PS-103) ha mostrato in concreto il costo di non consultare
  nessuno prima di fissare i criteri di una card `art`: reverse engineering
  dei pixel della cornice e sei iterazioni di tuning a tentoni contro la
  safe area, tutto lavoro che una consultazione preventiva avrebbe evitato.
- **2026-09-06 — Il ruolo di pianificazione resta solo lato Claude, mai su
  Codex.** Per richiesta esplicita del proprietario: l'agente delegato alla
  generazione (Codex) deve restare un esecutore puro — prende una card
  completa, genera l'asset, non fa nient'altro. Non ha inoltre, in questo
  setup, un canale per interpellare il proprietario in modo interattivo.
- **2026-09-06 — Le domande sull'arte le pone il game-art-designer, non
  `card-crea`.** `card-crea` è una skill generica e leggera, senza
  competenza tecnica su come un asset si integra in Godot (nine-slice,
  StyleBoxTexture, safe area). Farle porre domande sulla direzione artistica
  sposterebbe la decisione tecnica su chi non ha gli strumenti per prenderla
  bene.
- **Sostituisce:** nessuna decisione precedente; estende PS-090 con la fase
  che lo precede.

## Documenti sincronizzati

- [x] `docs/cards/README.md`: regola di delega aggiornata con il passaggio
      di consultazione preventiva.

## Note

Card gemella di PS-090 nello spirito: PS-090 ha separato "chi genera" da "chi
integra"; questa separa "chi decide la direzione" da "chi genera".
