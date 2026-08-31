---
id: PS-030
titolo: Correggi il crash del runner quando un test viene eliminato
tipo: fix
area: tooling
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-31
---

# PS-030 — Correggi il crash del runner quando un test viene eliminato

## Contesto

`tools/run-milestone-checks.ps1`, profilo `Relevant`, calcola i path
modificati con `git diff --name-only HEAD` (`Get-ChangedRepositoryPaths`).
`Find-RelevantSmokes` aggiunge al set "focused" qualunque path che combacia con
`tests/(unit|integration)/.../test_*.gd`, senza controllare che il file esista
ancora su disco. Quando un test viene eliminato (`git rm`, o cancellazione
diretta) invece che modificato, il path cancellato entra comunque nel set. Più
avanti nella pipeline il set viene risolto con
`Resolve-RepositoryPath -Path $_ -MustExist`, che lancia un'eccezione .NET non
gestita ("File non trovato") invece di un fallimento leggibile: il runner si
interrompe con `status=FAIL` e un `runner-fatal.log`, non con un normale report
di test.

Riprodotto durante PS-004: la rimozione di
`tests/unit/test_b18e_zat_thunder_storm.gd` e
`tests/unit/test_b43_lightning_storm.gd` (sostituiti da
`tests/unit/test_ps004_zat_thunder_charge.gd`, contratto dell'attiva
riprogettato) ha fatto fallire `-Profile Relevant` con
`File non trovato: ...test_b18e_zat_thunder_storm.gd`. Aggirato passando
`-ChangedPath` esplicito con l'elenco dei path pertinenti, escludendo i due file
cancellati.

## Comportamento atteso

Eliminare un test file (perché il comportamento che copriva è stato rimosso o
sostituito) non deve mai far crashare il runner con un'eccezione non gestita.
Un file di test cancellato semplicemente non ha nulla da eseguire: va escluso
dal set "focused"/regressione senza intervento manuale, con l'esito riportato
nel modo leggibile già in uso per gli altri casi (vedi
`docs/verification-workflow.md`).

## Criteri di accettazione

- [x] Eliminare un file `tests/**/test_*.gd` tracciato da git e rilanciare il
      profilo `Relevant` (senza `-ChangedPath` esplicito) non produce
      `runner-fatal.log` né un'eccezione .NET non gestita.
- [x] Il file cancellato non compare nel set "focused"/regressione della corsa.
- [x] Modificare (non cancellare) un file di test esistente continua a
      inserirlo nel set "focused" come oggi.
- [x] Nessuna regressione sul comportamento per path runtime non mappati
      (fallback `run_all`) né sulla cache dei batch `PASS`.

## Ambito

Sistemi attesi:

- `Get-ChangedRepositoryPaths` e/o `Find-RelevantSmokes` in
  `tools/run-milestone-checks.ps1`;
- eventualmente `tests/tooling/_milestone_runner_contract.ps1`, se il contratto
  del runner viene esteso per coprire questo caso.

Non modificare:

- la logica di selezione `Focused` per milestone (`Find-FocusedGutTests`);
- il comportamento per i path runtime non mappati (fallback `run_all`);
- la cache dei batch `PASS` e la sua chiave.

## Verifica

- Smoke: estendere `tests/tooling/_milestone_runner_contract.ps1` con un caso
  che simula un path di test cancellato nell'elenco di `Find-RelevantSmokes` (o
  equivalente) e verifica che non lanci eccezioni e che il path non compaia nel
  set risultante.
- Profilo minimo prima della chiusura: `Relevant`
- **2026-08-31 — contratto tooling PASS su Windows**:
  `tests/tooling/_milestone_runner_contract.ps1` ha restituito
  `MILESTONE_RUNNER_CONTRACT_OK`. Su richiesta del proprietario non è stato
  rilanciato un profilo GUT ridondante, poiché la card modifica solo il piano
  PowerShell e non il runtime di gioco.

## Gate manuali

- [x] Runtime Windows: non richiesto, tooling PowerShell.
- [x] Validazione statica APK: non richiesta.
- [x] Runtime fisico Pixel 9: non richiesto, tooling PowerShell.
- [x] Controllo percettivo richiesto: no.

## Decisioni

- **2026-08-30 — Aperta durante PS-004, non risolta lì.** PS-004 doveva
  sostituire due test obsoleti con uno nuovo; il crash del runner è un
  problema del tooling di verifica, non del contratto di Tempesta di Tuoni, e
  PS-004 lo ha aggirato con `-ChangedPath` esplicito invece di allargare il
  proprio ambito.
- **2026-08-31 — Filtro spostato in `Find-RelevantSmokes`, non in
  `Get-ChangedRepositoryPaths`.** `Get-ChangedRepositoryPaths` resta fedele al
  diff (incluse le cancellazioni) perché alimenta anche `changed_paths` nel
  report del plan; filtrare lì avrebbe nascosto la cancellazione dal report.
  Il path di un test cancellato viene invece scartato solo nel punto in cui
  `Find-RelevantSmokes` decide se aggiungerlo al set "focused"/regressione,
  con un controllo `Test-Path` sul file reale prima di `$selected.Add`.

## Documenti sincronizzati

- [x] `docs/verification-workflow.md`: nessun aggiornamento richiesto; il
      comportamento documentato dei path esistenti e non mappati non cambia.

## Note

Riproduzione minima: da un branch con almeno un test tracciato,
`git rm tests/unit/test_qualcosa.gd` seguito da
`.\tools\run-milestone-checks.ps1 -Milestone <ID> -Profile Relevant` (senza
`-ChangedPath`) riproduce `runner-fatal.log` con
`System.Management.Automation.PropertyNotFoundException` o
`File non trovato: ...` a seconda del punto della pipeline raggiunto.

**Chiusura 2026-08-31.** Il fix era già presente nel commit `4709d5e`. Il
contratto PowerShell dedicato è verde; il filtro `Test-Path` agisce solo sui
test cancellati e lascia invariati diff riportato, fallback runtime e cache.
