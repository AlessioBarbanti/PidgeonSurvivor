---
id: PS-036
titolo: Rendi distinta la schermata delle Specialità di Barb
tipo: ux
area: ui
stato: IN VERIFICA
priorita: media
dipende_da: []
origine: PS-012
milestone:
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-036 — Rendi distinta la schermata delle Specialità di Barb

## Contesto

PS-012 ha introdotto `BarbRewardOverlay` come schermata dedicata alla ricompensa Boss, ma oggi la sua struttura visiva è troppo simile alla normale selezione upgrade.

Dallo screenshot della selezione attuale, il layout a tre carte è già leggibile e funzionale: tre pannelli grandi, sfondo scuro, bordo blu e carta selezionata evidenziata. Il problema non è la struttura, ma il fatto che la schermata Barb non venga percepita come un momento speciale e separato dal normale level-up.

Inoltre il proprietario ha richiesto che durante questa schermata sia presente una **caricatura di Barb**, basata sulla foto fornita.

## Comportamento atteso

La schermata `BarbRewardOverlay` deve rimanere coerente con la selezione upgrade esistente, ma risultare visivamente distinta come ricompensa Boss speciale.

### Struttura generale

La schermata mantiene:

- il layout a tre carte affiancate;
- la selezione di una carta alla volta;
- la leggibilità del contenuto testuale;
- la stessa logica di focus e input della schermata upgrade.

Non deve diventare una UI completamente diversa: deve essere percepita come **una variante premium/speciale** della selezione normale.

### Header dedicato

La parte alta della schermata deve essere diversa dal normale `LIVELLO X`.

Al posto del titolo level-up, la schermata mostra un header dedicato, per esempio:

- `LE SPECIALITÀ DI BARB`

oppure, in modalità fallback:

- `IL PREMIO DI BARB`

L’header deve avere maggiore personalità visiva rispetto alla schermata normale, con palette più calda e tono da ricompensa speciale.

### Caricatura di Barb

La schermata include una **caricatura di Barb** ricavata dalla foto di riferimento fornita dal proprietario.

La caricatura deve essere:

- riconoscibile come Barb;
- stilizzata/coerente con il linguaggio visivo del gioco;
- non fotorealistica;
- usata come elemento decorativo non interattivo.

Elementi caratteristici da mantenere:

- sorriso/espressione amichevole;
- barba;
- capelli corti;
- piercing al sopracciglio;
- gesto del pollice alzato, se compatibile con l’inquadratura finale.

Posizionamento baseline:

- nella parte alta della schermata;
- integrata nell’header o leggermente sovrapposta sopra/accanto al titolo;
- senza coprire il testo delle tre carte;
- senza ridurre in modo significativo lo spazio utile alle scelte.

### Trattamento delle carte

Le carte delle vere Specialità devono restare strutturalmente uguali alle `UpgradeCard`, ma avere un trattamento grafico dedicato.

Direzione visiva:

- mantenere fondo scuro leggibile;
- sostituire il bordo freddo blu con una variante più calda/oro/arancio;
- mantenere chiaro quale carta è selezionata;
- mantenere leggibili nome, descrizione e rango.

L’obiettivo non è rifare le carte da zero, ma far capire che **queste non sono tre carte qualsiasi**.

### Differenza tra modalità Specialità e fallback

La schermata Barb può esistere in due casi:

1. **Sblocco di una Specialità nuova**
   - carte con trattamento speciale Barb;
   - messaggio chiaramente legato allo sblocco.

2. **Specialità esaurite → ricompensa bonus**
   - stessa cornice scenica di Barb;
   - stessa caricatura/identità generale;
   - ma carte graficamente normali o più vicine al normale level-up, perché non rappresentano nuove Specialità.

In questo modo il Player distingue:

- **sblocco di una meccanica nuova**;
- **semplice premio bonus dato da Barb**.

### Atmosfera e presentazione

La schermata può usare piccoli elementi decorativi coerenti con il tema Barb/griglia, purché non disturbino la leggibilità:

- lieve glow caldo;
- piccoli dettagli decorativi;
- leggero trattamento scenico dello sfondo.

Non devono essere introdotti effetti visivi invasivi o animazioni che rallentano la scelta.

## Criteri di accettazione

- [x] `BarbRewardOverlay` è percepibile come distinta dal normale upgrade overlay.
- [x] Il layout a tre carte resta invariato nella sua struttura principale.
- [x] La schermata mostra un titolo dedicato a Barb e non il normale titolo `LIVELLO X`.
- [x] La schermata include una caricatura visibile di Barb basata sulla foto di riferimento.
- [x] La caricatura è stilizzata e coerente con il linguaggio visivo del gioco.
- [x] La caricatura mantiene almeno barba, capelli corti e piercing al sopracciglio come tratti riconoscibili.
- [x] La caricatura non copre né rende illeggibili le tre carte.
- [x] Le carte delle vere Specialità hanno un trattamento visivo distinto dalle normali carte upgrade.
- [x] Nome, descrizione e rango delle carte restano leggibili almeno quanto nella schermata upgrade normale.
- [x] La carta selezionata resta chiaramente evidenziata.
- [x] La modalità “nuova Specialità” è distinguibile dalla modalità “premio bonus”.
- [x] In modalità premio bonus, la schermata mantiene l’identità di Barb ma non comunica erroneamente lo sblocco di una nuova Specialità.
- [x] Focus, input, selezione e lock anti-tap restano invariati rispetto al contratto di PS-012.
- [ ] La schermata resta leggibile su Windows e su Pixel 9.

## Ambito

