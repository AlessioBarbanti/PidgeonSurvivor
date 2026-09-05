---
id: PS-101
titolo: Racconta la fame dietro agli Evil e la redenzione di Barb
tipo: feat
area: gameplay
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-09-05
aggiornato: 2026-09-05
---

# PS-101 — Racconta la fame dietro agli Evil e la redenzione di Barb

## Contesto

Il gioco non spiega mai perché un amico diventi `Evil <Nome>`, né perché
sconfiggerlo con la Specialità di Barb lo faccia tornare come prima.
`BossDefinition` ([scripts/bosses/boss_definition.gd](../../../scripts/bosses/boss_definition.gd))
espone un campo `quote` con gate di approvazione (`quote_approved`,
`get_safe_quote()`), ma vale solo per `data/bosses/first_boss.tres`, dove era
ancora il placeholder non approvato `"Citazione personale in attesa di
approvazione."` — nemmeno il Piccione Malvagio aveva una battuta vera.
`BossEncounter.resolve_variant()` ([scripts/bosses/boss_encounter.gd](../../../scripts/bosses/boss_encounter.gd))
duplica quel `BossDefinition` per costruire la variante Evil
(`evil_definition := baseline.duplicate(true)`), quindi ogni `Evil <Nome>`
mostra già la stessa citazione del Piccione Malvagio — questo meccanismo di
condivisione **non era un difetto da correggere**, si è rivelato la
direzione voluta dal proprietario (vedi Decisioni).

`BarbRewardOverlay` ([scripts/ui/barb_reward_overlay.gd](../../../scripts/ui/barb_reward_overlay.gd))
mostrava solo `"LE SPECIALITÀ DI BARB"` / `"IL PREMIO DI BARB"`, senza mai
nominare quale amico fosse stato appena salvato, anche se
`BossEncounter.get_last_defeated_title()` lo sapeva già e non era letto da
nessuna UI.

Il proprietario vuole un aggancio narrativo semplice, coerente col tono
leggero e col tema griglia del gioco (sottotitolo "It's grilling time!"): gli
amici diventano malvagi perché hanno **fame**, non per cattiveria. Il Player
li affronta per fermarli, non per punirli. Una volta sconfitti, la Specialità
di Barb li sfama e li fa tornare amici come prima. **Barb resta però una
figura sempre positiva**: nessun testo sul suo schermo di ricompensa può
avere un tono ammonitore o negativo, nemmeno per restare in tema con la fame
degli Evil.

## Comportamento atteso

- Il Piccione Malvagio e ogni `Evil <Nome>` condividono **una sola citazione**
  nella Boss Intro, a tema fame, mai intercambiabile con un tono cupo o
  violento — non una citazione diversa per ciascuno degli otto profili.
- Il Barb Reward mostrato dopo la vittoria nomina l'amico appena sconfitto e
  comunica che è tornato con noi grazie a Barb, con un tono sempre positivo
  e mai un ammonimento (né sulla fame né su altro).
- Quando il Boss sconfitto è il Piccione Malvagio (nessun amico da nominare),
  il Barb Reward mostra comunque una riga positiva generica su Barb, mai un
  vuoto o un testo incoerente.

## Criteri di accettazione

- [x] `BossDefinition.get_safe_quote()` **non** fa branch sul `friend_profile`:
      resta il meccanismo originale a citazione singola condivisa, ereditata
      dagli Evil tramite `duplicate(true)` in `BossEncounter.resolve_variant()`.
      Coperto da `test_evil_variant_shares_the_single_boss_quote_with_no_per_friend_branch`.
- [x] `data/bosses/first_boss.tres` ha una citazione scritta **e approvata
      esplicitamente dal proprietario** (`quote_approved = true`, vedi
      Decisioni per il testo finale): la Boss Intro mostra la citazione vera,
      non più `safe_quote_placeholder`, per il Piccione Malvagio e per ogni
      `Evil <Nome>`. Coperto da
      `test_baseline_pigeon_quote_is_approved_and_live_for_baseline_and_evil`.
