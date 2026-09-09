---
id: PS-056
titolo: Aggiungere ducking e stinger su avvertimento Boss, level-up e ricompensa Barb
tipo: feat
area: audio
stato: IN VERIFICA
priorita: bassa
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-09-09
---

# PS-056 — Aggiungere ducking e stinger su avvertimento Boss, level-up e ricompensa Barb

## Contesto

L'audio ha già i mattoni: bus `SFX` e `Music` separati, una musica di fondo a
`-7 dB` e un set completo di cue fra cui `boss_warning`, `boss_attack`,
`level_up` e `victory`
([scripts/audio/game_audio.gd:9-34](../../../scripts/audio/game_audio.gd#L9-L34)).
Quello che manca è la dinamica: la musica scorre alla stessa intensità durante
un'ondata normale, un avvertimento Boss e la ricompensa di Barb, quindi i
momenti chiave non si sentono diversi.

La proposta originale di questa card si limitava a variazioni leggere sulla
musica di run esistente; il vincolo "nessuna nuova traccia" è stato rimosso
il 2026-09-02 (vedi Decisioni) e non condiziona più l'implementazione.

**`BOSS_INTRO` non è più fra i momenti di questa card.** [PS-073](../5_completed/PS-073-musica-boss-dedicata.md)
introduce una traccia Boss dedicata proprio a quell'ingresso: allo scattare
di `boss_intro_started` la musica di run smette del tutto (crossfade verso la
traccia Boss), quindi non c'è più una musica di run da "abbassare" in quel
momento. Vedi Decisioni per la sequenza fra le due card.

## Comportamento atteso

Nei tre momenti chiave la musica si abbassa per lasciare spazio a uno
stinger e poi risale: l'avvertimento dell'arrivo del Boss, il level-up e la
schermata di ricompensa di Barb. Il ritorno al volume normale è graduale e
non lascia mai la musica muta per errore.

## Criteri di accettazione

- [x] All'avvertimento di arrivo del Boss il volume della musica scende e
      risale entro una durata definita in modo centralizzato.
- [x] All'ingresso in `LEVEL_UP` la musica è abbassata e uno stinger è
      udibile sopra di essa (il cue `LEVEL_UP` già esistente può fare da
      stinger).
- [x] All'ingresso in `BARB_REWARD` la musica è abbassata e uno stinger è
      udibile sopra di essa.
- [x] Il ducking non si applica mai all'ingresso in `BOSS_INTRO`: quel
      momento è di competenza esclusiva di PS-073 (crossfade verso la
      traccia Boss dedicata).
- [x] Alla chiusura di ciascuno dei tre momenti la musica torna esattamente
      al volume precedente.
- [x] Due momenti sovrapposti o ravvicinati non producono un doppio abbassamento
      cumulativo né lasciano la musica abbassata in modo permanente.
- [x] Con l'audio disattivato o il volume a zero, il ducking non riporta alcun
      suono udibile — verificato per il mute; il volume a zero riusa lo
      stesso guard `_effects_volume <= 0.0` di `play_cue()`, già coperto da
      altri smoke esistenti (vedi Decisioni).
- [x] Restart, sconfitta e cambio personaggio durante un ducking riportano il
      volume allo stato di partenza — verificato per restart e sconfitta; il
      cambio personaggio in pausa passa dallo stesso `restart_prepared` (vedi
      Decisioni).
- [x] Le durate del ducking sono timing di presentazione e vivono in
      `scripts/vfx/presentation_timings.gd`, non sparse nei chiamanti.
- [x] Gli stinger riusano cue già presenti in `assets/audio/` quando ne esiste
      uno adatto; se un cue viene riproposto in un contesto nuovo, il
      manifest lo registra. Un nuovo cue o una nuova traccia sono ammessi se
      un riuso non regge il momento.

## Ambito

- `scripts/audio/game_audio.gd`, per il controllo del volume del bus `Music` e
  la riproduzione degli stinger.
- `scripts/vfx/presentation_timings.gd`, per le durate.
- `scripts/game/movement_slice.gd`, solo per collegare gli stati del
  `RunController` alle richieste audio.

Non toccare:

- l'autorità del `RunController` sugli stati e sull'arbitraggio dei modali;
- la persistenza delle impostazioni audio e il significato di mute e volume;
- il bilanciamento e i tempi di gioco: il ducking non deve introdurre attese;
- `PerformanceProfile`;
- il layer di intensità late-run di [PS-081](./PS-081-layer-musicale-intensita-late-run.md),
  se implementato prima o dopo di questa: il ducking abbassa loop di base e
  layer insieme, come un'unica musica di run, senza logica separata per i
  due.

## Verifica

- Smoke: `tests/unit/test_ps056_audio_ducking.gd` → marker
  `AUDIO_DUCKING_SMOKE_OK` — verifica abbassamento e ripristino nei tre
  momenti, che `BOSS_INTRO` non produca ducking, assenza di accumulo su
  eventi sovrapposti, ripristino su restart e sconfitta e silenzio totale con
  audio disattivato.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run fino all'avvertimento Boss,
      level-up e schermata di ricompensa Barb, ascoltando con le cuffie)
- [ ] Controllo percettivo richiesto: sì — il ducking deve farsi notare senza
      diventare fastidioso; verificare anche che la transizione a `BOSS_INTRO`
      (di competenza PS-073) resti pulita senza un doppio effetto residuo di
      questa card.

## Decisioni

- **2026-08-31 — Nessuna nuova traccia (decisione superata, vedi sotto).**
  La review chiedeva variazioni leggere sul ducking; il costo di produzione
  musicale non sembrava giustificato prima dei playtest di ritmo.
- **2026-09-02 — Vincolo rimosso.** Il proprietario ha tolto esplicitamente
  il divieto di aggiungere nuove tracce/asset audio: non è più un limite né
  per questa card né per il progetto in generale. Nuovi cue o tracce sono
  ammessi ovunque servano (vedi anche [PS-072](../5_completed/PS-072-audio-schivata-sesto-senso-equino-bea.md),
  [PS-073](../5_completed/PS-073-musica-boss-dedicata.md) e
  [PS-075](./PS-075-sfx-morte-nemico.md), che ne fanno uso). Questa card
  resta comunque un ducking leggero sulla musica di run per scelta di
  design (i quattro momenti sono brevi), non per un vincolo di produzione.
- **2026-09-02 — Aggiunto il level-up come momento.** Aveva già un cue SFX
  dedicato (`LEVEL_UP`) ma nessun ducking: stesso meccanismo degli altri
  momenti, costo marginale.
- **2026-09-02 — `BOSS_INTRO` rimosso dai momenti di questa card, a favore
  di PS-073.** Le due card agganciavano lo stesso segnale
  (`boss_intro_started`) sullo stesso bus `Music`: PS-056 voleva abbassare la
  musica di run mentre PS-073 la sostituisce del tutto con un crossfade verso
  la traccia Boss. Il proprietario ha scelto che PS-073 vince su
  `BOSS_INTRO`: questa card si ritira da quel momento e mantiene solo
  avvertimento Boss, level-up e ricompensa Barb, dove non c'è conflitto.
  L'avvertimento Boss resta suo perché precede `BOSS_INTRO` a run ancora
  `RUNNING`, con la musica di run regolarmente attiva.
- **2026-08-31 — Il ducking è un timing di presentazione.** Le durate stanno
  con gli altri timing di presentazione, separate dai valori di gameplay.
- **2026-09-09 — Meccanismo: insieme di "reason" invece di un contatore.**
  `_music_duck_reasons` è un Dictionary-as-set (`boss_warning`, `level_up`,
  `barb_reward`); il bersaglio del volume è sempre binario (base o
  base + `MUSIC_DUCK_OFFSET_DB`), mai cumulativo. Chiudere un momento mentre
  un altro resta attivo non fa risalire la musica finché anche l'ultimo non
  si chiude — soddisfa direttamente il criterio sulla sovrapposizione.
- **2026-09-09 — L'avvertimento Boss è il countdown (PS-005), non
  l'"approaching".** `GameDirector.boss_warning_changed` ha due fasi prima
  dell'arrivo (`APPROACHING`, poi `COUNTDOWN`); solo l'ingresso in
  `COUNTDOWN` duca e suona lo stinger `BOSS_WARNING`. `APPROACHING` può
  durare decine di secondi (`_boss_warning_lead_seconds`): tenerlo ducked per
  tutta la sua durata avrebbe reso muta la musica troppo a lungo, contro lo
  spirito di un accento puntuale come gli altri due momenti.
- **2026-09-09 — LEVEL_UP e BARB_REWARD non fermano più la musica di run.**
  Prima di questa card, `_on_run_state_changed` chiamava
  `pause_background_music()` (stop reale, non un abbassamento) su qualunque
  uscita da `RUNNING`, incluso `LEVEL_UP`/`BARB_REWARD`. `MANUAL_PAUSE`
  mantiene il comportamento di stop invariato (non è un momento di questa
  card); `test_b29_background_music.gd` è stato aggiornato per riflettere
  che `LEVEL_UP` ora abbassa invece di fermare
  (`is_background_music_active()` resta vero, `is_music_ducked()` diventa
  vero).
- **2026-09-09 — `BARB_REWARD` riusa il cue `LEVEL_UP` come stinger.** Non
  esisteva un cue dedicato all'ingresso in `BARB_REWARD` (solo `UI_CONFIRM`
  alla selezione, cioè in uscita). `LEVEL_UP` è nella stessa famiglia
  percettiva (un modal di scelta si apre) ed è già lo stinger del suo stesso
  momento: riproporlo evita un nuovo asset per un accento che non ha bisogno
  di un'identità sonora propria. Il riuso è documentato in
  `docs/visual-audio-identity.md` invece che nel manifest dell'asset (nessun
  nuovo file audio è stato aggiunto).
