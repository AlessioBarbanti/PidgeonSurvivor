---
id: PS-178
titolo: Diagnostica il lag riportato al minuto 2 (coincide con l'arrivo del primo Boss)
tipo: perf
area: gameplay
stato: IN CORSO
priorita: alta
dipende_da: []
origine: test reale su Pixel 9 della v0.3.0, 2026-09-15
creato: 2026-09-15
aggiornato: 2026-09-15
---

# PS-178 — Diagnostica il lag riportato al minuto 2 (coincide con l'arrivo del primo Boss)

## Contesto

Testando la build v0.3.0 su Pixel 9, il proprietario riporta un calo di
prestazioni ("lagga") intorno al minuto 2 di run, ipotizzando "troppi
nemici forse". La soglia del primo Boss
(`GameDirectorProfile.boss_thresholds_seconds = [120.0]`,
[scripts/game/game_director_profile.gd:8](../../../scripts/game/game_director_profile.gd))
coincide esattamente con quell'istante: il calo potrebbe non essere densità
nemica ordinaria ma il costo dell'ingresso in `BOSS_INTRO` (spawn del Boss,
VFX, transizione UI, eventuale sospensione dello spawn ordinario) sommato
alla densità residua dell'onda già in corso. Non è ancora diagnosticato:
l'ipotesi del proprietario e quella del timing del Boss sono entrambe da
verificare, non assumere.

## Comportamento atteso

Nessun calo di frame percepibile intorno al minuto 2 (arrivo del primo
Boss), a parità di device, rispetto al resto della run.

## Criteri di accettazione

- [ ] Misurato (profiler Godot headless/log frame time) cosa succede nei
      2-3 secondi intorno a `t=120s`: identificata la causa reale fra
      densità nemici ordinaria, spawn/VFX del Boss, transizione
      `RunController` verso `BOSS_INTRO`, garbage collection, import
      asset a runtime, o altro. **Non raggiunto in questa sessione**:
      nessun binario Godot disponibile in questo ambiente remoto (solo
      MIME type registrati, nessun eseguibile — vedi Decisioni), quindi lo
      script di profiling creato non è stato eseguito. Fatta un'analisi
      statica del codice che restringe le ipotesi (vedi Decisioni).
- [x] Se la causa è densità nemica ordinaria non correlata al Boss,
      verificato se è una regressione recente (post PS-076/PS-123/PS-171)
      o un problema preesistente mai notato prima. Verificato per analisi
      statica che la densità ordinaria **non ha alcuna soglia o
      discontinuità a t=120s** (vedi Decisioni): non è quindi una
      regressione puntuale di quelle card, è al più un accumulo continuo
      già presente da prima.
- [ ] Frame time intorno all'arrivo del Boss riportato entro una soglia
      accettabile (da definire in base alla misura sopra) su Pixel 9. Non
      misurabile senza eseguire lo script di profiling su un runtime Godot
      reale (gate aperto, vedi Gate manuali).
- [x] Nessuna regressione sul ritmo di spawn/pressione delle card di
      bilanciamento già chiuse (PS-123, PS-157, PS-171). Nessun codice di
      gameplay toccato in questa card (solo diagnosi + nuovo script in
      `tools/`), quindi nessuna regressione possibile.

## Ambito

- `scripts/game/game_director.gd` e profilo soglie Boss, per capire cosa
  succede allo spawn ordinario nell'istante della transizione.
- Transizione `RunController` → `BOSS_INTRO`, `scripts/bosses/first_boss.gd`
  (spawn/VFX iniziali), `BossUI`.
- Strumenti di profiling (nuovo script se serve), non il bilanciamento
  HP/danno già chiuso salvo che la diagnosi lo richieda esplicitamente e lo
  motivi.

## Verifica

- Nuovo script di profiling/diagnosi in `tools/` per catturare frame time
  reale intorno a `t=120s`: creato
  [tools/_diagnose_boss_lag_ps178.gd](../../../tools/_diagnose_boss_lag_ps178.gd).
  Non è un test GUT: è uno script `SceneTree` (stesso pattern di
  `tools/_capture_boss_intro_ps176.gd`) che avvia una run headless reale
  (spawner e curva attivi, non lo stress harness B18V statico) e registra
  in un CSV il frame time per-frame (`Time.get_ticks_usec`, non il
  campionamento a 1Hz di `PerformanceMonitor`) nella finestra
  `[soglia_Boss-3s, transizione_BOSS_INTRO+3s]`, con conteggio nemici/nodi/
  draw call per riga. **Non eseguito**: nessun binario Godot in questo
  ambiente remoto (vedi Decisioni). Da eseguire su Windows con
  `godot_console --headless --path . --script tools/_diagnose_boss_lag_ps178.gd -- --run-seed=20260915`
  (vedi intestazione dello script per la sintassi PowerShell multilinea).
- Test GUT solo se la causa individuata è deterministica e riproducibile
  headless. Non applicabile finché la causa non è confermata dal profiler.
- Profilo minimo prima della chiusura: `Relevant`. Non eseguito in questa
  sessione (nessun runtime Godot disponibile).

## Gate manuali

- [ ] Runtime Windows — non eseguito: nessun binario Godot in questo
      ambiente remoto per lanciare lo script di profiling creato.
