---
id: PS-064
titolo: I nodi top_level dei modal ignorano l'offset del safe-rect del display
tipo: fix
area: ui
stato: PRONTO
priorita: media
dipende_da: [PS-059]
origine:
creato: 2026-09-01
aggiornato: 2026-09-01
---

# PS-064 — I nodi `top_level` dei modal ignorano l'offset del safe-rect del display

## Contesto

PS-059 ha reso `SafeMargins` (titolo + carte) `top_level = true` in
`upgrade_overlay.tscn` e `barb_reward_overlay.tscn`, necessario perché
disegnasse sopra il `Dimmer` invece che sotto (altrimenti il modal torna
"tutto nero", il bug originale di PS-059).

Un `CanvasItem` `top_level` viene però riparentato dal renderer direttamente
al canvas del `CanvasLayer`, **ignorando qualunque offset di posizione dei
suoi antenati**. `SafeAreaRoot` applica normalmente un offset reale
(`_safe_area_root.position = safe_area.position` in
`scripts/game/movement_slice.gd`) per tenere i contenuti dentro il safe-rect
del display quando `ArenaLayout.respect_display_safe_area` (default `true`)
rileva un vero notch/cutout. Con `SafeMargins` `top_level`, quell'offset
smette di valere per titolo e carte: finirebbero posizionati come se il
cutout non esistesse, potenzialmente sotto di esso — mentre il `Dimmer`
(anch'esso `top_level`, per design) continuerebbe correttamente a coprire
tutto lo schermo.

Sui device reali testati finora (Pixel 9) `safe_area.position` risulta
`(0,0)`: il bug non si è ancora manifestato visivamente. Resta latente per
qualunque device Android in landscape con un cutout reale.

**Effetto collaterale già osservato**: i test che verificano "carta fuori
safe area" in `test_ps047_upgrade_card_hierarchy.gd`,
`test_b11_upgrade_overlay.gd` e `test_ps036_barb_reward_visual_identity.gd`
falliscono ora in isolamento, perché il loro fixture simula un safe-rect
ristretto posizionando un `Control` "nudo" (senza un vero `CanvasLayer`) —
esattamente il pattern che `top_level` ignora. Riprodotto rimuovendo
temporaneamente `top_level` da `SafeMargins`: il posizionamento torna
corretto rispetto al rect simulato, confermando la causa.

## Comportamento atteso

Quando `safe_area.position` non è `(0,0)` (device con cutout reale), titolo
e carte dei modal di scelta restano dentro il safe-rect vero, non sotto il
cutout — mantenendo il `Dimmer` a copertura piena dello schermo come oggi.

## Criteri di accettazione

- [ ] Con un `safe_area` simulato non allineato a `(0,0)`, `SafeMargins`
      (titolo e carte) risulta contenuto nel safe-rect simulato, non nel
      rettangolo pieno del viewport.
- [ ] Il `Dimmer` continua a coprire l'intero viewport (nessuna regressione
      sul criterio di PS-046/PS-059: HUD non leggibile dietro il modal).
- [ ] `test_ps047_upgrade_card_hierarchy.gd`, `test_b11_upgrade_overlay.gd`
      e `test_ps036_barb_reward_visual_identity.gd` tornano verdi sulle
      assert "carta fuori safe area", senza indebolire la soglia
      (`LAYOUT_TOLERANCE`) né rimuovere il controllo.
- [ ] Nessuna regressione sul comportamento già confermato su device reale
      (Pixel 9, `safe_area.position == (0,0)`): il modal resta identico a
      come l'ha validato il proprietario dopo PS-059/063.

## Ambito

- `scenes/ui/upgrade_overlay.tscn`, `scenes/ui/barb_reward_overlay.tscn`
  (posizionamento di `Dimmer`/`SafeMargins`).
- Eventuale logica di posizionamento in `scripts/ui/upgrade_overlay.gd` /
  `scripts/ui/barb_reward_overlay.gd`, se la soluzione richiede calcolare un
  offset a runtime invece di affidarsi solo alle ancore statiche.
- I tre file di test citati sopra, solo se la loro assert va adattata al
  meccanismo scelto (non per abbassarne la soglia).

Non toccare:

- il criterio "HUD non leggibile dietro il modal" di PS-046/059;
- `ArenaLayout`/`SafeAreaRoot` e il calcolo di `safe_area` (già corretto,
  origine del vincolo da rispettare, non il bug);
- la gerarchia interna delle carte (PS-047/063).

## Verifica

- Smoke: estendere o affiancare
  `tests/unit/test_ps046_level_up_modal_isolation.gd` (o un nuovo test
  dedicato) con un caso che imposta un `safe_area` non allineato a `(0,0)`
  e verifica che `SafeMargins` resti dentro quel rect mentre `Dimmer` copre
  comunque l'intero viewport.
- Profilo minimo prima della chiusura: `Relevant`, includendo
  `test_ps047_upgrade_card_hierarchy.gd`, `test_b11_upgrade_overlay.gd`,
  `test_ps036_barb_reward_visual_identity.gd`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: non riproduce il caso (nessun cutout), quindi
      non sufficiente da solo a chiudere questa card.
- [ ] Controllo percettivo richiesto: sì, idealmente su un device con un
      cutout reale in landscape se disponibile; altrimenti solo verifica
      automatica con `safe_area` simulato.

## Decisioni

- **2026-09-01 — Scoperta durante la verifica di PS-063, non richiesta**
  esplicitamente dal proprietario in questa sessione: aperta come card
  separata invece di allargare PS-059/063, dato che è un difetto latente
  (non ancora osservato su device reale) e non blocca il lavoro già
  confermato.
- **2026-09-01 — Direzione tecnica non ancora scelta.** Due strade
  plausibili, nessuna implementata: (a) calcolare via script un offset
  negativo dinamico su `Dimmer`/`SafeMargins` pari alla differenza fra la
  loro posizione globale e `(0,0)`, così restano `top_level` per l'ordine
  di disegno ma si riposizionano manualmente rispetto al vero safe-rect;
  (b) ripensare come i modal si agganciano al `CanvasLayer` (es. spostare
  `Dimmer` a un livello dedicato sopra l'intero `SafeAreaRoot`, invece di
  annidarlo dentro l'overlay). Nessuna delle due è stata validata.

## Documenti sincronizzati

- [ ] Nessuno finché non è chiaro il contratto risultante.

## Note

Priorità `media`, non `alta`: il difetto è reale ma non osservato su
hardware reale finora testato (Pixel 9, `safe_area.position == (0,0)`).
Non blocca la chiusura di PS-059/063.
