---
id: PS-141
titolo: Arricchisci i telegraph d'attacco del Boss per non sembrare debug
tipo: ux
area: arte
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-141 — Arricchisci i telegraph d'attacco del Boss per non sembrare debug

## Contesto

Gli indicatori di area d'attacco del Boss (`scripts/bosses/first_boss.gd`,
`_draw_radial_volley_telegraph` e `_draw_targeted_blast_telegraph`) sono
disegni procedurali: un singolo `draw_arc`/`draw_circle` a stroke costante,
senza variazione di intensità nel tempo né texture. Il colore magenta
(`EVIL_TELEGRAPH_COLOR`, `scripts/bosses/boss_encounter.gd`) è intenzionale
(riservato agli avversari "Evil" per distinguerli dai boss normali, che usano
rosso-arancio) e resta invariato. Il proprietario percepisce comunque questi
indicatori come placeholder di debug durante il combattimento. Consultato in
merito, il direttore-artistico conferma: il colore va tenuto, ma il
trattamento visivo — stroke uniforme, nessuna profondità, nessuna animazione
legata al countdown, nessun legame con l'estetica a tema fuoco/griglia del
gioco — è ciò che lo fa leggere come wireframe di debug invece che come VFX
finito.

## Comportamento atteso

Durante un telegraph d'attacco Boss (volley radiale o blast mirato), il
giocatore percepisce un indicatore con profondità visiva e un'imminenza
crescente man mano che l'attacco si avvicina, coerente con il linguaggio
visivo a tema fuoco/griglia già presente nel gioco — non un contorno
vettoriale statico e uniforme.

## Criteri di accettazione

- [ ] L'intensità visiva del telegraph (opacità e/o spessore del tratto)
      cambia percepibilmente con il countdown (`progress` in
      `_draw_active_telegraph`), invece di restare a stroke costante dal
      primo all'ultimo frame.
- [ ] L'indicatore ha una profondità visiva percepibile (es. più livelli di
      contorno, un bagliore) e non si legge più come un singolo tratto
      vettoriale uniforme a schermo intero.
- [ ] Il colore magenta riservato agli Evil (`EVIL_TELEGRAPH_COLOR`) e quello
      rosso-arancio dei boss normali restano invariati e distinguibili fra
      loro come oggi.
- [ ] La leggibilità del perimetro esatto dell'area colpita (dove il
      giocatore deve stare per evitare danno) non peggiora rispetto a oggi:
      il confine resta chiaramente individuabile a colpo d'occhio.

## Ambito

- File attesi: `scripts/bosses/first_boss.gd`
  (`_draw_radial_volley_telegraph`, `_draw_targeted_blast_telegraph`,
  `_draw_active_telegraph`), eventualmente `scripts/actors/ranged_enemy.gd`
  se condivide la stessa logica di disegno.
- Non toccare: `EVIL_TELEGRAPH_COLOR` e la distinzione cromatica Evil/boss
  normale (`scripts/bosses/boss_encounter.gd`), il calcolo di
  `_telegraph_duration`/`_telegraph_remaining` e la finestra di danno reale
  (solo il trattamento visivo cambia, non i frame di sicurezza).
- Non è richiesta nuova arte raster: il gioco non ha un sistema di
  particellari (`GPUParticles2D`/`CPUParticles2D`) dedicato oggi — verificare
  prima di assumerne uno. Se durante l'implementazione emerge che serve
  davvero una texture dedicata (es. una decal di terra bruciata sotto il
  telegraph) invece di un arricchimento del disegno procedurale, quella
  parte è materiale da card `tipo: art` separata, delegata a
  `game-art-designer` e collegata qui via `dipende_da` — non va prodotta
  dentro questa card.

## Verifica

- Smoke: `tests/unit/test_ps141_boss_telegraph_intensity.gd` → marker
  `PS141_BOSS_TELEGRAPH_OK`, verifica che il valore usato per opacità/stroke
  del telegraph cambi fra inizio e fine del countdown (non resti costante) e
  che i colori Evil/boss normale restino quelli attesi.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: percezione durante un vero
      combattimento Boss, non solo screenshot statico)
- [ ] Controllo percettivo richiesto: sì — il proprietario ha segnalato
      l'aspetto "da debug" giocando dal vivo, non da uno screenshot

## Decisioni

- **2026-09-10 — Consultato il direttore-artistico prima di aprire la card**
  (richiesta del proprietario dopo aver notato l'aspetto "da debug" degli
  attacchi Boss). Confermato che il colore magenta è intenzionale e va
  tenuto; il problema è la mancanza di profondità/animazione nel disegno
  procedurale, non la tinta. Sconsigliata l'assunzione di un riuso diretto di
  particellari fuoco "già pronti": il progetto non ha oggi nodi
  `GPUParticles2D`/`CPUParticles2D`, verificato durante l'apertura di questa
  card — se servono vanno introdotti, non riusati da un sistema inesistente.

## Documenti sincronizzati

- [ ] `docs/enemies-bosses.md`, se il risultato introduce una convenzione
      visiva esplicita per i telegraph (es. animazione di intensità come
      standard per ogni futuro pattern d'attacco).

## Note

Direzioni suggerite dal direttore-artistico, non vincolanti per
l'implementazione: ring esterno più tenue (glow) oltre al tratto interno
definito; pulsazione di opacità/spessore legata a `progress` invece di un
valore costante; eventuale riempimento centrale non piatto. La scelta tecnica
esatta (nuovo disegno procedurale più ricco vs. nodo particellare introdotto
ex novo) resta a `card-risolvi`.