- [ ] Validazione statica APK — non richiesta per la sola diagnosi.
- [ ] Runtime fisico Pixel 9 (gate primario: il sintomo è stato riportato
      lì, non riprodotto altrove finora) — non eseguibile in questa
      sessione, nessun device collegato.
- [ ] Controllo percettivo richiesto: sì — "non lagga più" è un giudizio
      del proprietario in gioco reale, non solo un numero di frame time

## Decisioni

- **2026-09-15 — Non assumere la causa riportata dal proprietario.** "Troppi
  nemici" è un'ipotesi del proprietario, non una diagnosi: la coincidenza
  con la soglia Boss a 120s è un indizio alternativo altrettanto plausibile
  da verificare prima di agire sulla densità di spawn.
- **2026-09-15 — Nessun binario Godot disponibile in questa sessione remota.**
  Verificato con una ricerca sull'intero filesystem: solo i MIME type
  (`/usr/share/mime/application/x-godot-*`) sono presenti, nessun eseguibile
  `godot`/`godot_console`. `docs/setup.md` conferma che il runner di
  verifica (`godot_console`, PowerShell) è strumentazione Windows. Coerente
  con «Onestà dei gate»: lo script di profiling è stato scritto ma non
  eseguito, il gate resta apertamente dichiarato invece di essere aggirato
  con un'esecuzione parziale o simulata.
- **2026-09-15 — Analisi statica: la densità ordinaria non ha alcuna
  discontinuità a `t=120s`.** `EnemySpawnProfile.late_run_curve_start_seconds
  = 60.0` e `late_run_curve_full_seconds = 300.0`
  ([scripts/game/enemy_spawn_profile.gd:109-115](../../../scripts/game/enemy_spawn_profile.gd)):
  a t=120s la curva è a circa il 25% della rampa (una progressione lineare
  continua fra 60s e 300s), non un salto o una soglia. Inoltre
  `EnemySpawner._process()` interrompe lo spawn ordinario non appena
  `RunController` lascia lo stato `RUNNING`
  ([scripts/game/enemy_spawner.gd:43-46](../../../scripts/game/enemy_spawner.gd),
  `_can_run_scheduler()` richiede `is_running()`), quindi durante
  `BOSS_INTRO` lo spawn ordinario è già sospeso, non accelerato. L'ipotesi
  "troppi nemici" del proprietario non trova quindi un meccanismo di
  causa-effetto specifico legato al minuto 2: se la densità pesa, è un
  accumulo continuo indistinguibile da qualunque altro istante della run,
  non un evento puntuale a t=120s.
- **2026-09-15 — Ipotesi più forte dall'analisi statica: primo upload GPU
  della texture del Boss, non costo CPU dello spawn.** `_spawn_boss()`
  ([scripts/bosses/boss_encounter.gd:349-429](../../../scripts/bosses/boss_encounter.gd))
  è sincrono in un solo frame ma leggero (istanzia una scena, un
  `Resource.duplicate(true)` di `BossDefinition` per gli Evil, nessun I/O),
  e `BossUI.show_intro()`
  ([scripts/ui/boss_ui.gd:54-67](../../../scripts/ui/boss_ui.gd)) non anima
  nulla (nessun Tween): imposta solo `visible = true` e uno `.texture`.
  Il sospetto reale è quello `.texture`: `FriendDefinition.gameplay_idle_right`
  e il ritratto della Boss Intro sono risorse già caricate in RAM da
  `FriendRegistry` all'avvio (campo `@export`), ma un `Texture2D` viene
  caricato in VRAM da Godot solo al primo utilizzo effettivo per il
  rendering — e quella texture specifica (lo sprite di gameplay dell'amico
  come nemico Evil, o il ritratto della Boss Intro) tipicamente non è mai
  stata disegnata prima nella run. Un upload GPU di prima volta è un costo
  reale e spesso percepibile su mobile (Pixel 9), coincide esattamente con
  l'istante di comparsa del Boss indipendentemente dalla densità nemica, e
  spiegherebbe un singolo hitch percepito piuttosto che un calo sostenuto.
  **Resta un'ipotesi**, non una diagnosi confermata: nessun profiler reale
  l'ha misurata in questa sessione. Lo script creato registra
  `draw_calls`/`nodes` per frame proprio per poter distinguere in futuro
  questo caso (spike isolato al frame di transizione, densità pressoché
  invariata) da un vero accumulo di densità (frame time già alto prima
  della transizione, che resta alto anche dopo).
- **2026-09-15 — Card lasciata `IN CORSO`, non spostata in verifica.** Il
  criterio centrale (causa reale misurata con un profiler) non è
  soddisfatto: quanto raccolto è un'analisi statica che restringe le
  ipotesi, non una diagnosi confermata da dati reali. Lo strumento per
  chiuderla esiste già (`tools/_diagnose_boss_lag_ps178.gd`); manca solo
  un'esecuzione su un runtime Godot reale (Windows o, per il gate primario,
  il Pixel 9 stesso).

## Documenti sincronizzati

- [ ] `docs/systems-difficulty.md` se la causa reale tocca lo spawn
      ordinario o la soglia Boss.

## Note

Segnalato dal proprietario durante il test reale su Pixel 9 della v0.3.0,
insieme ad altri cinque problemi nella stessa sessione (PS-179..PS-183).
