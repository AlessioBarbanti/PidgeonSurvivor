---
id: PS-132
titolo: Correggi la derivazione degli sprite di gameplay che sfarina Alea e Zat
tipo: fix
area: arte
stato: PRONTO
priorita: media
dipende_da: [PS-116]
origine:
creato: 2026-09-08
aggiornato: 2026-09-08
---

# PS-132 — Correggi la derivazione degli sprite di gameplay che sfarina Alea e Zat

## Contesto

Il proprietario segnala che gli sprite di gameplay del cast sono «troppo poco
dettagliati» e «troppo pixelosi» rispetto ai piccioni nemici, indicando **Alea**
come esempio del difetto e **Aleo** come esempio che invece va bene.

È il gate percettivo di
[PS-116](../4_to_test/PS-116-aumenta-risoluzione-sprite-gameplay-cast.md) che si
chiude **negativo**: quella card aveva già raddoppiato il canvas nativo da
`32×32` a `64×64` per frame rigenerando dal master `hd/poses.png`, e il gap
resta. L'asse risoluzione è quindi esaurito, non va ritentato tal quale.

Il `game-art-designer`, consultato in modalità pianificazione (PS-109), ha
ispezionato tutti e otto i derivati e ha stilato la classifica reale: **Alea** è
il caso peggiore per doppia causa (arti filiformi da ballerina che collassano a
1–2px **e** palette bianco-avorio a bassissimo contrasto interno); **Zat** è il
secondo per la sola palette bianco-ciano uniforme; Marghe e Bea sono rischi medi
non ancora rotti (capelli lunghi che si frammentano, gambe sottili in parte
compensate dalla palette satura); Migi, Lollo, Magno e Aleo leggono bene.

La tensione apparente fra «poco dettagliati» e «troppo pixelosi» si scioglie
distinguendo **dettaglio strutturale** (ampiezza di sagoma, spessore degli arti,
contrasto fra regioni — ciò che rende leggibile un piccione a 48px) da
**dettaglio pittorico** (gradienti, sfumature, antialias del master). Alzare la
risoluzione sullo stesso master pittorico aumenta solo il secondo: ecco perché
PS-116 non ha chiuso il gap.

A questo si aggiunge una causa meccanica accertata leggendo
[tools/process-cast-sprite.ps1](../../../tools/process-cast-sprite.ps1), non
emersa in PS-116: la riduzione usa
`InterpolationMode::NearestNeighbor` con `SmoothingMode::None` su un fattore di
scala enorme. Con `-CanvasSize 64 -Padding 4` l'area disegnabile è `56px`, mentre
la figura nel master è alta ~950px: **ogni pixel di destinazione campiona un solo
pixel sorgente ogni ~17×17 e scarta tutti gli altri**. Una gamba spessa 12px nel
master ha meno di un pixel di probabilità di essere campionata con continuità:
cade fra i campioni, si spezza e diventa il "pixeloso" che il proprietario vede.
È esattamente l'operazione che distrugge le strutture sottili, e colpisce Alea
molto più di Aleo perché Aleo ha arti spessi e contorni scuri ad alto contrasto
che sopravvivono a qualunque campionamento.

## Comportamento atteso

