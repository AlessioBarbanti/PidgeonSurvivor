---
id: PS-185
titolo: Centralizza le letture della build e i filtri delle offerte upgrade
tipo: chore
area: gameplay
stato: IN CORSO
priorita: media
dipende_da: []
origine: Richiesta autonoma di code cleaning del 2026-09-15
creato: 2026-09-15
aggiornato: 2026-09-15
---

# PS-185 — Centralizza le letture della build e i filtri delle offerte upgrade

## Contesto

Pausa e terminale ricostruiscono la stessa lista di upgrade acquisiti,
attraversando servizio, registry e ranghi e duplicando ordinamento e filtro.
Il servizio ripete inoltre i filtri dei candidati nei level-up e nei bonus
di Barb: una nuova regola deve essere mantenuta in due punti.

## Comportamento atteso

Build, ordinamento, offerte, ranghi, segnali e sequenze RNG restano invariati.
UpgradeService possiede la lettura dei ranghi acquisiti e la selezione del pool;
le schermate decidono soltanto quanti elementi visualizzare e come disegnarli.

## Criteri di accettazione

- [x] Una sola API costruisce snapshot ordinati dei ranghi realmente acquisiti;
      il rango iniziale implicito non compare prima di una scelta.
- [x] Pausa mostra tutta la build, terminale al massimo tre upgrade; parità
      risolta per ID, nessuna modifica al catalogo o al layout.
- [x] Modificare lo snapshot restituito non modifica ranghi o letture successive.
- [x] Level-up e bonus Barb applicano lo stesso percorso di filtraggio, mantenendo
      stream RNG distinti, ordine dei candidati e fallback del pool saturo.
- [ ] Test mirati e Full eseguiti; eventuali fallimenti della baseline distinti.

## Ambito

UpgradeService, RunSummary, consumatori pausa/terminale, test e mappa regressioni.
Nessun bilanciamento, asset, dato serializzato o stato di RunController modificato.

## Verifica

- Test: `tests/unit/test_ps185_upgrade_queries.gd`.
- Regressioni: B10, B18G, PS-012, PS-053, PS-164; profilo finale Full.

## Gate manuali

- [ ] Runtime Windows esportato.
- [ ] Validazione statica APK corrente.
- [ ] Runtime fisico Pixel 9: upgrade, pausa/build, Barb, terminale e restart.
- Controllo percettivo dedicato: non richiesto; layout invariato.

## Decisioni

- **2026-09-15 — Ownership delle letture nel servizio.** La build è derivata
  da stato già posseduto da UpgradeService; non introduce un secondo store né
  un servizio UI. Le definizioni Resource restano condivise, i ranghi sono copie.
- **2026-09-15 — Refactoring locale del pool.** Un helper interno elimina la
  duplicazione; un nuovo sistema di estrazione sarebbe un costo senza beneficio.
- **2026-09-15 — Isolamento Git.** Branch `refactor/code-cleaning-2026-09-15`
  da `fff4dcb` (develop aggiornato), worktree `exports/refactor-cleaning`.
  La modifica preesistente PS-182 resta nel worktree originale.

## Documenti sincronizzati

- [x] `docs/ui-ux-flow.md`: lettura della build attraverso il servizio.
- [x] `tools/milestone-test-map.json`: regressioni delle letture upgrade.

## Note

- Baseline `Full -RefreshEditor -NoCache` sul codice `fff4dcb`: 148/149
  script verdi. Un test PS-158 fallisce sulla persistenza del proiettile del
  Tiratore (`test_killing_the_shooter_after_it_fires_does_not_cancel_the_projectile`),
  problema già tracciato da PS-177. Log `20260915-230503-PS-185` sotto
  `%TEMP%/il-gioco-verification`.
- Primo import del worktree: crash del motore caricando il tema con cache font
  assente. Copiati soltanto i `.fontdata` generati dal checkout originale;
  successivo refresh completato, nessun cambiamento a font o tema.
- Caratterizzazione sul codice originale: tre test RNG verdi, sequenza seed
  `18503` registrata nel test. Log `20260915-230833-PS-185`.
- Dopo il refactoring: `Relevant -FocusedSmoke tests/unit/test_ps185_upgrade_queries.gd
  -RefreshEditor -NoCache`, 67/67 step verdi (refresh, focused, 65 regressioni).
  Log `20260915-231112-PS-185`; copre snapshot isolati, rango iniziale implicito,
  restart, fallback saturazione, stream RNG indipendenti e sequenza preesistente.
- `tests/tooling/_milestone_runner_contract.ps1`: `MILESTONE_RUNNER_CONTRACT_OK`.
