---
id: PS-143
titolo: Sostituisci l'icona ingranaggio della pausa con un bottone IMPOSTAZIONI
tipo: ux
area: ui
stato: IN VERIFICA
priorita: media
dipende_da: [PS-137]
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-143 — Sostituisci l'icona ingranaggio della pausa con un bottone IMPOSTAZIONI

## Contesto

PS-137 ha introdotto un'icona ingranaggio (glifo Unicode "⚙" su
`StyleBoxFlat`) fluttuante fuori dalla colonna Resume/Cambia personaggio nel
pannello pausa, per aprire l'overlay impostazioni condiviso con la welcome.
Verificato dal vivo dal proprietario: l'icona è quasi illeggibile contro lo
sfondo scuro. Consultato in merito, il direttore-artistico ha isolato la
causa reale confrontando con "II" del pausa-HUD (stesso font, stesso
`StyleBoxFlat` con bordo oro, stessa famiglia di bottone): il problema non è
solo il colore, è la forma del glifo "⚙" stesso, che a queste dimensioni
diventa una sagoma sottile e frastagliata che nessun font rende con uno
stroke pieno — un problema strutturale del riuso di un carattere di sistema
come icona funzionale, non risolvibile con un semplice cambio di colore.

Il proprietario ha poi chiarito di aver inteso, nella richiesta originaria di
PS-137, che i due tasti ingranaggio (welcome e pausa) dovessero portare
**alla stessa pagina** (stessa istanza dell'overlay condiviso), non che
dovessero avere **lo stesso stile visivo**. Corregge quindi lo scopo di
quella card (vedi PS-137, sezione Decisioni, voce 2026-09-10): la welcome
resta invariata con la propria icona; solo la pausa sostituisce l'icona
fluttuante con un terzo bottone testuale a piena colonna, come le altre due
azioni già presenti.

## Comportamento atteso

Il pannello "IN PAUSA" mostra tre bottoni in colonna — RIPRENDI (primario),
CAMBIA PERSONAGGIO (secondario), IMPOSTAZIONI (secondario, in fondo) — che
aprono rispettivamente la ripresa della run, la conferma di cambio
personaggio e l'overlay impostazioni condiviso già esistente. Nessuna icona
fluttuante resta fuori dalla colonna nel pannello pausa. La welcome screen
non cambia: mantiene la propria icona ingranaggio così com'è oggi.

## Criteri di accettazione

- [x] Il pannello pausa non mostra più `SettingsButton` come icona
      fluttuante fuori dalla colonna: al suo posto, un bottone
      "IMPOSTAZIONI" appare nella stessa colonna di RIPRENDI/CAMBIA
      PERSONAGGIO, come ultimo elemento.
- [x] Il bottone "IMPOSTAZIONI" usa lo stesso stile secondario di "CAMBIA
      PERSONAGGIO" (`StyleBoxTexture_secondary_*`), non lo stile primario di
      "RIPRENDI".
- [x] Premendo "IMPOSTAZIONI" si apre la stessa istanza dell'overlay
      impostazioni condiviso già aperta oggi dall'icona (nessun
      comportamento nuovo lato overlay, solo il trigger cambia).
- [x] `scenes/ui/welcome_screen.tscn` non viene modificata: l'icona
      ingranaggio della welcome resta identica a oggi.
- [x] La catena `focus_neighbor` da tastiera/gamepad copre i tre bottoni in
      ordine (RIPRENDI ↔ CAMBIA PERSONAGGIO ↔ IMPOSTAZIONI) senza salti né
      trappole di focus, sostituendo la catena che oggi include l'icona.
- [x] Il flusso di conferma cambio personaggio (`ConfirmationCenter`) resta
      invariato: nessuna modifica a `_on_change_character_button_pressed()`,
      `_cancel_change_character()` o al nodo `ConfirmationCenter`, invariati
      dal codice precedente e coperti dalle regressioni `Relevant` (28/28
      verdi, incluso `test_b18n_pause_change_character.gd`).

## Ambito

- File attesi: `scenes/ui/pause_overlay.tscn` (rimozione `SettingsButton`
  come nodo fluttuante, aggiunta bottone "IMPOSTAZIONI" in `VBox`),
  `scripts/ui/pause_overlay.gd` (wiring del bottone al posto dell'icona,
  aggiornamento `focus_neighbor`).
- Non toccare: `scenes/ui/welcome_screen.tscn`,
  `scripts/ui/welcome_screen.gd` — restano fuori scopo per esplicita
  richiesta del proprietario.
- Non toccare: `scenes/ui/settings_overlay.tscn` e la sua logica interna
  (tab, persistenza impostazioni) — cambia solo il trigger che lo apre dalla
  pausa, non l'overlay stesso.
- Aggiornare `tests/unit/test_ps137_shared_settings_overlay.gd` per la nuova
  catena `focus_neighbor` basata sul bottone invece che sull'icona (la
  card PS-137 lo segnala esplicitamente come da fare qui).
