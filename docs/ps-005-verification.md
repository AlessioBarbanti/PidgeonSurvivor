# PS-005 — Verifica warning Boss

Stato: **IN VERIFICA**

## Risultato implementato

Il primo Boss usa la soglia autorevole `02:00` di tempo `RUNNING`. Il
`GameDirector` emette un warning configurabile da `01:45`, passa al countdown
negli ultimi `5` secondi e lo rimuove quando inizia il normale flusso di Boss
Intro. Pausa, level-up e restart riusano i contratti esistenti; l'HUD osserva
lo stato senza introdurre un timer locale o un nuovo stato della run.

## Evidenza automatica

- contratto runner: `MILESTONE_RUNNER_CONTRACT_OK`;
- contratto cattura processi: `PROCESS_CAPTURE_CONTRACT_OK`;
- profilo `Focused -NoCache`: PASS sul test
  `tests/unit/test_ps005_boss_warning.gd`;
- profilo `Relevant -NoCache`: PASS sul focalizzato e su `22/22` regressioni;
- nessun `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o `CONTRACT_FAIL`.

## Evidenza di piattaforma

- export debug Windows x64 e smoke dell'eseguibile: completati;
- APK debug: `105702545` byte, SHA-256
  `729EF9617A46009F221F6E2A7D12B780683B5CA0059D8F615684798AB92EE638`;
- ispezione statica: package `com.ilgioco.pidgeonsurvivor`, min SDK `31`,
  target SDK `36`, sola ABI `arm64-v8a`, firma v2 e launcher
  `com.godot.game.GodotAppLauncher`;
- installazione `adb install -r` sul Pixel 9 `49140DLAQ0010Y`: `Success`;
- package installato: versione `0.1.0` (`versionCode=1`), ABI
  `arm64-v8a`, aggiornato il `2026-08-30 16:49:55`;
- cold launch: `Status: ok`, processo applicazione attivo e nessun crash,
  errore script o marker di fallimento nel log acquisito.

## Gate manuali aperti

- run Windows fino al primo Boss;
- run Pixel 9 fino al primo Boss;
- leggibilità di `BOSS IN ARRIVO` e del countdown durante un'orda densa;
- assenza di sovrapposizioni importanti e chiarezza della transizione verso la
  Boss Intro.

Installazione e cold launch provano il deployment, non sostituiscono questi
gate gameplay e percettivi.
