---
id: PS-177
titolo: Diagnostica il proiettile del Tiratore espulso in modo non deterministico su Full
tipo: fix
area: gameplay
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-09-14
aggiornato: 2026-09-16
---

# PS-177 — Diagnostica il proiettile del Tiratore espulso in modo non deterministico su Full

## Contesto

Durante la verifica di [PS-176](../4_to_test/PS-176-ritratti-boss-fluttuanti-senza-cornice.md)
(Boss Intro, ritratti fluttuanti — nessun file toccato interseca
`scripts/actors/base_enemy.gd`, `ranged_enemy.gd` o la logica del Tiratore),
`-Profile Full` ha fallito **3 volte su 3** tentativi consecutivi, sempre sullo
stesso test:
`tests/unit/test_ps158_mature_build_anti_afk.gd::test_killing_the_shooter_after_it_fires_does_not_cancel_the_projectile`,
sempre con lo stesso assert: "Il proiettile gia' sparato non deve sparire con
la fonte uccisa mentre la run e' ancora in corso". Lo stesso test passa
sempre pulito in isolamento (`-Profile Focused`, verificato più volte).

Il meccanismo sotto test è in
[scripts/actors/ranged_enemy.gd](../../../scripts/actors/ranged_enemy.gd)
`_exit_tree()`:

```gdscript
func _exit_tree() -> void:
    var run_controller := get_run_controller()
    if run_controller == null or not run_controller.is_running():
        clear_attack_runtime()
    super._exit_tree()
```

`clear_attack_runtime()` espelle i proiettili in volo solo quando la run
**non** è `RUNNING` (restart/teardown genuino). Il test costruisce un
`RunController.new()` locale, chiama `controller.start_run(15800)`, poi
uccide il Tiratore e attende un solo `wait_process_frames(1)` prima di
verificare che il proiettile sia sopravvissuto. Se in quella finestra
`run_controller.is_running()` risultasse transitoriamente `false` (stato non
ancora `RUNNING` dopo `start_run()`, per esempio per una transizione
deferred/asincrona sensibile al carico di processo), il proiettile verrebbe
espulso per errore — esattamente il sintomo osservato, e solo quando il
processo GUT ha già eseguito ~100+ script precedenti (carico maggiore,
timing più stretto).

