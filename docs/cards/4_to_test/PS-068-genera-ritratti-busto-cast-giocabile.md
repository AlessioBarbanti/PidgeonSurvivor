---
id: PS-068
titolo: Generare i ritratti busto definitivi del cast giocabile
tipo: art
area: arte
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-09-02
aggiornato: 2026-09-03
---

# PS-068 — Generare i ritratti busto definitivi del cast giocabile

## Contesto

Ogni `FriendDefinition` espone un campo `portrait` (busto ravvicinato) distinto
da `selection_portrait` (arte a figura intera usata oggi nel carosello del
selettore, derivata dalle pose HD B18U). Per tutti e otto i personaggi
`portrait` e `portrait_placeholder` puntano ancora allo stesso ritaglio
`AtlasTexture` dello spritesheet di terze parti CC0 (Eldiran
`RPGCharacterSprites32x32-transparent.png`), nonostante `portraits_approved`
sia già `true` in ciascun `.tres`: non esiste quindi un vero ritratto busto
"buono" per i Player, a differenza degli Evil, che ora hanno un busto
definitivo prodotto da PS-051/PS-052 con la stessa grammatica pixel-art del
resto del cast.

## Comportamento atteso

Ogni personaggio giocabile possiede un ritratto busto originale, alla stessa
qualità e con la stessa griglia di produzione dei ritratti Evil, riconoscibile
come controparte "buona" dello stesso soggetto e coerente con le pose HD B18U
già approvate.

## Criteri di accettazione

- [x] Sono presenti otto ritratti busto: Alea, Aleo, Bea, Lollo, Magno, Marghe,
      Migi, Zat.
- [x] Ogni busto conserva silhouette, acconciatura, corporatura, costume e
      accessori distintivi già approvati nelle pose HD B18U e nel carosello
      selezione, senza reinventare l'identità del personaggio.
- [x] Gli otto ritratti condividono una sola grammatica di produzione (taglio,
      inquadratura, outline, palette, trattamento pixel-art), analoga a quella
      usata per i ritratti Evil, mantenendo comunque leggibile la differenza
      Player/Evil se i due busti compaiono nello stesso contesto.
- [x] Ogni ritratto è leggibile alla dimensione minima prevista dal suo utilizzo
      runtime (almeno quella del busto Evil in Boss intro).
- [x] Nessun ritratto definitivo riusa lo spritesheet CC0 di terze parti
      (`RPGCharacterSprites32x32-transparent.png`).
- [x] `portrait` e `portrait_placeholder` di ciascun `data/friends/<id>.tres`
      puntano al nuovo busto definitivo; nessuno dei due campi resta legato
      all'`AtlasTexture` CC0.
- [x] `portraits_are_placeholders` viene aggiornato a `false` solo dopo
      l'accettazione percettiva del proprietario sugli otto busti.
- [x] `tests/unit/test_b17_friend_content.gd` non assume più che `portrait`
      sia un ritaglio `32x32`: l'asserzione va aggiornata insieme al nuovo
      asset, seguendo lo stesso trattamento già applicato al lato
      `evil_portrait` da [PS-070](../2_to_do/PS-070-aggiorna-aspettativa-32x32-evil-portrait-b17.md).
- [x] Ogni nuovo file possiede master HD e derivato runtime separati, secondo
      la struttura `hd/` / `generated/` già in uso per il cast.
- [x] Il manifest registra percorso, prompt/origine, autore, licenza,
      trasformazioni e SHA-256 per ciascun nuovo file; i master HD restano
      esclusi dai preset export.

## Ambito

- `assets/art/characters/<id>/hd/` e `assets/art/characters/<id>/generated/`,
  per gli otto personaggi: nuovo file busto Player (nome da scegliere in
  coerenza con `evil_portrait.png`, per esempio `portrait.png`).
- `assets/art/characters/ASSET-MANIFEST.md`.
- `data/friends/*.tres`, solo per i campi `portrait`, `portrait_placeholder`,
  `portrait_source`, `portraits_are_placeholders` e metadati di
  approvazione/provenienza.

Non toccare:

- `selection_portrait` (`carousel.png`) e la sua risoluzione nel carosello:
  resta l'arte a figura intera già approvata; questa card produce un asset
  aggiuntivo, non la sostituisce.
- `evil_portrait`, gli asset e i dati Evil (PS-051/PS-052).
- `scripts/ui/character_select_overlay.gd` e qualunque scena UI: l'eventuale
  esposizione del nuovo busto nel selettore è oggetto di [PS-069](../2_to_do/PS-069-ridisegna-selettore-personaggi-per-ritratti-busto.md).
- valori di gameplay, passive, abilità attive dei Friend.

## Verifica

