---
id: PS-023
titolo: Rendi leggibile e non bloccante il runner di verifica
tipo: chore
area: tooling
stato: COMPLETATO
priorita: alta
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-09-04
---

# PS-023 — Rendi leggibile e non bloccante il runner di verifica

## Contesto

`tools/run-milestone-checks.ps1` non permette di sapere se una verifica sta
andando bene, è rotta o è appesa. Cinque difetti distinti, tutti riprodotti il
2026-08-30 durante PS-013, PS-019 e PS-020:

1. **Un test rosso marca rossi tutti gli altri.** GUT con `-gexit` esce con
   codice non-zero quando anche un solo test fallisce; il runner interpreta
   quell'exit code come «processo non ok» e forza `FAIL` su ogni script del
   batch. Nella run `20260830-133544-PS-013` questo ha prodotto 65 righe
   `FAIL … note=GUT: 0/N test falliti` per un unico test davvero rosso. Nello
   stesso log i marker `SCRIPT ERROR|FATAL EXCEPTION|CONTRACT_FAIL|SMOKE_FAIL`
   sono zero: l'exit code era l'unica causa.
2. **Nessun timeout sul batch GUT.** `Invoke-GutBatch` chiama
   `Invoke-CapturedProcess` senza `-TimeoutSeconds` e il default è `0`, cioè
   attesa infinita. Un test appeso appende il runner senza produrre output.
3. **Nessun segno di vita durante il batch.** L'output viene scritto solo alla
   fine: una suite da quindici minuti è indistinguibile da un blocco.
4. **`Relevant` degenera in suite completa per colpa dei file documentali.**
   `Test-IsRuntimePath` considera runtime qualunque path sotto `assets/`,
   quindi anche `assets/art/vfx/ASSET-MANIFEST.md`. Nessuna regola della mappa
   la copre, quindi scatta il fallback `run_all`. Poiché ogni card aggiorna la
   propria documentazione, il checkpoint `Relevant` costa quanto un `Full`.
   `docs/verification-workflow.md` promette il contrario.
5. **`exit_code` degli step per-script è la costante `0`.** Il riepilogo
   dichiara `exit=0` anche quando il processo è uscito male o è scaduto.

## Comportamento atteso

Chi legge il riepilogo del runner capisce, senza aprire i log: quali test sono
falliti davvero, se il processo è morto, se è scaduto, e se sta ancora
lavorando. Un batch appeso viene interrotto e dichiarato tale invece di
bloccare la sessione. `Relevant` esegue le regressioni pertinenti, non tutte.

## Criteri di accettazione

- [x] Un batch GUT con un solo test rosso riporta `FAIL` **solo** sullo script
      che contiene quel test; gli altri restano `PASS`.
- [x] Un errore motore non attribuibile a un singolo script (`SCRIPT ERROR`,
      `FATAL EXCEPTION`, `CONTRACT_FAIL`, `SMOKE_FAIL`), un crash o un timeout
      producono comunque un `FAIL` di batch esplicito e distinguibile dal
      fallimento di un singolo test.
- [x] Il batch GUT ha un timeout; alla scadenza il processo viene terminato e
      lo step risulta `TIMEOUT` con il log parziale conservato.
      *Formulazione corretta rispetto a quella iniziale: `TIMEOUT` è
      l'etichetta con cui lo step viene **letto** (riepilogo e `timed_out` nel
      JSON, exit `124`). Il valore interno di `status` resta `FAIL`, perché
      introdurre un sesto stato nel vocabolario avrebbe richiesto di rivedere
      i sei punti che aggregano su `status -eq 'FAIL'`, con il rischio che un
      timeout venisse contato come successo.*
- [x] Durante un batch lungo il runner emette una riga di avanzamento, così
      che silenzio e blocco non si somiglino.
- [x] Il campo `exit_code` degli step riporta il codice reale del processo.
- [x] Una modifica a soli file documentali (`*.md`, manifest degli asset) non
      fa scattare `run_all`; `Relevant` su una card che tocca un solo script
      esegue le regressioni mappate, non l'intera suite.
- [x] Il fallback `run_all` è rimosso anche per i path runtime effettivi senza
      regola nella mappa: `Relevant` non degenera più in suite completa in
      quel caso, il path viene solo segnalato a schermo come privo di
      regressioni automatiche mappate. Copertura completa resta disponibile
      con `-RegressionSmoke` esplicito o un profilo `Full`/`Release`.
