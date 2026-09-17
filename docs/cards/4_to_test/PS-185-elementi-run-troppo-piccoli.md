---
id: PS-185
titolo: Aumenta la leggibilità generale degli elementi a schermo durante la run
tipo: ux
area: ui
stato: IN VERIFICA
priorita: alta
dipende_da: []
origine: feedback di playtest di Elisa (giocatrice esterna), riportato dal proprietario il 2026-09-16
creato: 2026-09-16
aggiornato: 2026-09-17
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

- [x] Documentato un audit delle dimensioni attuali a schermo (font size del
      tema `assets/themes/pidgeon_survivor.tres`, footprint in px di
      personaggio/nemici, dimensioni icone HUD) sui tre profili viewport
      (16:9, 20:9, 4:3) e, se possibile, su risoluzione fisica Pixel 9. Vedi
      Decisioni per i valori misurati.
- [x] Identificati esplicitamente quali elementi risultano sottodimensionati
      per un giocatore reale, distinguendo il problema da quanto già chiuso
      da PS-045 (composizione) e PS-116 (nitidezza). Vedi Decisioni: HUD
      testuale (cronometro, tag XP/HP, avvisi) e spessore delle barre;
      footprint di personaggio/nemici deliberatamente non toccato in questa
      card (vedi Ambito e Decisioni).
- [x] Gli elementi identificati come critici per la leggibilità in tempo
      reale (almeno HP/XP, timer, avvisi/testo HUD) sono ingranditi in modo
      misurabile rispetto ai valori odierni. Cronometro 28→32px, tag XP/HP
      13→16px, avviso Boss 23→27px, testo evento ondata 16→19px, spessore di
      riempimento barre XP/HP aumentato riducendo il margine interno
      (3/2px→1/1px a parità di altezza del pannello).
- [ ] Il playfield e lo spazio di manovra non si riducono rispetto a oggi:
      nessuna regressione sulla fascia di spawn/safe rect derivata da
      `ArenaWorld`/`ArenaLayout`. **Non rispettato alla lettera, deviazione
      approvata esplicitamente dal proprietario in sessione**: vedi
      Decisioni.
- [x] Nessuna hitbox, danno, velocità o soglia di bilanciamento cambia per
      effetto di questa card. Nessun file di gameplay/bilanciamento toccato
      (solo tema, `hud.tscn`, `hud.gd`, nessun cambiamento a `RunController`/
      `GameDirector`/registry effetti/attori).
- [x] Il layout resta corretto e dentro la safe area sui tre profili di
      viewport dopo l'ingrandimento. Verificato dallo smoke dedicato
      (`test_ps185_onscreen_readability.gd`) su 16:9/20:9/4:3, e dalle
      regressioni esistenti (`test_ps005_boss_warning.gd`,
      `test_ps025_boss_warning_size.gd`) riallineate al nuovo layout.
- [ ] Il proprietario (idealmente con un secondo riscontro di Elisa) conferma
      percettivamente che la sensazione di "tutto piccolo" è risolta o
      significativamente ridotta. Non chiudibile da questa sessione: il
      proprietario ha scelto di provare di persona l'APK già installato sul
      Pixel 9 invece di una prova automatizzata via ADB.

## Ambito

- `assets/themes/pidgeon_survivor.tres` (font size), HUD
  (`scenes/ui/hud.tscn`, `scripts/ui/hud.gd`), icone di stato. Toccati:
  `HudTimer` (font), `ExperienceKindLabel`/`HealthKindLabel` (font override),
  `BossWarningLabel`/`WaveEventLabel` (font override), `StyleBoxEmpty_bar_panel`
  (margine interno), `TopBand`/`BossWarningSlot`/`WaveEventSlot` (riposizionati
  per il nuovo spazio richiesto dal cronometro), `GameHud.GAMEPLAY_TOP_INSET`.
