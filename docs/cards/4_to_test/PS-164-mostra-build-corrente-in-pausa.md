---
id: PS-164
titolo: Mostra la build corrente nel pannello pausa
tipo: ux
area: ui
stato: IN VERIFICA
priorita: media
dipende_da: [PS-142, PS-145, PS-147]
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-14
---

# PS-164 — Mostra la build corrente nel pannello pausa

## Contesto

Il playtest chiede una schermata consultabile durante la run per ricordare gli upgrade già raccolti. Il `PauseOverlay` corrente contiene i controlli di pausa/impostazioni/cambio personaggio/uscita ma non espone la build. `UpgradeService` mantiene già i ranghi della run ed espone `get_ranks()` e `get_registry()`: la prima stesura assumeva erroneamente che servisse necessariamente una nuova API di lettura.

## Comportamento atteso

Aprendo la pausa il giocatore deve poter vedere, senza perdere la run, quali upgrade possiede e a quale rango. Il riepilogo deve convivere con i controlli esistenti e restare leggibile nei profili compatti tramite lo scroll già previsto dal pannello.

## Criteri di accettazione

- [x] Il pannello pausa mostra tutti gli upgrade ordinari acquisiti nella run corrente con nome e rango effettivo.
- [x] Le Specialità di Barb effettivamente sbloccate nella run — già presenti nei rank a partire da 1 — sono distinguibili dagli upgrade ordinari; le Specialità ancora bloccate non compaiono.
- [x] Un upgrade appena scelto compare nel riepilogo alla successiva apertura della pausa senza restart o refresh manuale.
- [x] Il riepilogo si azzera completamente a restart o cambio personaggio.
- [x] Il pannello resta entro safe area sui profili già coperti da PS-142/PS-145 e lo scroll consente di raggiungere ogni voce senza coprire i bottoni principali.

## Ambito

- `scripts/ui/pause_overlay.gd` e relativa scena UI.
- `scripts/progression/upgrade_service.gd` e `upgrade_registry.gd`: riuso delle API di lettura già esposte; aggiungerne una nuova solo se il riepilogo non può essere costruito senza duplicare logica.
- `scripts/game/movement_slice.gd` per il wiring scene-local.
- Non trasformare la pausa in una seconda schermata di level-up e non permettere modifiche alla build da questo pannello.

## Verifica

- GUT: `tests/unit/test_ps164_pause_build_summary.gd` → marker `PS164_PAUSE_BUILD_SUMMARY_SMOKE_OK`, con le regressioni PS-142/PS-145/PS-147 del pannello pausa.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [x] Runtime Windows — `godot_console --path . --script tools/_capture_ui_screenshots.gd`
      (non headless, framebuffer reale), percorso completo
      welcome→tutorial→selezione→run→level-up→ricompensa Barb (tutte e 8 le
      Specialità sbloccate)→Boss→pausa→terminale, marker `CAPTURE_DONE`,
      nessun `SCRIPT ERROR`/`FATAL EXCEPTION` nell'output.
- [ ] Validazione statica APK — non eseguita in questa sessione.
- [ ] Runtime fisico Pixel 9 (percorso: run con almeno 6 upgrade e una Specialità, apertura pausa su profilo Pixel 9) — nessun device collegato (`adb devices` vuoto); gate lasciato aperto, non blocca la chiusura degli automatici.
- [x] Controllo percettivo richiesto: sì — **Approvato** da `direttore-artistico`, due passate (pianificazione prima di implementare, revisione del render dopo). Vedi Decisioni.

## Decisioni

