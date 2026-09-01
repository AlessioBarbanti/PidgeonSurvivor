---
id: PS-059
titolo: Schiarire il contrasto fra velo e carte nei modal di scelta
tipo: fix
area: ui
stato: IN CORSO
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

- [ ] Il colore del `Dimmer` (`upgrade_overlay.tscn` e
      `barb_reward_overlay.tscn`) e il colore di sfondo `normal` della carta
      corrispondente (`upgrade_card.tscn` e il pannello carta di
      `barb_reward_overlay.tscn`) hanno una differenza di luminanza percepita
      verificabile via smoke (lettura diretta dei `Color` a runtime, soglia da
      definire in implementazione, indicativamente ≥ 0.05 in scala 0-1 di
      luminanza relativa).
      *Implementato e calcolato a mano (luma 0.299R+0.587G+0.114B sui `Color`
      modificati): delta ≈ 0.11 (carta normale/BARB_BONUS su
      `UpgradeOverlay`), ≈ 0.09 (header Barb), ≈ 0.07-0.11 (carta
      `BARB_SPECIALITY` in tutti gli stati). Non eseguito realmente: nessun
      binario Godot in questa sessione, vedi Verifica.*
- [ ] Il criterio di PS-046 resta vero senza regressioni: HUD, cronometro,
      barre XP/vita, pulsante pausa e joystick restano non leggibili dietro il
      modal (`test_ps046_level_up_modal_isolation.gd` resta verde).
      *Non toccato lo z-index né il colore/alpha dei `Dimmer`: solo lo sfondo
      dei pannelli sopra di essi è cambiato, quindi il criterio PS-046 non
      dovrebbe regredire, ma il test non è stato rieseguito in questa
      sessione.*
- [ ] Le stesse modifiche di colore si applicano coerentemente a
      `BarbRewardOverlay` in entrambe le modalità `BARB_SPECIALITY` e
      `BARB_BONUS`, non solo all'offerta di livello normale.
      *`BARB_BONUS` riusa `upgrade_card.tscn` (stessa carta blu), quindi
      eredita automaticamente la modifica; `BARB_SPECIALITY` usa uno stile
      dedicato in `_apply_visual_treatment()` (`upgrade_card.gd`), schiarito
      separatamente con la stessa proporzione.*
- [x] Nessun valore di rango, effetto, probabilità o bilanciamento upgrade
      cambia: la modifica è solo di colore/presentazione.
      *Toccati solo `bg_color` di `StyleBoxFlat` in tre `.tscn`/`.gd` di
      presentazione; nessun file in `data/upgrades/`, `UpgradeEffectRegistry`
      o `UpgradeService` modificato.*
- [ ] Il `SafeMargins` di `UpgradeOverlay` e `BarbRewardOverlay` disegna
      sopra il rispettivo `Dimmer` per davvero (non solo "colore più chiaro"):
      entrambi condividono lo stesso ordinamento di disegno `top_level`,
      cosi' le carte non vengono ridipinte sopra dal velo.
      *Aggiunto `top_level = true` a `SafeMargins` in entrambe le scene,
      cosi' compete nello stesso elenco "piatto" del canvas del `Dimmer`
      invece che nel sottoalbero di `SafeAreaRoot`. Nuovo test
      `test_ps059_safe_margins_shares_dimmer_top_level_draw_order` verifica
      staticamente `top_level` su entrambi i nodi e che `SafeMargins` abbia
      indice maggiore del `Dimmer`. Non eseguito realmente in questa sessione
      (nessun Godot disponibile): resta da confermare con un run CI +
      controllo percettivo reale.*
- [ ] Controllo percettivo su schermo reale (Windows e/o Pixel 9): il modal
      non viene più descritto come "tutto nero" o illeggibile.
      *Non ancora confermato dopo QUESTO secondo fix. Il primo fix (solo
      colore) è stato provato su device reale ed è risultato insufficiente —
      vedi Contesto. Resta gate manuale del proprietario da rifare con la
      nuova build.*

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
- **Non eseguito in questa sessione**: l'ambiente di lavoro remoto non ha un
  binario Godot né PowerShell disponibili, quindi lo smoke è stato scritto ma
  mai lanciato e la cache dell'editor non è stata rinfrescata (serve
  `-RefreshEditor` per generare il file `.gd.uid` dello smoke, come per ogni
  nuovo script). Chi riprende la card deve eseguire, su Windows:
  ```powershell
  .\tools\run-milestone-checks.ps1 -Milestone PS-059 -Profile Focused `
    -FocusedSmoke tests/unit/test_ps059_upgrade_modal_contrast.gd -RefreshEditor
  .\tools\run-milestone-checks.ps1 -Milestone PS-059 -Profile Relevant `
    -FocusedSmoke tests/unit/test_ps059_upgrade_modal_contrast.gd
  ```
  e controllare i log per `SCRIPT ERROR`/`FATAL EXCEPTION` oltre all'exit
  code, prima di spuntare i criteri sopra e passare la card a `IN VERIFICA`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: livello 2+ in Survival, ricompensa
      Barb Speciality e bonus)
- [ ] Controllo percettivo richiesto: sì

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

## Documenti sincronizzati

- [ ] Nessuno: la modifica è di presentazione interna e non cambia un
      contratto durevole descritto in `docs/ui-ux-flow.md` oltre a quanto già
      coperto da PS-046.

## Note

Le carte upgrade e la ricompensa Barb condividono lo stesso pattern
"Dimmer scuro + pannello scuro"; la card copre entrambe per evitare di
risolvere solo la metà del problema segnalato.
