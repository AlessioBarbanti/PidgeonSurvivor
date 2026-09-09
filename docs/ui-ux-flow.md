# UI/UX e flusso schermate

Questo documento descrive lo stato attuale del flusso schermate, dei modali
di run e dei sistemi di input/lifecycle. Non è un backlog: lo stato
operativo resta nella [board](./cards/README.md).

## Flusso `welcome → (tutorial) → selezione → run → pausa`

Tutte le schermate sono figlie della stessa scena
[scenes/game/movement_slice.tscn](../scenes/game/movement_slice.tscn),
orchestrate da
[scripts/game/movement_slice.gd](../scripts/game/movement_slice.gd):
`WelcomeScreen` (`scripts/ui/welcome_screen.gd`), `TutorialScreen`
(`scripts/ui/tutorial_screen.gd`), `CharacterSelectOverlay`
(`scripts/ui/character_select_overlay.gd`), la HUD di run (`scripts/ui/hud.gd`,
`GameHud`), `PauseOverlay` (`scripts/ui/pause_overlay.gd`) ed `EndScreen`
(`scripts/ui/end_screen.gd`). `SettingsOverlay`
(`scripts/ui/settings_overlay.gd`, PS-137) è un'istanza unica separata,
apribile dal tasto ingranaggio sia della welcome sia della pausa: non fa
parte della sequenza sopra, resta un layer puramente visivo sopra lo stato
attivo (`BOOT` o `MANUAL_PAUSE`).

Transizioni (tutte in `movement_slice.gd`):

- `_show_welcome_screen()` (:907) e `_show_tutorial_screen()` (:921) agiscono
  solo se `RunController.get_state() == BOOT`.
- `_on_welcome_play_requested` → `_show_character_selection()` (:1830-1834).
- `_on_welcome_tutorial_requested` → `_show_tutorial_screen()` (:1837-1841).
- `_on_tutorial_play_requested` → `_show_character_selection()` (:1849-1853).
- `_on_tutorial_close_requested` → torna a `_show_welcome_screen(true)`
  (:1844-1846).
- `_on_character_selection_back_requested` → torna a `_show_welcome_screen()`
  (:1856-1858).
- `_on_friend_confirmed` → `select_friend_for_next_run` +
  `_start_selected_run()` (:1820-1827, :877): chiama
  `RunController.start_run(seed)`, che riesce solo da `BOOT`
  (`run_controller.gd:50-59`); solo in caso di successo nasconde
  welcome/tutorial/selezione e mostra HUD e joystick.

**`BOOT` resta attivo finché il giocatore non conferma**: `start_run()` è
l'unica via d'uscita da `BOOT` e richiede esplicitamente quello stato
(`run_controller.gd:51`). Nessuna transizione automatica lo supera; resta
finché il giocatore non preme "GIOCA con `<Nome>`" nel selettore
(`_on_confirm_pressed`, `character_select_overlay.gd:592-596` → segnale
`friend_confirmed`).

**Back/annulla chiude solo il modale in cima, mai la run.** L'arbitro è
`PlatformLifecycle.request_back()`
([scripts/input/platform_lifecycle.gd:66-91](../scripts/input/platform_lifecycle.gd)),
che smista in base allo stato di `RunController`:

- `BOOT` → `_on_boot_back_requested` (`movement_slice.gd:2216`): prima
  `TutorialScreen.handle_back_requested()` se visibile, poi
  `CharacterSelectOverlay` (torna a Welcome), poi
  `WelcomeScreen.handle_back_requested()` — che (PS-137) delega prima
  all'overlay impostazioni condiviso se aperto (`SettingsOverlay.handle_back_requested()`),
  altrimenti non ha più nulla da chiudere localmente.
- `RUNNING` → apre la pausa (`request_manual_pause()`).
- `MANUAL_PAUSE` → `PauseOverlay.handle_back_requested()`, che (PS-137)
  controlla prima l'overlay impostazioni condiviso (se aperto lo chiude e
  basta), poi la sotto-conferma "cambia personaggio" se visibile, altrimenti
  `request_resume()`.
