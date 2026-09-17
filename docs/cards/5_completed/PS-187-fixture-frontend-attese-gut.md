---
id: PS-187
titolo: Centralizza le fixture frontend e rendi espliciti i timeout GUT
tipo: chore
area: tooling
stato: COMPLETATO
priorita: media
dipende_da: []
origine: Audit autonomo dei test richiesto dal proprietario
creato: 2026-09-16
aggiornato: 2026-09-17
---

# PS-187 — Centralizza le fixture frontend e rendi espliciti i timeout GUT

## Contesto

I test frontend ripetono la costruzione della stessa scena con un flag globale
di BOOT, spesso senza inizializzare viewport e seed. Ripristinano il flag a
`false` anche quando prima non esisteva. Tre helper di sblocco selezione
duplicano un ciclo senza limite; l'attesa Tween condivisa scade senza fallire.

## Comportamento atteso

Fixture con viewport e seed espliciti, impostazioni temporanee ripristinate al
valore precedente e attese UI che falliscono quando il segnale atteso manca.
Gameplay, bilanciamento e contratti delle asserzioni restano invariati.

## Criteri di accettazione

- [x] Setup frontend comune centralizzato; le configurazioni prima di `_ready`
      restano possibili senza aggiungere un framework di fixture.
- [x] Ripristino esatto del flag BOOT e seed/viewport riproducibili.
- [x] Attese di selezione e transizioni limitate, con fallimento esplicito.
- [x] Focused sui test migrati, Full e contratto del runner verdi.
- [x] Controllo negativo: un'attesa che non termina rende rosso il test.

## Ambito

`tests/unit/helpers/gameplay_test.gd`, test frontend che duplicano il setup,
test overlay con attese duplicate, mappa delle regressioni e workflow di verifica.
Nessun cambiamento al runtime, alle scene o ai dati di gioco.

## Verifica

GUT Focused sui test migrati; Full nello stesso processo, senza cache.
`tests/tooling/_milestone_runner_contract.ps1` per la mappa degli helper.

## Gate manuali

Windows runtime, APK e Pixel 9: non pertinenti per modifiche ai soli test.
Revisione completata; integrazione autorizzata dal proprietario il 2026-09-17.

## Decisioni

- **2026-09-16 — Attese valide anche in pausa.** Il tentativo iniziale con
  `GUT.wait_while` ha bloccato B11 in LEVEL_UP: il suo awaiter avanza in
  `_physics_process`, sospeso dal SceneTree. Sostituito con un piccolo
  polling sul segnale `process_frame` e deadline reale. Le due API di
  dominio aggiungono un'asserzione al timeout. Nessun cambio al framework GUT
  o al process_mode del gioco. Prova negativa di selezione bloccata in pausa
  e Tween infinito: due test su due rossi, `20260916-081312-PS-187`.
- **2026-09-16 — Estendi la fixture esistente.** Aggiunti BOOT e seed alla
  stessa API; otto script frontend migrati. La configurazione del percorso
  di persistenza touch prima di `_ready` resta esplicita, con ripristino
  esatto del flag. Nessuna factory generica o gerarchia di fixture.
- **2026-09-16 — Scarti deliberati.** Non si riscrivono test di dominio
  distinti solo per eliminare nomi ripetuti; non si sostituiscono tutte le
  verifiche di wiring con mock o confronti di sorgenti. Il valore e' nei
  contratti osservabili, nell'isolamento e nelle attese affidabili.
- **2026-09-16 — Branch indipendente.** Parte da `develop` `fff4dcb` nel
  worktree `exports/refactor-tests`; PS-185 e PS-186 sono riservati al
  precedente branch di refactoring, non integrato.

## Documenti sincronizzati

- [x] `docs/verification-workflow.md` e `tools/milestone-test-map.json`.

## Note

Relevant `20260916-011347-PS-187`: helper e 12 script consumatori verdi. Il test della fixture copre flag assente/falso/vero, seed reale della run e timeout con SceneTree in pausa. Mappa/cache/report sono completati dalla card PS-188.


Verifica finale 2026-09-16: cinque esecuzioni consecutive di Full con
-NoCache e un solo processo GUT: 150 script / 469 test verdi per esecuzione,
toolchain e project smoke verdi. Nessun SCRIPT ERROR, FATAL EXCEPTION,
SMOKE_FAIL o CONTRACT_FAIL. Log in %TEMP%/il-gioco-verification:
20260916-081407-PS-188, 20260916-081639-PS-188, 20260916-081909-PS-188,
20260916-082143-PS-188, 20260916-082416-PS-188.

Stato IN VERIFICA per la revisione del branch refactor/test-cleaning-2026-09-16.

Verifica aggiuntiva sul risultato finale del branch, dopo PS-178:
`20260916-150244-PS-188` Full senza cache, 151 script / 474 casi nello
stesso processo GUT, nessun fallimento o pending e nessun marker di errore.
Release `20260916-145813-PS-178`: 474 casi, smoke Windows e APK statico
verdi; Android fisico aperto. Le misure del lag e i relativi limiti restano
nella card PS-178, distinta dalle correzioni delle fixture e del runner.

### Chiusura e integrazione autorizzata — 2026-09-17

Revisione tecnica dei due branch completata su richiesta di merge del
proprietario. Il risultato combinato al commit `56256b5` passa **153 script /
484 casi GUT nello stesso processo**, zero fallimenti o pending, e il
contratto PowerShell del runner anche con checkout pulito. Log
`20260917-202700-PS-188` in `%TEMP%/il-gioco-verification`.
Questa evidenza chiude i gate dei test/tooling della card; i gate fisici e
il rallentamento residuo restano nelle card runtime PS-178/PS-186/PS-190 e
nel seguito PS-189. Il primo export Android combinato richiede un recupero
dell'ambiente generato, documentato in PS-186: non e' una prova Pixel.
