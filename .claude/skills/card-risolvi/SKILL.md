---
name: card-risolvi
description: Risolvi una card della board di Pidgeon Survivor nelle cartelle di fase sotto docs/cards/ — implementazione, smoke, verifica e aggiornamento dello stato. Usala per "risolvi PS-007", "prendi la prossima card", "chiudi la card del joystick" o quando si lavora su un file docs/cards/*/PS-*.md.
---

# Risolvi una card

La card è l'unico contratto operativo: non allargarla e non reinterpretarla.

## 1. Prendi la card

1. `git status --short`: preserva ogni modifica preesistente.
2. Apri la card indicata. Se ti è stato chiesto "la prossima" (o equivalenti
   come "procediamo con la prossima card"):
   - Controlla prima [docs/cards/3_in_sprint/](../../../docs/cards/3_in_sprint/).
     Se contiene ancora card, prendi quella `PRONTO` a priorità più alta (a
     parità, ID crescente) **che non richieda generazione di asset** (vedi
     punto 3) e vai al punto 7.
   - Se `3_in_sprint/` è vuota, scegli in
     [docs/cards/README.md](../../../docs/cards/README.md) la card `2_to_do`
     in stato `PRONTO` a priorità più alta con dipendenze chiuse (prerequisito
     almeno `IN VERIFICA`, non serve `COMPLETATO`) **che non richieda
     generazione di asset** (vedi punto 3). Aggiungi al blocco la sua
     catena di dipendenza — le card che ne dipendono e quelle da cui dipende —
     fino al confine naturale del filone. Se non è chiaro quali card
     includere, **fermati e chiedi al proprietario** prima di spostare
     qualunque file.
   - Sposta l'intero blocco scelto in `docs/cards/3_in_sprint/` e aggiorna i
     link nella board, poi riparti dalla prima card del blocco.
3. Non lavorare direttamente card `tipo: art` il cui comportamento atteso o
   criteri di accettazione prevedono la creazione o generazione di nuovi asset
   grafici (non la sola integrazione, l'adattamento geometrico/procedurale o
   il riuso di arte esistente): sono di competenza dell'agente Game Art
   Designer (`.agents/skills/game-art-designer/SKILL.md`), disponibile sia su
   Claude (`.claude/agents/game-art-designer.md`) sia su Codex
   (`.codex/agents/game-art-designer.toml`). Se la incontri scegliendo "la
   prossima card", scartala e passa alla candidata successiva idonea per
   priorità (a parità, ID crescente); se il proprietario l'ha chiesta
   esplicitamente per ID, **fermati** e proponi di invocare l'agente
   `game-art-designer` invece di implementarne tu la parte grafica, a meno che
   non ti chieda esplicitamente di procedere comunque tu.
4. Se lo stato è `DA DEFINIRE` o `BLOCCATO`, **fermati**: riporta la domanda o la
   dipendenza registrata nella card e non implementare.
   Se lo stato è `SCARTATA`, **fermati**: la card è stata valutata e respinta
   dal proprietario; non implementarla senza una sua conferma esplicita.
5. Se ricevi un vecchio ID B-series, trova la card tramite `origine`; se non
   esiste, creala prima di implementare.
6. Se la card che stai per prendere dipende (`dipende_da`) da una card
   `tipo: art` non ancora `IN VERIFICA` (punto 4 normalmente ti fermerebbe
   qui): controlla se quella card `art` ha già la geometria di consegna
   fissata in "Decisioni" (modalità pianificazione, PS-109). Se sì, puoi
   procedere subito invece di aspettare — vedi "Procedi con un placeholder"
   più sotto; se la geometria non è ancora fissata, fermati comunque, come al
   punto 4.
7. Porta lo stato a `IN CORSO` (o `IN ATTESA ASSET` se hai appena cablato un
   placeholder, vedi sotto), sposta la card in `docs/cards/3_in_sprint/` (se
   non ci è già) e aggiorna `aggiornato`, stato e link nella board.

### Procedi con un placeholder (PS-110)

Quando una card di integrazione dipende da una card `art` la cui geometria è
già decisa ma il derivato reale non esiste ancora, non aspettare: genera un
placeholder deterministico con
[`tools/generate-art-placeholder.ps1`](../../../tools/generate-art-placeholder.ps1)
alla stessa dimensione/geometria (fori compresi, con `-HoleRect`/`-HoleCircle`)
decisa nella card `art`, scrivendolo **esattamente nel percorso `generated/`
che l'asset reale occuperà**. Cabla la scena/il codice su quel percorso come
se fosse già quello definitivo: quando l'asset vero arriverà, sostituirà solo
i byte del file, senza toccare la tua card.

Porta lo stato della card di integrazione a `IN ATTESA ASSET` (resta in
`3_in_sprint`, non è `PRONTO` quindi la selezione "prossima card" la ignora
da sola). Registra in "Decisioni" quale comando hai usato per generarlo e a
quale card `art` è collegato. Non puoi chiudere questa card (vedi
"4. Chiudi") finché il placeholder non è stato sostituito.

## 2. Implementa

- Solo ciò che i criteri di accettazione richiedono. Se durante il lavoro emerge
  un problema adiacente, **apri una nuova card** (skill `card-crea`) invece di
  allargare questa.
- GDScript tipizzato, scene-local, signal-driven; contratti di
  [CLAUDE.md](../../../CLAUDE.md) intatti.
- Se la card tocca asset, applica la skill `asset-pipeline`.
- Se serve una prova nuova, applica la skill `smoke-test`.
- Se un criterio si rivela impossibile o sbagliato, non riscriverlo di nascosto:
  segnalalo, proponi la formulazione corretta e procedi sul resto.

## 3. Verifica

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-010 -Profile Focused `
  -FocusedSmoke tests/unit/test_grill_defense_mode.gd
.\tools\run-milestone-checks.ps1 -Milestone PS-010 -Profile Relevant `
  -FocusedSmoke tests/unit/test_grill_defense_mode.gd
```

Il parametro tecnico storico `-Milestone` accetta l'ID card; passa sempre
`-FocusedSmoke` con il percorso pertinente quando esiste. Exit code `0` non basta:
controlla i log per `SCRIPT ERROR` o `FATAL EXCEPTION` (un errore motore può non
tradursi in un'asserzione GUT fallita) oltre al report GUT stesso. Per i gate di
piattaforma applica `gate-piattaforme`.

## 4. Chiudi

1. Se questa card è (o è stata) `IN ATTESA ASSET`: prima di qualunque altro
   passo, verifica che il pixel `(0,0)` del derivato referenziato **non sia
   più** la firma del placeholder (magenta pieno, `255,0,255,255` — vedi
   `tools/generate-art-placeholder.ps1`). Se lo è ancora, la card resta
   `IN ATTESA ASSET`: non procedere oltre in questa sezione.
2. Spunta i criteri di accettazione **realmente** verificati e lascia non
   spuntati gli altri, con una riga che dice perché.
3. Aggiorna lo stato:
   - `IN VERIFICA` se gli automatici sono verdi ma restano gate manuali,
     percettivi o su device;
   - `COMPLETATO` quando tutti i gate pertinenti sono chiusi e la card è
     accettata; il commit resta separato.
   Sposta `IN VERIFICA` in `docs/cards/4_to_test/` e `COMPLETATO` in
   `docs/cards/5_completed/`.
4. Scrivi in `Decisioni` le scelte e motivazioni; in Note alternative, comandi e
   marker esatti usati come evidenza.
5. Aggiorna stato e link della riga nella tabella di
   [docs/cards/README.md](../../../docs/cards/README.md).
6. Controlla che metadati, dipendenze e riga della board restino allineati.
7. Se cambia la verità corrente, propaga il solo contratto risultante in
   `prd.md`, `CLAUDE.md`, cataloghi o `setup.md` e spunta
   `Documenti sincronizzati`. La motivazione resta nella card.
8. Commit solo su richiesta: `feat(PS-007): ...` o `fix(PS-007): ...`, in
   italiano, focalizzato. Nessun push se non richiesto.
9. Riporta: cosa è cambiato, criteri chiusi e criteri lasciati aperti, risultati
   Windows/Android separati, gate ancora aperti.
