# Manifest asset — Icone passive

## B18W — Flusso Aerodinamico Bovino

- Data generazione: 2026-08-25
- Generatore: OpenAI ImageGen built-in
- Licenza: asset originale del progetto, utilizzabile e modificabile nel gioco
  e nei suoi materiali promozionali.
- Stato: approvazione percettiva manuale finale ancora aperta.

### Prompt finale

```text
Use case: stylized-concept
Asset type: passive ability icon for a Godot pixel-fantasy character selection screen
Primary request: create one square pixel-art emblem for the passive ability "Flusso Aerodinamico Bovino"
Subject: a bold front-facing friendly bull head with short ivory horns, surrounded by two compact curling wind streams suggesting aerodynamic speed
Style/medium: polished 32-bit fantasy pixel art, crisp chunky pixels, readable when reduced to 72x72, matching a dark medieval-fantasy game UI with restrained cyan wind highlights and warm ivory/gold focal details
Composition/framing: centered single emblem, generous padding, strong silhouette, no enclosing card or outer frame
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for background removal
Constraints: one icon only; no text, no letters, no numbers, no logo, no watermark; no cast shadow, contact shadow, reflection, gradients or texture in the background; keep the subject fully separated from the background; do not use #00ff00 anywhere in the emblem
Avoid: photorealism, smooth vector style, emoji style, circular app-icon container, UI mockup, multiple icons
```

ImageGen ha restituito direttamente un PNG RGBA con angoli trasparenti; non è
stato necessario rimuovere il chroma key. Il derivato runtime è prodotto da
`tools/process-passive-icon.ps1`: bounds alpha con soglia `8`, padding quadrato
`12`, riduzione nearest-neighbor a `128×128`.

| Percorso | Dimensioni | Uso | SHA-256 |
|---|---:|---|---|
| `assets/art/icons/passives/hd/magno_aerodynamic_flow_source.png` | `1254×1254` RGBA | Master escluso da import ed export | `9B3533BB2AC05E3C51863227789E01BBF1425802CF111F530D722115FDEBE5E0` |
| `assets/art/icons/passives/generated/magno_aerodynamic_flow.png` | `128×128` RGBA | Icona runtime B18W | `2A316F73EDF6C9E6E452C9422A8320285EA95D8127E1D38A3A1CB83E7CB63183` |

## B18W — Set completo delle passive

- Data integrazione: 2026-08-25
- Origine: sette master PNG RGBA forniti dal proprietario del progetto per
  l'integrazione nel roster; i prompt riproducibili sono in
  [`GENERATION-PROMPTS.md`](./GENERATION-PROMPTS.md).
- Licenza: materiale conferito dal proprietario per l'uso nel progetto; nessuna
  fonte terza o marchio è dichiarato nel manifest.
- Trasformazione: `tools/process-passive-icon.ps1` con soglia alpha `8`, padding
  `12` e riduzione nearest-neighbor a `128×128`.
- Verifica: sorgenti e runtime sono PNG RGBA; gli angoli runtime hanno alpha
  `0` e l'ispezione percettiva conferma una singola silhouette leggibile per
  emblema.

