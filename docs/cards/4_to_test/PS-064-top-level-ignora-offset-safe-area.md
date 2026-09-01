---
id: PS-064
titolo: I nodi top_level dei modal ignorano l'offset del safe-rect del display
tipo: fix
area: ui
stato: IN VERIFICA
priorita: alta
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

Un `CanvasItem` `top_level` con ancore `FULL_RECT` non eredita né la
posizione né la dimensione del proprio antenato logico: si ancora
direttamente al rettangolo del **viewport**, ignorando sia l'offset sia il
ridimensionamento che `SafeAreaRoot` applica normalmente
(`_safe_area_root.position/size = safe_area.position/size` in
`movement_slice.gd`).

**Non più latente**: il proprietario ha segnalato guardando una build reale
che le carte di livello non erano centrate verticalmente e che titolo/carte
finivano sopra la fascia riservata all'HUD ("stiamo andando sopra alla safe
area"). Misurato in sandbox con un fixture GUT reale (1280×720,
`edge_inset=20` → `safe_area=(20,20)-(1240,680)`): `SafeMargins` si
ancorava a `(0,0)-(1280,720)` (l'intero viewport) invece che al rettangolo
sicuro `(20,20)-(1240,680)`. La size sbagliata (40px in più fra alto e
basso, distribuiti in modo simmetrico dall'allineamento `CENTER` del
`VBoxContainer`) non spostava percettibilmente il centro nel caso simmetrico,
ma su un vero dispositivo con un inset reale (o semplicemente con l'inset
strutturale `edge_inset` sempre attivo, non solo sui notch) sposta il
contenuto centrato rispetto al rettangolo sbagliato, con l'effetto visibile
segnalato dal proprietario.

**Effetto collaterale già osservato**: i test che verificano "carta fuori
safe area" in `test_ps047_upgrade_card_hierarchy.gd`,
`test_b11_upgrade_overlay.gd` e `test_ps036_barb_reward_visual_identity.gd`
fallivano per questo, riprodotto rimuovendo temporaneamente `top_level` da
`SafeMargins`: il posizionamento tornava corretto, confermando la causa.

## Comportamento atteso

Quando `safe_area` non coincide col viewport intero (offset e/o size
ridotta), titolo e carte dei modal di scelta restano dentro il rettangolo
sicuro vero, non nel viewport intero — mantenendo il `Dimmer` a copertura
piena dello schermo come oggi, e mantenendo le carte centrate verticalmente
nel rettangolo sicuro.

## Soluzione implementata

`UpgradeOverlay`/`BarbRewardOverlay` espongono `apply_safe_area(rect: Rect2)`,
che riposiziona/ridimensiona `SafeMargins` esplicitamente
(`_safe_margins.position/size = rect.position/size`), bypassando le ancore
(rimosse dalla scena: `SafeMargins` non ha più `anchor_right/bottom` o
`grow_horizontal/vertical`, resta `top_level` per l'ordine di disegno sopra
il `Dimmer`).

Due percorsi alimentano `apply_safe_area()`, entrambi necessari:

- **Gioco reale**: `movement_slice.gd._apply_layout()` — che già calcola
  `safe_area` per `_safe_area_root` — la inoltra a entrambi gli overlay
  subito dopo. Copre anche i cambi di sola posizione (senza cambio di size)
  che una notifica di resize non intercetterebbe da sola.
- **Fixture di test isolati** (`test_ps047`/`test_b11`/`test_ps036`, che
  instanziano l'overlay dentro un `Control` "nudo" senza passare da
  `movement_slice`): l'overlay stesso, non essendo `top_level`, eredita già
  correttamente posizione e size dal proprio antenato reale tramite le
  ancore native di Godot. Un self-sync interno (`resized.connect(...)` +
  chiamata in `_ready()`) legge il proprio `get_global_rect()` e lo inoltra
  ad `apply_safe_area()`, senza richiedere alcuna modifica ai tre file di
  test.

## Criteri di accettazione

- [x] Con un `safe_area` simulato non allineato a `(0,0)` e più piccolo del
      viewport, `SafeMargins` (titolo e carte) risulta contenuto nel
      safe-rect simulato, non nel rettangolo pieno del viewport. *Misurato
      in sandbox: `safe_margins rect` combacia esattamente con
      `safe_area_root rect` in tutti i casi provati.*
- [x] Il `Dimmer` continua a coprire l'intero viewport (nessuna regressione
      sul criterio di PS-046/PS-059). *Non toccato: resta `top_level` con
      ancore `FULL_RECT` invariate.*
- [x] `test_b11_upgrade_overlay.gd` torna verde sull'assert "carta fuori
      safe area" (era il file che copriva `UpgradeOverlay`, cioè il modal di
      livello segnalato dal proprietario), senza indebolire la soglia
      (`LAYOUT_TOLERANCE`) né rimuovere il controllo.
- [ ] `test_ps047_upgrade_card_hierarchy.gd` (solo i casi `BARB_SPECIALITY`/
      `BARB_BONUS`) e `test_ps036_barb_reward_visual_identity.gd` restano
      rossi: non per l'offset (corretto), ma per un difetto distinto e
      indipendente — il contenuto di `BarbRewardOverlay` (header con
      ritratto di Barb + carte) non entra più nel rettangolo sicuro corretto
      una volta che questo non è più gonfiato dal bug di offset. Aperta
      **PS-065** per questo, invece di allargare questa card o toccare un
      asset visivo (il ritratto di Barb) senza conferma del proprietario.
