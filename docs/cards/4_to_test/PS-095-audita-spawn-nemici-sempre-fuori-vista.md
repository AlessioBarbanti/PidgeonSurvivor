---
id: PS-095
titolo: Audita e correggi lo spawn nemici che compare dentro l'area visibile
tipo: fix
area: gameplay
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-09-04
aggiornato: 2026-09-04
---

# PS-095 — Audita e correggi lo spawn nemici che compare dentro l'area visibile

## Contesto

Il proprietario ha visto in game un nemico comparire già dentro l'area
visibile invece che fuori campo, ma non ricorda le condizioni esatte
(archetipo, fase della run, device). La funzione pura
`EnemySpawner.sample_spawn_position` (usata sia dallo spawn ordinario sia
dalle formazioni evento in `wave_event_scheduler.gd`) è già progettata per
restituire solo punti fuori da `viewport_rect` ed è coperta da
`test_b04_enemy_spawner.gd`, ma quella copertura verifica solo la funzione
statica con rettangoli sintetici, non l'intera pipeline con `ArenaLayout` e
`Camera2D` reali durante resize, cambio orientamento o cluster spawn. Il gap
fra funzione pura corretta e comportamento osservato in game va isolato.

## Comportamento atteso

Ogni nemico generato dal ciclo di spawn ordinario (singolo, cluster,
formazione evento, fallback geometrico) appare sempre fuori dal rettangolo
effettivamente visibile al momento dello spawn, per tutta la durata della run
e su qualunque risoluzione/orientamento supportato. Se un percorso di spawn
viola questo contratto, va corretto.

## Criteri di accettazione

- [x] È documentato quale/i percorso/i di spawn (ordinario, cluster
      `spawn_cluster_size`, formazione evento, fallback
      `get_farthest_rect_corner`) possono produrre una posizione dentro il
      rettangolo visibile reale, con la sequenza che lo riproduce.
      *Tutti e quattro condividono un'unica causa: vedi Decisioni.*
- [x] Un test GUT che usa `ArenaLayout`/`Camera2D` reali (non solo
      `Rect2` sintetici) verifica che ogni nemico spawnato da
      `EnemySpawner`/`WaveEventScheduler` risulti fuori dal rettangolo
      visibile corrente, incluso subito dopo un resize/cambio orientamento
      del viewport.
      *`tests/unit/test_ps095_enemy_spawn_off_screen.gd`, quattro test.*
- [x] Se il test individua una violazione reale, la causa è corretta nel
      codice di produzione (non solo nel test) e il test passa in modo
      deterministico.
      *`EnemySpawner.get_visible_reference_rect()`, vedi Decisioni.*
- [ ] Se nessuna violazione emerge dall'audit end-to-end, la card lo
      dichiara esplicitamente con le condizioni testate ed è chiusa senza
      modifiche al comportamento di gameplay.
      *Non applicabile: l'audit ha trovato una violazione reale ed è stata
      corretta (criterio precedente).*

## Ambito

- File attesi: `scripts/game/enemy_spawner.gd`,
  `scripts/game/wave_event_scheduler.gd`, `scripts/game/arena_layout.gd`
  (solo lettura per il rettangolo visibile), nuovo test in
  `tests/unit/`.
- Non toccare: lo spawn del Boss (`boss_encounter.gd`,
  `calculate_spawn_position`) — spawna di proposito dentro l'area visibile
  con telegraph (PS-005), è un'eccezione voluta, non un bug. Non toccare i
  frammenti dello `splitter` (`spawn_archetype_instance` con posizione
  esplicita alla morte del genitore) — anche questi compaiono di proposito
  dove muore il genitore. Non toccare `RunController`, il registry effetti o
  il bilanciamento di `EnemySpawnProfile`.

## Verifica

- Smoke: nuovo `tests/unit/test_ps095_enemy_spawn_off_screen.gd` → marker
  `PS095_ENEMY_SPAWN_OFF_SCREEN_OK`
