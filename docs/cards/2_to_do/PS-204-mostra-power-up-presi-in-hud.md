---
id: PS-204
titolo: Mostra nell'HUD i power up presi e il loro rango
tipo: ux
area: ui
stato: BLOCCATO
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
fotocamera, oggi occupata solo dall'arena), una **griglia di 6 caselle, 3
colonne × 2 righe**, nella metà alta dello schermo. A metà altezza resta una
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

- [ ] Durante `RUNNING` l'HUD mostra a sinistra 6 caselle in una griglia di
      3 colonne × 2 righe; il loro numero viene dal tetto di PS-203, non da
      una seconda costante.
- [ ] Scegliere un power up nuovo lo fa comparire nella prima casella libera
      senza aprire la pausa; salire di rango aggiorna il numero della stessa
      casella.
- [ ] L'ordine delle caselle è quello di acquisizione, riga per riga da
      sinistra, e non cambia quando cambiano i ranghi.
- [ ] Le Specialità di Barb sbloccate compaiono nel gruppo separato, mai
      dentro le 6 caselle; quelle bloccate non compaiono.
- [ ] Griglia e gruppo Specialità partono dal bordo sinistro del
      **viewport**, non da quello della safe area: con una safe area sinistra
      rientrata (profilo cutout simulato) la prima colonna sta nella striscia
      esterna.
- [ ] La griglia sta tutta sopra la fascia libera centrata a metà altezza del
      viewport, il gruppo Specialità tutto sotto; nessuna casella la
      interseca. La fascia ha un'altezza unica configurabile e vale su tutte
      le piattaforme, Windows compreso, così il layout è uno solo.
- [ ] Giocando Alea, il rettangolo della lista non interseca
      `get_sobriety_icon_rect()`, in tutti i profili di viewport già coperti
      dai test HUD, anche senza striscia laterale (Windows).
- [ ] Con 6 caselle piene e tutte le 8 Specialità sbloccate, sul profilo più
      compatto: la lista resta dentro il viewport e non interseca barre
      XP/HP, calice di Alea, pannello abilità né rettangolo di riposo del
      joystick.
- [ ] Un tocco che parte sopra la lista avvia il joystick di movimento come
      altrove (la lista non entra in `is_touch_origin_excluded`).
- [ ] Restart e cambio personaggio svuotano caselle e gruppo Specialità.

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

- [ ] Runtime Windows (cattura `tools/_capture_ui_screenshots.gd` con Alea,
      6 caselle piene e Specialità sbloccate)
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run con Alea fino a 6 power up e
      almeno una Specialità; controllo che la colonna stia nella striscia del
      foro fotocamera senza coprirlo, calice e joystick liberi)
- [ ] Controllo percettivo richiesto: sì, con l'agente `direttore-artistico`
      (dimensione icone, leggibilità del rango, trattamento Specialità)

## Decisioni

- **2026-09-22 — Formato.** Confermato dal proprietario: icona + rango,
  6 caselle sempre visibili anche se vuote, in griglia 3×2 invece che in
  fila. Letta come 3 colonne × 2 righe: così la griglia sta fra il calice
  di Alea e la fascia del foro; 2 colonne × 3 righe non ci entrerebbe in
  altezza.
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
- **Aperta:** dissolvenza della lista quando il Player ci passa sotto, come il
  pulsante abilità (B52). Non richiesta ora; da valutare dopo il primo
  playtest.

## Documenti sincronizzati

- [ ] `docs/ui-ux-flow.md` — sezione HUD.
- [ ] `docs/visual-audio-identity.md` — trattamento Specialità nell'HUD.
- [ ] `tools/milestone-test-map.json` — regressioni del nuovo test.

## Note

- Sblocco: parte quando PS-203 raggiunge almeno `IN VERIFICA`.
- Nessuna nuova arte: icone già presenti nelle definizioni upgrade; caselle
  vuote disegnate proceduralmente.
