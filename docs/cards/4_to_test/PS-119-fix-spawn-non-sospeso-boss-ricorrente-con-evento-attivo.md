---
id: PS-119
titolo: Correggi lo spawn ordinario che non si sospende durante un Boss se un evento d'ondata è già maturato
tipo: fix
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: []
origine: segnalazione del proprietario 2026-09-07 (test su device, secondo Boss)
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-119 — Correggi lo spawn ordinario che non si sospende durante un Boss se un evento d'ondata è già maturato

## Contesto

Il proprietario ha segnalato, giocando su device: "durante il secondo boss,
lo spawn non si è interrotto, sono continuati ad arrivare nemici".

Contratto atteso (`docs/systems-difficulty.md:123-125`, B53): un Boss attivo
sospende sempre lo spawn ordinario
(`EnemySpawner.set_ordinary_spawn_suspended(true)`), dall'ingresso effettivo
fino alla sua uscita, per **ogni** Boss (primo o ricorrente).

Causa reale: `EnemySpawner._ordinary_spawn_suspended`
(`scripts/game/enemy_spawner.gd:33`) è un booleano condiviso, senza owner, tra
due scrittori indipendenti:

1. `scripts/game/movement_slice.gd:1982-1987` — i handler collegati ai
   segnali di `BossEncounter` (`boss_spawned`/`boss_defeated`) impostano il
   flag a `true`/`false` per la durata del Boss.
2. `scripts/game/wave_event_scheduler.gd:277-283` (`_clear_spawner_overrides`)
   — chiamata anche da `_handle_boss_active()` (righe 308-328) quando un Boss
   diventa bloccante mentre un evento d'ondata (PS-008) è già `TELEGRAPH`/
   `ACTIVE`: **azzera incondizionatamente** `set_ordinary_spawn_suspended(false)`,
   indipendentemente da chi avesse sospeso lo spawner. Se il Boss lo aveva
   appena messo a `true`, questa chiamata lo rimette a `false` mentre il Boss
   è ancora vivo, e nessun altro codice lo rimette a `true` finché il Boss
   non muore: lo spawner riprende a generare nemici a piena cadenza per tutto
   il resto del combattimento.

Perché solo il "secondo Boss" e non il primo: `WaveEventSchedulerProfile.min_start_seconds`
di default è `150s` (`docs/prd.md` / `wave_event_scheduler_profile.gd:14-15`),
mentre il primo Boss scatta a `120s` — nessun evento d'ondata può essere già
maturato a quel punto, quindi `_handle_boss_active()` trova sempre `_phase ==
IDLE` e non tocca il flag. Un Boss ricorrente (finestra
`recurring_boss_window_seconds=240s` dopo l'ultimo, tipicamente intorno a
`06:00`) arriva invece ben oltre `02:30`: a quel punto un evento d'ondata è
quasi sempre già `TELEGRAPH`/`ACTIVE`, ed è lì che il bug si manifesta. Il
primo Boss è strutturalmente immune, ma la causa non dipende dall'ordinale
del Boss: è una collisione fra due scrittori dello stesso flag, riproducibile
anche al primo Boss con un profilo diverso (vedi Verifica).

## Comportamento atteso

Lo spawn ordinario resta sospeso per l'intera durata di **ogni** Boss attivo
(primo o ricorrente), anche quando lo scheduler degli eventi d'ondata deve
interrompere un evento già maturato nello stesso momento.

## Criteri di accettazione

- [x] `WaveEventScheduler._handle_boss_active()` non riattiva mai lo spawn
      ordinario: pulisce solo gli override di propria competenza (settore,
      pesi archetipo, moltiplicatore intervallo), mai
      `ordinary_spawn_suspended`, che resta di competenza esclusiva del
      ciclo di vita del Boss (`movement_slice.gd`).
- [x] Il comportamento invariato per i percorsi normali di fine evento
      (`_end_active_event()`, `_clear_active_event()`, nessun Boss coinvolto)
      resta bit-per-bit identico: continuano a riattivare
      `ordinary_spawn_suspended` come oggi.
- [x] Nuovo test che riproduce lo scenario esatto: un evento d'ondata già
      maturato quando un Boss (sia il primo con soglia anticipata dal
      profilo di test, sia un Boss ricorrente successivo) entra in
      combattimento — `EnemySpawner.is_ordinary_spawn_suspended()` deve
      restare `true` per tutta la durata del Boss.

## Ambito

- `scripts/game/wave_event_scheduler.gd`: `_handle_boss_active()`,
  `_clear_spawner_overrides()`.
- `tests/unit/test_ps008_wave_events.gd`: rinforza
  `test_real_boss_lifecycle_interrupts_matured_event_and_postpones` con
  l'assert mancante e con un secondo giro sul Boss ricorrente.

