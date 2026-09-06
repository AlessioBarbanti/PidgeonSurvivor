---
id: PS-110
titolo: Placeholder generato e stato IN ATTESA ASSET per procedere prima dell'asset reale
tipo: chore
area: tooling
stato: COMPLETATO
priorita: media
dipende_da: [PS-109]
origine: conversazione del proprietario 2026-09-06
creato: 2026-09-06
aggiornato: 2026-09-06
---

# PS-110 — Placeholder generato e stato IN ATTESA ASSET per procedere prima dell'asset reale

## Contesto

Dopo [PS-109](../5_completed/PS-109-consulta-game-art-designer-prima-di-fissare-criteri-art.md)
la geometria di consegna di un asset (dimensioni, fori, margini) viene
decisa **prima** che Codex generi qualunque pixel. Questo rende possibile
un passo ulteriore: una card di integrazione non deve più aspettare che
l'asset reale esista per iniziare il proprio lavoro — puo' cablare subito un
placeholder con la geometria già concordata, e l'asset vero, quando arriva,
sostituisce solo i byte del file senza toccare il wiring. Oggi non esiste
né lo strumento per generare quel placeholder né un modo, visibile in
board, di segnalare "questa integrazione è già cablata, aspetta solo
l'asset" — utile anche a chi gestisce la coda di generazione per sapere
quali asset stanno davvero bloccando qualcosa.

## Comportamento atteso

Una card di integrazione che dipende da una card `tipo: art` con la
geometria già fissata in pianificazione (PS-109) può procedere subito:
genera un placeholder deterministico e riconoscibile alla geometria
concordata, lo referenzia nel percorso `generated/` definitivo, e passa allo
stato `IN ATTESA ASSET` invece di restare bloccata. Non può chiudersi
finché l'asset reale non ha sostituito il placeholder — verificato da un
gate automatico, non a occhio.

## Criteri di accettazione

- [x] Nuovo script `tools/generate-art-placeholder.ps1`: genera un PNG
      deterministico a dimensione richiesta (`-Width`/`-Height`), con
      ritagli opzionali resi trasparenti ad alpha reale (`-HoleRect`/
      `-HoleCircle`) e un'etichetta diagonale ripetuta per riconoscimento a
      occhio. Il pixel `(0,0)` è sempre magenta pieno (`255,0,255,255`) per
      costruzione: è la firma di riconoscimento automatico, indipendente dal
      rendering del testo (non garantito identico fra ambienti/font).
      Verificato manualmente: scacchiera, etichetta ed exact alpha-zero nel
      foro circolare confermati su un caso reale (764×464 con foro
      circolare, stessa geometria della cornice Boss Intro di PS-102/103).
- [x] Nuovo stato di board `IN ATTESA ASSET`: aggiunto al vocabolario in
      `docs/cards/README.md` e al commento del frontmatter in
      `docs/cards/_TEMPLATE.md`. Vive in `3_in_sprint/` (nessuna nuova
      cartella): è una card `IN CORSO` che nomina esplicitamente il proprio
      blocco. La selezione "prossima card" la ignora perché il criterio di
      scelta resta `PRONTO`, invariato.
- [x] `docs/cards/README.md` documenta l'eccezione alla regola `dipende_da`
      (un'integrazione può iniziare col prerequisito `art` ancora
      `PRONTO`/`IN CORSO` se la geometria è già fissata) e il segnale di
      priorità per Codex (una card `art` referenziata da una riga
      `IN ATTESA ASSET` ha priorità su una card `art` `PRONTO` che nessuno
      sta aspettando).
- [x] `.claude/skills/card-risolvi/SKILL.md` descrive quando e come usare il
      placeholder (nuovo punto nel passo "Prendi la card" + sezione
      dedicata "Procedi con un placeholder"), e il gate di chiusura nel
      passo "Chiudi": verifica del pixel `(0,0)` prima di poter passare a
      `IN VERIFICA`/`COMPLETATO`.
