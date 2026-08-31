---
id: PS-045
titolo: Riequilibrare composizione e leggibilità dell'arena 20:9
tipo: ux
area: arte
stato: PRONTO
priorita: alta
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-045 — Riequilibrare composizione e leggibilità dell'arena 20:9

## Contesto

Le nuove catture Pixel 9
[04_gameplay_hud.png](../../../exports/ui-screenshots/pixel9-20x9/04_gameplay_hud.png)
e
[04b_gameplay_pressure.png](../../../exports/ui-screenshots/pixel9-20x9/04b_gameplay_pressure.png)
mostrano che attacchi alleati e ostili sono già separati cromaticamente. Il
problema principale è la composizione sul formato 20:9: personaggio e nemici
restano piccoli, ampie zone dell'arena sono vuote e i prop ripetuti formano una
disposizione regolare da test room.

Camino, tavolo, panca, stendino e lavatoio esistono già in
`assets/art/arena/generated/`. La card deve usarli meglio, non produrne altri.

## Comportamento atteso

La run usa in modo equilibrato il playfield utile senza perdere spazio di
manovra. Il giocatore individua subito personaggio, minacce, proiettili e
pickup anche in pressione; i prop costruiscono una piazza da grigliata
irregolare e vissuta, senza griglie, coppie specchiate o grandi fasce
unilateralmente inutilizzate.

## Criteri di accettazione

- [ ] Su Pixel 9 20:9 personaggio, nemici, proiettili e pickup restano
      distinguibili alla scala di gioco reale, senza affidarsi a crop o zoom
      della cattura.
- [ ] La composizione usa in modo bilanciato la larghezza del playfield a
      sinistra e a destra del giocatore; non resta una fascia laterale vuota
      prodotta dal layout della scena.
- [ ] I prop non formano righe regolari, coppie specchiate o ripetizioni
      equidistanti: sono raccolti in gruppi irregolari usando almeno tre
      famiglie di oggetti già esistenti.
- [ ] Il centro conserva spazio di manovra, ma non appare come un rettangolo
      vuoto separato dalla scenografia.
- [ ] La distinzione cromatica già visibile fra attacchi alleati e ostili viene
      preservata; questa card non impone una ricolorazione generale di attori,
      pickup o terreno.
- [ ] Le collisioni degli ostacoli continuano a corrispondere alle parti
      opache e non cambiano hitbox, danni, velocità o bilanciamento.
- [ ] Il layout resta derivato da `ArenaWorld`/`ArenaLayout` e rimane valido
      in 16:9, 20:9 e 4:3, dentro la rispettiva safe area.
- [ ] Nessun nuovo asset grafico viene introdotto da questa card.

## Ambito

- `scenes/game/movement_slice.tscn`, nodo `World/Obstacles`.
- `scripts/ui/arena_view.gd` e presentazione degli attori, solo se una piccola
  correzione di scala o contrasto è necessaria dopo il riassetto.
- `scripts/game/obstacles/static_obstacle.gd`, solo per mantenere corretta la
  relazione fra sprite e collisione.

Non toccare:

- `RunController`, `GameDirector`, curve di difficoltà e spawn;
- la fascia di spawn e il safe rect derivati da `ArenaWorld`/`ArenaLayout`;
- hitbox, danni, velocità e bilanciamento;
- il registry degli effetti e la semantica cromatica già esistente.

## Verifica

- Smoke: `tests/unit/test_ps045_arena_visual_hierarchy.gd` → marker
  `ARENA_VISUAL_HIERARCHY_SMOKE_OK` — verifica contenimento dei prop nel
  playfield, spazio minimo di manovra e stabilità su 16:9, 20:9 e 4:3. La
  qualità percettiva non viene dichiarata da questo smoke.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: ondata affollata con nemici, proiettili delle due
      fazioni, XP e cura contemporaneamente visibili
- [ ] Controllo percettivo richiesto: sì — leggibilità alla scala reale e
      superamento dell'aspetto da test room

## Decisioni

- **2026-08-31 — La nuova evidenza sposta il problema sulla composizione.** Le
  famiglie cromatiche sono già distinguibili; non si prescrivono bordi, ombre
  o ricolorazioni universali senza una prova runtime che li renda necessari.
- **2026-08-31 — Nessun nuovo prop.** Varietà e ritmo devono emergere dagli
  asset già disponibili e da un posizionamento meno regolare.

## Documenti sincronizzati

- [ ] `docs/visual-audio-identity.md`: principi di gerarchia e composizione
      dell'arena, solo se diventano un contratto durevole.

## Note

La cattura statica dimostra il layout a freddo; la chiusura richiede anche una
verifica percettiva durante una vera ondata affollata.
