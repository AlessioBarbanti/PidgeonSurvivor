---
id: PS-071
titolo: Il pannello della Boss Intro esce dalla safe area
tipo: fix
area: ui
stato: IN VERIFICA
priorita: media
dipende_da: []
origine: B15
creato: 2026-09-02
aggiornato: 2026-09-02
---

# PS-071 — Il pannello della Boss Intro esce dalla safe area

## Contesto

`tests/unit/test_b15_boss_encounter.gd:88` verifica che
`boss_ui.get_intro_panel_rect()` resti dentro
`arena_layout.get_safe_area_rect()`. Il test fallisce:

```
Il pannello intro Boss deve restare nella safe area.
Interno [P: (20.0, 18.5), S: (620.0, 683.0)], esterno [P: (20.0, 20.0), S: (1240.0, 680.0)].
```

Il pannello sborda sia in alto (`18.5` contro un top sicuro di `20.0`) sia in
basso (`18.5 + 683 = 701.5` contro un fondo sicuro di `700.0`). Riprodotto in
un sandbox Linux con Godot 4.7.1 headless su `HEAD`, prima di qualunque
modifica di [PS-052](../4_to_test/PS-052-genera-ritratti-evil-e-icone-signature.md):
non è quindi legato alla produzione dei ritratti Evil/icone Signature, ma a
un difetto preesistente di `scripts/ui/boss_ui.gd` /
`scenes/ui/boss_ui.tscn`, la stessa famiglia di problema già risolta da
[PS-067](../4_to_test/PS-067-carte-upgrade-e-barb-escono-di-6px-dalla-safe-area.md)
sugli overlay upgrade/Barb (contenimento nella safe area come vincolo duro,
non rispettato quando il contenuto del pannello cresce). A differenza di
quegli overlay, `boss_ui.gd` non espone un metodo `apply_safe_area()` né usa
un `MarginContainer` con margine ricalcolato: va verificato come il pannello
Boss Intro riceve oggi (se le riceve) le informazioni di safe area
dall'orchestratore.

## Comportamento atteso

`boss_ui.get_intro_panel_rect()` resta interamente dentro il rettangolo
sicuro restituito da `arena_layout.get_safe_area_rect()` in tutte le
configurazioni esercitate da `test_b15_boss_encounter.gd` e da
`test_ps051_boss_intro_identity.gd` (che copre già 16:9, 20:9 cutout, 4:3 per
il solo caso Evil).

## Criteri di accettazione

- [x] `tests/unit/test_b15_boss_encounter.gd::test_composed_encounter` passa.
- [x] `tests/unit/test_ps051_boss_intro_identity.gd::test_boss_intro_panel_stays_in_safe_area_across_aspect_ratios`
      continua a passare sui tre profili già coperti.
- [x] Il fix non altera contenuto, ordine o dimensioni interne del pannello
      (ritratto, titolo, icona Signature) definiti da PS-051, solo il suo
      contenimento geometrico: l'unica leva toccata è la spaziatura fra i
      blocchi del pannello (`VBoxContainer.separation`, uno spazio vuoto, non
      un elemento di contenuto), e solo quando il contenuto reale non entra
      con la spaziatura preferita.

## Ambito

- `scripts/ui/boss_ui.gd`, `scenes/ui/boss_ui.tscn`: il calcolo di
  posizione/dimensione del pannello Boss Intro rispetto al safe rect
  ricevuto dall'orchestratore.

Non toccare:

- l'autorità di `RunController` e l'arbitraggio dei modali;
- il contratto della safe area calcolato da `ArenaLayout`/`SafeAreaRoot`
  (PS-064): questa card consuma quel rettangolo, non lo ridefinisce;
- ritratto, icona Signature e tinta personale introdotti da PS-051/PS-052.

## Verifica

- Smoke esistenti: `tests/unit/test_b15_boss_encounter.gd`,
  `tests/unit/test_ps051_boss_intro_identity.gd`. Non serve un nuovo smoke
  dedicato: il contratto è già coperto, è la sua violazione a essere il
  difetto.
- Profilo minimo prima della chiusura: `Relevant`. Eseguito con Godot 4.7.1
  headless in sandbox Linux (nessun PowerShell disponibile in questa
  sessione): tutti gli smoke mappati su `scripts/ui/*` e su
  `scripts/bosses/*`/`data/bosses/*` passano (78 test, 26 script), incluso
  l'intero set Boss/HUD/upgrade/Barb. L'unico fallimento residuo
  (`test_b54_tutorial_flow.gd`) è preesistente e indipendente, già noto da
  PS-067/PS-052 (asset tutorial PS-048/PS-049, fuori ambito).

