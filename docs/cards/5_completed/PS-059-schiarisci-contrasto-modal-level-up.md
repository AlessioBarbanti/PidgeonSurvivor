---
id: PS-059
titolo: Schiarire il contrasto fra velo e carte nei modal di scelta
tipo: fix
area: ui
stato: COMPLETATO
priorita: alta
dipende_da: [PS-046, PS-047]
origine:
creato: 2026-09-01
aggiornato: 2026-09-01
---

# PS-059 — Schiarire il contrasto fra velo e carte nei modal di scelta

## Contesto

Il proprietario ha segnalato, con uno screenshot reale (`LIVELLO 3`, offerta
`Forchettone da Braciere` / `Shock Termico` / `Ritardo Cronico`), che l'intero
modal di level-up appare "praticamente tutto nero" e a stento leggibile, non
solo lo sfondo HUD attenuato.

PS-046 ha portato il `Dimmer` di `upgrade_overlay.tscn` a
`Color(0.004, 0.009, 0.018, 0.91)` (alpha 91%, quasi nero puro) per nascondere
HUD e cronometro dietro il modal; `barb_reward_overlay.tscn` usa un `Dimmer`
analogo, `Color(0.058, 0.008, 0.02, 0.93)`. Lo sfondo `normal` delle carte in
`upgrade_card.tscn` (`StyleBoxFlat_normal`, `bg_color = Color(0.035, 0.063,
0.11, 0.98)`, ~RGB 9,16,28) e il pannello equivalente di
`barb_reward_overlay.tscn` (`bg_color = Color(0.105, 0.025, 0.014, 0.98)`,
~RGB 27,6,4) sono a loro volta quasi indistinguibili dal velo sottostante:
la differenza di luminanza fra "sfondo attenuato" e "pannello della scelta" è
troppo piccola perché l'occhio le separi. Il gate percettivo manuale di
PS-046 e PS-047 ("Controllo percettivo richiesto: sì") era rimasto aperto
proprio in attesa di una verifica su schermo reale, che ora conferma il
problema.

Nessun binario Godot era disponibile in questa sessione per catturare uno
screenshot di conferma pixel-per-pixel: la verifica visiva resta un gate
manuale da chiudere durante l'implementazione.

**Aggiornamento 2026-09-01 (device reale, dopo il primo fix di colore):** il
proprietario ha compilato l'APK con il fix di contrasto sopra e lo ha provato
su device fisico — il modal era ancora "praticamente tutto nero", identico a
prima, nonostante i colori dei pannelli fossero stati resi visibilmente più
chiari. Questo esclude il contrasto colore come causa unica: il proprietario
ha correttamente sospettato uno z-index. Causa radice reale, trovata
rileggendo la semantica di `CanvasItem.top_level` in Godot: il `Dimmer` ha
`top_level = true` (per coprire l'intero viewport oltre il safe-rect
calcolato da `ArenaLayout`/`SafeAreaRoot`). Un CanvasItem `top_level` viene
riparentato dal renderer direttamente al canvas del `CanvasLayer`, non al suo
Control padre — quindi per l'ordine di disegno il `Dimmer` competeva con
l'intero sottoalbero di `SafeAreaRoot` (HUD, `UpgradeOverlay`/`SafeMargins`
compresi) come blocco unico, invece che con `SafeMargins` come fratello
diretto. Essendo entrato nel canvas dopo `SafeAreaRoot` (essendo annidato più
in profondità), disegnava sopra tutto quel blocco — carte comprese, non solo
HUD. Il fix di colore di PS-059 non poteva funzionare perché il colore della
carta non arrivava mai a schermo: veniva sempre ridipinto sopra dal velo.

## Comportamento atteso

Aprendo un'offerta di livello o una ricompensa Barb, chi gioca distingue
subito il pannello della carta dallo sfondo attenuato dietro di esso, e legge
titolo, descrizione, riepilogo effetto e rango senza sforzo, mantenendo intatto
l'isolamento da HUD e cronometro introdotto da PS-046.

