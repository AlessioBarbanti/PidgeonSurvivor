---
id: PS-074
titolo: Aggiungi un suono di click ai bottoni UI oggi silenziosi
tipo: ux
area: audio
stato: IN VERIFICA
priorita: bassa
dipende_da: []
origine:
creato: 2026-09-02
aggiornato: 2026-09-09
---

# PS-074 — Aggiungi un suono di click ai bottoni UI oggi silenziosi

## Contesto

`GameAudio` riproduce `UI_CONFIRM` solo da due punti:
`_on_upgrade_submitted` e `_on_friend_confirmed`
([scripts/audio/game_audio.gd:609-615](../../../scripts/audio/game_audio.gd#L609-L615)).
`PAUSE`/`RESUME` partono dal cambio di stato del `RunController`, non dal
bottone in sé. Una ricognizione di tutti i `.pressed.connect(...)` sotto
`scripts/ui/` mostra che il resto dei bottoni interattivi non produce alcun
suono alla pressione:

- `pause_overlay.gd`: `_change_character_button`, `_cancel_change_button`,
  `_confirm_change_button` (il solo `_resume_button` è coperto indirettamente
  dal cambio di stato a `RUNNING`).
- `character_select_overlay.gd`: `_previous_button`, `_next_button`,
  `_back_button` (il solo bottone di conferma è coperto da
  `friend_confirmed`).
- `welcome_screen.gd`: `_play_button`, `_tutorial_button`,
  `_settings_button`, `_close_settings_button`.
- `end_screen.gd`: `_restart_button`, `_change_character_button`.
- `boss_ui.gd`: `_continue_button`.
- `tutorial_screen.gd`: `_previous_button`, `_next_button`.

Il gioco risulta percettibilmente "silenzioso" proprio su questa superficie:
la maggior parte della navigazione fra schermate non dà mai un riscontro
sonoro.

## Comportamento atteso

Ogni bottone elencato sopra produce un breve suono di click alla pressione
(mouse, touch, tastiera/gamepad), senza duplicare o sovrapporsi ai suoni già
esistenti su bottoni che ne hanno già uno dedicato (conferma upgrade/Barb/
personaggio, pausa/ripresa).

## Criteri di accettazione

- [x] Tutti i bottoni elencati in Ambito riproducono un nuovo cue di click
      alla pressione — tranne Gioca/Tutorial della welcome e "Successivo"
      sull'ultima pagina del tutorial (diventa "GIOCA"), scoperti già coperti
      da `UI_CONFIRM` rileggendo il codice: vedi Decisioni, non è
      un'eccezione silenziosa.
- [x] I bottoni che già causano `UI_CONFIRM`, `PAUSE` o `RESUME` non
      raddoppiano il suono sulla stessa pressione.
- [x] Pressioni ravvicinate (es. tenere Precedente/Successivo sul carosello o
      sul tutorial) non producono distorsione né accumulo fastidioso: rispetta
      un limite di frequenza, come già fatto per `SHOT`/`HIT` tramite
      `minimum_interval_msec`.
- [x] Il click funziona identico da mouse, touch e conferma da tastiera/
      gamepad (`ui_accept`) sul bottone a fuoco: la logica vive nell'handler
      del segnale `.pressed`, che Godot emette identico da qualunque sorgente
      di input su un bottone a fuoco — nessuna diramazione per dispositivo.
- [x] Con audio disattivato o volume a zero non è udibile alcun suono.
- [x] Il cue riusa uno stream CC0 già presente in `assets/audio/` (per
      esempio dal set Kenney già in repo) se ne esiste uno adatto; altrimenti
      ne integra uno nuovo con riga nel manifest.

## Ambito

- `scripts/ui/pause_overlay.gd`, `character_select_overlay.gd`,
  `welcome_screen.gd`, `end_screen.gd`, `boss_ui.gd`, `tutorial_screen.gd`:
  solo per esporre o collegare il segnale di pressione al click, non per
  cambiare la logica di navigazione.
- `scripts/audio/game_audio.gd`: nuovo cue `UI_CLICK` (o nome equivalente) e
  le connessioni necessarie.

Non toccare:

- la logica di navigazione, focus e neighbor esistente in ciascun overlay;
- il flusso `welcome → tutorial → selezione → run → pausa`;
- `RunController` e l'arbitraggio dei modali;
- i cue già dedicati (`UI_CONFIRM`, `PAUSE`, `RESUME`).

## Verifica

- Smoke: `tests/unit/test_ps074_ui_click_feedback.gd` → marker
  `UI_CLICK_FEEDBACK_SMOKE_OK` — verifica che ciascun bottone elencato
  produca il cue, che i bottoni già coperti non lo raddoppino, che pressioni
  ravvicinate non producano accumulo e che con audio disattivato non ci sia
  riproduzione.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: naviga l'intero flusso welcome → tutorial →
      selezione → run → pausa → cambio personaggio → fine run toccando ogni
      bottone, con le cuffie
- [ ] Controllo percettivo richiesto: sì — il click non deve risultare
      fastidioso su pressioni ripetute rapide (carosello, tutorial)

## Decisioni

- **2026-09-02 — Card nata da una ricognizione a tappeto.** Nessun altro
  punto oltre a `UI_CONFIRM`/`PAUSE`/`RESUME` produce suono sui bottoni;
  elenco sopra verificato leggendo ogni `.pressed.connect(...)` sotto
  `scripts/ui/`.
- **2026-09-02 — Riuso preferito, nuovo asset ammesso.** Coerente con lo
  sblocco generale sui nuovi asset audio deciso dal proprietario.
- **2026-09-09 — Nessuno stream già in repository reggeva come click
  leggero.** Gli 8 file Kenney già importati sono tutti già assegnati a un
  cue esistente (conferme, aperture/chiusure, maximize/minimize) — nessuno
  è uno "spare" riutilizzabile. Scaricato il pack sorgente completo
  (`kenney.nl/assets/interface-sounds`, stesso pack CC0 già in uso) via
  `curl`, individuati 5 candidati dedicati (`Audio/click_001.ogg` …
  `click_005.ogg`), mandati al proprietario via `SendUserFile` per
  l'ascolto. Approvato `click_001.ogg` → `ui_click.ogg`.
- **2026-09-09 — Segnale condiviso `ui_click_requested()` per overlay,
  handler unico in `GameAudio`.** Ogni overlay/schermata coinvolta espone lo
  stesso segnale (pattern già usato da `selection_submitted`/
  `friend_confirmed`); `GameAudio.configure()` si connette a tutti e un solo
  `_on_ui_click_requested()` chiama `play_cue(UI_CLICK, -5.0, 80)`. Evita
  logica duplicata per overlay e mantiene il debounce centralizzato su un
  solo punto.
- **2026-09-09 — Wrapper handler dove il bottone era connesso direttamente a
  un metodo condiviso (es. `navigate_previous()`, `_open_settings()`,
  `_close_settings()`).** Alcuni bottoni erano collegati a metodi pubblici
  riusati anche da swipe/scorciatoie/back-gesture (es.
  `character_select_overlay.navigate_previous()` chiamato anche dal touch
  swipe; `welcome_screen._close_settings()` chiamato anche dal Back di
  piattaforma). Emettere il click dentro quei metodi condivisi lo avrebbe
  esteso a percorsi non richiesti da questa card (swipe, Back). Aggiunto un
  wrapper `_on_<bottone>_pressed()` dedicato, connesso solo al `.pressed` del
  bottone, che emette il click e poi chiama il metodo condiviso — nessuna
  modifica alla logica di navigazione stessa.
- **2026-09-09 — Gioca e Tutorial (welcome), e "Successivo" sull'ultima
  pagina del tutorial, esclusi: già coperti da `UI_CONFIRM`.** La
  ricognizione originale della card (Contesto) diceva che `UI_CONFIRM`
  partiva solo da `_on_upgrade_submitted`/`_on_friend_confirmed` in
  `game_audio.gd`. Rileggendo il codice durante l'implementazione,
  `movement_slice.gd:_on_welcome_play_requested` e
  `_on_welcome_tutorial_requested` chiamano già `_game_audio.play_cue(UI_CONFIRM, ...)`
  direttamente (codice preesistente, non aggiunto da questa card) — così
  come `_on_tutorial_play_requested` per "Successivo" quando il testo
  diventa "GIOCA". Aggiungere `UI_CLICK` anche lì avrebbe raddoppiato il
  suono sulla stessa pressione, violando il secondo criterio di
  accettazione. Rimossa l'emissione da quei tre punti; documentato inline
  nel codice per evitare che una futura lettura superficiale della card
  reintroduca il raddoppio.
- **2026-09-09 — Aggiunto `boss_ui.get_continue_button()`.** Mancava un
  getter pubblico per `_continue_button` (solo `get_continue_button_style()`
  esisteva); necessario per collegare il segnale e per lo smoke, stesso
  pattern già usato da tutti gli altri overlay coinvolti.

## Documenti sincronizzati

- [x] `docs/visual-audio-identity.md`: elenco cue completo.

## Note

Se in fase di implementazione emergesse un bottone non elencato qui (per
esempio in un overlay non ancora ricognito), aggiungerlo a questa card è
legittimo solo se non ne cambia l'ambito generale; altrimenti apri una card
separata.
