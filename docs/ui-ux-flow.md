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
(`scripts/ui/end_screen.gd`).

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

- `BOOT` → `_on_boot_back_requested` (`movement_slice.gd:1861-1869`): prima
  `TutorialScreen.handle_back_requested()` se visibile, poi
  `CharacterSelectOverlay` (torna a Welcome), poi
  `WelcomeScreen.handle_back_requested()` (chiude solo il pannello
  impostazioni se aperto).
- `RUNNING` → apre la pausa (`request_manual_pause()`).
- `MANUAL_PAUSE` → prima `PauseOverlay.handle_back_requested()` (chiude solo
  la sotto-conferma "cambia personaggio" se visibile), altrimenti
  `request_resume()`.
- **Ogni altro stato** (`LEVEL_UP`, `BOSS_INTRO`, `BARB_REWARD`, `VICTORY`,
  `DEFEAT`) → il Back sospende solo l'input e non fa altro (righe 88-90): è
  inerte durante questi modali, non può mai chiuderli né uscire dalla run.

L'esclusività dei modali è garantita a monte dall'enum di stato di
`RunController`: essendo `_state` un singolo valore, `LEVEL_UP`,
`BOSS_INTRO`, `BARB_REWARD` e `MANUAL_PAUSE` non possono mai coesistere.

## HUD e modali di run

- **HUD** (`scripts/ui/hud.gd`) — sempre visibile durante `RUNNING`: barre
  XP/HP senza numeri o testo (`get_health_text()`/`get_experience_text()`/
  `get_level_text()` ritornano sempre `""`, righe 190-199), cronometro
  (`_on_run_time_changed`, :597), warning Boss (`_on_boss_warning_changed`,
  :615, copy descritto in [systems-difficulty.md](./systems-difficulty.md)),
  telegraph delle ondate (`_on_wave_event_telegraph_changed`, :642), pulsante
  pausa abilitato solo se `is_running()` (`_set_pause_available`, :665) e
  pulsante abilità attiva touch (`TouchAbilityButton`, con dissolvenza al
  passaggio del player, righe 286-330).
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

**Nota.** `RunController.request_victory()` è definito e collegato (EndScreen,
HUD, audio), ma nessun punto del codice lo invoca oggi: l'unico terminale
raggiungibile in pratica è `request_defeat()`, cablato in
`_on_player_died` (`movement_slice.gd:1742-1747`). Coerente con B33
("la morte di un Boss non chiude la run: i Boss ricorrono"), ma il ramo
`VICTORY` resta stato/UI dormiente nel codice attuale.

## `InputRouter` — input unificato

[scripts/input/input_router.gd](../scripts/input/input_router.gd) unifica
tastiera (`Input.get_vector` sulle action di movimento, righe 296-302),
gamepad (stesse action, mappate su `InputMap`) e touch (`TouchJoystick`
legato via `bind_touch_joystick`, righe 73-87) in due intenzioni pubbliche:

- `movement_vector: Vector2` (segnale `movement_vector_changed`) — se il
  joystick touch è attivo prevale su tastiera/gamepad (`_refresh_movement`,
  righe 258-260).
- `active_ability_requested` — emesso da `request_active_ability()` (:107),
  collegabile sia al `TouchAbilityButton` sia alla action da
  tastiera/gamepad `active_ability` (`_refresh_active_ability`, righe
  279-286).

`movement_slice.gd:77` collega `movement_vector_changed` al Player;
`AbilityController` si collega direttamente a `InputRouter`
(`movement_slice.gd:204-209`).

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
  `get_visible_reference_rect()` (righe 109-119): stessa dimensione del
  playfield ma **ricentrata sulla vista camera corrente**.
- Adattamento a risoluzioni diverse (Windows vs Android landscape):
  `movement_slice._apply_layout()` (righe 333-373) posiziona la safe area
  root sulla safe area calcolata da `ArenaLayout`, ma ancora le barre XP/HP
  al **viewport** con margini simmetrici percentuali
  (`_apply_bar_horizontal_margins`, righe 376-390) — così le barre non
  restano "attaccate" da un lato quando la safe area è asimmetrica (notch o
  cutout Android). Nessuna coordinata `1280×720` hardcoded, coerente con
  `CLAUDE.md`.

## Gate aperti

Questo documento è stato scritto per lettura statica del codice, non per
prova su device: il comportamento runtime di `PlatformLifecycle` e
`ArenaLayout` su Android fisico resta un gate di verifica separato (vedi
`docs/verification-workflow.md` e le note `Onestà dei gate` di `CLAUDE.md`),
non chiuso da questo documento.
