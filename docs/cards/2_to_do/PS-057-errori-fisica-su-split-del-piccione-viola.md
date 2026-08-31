---
id: PS-057
titolo: Eliminare gli errori di fisica quando il piccione viola si sdoppia
tipo: fix
area: gameplay
stato: PRONTO
priorita: media
dipende_da: []
origine: PS-044
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-057 — Eliminare gli errori di fisica quando il piccione viola si sdoppia

## Contesto

Durante la cattura runtime di PS-044, alla prima ondata affollata con Boss in
campo, il log Windows si riempie di errori del motore:

```
ERROR: Can't change this state while flushing queries. Use call_deferred() or
set_deferred() to change monitoring state instead.
   at: body_set_shape_as_one_way_collision / area_set_shape_disabled
   [0] _make_collision_shapes_unique (res://scripts/actors/base_enemy.gd:647)
   [1] _ready (res://scripts/actors/base_enemy.gd:106)
   [2] _finalize_spawned_enemy (res://scripts/game/enemy_spawner.gd:409)
   [3] spawn_archetype_instance (res://scripts/game/enemy_spawner.gd:296)
   [4] _on_died (res://scripts/actors/splitter_enemy.gd:38)
   [5] take_damage (res://scripts/components/health_component.gd:67)
   [6] try_hit (res://scripts/combat/projectile.gd:182)
```

La catena è sempre la stessa: un proiettile uccide un piccione viola *dentro*
il flush delle query fisiche, `SplitterEnemy._on_died()` chiede subito lo spawn
dei frammenti ([scripts/actors/splitter_enemy.gd:38](../../../scripts/actors/splitter_enemy.gd#L38))
e il `_ready()` dei nuovi nemici sostituisce le `CollisionShape2D`
([scripts/actors/base_enemy.gd:643-661](../../../scripts/actors/base_enemy.gd#L643-L661))
mentre il server fisico non lo consente.

La rigenerazione completa del pacchetto di catture del 31 agosto 2026 (due
profili di viewport, `52` PNG) ha prodotto `48` righe `ERROR:` con **quattro**
firme distinte, non una sola: la radice non è solo la sostituzione delle shape,
ma tutto ciò che i frammenti fanno al server fisico nascendo dentro il flush.

| Occorrenze | Chiamata rifiutata | Frame `[0]` |
|---|---|---|
| 24 | `body_set_shape_as_one_way_collision` | `_finalize_spawned_enemy` ([enemy_spawner.gd:409](../../../scripts/game/enemy_spawner.gd#L409)), cioè l'`add_child` stesso |
| 16 | `area_set_shape_disabled` | `_make_collision_shapes_unique` ([base_enemy.gd:647](../../../scripts/actors/base_enemy.gd#L647), `654`, `661`) |
| 8 | `body_set_shape_disabled` | idem |
| 8 | `set_monitorable` | `_ready` di [contact_damage.gd:20](../../../scripts/components/contact_damage.gd#L20) e [hurtbox.gd:11](../../../scripts/components/hurtbox.gd#L11) |

L'ultima riga allarga l'ambito rispetto alla prima diagnosi: anche i componenti
`ContactDamage` e `Hurtbox` toccano il server fisico nel proprio `_ready()`.
Differire la sola sostituzione delle shape non basterebbe.

Non è un errore introdotto da PS-044: la cattura lo ha solo reso visibile,
perché ora arriva davvero a un incontro Boss con l'arena popolata. Il gioco non
crasha, ma per il contratto di onestà dei gate un log pieno di `ERROR` è un
fallimento anche con exit code `0`, e ogni nuova verifica runtime parte da un
log sporco in cui un errore vero passerebbe inosservato.

## Comportamento atteso

Uno split del piccione viola durante una collisione non produce alcun errore
del motore. I frammenti compaiono, si muovono e colpiscono esattamente come
oggi.

## Criteri di accettazione

- [ ] Una run che uccide piccioni viola con proiettili non produce righe
      `Can't change this state while flushing queries` nel log.
- [ ] Il numero, la posizione e le statistiche dei frammenti generati restano
      identici a oggi.
- [ ] Le collisioni dei frammenti restano indipendenti da quelle del genitore:
      la duplicazione delle `CircleShape2D` non viene rimossa, solo spostata in
      un momento consentito.
- [ ] La sequenza RNG di spawn resta invariata a parità di seed.
- [ ] Nessun frammento resta senza collisione attiva per più di un frame.
- [ ] Il log runtime Windows di una cattura completa non contiene righe
      `ERROR:` originate da `base_enemy.gd` o `enemy_spawner.gd`.
- [ ] Nessuna delle quattro firme registrate nel Contesto compare più:
      `body_set_shape_as_one_way_collision`, `area_set_shape_disabled`,
      `body_set_shape_disabled`, `set_monitorable`.

## Ambito

- `scripts/actors/base_enemy.gd`, `_make_collision_shapes_unique` e il punto in
  cui viene chiamata.
- `scripts/actors/splitter_enemy.gd`, `scripts/game/enemy_spawner.gd`, solo se
  lo spawn va differito.
- `scripts/components/contact_damage.gd` e `scripts/components/hurtbox.gd`,
  che nel proprio `_ready()` chiamano `set_monitorable` sullo stesso frame.

Non toccare:

- il numero di frammenti, le loro statistiche e il bilanciamento dello split;
- la sequenza RNG dello spawner;
- `RunController`, `GameDirector` e le curve di difficoltà.

## Verifica

- Smoke: `tests/unit/test_ps057_splitter_spawn_physics.gd` → marker
  `SPLITTER_SPAWN_PHYSICS_SMOKE_OK` — uccide un piccione viola durante una
  collisione e verifica che i frammenti nascano con collisioni proprie senza
  errori del motore.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows (percorso: run fino a un'ondata con piccioni viola,
      lettura del log alla ricerca di righe `ERROR:`)
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: stessa ondata, log via `adb logcat`)
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-08-31 — Card aperta da PS-044, non risolta al suo interno.** PS-044
  copre le catture UI; correggere lo spawn dei frammenti è codice di gameplay e
  merita una card e uno smoke propri.
- **2026-08-31 — L'ambito include i componenti, non solo le shape.** La
  rigenerazione completa del pacchetto ha mostrato quattro firme di errore
  distinte: `ContactDamage` e `Hurtbox` chiamano `set_monitorable` nel proprio
  `_ready()`, quindi differire la sola `_make_collision_shapes_unique` lascia
  il log sporco. La correzione deve coprire l'intero ingresso in scena del
  frammento.

## Documenti sincronizzati

- [ ] Nessuno previsto: è una correzione interna che non cambia un contratto.

## Note

La duplicazione delle shape serve a rendere indipendenti le collisioni di ogni
nemico: la soluzione non è rimuoverla, ma eseguirla quando il server fisico lo
consente (per esempio differendo lo spawn dei frammenti o la sostituzione delle
shape di un frame).
