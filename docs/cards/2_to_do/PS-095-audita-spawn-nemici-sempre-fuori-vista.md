---
id: PS-095
titolo: Audita e correggi lo spawn nemici che compare dentro l'area visibile
tipo: fix
area: gameplay
stato: PRONTO
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

- [ ] È documentato quale/i percorso/i di spawn (ordinario, cluster
      `spawn_cluster_size`, formazione evento, fallback
      `get_farthest_rect_corner`) possono produrre una posizione dentro il
      rettangolo visibile reale, con la sequenza che lo riproduce.
- [ ] Un test GUT che usa `ArenaLayout`/`Camera2D` reali (non solo
      `Rect2` sintetici) verifica che ogni nemico spawnato da
      `EnemySpawner`/`WaveEventScheduler` risulti fuori dal rettangolo
      visibile corrente, incluso subito dopo un resize/cambio orientamento
      del viewport.
- [ ] Se il test individua una violazione reale, la causa è corretta nel
      codice di produzione (non solo nel test) e il test passa in modo
      deterministico.
- [ ] Se nessuna violazione emerge dall'audit end-to-end, la card lo
      dichiara esplicitamente con le condizioni testate ed è chiusa senza
      modifiche al comportamento di gameplay.

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

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: osservare uno spawn nemico a schermo
      durante una run reale, se il gate Windows non basta a riprodurre)
- [ ] Controllo percettivo richiesto: sì — osservare visivamente gli spawn
      durante una run per confermare che nessun nemico compaia a vista

## Decisioni

- **2026-09-04 — Card aperta come indagine, non come fix mirato.** Il
  proprietario ha confermato di aver visto il bug in game ma non ricorda le
  condizioni esatte di riproduzione. La card parte quindi da un audit
  end-to-end di tutti i percorsi di spawn invece che da una causa già nota.
- **2026-09-04 — Boss e frammenti dello splitter restano fuori scope.**
  Sono eccezioni di design già documentate (spawn Boss telegrafato, split
  alla morte del genitore), non violazioni del contratto "spawn sempre fuori
  vista" applicato ai nemici ordinari.

## Documenti sincronizzati

- [ ] `systems-difficulty.md`, se l'audit porta a un cambiamento del
      contratto di spawn o dei suoi margini.

## Note

Nessuna.
