---
id: PS-038
titolo: Documentazione di game design per review interna
tipo: chore
area: docs
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-038 — Documentazione di game design per review interna

## Contesto

`docs/characters.md` e `docs/powerup-catalog.md` sono gli unici cataloghi
correnti nella tabella delle fonti di verità di `CLAUDE.md`. Mancano
documenti equivalenti per nemici/Boss, sistemi/curva di difficoltà, flusso
UI/UX e identità visiva/audio: chi fa una review interna del game design deve
oggi ricostruirli leggendo `scripts/`, `data/` e `scenes/` da zero.

## Comportamento atteso

Quattro nuovi documenti in `docs/`, nello stesso stile contrattuale di
`characters.md`/`powerup-catalog.md` (prosa in italiano, ogni contratto
runtime citato con file e — dove serve puntualità — riga sorgente, nessun
valore reinventato a memoria), aggiunti alla tabella delle fonti di verità di
`CLAUDE.md`:

- `docs/enemies-bosses.md` — archetipi nemici correnti e il sistema Boss
  (baseline, varianti `Evil <Nome>`, Signature Ability), con le fonti dati
  (`data/enemies/*`, `data/bosses/*`) e la logica che le legge.
- `docs/systems-difficulty.md` — loop di run (`RunController`, stati),
  spawn e curva di difficoltà (`GameDirector`, `GameDirectorProfile`),
  progressione/level up, senza duplicare `prd.md` ma linkandolo dove il
  contratto è già scritto lì.
- `docs/ui-ux-flow.md` — flusso `welcome → (tutorial) → selezione → run →
  pausa`, HUD, modali e arbitraggio, input unificato (`InputRouter`:
  tastiera/gamepad/touch) e `PlatformLifecycle`.
- `docs/visual-audio-identity.md` — direzione artistica corrente (palette
  grigliatori/piccioni, cast), stato di musica ed effetti sonori, con
  riferimento agli `ASSET-MANIFEST.md` di cartella invece di duplicarne le
  righe.

## Criteri di accettazione

- [x] `docs/enemies-bosses.md` esiste e ogni archetipo nemico e ogni
      comportamento Boss/Evil descritto cita il file dati o script sorgente
      corrente.
- [x] `docs/systems-difficulty.md` esiste e descrive stati di
      `RunController`, spawn e curva di difficoltà di `GameDirector` citando
      i file/parametri sorgente correnti, senza contraddire `prd.md`.
- [x] `docs/ui-ux-flow.md` esiste e descrive il flusso schermate, `InputRouter`
      e `PlatformLifecycle` citando i file sorgente correnti.
- [x] `docs/visual-audio-identity.md` esiste, descrive lo stato attuale di
      arte/audio e rimanda agli `ASSET-MANIFEST.md` pertinenti invece di
      duplicarli.
- [x] Nessuno dei quattro documenti introduce un valore, un contratto o un
      comportamento non verificabile nel codice/dati al momento della
      stesura. Metodo: quattro ricognizioni dedicate sul codice/dati sorgente
      più uno spot-check successivo con `grep`/lettura diretta su un
      campione di affermazioni forti (stati `RunController`, soglie Boss,
      Signature Registry, curva XP, offerte upgrade, pesi archetipi). Lo
      spot-check ha trovato e corretto un errore reale: la tabella delle
      Signature aveva scambiato le meccaniche fra Alea/Aleo/Migi/Marghe,
      corretto confrontando `boss_signature_registry.gd:26-52` con
      `characters.md`. Non è stata verificata riga per riga ogni singola
      citazione dei quattro documenti: resta un rischio residuo su
      affermazioni minori non ricontrollate a campione.
- [x] `CLAUDE.md` elenca i quattro nuovi documenti nella tabella delle fonti
      di verità.
- [x] Nessun file runtime (`scripts/`, `scenes/`, `data/`) viene modificato da
      questa card (`git status --short` conferma solo `CLAUDE.md`,
      `docs/cards/` e i quattro nuovi `docs/*.md`).

## Ambito

- Nuovi file in `docs/`: `enemies-bosses.md`, `systems-difficulty.md`,
  `ui-ux-flow.md`, `visual-audio-identity.md`.
- Tabella "Fonti di verità" in `CLAUDE.md`.

Non modificare:

- `prd.md`, `characters.md`, `powerup-catalog.md` (restano le fonti primarie;
  i nuovi documenti le linkano invece di duplicarle);
- qualunque file in `scripts/`, `scenes/`, `data/`: card di sola
  documentazione, nessun cambiamento runtime o di bilanciamento;
- la board delle card (`docs/cards/README.md`) resta l'unica fonte operativa
  di stato/priorità: i nuovi documenti descrivono lo stato attuale del
  codice, non un backlog.

## Verifica

- Nessuno smoke automatico: modifica esclusivamente a file `.md`, che
  `docs/verification-workflow.md` classifica come "solo documentali" senza
  regressioni runtime attese.
- Verifica per lettura incrociata: ogni affermazione dei quattro documenti va
  confrontata con il file/riga sorgente citato al momento della stesura.
- Profilo minimo prima della chiusura: nessuno (nessun cambiamento runtime da
  verificare con `run-milestone-checks.ps1`).

## Gate manuali

- [x] Runtime Windows — non pertinente, nessun cambiamento runtime.
- [x] Validazione statica APK — non pertinente.
- [x] Runtime fisico Pixel 9 — non pertinente.
- [x] Controllo percettivo richiesto: no.

## Decisioni

- **2026-08-31 — Formato: markdown nel repository, non artifact esterno.**
  Il proprietario vuole documenti durevoli in `docs/`, per una review
  interna, nello stesso stile di `characters.md`/`powerup-catalog.md`.
- **2026-08-31 — Quattro documenti separati per argomento**, invece di un
  unico file lungo, per restare coerenti con la struttura a cataloghi già in
  uso e non creare un tracker parallelo.
- **2026-08-31 — Ricognizione delegata, stesura e verifica trattenute.**
  Quattro ricognizioni in sola lettura hanno raccolto il materiale grezzo con
  citazioni file:riga; la prosa finale e lo spot-check di coerenza restano
  fatti in prima persona, non delegati.
- **2026-08-31 — Problema adiacente aperto come card separata, non corretto
  qui.** La ricognizione Boss ha trovato un'API mancante
  (`BossEncounter.get_last_experience_reward()`) sul ramo `VICTORY` di
  `_show_terminal_screen`, oggi non raggiungibile in produzione. Non
  corretto in questa card (sola documentazione): aperta come
  [PS-039](../to_do/PS-039-api-mancante-vittoria-ricompensa-boss.md).
  L'indagine per implementarla ha poi mostrato che il regresso era più ampio
  di quanto stimato qui (rompeva anche il ramo `DEFEAT`, non solo
  `VICTORY`): la card PS-039 riporta la cronologia corretta.

## Documenti sincronizzati

- [x] `CLAUDE.md` — riga aggiunta per ciascuno dei quattro nuovi documenti
      nella tabella "Fonti di verità".

## Note

I quattro documenti descrivono lo **stato attuale** del codice/dati, non
proposte o roadmap: eventuali cambi di design restano nelle card che li
introducono, secondo la stessa convenzione già in uso per `characters.md` e
`powerup-catalog.md`.
