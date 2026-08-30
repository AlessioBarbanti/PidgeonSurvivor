---
id: PS-015
titolo: Adegua il test della card centrale del selettore all'artwork di selezione
tipo: fix
area: ui
stato: COMPLETATO
priorita: bassa
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-015 — Adegua il test della card centrale del selettore all'artwork di selezione

## Contesto

Il criterio originale di questa card chiedeva di "ripristinare" un bordo
pixelato (`StyleBoxFlat`) sulla card centrale del selettore personaggi,
assumendo che la sua assenza fosse una regressione. Non lo è: il
proprietario ha confermato che il bordo pixelato è stato **deliberatamente
sostituito** da un artwork di cornice
(`res://assets/art/ui/pause/pause_panel_frame.png`, applicato come
`StyleBoxTexture` in [scripts/ui/character_select_overlay.gd](../../../scripts/ui/character_select_overlay.gd)
tramite `_make_selected_card_style()`). Il codice runtime è quindi corretto
così com'è; era il test `tests/unit/test_b18w_character_select_refinement.gd`
a controllare il contratto sbagliato (uno `StyleBoxFlat` con bordo
pixelato), fallendo contro un comportamento voluto.

## Comportamento atteso

La card centrale del selettore personaggi mostra l'artwork della cornice di
selezione (`pause_panel_frame.png` tramite `StyleBoxTexture`), distinguibile
visivamente dalle card laterali che restano su `StyleBoxFlat`.

## Criteri di accettazione

- [x] La card centrale espone la cornice artwork (`StyleBoxTexture` su
      `pause_panel_frame.png`), verificata dal controllo automatico.
- [x] Le card laterali (non centrali) restano su `StyleBoxFlat`, per
      mantenere la distinzione visiva del focus.
- [x] Il test non modifica la logica di navigazione né il codice runtime:
      solo l'asserzione sullo stile della card centrale.

## Ambito

- `tests/unit/test_b18w_character_select_refinement.gd`, limitatamente
  all'asserzione sullo stile della card centrale.

Non modificare:

- `scenes/ui/character_select_overlay.tscn` e
  `scripts/ui/character_select_overlay.gd` (il comportamento runtime è
  quello voluto);
- la logica di navigazione e selezione del carosello;
- il contenuto testuale o i ritratti mostrati.

## Verifica

- Test: `tests/unit/test_b18w_character_select_refinement.gd` — aggiornato
  per attendersi `StyleBoxTexture` con `pause_panel_frame.png` al posto del
  bordo pixelato `StyleBoxFlat`.
- `.\tools\run-milestone-checks.ps1 -Milestone PS-015 -Profile Relevant -FocusedSmoke tests/unit/test_b18w_character_select_refinement.gd`
  → focused=1/1 passa. Il batch di regressione riporta un solo fallimento,
  preesistente e scorrelato (`test_b18m_ability_visuals.gd`: SHA-256 non
  registrato per `instinctive_dodge_accent.gd`, già coperto dalla card
  PS-019 aperta); non introdotto da questa modifica.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9
- [ ] Controllo percettivo richiesto: no — nessuna modifica visiva, solo il
      test è stato corretto per riflettere l'artwork già in uso.

## Decisioni

- **2026-08-30 — Scoperto durante la migrazione GUT, non introdotto da
  essa.** Riprodotto rilanciando lo smoke legacy originale in isolamento
  prima che venisse cancellato: falliva identico.
- **2026-08-30 — Il criterio originale era sbagliato.** Il proprietario ha
  chiarito che il bordo pixelato è stato sostituito intenzionalmente da un
  artwork di selezione; il fix corretto è adeguare il test al codice, non
  il codice al test.

## Documenti sincronizzati

- [ ] Nessuno previsto; correzione di un test interno, nessun contratto di
      prodotto cambia.

## Note

Nessuna nota aggiuntiva; priorità bassa perché puramente cosmetico e non
bloccante per il gameplay.