- Smoke: estendi `tests/unit/test_friend_definition_portraits.gd` (o crea
  `tests/unit/test_ps068_friend_portrait_assets.gd` se non esiste un test
  dedicato) → marker `FRIEND_PORTRAIT_ASSETS_SMOKE_OK` — verifica che tutti gli
  otto `FriendDefinition` risolvano `portrait`/`portrait_placeholder` su un
  asset diverso dall'`AtlasTexture` CC0 e che nessun riferimento resti rotto.
- Aggiorna anche `tests/unit/test_b17_friend_content.gd`: l'asserzione che
  `portrait` sia un ritaglio `32x32` (già superata per `evil_portrait` da
  PS-070) va rimossa o resa condizionale a `portraits_are_placeholders`.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK — master HD esclusi dai tre preset
- [ ] Runtime fisico Pixel 9: non richiesto da questa card in isolamento,
      salvo che il busto sia già esposto in una UI esistente
- [x] Controllo percettivo richiesto: sì — accettazione del proprietario sugli
      otto busti e confronto con pose HD, carosello e ritratti Evil

## Decisioni

- **2026-09-02 — Asset aggiuntivo, non sostituzione del carosello.** Il busto
  ravvicinato è un nuovo asset con proprio scopo (analogo a `evil_portrait`);
  `selection_portrait` a figura intera resta invariato e continua a essere
  usato dove già lo è oggi.
- **2026-09-02 — Nessuna decisione ancora presa su dove il busto verrà
  mostrato in UI.** La sola integrazione nel selettore personaggi è
  responsabilità di PS-069, che dipende da questa card.
- **2026-09-02 — Questa card possiede l'aggiornamento del lato `portrait` in
  `test_b17_friend_content.gd`.** PS-070 ha corretto solo il lato
  `evil_portrait` della stessa asserzione, dichiarando esplicitamente di non
  anticipare il lato `portrait` finché l'asset placeholder non viene
  sostituito. Quel momento è questa card: chi la risolve deve toccare quella
  riga di test, non limitarsi al nuovo asset.
- **2026-09-02 — Alea e Aleo approvati come campione della famiglia.** Il
  proprietario ha approvato esplicitamente i candidati ImageGen
  `exec-42e07cf9-a7ca-434a-abb7-c0d1c273572e.png` (Alea) e
  `exec-bb092209-0081-4a9d-921d-a81674bd766d.png` (Aleo). `poses.png` resta
  dominante per stile, costume e proporzioni; le fotografie personali
  autorizzate forniscono soltanto citazioni fisionomiche semplificate, non una
  copia fotorealistica. Dopo il solo passaggio `background-extraction`, i
  master trasparenti sono stati promossi come `<id>/hd/portrait.png` e
  derivati a `256x256` come `<id>/generated/portrait.png`.
- **2026-09-02 — Nessuna integrazione parziale dei dati.** I due asset
  approvati restano preparati ma non ancora collegati ai `FriendDefinition`:
  `portrait`, `portrait_placeholder` e `portraits_are_placeholders` saranno
  aggiornati insieme per tutti e otto i personaggi dopo l'accettazione
  percettiva dell'intera famiglia, evitando uno stato runtime misto.
- **2026-09-03 — Famiglia approvata e integrata atomicamente.** Il proprietario
  ha approvato Bea, Lollo, Magno, Migi e Zat insieme ai campioni Alea/Aleo. Per
  Marghe ha richiesto soltanto capelli neri: un edit mirato ha cambiato il
  colore da castano a nero con riflessi freddi, preservando posa, volto,
  costume e inquadratura. Dopo l'estrazione degli sfondi, tutti gli otto
  `FriendDefinition` usano il derivato `generated/portrait.png` sia come
  `portrait` sia come fallback approvato; nessun `portrait` resta legato al
  foglio CC0.
- **2026-09-03 — Verifiche automatiche saltate su richiesta.** Il refresh
  headless ha raggiunto il marker `[ DONE ] reimport` per tutti gli otto PNG,
  ma il proprietario ha chiesto di non eseguire i test e di committare
  direttamente. `Focused`, `Relevant`, Windows runtime e validazione APK
  restano quindi aperti e impediscono il passaggio a `COMPLETATO`.

## Documenti sincronizzati

- [x] `assets/art/characters/ASSET-MANIFEST.md`.
- [x] `docs/visual-audio-identity.md`: ritratti busto Player definitivi.
- [x] `docs/characters.md`: stato runtime dei ritratti Player.

## Note

Riusa la stessa pipeline di produzione (master HD trasparente,
trasformazione deterministica verso il derivato runtime, manifest con hash)
già rodata per i ritratti Evil in PS-052.

Gli otto master e derivati sono approvati e integrati. L'art review dei
derivati `256x256` ha confermato leggibilità, alfa reale e coerenza della
famiglia; resta da verificare il caricamento tramite i profili automatici e la
resa nel runtime Windows. La validazione percettiva del proprietario è già
chiusa; il Pixel 9 non è richiesto da questa card in isolamento.
