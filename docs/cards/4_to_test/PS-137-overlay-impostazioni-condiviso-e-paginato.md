---
id: PS-137
titolo: Overlay impostazioni condiviso, più grande e paginato per categoria
tipo: ux
area: ui
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-09-09
aggiornato: 2026-09-09
---

# PS-137 — Overlay impostazioni condiviso, più grande e paginato per categoria

## Contesto

Oggi welcome e pausa hanno ciascuna il proprio pannello impostazioni: la
welcome apre `%SettingsPanel` da un tasto ingranaggio dedicato, la pausa
mostra le stesse tre sezioni (Audio, Accessibilità, Controlli touch) inline
nel proprio pannello, insieme a Resume e Cambia personaggio, tutto in un
unico `VBoxContainer` scrollabile. PS-050 aveva uniformato lo *stile* fra i
due pannelli ma aveva deciso esplicitamente di **non** condividere la scena,
per non accoppiare due schermate con cicli di vita diversi (welcome pre-run
in `BOOT`, pausa in-run in `MANUAL_PAUSE`).

Il proprietario chiede ora di invertire quella scelta: un solo modal
impostazioni condiviso fra welcome e pausa, più grande di oggi, con la pausa
semplificata a un tasto dedicato che lo apre invece dei controlli inline, e
il contenuto paginato per categoria invece che in un unico scroll verticale.

## Comportamento atteso

Un solo overlay impostazioni, istanziato una volta nella scena di run, si
apre sia dal tasto ingranaggio della welcome sia da un nuovo tasto
ingranaggio nella pausa. Il modal è dimensionato a un target fisso più
grande di quello attuale, restando dentro la safe area su 16:9, 20:9 e 4:3.
Il contenuto è diviso in tre tab orizzontali testuali — AUDIO,
ACCESSIBILITÀ, CONTROLLI TOUCH — che mostrano una categoria alla volta;
ogni apertura riparte sempre dalla tab AUDIO. Il pannello di pausa si
riduce a Resume e Cambia personaggio in colonna, con l'icona ingranaggio
fluttuante fuori da quella colonna, nella stessa posizione/stile del tasto
ingranaggio della welcome, per aprire l'overlay condiviso.

## Criteri di accettazione

- [x] Un solo nodo overlay impostazioni esiste nella scena di run, non più
      due alberi paralleli in welcome e pausa.
- [x] Il tasto ingranaggio della welcome e il nuovo tasto ingranaggio della
      pausa aprono la stessa istanza dell'overlay.
- [x] L'overlay è dimensionato a un target fisso più grande di quello
      attuale della welcome/pausa, e resta interamente dentro la safe area
      su 16:9, 20:9 e 4:3.
- [x] Il contenuto è diviso in tre tab orizzontali testuali — AUDIO,
      ACCESSIBILITÀ, CONTROLLI TOUCH — che mostrano una categoria alla
      volta; nessuno scroll verticale che le mescoli tutte e tre.
- [x] Ogni apertura dell'overlay mostra sempre la tab AUDIO per prima,
      indipendentemente da quale tab fosse attiva all'ultima chiusura.
- [x] Volume, mute, riduzione lampeggi, sparo manuale, dimensione abilità e
      dimensione joystick leggono e scrivono lo stesso stato persistente di
      oggi, indipendentemente da quale tasto (welcome o pausa) ha aperto
      l'overlay.
- [x] Il pannello di pausa mostra solo Resume e Cambia personaggio in
      colonna; l'icona ingranaggio per le impostazioni è fluttuante fuori
      da quella colonna, nella stessa posizione/stile del tasto ingranaggio
      della welcome.
- [x] Back/`ui_cancel` chiude solo l'overlay impostazioni quando è aperto,
      senza chiudere welcome o pausa sottostante; se l'overlay non è
      aperto, Back si comporta come oggi in welcome/pausa.
- [x] L'icona ingranaggio della pausa è raggiungibile via `focus_neighbor`
      insieme a Resume e Cambia personaggio, e le tre tab dell'overlay sono
      navigabili da tastiera/gamepad senza mouse/touch.
- [x] Il flusso di conferma cambio personaggio (`ConfirmationCenter`) resta
      invariato e non interagisce con l'overlay impostazioni condiviso.

## Ambito

- `scenes/ui/welcome_screen.tscn`, `scripts/ui/welcome_screen.gd`.
- `scenes/ui/pause_overlay.tscn`, `scripts/ui/pause_overlay.gd`.
- Nuova scena/script per l'overlay impostazioni condiviso (es.
  `scenes/ui/settings_overlay.tscn`), istanziato una sola volta in
  `scenes/game/movement_slice.tscn`.
- `scripts/game/movement_slice.gd`: wiring dei segnali/getter oggi
  duplicati fra welcome e pausa, incluso `_touch_control_settings.configure(...)`
  e `_fire_mode_settings.configure(...)`, che oggi assumono due nodi target
  distinti con gli stessi getter/signal.