- **Ogni altro stato** (`LEVEL_UP`, `BOSS_INTRO`, `BARB_REWARD`, `VICTORY`,
  `DEFEAT`) → il Back sospende solo l'input e non fa altro (righe 88-90): è
  inerte durante questi modali, non può mai chiuderli né uscire dalla run.

L'esclusività dei modali è garantita a monte dall'enum di stato di
`RunController`: essendo `_state` un singolo valore, `LEVEL_UP`,
`BOSS_INTRO`, `BARB_REWARD` e `MANUAL_PAUSE` non possono mai coesistere.

### Composizione del selettore personaggi

Il selettore ([scenes/ui/character_select_overlay.tscn](../scenes/ui/character_select_overlay.tscn))
è organizzato attorno a due domande distinte: **chi sto scegliendo** a
sinistra, **come gioca** a destra.

- **Busto del Friend** (`%BustPortrait`) — è la rappresentazione primaria del
  personaggio selezionato e risolve `FriendDefinition.get_public_portrait()`,
  cioè i ritratti busto prodotti da PS-068
  (`assets/art/characters/<id>/generated/portrait.png`, `256×256`). Non è
  chiuso in un pannello: la silhouette trasparente partecipa alla
  composizione. `_layout_portrait_stage()` gli assegna sempre l'intera colonna
  Friend (`bust_side = min(stage.x, stage.y)`), a qualunque aspect ratio: non
  esiste più un ramo "identità accanto al busto". L'arte a figura intera
  `selection_portrait` (`carousel.png`) non compare più in questa schermata:
  resta nei dati come rappresentazione di gameplay.
- **Blocco identità** (`%IdentityBlock`) — nome in oro, filo ornamentale e
  ruolo, **sovrapposto** al bordo inferiore del busto (non più sotto in una
  riga propria, né accanto): busto e identità sono un unico blocco verticale.
  La larghezza non è più quella della colonna ma `IDENTITY_BUST_WIDTH_RATIO`
  (1,5) volte il lato del busto, centrata su di lui: il filo dorato è il
  basamento del personaggio, non un separatore di schermata, e non arriva a
  filo delle card. Il blocco chiude la colonna Friend, non il busto: dove il
  busto è limitato dalla larghezza resterebbe spazio morto sotto di lui, e
  agganciare lì nome e ruolo alzerebbe il filo togliendo altezza alle card.
  Sui formati in cui il busto riempie la riga le due quote coincidono. Per
  restare leggibile su qualunque costume, un `%IdentityBackdrop`
  (`GradientTexture2D` radiale generato proceduralmente, nessun asset)
  disegna un alone scuro sfumato dietro al testo, largo il 78% del blocco.
- **Pannelli Passiva / Abilità attiva** — occhielli ciano come colore di
  sistema, titoli in oro, icona `136×136`. La colonna `%AbilityCards` è
  **allineata al bordo superiore del busto** e si ferma
  `ABILITY_CARDS_RULE_GAP` (18px) **sopra il filo dorato dell'identità**: la
  fascia che quel filo disegna resta continua invece di essere attraversata
  dalla colonna informativa. `_sync_ability_card_heights()` divide quel budget
  fra le due card, che restano quindi identiche fra loro e — a parità di
  formato — identiche per tutti e otto i Friend: sfogliare il roster non fa
  ballare la colonna. Se il testo di un Friend non entra nel budget vince il
  testo: la card cresce oltre il filo invece di troncare.
  La larghezza è dinamica: `_on_overlay_resized()` la calcola come
  `ABILITY_CARDS_WIDTH_RATIO` (42%) della larghezza di contenuto del pannello,
  clampata fra `ABILITY_CARDS_MIN_WIDTH` (520 — sotto questa soglia la colonna
  di testo interna costringe le descrizioni su una riga in più e le card non
  stanno più nel budget) e `ABILITY_CARDS_MAX_WIDTH` (580), poi limitata dallo
  spazio che resta togliendo la larghezza minima della colonna Friend. Il
  busto non paga questo allargamento: è limitato dall'altezza della riga, non
  dalla larghezza della colonna, quindi le card recuperano spazio vuoto e non
  presenza del personaggio.
