---
id: PS-010
titolo: Implementa la modalità Difesa Grigliata
tipo: feat
area: gameplay
stato: IDEA
priorita: alta
dipende_da: []
origine: B23
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-010 — Implementa la modalità Difesa Grigliata

## Contesto

Il gioco offre oggi Sopravvivenza. Serve una seconda modalità in cui il Player
difende una griglia con carne, senza duplicare stato della run, targeting o
cleanup e senza contaminare una modalità con l'altra.

## Comportamento atteso

- La selezione personaggio include la scelta fra **Sopravvivenza** (default) e
  **Difesa Grigliata**, sempre in `BOOT`.
- Difesa Grigliata crea al centro del mondo una griglia con salute configurabile
  e HUD dedicato fuori dal playfield.
- I nemici possono scegliere tramite dati se attaccare Player o griglia; il
  Player continua a poterli attirare e uccidere.
- La run termina in `DEFEAT` se il Player o la griglia raggiungono zero HP.
- Boss e progressione riusano i contratti correnti di Sopravvivenza; questa card
  non introduce un secondo scheduler.

## Criteri di accettazione

- [ ] Navigare modalità e profilo non avvia clock, spawn, seed o input gameplay.
- [ ] Back conserva il flusso `welcome → selezione → run` senza creare una run.
- [ ] La griglia nasce nel centro autorevole di `ArenaWorld` con HP configurabili.
- [ ] L'HUD della griglia non copre Player, Boss UI, telegraph o controlli touch.
- [ ] Target Player/griglia è dichiarativo e deterministico per seed.
- [ ] Morte Player o griglia produce una sola `DEFEAT`.
- [ ] Nessuna cura o riparazione implicita viene introdotta.
- [ ] Pausa, focus, Home/lock, cambio personaggio e restart non lasciano stato residuo.
- [ ] Sopravvivenza mantiene comportamento e bilanciamento correnti.

## Ambito

`RunController`, selezione personaggio/modalità, `GameDirector`, targeting
nemico, obiettivo difendibile, HUD e cleanup. Non duplicare clock, seed o
scheduler Boss e non introdurre autoload.

## Verifica

- Smoke: `tests/integration/_grill_defense_mode_smoke.gd` → marker
  `GRILL_DEFENSE_MODE_SMOKE_OK`.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows per entrambe le modalità.
- [ ] Validazione statica APK.
- [ ] Pixel 9: selezione → difesa → joystick tenuto + abilità col secondo dito.
- [ ] Sconfitta separata per morte Player e morte griglia.
- [ ] Controllo percettivo di obiettivo, HUD, aggro e leggibilità nelle orde.

## Decisioni

- **2026-08-30 — Sopravvivenza resta il default.** La nuova modalità è una
  scelta esplicita in `BOOT`, non una variazione casuale della run.
- **2026-08-30 — Un solo RunController e un solo scheduler Boss.** La modalità
  aggiunge obiettivo, target e HUD, non una seconda architettura.
- **2026-08-30 — Nessuna riparazione implicita nella prima versione.** Cura o
  manutenzione della griglia richiederebbero una nuova card.

## Documenti sincronizzati

- [ ] `prd.md`: modalità, condizioni di sconfitta e targeting risultanti.
- [ ] `CLAUDE.md`: solo se cambia un contratto architetturale.
- [ ] Nota di verifica dedicata, se vengono prodotti gate/evidenze.

## Note

Contratto storico: B23 nello
[snapshot archiviato](../../archive/development-plan-through-b54-2026-08-30.md#b23--modalità-difesa-grigliata).
