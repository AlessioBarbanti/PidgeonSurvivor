---
id: PS-190
titolo: Centralizza le letture della build e i filtri delle offerte upgrade
tipo: chore
area: gameplay
stato: COMPLETATO
priorita: media
dipende_da: []
origine: Richiesta autonoma di code cleaning del 2026-09-15
creato: 2026-09-15
aggiornato: 2026-09-19
---

# PS-190 — Centralizza le letture della build e i filtri delle offerte upgrade

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
- [x] Test mirati e Full eseguiti; eventuali fallimenti della baseline distinti.

## Ambito

UpgradeService, RunSummary, consumatori pausa/terminale, test e mappa regressioni.
Nessun bilanciamento, asset, dato serializzato o stato di RunController modificato.

## Verifica

- Test: `tests/unit/test_ps190_upgrade_queries.gd`.
- Regressioni: B10, B18G, PS-012, PS-053, PS-164; profilo finale Full.

## Gate manuali

- [x] Runtime Windows esportato: export e smoke automatico di avvio.
- [x] Validazione statica APK corrente.
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
- 2026-09-19: chiusa dal proprietario con il passaggio in blocco di tutte le card `IN VERIFICA` a `COMPLETATO`.

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
- Dopo il refactoring: `Relevant -FocusedSmoke tests/unit/test_ps190_upgrade_queries.gd
  -RefreshEditor -NoCache`, 67/67 step verdi (refresh, focused, 65 regressioni).
  Log `20260915-231112-PS-185`; copre snapshot isolati, rango iniziale implicito,
  restart, fallback saturazione, stream RNG indipendenti e sequenza preesistente.
- `tests/tooling/_milestone_runner_contract.ps1`: `MILESTONE_RUNNER_CONTRACT_OK`.
- **2026-09-16 — Verifica finale con PS-186.** `Release -KeepGoing -NoCache`:
  476/477 test GUT verdi, stesso fallimento PS-158 della baseline (PS-177).
  Export/smoke Windows e ispezione statica APK verdi; Android export `RECOVERED`.
  Toolchain e project smoke ripetuti con successo dopo la creazione del template
  Gradle nel worktree. Comandi, log e hash nella
  [PS-186](./PS-186-separa-validazione-contratti-run.md).
- La card resta `IN VERIFICA`: review del branch e percorso fisico Pixel 9
  ancora aperti; il profilo completo non viene dichiarato verde.

- **2026-09-17 — Rinumerazione in integrazione.** Il numero PS-185 era stato
  assegnato indipendentemente su develop alla leggibilita' degli elementi.
  Questo refactoring diventa PS-190; i nomi dei log storici PS-185 e i seed
  restano quelli realmente usati. Test, mappa e riferimenti correnti aggiornati.

### Integrazione dei refactoring — 2026-09-17

Il proprietario ha autorizzato l'integrazione in develop. Risultato combinato
al commit `56256b5`: **153 script / 484 casi GUT verdi nello stesso processo**,
zero pending/fallimenti; contratto PowerShell del runner verde anche su
checkout pulito. Export e runtime Windows verdi. Log del Release
`20260917-202700-PS-188` in `%TEMP%/il-gioco-verification`.
Il fallimento storico PS-177 è risolto dalle correzioni delle fixture.
Il test PS-186 usa ora il setup BOOT condiviso di PS-187 ed è incluso nella
mappa di tutti i consumatori dell'helper. La vecchia card upgrade PS-185 è
rinumerata PS-190 per preservare la PS-185 di leggibilità già in develop.

Il primo Release è **FAIL sul solo export Android**: nel worktree mancava
`android/build/.gdignore`, quindi il refresh aveva importato i file generati
per Gradle e prodotto `.import` non validi dentro `res/`. Il vecchio APK del
16 settembre non è stato accettato come nuova build dal runner.
Ripristinata l'esclusione presente nel checkout principale, rimossi soltanto
19 `.import` generati nella cartella `android/build/res` e rigenerata la cache
UID. Nessun asset o sorgente di produzione cambiato per questo recupero.

Ripetizione mirata `20260917-203230-PS-186`: refresh, 3/3 test focused,
export Android **RECOVERED** dopo il marker di fine e ispezione statica **PASS**.
Nuovo file `exports/android/pidgeon-survivor-integrated-20260917.apk`,
73.434.243 byte, SHA-256
`6B8557EEC8B516FFFD3B77D42BB49F1FCE07D5E4FB70A4F03B9A5CFDE222E078`.
Contiene il validatore estratto, package `com.ilgioco.pidgeonsurvivor`,
API 31/36, sola ARM64 e firma v2 valida. Nessun SCRIPT ERROR,
FATAL EXCEPTION, SMOKE_FAIL o CONTRACT_FAIL nei controlli finali.

Restano le diagnostiche di teardown già osservate nel branch runtime
(11/26/8 RID, 235 ObjectDB, 70 risorse e pagine Variant PagedAllocator).
Gate fisico Pixel 9 aperto: nessun device installato/provato. L'autorizzazione
al merge non sostituisce questo gate; la card resta IN VERIFICA per esso.
