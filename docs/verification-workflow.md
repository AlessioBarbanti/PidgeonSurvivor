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
cartelle `hd` non avviano regressioni runtime. Un path runtime senza regola
nel manifest **non** fa più scattare l'intera suite: `Relevant` resta un
checkpoint delimitato, il path viene solo segnalato a schermo come privo di
regressioni automatiche. Copertura completa per quel path si ottiene con
`-RegressionSmoke` esplicito o con un profilo `Full`/`Release`.

«Solo documentali» include i `.md` e i `.txt` **ovunque**, anche dentro
`assets/`: un `ASSET-MANIFEST.md` descrive gli asset, non è un asset.

`Focused` seleziona per contenuto: grep sul testo del file cercando
`\b<MILESTONE>\b` (case-sensitive). La maggior parte dei test cita la propria
milestone nei messaggi di asserzione anche quando non compare nel nome del
file; questo grep è quindi un sovrainsieme sicuro, mai più stretto della sola
corrispondenza sul nome. Un test può citare più di una milestone (es. un
raffronto esplicito fra due slice): in quel caso comparirà nel piano
`Focused` di entrambe, invariato.

## Fallimento di un test e fallimento del batch

I due casi sono distinti e vanno letti in modo diverso.

Un **test rosso** appartiene al proprio script: solo quello risulta `FAIL`,
con il conteggio nella nota (`GUT: 1/3 test falliti.`). GUT con `-gexit` esce
con codice non-zero appena un test fallisce, ma quel codice riguarda il
processo, non gli altri script del batch, che restano `PASS`.

Un **fallimento di batch** compare come step separato `<categoria>-gut-batch`
e ha solo tre cause, nessuna attribuibile a un singolo script:

- il batch è scaduto (`TIMEOUT`, exit `124`);
- è comparso un errore motore fuori dalle asserzioni (`SCRIPT ERROR`,
  `FATAL EXCEPTION`, `CONTRACT_FAIL`, `SMOKE_FAIL`), che vale anche con
  report GUT verde;
- il processo è uscito male senza alcun test rosso, cioè è morto fuori dai
  test.

L'`exit_code` degli step è quello reale del processo e resta nel JSON; nella
riga leggibile compare solo per gli step non verdi, perché accanto a un `PASS`
descriverebbe il batch e non lo script.

## Batch lunghi: timeout e avanzamento

Il batch GUT ha un tetto di tempo, `-GutTimeoutSeconds` (default `1800`).
Alla scadenza il processo viene terminato, il log parziale resta e lo step è
dichiarato `TIMEOUT`: un test appeso non blocca più la sessione senza dire
niente.

Ogni minuto il runner stampa una riga di avanzamento con tempo trascorso,
script completati e ultimo script avviato:

```
... gut-focused vivo da 00:01:00: 1/2 script, ultimo res://tests/unit/test_x.gd
```

Va su `Write-Host`, quindi non inquina lo stdout letto da `-AsJson`. Quando un
batch si pianta, quella riga nomina lo script su cui si è piantato.

## Cache e diagnostica

Sono riutilizzati soltanto risultati `PASS`. La chiave del batch GUT include
versione di Godot, runner, mappa e contenuto di tutti i file selezionati per
quel profilo; un cache hit rimaterializza l'esito per singolo script senza
rilanciare Godot né riparsare il report. Per gli export viene verificato anche
l'hash dell'artefatto presente. Cambiare un test invalida solo il batch che lo
contiene; cambiare il runtime invalida tutti i batch pertinenti.

**Una verifica ripetuta richiede `-NoCache`.** Rilanciare lo stesso comando
senza `-NoCache` restituisce `CACHED` in un secondo senza avviare Godot: se un
criterio di accettazione chiede *N* esecuzioni consecutive, le ripetizioni
dalla seconda in poi non provano nulla. Le righe `cached=` nel riepilogo
compatto e lo stato `CACHED` per step dicono quando è successo.

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
copre profili, selezione dei test e la distinzione fra test rosso e batch
fallito (`tools/lib/gut-batch-status.ps1`, funzione pura apposta per essere
verificabile senza Godot); il secondo la cattura dei processi esterni (marker
di completamento, ripiego sulla stabilità dell'artefatto, timeout,
avanzamento):

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

## Pacchetto di catture UI

Le revisioni visive e le evidenze percettive partono da un pacchetto di
schermate rigenerabile, prodotto da un solo entry point:

```powershell
godot_console --path . --script tools/_capture_ui_screenshots.gd
```

Lo script non è un test: guida il flusso reale `welcome → tutorial → selezione
→ run → pausa → terminale` e salva un PNG per stato. I formati prodotti sono
dichiarati in un solo punto dello script, non passati da riga di comando, così
il contenuto del pacchetto non dipende da come lo si invoca:

| Profilo | Viewport | Percorso |
|---|---|---|
| `16x9` | `1280×720` | `exports/ui-screenshots/` |
| `20x9` | `2424×1080` | `exports/ui-screenshots/pixel9-20x9/` |

I due pacchetti hanno gli stessi nomi di file. `exports/` è ignorato da git: le
catture sono artefatti locali e vanno rigenerate, mai commesse.

Regole che rendono il pacchetto utilizzabile come evidenza:

- ogni scatto dichiara lo stato del `RunController` che si aspetta, e non viene
  salvato se lo stato non corrisponde o se è visibile un modale che quello
  stato non prevede: una composizione impossibile fallisce la cattura invece di
  finire in un PNG;
- gli stati si raggiungono dal percorso reale — il Boss dalla soglia del
  `GameDirector`, la ricompensa Barb da `UpgradeService`, la pausa dal
  `PlatformLifecycle` — mai simulandoli, perché una simulazione documenta un
  incontro che quel seed non produce;
- i valori mostrati sono quelli della sessione: il tempo del riepilogo
  terminale è lo stesso tempo di run dell'HUD;
- uno stato dormiente non entra nel pacchetto finché non è raggiungibile
  giocando.

**Il pacchetto `20x9` non è un gate Android.** È una simulazione di viewport
eseguita su Windows: non prova installazione, cold launch, touch, multitouch,
lifecycle né qualità percettiva sul device, che restano risultati separati.

**Percorso alternativo senza display locale (PS-061):** il workflow
[`.github/workflows/ui-screenshots.yml`](../.github/workflows/ui-screenshots.yml)
esegue lo stesso `tools/_capture_ui_screenshots.gd` in CI (Xvfb al posto di un
display reale, `godot --path .` senza `--headless` perché lo script legge
`root.get_texture().get_image()`) e pubblica `exports/ui-screenshots/**` come
artifact scaricabile, azionabile da "Actions" con `workflow_dispatch`. Non
sostituisce il percorso locale sopra.

## Igiene del contesto Codex

Usare una conversazione per una card o checkpoint coerente. Prima di
passare a una nuova conversazione, registrare stato, comandi, marker e gate
aperti nella card e nell'eventuale nota di verifica. In questo modo il nuovo
turno può leggere poche fonti autorevoli senza trascinare tutta la cronologia.
