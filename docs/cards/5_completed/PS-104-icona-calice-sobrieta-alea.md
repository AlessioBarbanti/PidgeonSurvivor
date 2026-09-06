---
id: PS-104
titolo: Genera l'icona del calice per la Sobrietà di Alea
tipo: art
area: arte
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-09-05
aggiornato: 2026-09-07
---

# PS-104 — Genera l'icona del calice per la Sobrietà di Alea

## Contesto

[PS-105](../4_to_test/PS-105-nuova-passiva-alea-due-dita-e-parto.md) sostituisce la
passiva di Alea, "L'Aquila Non Sbaglia Mai" (RNG a intervalli,
`alea_eagle_never_misses`), con "Due Dita e Parto": una barra Sobrietà che si
riempie in modo prevedibile e, raggiunta la soglia, fa entrare Alea in
"Brilla" per qualche secondo. Il proprietario vuole rappresentare la barra
con un **calice di vino rosso** nella safe area, in alto a sinistra. In fase
di richiesta si era posta la domanda se la stessa icona potesse servire
anche altrove (es. come tell di stato aggiuntivo): il proprietario ha
confermato che resta **solo un indicatore HUD** (vedi Decisioni).

Il precedente diretto è il particellare di stato già in uso per Alea
(`TELL_ALEA_POSITIVE`/`TELL_ALEA_NEGATIVE`,
[scripts/content/friend_passive_controller.gd:53-54](../../../scripts/content/friend_passive_controller.gd)),
oggi verde/rosso durante l'effetto casuale attivo: con la nuova passiva
diventa obsoleto (non esiste più un esito positivo/negativo) e
[PS-105](../4_to_test/PS-105-nuova-passiva-alea-due-dita-e-parto.md) lo sostituisce con
un nuovo particellare colorato dedicato a "in Brilla" — non con questa
icona, che resta separata.