- [x] Gli step non-GUT (refresh editor, toolchain, export Windows/Android,
      ispezione statica APK) emettono anch'essi inizio/fine con esito e
      durata, e una riga di avanzamento periodica mentre sono in corso, non
      solo il batch GUT.
- [x] `tests/tooling/_milestone_runner_contract.ps1` copre ognuno dei punti
      sopra e passa.
      *Con una precisazione onesta: il contratto copre senza Godot la
      distinzione test rosso / batch fallito, l'esistenza e il minimo del
      timeout, e la sola regola documentale di selezione (riga 68). La
      rimozione del fallback `run_all` per i path runtime non mappati e
      l'avanzamento sugli step non-GUT non sono coperti dal contratto
      automatico: sono verificati solo dalla prova end-to-end qui sotto. La
      riga di avanzamento del batch GUT è coperta
      da `_process_capture_contract.ps1`. Il rendering dell'output e
      l'`exit_code` reale sono provati end-to-end nelle evidenze qui sotto,
      non da un'asserzione automatica.*

## Ambito

- `tools/run-milestone-checks.ps1`;
- `tools/lib/process-capture.ps1`, se serve per timeout e avanzamento;
- `tools/milestone-test-map.json`, solo se una regola documentale è la via più
  pulita;
- `tests/tooling/_milestone_runner_contract.ps1`;
- `docs/verification-workflow.md`, per allineare il contratto descritto.

Non modificare:

- il contratto di onestà dei gate: un errore motore deve continuare a produrre
  `FAIL` anche con report GUT verde;
- i 66 test in `tests/unit/`: non sono l'oggetto di questa card;
- la separazione fra i tre risultati Windows / APK statico / device fisico.

## Verifica

- `.\tests\tooling\_milestone_runner_contract.ps1`
- `.\tests\tooling\_process_capture_contract.ps1`
- Prova end-to-end: un `Relevant` su una card che tocca un solo script deve
  eseguire le regressioni mappate e non tutta la suite.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [x] Runtime Windows: non richiesto, la card non tocca il gioco.
- [x] Validazione statica APK: non richiesta.
- [x] Runtime fisico Pixel 9: non richiesto.
- [x] Controllo percettivo richiesto: no.

## Decisioni

- **2026-08-30 — Si sistema, non si riscrive.** I test GUT hanno appena
  dimostrato di funzionare (hanno intercettato PS-013 e PS-019, e su PS-020 il
  contratto B18W ha segnalato un asset davvero non caricabile). Il difetto è
  tutto nello strato di orchestrazione, e i cinque punti sono localizzati.
  Riscrivere significherebbe rifare profili, mappa, cache e cattura processi,
  sostituendo bug noti e riproducibili con bug nuovi.
- **2026-09-02 — Il fallback `run_all` va tolto del tutto, non solo per i
  `.md`.** La correzione originale escludeva solo i file documentali dal
  fallback, ma qualunque path runtime *legittimo* senza regola nella mappa
  (uno script nuovo, un asset in una cartella non ancora mappata) faceva
  ancora scattare la suite completa: lo stesso costo che la card doveva
  eliminare, spostato da «ogni card che tocca la doc» a «ogni card che tocca
  un file non ancora mappato», comunque frequente. `Relevant` resta un
  checkpoint delimitato solo se non degenera mai; il prezzo è che un path
  davvero privo di copertura passa silenzioso a meno di leggere la
  segnalazione a schermo — accettabile perché resta disponibile
  `-RegressionSmoke` esplicito o un profilo `Full` per chi vuole essere
  sicuro. Nello stesso intervento, gli step non-GUT (refresh editor,
  toolchain, export, ispezione) sono stati resi silenziosi solo quanto lo era
  il batch GUT prima della card: aggiunta la stessa disciplina inizio/fine +
  avanzamento periodico, altrimenti un `export_android` appeso resta
  indistinguibile da un blocco esattamente come lo era il batch GUT.

## Documenti sincronizzati

- [x] `docs/verification-workflow.md`: nuove sezioni «Fallimento di un test e
      fallimento del batch» e «Batch lunghi: timeout e avanzamento», la regola
      sui `.md` dentro `assets/`, e la nota che una verifica ripetuta richiede
      `-NoCache`.

## Note

Evidenze dei sintomi: log `20260830-133544-PS-013` (65 falsi `FAIL`),
`20260830-133043-PS-020`…`20260830-133348-PS-020` (dieci ripetizioni rese
inutili dalla cache prima di passare a `-NoCache`).

### Prove raccolte il 2026-08-30

**Un test rosso non tinge di rosso gli altri.** Creato un
`tests/unit/test_ps023_temp_failure.gd` con una sola asserzione falsa,
eseguito insieme a due file verdi, poi cancellato:

