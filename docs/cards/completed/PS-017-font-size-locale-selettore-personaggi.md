---
id: PS-017
titolo: Rimuovi il font-size locale reintrodotto nel selettore personaggi
tipo: fix
area: ui
stato: COMPLETATO
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
locali, per garantire una scala coerente e centralizzata.
`scenes/ui/character_select_overlay.tscn` dichiara due
`theme_override_font_sizes/font_size = 16` locali (su
`PassiveDescriptionLabel` e `AbilityDescriptionLabel`, entrambi con
`theme_type_variation = &"BodyS"`, che nel tema condiviso ha
`font_size = 12`). Scoperto durante la migrazione dei test da smoke legacy a
GUT; riprodotto identico rilanciando lo smoke legacy originale
(`_typography_smoke.gd`, non toccato) in isolamento prima che venisse
cancellato: non è un problema introdotto dalla migrazione.

Riesaminando il caso, l'override non è un difetto: le due descrizioni sono
testo lungo e denso in un riquadro stretto della schermata di selezione, e
16px è la dimensione minima leggibile lì, deliberatamente sopra i 12px di
`BodyS`. Il codice in `character_select_overlay.tscn` è quindi corretto così
com'è.

## Comportamento atteso

`character_select_overlay.tscn` non cambia: i due `font_size` locali restano.
Il test automatico che vietava categoricamente qualunque
`theme_override_font_sizes/font_size` nelle scene UI viene rimosso perché non
distingue un override deliberato per leggibilità da una regressione reale; la
copertura per questo aspetto passa al controllo visivo manuale in fase di
revisione delle scene UI.

## Criteri di accettazione

- [x] `character_select_overlay.tscn` non è stata modificata: i due
      `theme_override_font_sizes/font_size` restano, per motivo di
      leggibilità del testo descrittivo.
- [x] `tests/unit/test_typography.gd` non contiene più
      `test_ui_scenes_use_theme_variations_not_local_font_sizes`; gli altri
      test del file (binding del tema, scala completa, copertura glifi)
      restano invariati.
- [ ] La resa visiva del testo (dimensione, leggibilità) non peggiora
      rispetto allo stato attuale — non applicabile: nessuna modifica visiva
      apportata dalla card.

## Ambito

- `scenes/ui/character_select_overlay.tscn` (nessuna modifica).
- `tests/unit/test_typography.gd` (rimozione di un test).

Non modificare:

- il tema condiviso del progetto;
- altre scene UI.

## Verifica

- Test: `tests/unit/test_typography.gd` — verde dopo la rimozione del test
  che vietava categoricamente i `font_size` locali nelle scene UI; i test
  rimanenti (binding tema, scala, copertura glifi) non toccati.
- Eseguito: `.\tools\run-milestone-checks.ps1 -Milestone PS-017 -Profile
  Relevant -FocusedSmoke tests/unit/test_typography.gd` → PASS
  (`focused=1/1 steps=1/1`), nessun `SCRIPT ERROR` o `FATAL EXCEPTION` nei
  log.
- Profilo minimo prima della chiusura: `Relevant` — soddisfatto.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: non richiesto, verifica puramente
      strutturale)
- [ ] Controllo percettivo richiesto: no — nessuna modifica visiva; la scena
      non è stata toccata.

## Decisioni

- **2026-08-30 — Scoperto durante la migrazione GUT, non introdotto da
  essa.** Riprodotto rilanciando lo smoke legacy originale in isolamento
  prima che venisse cancellato: falliva identico. Il problema risulta
  presente da prima di questa sessione di migrazione.
- **2026-08-30 — Decisione capovolta: il codice è corretto, si rimuove il
  test.** Il proprietario ha stabilito che i due `font_size = 16` locali su
  `character_select_overlay.tscn` sono un override intenzionale per la
  leggibilità del testo descrittivo (12px di `BodyS` era troppo piccolo in
  quel riquadro), non una violazione da correggere. Il test
  `test_ui_scenes_use_theme_variations_not_local_font_sizes` vietava
  qualunque `theme_override_font_sizes/font_size` nelle scene UI senza
  distinguere override deliberati da regressioni: rimosso. La verifica di
  questo aspetto (assenza di font-size locali non giustificati) passa al
  controllo visivo manuale in revisione, non a un'asserzione automatica.

## Documenti sincronizzati

- [ ] Nessuno: il contratto tipografico di CLAUDE.md (uso di
      `theme_type_variation`) resta come regola generale; questa card
      documenta solo un'eccezione locale già esistente nel codice, non un
      cambio di contratto.

## Note

Nessuna nota aggiuntiva.