- Gestione di Back/`ui_cancel` per il nuovo overlay.

Non toccare:

- `RunController`: stati e arbitraggio dei modali. L'overlay resta un layer
  puramente visivo sopra lo stato attivo (`BOOT` o `MANUAL_PAUSE`) e non
  introduce nuovi stati.
- Flusso `welcome → tutorial → selezione → run → pausa`.
- `ConfirmationCenter` (conferma cambio personaggio) e la sua logica.
- Formato e percorso della persistenza delle impostazioni.
- `pause_panel_frame.png`: riusato as-is (nine-slice 768×512, margini
  56×52, già pensato per scalare). Un'eventuale sfocatura percettibile alla
  dimensione ingrandita è un gate manuale da verificare, non un lavoro di
  arte precondizionato da questa card.

## Verifica

- Smoke: `tests/unit/test_ps137_shared_settings_overlay.gd` → marker
  `SHARED_SETTINGS_OVERLAY_SMOKE_OK` — verifica istanza unica, apertura da
  entrambi i tasti, sincronizzazione dello stato, tab che ripartono sempre
  da AUDIO, Back che chiude solo l'overlay, catena `focus_neighbor`
  dell'icona ingranaggio in pausa.
- `tests/unit/test_ps050_welcome_settings_system.gd` assume due alberi
  paralleli sincronizzati e va rivisto o sostituito coerentemente col nuovo
  contratto a istanza unica; registrare la scelta in Decisioni durante la
  risoluzione.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: apri l'overlay dalla welcome, cambia un
      valore, apri l'overlay dalla pausa e verifica lo stesso valore; naviga
      le tre tab a touch
- [ ] Controllo percettivo richiesto: sì — verificare che
      `pause_panel_frame.png` non risulti sfocato/tirato alla dimensione
      ingrandita su 16:9, 20:9 e 4:3; se sfocato, aprire una card separata
      `tipo: art` per un master a risoluzione maggiore dello stesso frame

## Decisioni

- **2026-09-09 — Inverte la decisione PS-050.** PS-050 aveva scelto
  esplicitamente due alberi di scena distinti con lo stesso stile, per non
  accoppiare cicli di vita diversi (welcome pre-run, pausa in-run). Il
  proprietario ha richiesto ora esplicitamente un modal condiviso; questa
  card riapre quel confine con piena consapevolezza.
- **2026-09-09 — Dimensione: target fisso più grande**, non percentuale di
  safe-area né "nessun ingrandimento esplicito". Deciso dal proprietario
  dopo consulto di pianificazione con `game-art-designer` (opzioni
  presentate: percentuale di safe-area, target fisso, nessun ingrandimento
  esplicito con solo respiro per categoria).
- **2026-09-09 — Condivisione: overlay unico top-level a istanza singola**,
  non scena riusabile duplicata né reparent a runtime. Deciso dal
  proprietario su raccomandazione tecnica del `game-art-designer`, per
  aderenza al vincolo scene-local/signal-driven e per eliminare la doppia
  sincronizzazione di stato che PS-050 aveva lasciato aperta fra i due
  pannelli separati.
- **2026-09-09 — Paginazione: tab orizzontali testuali**, non frecce
  prev/next né tab verticali con icona. Nessuna nuova arte richiesta: card
  `tipo: art` non necessaria — l'icona ingranaggio è un glifo Unicode su
  `StyleBoxFlat` generati a codice, le tab riusano lo stile `ButtonStandard`
  già presente in entrambe le scene.
- **2026-09-09 — Tasto pausa: icona ingranaggio fluttuante** che replica
  posizione e stile del gear button della welcome, fuori dalla colonna
  Resume/Cambia personaggio. La colonna pausa si riduce a due soli bottoni.
- **2026-09-09 — La paginazione riparte sempre dalla tab AUDIO a ogni
  apertura**, non ricorda l'ultima categoria vista. Scelta per
  comportamento deterministico e testabile, e perché lo stesso overlay ora
  si apre da due punti di ingresso diversi (welcome e pausa).
- **Sostituisce:** la decisione "nessuna scena condivisa" di PS-050
  ([docs/cards/5_completed/PS-050-uniforma-impostazioni-welcome-alla-pausa.md](../5_completed/PS-050-uniforma-impostazioni-welcome-alla-pausa.md),
  sezione Decisioni, voce 2026-09-01).