Questa card si ferma alla produzione degli asset, come impone
[PS-090](../5_completed/PS-090-separa-generazione-integrazione-card-art.md).
Il cablaggio in HUD (e l'eventuale riuso come tell di stato) è
[PS-106](../3_in_sprint/PS-106-integra-icona-calice-sobrieta-alea-hud.md).

## Comportamento atteso

Esiste, derivata e a manifest, un'icona a calice di vino rosso che comunica
visivamente il livello di riempimento della barra Sobrietà (da vuoto a
pieno), coerente con lo stile pixel-art già stabilito per le altre icone HUD
e di stato del gioco.

## Criteri di accettazione

- [x] Esiste un master a tema calice di vino rosso, leggibile a dimensione
      HUD (icona piccola in alto a sinistra, non un elemento a piena
      schermata).
- [x] Il calice comunica il **livello di riempimento graduale** tramite due
      derivati alla stessa canvas quadrata `128×128` RGBA, allineati
      pixel-per-pixel fra loro: `alea_sobriety_glass_empty.png` (vetro/
      contorno del calice, base statica sempre visibile) e
      `alea_sobriety_wine_fill.png` (solo il liquido isolato, senza il
      contorno del vetro). I due file sono pensati perché PS-106 li componga
      con una maschera/shader di riempimento verticale dal basso verso
      l'alto, guidata direttamente dal float continuo 0.0-1.0 di PS-105:
      nessuno stato intermedio pre-renderizzato, nessuna rigenerazione se
      cambia la logica di soglia della passiva.
- [x] Lo stato "pieno" si distingue a colpo d'occhio dallo stato "vuoto"
      anche a saturazione ridotta (stesso principio già richiesto alle
      coppie di stato in PS-029/PS-098: mai il solo colore a portare
      l'informazione).
- [x] Il derivato esiste in `assets/art/icons/` (percorso coerente con le
      icone HUD/passive già presenti) con una riga nell'`ASSET-MANIFEST.md`
      pertinente: origine, autore/licenza, trasformazioni, hash SHA-256.
- [x] PS-104 non ha modificato scene o script: i file sostituiscono i
      placeholder agli stessi percorsi già referenziati dalla card di wiring
      [PS-106](../3_in_sprint/PS-106-integra-icona-calice-sobrieta-alea-hud.md).

## Ambito

- Nuovi master e derivati sotto `assets/art/icons/` (percorso esatto a
  discrezione dell'agente, coerente con le convenzioni già in uso).
- `ASSET-MANIFEST.md` della cartella pertinente.

Non toccare:

- `scenes/ui/hud.tscn`, `scripts/ui/hud.gd`,
  `scripts/content/friend_passive_controller.gd` (wiring: PS-106);
- `data/friends/alea.tres` e la logica della passiva di Alea;
- ritratti, sprite di gameplay e Signature di Alea/Evil Alea, non toccati da
  questa card.

## Verifica

- Nessuno smoke GUT: card `tipo: art`, verificata da art review e manifest
  come da convenzione PS-090.

## Gate manuali

- [x] Runtime Windows: non pertinente a PS-104, appartiene a PS-106 e va
      rieseguito con il derivato reale
- [x] Validazione statica APK: non pertinente a PS-104, appartiene a PS-106 e
      va rieseguita con il derivato reale
- [x] Runtime fisico Pixel 9: non pertinente a PS-104 (nessun wiring); resta
      un gate della card di integrazione PS-106
- [x] Controllo percettivo: review isolata a `128×128` e a `32×32` su fondo
      HUD scuro. Outline/stelo/piede restano leggibili nel layer vetro e il
      vino isolato aggiunge una massa riconoscibile dal basso; il risultato
      non sostituisce la review in runtime di PS-106.

## Decisioni

- **2026-09-05 — L'icona resta un indicatore HUD, non un tell di stato.**
  Il proprietario ha confermato: il calice copre solo la barra Sobrietà in
  alto a sinistra. Il tell "in Brilla" (ex `TELL_ALEA_POSITIVE`/
  `TELL_ALEA_NEGATIVE`) resta un particellare colorato indipendente,
  cablato da [PS-105](../4_to_test/PS-105-nuova-passiva-alea-due-dita-e-parto.md) sullo
  stesso meccanismo già in uso per Aleo/Lollo/Migi — non questa icona.
- **2026-09-06 — Opzione A: asset a due layer con maschera di riempimento
  verticale, guidata direttamente dal float 0.0-1.0 di PS-105 (non un set di
  frame discreti a soglia).** Confermato dal proprietario: il segnale
  sorgente è un float continuo, non un insieme di stati fissi, e PS-106
  richiede un aggiornamento in tempo reale "senza polling né valori
  stantii" — un mascheramento/shader verticale legge il float direttamente
  senza introdurre gradini visibili né richiedere N unità d'arte aggiuntive
  ad ogni ritocco della soglia di Brilla. Geometria di consegna (decisione
  tecnica di integrazione, non creativa): due derivati `128×128` RGBA sulla
  stessa canvas — `alea_sobriety_glass_empty.png` (vetro/contorno, sempre
  visibile) e `alea_sobriety_wine_fill.png` (solo liquido, da mascherare
  verticalmente dal basso in PS-106). La dimensione `128×128` non è
  arbitraria: è la stessa già in uso da tutta la pipeline icone del
  progetto (passive, abilità, nemici — tutte derivate a `128×128` da
  `tools/process-*-icon.ps1`), così l'integrazione in HUD scala verso il
  basso una texture pixel-art coerente invece di introdurre una nuova scala
  di produzione.
- **2026-09-07 — Master e due layer reali prodotti con ImageGen e derivati
  dalla stessa canvas.** `alea_sobriety_goblet_master.png` è il master
  1254×1254 RGBA; l'editing separa vetro e liquido in due sorgenti della stessa
  dimensione. `tools/process-layered-hud-icon.ps1` riduce entrambi alla stessa
  canvas 128×128 con nearest-neighbor e conserva le coordinate, ricavando il
  vetro dal master con una maschera cromatica del solo borgogna. La prima
  estrazione del vetro è stata scartata in art review perché aveva reso opaco
  il checkerboard di trasparenza; il derivato finale ha alpha 0 al centro della
  coppa e negli angoli. A scala reale, il calice vuoto conserva outline,
  stelo e piede oro/azzurri mentre il vino isolato riempie la coppa dal basso:
  forma e massa del liquido, non il solo colore, distinguono pieno e vuoto.
- **2026-09-07 — PS-106 è la card di integrazione corretta.** La card aveva
  ancora il collegamento storico a PS-105 e il criterio "nessun riferimento";
  PS-106 ha già cablato i percorsi definitivi su placeholder e ora riceve il
  loro contenuto reale senza alcuna modifica runtime da PS-104. Refresh import,
  smoke e verifica di integrazione restano apertamente di PS-106.

## Documenti sincronizzati

- [x] `docs/visual-audio-identity.md`: nuova riga per l'icona HUD.

## Note

Card gemella di [PS-106](../3_in_sprint/PS-106-integra-icona-calice-sobrieta-alea-hud.md),
che possiede il cablaggio HUD e i suoi gate runtime.
