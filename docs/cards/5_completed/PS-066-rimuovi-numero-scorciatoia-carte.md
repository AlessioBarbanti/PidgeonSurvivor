---
id: PS-066
titolo: Rimuovere il numero di scorciatoia visibile dalle carte upgrade
tipo: fix
area: ui
stato: COMPLETATO
priorita: bassa
dipende_da: [PS-047]
origine:
creato: 2026-09-01
aggiornato: 2026-09-04
---

# PS-066 — Rimuovere il numero di scorciatoia visibile dalle carte upgrade

## Contesto

Il proprietario, guardando lo stesso screenshot che ha segnalato PS-064
(carte non centrate, sopra la safe area), ha chiesto di rimuovere anche il
numero (1/2/3) mostrato nell'angolo in alto a sinistra di ogni carta upgrade
(`ShortcutLabel` in `upgrade_card.tscn`).

Il numero era puramente un'etichetta visiva: le scorciatoie da tastiera
(tasti 1/2/3 per scegliere la carta corrispondente,
`_shortcut_index_for_key()` in `upgrade_overlay.gd`) leggono l'evento
tastiera direttamente, senza dipendere dal testo dell'etichetta — restano
invariate.

## Comportamento atteso

Le carte upgrade (offerta normale, `BARB_SPECIALITY`, `BARB_BONUS`, che
riusano la stessa scena) non mostrano più alcun numero. Le scorciatoie da
tastiera 1/2/3 continuano a funzionare.

## Criteri di accettazione

- [x] Nessun nodo `ShortcutLabel`/`Header` in `upgrade_card.tscn`.
      *Rimossi entrambi (il numero e lo spaziatore che lo affiancava):
      `Content` parte direttamente da `IconCenter`.*
- [x] `upgrade_card.gd` non referenzia più l'etichetta rimossa.
      *`_shortcut_label` e i suoi due usi (`configure()`, `clear_card()`)
      rimossi.*
- [x] Le scorciatoie da tastiera 1/2/3 restano invariate.
      *`_shortcut_index_for_key()` in `upgrade_overlay.gd` non tocca
      `ShortcutLabel`: nessuna modifica necessaria, confermato leggendo il
      codice.*
- [x] Nessuna regressione sull'altezza minima dinamica delle carte (PS-063):
      la rimozione toglie un figlio da `Margins/Content`, che
      `_grow_to_fit_content()` già somma dinamicamente
      (`content.get_children()`), quindi si adatta da solo.

## Ambito

- `scenes/ui/upgrade_card.tscn` (rimozione di `Header`/`ShortcutLabel`/
  `HeaderSpacer`).
- `scripts/ui/upgrade_card.gd` (rimozione dei riferimenti).

Non toccare:

- `_shortcut_index_for_key()` e la gestione input in `upgrade_overlay.gd`
  (le scorciatoie restano attive, solo l'etichetta visiva sparisce);
- il resto della gerarchia della carta (PS-047/063).

## Verifica

- Smoke esistenti riusati: `tests/unit/test_ps047_upgrade_card_hierarchy.gd`,
  `tests/unit/test_b11_upgrade_overlay.gd` (nessuno referenzia
  `ShortcutLabel`, verificato con una ricerca nel repository prima della
  rimozione).
- Cattura UI reale (`tools/_capture_ui_screenshots.gd` via Xvfb) ispezionata
  a occhio sul profilo `16x9`: nessun numero visibile sulle carte upgrade né
  su quelle del premio Barb.

## Gate manuali

- [x] Runtime Windows: confermato dal proprietario.
- [x] Validazione statica APK: confermata dal proprietario.
- [x] Runtime fisico Pixel 9: confermato dal proprietario insieme a PS-064.
- [x] Controllo percettivo richiesto: sì — il proprietario ha riconfermato la
      rimozione allo stesso modo in cui l'aveva richiesta.

## Documenti sincronizzati

- [x] Nessuno: modifica di presentazione interna, nessun contratto durevole
      cambia oltre a quanto già coperto da PS-047.

## Note

Priorità `bassa`: modifica cosmetica isolata, senza impatto funzionale né
sulle scorciatoie da tastiera.
