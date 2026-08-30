# Workflow di verifica delle card

`tools/run-milestone-checks.ps1` riduce il lavoro ripetuto e mantiene una sola
sequenza verificabile. L'output predefinito è una riga compatta; i log completi
restano in `%TEMP%\il-gioco-verification` e si aprono soltanto in caso di errore.

## Profili cumulativi

| Momento | Profilo | Contenuto |
|---|---|---|
| Dopo una modifica locale | `Focused` | Smoke indicato dalla card |
| Checkpoint della card | `Relevant` | Focused più regressioni associate ai file cambiati |
| Prima della chiusura | `Full` | Tutti gli smoke di integrazione, toolchain e project smoke |
| Candidata multipiattaforma | `Release` | `Full`, refresh editor, export/runtime Windows, export e ispezione statica Android |

Comandi normali:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-010 -Profile Focused `
  -FocusedSmoke tests/integration/_grill_defense_mode_smoke.gd
.\tools\run-milestone-checks.ps1 -Milestone PS-010 -Profile Relevant `
  -FocusedSmoke tests/integration/_grill_defense_mode_smoke.gd
.\tools\run-milestone-checks.ps1 -Milestone PS-010 -Profile Full
.\tools\run-milestone-checks.ps1 -Milestone PS-010 -Profile Release
```

`Relevant` legge automaticamente le modifiche tracked e untracked di Git. Per
simulare o restringere il checkpoint si possono passare più percorsi:

```powershell
.\tools\run-milestone-checks.ps1 `
  -Milestone PS-001 `
  -Profile Relevant `
  -FocusedSmoke tests/integration/_b44_state_tells_smoke.gd `
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
.\tools\run-milestone-checks.ps1 -Milestone PS-001 -Profile Full -NoCache

# Mostra il piano senza avviare Godot.
.\tools\run-milestone-checks.ps1 -Milestone PS-001 -Profile Relevant -PlanOnly `
  -FocusedSmoke tests/integration/_b44_state_tells_smoke.gd

# Espande una diagnosi; il default resta Compact.
.\tools\run-milestone-checks.ps1 -Milestone PS-001 -Profile Relevant -OutputMode Detailed `
  -FocusedSmoke tests/integration/_b44_state_tells_smoke.gd
```

I contratti degli strumenti vengono controllati senza avviare Godot. Il primo
copre profili e selezione dei test, il secondo la cattura dei processi esterni
(marker di completamento, ripiego sulla stabilità dell'artefatto, timeout):

```powershell
.\tests\tooling\_milestone_runner_contract.ps1
.\tests\tooling\_process_capture_contract.ps1
```

## Confini dei gate

Il profilo `Release` può recuperare il caso Windows in cui l'exporter Android
rimane aperto dopo aver completato l'APK. Il runner attende il marker
`[ DONE ] export` stampato da Godot, concede una breve grazia perché il
processo esca da solo, poi termina esclusivamente l'albero avviato da quella
esecuzione. Se il marker non compare, ripiega sulla stabilità dell'artefatto.
Accetta `RECOVERED` soltanto dopo package, SDK, ABI, firma e struttura ZIP
verdi.

I codici di uscita distinguono i tre casi nei log: `126` terminato dopo il
marker, `125` terminato dopo un artefatto rimasto stabile, `124` scaduto senza
alcun segnale.

Questo non prova installazione, cold launch, touch, multitouch, lifecycle,
prestazioni o qualità percettiva sul device. Tali risultati restano gate
separati nelle note di verifica collegate dalla card.

## Igiene del contesto Codex

Usare una conversazione per una card o checkpoint coerente. Prima di
passare a una nuova conversazione, registrare stato, comandi, marker e gate
aperti nella card e nell'eventuale nota di verifica. In questo modo il nuovo
turno può leggere poche fonti autorevoli senza trascinare tutta la cronologia.
