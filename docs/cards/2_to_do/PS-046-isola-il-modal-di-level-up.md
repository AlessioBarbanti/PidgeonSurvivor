---
id: PS-046
titolo: Isolare il modal di level-up da HUD e cronometro
tipo: ux
area: ui
stato: PRONTO
priorita: alta
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-08-31
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

- [ ] In `LEVEL_UP` e `BARB_REWARD` barre XP e vita, cronometro, pausa,
      joystick e pulsante abilità non sono leggibili sopra il contenuto del
      modal.
- [ ] Titolo, sottotitolo e carte occupano uno spazio riservato interno al
      modal e non intersecano il rettangolo usato normalmente dal cronometro.
- [ ] Il velo copre in modo uniforme tutto il playfield utile anche in 20:9,
      senza una fascia laterale con intensità diversa.
- [ ] Alla chiusura, HUD, joystick e pulsante abilità tornano con gli stessi
      valori, visibilità e stato di ricarica precedenti all'apertura.
- [ ] Il ripristino avviene anche su restart, sconfitta e cambio personaggio
      durante un'offerta.
- [ ] Pausa e schermata finale conservano il comportamento attuale e non
      vengono assimilate ai modal di scelta.
- [ ] Il lock anti-tap di `SELECTION_LOCK_SECONDS` resta invariato.
- [ ] Il `RunController` resta l'unica autorità sugli stati: HUD e overlay
      reagiscono allo stato, non lo decidono.

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

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: level-up normale, ricompensa Speciality e bonus
      Barb, poi ritorno alla run
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-08-31 — Ambito limitato ai modal di scelta.** Le nuove catture
  dimostrano che pausa e conferma cambio personaggio sono già coerenti; non
  vanno alterate per uniformità teorica.
- **2026-08-31 — Stato reversibile, implementazione libera.** La card richiede
  isolamento e ripristino esatto, non prescrive se ottenerli con visibilità,
  modulazione o un livello di copertura dedicato.

## Documenti sincronizzati

- [ ] `docs/ui-ux-flow.md`: comportamento dell'HUD durante `LEVEL_UP` e
      `BARB_REWARD`.

## Note

La resa delle carte resta separata in PS-047: prima si stabilizza il modal,
poi si compatta la gerarchia interna.