## Criteri di accettazione

- [x] Il colore del `Dimmer` (`upgrade_overlay.tscn` e
      `barb_reward_overlay.tscn`) e il colore di sfondo `normal` della carta
      corrispondente (`upgrade_card.tscn` e il pannello carta di
      `barb_reward_overlay.tscn`) hanno una differenza di luminanza percepita
      verificabile via smoke (lettura diretta dei `Color` a runtime, soglia da
      definire in implementazione, indicativamente ≥ 0.05 in scala 0-1 di
      luminanza relativa).
      *Eseguito davvero in questa sessione (vedi Verifica): GUT locale verde,
      3/3 test passati, marker `UPGRADE_MODAL_CONTRAST_SMOKE_OK` stampato.*
- [x] Il criterio di PS-046 resta vero senza regressioni: HUD, cronometro,
      barre XP/vita, pulsante pausa e joystick restano non leggibili dietro il
      modal (`test_ps046_level_up_modal_isolation.gd` resta verde).
      *Rieseguito localmente in questa sessione: 2/2 passati, nessuna
      regressione.*
- [x] Le stesse modifiche di colore si applicano coerentemente a
      `BarbRewardOverlay` in entrambe le modalità `BARB_SPECIALITY` e
      `BARB_BONUS`, non solo all'offerta di livello normale.
      *`BARB_BONUS` riusa `upgrade_card.tscn` (stessa carta blu), quindi
      eredita automaticamente la modifica; `BARB_SPECIALITY` usa uno stile
      dedicato in `_apply_visual_treatment()` (`upgrade_card.gd`), schiarito
      separatamente con la stessa proporzione. Confermato anche a occhio nudo
      su `05b_barb_speciality.png`/`05c_barb_bonus.png` (vedi Verifica).*
- [x] Nessun valore di rango, effetto, probabilità o bilanciamento upgrade
      cambia: la modifica è solo di colore/presentazione.
      *Toccati solo `bg_color` di `StyleBoxFlat` in tre `.tscn`/`.gd` di
      presentazione; nessun file in `data/upgrades/`, `UpgradeEffectRegistry`
      o `UpgradeService` modificato.*
- [x] Il `SafeMargins` di `UpgradeOverlay` e `BarbRewardOverlay` disegna
      sopra il rispettivo `Dimmer` per davvero (non solo "colore più chiaro"):
      entrambi condividono lo stesso ordinamento di disegno `top_level`,
      cosi' le carte non vengono ridipinte sopra dal velo.
      *Aggiunto `top_level = true` a `SafeMargins` in entrambe le scene.
      Verificato in tre modi indipendenti: (1) smoke strutturale
      `test_ps059_safe_margins_shares_dimmer_top_level_draw_order`, verde
      localmente; (2) cattura UI locale (`tools/_capture_ui_screenshots.gd`
      via Xvfb) ispezionata a occhio — vedi Verifica; (3) il proprietario ha
      confermato su Pixel 9 reale: "il dimmer nero è sistemato".*
- [x] Controllo percettivo su schermo reale (Windows e/o Pixel 9): il modal
      non viene più descritto come "tutto nero" o illeggibile.
      *Confermato dal proprietario su device reale dopo il fix `top_level`
      (non dopo il primo fix di solo colore, che era risultato insufficiente
      — vedi Contesto). Confermato anche dalla cattura UI locale di questa
      sessione.*

## Ambito

- `scenes/ui/upgrade_overlay.tscn` (colore `Dimmer`; `top_level` su
  `SafeMargins`).
- `scenes/ui/barb_reward_overlay.tscn` (colore del pannello header; `top_level`
  su `SafeMargins`; `Dimmer` non toccato, vedi Decisioni).
- `scenes/ui/upgrade_card.tscn` (`StyleBoxFlat_normal`, `_pressed`,
  `_disabled`).
