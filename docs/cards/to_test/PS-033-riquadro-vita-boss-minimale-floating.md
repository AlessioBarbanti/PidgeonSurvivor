---
id: PS-033
titolo: Elimina l'HUD dedicata del Boss, la vita resta solo overhead
tipo: ux
area: ui
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-033 — Elimina l'HUD dedicata del Boss, la vita resta solo overhead

## Contesto

`%BossHealthPanel` ([scenes/ui/boss_ui.tscn](../../../scenes/ui/boss_ui.tscn))
era un pannello HUD fisso con nome, testo numerico HP e barra, sovrapposto alla
zona di gioco. Un primo intervento lo aveva reso più leggero (sfondo semi-
trasparente, niente bordo, meno ingombro verticale — vedi Decisioni), ma il
proprietario ha poi chiesto di eliminarlo del tutto: la vita del Boss deve
comparire solo come la barra overhead già disegnata sopra ogni nemico da
`BaseEnemy._draw_health_bar()`, resa un po' più lunga e spessa per restare
leggibile su un'entità con molta più vita e uno scontro più lungo.

Questa card assorbe ed estende quanto fatto in precedenza sullo stesso
elemento; supersede anche [PS-009](../completed/PS-009-trasparenza-dialog-boss.md)
(trasparenza del pannello sotto il Player), il cui oggetto (il pannello
stesso) non esiste più — vedi quella card per la nota di chiusura.

## Comportamento atteso

Con un Boss attivo non compare più alcun pannello HUD dedicato: né durante
l'introduzione né durante il combattimento. La vita del Boss è leggibile solo
tramite la barra disegnata sopra il suo sprite, come per gli altri nemici, ma
più lunga e spessa in proporzione alla sua rilevanza. Il dialog di
introduzione ("BOSS IN ARRIVO", nome, citazione, pulsante AFFRONTA) resta
invariato: non è l'HUD di cui questa card chiede la rimozione.

## Criteri di accettazione

- [x] `%BossHealthPanel` e tutti i suoi figli (`Content`, `BossNameLabel`,
      `BossHealthBar`) sono rimossi da `boss_ui.tscn`, insieme agli
      `StyleBoxFlat` che li stilizzavano.
- [x] `BossUI` non ha più alcuna API legata al pannello vita (`bind_boss`,
      `clear_boss`, `get_boss`, `is_boss_health_visible`,
      `get_boss_health_panel_rect`, `get_boss_health_value`,
      `get_boss_health_max`) né alla dissolvenza player-sotto-pannello
      (`set_player_fade_target`, `is_player_occluding_boss_ui`,
      `get_boss_ui_alpha`, `get_player_fade_target_screen_position`).
      `BossUI` resta responsabile solo dell'`IntroLayer`.
- [x] `FirstBoss` imposta una barra vita overhead più lunga e spessa di quella
      base (`health_bar_thickness` e `health_bar_length_scale` su `BaseEnemy`
      superiori ai valori di default usati dai nemici comuni).
- [x] Il comportamento della barra vita per i nemici comuni non cambia
      (stessi `health_bar_thickness`/`health_bar_length_scale` di default).
- [x] Nessuna modifica a HP, statistiche o comportamento del Boss.
- [x] Nessuna modifica al dialog di introduzione (`IntroLayer`).
- [x] `test_b15_boss_encounter.gd`, `test_b16_complete_run.gd` e
      `test_b18b_visual_identity.gd` sono aggiornati al nuovo contratto e
      passano.
- [x] La corona decorativa disegnata sopra il Boss (`FirstBoss._draw_boss_mark()`)
      è rimossa: nessun nodo la sostituisce, nessun test la referenzia.

## Ambito

- `scenes/ui/boss_ui.tscn` e `scripts/ui/boss_ui.gd`: rimozione del pannello
  vita e di ogni logica associata (compresa la dissolvenza PS-009).
- `scripts/actors/base_enemy.gd`: nuovi parametri `health_bar_thickness` /
  `health_bar_length_scale` per la barra overhead disegnata in `_draw()`,
  con default identico al comportamento storico (nessun impatto sui nemici
  comuni).
- `scripts/bosses/first_boss.gd`: applica valori maggiorati di questi due
  parametri al Boss.
- `scripts/bosses/boss_encounter.gd`, `scripts/game/movement_slice.gd`:
  rimozione delle chiamate al contratto eliminato di `BossUI`.
- `scripts/vfx/presentation_timings.gd`: rimozione di
  `BOSS_UI_FADE_SECONDS`, non più usata.

