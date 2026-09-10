---
id: PS-154
titolo: Correggi la cornice del roster nel selettore personaggi e desatura i non selezionati
tipo: fix
area: ui
stato: IN CORSO
priorita: media
dipende_da: []
origine:
creato: 2026-09-10
aggiornato: 2026-09-11
---

# PS-154 — Correggi la cornice del roster nel selettore personaggi e desatura i non selezionati

## Contesto

Nella fascia roster del selettore personaggi (`CharacterSelectOverlay`), la
card del personaggio selezionato usa una `StyleBoxTexture` ritagliata da
`assets/art/ui/pause/pause_panel_frame.png` con `texture_margin` fissato a
`22` (`_make_selected_card_style()`). Il motivo dorato reale dentro quel
file non parte dall'angolo (0,0) ma da circa x:12,y:13 ed è pieno solo fino
a x:55,y:55 (stessa geometria già scoperta durante PS-139/PS-152): un
margine di `22` cattura quindi solo un piccolo triangolo del motivo,
mostrando una cornice visibilmente troncata sul personaggio selezionato —
segnalato dal proprietario confrontandola con l'area piena occupata dai
vicini. I personaggi non selezionati oggi non hanno alcuna cornice-asset,
solo uno `StyleBoxFlat` piatto (`_make_card_style()`), e un'attenuazione
`modulate` grigio-azzurra (`ROSTER_PREVIEW_MODULATE`) più vicina a un dimming
che a una vera desaturazione.

Confrontato con il proprietario: la cornice-asset (corretta) va estesa a
tutti i personaggi del roster, selezionato compreso, lasciando che la
gerarchia visiva selezionato/non-selezionato sia comunicata da una
desaturazione reale e marcata (quasi bianco e nero) sui non selezionati,
non dalla sola presenza/assenza della cornice.

## Comportamento atteso

Ogni personaggio nella fascia roster (selezionato e non) mostra la stessa
cornice dorata a rivetti, dimensionata correttamente rispetto alla propria
card (motivo completo, non troncato). Il personaggio selezionato appare a
colori pieni; tutti gli altri appaiono fortemente desaturati (quasi
scala di grigi), rendendo il selezionato immediatamente riconoscibile senza
bisogno di guardare quale card è più grande.

## Criteri di accettazione

- [x] Il `texture_margin` di `_make_roster_card_style()` (rinominata da
      `_make_selected_card_style()`) cattura l'intero motivo dorato del
      corner di `pause_panel_frame.png` (margini coerenti con quelli già in
      uso in `pause_overlay.tscn`: `56` orizzontale, `52` verticale), non più
      `22`.
- [x] Tutte le card del roster (selezionata e non) usano la stessa
      `StyleBoxTexture` basata su `pause_panel_frame.png`, ridimensionata in
      proporzione alla dimensione reale della card via il comportamento
      nativo di Godot (compressione proporzionale dei margini quando il
      riquadro è più stretto della somma dei due margini): nessuno
      `StyleBoxFlat` piatto residuo su nessuna card del roster — verificato
      dallo smoke dedicato e dagli screenshot reali.
- [x] I personaggi non selezionati sono desaturati con un effetto reale
      (shader dedicato `assets/shaders/desaturate.gdshader`, non un semplice
      `modulate` grigio-azzurro): saturazione `0.12` (quasi scala di grigi).
- [x] Il personaggio selezionato resta a saturazione piena (`1.0`).
- [x] La transizione fra un personaggio e l'altro (navigazione carosello)
      anima anche la desaturazione con la stessa durata delle altre
      proprietà già animate (`tween_method` sullo `shader_parameter`,
      `TRANSITION_DURATION` come posizione/dimensione/opacità).
- [x] Nessuna regressione sul resto del selettore: frecce Precedente/
      Successivo, CTA "GIOCA CON `<Nome>`", focus da tastiera/gamepad,
      layout busto/identità/card Passiva-Abilità — Relevant 34/34, Full
      140/140.
- [x] (Emerso durante l'implementazione, segnalato dal proprietario sugli
      screenshot reali) Il bordo inferiore delle card resta allineato fra
      selezionata e vicine: l'inset verticale del roster (`ROSTER_PREVIEW_INSET.y`)
      centrava le card preview (più basse) e quella selezionata (più alta)
      sullo stesso asse, facendola sporgere 7px sia sopra che sotto le
      vicine — invisibile prima con un bordo piatto sottile, evidente ora
      che tutte le card hanno la cornice-asset. Rimosso l'inset verticale:
      resta solo quello orizzontale.
