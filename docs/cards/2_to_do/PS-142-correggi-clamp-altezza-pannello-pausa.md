---
id: PS-142
titolo: Correggi il clamp dell'altezza del pannello pausa
tipo: fix
area: ui
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-142 — Correggi il clamp dell'altezza del pannello pausa

## Contesto

Da quando PS-137 ha ridotto il pannello "IN PAUSA" a solo titolo + due
bottoni (Resume, Cambia personaggio), il pannello mostra molto più spazio
verticale di quanto il contenuto richieda, con una scrollbar la cui track
occupa quasi tutta l'altezza e un thumb minuscolo — segno che lo spazio
riservato è molto più grande del contenuto reale. Verificato dal vivo dal
proprietario con screenshot.

Consultato in merito, il direttore-artistico ha confrontato
`PauseCenter/Panel` con `ConfirmationCenter/Panel` nello stesso file
(`scenes/ui/pause_overlay.tscn`): quest'ultimo usa la stessa cornice
(`pause_panel_frame.png`) senza `ScrollContainer` e si dimensiona
correttamente al proprio contenuto — prova diretta che il frame nine-slice
regge bene un pannello compatto e che il problema non è la cornice. La causa
è in `_clamp_pause_scroll_height()`
(`scripts/ui/pause_overlay.gd`): il commento nel codice (PS-085) dichiara
esplicitamente che il clamp calcolato dev'essere un **tetto**, non un
**pavimento**, ma nello screenshot si comporta come un pavimento — quasi
certamente perché legge `_pause_vbox.get_combined_minimum_size().y` prima
che il layout abbia processato la dimensione reale di bottoni/testo.

## Comportamento atteso

Il pannello "IN PAUSA" si dimensiona all'altezza naturale del proprio
contenuto (titolo + bottoni visibili in quel momento), senza spazio vuoto in
eccesso e senza mostrare uno `ScrollContainer`/scrollbar quando il contenuto
entra comodamente nello schermo disponibile.

## Criteri di accettazione

- [ ] A parità di viewport, l'altezza renderizzata del pannello pausa
      corrisponde all'altezza naturale minima del suo `VBoxContainer`
      (più il chrome della cornice), non a un valore residuo/stale
      calcolato prima che il layout fosse pronto.
- [ ] Nessuna scrollbar verticale è visibile nel pannello pausa quando il
      contenuto (titolo + bottoni) entra nello spazio disponibile del
      viewport, su 16:9, 20:9 e 4:3.
- [ ] Su un viewport compatto dove il contenuto NON entrerebbe comodamente,
      il clamp continua a funzionare come tetto di sicurezza (comportamento
      PS-085 preesistente, non regredito).
- [ ] Il comportamento resta corretto anche dopo un ridimensionamento del
      viewport a runtime (`get_viewport().size_changed`), non solo alla
      prima apertura.

## Ambito

- File attesi: `scripts/ui/pause_overlay.gd` (`_clamp_pause_scroll_height`,
  timing della chiamata rispetto al layout del `VBoxContainer`).
- Valutare, se pertinente, se lo `ScrollContainer` (`PauseScroll`) sia ancora
  necessario ora che il contenuto della colonna pausa è fisso e corto
  (titolo + bottoni), oppure se vada mantenuto per coprire profili futuri
  con più bottoni (vedi PS-143, che aggiunge un terzo bottone alla stessa
  colonna).
- Non toccare: `ConfirmationCenter` (già corretto, usato come riferimento di
  comportamento atteso), la logica di apertura/chiusura della pausa in
  `RunController`, `SettingsOverlay`.

## Verifica

- Smoke: `tests/unit/test_ps142_pause_panel_height_clamp.gd` → marker
  `PS142_PAUSE_PANEL_HEIGHT_OK`, verifica che l'altezza assegnata al
  contenitore scrollabile del pannello pausa corrisponda all'altezza naturale
  del `VBox` (entro una tolleranza minima) quando il viewport ha spazio
  sufficiente, su almeno due profili di viewport diversi.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: apertura pausa, verifica assenza
      scrollbar/spazio vuoto)
- [ ] Controllo percettivo richiesto: sì — confronto screenshot fornito dal
      proprietario prima/dopo

## Decisioni

- **2026-09-10 — Consultato il direttore-artistico prima di aprire la
  card** (richiesta del proprietario dopo screenshot dal vivo). Confermato
  che è un bug di timing/layout, non una scelta di design: il frame
  `pause_panel_frame.png` regge già un pannello compatto (vedi
  `ConfirmationCenter/Panel` nello stesso file), quindi nessuna nuova arte è
  richiesta.

## Documenti sincronizzati

- [ ] Nessuno atteso: fix di comportamento, nessun contratto di prodotto
      cambia.

## Note

Questa card è indipendente da PS-143 (sostituzione dell'icona ingranaggio
con un bottone IMPOSTAZIONI nella stessa colonna): possono essere risolte in
qualunque ordine, ma toccano lo stesso file e lo stesso pannello — verificare
insieme con uno screenshot finale se risolte in sequenza ravvicinata.