Non modificare:

- `IntroLayer` (il dialog "Boss in arrivo") e il suo `ContinueButton`;
- la logica di combattimento, i pattern d'attacco o le statistiche del Boss;
- il comportamento della barra vita overhead per i nemici comuni (stesso
  spessore/lunghezza di sempre);
- il layout del resto della HUD (`hud.gd`, joystick, pulsante abilità).

## Verifica

- Test aggiornati/coperti: `tests/unit/test_b15_boss_encounter.gd`,
  `tests/unit/test_b16_complete_run.gd`,
  `tests/unit/test_b18b_visual_identity.gd`.
- Rimosso `tests/unit/test_ps009_boss_ui_transparency.gd`: verificava una
  logica che non esiste più (vedi PS-009).
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: raggiungi un Boss e osserva la barra
      vita durante il combattimento)
- [ ] Controllo percettivo richiesto: sì
- [ ] La barra overhead del Boss resta leggibile durante il combattimento
      (VFX, proiettili, altri nemici).
- [ ] Nessuna HUD residua compare all'apertura o alla chiusura dell'incontro.

## Decisioni

- **2026-08-31 — Prima iterazione (superata): pannello minimale.** Prima
  versione della card: alleggerire `%BossHealthPanel` (sfondo semi-
  trasparente 0.32 invece di 0.94, niente bordo, altezza 360×40 invece di
  560×70, rimosso il testo numerico HP). Implementata e verificata
  (`Focused`/`Relevant` PASS), poi superata dalla decisione seguente prima
  della chiusura della card.
- **2026-08-31 — Decisione finale del proprietario: eliminare l'HUD, usare
  solo la barra overhead.** Il proprietario ha valutato lo screenshot della
  prima iterazione e ha chiesto di rimuovere completamente il pannello,
  affidandosi alla barra vita già disegnata da `BaseEnemy._draw_health_bar()`
  sopra ogni nemico, ingrandita per il Boss. Motivazione: massima leggerezza,
  coerenza visiva con i nemici comuni, e semplificazione del codice (elimina
  anche tutta la logica di dissolvenza PS-009, non più necessaria senza un
  pannello da far sparire).
- **2026-08-31 — La barra overhead resta nascosta a vita piena, per
  costruzione.** `_draw_health_bar()` (invariato in questo comportamento)
  non disegna nulla quando `health_current >= health_max`, cosa vera anche
  per il Boss appena finita l'introduzione. Non l'ho cambiato perché
  modificherebbe la soglia di visibilità per *tutti* i nemici o richiederebbe
  un'eccezione dedicata al Boss, entrambe fuori dall'ambito di questa card:
  segnalato al proprietario come possibile follow-up, non implementato.
- **2026-08-31 — Dimensioni scelte.** `health_bar_thickness = 9.0` (contro il
  default `4.0`) e `health_bar_length_scale = 1.6` (barra larga
  `collision_radius * 2 * 1.6`), solo su `FirstBoss`. Valori di partenza da
  confermare nel controllo percettivo.
- **Sostituisce:** l'approccio "pannello minimale" della prima iterazione di
  questa stessa card (vedi sopra) e rende PS-009 obsoleta (vedi quella card).
- **2026-08-31 — Rimossa anche la corona decorativa sopra il Boss.** Con la
  barra vita ingrandita, la corona disegnata da
  `FirstBoss._draw_boss_mark()` si sovrapponeva visivamente alla barra (bordo
  inferiore della corona e bordo superiore della barra coincidevano
  esattamente). Il proprietario ha chiesto di rimuovere del tutto la corona
  invece di ricalcolarne la posizione. Nessun test la referenziava
  esplicitamente.

## Documenti sincronizzati

- [ ] Nessuno: dettaglio presentazionale locale a `BossUI`/`BaseEnemy`.

## Note

Richiesta originale del proprietario: "modifichiamo la dialog attorno alla
vita del boss, occupa troppo spazio nella schermata, facciamo qualcosa di
leggerissimo e floating, togliamo testi inutili e rendiamolo molto più
minimale." Seguita dalla decisione finale, dopo aver visto uno screenshot
della prima iterazione: "Ma [...] è il caso di toglierla del tutto e lasciare
la vita sopra al boss come gli altri nemici? [...] Eliminiamo l'hud dedicata,
lasciamo solo la barra sopra al boss, magari un po' più lunga e spessa di
quella degli altri nemici."