- [ ] Nessuna regressione sul comportamento già confermato su device reale
      (Pixel 9): da riconfermare dal proprietario con la prossima build,
      insieme alla card che ha motivato questa (vedi Note).

## Ambito

- `scenes/ui/upgrade_overlay.tscn`, `scenes/ui/barb_reward_overlay.tscn`
  (ancore di `SafeMargins` rimosse, resta `top_level`).
- `scripts/ui/upgrade_overlay.gd`, `scripts/ui/barb_reward_overlay.gd`
  (`apply_safe_area()` + self-sync).
- `scripts/game/movement_slice.gd` (`_apply_layout()` inoltra `safe_area`
  agli overlay).
- `scenes/ui/barb_reward_overlay.tscn`: `separation`/`margin_bottom` di
  `Layout` ridotti (10→6, 16→10) come mitigazione sicura (nessun rischio
  visivo, nessun asset toccato) verso il difetto di PS-065 — non lo risolve
  del tutto, riduce solo lo sconfinamento residuo.

Non toccato:

- i tre file di test citati (nessuna assert modificata, solo il
  comportamento del codice sotto test);
- il criterio "HUD non leggibile dietro il modal" di PS-046/059;
- `ArenaLayout`/`SafeAreaRoot` e il calcolo di `safe_area`;
- la gerarchia interna delle carte (PS-047/063), a parte la rimozione del
  numero di scorciatoia visibile (vedi **PS-066**, motivata dalla stessa
  segnalazione del proprietario ma tracciata separatamente).

## Verifica

- **Eseguito 2026-09-01, localmente in sandbox** (Godot 4.7.1 via
  `tools/setup-remote-sandbox.sh`):
  ```
  godot --headless --path . -s addons/gut/gut_cmdln.gd \
    -gtest=res://tests/unit/test_ps047_upgrade_card_hierarchy.gd,res://tests/unit/test_ps059_upgrade_modal_contrast.gd,res://tests/unit/test_ps046_level_up_modal_isolation.gd,res://tests/unit/test_b11_upgrade_overlay.gd,res://tests/unit/test_ps036_barb_reward_visual_identity.gd,res://tests/unit/test_ps012_barb_specialities.gd \
    -gexit
  ```
  → `test_b11`, `test_ps059`, `test_ps046`, `test_ps012` verdi. `test_ps047`
  e `test_ps036` rossi solo sui casi Barb Reward (vedi PS-065), confermato
  identico anche isolando lo stash di questa card contro il baseline (il
  difetto di contenuto Barb esiste già prima di questa card, semplicemente
  mascherato dal bug di offset che gonfiava lo spazio disponibile).
- Cattura UI reale (`tools/_capture_ui_screenshots.gd` via Xvfb) ispezionata
  a occhio sul profilo `16x9` (1280×720): il modal di livello risulta
  centrato verticalmente, con margine chiaro sotto la fascia HUD, nessun
  numero di scorciatoia visibile sulle carte.

## Gate manuali

- [ ] Runtime Windows: non eseguito in questa sessione.
- [ ] Validazione statica APK: da confermare con un run CI (PS-060) su
      questo commit.
- [ ] Runtime fisico Pixel 9: da riconfermare dal proprietario — la
      segnalazione originale (carte non centrate, sopra la safe area) è
      arrivata da una build su questo device.
- [ ] Controllo percettivo richiesto: sì — il proprietario ha segnalato il
      difetto originale da uno screenshot reale; la correzione va
      riconfermata allo stesso modo.

## Decisioni

- **2026-09-01 — Scoperta durante la verifica di PS-063, non richiesta
  esplicitamente dal proprietario in quella sessione**: aperta come card
  separata invece di allargare PS-059/063, dato che allora sembrava un
  difetto latente (non osservato su device reale).
- **2026-09-01 — Promossa da `media` ad `alta`**: il proprietario ha
  segnalato l'effetto visibile (carte non centrate, sopra la safe area) su
  una build reale, provando che non era latente.
- **2026-09-01 — Push esplicito dall'orchestratore invece di sola
  auto-lettura**: scelto perché `movement_slice.gd` già calcola `safe_area`
  una sola volta per frame e la inoltra esplicitamente a `_safe_area_root`;
  far leggere agli overlay solo il proprio `get_global_rect()` via notifica
  di resize non avrebbe coperto un cambio di sola posizione (safe_area che
  trasla senza cambiare size, es. rotazione con inset differente per lato),
  perché Godot non emette `resized` per un cambio di sola posizione
  dell'antenato. Il self-sync via `resized` resta come rete di sicurezza per
  i fixture di test isolati, che non passano da `movement_slice`.
- **2026-09-01 — BarbRewardOverlay non riparato qui**: il contenuto
  (header + carte) non entra nel rettangolo sicuro corretto a certe
  risoluzioni compatte; la causa è indipendente dall'offset (un problema di
  spazio, non di posizione) e la soluzione plausibile richiede o restringere
  il ritratto di Barb (asset visivo, decisione del proprietario come già
  successo in PS-063 per l'icona) o un'altra scelta di bilanciamento.
  Tracciato in PS-065 invece di deciderlo qui senza conferma.

## Documenti sincronizzati

- [ ] Nessuno finché il gate percettivo del proprietario non conferma la
      correzione su device.

## Note

Priorità alzata ad `alta`: il difetto è reale e osservato su build reale dal
proprietario (non più solo teorico). PS-065 (BarbRewardOverlay) e PS-066
(rimozione numeri di scorciatoia dalle carte) nascono dalla stessa
segnalazione ma restano card indipendenti perché toccano superfici diverse
del problema.
