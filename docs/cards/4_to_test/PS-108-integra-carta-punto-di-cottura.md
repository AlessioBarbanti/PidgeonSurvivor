---
id: PS-108
titolo: Integra la carta Punto di Cottura nel catalogo live
tipo: chore
area: gameplay
stato: BLOCCATO
priorita: media
dipende_da: [PS-107]
origine:
creato: 2026-09-06
aggiornato: 2026-09-06
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

- [ ] `data/upgrades/cooking_point_crit.tres` referenzia l'icona derivata da
      PS-107 (`icon = ExtResource(...)`).
- [ ] La carta è aggiunta all'array `definitions` dell'`UpgradeRegistry` in
      `scenes/game/movement_slice.tscn` (nuovo `ext_resource` + voce
      nell'array), sullo stesso pattern delle altre carte del catalogo
      ordinario.
- [ ] Un run reale (o uno smoke GUT dedicato) conferma che la carta compare
      nel pool di offerta e che selezionarla applica davvero il bonus
      critico dichiarato (`chance_bonus_per_rank`, `critical_damage_multiplier`)
      — il meccanismo sottostante è già coperto da
      `tests/unit/test_ps093_extended_base_stats.gd`, qui serve solo la
      prova che il catalogo la esponga.
- [ ] `docs/powerup-catalog.md` (sezione "Punto di Cottura"): lo stato icona
      passa da "bloccato" a referenziato/accettato.
- [ ] `assets/art/icons/upgrades/ASSET-MANIFEST.md`: già aggiornato da
      PS-107; verificare solo che il derivato referenziato qui coincida.

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

- Smoke: se non già sufficiente il pattern esistente, un breve test
  `tests/unit/test_ps108_cooking_point_catalog_wiring.gd` → marker
  `COOKING_POINT_CATALOG_WIRING_SMOKE_OK` che verifica la presenza della
  carta nel registry pescabile e la sua risoluzione tramite
  `UpgradeEffectRegistry.can_apply()`.
- Profilo minimo prima della chiusura: `Relevant`.

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

## Documenti sincronizzati

- [ ] `docs/powerup-catalog.md`: sezione "Punto di Cottura".

## Note

`BLOCCATO` finché [PS-107](../2_to_do/PS-107-rigenera-icona-punto-di-cottura.md)
non raggiunge almeno `IN VERIFICA`.
