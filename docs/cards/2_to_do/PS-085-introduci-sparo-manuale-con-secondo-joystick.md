---
id: PS-085
titolo: Introduci lo sparo manuale come modalità alternativa allo sparo automatico
tipo: feat
area: gameplay
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-09-03
aggiornato: 2026-09-03
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

- [ ] Con la modalità impostata su Automatico, il comportamento di
      `WeaponController` è bit-per-bit quello attuale: nessun criterio di
      questa card introduce regressioni sull'automatico esistente.
- [ ] Con la modalità impostata su Manuale, il personaggio non spara mentre
      il joystick di mira (o il tasto di mira su Windows, o lo stick destro
      su gamepad) è a riposo, anche se un bersaglio è a portata e il
      cooldown è scaduto.
- [ ] In modalità Manuale, mentre il giocatore mira, i colpi partono nella
      direzione impostata dal joystick/mouse/stick destro, non
      necessariamente verso il nemico più vicino.
- [ ] Il joystick di mira touch è visibile solo in modalità Manuale ed è
      operabile in multitouch simultaneo con il joystick di movimento e il
      pulsante abilità (tre contatti indipendenti), senza che l'uno rubi il
      puntatore dell'altro.
- [ ] Il pulsante abilità attiva resta interamente utilizzabile (posizione,
      dimensione, cooldown radiale) nella nuova posizione, in entrambe le
      modalità.
- [ ] La modalità di sparo scelta persiste fra una run e l'altra e fra un
      riavvio dell'app e l'altro (stesso meccanismo di persistenza di
      `TouchControlSettings`).
- [ ] Cambiare modalità dalle impostazioni (welcome o pausa) non richiede il
      riavvio della run per avere effetto sulla run in corso, se cambiata
      dalla pausa.
- [ ] Nessun upgrade, passiva o abilità attiva legge o dipende dalla
      direzione di mira automatica in un modo che si rompe passando a
      manuale (es. effetti che assumono "il bersaglio colpito è sempre il
      più vicino").

## Ambito

- `scripts/combat/weapon_controller.gd` — deve accettare una sorgente di
  direzione/consenso a sparare esterna in modalità manuale, invece di
  derivare sempre mira e trigger da `TargetingSystem`.
- `scripts/input/input_router.gd` — nuova intenzione di mira (vettore
  direzione + stato "sta mirando"), unificata da touch/mouse/gamepad come le
  altre.
- Nuova istanza di `scenes/ui/touch_joystick.tscn` per la mira, cablata come
  il joystick di movimento esistente (`InputRouter.touch_joystick_path`
  diventa insufficiente da solo: serve un secondo binding equivalente).
- `scenes/ui/hud.tscn` — riposizionamento di `AbilityPanel`/
  `ActiveAbilityButton` e posizionamento del nuovo joystick di mira.
- Nuova classe di impostazione persistente per la modalità di sparo, stesso
  pattern di `scripts/app/touch_control_settings.gd`.
- Schermate impostazioni (welcome e pausa, PS-050) — nuovo controllo per
  scegliere la modalità.
- `scenes/game/movement_slice.tscn` — nuovi `NodePath` di cablaggio.

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
  `MANUAL_FIRE_MODE_SMOKE_OK`. Deve coprire almeno: nessun colpo a riposo in
  manuale, direzione del colpo segue l'input di mira in manuale, parità di
  comportamento con l'automatico attuale quando la modalità è Automatico,
  persistenza della modalità fra restart.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows (mira con mouse).
- [ ] Validazione statica APK.
- [ ] Runtime fisico Pixel 9 (percorso: aprire una run, passare a Manuale
      dalle impostazioni, verificare multitouch a tre dita — movimento, mira,
      abilità — poi tornare ad Automatico e confermare che il comportamento
      sia quello di sempre).
- [ ] Controllo percettivo richiesto: sì (nuova posizione del pulsante
      abilità e nuovo joystick devono restare dentro la safe area su 16:9,
      20:9 e 4:3, senza sovrapporsi a HUD o carte upgrade).

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

- **Aperto:** margini esatti del riposizionamento (di quanto sale il
  pulsante abilità, dimensione/posizione del joystick di mira touch) sono
  lasciati all'implementazione, purché rispettino i criteri di accettazione
  su safe area e multitouch; nessun vincolo pixel-preciso dato dal
  proprietario in questa card.

## Documenti sincronizzati

- [ ] `docs/ui-ux-flow.md` — documentare la nuova posizione del pulsante
      abilità, il joystick di mira e il controllo di modalità nelle
      impostazioni.
- [ ] `docs/systems-difficulty.md` — annotare che lo sparo manuale sposta
      parte della responsabilità del DPS effettivo sul giocatore (il tempo
      "non mirato" è tempo senza danno), se questo cambia le assunzioni di
      bilanciamento della curva di difficoltà documentate lì.

## Note

Il design alla base, nelle parole del proprietario: lo sparo manuale serve a
far sì che il giocatore possa smettere per un momento di sparare — a
differenza dell'automatico, che spara sempre appena c'è un bersaglio — per
poi premere il pulsante abilità al bisogno. È un controllo tattico in più,
non solo una diversa fonte di input per la stessa cadenza automatica.
