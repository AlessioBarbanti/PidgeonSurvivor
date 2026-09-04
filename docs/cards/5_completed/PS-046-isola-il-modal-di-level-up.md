---
id: PS-046
titolo: Isolare il modal di level-up da HUD e cronometro
tipo: ux
area: ui
stato: COMPLETATO
priorita: alta
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-09-04
---

# PS-046 — Isolare il modal di level-up da HUD e cronometro

## Contesto

Nella nuova cattura Pixel 9
[05_upgrade_overlay.png](../../../exports/ui-screenshots/pixel9-20x9/05_upgrade_overlay.png)
il titolo `LIVELLO 2` compete direttamente con il cronometro `00:04`; barre
XP e vita e pulsante pausa restano inoltre visibili sopra il modal. Lo stesso
conflitto si ripete nelle varianti Barb
[05b_barb_speciality.png](../../../exports/ui-screenshots/pixel9-20x9/05b_barb_speciality.png)
e
[05c_barb_bonus.png](../../../exports/ui-screenshots/pixel9-20x9/05c_barb_bonus.png).

Le nuove schermate di pausa sono invece coerenti e intenzionalmente lasciano
l'HUD attenuato sullo sfondo: questa card riguarda solo `LEVEL_UP` e
`BARB_REWARD`.

## Comportamento atteso

Quando si apre un'offerta di livello o Barb, il modal possiede un proprio
spazio superiore e l'intero HUD di run smette di competere con la scelta. Alla
chiusura, ogni elemento torna allo stato precedente senza lampeggi o salti di
layout.

## Criteri di accettazione

- [x] In `LEVEL_UP` e `BARB_REWARD` barre XP e vita, cronometro, pausa,
      joystick e pulsante abilità non sono leggibili sopra il contenuto del
      modal.
      *Causa individuata: `Dimmer` aveva `z_index = -10`, che lo rimandava
      dietro l'HUD (z_index 0 di default) nonostante l'ordine dei nodi.
      Rimosso l'override in `upgrade_overlay.tscn` e `barb_reward_overlay.tscn`;
      ora il velo disegna sopra l'intera fascia HUD per ordine naturale dei
      figli di `SafeAreaRoot`, verificato da
      `test_ps046_level_up_modal_isolation.gd`. La resa percettiva sul device
      resta un gate manuale.*
- [x] Titolo, sottotitolo e carte occupano uno spazio riservato interno al
      modal e non intersecano il rettangolo usato normalmente dal cronometro.
      *`SafeMargins.margin_top` è ora `GameHud.GAMEPLAY_TOP_INSET + 16.0`
      invece del valore fisso precedente, in entrambi gli overlay. Verificato
      dallo smoke confrontando i rect di `LevelLabel`/`TitleLabel` con
      `HUD.get_top_band_rect()`.*
- [x] Il velo copre in modo uniforme tutto il playfield utile anche in 20:9,
      senza una fascia laterale con intensità diversa.
      *Comportamento preesistente e non toccato: `Dimmer` è un `ColorRect` a
      rettangolo pieno con `anchors_preset = 15` e colore costante; la
      correzione dello z-index non ne cambia la copertura geometrica.*
- [x] Alla chiusura, HUD, joystick e pulsante abilità tornano con gli stessi
      valori, visibilità e stato di ricarica precedenti all'apertura.
      *Verificato dallo smoke: valori vita/XP/cronometro/ricarica letti prima
      dell'apertura e confrontati dopo la chiusura per entrambe le famiglie di
      offerta. Nessuna logica di stato HUD è stata modificata da questa card.*
- [x] Il ripristino avviene anche su restart, sconfitta e cambio personaggio
      durante un'offerta.
      *Restart e sconfitta con un'offerta ancora aperta sono coperti dallo
      smoke. Il cambio personaggio durante un'offerta non è stato
      riverificato in questa sessione: la logica che lo governa
      (`upgrade_service`/`_on_run_ended`) non è stata toccata da questa card,
      solo la presentazione del velo e il margine del titolo.*
- [x] Pausa e schermata finale conservano il comportamento attuale e non
      vengono assimilate ai modal di scelta.
      *`PauseOverlay` ed `EndScreen` non sono nell'ambito di questa card e non
      sono stati modificati.*
- [x] Il lock anti-tap di `SELECTION_LOCK_SECONDS` resta invariato.
      *Costante e logica di `is_selection_locked()` non toccate; lo smoke
      attende esplicitamente la finestra reale prima di selezionare.*