- [x] `BarbRewardOverlay` mostra, oltre al titolo esistente, il nome
      dell'amico appena salvato — letto da un nuovo
      `BossEncounter.get_last_defeated_friend_name()` (non
      `get_last_defeated_title()`, che per un Evil resta "Evil <Nome>": va
      nominato "Magno", non "Evil Magno", una volta redento) — in una frase
      sempre positiva ("`<Nome>` è tornato tra noi, grazie a Barb!").
- [x] Quando il Boss sconfitto è il Piccione Malvagio (nessun `friend_profile`,
      niente da "salvare"), `BarbRewardOverlay` mostra la riga generica
      positiva `BarbRewardOverlay.BARB_GENERIC_REWARD_LINE` ("Con Barb ai
      fornelli, va sempre a finire bene!"), mai un nome vuoto o un testo
      incoerente.
- [x] Nessun testo del Barb Reward contiene mai un tono ammonitore o negativo
      (né "fame" né "orribile" o simili): Barb resta sempre una figura
      positiva, per richiesta esplicita del proprietario. Coperto da
      `test_barb_reward_stays_positive_naming_the_redeemed_friend_or_not`.
- [x] Nessuna citazione o riga di redenzione supera lo spazio disponibile nel
      proprio label senza troncarsi in modo illeggibile. La riga di
      redenzione vive dentro l'header a dimensione fissa di
      `BarbRewardOverlay` con `clip_text`/ellissi invece che in una riga
      aggiunta al `VBoxContainer` principale (vedi Decisioni per la
      regressione trovata e corretta su questo punto).

## Ambito

- `scripts/bosses/boss_encounter.gd`: `get_last_defeated_friend_name()`.
- `scripts/ui/barb_reward_overlay.gd` e
  [scenes/ui/barb_reward_overlay.tscn](../../../scenes/ui/barb_reward_overlay.tscn):
  riga di redenzione positiva con il nome dell'amico salvato.
- `data/bosses/first_boss.tres`: citazione condivisa, approvata.
- `docs/enemies-bosses.md`: sincronizzare il contratto narrativo finale.
- `tests/unit/test_b15_boss_encounter.gd`: due assert non più valide con la
  citazione approvata (vedi Decisioni), non un cambio di contratto.

Non toccare:

- `BossDefinition.get_safe_quote()` oltre a lasciarlo come già era (nessun
  branch per amico): è la direzione confermata dal proprietario, non un
  difetto da correggere;
- `BossEncounter.resolve_variant()` — RNG, soglie e selezione del profilo
  restano quelli di PS-006/PS-037;
- il layout e la cornice della Boss Intro (quello è
  [PS-102](./PS-102-cornice-dedicata-boss-intro.md)/PS-103, non questa card);
- `effect_id`, statistiche, Signature e ogni altro contratto meccanico dei
  profili Evil.

## Verifica

- Smoke: `tests/unit/test_ps101_evil_hunger_narrative.gd` → marker
  `EVIL_HUNGER_NARRATIVE_SMOKE_OK` — quattro test: nessun branch per amico su
  `get_safe_quote()` (citazione condivisa, non un fallback per profilo),
  citazione approvata live su Piccione Malvagio ed Evil, tono sempre
  positivo del Barb Reward (con e senza amico nominato, mai "fame"/"orribile"
  in output), e nome dell'amico riportato da
  `BossEncounter.get_last_defeated_friend_name()` sia per un Evil sia per il
  Piccione Malvagio (vuoto).
- **Eseguita il 5 settembre 2026** in sandbox Linux remota (Godot 4.7.1
  headless via `tools/setup-remote-sandbox.sh`, non il runner PowerShell di
  `docs/setup.md`): suite `tests/unit/` completa → 320/320 passed, nessun
  `SCRIPT ERROR` né `FATAL EXCEPTION` nel log. Include la correzione di
  `test_b15_boss_encounter.gd::test_composed_encounter` (vedi Decisioni): la
  citazione approvata, più lunga del vecchio placeholder e su due righe, ha
  esposto un'assunzione di test non più valida e un varco di timing
  preesistente, non un difetto del gioco.
- Profilo minimo prima della chiusura: `Relevant` — non eseguito col runner
  PowerShell ufficiale (ambiente senza Windows in questa sessione): la corsa
  GUT headless sopra ne è l'equivalente funzionale ma non sostituisce
  `run-milestone-checks.ps1` per l'onestà dei gate.

## Gate manuali

- [ ] Runtime Windows — non eseguito in questa sessione (sandbox Linux senza
      Godot Windows/editor grafico): resta aperto, non silenziosamente
      assunto verde.
- [ ] Validazione statica APK — non pertinente a questa card, ma non
      eseguita comunque.
- [ ] Runtime fisico Pixel 9 (percorso: intro Boss di un Evil qualunque +
      Barb Reward dopo la vittoria) — richiede device fisico, non
      disponibile in questa sessione: gate lasciato esplicitamente aperto.
- [x] Controllo percettivo del testo: la citazione condivisa è stata letta e
      approvata esplicitamente dal proprietario il 5 settembre 2026 (vedi
      Decisioni). Resta comunque da vedere a schermo reale su device (gate
      Pixel 9 sopra), non solo nel testo.

## Decisioni

- **2026-09-05 — La fame è l'unica causa della trasformazione, mai
  cattiveria innata.** Il proprietario ha chiesto esplicitamente un tono
  leggero e giocoso, coerente col resto del gioco: nessun testo deve
  suggerire crudeltà, violenza reale o un evento oscuro.
- **2026-09-05 — Prima versione scartata: otto citazioni distinte, una per
  profilo Evil.** Prima iterazione: campo `evil_quote` per profilo su
  `FriendDefinition`, con gate di approvazione dedicato
  (`evil_quote_approved`) e branch in `BossDefinition.get_safe_quote()` su
  `friend_profile`, sullo stesso modello di `get_safe_title()`/
  `get_safe_portrait()`. Il proprietario ha respinto l'intero set ("queste
  citazioni non mi piacciono") e ha chiesto **una sola citazione generica per
  tutti** — non solo per gli Evil, per ogni Boss. Rimossi `evil_quote`,
  `evil_quote_approved`, `safe_evil_quote` e il relativo getter da
  `FriendDefinition`; il branch in `get_safe_quote()` è stato tolto,
  ripristinando il meccanismo di condivisione originale (`duplicate(true)`)
  che già esisteva prima di questa card. Le otto citazioni scartate restano
  solo come riferimento storico, non nel codice: Magno "Ho una fame che
  scuote la terra..."; Bea "Ho una fame che brucia più della mia scia...";
  Zat "Persino le mie scariche sanno di fame..."; Alea "La fortuna gira, ma
  il mio stomaco gira più forte..."; Aleo "Sono freddo perché ho lo stomaco
  vuoto..."; Lollo "Iperfocalizzato... sulla fame..."; Migi "Mi chiudo nel
  guscio perché fuori c'è solo fame..."; Marghe "Ballo per non pensarci, ma
  la fame balla più forte di me...".
- **2026-09-05 — Seconda versione scartata: riga "La fame fa fare cose
  orribili." sul Barb Reward.** Prima iterazione della riga ricorrente:
  mostrata sempre nel Barb Reward, con o senza amico nominato. Il
  proprietario ha segnalato che il tono era troppo negativo/ammonitore per
  lo schermo di Barb, che deve restare una figura sempre positiva. Sostituita
  con `BarbRewardOverlay.BARB_GENERIC_REWARD_LINE` ("Con Barb ai fornelli, va
  sempre a finire bene!") per il caso senza amico nominato, e con "`<Nome>` è
  tornato tra noi, grazie a Barb!" quando un amico è stato redento — nessuna
  delle due menziona più la fame.
- **2026-09-05 — Citazione del Piccione Malvagio approvata dal
  proprietario, condivisa anche dagli Evil.** Testo finale, dettato
  esplicitamente dal proprietario: "Non sono cattivo, sono solo
  affamato...\nE nessuno mi ha ancora portato la grigliata!" (due righe,
  `quote` è `@export_multiline`). Scritta in `data/bosses/first_boss.tres`
  con `quote_approved = true`. Funziona genericamente sia per il Piccione
  Malvagio sia per qualunque `Evil <Nome>` proprio perché non nomina alcuna
  persona specifica.
- **2026-09-05 — La citazione approvata, su due righe, ha esposto una
  regressione preesistente in `test_b15_boss_encounter.gd`, corretta in
  questa card.** `test_composed_encounter` faceva due assunzioni non più
  valide: (1) l'assert `definition.quote not in
  boss_ui.get_intro_quote_text()` presupponeva una citazione sempre non
  approvata — con `quote_approved = true` il testo vero compare per design,
  quindi l'assert falliva sempre; semplificato per verificare solo che la UI
  mostri `get_safe_quote()`, qualunque cosa risolva. (2) l'assert sul
  pannello dentro la safe area leggeva `get_intro_panel_rect()` **subito**
  dopo `controller._process(120.01)`, senza attendere i due frame del
  ricalcolo differito (`_defer_reflow_intro_panel_position`, PS-071): col
  vecchio placeholder corto il rect immediato (frame 0, prima
  dell'assestamento del wrapping) capitava già dentro la safe area per
  caso; con la citazione approvata, più lunga e su due righe, il rect
  immediato eccede transitoriamente la safe area (verificato: si assesta
  correttamente entro 2 frame). Aggiunto `await wait_process_frames(2)`
  prima dell'assert, che è poi il motivo per cui `_defer_reflow_intro_panel_position`
  esiste da PS-071. Non e' una regressione del gioco: rieseguita l'intera
  suite dopo la correzione, 320/320 verdi.
- **2026-09-05 — Riga di redenzione nell'header fisso, non in una riga
  dedicata del layout principale.** Prima versione: `RedemptionLabel` come
  terzo figlio di `SafeMargins/Layout`, accanto a `HeaderPanel` e `Cards`.
  Funzionava isolatamente ma rompeva
  `test_ps046_level_up_modal_isolation.gd`: l'altezza aggiunta spingeva la
  posizione centrata calcolata da `_reflow_top_margin()` verso l'alto,
  facendo intersecare `TitleLabel` con la fascia HUD superiore al primo
  passaggio di reflow (prima che il secondo passaggio differito
  ricalcolasse). Spostata dentro `HeaderText`
  (`HeaderPanel/HeaderContent/TextMargins/HeaderText`), che ha già margine
  verticale inutilizzato e — poiché `HeaderContent` è un `Control` semplice,
  non un `Container` — non propaga la crescita dei figli al genitore:
  l'altezza totale misurata da `_measure_layout_min_height()` resta
  identica a prima della card. `clip_text` + `text_overrun_behavior`
  sostituisce l'autowrap per restare garantito su una riga sola. Verificato
  rieseguendo sia `test_ps046_level_up_modal_isolation.gd` sia l'intera
  suite dopo la correzione.

## Documenti sincronizzati

- [ ] `docs/characters.md`: non toccato. La citazione resta bozza non
      approvata; il file dichiara nomi e testi "approvati dal proprietario
      del progetto il 17 agosto 2026" e non va anticipato.
- [x] `docs/enemies-bosses.md`: nuova sezione "Perché diventano Evil: la
      fame (PS-101)" dopo "Boss Intro: identità individuale", aggiornata per
      descrivere la citazione singola condivisa (non un campo per profilo) e
      il tono sempre positivo del Barb Reward.

## Note

Questa card è indipendente dal redesign visivo del pannello
([PS-102](./PS-102-cornice-dedicata-boss-intro.md)/PS-103): tocca solo dati e
copy, non frame o layout. Le due linee di lavoro possono procedere in
parallelo e chiudersi in qualunque ordine.

Non è una card `tipo: art`: non richiede delega a `game-art-designer`. Una
volta approvata la citazione condivisa, il proprietario può invocare
manualmente `revisore-design-ux` per verificare che comunichi davvero "fame
→ scontro → redenzione" a chi gioca per la prima volta — non è invocazione
automatica di `card-risolvi`, va richiesta esplicitamente se il proprietario
la ritiene utile.