- **2026-09-11 — Il riepilogo vive nella pausa, come richiesto dal playtest, e resta read-only.**
- **2026-09-11 — Si riusa lo scroll/clamp del `PauseOverlay` invece di creare un nuovo modal concorrente.**
- **2026-09-14 — Consultato `direttore-artistico` in modalità pianificazione, prima di implementare.** Ha confermato la direzione (righe procedurali stile `end_screen._build_upgrade_chip`, oro locale del pannello per le Specialità invece del bordo/sfondo di `UpgradeCard`) e corretto tre punti rispetto alla mia proposta iniziale: icona 48×48 riusando `UPGRADE_CHIP_ICON_SIZE` di `end_screen.gd` (non un valore ridotto); ruoli colore presi dal fratello più stretto (`settings_overlay.tscn`, righe `VolumeRow`/`AbilitySizeRow`) invece di `end_screen` — titolo crema `Color(1, 0.91, 0.7, 1)` (`BodyM`), rango sempre muted `Color(0.722, 0.784, 0.85, 1)` (`ValueNumeric`) a destra, oro solo sul `font_color` del titolo Specialità; separatore di sezione riusando lo `StyleBoxFlat` di `TabSeparator` in `settings_overlay.tscn` invece di inventarne uno nuovo. Ha inoltre segnalato di non riusare `movement_slice._build_top_upgrade_entries()` così com'è (tronca a 3): riusato solo l'ordinamento (rango desc, poi ID), scritta una funzione dedicata in `pause_overlay.gd` senza troncamento.
- **2026-09-14 — Implementazione.** `scenes/ui/pause_overlay.tscn`: nuovi nodi `BuildSummarySeparator`/`BuildSummaryTitle`/`BuildSummaryList` in coda al `VBox` esistente (stesso scroll/clamp di PS-142). `scripts/ui/pause_overlay.gd`: `configure_upgrade_service()` (cablata una volta da `movement_slice.gd`, come `configure_settings_overlay()`), `_refresh_build_summary()` richiamata a ogni `show_pause()` (nessun segnale dedicato: la ricostruzione a ogni apertura copre sia l'aggiornamento post-scelta sia l'azzeramento post-restart, dato che `UpgradeService` svuota già `_ranks` prima della prossima `RUNNING`), righe costruite proceduralmente (icona+titolo+rango), Specialità sbloccate distinte solo da `font_color` oro sul titolo. Aggiunta verifica di cablaggio in `movement_slice._validate_current_contract()` (`PauseOverlay.get_upgrade_service() == _upgrade_service`), stesso pattern già in uso per `BarbRewardOverlay`/`UpgradeOverlay`.
- **2026-09-14 — Verifica automatica.** `tests/unit/test_ps164_pause_build_summary.gd` (3 test: upgrade ordinario + Specialità distinti e Specialità bloccate assenti; aggiornamento senza restart; azzeramento su restart reale via `RunController.restart_run()`), marker `PS164_PAUSE_BUILD_SUMMARY_SMOKE_OK`. Profilo `Relevant`: 59/59 (1 focused + 58 regressioni), nessun `SCRIPT ERROR`/`FATAL EXCEPTION` nei log.
- **2026-09-14 — Consultato di nuovo `direttore-artistico` dopo l'implementazione, sul render reale** (`exports/ui-screenshots/07_pause_overlay.png` e la variante `pixel9-20x9`, generate da una run che sblocca tutte le Specialità prima di aprire la pausa). Ha campionato i pixel del testo: scarto di tinta crema→oro ≈0.34 sul canale blu, identico fra le due risoluzioni, oltre la soglia ±0.3-0.4 già stabilita per questo pannello scuro da PS-147. **Valutazione: Approva**, nessuna modifica richiesta. Ha segnalato due follow-up non bloccanti: (1) verifica non visiva che le Specialità ancora bloccate restino assenti — già coperta dal test GUT sopra, non solo dallo screenshot; (2) fissare in `visual-audio-identity.md` la regola dei due trattamenti Specialità (bordo/sfondo su card cliccabile vs solo `font_color` su riga read-only) per evitare un terzo trattamento in un futuro riepilogo — fatto, vedi `docs/visual-audio-identity.md`.

## Documenti sincronizzati

- [x] `docs/ui-ux-flow.md` — aggiunta la sezione "Riepilogo build nella pausa (PS-164)".
- [x] `docs/visual-audio-identity.md` — aggiunta la regola dei due trattamenti Specialità (card cliccabile vs riga read-only), emersa dalla revisione `direttore-artistico`.
- [ ] Nota `*-verification.md` — non prodotta: come già per PS-145/PS-147, l'evidenza screenshot vive in questa card (Gate manuali/Decisioni), non in un documento `b*-verification.md` dedicato; nessun precedente di card pausa ne ha creato uno.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. I valori o gli esempi citati nel feedback sono trattati come evidenza percettiva e non come specifica numerica, salvo dove la card lo dichiara esplicitamente.