Non toccare:

- `scripts/game/enemy_spawner.gd`: il gate (`_ordinary_spawn_suspended` in
  `_process()`) e i setter sono corretti, il problema è solo in chi li
  richiama e quando.
- `scripts/bosses/boss_encounter.gd`: emette `boss_spawned`/`boss_defeated`
  simmetricamente per ogni Boss, primo o ricorrente — nessun cambiamento
  necessario lì (verificato in indagine).
- la logica di `postpone`/`discard` degli eventi d'ondata interrotti da un
  Boss (`profile.is_postpone_policy()`), invariata.

## Verifica

- Smoke: `tests/unit/test_ps008_wave_events.gd` →
  `test_real_boss_lifecycle_interrupts_matured_event_and_postpones` (rinforzato)
  → marker esistente della suite. Verifica: dopo che lo scheduler interrompe
  un evento maturato durante l'ingresso/combattimento del Boss,
  `spawner.is_ordinary_spawn_suspended()` resta `true`; ripetuto per un
  secondo Boss (ricorrente) con un nuovo evento maturato nel frattempo, per
  riprodurre esattamente lo scenario segnalato.
- **Prova di regressione genuina**: verificato che le due nuove assert
  falliscono entrambe (2/11) ripristinando temporaneamente il codice
  pre-fix (`git stash`) e rifallendo la suite, poi ripristinato il fix e
  confermato 11/11 verde. Non solo "il test passa", ma "il test avrebbe
  intercettato il bug".
- Eseguito: Focused 1/1 PASS, Relevant 5/5 PASS (1 focused + 4 regressione:
  `test_b14_game_director.gd`, `test_b53_boss_horde_pause.gd` e le altre due
  già mappate su questo file), nessun `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Profilo minimo prima della chiusura: `Relevant`. ✅

## Gate manuali

- [ ] **Aperto** — Runtime Windows: non eseguito.
- [x] Validazione statica APK: superata dal workflow CI
      (`android-debug-release.yml`, run 34118188873, 2026-09-07) sull'APK
      contenente questo fix — `aapt2 dump badging`, `apksigner verify`,
      controllo librerie native, tutti verdi.
- [x] Runtime fisico Pixel 9: confermato dal proprietario in conversazione
      (2026-09-07) su una run reale — raggiunto un secondo Boss, spawn
      ordinario correttamente sospeso per tutto il combattimento.
- [ ] Controllo percettivo richiesto: no.

## Decisioni

- **2026-09-07 — Fix nello scheduler, non nell'EnemySpawner.** Il flag
  condiviso senza owner è la causa strutturale, ma introdurre un vero
  refcount/owner su `EnemySpawner._ordinary_spawn_suspended` per un solo
  chiamante problematico sarebbe una modifica più ampia del necessario.
  `_handle_boss_active()` è l'unico punto che clobbera il flag di un altro
  proprietario: gli si insegna a non toccare quel flag, punto. Se in futuro
  emergesse un terzo scrittore con lo stesso problema, varrà la pena
  introdurre un vero possesso del flag — non ora, per una sola collisione
  nota.
- **2026-09-07 — Nessun cambiamento a `boss_encounter.gd`/`enemy_spawner.gd`.**
  L'indagine ha escluso che la ricorrenza del Boss introduca asimmetrie: la
  sequenza di segnali `boss_spawned`/`boss_defeated` è identica per ogni
  Boss. Il "secondo Boss" del titolo del bug è solo la prima occasione
  temporale in cui il profilo di gioco reale rende probabile un evento
  d'ondata già maturato, non una causa distinta.

- **2026-09-07 — Confermato su device reale.** Il proprietario ha giocato
  una run con Lollo dopo l'aggiornamento dell'APK (release
  `android-debug-latest`, workflow run 34118188873) e ha raggiunto un
  secondo Boss: "sì" alla domanda esplicita se lo spawn si fosse fermato
  correttamente durante il combattimento. Resta aperto solo il gate Runtime
  Windows (non pertinente in pratica: la logica è identica su ogni
  piattaforma, nessun percorso Windows-specifico coinvolto, ma non
  eseguito esplicitamente in questa sessione).

## Documenti sincronizzati

- [ ] Nessuno: comportamento già documentato correttamente in
      `docs/systems-difficulty.md:123-125`; questo era un bug di
      implementazione, non un contratto da aggiornare.

## Note

Nessuna card precedente copriva questa interazione: PS-095 riguarda *dove*
spawnano i nemici (fuori campo), non *se* lo spawn deve fermarsi durante un
Boss. Individuato per la prima volta con questa segnalazione.
