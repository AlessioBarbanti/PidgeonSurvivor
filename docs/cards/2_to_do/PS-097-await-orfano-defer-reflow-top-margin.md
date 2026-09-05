---
id: PS-097
titolo: Applica a UpgradeOverlay/BarbRewardOverlay la correzione dell'await orfano di PS-096
tipo: fix
area: tooling
stato: PRONTO
priorita: bassa
dipende_da: [PS-096]
origine: PS-096
creato: 2026-09-05
aggiornato: 2026-09-05
---

# PS-097 — Applica a UpgradeOverlay/BarbRewardOverlay la correzione dell'await orfano di PS-096

## Contesto

[PS-096](../4_to_test/PS-096-await-orfano-grow-to-fit-content-upgrade-card.md)
ha diagnosticato e corretto un errore motore ripetuto in full suite:
`UpgradeCard._grow_to_fit_content()` usava `await get_tree().process_frame`
(due volte) in modo "fire-and-forget" subito dopo `configure()`; se il nodo
veniva liberato (es. `add_child_autofree` a fine test) mentre la coroutine
era ancora sospesa su quel segnale, Godot produceva
`ERROR: Resumed function '_grow_to_fit_content()' after await, but class
instance is gone` — un errore che il consueto guardiano `is_inside_tree()`
non può prevenire, perché scatta nel tentativo stesso di riprendere la
funzione, prima che il suo corpo torni a eseguire. La correzione ha sostituito
i due `await` con due connessioni one-shot a `process_frame`, che si
disconnettono da sole senza errore quando il bersaglio viene liberato.

Verificando la correzione con l'intera suite (`-gdir=res://tests/unit`), gli
errori su `upgrade_card.gd` sono scesi a zero, ma sono emersi **due
occorrenze gemelle dello stesso pattern**, non coperte dall'ambito di
PS-096:

```
ERROR: Resumed function '_defer_reflow_top_margin()' after await, but class
instance is gone. At script: res://scripts/ui/upgrade_overlay.gd:345
ERROR: Resumed function '_defer_reflow_top_margin()' after await, but class
instance is gone. At script: res://scripts/ui/barb_reward_overlay.gd:365
```

Entrambe le funzioni (origine PS-063) hanno la stessa forma:

```gdscript
func _defer_reflow_top_margin() -> void:
	await get_tree().process_frame               # x2 in upgrade_overlay.gd, x1 in barb_reward_overlay.gd
	if is_instance_valid(self) and is_inside_tree():
		_reflow_top_margin()
```

chiamata in modo fire-and-forget subito dopo aver mostrato il modal, stesso
principio di `UpgradeCard._grow_to_fit_content()`: stessa causa, stessa
correzione.

## Comportamento atteso

Nessun `ERROR: Resumed function ... after await, but class instance is gone`
compare più nei log durante una corsa `Full` di `tests/unit/`, né da
`upgrade_overlay.gd` né da `barb_reward_overlay.gd`. `_reflow_top_margin()`
continua a essere ricalcolato un paio di frame dopo l'apertura del modal,
esattamente come oggi (PS-063), senza cambi di comportamento percepibile in
gioco.

## Criteri di accettazione

- [ ] `UpgradeOverlay._defer_reflow_top_margin()` e
      `BarbRewardOverlay._defer_reflow_top_margin()` non usano più
      `await get_tree().process_frame` fire-and-forget: applicano lo stesso
      schema a connessioni one-shot introdotto da PS-096 in
      `UpgradeCard._grow_to_fit_content()` (o uno schema equivalente che
      risolve la stessa classe di errore).
- [ ] Una corsa `Full` di `tests/unit/` non produce più alcuna occorrenza di
      `Resumed function ... after await, but class instance is gone` per
      questi due file.
- [ ] Il ricalcolo del margine superiore dopo l'apertura del modal (PS-063)
      resta invariato nel comportamento osservabile: nessuna regressione sui
      test esistenti che coprono `UpgradeOverlay`/`BarbRewardOverlay`.

## Ambito

- File attesi: `scripts/ui/upgrade_overlay.gd`,
  `scripts/ui/barb_reward_overlay.gd`.
- Non toccare: `scripts/ui/upgrade_card.gd` — già corretto da PS-096; questa
  card applica lo stesso schema, non lo rivede.

## Verifica

- Riprodurre/confermare con una corsa `Full` di `tests/unit/` (non basta
  l'esecuzione isolata dei singoli file, come già osservato in PS-096) e
  controllare che le due occorrenze spariscano dal log.
- Profilo minimo prima della chiusura: `Full`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: non applicabile, è un problema di
      soli test/log)
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-09-05 — Aperta come effetto collaterale della verifica di PS-096,
  non come sua estensione.** Il contratto di card-risolvi impone di isolare
  problemi adiacenti in una card separata invece di allargare quella in
  corso; l'ambito di PS-096 è dichiarato esplicitamente limitato a
  `upgrade_card.gd`.
- **2026-09-05 — Dipende da PS-096.** Riusa lo schema di correzione appena
  validato lì (connessioni one-shot a `process_frame` invece di `await`
  fire-and-forget); non ha senso implementarla prima che PS-096 sia
  verificata.

## Documenti sincronizzati

- [ ] Nessuno atteso: è una correzione di affidabilità dei test/log, non un
      contratto di prodotto.

## Note

Comandi usati per la scoperta (sandbox Linux remoto, Godot 4.7.1 via
`tools/setup-remote-sandbox.sh`):

```
xvfb-run --auto-servernum --server-args="-screen 0 1280x720x24" \
  godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/unit -gexit
```