I due commit locali più recenti (non ancora pushati, `ahead 3` di
`origin/develop` al momento dell'apertura di questa card) toccano proprio
quest'area: `aa2225d fix(PS-158): rimuovi il telegraph dai Tiratori, sparo
immediato a tiro` e `71147a2 fix(PS-158): il colpo telegrafato del Tiratore
sopravvive alla sua morte`. Non è escluso che uno dei due abbia introdotto una
finestra di timing più stretta.

Esiste un precedente già tracciato per non-determinismo del profilo Full su
test nemici/fisica sensibili al timing: [PS-175](./PS-175-residuo-non-determinismo-separazione-nemici-full.md),
aperta per `test_ps171_enemy_overlap_separation.gd` con causa sospetta
"nemici fantasma ancora vivi da fixture precedenti nello stesso processo
GUT". Potrebbe essere la stessa causa radice, o una correlata (entrambe
emergono solo su `-Profile Full`, mai in isolamento).

## Comportamento atteso

A parità di codice, `-Profile Full` deve produrre lo stesso esito (verde o
rosso) in esecuzioni ripetute consecutive su questo test. Se la causa è una
vera finestra di race nel gameplay (`RunController.is_running()` non ancora
vero quando un nemico esce dall'albero subito dopo `start_run()`), il fix
vive nel codice di runtime, non nell'allentare l'asserzione del test per
nasconderlo.

## Criteri di accettazione

- [x] Cinque Full consecutivi senza cache verdi sul test del proiettile.
- [x] Causa nella registrazione fisica della fixture diagnosticata tramite stack.
- [x] Nessuna race di RunController: codice runtime invariato, collisioni reali conservate.
- [x] Sopravvivenza dopo la morte e pulizia al restart verificate; prova negativa sensibile alla regressione.

## Ambito

- `scripts/actors/ranged_enemy.gd` (`_exit_tree()`, `clear_attack_runtime()`).
- `scripts/game/run_controller.gd` (`start_run()`, `is_running()`), solo se
  la diagnosi conferma la race lì.
- `tests/unit/test_ps158_mature_build_anti_afk.gd`.
- Valuta se la causa radice è condivisa con [PS-175](./PS-175-residuo-non-determinismo-separazione-nemici-full.md)
  prima di duplicare la diagnosi.

Non toccare:

- Qualunque file della Boss Intro/ritratti (PS-176): nessuna relazione,
  verificato — questa card nasce da un fallimento incontrato lì ma il
  sintomo non tocca alcun file di quella card.
- Il contratto "nessun telegraph" del Tiratore (PS-158/commit `aa2225d`): è
  una richiesta esplicita del proprietario, non in discussione qui.

## Verifica

- GUT: `tests/unit/test_ps158_mature_build_anti_afk.gd`.
- Profilo minimo prima della chiusura: `Full`, eseguito ripetutamente (almeno
  5 volte) per raccogliere evidenza di stabilità — non basta una singola
  esecuzione verde, vista la natura intermittente ma frequente del sintomo
  (3/3 nella sessione che l'ha scoperto).

## Gate manuali

Windows runtime, APK e Pixel 9 non pertinenti: cambia solo il test.
Revisione del branch prima dell'integrazione; nessun merge automatico.

## Decisioni

- **2026-09-14 — Aperta come card separata invece di bloccare PS-176.**
  Nessun file toccato da PS-176 interseca `ranged_enemy.gd`/
  `run_controller.gd`; il fallimento è emerso solo perché la verifica di
  PS-176 esegue `-Profile Full`.


- **2026-09-16 — Ipotesi sul controller esclusa dallo stack reale.**
  Full originale rosso in `20260916-005747-PS-177` e
  `20260916-010223-PS-177`: il nemico usciva con `running=true` e lo stack
  di `expired` era `_on_body_entered -> try_hit`, non `clear_attack_runtime`.
  Il colpo era a x=3,33 e il Player gia' a x=200: collisione pendente dopo
  aver inserito il Player all'origine e spostato soltanto dopo un frame.
- **2026-09-16 — Inizializzazione prima della registrazione fisica.**
  Player posizionato prima di `add_child`, fisica dei due attori disattivata
  per il setup manuale, controller assegnato e un frame fisico di
  sincronizzazione prima di sparare. Il proiettile mantiene fisica e
  collisioni vere: non si maschera il problema disabilitando il collider.
  Il test ora controlla anche controller ancora RUNNING, nemico liberato e
  avanzamento del colpo. La prova negativa con cancellazione incondizionata
  in `_exit_tree` e' rossa (`20260916-081324-PS-177`); mutazione rimossa.
  Sopravvivenza e restart passano insieme dopo il ripristino.

## Documenti sincronizzati

- [x] Board e `docs/verification-workflow.md`.

## Note

Le tre esecuzioni fallite (2026-09-14, sessione di verifica PS-176) sono
riassunte nei rispettivi `LOG_ROOT` locali (non nel repository):
`20260914-213822-PS-176`, `20260914-214213-PS-176`, `20260914-214538-PS-176`
in `%LOCALAPPDATA%\Temp\il-gioco-verification\`. Lo stesso test, isolato con
`-Profile Focused -FocusedSmoke tests/unit/test_ps158_mature_build_anti_afk.gd`,
è passato pulito.


Verifica finale 2026-09-16: cinque esecuzioni consecutive di Full con
-NoCache e un solo processo GUT: 150 script / 469 test verdi per esecuzione,
toolchain e project smoke verdi. Nessun SCRIPT ERROR, FATAL EXCEPTION,
SMOKE_FAIL o CONTRACT_FAIL. Log in %TEMP%/il-gioco-verification:
20260916-081407-PS-188, 20260916-081639-PS-188, 20260916-081909-PS-188,
20260916-082143-PS-188, 20260916-082416-PS-188.

Stato IN VERIFICA per la revisione del branch refactor/test-cleaning-2026-09-16.

Verifica aggiuntiva sul risultato finale del branch, dopo PS-178:
`20260916-150244-PS-188` Full senza cache, 151 script / 474 casi nello
stesso processo GUT, nessun fallimento o pending e nessun marker di errore.
Release `20260916-145813-PS-178`: 474 casi, smoke Windows e APK statico
verdi; Android fisico aperto. Le misure del lag e i relativi limiti restano
nella card PS-178, distinta dalle correzioni delle fixture e del runner.
