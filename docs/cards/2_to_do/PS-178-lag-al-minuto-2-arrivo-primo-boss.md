---
id: PS-178
titolo: Diagnostica il lag riportato al minuto 2 (coincide con l'arrivo del primo Boss)
tipo: perf
area: gameplay
stato: PRONTO
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
      asset a runtime, o altro.
- [ ] Se la causa è densità nemica ordinaria non correlata al Boss,
      verificato se è una regressione recente (post PS-076/PS-123/PS-171)
      o un problema preesistente mai notato prima.
- [ ] Frame time intorno all'arrivo del Boss riportato entro una soglia
      accettabile (da definire in base alla misura sopra) su Pixel 9.
- [ ] Nessuna regressione sul ritmo di spawn/pressione delle card di
      bilanciamento già chiuse (PS-123, PS-157, PS-171).

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
  reale intorno a `t=120s`.
- Test GUT solo se la causa individuata è deterministica e riproducibile
  headless.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (gate primario: il sintomo è stato riportato
      lì, non riprodotto altrove finora)
- [ ] Controllo percettivo richiesto: sì — "non lagga più" è un giudizio
      del proprietario in gioco reale, non solo un numero di frame time

## Decisioni

- **2026-09-15 — Non assumere la causa riportata dal proprietario.** "Troppi
  nemici" è un'ipotesi del proprietario, non una diagnosi: la coincidenza
  con la soglia Boss a 120s è un indizio alternativo altrettanto plausibile
  da verificare prima di agire sulla densità di spawn.

## Documenti sincronizzati

- [ ] `docs/systems-difficulty.md` se la causa reale tocca lo spawn
      ordinario o la soglia Boss.

## Note

Segnalato dal proprietario durante il test reale su Pixel 9 della v0.3.0,
insieme ad altri cinque problemi nella stessa sessione (PS-179..PS-183).
