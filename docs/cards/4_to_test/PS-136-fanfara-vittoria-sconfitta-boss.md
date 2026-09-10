---
id: PS-136
titolo: Aggiungi una fanfara di vittoria alla sconfitta del Boss
tipo: feat
area: audio
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-09-09
aggiornato: 2026-09-09
---

# PS-136 — Aggiungi una fanfara di vittoria alla sconfitta del Boss

## Contesto

Il segnale `boss_defeated(boss: FirstBoss)` è già dichiarato ed emesso in
[scripts/bosses/boss_encounter.gd:7](../../../scripts/bosses/boss_encounter.gd#L7)
e [scripts/bosses/boss_encounter.gd:498](../../../scripts/bosses/boss_encounter.gd#L498).
`GameAudio` lo ascolta già
([scripts/audio/game_audio.gd:180](../../../scripts/audio/game_audio.gd#L180)),
ma l'handler `_on_boss_defeated`
([scripts/audio/game_audio.gd:869-871](../../../scripts/audio/game_audio.gd#L869-L871))
oggi si limita a `end_boss_music()`, il crossfade di ritorno alla musica di
run: nessun SFX puntuale segna il momento in cui il Boss cade. `VICTORY`/
`DEFEAT` ([scripts/audio/game_audio.gd:36-37](../../../scripts/audio/game_audio.gd#L36-L37))
scattano solo a fine run, non a ogni sconfitta di un singolo Boss — e i Boss
ricorrono (`CLAUDE.md`), quindi questo cue deve poter suonare più volte in
una stessa run. [PS-075](../6_rejected/PS-075-sfx-morte-nemico.md) (SFX alla
morte dei nemici comuni) è stata scartata per rischio di rumore di fondo con
centinaia di morti a schermo, ma prevedeva esplicitamente questo caso come
non in conflitto: "la morte del Boss resta distinta... già coperta da
VICTORY o da un'eventuale fanfara Boss di un'altra card". La sconfitta di un
Boss è un evento singolo e raro per run, non ripetuto in massa: il rischio
di affaticamento uditivo di PS-075 non si applica qui.

## Comportamento atteso

Quando un Boss viene sconfitto (ogni volta, comprese le ricorrenze), chi
gioca sente un breve segnale di vittoria nella stessa famiglia sonora del
cue `LEVEL_UP` esistente (Kenney Interface Sounds, non un jingle 8-bit
melodico né una tromba orchestrale), distinto dalla musica di fine run
(`VICTORY`/`DEFEAT`) e dal crossfade musicale già esistente. Con audio
disattivato o volume a zero non si sente nulla.

## Criteri di accettazione

- [x] `GameAudio` riproduce un nuovo cue (`BOSS_VICTORY`) da
      `_on_boss_defeated`, seguendo lo stesso pattern costante-`StringName` +
      `@export var ..._stream: AudioStream` + branch in `get_stream_for_cue()`
      + `play_cue()` già usato per gli altri cue.
- [x] Il cue suona a ogni sconfitta di Boss nella stessa run, non solo alla
      prima (i Boss ricorrono, CLAUDE.md) — verificato dallo smoke su due
      ricorrenze consecutive.
- [x] Il cue è percepibilmente distinto dai cue `VICTORY`/`DEFEAT` di fine
      run e non li sostituisce né li duplica.
- [x] Il cue non interferisce con il crossfade di `end_boss_music()`: i due
      restano compatibili (bus `SFX` per il cue, bus `Music` per il
      crossfade) — `play_cue()` precede `end_boss_music()` in
      `_on_boss_defeated()`, nessuna dipendenza fra i due.
- [x] Con audio disattivato o volume a zero non è udibile alcun suono.
- [x] `has_complete_cue_set()` include il nuovo cue.
- [x] Il suono è nella stessa famiglia sonora del cue `LEVEL_UP` (Kenney
      Interface Sounds CC0, non chip-tune arcade né tromba orchestrale —
      vedi Decisioni per il cambio di direzione); nuovo asset CC0 integrato
      con riga nel manifest della sua sottocartella in
      `assets/audio/third_party/`.

## Ambito

- `scripts/audio/game_audio.gd`: nuova costante cue, nuovo `@export`
  stream, branch in `get_stream_for_cue()`, chiamata `play_cue()` in
  `_on_boss_defeated()`, inclusione in `has_complete_cue_set()`.
- `assets/audio/third_party/<fonte>/`: nuovo file audio + riga manifest.
- `scenes/game/movement_slice.tscn` (o dove `GameAudio` è istanziato): solo
  per assegnare il nuovo stream esportato, se necessario.

Non toccare:

- `boss_encounter.gd` e il segnale `boss_defeated` (già presenti e
  sufficienti);
- `end_boss_music()` e il crossfade musicale esistente;
- i cue `VICTORY`/`DEFEAT` di fine run (PS-080) e la loro musica dedicata;
- il ducking/stinger di PS-056, se non ancora implementato: questa card non
  lo presuppone né lo blocca.

## Verifica

- Smoke: `tests/unit/test_ps136_boss_victory_fanfare.gd` → marker
  `BOSS_VICTORY_FANFARE_SMOKE_OK` — verifica che `boss_defeated` produca il
  nuovo cue, che scatti anche su una seconda sconfitta nella stessa run, che
  `has_complete_cue_set()` lo includa e che con audio disattivato non ci sia
  riproduzione.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: sconfiggi un Boss (e la sua ricorrenza) con le
      cuffie
- [ ] Controllo percettivo richiesto: sì — la fanfara deve leggersi come
      "vittoria sul Boss" e non entrare in conflitto udibile con il crossfade
      verso la musica di run

## Decisioni

- **2026-09-09 — Nuovo cue, non riuso di `VICTORY`.** `VICTORY` è legato a
  fine run (PS-080); riusarlo alla sconfitta di un Boss ricorrente lo
  renderebbe fuorviante (suonerebbe "hai vinto la run" a metà run).
- **2026-09-09 — Direzione sonora cambiata due volte dopo ascolto diretto dei
  candidati.** Prima ipotesi (arcade/8-bit, jingle Kenney "Music Jingles" già
  usati per `victory.ogg`/`defeat.ogg`): 4 candidati auditionati dal
  proprietario, nessuno convincente. Seconda ipotesi (vera tromba/ottone,
  Freesound CC0): 3 candidati, scartata l'intera direzione ("usciamo
  dall'idea del trumphet, non mi piace"). Direzione finale: stessa famiglia
  sonora del cue `LEVEL_UP` esistente (Kenney Interface Sounds, non ancora
  sfruttata oltre gli 8 file già in uso in `kenney_b18/`). 4 candidati da
  quella famiglia, scelto `maximize_005.ogg` ("il fratello maggiore" di
  `level_up.ogg` = `maximize_006.ogg`).
- **2026-09-09 — Asset:** `boss_victory.ogg` = `Audio/maximize_005.ogg` dal
  pack Kenney Interface Sounds 1.0 (CC0), stessa fonte già documentata in
  [kenney_b18/ASSET-MANIFEST.md](../../../assets/audio/third_party/kenney_b18/ASSET-MANIFEST.md),
  copiato senza trasformazioni.

## Documenti sincronizzati

- [x] `docs/visual-audio-identity.md`: elenco cue aggiornato a 16 (era 15),
      `BOSS_VICTORY` documentato.

## Note

Asset cercato online (non generato): nessun coinvolgimento di ImageGen o
agenti art, è un asset audio. Il proprietario ha scelto il candidato finale
ascoltando direttamente i file via `SendUserFile`, non da una descrizione:
la resa del suono isolato è quindi già validata dal proprietario; resta
aperto solo il gate percettivo in-game (mix col crossfade musicale, timing
reale alla sconfitta) nei Gate manuali sotto.
