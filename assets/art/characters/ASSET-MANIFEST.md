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
`<id>/hd/`) e dagli export (`assets/art/characters/*/hd/**` nei preset). Solo
`generated/` è consumato dal runtime.

## Parte 1 — Strisce Player (B18U)

Le otto strisce Player sono asset raster originali prodotti il 25 agosto 2026
con OpenAI ImageGen built-in per il progetto IL GIOCO. La baseline iniziale non
usava fotografie o persone reali; l'identity pass del 28 agosto 2026 la supera
per tutti gli otto profili usando riferimenti fotografici forniti e autorizzati
esplicitamente dal proprietario. I risultati restano caricature pixel-art e non
contengono marche, loghi o personaggi di terzi. Il prompt del rework Aleo è in
`docs/aleo-rework-art-prompts.md`.
Origine: progetto IL GIOCO; autore: progetto IL GIOCO con assistenza OpenAI
ImageGen; licenza: Licenza del progetto.

Il fondale approvato B18O
`assets/art/ui/welcome/welcome_ability_cast_background.png` e la conversazione
del 24 agosto 2026 sono stati usati come riferimento visivo per identita,
capelli, corporature, costumi e palette. Il fondale non e incorporato nei file
Player e nessuna UI o scena della welcome entra nelle texture runtime.

### Identity pass del 28 agosto 2026

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
Aleo sono in `docs/aleo-rework-art-prompts.md`.

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
| `magno` | Uomo energumeno tellurico, molto largo e muscoloso, outfit terra, piccoli richiami bovini, passo pesante | Rimossa ogni anatomia animale del primo output: Magno resta umano come nella welcome, con soli motivi a corna/emblema bovino |
| `bea` | Pattinatrice agile senza casco, capelli scuri lunghi e ricci, giacca viola, protezioni e roller, falcata da skating | Nessuna correzione: confronto diretto con Bea B18O positivo; scia e Powerslide restano VFX separati |
| `zat` | Infermiera elettrica in bianco-ciano, simbolo medico generico a cuore, caschetto, passo rapido | Rimosso completamente il copricapo generato; caschetto teal e divisa sono allineati alla welcome, senza Croce Rossa |
| `alea` | Ballerina classica, tutu leggibile, passi eleganti | Capelli portati al biondo caldo e costume a bianco-avorio con oro come nella welcome; nastro e aquila restano VFX separati |
| `aleo` | Muratore con casco, cazzuola, piccolo secchio e stivali, passo robusto | Reso giovane e senza barba; gilet arancio sostituito da abito da lavoro verde oliva e giallo coerente con la welcome. **Da rigenerare**: il rework del 28 agosto 2026 trasforma Aleo in un termotecnico; prompt aggiornato in [`docs/aleo-rework-art-prompts.md`](../../../docs/aleo-rework-art-prompts.md) |
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
massima `28x28`, la centra orizzontalmente e la allinea a `2 px` dal fondo di un
canvas trasparente `32x32`. I tre frame diventano una striscia RGBA `96x32`
ordinata `passo A | idle | passo B`. Nessun ritocco di colore, compositing o VFX
e applicato dopo ImageGen.

Le sorgenti selezionate dopo la rimozione del chroma sono conservate come PNG
RGBA HD `1536x1024` in `<id>/hd/`, su richiesta del proprietario, per riusi
artistici futuri. La presenza di `<id>/hd/.gdignore` e gli exclude filter dei
preset impediscono che siano importate o incluse in EXE/APK. Soltanto le
strisce `96x32` sono consumate dal runtime e Godot le mostra con filtro
nearest.

### File e integrita

