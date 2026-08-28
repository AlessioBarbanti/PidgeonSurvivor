# NEXT PROMPT — Polish finale del tutorial B54

Lavora sulla candidata corrente del tutorial B54. La nuova direzione visiva è
buona, ma servono le correzioni seguenti prima dell'accettazione percettiva.
Non modificare il flusso `BOOT`, il pulsante `TUTORIAL` della welcome, la
navigazione swipe/tastiera/controller, il comportamento `ESCI` sulla prima
pagina, `INDIETRO` sulle successive o il CTA finale `GIOCA`.

## 1. Pagine Abilità e Potenziamenti

- Disponi le quattro icone in una matrice **2×2**, evitando la fila orizzontale
  corrente e le card alte e strette.
- Nella pagina Abilità rimuovi tutte le didascalie sotto le icone: niente
  `TUONI`, `TROTTOLA`, `ZEN`, `SISMA` o altri nomi. Le icone devono essere il
  soggetto visivo principale, con dimensioni e spaziatura uniformi.
- Nella pagina Potenziamenti non usare l'icona/arte di `RACCOLTA`
  (`pickup_range.png`). Sostituiscila con l'arte già esistente di **Bis di
  Salsiccia**:
  `assets/art/icons/upgrades/generated/bis_di_salsiccia.png`.
- Anche la pagina Potenziamenti usa la matrice 2×2. Conserva soltanto le
  etichette davvero utili alla spiegazione; non reintrodurre una galleria di
  nomi tecnici.

## 2. Loop delle animazioni

- Elimina ogni salto visibile fra l'ultimo frame e il primo. Nessun elemento
  deve arrivare alla fine del movimento e teletrasportarsi allo stato iniziale.
- Usa loop realmente continui: animazione ping-pong, curva chiusa o ritorno
  animato lungo lo stesso percorso. Posizione, scala, rotazione e opacità devono
  restare continue al cambio di ciclo.
- Se un elemento deve ripartire da una posizione diversa, il reset può avvenire
  soltanto mentre è completamente nascosto; non usare questa soluzione per i
  piccioni in camminata.
- Mantieni il rispetto di `Flash ridotti` e ferma ogni animazione quando il
  tutorial non è visibile.

## 3. Pagina Nemici

- Organizza i cinque piccioni su **due file**: due elementi centrati nella fila
  superiore e tre elementi centrati in quella inferiore.
- Rimuovi tutte le etichette sotto le icone (`BASE`, `SCIAME`, `ARMATO`,
  `DIVIDE`, `SPARA`). I nomi e le differenze possono restare nel testo
  descrittivo della pagina, ma non dentro la composizione visiva.
- Non limitarti a far pulsare o scalare icone statiche. Riusa, dove possibile,
  gli sprite/frame e la logica di camminata già esistenti nel gameplay per i
  cinque archetipi.
- Il ciclo desiderato è: **camminata → breve pausa in posa leggibile → nuova
  camminata**. La posizione non deve saltare al riavvio: il piccione può
  invertire direzione e tornare camminando, oppure restare nello stesso slot e
  animare i frame di passo senza traslazione.
- Mantieni le cinque silhouette chiaramente distinguibili e una scala visiva
  coerente fra le due file.

## 4. Sfondo e viewport

- Lo sfondo del tutorial deve coprire l'intero **viewport**, edge-to-edge, non
  il rettangolo della safe area.
- Posiziona texture di sfondo e tint/overlay fuori dai container della safe
  area, con anchor full-rect `(0, 0) → (1, 1)` e resa aspect-cover. Non devono
  comparire bande o margini che rivelano l'arena sottostante.
- La safe area continua a proteggere pannello, copy e controlli interattivi;
  questo vincolo non deve restringere lo sfondo decorativo.
- Verifica esplicitamente 16:9, Pixel 9 20:9 e 4:3.

## 5. Verifica richiesta

- Aggiorna lo smoke B54 per coprire struttura 2×2, sostituzione con Bis di
  Salsiccia, assenza delle label nelle gallery, layout nemici 2+3 e sfondo
  full-viewport.
- Aggiungi una verifica deterministica della continuità dei loop e dello stop
  del processing quando il tutorial è nascosto.
- Esegui refresh import/classi, Focused B54 e Relevant; distingui eventuali
  failure preesistenti da regressioni introdotte dal tutorial.
- Produci nuove catture delle sei pagine e controlla visivamente almeno il
  passaggio completo di due cicli animati, senza usare il solo primo/ultimo
  frame come prova.
- Esporta la nuova APK, validala staticamente e installala sul Pixel 9 soltanto
  dopo avere confermato che il proprietario non la sta provando. Cold launch,
  input reale e accettazione percettiva restano gate distinti.

Aggiorna infine `docs/development-plan.md`, `docs/gameplay-evolution-plan.md`,
`docs/prd.md`, `docs/decision-log.md` e `docs/b54-verification.md` con il nuovo
contratto e le evidenze effettivamente raccolte. Non effettuare commit se non
richiesto esplicitamente.