- Profilo minimo prima della chiusura: `Relevant`
- **Eseguito 2026-09-04 (sandbox Linux remoto, Godot 4.7.1 via
  `tools/setup-remote-sandbox.sh`, non sostituisce il percorso Windows
  locale):**
  - `test_ps095_enemy_spawn_off_screen.gd` isolato → `4/4 passed`, marker
    `PS095_ENEMY_SPAWN_OFF_SCREEN_OK` emesso. Controllato anche che i 4 test
    **falliscano** sul codice pre-fix (bug riprodotto, non un falso
    positivo).
  - Profilo `Relevant` (regole di `tools/milestone-test-map.json` per
    `enemy_spawner.gd`) + il nuovo smoke, in un solo processo:
    `test_ps095_enemy_spawn_off_screen.gd`, `test_b04_enemy_spawner.gd`,
    `test_b05_combat_slice.gd`, `test_b06_player_survival.gd`,
    `test_b18h_pigeon_enemies.gd`, `test_b28_horde_density.gd`,
    `test_b37_density_direction.gd`, `test_b38_arena_world.gd`,
    `test_ps007_late_run_pressure.gd`, `test_ps008_wave_events.gd`,
    `test_ps076_enemy_density_rebalance.gd` → `58/58 passed`, `907` assert,
    nessun `SCRIPT ERROR`/`FATAL EXCEPTION` nei log.
  - Profilo `Full` (intera `tests/unit/`) → `309/310 passed`. L'unico
    fallimento, `test_b27_upgrade_icon_refresh.gd`, è preesistente e
    indipendente da questa card (nessun file toccato qui riguarda
    `UpgradeCard`/`upgrade_card.gd`; il test passa isolato con lo stesso
    profilo, fallisce solo dentro la corsa `Full` completa). Tracciato
    separatamente in
    [PS-096](../2_to_do/PS-096-await-orfano-grow-to-fit-content-upgrade-card.md).

## Gate manuali

- [ ] Runtime Windows — non eseguito in questa sessione (solo sandbox Linux
      headless, nessun accesso a un ambiente Windows).
- [ ] Validazione statica APK — non eseguita in questa sessione.
- [ ] Runtime fisico Pixel 9 (percorso: osservare uno spawn nemico a schermo
      durante una run reale, se il gate Windows non basta a riprodurre) —
      non eseguito, nessun device disponibile in questa sessione.
- [ ] Controllo percettivo richiesto: sì — osservare visivamente gli spawn
      durante una run per confermare che nessun nemico compaia a vista — non
      eseguito, nessun rendering reale disponibile in questa sessione.

Gate lasciati esplicitamente aperti (nessun device/ambiente Windows o
Android disponibile in questa sessione): la correzione è verificata solo a
livello automatico.

## Decisioni

- **2026-09-04 — Card aperta come indagine, non come fix mirato.** Il
  proprietario ha confermato di aver visto il bug in game ma non ricorda le
  condizioni esatte di riproduzione. La card parte quindi da un audit
  end-to-end di tutti i percorsi di spawn invece che da una causa già nota.
- **2026-09-04 — Boss e frammenti dello splitter restano fuori scope.**
  Sono eccezioni di design già documentate (spawn Boss telegrafato, split
  alla morte del genitore), non violazioni del contratto "spawn sempre fuori
  vista" applicato ai nemici ordinari.
- **2026-09-04 — Causa radice: `get_visible_reference_rect()` usava le
  dimensioni del playfield, non quelle del viewport reale.**
  `EnemySpawner.get_visible_reference_rect()` (letta sia da
  `try_spawn_enemy()`/`_sample_position()` per spawn ordinario e a grappolo,
  sia da `WaveEventScheduler._spawn_formation_unit()` per le formazioni
  evento) centrava sulla vista camera un rettangolo delle **dimensioni del
  playfield** di `ArenaLayout` (il crop a `target_aspect_ratio`, default
  16:9), trattandolo come "lo schermo". Ma `project.godot` dichiara
  `window/stretch/aspect="expand"`: mondo, `Camera2D` e nemici riempiono
  l'**intero viewport reale** qualunque sia il suo aspect ratio, senza
  letterbox. Su un dispositivo più largo di 16:9 — Android landscape 20:9,
  uno dei due target co-primari del progetto (`CLAUDE.md`) — il playfield è
  quindi deliberatamente più stretto dello schermo davvero visibile (crop
  orizzontale per composizione, PS-045): un nemico piazzato "appena fuori"
  dal playfield poteva cadere ben dentro la fascia laterale che lo schermo
  mostra comunque. Lo stesso rettangolo era anche esposto a una finestra di
  razza: `ArenaLayout._playfield_rect` si aggiorna in modo differito
  (`call_deferred`) su resize/cambio orientamento, quindi nel frame fra un
  resize e quel refresh restava quello vecchio mentre il viewport reale era
  già quello nuovo.
  Fallback (`get_farthest_rect_corner`) e spawn a grappolo/formazione evento
  non hanno una causa distinta: leggono tutti lo stesso rettangolo da
  `get_visible_reference_rect()`, quindi condividono causa e correzione.
