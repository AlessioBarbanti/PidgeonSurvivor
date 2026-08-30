---
id: PS-017
titolo: Rimuovi il font-size locale reintrodotto nel selettore personaggi
tipo: fix
area: ui
stato: PRONTO
priorita: bassa
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-017 — Rimuovi il font-size locale reintrodotto nel selettore personaggi

## Contesto

Il contratto tipografico del progetto richiede che le scene UI usino
`theme_type_variation` invece di `theme_override_font_sizes/font_size`
locali, per garantire una scala coerente e centralizzata. Oggi
`scenes/ui/character_select_overlay.tscn` reintroduce un
`theme_override_font_sizes/font_size` locale, violando quel contratto.
Scoperto durante la migrazione dei test da smoke legacy a GUT; riprodotto
identico rilanciando lo smoke legacy originale (`_typography_smoke.gd`, non
toccato) in isolamento prima che venisse cancellato: non è un problema
introdotto dalla migrazione.

## Comportamento atteso

`character_select_overlay.tscn` non dichiara alcun
`theme_override_font_sizes/font_size` locale; la dimensione del testo deriva
esclusivamente da `theme_type_variation` sul tema condiviso del progetto.

## Criteri di accettazione

- [ ] `character_select_overlay.tscn` non contiene più alcuna proprietà
      `theme_override_font_sizes/font_size`.
- [ ] Il testo della scena usa una `theme_type_variation` valida definita
      nel tema condiviso.
- [ ] La resa visiva del testo (dimensione, leggibilità) non peggiora
      rispetto allo stato attuale.

## Ambito

- `scenes/ui/character_select_overlay.tscn`.

Non modificare:

- il tema condiviso del progetto, salvo aggiungere una variazione mancante
  se davvero necessaria per replicare la dimensione attuale;
- altre scene UI già conformi al contratto.

## Verifica

- Test: `tests/unit/test_typography.gd` — fallisce oggi su questo controllo
  specifico per `character_select_overlay.tscn`.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: non richiesto, verifica puramente
      strutturale)
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-08-30 — Scoperto durante la migrazione GUT, non introdotto da
  essa.** Riprodotto rilanciando lo smoke legacy originale in isolamento
  prima che venisse cancellato: falliva identico. Il problema risulta
  presente da prima di questa sessione di migrazione.

## Documenti sincronizzati

- [ ] Nessuno previsto; allineamento a un contratto già esistente.

## Note

Nessuna nota aggiuntiva.
