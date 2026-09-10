---
id: PS-152
titolo: Genera il rivetto d'angolo isolato per le carte upgrade
tipo: art
area: arte
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-152 — Genera il rivetto d'angolo isolato per le carte upgrade

## Contesto

[PS-139](../4_to_test/PS-139-cornice-asset-carte-upgrade.md) doveva applicare
alle tre carte upgrade (`scenes/ui/upgrade_card.tscn`) un trattamento coerente
con la cornice dorata a rivetti già usata in pausa/selettore/boss intro
(`assets/art/ui/pause/pause_panel_frame.png`). Il nine-slice pieno di
quell'asset non era praticabile: contiene un crest a diamante centrato in
alto/basso che con tre carte affiancate si sarebbe ripetuto tre volte (il
direttore-artistico l'aveva già sconsigliato in una consultazione precedente
a PS-139).

Il tentativo di PS-139 di ritagliare geometricamente (via `AtlasTexture`,
nessun nuovo file) i quattro angoli del file esistente è stato bocciato in
art review: `pause_panel_frame.png` è un PNG completamente opaco (nessun
canale alpha), e il rivetto dorato dentro ciascun ritaglio 56×52 non parte
dall'angolo (0,0) del ritaglio — verificato pixel per pixel, lo sfondo
quasi-nero (RGB≈5,6,6, alpha 255) circonda il motivo dorato vero e proprio
(che occupa solo x:[12,55] y:[13,55] circa dentro quel riquadro). Quel bezel
non coincide con il navy della carta (`bg_color` ≈ RGB 28,41,56): a schermo
compariva una toppa rettangolare scura scollegata dal vero spigolo della
carta, non un rivetto che vi si aggancia.

Il game-art-designer (consultato in modalità pianificazione) sconsiglia un
ulteriore matting del file esistente: il motivo è già alla sua risoluzione
minima utile (crop di un foglio già ridotto al 50% da un master), e qualunque
soglia di trasparenza applicata a posteriori lascerebbe una frangia residua
(stesso difetto, solo attenuato) o eroderebbe i dettagli già minuscoli.
Raccomanda un asset nuovo, generato ex-novo con alpha reale, ispirato alla
stessa palette/stile del frame esistente ma pensato da zero per essere
isolato — un solo master (angolo in alto a sinistra) pensato per essere
riusato via `flip_h`/`flip_v` di Godot sugli altri tre angoli, così i quattro
risultano pixel-identici per costruzione (a differenza dei quattro ritagli
indipendenti tentati da PS-139).

Questa card si ferma alla produzione dell'asset, come impone
[PS-090](../5_completed/PS-090-separa-generazione-integrazione-card-art.md).
Il cablaggio nella scena (già preparato da PS-139 su un placeholder) resta di
PS-139.

## Comportamento atteso

Esiste, derivato e a manifest, un rivetto d'angolo isolato con alpha reale
(sfondo trasparente attorno alla silhouette del motivo), stilisticamente
coerente con `pause_panel_frame.png` (oro antico, bronzo scuro, piccolo
rivetto), pronto per essere applicato ai quattro angoli di una carta UI via
`flip_h`/`flip_v`, senza margine trasparente sui due lati che devono
coincidere con lo spigolo reale della carta.

## Criteri di accettazione

- [x] Esiste un master HD del solo motivo "medaglione/rivetto d'angolo"
      (nessun tratto di bordo che ne esce, per decisione del proprietario),
      alla stessa palette e livello di dettaglio di
      `assets/art/ui/pause/pause_panel_frame.png` — confrontato affiancato
      in art review, non lasciato al giudizio implicito di chi genera.
- [x] Il derivato runtime ha alpha reale (trasparente, non un rettangolo
      pieno) attorno alla silhouette del motivo: canvas `128×128` RGBA, motivo
      ancorato esattamente all'angolo (0,0) del canvas (zero margine in alto
      e a sinistra, così l'ornamento copre interamente
      `corner_radius = 12` della carta senza lasciarlo intravedere), margine
      trasparente ~19% a destra e in basso per non tagliare bordi/ombre
      morbide.
- [x] Un solo file basta per tutti e quattro gli angoli della carta: nessuna
      asimmetria o dettaglio direzionale (fonte di luce marcata, testo) che
      impedirebbe di riusarlo via `flip_h`/`flip_v` su Godot per gli altri
      tre angoli.
- [x] Prominenza/scala pensate per la stessa resa proporzionale già vista nello
      screenshot approvato di PS-139 (`~32×30` a schermo su carte
      `250×392`), non un motivo ingrandito o ricontrastato per compensare
      l'assenza delle linee di bordo connesse.
- [x] Il derivato esiste in `assets/art/ui/upgrade_card/` con una riga
      nell'`ASSET-MANIFEST.md` pertinente: origine, autore/licenza,
      trasformazioni, hash SHA-256.
- [x] PS-152 non modifica scene o script: il file sostituisce il placeholder
      allo stesso percorso già referenziato da PS-139
      (`assets/art/ui/upgrade_card/upgrade_card_corner.png`).

## Ambito

- Nuovo master e derivato sotto `assets/art/ui/upgrade_card/`.
- `assets/art/ui/upgrade_card/ASSET-MANIFEST.md` (nuovo file).

Non toccare:

- `scenes/ui/upgrade_card.tscn`, `scripts/ui/upgrade_card.gd` (wiring:
  PS-139);
