---
id: PS-016
titolo: Riporta il tutorial dentro la safe area su tutti i profili
tipo: fix
area: ui
stato: PRONTO
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

- [ ] Il pannello principale del tutorial resta nella safe area su
      1280x720.
- [ ] Il pannello principale del tutorial resta nella safe area su
      1600x720 (20:9 con cutout simulato).
- [ ] Il pannello principale del tutorial resta nella safe area su
      960x720 (4:3).
- [ ] I pulsanti ESCI/INDIETRO e il CTA di pagina (AVANTI/GIOCA) restano
      interamente dentro il pannello su tutti e tre i profili.
- [ ] Tutti i target del tutorial restano touch-safe (almeno 44×44) su
      tutti e tre i profili.

## Ambito

- `scenes/ui/tutorial_screen.tscn` e lo script associato, in particolare il
  calcolo del rettangolo del pannello principale rispetto alla safe area.

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

## Documenti sincronizzati

- [ ] Nessuno previsto; fix layout interno.

## Note

Nessuna alternativa scartata: la card nasce da un'osservazione automatica
del controllo di layout già esistente nel test.
