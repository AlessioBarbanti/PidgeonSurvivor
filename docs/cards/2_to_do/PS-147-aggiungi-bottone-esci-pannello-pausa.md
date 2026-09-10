---
id: PS-147
titolo: Aggiungi bottone ESCI al pannello pausa
tipo: feat
area: ui
stato: PRONTO
priorita: media
dipende_da: [PS-145]
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-147 — Aggiungi bottone ESCI al pannello pausa

## Contesto

Il pannello "IN PAUSA" ha oggi tre bottoni: RIPRENDI, CAMBIA PERSONAGGIO,
IMPOSTAZIONI. Non esiste un modo per abbandonare la run e tornare al menu
senza aspettare la sconfitta o la vittoria — il proprietario, rivedendo lo
screenshot Pixel 9 aggiornato del pannello (evidenza usata anche da
[PS-145](PS-145-distingui-e-distanzia-bottoni-secondari-pausa.md)), ha
segnalato che manca un bottone ESCI.

Il codebase ha già tutti i pezzi per questo flusso, mai collegati fra loro
per la pausa:

- `RunController.prepare_restart()` (`scripts/game/run_controller.gd`)
  riporta lo stato a `BOOT` da qualunque stato non terminale-lockato —
  `MANUAL_PAUSE` incluso — azzerando seed e tempo di run. È la stessa
  funzione già usata da `_on_change_character_requested()`
  (`scripts/game/movement_slice.gd:2162`) per il bottone "CAMBIA
  PERSONAGGIO" del terminale/pausa, solo che quel percorso chiama poi
  `_show_character_selection()`; ESCI deve chiamare `_show_welcome_screen()`
  invece (destinazione scelta dal proprietario: welcome/selezione, non la
  chiusura dell'app).
- `PauseOverlay` (`scripts/ui/pause_overlay.gd`) ha già un flusso di
  conferma a due bottoni (`ConfirmationCenter`/`CancelChangeButton`/
  `ConfirmChangeButton`) usato oggi solo da CAMBIA PERSONAGGIO. Va reso
  generico per un secondo scopo (ESCI) invece di duplicare il pannello.

Consultato il direttore-artistico (modalità pianificazione, screenshot
Pixel 9 alla mano): la texture nine-slice condivisa dai bottoni secondari
(`secondary_button_cta_base.png`) ha canale rosso ≈0, quindi non può
virare verso un vero rosso/allerta via `modulate_color` — può solo
scurirsi. La direzione data: ESCI è il gradino più scuro di una rampa di
luminosità a tre livelli (CAMBIA PERSONAGGIO = base, IMPOSTAZIONI = chiaro,
ESCI = scuro), isolato in fondo alla colonna da uno spazio extra, con
l'unico vero accento di tinta (un corallo tenue, stessa famiglia del rosso
"GAME OVER" di `end_screen.tscn` ma desaturato) portato dal `font_color`
del testo, non dalla texture.

## Comportamento atteso

Nel pannello "IN PAUSA", un quarto bottone "ESCI" appare in fondo alla
colonna, separato dagli altri due bottoni secondari da uno spazio più
ampio del normale. Il suo stile è visibilmente più scuro di CAMBIA
PERSONAGGIO e IMPOSTAZIONI, con il testo in un tono corallo tenue invece
del crema standard. Premendolo apre una conferma ("USCIRE DALLA PARTITA?")
con le stesse due opzioni (Annulla/Conferma) già viste per CAMBIA
PERSONAGGIO; confermando, la run corrente viene abbandonata (seed e tempo
azzerati, nessuna schermata di vittoria/sconfitta) e il gioco torna alla
welcome. Annullando, si torna al pannello pausa con RIPRENDI/CAMBIA
PERSONAGGIO/IMPOSTAZIONI/ESCI di nuovo attivi.

## Criteri di accettazione

