# Manifest sprite Player B18U

Le otto strisce Player sono asset raster originali prodotti il 25 agosto 2026
con OpenAI ImageGen built-in per il progetto IL GIOCO. Nessuna fotografia,
persona reale, marca, logo o personaggio di terzi e stato usato come soggetto.
Origine: progetto IL GIOCO; autore: progetto IL GIOCO con assistenza OpenAI
ImageGen; licenza: Licenza del progetto.

Il fondale approvato B18O
`assets/art/ui/welcome/welcome_ability_cast_background.png` e la conversazione
del 24 agosto 2026 sono stati usati come riferimento visivo per identita,
capelli, corporature, costumi e palette. Il fondale non e incorporato nei file
Player e nessuna UI o scena della welcome entra nelle texture runtime.

## Prompt condiviso

```text
Use case: stylized-concept
Asset type: three-frame 2D Godot character sprite strip
Primary request: create one original fictional character in exactly three registered right-facing poses in one horizontal row: locomotion pose A, neutral idle, locomotion pose B
Scene/backdrop: perfectly flat uniform chroma-key background everywhere
Style/medium: polished caricatural arcade pixel art matching the approved welcome cast; crisp dark outline, limited palette, chunky readable pixel clusters
Composition/framing: exactly three equal-width cells, full body visible, identical scale, baseline, center and proportions, generous padding, no dividers
Constraints: fictional human archetype only; faces right; no real person, logo, trademark, text, watermark, shadows, gradient, scenery, floor or gameplay VFX; crisp edges suitable for deterministic downscale to 32x32 per frame
```

ImageGen ha usato la striscia Magno corretta come riferimento di stile,
registrazione e chroma per gli altri sette output. Per le correzioni di Magno,
Zat, Alea, Aleo e Marghe sono stati forniti insieme la rispettiva striscia come
edit target e il fondale B18O come reference approvata, con il vincolo di
preservare tre pose, baseline, scala, pixel-art e chroma.

## Prompt specifici e correzioni dalla welcome

| ID | Soggetto e locomozione richiesti | Correzione finale rispetto al primo output |
|---|---|---|
| `magno` | Uomo energumeno tellurico, molto largo e muscoloso, outfit terra, piccoli richiami bovini, passo pesante | Rimossa ogni anatomia animale del primo output: Magno resta umano come nella welcome, con soli motivi a corna/emblema bovino |
| `bea` | Pattinatrice agile senza casco, capelli scuri lunghi e ricci, giacca viola, protezioni e roller, falcata da skating | Nessuna correzione: confronto diretto con Bea B18O positivo; scia e Powerslide restano VFX separati |
| `zat` | Infermiera elettrica in bianco-ciano, simbolo medico generico a cuore, caschetto, passo rapido | Rimosso completamente il copricapo generato; caschetto teal e divisa sono allineati alla welcome, senza Croce Rossa |
| `alea` | Ballerina classica, tutu leggibile, passi eleganti | Capelli portati al biondo caldo e costume a bianco-avorio con oro come nella welcome; nastro e aquila restano VFX separati |
| `aleo` | Muratore con casco, cazzuola, piccolo secchio e stivali, passo robusto | Reso giovane e senza barba; gilet arancio sostituito da abito da lavoro verde oliva e giallo coerente con la welcome |
| `lollo` | Cosplayer iperattivo con capelli scuri, tuta blu, dettagli gialli, goggles e accessori wasteland originali | Nessuna correzione: confronto diretto con Lollo B18O positivo; nessun numero, marchio o costume riconoscibile |
| `migi` | Donna calma con capelli neri e occhiali, outfit teal, scudo a guscio compatto, passo deliberato | Nessuna correzione: confronto diretto con Migi B18O positivo; cupola e onde rallentanti restano VFX separati |
| `marghe` | Ballerina reggaeton con capelli neri molto lunghi, magenta-oro e passo ritmico | Corporatura resa piu morbida e piena e palette spostata al viola, magenta e oro come nella welcome; clone d'ombra resta VFX separato |

## Trasformazioni deterministiche

Gli output selezionati sono PNG `1536x1024` su chroma. Il helper installato
`remove_chroma_key.py` rimuove `#00FF00` con tolleranza `80` e despill; Migi usa
`#FF00FF` per non confondere il guscio teal. Per questa pixel-art piatta il key
hard e intenzionale: i PNG intermedi non contengono alpha parziale.

`tools/process-cast-sprite.ps1` divide ogni sorgente in tre celle uguali,
seleziona deterministicamente la componente connessa opaca piu grande di ogni
cella usando soglia alpha `192`, la ricampiona nearest-neighbor dentro un'area
massima `28x28`, la centra orizzontalmente e la allinea a `2 px` dal fondo di un
canvas trasparente `32x32`. I tre frame diventano una striscia RGBA `96x32`
ordinata `passo A | idle | passo B`. Nessun ritocco di colore, compositing o VFX
e applicato dopo ImageGen.