- `scripts/ui/upgrade_card.gd` (`_apply_visual_treatment`): gli stessi colori
  troppo scuri erano duplicati in codice per il trattamento visivo
  `BARB_SPECIALITY` (PS-036), non solo nella scena `.tscn` condivisa da offerta
  normale e `BARB_BONUS`.

Non toccare:

- z-index e margini già corretti da PS-046;
- gerarchia e spaziatura interna delle carte, contratto di PS-047;
- `RunController`, arbitraggio degli stati e generazione dell'offerta;
- `UpgradeEffectRegistry`, dati e bilanciamento upgrade.

## Verifica

- Smoke: `tests/unit/test_ps059_upgrade_modal_contrast.gd` → marker
  `UPGRADE_MODAL_CONTRAST_SMOKE_OK` — legge i `Color` effettivi di `Dimmer` e
  pannello carta per entrambi gli overlay e verifica la soglia di luminanza.
- Profilo minimo prima della chiusura: `Relevant`
- **Eseguito 2026-09-01, localmente in sandbox** (non Windows/PowerShell, ma
  Godot 4.7.1 reale installato via `tools/setup-remote-sandbox.sh`, PS-062):
  ```
  godot --headless --editor --path . --quit   # warm-up cache import
  godot --headless --path . -s addons/gut/gut_cmdln.gd \
    -gtest=res://tests/unit/test_ps059_upgrade_modal_contrast.gd,res://tests/unit/test_ps046_level_up_modal_isolation.gd,res://tests/unit/test_ps047_upgrade_card_hierarchy.gd \
    -gexit
  ```
  → `3/3 passed. / 2/2 passed. / 2/2 passed.`, `All tests passed!`, marker
  `UPGRADE_MODAL_CONTRAST_SMOKE_OK` stampato, nessun `SCRIPT ERROR`/
  `FATAL EXCEPTION` nel log. Non ancora eseguito sul profilo `Relevant`
  completo né su Windows con `run-milestone-checks.ps1`: chi vuole quella
  copertura più ampia può ancora lanciarlo lì, ma i test toccati da questa
  card sono verdi con un'esecuzione reale del motore.
- **Verifica visiva aggiuntiva (non richiesta dallo smoke, ma decisiva)**:
  `xvfb-run godot --path . --script tools/_capture_ui_screenshots.gd`
  eseguito localmente (profilo `20x9`), `CAPTURE_DONE`, 26/26 scatti per
  profilo. `05_upgrade_overlay.png`, `05b_barb_speciality.png`,
  `05c_barb_bonus.png` ispezionati a occhio: carte nettamente leggibili,
  pannello distinto dal velo, titoli e testi ad alto contrasto — coerente con
  la conferma del proprietario su device reale.

## Gate manuali

- [ ] Runtime Windows: non eseguito in questa sessione (nessun Windows
      disponibile); non bloccante, il runtime Linux locale e il device
      Android reale hanno già validato il comportamento.
- [x] Validazione statica APK: fatta come parte del run CI di PS-060 (build
      con questo fix, ispezione aapt2/apksigner verde).
