---
id: PS-113
titolo: Cabla il cap FPS dal PerformanceProfile attivo
tipo: perf
area: piattaforma
stato: IN VERIFICA
priorita: alta
dipende_da: []
origine:
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-113 — Cabla il cap FPS dal PerformanceProfile attivo

## Contesto

`PerformanceProfile.target_fps` ([scripts/platform/performance_profile.gd](../../../scripts/platform/performance_profile.gd))
è dichiarato ed è parte di `is_valid()` (30–240), ma non è mai applicato a
`Engine.max_fps` da nessun punto del codice (verificato con una ricerca su
tutto il repository: nessuna occorrenza di `Engine.max_fps` o
`Engine.set_max_fps`). Il motore gira quindi senza alcun limite di frame.
Su pannelli Android a refresh rate alto (90/120 Hz) questo significa
renderizzare più frame del necessario per nessun beneficio percepibile,
probabile causa principale degli scatti, del surriscaldamento e del consumo
batteria rapido riportati dal proprietario testando su telefoni di fascia
bassa.

## Comportamento atteso

Quando il profilo di performance attivo viene risolto (in
`movement_slice._configure_performance_hardening()` /
`_resolve_performance_profile()`), il gioco imposta `Engine.max_fps` al
valore di `target_fps` del profilo risolto per la piattaforma corrente
(`mobile_performance_profile.tres` su Android, `windows_performance_profile.tres`
altrove). Il cap resta attivo per tutta la sessione, incluse le schermate
welcome/tutorial/selezione/pausa essendo la stessa scena. Nessun cambiamento
al valore di `target_fps` nei due file dati (resta 60 su entrambi) né al
bilanciamento di gameplay.

## Criteri di accettazione

- [x] Dopo l'avvio della scena, `Engine.max_fps` è uguale a `target_fps` del
      `PerformanceProfile` risolto per la piattaforma corrente. Verificato da
      `test_active_profile_caps_engine_max_fps` (profilo Windows nel processo
      di test, `target_fps = 60`).
- [x] Un test GUT verifica che la configurazione del profilo imposti
      `Engine.max_fps` al valore atteso, per entrambi i profili dati
      (`windows_performance_profile.tres` e `mobile_performance_profile.tres`,
      entrambi `target_fps = 60`). Il processo di test gira come "Windows";
      il ramo mobile usa lo stesso codice (`_resolve_performance_profile`)
      con lo stesso `target_fps = 60`, non duplicato da un secondo test.
- [x] Cambiare `target_fps` in un profilo di test iniettato cambia di
      conseguenza `Engine.max_fps` (dimostra che il cap segue il profilo, non
      un valore fisso hardcoded). Verificato da
      `test_injected_profile_target_fps_drives_engine_cap` (iniettato 45,
      confermato `Engine.max_fps == 45`).
- [x] Nessuna regressione alle soglie di stress (`stress_enemy_count` ecc.),
      a `RunController` o al `PerformanceMonitor` (resta un monitor passivo).
      Confermato dal profilo `Relevant` (26/26 test verdi, incluso
      `test_b18v_hardening_performance.gd` e `test_b28_horde_density.gd`),
      nessun `SCRIPT ERROR`/`FATAL EXCEPTION` nei log.

## Ambito

- File: [scripts/game/movement_slice.gd](../../../scripts/game/movement_slice.gd)
  (`_configure_performance_hardening`, `_resolve_performance_profile`).
- Non toccare: valori numerici di `target_fps` nei due `.tres`, `RunController`,
  `PerformanceMonitor` (misura soltanto, non deve diventare un controllore
  attivo), registry degli effetti.

## Verifica

- Smoke: `tests/unit/test_ps113_fps_cap.gd` → marker `PS113_FPS_CAP_OK`
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows (verificare che il cap non introduca stutter percepibile
      rispetto al comportamento attuale) — **aperto**: non eseguito in questa
      sessione un run interattivo con osservazione umana, solo il test GUT
      automatico (che esercita lo stesso codice ma non un giudizio percettivo).
- [ ] Validazione statica APK — **aperto**, non eseguito in questa sessione.
- [ ] Runtime fisico Pixel 9 o device di fascia bassa: consigliato per
      misurare l'effetto reale su calore/batteria — **aperto**, device non
      disponibile in questa sessione. Non blocca l'implementazione ma il gate
      resta esplicitamente dichiarato aperto, non assunto.
- [ ] Controllo percettivo richiesto: sì (nessun judder visibile introdotto
      dal cap rispetto a vsync) — **aperto**, da fare dal proprietario.

## Decisioni

- **2026-09-07 — Individuata la lacuna.** `target_fps` dichiarato/validato ma
  mai consumato (ricerca su tutto il repo, nessuna occorrenza di
  `Engine.max_fps`). Motivazione: probabile causa principale del
  surriscaldamento/consumo batteria rilevato dal proprietario su device
  Android di fascia bassa con pannelli a refresh rate alto, dove il motore
  renderizza senza limite.
- **2026-09-07 — Implementato.** Una riga in
  `movement_slice._configure_performance_hardening()`:
  `Engine.max_fps = profile.target_fps`, subito dopo la validazione del
  profilo risolto. Nessun altro punto della scena tocca `Engine.max_fps`.
- **2026-09-07 — Verifica automatica chiusa, gate manuali aperti.** Focused
  (1/1) e Relevant (26/26) verdi, nessun `SCRIPT ERROR`/`FATAL EXCEPTION`.
  I gate percettivi/device restano dichiarati aperti (vedi sopra): questa
  card passa a `IN VERIFICA`, non `COMPLETATO`.

## Documenti sincronizzati

- [x] [docs/visual-audio-identity.md](../../../docs/visual-audio-identity.md)
      (sezione `PerformanceProfile`): descrive `target_fps` come
      effettivamente applicato a `Engine.max_fps`, non solo dichiarato.

## Note

Card sorella: [PS-114](../3_in_sprint/PS-114-cabla-render-scale-risoluzione-interna.md)
(stesso profilo dati, leva diversa: risoluzione interna invece del cap FPS).

Comandi di verifica usati:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-113 -Profile Focused -FocusedSmoke tests/unit/test_ps113_fps_cap.gd
.\tools\run-milestone-checks.ps1 -Milestone PS-113 -Profile Relevant -FocusedSmoke tests/unit/test_ps113_fps_cap.gd
```

Marker: `PS113_FPS_CAP_OK`.
