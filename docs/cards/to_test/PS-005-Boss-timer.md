---
id: PS-005
titolo: Annuncia l'arrivo del Boss
tipo: ux
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-005 — Annuncia l'arrivo del Boss

## Contesto

Il primo Boss deve arrivare a `02:00` di tempo di run.

Il giocatore deve sapere in anticipo che il Boss sta per comparire, così può decidere se conservare l'abilità attiva, cercare una posizione migliore o prepararsi allo scontro.

L'attuale Boss Intro comunica il Boss quando l'incontro è già iniziato; serve quindi un tell precedente che non interrompa il gameplay.

## Comportamento atteso

Il primo Boss viene schedulato a:

`02:00`

Negli ultimi secondi prima dello spawn compare un avviso visivo all'interno dell'HUD.

Baseline:

* da `01:45` compare **BOSS IN ARRIVO**;
* negli ultimi `5` secondi viene mostrato un countdown:

  * `BOSS IN 5`
  * `BOSS IN 4`
  * `BOSS IN 3`
  * `BOSS IN 2`
  * `BOSS IN 1`
* a `02:00` l'avviso scompare e parte il normale flusso di Boss Intro.

L'avviso:

* non mette in pausa la run;
* non blocca movimento, sparo o abilità;
* non modifica la velocità del gioco;
* usa esclusivamente il clock `RUNNING`;
* deve essere chiaramente distinguibile dal timer normale senza coprire il gameplay.

Il preavviso deve permettere al giocatore di comprendere che lo scontro è imminente senza obbligarlo a leggere continuamente il cronometro.

## Criteri di accettazione

* [x] Il primo Boss diventa eleggibile a `02:00` di tempo `RUNNING`.
* [x] A `01:45` compare l'avviso `BOSS IN ARRIVO`.
* [x] Da `01:55` a `01:59` viene mostrato il countdown `5 → 1`.
* [x] Il countdown utilizza il tempo di run e non il tempo reale.
* [x] Pausa e level-up congelano il countdown.
* [x] Riprendendo la run il countdown continua dal valore corretto.
* [x] L'avviso non impedisce movimento, fuoco automatico o uso dell'abilità attiva.
* [x] A `02:00` l'avviso viene rimosso prima o contestualmente all'avvio della Boss Intro.
* [x] L'avviso non rimane visibile durante lo scontro con il Boss.
* [x] Restart elimina completamente countdown e stato di warning.
* [x] Il warning non viene mostrato nuovamente per la stessa soglia Boss.
* [x] Nessun elemento dell'avviso copre XP, HP, pausa o controllo abilità.

## Ambito

Sistemi attesi:

* scheduler del primo Boss;
* HUD;
* stato di preavviso Boss;
* clock `RUNNING`;
* cleanup su restart.

Non modificare:

* contenuto della Boss Intro;
* pattern e statistiche dei Boss;
* selezione del Boss/Evil;
* Signature Ability degli Evil;
* regole generali di pausa;
* comportamento delle abilità del Player.

Il warning è esclusivamente informativo e non deve introdurre uno stato aggiuntivo del `RunController`.

## Verifica

* GUT focalizzato: `tests/unit/test_ps005_boss_warning.gd`.
* Copertura minima:

  * warning a `01:45`;
  * countdown da `5` a `1`;
  * spawn a `02:00`;
  * congelamento in pausa;
  * congelamento durante level-up;
  * nessun warning duplicato;
  * cleanup al restart.
* Profilo minimo prima della chiusura: `Relevant`

### Evidenza automatica — 2026-08-30

* contratto runner: `MILESTONE_RUNNER_CONTRACT_OK`;
* contratto cattura processi: `PROCESS_CAPTURE_CONTRACT_OK`;
* profilo `Focused -NoCache`: PASS sul test PS-005;
* profilo `Relevant -NoCache`: PASS sul focalizzato e su `22/22` regressioni;
* nessun `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o `CONTRACT_FAIL`.

### Evidenza di piattaforma — 2026-08-30

* export debug Windows x64 e smoke dell'eseguibile: completati;
* APK debug: `105702545` byte, SHA-256
  `729EF9617A46009F221F6E2A7D12B780683B5CA0059D8F615684798AB92EE638`;
* ispezione statica: package `com.ilgioco.pidgeonsurvivor`, min SDK `31`,
  target SDK `36`, sola ABI `arm64-v8a`, firma v2 e launcher
  `com.godot.game.GodotAppLauncher`;
* installazione `adb install -r` sul Pixel 9 `49140DLAQ0010Y`: `Success`;
* package installato: versione `0.1.0` (`versionCode=1`), ABI
  `arm64-v8a`, aggiornato il `2026-08-30 16:49:55`;
* cold launch: `Status: ok`, processo applicazione attivo e nessun crash,
  errore script o marker di fallimento nel log acquisito.

Installazione e cold launch provano il deployment, non sostituiscono la run
fino al Boss o i gate percettivi elencati sotto.

## Gate manuali

* [ ] Runtime Windows
* [x] Validazione statica APK
* [ ] Runtime fisico Pixel 9: run completa fino al primo Boss
* [ ] Controllo percettivo richiesto: sì
* [ ] `BOSS IN ARRIVO` è leggibile senza distogliere eccessivamente l'attenzione dal combattimento.
* [ ] Il countdown `5 → 1` è percepibile durante un'orda densa.
* [ ] L'avviso non copre telegraph, nemici o proiettili importanti.
* [ ] Il giocatore ha materialmente il tempo di decidere se conservare l'abilità attiva per il Boss.
* [ ] La transizione tra countdown e Boss Intro risulta chiara e senza duplicazioni visive.

## Decisioni

- **2026-08-30 — Warning non bloccante nell'HUD.** L'annuncio prepara il
  giocatore senza diventare una seconda Boss Intro o fermare la run.
- **Baseline da playtest — 15 secondi di preavviso e countdown finale di 5.**
  I valori restano configurabili e seguono lo scheduler Boss autorevole.
- **2026-08-30 — Stato nel Director, presentazione nell'HUD.** Il
  `GameDirector` deriva il warning dalle soglie configurate e dal clock
  `RUNNING`; l'HUD osserva soltanto fase e secondi residui, senza introdurre un
  nuovo stato del `RunController` o un timer locale.

## Documenti sincronizzati

- [x] `prd.md`: soglia, comportamento osservabile e clock del warning.

## Note

Obiettivo del warning:

**informazione → preparazione → Boss**

Il Boss non deve essere una sorpresa completa. Sapere che arriverà a `02:00` permette di trasformare gli ultimi secondi in una piccola fase di preparazione e rende più significativa la gestione dei cooldown.

Il warning non deve diventare una seconda Boss Intro.

Baseline iniziale:

* warning generale: `15 s`;
* countdown numerico: ultimi `5 s`;
* primo Boss: `02:00`.

Timing e presentazione restano configurabili per eventuale playtest. Restano
aperti la run manuale Windows, la run Pixel fino al primo Boss e la valutazione
percettiva durante un'orda densa; per questo la card è `IN VERIFICA` e non
`COMPLETATO`.
