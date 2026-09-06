---
id: PS-107
titolo: Rigenera l'icona di Punto di Cottura (ex Salamoia Bolognese)
tipo: art
area: arte
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-09-06
aggiornato: 2026-09-07
---

# PS-107 — Rigenera l'icona di Punto di Cottura (ex Salamoia Bolognese)

## Contesto

[PS-093](../4_to_test/PS-093-nuovi-assi-scarto-base-personaggi.md) introduce
la carta upgrade del colpo critico (`data/upgrades/cooking_point_crit.tres`,
titolo "Punto di Cottura", rinominata da "Salamoia Bolognese" per la regola
PS-089 che riserva i nomi di tagli/preparazioni di carne alle Specialità di
Barb). Il meccanismo è implementato e verificato; la carta non è ancora
cablata nel catalogo live perché le manca un'icona accettabile.

Il master HD orfano riusabile (`assets/art/icons/upgrades/hd/upgrade_salamoia_bolognese.png`,
1254×1254, mai derivato prima) è stato sottoposto ad art review
(`direttore-artistico`) durante la risoluzione di PS-093 ed è stato bocciato:

- **Silhouette a tre nuclei diagonali** (ciotola in alto a sinistra, pennello
  a destra, bistecca in basso, uniti da un filo di colata) — nessun altro
  derivato del catalogo upgrade adotta questa composizione; tutti gli altri
  sono un unico cluster compatto.
- **Illeggibile alla dimensione reale d'uso**: a 48×48 (`UPGRADE_CHIP_ICON_SIZE`
  in [scripts/ui/end_screen.gd](../../../scripts/ui/end_screen.gd), e in
  [scenes/ui/hud.tscn](../../../scenes/ui/hud.tscn) riga 260) diventa una
  macchia arancione/marrone indistinguibile.
- **Confondibile con "Il condimento di Barb"** (`assets/art/icons/upgrades/generated/condimento_di_barb.png`):
  stesso soggetto ciotola/vaso di spezie, stessa palette, per due effetti
  meccanicamente lontanissimi (XP vs colpo critico).

Il crop/resize automatico non è la causa (verificato: l'algoritmo replica
esattamente `tools/process-upgrade-icon.ps1`, pixel-per-pixel identico su un
altro asset della stessa serie): il problema è nel master stesso, non
risolvibile con un ricrop diverso.

## Comportamento atteso

Esiste, a manifest, un nuovo master HD per "Punto di Cottura" che risolve i
tre problemi sopra: un solo nucleo visivo, leggibile a 48px, distinguibile da
"Il condimento di Barb".

## Criteri di accettazione

- [x] Il master a tema "colpo critico/punto perfetto" risolve in **un solo
      nucleo visivo compatto** (non tre elementi separati agli angoli, come
      il master bocciato) — coerente con la convenzione osservata in tutti
      gli altri 14 derivati del catalogo upgrade (un solo cluster silhouette
      contenuto). Verificato: bistecca+sonda del termometro sono un unico
      cluster fuso, la sonda è infilata nella carne, non tre elementi
      agli angoli.
- [x] Al massimo 2-3 elementi di contorno, coerente con la densità di
      `meat_fork_damage`/`pinza_lunga`, non con l'estremo di
      `condimento_di_barb`. Verificato per ispezione diretta affiancata dei
      tre derivati (vedi Decisioni): bistecca + sonda/quadrante + un solo
      accento di glint, nessuna ciotola/erbe/aglio/vaso.
- [x] Include un elemento visivo univoco che comunichi "colpo perfetto" (es.
      una scintilla/bagliore concentrato sul punto di contatto), distinto da
      "Il condimento di Barb" invece di ripeterne bowl/vaso + erbe sparse.
      Verificato: quadrante analogico rosso-arancio-verde con ago fermo sulla
      zona verde e glint ciano-bianco isolato proprio lì, unico accento
      freddo dell'immagine.
