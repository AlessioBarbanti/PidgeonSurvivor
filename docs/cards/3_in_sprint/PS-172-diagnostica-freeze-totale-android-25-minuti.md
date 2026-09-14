---
id: PS-172
titolo: Diagnostica il freeze totale su Android a ~25 minuti di run
tipo: chore
area: piattaforma
stato: IN CORSO
priorita: alta
dipende_da: []
origine: playtest esterno 2026-09-11 — feedback Magno
creato: 2026-09-13
aggiornato: 2026-09-13
---

# PS-172 — Diagnostica il freeze totale su Android a ~25 minuti di run

## Contesto

Magno ha segnalato che, giocando su Android, il gioco si è bloccato
completamente attorno al minuto 25 di run: schermata ferma, nessun input più
funzionante. Non è un crash (il processo non è tornato a home/desktop) né un
semplice calo di frame rate: il gioco ha smesso di rispondere. `EnemySpawner`
ha già un tetto (`spawn_profile.max_alive_enemies`) sui nemici vivi
contemporaneamente, quindi il freeze non è necessariamente spiegabile con una
crescita illimitata del conteggio nemici; restano da verificare altre
sorgenti che potrebbero accumularsi nel tempo indipendentemente da quel cap
— proiettili/telegraph dei tiratori, VFX ed eventi d'ondata, la crescita
senza tetto della pressione oltre `late_run_curve_full_seconds` (PS-126) — e
se il comportamento sia specifico di Android o riproducibile anche su
Windows.

## Comportamento atteso

La causa radice del freeze viene identificata e documentata con evidenza
reale (log/profiling), non per ipotesi. Se la correzione è piccola e sicura
viene applicata direttamente qui; se richiede un intervento più ampio o
rischioso, questa card si ferma alla diagnosi e apre una card fix dedicata
con l'evidenza raccolta.

## Criteri di accettazione

- [ ] Causa radice del freeze identificata e documentata in questa card
      (memory leak, ANR per operazione bloccante sul thread principale,
      valore non finito/overflow in una curva che cresce senza tetto,
      accumulo di nodi/segnali/timer non ripuliti, o altro), con log a
      supporto. **Non raggiunto**: nessun device Android disponibile in
      questa sessione (`adb devices` non elenca nulla). Eseguita solo
      un'analisi statica del codice (vedi Decisioni) senza log reali a
      supporto di una causa specifica.
- [ ] Riprodotto almeno un caso controllato che raggiunge o supera i 25
      minuti di tempo logico su un device Android reale, con `adb logcat`
      raccolto nella finestra del blocco. **Non eseguibile in questa
      sessione**: gate manuale, lasciato apertamente dichiarato sotto.
- [ ] Verificato e documentato se il freeze si riproduce anche su Windows con
      una run equivalente, per isolare se il problema è specifico della
      piattaforma Android o del runtime di gioco in generale. **Non
      eseguito**: richiede una run reale ≥25 minuti con input di gioco
      autentico (spawn/upgrade/wave dinamici), non riproducibile dallo stress
      harness esistente (`--b18v-soak`), che popola nemici/proiettili
      statici e non esercita spawner/curve/abilità nel tempo.
- [ ] Se la causa è isolabile con una correzione piccola e sicura, viene
      applicata in questa card e verificata con una run reale che supera i
      30 minuti senza freeze. Applicata una correzione minima e sicura per
      un difetto reale trovato durante l'audit (vedi Decisioni), ma **non è
      confermato che sia la causa del freeze segnalato** — non c'è evidenza
      che li colleghi.
- [ ] Se la causa richiede una correzione più ampia o rischiosa, viene aperta
      una card fix dedicata con l'evidenza raccolta invece di allargare
      questa diagnosi. Non applicabile: nessuna causa certa identificata da
      cui derivare una card fix mirata.
- [x] Non viene introdotta alcuna tolleranza artificiale (es. terminare la
      run forzatamente a tempo, ridurre densità/pressione "per sicurezza")
      come sostituto della diagnosi reale. Nessun bilanciamento toccato.

## Ambito

- Nessuna modifica runtime finché la causa non è identificata; solo dopo la
  diagnosi, l'eventuale fix minimo tocca il sistema realmente coinvolto.
- Sospetti principali da verificare: `scripts/game/enemy_spawner.gd` (cap
  `max_alive_enemies` e pulizia dei nemici morti), `scripts/actors/ranged_enemy.gd`
  e `scripts/bosses/boss_projectile.gd` (proiettili/telegraph non ripuliti),
  `scripts/game/wave_event_scheduler.gd` (eventi accumulati), la curva senza
  tetto di PS-126, VFX/particellari di late-run.
- Non modificare bilanciamento (HP/danno/densità) come tentativo di aggirare
  il sintomo senza averne capito la causa.

## Verifica

- GUT: `tests/unit/test_b18v_hardening_performance.gd` → nuovo
  `test_ps172_performance_monitor_caps_sample_history` → marker
  `PS172_PERFORMANCE_MONITOR_SAMPLE_CAP_SMOKE_OK`, verifica che
  `PerformanceMonitor._samples` resti limitata a `MAX_SAMPLES` anche
  guidando `_process()` manualmente ben oltre quel numero di campioni.
- Focused: 1/1 verde. Relevant: 2/2 (1 focused + 1 regressione mappata su
  `scripts/platform/performance*`), nessun `SCRIPT ERROR`/`FATAL EXCEPTION`.
  `Full` non eseguito: modifica isolata a un file di telemetria/perf, non a
  un sistema condiviso da tutta la suite.