- `scenes/ui/barb_reward_overlay.tscn`
- `scripts/ui/barb_reward_overlay.gd`
- eventuale variante visuale di `upgrade_card.tscn` per il contesto Barb
- asset della caricatura di Barb
- asset decorativi o header dedicati
- copy della schermata Barb

Non toccare:

- la logica di generazione dell’offerta;
- eleggibilità delle Specialità;
- RNG deterministico;
- assegnazione del rank 1;
- progressione delle Specialità;
- comportamento della schermata level-up normale, salvo eventuale riuso di componenti;
- input, focus e lock anti-tap già definiti da PS-012.

## Verifica

- Smoke: `tests/unit/test_ps036_barb_reward_visual_identity.gd` → marker `BARB_REWARD_VISUAL_IDENTITY_SMOKE_OK`
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [x] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: sconfiggi un Boss → apri schermata Barb con Specialità disponibili → verifica versione fallback con Specialità esaurite)
- [ ] Controllo percettivo richiesto: sì
- [ ] La schermata Barb è chiaramente distinta dal normale level-up già al primo colpo d’occhio.
- [ ] La caricatura di Barb è riconoscibile e aggiunge identità senza disturbare la leggibilità.
- [ ] Le carte restano il focus visivo principale della scelta.
- [ ] La modalità sblocco e la modalità fallback non vengono confuse.
- [ ] La schermata mantiene la chiarezza e l’ordine della selezione upgrade esistente.

## Decisioni

- **2026-08-31 — PS-012 resta l'origine, non una dipendenza operativa.** La
  UI e il flusso `BarbRewardOverlay` sono già presenti nel runtime; i gate
  manuali ancora aperti di PS-012 non impediscono il restyle puramente
  presentativo di questa card.
- **2026-08-31 — La schermata Barb mantiene il layout base della selezione upgrade.** Non viene creato un secondo paradigma UI.
- **2026-08-31 — La distinzione avviene tramite header, palette, cornice e presenza della caricatura di Barb.** Questo rende la ricompensa Boss immediatamente riconoscibile.
- **2026-08-31 — La schermata deve includere una caricatura del proprietario.** La caricatura è decorativa, coerente con il gioco e basata sulla foto fornita.
- **2026-08-31 — La modalità fallback conserva la scena Barb ma non deve fingere di sbloccare nuove Specialità.**
- **2026-08-31 — L'header non usa sottotitoli esplicativi.** Su richiesta del
  proprietario vengono rimossi sia “Barb sblocca una nuova meccanica per questa
  run” sia il contatore testuale “Specialità al completo”; titolo e badge
  distinguono già le due modalità senza appesantire la composizione.
- **2026-08-31 — Barb viene presentato come “Maestro della griglia”.** Il
  ritratto finale usa grembiule annerito, guanto in pelle consumato, secondo
  guanto riposto, fuliggine/unto, occhi blu scuri e pixel cluster più grandi;
  resta visibile una sola mano attiva con pollice di proporzioni naturali.
- **2026-08-31 — La fotografia resta fuori dal repository.** Il proprietario
  l'ha fornita e ha richiesto esplicitamente la caricatura; master ImageGen,
  derivato runtime, prompt, trasformazioni, licenza e hash sono registrati nel
  manifest locale dell'asset.
- **Sostituisce:** la direzione precedente “da definire” della schermata Barb.

## Documenti sincronizzati

- [x] `docs/prd.md` §3.3: identità distinta sblocco/bonus.
- [x] `assets/art/ui/barb_reward/ASSET-MANIFEST.md`: approvazione d'uso,
      prompt finale, trasformazioni e hash; non esiste un `content-approvals.md`.

## Note

La schermata upgrade normale resta la base: tre carte grandi, leggibilità alta, focus immediato.

La schermata Barb deve differenziarsi senza rompere questa chiarezza.

Direzione sintetica:

- **upgrade normale** = freddo, pulito, funzionale;
- **Specialità di Barb** = caldo, speciale, premio, sblocco;
- **premio bonus di Barb** = identità Barb, ma carte più vicine al normale upgrade.

La caricatura di Barb deve essere trattata come asset UI dedicato e non come semplice foto incollata.

### Evidenze 2026-08-31

- `Focused`: PASS (`1/1`), marker
  `BARB_REWARD_VISUAL_IDENTITY_SMOKE_OK`, log
  `20260831-021659-PS-036` senza `SCRIPT ERROR`, `SMOKE_FAIL` o
  `CONTRACT_FAIL`.
- `Relevant`: il focused è PASS, ma la regressione aggregata del worktree si è
  fermata al timeout controllato di 240 s dopo `16/73` script. Il piano include
  `52` file modificati, in gran parte appartenenti alle card Boss già presenti;
  non è un fallimento attribuibile a un'asserzione PS-036. Log:
  `20260831-015654-PS-036`.
- Windows/OpenGL Compatibility: cattura runtime conclusa con
  `PS036_CAPTURE_DONE`, senza errori script.
- I tre preset Windows/APK/AAB escludono
  `assets/art/ui/barb_reward/hd/**`; il test focused verifica il contratto.
- Screenshot ispezionati a `1280x720`:
  `exports/ui-screenshots/ps036/01_barb_speciality.png` e
  `exports/ui-screenshots/ps036/02_barb_bonus.png`. In entrambe la caricatura
  resta nell'header senza coprire le carte; sblocco caldo/oro e bonus con carte
  fredde risultano distinti. La cattura aggiornata non contiene sottotitoli:
  badge e titolo restano centrati senza vuoti anomali.
- Restano aperti: completamento `Relevant`, validazione statica APK, runtime
  fisico/percettivo Pixel 9 e accettazione finale del proprietario sulla
  versione definitiva dell'asset.