- [x] `.claude/skills/asset-pipeline/SKILL.md` documenta lo stesso
      meccanismo dal lato della pipeline asset (nuovo passo "0").
- [x] `.agents/skills/game-art-designer/SKILL.md` (contratto condiviso
      Claude/Codex) istruisce l'esecutore a dare priorità alle card `art`
      che sbloccano una riga `IN ATTESA ASSET`, e a sostituire un
      placeholder esistente allo stesso percorso invece di trattarlo come
      un conflitto o un asset da preservare.

## Ambito

- `tools/generate-art-placeholder.ps1` (nuovo).
- `docs/cards/README.md`, `docs/cards/_TEMPLATE.md`.
- `.claude/skills/card-risolvi/SKILL.md`.
- `.claude/skills/asset-pipeline/SKILL.md`.
- `.agents/skills/game-art-designer/SKILL.md`.

Non toccare:

- `.claude/agents/game-art-designer.md` e `.codex/agents/game-art-designer.toml`:
  la distinzione pianificazione/produzione di PS-109 già li copre; questa
  card cambia solo la produzione, non chi la fa o come decide la direzione.
- Le card `art`/integrazione già chiuse: restano storiche sotto il
  contratto con cui sono state lavorate.

## Verifica

- Nessuno smoke GUT: cambia solo tooling di sviluppo e documentazione di
  processo, non runtime di gioco. Verificato:
  - esecuzione diretta di `tools/generate-art-placeholder.ps1` con un caso
    reale (foro circolare) — marker `PLACEHOLDER_OK`, pixel `(0,0)` e alpha
    del foro confermati via `System.Drawing`;
  - lettura incrociata delle cinque fonti toccate, nessuna contraddizione
    con PS-109 né con la regola `dipende_da` esistente.
- Profilo minimo prima della chiusura: nessuno (nessun codice o dato di
  runtime cambia).

## Gate manuali

- [ ] Runtime Windows: non applicabile
- [ ] Validazione statica APK: non applicabile
- [ ] Runtime fisico Pixel 9: non applicabile
- [ ] Controllo percettivo richiesto: no (lo script è stato ispezionato
      visivamente in questa sessione, ma non è un asset di gioco)

## Decisioni

- **2026-09-06 — La firma di riconoscimento è un pixel, non un hash di
  file.** Un confronto per hash fra una rigenerazione dello script e il file
  in `generated/` sarebbe stato più preciso in teoria, ma il rendering del
  testo via GDI+ (font, hinting, DPI) non è garantito byte-identico fra
  macchine o versioni di .NET — un gate basato su quello avrebbe potuto dare
  falsi negativi. Il pixel `(0,0)` sempre magenta pieno per costruzione è
  una firma sufficientemente distintiva (nessun asset reale dovrebbe avere
  quell'esatto colore lì) e completamente stabile.
- **2026-09-06 — Il placeholder si scrive direttamente in `generated/`, non
  in un percorso separato.** È il punto centrale della proposta: la card di
  integrazione referenzia da subito il percorso finale, così l'asset vero
  lo sostituisce senza richiedere alcuna modifica al wiring già scritto.
- **2026-09-06 — Nessuna nuova cartella per `IN ATTESA ASSET`.** Resta in
  `3_in_sprint/` insieme a `PRONTO`/`IN CORSO`: è concettualmente lavoro in
  corso che nomina il proprio blocco, non una fase nuova del processo.
- **2026-09-06 — Estende PS-109, non lo sostituisce.** Il placeholder è
  utile solo perché PS-109 fissa la geometria di consegna prima che
  l'integrazione inizi; senza quella pianificazione un placeholder
  rischierebbe comunque dimensioni sbagliate.

## Documenti sincronizzati

- [x] `docs/cards/README.md`: vocabolario stati, mappa cartelle, regola
      `dipende_da` e riga di board aggiornati.

## Note

Card gemella di PS-109: PS-109 decide *cosa* produrre prima che la
produzione inizi; questa permette a chi cabla di *procedere* prima che la
produzione sia finita.
