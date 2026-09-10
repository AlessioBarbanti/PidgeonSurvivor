---
id: PS-153
titolo: Rimuovi il badge di modalità dalla ricompensa di Barb e ingrandisci la riga di redenzione
tipo: ux
area: ui
stato: IN VERIFICA
priorita: bassa
dipende_da: []
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-153 — Rimuovi il badge di modalità dalla ricompensa di Barb e ingrandisci la riga di redenzione

## Contesto

L'header di `BarbRewardOverlay` (sia in modalità sblocco Specialità che in
modalità premio bonus) mostra un piccolo riquadro/badge sopra il titolo
(`ModeLabel`, "NUOVA SPECIALITÀ" o "RICOMPENSA BONUS") che il proprietario
vuole rimuovere. La riga sotto il titolo (`RedemptionLabel`, oggi "Con Barb
ai fornelli, va sempre a finire bene!" nel fallback generico, tema `BodyS` —
12px, il più piccolo del catalogo tipografico) va aggiornata nel testo e resa
un po' più grande.

## Comportamento atteso

L'header della ricompensa di Barb, in entrambe le modalità (sblocco
Specialità e premio bonus), non mostra più il badge di modalità. La riga di
redenzione generica recita "Con Barb alla griglia, va sempre a finire
bene!" ed è leggibile a una dimensione di font maggiore di quella attuale.

## Criteri di accettazione

- [x] Il nodo `ModeLabel` (e il suo contenitore `ModeCenter`) non esiste più
      in `scenes/ui/barb_reward_overlay.tscn`; nessun riquadro/badge resta
      visibile sopra il titolo in nessuna delle due modalità — confermato sia
      dallo smoke (`find_child("ModeLabel", ...)` nullo) sia dagli screenshot
      reali di entrambe le modalità.
- [x] `BarbRewardOverlay.get_mode_text()` e il campo `_mode_label` sono
      rimossi dallo script: nessun riferimento pendente a un nodo che non
      esiste più.
- [x] La costante `BarbRewardOverlay.BARB_GENERIC_REWARD_LINE` recita "Con
      Barb alla griglia, va sempre a finire bene!" (era "... ai fornelli,
      ...") — verificato anche dal testo di scena di default su
      `RedemptionLabel`.
- [x] `RedemptionLabel` usa `theme_type_variation = &"BodyM"` (16px, contro i
      12px di `BodyS` di prima) — confermato leggibile negli screenshot reali
      di entrambe le modalità.
- [x] Nessuna regressione sul resto dell'header (titolo, ritratto di Barb,
      layout delle tre carte) in nessuna delle due modalità — Relevant 35/35,
      Full 139/139.

## Ambito

- `scenes/ui/barb_reward_overlay.tscn`: rimuove `ModeCenter`/`ModeLabel` e il
  relativo `StyleBoxFlat_mode` se non più referenziato; aggiorna
  `theme_type_variation` di `RedemptionLabel`.
- `scripts/ui/barb_reward_overlay.gd`: rimuove `_mode_label`,
  `get_mode_text()` e le righe che impostano testo/colore del badge in
  `_show_offer()`; aggiorna `BARB_GENERIC_REWARD_LINE`.
- `tests/unit/test_ps036_barb_reward_visual_identity.gd`: rimuove le
  asserzioni su `get_mode_text()` (il metodo non esiste più).

Non toccare:

- `TitleLabel` ("LE SPECIALITÀ DI BARB" / "IL PREMIO DI BARB") e la sua
  logica di scelta testo;
- Il layout delle carte (`Cards`, `UpgradeCard`), non oggetto di questa
  card;
- La logica di redenzione/nome amico (`_redeemed_friend_name`,
  `set_redeemed_friend_name`), solo il testo del fallback generico cambia.

## Verifica

- Smoke: `tests/unit/test_ps036_barb_reward_visual_identity.gd` (aggiornato:
  le due asserzioni su `get_mode_text()` sono sostituite da
  `assert_null(find_child("ModeLabel", ...))`) e
  `tests/unit/test_ps101_evil_hunger_narrative.gd` (verifica già la
  costante `BARB_GENERIC_REWARD_LINE` per riferimento, non una stringa
  hardcoded: resta verde senza modifiche allo smoke).
- Focused (`-RefreshEditor`): 3/3 verdi (119 asserzioni), nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Relevant: 1/1 focused, 34/34 regressioni, 35/35 step, nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Full: 137/137 regressioni, toolchain PASS, 139/139 step, nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Screenshot reali rigenerati (`exports/ui-screenshots/05b_barb_speciality.png`,
  `05c_barb_bonus.png`, entrambi 16:9 e Pixel 9 20:9): badge assente, nuovo
  testo e font più grande confermati in entrambe le modalità.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9
- [ ] Controllo percettivo richiesto: sì — ispezionati gli screenshot reali
      di entrambe le modalità in questa sessione (badge assente, testo e
      font corretti); lasciato aperto per una conferma diretta del
      proprietario/direttore-artistico, non un'auto-validazione.

## Decisioni

- **2026-09-10 — Richiesta esplicita del proprietario, estesa da lui stesso
  a entrambe le modalità** ("E stesse modifiche anche in premio di barb"):
  rimozione badge, nuovo testo, font più grande valgono sia per lo sblocco
  Specialità sia per il premio bonus, essendo lo stesso `RedemptionLabel` e
  lo stesso `ModeLabel` condivisi dalle due modalità.
- **2026-09-10 — Automatici verdi, screenshot reali confermano il risultato
  atteso.** Rigenerato il pacchetto ufficiale
  (`tools/_capture_ui_screenshots.gd`): in entrambe le modalità il badge non
  compare più, la riga recita "Con Barb alla griglia, va sempre a finire
  bene!" a `BodyM` (16px), nessuna regressione su titolo/ritratto/carte.
  Card portata a `IN VERIFICA`: restano aperti i soli gate manuali su
  device/piattaforma.

## Documenti sincronizzati

- [x] `docs/enemies-bosses.md`: citazione di `BARB_GENERIC_REWARD_LINE`
      aggiornata al nuovo testo ("Con Barb alla griglia...").

## Note

Nessuna implicazione per `docs/visual-audio-identity.md`: nessun nuovo
asset, solo rimozione di un nodo esistente e una `theme_type_variation` già
in catalogo.
