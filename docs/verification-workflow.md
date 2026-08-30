# Workflow di verifica delle card

`tools/run-milestone-checks.ps1` riduce il lavoro ripetuto e mantiene una sola
sequenza verificabile. L'output predefinito è una riga compatta; i log completi
restano in `%TEMP%\il-gioco-verification` e si aprono soltanto in caso di errore.

Tutti i test vivono in `tests/unit/` (nome `test_*.gd`, contratto GUT: `extends
GutTest` o `extends GutGameplayTest`, metodi `func test_*() -> void:`) ed
eseguono in un solo processo Godot per profilo, tramite GUT (`addons/gut/`).
Non esiste più il precedente contratto a script `SceneTree` con marker
`<MILESTONE>_..._SMOKE_OK` stampato a schermo: i fallimenti si leggono dal
report JUnit di GUT, non dal testo dei log.

## Profili cumulativi

| Momento | Profilo | Contenuto |
|---|---|---|
| Dopo una modifica locale | `Focused` | Test indicato dalla card |
| Checkpoint della card | `Relevant` | Focused più regressioni associate ai file cambiati |
| Prima della chiusura | `Full` | Tutti i test GUT, toolchain e project smoke |
| Candidata multipiattaforma | `Release` | `Full`, refresh editor, export/runtime Windows, export e ispezione statica Android |

Comandi normali:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-010 -Profile Focused `
  -FocusedSmoke tests/unit/test_grill_defense_mode.gd
.\tools\run-milestone-checks.ps1 -Milestone PS-010 -Profile Relevant `
  -FocusedSmoke tests/unit/test_grill_defense_mode.gd
.\tools\run-milestone-checks.ps1 -Milestone PS-010 -Profile Full
.\tools\run-milestone-checks.ps1 -Milestone PS-010 -Profile Release
```

`Relevant` legge automaticamente le modifiche tracked e untracked di Git. Per
simulare o restringere il checkpoint si possono passare più percorsi:

```powershell
.\tools\run-milestone-checks.ps1 `
  -Milestone PS-001 `
  -Profile Relevant `
  -FocusedSmoke tests/unit/test_b44_state_tells.gd `
  -ChangedPath scripts/actors/player.gd,scenes/actors/player.tscn
```

Le associazioni vivono in `tools/milestone-test-map.json` (ogni riga `smokes`
elenca path `tests/unit/test_*.gd`). File solo documentali e master in
cartelle `hd` non avviano regressioni runtime; una modifica runtime
sconosciuta fa invece scattare l'intera suite, in modo conservativo.

`Focused` seleziona per contenuto: grep sul testo del file cercando
`\b<MILESTONE>\b` (case-sensitive). La maggior parte dei test cita la propria
milestone nei messaggi di asserzione anche quando non compare nel nome del
file; questo grep è quindi un sovrainsieme sicuro, mai più stretto della sola
corrispondenza sul nome. Un test può citare più di una milestone (es. un
raffronto esplicito fra due slice): in quel caso comparirà nel piano
`Focused` di entrambe, invariato.

## Cache e diagnostica

Sono riutilizzati soltanto risultati `PASS`. La chiave del batch GUT include
versione di Godot, runner, mappa e contenuto di tutti i file selezionati per
quel profilo; un cache hit rimaterializza l'esito per singolo script senza
rilanciare Godot né riparsare il report. Per gli export viene verificato anche
l'hash dell'artefatto presente. Cambiare un test invalida solo il batch che lo
contiene; cambiare il runtime invalida tutti i batch pertinenti.

La cache è locale e sacrificabile:

```powershell
# Ricalcola senza leggere o scrivere la cache.
.\tools\run-milestone-checks.ps1 -Milestone PS-001 -Profile Full -NoCache

# Mostra il piano senza avviare Godot.
.\tools\run-milestone-checks.ps1 -Milestone PS-001 -Profile Relevant -PlanOnly `
  -FocusedSmoke tests/unit/test_b44_state_tells.gd

# Espande una diagnosi; il default resta Compact.
.\tools\run-milestone-checks.ps1 -Milestone PS-001 -Profile Relevant -OutputMode Detailed `
  -FocusedSmoke tests/unit/test_b44_state_tells.gd
```

I contratti degli strumenti vengono controllati senza avviare Godot. Il primo
copre profili e selezione dei test, il secondo la cattura dei processi esterni
(marker di completamento, ripiego sulla stabilità dell'artefatto, timeout):

```powershell
.\tests\tooling\_milestone_runner_contract.ps1
.\tests\tooling\_process_capture_contract.ps1
```

## Onestà dei gate anche con GUT

Il conteggio di fallimenti di GUT (`gut.get_fail_count()`) non intercetta ogni
errore motore: un `SCRIPT ERROR` o una `FATAL EXCEPTION` sollevati durante un
test possono non tradursi in un'asserzione fallita contata da GUT. Per questo
il runner continua a cercare gli stessi pattern testuali (`SCRIPT ERROR`,
`FATAL EXCEPTION`) nell'intero output del processo, esattamente come faceva
con il vecchio contratto a marker, e forza `FAIL` anche quando il report JUnit
risulterebbe verde. Un batch che non produce alcun report JUnit leggibile
(crash prima della scrittura) è sempre `FAIL`, mai un piano vuoto silenzioso.

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
