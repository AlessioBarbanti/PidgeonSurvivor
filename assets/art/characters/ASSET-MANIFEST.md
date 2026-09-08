# Manifest asset — Cast (Player e Evil)

Questo manifest copre tutti gli asset degli otto personaggi giocabili, sotto
`assets/art/characters/<id>/`, per entrambe le varianti Player ed Evil:

```
assets/art/characters/<id>/
  hd/
    poses.png              # master HD Player, 3 pose (escluso da import/export)
    evil_portrait.png     # master HD Evil, ritratto busto (escluso da import/export)
  generated/
    sprite.png             # striscia runtime 96x32 (idle + 2 passi)
    carousel.png            # ritratto carosello selezione 256x256
    evil_portrait.png       # ritratto Evil runtime 256x256
```

I master `hd/` restano esclusi dall'import Godot (`.gdignore` per ciascun
`<id>/hd/`) e dagli export (`assets/art/characters/*/hd/**` nei preset). Le
reference fotografiche autorizzate vivono invece in
`docs/characters/references/<id>/` — materiale di documentazione e
provenienza, non un asset da derivare — anch'esse protette da `.gdignore` ed
escluse dai preset (`docs/characters/references/**`). Il documento di
direzione visuale di ciascun personaggio è in `docs/characters/<id>.md`. Solo
`generated/` è consumato dal runtime.

## Parte 1 — Strisce Player (B18U)

Le otto strisce Player sono asset raster originali prodotti il 25 agosto 2026
con OpenAI ImageGen built-in per il progetto IL GIOCO. La baseline iniziale non
usava fotografie o persone reali; l'identity pass del 28 agosto 2026 la supera
per tutti gli otto profili usando riferimenti fotografici forniti e autorizzati
esplicitamente dal proprietario. I risultati restano caricature pixel-art e non
contengono marche, loghi o personaggi di terzi. Il registro dei prompt
disponibili (inclusi i due originali recuperati per Aleo e Magno) e delle
reference fotografiche archiviate è in
`docs/archive/generation-prompts-and-references.md`.
Origine: progetto IL GIOCO; autore: progetto IL GIOCO con assistenza OpenAI
ImageGen; licenza: Licenza del progetto.

Il fondale approvato B18O
`assets/art/ui/welcome/welcome_ability_cast_background.png` e la conversazione
del 24 agosto 2026 sono stati usati come riferimento visivo per identita,
capelli, corporature, costumi e palette. Il fondale non e incorporato nei file
Player e nessuna UI o scena della welcome entra nelle texture runtime.

### Identity pass del 28 agosto 2026

### Reference fotografiche archiviate il 2 settembre 2026, spostate sotto `docs/` il 2 settembre 2026 (PS-084)