- **Fascia roster** (`%RosterRow`) — una strip che **scorre** attorno al Friend
  selezionato, il quale resta sempre al centro: mostra
  `ROSTER_VISIBLE_SLOTS` (7) miniature, tre per lato, e con otto Friend il
  diametralmente opposto resta fuori e rientra ruotando. Le miniature
  ritagliano il busto sul volto con un'unica regione condivisa
  (`ROSTER_HEADSHOT_REGION`), uguale per tutti, senza adattamenti
  per-personaggio. Il selezionato porta la cornice `pause_panel_frame.png`,
  gli altri restano rientrati e attenuati **a tinta piena**: con un alpha < 1
  il busto sconfinante traspariva attraverso le card. Indice, wrap circolare,
  frecce, swipe e tap restano quelli di `_navigate`: cambia dove vengono
  disegnate le card, non la logica di selezione.
- **Gerarchia cromatica** — oro/arancio per personaggio, nomi e CTA;
  ciano/teal per etichette e segnali di sistema; avorio caldo per il titolo
  `SCEGLI IL PERSONAGGIO`, che non compete più come terzo punto focale.

Il pannello non è più una scatola fissa `910×490`: `_on_overlay_resized()` lo
fa crescere con la viewport fra `PANEL_MIN_SIZE` e `PANEL_MAX_SIZE`
(`1400×760`), così il 20:9 usa larghezza reale. I margini sono asimmetrici
(`PANEL_MARGIN_LEFT` 32 contro 20 a destra e 14 in verticale): in landscape il
ritaglio fotocamera del Pixel 9 sta a sinistra, quindi quel lato conserva più
guardia oltre alla safe area di sistema già applicata da `SafeAreaRoot`.

## HUD e modali di run

- **HUD** (`scripts/ui/hud.gd`) — sempre visibile durante `RUNNING`: barre
  XP/HP senza numeri o testo (`get_health_text()`/`get_experience_text()`/
  `get_level_text()` ritornano sempre `""`, righe 190-199), cronometro
  (`_on_run_time_changed`, :597), warning Boss (`_on_boss_warning_changed`,
  :615, copy descritto in [systems-difficulty.md](./systems-difficulty.md)),
  telegraph delle ondate (`_on_wave_event_telegraph_changed`, :642), pulsante
  pausa abilitato solo se `is_running()` (`_set_pause_available`, :665) e
  pulsante abilità attiva touch (`TouchAbilityButton`, con dissolvenza al
  passaggio del player, righe 286-330). **PS-085**: il pulsante è più in
  alto rispetto al bordo inferiore che occupava prima, in entrambe le
  modalità di sparo — lo spazio liberato è l'angolo di riposo del nuovo
  `AimTouchJoystick`, visibile solo in modalità Manuale
  (`_sync_aim_touch_joystick_visibility`, `movement_slice.gd`).
- **Level up** — `UpgradeOverlay` (`scripts/ui/upgrade_overlay.gd`): appare
  su `offer_generated` di `UpgradeService` (:327), innescato quando
  `ExperienceSystem` chiama `RunController.request_level_up()`. Mostra 3
  carte, con un lock anti-tap di `0.45s` (`SELECTION_LOCK_SECONDS`, :9); si
  chiude selezionando una carta →
  `UpgradeService.select_upgrade()` → `ExperienceSystem.complete_level_up()`
  → `RunController.complete_level_up()`.
- **Boss** — `BossUI` (`scripts/ui/boss_ui.gd`): l'intro parte da
  `BossEncounter._spawn_boss()` (`boss_encounter.gd:348`) dopo
  `RunController.request_boss_intro()`; si chiude col pulsante "Continua" →
  `intro_continue_requested` → `BossEncounter._on_intro_continue_requested`
  → `complete_intro()` → `RunController.complete_boss_intro()`.
- **Ricompensa Barb (PS-012)** — `BarbRewardOverlay`
  (`scripts/ui/barb_reward_overlay.gd`): alla morte del Boss,
  `UpgradeService.queue_barb_reward()` entra in `BARB_REWARD` solo quando la
  run è `RUNNING` (`_try_start_barb_reward`, righe 384-394 — se un
  `LEVEL_UP` è in corso, la richiesta resta in coda e riparte da sé al
  ritorno in `RUNNING`). Due modalità: sblocco di una Specialità del roster
  Barb, oppure — quando tutte sono già sbloccate — bonus ripetuto. Si chiude
  selezionando una carta → `_finish_barb_reward()` →
  `RunController.complete_barb_reward()`.
