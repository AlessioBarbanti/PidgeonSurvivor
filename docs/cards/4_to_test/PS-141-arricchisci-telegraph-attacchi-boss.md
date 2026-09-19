---
id: PS-141
titolo: Arricchisci i telegraph d'attacco del Boss per non sembrare debug
tipo: ux
area: arte
stato: IN VERIFICA
priorita: media
dipende_da: [PS-144]
origine:
creato: 2026-09-10
aggiornato: 2026-09-20
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

- [x] L'intensità visiva del telegraph (opacità e/o spessore del tratto)
      cambia percepibilmente con il countdown (`progress` in
      `_draw_active_telegraph`), invece di restare a stroke costante dal
      primo all'ultimo frame.
- [x] L'indicatore ha una profondità visiva percepibile (es. più livelli di
      contorno, un bagliore) e non si legge più come un singolo tratto
      vettoriale uniforme a schermo intero.
- [x] Il colore magenta riservato agli Evil (`EVIL_TELEGRAPH_COLOR`) e quello
      rosso-arancio dei boss normali restano invariati e distinguibili fra
      loro come oggi.
- [x] La leggibilità del perimetro esatto dell'area colpita (dove il
      giocatore deve stare per evitare danno) non peggiora rispetto a oggi:
      il confine resta chiaramente individuabile a colpo d'occhio.

## Ambito

- PS-141 integra gli asset prodotti da PS-144 in tutti i pattern d'attacco
  Boss/Evil: volley radiale, blast mirato, scia di piume, Signature e relative
  aree attive. Riusa gli sprite già esistenti quando adeguati.
- File attesi: `scripts/bosses/first_boss.gd`,
  `scripts/bosses/boss_signature_area.gd`, eventuale helper di presentazione,
  test deterministici e harness per screenshot.
- Evitare al massimo `draw_arc`, `draw_circle`, linee e primitive analoghe
  come rappresentazione degli attacchi: usare texture con profondità e
  animazione legata al countdown. La precisione geometrica del pericolo deve
  restare verificabile anche con il nuovo trattamento materico.
- Preservare palette Boss/Evil, danno, collisioni, timing, finestre sicure,
  pausa e restart. La generazione raster appartiene esclusivamente a PS-144.

## Verifica

- Smoke: `tests/unit/test_ps141_boss_telegraph_intensity.gd` → marker
  `PS141_BOSS_TELEGRAPH_OK`, verifica che il valore usato per opacità/stroke
  del telegraph cambi fra inizio e fine del countdown (non resti costante) e
  che i colori Evil/boss normale restino quelli attesi.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [x] Runtime Windows — 57 catture dal renderer Windows reale
      (`tools/_capture_boss_telegraphs_ps141.gd`, marker `PS141_CAPTURE_DONE`,
      nessun `error!=0`, run sempre in `RUNNING`). È una scena congelata a
      frame guidati, non una partita giocata: il giudizio sul combattimento
      vero resta al gate percettivo qui sotto.
- [ ] Validazione statica APK — non eseguita in questa sessione
- [ ] Runtime fisico Pixel 9 (percorso: percezione durante un vero
      combattimento Boss, non solo screenshot statico)
- [ ] Controllo percettivo richiesto: sì — il proprietario ha segnalato
      l'aspetto "da debug" giocando dal vivo, non da uno screenshot

## Decisioni

- **2026-09-20 — Le corsie della Scia di Piume usano l'inviluppo reale del
  colpo.** Disegnate al solo `feather_line_projectile_radius` (7 px) le dodici
  corsie si schiacciavano in linee piatte: esattamente l'aspetto "da debug"
  che la card elimina. La fascia ora è `raggio piuma + raggio del Player`,
  cioè l'insieme esatto delle posizioni in cui il centro del Player viene
  colpito. Sovrastima mai: mostra tutto ciò che colpisce, non meno.
  L'anello dell'area mirata resta invece sul solo raggio dell'abilità, come
  prima di questa card — asimmetria preesistente, non toccata qui.