## Gate manuali

- [ ] Runtime Windows: verifica visiva della Boss Intro su almeno un profilo
      20:9. **Aperto**: nessun ambiente Windows disponibile in questa
      sessione, solo validazione headless via Godot/GUT.
- [x] Validazione statica APK: non richiesta, il fix resta lato UI 2D
      (nessun asset o preset export toccato).
- [ ] Runtime fisico Pixel 9: utile se il fix cambia margini condivisi con
      altri modal, non indispensabile per la sola geometria. **Aperto**:
      nessun device disponibile in questa sessione.
- [x] Controllo percettivo richiesto: no, il criterio è geometrico e già
      verificato dagli smoke esistenti.

## Decisioni

- **2026-09-02 — Card separata invece di allargare PS-052.** Il fallimento è
  emerso mentre si eseguiva il set di regressione di PS-052 (che tocca
  `data/bosses/signatures/*.tres`, pattern che aggancia
  `test_b15_boss_encounter.gd` in `tools/milestone-test-map.json`), ma è
  riprodotto identico anche senza le modifiche di quella card.
- **2026-09-02 — Causa reale: `CenterContainer` che centra senza mai
  contenere, non un problema di propagazione della safe area.** L'ambito
  originario ipotizzava che `boss_ui.gd` non ricevesse affatto la safe area
  dall'orchestratore. Verificato il contrario: `BossUI` è un `Control`
  semplice (non un `Container`) figlio diretto di `SafeAreaRoot`, che
  `movement_slice.gd::_apply_layout()` dimensiona già esplicitamente al
  rettangolo sicuro (`_safe_area_root.size = safe_area.size`); essendo
  ancorato `FULL_RECT` e non essendo un `Container`, `BossUI.size` riflette
  sempre quel rettangolo vero, senza il rischio di auto-inflazione visto in
  PS-067 (quel rischio riguarda solo i `Container`, la cui `size` non può
  mai scendere sotto la propria minimum-size). Il vero difetto era che
  `%Center` era una `CenterContainer`: centra il pannello ma non lo contiene
  mai, quindi quando il contenuto reale (titolo/citazione più lunghi in
  `test_b15`) supera l'altezza disponibile di qualche pixel, il pannello
  trabocca simmetricamente sopra e sotto invece di restare vincolato.
- **2026-09-02 — Fix: spaziatura come preferenza morbida, contenimento come
  vincolo duro, nessuna riduzione di contenuto.** `%Center` è ora una
  `MarginContainer` i cui margini vengono ricalcolati da
  `_reflow_intro_panel_position()` usando `BossUI.size` (mai gonfiato, per i
  motivi sopra) come base: centra normalmente quando c'è spazio, altrimenti
  restringe prima la spaziatura fra i blocchi del pannello
  (`VBoxContainer.separation`, minimo `8`, preferita `18`) e infine azzera i
  margini di centratura piuttosto che lasciar traboccare il pannello. Non è
  stata ridotta né alterata alcuna dimensione di ritratto, titolo, citazione
  o icona Signature: l'unica leva è lo spazio vuoto fra i blocchi. La stessa
  spaziatura preferita resta invariata (`18`, il valore preesistente) in
  tutti i casi in cui il contenuto ci sta già, quindi nessuna regressione
  visiva sui casi già verificati da PS-051.

## Documenti sincronizzati

- [x] Nessuno atteso: è una correzione geometrica entro un contratto già
      approvato da PS-051, senza introdurre un nuovo contratto visivo.

## Note

Riprodotto con:

```
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gtest=tests/unit/test_b15_boss_encounter.gd -gexit
```

Vedi PS-067 per il pattern di causa più probabile su questa famiglia di bug
(un contenitore che si autoingrandisce oltre il rettangolo assegnato, o una
preferenza morbida — centratura, clearance — applicata come se fosse un
vincolo duro): la causa qui era il secondo caso, non il primo (vedi
Decisioni per il dettaglio).

Evidenza di chiusura (2026-09-02), Godot 4.7.1 headless in sandbox Linux:

```
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gtest=tests/unit/test_b15_boss_encounter.gd,tests/unit/test_ps051_boss_intro_identity.gd \
  -gexit
```

`2/2` e `5/5` test passati. Rieseguito anche il set esteso mappato su
`scripts/ui/*` (26 script, 78 test): un solo fallimento residuo,
`test_b54_tutorial_flow.gd`, preesistente e indipendente (asset tutorial
PS-048/PS-049).