- [x] (Emerso durante l'implementazione, stesso motivo) Il ritratto resta
      contenuto dentro l'anello della cornice, non sovrapposto agli angoli
      dorati: `content_margin` della `StyleBoxTexture` e il padding
      dell'icona (`ROSTER_SELECTED_ICON_PADDING`/`ROSTER_PREVIEW_ICON_PADDING`)
      erano tarati per il vecchio bordo piatto (6/16/22px) e lasciavano
      l'icona quasi a filo del bordo fisico, sopra gli angoli molto più
      grandi della cornice corretta (56/52). Aumentati rispettivamente a
      20px e 48/54px.

## Ambito

- `scripts/ui/character_select_overlay.gd`: `_make_roster_card_style()`
  (ex `_make_selected_card_style()`, margini e content_margin),
  `_build_card_styles()`/`_apply_card_role()` (stile unico per selezionato e
  preview), `_layout_cards()` (assegnazione/tween della saturazione,
  rimosso l'inset verticale), `_rebuild_buttons()` (materiale shader per
  bottone), `ROSTER_SELECTED_ICON_PADDING`/`ROSTER_PREVIEW_ICON_PADDING`
  (contenimento del ritratto).
- Nuovo `assets/shaders/desaturate.gdshader` (shader generico, riusabile:
  non è un asset grafico/audio, non richiede riga in `ASSET-MANIFEST.md`).
- Nuovo `tests/unit/test_ps154_roster_frame_and_saturation.gd`.
- `tools/milestone-test-map.json`.

Non toccare:

- `assets/art/ui/pause/pause_panel_frame.png` e il suo uso altrove (pausa,
  tutorial, terminale, boss intro, CTA "GIOCA CON"): restano invariati,
  stesso file, solo il ritaglio nel roster cambia margine;
- Layout busto/identità/card Passiva-Abilità, frecce Precedente/Successivo,
  CTA dominante: non oggetto di questa card;
- `ROSTER_HEADSHOT_REGION` e la logica di ritaglio del volto (PS-069).

## Verifica

- Smoke: `tests/unit/test_b18w_character_select_refinement.gd` (verifica già
  che la card centrale usi `StyleBoxTexture` su `pause_panel_frame.png`:
  resta verde, il file non cambia) e il nuovo
  `tests/unit/test_ps154_roster_frame_and_saturation.gd` → marker
  `PS154_ROSTER_FRAME_AND_SATURATION_SMOKE_OK`, verifica che (a) ogni card
  visibile del roster usi `StyleBoxTexture` su `pause_panel_frame.png` con
  margine `>=56/52`, (b) ogni bottone abbia uno `ShaderMaterial` di
  desaturazione, il selezionato a saturazione `1.0` e gli altri `<=0.2`,
  (c) dopo la navigazione la transizione si completi senza Tween residui e
  il nuovo/vecchio selezionato scambino saturazione.
- Focused (`-RefreshEditor`): 2/2 verdi (42 asserzioni), nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Relevant: 1/1 focused, 33/33 regressioni, 34/34 step, nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Full: 138/138 regressioni, toolchain PASS, 140/140 step, nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Screenshot reali rigenerati (`exports/ui-screenshots/03_character_select.png`
  e varianti `03b_character_*`, 16:9 e Pixel 9 20:9): cornice intera su ogni
  card, bordi inferiori allineati, ritratto contenuto nell'anello dorato,
  desaturazione marcata sui non selezionati.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: selettore personaggi, navigazione
      del roster)
- [ ] Controllo percettivo richiesto: sì — ispezionati gli screenshot reali
      in questa sessione (cornice completa, allineamento, contenimento del
      ritratto, desaturazione); lasciato aperto per una conferma diretta del
      proprietario, non un'auto-validazione.

## Decisioni

- **2026-09-10 — Causa radice condivisa con PS-139/PS-152.** Stessa
  geometria del motivo dorato di `pause_panel_frame.png` già mappata
  durante quelle card (offset x:12,y:13, pieno fino a x:55,y:55): un
  margine troppo stretto tronca il motivo invece di scalarlo. Qui il
  margine va aumentato (non serve un nuovo asset dedicato come in PS-152,
  perché il nine-slice di Godot scala proporzionalmente i margini quando il
  riquadro è più piccolo della somma dei due, invece di troncare la sorgente
  — a differenza del crop ad angoli indipendenti tentato in PS-139).
- **2026-09-10 — Scelta del proprietario: cornice per tutti, gerarchia via
  desaturazione** (non cornice solo sul selezionato). Richiede un secondo
  cambiamento (desaturazione reale via shader, non solo `modulate`) per
  mantenere leggibile la differenza selezionato/non-selezionato senza più
  affidarla alla sola presenza della cornice.
- **2026-09-10 — Desaturazione forte (quasi B/N), non moderata.** Scelta
  esplicita del proprietario fra le due opzioni proposte.