- **2026-09-20 — Il nastro di corsia si ripete invece di stirarsi.** Una sola
  quad stirata su 1600 px annullava la materia della texture. `corridor_tiles`
  ripete la regione vicino alla proporzione nativa, con un tetto di 4 stampe
  per corsia per non far esplodere le draw call su Android.

- **2026-09-19 — Direzione aggiornata dal proprietario:** tutti gli attacchi
  necessitano di asset; il solo arricchimento delle primitive non soddisfa
  più la richiesta. Questa decisione supera il precedente ambito procedurale
  senza nuova arte. PS-144 produce; PS-141 integra e verifica, senza cambiare
  il comportamento di combattimento. La dipendenza è PS-141 → PS-144.

- **2026-09-10 — Consultato il direttore-artistico prima di aprire la card**
  (richiesta del proprietario dopo aver notato l'aspetto "da debug" degli
  attacchi Boss). Confermato che il colore magenta è intenzionale e va
  tenuto; il problema è la mancanza di profondità/animazione nel disegno
  procedurale, non la tinta. Sconsigliata l'assunzione di un riuso diretto di
  particellari fuoco "già pronti": il progetto non ha oggi nodi
  `GPUParticles2D`/`CPUParticles2D`, verificato durante l'apertura di questa
  card — se servono vanno introdotti, non riusati da un sistema inesistente.

- **2026-09-19 — Palette verificata sui dati correnti:** il baseline usa
  `Color(1, 0.22, 0.5, 0.76)` in `first_boss.tres`; Evil usa
  `Color(0.92, 0.12, 0.78, 0.78)` in `BossEncounter`. La descrizione storica
  rosso-arancio è imprecisa rispetto ai dati attuali: si conservano questi
  valori esatti, senza un cambio cromatico implicito.

## Documenti sincronizzati

- [x] `docs/enemies-bosses.md` — nuova sezione "Presentazione degli attacchi
      (PS-141/PS-144)": stampe raster obbligatorie, rampa di intensità con
      geometria congelata, modulazione del colore ostile e ancoraggio ai raggi
      autorevoli. Vale per ogni pattern futuro.

## Note

Verifica eseguita il 2026-09-20 (nessun `SCRIPT ERROR` nei log):

```powershell
.	oolsun-milestone-checks.ps1 -Milestone PS-141 -Profile Relevant `
  -FocusedSmoke tests/unit/test_ps141_boss_telegraph_intensity.gd,`
tests/unit/test_ps141_boss_raster_decorations.gd
.	oolsun-milestone-checks.ps1 -Milestone PS-141 -Profile Full
```

`Relevant` PASS (focused 3/3, regression 28/28), `Full` PASS (regression
157/157, toolchain 1/1). Marker: `PS141_BOSS_TELEGRAPH_OK`,
`PS141_BOSS_RASTER_DECORATIONS_OK`. Il ventaglio accoppiato/opposto su cui si
appoggia il disegno della corsia intera è ora asserito in
`tests/unit/test_ps127_piccione_malvagio_hard_rare.gd`.

Catture: `exports/ui-screenshots/ps141-boss-telegraphs/` (57 PNG 1280x720,
tre passi di countdown 05/50/95 più lo stato attivo, baseline ed Evil, tutte
le Signature del catalogo). La cartella `-before` presente a metà lavoro è
stata rimossa: era una copia identica alle catture post-modifica, non una
baseline: un confronto onesto richiederebbe di ricostruire l'albero pre-card,
cosa che non è stata fatta per non toccare il worktree del proprietario.

Le proposte procedurali originali (glow tramite più archi e tratti) sono
superate dalla direzione del 2026-09-19. Restano validi i requisiti di
imminenza crescente, profondità, palette e precisione del perimetro.
La resa definitiva usa gli asset di PS-144 e il riuso motivato delle VFX
esistenti. Gli screenshot documentano la resa; non sostituiscono il gate
percettivo del proprietario durante un combattimento reale.