| Profilo | Master HD escluso | Runtime | SHA-256 master | SHA-256 runtime |
|---|---|---|---|---|
| Alea | `hd/alea_two_fingers_and_go_source.png` (`1254×1254`) | `generated/alea_two_fingers_and_go.png` (`128×128`) | `8E844C28A267B6CDE5B7DE06EE2AC3D7E3CCDC31033CA7348CA224E6BDB37DBE` | `20D3FB3A56665529D8DE030EA0E74AA11333576A1CB1E1419D552D1DF5985614` |
| Aleo | `hd/aleo_internal_thermostat_source.png` (`1254×1254`) | `generated/aleo_internal_thermostat.png` (`128×128`) | `DE7C74482368403EEDAFB78B37DDE60184AA856C8244A1CC1A54797BF7FDE009` | `4682CAE23E55D5D4CBDBF884A84C3C3E49CC1B35252C8AEC0B8B77246A9FDE74` |
| Bea | `hd/bea_sixth_sense_source.png` (`1254×1254`) | `generated/bea_sixth_sense.png` (`128×128`) | `79FC97FB593043622D05797CABA8CED7751BC02658AE2D8E9BB5EED67D66A1C4` | `8F288AAA5A41EA862A2BCA9D78D735CCC7327804FFF2BAA432D016833B2F7D63` |
| Lollo | `hd/lollo_hyperactivity_source.png` (`1312×1199`) | `generated/lollo_hyperactivity.png` (`128×128`) | `766D6C8BD9B6D1A0BD466AE4C9E9EE15895AA489AEF2AC667D22F46B6E6F1B28` | `3045EC926EF1449A50CF7AA9F2F759D7F28B4C79426D5928039A469B1A0C1A12` |
| Marghe | `hd/marghe_contagious_smile_source.png` (`1312×1199`) | `generated/marghe_contagious_smile.png` (`128×128`) | `DD63AEEA2FC3227E22598E55720AAD444A653D63C6D4586F1F17009522AF7D35` | `9096F0357DC024DAA6EAE631C93D67138DD5B49D9BF907448D23E79AB087A997` |
| Migi | `hd/migi_turtle_shell_source.png` (`1292×1218`) | `generated/migi_turtle_shell.png` (`128×128`) | `953FFD30A11D1DCCB9A4A284C45B912CA6D22760A130ABD469842430B6356CF9` | `CC1F750FB6D12EF05B725A1B56E490CBADC06D23B2F6F68E7612E9731D63B030` |
| Zat | `hd/zat_delayed_healing_source.png` (`1166×1349`) | `generated/zat_delayed_healing.png` (`128×128`) | `AA44B43329B729A3B73EAD63B38816CA5C85B7FA4AEB3CB0EEF16B994F4C903D` | `E292289E75B4E2BBFEF226F1548EC9625F9D17F24207F50DBF968213ACDEE163` |

## Candidato — normalizzazione Aleo (approvato e promosso)

- Data produzione: 2026-09-08.
- Origine e generatore: OpenAI ImageGen built-in; generazione iniziale guidata
  da `generated/magno_aerodynamic_flow.png` come sola reference di stile e
  composizione, poi edit del soggetto secondo la direzione approvata in
  PS-131.
- Autore: progetto IL GIOCO con assistenza OpenAI ImageGen.
- Licenza: Licenza del progetto.
- Output selezionato: `exec-6346a973-ba75-4d7a-9f5b-1fdd64c6414f.png`.
- Estrazione alpha: rimozione deterministica del chroma verde dal master
  selezionato; un pixel è reso trasparente quando `G > 90`, `G > R + 30` e
  `G > B + 30`. Verifica successiva: nessun pixel visibile resta
  verde-dominante e i quattro angoli hanno alpha `0`.
- Derivazione: `tools/process-passive-icon.ps1 -Size 128
  -VisibleAlphaThreshold 8 -Padding 12`.
- Approvazione: il proprietario ha approvato esplicitamente il candidato con
  «Promosso!» l'8 settembre 2026.
- Promozione: gli stessi byte sono stati copiati nei percorsi canonici
  `hd/aleo_internal_thermostat_source.png` e
  `generated/aleo_internal_thermostat.png`; `data/friends/aleo.tres` continua a
  referenziare il derivato allo stesso percorso, senza modifiche al wiring.
- I file sotto `_review/aleo_normalize/` restano come evidenza non importata e
  non esportata della variante approvata.

### Prompt finale

```text
Use case: precise-object-edit
Asset type: high-resolution square master for Aleo's passive ability icon in
Pidgeon Survivor
Primary request: turn one ember coal into a cohesive object with an
approximately 50/50 material split; keep one half as living red-orange-gold
ember and freeze the other half under an attached pale-cyan and ice-white
frost crust.
Style/medium: polished 32-bit fantasy arcade pixel art, crisp chunky clusters,
stepped edges, limited palette and dark-plum outline, readable at 72x72.
Composition/framing: one centered irregular coal silhouette with generous
padding; the warm and frozen regions each occupy roughly half the same mass.
Scene/backdrop: flat pure #00FF00 chroma key for deterministic removal.
Constraints: one continuous object; no ring, bezel, card, inner background,
thermometer, gauge, snowflake symbol, detached spiral, separate ice crystals,
explosion, radial crystal crown, text, logo, watermark, shadow or second icon.
```

