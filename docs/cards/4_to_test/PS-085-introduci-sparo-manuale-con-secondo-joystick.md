---
id: PS-085
titolo: Introduci lo sparo manuale come modalità alternativa allo sparo automatico
tipo: feat
area: gameplay
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-09-03
aggiornato: 2026-09-06
---

# PS-085 — Introduci lo sparo manuale come modalità alternativa allo sparo automatico

## Contesto

Oggi `WeaponController` è interamente automatico: appena il cooldown è
scaduto e `TargetingSystem.get_nearest_alive()` trova un bersaglio, il colpo
parte da solo verso di esso (`scripts/combat/weapon_controller.gd`,
`try_fire()`/`_process()`). Il giocatore non ha alcun controllo su quando o
dove sparare; l'unico input di combattimento esistente è l'abilità attiva
(`InputRouter.active_ability_requested`).

Il proprietario vuole introdurre una seconda modalità di sparo, manuale, in
cui il giocatore controlla lui stesso la direzione di mira e può smettere di
sparare per un momento, in modo tattico, prima di attivare l'abilità quando
serve.

## Comportamento atteso

Il gioco espone due modalità di sparo, selezionabili come impostazione
persistente (stesso pattern di `TouchControlSettings`,
`scripts/app/touch_control_settings.gd`, salvata su `user://`):

- **Automatico** (comportamento attuale, invariato): il personaggio spara da
  solo verso il nemico più vicino appena il cooldown lo consente.
- **Manuale**: il personaggio spara solo mentre il giocatore mira
  attivamente. Su touch compare un secondo joystick, identico a quello di
  movimento (`scenes/ui/touch_joystick.tscn`/`TouchJoystick`), che imposta la
  direzione di mira; il colpo parte verso quella direzione mentre il joystick
  è fuori dalla deadzone, e si ferma quando il giocatore lo rilascia. Su
  Windows/desktop il mouse sostituisce il secondo joystick (direzione dal
  personaggio al cursore, sparo attivo mentre il tasto di mira è tenuto); su
  gamepad lo stick destro ha lo stesso ruolo dello stick sinistro sul
  movimento.

In entrambe le modalità il pulsante abilità attiva
(`%ActiveAbilityButton`) viene riposizionato leggermente più in alto rispetto
alla posizione attuale, per lasciare spazio coerente al joystick di mira
touch anche quando non è visibile (modalità automatica): il layout HUD non
deve "saltare" quando il giocatore cambia modalità.

Cambiare modalità non altera build, upgrade o bilanciamento delle armi:
cambia solo chi decide la direzione e il momento del colpo.

## Criteri di accettazione

- [x] Con la modalità impostata su Automatico, il comportamento di
      `WeaponController` è bit-per-bit quello attuale: nessun criterio di
      questa card introduce regressioni sull'automatico esistente.
      Verificato da `test_ps085_manual_fire_mode.gd` (branch automatico
      isolato, invariato, testato anche con una mira manuale "spinta" in
      background) e dall'intera suite `Full` verde.
- [x] Con la modalità impostata su Manuale, il personaggio non spara mentre
      il joystick di mira (o il tasto di mira su Windows, o lo stick destro
      su gamepad) è a riposo, anche se un bersaglio è a portata e il
      cooldown è scaduto. Verificato end-to-end per il joystick touch
      (evento simulato attraverso `TouchJoystick → InputRouter →
      WeaponController`); mouse e stick destro condividono lo stesso
      `_refresh_aim()`/`set_manual_aim_state()` ma restano provati solo da
      revisione di codice + il gate manuale Windows/Pixel qui sotto.
- [x] In modalità Manuale, mentre il giocatore mira, i colpi partono nella
      direzione impostata dal joystick/mouse/stick destro, non
      necessariamente verso il nemico più vicino. Verificato per il
      joystick touch e per l'API diretta (stesso percorso usato da
      mouse/gamepad).
- [x] Il joystick di mira touch è visibile solo in modalità Manuale ed è
      operabile in multitouch simultaneo con il joystick di movimento e il
      pulsante abilità (tre contatti indipendenti), senza che l'uno rubi il
      puntatore dell'altro. Verificato in headless con tre indici di tocco
      indipendenti; la prova fisica a tre dita resta comunque un gate
      manuale (vedi sotto — coerente con la nota di memoria sui limiti di
      `sendevent`/SELinux sul Pixel 9 già incontrata su altre card).
- [x] Il pulsante abilità attiva resta interamente utilizzabile (posizione,
      dimensione, cooldown radiale) nella nuova posizione, in entrambe le
      modalità. Verificato via `test_b18p_touch_control_settings.gd`
      (invariato) più il tap simulato di questa card.
