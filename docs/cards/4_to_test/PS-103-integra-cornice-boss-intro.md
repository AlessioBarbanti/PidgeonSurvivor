---
id: PS-103
titolo: Integra la cornice dedicata nella Boss Intro
tipo: ux
area: ui
stato: IN VERIFICA
priorita: media
dipende_da: [PS-102]
origine:
creato: 2026-09-05
aggiornato: 2026-09-06
---

# PS-103 — Integra la cornice dedicata nella Boss Intro

## Contesto

[PS-102](../4_to_test/PS-102-cornice-dedicata-boss-intro.md) produce una cornice propria
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

- [x] `IntroPanel` usa il nuovo `StyleBoxTexture` costruito sull'asset di
      PS-102, non più `pause_panel_frame.png`.
- [x] `PortraitFrame`/`PortraitTexture` sono ridimensionati/riposizionati per
      il nuovo trattamento del ritratto prodotto da PS-102, senza clipping né
      distorsione dell'immagine.
- [x] Il Piccione Malvagio (baseline) mostra la nuova cornice senza alcun
      trattamento cromatico personale — titolo e cornice restano sul colore
      neutro, come impone il contratto PS-051 già in vigore.
- [x] Un `Evil <Nome>` mostra la nuova cornice con nome e cornice tinti
      dall'`accent_color` della sua Signature, mescolato a bianco per restare
      leggibile — stesso contratto PS-051, non toccato da questa card.
- [x] Ritratto, icona Signature o citazione mancanti fanno ricomporre la
      intro sugli elementi restanti (slot nascosto), mai una texture nulla
      visibile o uno spazio vuoto dedicato — stesso comportamento già
      garantito prima di questa card (logica di `_apply_portrait`/
      `_apply_signature_identity` non toccata, smoke PS-051 invariati verdi).
- [x] Il pannello resta interamente dentro la safe area corrente per ogni
      combinazione di titolo/citazione lunghi già coperta da PS-071, su
      almeno le risoluzioni di riferimento Windows e Android landscape —
      verificato dal nuovo smoke PS-103 e dai smoke PS-051/B15 esistenti
      (aspect ratio 16:9, 20:9, 4:3, safe rect reali di gioco). Il runtime
      fisico Pixel 9 resta comunque un gate manuale aperto (vedi sotto).
- [x] La CTA "AFFRONTA" non cambia mai stile o colore in base al Boss —
      invariato (non toccato da questa card, smoke esistenti ancora verdi).
- [x] Il pannello di pausa (`pause_panel_frame.png` e il proprio
      `StyleBoxTexture`) resta bit-per-bit invariato: nessuna regressione
      cosmetica sulla pausa per effetto di questa card — verificato dallo
      smoke PS-103 dedicato e da uno screenshot reale del pannello di pausa.

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
  `Evil <Nome>` la riceva, che il pannello resti dentro la safe area con
  titolo/citazione al limite di lunghezza, e che il pannello di pausa resti
  invariato.
- Regressione: `test_ps051_boss_intro_identity.gd` (identità PS-051 e safe
  area su 3 aspect ratio) e `test_b15_boss_encounter.gd` (flusso Boss
  completo) restano verdi senza modifiche.
- Profilo eseguito: `Relevant` (54/54 verdi) e `Full` (111/111 verdi +
  toolchain), nessun `SCRIPT ERROR`/`FATAL EXCEPTION` nei log.
- Verifica visiva non bloccante: cattura reale via
  `tools/_capture_ui_screenshots.gd` (profili 16:9 e Pixel 9 20:9) per il
  Piccione Malvagio e un Evil (`EVIL MARGHE`) e per il pannello di pausa —
  nessuna regressione visibile, medaglione ritagliato correttamente in
  cerchio, cornice leggibile e distinta dalla pausa. Non sostituisce il
  controllo percettivo del proprietario richiesto sotto.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: Boss Intro sia baseline sia Evil,
      titolo/citazione più lunghi del solito)
- [ ] Controllo percettivo richiesto: sì — la nuova cornice deve leggersi
      come un momento distinto dalla pausa una volta cablata in scena, non
      solo nel provino isolato di PS-102. Uno screenshot reale (Windows,
      16:9 e Pixel 9 20:9, baseline ed Evil) è già stato prodotto come prima
      verifica ma non sostituisce il controllo del proprietario.

## Decisioni