- **`EndScreen`** (`scripts/ui/end_screen.gd`): mostrata da
  `_on_run_ended` → `_show_terminal_screen()` (`movement_slice.gd:1750-1801`)
  su `VICTORY`/`DEFEAT`. Pulsanti "RIPROVA/NUOVA RUN"
  (`restart_requested`) e "Cambia personaggio" (`change_character_requested`).

**Decisione (PS-055, 2026-09-07).** Sopravvivenza è endless: lo scopo è
sopravvivere il più a lungo possibile, non "vincere". `RunController
.request_victory()` è definito e collegato (EndScreen, HUD, audio), ma
nessun punto del codice lo invoca: l'unico terminale raggiungibile in
pratica è `request_defeat()`, cablato in `_on_player_died`
(`movement_slice.gd:1742-1747`). Coerente con B33 ("la morte di un Boss non
chiude la run: i Boss ricorrono"). Il ramo `VICTORY` resta stato/UI
dormiente per scelta, non per lacuna: sarà riservato a una futura modalità
con una condizione di vittoria propria (Difesa Grigliata, §3.5A del PRD),
non a Sopravvivenza.

## `InputRouter` — input unificato

[scripts/input/input_router.gd](../scripts/input/input_router.gd) unifica
tastiera (`Input.get_vector` sulle action di movimento, righe 472-478),
gamepad (stesse action, mappate su `InputMap`) e touch (`TouchJoystick`
legato via `bind_touch_joystick`, righe 107-121) in tre intenzioni pubbliche:

- `movement_vector: Vector2` (segnale `movement_vector_changed`) — se il
  joystick touch è attivo prevale su tastiera/gamepad (`_refresh_movement`,
  righe 354-369).
- `active_ability_requested` — emesso da `request_active_ability()` (:164),
  collegabile sia al `TouchAbilityButton` sia alla action da
  tastiera/gamepad `active_ability` (`_refresh_active_ability`, righe
  455-462).
- **`manual_aim_changed(direction, active)` (PS-085)** — mira per lo sparo
  manuale, stesso schema del movimento ma con tre sorgenti in ordine di
  priorità (`_refresh_aim`, righe 392-415): joystick touch dedicato
  (`bind_aim_touch_joystick`, :123, mentre il dito lo tiene premuto) → stick
  destro gamepad (action `aim_left`/`aim_right`/`aim_up`/`aim_down`) → mouse
  su desktop (direzione dal Player verso `get_global_mouse_position()`,
  attiva solo mentre l'action `manual_fire_hold` è premuta). `direction`
  conserva l'ultimo impegno anche quando `active` torna a `false`, come
  `_last_aim_direction` dell'automatico. `bind_aim_origin(_player)`
  (`movement_slice.gd`) è l'unica dipendenza di `InputRouter` su un nodo di
  mondo, usata solo per la proiezione del cursore.

`movement_slice.gd` collega `movement_vector_changed` al Player e
`manual_aim_changed` a `WeaponController.set_manual_aim_state()`;
`AbilityController` si collega direttamente a `InputRouter`.

Gate anti-input residuo: `suspend_input()`/`resume_input()` (righe 118-131)
con riarmo neutro (`_try_neutral_rearm`, righe 265-276) — l'input riprende
solo quando torna a zero (nessun tasto/joystick premuto), per evitare che un
input tenuto durante una pausa "scatti" alla ripresa.

## `PlatformLifecycle` — non riprende mai da sola

[scripts/input/platform_lifecycle.gd](../scripts/input/platform_lifecycle.gd)
traduce le notifiche di piattaforma in richieste a `RunController`, mai in
ripristini automatici:

- `NOTIFICATION_APPLICATION_FOCUS_OUT`/`WM_WINDOW_FOCUS_OUT` (righe 118-120)
  e `NOTIFICATION_APPLICATION_PAUSED` (123-125) →
  `_pause_for_interruption()` → `request_manual_pause()`.
- `NOTIFICATION_WM_GO_BACK_REQUEST` (Back di sistema Android) →
  `request_back()`.
- **`NOTIFICATION_APPLICATION_RESUMED`** (righe 126-127) si limita a
  `_application_paused = false`, **senza alcuna chiamata a
  `resume_run()`**. La ripresa avviene solo tramite `request_resume()`
  (righe 52-63), invocato esclusivamente dal segnale `resume_requested` di
  `PauseOverlay` — cioè da un'azione esplicita del giocatore. Verifica diretta
  del vincolo `CLAUDE.md` "non riprende mai una run automaticamente".

## `ArenaWorld` / `ArenaLayout`

Due concetti distinti:

- **`ArenaWorld`** (`scripts/game/arena_world.gd`) — mondo di gioco a
  **dimensione fissa** (`world_size := Vector2(2400.0, 1500.0)`, righe 6-8),
  indipendente dal viewport: la `Camera2D` scorre una finestra al suo
  interno. Usato per i limiti camera e lo spawn del player.
- **`ArenaLayout`** (`scripts/game/arena_layout.gd`) — deriva invece **safe
  area, playfield e fascia HUD dalla viewport corrente**, ricalcolata a ogni
  cambio: `refresh_layout()` (righe 71-121) legge
  `get_viewport().get_visible_rect()`, `DisplayServer.window_get_size()` e
  `DisplayServer.get_display_safe_area()`; applica `top_reserved_height`
  (fascia HUD) e calcola `playfield_rect` mantenendo `target_aspect_ratio`
  (16:9 di default, `calculate_playfield_rect`, righe 221-243). Si
  riaggiorna su resize/focus/resume.
- La fascia di spawn/despawn nemici (`EnemySpawner`) non usa
  `ArenaLayout.get_playfield_rect()` direttamente ma
  `get_visible_reference_rect()` (PS-095): dimensione del **viewport reale**
  (`ArenaLayout.get_viewport_rect()`, letto dal vivo a ogni chiamata, non il
  playfield ritagliato a `target_aspect_ratio`) **ricentrata sulla vista
  camera corrente**. `project.godot` dichiara
  `window/stretch/aspect="expand"`: mondo e camera riempiono l'intero
  viewport senza letterbox, quindi il playfield (più stretto su schermi più
  larghi di 16:9, es. Android landscape 20:9) non rappresenta lo schermo
  davvero visibile — usarlo per lo spawn lasciava nemici comparire dentro
  l'area visibile reale.
- Adattamento a risoluzioni diverse (Windows vs Android landscape):
  `movement_slice._apply_layout()` (righe 338-380) posiziona la safe area
  root sulla safe area calcolata da `ArenaLayout`, ma ancora le barre XP/HP
  al **viewport** con margini simmetrici percentuali
  (`_apply_bar_horizontal_margins`, righe 383-397) — così le barre non
  restano "attaccate" da un lato quando la safe area è asimmetrica (notch o
  cutout Android). Nessuna coordinata `1280×720` hardcoded, coerente con
  `CLAUDE.md`.
- **`UpgradeOverlay`/`BarbRewardOverlay` e la safe area (PS-064).** Il velo e
  il contenitore di titolo/carte di questi due modali sono `top_level`
  (necessario da PS-059 per disegnare sopra ogni altro elemento dell'HUD):
  un nodo `top_level` non eredita la trasformazione del proprio antenato,
  quindi ignorerebbe la posizione/size che `SafeAreaRoot` applicherebbe
  altrimenti. `_apply_layout()` inoltra perciò la stessa `safe_area` anche a
  `UpgradeOverlay.apply_safe_area()`/`BarbRewardOverlay.apply_safe_area()`,
  che riposizionano il loro `SafeMargins` esplicitamente. Titolo e carte si
  centrano poi sull'altezza del **viewport** (non della safe area, che può
  divergere) restando comunque vincolati a non coprire la fascia HUD
  superiore (contratto PS-046) né uscire dal bordo inferiore della safe
  area — vedi `_reflow_top_margin()` in entrambi gli script.

## Gate aperti

Questo documento è stato scritto per lettura statica del codice, non per
prova su device: il comportamento runtime di `PlatformLifecycle` e
`ArenaLayout` su Android fisico resta un gate di verifica separato (vedi
`docs/verification-workflow.md` e le note `Onestà dei gate` di `CLAUDE.md`),
non chiuso da questo documento.
