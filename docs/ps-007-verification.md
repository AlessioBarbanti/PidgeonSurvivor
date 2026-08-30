# PS-007 — Verifica pressione late-run

Stato: **IN VERIFICA**

## Risultato implementato

La progressione ordinaria non si appiattisce piu' quando l'intervallo di spawn
raggiunge il minimo. `EnemySpawnProfile` espone una curva qualitativa data-driven
fra `01:00` e `05:00`: riduce il peso relativo del nemico base, applica i
moltiplicatori late-run dichiarati dagli archetipi e aumenta la probabilita' di
pressione da piu' settori. Non modifica HP, danno, statistiche del Player,
targeting o powerup.

Da `03:00`, `EnemySpawner` garantisce il tiratore al prossimo spawn eleggibile
quando ne manca uno da almeno `4 s`. La scelta usa lo stesso RNG della run e non
introduce uno scheduler a tempo parete. Pausa, `LEVEL_UP`, `BOSS_INTRO` e restart
restano governati da `RunController`.

Con i valori correnti, a `03:00` i pesi effettivi sono circa `3,99` base,
`2,24` sciamatore, `1,08` corazzato, `1,30` divisore e `2,10` tiratore. A
`05:00` diventano `1,98`, `3,08`, `1,26`, `1,60` e `3,00`: la composizione
continua quindi a evolvere dopo la soglia AFK senza gonfiare gli HP.

## Scenario AFK automatico

- seed: `1707`;
- tempo logico: `03:00`;
- Player fermo;
- tiratore a `320` unita' dalla posizione del Player;
- cooldown `2,2 s`, telegraph `0,6 s`, viaggio `1,6 s` a velocita' `200`;
- minaccia alla posizione del Player in circa `4,4 s`, entro la finestra di
  `10 s`.

Il test dedicato e'
[`tests/unit/test_ps007_late_run_pressure.gd`](../tests/unit/test_ps007_late_run_pressure.gd)
e stampa `LATE_RUN_PRESSURE_SMOKE_OK`. Copre anche curva iniziale invariata,
vantaggio del danno piu' alto, piu' tipologie contemporanee, determinismo,
freeze dei modali e reset.

## Evidenza automatica

- refresh editor Godot 4.7.1: superato;
- profilo `Focused -NoCache`: `3/3` test, marker
  `LATE_RUN_PRESSURE_SMOKE_OK`, nessun marker di errore;
- profilo `Relevant -NoCache`: Focused `3/3`, regressioni `28/28` suite
  (`72/72` test), `29/29` step complessivi, nessun marker di errore;
- contratto tooling: `MILESTONE_RUNNER_CONTRACT_OK`.

## Evidenza di piattaforma

- export debug Windows: completato;
- smoke dell'eseguibile Windows x64: `SMOKE_OK`, contratti `B03`-`B18W`,
  `B18V` e `B54` verdi, nessun marker di errore;
- APK debug: `105702545` byte, SHA-256
  `729EF9617A46009F221F6E2A7D12B780683B5CA0059D8F615684798AB92EE638`;
- ispezione statica APK: `ANDROID_STATIC_VALID`, package
  `com.ilgioco.pidgeonsurvivor`, min SDK `31`, target SDK `36`, sola ABI
  `arm64-v8a`, firma v2 valida, launcher
  `com.godot.game.GodotAppLauncher`, nessun permesso inatteso;
- installazione `adb install -r` sul Pixel 9 `49140DLAQ0010Y`: `Success`;
- package installato: versione `0.1.0` (`versionCode=1`), ABI
  `arm64-v8a`, aggiornato il `2026-08-30 16:49:55`;
- cold launch tramite `com.godot.game.GodotAppLauncher`: `Status: ok`, processo
  applicazione attivo e nessun crash, errore script o marker di fallimento nel
  log acquisito.

## Relazione con PS-008

PS-007 possiede la curva ordinaria e il criterio AFK. PS-008 aggiungera' eventi
riconoscibili e finiti sopra gli stessi pesi e settori effettivi; non deve
duplicare la curva, e la sua chiusura non sostituisce il playtest AFK.

## Gate manuali aperti

- runtime Windows oltre `03:00` con build offensiva forte;
- run fisica Pixel 9 oltre `03:00` (installazione e cold launch sono verdi);
- confronto fermo per `10 s` / movimento attivo nella stessa situazione;
- percezione di potenza della build e leggibilita' degli archetipi nelle orde
  dense.
