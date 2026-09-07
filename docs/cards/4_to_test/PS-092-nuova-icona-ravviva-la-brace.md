---
id: PS-092
titolo: Genera una nuova icona per Ravviva la Brace! (ex Bis di Salsiccia)
tipo: art
area: arte
stato: IN VERIFICA
priorita: bassa
dipende_da: []
origine: PS-089
creato: 2026-09-04
aggiornato: 2026-09-07
---

# PS-092 — Genera una nuova icona per Ravviva la Brace! (ex Bis di Salsiccia)

## Contesto

[PS-089](../5_completed/PS-089-elimina-sovrapposizioni-tema-carne-powerup.md) ha
rinominato `ability_cooldown` (`data/upgrades/ability_cooldown.tres`) da
`Bis di Salsiccia` a `Ravviva la Brace!`, perché un pezzo di carne è ora un
soggetto riservato alle otto Specialità di Barb
([PS-078](../4_to_test/PS-078-tematizza-catalogo-specialita-barb.md)). Quella
card ha toccato solo `title`/`description`/`effect_summary`: l'icona runtime
era ancora `assets/art/icons/upgrades/generated/bis_di_salsiccia.png`, derivata
da `assets/art/icons/upgrades/hd/upgrade_bis_di_salsiccia.png`, e ritraeva
letteralmente una salsiccia — l'incoerenza fra testo e immagine che questa card
ha ora sostituito.

## Comportamento atteso

`ability_cooldown` ha un'icona coerente con il nuovo titolo e con la
direzione visiva grigliatore già stabilita in `docs/powerup-catalog.md`
(utensili, condimenti, pirofile, brace, cottura — mai carne), che comunica
"riduzione del cooldown dell'abilità attiva" senza raffigurare un pezzo di
carne.

## Criteri di accettazione

- [x] Nuovo master HD in `assets/art/icons/upgrades/hd/` e derivato
      `128×128` in `assets/art/icons/upgrades/generated/` che sostituiscono
      `upgrade_bis_di_salsiccia.png`/`bis_di_salsiccia.png`, con riga
      aggiornata in `assets/art/icons/upgrades/ASSET-MANIFEST.md` (origine,
      autore/licenza, trasformazioni, hash SHA-256).
- [x] Il soggetto raffigurato non è un taglio, un pezzo o un piatto di carne:
      resta nel registro utensili/brace/cottura già stabilito per il
      catalogo ordinario, mai carne (riservata alle Specialità, PS-078).
- [x] L'icona comunica a colpo d'occhio "ricarica più rapida dell'abilità
      attiva" (es. brace che si riaccende, un secondo giro di cottura),
      leggibile a dimensione carta reale.
- [x] Nessun piccione come soggetto principale, coerente con la direzione
      visiva dichiarata in `docs/powerup-catalog.md`.
- [x] Nessuna modifica a `title`, `description`, `effect_summary`,
      `effect_id`, `effect_parameters`, `weight`, `max_rank`: questa card
      cambia solo l'icona.

## Ambito

- `assets/art/icons/upgrades/hd/` e `assets/art/icons/upgrades/generated/`:
  solo il nuovo asset per `ability_cooldown`.
- `assets/art/icons/upgrades/ASSET-MANIFEST.md`.

Non toccare:

- `data/upgrades/ability_cooldown.tres` oltre al riferimento `icon`;
- qualunque altra carta del catalogo ordinario o delle Specialità di Barb;
- `docs/powerup-catalog.md` oltre a un'eventuale nota sul nuovo file icona,
  se il proprietario la vuole registrare.

Card `tipo: art` che richiede una nuova generazione: per contratto di board
([docs/cards/README.md](../README.md)) va delegata all'agente
`game-art-designer`, non implementata direttamente da `card-risolvi`. Il
riferimento `icon = ExtResource(...)` in `ability_cooldown.tres` verso il
nuovo derivato è lo scambio di un `ext_resource` già esistente sulla stessa
riga, non un nuovo wiring: resta dentro questa card invece di aprire una
card di integrazione separata (vedi [PS-090](../5_completed/PS-090-separa-generazione-integrazione-card-art.md),
che comunque non era ancora chiusa quando questa card è stata scritta).

## Verifica

- Nessuno smoke GUT dedicato: la copertura runtime esistente
  (`test_powerup_first_wave.gd`, `test_b12_upgrade_effects.gd`) verifica già
  che `ability_cooldown` risolva un'icona non nulla; non serve un nuovo test
  per un cambio di solo asset.
- Profilo minimo prima della chiusura: `Focused` sulla suite upgrade
  esistente, per confermare che il nuovo riferimento icona non rompa nulla.