- [x] Il derivato a 128×128 (stesso script/algoritmo `process-upgrade-icon.ps1`)
      resta leggibile e riconoscibile **anche ridimensionato a 48×48**
      (dimensione reale d'uso in HUD/fine run) — verificarlo esplicitamente
      prima di consegnare, non solo a 128px. Verificato con un downscale
      nearest-neighbor aggiuntivo del derivato a 48×48 (fuori pipeline
      runtime, solo per questa verifica): bistecca, sonda, quadrante e i tre
      colori dell'arco restano distinti; confronto diretto contro lo stesso
      downscale di `meat_fork_damage.png` (comparabile) e
      `condimento_di_barb.png` (diventa una macchia illeggibile a quella
      scala, il problema originale che questa card doveva evitare).
- [x] Il titolo "Salamoia Bolognese"/il tema "carne" non compare: il nome
      della carta è "Punto di Cottura" ([PS-089](../5_completed/PS-089-elimina-sovrapposizioni-tema-carne-powerup.md)
      vieta ai nomi del catalogo ordinario di citare tagli/preparazioni di
      carne). Nessun testo è renderizzato nell'icona; il nome carta non è
      stato toccato.
- [x] Il derivato esiste in `assets/art/icons/upgrades/generated/` con una
      riga nell'`ASSET-MANIFEST.md` pertinente: origine, autore/licenza,
      trasformazioni, hash SHA-256.
- [x] Nessun file derivato è ancora referenziato da scene o script: il
      cablaggio nel catalogo live resta a
      [PS-108](../2_to_do/PS-108-integra-carta-punto-di-cottura.md). Verificato
      con una ricerca del nome file nel repository: nessun risultato fuori da
      questa card e dal manifest.

## Ambito

- Nuovo master e derivato sotto `assets/art/icons/upgrades/`.
- `ASSET-MANIFEST.md` della cartella pertinente.
- Il vecchio master orfano (`hd/upgrade_salamoia_bolognese.png`) resta sul
  disco come storico bocciato; non va cancellato da questa card.

Non toccare:

- `data/upgrades/cooking_point_crit.tres` e la logica del colpo critico
  (`WeaponController`, `UpgradeEffectRegistry`): già implementati da PS-093;
- il cablaggio nel catalogo live e in `docs/powerup-catalog.md`/
  `ASSET-MANIFEST.md` di riferimento finale: [PS-108](../2_to_do/PS-108-integra-carta-punto-di-cottura.md).

## Verifica

- Nessuno smoke GUT: card `tipo: art`, verificata da art review e manifest
  come da convenzione PS-090.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: non pertinente a questa card (nessun wiring)
- [ ] Controllo percettivo richiesto: sì — leggibilità a 48px reale, non solo
      a 128px in isolamento. Lasciato aperto per approvazione del
      proprietario: la direzione bistecca+termometro è una reinterpretazione
      creativa non ancora vista da un umano, non solo un ricontrollo tecnico.
      Verifica tecnica già svolta e documentata in Decisioni: downscale
      nearest-neighbor esplicito a 48×48 del derivato, confrontato affiancato
      con lo stesso downscale di `meat_fork_damage.png` e
      `condimento_di_barb.png` (vedi `ASSET-MANIFEST.md` per il dettaglio).

## Decisioni

- **2026-09-06 — Bocciata la derivazione del master orfano esistente.**
  `direttore-artistico` ha dato verdetto "Da rifare" durante PS-093: tre
  nuclei visivi separati, illeggibile a 48px, confondibile con "Il
  condimento di Barb". Card aperta per la rigenerazione invece di forzare un
  derivato scadente in gioco.
- **2026-09-06 — Rinominata da "Salamoia Bolognese" a "Punto di Cottura".**
  `salamoia` è nella lista nera di [PS-089](../5_completed/PS-089-elimina-sovrapposizioni-tema-carne-powerup.md)
  (`tests/unit/test_ps089_ordinary_catalog_meat_audit.gd`), che riserva i
  nomi di tagli/preparazioni di carne alle Specialità di Barb. La proposta
  originale in `docs/powerup-catalog.md` (31 agosto 2026) precedeva quella
  regola.
- **2026-09-07 — Nuovo master: bistecca + termometro da cucina come nucleo
  unico, non ridisegno del vecchio soggetto ciotola/pennello/bistecca.** I
  criteri della card fissano già la direzione ("colpo critico/punto di
  cottura perfetto", un solo nucleo, elemento univoco tipo scintilla/bagliore
  sul punto di contatto) senza specificare l'oggetto esatto: ho scelto un
  termometro da cucina infilato nella bistecca perché rappresenta
  letteralmente "punto di cottura" (la sonda misura il punto di cottura
  della carne) e permette di ancorare l'elemento univoco richiesto a un
  quadrante analogico con arco colorato rosso-arancio-verde e ago fermo sulla
  zona verde — un "colpo perfetto" leggibile come stato, non solo come
  effetto decorativo. L'accento del glint è ciano-bianco (non ambra come il
  resto della famiglia "Specialità"): scelta deliberata per marcare
  visivamente "critico" come categoria diversa dagli accenti di brace/calore
  già usati ovunque, riprendendo la convenzione di glow freddo già stabilita
  da `pinza_lunga.png` per un effetto potenziato/speciale. Risolve i tre
  problemi diagnosticati: (1) un solo cluster fuso bistecca+sonda, non tre
  elementi separati; (2) verificato leggibile a 48×48 (vedi Criteri di
  accettazione e `ASSET-MANIFEST.md`); (3) nessuna ciotola/erbe/aglio/vaso,
  silhouette non sovrapponibile a "Il condimento di Barb". Generato con
  ImageGen via Codex CLI (gpt-image), un solo candidato accettato in art
  review senza bisogno di iterazione: master `hd/upgrade_cooking_point_crit.png`
  (`1254×1254` RGBA, alpha reale verificato ai quattro angoli), derivato
  `generated/cooking_point_crit.png` (`128×128`, stesso
  `tools/process-upgrade-icon.ps1` degli altri derivati della cartella).
  Decisione rivedibile: se il proprietario preferisce un soggetto diverso in
  sede di controllo percettivo (gate lasciato aperto sotto), rigenerare
  restando dentro gli stessi criteri già fissati.

## Documenti sincronizzati

- [x] `docs/powerup-catalog.md`: sezione "Punto di Cottura" — stato icona
      aggiornato per riflettere il nuovo master/derivato prodotti; resta un
      riferimento a "controllo percettivo aperto" finché il proprietario non
      approva la direzione bistecca+termometro.

## Note

Delegata a `game-art-designer` per la regola di board sulle card `tipo: art`
che richiedono nuova generazione. Al momento dell'apertura di questa card,
l'agente aveva segnalato ImageGen non disponibile su altre card aperte in
parallelo (PS-102, PS-104): in questa sessione ImageGen era disponibile e la
generazione è avvenuta al primo tentativo, senza bisogno di iterazione.