- [x] La modalità di sparo scelta persiste fra una run e l'altra e fra un
      riavvio dell'app e l'altro (stesso meccanismo di persistenza di
      `TouchControlSettings`). Verificato sia in-run (restart) sia su disco
      (nuova istanza di `FireModeSettings` dallo stesso file `.cfg`).
- [x] Cambiare modalità dalle impostazioni (welcome o pausa) non richiede il
      riavvio della run per avere effetto sulla run in corso, se cambiata
      dalla pausa. Verificato: il toggle applica `WeaponController` e la
      geometria dei joystick nello stesso frame, senza attendere un
      riavvio.
- [x] Nessun upgrade, passiva o abilità attiva legge o dipende dalla
      direzione di mira automatica in un modo che si rompe passando a
      manuale (es. effetti che assumono "il bersaglio colpito è sempre il
      più vicino"). Verificato per revisione di codice: nessun registry di
      effetti legge `WeaponController.get_targeting_system()` per altro che
      il chaining post-hit (indipendente dalla sorgente della mira
      iniziale); confermato anche dalla suite `Full` verde.

## Ambito

- `scripts/combat/weapon_controller.gd` — deve accettare una sorgente di
  direzione/consenso a sparare esterna in modalità manuale, invece di
  derivare sempre mira e trigger da `TargetingSystem`.
- `scripts/input/input_router.gd` — nuova intenzione di mira (vettore
  direzione + stato "sta mirando"), unificata da touch/mouse/gamepad come le
  altre.
- Nuova istanza di `scenes/ui/touch_joystick.tscn` per la mira
  (`AimTouchJoystick`), cablata come il joystick di movimento esistente
  (`InputRouter.aim_touch_joystick_path`, nuovo binding equivalente a
  `touch_joystick_path`).
- `scripts/game/movement_slice.gd` — riposizionamento di `AbilityPanel`/
  `ActiveAbilityButton` (via `set_active_ability_scale()`, nessuna modifica
  a `hud.tscn`) e posizionamento/cattura dinamica del nuovo joystick di
  mira, speculare a quello di movimento.
- `scripts/app/fire_mode_settings.gd` — nuova classe di impostazione
  persistente per la modalità di sparo, stesso pattern di
  `touch_control_settings.gd`.
- Schermate impostazioni (welcome e pausa, PS-050) — nuovo controllo
  `ManualFireCheckButton` nella sezione "CONTROLLI TOUCH" esistente (non
  una sezione dedicata: il pannello non aveva margine libero, vedi
  Decisioni).
- `scenes/game/movement_slice.tscn` — nuovi nodi/`NodePath` di cablaggio.

Non toccare:

- `RunController` e il flusso `welcome → tutorial → selezione → run → pausa`.
- Bilanciamento di danno/cadenza/upgrade delle armi: questa card cambia solo
  la sorgente della direzione di mira e del trigger, non le statistiche.
- `TargetingSystem.get_nearest_alive()` resta la sorgente di mira per la
  modalità Automatico, invariata.
- Registry di effetti (`AbilityEffectRegistry`, `UpgradeEffectRegistry`):
  nessuna logica di gameplay nei dati.

## Verifica

- Smoke: `tests/unit/test_ps085_manual_fire_mode.gd` → marker
  `MANUAL_FIRE_MODE_SMOKE_OK`. Copre: parità automatico anche con mira
  manuale attiva in background, nessun colpo a riposo in manuale, direzione
  del colpo che segue la mira (sia via joystick touch reale sia via API
  diretta) invece del bersaglio più vicino, multitouch a tre contatti
  indipendenti (movimento + mira + abilità) in headless, persistenza della
  modalità in-run (restart) e su disco (nuova istanza di
  `FireModeSettings`), sincronizzazione bidirezionale welcome↔pausa.
- `test_ps050_welcome_settings_system.gd` aggiornato (nuovo controllo
  condiviso nella lista attesa) e verde.
- `test_b18p_touch_control_settings.gd` verde, invariato nel contratto:
  il nuovo controllo non altera la geometria che quel test verificava già.
- Profilo eseguito prima della chiusura: `Full` (oltre al minimo
  `Relevant` richiesto dalla card), toolchain incluso — tutto verde, nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION` nei log.

## Gate manuali

- [ ] Runtime Windows (mira con mouse) — non eseguibile in questa sessione
      (nessun accesso a un binario Windows interattivo); automatico verde.
- [ ] Validazione statica APK — non eseguita in questa sessione.
- [ ] Runtime fisico Pixel 9 (percorso: aprire una run, passare a Manuale
      dalle impostazioni, verificare multitouch a tre dita — movimento, mira,
      abilità — poi tornare ad Automatico e confermare che il comportamento
      sia quello di sempre). Non eseguibile in questa sessione: nessun
      device collegato. Coerente con la nota di memoria sui limiti noti di
      `sendevent`/SELinux sul Pixel 9 per le prove multitouch automatizzate.
- [ ] Controllo percettivo richiesto: sì (nuova posizione del pulsante
      abilità e nuovo joystick devono restare dentro la safe area su 16:9,
      20:9 e 4:3, senza sovrapporsi a HUD o carte upgrade; verificare anche
      che il pannello impostazioni scorra in modo leggibile sui profili più
      compatti, vedi Decisioni). Non eseguito: richiede occhio umano su
      device/finestra reale.

## Decisioni

- **2026-09-03 — Cambio modalità tramite impostazione persistente.** Non un
  toggle in-run né una scelta per personaggio: stesso meccanismo di
  `TouchControlSettings`, accessibile da welcome e pausa (coerente con
  PS-050). Il proprietario ha scelto questa opzione fra le alternative
  proposte (scelta per personaggio, pulsante di switch in-run).

- **2026-09-03 — Mira non-touch: mouse su Windows, stick destro su gamepad.**
  Schema twin-stick standard. Il proprietario ha scartato l'alternativa in
  cui Windows/gamepad restano sempre a mira automatica anche in modalità
  Manuale (controllando solo il "quando", non il "dove"): la direzione
  libera vale su tutte le piattaforme, non solo touch.

- **2026-09-03 — Il pulsante abilità si sposta in entrambe le modalità.**
  Richiesta esplicita del proprietario: la nuova posizione, più in alto,
  vale sia in Automatico sia in Manuale, così il layout non cambia quando si
  cambia modalità.

- **2026-09-06 — Margini di riposizionamento risolti in implementazione.**
  `TouchJoystick` a origine dinamica non disegna nulla a riposo
  (`_draw()` esce subito se `dynamic_origin && not is_active()`): il
  joystick di mira è quindi invisibile finché non viene toccato, e non
  serve riservargli l'intera altezza di controllo. Il pulsante abilità sale
  di una costante fissa (`ability_panel_aim_lift`, 72px di default,
  esportata su `movement_slice.gd`), non dell'altezza piena del joystick —
  un tentativo iniziale con quest'ultima spostava il pulsante fuori
  posizione in modo vistoso. La cattura dinamica si divide invece a metà
  fra i due joystick solo quando il Manuale è attivo (in Automatico il
  movimento mantiene l'intera safe area, come B18L, criterio di non
  regressione rispettato).
- **2026-09-06 — Il toggle SPARO MANUALE non ha una sezione dedicata.**
  Aggiungerlo come sezione propria (separatore + titolo + controllo)
  sforava di 45px la safe area a 960×720 su un pannello impostazioni che
  aveva già solo ~5px di margine libero (contratto verificato da
  `test_b18p_touch_control_settings.gd`, PS-050/PS-067). Il controllo vive
  invece come riga aggiuntiva nella sezione "CONTROLLI TOUCH" esistente.
  Anche una sola riga sforava comunque il margine residuo: il contenuto
  impostazioni di welcome e pausa ora scorre internamente
  (`ScrollContainer` con altezza clampata al minimo fra altezza naturale e
  spazio davvero disponibile — `_clamp_settings_scroll_height()` in
  `welcome_screen.gd`, `_clamp_pause_scroll_height()` in
  `pause_overlay.gd`) invece di sforare il viewport. Sui profili con
  margine sufficiente il risultato è identico a prima (nessuno scroll
  visibile). Il proprietario non è stato consultato su questa scelta
  strutturale nel dettaglio implementativo, ma sulla direzione generale sì
  (vedi conversazione): rendere scorrevole il contenuto invece di
  accorciare altrove o limitare il controllo alla sola pausa.
- **Aperto:** l'aspetto risultante dello scroll (leggibilità, se serve un
  indicatore di scroll più visibile) e la sensazione al tatto del secondo
  joystick restano un controllo percettivo Windows/Pixel 9, non ancora
  eseguito in questa sessione.

## Documenti sincronizzati

- [x] `docs/ui-ux-flow.md` — documentata la nuova intenzione
      `manual_aim_changed` di `InputRouter` (tre sorgenti in ordine di
      priorità) e la nuova posizione del pulsante abilità/joystick di mira.
- [x] `docs/systems-difficulty.md` — nuova sezione "Sparo manuale e
      responsabilità del DPS (PS-085)": la modalità Manuale sposta parte
      della responsabilità del DPS sul giocatore; le curve restano tarate
      sull'Automatico finché un playtest percettivo non richiede un
      riequilibrio dedicato.

## Note

Il design alla base, nelle parole del proprietario: lo sparo manuale serve a
far sì che il giocatore possa smettere per un momento di sparare — a
differenza dell'automatico, che spara sempre appena c'è un bersaglio — per
poi premere il pulsante abilità al bisogno. È un controllo tattico in più,
non solo una diversa fonte di input per la stessa cadenza automatica.
