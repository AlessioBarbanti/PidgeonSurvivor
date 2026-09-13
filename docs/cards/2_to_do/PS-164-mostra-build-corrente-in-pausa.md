---
id: PS-164
titolo: Mostra la build corrente nel pannello pausa
tipo: ux
area: ui
stato: PRONTO
priorita: media
dipende_da: [PS-142, PS-145, PS-147]
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-11
---

# PS-164 — Mostra la build corrente nel pannello pausa

## Contesto

Il playtest chiede una schermata consultabile durante la run per ricordare gli upgrade già raccolti. Il `PauseOverlay` corrente contiene i controlli di pausa/impostazioni/cambio personaggio/uscita ma non espone la build. `UpgradeService` mantiene già i ranghi della run ed espone `get_ranks()` e `get_registry()`: la prima stesura assumeva erroneamente che servisse necessariamente una nuova API di lettura.

## Comportamento atteso

Aprendo la pausa il giocatore deve poter vedere, senza perdere la run, quali upgrade possiede e a quale rango. Il riepilogo deve convivere con i controlli esistenti e restare leggibile nei profili compatti tramite lo scroll già previsto dal pannello.

## Criteri di accettazione

- [ ] Il pannello pausa mostra tutti gli upgrade ordinari acquisiti nella run corrente con nome e rango effettivo.
- [ ] Le Specialità di Barb effettivamente sbloccate nella run — già presenti nei rank a partire da 1 — sono distinguibili dagli upgrade ordinari; le Specialità ancora bloccate non compaiono.
- [ ] Un upgrade appena scelto compare nel riepilogo alla successiva apertura della pausa senza restart o refresh manuale.
- [ ] Il riepilogo si azzera completamente a restart o cambio personaggio.
- [ ] Il pannello resta entro safe area sui profili già coperti da PS-142/PS-145 e lo scroll consente di raggiungere ogni voce senza coprire i bottoni principali.

## Ambito

- `scripts/ui/pause_overlay.gd` e relativa scena UI.
- `scripts/progression/upgrade_service.gd` e `upgrade_registry.gd`: riuso delle API di lettura già esposte; aggiungerne una nuova solo se il riepilogo non può essere costruito senza duplicare logica.
- `scripts/game/movement_slice.gd` per il wiring scene-local.
- Non trasformare la pausa in una seconda schermata di level-up e non permettere modifiche alla build da questo pannello.

## Verifica

- GUT: `tests/unit/test_ps164_pause_build_summary.gd` → marker `PS164_PAUSE_BUILD_SUMMARY_SMOKE_OK`, con le regressioni PS-142/PS-145/PS-147 del pannello pausa.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run con almeno 6 upgrade e una Specialità, apertura pausa su profilo Pixel 9)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-09-11 — Il riepilogo vive nella pausa, come richiesto dal playtest, e resta read-only.**
- **2026-09-11 — Si riusa lo scroll/clamp del `PauseOverlay` invece di creare un nuovo modal concorrente.**

## Documenti sincronizzati

- [ ] `docs/prd.md` o `docs/ui-ux-flow.md`, se il riepilogo entra nel contratto della pausa.
- [ ] Nota `*-verification.md`, se vengono prodotte catture UI.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. I valori o gli esempi citati nel feedback sono trattati come evidenza percettiva e non come specifica numerica, salvo dove la card lo dichiara esplicitamente.
