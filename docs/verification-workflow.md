# Workflow di verifica dei milestone

`tools/run-milestone-checks.ps1` riduce il lavoro ripetuto e mantiene una sola
sequenza verificabile. L'output predefinito è una riga compatta; i log completi
restano in `%TEMP%\il-gioco-verification` e si aprono soltanto in caso di errore.

## Profili cumulativi

| Momento | Profilo | Contenuto |
|---|---|---|
| Dopo una modifica locale | `Focused` | Smoke identificato dal marker del milestone |
| Checkpoint della slice | `Relevant` | Focused più regressioni associate ai file cambiati |
| Prima della chiusura | `Full` | Tutti gli smoke di integrazione, toolchain e project smoke |
| Candidata multipiattaforma | `Release` | `Full`, refresh editor, export/runtime Windows, export e ispezione statica Android |

Comandi normali:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone B24 -Profile Focused
.\tools\run-milestone-checks.ps1 -Milestone B24 -Profile Relevant
.\tools\run-milestone-checks.ps1 -Milestone B24 -Profile Full
.\tools\run-milestone-checks.ps1 -Milestone B24 -Profile Release
```

`Relevant` legge automaticamente le modifiche tracked e untracked di Git. Per
simulare o restringere il checkpoint si possono passare più percorsi:

```powershell
.\tools\run-milestone-checks.ps1 `
  -Milestone B24 `
  -Profile Relevant `
  -ChangedPath scripts/actors/player.gd,scenes/actors/player.tscn
```

Le associazioni vivono in `tools/milestone-test-map.json`. File solo
documentali e master in cartelle `hd` non avviano regressioni runtime; una
modifica runtime sconosciuta fa invece scattare l'intera suite, in modo
conservativo.

## Cache e diagnostica

Sono riutilizzati soltanto risultati `PASS`. La chiave include versione di
Godot, runner, mappa, contenuto runtime e contenuto dello smoke. Per gli export
viene verificato anche l'hash dell'artefatto presente. Cambiare uno smoke
invalida quel test; cambiare il runtime invalida tutti i test pertinenti.

La cache è locale e sacrificabile:

```powershell
# Ricalcola senza leggere o scrivere la cache.
.\tools\run-milestone-checks.ps1 -Milestone B24 -Profile Full -NoCache

# Mostra il piano senza avviare Godot.
.\tools\run-milestone-checks.ps1 -Milestone B24 -Profile Relevant -PlanOnly

# Espande una diagnosi; il default resta Compact.
.\tools\run-milestone-checks.ps1 -Milestone B24 -Profile Relevant -OutputMode Detailed
```

Il contratto dei profili e della selezione viene controllato senza avviare
Godot:

```powershell
.\tests\tooling\_milestone_runner_contract.ps1
```

## Confini dei gate

Il profilo `Release` può recuperare il caso Windows in cui l'exporter Android
rimane aperto dopo aver scritto un APK nuovo e stabile. Termina esclusivamente
il processo avviato dal runner e accetta `RECOVERED` soltanto dopo package,
SDK, ABI, firma e struttura ZIP verdi.

Questo non prova installazione, cold launch, touch, multitouch, lifecycle,
prestazioni o qualità percettiva sul device. Tali risultati restano gate
separati nelle note di verifica del milestone.

## Igiene del contesto Codex

Usare una conversazione per un milestone o checkpoint coerente. Prima di
passare a una nuova conversazione, registrare stato, comandi, marker e gate
aperti nella nota di verifica e nel development plan. In questo modo il nuovo
turno può leggere poche fonti autorevoli senza trascinare tutta la cronologia.