Le fotografie originali autorizzate dal proprietario sono conservate in
`docs/characters/references/<id>/source-XX.png` (spostate da
`assets/art/characters/references/<id>/` senza alterare i byte), tutte fuori da
import ed export. Origine: asset del progetto forniti dal proprietario; autore
e licenza: non applicabili a una reference privata del proprietario.
Trasformazione: nessuna (solo normalizzazione deterministica dei nomi in
minuscolo al momento dell'archiviazione). Ruolo: `subject reference` per
future generazioni in caricatura pixel-art, mai runtime.

La tabella completa con dimensioni e SHA-256 è nel registro storico
`docs/archive/generation-prompts-and-references.md`; non duplicarla qui per
evitare due fonti di integrità divergenti. La sintesi della direzione visuale
per personaggio, con i percorsi correnti dei master, è in
`docs/characters/<id>.md`.

Le otto strisce sono state rigenerate dal proprietario del progetto in un
passaggio di identita successivo alla baseline B18U. I master conferiti erano
gia PNG RGBA trasparenti `1536x1024`, accompagnati da una copia intermedia su
chroma per ogni candidato. Per ogni personaggio e stata promossa la versione
piu recente (percorsi aggiornati alla riorganizzazione per cartella-personaggio
del 2 settembre 2026):

| Personaggio | Master corrente |
|---|---|
| `magno` | `magno/hd/poses.png` |
| `bea` | `bea/hd/poses.png` |
| `zat` | `zat/hd/poses.png` |
| `alea` | `alea/hd/poses.png` |
| `aleo` | `aleo/hd/poses.png` |
| `lollo` | `lollo/hd/poses.png` |
| `migi` | `migi/hd/poses.png` |
| `marghe` | `marghe/hd/poses.png` |

Le copie su chroma e le versioni non promosse erano materiale di staging non
versionato e sono state rimosse dopo la promozione: per questo la tabella di
integrita registra ora byte e SHA-256 del master HD trasparente al posto
dell'output ImageGen su chroma della baseline B18U. Le trasformazioni
deterministiche verso `96x32` e verso il carosello `256x256` sono invariate e
sono state rieseguite con gli stessi script e gli stessi parametri.

Per `aleo` il passaggio accompagna inoltre il rework gameplay da muratore a
termotecnico. Come per gli altri sette profili, la direzione visuale usa un
riferimento autorizzato e resta una caricatura pixel-art. I prompt specifici di
Aleo sono nel registro storico `docs/archive/generation-prompts-and-references.md`.

### Prompt condiviso della baseline del 25 agosto

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

### Prompt specifici e correzioni dalla welcome

| ID | Soggetto e locomozione richiesti | Correzione finale rispetto al primo output |
|---|---|---|
| `magno` | Uomo energumeno tellurico, molto largo e muscoloso, outfit terra, piccoli richiami bovini, passo pesante | Rimossa ogni anatomia animale del primo output: Magno resta umano come nella welcome, con soli motivi a corna/emblema bovino. Il successivo identity pass ha un prompt integrale recuperato nel [registro storico](../../../docs/archive/generation-prompts-and-references.md#magno--originale-recuperato) |
| `bea` | Pattinatrice agile senza casco, capelli scuri lunghi e ricci, giacca viola, protezioni e roller, falcata da skating | Nessuna correzione: confronto diretto con Bea B18O positivo; scia e Powerslide restano VFX separati |
| `zat` | Infermiera elettrica in bianco-ciano, simbolo medico generico a cuore, caschetto, passo rapido | Rimosso completamente il copricapo generato; caschetto teal e divisa sono allineati alla welcome, senza Croce Rossa |
| `alea` | Ballerina classica, tutu leggibile, passi eleganti | Capelli portati al biondo caldo e costume a bianco-avorio con oro come nella welcome; nastro e aquila restano VFX separati |
| `aleo` | Muratore con casco, cazzuola, piccolo secchio e stivali, passo robusto | Reso giovane e senza barba; gilet arancio sostituito da abito da lavoro verde oliva e giallo coerente con la welcome. **Da rigenerare**: il rework del 28 agosto 2026 trasforma Aleo in un termotecnico; prompt aggiornato nel [registro storico](../../../docs/archive/generation-prompts-and-references.md#aleo--originale-recuperato) |
| `lollo` | Cosplayer iperattivo con capelli scuri, tuta blu, dettagli gialli, goggles e accessori wasteland originali | Nessuna correzione: confronto diretto con Lollo B18O positivo; nessun numero, marchio o costume riconoscibile |
| `migi` | Donna calma con capelli neri e occhiali, outfit teal, scudo a guscio compatto, passo deliberato | Nessuna correzione: confronto diretto con Migi B18O positivo; cupola e onde rallentanti restano VFX separati |
| `marghe` | Ballerina reggaeton con capelli neri molto lunghi, magenta-oro e passo ritmico | Corporatura resa piu morbida e piena e palette spostata al viola, magenta e oro come nella welcome; clone d'ombra resta VFX separato |

### Trasformazioni deterministiche

Gli output selezionati sono PNG `1536x1024` su chroma. Il helper installato
`remove_chroma_key.py` rimuove `#00FF00` con tolleranza `80` e despill; Migi usa
`#FF00FF` per non confondere il guscio teal. Per questa pixel-art piatta il key
hard e intenzionale: i PNG intermedi non contengono alpha parziale.

`tools/process-cast-sprite.ps1` divide ogni sorgente in tre celle uguali,
seleziona deterministicamente la componente connessa opaca piu grande di ogni
cella usando soglia alpha `192`, la ricampiona nearest-neighbor dentro un'area
massima e la centra orizzontalmente allineandola al fondo di un canvas
trasparente. Nessun ritocco di colore, compositing o VFX e applicato dopo
ImageGen.

**Comando corrente (PS-116, dal 7 settembre 2026):**
`-FrameCount 3 -CanvasSize 64 -Padding 4` (area utile `56x56`, striscia
runtime `192x64`, ordine `passo A | idle | passo B`). Sostituisce il comando
originale `-CanvasSize 32 -Padding 2` (area utile `28x28`, striscia `96x32`):
stesso rapporto area utile/canvas (`87.5%`), quindi la stessa inquadratura e
gli stessi margini relativi, solo con il doppio di pixel sorgente per lato.
Causa: gap di definizione percepito fra il personaggio giocabile (nativo
32x32, poi ingrandito ~2x a schermo) e i piccioni nemici (nativi 48x48) — vedi
la card PS-116 per l'analisi completa. Nessun master toccato: stesso
`hd/poses.png` di ciascun personaggio, gia' approvato.

Le sorgenti selezionate dopo la rimozione del chroma sono conservate come PNG
RGBA HD `1536x1024` in `<id>/hd/`, su richiesta del proprietario, per riusi
artistici futuri. La presenza di `<id>/hd/.gdignore` e gli exclude filter dei
preset impediscono che siano importate o incluse in EXE/APK. Soltanto le
strisce `96x32` sono consumate dal runtime e Godot le mostra con filtro
nearest.

### File e integrita

Byte/hash "runtime" aggiornati al 7 settembre 2026 (PS-116, derivato `192x64`);
il master HD e il suo hash sono invariati.

| File runtime | Byte master HD | SHA-256 master HD | Byte runtime | SHA-256 runtime |
|---|---:|---|---:|---|
| `magno/generated/sprite.png` | `1060810` | `2EA717859B91B420B97F8D9975D67A3C827BA94CC4355739A4DB4FE370F836A5` | `11399` | `6D38CF835DBA9ECDA91A46BF57BAA5F07D7EA3DB9D5B1E85705498DCF4634F92` |
| `bea/generated/sprite.png` | `953157` | `3C6B26826B9A6B5708174AE6EDB42F1F652A120DE0B17C3405DCAB8CB756059D` | `10550` | `0268364C47C4F21983DB54DA0A18BBA2D97C957A6712041B2DE9B42A0D871D52` |
| `zat/generated/sprite.png` | `810909` | `DD1EB3F249F37426E9573DE02C2E0292F32A932A0C2059F82325D1F92919780B` | `8584` | `98BB6BFEA0E0144923D7A233AD96BC91695ACBD55D9352F79E04251214C5E1F0` |
| `alea/generated/sprite.png` | `829661` | `61C760FA609852BA31F5C24CE43626EA41228AAC6DFC9371D78D83F65408FEA5` | `6260` | `5E4A2CFED4B2DB4E749EF87F1801AB7D835F9C736405E7EEA9B4D5EDA0493F26` |
| `aleo/generated/sprite.png` | `980832` | `53999B4B51D97A918B5AC8F68444417E07B8B17EA4837C239173C5DEF4C787DE` | `9905` | `DC7069EF10B070072337822386A14DE4CA52E7EB412464F08D70D5A32DCC438E` |
| `lollo/generated/sprite.png` | `862437` | `CA66A174E501BEAB30CA3076F3682CCE955E488EC6EB8BBFC3C7734FDC1CF424` | `9311` | `85CCFA620E98B9B4167C4F06B195228EDB0DCDE4EC91BC79E8834A04B8644872` |
| `migi/generated/sprite.png` | `810304` | `04EDEE8F99B5849384D268BD35CB4E498EA80BEA1FA961A67BD19B8D1DC75499` | `10130` | `DACE18ACE1A38858B80EF2D4475B2A4ECB4E1EFEEB59D75EE6AF56ECE17DC56E` |
| `marghe/generated/sprite.png` | `1110523` | `D20B2CBA8B5FEB9A70D62D5E5CBEDFAB96E0FC9BB4E1C954B9BDBEC782A1872C` | `11259` | `F6E8F39C8A815C5F292CDE57273E6BD030F1C8899B843DEC77E19D89368D59CA` |

### Sorgenti HD trasparenti conservate

| File HD | Dimensioni | SHA-256 |
|---|---:|---|
| `magno/hd/poses.png` | `1536x1024` | `2EA717859B91B420B97F8D9975D67A3C827BA94CC4355739A4DB4FE370F836A5` |
| `bea/hd/poses.png` | `1536x1024` | `3C6B26826B9A6B5708174AE6EDB42F1F652A120DE0B17C3405DCAB8CB756059D` |
| `zat/hd/poses.png` | `1536x1024` | `DD1EB3F249F37426E9573DE02C2E0292F32A932A0C2059F82325D1F92919780B` |
| `alea/hd/poses.png` | `1536x1024` | `61C760FA609852BA31F5C24CE43626EA41228AAC6DFC9371D78D83F65408FEA5` |
| `aleo/hd/poses.png` | `1536x1024` | `53999B4B51D97A918B5AC8F68444417E07B8B17EA4837C239173C5DEF4C787DE` |
| `lollo/hd/poses.png` | `1536x1024` | `CA66A174E501BEAB30CA3076F3682CCE955E488EC6EB8BBFC3C7734FDC1CF424` |
| `migi/hd/poses.png` | `1536x1024` | `04EDEE8F99B5849384D268BD35CB4E498EA80BEA1FA961A67BD19B8D1DC75499` |
| `marghe/hd/poses.png` | `1536x1024` | `D20B2CBA8B5FEB9A70D62D5E5CBEDFAB96E0FC9BB4E1C954B9BDBEC782A1872C` |

### Derivati frontend B18T

Il carosello B18T usa la posa idle centrale delle stesse otto sorgenti HD. Lo
script `tools/process-carousel-portrait.ps1` divide il master in tre celle,
isola deterministicamente la componente opaca connessa piu grande della cella
centrale e la ricampiona nearest-neighbor in un canvas trasparente `256x256`,
con `14 px` di padding e allineamento al fondo. Non applica generazione,
ritocco, recolor, compositing o VFX: autore, generatore, prompt, data e licenza
restano quelli del master B18U. I master in `<id>/hd/` continuano a essere
esclusi da import ed export; soltanto questi derivati UI vengono consumati dal
runtime.

| File carosello | Byte | SHA-256 |
|---|---:|---|
| `magno/generated/carousel.png` | `61363` | `C8930E629C57F598DB8B82E8710C7DE2D0CA52E8FB3749D75ADBED90F949FE26` |
| `bea/generated/carousel.png` | `46858` | `A3ECB4C23A252E033C32424B606367409F2FE350A9908A0E556A327930F8454A` |
| `zat/generated/carousel.png` | `40219` | `B7CE0D95801E6B3E92E6861D59C8ADA7B6BBAC2AEE917AB2F36788597B0BF2AB` |
| `alea/generated/carousel.png` | `29153` | `CE59D593AFA30667B75E5DD185595C45028109BA48E8FEDFFB267360FE434DF6` |
| `aleo/generated/carousel.png` | `49755` | `18951C313652C86D696B29B831A4CBD9FD136B3FA377FF3DA59EA8F11A044EC6` |
| `lollo/generated/carousel.png` | `48688` | `1C57686966A4C395616E9163C47DB6E7449F453CBC980B03D1D561EA9D8AA46E` |
| `migi/generated/carousel.png` | `48941` | `3249AE96796D4DE09A914D36F5E9F3EE2ACFBD08A0738F45A9A0A1BEA26310F4` |
| `marghe/generated/carousel.png` | `54744` | `922DFED4E24588698350040EFFF4460936EB84A59FE73EA94B73EE4A510007A9` |

## Parte 2 — Ritratti Evil (PS-052)

### Produzione art-only del 1 settembre 2026, integrazione del 2 settembre 2026

Gli otto ritratti definitivi sono stati prodotti in anticipo rispetto
all'integrazione prevista da PS-052. `data/friends/*.tres` referenzia ora
`<id>/generated/evil_portrait.png` al posto dei segnaposto
`fake_evil_portrait.png` introdotti da PS-051, rimossi dalle cartelle runtime.
`evil_portrait_placeholder` resta il fallback dichiarato; l'accettazione
percettiva del proprietario (silhouette, leggibilità alla dimensione reale
della Boss intro) resta aperta.

- Origine: OpenAI ImageGen built-in, a partire dalla direzione visuale del cast
  del progetto IL GIOCO.
- Autore: progetto IL GIOCO con assistenza OpenAI ImageGen.
- Licenza: Licenza del progetto.
- Riferimenti ispezionati: i ritratti `<id>/generated/carousel.png` e la
  direzione visuale in `docs/characters.md`.
- Input ImageGen effettivi: i ritratti carosello di Alea, Aleo, Bea e Lollo sono
  stati usati come edit target per identità, costume e linguaggio pixel-art. Per
  Magno, Marghe, Migi e Zat la generazione è stata guidata dal brief testuale;
  i fratelli visivi sono stati studiati ma non allegati come input.

### Prompt e grammatica condivisa

Prompt comune normalizzato: ritratto quadrato da Boss intro, busto centrale a
tre quarti, pixel-art arcade rifinita con outline prugna scuro, cluster leggibili
e margine sicuro; preservare acconciatura, corporatura, colori dell'abito e
accessori del personaggio; applicare una sola grammatica Evil composta da fumo
prugna controllato, occhio magenta-viola luminoso, poche crepe energetiche e rim
light personale; sfondo realmente trasparente; nessun testo, cornice, logo,
watermark, gore, personaggio aggiuntivo, scenario o trasformazione in demone o
volatile generico.

| ID | Specifica del prompt |
|---|---|
| `evil_alea` | Ballerina classica bionda, costume avorio-oro e ornamento preservati; posa composta e minacciosa, accento magenta. |
| `evil_aleo` | Termotecnico robusto con capelli castani, barba ramata, occhiali, tuta nera, manometri e tubi; accento ciano-rame. |
| `evil_bea` | Pattinatrice agile con lunghi ricci scuri, occhiali, fascia e giacca sportiva viola; sorriso predatorio e accento arancio caldo. |
| `evil_lollo` | Cosplayer iperattivo con capelli scuri, goggles ciano, sciarpa e tuta retrofuturista blu-gialla originale; accento magenta elettrico. |
| `evil_magno` | Uomo molto largo e muscoloso, capelli lunghi e barba, canotta nera con emblema bovino dorato; posa pesante e accento ambra tellurico. |
| `evil_marghe` | Donna morbida con capelli neri molto lunghi, occhiali, outfit reggaeton viola-magenta e oro; rotazione ritmica e accento ciano clone. |
| `evil_migi` | Donna calma con capelli neri raccolti, occhiali, tuta protettiva teal e guscio segmentato; minaccia controllata e accento menta. |
| `evil_zat` | Medica elettrica con caschetto castano, divisa bianco-ciano, guanti teal e simbolo generico a cuore; accento ciano con lampo giallo. |

Alea e Aleo hanno richiesto un passaggio correttivo `background-extraction`:
rimuovere soltanto il checkerboard chiaro incorporato, preservando soggetto,
pixel-art, colori, effetti e inquadratura, e produrre alfa reale senza ridisegno.

### Correzione Evil Magno (PS-135, 8 settembre 2026)

Il master Evil di Magno è stato corretto tramite OpenAI ImageGen built-in per
ripristinare gli accessori identitari già presenti nei master Player, senza
modificare il percorso consumato dal runtime.

- Origine: edit del master esistente `magno/hd/evil_portrait.png`.
- Autore: progetto IL GIOCO con assistenza OpenAI ImageGen.
- Licenza: Licenza del progetto.
- Input ImageGen effettivi del primo edit: il vecchio Evil come `edit target`;
  `magno/hd/portrait.png` e `magno/hd/poses.png` come reference di soggetto,
  costume e accessori; `alea/hd/evil_portrait.png` come reference di stile per
  la sola grammatica normal-to-Evil.
- Correzione selezionata: corona con due corna d'avorio e gemma turchese;
  spallaccio bovino con esattamente due corna d'avorio e gemma turchese in
  castone dorato; collana ad artiglio rimossa. Capelli lunghi, barba, canotta
  nera, emblema bovino, fumo prugna, occhio magenta, crepe e rim light ambra
  sono stati preservati.
- Traccia output selezionati: `exec-a924d2dd-e49e-4f1f-8a51-f3adae6e9982.png`
  (edit accessori) -> `exec-4d8894d3-ef07-4938-8874-836bbe0d2f2c.png`
  (`background-extraction`, rimozione del solo checkerboard incorporato).

Prompt finale normalizzato:

```text
Use case: precise-object-edit seguito da background-extraction.
Correggere soltanto gli accessori mancanti del master Evil di Magno: mantenere
identità, posa, corporatura, capelli lunghi, barba, canotta nera, emblema
bovino e grammatica Evil; ripristinare la corona cornuta con gemma turchese e
lo spallaccio con esattamente due corna d'avorio e gemma in castone dorato;
rimuovere completamente la collana ad artiglio. Preservare composizione,
pixel-art arcade, crop quadrato e margini. Nel passaggio finale rimuovere solo
il checkerboard incorporato e produrre alfa reale senza ridisegno o aloni.
```

### Trasformazione deterministica

I derivati sono ottenuti con:

```powershell
.\tools\process-upgrade-icon.ps1 -InputPath <master> -OutputPath <runtime> `
  -Size 256 -Padding 24
```

Lo script ritaglia sui bounds alpha con soglia predefinita `8`, inserisce il
soggetto in un canvas quadrato trasparente e riduce nearest-neighbor. I master
restano in `<id>/hd/`, protetti da `.gdignore`; soltanto `<id>/generated/` è
destinato al runtime futuro.

### File e integrità

| Personaggio | Master HD escluso | SHA-256 master | Derivato runtime | SHA-256 runtime |
|---|---|---|---|---|
| Alea | `alea/hd/evil_portrait.png` (`1145x1374`) | `6EA34F34A2657A015C4DA5227788751BE61B4B03888FEE79724920C52E20CEED` | `alea/generated/evil_portrait.png` (`256x256`) | `DBC64CC4398AF5152F4724266BFC415F4CC5A2915CDF881F3AAEE83BC3840571` |
| Aleo | `aleo/hd/evil_portrait.png` (`1239x1270`) | `615835723D6DFE04EFDF58021765937CBF401693354E4553C7154D19F9538B03` | `aleo/generated/evil_portrait.png` (`256x256`) | `F5A25E8B53E17BD4B1D9D4CCA35176EA6B399D3C39795DDB70CCC789A91DAEF2` |
| Bea | `bea/hd/evil_portrait.png` (`1254x1254`) | `D010B56345970E3D45DFDDDF23F4CC698F3DDE70981C290B87CEC80A2790F18F` | `bea/generated/evil_portrait.png` (`256x256`) | `81AEF0A3B73D1C102FAB653BC151AF33A42EA9082A35422E559294F61C8CCE8E` |
| Lollo | `lollo/hd/evil_portrait.png` (`1254x1254`) | `009820FFB0BF06C639EEFEF83BD4561DF9AA70A0B4200B61C96899D2C1749FA5` | `lollo/generated/evil_portrait.png` (`256x256`) | `21A4B9A35F38614F2C4DCDE502CBD004FCD65F2764EB0C68B06219115B8D914B` |
| Magno | `magno/hd/evil_portrait.png` (`1254x1254`) | `DD729B392C959404089177E8489C135436BC1D02076A0B0EDDC266E78EF8365D` | `magno/generated/evil_portrait.png` (`256x256`) | `49DE75C71232CCD7FBCF5A54711A761022365612110AA07BF549FAD9EA7C68F5` |
| Marghe | `marghe/hd/evil_portrait.png` (`1254x1254`) | `A5B56E0568578E6ACC9A49FD75966D792EB1ED68D4F3C6BB3AC643FB6A075504` | `marghe/generated/evil_portrait.png` (`256x256`) | `9C3818FA2B550E49DA73FEA0051AD87479D15BC97A3A9D1422D35B1BF90B18E3` |
| Migi | `migi/hd/evil_portrait.png` (`1254x1254`) | `1C4605A9C582DF2582BFA5241FE96ABC89B83F944F64B816BE439000BA7D3904` | `migi/generated/evil_portrait.png` (`256x256`) | `9818F360B1A24562DB3E4CE0FEFC4173EDC34F9F16A802F073D0AA19C1A25573` |
| Zat | `zat/hd/evil_portrait.png` (`1254x1254`) | `334B650872FB8201E1B4B8E4D1FE9174998155658A2D91DCCCD0A6C7C74D15B4` | `zat/generated/evil_portrait.png` (`256x256`) | `AAD26DFA34729C379CE24F735F2DF569C315D6F9A2CAF2371D6CA64EA2257F00` |

## Parte 3 — Ritratti Player (PS-068)

### Produzione approvata il 3 settembre 2026

- Origine: OpenAI ImageGen built-in, generazione guidata dai master Player
  `poses.png` e da fotografie personali autorizzate del cast.
- Autore: progetto IL GIOCO con assistenza OpenAI ImageGen.
- Licenza: Licenza del progetto.
- Approvazione: il proprietario ha approvato esplicitamente gli otto busti.
  Per Marghe ha richiesto un'unica correzione: capelli neri; il resto del
  candidato è rimasto invariato.
- Ruolo dei riferimenti: `poses.png` è dominante per design, costume,
  proporzioni e grammatica pixel-art; le fotografie in
  `docs/characters/references/<id>/` sono `subject reference` usate soltanto
  per citazioni fisionomiche semplificate, mai come edit target o copie
  fotorealistiche.

Prompt finale condiviso normalizzato:

```text
Creare il ritratto busto Player nella stessa famiglia pixel-art arcade dei
master poses.png: cluster visibili, bordi a gradini, palette limitata, due o tre
fasce d'ombra, lineamenti semplificati e outline prugna scuro. Conservare design,
costume e proporzioni del personaggio di gioco; trasferire dalle fotografie solo
pochi tratti-citazione riconoscibili, senza riprodurre geometria facciale,
texture o illuminazione fotografica. Inquadratura quadrata coerente, dal punto
vita verso l'alto, sfondo trasparente; niente fotorealismo, 3D, stile chibi,
effetti Evil, testo, logo o watermark.
```

Specifiche applicate:

| ID | Input ImageGen effettivi e citazioni |
|---|---|
| `alea` | `alea/hd/poses.png` dominante; `alea/hd/evil_portrait.png` solo per taglio/densità; `references/alea/source-02.png` e `source-04.png` per volto ovale, naso, occhi, sorriso e piccolo septum. |
| `aleo` | `aleo/hd/poses.png` dominante; `aleo/hd/evil_portrait.png` solo per taglio/densità; `references/aleo/source-01.png` e `source-02.png` per capelli laterali, occhiali, barba, mandibola morbida e mezzo sorriso. |
| `bea` | `bea/hd/poses.png` dominante; `references/bea/source-01.png`, `source-02.png` e `source-03.png` solo per citazioni fisionomiche semplificate. |
| `lollo` | `lollo/hd/poses.png` dominante; `references/lollo/source-01.png` e `source-02.png` solo per citazioni fisionomiche semplificate. |
| `magno` | `magno/hd/poses.png` dominante; `references/magno/source-01.png` solo per citazioni fisionomiche semplificate. |
| `marghe` | `marghe/hd/poses.png` dominante; `references/marghe/source-01.png` e `source-02.png` solo per citazioni fisionomiche semplificate; editing finale limitato al colore nero dei capelli. |
| `migi` | `migi/hd/poses.png` dominante; `references/migi/source-01.png` e `source-02.png` solo per citazioni fisionomiche semplificate. |
| `zat` | `zat/hd/poses.png` dominante; `references/zat/source-01.png`–`source-04.png` solo per citazioni fisionomiche semplificate. |

Traccia degli output ImageGen selezionati (`candidato → master trasparente`):

| ID | Output selezionati |
|---|---|
| `alea` | `exec-42e07cf9-a7ca-434a-abb7-c0d1c273572e.png` → `exec-9285eca1-0885-44bf-8f78-e5e980051618.png` |
| `aleo` | `exec-bb092209-0081-4a9d-921d-a81674bd766d.png` → `exec-0c08033e-ebdd-490b-8755-3fe733455089.png` |
| `bea` | `exec-6c7e6ba5-349d-4a10-8f3a-347801917add.png` → `exec-9816634f-8021-4962-8cd8-6855be009f98.png` |
| `lollo` | `exec-739f7142-b9b1-4395-a0a2-2a216a8d986c.png` → `exec-b4ae8ef0-0283-4d6e-b041-51beee2c01ba.png` |
| `magno` | `exec-ea64aec9-473c-40a6-b213-a94b6fd55fd2.png` → `exec-b2728d46-2194-48f7-85df-45e9de6b765e.png` |
| `marghe` | `exec-c26e515e-bdac-49dc-9273-796d3925308a.png` → edit capelli `exec-beeb4b07-7dbf-4900-a80b-df1243b1042a.png` → `exec-d18b1a72-c4b4-4881-98ab-2fca62bbd10f.png` |
| `migi` | `exec-025ea481-3cc0-4bb7-94d0-ecd8db15d716.png` → `exec-575e26cf-c4b9-4fd2-ae24-177dcd82c8db.png` |
| `zat` | `exec-b8c83322-35bf-4e42-b649-c881c958f72e.png` → `exec-26bcc2af-12f1-40b5-9f51-9d56bab4557e.png` |

I candidati approvati incorporavano checkerboard chiaro o fondale bianco. Un
passaggio ImageGen `background-extraction` per ciascun file ha rimosso solo lo
sfondo e prodotto alfa reale; l'art review ha confermato la conservazione di
soggetto, proporzioni, posa, costume, palette e inquadratura. Su Marghe un edit
`precise-object-edit` precedente all'estrazione ha sostituito esclusivamente il
castano dei capelli con nero e riflessi freddi. I derivati runtime sono stati
prodotti con:

```powershell
.\tools\process-upgrade-icon.ps1 -InputPath <id>/hd/portrait.png `
  -OutputPath <id>/generated/portrait.png -Size 256 -Padding 12 `
  -VisibleAlphaThreshold 8
```

| Personaggio | Master HD escluso | SHA-256 master | Derivato runtime | SHA-256 runtime |
|---|---|---|---|---|
| Alea | `alea/hd/portrait.png` (`1207x1303`) | `C1F2973CBB3AF3AC17F950DB822A8F9BB63220B2980DB9432D64295F4A3982AF` | `alea/generated/portrait.png` (`256x256`) | `1689DCCD66CC477CE0B9A5C710B1C96B1D544C1C9125094B097248122A1C057B` |
| Aleo | `aleo/hd/portrait.png` (`1230x1278`) | `3301280D83AC90B3E5C341D4C0A59228B64A6C984A8ADFBECFA6FEE5E9CAF857` | `aleo/generated/portrait.png` (`256x256`) | `6BA17270293119E39F21BCE94F9A4AFB385593965B76B6B9985F072C89CB0627` |
| Bea | `bea/hd/portrait.png` (`1240x1268`) | `5EAA423221801A7E1EB3A4988FE93338098C40EC72E4A30AB3C989CB0C23EE1A` | `bea/generated/portrait.png` (`256x256`) | `37D13C4526E639708B98E2F7FC6DA18AB5A2FA3BACC167ABC3F25AD449A28563` |
| Lollo | `lollo/hd/portrait.png` (`1230x1278`) | `6DF4F01914CB3AC695A2CC28CEF090E2B547938EDD2866F0767B601941CEDA73` | `lollo/generated/portrait.png` (`256x256`) | `D653A0A741AB2027FEA76F363BE995703D9F207424C50D85D4D8DE886DEC9A3E` |
| Magno | `magno/hd/portrait.png` (`1230x1278`) | `91378520997E3422715D1672421993D9ADBA54C82AAFA68789F3C2D6968D268E` | `magno/generated/portrait.png` (`256x256`) | `AA9B1316EE1C0726205E5772581E2A7E0C6051374C42B97C16B534AAAE5AC56B` |
| Marghe | `marghe/hd/portrait.png` (`1205x1305`) | `FF073246590A852748D0CEAFD98B8959C0C9D836A181A40A3058706C0DFF0CD4` | `marghe/generated/portrait.png` (`256x256`) | `D7D599D3E91DBE1949373CEAF3B062AE377A46ACA9302F7CFA54DEEB7D9D1D43` |
| Migi | `migi/hd/portrait.png` (`1230x1278`) | `06E933AEBFF53F671387BB9E4A8F56F7D8A3FD97EA851C4A896FA98FC2CFB0EF` | `migi/generated/portrait.png` (`256x256`) | `6663F00E7C0A368D26E8A847692BFDA95EE6A7E8ED92DFB514D3528AD4619553` |
| Zat | `zat/hd/portrait.png` (`1214x1295`) | `347512EC3E60EBB2DA4F48ADBF9B627215A9966BBD1DE9BFD43286C358A58477` | `zat/generated/portrait.png` (`256x256`) | `F679DAF73198AA67407FDEE483210A91ABC31D8DFA7E6C85CDEC1F4F533485BA` |

I master HD restano esclusi da import ed export tramite i `.gdignore` già
presenti e gli exclude filter dei tre preset. Il runtime usa esclusivamente i
derivati `generated/portrait.png`.

## Riorganizzazione del 2 settembre 2026

Gli asset erano originariamente divisi in due alberi paralleli,
`assets/art/characters/players/` (con `hd/` e `carousel/`) e
`assets/art/characters/evil/` (con `hd/` e `generated/`), con nomi di file
ridondanti (`evil_alea_source.png`, `carousel/alea.png`, `players/alea.png`).
Sono stati raggruppati per personaggio sotto `assets/art/characters/<id>/`
mantenendo la distinzione `hd/`/`generated/` e i due manifest sono stati fusi
in questo file. Nessun contenuto binario è cambiato: solo percorso e nome file;
gli hash SHA-256 sopra restano quelli originali.

## Parte 4 — Ritratto del Piccione Malvagio (PS-128)

### Produzione art-only del 7 settembre 2026

- Origine: OpenAI ImageGen built-in, generazione testuale guidata dallo sprite
  runtime esistente `assets/art/enemies/pigeons/pigeon_special.png` e dalla
  famiglia corrente dei ritratti Evil, entrambi ispezionati prima della
  generazione ma non allegati come input ImageGen.
- Autore: progetto IL GIOCO con assistenza OpenAI ImageGen.
- Licenza: Licenza del progetto.
- Output ImageGen selezionato:
  `exec-1833b260-03b9-4457-ba8c-79619be5ab77.png`.
- Integrazione runtime: fuori ambito per PS-128; appartiene a PS-129. Il
  derivato è pronto nel percorso definitivo ma nessun `.tres`, scena o test è
  stato modificato da questa produzione.

Prompt finale normalizzato:

```text
Use case: stylized-concept
Asset type: square 2D game Boss-intro portrait master for Pidgeon Survivor
Primary request: create a definitive high-resolution bust portrait of the
existing Piccione Malvagio, translating its tiny gameplay sprite into the same
polished arcade pixel-art portrait family as the game's Evil Boss portraits;
this is the same character, not a redesign
Scene/backdrop: genuinely transparent background, with only a small restrained
plume of detached plum-purple corruption smoke behind the silhouette
Subject: exactly one sinister real pigeon, clearly avian and non-humanoid,
chest-up three-quarter view facing right; broad charcoal and deep indigo body
feathers; near-black plum outline; vivid magenta neck collar and iridescent
band; orange-gold beak and a few clean gold-orange wing-feather accents; one
sharp luminous magenta eye; proud, hungry, scheming expression; compact
powerful pigeon silhouette matching a game Boss
Style/medium: polished caricatural 16-bit arcade pixel art; visibly stepped
edges, intentional chunky pixel clusters, limited palette, two or three clear
shadow bands, crisp near-black plum outline; match the density and finish of a
premium 256x256 Boss portrait, not a tiny sprite enlargement
Composition/framing: square canvas, centered chest-up bust, head fully visible,
safe transparent margin on every side, subject fills roughly 78 percent of the
canvas, essential beak crest chest and shoulders kept away from edges
Lighting/mood: dramatic warm orange-gold rim light against cool indigo feathers;
ominous but playful arcade villain
Color palette: body #291F47-like charcoal indigo, outline #090513-like near-black
plum, accent #FFAD29-like orange-gold, corruption glow #FF387F-like magenta,
restrained plum smoke
Constraints: preserve pigeon anatomy and the existing character identity; true
alpha transparency; exactly one pigeon; no human body, hands, clothing, armor,
crown, sunglasses, grill, food, scenery, floor, cast shadow, frame, UI, text,
letters, logo, watermark, checkerboard, white backdrop or opaque background
Avoid: photorealism, smooth digital painting, 3D render, vector art, anime
humanization, generic demon, raven or eagle anatomy, excessive particles,
muddy gradients, tiny noisy feather detail
```

Trasformazione deterministica:

```powershell
.\tools\process-upgrade-icon.ps1 `
  -InputPath assets\art\characters\piccione_malvagio\hd\portrait.png `
  -OutputPath assets\art\characters\piccione_malvagio\generated\portrait.png `
  -Size 256 -Padding 24
```

Lo script ritaglia sui bounds alpha con soglia `8`, aggiunge padding quadrato e
riduce nearest-neighbor su canvas RGBA trasparente. La review isolata ha
confermato silhouette, palette, leggibilità del volto e margini a `256×256`; i
quattro angoli del derivato hanno alpha `0`.

| Asset | Dimensioni | Byte | SHA-256 |
|---|---:|---:|---|
| `piccione_malvagio/hd/portrait.png` | `1254x1254` | `1508058` | `E74C9D86FE605669DB6BB7BC6B673E38F12F89B1D6CE069B0E87FD2FAE6735FA` |
| `piccione_malvagio/generated/portrait.png` | `256x256` | `120448` | `51C4ADCAFC11B9ECCE53C2E3910AC62C3FE5CAD1C0F78A11ED92F62C1D5865AB` |

Il master è escluso da import tramite
`piccione_malvagio/hd/.gdignore` e dai tre export tramite il filtro comune
`assets/art/characters/*/hd/**`.
