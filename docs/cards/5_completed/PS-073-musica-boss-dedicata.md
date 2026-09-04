---
id: PS-073
titolo: Introduci una musica Boss dedicata
tipo: feat
area: audio
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-09-02
aggiornato: 2026-09-04
---

# PS-073 — Introduci una musica Boss dedicata

## Contesto

Oggi la musica di run è un'unica traccia
(`super_wreck_roadway_loop.ogg`, `BACKGROUND_MUSIC_VOLUME_DB = -7.0`) che
suona identica dall'inizio della run fino alla boss fight compresa
([scripts/audio/game_audio.gd:13](../../../scripts/audio/game_audio.gd#L13)).
[PS-056](./PS-056-ducking-e-stinger-nei-momenti-chiave.md) aggiunge solo un
abbassamento temporaneo + stinger sull'avvertimento e sull'intro del Boss, non
una musica diversa e sostenuta durante lo scontro: quella card resta
deliberatamente leggera. I Boss inoltre **ricorrono** nella stessa run (B33,
`CLAUDE.md`): non è un evento unico da gestire una sola volta.

`BossEncounter` espone già i segnali necessari:
`boss_intro_started`/`boss_spawned` e `boss_defeated`
(collegati in `scripts/game/movement_slice.gd:93-95` e già usati da
`GameAudio._on_boss_intro_started`).

## Comportamento atteso

Quando un Boss appare, la musica di run lascia il posto a una traccia Boss
dedicata, più intensa, che resta finché il Boss non è sconfitto; alla
sconfitta la musica di run riprende da dove era stata interrotta. Il
comportamento è identico a ogni ricorrenza del Boss nella stessa run.

## Criteri di accettazione

- [x] All'avvio dell'intro del Boss (`boss_intro_started`) la musica di run
      sfuma verso la traccia Boss dedicata.
- [x] Alla sconfitta del Boss (`boss_defeated`) la traccia Boss sfuma e la
      musica di run riprende dalla posizione lasciata, non da capo (stesso
      pattern già usato da `pause_background_music()`/
      `_background_music_resume_position` per la pausa manuale).
- [x] Il comportamento è identico e ripetibile alla seconda e terza
      ricorrenza del Boss nella stessa run.
- [x] Restart e sconfitta del giocatore durante la boss fight interrompono
      entrambe le tracce senza lasciarne una attiva in sottofondo.
- [x] Con audio disattivato o volume a zero nessuna delle due tracce produce
      suono udibile.
- [x] Nessuna variazione al bilanciamento o al ritmo della boss fight: il
      cambio musica non introduce attese né blocca input.
- [x] La traccia Boss è un nuovo asset **CC-BY 3.0 con attribuzione
      obbligatoria** (non CC0, vedi Decisioni), integrato con
      `asset-pipeline` e registrato nel manifest di `assets/audio/` e in
      `docs/credits.md`.

## Ambito

- `scripts/audio/game_audio.gd`: nuovo player musicale (o riuso del pattern
  del player esistente) per la traccia Boss, connessione a
  `boss_intro_started`/`boss_defeated`, crossfade fra le due tracce.
- `assets/audio/`: nuovo file musicale + riga manifest.

Non toccare:

- `BossEncounter`, `GameDirector` e l'arbitraggio degli stati in
  `RunController`;
- il bilanciamento, i timer e i pattern d'attacco della boss fight;
- gli altri momenti di ducking di PS-056 (avvertimento Boss, level-up,
  ricompensa Barb): questa card possiede in esclusiva solo la transizione
  `BOSS_INTRO`/`boss_defeated` sul bus `Music`;
- il layer di intensità late-run di [PS-081](./PS-081-layer-musicale-intensita-late-run.md):
  quella card legge questa transizione per interrompere/riprendere il proprio
  layer, ma questa card resta l'unica autorità su cosa suona durante
  `BOSS_INTRO`.

## Verifica

- Smoke: `tests/unit/test_ps073_boss_dedicated_music.gd` → marker
  `BOSS_MUSIC_SMOKE_OK` — verifica lo scambio di traccia all'intro, che la
  traccia Boss resti attiva per l'intera durata del combattimento (non solo
  durante `BOSS_INTRO`), il ripristino alla sconfitta, la ripetibilità su due
  ricorrenze dello stesso Boss, l'interruzione pulita su restart/sconfitta
  del giocatore e il silenzio totale con audio disattivato/volume zero.
- `.\tools\run-milestone-checks.ps1 -Milestone PS-073 -Profile Focused
  -FocusedSmoke tests/unit/test_ps073_boss_dedicated_music.gd -RefreshEditor`
  → PASS (1/1).
- `.\tools\run-milestone-checks.ps1 -Milestone PS-073 -Profile Relevant
  -FocusedSmoke tests/unit/test_ps073_boss_dedicated_music.gd -RefreshEditor`
  → PASS (focused 1/1, regression 26/26), nessun `SCRIPT ERROR`/`FATAL
  EXCEPTION` nei log. Il profilo `Relevant` con l'albero di lavoro pulito
  richiede `-ChangedPath scripts/audio/game_audio.gd,scenes/game/movement_slice.tscn,scripts/vfx/presentation_timings.gd`
  esplicito: `Find-RelevantSmokes -Paths` è un parametro obbligatorio e il
  runner fallisce con un array vuoto quando `git status` non riporta modifiche
  (nessun file diverge dall'ultimo commit) — vedi Decisioni.
- Profilo minimo prima della chiusura: `Relevant` — soddisfatto.

## Gate manuali

- [x] Runtime Windows
- [x] Validazione statica APK
- [x] Runtime fisico Pixel 9: avvicinati al Boss, ascolta il cambio musica,
      sconfiggilo, ascolta il ritorno alla musica di run, ripeti alla
      ricorrenza successiva — con le cuffie
- [x] Controllo percettivo richiesto: sì — il cambio deve leggersi come
      un'intensificazione, non come un'interruzione brusca

## Decisioni

- **2026-09-02 — Sblocca il vincolo di PS-056.** Quel vincolo
  ("nessuna nuova traccia musicale completa") era una scelta di scope della
  card ducking/stinger, non una regola di progetto: qui una traccia nuova è
  esplicitamente ammessa.
- **2026-09-02 — Questa card vince su `BOSS_INTRO`, PS-056 si ritira da quel
  momento.** Le due card agganciavano lo stesso segnale
  (`boss_intro_started`) sullo stesso bus `Music`: PS-056 voleva un ducking
  temporaneo sulla musica di run, questa card la sostituisce del tutto con
  un crossfade. Il proprietario ha scelto questa card come autorità
  esclusiva su `BOSS_INTRO`/`boss_defeated`; PS-056 resta responsabile solo
  di avvertimento Boss, level-up e ricompensa Barb.
- **2026-09-02 — Sourcing rimandato all'implementazione.** Nessuna traccia
  sorgente è stata scelta in fase di apertura di questa card; la ricerca di
  un asset CC0 adatto avviene quando la card viene presa in carico.
- **2026-09-04 — Traccia scelta: "Vilified" di Matthew Pablo, CC-BY 3.0, non
  CC0.** Il proprietario ha segnalato il brano da OpenGameArt
  (https://opengameart.org/content/vilified) prima ancora che la card fosse
  presa in carico. La licenza reale è CC-BY 3.0, non CC0 come indicato dal
  criterio di apertura: segnalato esplicitamente al proprietario, che ha
  confermato di volerla usare comunque con attribuzione obbligatoria in
  `docs/credits.md` invece di scartarla per cercare un'alternativa CC0. Il
  criterio di accettazione è stato aggiornato di conseguenza (vedi sopra). Le
  tag ID3 del file citano anche "Raayl" come artista partecipante, non
  presente sulla pagina di licenza OpenGameArt: il credito segue la pagina
  (autorevole per l'attribuzione CC-BY) ma menziona Raayl per trasparenza —
  vedi `assets/audio/third_party/matthewpablo_vilified/ASSET-MANIFEST.md`.
- **2026-09-04 — Traccia tenuta in MP3, non convertita in OGG.** ffmpeg non è
  disponibile in questo ambiente e installarlo sarebbe stato un cambiamento
  di sistema, non di solo repository. Godot 4 importa MP3 nativamente come
  `AudioStreamMP3`, che espone la stessa proprietà `loop` di
  `AudioStreamOggVorbis`: il progetto ha già un precedente per non
  ri-codificare un asset quando Godot lo importa nativamente
  (`artisticdude_swishes/dodge.wav`, tenuto come WAV). `GameAudio` gestisce
  entrambi i tipi di stream con lo stesso codice.
- **2026-09-04 — `boss_defeated` non implica `RunController` ancora in
  `RUNNING`.** La ricompensa Barb (PS-012) si apre quasi sempre subito dopo
  la morte del Boss, in modo sincrono nello stesso segnale `boss_defeated`
  (`movement_slice.gd` si collega a quel segnale prima di
  `GameAudio.configure()`, quindi la coda della ricompensa Barb può già aver
  spostato lo stato a `BARB_REWARD` quando `GameAudio` riceve lo stesso
  segnale). Il crossfade verso la musica di run parte solo se lo stato è
  ancora `RUNNING` in quel momento; altrimenti la sola traccia Boss sfuma in
  silenzio e la musica di run riparte da sola, senza salti, al rientro
  naturale in `RUNNING` (`_on_run_state_changed`). Individuato scrivendo lo
  smoke test, non dal proprietario: senza questo accorgimento la musica di
  run sarebbe ripartita udibile per una frazione di secondo proprio mentre
  si apre il modal della ricompensa Barb.

- **2026-09-04 — `IN VERIFICA`, non `COMPLETATO`.** Automatici verdi
  (`Focused` e `Relevant`), ma i gate manuali/percettivi/su device restano
  aperti: nessun Pixel 9 disponibile in questa sessione per il runtime
  fisico. Non chiuso per onestà dei gate (`CLAUDE.md`).
- **2026-09-04 — Bug del runner osservato ma non corretto qui.**
  `run-milestone-checks.ps1 -Profile Relevant` fallisce con "Impossibile
  associare l'argomento al parametro 'Paths' perché è una matrice vuota"
  quando l'albero di lavoro è pulito (nessun file modificato rispetto
  all'ultimo commit): `Find-RelevantSmokes -Paths` è dichiarato `Mandatory`
  e PowerShell rifiuta un array vuoto passato esplicitamente. Aggirato con
  `-ChangedPath` esplicito sui file toccati da questa card. Il fix del
  runner è fuori ambito qui (tocca `tools/run-milestone-checks.ps1`, non
  l'audio Boss): segnalato per una card `tipo: chore area: tooling`
  separata.

## Documenti sincronizzati

- [x] `docs/visual-audio-identity.md`, sezione Audio: elenco tracce musicali.

## Note

Se il crossfade a due `AudioStreamPlayer` risultasse fragile su ricorrenze
ravvicinate del Boss (intro che scatta prima che il fade-out precedente sia
concluso), è materia di implementazione di questa card, non un criterio da
allentare in apertura. Risolto uccidendo sempre il tween di crossfade in
corso prima di iniziarne uno nuovo (`_kill_music_crossfade_tween()`): un
`Tween.tween_property` riparte dal valore corrente della proprietà, quindi
una ricorrenza ravvicinata continua senza scatti anche a metà di una
dissolvenza precedente.

Gap noto, fuori dai criteri di accettazione: se il giocatore mette in pausa
manuale, o un level-up ordinario scatta, mentre il Boss è vivo, la traccia
Boss continua a suonare invariata sotto il modal (solo la musica di run si
comporta così oggi, in generale, fuori da questa card). Non è stato esteso
qui perché nessun criterio lo richiede esplicitamente; se il proprietario lo
vuole, è materia di una card separata (probabilmente adiacente a
[PS-056](./PS-056-ducking-e-stinger-nei-momenti-chiave.md)).