Le sorgenti selezionate dopo la rimozione del chroma sono conservate come PNG
RGBA HD `1536x1024` in `hd/`, su richiesta del proprietario, per riusi artistici
futuri. La presenza di `hd/.gdignore` e gli exclude filter dei preset impediscono
che siano importate o incluse in EXE/APK. Soltanto le strisce `96x32` sono
consumate dal runtime e Godot le mostra con filtro nearest.

## File e integrita

| File runtime | Byte sorgente | SHA-256 sorgente ImageGen | Byte runtime | SHA-256 runtime |
|---|---:|---|---:|---|
| `magno.png` | `1640981` | `2DB2A2D66519F0B1A1562B7E3A369C870A89619F5A4CF17CC16FE71043F6CB98` | `3416` | `1964FE0E1329BCFF44355EC1D940E84BFE434A3F4669F0188321B96B68F4D4FE` |
| `bea.png` | `1556624` | `33A47A5353E7F187ED41F1235C9FCEB75B635EB44BF7CB1637EC01F476485B3B` | `2987` | `AC1ADF45DE9B303E9778BDFF1B916B3C210D031864709C182BDB30B1A1F1FDC2` |
| `zat.png` | `1556043` | `61FE527A0BB5EB87FD53B09AC2C6E882FE7BAA8D6F57BA3813D9BA606218014A` | `2458` | `7CEC69B264AE522501DADDCDF471C0EF5DA037B2E3AB46FA1DF4A07592267EC6` |
| `alea.png` | `1602487` | `B1CD6731D6EE22FCA9B46B4CF8E44BDE890B2C6696F114D5E73972A12632B4E1` | `1968` | `B5DF2382A8231C826C6B447D91E22CA2E1ECCE9C0B0AD9E19EE8971D283D08E2` |
| `aleo.png` | `1729632` | `33E17636A5B07267CFE7D21F487A2927EB7A95464470620271A284C83909A574` | `3036` | `0430029F910D1988E194F9216C03F1A54B59D8C859BC08AA9867DCDB70E34870` |
| `lollo.png` | `1511189` | `4164CB0BE7A59799C30076CF6A113592762A68829B8AF31EEB0CF884F63193FA` | `3013` | `11990611A90F250497EF9F910C598A8DD36465B3407F70B98171C156534FF7B7` |
| `migi.png` | `1484023` | `D73463B27D8E09D8D8879A5A88C862ED9ADA408C1C89EB759FBD5E4A2126E5EF` | `2851` | `929331699DDF23E70B30B99E1557AC53E15CBB914D9BF18E1F9C3EFBB1FD32F3` |
| `marghe.png` | `1591662` | `33561B0CA59C2546FB10C46A0BBD2EA2C01D8400E4869AAB7926FFE98D916A0C` | `3159` | `BC6ED19334215AD9E7F549A9DA0D98AF94674E2674753F0A926D3EB7E43E0BD7` |

## Sorgenti HD trasparenti conservate

| File HD | Dimensioni | SHA-256 |
|---|---:|---|
| `hd/magno_source.png` | `1536x1024` | `07619CD1DA79DC81685814C0F159F0A6FD7B234BA4C129C84F29FF08B41E82F0` |
| `hd/bea_source.png` | `1536x1024` | `9ACBBFB7A3B81E1F4A47FFFBEF47D2384A67DCD88C2815D22536AF66199243B8` |
| `hd/zat_source.png` | `1536x1024` | `3DBD1945CE4765BA2B8605121675F1BA57425A2C0FE797FCB9D801594C6DE2D6` |
| `hd/alea_source.png` | `1536x1024` | `636FE1DC8B03676E467FA510659B638F6719526067435FF404F37CAD862071D0` |
| `hd/aleo_source.png` | `1536x1024` | `5FF2A5B140F2E5334AE34110D366C1AD164D0C1366D96D7B9AE05108986C76F4` |
| `hd/lollo_source.png` | `1536x1024` | `597CF0546BBBD7176F61A931595DD0490727C77D5452E0044D8838E82072AEBE` |
| `hd/migi_source.png` | `1536x1024` | `0922837FF4633230EFA8A79915872CF4D00EE0EC75B6F5CA65BAF096DFA1CAE8` |
| `hd/marghe_source.png` | `1536x1024` | `E6E107A6BFB7ED6898A8EE84160FACB8900A615A673A5A7A10E64009A1FF56F8` |
