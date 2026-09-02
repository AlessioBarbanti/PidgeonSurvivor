---
id: PS-074
titolo: Aggiungi un suono di click ai bottoni UI oggi silenziosi
tipo: ux
area: audio
stato: PRONTO
priorita: bassa
dipende_da: []
origine:
creato: 2026-09-02
aggiornato: 2026-09-02
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

- [ ] Tutti i bottoni elencati in Ambito riproducono un nuovo cue di click
      alla pressione.
- [ ] I bottoni che già causano `UI_CONFIRM`, `PAUSE` o `RESUME` non
      raddoppiano il suono sulla stessa pressione.
- [ ] Pressioni ravvicinate (es. tenere Precedente/Successivo sul carosello o
      sul tutorial) non producono distorsione né accumulo fastidioso: rispetta
      un limite di frequenza, come già fatto per `SHOT`/`HIT` tramite
      `minimum_interval_msec`.
- [ ] Il click funziona identico da mouse, touch e conferma da tastiera/
      gamepad (`ui_accept`) sul bottone a fuoco.
- [ ] Con audio disattivato o volume a zero non è udibile alcun suono.
- [ ] Il cue riusa uno stream CC0 già presente in `assets/audio/` (per
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

## Documenti sincronizzati

- [ ] `docs/visual-audio-identity.md`: elenco cue completo.

## Note

Se in fase di implementazione emergesse un bottone non elencato qui (per
esempio in un overlay non ancora ricognito), aggiungerlo a questa card è
legittimo solo se non ne cambia l'ambito generale; altrimenti apri una card
separata.