- [ ] `scenes/ui/pause_overlay.tscn`: nuovo nodo `ExitButton` (`Button`,
      `unique_name_in_owner`) nel `VBox` della colonna pausa, dopo
      `SettingsButton`, testo `"ESCI"`, stessa sagoma/altezza (64px) dei
      bottoni secondari.
- [ ] Fra `SettingsButton` ed `ExitButton` è inserito un `Control`
      spaziatore dedicato (`custom_minimum_size = Vector2(0, 24)`), in
      aggiunta alla `separation = 16` del `VBox`: il vuoto percepito prima
      di ESCI è quindi maggiore di quello fra gli altri bottoni.
- [ ] `ExitButton` usa tre nuovi `StyleBoxTexture` dedicati (stessa
      `AtlasTexture_secondary_cta`, stessi `texture_margin_*`/
      `expand_margin_*` dei cloni già introdotti da PS-145) con
      `modulate_color`: `normal = Color(0.5, 0.5, 0.58, 1)`,
      `hover = Color(0.7, 0.68, 0.74, 1)`, `pressed = Color(0.34, 0.34, 0.4, 1)`;
      `focus` riusa lo stato `hover`. Il risultato è più scuro sia di
      CAMBIA PERSONAGGIO sia di IMPOSTAZIONI in ogni stato.
- [ ] `ExitButton` ha `font_color = Color(0.95, 0.72, 0.7, 1)` (corallo
      tenue); RIPRENDI/CAMBIA PERSONAGGIO/IMPOSTAZIONI non cambiano
      `font_color`.
- [ ] Premere `ExitButton` mostra lo stesso `ConfirmationCenter` già usato
      da CAMBIA PERSONAGGIO, con `TitleLabel.text = "USCIRE DALLA
      PARTITA?"` e `SummaryLabel.text` che comunica l'abbandono della run
      corrente (es. "Abbandonerai la run corrente e tornerai al menu.") —
      non un secondo pannello duplicato.
- [ ] Confermare l'uscita: `RunController.prepare_restart()` viene
      chiamato e il gioco mostra la welcome screen (`_show_welcome_screen()`
      o equivalente), non la selezione personaggio e non l'end screen.
      Annullare l'uscita torna al pannello pausa con tutti e quattro i
      bottoni riabilitati, senza toccare lo stato `MANUAL_PAUSE`.
- [ ] La catena `focus_neighbor` copre i quattro elementi della colonna
      pausa (RIPRENDI ↔ CAMBIA PERSONAGGIO ↔ IMPOSTAZIONI ↔ ESCI) più il
      loop Annulla ↔ Conferma nella conferma, coerente con l'uso duale
      (CAMBIA PERSONAGGIO/ESCI) del `ConfirmationCenter`.
- [ ] A parità di viewport, l'altezza naturale del `VBox` (con il quarto
      bottone e lo spaziatore) resta un tetto per il clamp di PS-142, non
      un pavimento: nessuna scrollbar visibile su 16:9/20:9.

## Ambito