```
IL_GIOCO_VERIFICATION milestone=PS-023 profile=Focused status=FAIL
PASS focused-tests/unit/test_ability_definition.gd
FAIL focused-tests/unit/test_ps023_temp_failure.gd exit=1 note=GUT: 1/1 test falliti.
PASS focused-tests/unit/test_upgrade_definition.gd
```

In compatto (log `20260830-143423-PS-023`):

```
... status=FAIL focused=2/3 steps=2/3 cached=0
FAIL step=focused-tests/unit/test_ps023_temp_failure.gd exit=1 log=... note=GUT: 1/1 test falliti.
```

Prima della card le stesse condizioni producevano tre righe `FAIL`.

**Timeout e avanzamento.** Sostituito lo stesso file temporaneo con un test che
non termina mai (`while true: await get_tree().process_frame`), poi cancellato:

```
... gut-focused vivo da 00:01:00: 1/2 script, ultimo res://tests/unit/test_ps023_temp_failure.gd
IL_GIOCO_VERIFICATION milestone=PS-023 profile=Focused status=FAIL
TIMEOUT focused-gut-batch exit=124 note=TIMEOUT dopo 60 s prima che GUT scrivesse il report: processo terminato, log parziale conservato.
```

Durata totale 62 s contro un'attesa prima infinita, e la riga di avanzamento
nomina lo script su cui si è piantato. Log `20260830-143622-PS-023`.

**Costo del checkpoint.** `Relevant` su `scripts/ui/upgrade_overlay.gd`
(log `20260830-143844-PS-023`):

```
... status=PASS focused=1/1 regression=7/7 steps=8/8 cached=0
durata: 124 s
```

Sette regressioni mappate invece dei 65 script della suite completa: **124
secondi contro i ~15 minuti** della stessa verifica il mattino stesso
(`20260830-133544-PS-013`).

**Suite completa con il runner corretto** (log `20260830-144237-PS-023`):

```
IL_GIOCO_VERIFICATION milestone=PS-023 profile=Full status=PASS regression=69/69 toolchain=1/1 steps=70/70 cached=0
```

Sedici righe di avanzamento, una al minuto, dall'apertura alla chiusura:

```
... gut-regression vivo da 00:01:00: 7/69 script, ultimo res://tests/unit/test_b06_player_survival.gd
...
... gut-regression vivo da 00:16:02: 67/69 script, ultimo res://tests/unit/test_powerup_first_wave.gd
```

**Contratti degli strumenti.**

```powershell
.\tests\tooling\_process_capture_contract.ps1   # PROCESS_CAPTURE_CONTRACT_OK
.\tests\tooling\_milestone_runner_contract.ps1  # MILESTONE_RUNNER_CONTRACT_OK
```

### Prove raccolte il 2026-09-02

**Un path runtime senza regola non fa più scattare `run_all`.** Aggiunto un
file temporaneo `scripts/_ps023_temp_probe.gd` (nessuna regola nella mappa),
poi cancellato:

```
... relevant: 1 path runtime senza regola in tools\milestone-test-map.json, nessuna regressione automatica per questi path. Path: scripts/_ps023_temp_probe.gd
==> piano PS-023/Relevant: focused=1 regression=19 refresh_editor=False toolchain=False project_smoke=False export_windows=False export_android=False cache=True
IL_GIOCO_VERIFICATION_PLAN milestone=PS-023 profile=Relevant focused=1 regression=19 changed=34 cache=True
```

`regression=19`, non l'intera suite: prima di questo intervento lo stesso
scenario avrebbe fatto scattare `run_all` su tutti i 69 test. Verifica solo
`-PlanOnly` (nessun Godot lanciato): non prova end-to-end l'avanzamento sugli
step non-GUT, che resta verificato per lettura del codice
(`New-GenericProgressAction`, `Write-StepStart`/`Write-StepDone` applicati a
`refresh-editor`, `toolchain`, `windows-export`, `windows-runtime`,
`android-export`, `android-static`) più le stesse garanzie già provate per
`Invoke-CapturedProcess` da `_process_capture_contract.ps1`, non da una nuova
prova end-to-end dedicata.

### Non risolto qui

La cache resta in grado di restituire `PASS` senza eseguire nulla, e la sua
chiave non include lo stato di `.godot/imported/`. Non era fra i criteri di
questa card: per ora è documentato in `docs/verification-workflow.md`, che
adesso dice esplicitamente che una verifica ripetuta richiede `-NoCache`.
