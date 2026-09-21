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

Sul lato sinistro, dentro la safe area e sotto la fascia HUD in alto, una
colonna di **6 caselle**: ogni casella occupata mostra l'icona del power up e
il suo rango; le caselle libere restano visibili e vuote, così il tetto si
legge a colpo d'occhio. Un power up nuovo prende la prima casella libera e le
caselle non si riordinano quando cambia un rango.

Sotto le 6 caselle, un **gruppo separato** con le Specialità di Barb
sbloccate (icona + rango), distinte dagli ordinari con il trattamento oro già
fissato per le righe read-only in `docs/visual-audio-identity.md` (PS-164).

La lista è solo da guardare: non intercetta tocchi o clic.

## Criteri di accettazione

- [ ] Durante `RUNNING` l'HUD mostra 6 caselle a sinistra; il loro numero
      viene dal tetto di PS-203, non da una seconda costante.
- [ ] Scegliere un power up nuovo lo fa comparire nella prima casella libera
      senza aprire la pausa; salire di rango aggiorna il numero della stessa
      casella.
- [ ] L'ordine delle caselle è quello di acquisizione e non cambia quando
      cambiano i ranghi.
- [ ] Le Specialità di Barb sbloccate compaiono nel gruppo separato, mai
      dentro le 6 caselle; quelle bloccate non compaiono.
- [ ] Giocando Alea, il rettangolo della lista non interseca
      `get_sobriety_icon_rect()`, in tutti i profili di viewport già coperti
      dai test HUD.
- [ ] Con 6 caselle piene e tutte le 8 Specialità sbloccate, sul profilo più
      compatto: la lista resta dentro la safe area e non interseca fascia
      superiore, calice di Alea, pannello abilità né rettangolo di riposo del
      joystick.
- [ ] Un tocco che parte sopra la lista avvia il joystick di movimento come
      altrove (la lista non entra in `is_touch_origin_excluded`).
- [ ] Restart e cambio personaggio svuotano caselle e gruppo Specialità.

## Ambito

- `scenes/ui/hud.tscn`, `scripts/ui/hud.gd`: nuovo blocco a sinistra sotto
  `SobrietySlot`, righe procedurali che riusano `UpgradeDefinition.icon`.
- `scripts/game/movement_slice.gd`: wiring scene-local dell'`UpgradeService`
  verso l'HUD, come già per `PauseOverlay`; verifica di cablaggio in
  `RunContractValidator`.
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
      almeno una Specialità; controllo safe area, calice e joystick)
- [ ] Controllo percettivo richiesto: sì, con l'agente `direttore-artistico`
      (dimensione icone, leggibilità del rango, trattamento Specialità)

## Decisioni

- **2026-09-22 — Formato.** Confermato dal proprietario: icona + rango,
  6 caselle sempre visibili anche se vuote.
- **2026-09-22 — Specialità.** Confermato dal proprietario: mostrate in un
  gruppo separato sotto le 6 caselle.
- **2026-09-22 — Posizione unica.** La lista parte sotto il calice di Alea
  per tutti i personaggi, così il layout non cambia fra un personaggio e
  l'altro.
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
