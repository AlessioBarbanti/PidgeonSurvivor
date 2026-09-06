---
id: PS-102
titolo: Genera una cornice dedicata per la Boss Intro
tipo: art
area: arte
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-09-05
aggiornato: 2026-09-06
---

# PS-102 — Genera una cornice dedicata per la Boss Intro

## Contesto

`BossUI.show_intro()` ([scenes/ui/boss_ui.tscn](../../../scenes/ui/boss_ui.tscn),
righe 89-93) riusa `pause_panel_frame.png` — lo stesso `StyleBoxTexture` del
pannello di pausa — come cornice del modale che rivela il Boss in arrivo:
`ext_resource type="Texture2D" path="res://assets/art/ui/pause/pause_panel_frame.png" id="3_modal_frame"`.
Dentro, un `PortraitFrame` di soli 112×112 (riga 102) ospita il ritratto,
sopra titolo, citazione e il bottone "AFFRONTA".

Il proprietario giudica il risultato non coerente con il resto
dell'identità visiva del gioco e poco curato: la rivelazione di un amico
diventato malvagio si presenta con la stessa cornice generica di un menu di
sistema (la pausa), senza nulla che la distingua come il momento diverso che
narrativamente è. Non è un difetto di dati o layout — PS-071 ha già corretto
la safe area di questo stesso pannello — è che la cornice stessa non è mai
stata disegnata per questo scopo.

Questa card si ferma alla produzione degli asset, come impone
[PS-090](../5_completed/PS-090-separa-generazione-integrazione-card-art.md).
Il cablaggio in `boss_ui.tscn` è [PS-103](../2_to_do/PS-103-integra-cornice-boss-intro.md).

## Comportamento atteso

Esiste, derivata e a manifest, una cornice propria per la Boss Intro —
distinta da `pause_panel_frame.png` — pensata per un momento di rivelazione
drammatica/giocosa (un amico corrotto entra in scena), non per un menu di
sistema. Include un trattamento del ritratto più protagonista dell'attuale
riquadro 112×112.

## Criteri di accettazione

- [x] Esiste un nuovo master per la cornice del pannello Boss Intro,
      distinguibile a colpo d'occhio da `pause_panel_frame.png` (non una
      semplice ricolorazione: cambia anche linguaggio decorativo/silhouette),
      coerente con la palette e lo stile pixel-art già stabiliti nel resto
      della UI (vedi `docs/visual-audio-identity.md`).
- [x] La cornice funziona sia per il Piccione Malvagio (nessun trattamento
      cromatico personale, riga 122-125 di `docs/enemies-bosses.md`) sia per
      un `Evil <Nome>` (tinta name/frame con l'`accent_color` della
      Signature, riga 126-129) senza contraddire quel contratto.
- [x] Include un trattamento dedicato per il ritratto (cornice/vignetta
      propria) più protagonista dell'attuale riquadro semplice 112×112, senza
      richiedere ritratti a risoluzione diversa da quelli già generati in
      PS-052.
- [x] Il file rispetta i vincoli di canvas/trasparenza richiesti dalla
      pipeline `tools/process-*.ps1` usata per derivarlo.
- [x] Il derivato esiste in `assets/art/ui/boss/generated/` (o percorso
      equivalente coerente con gli altri asset UI Boss già presenti) con una
      riga nell'`ASSET-MANIFEST.md` pertinente: origine, autore/licenza,
      trasformazioni, hash SHA-256.
- [x] Nessun file derivato è ancora referenziato da `boss_ui.tscn`: il
      cablaggio resta a [PS-103](../2_to_do/PS-103-integra-cornice-boss-intro.md).

## Ambito

- Nuovi master e derivati sotto `assets/art/ui/boss/`.
- `ASSET-MANIFEST.md` della cartella pertinente.

Non toccare:

