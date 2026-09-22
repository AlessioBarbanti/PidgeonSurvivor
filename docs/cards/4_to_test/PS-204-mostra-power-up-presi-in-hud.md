---
id: PS-204
titolo: Mostra nell'HUD i power up presi e il loro rango
tipo: ux
area: ui
stato: IN VERIFICA
priorita: media
dipende_da: [PS-203]
origine:
creato: 2026-09-22
aggiornato: 2026-09-22
---

# PS-204 — Mostra nell'HUD i power up presi e il loro rango

## Contesto

Durante la run la build è consultabile solo aprendo la pausa (PS-164). Con il
tetto di 6 power up diversi (PS-203) il giocatore deve sapere, senza
fermarsi, quali posti ha già occupato e a che rango sono. Il lato sinistro
dell'HUD ospita già il calice Sobrietà di Alea (`SobrietySlot`, solo per
Alea): la nuova lista non deve sovrapporvisi.

## Comportamento atteso

Sul lato sinistro, **fuori dalla safe area**, nella striscia fra il bordo
dello schermo e la safe area (su Pixel 9 in landscape è quella del foro della
fotocamera, oggi occupata solo dall'arena), una **griglia di 6 caselle, 2
colonne × 3 righe**, nella metà alta dello schermo. A metà altezza resta una
fascia libera, dove sta il foro. Ogni casella occupata mostra l'icona del
power up e il suo rango; le caselle libere restano visibili e vuote, così il
tetto si legge a colpo d'occhio. Un power up nuovo prende la prima casella
libera (riga per riga, da sinistra) e le caselle non si riordinano quando
cambia un rango.

Nella metà bassa, sotto la fascia libera, un **gruppo separato** con le
Specialità di Barb sbloccate (icona + rango), distinte dagli ordinari con il
trattamento oro già fissato per le righe read-only in
`docs/visual-audio-identity.md` (PS-164).

Griglia e gruppo sono solo da guardare: non intercettano tocchi o clic.

## Criteri di accettazione

- [x] Durante `RUNNING` l'HUD mostra a sinistra 6 caselle in una griglia di
      2 colonne × 3 righe; il loro numero viene dal tetto di PS-203, non da
      una seconda costante.
- [x] Scegliere un power up nuovo lo fa comparire nella prima casella libera
      senza aprire la pausa; salire di rango aggiorna il numero della stessa
      casella.
- [x] L'ordine delle caselle è quello di acquisizione, riga per riga da
      sinistra, e non cambia quando cambiano i ranghi.
- [x] Le Specialità di Barb sbloccate compaiono nel gruppo separato, mai
      dentro le 6 caselle; quelle bloccate non compaiono.
- [x] Griglia e gruppo Specialità partono dal bordo sinistro del
      **viewport**, non da quello della safe area: con una safe area sinistra
      rientrata (profilo cutout simulato) la prima colonna sta nella striscia
      esterna.
- [x] La griglia sta tutta sopra la fascia libera centrata a metà altezza del
      viewport, il gruppo Specialità tutto sotto; nessuna casella la
      interseca. La fascia ha un'altezza unica configurabile e vale su tutte
      le piattaforme, Windows compreso, così il layout è uno solo.
- [x] Giocando Alea, il rettangolo della lista non interseca
      `get_sobriety_icon_rect()`, in tutti i profili di viewport già coperti
      dai test HUD, anche senza striscia laterale (Windows).
- [x] Con 6 caselle piene e tutte le 8 Specialità sbloccate, sul profilo più
      compatto: la lista resta dentro il viewport e non interseca barre
      XP/HP, calice di Alea, pannello abilità né rettangolo di riposo del
      joystick.
- [x] Un tocco che parte sopra la lista avvia il joystick di movimento come
      altrove (la lista non entra in `is_touch_origin_excluded`).
- [x] Restart e cambio personaggio svuotano caselle e gruppo Specialità.

## Ambito

- `scenes/ui/hud.tscn`, `scripts/ui/hud.gd`: nuovo blocco a sinistra,
  righe procedurali che riusano `UpgradeDefinition.icon`. Il blocco non può
  vivere sotto `SafeAreaRoot` come il resto dell'HUD: va posizionato sul
  viewport, come già le barre XP/HP (`_apply_bar_horizontal_margins`).
- `scripts/game/movement_slice.gd`: posizionamento in `_apply_layout()`
  (viewport e safe area) e wiring scene-local dell'`UpgradeService`
  verso l'HUD, come già per `PauseOverlay`; verifica di cablaggio in
  `RunContractValidator`.
- Non toccare `ArenaLayout`: safe area e playfield non cambiano, e non serve
  leggere i cutout del display.
- `UpgradeService` resta la sola fonte della build; l'ordine di acquisizione
  si ricava dai ranghi già posseduti, senza un secondo store nella UI.
- Non toccare `RunController`, l'arbitraggio dei modali, i registry degli
  effetti né il riepilogo della pausa (PS-164). La UI osserva segnali e non
  modifica la build.

## Verifica

- Test: `tests/unit/test_ps204_hud_upgrade_slots.gd`.
- Regressioni: HUD (PS-106, PS-138, PS-146, PS-185), pausa PS-164,
  PS-203; aggiornare `tools/milestone-test-map.json`.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [x] Runtime Windows (cattura con Alea, 6 caselle piene e Specialità
      sbloccate) — fatta con lo script dedicato
      `tools/_capture_hud_build_ps204.gd` invece di aggiungere uno stato a
      `tools/_capture_ui_screenshots.gd`, per non spostare la sequenza
      verificata da PS-044. PNG in `exports/ui-screenshots/ps204-hud-build/`.
- [ ] Validazione statica APK — aperto: APK non ricompilato in questa
      sessione.
- [ ] Runtime fisico Pixel 9 (percorso: run con Alea fino a 6 power up e
      almeno una Specialità; controllo che la colonna stia nella striscia del
      foro fotocamera senza coprirlo, calice e joystick liberi)
- [ ] Controllo percettivo richiesto: sì, con l'agente `direttore-artistico`
      (dimensione icone, leggibilità del rango, trattamento Specialità) —
      aperto. Da guardare in particolare: a 32 px (1280×720 e 960×720 con il
      calice riservato) il numero del rango copre parte dell'icona.

## Decisioni

- **2026-09-22 — Formato.** Confermato dal proprietario: icona + rango,
  6 caselle sempre visibili anche se vuote, in griglia invece che in fila.
- **2026-09-22 — Griglia 2 colonne × 3 righe.** Corretto dal proprietario:
  la prima stesura l'aveva letta come 3 colonne × 2 righe. Sul Pixel la
  griglia sta nella striscia laterale, a sinistra del calice di Alea, e le
  tre righe hanno tutta la metà alta a disposizione. Vincolo da verificare
  su Windows, dove la striscia non esiste: giocando Alea la griglia deve
  stare fra il fondo del calice (`SobrietySlot`, y 58–202 nella `TopBand`) e
  la fascia libera a metà altezza, e tre righe in quello spazio impongono
  caselle più piccole di quanto farebbero due righe. La leggibilità va
  giudicata nel controllo percettivo.
- **2026-09-22 — Specialità.** Confermato dal proprietario: mostrate in un
  gruppo separato, nella metà bassa sotto la fascia del foro.
- **2026-09-22 — Posizione fuori dalla safe area.** Confermato dal
  proprietario: la colonna va nella striscia laterale sinistra fra bordo
  schermo e safe area, non dentro la safe area. Il progetto usa lo stretch
  `expand`, quindi lì c'è arena e non una banda vuota. Su
  Windows la striscia non esiste (restano i 20px di `edge_inset`): la
  colonna finisce a filo schermo e lì il vincolo di non coprire il calice
  di Alea è quello che conta.
- **2026-09-22 — Il foro è sempre a metà.** Regola del proprietario: su tutti
  i telefoni il foro della fotocamera sta esattamente a metà dello schermo.
  Basta quindi una fascia libera fissa a metà altezza, senza leggere
  `DisplayServer.get_display_cutouts()`.
- **2026-09-22 — Dimensione delle caselle calcolata, non fissa.**
  `GameHud.layout_upgrade_slots()` prova le caselle da 44 a 16 px e tiene la
  più grande per cui la griglia, spinta sotto barre XP/HP e calice, resta sopra
  la fascia e il gruppo Specialità resta sopra il fondo del viewport senza
  toccare joystick a riposo e pulsante abilità. Esiti misurati: 1280×720 e
  960×720 → 32 px (griglia sotto il calice, y 226–330); 1600×720 senza
  cutout → 35 px e griglia accanto al calice, dall'alto; cutout 20:9 simulato
  (safe area x 64) → 35 px, prima colonna x 6–41 nella striscia.
- **2026-09-22 — Calice sempre riservato.** Il rettangolo del calice conta
  come ostacolo anche quando non si gioca Alea: il layout resta uno solo e
  non salta al cambio personaggio.
- **2026-09-22 — Specialità in una colonna.** Due colonne sotto la fascia
  urterebbero il joystick a riposo (x 60 su Windows): una colonna di 8
  caselle sta fra la fascia e il fondo del viewport, con lo spazio riservato
  per tutte le Specialità del catalogo così lo sblocco non sposta nulla.
- **2026-09-22 — Fascia del foro a 56 px logici**
  (`GameHud.camera_hole_band_height`, esportato). Valore iniziale da
  confermare sul Pixel.
- **2026-09-22 — Ordine dei posti.** L'HUD legge
  `UpgradeService.get_distinct_upgrade_ids()` (PS-203), che segue l'ordine
  d'inserimento dei ranghi: nessuno store nella UI.
- **2026-09-22 — Trattamento Specialità.** Solo il numero del rango passa
  all'oro `PauseOverlay.BUILD_SUMMARY_SPECIALITY_TITLE_COLOR`, come le righe
  read-only della pausa; nessun bordo o fondo dedicato.
- **Aperta:** dissolvenza della lista quando il Player ci passa sotto, come il
  pulsante abilità (B52). Non richiesta ora; da valutare dopo il primo
  playtest.

## Documenti sincronizzati

- [x] `docs/ui-ux-flow.md` — sezione HUD.
- [x] `docs/visual-audio-identity.md` — trattamento Specialità nell'HUD.
- [x] `tools/milestone-test-map.json` — regressioni del nuovo test.

## Note

- Sblocco: parte quando PS-203 raggiunge almeno `IN VERIFICA`.
- Nessuna nuova arte: icone già presenti nelle definizioni upgrade; caselle
  vuote disegnate proceduralmente.
- Evidenza 2026-09-22:
  `.\tools\run-milestone-checks.ps1 -Milestone PS-204 -Profile Focused -FocusedSmoke tests/unit/test_ps204_hud_upgrade_slots.gd -RefreshEditor`
  → al primo giro 1/4 test fallito: a 1600×720 la griglia sta dentro la
  `TopBand`, che esclude i tocchi di suo; l'assert è stato corretto per
  verificare che la lista non aggiunga esclusioni proprie.
  `-Profile Relevant` → `status=PASS focused=1/1 regression=72/72`
  (212 test, 7529 assert), nessun `SCRIPT ERROR`/`FATAL EXCEPTION`.
  `godot_console --path . --script tools/_capture_hud_build_ps204.gd` →
  `PS204_CAPTURE_DONE`, exit 0, tre PNG (1280×720, 2424×1080, 960×720).
- Il profilo 20:9 su desktop non ha il foro: la posizione nella striscia si
  vede solo sul Pixel.
