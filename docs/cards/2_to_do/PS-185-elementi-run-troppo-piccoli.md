---
id: PS-185
titolo: Aumenta la leggibilità generale degli elementi a schermo durante la run
tipo: ux
area: ui
stato: PRONTO
priorita: alta
dipende_da: []
origine: feedback di playtest di Elisa (giocatrice esterna), riportato dal proprietario il 2026-09-16
creato: 2026-09-16
aggiornato: 2026-09-16
---

# PS-185 — Aumenta la leggibilità generale degli elementi a schermo durante la run

## Contesto

Il proprietario riporta un feedback di playtest di Elisa: "il gioco è bello ma
mi sono cavata gli occhi" — durante la run percepisce tutto come troppo
piccolo. È un giudizio complessivo, non ancora ricondotto a un elemento
specifico: può riguardare il footprint di personaggio/nemici, le dimensioni di
testo/icone HUD (`assets/themes/pidgeon_survivor.tres`, `default_font_size =
16`, `BodyM = 16`, `BodyS = 12`), o il rapporto fra playfield e viewport
(`scripts/game/arena_layout.gd`, `project.godot` con risoluzione base
1280×720 e stretch `canvas_items`/`expand`). Non esiste alcuno zoom di camera
nel codice: tutto è renderizzato 1:1 fra unità di mondo e pixel del playfield
calcolato da `ArenaLayout`.

Non è la stessa causa già affrontata da PS-045 (composizione e spaziatura dei
prop dell'arena, non le dimensioni) né da PS-116 (nitidezza/risoluzione nativa
dello sprite del cast, a footprint a schermo esplicitamente invariato,
~66px). Qui il tema è la dimensione percepita degli elementi, non la
composizione né il dettaglio.

## Comportamento atteso

Durante la run, gli elementi che il giocatore deve leggere in tempo reale
(HP/XP, timer, avvisi, icone di stato, personaggio, nemici, proiettili,
pickup) risultano percepibilmente più grandi/leggibili rispetto a oggi, senza
ridurre lo spazio di manovra del playfield né alterare bilanciamento, hitbox o
velocità.

## Criteri di accettazione

- [ ] Documentato un audit delle dimensioni attuali a schermo (font size del
      tema `assets/themes/pidgeon_survivor.tres`, footprint in px di
      personaggio/nemici, dimensioni icone HUD) sui tre profili viewport
      (16:9, 20:9, 4:3) e, se possibile, su risoluzione fisica Pixel 9.
- [ ] Identificati esplicitamente quali elementi risultano sottodimensionati
      per un giocatore reale, distinguendo il problema da quanto già chiuso
      da PS-045 (composizione) e PS-116 (nitidezza).
- [ ] Gli elementi identificati come critici per la leggibilità in tempo
      reale (almeno HP/XP, timer, avvisi/testo HUD) sono ingranditi in modo
      misurabile rispetto ai valori odierni.
- [ ] Il playfield e lo spazio di manovra non si riducono rispetto a oggi:
      nessuna regressione sulla fascia di spawn/safe rect derivata da
      `ArenaWorld`/`ArenaLayout`.
- [ ] Nessuna hitbox, danno, velocità o soglia di bilanciamento cambia per
      effetto di questa card.
- [ ] Il layout resta corretto e dentro la safe area sui tre profili di
      viewport dopo l'ingrandimento.
- [ ] Il proprietario (idealmente con un secondo riscontro di Elisa) conferma
      percettivamente che la sensazione di "tutto piccolo" è risolta o
      significativamente ridotta.

## Ambito

- `assets/themes/pidgeon_survivor.tres` (font size), HUD
  (`scenes/ui/hud.tscn`, `scripts/ui/hud.gd`), icone di stato.
- Eventuale scala visiva di personaggio/nemici (`scenes/actors/player.tscn`,
  `scenes/actors/base_enemy.tscn`), solo se l'audit conferma che è il
  footprint — non la nitidezza già risolta da PS-116 — la causa.
- `scripts/game/arena_layout.gd`/`arena_world.gd` solo in lettura come
  riferimento del playfield attuale, salvo che l'audit indichi che il
  rapporto playfield/viewport è parte della causa.

Non toccare:

- `RunController`, `GameDirector`, curve di difficoltà e spawn;
- hitbox, danni, velocità, bilanciamento;
- la pipeline di nitidezza/risoluzione nativa già chiusa da PS-116;
- la composizione dell'arena già chiusa da PS-045;
- il registry degli effetti.

## Verifica

- Nuovo smoke `tests/unit/test_ps185_onscreen_readability.gd` → marker
  `PS185_READABILITY_SMOKE_OK`, che verifica dimensionalmente gli elementi
  ingranditi rispetto ai valori odierni e l'assenza di regressioni su safe
  area/playfield sui tre profili di viewport.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK (solo se la modifica tocca scene/asset
      impacchettati nell'HUD)
- [ ] Runtime fisico Pixel 9 (percorso: run completa con orda densa e almeno
      un incontro Boss) — obbligatorio: il feedback nasce da un test fisico
      su device, non riprodotto altrove
- [ ] Controllo percettivo richiesto: sì — è il criterio primario della card

## Decisioni

- **2026-09-16 — Non assumere quale elemento sia la causa.** "Tutto piccolo"
  è un giudizio olistico di un playtest reale (Elisa), non una diagnosi
  tecnica. Prima si accerta cosa è realmente sottodimensionato, poi si
  sceglie cosa ingrandire — stesso approccio già usato per le diagnosi dello
  stesso batch di feedback (PS-172, PS-175, PS-177, PS-178).
- **2026-09-16 — Perimetro distinto da PS-045 e PS-116.** PS-045 ha lavorato
  sulla composizione/spaziatura dell'arena a parità di scala; PS-116 ha
  aumentato la risoluzione nativa dello sprite del cast mantenendo
  esplicitamente invariato il footprint a schermo (~66px). Nessuna delle due
  ha toccato la dimensione percepita complessiva: questa card la affronta per
  la prima volta.

## Documenti sincronizzati

- [ ] `docs/ui-ux-flow.md`, se emerge un nuovo contratto dimensionale per HUD
      o testo.
- [ ] `docs/visual-audio-identity.md`, se cambia la scala visiva di
      personaggio/nemici.

## Note

Segnalato dal proprietario riportando il feedback di Elisa (giocatrice
esterna, non proprietaria del progetto) dopo un playtest della build
corrente, 2026-09-16.