- `scenes/ui/boss_ui.tscn` e `scripts/ui/boss_ui.gd` (wiring: PS-103);
- `pause_panel_frame.png` e il pannello di pausa, che restano invariati;
- il contratto identità individuale Piccione Malvagio vs `Evil <Nome>`
  descritto in `docs/enemies-bosses.md` (righe 117-138) — la nuova cornice lo
  serve, non lo cambia;
- ritratti ed icone Signature (PS-052, già COMPLETATA).

## Verifica

- Nessuno smoke GUT: card `tipo: art`, verificata da art review e manifest
  come da convenzione PS-090.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: non pertinente a questa card (nessun wiring)
- [ ] Controllo percettivo richiesto: sì — la cornice deve leggersi come un
      momento distinto dal pannello di pausa, non come un restyle cosmetico
      minore, e deve reggere sia la variante neutra (Piccione Malvagio) sia
      quella tinta (`Evil <Nome>`)

## Decisioni

- **2026-09-05 — La cornice è nuova arte, non un restyle del pannello di
  pausa.** Il proprietario ha giudicato l'attuale riuso di
  `pause_panel_frame.png` la causa diretta della mancanza di coerenza/qualità
  percepita: la correzione richiede un asset nuovo, non un aggiustamento di
  parametri sullo `StyleBoxTexture` esistente.
- **2026-09-06 — Placca larga 3:2 con medaglione ritratto integrato.** Il
  derivato conserverà un centro scuro pulito per title/copy/CTA, mentre una
  vignetta circolare in alto interrompe la silhouette rettangolare del menu.
  La decorazione usa ferro brunito, brace e piume scure neutre: l'accento
  resta modulabile dalla UI per gli `Evil <Nome>` senza personalizzare il
  Piccione Malvagio.
- **Aperto per il resolver — dimensione e forma esatta del nuovo riquadro
  ritratto.** Il proprietario ha chiesto un ritratto "più protagonista" senza
  fissare una dimensione target; va proposta in bozza rispettando i vincoli
  di risoluzione dei ritratti già generati in PS-052.

## Documenti sincronizzati

- [x] `docs/visual-audio-identity.md`: nuova riga per la cornice Boss Intro,
      stesso trattamento riservato agli altri asset UI Boss già in tabella.

## Note

Card gemella di [PS-103](../2_to_do/PS-103-integra-cornice-boss-intro.md), che la
cablerà in scena. Nessuna relazione con [PS-101](./PS-101-racconta-fame-dietro-agli-evil.md)
(narrativa/copy): le due linee di lavoro sono indipendenti.

Card `tipo: art` con generazione di nuovi asset: per contratto di board
([docs/cards/README.md](../README.md)) va delegata all'agente
`game-art-designer`, non implementata da `card-risolvi`. A generazione
completata, il proprietario può invocare manualmente `direttore-artistico`
per confrontare la nuova cornice con i "fratelli visivi" già esistenti negli
altri asset UI Boss, prima di considerarla pronta per l'art review.

### Evidenze 2026-09-06

- **Direzione e review isolata:** master `1536x1024` e derivato
  `764x464` ispezionati visivamente. Il medaglione è il punto focale, resta
  compatibile con i ritratti `256x256` esistenti e il corpo inferiore conserva
  spazio calmo per titolo, citazione e CTA. Piume/braci/ferro rendono la
  silhouette inequivocabilmente distinta da `pause_panel_frame.png`; non sono
  emersi testo, soggetti estranei, tinte di personaggio o bordi opachi fuori
  dall'asset.
- **Produzione:** derivazione riproducibile con
  `process-character-select-cta.ps1 -ScalePercent 50 -VisibleAlphaThreshold 8 -Padding 4`.
  Hash e filtri `hd/` dei preset Windows/APK/AAB sono registrati nel manifest.
- **Integrazione:** fuori ambito. `boss_ui.tscn` continua a referenziare
  `pause_panel_frame.png`; PS-103 è stata sbloccata a `PRONTO` per il wiring.
- **Gate aperti:** review percettiva del proprietario e i gate Windows/APK
  restano da svolgere dopo PS-103, quando l'asset sarà nel contesto runtime.
