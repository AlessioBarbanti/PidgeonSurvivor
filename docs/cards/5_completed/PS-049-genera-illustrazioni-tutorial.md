---
id: PS-049
titolo: Generare le tre illustrazioni definitive del tutorial
tipo: art
area: arte
stato: COMPLETATO
priorita: media
dipende_da: [PS-048]
origine:
creato: 2026-08-31
aggiornato: 2026-09-04
---

# PS-049 — Generare le tre illustrazioni definitive del tutorial

## Contesto

[PS-048](./PS-048-fedelta-al-runtime-di-tre-pagine-tutorial.md) corregge tre
pagine e le cabla su segnaposto `fake_*.png`. Questa card sostituisce i fake
con arte definitiva mantenendo composizione, ingombri e significato già
validati.

Le nuove catture 20:9 confermano che cornice e contenitore del tutorial sono
già coerenti: l'intervento riguarda solo le tre illustrazioni.

## Comportamento atteso

Le illustrazioni sembrano parte del gioco e rappresentano fedelmente i segnali
runtime: confronto di stato per l'abilità, sequenza XP → livello → carta e
vocabolario dei telegraph. Non diventano vignette decorative scollegate dagli
elementi che il giocatore incontrerà.

## Criteri di accettazione

### `tutorial_ability_button.png`

- [x] Mostra il vero pulsante abilità dell'HUD, non un'icona generica.
- [x] Gli stati `PRONTA` e `IN RICARICA` sono confrontabili e il riempimento
      circolare è la differenza dominante.
- [x] Un accenno dell'angolo di schermo comunica la posizione in basso a
      destra senza aggiungere un HUD fittizio.

### `tutorial_pickups.png`

- [x] XP e cura riprendono forma e colori degli elementi runtime correnti.
- [x] La carta di scelta è riconoscibile come esito del level-up.
- [x] La lettura XP → livello → carta è chiara; la cura resta un recupero vita
      parallelo e non un passaggio obbligatorio della sequenza.

### `tutorial_telegraphs.png`

- [x] Mostra almeno tre forme di zona pericolosa distinte, per esempio linea,
      anello e area.
- [x] Forme, trasparenze e colori sono coerenti con i telegraph runtime.
- [x] Nessuna forma viene presentata come il segnale universale dei Boss.

### Comuni

- [x] I file definitivi sostituiscono i percorsi `fake_*.png` cablati da
      PS-048 e i riferimenti nei `.tres` vengono aggiornati.
- [x] Nessun `fake_*.png` resta sotto `assets/art/ui/tutorial/`.
- [x] Ogni immagine è leggibile nelle catture 1280×720 e Pixel 9 20:9 senza
      testo microscopico o dettagli essenziali affidati a pochi pixel — verificato
      solo a schermo (vedi Gate manuali per la resa reale su Windows/Pixel 9).
- [x] Palette, cornici e pixel density sono coerenti con le altre pagine.
- [x] Ogni nuovo file ha una riga in
      `assets/art/ui/tutorial/ASSET-MANIFEST.md` con percorso, origine, autore,
      licenza, trasformazioni e SHA-256; i master HD restano esclusi dagli
      export.

## Ambito

- `assets/art/ui/tutorial/hd/` e
  `assets/art/ui/tutorial/generated/`.
- `assets/art/ui/tutorial/ASSET-MANIFEST.md`.
- `data/tutorial/ability.tres`, `data/tutorial/progression.tres`,
  `data/tutorial/boss.tres`, solo per sostituire i percorsi fake.

Non toccare:

- testo, ordine e struttura stabiliti da PS-048;
- contenitore, navigazione e safe area del tutorial;
- script e gameplay.

## Verifica

- Smoke: riusa `tests/unit/test_ps048_tutorial_runtime_fidelity.gd`, esteso
  per verificare che nessuna pagina punti a un file con prefisso `fake_`.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [x] Runtime Windows
- [x] Validazione statica APK — i master HD restano esclusi dai tre preset
      (verificato solo nel `exclude_filter` di `export_presets.cfg`, non su un
      APK esportato)
- [x] Runtime fisico Pixel 9: pagine 3, 4 e 6 alla scala reale
- [x] Controllo percettivo richiesto: sì — le immagini insegnano gli stessi
      segnali che compaiono nella run. Confermato dal proprietario nel
      contenitore tutorial reale, a scala reale su device.

## Decisioni

- **2026-08-31 — I fake restano il contratto di passaggio.** PS-049 li
  sostituisce solo dopo che contenuto e ingombri sono stati validati in PS-048.
- **2026-08-31 — Fedeltà prima della decorazione.** Ogni licenza stilistica è
  subordinata alla riconoscibilità degli elementi runtime.
- **2026-09-01 — Fonte delle tre illustrazioni: catture aggiornate o arte già
  esistente, non disegni scollegati dal runtime.** Rigenerare
  `tools/_capture_ui_screenshots.gd` prima di produrre le illustrazioni: il
  pacchetto Pixel 9 (`exports/ui-screenshots/pixel9-20x9/`) ora mostra anche
  il joystick "floating" attivo, non solo il pulsante abilità. Usare queste
  catture come riferimento diretto per comporre `tutorial_ability_button.png`
  e `tutorial_pickups.png`; dove un elemento runtime ha già una sprite
  definitiva in `assets/art/`, riusare quella invece di ridisegnarla. Generare
  arte nuova solo per ciò che le catture e l'arte esistente non coprono (per
  esempio le forme di zona di `tutorial_telegraphs.png`, che non sono un
  singolo elemento fotografabile).
- **2026-09-02 — Ogni illustrazione è un composito, non una singola
  generazione AI.** Solo lo sfondo ambientale è ImageGen (Codex CLI
  `gpt-image`, `generate_image_set` per uno style guide condiviso); gli
  elementi che i criteri richiedono fedeli al runtime (disco abilità, cristallo
  XP, forme di telegraph) sono ridisegnati deterministicamente con
  Python/Pillow dai valori esatti letti negli script (`touch_ability_button.gd`,
  `experience_pickup.gd`, `first_boss.gd`) o ritagliati da catture runtime
  reali. Dettagli, prompt e provenienza completi in
  `assets/art/ui/tutorial/ASSET-MANIFEST.md`.
- **2026-09-02 — Profilo `Relevant` non eseguito, per decisione esplicita del
  proprietario.** Solo il profilo `Focused` su
  `tests/unit/test_ps048_tutorial_runtime_fidelity.gd` è stato eseguito ed è
  verde. Registrato come rinuncia operativa, non come evidenza di
  regressione verificata: se emergono problemi di import o riferimenti
  incrociati, vanno controllati alla prossima verifica utile del profilo
  `Relevant`.

## Documenti sincronizzati

- [x] `assets/art/ui/tutorial/ASSET-MANIFEST.md`.
- [x] `docs/visual-audio-identity.md` — riga `ui/tutorial` aggiornata con la
      convenzione "sfondo ImageGen + composizione deterministica di elementi
      runtime reali".

## Note

Conservare master HD, derivato runtime, prompt, trasformazioni e hash secondo
la pipeline asset del repository.
