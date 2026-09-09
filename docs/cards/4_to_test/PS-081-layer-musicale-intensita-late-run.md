---
id: PS-081
titolo: Accelera la musica di run nella curva di intensità late-run
tipo: feat
area: audio
stato: IN VERIFICA
priorita: media
dipende_da: [PS-056]
origine:
creato: 2026-09-02
aggiornato: 2026-09-09
---

# PS-081 — Accelera la musica di run nella curva di intensità late-run

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
di run accelera gradualmente (velocità di riproduzione, quindi anche
l'intonazione sale con essa): stessa traccia, nessun secondo stem da
sincronizzare in fase. La sensazione di pressione crescente coincide con la
curva di difficoltà già esistente senza richiedere un nuovo asset musicale.

## Criteri di accettazione

- [x] Prima di `late_run_curve_start_seconds` la musica di run riproduce a
      velocità normale (`pitch_scale == 1.0`).
- [x] Fra `late_run_curve_start_seconds` e `late_run_curve_full_seconds` la
      velocità sale gradualmente, non a scatti, fino al valore massimo
      dichiarato in modo centralizzato (non oltre `1.0` +
      `MUSIC_LATE_RUN_MAX_PITCH_SCALE_OFFSET`).
- [x] Oltre `late_run_curve_full_seconds` la velocità resta al massimo per il
      resto della run (coerente con PS-126: la curva di difficoltà stessa non
      cresce oltre quel punto).
- [x] Le soglie riusano esattamente le costanti già esistenti di
      `EnemySpawnProfile` (`late_run_curve_start_seconds`/
      `late_run_curve_full_seconds`) invece di introdurne di nuove duplicate.
- [x] La traccia Boss dedicata (PS-073) non è mai accelerata: l'effetto
      riguarda solo la musica di run. Al ritorno dalla traccia Boss dopo la
      sconfitta, la velocità riflette subito il tempo di run già trascorso
      (deriva dal tempo corrente, non da uno stato accumulato separato).
- [x] Il ducking di [PS-056](./PS-056-ducking-e-stinger-nei-momenti-chiave.md)
      (avvertimento Boss, level-up, ricompensa Barb) continua a funzionare
      invariato: agisce sul volume, l'accelerazione su un'altra proprietà
      dello stesso player, le due non si contendono lo stato.
- [x] Restart azzera l'accelerazione: una nuova run riparte da velocità
      normale indipendentemente dal punto raggiunto dalla run precedente.
- [x] Con audio disattivato o volume a zero l'accelerazione non introduce
      alcun suono udibile (il bus resta silenzioso come oggi) — non
      retestato a parte: `pitch_scale` non introduce alcun nuovo percorso di
      riproduzione, riusa lo stesso player già coperto dal guard esistente
      sul bus `Music`.

## Ambito

- `scripts/audio/game_audio.gd`: lettura del tempo di run corrente
  (`RunController.run_time_changed`) e delle soglie da
  `_game_director.get_enemy_spawner().spawn_profile` (già disponibile da
  PS-056, nessun nuovo parametro a `configure()`), calcolo e applicazione di
  `pitch_scale` sul player della musica di run.

Non toccare:

- `EnemySpawnProfile` e la curva di difficoltà ordinaria: questa card ne
  legge solo le soglie temporali già dichiarate, senza modificarle;
- `BOSS_INTRO`/`boss_defeated`/la traccia Boss dedicata, di competenza
  esclusiva di PS-073;
- i tre momenti di ducking di PS-056, che restano invariati nel loro
  comportamento (agiscono sul volume, non sulla velocità).

## Verifica

- Smoke: `tests/unit/test_ps081_late_run_music_intensity.gd` → marker
  `LATE_RUN_MUSIC_INTENSITY_SMOKE_OK` — verifica velocità normale prima della
  soglia iniziale, crescita graduale fino al massimo alla soglia finale,
  valore mantenuto oltre la soglia finale, nessun effetto sulla traccia
  Boss, compatibilità col ducking di PS-056, e reset su restart.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run di almeno 5 minuti ascoltando
      l'accelerazione, con almeno una boss fight nel mezzo per verificare che
      la traccia Boss non acceleri e che la musica di run riprenda alla
      velocità corretta, con le cuffie)