- `assets/art/ui/pause/pause_panel_frame.png` e il suo uso nine-slice
  altrove (pausa, tutorial, terminale, boss intro): resta invariato, questo
  è un asset nuovo e distinto, non una sua modifica;
- lo `StyleBoxFlat` blu freddo della carta (bordo/sfondo): identità di
  sistema di PS-036, non oggetto di questa card.

## Verifica

- Nessuno smoke GUT: card `tipo: art`, verificata da art review e manifest
  come da convenzione PS-090.

## Gate manuali

- [x] Runtime Windows: non pertinente a PS-152, appartiene a PS-139 e va
      rieseguito con il derivato reale
- [x] Validazione statica APK: non pertinente a PS-152, appartiene a PS-139
- [x] Runtime fisico Pixel 9: non pertinente a PS-152 (nessun wiring); resta
      un gate di PS-139
- [x] Controllo percettivo: confronto affiancato col motivo d'angolo di
      `pause_panel_frame.png` (coerenza palette/stile) e review isolata a
      `128×128` su fondo navy scuro (coerenza col contesto reale della
      carta) — non sostituisce la review in runtime di PS-139 con le tre
      carte affiancate

## Decisioni

- **2026-09-10 — Asset nuovo ex-novo, non matting del file esistente.**
  Raccomandazione del game-art-designer in pianificazione: il motivo dentro
  `pause_panel_frame.png` è già alla risoluzione minima utile (crop di un
  foglio già ridotto al 50% da un master 1536×1024); qualunque estrazione a
  posteriori lascerebbe una frangia residua o eroderebbe dettagli già
  minuscoli. Un asset generato da zero parte con alpha pulita e permette di
  controllare canvas/margini per l'uso specifico. Rischio esplicito: deriva
  stilistica dalla palette esistente — mitigato dal criterio di confronto
  affiancato in art review.
- **2026-09-10 — Un solo master riusato via `flip_h`/`flip_v`, non quattro
  varianti.** Il motivo (medaglione/rivetto, nessun elemento direzionale) è
  per costruzione adatto al mirroring nativo di Godot; garantisce anche i
  quattro angoli pixel-identici fra loro, a differenza dei quattro ritagli
  indipendenti tentati da PS-139 (crop da un foglio disegnato, non
  garantiti identici).
- **2026-09-10 — Solo medaglione, niente tratto di bordo in uscita.**
  Scelta del proprietario fra due opzioni proposte dal game-art-designer:
  un tratto di bordo dorato in uscita dall'angolo avrebbe convissuto col
  bordo blu di 3px dello `StyleBoxFlat` esistente, due linguaggi di bordo
  sovrapposti da verificare. Il medaglione isolato replica la composizione
  che PS-139 aveva già ritagliato geometricamente, cambiando solo il difetto
  segnalato (alpha/colore).
- **2026-09-10 — Stessa prominenza proporzionale di oggi, non ingrandita.**
  Scelta del proprietario: la resa già vista nello screenshot approvato di
  PS-139 (`~32×30` a schermo) resta il riferimento; minimo rischio, isola
  solo il problema tecnico senza cambiare un impatto visivo già validato in
  art review.
- **2026-09-10 — Geometria di consegna (decisione tecnica di integrazione,
  non creativa): master HD `512×512`, motivo ancorato a (0,0), derivato
  runtime `128×128` RGBA via lo stesso schema deterministico
  nearest-neighbor già in uso per `pause_panel_frame.png`.** Margine di
  sicurezza ~19% solo sui lati destro/basso (quelli rivolti verso il centro
  della carta); zero margine su alto/sinistra perché quel bordo deve
  coincidere esattamente con lo spigolo della carta, coprendo
  `corner_radius = 12` dello `StyleBoxFlat` sottostante.
- **2026-09-10 — Candidato promosso dal proprietario.** La review interna ha
  scartato il primo tentativo perché introduceva una staffa a L e tratti di
  bordo vietati. Il candidato selezionato è una placca compatta bronzo/oro con
  rivetto centrale; dopo il confronto su fondo navy e col frame pausa, il
  proprietario ha risposto «Promosso!». Il derivato approvato sostituisce il
  placeholder allo stesso percorso già cablato da PS-139; scene e script
  restano invariati.

## Documenti sincronizzati

- [x] `docs/visual-audio-identity.md`: nuova riga per l'ornamento d'angolo
      delle carte upgrade, con la regola "gli ornamenti d'angolo derivati per
      usi a clip devono esistere come asset a sé con alpha trasparente, non
      come crop diretti di un frame intero" (raccomandazione del
      direttore-artistico, per evitare che il prossimo riuso ripeta lo stesso
      difetto di bezel opaco).

## Note

Card gemella di [PS-139](../4_to_test/PS-139-cornice-asset-carte-upgrade.md),
che possiede il cablaggio in scena e i gate runtime sul derivato promosso.

Evidenza 2026-09-10: master `512×512` e derivato `128×128` aperti alla
dimensione reale; bounds alpha del derivato `0,0..103,103`, margine destro e
inferiore `24 px` (18,75%), pixel `(0,0)` trasparente, nessuna alpha parziale.
Confronto affiancato con `pause_panel_frame.png` e composizione su fondo navy
`RGB(28,41,56)` superati; approvazione finale del proprietario: «Promosso!».
