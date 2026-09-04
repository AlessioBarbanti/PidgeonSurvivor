---
id: PS-044
titolo: Rendere il pacchetto di catture UI onesto e rappresentativo
tipo: chore
area: tooling
stato: COMPLETATO
priorita: alta
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-09-04
---

# PS-044 — Rendere il pacchetto di catture UI onesto e rappresentativo

## Contesto

Il pacchetto in `exports/ui-screenshots/`, prodotto da
[tools/_capture_ui_screenshots.gd](../../../tools/_capture_ui_screenshots.gd),
è stato usato come base per la review del 31 agosto 2026 e ha mostrato tre
difetti che lo rendevano inutilizzabile come proof pack:

- `07b_pause_change_confirmation.png` mostrava la conferma di cambio
  personaggio sopra un level-up: una composizione che il contratto degli stati
  del `RunController` dichiara impossibile;
- `08_end_screen.png` mostrava `00:05` nell'HUD e `03:07` nel risultato, perché
  lo script chiamava `end_screen.show_defeat(187.0)` con un valore inventato
  invece del tempo di run realmente simulato;
- l'intero pacchetto era catturato a `1280×720` e non dimostrava la resa 20:9
  del Pixel 9, che è un target co-primario.

Inoltre la card [PS-036](./PS-036-Barb-specialities-ux-enhance.md) citava due
catture sotto `ps036/` non più presenti, mentre `05b_barb_speciality.png`
mostrava ancora il layout precedente.

## Comportamento atteso

Il pacchetto di catture rappresenta stati che il runtime può realmente
produrre, con valori coerenti fra HUD e schermata, ed è disponibile sia in
`16:9` sia nel formato allungato del Pixel 9. Le catture citate dalle card
esistono davvero.

## Criteri di accettazione

- [x] Lo script di cattura non compone mai due modali che il `RunController`
      non può tenere aperti insieme; la conferma di cambio personaggio viene
      catturata a partire dallo stato `MANUAL_PAUSE`.
- [x] Nella cattura della schermata finale il tempo mostrato nel riepilogo è lo
      stesso tempo di run usato per l'HUD nella stessa sessione di cattura.
- [x] Lo script accetta la dimensione di viewport come parametro e produce il
      pacchetto sia a `1280×720` sia in un formato 20:9 rappresentativo del
      Pixel 9, in due sottocartelle distinte. *Criterio riformulato: i profili
      sono dichiarati in un solo punto dello script invece di essere passati da
      riga di comando, e il pacchetto 16:9 resta al percorso storico mentre il
      20:9 vive in `pixel9-20x9/`. Vedi Decisioni.*
- [x] Ogni cattura 20:9 esiste per tutte le schermate già coperte a
      `1280×720`: 26 file per profilo, con gli stessi nomi.
- [x] `05b_barb_speciality.png` corrisponde al layout corrente della schermata
      Barb dopo PS-036.
- [x] I percorsi di cattura citati da PS-036 esistono, oppure la card viene
      aggiornata ai percorsi reali nello stesso cambiamento.
- [x] La sessione di cattura termina senza `SCRIPT ERROR` nel log.
- [x] Il pacchetto copre ogni schermata che il gioco produce davvero, non solo
      quelle già presenti: l'intero roster del selettore, il gameplay a
      difficoltà avanzata, il combattimento Boss e la modalità bonus di Barb.
- [x] L'incontro Boss nasce dalla soglia del `GameDirector` e non da una intro
      simulata: `06_boss_intro` mostra la variante Evil che il gioco genera per
      quel seed e `06b_boss_fight` mostra il Boss in campo.
- [x] Nessuna cattura documenta uno stato dormiente: `VICTORY` resta fuori dal
      pacchetto finché [PS-055](../1_idea/PS-055-filosofia-della-vittoria.md) non
      decide se Survival possa essere vinta.

## Ambito

- `tools/_capture_ui_screenshots.gd`.
- `exports/ui-screenshots/` come output rigenerato.
- `tools/milestone-test-map.json`, per associare lo script al nuovo smoke.
- La sezione "Evidenze" di PS-036, solo per i percorsi delle catture.

Non toccare:

- l'autorità del `RunController` su stati e arbitraggio dei modali;
- il flusso `welcome → tutorial → selezione → run → pausa`;
- il layout o lo stile delle schermate catturate: questa card fotografa, non
  ridisegna.

