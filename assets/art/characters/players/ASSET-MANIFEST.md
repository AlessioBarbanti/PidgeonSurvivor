# Manifest sprite Player B18U

Le otto strisce Player sono asset raster originali prodotti il 25 agosto 2026
con OpenAI ImageGen built-in per il progetto IL GIOCO. Nessuna fotografia,
persona reale, marca, logo o personaggio di terzi e stato usato come soggetto.
La dichiarazione vale per le otto strisce qui registrate. La striscia `aleo` e
pero superata dal rework del 28 agosto 2026: la nuova direzione visuale del
personaggio e ispirata, con consenso esplicito dichiarato dal proprietario, ai
tratti di una persona reale, e resta una caricatura pixel-art. Il prompt di
rigenerazione e in `docs/aleo-rework-art-prompts.md`.
Origine: progetto IL GIOCO; autore: progetto IL GIOCO con assistenza OpenAI
ImageGen; licenza: Licenza del progetto.

Il fondale approvato B18O
`assets/art/ui/welcome/welcome_ability_cast_background.png` e la conversazione
del 24 agosto 2026 sono stati usati come riferimento visivo per identita,
capelli, corporature, costumi e palette. Il fondale non e incorporato nei file
Player e nessuna UI o scena della welcome entra nelle texture runtime.

## Identity pass del 28 agosto 2026

Le otto strisce sono state rigenerate dal proprietario del progetto in un
passaggio di identita successivo alla baseline B18U. I master conferiti erano
gia PNG RGBA trasparenti `1536x1024`, accompagnati da una copia intermedia su
chroma per ogni candidato. Per ogni personaggio e stata promossa la versione
piu recente:

| Personaggio | Candidato promosso |
|---|---|
| `magno` | `magno_identity_v3_source.png` |
| `bea` | `bea_identity_v5_source.png` |
| `zat` | `zat_identity_v2_source.png` |
| `alea` | `alea_identity_v3_source.png` |
| `aleo` | `aleo_thermotechnician_v3_source.png` |
| `lollo` | `lollo_identity_v2_source.png` |
| `migi` | `migi_identity_v2_source.png` |
| `marghe` | `marghe_identity_v3_source.png` |

Le copie su chroma e le versioni non promosse erano materiale di staging non
versionato e sono state rimosse dopo la promozione: per questo la tabella di
integrita registra ora byte e SHA-256 del master HD trasparente al posto
dell'output ImageGen su chroma della baseline B18U. Le trasformazioni
deterministiche verso `96x32` e verso il carosello `256x256` sono invariate e
sono state rieseguite con gli stessi script e gli stessi parametri.

Per `aleo` il passaggio accompagna il rework gameplay da muratore a
termotecnico: la sua direzione visuale e ispirata, con consenso esplicito
dichiarato dal proprietario, ai tratti di una persona reale e resta una
caricatura pixel-art. La clausola «nessuna persona realeº della baseline B18U
continua a valere per gli altri sette profili. I prompt di questo passaggio per
Aleo sono in `docs/aleo-rework-art-prompts.md`.

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
| `aleo` | Muratore con casco, cazzuola, piccolo secchio e stivali, passo robusto | Reso giovane e senza barba; gilet arancio sostituito da abito da lavoro verde oliva e giallo coerente con la welcome. **Da rigenerare**: il rework del 28 agosto 2026 trasforma Aleo in un termotecnico; prompt aggiornato in [`docs/aleo-rework-art-prompts.md`](../../../../docs/aleo-rework-art-prompts.md) |
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

| File runtime | Byte master HD | SHA-256 master HD | Byte runtime | SHA-256 runtime |
|---|---:|---|---:|---|
| `magno.png` | `1060810` | `2EA717859B91B420B97F8D9975D67A3C827BA94CC4355739A4DB4FE370F836A5` | `3162` | `BF3CDDC9AFAC4028A037B588DEF3A0E8C0F7562C6952662E772A9432240766BB` |
| `bea.png` | `953157` | `3C6B26826B9A6B5708174AE6EDB42F1F652A120DE0B17C3405DCAB8CB756059D` | `2942` | `0646F8C7E1486C548A3C1F96090297E826EA5EC419B698AAC6C4A74144256CB3` |
| `zat.png` | `810909` | `DD1EB3F249F37426E9573DE02C2E0292F32A932A0C2059F82325D1F92919780B` | `2390` | `A3B621F76C222873017A21E2206A072A71D908713B4A59BBAEA5AD7B9867E0FA` |
| `alea.png` | `829661` | `61C760FA609852BA31F5C24CE43626EA41228AAC6DFC9371D78D83F65408FEA5` | `1853` | `5FA4E05D766D22F323B18BD2D61B0059CA5298C19B386A794C6EFB14FD8FDD51` |
| `aleo.png` | `980832` | `53999B4B51D97A918B5AC8F68444417E07B8B17EA4837C239173C5DEF4C787DE` | `2743` | `2408BC57B90877DE4F34C99BB9A0FD6404E33B61A542A19263CCE7B2C99149C6` |
| `lollo.png` | `862437` | `CA66A174E501BEAB30CA3076F3682CCE955E488EC6EB8BBFC3C7734FDC1CF424` | `2655` | `633751EE7DB25DDC92F3156BE4898124923894A4F6722D52045B2AC49F74BA31` |
| `migi.png` | `810304` | `04EDEE8F99B5849384D268BD35CB4E498EA80BEA1FA961A67BD19B8D1DC75499` | `2821` | `CC2C6CFC7A7CE160AD0870FE3DC6166771242610CABE7A89F9E72EE6E1446430` |
| `marghe.png` | `1110523` | `D20B2CBA8B5FEB9A70D62D5E5CBEDFAB96E0FC9BB4E1C954B9BDBEC782A1872C` | `3145` | `30CA08F5BF1E59F0D6856B69B487C77CF75A8F0314827C3FB62F73096349DB9C` |

