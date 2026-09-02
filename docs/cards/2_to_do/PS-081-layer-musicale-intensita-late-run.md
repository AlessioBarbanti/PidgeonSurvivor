---
id: PS-081
titolo: Aggiungi un layer musicale di intensità crescente late-run
tipo: feat
area: audio
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-09-02
aggiornato: 2026-09-02
---

# PS-081 — Aggiungi un layer musicale di intensità crescente late-run

## Contesto

La curva di difficoltà ordinaria esiste già ed è dettagliata
(`data/spawn_profiles/default_enemy_spawn_profile.tres`,
`late_run_curve_start_seconds=60.0`, `late_run_curve_full_seconds=300.0`: fra
questi due istanti il peso del piccione base scende fino al `33%` e i
moltiplicatori favoriscono sciamatori, corazzati, divisori e tiratori,
`docs/systems-difficulty.md`), ma la musica di run resta piatta dall'inizio
alla fine: non comunica in alcun modo la pressione crescente che il gioco già
simula meccanicamente.

## Comportamento atteso

Fra `late_run_curve_start_seconds` e `late_run_curve_full_seconds` la musica
di run si intensifica gradualmente: un layer di tensione/percussioni si
aggiunge sopra il loop di base, sincronizzato in fase con esso, dando una
sensazione crescente di pressione coerente con la curva di difficoltà già
esistente.

## Criteri di accettazione

- [ ] Il layer di intensità è silenzioso prima di
      `late_run_curve_start_seconds`.
- [ ] Il layer cresce gradualmente, non a scatti, fra
      `late_run_curve_start_seconds` e `late_run_curve_full_seconds` fino al
      volume massimo dichiarato.
- [ ] Il layer resta sincronizzato in fase con il loop di base per tutta la
      durata, senza sfasamento percepibile, anche dopo pausa e ripresa.
- [ ] Le soglie riusano esattamente le costanti già esistenti di
      `EnemySpawnProfile` (`late_run_curve_start_seconds`/
      `late_run_curve_full_seconds`) invece di introdurne di nuove duplicate.
- [ ] Durante `BOSS_INTRO` (di competenza esclusiva di
      [PS-073](./PS-073-musica-boss-dedicata.md)) sia il loop di base sia il
      layer si interrompono insieme; al ritorno alla musica di run dopo la
      sconfitta del Boss, il layer riprende dal livello di intensità
      corretto per il tempo di run trascorso, non da zero.
- [ ] Il ducking di [PS-056](./PS-056-ducking-e-stinger-nei-momenti-chiave.md)
      (avvertimento Boss, level-up, ricompensa Barb) abbassa il loop di base
      e il layer insieme, come un'unica musica di run.
- [ ] Restart azzera il progresso dell'intensità: una nuova run riparte da
      zero indipendentemente dal punto raggiunto dalla run precedente.
- [ ] Con audio disattivato o volume a zero nessuna delle due componenti
      produce suono udibile.
- [ ] Se il sourcing di un secondo stem musicalmente compatibile con il loop
      di base (stessa tonalità, stesso tempo, stessa durata di loop) non
      risulta disponibile o non regge musicalmente all'ascolto, si passa
      esplicitamente al fallback dichiarato: 2-3 varianti della stessa
      traccia (o traccia diversa) in crossfade alle stesse soglie di tempo,
      invece del layering verticale. La scelta effettivamente fatta va
      registrata nelle Decisioni della card.

## Ambito

- `scripts/audio/game_audio.gd`: nuovo player per il layer di intensità (o
  gestione multi-stem), lettura del tempo di run corrente.
- `assets/audio/`: nuovo stem di intensità (o le varianti di fallback) +
  riga manifest.

Non toccare:

- `EnemySpawnProfile` e la curva di difficoltà ordinaria: questa card ne
  legge solo le soglie temporali già dichiarate, senza modificarle;
- `BOSS_INTRO`/`boss_defeated`, di competenza esclusiva di PS-073;
- i tre momenti di ducking di PS-056, che restano invariati nel loro
  comportamento — si limitano ad abbassare anche il nuovo layer insieme al
  loop di base, non a duplicare la logica.

## Verifica

- Smoke: `tests/unit/test_ps081_late_run_music_intensity.gd` → marker
  `LATE_RUN_MUSIC_INTENSITY_SMOKE_OK` — verifica silenzio del layer prima
  della soglia iniziale, crescita graduale fino alla soglia finale, sincronia
  di fase, ripresa corretta dopo `BOSS_INTRO`, comportamento del ducking
  sulle due componenti insieme, e reset su restart.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run di almeno 5 minuti ascoltando la
      crescita di intensità, con almeno una boss fight nel mezzo per
      verificare interruzione e ripresa corrette, con le cuffie)
- [ ] Controllo percettivo richiesto: sì — la crescita deve leggersi come
      pressione via via maggiore, non come un cambio di traccia percepibile
      a scatti

## Decisioni

- **2026-09-02 — Layering verticale come prima scelta, crossfade a stadi
  come fallback esplicito.** Il proprietario ha scelto di provare prima il
  vero layering (un secondo stem che si aggiunge sopra il loop di base);
  se il sourcing di due stem compatibili non regge musicalmente, si passa al
  crossfade a stadi già usato concettualmente da PS-073, senza che questo sia
  considerato un fallimento della card.
- **2026-09-02 — Riusa le soglie esistenti invece di duplicarle.** La curva
  di difficoltà ordinaria (`late_run_curve_start_seconds`/
  `late_run_curve_full_seconds`) è già la fonte di verità del ritmo late-run;
  introdurre soglie audio separate le farebbe divergere nel tempo.
- **2026-09-02 — Coordinamento esplicito con PS-073 e PS-056.** Nessuna
  sovrapposizione di competenza sullo stesso trigger: `BOSS_INTRO` resta
  esclusiva di PS-073, il ducking di PS-056 tratta loop e layer come
  un'unica musica di run.

## Documenti sincronizzati

- [ ] `docs/systems-difficulty.md`: nota che la dinamica audio è ora agganciata
      alla stessa curva late-run già descritta lì.
- [ ] `docs/visual-audio-identity.md`: nuovo layer musicale.

## Note

Se il layering verticale richiede un asset composto apposta (i due stem
pensati insieme, non sourciati indipendentemente), valutarlo come possibile
lavoro per `game-art-designer`/composizione dedicata invece di forzare due
tracce CC0 indipendenti a stare insieme: è preferibile il fallback a
crossfade a una sovrapposizione che suona male.