`tools/process-cast-sprite.ps1` acquisisce un trattamento di derivazione
opt-in che preserva la struttura invece di decimarla: riduzione che conserva la
massa dei pixel sorgente (media d'area o riduzione a due stadi) al posto del
campionamento nearest-neighbor secco, quantizzazione della palette a pochi toni
piatti, contorno scuro applicato sul perimetro della sagoma e soglia alfa finale
che mantiene i bordi netti da pixel art senza frangia sfumata. È lo stesso
assetto che rende leggibili i piccioni — palette limitata, contorno scuro,
contrasto alto — ottenuto però per elaborazione deterministica sul master già
approvato, senza nuova sintesi e senza toccare costume, posa o palette
d'identità.

I derivati `assets/art/characters/<id>/generated/sprite.png` di **alea** e
**zat** vengono rigenerati con quel trattamento. Gli altri sei personaggi
restano **byte-identici**: il nuovo comportamento è attivato da parametri
espliciti e i default dello script continuano a produrre esattamente l'output
odierno, così le sette righe di hash già cablate in
`tests/unit/test_b18u_cast_sprites.gd` non cambiano per chi non è in ambito.

Canvas, numero di frame, footprint a schermo, region `AtlasTexture` e hitbox
restano invariati: `player.tscn` e i `data/friends/<id>.tres` non si toccano. Il
corpo Evil (Boss), che riusa la stessa region, eredita il miglioramento
automaticamente come già accertato in PS-116.

## Criteri di accettazione

- [ ] `tools/process-cast-sprite.ps1` invocato **senza** i nuovi parametri
      produce, per tutti e otto i personaggi, un file byte-identico a quello
      oggi in repo (stesso SHA-256): il default non cambia comportamento.
- [ ] I derivati di **alea** e **zat** sono rigenerati col nuovo trattamento e
      restano `192×64` RGBA a 3 frame; i derivati degli altri sei personaggi
      sono invariati e i loro SHA-256 in
      `tests/unit/test_b18u_cast_sprites.gd` non vengono modificati.
- [ ] In ciascuno dei 3 frame dei derivati di alea e zat la sagoma non è
      frammentata: le componenti connesse di pixel con alfa `≥192` e area
      `≥2px` sono al massimo due per frame (corpo più un eventuale accessorio
      volutamente staccato), contro le schegge isolate prodotte oggi dal
      campionamento nearest-neighbor.
- [ ] In ciascuno dei 3 frame dei derivati di alea e zat nessuna colonna di
      pixel interna al bounding box della sagoma è completamente vuota sotto
      la linea di vita: le gambe non si interrompono a metà.
- [ ] Il perimetro esterno della sagoma di alea e zat è coperto per almeno il
      90% da pixel di contorno scuro, senza interruzioni superiori a 2px
      consecutivi.
- [ ] La palette è effettivamente quantizzata: i colori RGB distinti fra i
      pixel con alfa `≥192` di un frame di alea o zat sono al massimo 24
      (oggi sono molti di più per via dell'antialias del master).
- [ ] Il rapporto di contrasto di luminanza fra la luminanza media della
      sagoma e quella del fondo d'arena è `≥3:1` per alea e zat, misurato sul
      colore di fondo dichiarato nel test.
- [ ] `scenes/actors/player.tscn`, gli otto `data/friends/<id>.tres`, il
      `CircleShape2D` di collisione e `HealthComponent` non vengono modificati:
      footprint a schermo, region atlas, hitbox e bilanciamento restano
      identici.
- [ ] `assets/art/characters/ASSET-MANIFEST.md` documenta il nuovo comando con
      i parametri esatti usati per alea e zat, accanto a quello corrente, e
      riporta byte e SHA-256 aggiornati dei due soli derivati rigenerati.
- [ ] Confronto visivo in-run, personaggio in ambito affiancato al piccione
      base, giudicato esplicitamente dal proprietario — resta il gate primario,
      non sostituibile dai criteri automatici qui sopra.

## Ambito

- `tools/process-cast-sprite.ps1`: nuovi parametri opt-in per riduzione che
  conserva la massa, quantizzazione palette, contorno e soglia alfa finale.
- `assets/art/characters/alea/generated/sprite.png` e
  `assets/art/characters/zat/generated/sprite.png`.
- `assets/art/characters/ASSET-MANIFEST.md`.
- Nuovo smoke in `tests/unit/`.

Non toccare:

- i master `hd/poses.png` di qualunque personaggio (nessuna nuova sintesi,
  nessun ritocco di costume, posa o palette d'identità);
- i derivati degli altri sei personaggi e i loro hash attesi;
- `scenes/actors/player.tscn`, `visual_scale_multiplier`, le region
  `AtlasTexture_gameplay_*` negli otto `data/friends/<id>.tres`;
- `scripts/bosses/boss_definition.gd`, `scripts/bosses/first_boss.gd` e i dati
  Boss: il corpo Evil eredita il beneficio dalla stessa region, va verificato
  non implementato;
- `portrait.png`, `carousel.png`, `evil_portrait.png` e le rispettive pipeline;
- le tre aure VFX di PS-099, tarate sul footprint e non sul canvas sorgente;
- `RunController`, il flusso `welcome → tutorial → selezione → run → pausa`, i
  registry degli effetti;
- lo stile e i file dei piccioni.

## Verifica

- Smoke: `tests/unit/test_ps132_cast_sprite_readability.gd` → marker
  `PS132_CAST_SPRITE_READABILITY_OK` (frammentazione, continuità delle gambe,
  copertura del contorno, conteggio colori, contrasto sagoma/fondo per alea e
  zat; invarianza byte-a-byte degli altri sei)
- Rieseguire `test_b18u_cast_sprites.gd`, `test_ps116_cast_sprite_resolution.gd`,
  `test_b24_player_visual_scale.gd` e `test_b18c_player_direction_animation.gd`:
  la regola `assets/art/characters/*/generated/*` di
  [tools/milestone-test-map.json](../../../tools/milestone-test-map.json) li
  pesca già, non serve aggiungere una riga
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows: confronto percettivo diretto Alea e Zat affiancate al
      piccione base, incluso un incontro Boss per il corpo Evil di Alea.
- [ ] Runtime fisico Pixel 9: la leggibilità va verificata anche a risoluzione
      mobile compressa, dove il problema è per definizione peggiore.
- [ ] Controllo percettivo richiesto: **sì**, è il criterio primario della card.

Non pertinenti: validazione statica dell'APK (nessun cambiamento di manifest,
permessi o struttura dell'artefatto; solo due PNG di dimensione invariata).

## Decisioni

- **2026-09-08 — L'asse risoluzione è esaurito, non si ritenta.** PS-116 ha
  già portato il canvas nativo da 32 a 64 senza chiudere il gap. Il
  `game-art-designer` ha sconsigliato esplicitamente un ulteriore aumento a
  96/128: su un master a shading morbido restituisce plausibilmente una
  versione più liscia dello stesso problema, non più nitida, e su Android il
  costo texture cresce (fino a `384×128` per otto personaggi) per un beneficio
  atteso basso.
- **2026-09-08 — Scelta del proprietario: prima il ritocco della derivazione,
  non il nuovo master.** Fra le tre direzioni proposte (nuovo master dedicato
  chunky, ritocco della derivazione, ulteriore aumento di canvas) il
  proprietario ha scelto il ritocco: costo medio-basso, nessuna nuova sintesi,
  **zero rischio di deriva d'identità** dai riferimenti fotografici autorizzati
  del 28/08/2026, ed è un asse realmente non ancora tentato — PS-116 aveva
  toccato solo la risoluzione, mai palette, contorno o metodo di
  ricampionamento.
- **2026-09-08 — Ambito limitato ad Alea e Zat.** Confermato dal proprietario
  sulla raccomandazione del `game-art-designer`: sono i due casi in cui il
  difetto è verificato e netto. Durante una run è visibile un solo sprite di
  gameplay alla volta — mai affiancati — quindi il rischio di incoerenza di
  famiglia è basso, mentre allargare a otto moltiplicherebbe costo e churn di
  hash senza un problema dimostrato sugli altri sei. Marghe e Bea restano
  osservati: se il difetto emerge, apriranno una card propria.
- **2026-09-08 — Il nuovo trattamento è opt-in, non il nuovo default.**
  Decisione tecnica presa scrivendo la card: rigenerare solo due personaggi su
  otto significa che il repo conterrà derivati prodotti da due versioni della
  pipeline. Rendere il trattamento opzionale e lasciare i default invariati è
  ciò che permette di dimostrare, con un criterio verificabile, che gli altri
  sei sono rimasti byte-identici invece di doverlo assumere.
- **Aperto — cosa succede se il gate percettivo resta negativo.** La strada
  successiva è quella già anticipata dalle Note di PS-116 e ripresa dal
  `game-art-designer` come opzione (a): un master `sprite_master.png` dedicato
  per personaggio, dipinto nativamente per il canvas di gameplay con palette
  piatta, contorno spesso e proporzioni compattate, distinto da `poses.png` che
  resta il master di ritratto e carosello. Sarebbe una card `tipo: art` con
  review d'identità, più una card di integrazione separata (PS-090). Il limite
  noto di questa card è proprio lì: la dilatazione può impedire che una gamba
  filiforme collassi, ma non può allargare una gamba che nel master è sottile.
- **Sostituisce:** nulla. Segue PS-116, che resta storica e non va riaperta.

## Documenti sincronizzati

- [ ] [docs/visual-audio-identity.md](../../../docs/visual-audio-identity.md):
      la sezione "Sprite di gameplay del cast (PS-116)" va estesa col comando
      di derivazione corrente per i personaggi trattati e con la nota che due
      derivati su otto usano il trattamento di leggibilità.
- [ ] `assets/art/characters/ASSET-MANIFEST.md`: comando, byte e SHA-256 dei
      due derivati rigenerati.
- [ ] `docs/characters/alea.md` e `docs/characters/zat.md`, se la sezione dei
      master e derivati correnti cita i parametri di derivazione.

## Note

**Questa card non richiede il `game-art-designer` in produzione**: non c'è
nuova sintesi, il master resta quello approvato e il lavoro è ingegneria dello
script più rigenerazione deterministica. È risolvibile da `card-risolvi` come
una normale card `fix`, con la skill `asset-pipeline` per la rigenerazione e il
manifest.

Le soglie numeriche nei criteri (24 colori, contrasto 3:1, 90% di contorno,
2px di interruzione massima) sono proposte del `game-art-designer` adattate a
questa direzione: vanno misurate sui derivati attuali prima di cablarle nel
test, e se un valore risulta irraggiungibile per costruzione va corretto nella
card con la misura reale, non aggirato allentandolo in silenzio.

Attenzione al ricampionamento: una media d'area pura reintroduce l'antialias
sfumato che rende "molle" la pixel art. La soglia alfa finale e la
quantizzazione servono proprio a ricostruire i bordi netti dopo la riduzione —
l'ordine delle operazioni conta.