| Percorso candidato | Dimensioni | Byte | SHA-256 |
|---|---:|---:|---|
| `_review/aleo_normalize/aleo_internal_thermostat_v2_source.png` | `1254×1254` RGBA | `1566731` | `DE7C74482368403EEDAFB78B37DDE60184AA856C8244A1CC1A54797BF7FDE009` |
| `_review/aleo_normalize/aleo_internal_thermostat_v2.png` | `128×128` RGBA | `30740` | `4682CAE23E55D5D4CBDBF884A84C3C3E49CC1B35252C8AEC0B8B77246A9FDE74` |

## Candidato — icona passiva Alea (approvato e promosso)

- Data produzione: 2026-09-10.
- Origine e generatore: asset originale del progetto generato con OpenAI
  ImageGen built-in; nessuna immagine di riferimento è stata allegata alla
  generazione.
- Autore: progetto IL GIOCO con assistenza OpenAI ImageGen.
- Licenza: Licenza del progetto.
- Output selezionato:
  `exec-e977a705-a914-4a4d-ac6b-1aee06c2020c.png`.
- Trasparenza: ImageGen ha restituito direttamente un PNG RGBA con sfondo
  trasparente; i quattro angoli del master e del derivato hanno alpha `0`.
- Derivazione: `tools/process-passive-icon.ps1 -Size 128
  -VisibleAlphaThreshold 8 -Padding 12`.
- Art review: calice, sbordo e stella restano distinti nel derivato `128×128`
  e nel controllo isolato a `72×72`; la diagonale e lo sbordo distinguono il
  candidato dal calice HUD verticale di Alea.
- Approvazione: il proprietario ha approvato esplicitamente il candidato
  («ho generato gli assets per alea e ho approvato il design») il 10
  settembre 2026.
- Promozione (PS-150): gli stessi byte sono stati copiati nei percorsi
  canonici `hd/alea_two_fingers_and_go_source.png` e
  `generated/alea_two_fingers_and_go.png`, sostituendo i file dell'aquila
  (`alea_eagle_never_misses_source.png`/`.png`, rimossi); `data/friends/alea.tres`
  ripunta `passive_icon` al nuovo derivato.
- I file sotto `_review/alea_goblet/` restano come evidenza non importata e
  non esportata della variante approvata.

### Prompt finale

```text
Use case: stylized-concept
Asset type: high-resolution square master for Alea's passive ability icon in a Godot pixel-fantasy character selection screen
Primary request: create one compact pixel-art emblem that immediately communicates "tipsy and seeing stars"
Subject: one elegant wine goblet strongly tilted diagonally, filled with burgundy red wine visibly sloshing and spilling over the rim; exactly one small five-point golden star floats above the goblet and follows a short open curved motion trail
Style/medium: polished 32-bit fantasy arcade pixel art, crisp chunky pixel clusters, stepped edges, limited palette, dark-plum outline and banded shading; readable when reduced to 72x72; visually compatible with ornate dark medieval-fantasy passive icons
Composition/framing: centered compact emblem with generous transparent padding; strong diagonal goblet silhouette; spilled wine and the single star remain safely inside the square; free silhouette without any enclosing frame
Scene/backdrop: genuinely transparent background
Color palette: pale ice-blue glass highlights, deep burgundy and crimson wine, restrained warm gold on rim/base/star, dark plum outline
Constraints: one goblet, one continuous visible wine spill and exactly one star only; the spill must clearly cross over the rim; the short trail belongs to the star and stays open; no text, letters, numbers, logo, watermark, cast shadow, contact shadow, background reflection, opaque inner background, ring, bezel or card; preserve clean alpha edges
Avoid: photorealism, smooth vector style, emoji style, circular app-icon container, UI mockup, bottle, static upright frontal goblet, spiral around the goblet, closed ring, constellation, multiple stars, bubbles, face, hands, real-world wine branding, green background
```

| Percorso candidato | Dimensioni | Byte | SHA-256 |
|---|---:|---:|---|
| `_review/alea_goblet/alea_two_fingers_and_go_source.png` | `1254×1254` RGBA | `663052` | `8E844C28A267B6CDE5B7DE06EE2AC3D7E3CCDC31033CA7348CA224E6BDB37DBE` |
| `_review/alea_goblet/alea_two_fingers_and_go.png` | `128×128` RGBA | `18556` | `20D3FB3A56665529D8DE030EA0E74AA11333576A1CB1E1419D552D1DF5985614` |