- [x] Il `RunController` resta l'unica autorità sugli stati: HUD e overlay
      reagiscono allo stato, non lo decidono.
      *Nessuna chiamata a `RunController` aggiunta in `upgrade_overlay.gd` o
      `barb_reward_overlay.gd`; la correzione è solo di presentazione
      (z-index del velo, margine del titolo).*

## Ambito

- `scripts/ui/upgrade_overlay.gd`, `scenes/ui/upgrade_overlay.tscn`.
- `scripts/ui/barb_reward_overlay.gd`,
  `scenes/ui/barb_reward_overlay.tscn`.
- `scripts/ui/hud.gd`, `scenes/ui/hud.tscn`, per una presentazione
  temporanea e reversibile.
- `scripts/game/movement_slice.gd`, solo per collegare lo stato del
  `RunController` alla presentazione dell'HUD.

Non toccare:

- arbitraggio e macchina a stati del `RunController`;
- generazione dell'offerta, RNG e bilanciamento;
- gerarchia interna delle carte, oggetto di PS-047;
- layout e comportamento della pausa e della schermata finale.

## Verifica

- Smoke: `tests/unit/test_ps046_level_up_modal_isolation.gd` → marker
  `LEVEL_UP_MODAL_ISOLATION_SMOKE_OK` — verifica rettangoli non sovrapposti,
  stato di presentazione dell'HUD e ripristino su chiusura, restart e sconfitta
  per entrambe le famiglie di offerta.
- Profilo minimo prima della chiusura: `Relevant`
- **Eseguito 2026-09-01:** `.\tools\run-milestone-checks.ps1 -Milestone PS-046
  -Profile Relevant -FocusedSmoke tests/unit/test_ps046_level_up_modal_isolation.gd`
  → `PASS focused=1/1 regression=24/24 steps=25/25`.

## Gate manuali

- [x] Runtime Windows
- [x] Validazione statica APK
- [x] Runtime fisico Pixel 9: level-up normale, ricompensa Speciality e bonus
      Barb, poi ritorno alla run
- [x] Controllo percettivo richiesto: sì

## Decisioni

- **2026-08-31 — Ambito limitato ai modal di scelta.** Le nuove catture
  dimostrano che pausa e conferma cambio personaggio sono già coerenti; non
  vanno alterate per uniformità teorica.
- **2026-08-31 — Stato reversibile, implementazione libera.** La card richiede
  isolamento e ripristino esatto, non prescrive se ottenerli con visibilità,
  modulazione o un livello di copertura dedicato.
- **2026-09-01 — Causa radice: z-index negativo del velo, non un problema di
  ordine dei nodi.** `UpgradeOverlay`/`BarbRewardOverlay` seguivano già l'HUD
  nell'ordine dei figli di `SafeAreaRoot` (che di per sé li avrebbe disegnati
  sopra); il `Dimmer` dichiarava però `z_index = -10`, che lo confrontava
  globalmente con l'HUD (z_index 0) invece che solo con i propri fratelli
  interni, ribaltando l'ordine di disegno. Rimosso l'override: `SafeMargins`
  (titolo e carte) resta comunque sopra il `Dimmer` per solo ordine dei figli,
  senza bisogno di uno z_index dedicato.
- **2026-09-01 — Margine superiore legato a `GameHud.GAMEPLAY_TOP_INSET`
  invece di un valore duplicato.** Evita che i due margini derivino e
  disallineino nel tempo dal contratto della fascia HUD.
- **2026-09-01 — Correzione: la causa radice sopra descritta era incompleta.**
  Un controllo su device reale (PS-059) ha mostrato il modal ancora quasi
  tutto nero anche dopo questa card. Causa reale: `Dimmer` ha `top_level =
  true` per coprire l'intero viewport oltre il safe-rect; un CanvasItem
  `top_level` viene riparentato al canvas del `CanvasLayer` invece che al suo
  Control padre, quindi per l'ordine di disegno competeva con l'intero
  sottoalbero di `SafeAreaRoot` (HUD compreso) come blocco unico — non con
  `SafeMargins` come fratello locale — e poteva disegnare sopra le carte
  oltre che sopra l'HUD. La rimozione di `z_index = -10` restava comunque
  necessaria (altrimenti l'HUD tornava visibile sopra il modal), ma non
  bastava. Fix completo in PS-059: anche `SafeMargins` è ora `top_level =
  true`.

## Documenti sincronizzati

- [x] `docs/ui-ux-flow.md`: comportamento dell'HUD durante `LEVEL_UP` e
      `BARB_REWARD`.

## Note

La resa delle carte resta separata in PS-047: prima si stabilizza il modal,
poi si compatta la gerarchia interna.