## Gate manuali

- [ ] Runtime Windows (percorso: run equivalente ≥ 25 minuti, per verificare
      se il freeze è specifico Android) — non eseguito: richiederebbe una run
      reale interattiva ≥25 minuti, non automatizzabile con gli strumenti
      esistenti (vedi Decisioni sullo stress harness).
- [ ] Validazione statica APK: non richiesta per la sola diagnosi
- [ ] Runtime fisico Android (percorso: run reale fino ad almeno 25–30 minuti
      con `adb logcat` attivo; gate obbligatorio e non sostituibile da uno
      smoke o da un profiling desktop) — **nessun device collegato in questa
      sessione** (`adb devices` vuoto dopo l'avvio del daemon): gate lasciato
      apertamente aperto, non aggirato.
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-09-13 — Segnalazione raccolta separatamente dal resto del playtest
  del 2026-09-11.** Il finding "freeze a 25 minuti" è emerso in una
  conversazione successiva, non nella prima trascrizione; resta comunque
  evidenza dello stesso playtest esterno (Magno).
- **2026-09-13 — Diagnosi prima della correzione.** Nessun fix speculativo:
  non si tocca bilanciamento, cap di spawn o densità come tentativo di
  mascherare il sintomo prima di averne capito la causa.
- **2026-09-13 — Un device Android reale resta indispensabile.** Coerente con
  la sezione «Onestà dei gate» di `CLAUDE.md`: se il device non è disponibile
  il gate resta apertamente dichiarato, non sostituito da un'ispezione
  indiretta. Verificato con `adb devices -l`: nessun device elencato in
  questa sessione.
- **2026-09-13 — Audit statico dei sospetti elencati in Ambito: nessuna causa
  certa trovata.** Percorsi controllati riga per riga e ritenuti robusti:
  `ExperienceCurve.get_experience_required()` (il requisito è sempre `>=1`,
  quindi il ciclo `while` di `ExperienceSystem._queue_reached_levels()` non
  può girare all'infinito anche con XP accumulata enorme);
  `WaveEventScheduler` (nessun array che cresce con la durata della run, ogni
  fase si pulisce su `_end_active_event`/`_clear_active_event`);
  `Projectile.expire()`/`try_hit()` (ogni percorso — hit singolo, catena,
  perforazione, scadenza — termina con `queue_free()`, nessun nodo orfano
  trovato); `BaseEnemy._on_died()` (rimuove dal gruppo `"enemies"` e libera il
  nodo in modo sincrono, non differito); `PlatformLifecycle` (la sospensione
  input su perdita di focus/pausa di sistema è comportamento voluto — mai
  ripreso automaticamente, per design — non un deadlock).
- **2026-09-13 — Trovato e corretto un difetto reale, non confermato come
  causa del freeze segnalato.** `PerformanceMonitor._process()` gira in ogni
  build (l'overlay visivo è l'unica parte opt-in/debug, la raccolta campioni
  no) e appendeva un campione al secondo su `_samples` senza alcun tetto: su
  una run molto lunga l'array cresce senza limite, anche in produzione.
  Aggiunto `MAX_SAMPLES := 300` con lo stesso pattern già in uso in
  `CombatFeedback.max_active_effects`. Corretto perché è un difetto reale
  trovato durante l'audit richiesto da questa card, non per allargarne lo
  scopo — ma non c'è evidenza (log, profiling) che colleghi questo specifico
  difetto al freeze di Magno: la dimensione in gioco resta piccola (al più
  qualche centinaio di dizionari minuscoli) e non spiega da sola uno stallo
  totale con input non responsivo.
- **2026-09-13 — Lo stress harness esistente (`--b18v-soak`, 1200s) non è lo
  strumento giusto per riprodurre questo freeze su Windows.** Popola nemici e
  proiettili STATICI (`move_speed = 0.0`, danno da contatto disabilitato) per
  misurare il solo costo per-nodo del motore: non esercita spawner dinamico,
  curva di difficoltà, eventi d'ondata o abilità che accumulano stato nel
  tempo — cioè esattamente i sistemi sospettati. Servirebbe un harness di
  gioco reale automatizzato (bot che si muove/spara) che oggi non esiste;
  fuori scopo introdurlo in questa card di sola diagnosi.
- **2026-09-13 — Card lasciata `IN CORSO`, non spostata in verifica.** Il
  criterio centrale (causa radice identificata con evidenza reale) non è
  soddisfatto: quanto raccolto è un audit statico parziale, non una diagnosi
  conclusiva. Coerente con «un device non disponibile non blocca
  l'implementazione: lascia il gate aperto e dichiaralo» (CLAUDE.md), il
  lavoro procede su altre card invece di restare bloccato in attesa di un
  device.

## Documenti sincronizzati

- [ ] `docs/systems-difficulty.md`, solo se la diagnosi rivela un contratto di
      pulizia/lifecycle mancante da documentare (es. un tetto da introdurre
      su una curva oggi senza limite). Non applicabile: nessun contratto di
      questo tipo emerso dall'audit.

## Note

Segnalazione verbale del proprietario (2026-09-13), raccolta da conversazione
di playtest del 2026-09-11 con Magno: freeze totale (non crash, non solo
framerate basso) su Android, attorno al minuto 25 di run. Device esatto non
specificato.