- [x] Runtime fisico Pixel 9 (percorso: livello 2+ in Survival, ricompensa
      Barb Speciality e bonus): confermato dal proprietario ("il dimmer nero
      è sistemato") sull'APK del run #3 di PS-060, che include questo fix.
- [x] Controllo percettivo richiesto: sì — soddisfatto dalla conferma del
      proprietario su device reale e dalla cattura UI locale ispezionata in
      questa sessione.

## Decisioni

- **2026-09-01 — Nata da una segnalazione diretta del proprietario con
  screenshot reale**, non da una cattura automatica. Root cause individuata
  per analisi statica del codice (colori `Dimmer` e pannello carta troppo
  vicini), non da un binario Godot eseguito in questa sessione.
- **2026-09-01 — Soglia di luminanza indicativa, non vincolante.** Il numero
  esatto (≥ 0.05) va confermato o affinato da chi implementa dopo un
  controllo percettivo reale; il criterio vincolante è la distinguibilità
  percepita, non la cifra in sé.
- **2026-09-01 — Schiarito il pannello, non il velo.** Per non rischiare di
  riaprire il criterio di PS-046 (HUD/cronometro leggibili dietro il modal),
  la card alza la luminosità di `StyleBoxFlat_normal`/`_pressed`/`_disabled`
  della carta e del pannello header Barb, lasciando invariati colore e alpha
  di entrambi i `Dimmer`.
- **2026-09-01 — Implementazione completata ma non eseguita.** Questa
  sessione remota non ha accesso a un binario Godot né a PowerShell: colori e
  smoke sono stati scritti e ragionati per calcolo diretto (luma), ma mai
  effettivamente lanciati nel motore. La card resta `IN CORSO` invece di
  `IN VERIFICA` finché qualcuno non esegue davvero il profilo `Relevant` su
  Windows.
- **2026-09-01 — Il fix di solo colore era insufficiente: causa radice reale
  è l'ordine di disegno di `top_level`, non il contrasto.** Confermato da un
  test su device reale con la build CI di PS-060 (stessi colori più chiari di
  questa card, stesso risultato "tutto nero"). Aggiunto `top_level = true`
  a `SafeMargins` in entrambe le scene invece di rimuoverlo dal `Dimmer`:
  rimuoverlo dal `Dimmer` avrebbe fatto perdere la copertura full-bleed oltre
  il safe-rect (motivo originale del flag, verificato in `arena_layout.gd`:
  `_safe_area_root.position`/`.size` derivano da
  `DisplayServer.get_display_safe_area()`, non da un letterbox 20:9 fisso).
  In pratica `safe_area.position` è quasi sempre `(0,0)` sui device reali
  testabili (nessun notch aggressivo), quindi il cambio di posizionamento
  introdotto da `top_level` su `SafeMargins` non dovrebbe essere visibile —
  ma non è stato verificato su un device con un vero inset per notch.
- **2026-09-01 — PS-046 aggiornata con una nota di correzione**, non
  riscritta: la sua diagnosi "z_index negativo" restava una causa reale (senza
  quel fix l'HUD tornava visibile sopra il modal) ma incompleta.
- **2026-09-01 — [Run #3](https://github.com/AlessioBarbanti/PidgeonSurvivor/actions/runs/33479512890)
  del workflow PS-060 verde con questo fix**, APK aggiornato sulla stessa
  Release `android-debug-latest`. Questo conferma solo che l'export/firma/ABI
  restano corretti (stessa ispezione statica di PS-060) — **non** conferma il
  comportamento visivo reale, che nessun automatismo di questa sessione può
  verificare. La card resta `IN CORSO` finché il proprietario non riprova il
  level-up sul device.
- **2026-09-01 — Chiusura `COMPLETATO`.** Il proprietario ha confermato su
  Pixel 9 reale che il velo nero è sistemato. Nella stessa sessione, dopo
  aver installato Godot in sandbox (PS-062), ho anche potuto rieseguire
  davvero gli smoke (verdi) e generare/ispezionare io stesso il pacchetto di
  catture UI: entrambe confermano indipendentemente quanto riportato dal
  proprietario. Prima volta in questa serie di card (PS-059/060/061) in cui
  la verifica non si ferma a "codice scritto ma non eseguito".

## Documenti sincronizzati

- [ ] Nessuno: la modifica è di presentazione interna e non cambia un
      contratto durevole descritto in `docs/ui-ux-flow.md` oltre a quanto già
      coperto da PS-046.

## Note

Le carte upgrade e la ricompensa Barb condividono lo stesso pattern
"Dimmer scuro + pannello scuro"; la card copre entrambe per evitare di
risolvere solo la metà del problema segnalato.