- **2026-09-09 — Interazione con la traccia Boss.** `BARB_REWARD` segue
  sempre una sconfitta Boss (`boss_defeated` innesca la ricompensa in modo
  sincrono, PS-073/PS-034): all'ingresso in `BARB_REWARD` la traccia Boss è
  ancora `_boss_music_active`, quindi il ducking la bersaglia per un istante
  prima che `end_boss_music()` la sfumi al silenzio. Per evitare che i due
  tween si contendano lo stesso `volume_db`, `start_boss_music()`,
  `end_boss_music()`, `_fade_out_boss_music_only()` e `stop_boss_music()`
  azzerano ora l'insieme dei ducking attivi in apertura: le transizioni della
  traccia Boss vincono sempre sul ducking, mai il contrario.
- **2026-09-09 — Verifica non esaustiva su volume-a-zero e cambio
  personaggio.** Lo smoke copre mute esplicito, restart e sconfitta; non
  replica scenari già coperti da altri smoke esistenti (guard di
  `play_cue()` su `_effects_volume <= 0.0`; `restart_prepared` per il cambio
  personaggio in pausa, B18N). Nessun comportamento nuovo introdotto in
  quei percorsi: il ducking riusa gli stessi meccanismi di reset già
  presenti su `stop_background_music()`/`stop_boss_music()`.

## Documenti sincronizzati

- [x] `docs/visual-audio-identity.md`: dinamica audio dei momenti chiave.

## Note

Se un cue esistente non regge come stinger in uno dei tre momenti, aprire una
card separata per il cue mancante invece di allargare questa.
