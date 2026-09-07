---
id: PS-116
titolo: Aumenta la risoluzione nativa dello sprite di gameplay del cast a 64×64
tipo: fix
area: arte
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-116 — Aumenta la risoluzione nativa dello sprite di gameplay del cast a 64×64

## Contesto

Il proprietario percepisce una disparità di definizione fra il personaggio
giocabile e i piccioni nemici: i piccioni sembrano nitidi, il personaggio
"poco definito". Consultato il `game-art-designer` in modalità pianificazione
(PS-109), la causa è confermata tecnica e non solo impressione soggettiva:

- Lo sprite di gameplay del cast (`assets/art/characters/<id>/generated/sprite.png`)
  è nativo **32×32 px per frame** su tutti e 8 i personaggi (verificato:
  zat, bea, aleo, alea, lollo, migi, marghe, magno, tutti 96×32 totale a 3
  frame). Gli sprite dei piccioni (`assets/art/enemies/pigeons/pigeon_*.png`)
  sono nativi **48×48 px per frame** (144×48 totale) — 1.5× la risoluzione
  lineare, 2.25× l'area.
- A schermo il personaggio non è più piccolo: `scenes/actors/player.tscn`
  applica `CharacterSprite.scale = Vector2(1.65, 1.65)` più
  `visual_scale_multiplier = 1.25` (costante, non per-personaggio — vedi
  `scripts/actors/player.gd:30`), per un footprint finale di
  `32 × 1.65 × 1.25 ≈ 66px`. Il piccione (`scenes/actors/base_enemy.tscn`,
  `EnemySprite`) non ha scala aggiuntiva e resta a `48px`. Il personaggio è
  quindi ingrandito ~2× da un canvas nativo più povero, mentre il piccione è
  mostrato quasi al nativo — da qui il gap di dettaglio percepito.
- Il master approvato (`assets/art/characters/<id>/hd/poses.png`, identity
  pass del 28/08/2026, PS-068/PS-084) contiene dettaglio sufficiente per un
  derivato a risoluzione più alta: lo script esistente
  `tools/process-cast-sprite.ps1` accetta già `-CanvasSize` come parametro
  (default 32), quindi rigenerare il derivato a 64 non richiede nuova sintesi
  né l'agente Game Art Designer.
- La stessa disparità si ripresenta sulla versione Evil (Boss) del
  personaggio: `BossDefinition.get_visual_texture()`
  ([scripts/bosses/boss_definition.gd:75-78](../../../scripts/bosses/boss_definition.gd))
  restituisce, per una variante Evil, esattamente
  `friend_profile.get_gameplay_idle_right()` — la stessa region
  `AtlasTexture_gameplay_idle` sul medesimo `sprite.png`, non un asset Evil
  separato. `first_boss.gd._sync_boss_visual()` la scala poi a
  `target_diameter = collision_radius * 1.9` (es. `46.0 * 1.9 = 87.4` per
  `data/bosses/first_boss.tres`), indipendente dalla risoluzione sorgente:
  oggi `87.4 / 32 ≈ 2.73×` di ingrandimento, quindi il corpo Evil in
  combattimento è probabilmente ancora meno definito del personaggio
  giocabile stesso. Il ritratto Evil di dialogo (`evil_portrait.png`,
  256×256, PS-052) è un asset diverso e non è affetto da questo problema.

## Comportamento atteso

Lo sprite di gameplay di tutti e 8 i personaggi viene rigenerato dal master
`hd/poses.png` già approvato con `tools/process-cast-sprite.ps1
-CanvasSize 64` (striscia 3 frame, 192×64 totale per personaggio). Il
footprint a schermo del personaggio resta invariato (~66px): la scala
compensativa si applica su `CharacterSprite.scale` in `player.tscn`
(`1.65 → 0.825`, dato che il canvas nativo raddoppia da 32 a 64), non sul
`visual_scale_multiplier` per personaggio né sulle aure VFX (PS-099), che
sono tarate sul footprint risultante e non sul canvas sorgente. Le region
`AtlasTexture` in ciascun `data/friends/<id>.tres`
(`gameplay_walk_right_frames`, `gameplay_idle_right`) vengono aggiornate da
`32×32` a `64×64` per frame, stessa sequenza (walk_a, idle, walk_b, idle).
Nessun cambiamento a costume, posa, palette, animazione o timing di
camminata: è un aumento di risoluzione del derivato esistente, non un
restyle.