| File runtime | Byte master HD | SHA-256 master HD | Byte runtime | SHA-256 runtime |
|---|---:|---|---:|---|
| `magno/generated/sprite.png` | `1060810` | `2EA717859B91B420B97F8D9975D67A3C827BA94CC4355739A4DB4FE370F836A5` | `3162` | `BF3CDDC9AFAC4028A037B588DEF3A0E8C0F7562C6952662E772A9432240766BB` |
| `bea/generated/sprite.png` | `953157` | `3C6B26826B9A6B5708174AE6EDB42F1F652A120DE0B17C3405DCAB8CB756059D` | `2942` | `0646F8C7E1486C548A3C1F96090297E826EA5EC419B698AAC6C4A74144256CB3` |
| `zat/generated/sprite.png` | `810909` | `DD1EB3F249F37426E9573DE02C2E0292F32A932A0C2059F82325D1F92919780B` | `2390` | `A3B621F76C222873017A21E2206A072A71D908713B4A59BBAEA5AD7B9867E0FA` |
| `alea/generated/sprite.png` | `829661` | `61C760FA609852BA31F5C24CE43626EA41228AAC6DFC9371D78D83F65408FEA5` | `1853` | `5FA4E05D766D22F323B18BD2D61B0059CA5298C19B386A794C6EFB14FD8FDD51` |
| `aleo/generated/sprite.png` | `980832` | `53999B4B51D97A918B5AC8F68444417E07B8B17EA4837C239173C5DEF4C787DE` | `2743` | `2408BC57B90877DE4F34C99BB9A0FD6404E33B61A542A19263CCE7B2C99149C6` |
| `lollo/generated/sprite.png` | `862437` | `CA66A174E501BEAB30CA3076F3682CCE955E488EC6EB8BBFC3C7734FDC1CF424` | `2655` | `633751EE7DB25DDC92F3156BE4898124923894A4F6722D52045B2AC49F74BA31` |
| `migi/generated/sprite.png` | `810304` | `04EDEE8F99B5849384D268BD35CB4E498EA80BEA1FA961A67BD19B8D1DC75499` | `2821` | `CC2C6CFC7A7CE160AD0870FE3DC6166771242610CABE7A89F9E72EE6E1446430` |
| `marghe/generated/sprite.png` | `1110523` | `D20B2CBA8B5FEB9A70D62D5E5CBEDFAB96E0FC9BB4E1C954B9BDBEC782A1872C` | `3145` | `30CA08F5BF1E59F0D6856B69B487C77CF75A8F0314827C3FB62F73096349DB9C` |

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
| Magno | `magno/hd/evil_portrait.png` (`1254x1254`) | `BDC3FF4097E0220928FAFA2C24E7C0C6EB9FE8DFE2FAF55A7C4F3FC2D6A8EFBC` | `magno/generated/evil_portrait.png` (`256x256`) | `D55F715224C99EE59EAB98B95E135C64B4B07105845390F57DA5095197CBF6F1` |
| Marghe | `marghe/hd/evil_portrait.png` (`1254x1254`) | `A5B56E0568578E6ACC9A49FD75966D792EB1ED68D4F3C6BB3AC643FB6A075504` | `marghe/generated/evil_portrait.png` (`256x256`) | `9C3818FA2B550E49DA73FEA0051AD87479D15BC97A3A9D1422D35B1BF90B18E3` |
| Migi | `migi/hd/evil_portrait.png` (`1254x1254`) | `1C4605A9C582DF2582BFA5241FE96ABC89B83F944F64B816BE439000BA7D3904` | `migi/generated/evil_portrait.png` (`256x256`) | `9818F360B1A24562DB3E4CE0FEFC4173EDC34F9F16A802F073D0AA19C1A25573` |
| Zat | `zat/hd/evil_portrait.png` (`1254x1254`) | `334B650872FB8201E1B4B8E4D1FE9174998155658A2D91DCCCD0A6C7C74D15B4` | `zat/generated/evil_portrait.png` (`256x256`) | `AAD26DFA34729C379CE24F735F2DF569C315D6F9A2CAF2371D6CA64EA2257F00` |

## Riorganizzazione del 2 settembre 2026

Gli asset erano originariamente divisi in due alberi paralleli,
`assets/art/characters/players/` (con `hd/` e `carousel/`) e
`assets/art/characters/evil/` (con `hd/` e `generated/`), con nomi di file
ridondanti (`evil_alea_source.png`, `carousel/alea.png`, `players/alea.png`).
Sono stati raggruppati per personaggio sotto `assets/art/characters/<id>/`
mantenendo la distinzione `hd/`/`generated/` e i due manifest sono stati fusi
in questo file. Nessun contenuto binario è cambiato: solo percorso e nome file;
gli hash SHA-256 sopra restano quelli originali.
