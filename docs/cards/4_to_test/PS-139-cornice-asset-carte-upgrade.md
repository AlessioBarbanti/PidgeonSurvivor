---
id: PS-139
titolo: Applica la cornice asset esistente alle carte upgrade
tipo: ux
area: ui
stato: IN VERIFICA
priorita: bassa
dipende_da: [PS-152]
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-139 — Applica la cornice asset esistente alle carte upgrade

## Contesto

Le tre carte di scelta upgrade (`scenes/ui/upgrade_card.tscn`) usano uno
`StyleBoxFlat` piatto (bordo 3px uniforme, `border_color = Color(0.19, 0.48,
0.68, 0.9)`), mentre il modale pausa e il bottone azione della selezione
personaggio usano già `assets/art/ui/pause/pause_panel_frame.png`, una
texture nine-slice dorata a rivetti pensata per essere riusata. Consultato in
merito, il direttore-artistico conferma che le carte upgrade — l'unico
momento "premiante" della UI — sono rimaste nel linguaggio grezzo delle prime
iterazioni mentre pausa, selezione personaggio e boss intro sono già passate
alla cornice asset: è drift di produzione, non solo estetico.

Il nine-slice pieno di `pause_panel_frame.png` non è praticabile: quel file
ha un crest a diamante centrato in alto/basso che con tre carte affiancate si
ripeterebbe tre volte fianco a fianco (il direttore-artistico l'aveva già
sconsigliato prima di aprire questa card). Un ritaglio geometrico dei soli
quattro angoli (via `AtlasTexture`, nessun nuovo file) è stato tentato ma
bocciato in art review: `pause_panel_frame.png` è completamente opaco (senza
alpha) e il motivo dorato dentro ciascun ritaglio 56×52 non parte
dall'angolo — il bezel quasi-nero risultante non coincide col navy della
carta e a schermo appare come una toppa scura scollegata dal vero spigolo.
[PS-152](../5_completed/PS-152-rivetto-angolo-carte-upgrade.md) produce l'asset
dedicato con alpha reale che risolve il problema; questa card procede nel
frattempo con un placeholder deterministico allo stesso percorso (PS-110),
invece di restare `BLOCCATO`.

## Comportamento atteso

Le carte upgrade mostrano un trattamento di cornice coerente con l'estetica
dorata a rivetti già stabilita altrove nella UI, senza risultare pesanti o
ripetitive quando tre carte sono affiancate.

## Criteri di accettazione

- [x] Lo sfondo/bordo delle carte upgrade (stato normale) non è più
      unicamente lo `StyleBoxFlat` piatto di prima: un ornamento dorato a
      rivetti (ritaglio/riuso dell'asset esistente, vedi Decisioni per il
      perché non è rimasto uno `StyleBoxTexture` nine-slice) compare ai
      quattro angoli di ogni carta. Lo `StyleBoxFlat` sottostante resta,
      bordo blu incluso (vedi criterio identità di sistema sotto).
- [x] Con tre carte affiancate a schermo (livello up con tre opzioni), il
      risultato non produce ripetizione visiva pesante né un crest duplicato
      tre volte — verificato con screenshot reali
      (`exports/ui-screenshots/05_upgrade_overlay.png` e la variante
      Pixel 9): l'ornamento è ai soli quattro angoli, il crest del frame
      pieno non compare mai.
- [x] L'ornamento d'angolo si aggancia pulito allo spigolo della carta, senza
      bezel/toppa scura visibile: asset reale di PS-152, verificato con
      screenshot reali e confermato dal direttore-artistico (vedi Decisioni).
- [x] Gli stati `hover`, `pressed`, `focus` e `disabled` restano leggibili e
      distinguibili fra loro quanto lo erano prima (nessuna regressione di
      feedback di interazione) — invariati rispetto alla card, non toccati.
- [x] Il contenuto della carta (icona, titolo, descrizione, MetaPanel con
      rango) resta interamente leggibile e non tagliato dai nuovi ornamenti
      d'angolo — verificato dallo smoke geometrico
      (`test_ps139_corner_ornaments_do_not_cover_real_content`).
- [x] Il bordo blu freddo dello stato `normal`/`hover` resta invariato:
      `test_ps036_barb_reward_visual_identity.gd` lo usa come identità di
      sistema per distinguere le carte level-up/bonus (fredde) dalle carte
      Speciality di Barb (calde, arancioni) — ricolorarlo a oro rompeva
      quel contratto, scoperto durante l'implementazione (non era un
      criterio esplicito della card originale, aggiunto qui perché ha
      vincolato la soluzione finale).