- Personaggio/nemici: **non toccati**. L'audit non ha isolato un confronto
  percettivo dedicato al footprint (richiederebbe una sessione propria, PS-116
  lo ha tenuto esplicitamente invariato a ~66px per una decisione già presa);
  la leggibilità in tempo reale (HP/XP/timer/avvisi) è il gap più concreto e
  misurabile trovato in questa sessione. Se dopo la conferma percettiva
  residua la sensazione di "piccolo", riferita nello specifico al footprint,
  apre una card dedicata.
- `scripts/game/arena_layout.gd`/`arena_world.gd`: non toccati in scrittura.
  Letti per confermare che `calculate_playfield_rect()` deriva correttamente
  dal nuovo `GAMEPLAY_TOP_INSET` (vedi Decisioni per il trade-off sul
  playfield).

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

- [x] Runtime Windows: screenshot HUD rigenerati (16:9 e Pixel9 20:9), nessun
      `SCRIPT ERROR`/`FATAL EXCEPTION`.
- [x] Validazione statica APK: `RECOVERED` (export non uscito da solo dopo
      `[ DONE ] export`, APK stabile), ispezione statica verde.
- [ ] Runtime fisico Pixel 9 (percorso: run completa con orda densa e almeno
      un incontro Boss) — **non eseguito in automatico in questa sessione**:
      il flag di verifica fisica B22 salta il tempo con un unico balzo e non
      fa accumulare spawn come farebbe una run reale (verificato leggendo
      `EnemySpawner._process`, incrementa un accumulatore con un singolo
      `if`, non un `while` di recupero). Serve tempo di gioco reale, non
      simulabile con lo shortcut usato per le altre card di questa sessione.
      APK aggiornato installato sul Pixel 9; il proprietario ha scelto di
      provarlo di persona invece di una prova automatizzata via ADB.
- [ ] Controllo percettivo richiesto: sì — è il criterio primario della
      card, non chiudibile da questa sessione (serve il proprietario,
      idealmente con un secondo riscontro di Elisa).

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
- **2026-09-17 — Audit delle dimensioni attuali (prima di modificare).**
  Tema (`assets/themes/pidgeon_survivor.tres`): `default_font_size=16`,
  `BodyS=12`, `BodyM=16`, `BodyL=18`, `HudTimer=28`. HUD
  (`scenes/ui/hud.tscn`): barre XP/HP alte 18/20px con margine interno
  3/2px (riempimento reale 13/15px), tag "XP"/"HP" in `Eyebrow` 13px,
  cronometro `HudTimer` 28px, avviso Boss 23px, testo evento ondata 16px,
  pulsante pausa 48×48px, pannello abilità 128×128px con icona 48px.
  Personaggio (`scenes/actors/player.tscn`): `scale=0.825`,
  `visual_scale_multiplier=1.25`, collisione raggio 24px (diametro 48px);
  footprint a schermo ~66px, lo stesso valore che PS-116 ha esplicitamente
  tenuto invariato. Nessuna risoluzione fisica Pixel 9 misurata
  separatamente: il progetto usa `stretch mode=canvas_items, aspect=expand`
  da base 1280×720, quindi le dimensioni logiche in pixel sono le stesse a
  parità di altezza (720) su tutti i profili landscape testati — confermato
  anche dal log reale del device (`viewport=(1616,720)` su un pannello fisico
  2424×1080, stessa altezza logica di 16:9).
- **2026-09-17 — Causa identificata: testo/barre HUD, non il footprint.**
  Il footprint di personaggio/nemici (~66px) è un valore su cui PS-116 ha già
  preso una decisione esplicita (invariato) e cambiarlo qui avrebbe richiesto
  un confronto percettivo dedicato (idealmente `direttore-artistico` o un
  nuovo playtest di Elisa mirato al solo footprint) che questa sessione non
  aveva. Il gap più concreto e misurabile trovato nell'audit: il cronometro,
  i tag XP/HP e gli avvisi Boss sono piccoli in termini assoluti (12-28px) a
  qualunque risoluzione logica, e le barre HP/XP sono sottili (13-15px di
  riempimento reale). Ingranditi questi; footprint lasciato invariato.
