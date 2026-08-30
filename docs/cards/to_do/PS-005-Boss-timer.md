---
id: PS-005
titolo: Annuncia l'arrivo del Boss
tipo: ux
area: gameplay
stato: PRONTO
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

* [ ] Il primo Boss diventa eleggibile a `02:00` di tempo `RUNNING`.
* [ ] A `01:45` compare l'avviso `BOSS IN ARRIVO`.
* [ ] Da `01:55` a `01:59` viene mostrato il countdown `5 → 1`.
* [ ] Il countdown utilizza il tempo di run e non il tempo reale.
* [ ] Pausa e level-up congelano il countdown.
* [ ] Riprendendo la run il countdown continua dal valore corretto.
* [ ] L'avviso non impedisce movimento, fuoco automatico o uso dell'abilità attiva.
* [ ] A `02:00` l'avviso viene rimosso prima o contestualmente all'avvio della Boss Intro.
* [ ] L'avviso non rimane visibile durante lo scontro con il Boss.
* [ ] Restart elimina completamente countdown e stato di warning.
* [ ] Il warning non viene mostrato nuovamente per la stessa soglia Boss.
* [ ] Nessun elemento dell'avviso copre XP, HP, pausa o controllo abilità.

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

* Smoke: `tests/integration/_boss_warning_smoke.gd` → marker `BOSS_WARNING_SMOKE_OK`
* Copertura minima:

  * warning a `01:45`;
  * countdown da `5` a `1`;
  * spawn a `02:00`;
  * congelamento in pausa;
  * congelamento durante level-up;
  * nessun warning duplicato;
  * cleanup al restart.
* Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

* [ ] Runtime Windows
* [ ] Validazione statica APK
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

## Documenti sincronizzati

- [ ] `prd.md`: comportamento osservabile del warning, se approvato.
- [ ] Documento di verifica dedicato, quando esistono evidenze runtime.

## Note

Obiettivo del warning:

**informazione → preparazione → Boss**

Il Boss non deve essere una sorpresa completa. Sapere che arriverà a `02:00` permette di trasformare gli ultimi secondi in una piccola fase di preparazione e rende più significativa la gestione dei cooldown.

Il warning non deve diventare una seconda Boss Intro.

Baseline iniziale:

* warning generale: `15 s`;
* countdown numerico: ultimi `5 s`;
* primo Boss: `02:00`.

Timing e presentazione restano configurabili per eventuale playtest.
