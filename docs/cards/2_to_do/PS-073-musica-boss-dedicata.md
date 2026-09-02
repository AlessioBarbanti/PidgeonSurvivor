---
id: PS-073
titolo: Introduci una musica Boss dedicata
tipo: feat
area: audio
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-09-02
aggiornato: 2026-09-02
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

- [ ] All'avvio dell'intro del Boss (`boss_intro_started`) la musica di run
      sfuma verso la traccia Boss dedicata.
- [ ] Alla sconfitta del Boss (`boss_defeated`) la traccia Boss sfuma e la
      musica di run riprende dalla posizione lasciata, non da capo (stesso
      pattern già usato da `pause_background_music()`/
      `_background_music_resume_position` per la pausa manuale).
- [ ] Il comportamento è identico e ripetibile alla seconda e terza
      ricorrenza del Boss nella stessa run.
- [ ] Restart e sconfitta del giocatore durante la boss fight interrompono
      entrambe le tracce senza lasciarne una attiva in sottofondo.
- [ ] Con audio disattivato o volume a zero nessuna delle due tracce produce
      suono udibile.
- [ ] Nessuna variazione al bilanciamento o al ritmo della boss fight: il
      cambio musica non introduce attese né blocca input.
- [ ] La traccia Boss è un nuovo asset CC0, integrato con `asset-pipeline` e
      registrato nel manifest di `assets/audio/`.

## Ambito

- `scripts/audio/game_audio.gd`: nuovo player musicale (o riuso del pattern
  del player esistente) per la traccia Boss, connessione a
  `boss_intro_started`/`boss_defeated`, crossfade fra le due tracce.
- `assets/audio/`: nuovo file musicale + riga manifest.

Non toccare:

- `BossEncounter`, `GameDirector` e l'arbitraggio degli stati in
  `RunController`;
- il bilanciamento, i timer e i pattern d'attacco della boss fight;
- `PS-056` (resta la card del ducking leggero; questa introduce la traccia
  sostenuta, sono cose diverse).

## Verifica

- Smoke: `tests/unit/test_ps073_boss_dedicated_music.gd` → marker
  `BOSS_MUSIC_SMOKE_OK` — verifica lo scambio di traccia all'intro, il
  ripristino alla sconfitta, la ripetibilità su più ricorrenze dello stesso
  Boss, l'interruzione pulita su restart/sconfitta del giocatore e il
  silenzio totale con audio disattivato.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: avvicinati al Boss, ascolta il cambio musica,
      sconfiggilo, ascolta il ritorno alla musica di run, ripeti alla
      ricorrenza successiva — con le cuffie
- [ ] Controllo percettivo richiesto: sì — il cambio deve leggersi come
      un'intensificazione, non come un'interruzione brusca

## Decisioni

- **2026-09-02 — Sblocca il vincolo di PS-056.** Quel vincolo
  ("nessuna nuova traccia musicale completa") era una scelta di scope della
  card ducking/stinger, non una regola di progetto: qui una traccia nuova è
  esplicitamente ammessa.
- **2026-09-02 — Sourcing rimandato all'implementazione.** Nessuna traccia
  sorgente è stata scelta in fase di apertura di questa card; la ricerca di
  un asset CC0 adatto avviene quando la card viene presa in carico.

## Documenti sincronizzati

- [ ] `docs/visual-audio-identity.md`, sezione Audio: elenco tracce musicali.

## Note

Se il crossfade a due `AudioStreamPlayer` risultasse fragile su ricorrenze
ravvicinate del Boss (intro che scatta prima che il fade-out precedente sia
concluso), è materia di implementazione di questa card, non un criterio da
allentare in apertura.
