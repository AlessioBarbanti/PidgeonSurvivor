---
id: PS-016
titolo: Riporta il tutorial dentro la safe area su tutti i profili
tipo: fix
area: ui
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-016 — Riporta il tutorial dentro la safe area su tutti i profili

## Contesto

Il pannello del tutorial esce dalla safe area su tutti e tre i profili di
layout testati (1280x720, 1600x720, 960x720), con il messaggio "il tutorial
deve restare nella safe area" fallito su ciascuno. Scoperto durante la
migrazione dei test da smoke legacy a GUT; riprodotto identico rilanciando
lo smoke legacy originale (`_b54_tutorial_flow_smoke.gd`, non toccato) in
isolamento prima che venisse cancellato: non è un problema introdotto dalla
migrazione.

## Comportamento atteso

Il pannello principale del tutorial, il target TUTORIAL della welcome e i
controlli ESCI/INDIETRO/AVANTI restano interamente contenuti nella safe
area calcolata da `ArenaLayout` su qualunque aspect ratio supportato.

## Criteri di accettazione

- [x] Il pannello principale del tutorial resta nella safe area su
      1280x720.
- [x] Il pannello principale del tutorial resta nella safe area su
      1600x720 (20:9 con cutout simulato).
- [x] Il pannello principale del tutorial resta nella safe area su
      960x720 (4:3).
- [x] I pulsanti ESCI/INDIETRO e il CTA di pagina (AVANTI/GIOCA) restano
      interamente dentro il pannello su tutti e tre i profili.
- [x] Tutti i target del tutorial restano touch-safe (almeno 44×44) su
      tutti e tre i profili.
- [x] Il target TUTORIAL della welcome (citato in "Comportamento atteso"
      ma assente da questa lista all'apertura) resta nella safe area su
      tutti e tre i profili, incluso mentre la welcome è nascosta dietro
      il tutorial. Verificato da `tests/unit/test_b54_tutorial_flow.gd`.

Automatico verificato con `-Profile Focused` e `-Profile Relevant`
(`-FocusedSmoke tests/unit/test_b54_tutorial_flow.gd`); i gate manuali
sotto restano aperti.

## Ambito

- `scenes/ui/tutorial_screen.tscn` e lo script associato, in particolare il
  calcolo del rettangolo del pannello principale rispetto alla safe area.
- Esteso durante la risoluzione, con conferma del proprietario, a
  `scenes/ui/welcome_screen.tscn` e `scripts/ui/welcome_screen.gd`: il
  target TUTORIAL della welcome citato nel "Comportamento atteso" falliva
  per una causa radice distinta e non risolvibile restando nel solo
  `tutorial_screen.tscn` (vedi Decisioni).

Non modificare:

- il contenuto delle sei pagine, la navigazione (swipe, pulsanti, indice) o
  le vetrine di abilità/potenziamenti/nemici;
- il flusso `welcome → tutorial → selezione`.

## Verifica

- Test: `tests/unit/test_b54_tutorial_flow.gd` — fallisce oggi su tutti e
  tre i profili con il messaggio citato sopra.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: apri il tutorial, verifica il
      pannello e i controlli su un device reale con cutout)
- [ ] Controllo percettivo richiesto: sì
- [ ] Il pannello resta leggibile e non tagliato dai bordi fisici del
      device.

## Decisioni

- **2026-08-30 — Scoperto durante la migrazione GUT, non introdotto da
  essa.** Riprodotto rilanciando lo smoke legacy originale in isolamento
  prima che venisse cancellato: falliva identico su tutti e tre i profili.
- **2026-08-30 — Causa del pannello: doppio margine verticale ridondante.**
  `PanelMargin` (16px top/bottom) si sommava al `content_margin` verticale
  (40px) già incluso nella texture della cornice (`StyleBoxTexture_modal_frame`),
  portando l'altezza minima reale del pannello a 692px contro 680px
  disponibili nella safe area (misurato con stampe di debug temporanee,
  poi rimosse). Fix: azzerato `PanelMargin` verticale in
  `tutorial_screen.tscn` (l'inset visivo resta garantito dal
  `content_margin` della cornice), portando l'altezza minima a ~660px.
- **2026-08-30 — Causa del pulsante TUTORIAL della welcome: vincolo del
  motore, non un bug applicativo.** Il test misura il pulsante mentre la
  welcome è nascosta dietro il tutorial. Verificato empiricamente (stampe
  di debug, poi notifica `Container.NOTIFICATION_SORT_CHILDREN` inviata a
  mano) che Godot non ridispone i `Container` (`CenterContainer`,
  `MarginContainer`) di un ramo non visibile nell'albero, nemmeno forzando
  `queue_sort()` o la notifica diretta: il layout resta congelato
  all'istantanea del boot iniziale finché la schermata non torna visibile.
  Non è quindi un difetto percepibile in gioco (al riapertura il layout si
  ricalcola prima di essere mostrato), ma impediva di soddisfare il
  criterio testato a schermata nascosta.
- **2026-08-30 — Scelta tra tre opzioni, confermata dal proprietario:
  riscrivere il centraggio della welcome invece di modificare il test o
  lasciare il gate aperto.** Sostituito il centraggio basato su
  `CenterContainer`/`MarginContainer` in `welcome_screen.tscn` con un
  inset statico via anchor/offset (`Margin`, ora un `Control` puro) e un
  calcolo esplicito in `welcome_screen.gd`
  (`_update_content_panel_rect()`, agganciato a `Center.resized` e
  richiamato dopo ogni toggle delle impostazioni), che non dipende dal
  sort dei Container e quindi resta corretto anche a schermata nascosta.
  Verificato che la formula di centraggio produce le stesse coordinate
  del `CenterContainer` precedente (nessuna regressione visiva attesa).
- **2026-08-30 — Fallimento pre-esistente e non correlato, non toccato.**
  `tests/unit/test_b18o_welcome_flow.gd` fallisce su "il logo decorativo
  deve restare nel viewport" sugli stessi tre profili; riprodotto identico
  anche sul codice precedente a questa card (verificato con `git stash`).
  È il difetto già tracciato da PS-014 ed è indipendente dal lavoro qui:
  lasciato invariato.

## Documenti sincronizzati

- [ ] Nessuno previsto; fix layout interno.

## Note

Nessuna alternativa scartata: la card nasce da un'osservazione automatica
del controllo di layout già esistente nel test.