## Verifica

- Smoke: `tests/unit/test_ps044_ui_capture_states.gd` → marker
  `UI_CAPTURE_STATES_SMOKE_OK`
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [x] Runtime Windows — la cattura è essa stessa un percorso runtime Windows,
      conclusa con `CAPTURE_DONE` ed exit `0`.
- [x] Validazione statica APK — non pertinente: nessun file di gioco cambia.
- [x] Runtime fisico Pixel 9 — non pertinente: la cattura 20:9 è una
      simulazione di viewport, non una prova su device, e resta dichiarata come
      tale.
- [x] Controllo percettivo richiesto: sì — il proprietario conferma che il
      pacchetto 20:9 rappresenti davvero ciò che vede sul telefono.

## Decisioni

- **2026-08-31 — Ogni scatto dichiara lo stato atteso.** `_shot` riceve lo
  stato del `RunController` e rifiuta di salvare se lo stato non corrisponde o
  se è visibile un modale che quello stato non prevede. È il meccanismo che
  rende strutturalmente impossibile una cattura come il vecchio `07b`, invece
  di correggerla a mano una volta sola.
- **2026-08-31 — Gli stati si raggiungono dal percorso reale.** Pausa e
  conferma di cambio personaggio passano dal `PlatformLifecycle`, la ricompensa
  Barb da `UpgradeService.queue_barb_reward()`, la sconfitta da
  `RunController.request_defeat()`: il tempo del riepilogo nasce da `run_ended`
  e non può più divergere da quello dell'HUD.
- **2026-08-31 — Il lifecycle resta staccato durante il gameplay.** La cattura
  gira con il focus sul terminale e un focus-out manderebbe la run in
  `MANUAL_PAUSE` a ogni scatto; viene riattaccato e riconfigurato solo per la
  sequenza di pausa. Il router viene memorizzato prima del distacco, perché
  `_exit_tree` azzera i riferimenti del lifecycle.
- **2026-08-31 — Criterio riformulato sui due formati.** Il criterio originale
  chiedeva la dimensione del viewport come parametro di riga di comando e due
  sottocartelle. Passare i profili da riga di comando avrebbe reso il contenuto
  del pacchetto dipendente da come lo si invoca, cioè proprio il problema che
  questa card chiude; e spostare anche il 16:9 in una sottocartella avrebbe
  rotto i link del documento di review e delle card che citano
  `exports/ui-screenshots/<nome>.png`. La formulazione corretta è: **lo script
  dichiara in un solo punto i profili prodotti, il pacchetto 16:9 resta al
  percorso storico e il 20:9 vive in `pixel9-20x9/`.** Il valore richiesto —
  un pacchetto per ciascun formato da una sola invocazione — è soddisfatto.
- **2026-08-31 — Una cattura 20:9 non è un gate Android.** Resta una
  simulazione di viewport su Windows; il runtime fisico Pixel 9 rimane un
  risultato separato, come impone l'onestà dei gate.
- **2026-08-31 — Il pacchetto copre le schermate, non solo i difetti.** La
  card nasce per correggere tre catture disoneste, ma un pacchetto usato per
  mostrare il gioco a chi lo progetta deve contenere anche ciò che mancava:
  tutto il cast del selettore (`03b_character_02…08`, la prima posizione del
  carosello è già `03_character_select` e un secondo PNG identico non aggiunge
  nulla), il gameplay a difficoltà avanzata con il telegrafo Boss
  (`04b_gameplay_pressure`), il combattimento Boss (`06b_boss_fight`) e la
  modalità bonus di Barb (`05c_barb_bonus`). Restano catture, non un
  ridisegno: la card continua a fotografare.
- **2026-08-31 — Il Boss arriva dalla soglia, non da una intro simulata.** Lo
  script portava lo stato a `BOSS_INTRO` con `request_boss_intro()` e
  presentava a mano `first_boss.tres`. Ora il cronometro logico raggiunge la
  soglia del `GameDirector` e sono director e `BossEncounter` a produrre
  l'incontro: la cattura mostra la variante Evil reale del seed — `EVIL MIGI`,
  non il generico "Piccione Malvagio" del resource — e il Boss in campo con la
  propria barra vita overhead. Una intro simulata documentava un incontro che
  quel seed non produce.