- Sincronizzare la correzione già annotata in
  [PS-137](../4_to_test/PS-137-overlay-impostazioni-condiviso-e-paginato.md)
  (criterio e decisione corretti, non duplicarli qui).

## Verifica

- Smoke: `tests/unit/test_ps143_pause_settings_button.gd` → marker
  `PS143_PAUSE_SETTINGS_BUTTON_OK`, verifica assenza del nodo icona
  fluttuante, presenza del bottone "IMPOSTAZIONI" nella colonna con lo
  stile secondario, apertura dell'overlay condiviso alla pressione, e catena
  `focus_neighbor` corretta fra i tre bottoni.
- Aggiornare `tests/unit/test_ps137_shared_settings_overlay.gd` per la
  parte relativa alla catena focus dell'icona pausa (non più applicabile).
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: apertura pausa, navigazione da
      tastiera/gamepad fra i tre bottoni, apertura impostazioni dal nuovo
      bottone)
- [ ] Controllo percettivo richiesto: sì — confronto screenshot fornito dal
      proprietario prima/dopo

## Decisioni

- **2026-09-10 — Consultato il direttore-artistico due volte**: prima ha
  proposto un'icona pixel-art dedicata (arte nuova) per correggere la
  leggibilità; il proprietario ha invece proposto di eliminare l'icona a
  favore di un bottone testuale nella colonna. Il direttore-artistico,
  confrontando le due direzioni, ha preferito la seconda: risolve la
  leggibilità in modo più netto (elimina il glifo Unicode invece di
  limitarsi a ricolorarlo) e non richiede alcuna nuova arte.
- **2026-09-10 — Scope limitato alla sola pausa, welcome esclusa
  esplicitamente.** Il direttore-artistico aveva inizialmente raccomandato
  di applicare lo stesso cambio anche alla welcome per "parità" con PS-137;
  il proprietario ha chiarito che il vincolo reale di PS-137 era la
  destinazione condivisa (stessa istanza overlay), non lo stile del tasto
  d'ingresso — la welcome resta quindi invariata.
- **Corregge:** il criterio di accettazione e la decisione "icona
  ingranaggio fluttuante" di
  [PS-137](../4_to_test/PS-137-overlay-impostazioni-condiviso-e-paginato.md),
  limitatamente al pannello pausa.

## Documenti sincronizzati

- [x] `docs/ui-ux-flow.md` descriveva l'overlay impostazioni come apribile
      "dal tasto ingranaggio sia della welcome sia della pausa": aggiornato
      per riflettere che la pausa apre l'overlay dal bottone "IMPOSTAZIONI"
      in colonna, non più da un'icona.

## Note

Ordine/trattamento consigliato dal direttore-artistico: RIPRENDI (primary,
in alto) → CAMBIA PERSONAGGIO (secondary) → IMPOSTAZIONI (secondary, in
fondo) — l'azione che porta fuori dal contesto immediato della run va per
ultima. La larghezza attuale del pannello (454px) resta adeguata: i bottoni
si espandono al contenitore e "IMPOSTAZIONI" è più corto di "CAMBIA
PERSONAGGIO", già provato a questa larghezza con lo stesso stile.

`scripts/ui/pause_overlay.gd` non ha richiesto modifiche: il codice usa già
`%SettingsButton` (nodo univoco per nome) per segnali, disabilitazione e
focus, indipendentemente dalla sua posizione nell'albero della scena —
spostare il nodo dentro `VBox` nel `.tscn` è stata la sola modifica
necessaria. Rimossi dal `.tscn` gli `StyleBoxFlat`/`StyleBoxEmpty` dedicati
al glifo `⚙` (`StyleBoxFlat_gear_normal/_hover/_pressed`,
`StyleBoxEmpty_gear_focus`), ormai orfani; `load_steps` aggiornato da 18 a
14.

Verifica automatica eseguita:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-143 -Profile Focused `
  -FocusedSmoke tests/unit/test_ps143_pause_settings_button.gd -NoCache
.\tools\run-milestone-checks.ps1 -Milestone PS-143 -Profile Relevant `
  -FocusedSmoke tests/unit/test_ps143_pause_settings_button.gd -NoCache
```

`Focused`: 1/1 verde (marker `PS143_PAUSE_SETTINGS_BUTTON_OK` stampato).
`Relevant`: 1/1 focused + 28/28 regressioni verdi, incluso
`test_ps137_shared_settings_overlay.gd` rinominato
(`test_pause_gear_focus_chain` → `test_pause_settings_button_focus_chain`) e
`test_b18n_pause_change_character.gd` (flusso cambio personaggio invariato).
Gate manuali (Windows/APK/Pixel 9/percettivo) non eseguiti in questa
sessione: restano aperti.