- File attesi: `scenes/ui/pause_overlay.tscn` (`VBox`, spaziatore, nuovi
  sub_resource `StyleBoxTexture_exit_*`, nodo `ExitButton`,
  `ConfirmationCenter` reso a doppio scopo), `scripts/ui/pause_overlay.gd`
  (nuovo segnale `exit_requested` o equivalente, stato "quale azione sta
  confermando" per instradare Annulla/Conferma), `scripts/game/movement_slice.gd`
  (nuovo handler che collega `exit_requested` a
  `_run_controller.prepare_restart()` + `_show_welcome_screen()`, sul
  modello di `_on_change_character_requested()`).
- Non toccare: `RunController` (nessuno stato nuovo — si riusa
  `prepare_restart()` così com'è), lo stile/testo di CAMBIA PERSONAGGIO e
  IMPOSTAZIONI già fissato da PS-145, `end_screen.tscn` (il suo bottone
  CAMBIA PERSONAGGIO resta invariato).
- Non introdurre un `RunState` dedicato per "run abbandonata": il contratto
  `BOOT/RUNNING/MANUAL_PAUSE/LEVEL_UP/BOSS_INTRO/BARB_REWARD/VICTORY/DEFEAT`
  resta quello descritto in CLAUDE.md.

## Verifica

- Smoke: `tests/unit/test_ps147_pause_exit_button.gd` → marker
  `PS147_PAUSE_EXIT_OK`, verifica presenza/stile/font_color di
  `ExitButton`, che la conferma mostri il testo corretto per ESCI (non
  quello di CAMBIA PERSONAGGIO), che confermare chiami
  `prepare_restart()` e porti a `BOOT` con la welcome visibile, che
  annullare non tocchi lo stato, e la catena `focus_neighbor` a quattro
  elementi.
- Aggiornare `tests/unit/test_ps145_pause_buttons_distinct_and_spaced.gd`
  se la sua assunzione di "tre bottoni nel VBox" deve diventare "almeno
  tre", per non rompersi quando ESCI è presente.
- Rigenerare il pacchetto di catture UI
  (`godot_console --path . --script tools/_capture_ui_screenshots.gd`) per
  includere ESCI nello scatto `07_pause_overlay` e verificare a colpo
  d'occhio la rampa di luminosità a tre livelli.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: pausa → ESCI → conferma → welcome;
      pausa → ESCI → annulla → pausa)
- [ ] Controllo percettivo richiesto: sì — confronto screenshot
      prima/dopo con il proprietario, stessa evidenza di PS-145

## Decisioni

- **2026-09-10 — Nata da revisione dello screenshot Pixel 9 di PS-145.**
  Il proprietario ha chiesto un bottone ESCI mancante nel pannello pausa;
  separata da PS-145 perché tocca `movement_slice.gd`/il flusso di
  navigazione, non solo lo stile di `pause_overlay.tscn`.
- **2026-09-10 — Destinazione di ESCI: welcome/selezione, non chiusura
  dell'app.** Scelta esplicita del proprietario via domanda diretta.
- **2026-09-10 — ESCI richiede conferma, riusando `ConfirmationCenter`.**
  Scelta esplicita del proprietario: CAMBIA PERSONAGGIO (che azzera "solo"
  la run corrente) ha già una conferma; ESCI è pari o più distruttivo e
  non può restare un singolo tap senza rete di sicurezza. Si riusa lo
  stesso pannello invece di duplicarlo, cambiando testo e segnale emesso
  in base a quale bottone lo ha aperto.
- **2026-09-10 — Consultato il direttore-artistico (modalità
  pianificazione) per i valori di stile.** Confermato via campionamento
  pixel che la texture nine-slice condivisa non può virare hue (canale
  rosso ≈0): la differenziazione usa tre assi indipendenti — rampa di
  luminosità (`modulate_color`, ESCI il più scuro dei tre bottoni
  "freddi"), spaziatura di gruppo (spaziatore da 24px isola ESCI dagli
  altri due, azione diversa dalle reversibili sopra), `font_color` corallo
  come unico vero accento di tinta, preso in prestito dalla famiglia
  cromatica di "GAME OVER" in `end_screen.tscn` ma desaturato.

## Documenti sincronizzati

- [ ] `docs/visual-audio-identity.md`: aggiungere la regola emersa dal
      direttore-artistico — quando più bottoni condividono una nine-slice
      a canale rosso nullo, la differenziazione va costruita su
      luminosità (`modulate_color`) + spaziatura di gruppo + `font_color`
      (mai un hue-shift via `modulate_color`, che la texture non regge).
- [ ] `docs/ui-ux-flow.md`: documentare il nuovo percorso pausa → ESCI →
      conferma → welcome come uscita esplicita dalla run, distinta da
      vittoria/sconfitta.

## Note

Alternative scartate dal direttore-artistico: un quarto tono di blu ancora
diverso per ESCI (la texture non lo regge in modo leggibile: produce un
"blu sporco" che sembra un errore di rendering); un vero rosso/allerta via
`modulate_color` (impossibile, canale rosso della texture base ≈0).