## Sorgenti HD trasparenti conservate

| File HD | Dimensioni | SHA-256 |
|---|---:|---|
| `hd/magno_source.png` | `1536x1024` | `2EA717859B91B420B97F8D9975D67A3C827BA94CC4355739A4DB4FE370F836A5` |
| `hd/bea_source.png` | `1536x1024` | `3C6B26826B9A6B5708174AE6EDB42F1F652A120DE0B17C3405DCAB8CB756059D` |
| `hd/zat_source.png` | `1536x1024` | `DD1EB3F249F37426E9573DE02C2E0292F32A932A0C2059F82325D1F92919780B` |
| `hd/alea_source.png` | `1536x1024` | `61C760FA609852BA31F5C24CE43626EA41228AAC6DFC9371D78D83F65408FEA5` |
| `hd/aleo_source.png` | `1536x1024` | `53999B4B51D97A918B5AC8F68444417E07B8B17EA4837C239173C5DEF4C787DE` |
| `hd/lollo_source.png` | `1536x1024` | `CA66A174E501BEAB30CA3076F3682CCE955E488EC6EB8BBFC3C7734FDC1CF424` |
| `hd/migi_source.png` | `1536x1024` | `04EDEE8F99B5849384D268BD35CB4E498EA80BEA1FA961A67BD19B8D1DC75499` |
| `hd/marghe_source.png` | `1536x1024` | `D20B2CBA8B5FEB9A70D62D5E5CBEDFAB96E0FC9BB4E1C954B9BDBEC782A1872C` |

## Derivati frontend B18T

Il carosello B18T usa la posa idle centrale delle stesse otto sorgenti HD. Lo
script `tools/process-carousel-portrait.ps1` divide il master in tre celle,
isola deterministicamente la componente opaca connessa piu grande della cella
centrale e la ricampiona nearest-neighbor in un canvas trasparente `256x256`,
con `14 px` di padding e allineamento al fondo. Non applica generazione,
ritocco, recolor, compositing o VFX: autore, generatore, prompt, data e licenza
restano quelli del master B18U. I master in `hd/` continuano a essere esclusi
da import ed export; soltanto questi derivati UI vengono consumati dal runtime.

| File carosello | Byte | SHA-256 |
|---|---:|---|
| `carousel/magno.png` | `61363` | `C8930E629C57F598DB8B82E8710C7DE2D0CA52E8FB3749D75ADBED90F949FE26` |
| `carousel/bea.png` | `46858` | `A3ECB4C23A252E033C32424B606367409F2FE350A9908A0E556A327930F8454A` |
| `carousel/zat.png` | `40219` | `B7CE0D95801E6B3E92E6861D59C8ADA7B6BBAC2AEE917AB2F36788597B0BF2AB` |
| `carousel/alea.png` | `29153` | `CE59D593AFA30667B75E5DD185595C45028109BA48E8FEDFFB267360FE434DF6` |
| `carousel/aleo.png` | `49755` | `18951C313652C86D696B29B831A4CBD9FD136B3FA377FF3DA59EA8F11A044EC6` |
| `carousel/lollo.png` | `48688` | `1C57686966A4C395616E9163C47DB6E7449F453CBC980B03D1D561EA9D8AA46E` |
| `carousel/migi.png` | `48941` | `3249AE96796D4DE09A914D36F5E9F3EE2ACFBD08A0738F45A9A0A1BEA26310F4` |
| `carousel/marghe.png` | `54744` | `922DFED4E24588698350040EFFF4460936EB84A59FE73EA94B73EE4A510007A9` |