- **2026-09-11 — Disallineamento verticale segnalato dal proprietario su
  screenshot reale (due linee guida, blu da spostare sulla rossa).**
  Diagnosticato: `ROSTER_PREVIEW_INSET.y = 14` centrava le card preview (più
  basse) e quella selezionata (più alta) sullo stesso asse verticale,
  facendo sporgere quella selezionata di 7px sia sopra che sotto le vicine.
  Con un bordo piatto sottile il disallineamento non si notava; con la
  cornice-asset ora su tutte le card è diventato visibile. Rimosso l'inset
  verticale (`Vector2(10.0, 0.0)`, prima `Vector2(10.0, 14.0)`): tutte le
  card condividono ora la stessa altezza e lo stesso asse, l'unica
  differenza dimensionale residua è la larghezza.
- **2026-09-11 — Prima di correggere il contenimento del ritratto, chiesto
  al proprietario se il problema fosse il motivo d'angolo ("queste
  gemme") o l'assenza di cornice sui non selezionati** (due letture
  possibili del feedback "mi piacevano di più i bordi di prima"). Risposta:
  il ritaglio va bene, ma dev'essere più grande e contenere il ritratto —
  il problema non era il motivo ma il fatto che il ritratto (dimensionato
  per il vecchio bordo piatto) si sovrapponeva agli angoli dorati molto più
  grandi della cornice corretta, coprendoli parzialmente invece di lasciarli
  visibili intorno a sé. Aumentati `content_margin` della `StyleBoxTexture`
  (6→20px) e i padding icona `ROSTER_SELECTED_ICON_PADDING`/
  `ROSTER_PREVIEW_ICON_PADDING` (16/22→48/54px) cosi' il ritratto rende
  visibile l'anello della cornice invece di sovrapporlo.
- **2026-09-11 — Riaperta dopo revisione screenshot: gli angoli a margine
  pieno (56/52) risultavano sovradimensionati rispetto al piccolo slot
  roster.** Il proprietario ha scelto esplicitamente un ritaglio nine-slice
  più piccolo dello stesso motivo (non un derivato dedicato): `texture_margin`
  di `_make_roster_card_style()` ridotto a `32`/`28`. `content_margin` e
  `ROSTER_SELECTED_ICON_PADDING`/`ROSTER_PREVIEW_ICON_PADDING` scalati di
  conseguenza (20→4, 48/54→28/32) per tenere il ritratto contenuto nel
  ritaglio più piccolo.
- **2026-09-11 — Ulteriore richiesta: assottigliare lo spessore visibile
  della cornice a ~1/3, mantenendo invariate le dimensioni x/y dell'angolo.**
  Il `texture_margin` (32/28, la dimensione strutturale del riquadro
  d'angolo) non è la leva giusta per questo: è il padding dell'icona
  (`ROSTER_SELECTED_ICON_PADDING`/`ROSTER_PREVIEW_ICON_PADDING`, che
  controlla quanto il ritratto si estende verso il bordo) a determinare
  quanto spessore di cornice resta visibile — un padding minore fa crescere
  il ritratto, coprendo più cornice. Ridotti a `9`/`11` (da `28`/`32`) e
  `content_margin` a `4` (da `20`) perché non diventi lui il vincolo
  dominante. Verificato via screenshot reali (confronto prima/dopo
  ravvicinato sulla card selezionata): spessore visibile ridotto, angoli
  laterali invariati. **Il proprietario ha chiesto di lasciare la card
  `IN CORSO` per ora e di non rieseguire la verifica automatica in questa
  sessione**: Focused/Relevant/Full precedenti (righe sopra) restano relativi
  allo stato *prima* di queste due ultime modifiche, non ancora
  ri-verificato.
- **2026-09-11 — Nota, senza chiudere la card:** il profilo `Full` rieseguito
  per [PS-155](../4_to_test/PS-155-correggi-altezza-e-centratura-testo-cta-arancione.md)
  (139/139 regressioni, nessun `SCRIPT ERROR`/`FATAL EXCEPTION`) copre anche
  `scripts/ui/character_select_overlay.gd` nel suo stato attuale (margine
  32/28, spessore cornice ridotto) e non ha rilevato regressioni. Lo stato
  resta `IN CORSO` come richiesto dal proprietario: e' solo evidenza di
  non-regressione raccolta di passaggio, non una chiusura della card.

## Documenti sincronizzati

- [x] `docs/visual-audio-identity.md`: aggiunte due regole riusabili — il
      `texture_margin` corretto per il nine-slice di `pause_panel_frame.png`
      su box piccoli (mai ridotto per "adattarlo", Godot scala da solo) e il
      pattern di desaturazione via `ShaderMaterial` per nodo per comunicare
      gerarchia quando più elementi condividono la stessa cornice-asset.

## Note

Nessuna consultazione del game-art-designer necessaria: riuso di un asset
esistente (stesso file, solo margine corretto) più un effetto puramente
tecnico (shader di desaturazione), nessuna nuova arte da generare.