- [x] L'output è stato validato dal direttore-artistico con l'asset reale:
      "Approvato" — aggancio pulito, coerenza di famiglia con
      `pause_panel_frame.png`, nessuna ripetizione pesante a tre carte,
      nessun drift fra gli stati level-up/bonus (freddo) e Speciality di
      Barb (caldo) (vedi Decisioni).

## Ambito

- File toccati: `scenes/ui/upgrade_card.tscn` (quattro `TextureRect`
  d'angolo aggiunti, `StyleBoxFlat` esistenti invariati nel colore tranne il
  `corner_radius` ridotto da 18 a 12), `scripts/ui/upgrade_card.gd`
  (nasconde gli ornamenti durante il trattamento Speciality di Barb),
  `tools/milestone-test-map.json`.
- Nuovo placeholder: `assets/art/ui/upgrade_card/upgrade_card_corner.png`
  (`128×128`, generato con `tools/generate-art-placeholder.ps1`), sostituito
  dall'asset reale di PS-152 senza altre modifiche a questa card.
- Non toccare: logica di `UpgradeService`/`UpgradeEffectRegistry`, il layout
  del `MetaPanel` (PS-047/PS-063), la scena `barb_reward_overlay` (stile
  diverso, non oggetto di questa card), il bordo blu freddo dello stato
  `normal` (identità di sistema PS-036).

## Verifica

- Smoke: `tests/unit/test_ps139_upgrade_card_frame.gd` → marker
  `PS139_UPGRADE_CARD_FRAME_OK`, verifica presenza/visibilità condizionata
  degli ornamenti d'angolo, distinzione degli stati, e assenza di
  sovrapposizione con icona/titolo reali. Non verifica la resa pixel-perfetta
  dell'aggancio allo spigolo (quello è un controllo percettivo, non
  automatizzabile in modo affidabile).
- Focused (`-RefreshEditor`), Relevant e Full rieseguiti con l'asset reale di
  PS-152 (non più il placeholder): Focused 5/5, Relevant 35/35 step
  (1/1 focused, 34/34 regressioni), Full 139/139 step (137/137 regressioni,
  toolchain PASS) — nessun `SCRIPT ERROR`/`FATAL EXCEPTION` in nessuno dei
  tre profili.
- Screenshot reali rigenerati con l'asset definitivo
  (`exports/ui-screenshots/05_upgrade_overlay.png` e la variante Pixel 9) e
  sottoposti al direttore-artistico: approvato (vedi Decisioni).

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: verifica percettiva della leggibilità
      delle tre carte affiancate su schermo compatto)
- [x] Controllo percettivo richiesto: sì — fatto. Confronto screenshot
      `05_upgrade_overlay.png` prima/dopo con l'asset reale di PS-152,
      validato dal direttore-artistico: "Approvato" (la prima revisione sul
      crop geometrico aveva bocciato quel tentativo, vedi Decisioni).

## Decisioni

- **2026-09-10 — Consultato il direttore-artistico prima di aprire la card**
  (richiesta del proprietario dopo revisione screenshot). Ha confermato che
  l'intervento è riuso di un asset già esistente (`pause_panel_frame.png`),
  non nuova arte, e ha sconsigliato la cornice piena con crest ripetuto tre
  volte a favore di un trattamento solo-perimetro. Motivazione integrale
  nella conversazione di apertura card, non duplicata qui.
- **2026-09-10 — Scartato lo `StyleBoxTexture` nine-slice pieno.** Un
  singolo margine Godot lega la dimensione dell'angolo allo spessore del
  bordo: non esiste un ritaglio nine-slice a margine singolo che includa
  angoli reali su entrambi i lati senza includere anche il crest centrale
  (che occupa la stessa fascia orizzontale). Escluso anche il taglio "solo
  angoli via 4 crop indipendenti + `StyleBoxFlat` per il bordo dritto": più
  vicino al fattibile, ma è quello che poi ha rivelato il problema del
  bezel (vedi sotto).
- **2026-09-10 — Ricolorare il bordo a oro rompeva l'identità di sistema di
  PS-036.** Un primo tentativo ha ricolorato `border_color` dello stato
  `normal` a un tono caldo (`0.62, 0.47, 0.22`); `test_ps036_barb_reward_visual_identity.gd`
  (`La carta bonus deve conservare il bordo freddo del level-up`, riga 120)
  verifica che il bordo `normal` resti blu-dominante come marcatore di
  sistema (level-up/bonus = freddo, Barb Speciality = caldo). Corretto
  scegliendo un blu diverso da quello originale (`0.32, 0.56, 0.74`, non
  identico al vecchio flat ma ancora "freddo") e affidando l'accento dorato
  ai soli quattro angoli.
