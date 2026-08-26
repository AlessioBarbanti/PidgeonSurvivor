# B28 — Densità orde e TTK più bullet-hell

Data: 27 agosto 2026  
Stato: `IN VERIFICA`

## Contratto implementato

- `EnemySpawnProfile`: cap `140`, intervallo `0,60 → 0,12 s`, accelerazione
  `0,003`, delay iniziale `0,50 s`.
- `BaseEnemy`: `24 HP` invece di `40`; Boss non è stato modificato da B28.
- Il profilo conserva la cadenza precedente (`1,00 → 0,25 s`, accelerazione
  `0,0025`) e scala ogni nemico ordinario con
  `1,50 × intervallo_corrente / intervallo_riferimento`: il budget XP è quindi
  il `150%` della baseline, ma resta frazionario per kill.
- `ExperienceDropper` accumula credito frazionario in XP intero, si azzera al
  restart e impedisce che un segnale `died` duplicato anticipi il budget.
- Nessun pooling introdotto: il profilo B18V mantiene stress reale sopra il cap
  B28 (`150` nemici, `200` proiettili, `200` pickup).

## Ricalibrazione XP del 27 agosto

Il feedback di gioco ha rilevato che, con l'orda B28, il level-up non teneva il
passo delle kill. `progression_experience_multiplier = 1,5` porta quindi il
budget XP ordinario al `150%` della baseline pre-B28, mantenendo l'accumulo
frazionario: cinque kill iniziali consegnano almeno `4 XP`, non cinque pickup
interi. Boss e relativo premio restano esclusi.

## Evidenza automatica

| Check | Risultato |
|---|---|
| Focused | `B28_HORDE_DENSITY_SMOKE_OK` |
| XP/spawn/level/combat dopo ricalibrazione | Verdi: `B07_EXPERIENCE_PICKUP_SMOKE_OK`, `B08_LEVEL_PROGRESSION_SMOKE_OK`, `B04_ENEMY_SPAWNER_SMOKE_OK`, `B05_COMBAT_SLICE_SMOKE_OK` |
| Regressioni B28 isolate | Verdi: spawn, combat, piccioni, XP, abilità, arena/HUD, roster, pausa, Boss, hardening B18V |
| Stress B18V | `B18V_STRESS_STARTED profile=windows duration=60.0 enemies=150 projectiles=200 pickups=200`, poi `B18V_PERFORMANCE_OK` |
| Export Windows | Verde: `godot_console --headless --path . --export-debug "Windows Desktop" exports/windows/PidgeonSurvivor.exe` |
| Runner Relevant completo | Aperto: `_ability_selection_icon_scale_smoke.gd` fallisce perché le icone abilità/passiva non sono presenti nel worktree; failure preesistente e non B28 |

## Piattaforme

- Windows runtime/profiling: aperto. Il wrapper console dell'export ha riportato
  `CreateProcess error 193`, quindi i sample senza entità non sono evidenza B28.
- Android export: aperto. Il comando Godot ha riportato `Gradle build daemon
  disappeared unexpectedly`; l'APK già presente è staticamente valido, ma questo
  non prova che sia un nuovo artefatto B28.
- APK statico presente: package `com.ilgioco.pidgeonsurvivor`, min SDK `31`,
  target SDK `36`, `arm64-v8a`, firma v2 e launcher validi.
- Pixel 9 (`49140DLAQ0010Y`): installazione, cold launch, welcome → selezione →
  run e catture a circa `00:09`/`00:37` effettuate; nessun `SCRIPT ERROR` o
  `FATAL EXCEPTION` nei log raccolti. Non è ancora una prova di frame pacing
  sostenuto a 60 FPS con densità target.

## Gate residui

1. Ottenere un export Android concluso senza daemon failure e verificare hash/
   installazione dell'artefatto corrente.
2. Profilare 60 FPS a densità B28 su runtime Windows e Pixel 9; verificare anche
   leggibilità di Player, pickup, proiettili e telegraph.
3. Risolvere o separare definitivamente il failure asset preesistente del runner
   completo prima della chiusura automatica della milestone.