Poiché il corpo Evil (Boss) riusa la stessa region, il beneficio si estende
automaticamente a lui: a `target_diameter` invariato (derivato da
`collision_radius`, non dalla risoluzione sorgente) il fattore di
ingrandimento del Boss si dimezza passando da texture 32×32 a 64×64 (es.
`87.4 / 64 ≈ 1.37×` invece di `2.73×` per il primo Boss). Nessuna modifica a
`boss_definition.gd`, `first_boss.gd` o ai dati Boss è necessaria: è un
effetto collaterale corretto della stessa modifica, da verificare non da
implementare.

## Criteri di accettazione

- [x] Tutti e 8 i file `assets/art/characters/<id>/generated/sprite.png`
      sono rigenerati a 64×64 px per frame (192×64 totale, 3 frame),
      prodotti da `tools/process-cast-sprite.ps1 -CanvasSize 64 -Padding 4`
      sul master `hd/poses.png` esistente di ciascun personaggio. Verificato
      da `test_cast_sprite_derivatives_are_64x64`.
- [x] `CharacterSprite.scale` in `scenes/actors/player.tscn` è aggiornato a
      `Vector2(0.825, 0.825)`; il footprint a schermo risultante
      (`64 × 0.825 × 1.25`) resta entro l'1% di 66px per tutti i personaggi.
      Verificato da `test_player_footprint_preserved_after_resolution_bump`
      su tutti e otto i profili (tolleranza 0.01px, ben sotto l'1%).
- [x] Le region `AtlasTexture_gameplay_*` negli 8 `data/friends/<id>.tres`
      referenziano celle `64×64` (non più `32×32`) nella sequenza corretta.
- [x] `test_b18u_cast_sprites.gd` e `test_b24_player_visual_scale.gd`
      (che oggi assumono `Vector2(1.65, 1.65)`/32×32) sono aggiornati alla
      nuova base scale e continuano a passare. Aggiornati anche due hash
      SHA-256 attesi in `test_b18u_cast_sprites.gd` (uno per personaggio) e
      la dimensione idle in `test_b18c_player_direction_animation.gd`,
      scoperti durante la verifica e non previsti nell'ambito originale.
- [x] Le tre aure VFX (`HyperfocusAura`, `ThermalGroundAura`,
      `ThunderChargeAura`, PS-099) restano visivamente invariate: nessuna
      regressione di allineamento o scala rispetto al footprint del
      personaggio. `test_ps099_state_tell_aura.gd` è nella suite `Relevant`
      rieseguita (53/53 verdi) e non tocca costanti hardcoded sul canvas
      sorgente (verificato per assenza di riferimenti `32x32`/`1.65` in
      `scripts/vfx/*aura*.gd`).
- [x] `CircleShape2D` (collision, radius 24.0) e `HealthComponent` restano
      invariati: nessun cambiamento a hitbox o bilanciamento (non toccati,
      confermato da `test_b18u_cast_sprites.gd::_assert_collision_contract`
      nella suite `Relevant`).
- [ ] Confronto visivo prima/dopo (screenshot in-run) mostra un
      miglioramento percepibile di nitidezza del personaggio rispetto al
      piccione, a giudizio del proprietario. **Aperto**: non eseguito in
      questa sessione (nessun run interattivo osservato da un umano).
- [x] Il corpo Evil (Boss) in combattimento, che riusa la stessa
      `AtlasTexture_gameplay_idle`, mostra lo stesso miglioramento di
      definizione: `test_evil_boss_body_resolution_improves` verifica che il
      fattore di scala segua `target_diameter / 64` (non più `/ 32`) senza
      alcuna modifica a `boss_definition.gd`, `first_boss.gd` o ai dati Boss.

## Ambito

- File: gli 8 `assets/art/characters/<id>/generated/sprite.png`,
  `scenes/actors/player.tscn`, gli 8 `data/friends/<id>.tres` (solo region
  `AtlasTexture_gameplay_*`), `tests/unit/test_b18u_cast_sprites.gd`,
  `tests/unit/test_b24_player_visual_scale.gd`.
- Scoperto durante l'implementazione, non nell'ambito originale ma necessario
  per non rompere il contratto esistente:
  `scripts/game/movement_slice.gd::_validate_current_contract()` conteneva
  due assert hardcoded su `Vector2(32.0, 32.0)` per l'idle/i frame del cast
  (righe ~1764, ~1776) e `tests/unit/test_b18c_player_direction_animation.gd`
  un'analoga assunzione — aggiornati a `64x64`, altrimenti B18U/B18C
  sarebbero falliti dopo la rigenerazione. Aggiornato anche il commento
  (non il valore, gia' corretto per costruzione) in
  `scripts/vfx/passive_state_particles.gd` che documentava la derivazione
  di `HEAD_OFFSET` sui vecchi numeri.
- Solo verifica, nessuna modifica: `scripts/bosses/boss_definition.gd`,
  `scripts/bosses/first_boss.gd`, `data/bosses/*.tres` — il corpo Evil/Boss
  eredita il beneficio dalla stessa region senza bisogno di toccare questi
  file; servono solo per confermare il criterio di accettazione dedicato.
- Non toccare: i master `hd/poses.png`, `portrait.png`, `carousel.png`,
  `evil_portrait.png` e le rispettive region/derivati (pipeline busti già
  chiusa, PS-068/PS-052); `AtlasTexture_evil` (placeholder terze parti, non
  correlato); costume/posa/palette del personaggio; `visual_scale_multiplier`
  (resta 1.25, costante e non per-personaggio); animazioni, timing di
  camminata o `gameplay_walk_fps`; collision radius, `HealthComponent`,
  `RunController`; lo stile o i file dei piccioni.

## Verifica

- Smoke: `tests/unit/test_ps116_cast_sprite_resolution.gd` → marker
  `PS116_CAST_SPRITE_RESOLUTION_OK` (verifica dimensioni derivati, region
  atlas aggiornate, footprint a schermo invariato)
- Estendere `test_b18u_cast_sprites.gd` e `test_b24_player_visual_scale.gd`
  ai nuovi valori attesi
- Rieseguire `test_b22_evil_boss_variants.gd` (già verifica che
  `get_visual_texture()` combaci con `get_gameplay_idle_right()`) per
  confermare che il legame Evil/sprite non si sia rotto
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows: confronto percettivo diretto personaggio/piccione a
      schermo, incluso almeno un incontro Boss per il corpo Evil — **aperto**,
      non eseguito in questa sessione (solo verifica automatica GUT).
- [ ] Validazione statica APK — **aperto**, non eseguito in questa sessione.
- [ ] Runtime fisico Pixel 9: verifica percettiva che il miglioramento sia
      visibile anche a risoluzione mobile compressa, incluso il Boss —
      **aperto**, device non disponibile in questa sessione. Non blocca
      l'implementazione ma il gate resta dichiarato aperto, non assunto.
- [ ] Controllo percettivo richiesto: sì — è il criterio primario di questa
      card (il proprietario deve giudicare se il gap percepito si è chiuso) —
      **aperto**, da fare dal proprietario.

## Decisioni

- **2026-09-07 — Consultato il game-art-designer in pianificazione (PS-109).**
  Confermata la causa tecnica (canvas nativo 32×32 vs 48×48 dei piccioni,
  aggravata dallo scale-up ~2× a schermo) e segnalato un secondo fattore
  concorrente: il master `poses.png` ha uno shading sfumato/painterly che
  potrebbe restare "morbido" anche a risoluzione più alta, a differenza dei
  piccioni disegnati fin dall'origine con palette piatta e contorno spesso.
- **2026-09-07 — Il proprietario ha scelto l'opzione a costo zero prima.**
  Rigenerare il derivato dal master già approvato con lo script esistente
  (nessuna nuova sintesi, nessun Codex), valutare il risultato, e solo se il
  gap resta evidente aprire una card `tipo: art` separata per un nuovo master
  "sprite" con shading piatto e chunky come i piccioni (opzione scartata per
  ora, non in questa card).
- **2026-09-07 — Canvas target 64×64**, non 48×48 (parità con i piccioni):
  a footprint a schermo invariato dà al protagonista più pixel sorgente dei
  piccioni, coerente col suo ruolo di protagonista, con una sola modifica di
  scala compensativa.
- **Aperto:** se dopo questa card il gap percepito resta evidente, la
  prossima card valuterà un nuovo master dedicato (fuori scope qui).
- **2026-09-07 — Implementato e verificato automaticamente.** Rigenerazione
  via skill `asset-pipeline` (8 derivati, manifest aggiornato con nuovi
  hash/byte e nota sul cambio di comando). Wiring: `player.tscn` (scala
  0.825), 8 `data/friends/<id>.tres` (region 64×64), due assert hardcoded
  scoperti in `movement_slice.gd` e un test aggiuntivo aggiornati (vedi
  Ambito). Nuovo smoke `test_ps116_cast_sprite_resolution.gd` (3 test:
  dimensioni derivati, footprint invariato su tutti gli 8 profili, corpo
  Evil). Focused 1/1, Relevant 53/53, nessun `SCRIPT ERROR`/`FATAL
  EXCEPTION`. Gate percettivi/device restano aperti: la card passa a
  `IN VERIFICA`, non `COMPLETATO`.
- **Nota tecnica:** un primo tentativo di aggiornare le region
  `AtlasTexture` negli 8 `.tres` con un ciclo PowerShell
  (`Get-Content`/`Set-Content`) ha corrotto l'encoding UTF-8 (BOM aggiunto,
  caratteri accentati trasformati in mojibake — "velocità" → "VelocitÃ ").
  Individuato da `git diff --stat` (conteggio righe cambiate superiore
  all'atteso) prima di qualunque commit. Ripristinati con `git checkout` e
  rifatti con l'Edit tool, che non ha questo problema.
- **2026-09-07 — Estesa esplicitamente alla versione Evil.** Il proprietario
  ha chiesto di includere anche il corpo Evil dei personaggi. Non serve una
  card separata: `BossDefinition.get_visual_texture()` riusa la stessa
  region `AtlasTexture_gameplay_idle` del personaggio normale, quindi il
  beneficio è automatico. Aggiunto un criterio di accettazione dedicato per
  verificarlo esplicitamente invece di darlo per assunto.

## Documenti sincronizzati

- [x] [docs/visual-audio-identity.md](../../../docs/visual-audio-identity.md):
      nuova sezione "Sprite di gameplay del cast (PS-116)" con dimensioni,
      comando di derivazione e nota sul beneficio automatico al corpo Evil.
- [x] `assets/art/characters/ASSET-MANIFEST.md`: righe "File e integrita"
      aggiornate con byte/hash dei nuovi derivati; aggiunto paragrafo che
      documenta il comando corrente (`-CanvasSize 64 -Padding 4`) accanto a
      quello storico.
- [x] `docs/prd.md`: il paragrafo sugli sprite B18U/B24 (sezione 3.6) era
      rimasto ai numeri pre-PS-116 (`96×32`/`32×32`, scala `1,65`/`2,0625`) —
      scoperto durante PS-100 mentre si editava la sezione adiacente
      sull'Ansia. Aggiornato a `192×64`/`64×64` e scala `0,825`/`1,03125`.

## Note

Se il confronto percettivo finale non chiude a sufficienza il gap, la card di
follow-up per un nuovo master "sprite" chunky (Opzione 2 discussa in
pianificazione) andrà aperta separatamente come `tipo: art`, con
consultazione del `game-art-designer` per la scomposizione in pezzi di
consegna e review d'identità per personaggio (rischio di deriva dai
riferimenti fotografici autorizzati del 28/08/2026).
