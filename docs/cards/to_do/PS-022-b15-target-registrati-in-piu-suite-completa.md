---
id: PS-022
titolo: Diagnostica i due target registrati in più di test_b15_boss_encounter
tipo: chore
area: tooling
stato: PRONTO
priorita: media
dipende_da: []
origine: PS-013
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-022 — Diagnostica i due target registrati in più di test_b15_boss_encounter

## Contesto

`tests/unit/test_b15_boss_encounter.gd::test_composed_encounter` fallisce
quando gira dentro la suite completa (65 script GUT in un solo processo) su
due conteggi del `TargetingSystem`:

- riga 107, `Targeting deve contenere Boss e nemico base`: 4 invece di 2;
- riga 160, `Il nemico base deve restare registrato fino al restart`: 3
  invece di 1.

Sempre esattamente **due bersagli registrati in più**. Lo stesso test passa
in isolamento (`Focused` sul solo file). Non è una regressione di
[PS-013](../to_test/PS-013-crash-typedarray-seconda-offerta-upgrade.md): le stesse due
asserzioni erano già fallite il 2026-08-29 alle 01:26 nello smoke legacy
equivalente `tests/integration/_boss_encounter_smoke.gd`, che girava in un
processo tutto suo (log `20260829-012625-B18M`,
`regression-_boss_encounter_smoke.log`).

La fixture disattiva `RunController._process` e `EnemySpawner._process`, ma
non tutto ciò che può registrare un bersaglio nel frattempo.

## Comportamento atteso

`test_b15_boss_encounter.gd` produce lo stesso esito in isolamento e dentro
la suite completa, e i conteggi del `TargetingSystem` riflettono solo le
entità che la fixture crea esplicitamente.

## Criteri di accettazione

- [ ] Identificato e documentato qui che cosa registra i due bersagli
      aggiuntivi (adds del Boss, spawn residuo, stato non ripulito da un test
      precedente nello stesso processo, o altro).
- [ ] `test_b15_boss_encounter.gd` passa sia in isolamento sia dentro un
      profilo `Full`, per tre esecuzioni consecutive con `-NoCache`.
- [ ] Se la causa è nella fixture, il test viene reso deterministico senza
      allentare le asserzioni sui conteggi.
- [ ] Se la causa è nel codice di gioco (registrazione doppia o mancata
      deregistrazione nel `TargetingSystem`), il problema viene descritto qui
      e spostato su una card dedicata.

## Ambito

- `tests/unit/test_b15_boss_encounter.gd`;
- in sola lettura, `scripts/game/targeting_system.gd`,
  `scripts/game/boss_encounter.gd`, `scripts/bosses/first_boss.gd` e
  `scripts/game/game_director.gd` per la diagnosi.

Non modificare come soluzione di comodo:

- non sostituire i conteggi esatti con soglie `>=` per far passare il test.

## Verifica

- Test: `tests/unit/test_b15_boss_encounter.gd`.
- Profilo minimo prima della chiusura: `Full` con `-NoCache`, ripetuto.

## Gate manuali

- [ ] Runtime Windows: non richiesto per la sola diagnosi.
- [ ] Validazione statica APK: non richiesta.
- [ ] Runtime fisico Pixel 9: non richiesto.
- [ ] Controllo percettivo richiesto: no.

## Decisioni

- **2026-08-30 — Card separata, aperta durante PS-013.** Emersa nella suite
  completa lanciata per verificare PS-013, ma indipendente da quel fix e
  precedente ad esso; allargare PS-013 avrebbe mescolato due problemi.

## Note

Evidenze:

- fallimento nella suite completa: log `20260830-133544-PS-013`,
  `gut-regression.log` righe 854-858 (159/160 test verdi, solo questo rosso);
- passaggio in isolamento lo stesso giorno: log `20260830-135304-PS-013`;
- stesso fallimento prima del fix PS-013 e prima della migrazione a GUT: log
  `20260829-012625-B18M`, `regression-_boss_encounter_smoke.log` righe 48-53.

Frequenza osservata il 2026-08-30: **un fallimento su tre** esecuzioni della
suite completa. Verde in `20260830-140828-PS-021` e in `20260830-144237-PS-023`
(69/69), rosso in `20260830-133544-PS-013`. Chi riprende la card non si aspetti
di riprodurlo al primo colpo: serve ripetere con `-NoCache`.