- **2026-09-17 — Scoperto un vincolo di layout senza margine: crescere il
  cronometro sposta tutto sotto.** `TimerSlot` è un `CenterContainer`: Godot
  impone alla dimensione del nodo un minimo derivato dal contenuto,
  indipendentemente dagli offset dichiarati nella scena. Misurato a runtime
  (istanze fresche, non riutilizzate): a 28px (valore spedito) l'altezza
  reale del contenitore è già 48px, non i 39px che l'offset della scena
  lascerebbe pensare — e il contratto esistente (`BossWarningSlot` a
  `offset_top=87`) è tarato esattamente su quel valore, senza alcun margine
  (`87 == 39 + 48`). A 32px l'altezza reale sale a 56px: senza spostare
  nulla, l'avviso Boss finirebbe **dietro** al cronometro. Corretto
  spostando `BossWarningSlot`/`WaveEventSlot` da `87` a `100` (margine di
  sicurezza di 5px) e crescendo `TopBand`/`GAMEPLAY_TOP_INSET` da 124 a 140.
- **2026-09-17 — Trade-off playfield/leggibilità, approvato esplicitamente
  dal proprietario.** Crescere `GAMEPLAY_TOP_INSET` di 16px sposta in basso
  il bordo superiore del playfield della stessa quantità (2.2%
  dell'altezza logica 720px): il criterio "il playfield non si riduce"
  non è rispettato alla lettera. Alternativa scartata (tenere il cronometro
  a 28px per non toccare affatto l'inset): avrebbe lasciato l'elemento più
  citato nel feedback ("il cronometro/le barre sono illeggibili a colpo
  d'occhio") invariato. Il proprietario, messo di fronte al numero esatto
  (16px su 720, ~2.2%), ha scelto di accettare la riduzione pur di ottenere
  un cronometro visibilmente più grande. Se in futuro la sensazione di
  spazio di manovra ridotto viene segnalata concretamente, riconsiderare
  qui, non altrove.

## Documenti sincronizzati

- [x] `docs/ui-ux-flow.md`: nessun aggiornamento necessario — il meccanismo
      di `ArenaLayout`/`top_reserved_height` resta invariato, cambia solo il
      valore della costante (non hardcoded nel documento).
- [x] `docs/visual-audio-identity.md`: nessun aggiornamento necessario —
      non documenta dimensioni font HUD specifiche; la scala visiva di
      personaggio/nemici non è stata toccata da questa card.

## Evidenze

- **2026-09-17 — Smoke dedicato:** `tests/unit/test_ps185_onscreen_readability.gd`,
  marker `PS185_READABILITY_SMOKE_OK`.
- **2026-09-17 — `Relevant`:** `focused=1/1`, `regression=37/37`, nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION`.
- **2026-09-17 — `Full`:** `focused=1/1`, `regression=153/153`, toolchain
  PASS, nessun `SCRIPT ERROR`/`FATAL EXCEPTION`.
- **2026-09-17 — Export/validazione statica Android:** `android-export`
  `RECOVERED`, `android-static` PASS.
- **2026-09-17 — Regressioni riallineate al nuovo layout:**
  `tests/unit/test_ps146_hud_bars_floating.gd` (nuovi valori di
  `content_margin`), `tests/unit/test_ps005_boss_warning.gd` e
  `tests/unit/test_ps025_boss_warning_size.gd` (nessuna modifica ai valori
  attesi: verificano il vincolo geometrico dinamicamente, tornano verdi da
  soli col nuovo posizionamento di `BossWarningSlot`/`WaveEventSlot`).
- **2026-09-17 — APK installato sul Pixel 9** (`49140DLAQ0010Y`) per la
  prova reale del proprietario; nessuna prova automatizzata via ADB in
  questa sessione (vedi Gate manuali).

## Note

Segnalato dal proprietario riportando il feedback di Elisa (giocatrice
esterna, non proprietaria del progetto) dopo un playtest della build
corrente, 2026-09-16.
