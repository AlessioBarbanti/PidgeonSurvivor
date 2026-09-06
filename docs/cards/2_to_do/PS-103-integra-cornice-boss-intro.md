---
id: PS-103
titolo: Integra la cornice dedicata nella Boss Intro
tipo: ux
area: ui
stato: BLOCCATO
priorita: media
dipende_da: [PS-102]
origine:
creato: 2026-09-05
aggiornato: 2026-09-05
---

# PS-103 — Integra la cornice dedicata nella Boss Intro

## Contesto

[PS-102](./PS-102-cornice-dedicata-boss-intro.md) produce una cornice propria
per il pannello `IntroPanel` di `BossUI` ([scenes/ui/boss_ui.tscn](../../../scenes/ui/boss_ui.tscn),
righe 89-93), oggi ancora sullo `StyleBoxTexture_intro_panel` costruito su
`pause_panel_frame.png` — lo stesso asset del pannello di pausa. Questa card
sostituisce il riferimento e adatta il layout del `PortraitFrame`
(righe 100-116) al nuovo trattamento del ritratto, senza toccare la logica
di `BossUI.show_intro()`/`_apply_visual_kind()` (contratto PS-051, vedi
`docs/enemies-bosses.md` righe 117-138) né lo stato `BOSS_INTRO` del
`RunController`.

## Comportamento atteso

La Boss Intro mostra la nuova cornice prodotta da PS-102 al posto del
pannello di pausa riciclato, con il ritratto nel nuovo trattamento, per
entrambe le varianti (Piccione Malvagio e `Evil <Nome>`), dentro la safe area
già garantita da PS-071, senza regressioni sul resto del contratto PS-051
(tinta nome/cornice per `Evil <Nome>`, nessun trattamento cromatico per il
Piccione Malvagio, CTA "AFFRONTA" invariata).

## Criteri di accettazione

- [ ] `IntroPanel` usa il nuovo `StyleBoxTexture` costruito sull'asset di
      PS-102, non più `pause_panel_frame.png`.
- [ ] `PortraitFrame`/`PortraitTexture` sono ridimensionati/riposizionati per
      il nuovo trattamento del ritratto prodotto da PS-102, senza clipping né
      distorsione dell'immagine.
- [ ] Il Piccione Malvagio (baseline) mostra la nuova cornice senza alcun
      trattamento cromatico personale — titolo e cornice restano sul colore
      neutro, come impone il contratto PS-051 già in vigore.
- [ ] Un `Evil <Nome>` mostra la nuova cornice con nome e cornice tinti
      dall'`accent_color` della sua Signature, mescolato a bianco per restare
      leggibile — stesso contratto PS-051, non toccato da questa card.
- [ ] Ritratto, icona Signature o citazione mancanti fanno ricomporre la
      intro sugli elementi restanti (slot nascosto), mai una texture nulla
      visibile o uno spazio vuoto dedicato — stesso comportamento già
      garantito prima di questa card.
- [ ] Il pannello resta interamente dentro la safe area corrente per ogni
      combinazione di titolo/citazione lunghi già coperta da PS-071, su
      almeno le risoluzioni di riferimento Windows e Android landscape.
- [ ] La CTA "AFFRONTA" non cambia mai stile o colore in base al Boss —
      invariato.
- [ ] Il pannello di pausa (`pause_panel_frame.png` e il proprio
      `StyleBoxTexture`) resta bit-per-bit invariato: nessuna regressione
      cosmetica sulla pausa per effetto di questa card.

## Ambito

- `scenes/ui/boss_ui.tscn`: `StyleBoxTexture_intro_panel`, `PortraitFrame`,
  `PortraitTexture`, `SignatureIcon`.
- `scripts/ui/boss_ui.gd`: solo se il nuovo trattamento del ritratto richiede
  un aggiustamento del riflow di safe area già esistente (righe 16-17, 52-75)
  — non la logica di risoluzione titolo/citazione/icona.

Non toccare:

- `BossUI.show_intro()`, `_apply_visual_kind()` e la risoluzione
  ritratto/icona/tinta per Piccione Malvagio vs `Evil <Nome>` (contratto
  PS-051);
- `BossEncounter.resolve_variant()` e la selezione del profilo Evil
  (PS-006/PS-037);
- lo stato `BOSS_INTRO` del `RunController` e l'arbitraggio dei modali;
- il pannello di pausa e il proprio `StyleBoxTexture`.

## Verifica

- Smoke: `tests/unit/test_ps103_boss_intro_frame_wiring.gd` → marker
  `BOSS_INTRO_FRAME_WIRING_SMOKE_OK` — verifica che `IntroPanel` risolva il
  nuovo `StyleBoxTexture`, che il Piccione Malvagio non riceva tinta e che un
  `Evil <Nome>` la riceva, e che il pannello resti dentro la safe area con
  titolo/citazione al limite di lunghezza già usati da
  `test_ps071` o equivalente.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: Boss Intro sia baseline sia Evil,
      titolo/citazione più lunghi del solito)
- [ ] Controllo percettivo richiesto: sì — la nuova cornice deve leggersi
      come un momento distinto dalla pausa una volta cablata in scena, non
      solo nel provino isolato di PS-102

## Decisioni

- **2026-09-05 — Card di solo wiring, nessuna decisione creativa propria.**
  Ogni scelta sul linguaggio visivo della cornice appartiene a
  [PS-102](./PS-102-cornice-dedicata-boss-intro.md); questa card la applica e
  basta.

## Documenti sincronizzati

- [ ] `docs/enemies-bosses.md`: se il nuovo trattamento del ritratto cambia
      dimensioni o comportamento descritti nella sezione "Boss Intro:
      identità individuale" (righe 117-138), aggiornarla di conseguenza.

## Note

`BLOCCATO` finché [PS-102](./PS-102-cornice-dedicata-boss-intro.md) non
raggiunge almeno `IN VERIFICA` (asset e manifest pronti da cablare), per il
contratto board in `docs/cards/README.md`.

Non è una card `tipo: art`: è wiring in scena, quindi non va delegata a
`game-art-designer` (quella resta la competenza di PS-102). Merita però una
rilettura del diff prima della chiusura, dato che tocca
`boss_ui.tscn`/`boss_ui.gd` e deve preservare il contratto identità
individuale PS-051 senza toccarne la logica. Il proprietario può inoltre
invocare manualmente `qa-esplorativo` una volta cablata la nuova cornice, per
un passaggio esplorativo sulla intro Boss (titoli/citazioni particolarmente
lunghi, sequenza Piccione Malvagio → Evil in run consecutive) che gli smoke
GUT deterministici non coprono.