- **2026-09-04 — Correzione: leggere il viewport reale invece del
  playfield, senza toccare `arena_layout.gd`.**
  `get_visible_reference_rect()` ora usa `ArenaLayout.get_viewport_rect()`
  (già pubblico, già letto dal vivo dal `Viewport` a ogni chiamata, nessuna
  cache) come dimensione di riferimento, con fallback alla dimensione del
  playfield solo quando il viewport risulta senza area (es. nodo non ancora
  nel tree). Non serve toccare `arena_layout.gd` (resta "solo lettura" come
  da ambito): la funzione esiste già e risolve entrambi i problemi — sia il
  crop 20:9 sia la finestra di razza sul resize, perché legge il viewport
  live invece della cache differita di `_playfield_rect`.
- **2026-09-04 — Test: i settori di spawn attivi vanno forzati, non lasciati
  al roll casuale.** `EnemySpawner._roll_active_sectors()` di norma lascia
  attivo un solo lato alla volta; un fixture di test che non lo forza rischia
  di non campionare mai il lato est/ovest dove si apre il divario 20:9,
  producendo un test verde per fortuna del seed invece che per correttezza.
  Il fixture del nuovo smoke chiama esplicitamente
  `spawner.set_active_sector_override(EnemySpawner.ALL_SECTORS.duplicate())`
  (la stessa API pubblica già usata dagli eventi d'ondata) dopo
  `start_run()`, per campionare tutti e quattro i lati in modo deterministico
  rispetto al seed.
- **2026-09-04 — `test_b27_upgrade_icon_refresh.gd` non è di questa card.**
  Fallisce solo dentro la corsa `Full` completa (non isolato), con un errore
  motore in `scripts/ui/upgrade_card.gd:77` non correlato a
  `enemy_spawner.gd`. Aperta come card separata invece di allargare questa:
  [PS-096](../2_to_do/PS-096-await-orfano-grow-to-fit-content-upgrade-card.md).
- **2026-09-04 — `docs/ui-ux-flow.md` aggiornato.** Descriveva
  `get_visible_reference_rect()` come "stessa dimensione del playfield,
  ricentrata sulla camera": non più vero dopo la correzione, aggiornato per
  restare fonte di verità sul comportamento corrente.

## Documenti sincronizzati

- [x] `docs/ui-ux-flow.md`: aggiornata la descrizione di
      `get_visible_reference_rect()` per riflettere l'uso del viewport reale
      invece del playfield.
- [ ] `systems-difficulty.md`: non toccato, non descriveva esplicitamente
      questo rettangolo né i suoi margini numerici (invariati).

## Note

Ambiente di verifica di questa sessione: sandbox Linux remoto senza
Godot/Android SDK preinstallati, preparato con
`tools/setup-remote-sandbox.sh` (Godot 4.7.1 headless + Xvfb, PS-062). Non
sostituisce il percorso Windows locale di `docs/setup.md`: nessun export
APK, solo GDScript/scene/test. Comandi usati:

```
xvfb-run --auto-servernum --server-args="-screen 0 1280x720x24" \
  godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gtest=tests/unit/test_ps095_enemy_spawn_off_screen.gd -gexit

xvfb-run --auto-servernum --server-args="-screen 0 1280x720x24" \
  godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/unit -gexit
```
