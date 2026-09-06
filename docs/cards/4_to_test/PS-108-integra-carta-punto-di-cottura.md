---
id: PS-108
titolo: Integra la carta Punto di Cottura nel catalogo live
tipo: chore
area: gameplay
stato: IN VERIFICA
priorita: media
dipende_da: [PS-107]
origine:
creato: 2026-09-06
aggiornato: 2026-09-07
---

# PS-108 — Integra la carta Punto di Cottura nel catalogo live

## Contesto

[PS-093](../3_in_sprint/PS-093-nuovi-assi-scarto-base-personaggi.md) ha
implementato per intero il meccanismo del colpo critico
(`WeaponController`, `UpgradeEffectRegistry`) e la definizione della carta
(`data/upgrades/cooking_point_crit.tres`, titolo "Punto di Cottura"), ma non
l'ha aggiunta al catalogo effettivamente pescabile in run
(`UpgradeRegistry.definitions` in
[scenes/game/movement_slice.tscn](../../../scenes/game/movement_slice.tscn))
perché priva di un'icona accettabile — vedi
[PS-107](../2_to_do/PS-107-rigenera-icona-punto-di-cottura.md).

## Comportamento atteso

"Punto di Cottura" compare fra le carte pescabili a level-up, con l'icona
rigenerata da PS-107, e il critico funziona in game esattamente come già
verificato negli smoke di PS-093.

## Criteri di accettazione

- [x] `data/upgrades/cooking_point_crit.tres` referenzia l'icona derivata da
      PS-107 (`icon = ExtResource(...)`). Cablato con lo stesso pattern di
      `wide_magnet.tres`/`pinza_lunga.png`.
- [x] La carta è aggiunta all'array `definitions` dell'`UpgradeRegistry` in
      `scenes/game/movement_slice.tscn` (nuovo `ext_resource`
      `127_cooking_point_crit` + voce in coda all'array), sullo stesso
      pattern delle altre carte del catalogo ordinario.
- [x] Uno smoke GUT dedicato conferma che la carta compare nel pool di
      offerta e che selezionarla applica davvero il bonus critico
      dichiarato (`chance_bonus_per_rank`, `critical_damage_multiplier`) —
      il meccanismo sottostante era già coperto da
      `tests/unit/test_ps093_extended_base_stats.gd`, il nuovo smoke prova
      solo che il catalogo la esponga e che l'effetto si applichi davvero
      al `WeaponController` reale (bonus critico 0.0→0.05→0.10 su due
      ranghi, moltiplicatore 1.75×, danno base invariato).
- [x] `docs/powerup-catalog.md` (sezione "Punto di Cottura"): lo stato icona
      passa da "bloccato" a referenziato/cablato nel catalogo live.
- [x] `assets/art/icons/upgrades/ASSET-MANIFEST.md`: già aggiornato da
      PS-107; verificato che il derivato referenziato da
      `cooking_point_crit.tres` coincide con quello a manifest (stesso
      percorso `generated/cooking_point_crit.png`).

## Ambito

- `scenes/game/movement_slice.tscn`: `UpgradeRegistry.definitions`.
- `data/upgrades/cooking_point_crit.tres`: campo `icon`.
- `docs/powerup-catalog.md`.

Non toccare:

- la logica del colpo critico in `WeaponController`/`UpgradeEffectRegistry`
  (PS-093, già chiusa e verificata);
- gli altri assi estesi di PS-093 (danno, avidità, raggio pickup, difesa) e
  i relativi scarti per personaggio.

## Verifica

- Smoke: `tests/unit/test_ps108_cooking_point_catalog_wiring.gd` → marker
  `COOKING_POINT_CATALOG_WIRING_SMOKE_OK`. Verifica: (1) `cooking_point_crit`
  è presente in `UpgradeRegistry.definitions` del catalogo live non
  modificato, con `icon` valorizzata; (2) `UpgradeEffectRegistry.can_apply()`
  accetta la Resource reale; (3) selezionandola due volte in un catalogo
  isolato (stesso pattern di `test_b12_upgrade_effects.gd`/
  `test_b13_signature_upgrades.gd`) il bonus critico del `WeaponController`
  passa 0.0→0.05→0.10 e il moltiplicatore critico diventa `1.75×`, senza
  mutare il danno base condiviso.
- Profilo eseguito: `Relevant` (32/32 verdi) poi `Full` (116/116 verdi:
  113 regressioni + 2 focused + toolchain), nessun `SCRIPT ERROR`/
  `FATAL EXCEPTION` nei log di entrambi. Una regressione preesistente in
  `test_b10_upgrade_service.gd` assumeva 25 carte normali nel catalogo
  composto: corretta a 26 (vedi Decisioni), non era un difetto di questa
  card ma un conteggio che doveva aggiornarsi insieme al catalogo reale.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: non richiesto, nessuna superficie
      Android-specifica oltre al catalogo già in uso
- [ ] Controllo percettivo richiesto: sì — la carta deve leggersi bene nel
      modal di level-up reale, non solo isolata

## Decisioni

- **2026-09-06 — Scorporata da PS-093.** Un solo criterio (l'icona/il
  cablaggio live) dipendeva da un asset non ancora pronto: scorporarlo
  sblocca PS-093 sul resto (meccanismo già implementato e verificato),
  stessa forma già usata per PS-102/103 e PS-104/106 in questa sessione.
- **2026-09-07 — Nuovo `ext_resource` `127_cooking_point_crit` in
  `movement_slice.tscn`, aggiunto in coda all'array `definitions` insieme
  alle altre carte ordinarie recenti (`piercing_rounds`/`double_barrel`/
  `death_burst`), non raggruppato per tipo — segue l'ordine di inserimento
  storico della scena, non un raggruppamento semantico.** `load_steps`
  aggiornato da 118 a 119 per coerenza.
- **2026-09-07 — Scoperta una regressione preesistente durante `Relevant`,
  non un difetto introdotto da questa card.** `test_b10_upgrade_service.gd`
  asseriva staticamente 25 carte normali nel catalogo composto; con
  "Punto di Cottura" aggiunta il catalogo reale ne conta 26. Corretto il
  numero atteso nel test invece di aggirare o indebolire l'asserzione: il
  test continua a proteggere che il catalogo abbia esattamente il numero di
  carte atteso, solo aggiornato al nuovo stato reale.

## Documenti sincronizzati

- [x] `docs/powerup-catalog.md`: sezione "Punto di Cottura" aggiornata per
      riflettere il cablaggio live.

## Note

Sbloccata: [PS-107](../4_to_test/PS-107-rigenera-icona-punto-di-cottura.md)
ha raggiunto `IN VERIFICA` il 2026-09-07 (derivato reale
`generated/cooking_point_crit.png` prodotto e verificato, gate manuali del
proprietario ancora aperti ma non bloccanti per questa card).
