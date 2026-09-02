---
id: PS-071
titolo: Il pannello della Boss Intro esce dalla safe area
tipo: fix
area: ui
stato: PRONTO
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

- [ ] `tests/unit/test_b15_boss_encounter.gd::test_composed_encounter` passa.
- [ ] `tests/unit/test_ps051_boss_intro_identity.gd::test_boss_intro_panel_stays_in_safe_area_across_aspect_ratios`
      continua a passare sui tre profili già coperti.
- [ ] Il fix non altera contenuto, ordine o dimensioni interne del pannello
      (ritratto, titolo, icona Signature) definiti da PS-051, solo il suo
      contenimento geometrico.

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
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows: verifica visiva della Boss Intro su almeno un profilo
      20:9.
- [ ] Validazione statica APK: non richiesta se il fix resta lato UI 2D.
- [ ] Runtime fisico Pixel 9: utile se il fix cambia margini condivisi con
      altri modal, non indispensabile per la sola geometria.
- [ ] Controllo percettivo richiesto: no, il criterio è geometrico e già
      verificato dagli smoke esistenti.

## Decisioni

- **2026-09-02 — Card separata invece di allargare PS-052.** Il fallimento è
  emerso mentre si eseguiva il set di regressione di PS-052 (che tocca
  `data/bosses/signatures/*.tres`, pattern che aggancia
  `test_b15_boss_encounter.gd` in `tools/milestone-test-map.json`), ma è
  riprodotto identico anche senza le modifiche di quella card.

## Documenti sincronizzati

- [ ] Nessuno atteso: è una correzione geometrica entro un contratto già
      approvato da PS-051.

## Note

Riprodotto con:

```
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gtest=tests/unit/test_b15_boss_encounter.gd -gexit
```

Vedi PS-067 per il pattern di causa più probabile su questa famiglia di bug
(un contenitore che si autoingrandisce oltre il rettangolo assegnato, o una
preferenza morbida — centratura, clearance — applicata come se fosse un
vincolo duro): da verificare se si applica anche a `boss_ui.gd` o se la causa
qui è diversa.
