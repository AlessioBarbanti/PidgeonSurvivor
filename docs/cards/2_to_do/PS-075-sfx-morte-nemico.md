---
id: PS-075
titolo: Aggiungi un SFX alla morte dei nemici
tipo: feat
area: audio
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-09-02
aggiornato: 2026-09-02
---

# PS-075 — Aggiungi un SFX alla morte dei nemici

## Contesto

`BaseEnemy` espone già `signal died(enemy: BaseEnemy)`
([scripts/actors/base_enemy.gd:6](../../../scripts/actors/base_enemy.gd#L6)),
ascoltato da `ExperienceDropper`, `HealthPickupDropper` e da
`CombatFeedback` per il VFX `DEATH_BURST`
([scripts/vfx/combat_feedback.gd:144-157](../../../scripts/vfx/combat_feedback.gd#L144-L157),
che si aggancia per-nemico quando compare). `GameAudio` non lo ascolta mai:
l'unico feedback sonoro sul combattimento resta `HIT` all'impatto del
proiettile ([scripts/audio/game_audio.gd:557-558](../../../scripts/audio/game_audio.gd#L557-L558)).
La morte del nemico in sé — il momento che dovrebbe dare la sensazione della
"uccisione" — è muta.

## Comportamento atteso

Quando un nemico muore (morte diretta o come frammento del divisore) si sente
un cue distinto da `HIT`, riconoscibile come "kill" e non come "impatto".
Durante un'ondata o uno split con molte morti ravvicinate il suono resta
leggibile invece di sommarsi in un rumore indistinto.

## Criteri di accettazione

- [ ] `GameAudio` riproduce un nuovo cue `ENEMY_DEFEATED` (o nome equivalente)
      alla morte di ciascun nemico, seguendo lo stesso pattern di aggancio
      per-nemico già usato da `CombatFeedback._track_enemy()` (via il segnale
      `enemy_spawned` dello spawner).
- [ ] Il cue è percepibilmente distinto da `HIT` e da `PICKUP`.
- [ ] Molte morti ravvicinate (ondata, split del piccione viola, area del
      Boss) non producono accumulo o distorsione: rispetta un limite di
      frequenza/polifonia, come già fatto per `SHOT`/`HIT` con
      `minimum_interval_msec`.
- [ ] La morte del Boss resta distinta e non riusa questo cue (già coperta da
      `VICTORY` o da un'eventuale fanfara Boss di un'altra card: nessun
      conflitto, non implementazione di quella parte qui).
- [ ] Con audio disattivato o volume a zero non è udibile alcun suono.
- [ ] `has_complete_cue_set()` include il nuovo cue.
- [ ] Il cue riusa uno stream CC0 già presente in `assets/audio/` se
      adeguato; altrimenti ne integra uno nuovo con riga nel manifest.

## Ambito

- `scripts/audio/game_audio.gd`: nuovo cue, nuova dipendenza da
  `EnemySpawner` in `configure()` (per agganciarsi a `enemy_spawned` come fa
  `CombatFeedback`), gestione del limite di frequenza.
- `scripts/game/movement_slice.gd`: solo per passare `EnemySpawner` a
  `GameAudio.configure()`.
- `assets/audio/`, solo se serve un nuovo stream: nuovo file + riga manifest.

Non toccare:

- `HealthComponent`, `BaseEnemy`, `ContactDamage` (logica di danno/morte);
- `CombatFeedback` e il VFX `DEATH_BURST` esistente;
- bilanciamento e conteggio nemici, `EnemySpawnProfile`.

## Verifica

- Smoke: `tests/unit/test_ps075_enemy_death_audio.gd` → marker
  `ENEMY_DEATH_AUDIO_SMOKE_OK` — verifica che la morte di un nemico produca
  il cue, che morti multiple ravvicinate rispettino il limite di frequenza,
  che la morte del Boss non lo riusi e che con audio disattivato non ci sia
  riproduzione.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: gioca fino a un'ondata affollata e a uno split
      del piccione viola, con le cuffie
- [ ] Controllo percettivo richiesto: sì — non deve diventare fastidioso o
      confuso durante le orde

## Decisioni

- **2026-09-02 — Distinto da `HIT`.** `HIT` resta il feedback dell'impatto;
  questo cue è specificamente il feedback della morte, altrimenti i due
  eventi restano indistinguibili all'orecchio.
- **2026-09-02 — Nuovo asset ammesso.** Coerente con lo sblocco generale sui
  nuovi asset audio deciso dal proprietario.

## Documenti sincronizzati

- [ ] `docs/visual-audio-identity.md`: elenco cue completo.

## Note

Se il limite di frequenza necessario per non affaticare l'orecchio durante le
orde risultasse in conflitto con la leggibilità delle morti singole fuori
ondata, è materia di implementazione di questa card, non un criterio da
allentare in apertura.