- **2026-09-09 — Nodo diretto figlio di `UI`, non di `UI/SafeAreaRoot`.**
  Welcome/Tutorial/CharacterSelectOverlay vivono sotto `SafeAreaRoot`
  (inset automatico), ma `PauseOverlay` ed `EndScreen` sono figli diretti di
  `UI`, aggiunti dopo `SafeAreaRoot`: in Godot i fratelli successivi
  disegnano sopra. Mettere l'overlay sotto `SafeAreaRoot` lo avrebbe fatto
  disegnare *sotto* `PauseOverlay`, invisibile/non interagibile quando
  aperto dalla pausa. Aggiunto come ultimo figlio di `UI` (dopo
  `PauseOverlay` ed `EndScreen`) per restare sempre in cima; la sua safe
  area non usa l'inset di `SafeAreaRoot` ma lo stesso margine fisso
  (`SAFETY_MARGIN = 24.0`) già usato da `PauseOverlay`, che ha lo stesso
  vincolo strutturale.
- **2026-09-09 — Wiring audio consolidato dentro `GameAudio`, non in
  `movement_slice.gd`.** Prima della card, il volume/mute della welcome
  passava da `movement_slice.gd` (`_on_welcome_audio_volume_changed` →
  `GameAudio.set_effects_volume`), mentre quello della pausa era già
  cablato direttamente dentro `GameAudio.configure()` — la stessa
  duplicazione di percorso che la card doveva risolvere. Scelto di
  consolidare sul pattern già usato da `GameAudio` (si connette da sé a
  `SettingsOverlay.audio_volume_changed`/`audio_mute_toggled`), coerente con
  "GameAudio: gestore unico e scene-local" di `CLAUDE.md`; rimossi gli
  handler ormai morti in `movement_slice.gd`.
- **2026-09-09 — Focus vuoto (`StyleBoxEmpty`) per le tab e il bottone
  Chiudi, non l'hover-come-focus della pausa.** La welcome usava
  `StyleBoxEmpty` per il focus dei propri bottoni (nessun riquadro
  visibile), la pausa riusa lo stile hover. Per l'overlay condiviso scelto
  lo stile welcome (coerente con `test_b18o_welcome_flow.gd`, che verificava
  già questo contratto sul vecchio pannello locale); i bottoni originali di
  pausa (Riprendi/Cambia personaggio/conferma) restano invariati con la
  loro convenzione.
- **2026-09-09 — `clip_text = true` sulle tre tab.** Lo stile `ButtonStandard`
  (texture 9-slice pensata per CTA singole, non per tre bottoni testuali
  affiancati) ha margini di texture ampi; con testo pieno "ACCESSIBILITÀ"/
  "CONTROLLI TOUCH" la larghezza minima naturale del pannello sforava il
  viewport 4:3 compatto (960×720, PS-085) — scoperto dal test di safe area
  di questa stessa card, non assunto a tavolino. `clip_text` toglie il
  contributo del testo alla dimensione minima del bottone (resta leggibile
  sui profili più larghi, dove c'è spazio); non è stato necessario cambiare
  lo stile stesso, restando fedeli alla decisione "riusa `ButtonStandard`".
- **2026-09-09 — `test_ps050_welcome_settings_system.gd` ritirato, non
  riscritto.** Il contratto che verificava (due alberi paralleli
  sincronizzati) non esiste più: l'istanza singola introdotta da questa
  card è ora l'unico contratto sensato, e `test_ps137_shared_settings_overlay.gd`
  lo copre da zero. Riscrivere il vecchio file l'avrebbe reso un doppione.
  Rimosso da `tools/milestone-test-map.json` insieme al file.
- **2026-09-09 — Nessuna menzione nuova in `CLAUDE.md`.** Verificato in
  chiusura come richiesto: la regola già esistente ("Back/annulla chiude
  solo il modale in cima, mai la run") copre già il comportamento
  dell'overlay condiviso senza bisogno di una voce dedicata — resta un
  dettaglio di implementazione UI, non un nuovo contratto architetturale.

## Documenti sincronizzati

- [x] `docs/ui-ux-flow.md`: aggiornato l'elenco schermate e i due punti
      dell'arbitrato Back (`BOOT`/`MANUAL_PAUSE`) per riflettere l'overlay
      condiviso.
- [x] `CLAUDE.md`: verificato in chiusura — nessuna modifica necessaria
      (vedi Decisioni).

## Note

Consulto di pianificazione con `game-art-designer` (2026-09-09) ha
verificato che nessun pezzo di arte nuova serve per le scelte fatte:
`%SettingsButton` della welcome è testo Unicode (`"⚙"`,
`theme_type_variation = "GlyphButtonL"`) su `StyleBoxFlat` a codice
(`welcome_screen.tscn` righe 113-270), le tab riusano
`secondary_button_cta_base.png` già in uso. File di riferimento per chi
risolve la card: `assets/art/ui/pause/ASSET-MANIFEST.md` (voce
`pause_panel_frame.png`), `scripts/ui/welcome_screen.gd` righe 291-303
(pattern `_update_main_action_focus`, da replicare in pausa per l'icona
ingranaggio nella catena `focus_neighbor`).