- **2026-09-10 — Angoli via `AtlasTexture` sul foglio esistente: bocciati in
  art review dal direttore-artistico.** Il crop diretto di
  `pause_panel_frame.png` (regioni `Rect2(0,0,56,52)` e simmetriche) è stato
  verificato al pixel: il file è completamente opaco (nessun canale alpha),
  il motivo dorato dentro ogni ritaglio non parte da (0,0) ma da circa
  x:12,y:13, e lo sfondo quasi-nero del ritaglio (RGB≈5,6,6) non coincide
  col navy della carta (RGB≈28,41,56). A schermo: una toppa scura
  rettangolare scollegata dal vero spigolo della carta, non un rivetto che
  vi si aggancia — confermato su entrambe le catture (16:9, Pixel 9 20:9),
  su tutte le carte, in tutti gli stati. Verdetto: "approva con modifiche",
  soluzione pulita = asset dedicato con alpha, non un ulteriore crop.
- **2026-09-10 — Scorporato l'asset dedicato in PS-152, procede con
  placeholder invece di restare `BLOCCATO` (PS-109/PS-110).** Il
  game-art-designer ha fissato in pianificazione la geometria di consegna
  (vedi Decisioni di PS-152): derivato `128×128` RGBA, motivo ancorato a
  (0,0), riusabile via `flip_h`/`flip_v` per i quattro angoli. Generato
  subito un placeholder alla stessa geometria con
  `tools/generate-art-placeholder.ps1 -OutputPath assets/art/ui/upgrade_card/upgrade_card_corner.png -Width 128 -Height 128 -Label CORNER`
  e cablato in scena (un solo `Texture2D`, non più quattro `AtlasTexture`
  indipendenti, coerente con la decisione "un solo master" di PS-152). Stato
  portato a `IN ATTESA ASSET`.
- **2026-09-10 — Asset reale ricevuto da PS-152.** Il proprietario ha promosso
  il rivetto dedicato e il placeholder è stato sostituito in-place; la card non
  è più `IN ATTESA ASSET` e torna `IN CORSO`. Restano da rieseguire le sue
  verifiche e i gate runtime con le tre carte affiancate.
- **2026-09-10 — Focused/Relevant/Full rilanciati con l'asset reale: tutti
  verdi, nessuna regressione.** Rigenerati anche gli screenshot ufficiali
  (16:9 e Pixel 9 20:9) con `tools/_capture_ui_screenshots.gd`.
- **2026-09-10 — Seconda revisione del direttore-artistico: "Approvato".**
  Verificato su crop pixel-level dei tre angoli campionati: nessun
  bezel/toppa scura residua, il rivetto si aggancia esattamente
  all'intersezione dei bordi blu della carta in entrambe le risoluzioni.
  Palette/stile coerenti con `pause_panel_frame.png` come "fratello
  visivo" credibile, pur essendo una sintesi bespoke dichiarata (facet a X
  vs sfera dorata in sede ottagonale — famiglia cromatica coerente, non un
  retread letterale). Nessuna ripetizione pesante a tre carte affiancate;
  il confine identitario level-up/bonus (freddo+oro) vs Speciality di Barb
  (caldo, staffa arancione senza rivetto) resta rispettato in entrambe le
  direzioni (`05b_barb_speciality.png`, `05c_barb_bonus.png`). Contenuto
  (icona/titolo/descrizione/MetaPanel) confermato leggibile e non tagliato.
  Nessuna modifica richiesta; nessuna nuova regola da fissare in
  `visual-audio-identity.md` (la convenzione sull'ornamento a sé con alpha
  reale è già registrata da PS-152). Card portata a `IN VERIFICA`: restano
  aperti solo i gate manuali su device/piattaforma, non eseguibili da
  questa sessione.

## Documenti sincronizzati

- [x] `docs/visual-audio-identity.md`: la regola sugli ornamenti d'angolo a
      clip (asset a sé con alpha, non crop di un frame intero) è registrata
      in PS-152, che la propaga quando consegna l'asset reale.

## Note

Alternativa scartata: cornice piena identica al modale pausa applicata a
ciascuna carta — il direttore-artistico la sconsiglia per ripetizione visiva
pesante a tre carte affiancate.

Seconda prova pratica del meccanismo placeholder/`IN ATTESA ASSET` di
PS-109/PS-110 dopo PS-104/PS-106, questa volta innescata da un rigetto in art
review durante l'implementazione (non da una dipendenza nota fin dall'inizio).