- `run-milestone-checks.ps1 -Milestone PS-092 -Profile Focused
  -FocusedSmoke tests/unit/test_powerup_first_wave.gd -RefreshEditor` → PASS:
  refresh editor riuscito, GUT `1/1`, JUnit `failures="0"`, 38 assert e nessun
  `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o `CONTRACT_FAIL`. Evidenze
  in `%LOCALAPPDATA%/Temp/il-gioco-verification/20260907-235713-PS-092/`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: apri il level-up o Barb con `Ravviva la
      Brace!` in offerta, verifica leggibilità dell'icona a dimensione reale
- [ ] Controllo percettivo richiesto: sì — l'icona deve leggersi come
      brace/cottura, non più come salume, e restare coerente con le altre
      icone del catalogo ordinario

## Decisioni

- **2026-09-07 — Produzione e art review concluse.** OpenAI ImageGen built-in
  ha prodotto il master RGBA `1254×1254`; il derivato `128×128` è stato creato
  con `tools/process-upgrade-icon.ps1` (soglia alfa `8`, padding `12`,
  nearest-neighbor). Master e runtime hanno alfa reale: gli angoli del master
  sono `0,0,1,0`, tutti sotto la soglia visibile `8`, e quelli del derivato
  sono `0,0,0,0`. Nel controllo isolato a `128×128` e `48×48` restano leggibili
  il braciere, la progressione scuro→incandescente e il flare; il candidato è
  stato accettato senza rigenerazione. Prompt, riferimenti osservati, licenza,
  trasformazione e SHA-256 sono nel manifest locale.
- **2026-09-07 — Contratti asset verificati.** Il controllo mirato ha prodotto
  `PS092_ART_ASSET_CHECK` con dimensioni corrette, hash manifest corrispondenti,
  nuovo riferimento runtime valido e vecchi asset rimossi. I tre preset
  contengono ancora l'esclusione `assets/art/icons/upgrades/hd/**`.
- **2026-09-07 — Sostituzione, non accumulo storico nel runtime.** I vecchi
  file `upgrade_bis_di_salsiccia.png` e `bis_di_salsiccia.png` sono rimossi;
  `ability_cooldown.tres` cambia esclusivamente il path dell'`ExtResource`
  icona in `ravviva_la_brace.png`. Gli altri campi restano invariati.

- **2026-09-07 — Direzione di produzione.** L'icona usa un unico braciere
  circolare compatto con carboni scuri che tornano incandescenti e una scia
  curva di riaccensione integrata nelle scintille. Outline scuro spesso,
  cel-shading piatto e palette ambra/arancio la mantengono nella famiglia
  upgrade; la composizione a un solo nucleo evita di duplicare la griglia
  affollata e il burst caotico di `A Tutta Brace!`. Il soggetto resta senza
  carne, testo, numeri o piccioni e deve reggere anche nel controllo a
  `48×48`.

- **2026-09-04 — Aperta da PS-089, non generata dentro quella card.** PS-089
  è una card `chore` di rinomina testuale; generare una nuova icona è lavoro
  di competenza `game-art-designer` per contratto di board, quindi PS-089 ha
  dichiarato l'incoerenza e aperto questa card invece di produrre l'asset.
- **2026-09-04 — Priorità bassa.** L'icona attuale è fuorviante ma non rotta:
  il gioco funziona, la carta resta selezionabile e leggibile come "riduzione
  cooldown" dal testo. Non blocca nessun'altra card.
- **2026-09-04 — Titolo corretto in `Ravviva la Brace!` (era `Bis di
  Brace`).** Il proprietario ha giudicato `Bis di Brace` un titolo debole e
  ha chiesto qualcosa sul riaccendere/ravvivare la brace: il nuovo titolo
  comunica meglio "l'abilità è di nuovo pronta" (la brace si riaccende)
  invece di limitarsi a un'eco del vecchio "bis". Propagato in
  `data/upgrades/ability_cooldown.tres`, `docs/powerup-catalog.md`, PS-089,
  PS-090 e nei test coinvolti.

## Documenti sincronizzati

- [x] `assets/art/icons/upgrades/ASSET-MANIFEST.md`: nuova sezione e riga per il
      derivato che sostituisce `bis_di_salsiccia`.
- [x] `docs/powerup-catalog.md`: rimossa la nota ormai superata sulla
      salsiccia runtime e registrato il soggetto definitivo.

## Note

La produzione automatica è completa. Restano aperti l'accettazione percettiva
del proprietario nel layout reale e i gate Windows, APK e Pixel 9 dichiarati
sopra; per questo la card resta `IN VERIFICA`.
