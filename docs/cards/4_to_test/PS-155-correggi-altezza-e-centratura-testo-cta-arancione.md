---
id: PS-155
titolo: Correggi altezza e centratura del testo sul CTA arancione
tipo: fix
area: ui
stato: IN VERIFICA
priorita: alta
dipende_da: []
origine:
creato: 2026-09-11
aggiornato: 2026-09-11
---

# PS-155 — Correggi altezza e centratura del testo sul CTA arancione

## Contesto

Nel menu di pausa, il pulsante "RIPRENDI" (stile CTA primario arancione,
`character_select_cta_base.png`) risultava visibilmente più alto dei
pulsanti blu affiancati ("CAMBIA PERSONAGGIO", "IMPOSTAZIONI", "ESCI",
stile CTA secondario) a parità di `custom_minimum_size` — segnalato dal
proprietario su uno screenshot reale. Misura pixel sullo screenshot: la
decorazione a diamante ai lati del CTA arancione occupava ~30px in verticale
contro i ~20px del CTA blu, coerente con `texture_margin_top` (34/24 a
seconda della scena) ed `expand_margin` più generosi sull'asset arancione, a
loro volta derivati da un master HD (`hd/character_select_cta_source.png`)
con un'altezza del contenuto visibile diversa da quella dell'asset blu
gemello.

