---
id: PS-096
titolo: Diagnostica l'await orfano di UpgradeCard._grow_to_fit_content in full suite
tipo: fix
area: tooling
stato: PRONTO
priorita: bassa
dipende_da: []
origine: PS-095
creato: 2026-09-04
aggiornato: 2026-09-04
---

# PS-096 — Diagnostica l'await orfano di UpgradeCard._grow_to_fit_content in full suite

## Contesto

Durante la verifica di [PS-095](../4_to_test/PS-095-audita-spawn-nemici-sempre-fuori-vista.md)
(profilo `Full`, l'intera cartella `tests/unit/`), `test_b27_upgrade_icon_refresh.gd`
(`test_upgrade_card_icons_stay_centered_and_scaled_across_viewports`) ha
fallito con una raffica di errori motore ripetuti:

```
ERROR: Resumed function '_grow_to_fit_content()' after await, but class
instance is gone. At script: res://scripts/ui/upgrade_card.gd:77
```

Lo stesso test, eseguito **da solo** con lo stesso profilo, passa in modo
pulito (185 assert verdi). Il fallimento dipende quindi dall'ordine/contesto
di esecuzione nella suite completa, non dal contenuto del test né da
`scripts/game/enemy_spawner.gd` (l'unico file toccato da PS-095): nessun
test della catena `Relevant` di PS-095 tocca `UpgradeCard` o
`upgrade_card.gd`.

## Comportamento atteso

`test_b27_upgrade_icon_refresh.gd` passa in modo deterministico sia isolato
sia dentro una corsa `Full` dell'intera cartella `tests/unit/`, senza errori
`SCRIPT ERROR`/`FATAL EXCEPTION` residui da coroutine riprese su istanze
liberate.

## Criteri di accettazione

- [ ] La causa dell'await orfano in `UpgradeCard._grow_to_fit_content()`
      (`scripts/ui/upgrade_card.gd:77`) è identificata: quale altro test
      (o quale ordine di esecuzione) lascia un nodo `UpgradeCard` in attesa
      su un `await` e poi lo libera prima che la coroutine riprenda.
- [ ] `test_b27_upgrade_icon_refresh.gd` passa in modo ripetibile dentro una
      corsa `Full` di `tests/unit/`, non solo isolato.
- [ ] Se la causa è nel test (setup/teardown che libera nodi con coroutine
      pendenti), la correzione resta nel test o nel suo fixture. Se la causa
      è in `UpgradeCard`/`upgrade_card.gd` (manca una guardia
      `is_instance_valid`/`tree_exiting` prima di riprendere dopo l'await),
      la correzione resta lì.

## Ambito

- File attesi: `tests/unit/test_b27_upgrade_icon_refresh.gd`,
  `scripts/ui/upgrade_card.gd`.
- Non toccare: `scripts/game/enemy_spawner.gd` e gli altri file di PS-095 —
  il problema è preesistente e indipendente da quella card.

## Verifica

- Riprodurre con una corsa `Full` di `tests/unit/` (non basta l'esecuzione
  isolata del singolo file) e confermare che l'errore sparisce.
- Profilo minimo prima della chiusura: `Full`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: non applicabile, è un problema di
      soli test)
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-09-04 — Aperta come effetto collaterale scoperto, non come parte di
  PS-095.** Il contratto di card-risolvi impone di isolare problemi
  adiacenti in una card separata invece di allargare quella in corso;
  PS-095 tocca solo `enemy_spawner.gd` e non ha relazione con `UpgradeCard`.

## Documenti sincronizzati

- [ ] Nessuno atteso: è una correzione di affidabilità dei test, non un
      contratto di prodotto.

## Note

Riprodotto con:
```
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```
in un sandbox Linux headless (Godot 4.7.1, `tools/setup-remote-sandbox.sh`).
Non riprodotto con:
```
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_b27_upgrade_icon_refresh.gd -gexit
```
(1/1 passed, 185 assert).