- [ ] Controllo percettivo richiesto: sì — l'accelerazione deve leggersi come
      pressione crescente, non come un artefatto percepibile ("effetto
      scoiattolo") o un cambio di intonazione fastidioso; il valore massimo
      di `MUSIC_LATE_RUN_MAX_PITCH_SCALE_OFFSET` è tarabile dopo l'ascolto

## Decisioni

- **2026-09-09 — Dipendenza formalizzata da PS-056.** Il criterio sul ducking
  ("Il ducking di PS-056... abbassa il loop di base e il layer insieme")
  presupponeva un meccanismo che non esisteva ancora. Il proprietario ha
  scelto di bundlare le due card in sequenza (PS-056 poi PS-081) invece di
  procedere con PS-081 lasciando quel criterio non verificabile;
  `dipende_da` aggiornato di conseguenza.
- **2026-09-02 — Layering verticale come prima scelta, crossfade a stadi
  come fallback esplicito (decisione superata, vedi sotto).** Il proprietario
  aveva scelto di provare prima il vero layering (un secondo stem che si
  aggiunge sopra il loop di base); se il sourcing di due stem compatibili non
  avesse retto musicalmente, si sarebbe passati al crossfade a stadi.
- **2026-09-09 — Sostituito con l'accelerazione della traccia esistente
  (`pitch_scale`).** Il proprietario ha valutato troppo difficile trovare un
  secondo stem musicalmente compatibile (stessa tonalità/tempo) e ha scelto
  di velocizzare la musica di run stessa invece di aggiungere un layer.
  Conseguenze: nessun nuovo asset audio, nessun manifest da aggiornare,
  "Ambito" e criteri riscritti di conseguenza (non più sincronia di fase fra
  due tracce, ma un solo valore di `pitch_scale` derivato dal tempo di run).
  `MUSIC_LATE_RUN_MAX_PITCH_SCALE_OFFSET` resta un valore tarabile dopo
  l'ascolto reale, come ogni altra costante di presentazione audio.
- **2026-09-02 — Riusa le soglie esistenti invece di duplicarle.** La curva
  di difficoltà ordinaria (`late_run_curve_start_seconds`/
  `late_run_curve_full_seconds`) è già la fonte di verità del ritmo late-run;
  introdurre soglie audio separate le farebbe divergere nel tempo.
- **2026-09-02 — Coordinamento esplicito con PS-073 e PS-056.** Nessuna
  sovrapposizione di competenza sullo stesso trigger: `BOSS_INTRO` resta
  esclusiva di PS-073, il ducking di PS-056 tratta loop e layer come
  un'unica musica di run.
- **2026-09-09 — Nessun nuovo parametro a `GameAudio.configure()`.**
  `_game_director` (aggiunto da PS-056) espone già `get_enemy_spawner()`;
  questa card lo riusa per leggere `spawn_profile.late_run_curve_*` invece di
  aggiungere un riferimento diretto a `EnemySpawner`.
- **2026-09-09 — Lo smoke usa un profilo duplicato con soglie ridotte
  (10s/40s invece di 60s/300s).** Il fixture completo (`instantiate_movement_slice`)
  ha `GameDirector` realmente agganciato a `RunController.run_time_changed`:
  avanzare il clock con `controller._process()` oltre la prima soglia Boss di
  default (120s) fa scattare `BOSS_INTRO` in modo sincrono nella stessa
  emissione di segnale, bloccando `is_running()` e quindi l'avanzamento del
  tempo che lo smoke deve controllare (primo tentativo: 3 assert falliti per
  questo, non per un bug del meccanismo). Duplicare `spawn_profile`
  (`Resource.duplicate(true)`, stesso pattern di `test_ps007_late_run_pressure.gd`)
  e restringere le sole soglie late-run tiene l'intero test sotto 120s,
  isolandolo dalla schedulazione Boss senza toccare `GameDirectorProfile`.
  Il profilo originale è ripristinato in `_teardown_fixture`.

## Documenti sincronizzati

- [x] `docs/systems-difficulty.md`: nota che la dinamica audio è ora agganciata
      alla stessa curva late-run già descritta lì.
- [x] `docs/visual-audio-identity.md`: accelerazione late-run della musica di
      run.

## Note

Nessun nuovo asset audio richiesto da questa card: l'effetto usa
`AudioStreamPlayer.pitch_scale` sulla traccia già esistente
(`super_wreck_roadway_loop.ogg`).
