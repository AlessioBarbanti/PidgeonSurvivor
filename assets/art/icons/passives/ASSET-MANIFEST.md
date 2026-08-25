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
  fonte terza, marchio o persona reale è dichiarata nel manifest.
- Trasformazione: `tools/process-passive-icon.ps1` con soglia alpha `8`, padding
  `12` e riduzione nearest-neighbor a `128×128`.
- Verifica: sorgenti e runtime sono PNG RGBA; gli angoli runtime hanno alpha
  `0` e l'ispezione percettiva conferma una singola silhouette leggibile per
  emblema.

| Profilo | Master HD escluso | Runtime | SHA-256 master | SHA-256 runtime |
|---|---|---|---|---|
| Alea | `hd/alea_eagle_never_misses_source.png` (`1254×1254`) | `generated/alea_eagle_never_misses.png` (`128×128`) | `533CD2551F29B4B6FE4797A97DB324D723969992B550F42FD98166B2F9111349` | `3C64311DEC722D8AF0DF3F8D85A33F43747546E01B2383FD894BBD1625F1CCD2` |
| Aleo | `hd/aleo_solid_structure_source.png` (`1254×1254`) | `generated/aleo_solid_structure.png` (`128×128`) | `B1D03A23890A07040FF5C89DC8286405E761C12619CF0C9E5D070486CF73D090` | `16F69F7A8CCD107AD1E5C758E5DCA9ECA34BFE9428437D3B36BF3490AEEB1418` |
| Bea | `hd/bea_sixth_sense_source.png` (`1254×1254`) | `generated/bea_sixth_sense.png` (`128×128`) | `79FC97FB593043622D05797CABA8CED7751BC02658AE2D8E9BB5EED67D66A1C4` | `8F288AAA5A41EA862A2BCA9D78D735CCC7327804FFF2BAA432D016833B2F7D63` |
| Lollo | `hd/lollo_hyperactivity_source.png` (`1312×1199`) | `generated/lollo_hyperactivity.png` (`128×128`) | `766D6C8BD9B6D1A0BD466AE4C9E9EE15895AA489AEF2AC667D22F46B6E6F1B28` | `3045EC926EF1449A50CF7AA9F2F759D7F28B4C79426D5928039A469B1A0C1A12` |
| Marghe | `hd/marghe_contagious_smile_source.png` (`1312×1199`) | `generated/marghe_contagious_smile.png` (`128×128`) | `DD63AEEA2FC3227E22598E55720AAD444A653D63C6D4586F1F17009522AF7D35` | `9096F0357DC024DAA6EAE631C93D67138DD5B49D9BF907448D23E79AB087A997` |
| Migi | `hd/migi_turtle_shell_source.png` (`1292×1218`) | `generated/migi_turtle_shell.png` (`128×128`) | `953FFD30A11D1DCCB9A4A284C45B912CA6D22760A130ABD469842430B6356CF9` | `CC1F750FB6D12EF05B725A1B56E490CBADC06D23B2F6F68E7612E9731D63B030` |
| Zat | `hd/zat_delayed_healing_source.png` (`1166×1349`) | `generated/zat_delayed_healing.png` (`128×128`) | `AA44B43329B729A3B73EAD63B38816CA5C85B7FA4AEB3CB0EEF16B994F4C903D` | `E292289E75B4E2BBFEF226F1548EC9625F9D17F24207F50DBF968213ACDEE163` |