Il proprietario ha rigenerato personalmente il master HD arancione (i due
grandi ornamenti a diamante comprimevano otticamente l'altezza percepita
della placca) e ha chiesto di ricablare tutte le scene che usano il
derivato. Riprocessando il derivato con le stesse proporzioni, il testo
tutto-maiuscolo (nessun discendente: "RIPRENDI", "GIOCA", "GIOCA CON
`<Nome>`", ecc.) è comparso visibilmente sopra il centro verticale della
placca più bassa.

## Comportamento atteso

Il CTA arancione (RIPRENDI, GIOCA, GIOCA CON `<Nome>`, CONFERMA, CONTINUA)
ha un'altezza visiva coerente con gli altri pulsanti dello stesso gruppo
(pausa: confrontabile col CTA blu adiacente) e il testo appare centrato
verticalmente sulla placca in ogni scena che lo usa.

## Criteri di accettazione

- [x] Il derivato runtime `character_select_cta_base.png` è rigenerato dal
      nuovo master HD fornito dal proprietario, con lo stesso comando
      deterministico (`tools/process-character-select-cta.ps1`, soglia
      alpha 8, padding 4, scala 35%).
- [x] La regione `AtlasTexture` e i `texture_margin_top`/`texture_margin_bottom`
      del CTA arancione sono aggiornati, in proporzione, in tutte le scene
      che lo referenziano: `pause_overlay.tscn`, `welcome_screen.tscn`,
      `character_select_overlay.tscn`, `tutorial_screen.tscn`,
      `end_screen.tscn`.
- [x] Nel menu di pausa, "RIPRENDI" e i pulsanti blu adiacenti hanno
      un'altezza visiva paragonabile — verificato su screenshot reale
      rigenerato dopo il fix.
- [x] Il testo del CTA arancione è centrato verticalmente sulla placca in
      ogni stato (`normal`/`hover`/`pressed`/`focus`) del menu di pausa —
      corretto con un `content_margin_top`/`content_margin_bottom`
      espliciti (`26`/`14`) sulle tre `StyleBoxTexture` del CTA primario in
      `pause_overlay.tscn`.
- [x] Verificato il testo su tutte le altre 4 scene via screenshot reali:
      welcome (`GIOCA`, bottone alto 74px) e selettore/tutorial (`GIOCA CON
      <Nome>`, `AVANTI`, bottoni piu' alti o margine 28) erano già centrati
      senza bisogno di correzioni; `end_screen.tscn` (`RIPROVA`, stesso
      margine 20 e altezza 64 di pausa) aveva lo stesso problema di pausa
      ed è stato corretto con lo stesso `content_margin_top`/`bottom`
      (`26`/`14`).
- [x] `ASSET-MANIFEST.md` di `assets/art/ui/character_select/` aggiornato
      con origine, dimensioni e SHA-256 del nuovo master e del derivato.

## Ambito

- File toccati: `scenes/ui/pause_overlay.tscn`, `scenes/ui/welcome_screen.tscn`,
  `scenes/ui/character_select_overlay.tscn`, `scenes/ui/tutorial_screen.tscn`,
  `scenes/ui/end_screen.tscn` (solo region/texture_margin/content_margin del
  CTA arancione condiviso, nessun altro stile toccato).
- Asset toccati: `assets/art/ui/character_select/hd/character_select_cta_source.png`
  (sostituito dal proprietario, vecchia versione conservata come
  `character_select_cta_source_OLD.png`), `character_select_cta_base.png`
  (rigenerato).
- Non toccare: lo stile CTA secondario/blu (`secondary_button_cta_base.png`),
  invariato e usato come riferimento di altezza corretta; logica di
  `PauseOverlay`/`WelcomeScreen`/`CharacterSelectOverlay` (solo stylebox).

## Verifica

- Nessun nuovo smoke GUT: modifica puramente di stylebox/asset, non di
  logica. La resa (altezza, centratura testo) è un controllo percettivo su
  screenshot reali, non automatizzabile in modo affidabile.
- Screenshot rigenerati con `tools/_capture_ui_screenshots.gd` dopo un
  refresh forzato della cache di import di Godot (vedi Decisioni: la prima
  rigenerazione mostrava ancora il derivato vecchio, cache di import non
  invalidata dalla sola sovrascrittura del file).
- Relevant: 34/34 regressioni, 35/35 step, nessun `SCRIPT ERROR`/`FATAL
  EXCEPTION`.
- Full: 139/139 regressioni, toolchain PASS, 140/140 step, nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9
- [x] Controllo percettivo richiesto: sì — il proprietario ha confermato
      via screenshot che il fix su pausa è corretto dopo il refresh della
      cache ("ok, ora si vede bene"); le altre 4 scene sono state
      autoverificate su screenshot reali in questa sessione (vedi criteri
      sopra), non ancora riviste esplicitamente dal proprietario.

## Decisioni

- **2026-09-11 — Causa readicata al master HD, non alla scena.** Misura
  pixel-per-pixel: la decorazione a diamante del CTA arancione occupava
  ~30px contro i ~20px del blu allo stesso `custom_minimum_size`. Il
  proprietario ha scelto di rigenerare lui stesso il master invece di
  correggere solo i margini nine-slice (che avrebbero comunque tagliato,
  non scalato, l'ornamento — stesso principio già visto in PS-139/PS-152/PS-154).
- **2026-09-11 — Regione e margini aggiornati in proporzione in tutte le 5
  scene che riusano il derivato**, non solo in `pause_overlay.tscn`: stesso
  file, quindi stessa nuova geometria ovunque.
- **2026-09-11 — Testo non centrato dopo il primo fix, segnalato dal
  proprietario.** Il testo tutto-maiuscolo (nessun discendente) restava
  visibilmente sopra il centro della placca più bassa. Corretto con un
  `content_margin_top`/`content_margin_bottom` espliciti e asimmetrici
  (`26`/`14`, non più il default implicito pari al `texture_margin`) sulle
  tre `StyleBoxTexture` del CTA primario in `pause_overlay.tscn` — l'unica
  scena verificata puntualmente finora (vedi criterio aperto sull'estensione
  alle altre 4 scene).
- **2026-09-11 — Il fix non compariva nei primi screenshot rigenerati,
  segnalato dal proprietario ("c'è ancora il pulsante vecchio").**
  Diagnosticato come cache di import di Godot non invalidata dalla sola
  sovrascrittura del PNG sorgente sul disco. Risolto forzando un reimport
  (`godot_console --headless --editor --path . --quit`, dopo aver rimosso
  il `.import` stale del derivato) prima di rigenerare gli screenshot.
  Nota operativa per il futuro: quando un asset raster viene sovrascritto
  fuori dall'editor Godot, verificare lo screenshot con un reimport forzato
  prima di dichiarare un fix visivo completo.
- **2026-09-11 — Estesa la correzione della centratura a `end_screen.tscn`.**
  Stessa combinazione margine `20`/altezza bottone `64` di `pause_overlay.tscn`
  (`RIPROVA`): stesso difetto, stessa correzione (`content_margin_top`/`bottom`
  `26`/`14`). Le altre 3 scene (welcome, selettore, tutorial) usano bottoni
  più alti (74/58px) o un margine maggiore (28) e non mostravano il problema
  su screenshot reale: nessuna modifica necessaria lì.

## Documenti sincronizzati

- [x] `assets/art/ui/character_select/ASSET-MANIFEST.md`: nuova sezione con
      origine, dimensioni e SHA-256 del master e del derivato aggiornati.

## Note

Nessuna consultazione del game-art-designer: il proprietario ha fornito
direttamente il nuovo master HD, nessuna nuova arte da generare lato
sessione — solo riprocessamento deterministico e ricablaggio scene.