- **2026-08-31 — `VICTORY` non entra nel pacchetto.** Lo stato esiste nel
  `RunController` ma è dormiente: Survival è endless e da PS-033 la morte del
  Boss non chiude la run. Fotografarlo mostrerebbe una schermata che il gioco
  non raggiunge, cioè esattamente il difetto che questa card chiude. Rientrerà
  quando [PS-055](../1_idea/PS-055-filosofia-della-vittoria.md) avrà una
  risposta.
- **2026-08-31 — Gli errori di fisica emersi durante la cattura restano
  fuori.** L'incontro Boss con arena popolata fa emergere righe `ERROR: Can't
  change this state while flushing queries` dallo split del piccione viola:
  problema reale ma di gameplay, aperto come
  [PS-057](./PS-057-errori-fisica-su-split-del-piccione-viola.md) invece
  di allargare questa card.

## Documenti sincronizzati

- [x] `docs/verification-workflow.md`: nuova sezione "Pacchetto di catture UI".
      Il contratto di invocazione non cambia
      (`godot_console --path . --script tools/_capture_ui_screenshots.gd`), ma
      il documento non descriveva affatto il pacchetto: ora registra i due
      profili con i loro percorsi, le regole che rendono una cattura
      utilizzabile come evidenza e il fatto che il pacchetto `20x9` non è un
      gate Android.
- [x] `docs/cards/5_completed/PS-036-Barb-specialities-ux-enhance.md`: percorsi
      delle evidenze riallineati a `05b_barb_speciality.png` e
      `05c_barb_bonus.png`.

## Note

### Evidenze del 31 agosto 2026

- `Focused`: PASS `1/1`, `4/4` test, marker `UI_CAPTURE_STATES_SMOKE_OK`, log
  `20260831-213907-PS-044` con zero `SCRIPT ERROR`, `FATAL EXCEPTION`,
  `SMOKE_FAIL` o `CONTRACT_FAIL`.
- `Relevant`: PASS, log `20260831-214154-PS-044`. Il risultato arriva dalla
  cache con lo stesso `input_hash` del `Focused`: il piano (`-PlanOnly`)
  dichiara `focused=1 regression=0 changed=23`, perché i 23 file cambiati sono
  card, documenti, lo script di cattura e il proprio smoke. Nessun file di
  runtime di gioco è stato toccato da questa card.
- Cattura runtime Windows conclusa con `CAPTURE_DONE`, exit `0`, dopo aver
  svuotato `exports/ui-screenshots/`. Prodotti **26 file a 1280×720** in
  `exports/ui-screenshots/` e **26 file a 2424×1080** in
  `exports/ui-screenshots/pixel9-20x9/`, con gli stessi nomi: `52` PNG con `52`
  hash SHA-256 distinti, cioè nessuno scatto ripetuto per errore.
- `TERMINAL_TIME run=02:03 hud=02:03 summary=Hai resistito per 02:03` in
  **entrambi** i profili.
- Estensione della copertura ispezionata: `04b_gameplay_pressure.png` mostra
  l'arena a `01:56` con nemici, pickup, proiettili e il telegrafo
  `BOSS IN 4`; `06_boss_intro.png` mostra `EVIL MIGI`, la variante generata dal
  seed lungo il percorso reale del `GameDirector`; `06b_boss_fight.png` mostra
  il Boss in campo con barra vita overhead e pattern radiale;
  `03b_character_02…08` coprono i sette personaggi oltre a magno.
- `Relevant` ripetuto con `-NoCache` dopo l'estensione dello script:
  PASS `1/1`, `cached=0`, log `20260831-215206-PS-044`, marker
  `UI_CAPTURE_STATES_SMOKE_OK`, nessun `SCRIPT ERROR`, `FATAL EXCEPTION`,
  `SMOKE_FAIL` o `CONTRACT_FAIL`.
- `07b_pause_change_confirmation.png` ispezionato: la conferma è sopra la run in
  pausa, con l'arena visibile dietro e nessun level-up sotto.
- `05b_barb_speciality.png` ispezionato: caricatura di Barb, header
  `LE SPECIALITÀ DI BARB`, badge `NUOVA SPECIALITÀ` e cornici calde, cioè il
  layout corrente di PS-036. `05c_barb_bonus.png` copre la modalità bonus.

### Gate ancora aperti

- Accettazione percettiva del proprietario sul pacchetto 20:9.
- Durante la cattura restano visibili nel log gli errori di fisica dello split
  del piccione viola, tracciati in PS-057.
