# Pidgeon Survivor — istruzioni di progetto

Prototipo 2D survivor in **Godot 4.7.1 Standard**, GDScript tipizzato, renderer
**Compatibility**. Target co-primari obbligatori: **Windows x64** e **Android
12–16 (API 31–36), ARM64, landscape**. Nome pubblico `Pidgeon Survivor`,
sottotitolo `It's grilling time!`, package `com.ilgioco.pidgeonsurvivor`.

## Fonti di verità

Il codice e i documenti nel repository sono autorevoli. Non ricostruire
contratti a memoria: leggili.

| Documento | Ruolo |
|---|---|
| [docs/development-plan.md](docs/development-plan.md) | **Fonte di verità operativa**: roadmap, backlog B-series, stati, gate aperti |
| [docs/prd.md](docs/prd.md) | Contratti di prodotto |
| [docs/decision-log.md](docs/decision-log.md) | Decisioni prese e loro motivazione |
| [docs/content-approvals.md](docs/content-approvals.md) | Approvazioni di nomi, ritratti, citazioni, audio, provenienza |
| [docs/verification-workflow.md](docs/verification-workflow.md) | Contratto dei profili del runner di verifica |
| [docs/setup.md](docs/setup.md) | Toolchain, variabili locali, export, manifest asset |
| `docs/b*-verification.md` | Evidenze per milestone |

Le note temporanee vanno integrate nel development plan e poi rimosse.

## Lingua

Documentazione, commenti di dominio, testo di gioco e messaggi di commit sono in
**italiano**. Identificatori, `class_name`, segnali, marker di test e nomi file
restano in **inglese**. Rispondi al proprietario in italiano.

## Architettura

Tutto è **scene-local e signal-driven**: nessun autoload, nessun event bus
globale. La scena della run è [scenes/game/movement_slice.tscn](scenes/game/movement_slice.tscn),
orchestrata da [scripts/game/movement_slice.gd](scripts/game/movement_slice.gd).

Contratti da preservare:

- **`RunController`** ([scripts/game/run_controller.gd](scripts/game/run_controller.gd))
  è l'unica autorità su stato, tempo logico, pausa, arbitraggio dei modali,
  vittoria/sconfitta, seed e restart. Stati: `BOOT`, `RUNNING`, `MANUAL_PAUSE`,
  `LEVEL_UP`, `BOSS_INTRO`, `VICTORY`, `DEFEAT`. Cooldown, timer e VFX di
  gameplay avanzano solo in `RUNNING` e si azzerano al restart.
- **Flusso UI**: `welcome → (tutorial) → selezione → run → pausa`. `BOOT` resta
  attivo finché il giocatore non conferma; Back/annulla chiude solo il modale in
  cima, mai la run.
- **`GameDirector`** possiede spawn, curve di difficoltà e soglie Boss; non tocca
  la UI. La morte di un Boss non chiude la run (B33): i Boss ricorrono.
- **`ArenaWorld` / `ArenaLayout`** derivano mondo, playfield, fascia di spawn e
  safe rect dalla viewport corrente. Nessuna coordinata `1280×720` hardcoded.
- **`InputRouter`** unifica tastiera, gamepad e touch in intenzioni;
  **`PlatformLifecycle`** traduce Back/focus/sospensione in richieste al
  `RunController` e **non riprende mai** una run automaticamente.
- **Registry di effetti**: i dati (`.tres` in [data/](data/)) dichiarano
  `effect_id` + parametri; la logica vive in `AbilityEffectRegistry` e
  `UpgradeEffectRegistry`. Mai logica nei file dati.
- **La UI osserva segnali e invia intenzioni**; non modifica statistiche né nodi
  nemici.
- `PerformanceProfile` regola risoluzione interna, VFX e particelle per
  piattaforma; non cambia mai il bilanciamento in modo invisibile.

Layout: [scripts/](scripts/) per la logica, [scenes/](scenes/) per le scene,
[data/](data/) per le `Resource` `.tres`, [assets/](assets/) per arte, audio e
font, [tests/integration/](tests/integration/) per gli smoke,
[tools/](tools/) per gli script PowerShell.

## Stile GDScript

- `class_name` + `extends` in testa; tipi espliciti ovunque, anche nei segnali.
- `@export_group` e `@export_range` con setter che validano (`clampf`, `maxf`,
  `is_finite`) invece di fidarsi dell'Inspector.
- Costanti in `SCREAMING_SNAKE_CASE`, membri privati con `_underscore`.
- Timing di presentazione centralizzati in
  [scripts/vfx/presentation_timings.gd](scripts/vfx/presentation_timings.gd),
  separati dai valori di gameplay.
- Tabulazioni per l'indentazione, due righe vuote fra le funzioni.
- Commenti solo dove spiegano il *perché*; usa `##` per la documentazione di
  membri esportati.

## Verifica

Un solo entry point:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone B23 -Profile Focused   # loop interno
.\tools\run-milestone-checks.ps1 -Milestone B23 -Profile Relevant  # checkpoint
.\tools\run-milestone-checks.ps1 -Milestone B23 -Profile Full      # gate automatico
.\tools\run-milestone-checks.ps1 -Milestone B23 -Profile Release   # export Windows/Android
```

- Ogni slice ha uno smoke deterministico `tests/integration/_*_smoke.gd` con un
  marker `*_SMOKE_OK` unico e uscita non nulla in caso di errore.
- Le associazioni file→regressioni vivono in
  [tools/milestone-test-map.json](tools/milestone-test-map.json).
- **Exit code `0` non basta**: i log con `SCRIPT ERROR`, `FATAL EXCEPTION`,
  `SMOKE_FAIL` o `CONTRACT_FAIL` sono fallimenti.
- Dopo aver aggiunto script con `class_name` o asset importati, rinfresca la
  cache dell'editor prima dello smoke (`-RefreshEditor`).
- L'export Android su Windows spesso non esce dopo `[ DONE ]` anche con l'APK
  completo: il runner chiude sul marker `[ DONE ] export`, non sull'uscita del
  processo. Non aspettare l'EOF e non terminare tutti i processi Godot/Java.

## Onestà dei gate

Windows runtime, validazione statica dell'APK e runtime fisico Android sono
**tre risultati distinti** e vanno riportati separatamente. Non chiudere mai un
gate Android di runtime, touch, lifecycle o multitouch senza aver installato
l'APK corrente su un device collegato, esercitato il percorso modificato e letto
i log. Smoke test e screenshot non sostituiscono un controllo percettivo,
geometrico, con controller o su device richiesto dal proprietario. Un device non
disponibile non blocca l'implementazione: lascia il gate **aperto** e dichiaralo.

## Igiene del repository

- Preserva ogni modifica preesistente nel worktree: non pulire, ripristinare o
  mettere in stage lavoro non tuo. Controlla `git status --short` prima di
  iniziare.
- `.godot/`, `exports/` e `android/build/` sono generati e non vanno mai messi in
  stage.
- Nuovi file grafici o audio richiedono una riga nel `ASSET-MANIFEST.md` della
  cartella, con percorso, origine, autore, licenza, trasformazioni e SHA-256.
- Commit solo su richiesta esplicita, focalizzati, in italiano, nella forma
  `feat(B23): ...` / `fix(B23): ...`. Non fare push se non richiesto.