- **2026-09-05 — Card di solo wiring, nessuna decisione creativa propria.**
  Ogni scelta sul linguaggio visivo della cornice appartiene a
  [PS-102](../4_to_test/PS-102-cornice-dedicata-boss-intro.md); questa card la applica e
  basta.
- **2026-09-06 — Il ritratto è un overlay disegnato prima di `%Center`, non
  un figlio della `VBox`.** Il medaglione di PS-102 e' un cerchio scavato
  nella parte alta dell'immagine (764x464), fuori dal flusso verticale di
  titolo/citazione/CTA. Tenerlo dentro la `VBox` (come nel vecchio riquadro
  112x112) avrebbe richiesto o distorcere il layout o tagliare il cerchio.
  `PortraitFrame` e' quindi un `Control` figlio di `IntroLayer`, inserito
  **prima** di `%Center` nell'ordine dei figli (vedi `boss_ui.tscn`):
  l'anello opaco della cornice, disegnato dopo, ritaglia gli angoli quadrati
  del ritratto in un cerchio pulito per pura sovrapposizione alpha, senza
  bisogno di shader o maschere. La posizione (`_reflow_portrait_frame` in
  `scripts/ui/boss_ui.gd`) riusa gli stessi `margin_x`/`margin_y` già
  calcolati da `_reflow_intro_panel_position` per centrare il pannello,
  evitando un ritardo di un frame dovuto al sort differito del
  `MarginContainer`.
- **2026-09-06 — Margini della `StyleBoxTexture` calibrati sul budget di
  safe area, non sulla sola geometria dell'asset.** Il medaglione richiede
  un `texture_margin_top`/`content_margin_top` di almeno ~204px (nativi) per
  mostrare il cerchio intero senza tagliarlo: non e' comprimibile senza
  ricadere sull'arte di PS-102. Il margine inferiore invece e' stato
  misurato empiricamente contro lo smoke di safe area con titolo/citazione
  al limite di lunghezza (non lo stress esagerato iniziale, ma un caso
  "lungo il doppio del reale", visto che nessun Boss in produzione usa oggi
  una citazione approvata più lunga del placeholder di `first_boss.tres`):
  a 620px di larghezza pannello, `content_margin_bottom=40`/
  `texture_margin_bottom=48` è il punto che tiene il pannello dentro la
  safe area di riferimento (1240x680) mantenendo comunque margine dal bordo
  decorativo. Valori finali:
  `texture_margin = (70, 208, 70, 48)` (L, T, R, B),
  `content_margin = (74, 208, 74, 40)`.
- **2026-09-06 — Dimensione/offset del medaglione (`PORTRAIT_MEDALLION_SIZE`,
  `PORTRAIT_MEDALLION_CENTER_Y` in `boss_ui.gd`) sono stime da provino, non
  misure pixel-perfette.** Ricavate analizzando il PNG generato (foro
  ellittico ~160x136 nativi, centro nativo (382,137)) e verificate con uno
  screenshot reale (Windows 16:9 e Pixel 9 20:9, baseline ed Evil): il
  ritratto riempie il foro senza margini vuoti né angoli quadrati visibili.
  Restano comunque il candidato più naturale da rifinire nel controllo
  percettivo del proprietario, se la resa dal vivo suggerisse un
  aggiustamento fine.

## Documenti sincronizzati

- [x] `docs/enemies-bosses.md`: non aggiornato. La sezione "Boss Intro:
      identità individuale" (righe 117-138) descrive solo la logica di
      risoluzione ritratto/icona/tinta (contratto PS-051), non toccata da
      questa card; non descrive dimensioni o geometria del pannello, quindi
      non c'è alcun contratto da propagare.

## Note

Non è una card `tipo: art`: è wiring in scena, quindi non è stata delegata a
`game-art-designer` (quella resta la competenza di PS-102).

Il proprietario può invocare manualmente `qa-esplorativo` per un passaggio
esplorativo sulla intro Boss (titoli/citazioni particolarmente lunghi,
sequenza Piccione Malvagio → Evil in run consecutive) che gli smoke GUT
deterministici non coprono, e `direttore-artistico` per confrontare la resa
cablata con i "fratelli visivi" già esistenti negli altri asset UI Boss.

Gli screenshot prodotti per la verifica visiva vivono in
`exports/ui-screenshots/06_boss_intro.png` (16:9) e
`exports/ui-screenshots/pixel9-20x9/06_boss_intro.png` (20:9): la cartella è
ignorata da git (artefatti locali, rigenerabili con
`tools/_capture_ui_screenshots.gd`).
