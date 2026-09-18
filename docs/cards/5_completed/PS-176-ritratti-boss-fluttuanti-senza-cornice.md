---
id: PS-176
titolo: Ritratti Boss fluttuanti senza cornice nella Boss Intro
tipo: ux
area: ui
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-09-14
aggiornato: 2026-09-19
---

# PS-176 — Ritratti Boss fluttuanti senza cornice nella Boss Intro

## Contesto

Il proprietario ha consultato `direttore-artistico` e deciso di sostituire il
trattamento attuale della Boss Intro. Oggi `BossUI` ([scripts/ui/boss_ui.gd](../../../scripts/ui/boss_ui.gd),
[scenes/ui/boss_ui.tscn](../../../scenes/ui/boss_ui.tscn)) mostra un
`IntroPanel` con `StyleBoxTexture` costruito sulla cornice generata da PS-102
(`assets/art/ui/boss/generated/boss_intro_frame.png`), un medaglione ritratto
circolare 128×144 ritagliato da un foro nella cornice, un titolo (tinto
dall'`accent_color` della Signature per gli Evil), un'icona Signature e la
citazione, tutti impilati in una `VBoxContainer`.

Sono arrivati 9 nuovi ritratti definitivi in `assets/Evil portrais new/`
(`Alea.png`, `Aleo.png`, `Bea.png`, `Lollo.png`, `Magno.png`, `Marghe.png`,
`Migi.png`, `Zat.png`, `Evil_Pidgeon.png` — uno per ognuno degli otto Evil più
il Piccione Malvagio), ciascuno 1536×1024, con l'ornamentazione (ali, catene,
gemme, cornice dorata) già dipinta dentro l'immagine e un cartiglio scuro
nella parte bassa riservato al testo. `REFERENCE.png` mostra lo stesso
cartiglio con un rettangolo verde puro (`#00FF00`) a delimitare l'area
disponibile per la citazione del personaggio (misurato: `x:[32.5%,67.3%]`,
`y:[78.2%,88.4%]` sull'immagine, centro a `x≈49.9%`).

Questa card sostituisce interamente il trattamento a pannello/medaglione/tinta
di [PS-102](../6_rejected/PS-102-cornice-dedicata-boss-intro.md) e
[PS-103](../6_rejected/PS-103-integra-cornice-boss-intro.md) (spostate a
`SCARTATA` da questa stessa decisione, vedi Decisioni) con un ritratto intero
"fluttuante" e nessun pannello esterno.

## Comportamento atteso

La Boss Intro mostra il ritratto del Boss (Evil `<Nome>` o Piccione Malvagio)
come immagine intera, scalata in `contain` (nessun crop, nessuna distorsione)
dentro la safe area corrente, senza alcun pannello, cornice o `StyleBoxTexture`
esterna: l'unica ornamentazione visibile è quella già dipinta nel file. La
citazione del Boss (`get_safe_quote()`) è sovrapposta al ritratto, dentro il
cartiglio già dipinto, con un inset di sicurezza che la tiene lontana dai
bordi (dove passano fumo/catene, meno leggibili). Titolo (nome Boss) e icona
Signature non sono più mostrati nella Boss Intro. Il bottone "AFFRONTA"
(`ContinueButton`, invariato) compare sotto il ritratto, mai sovrapposto
all'immagine.

## Criteri di accettazione

- [x] `IntroPanel`, `StyleBoxTexture_intro_panel` e il riferimento a
      `boss_intro_frame.png` sono rimossi dalla scena: nessun pannello/cornice
      esterna avvolge più il ritratto nella Boss Intro.
- [x] Il ritratto (Evil `<Nome>` o Piccione Malvagio) è mostrato in `contain`
      dentro la safe area corrente per tutte e 9 le varianti, senza crop né
      distorsione, su almeno le risoluzioni di riferimento Windows (16:9) e
      Android landscape (20:9, Pixel 9).
- [x] La citazione è sovrapposta al ritratto dentro il rettangolo del
      cartiglio, calcolato come percentuale della dimensione a schermo reale
      dell'immagine (non coordinate hardcoded in pixel), coerente con le
      percentuali misurate su `REFERENCE.png`.
- [x] Il font e i colori della citazione riusano token/valori già esistenti nel
      progetto (nessun nuovo token introdotto per questa card).
- [x] La citazione di stress da 167 caratteri (già coperta da
      `test_ps103_boss_intro_frame_wiring.gd`) resta interamente dentro il
      rettangolo del cartiglio, senza uscirne, su tutte e 9 le varianti.
- [x] Titolo (nome Boss) e icona Signature non compaiono più da nessuna parte
      della Boss Intro (rimossi dalla scena, non solo nascosti).
- [x] Il bottone "AFFRONTA" resta invariato (segnali, testo, stile,
      focus/hover/pressed) e non si sovrappone mai al ritratto.
- [x] Un ritratto mancante fa nascondere l'intero blocco ritratto+citazione
      senza lasciare spazio vuoto dedicato (stesso comportamento di
      ricomposizione già garantito prima di questa card).
- [x] I 9 ritratti in `assets/Evil portrais new/` sostituiscono i bust
      precedenti (`evil_portrait.png` per gli otto Evil, `portrait.png` per il
      Piccione Malvagio): master in `hd/`, derivato in `generated/`, riga
      `ASSET-MANIFEST.md` per ciascuno con origine, licenza, trasformazioni e
      SHA-256 di entrambi (skill `asset-pipeline`).
- [x] Il pannello di pausa (`pause_panel_frame.png` e il proprio
      `StyleBoxTexture`) resta bit-per-bit invariato: nessuna regressione
      cosmetica per effetto di questa card (nessun file di pausa toccato).

## Ambito

- `scenes/ui/boss_ui.tscn`: rimuovere `IntroPanel`/`VBox`/`Caption`/
  `IntroTitleLabel`/`SignatureIcon`/`StyleBoxTexture_intro_panel`; introdurre
  un nodo immagine full-bleed per il ritratto e un overlay testo per la
  citazione; riposizionare `ContinueButton` sotto il ritratto.
- `scripts/ui/boss_ui.gd`: `_reflow_intro_panel_position`,
  `_reflow_portrait_frame`, `_apply_signature_identity`,
  `PORTRAIT_MEDALLION_SIZE`/`PORTRAIT_MEDALLION_CENTER_Y` da riscrivere o
  rimuovere per il nuovo layout; `show_intro()`/`_apply_portrait` aggiornati
  per il posizionamento percentuale della citazione sul ritratto scalato.
- `data/friends/*.tres` (campo `evil_portrait`, 8 file) e
  `data/bosses/first_boss.tres` (campo `portrait`): puntati ai nuovi asset.
- `assets/art/characters/<nome>/{hd,generated}/evil_portrait.png` (8) e
  `assets/art/characters/piccione_malvagio/{hd,generated}/portrait.png`:
  nuovi master/derivati da `assets/Evil portrais new/*.png`, con riga
  `ASSET-MANIFEST.md` aggiornata.
- `tests/unit/test_ps103_boss_intro_frame_wiring.gd` e
  `tests/unit/test_ps051_boss_intro_identity.gd`: entrambi asseriscono oggi
  cornice/medaglione/icona/tinta che questa card rimuove — vanno riscritti sul
  nuovo contratto (ritratto floating, nessuna icona/tinta), non lasciati a
  fallire né eliminati senza sostituzione.

Non toccare:

- La risoluzione di ritratto/Signature per `is_evil_variant()`/
  `friend_profile` in `BossDefinition.get_safe_portrait()`/
  `FriendDefinition.get_public_evil_portrait()` (contratto PS-051 di
  *risoluzione* dell'asset, non di presentazione) — cambia solo quale file
  viene risolto, non la logica che lo risolve.
- `BossEncounter.resolve_variant()` e la selezione del profilo Evil
  (PS-006/PS-037/PS-162).
- Lo stato `BOSS_INTRO` del `RunController` e l'arbitraggio dei modali.
- Il pannello di pausa e il proprio `StyleBoxTexture`.
- Segnali, testo e stile del `ContinueButton`.

## Verifica

- Smoke: `tests/unit/test_ps176_boss_intro_floating_portrait.gd` → marker
  `BOSS_INTRO_FLOATING_PORTRAIT_SMOKE_OK` — verifica assenza di
  `StyleBoxTexture` sul pannello (o assenza del pannello stesso), scaling
  `contain` del ritratto dentro la safe area, posizione della citazione come
  percentuale sull'immagine scalata (non hardcoded), citazione di stress
  entro i bordi del cartiglio su più aspect ratio, bottone AFFRONTA sotto il
  ritratto senza sovrapposizione, e ricomposizione senza spazio vuoto quando
  il ritratto manca — per tutte e 9 le varianti (8 Evil + Piccione Malvagio).
- Riscrivere `test_ps051_boss_intro_identity.gd` e
  `test_ps103_boss_intro_frame_wiring.gd` sul nuovo contratto (rimuovere le
  asserzioni su icona Signature e tinta accento, non più presenti) invece di
  lasciarli rossi.
- Profilo minimo prima della chiusura: `Relevant`; `Full` prima di
  `IN VERIFICA`.

## Gate manuali

- [ ] Runtime Windows: non eseguito interattivamente (solo rendering reale via
      `godot_console` non headless per gli screenshot, non un playtest con
      tastiera/mouse sull'EXE). Resta aperto.
- [ ] Validazione statica APK: non eseguita in questa sessione. Resta aperto.
- [ ] Runtime fisico Pixel 9 (percorso: Boss Intro su almeno un Evil e sul
      Piccione Malvagio, citazione al limite di lunghezza, verifica leggibilità
      del testo sovrapposto su schermo piccolo landscape): non eseguito, nessun
      device collegato in questa sessione. Resta aperto.
- [x] Controllo percettivo richiesto: sì — eseguito dall'agente
      `direttore-artistico` su 18 screenshot della resa cablata reale (9
      varianti × 16:9/20:9, `exports/ui-screenshots/ps176-boss-intro/`)
      confrontati con i master in `assets/Evil portrais new/`. Prima passata:
      **approva con modifiche** — ha trovato un conflitto reale non colto dagli
      smoke GUT (la gemma apicale della cornice invadeva la fascia HUD in alto
      a 16:9, coprendo il cronometro; vedi Decisioni per causa e fix). Dopo il
      fix, seconda passata mirata: **risolto**, confermato su 7 screenshot
      rappresentativi (16:9 ed 20:9, inclusa la citazione di stress). Nessuna
      riserva residua su stile, leggibilità del cartiglio o bottone AFFRONTA.

## Decisioni

- **2026-09-14 — Titolo e icona Signature rimossi dalla Boss Intro
  (opzione "Minimal" scelta dal proprietario).** Il rettangolo del cartiglio
  è piccolo a schermo (~300-340×48-55px di testo utile anche con
  l'immagine grande in safe area): il volto dipinto identifica già il
  personaggio, la citazione da sola occupa comodamente lo spazio nel caso di
  stress (167 caratteri, font esistente `BodyS`/12px, 3 righe). Se in futuro
  serve reintrodurre nome o icona, apre una nuova card.
- **2026-09-14 — Il Piccione Malvagio riceve lo stesso trattamento degli
  Evil, non un layout ad hoc.** Il proprietario ha fornito `Evil_Pidgeon.png`
  nello stesso set, con identica geometria/cartiglio delle altre 8 immagini:
  nessuna eccezione di scope, le 9 varianti condividono lo stesso contratto di
  presentazione.
- **2026-09-14 — Riserva statica di `GameHud.GAMEPLAY_TOP_INSET +
  UpgradeOverlay.TOP_BAND_CLEARANCE` in cima al ritratto, trovato dal
  controllo percettivo, non dagli smoke GUT.** Gli smoke verificano il
  ritratto dentro `arena_layout.get_safe_area_rect()` (vincolo fisico:
  bordi/cutout, PS-064), ma quel rettangolo non esclude mai la fascia HUD di
  gioco (cronometro/barre): è un problema diverso, storicamente risolto per
  `UpgradeOverlay`/`BarbRewardOverlay` con `GAMEPLAY_TOP_INSET +
  TOP_BAND_CLEARANCE` (PS-046), mai per `BossUI` perché il vecchio pannello
  medaglione+testo era troppo corto per raggiungere quella fascia. Il nuovo
  ritratto, molto più alto, la raggiungeva. `BossUI` è però figlio diretto di
  `SafeAreaRoot` (non `top_level`, a differenza degli overlay sopra, PS-071):
  non serve un `apply_safe_area()` dall'orchestratore, basta riservare lo
  stesso margine in `_ready()`, staticamente — l'`AspectRatioContainer` si
  limita a rimpicciolirsi nello spazio residuo, non può mai sforare. Aggiunto
  anche un assert dedicato in `test_ps176_boss_intro_floating_portrait.gd`
  (non solo lo screenshot) per evitare che regredisca silenziosamente.
- **Sostituisce:** [PS-102](../6_rejected/PS-102-cornice-dedicata-boss-intro.md)
  (cornice dedicata) e [PS-103](../6_rejected/PS-103-integra-cornice-boss-intro.md)
  (integrazione cornice), entrambe spostate da `IN VERIFICA` a `SCARTATA` in
  questa stessa modifica: il loro output (cornice generata, medaglione
  circolare) viene rimosso da questa card prima ancora di aver superato la
  verifica.
- **2026-09-14 — La citazione è un `RichTextLabel` (`fit_content = false`),
  non un `Label`.** Scoperto in implementazione: un `Label` con
  `autowrap_mode` forza la propria size al minimo necessario a contenere
  tutte le righe wrappate, anche oltre il rettangolo assegnato dalle ancore —
  un vincolo di Godot su qualunque `Control`, non solo dentro un `Container`
  (verificato con uno script headless dedicato). Con la citazione di stress
  (167 caratteri, 4 righe effettive a `BodyS`/12px sulla larghezza del
  cartiglio) il `Label` cresceva oltre il cartiglio dipinto. `RichTextLabel`
  con `fit_content = false` non contribuisce le proprie righe al calcolo
  della minimum size: resta esattamente al rettangolo percentuale assegnato,
  e `clip_contents = true` taglia l'eventuale eccesso invece di farlo
  sconfinare. Poiché `RichTextLabel` non eredita da `Label`, la variazione di
  tema `BodyS` (`base_type = Label`) non gli si applica: font, size (12) e
  colore sono riprodotti come override diretti sullo stesso font/valori di
  `BodyS` (`assets/fonts/nunito_regular.tres`, 12px, `Color(1, 0.94, 0.8, 1)`)
  invece che tramite `theme_type_variation` — stesso valore riusato, nessun
  nuovo token nel file tema.
- **2026-09-14 — Ridimensionamento dei ritratti: bicubico al 50%, nessun
  ritaglio sui bounds alpha.** I 9 master coprono quasi l'intero canvas
  `1536×1024` (bbox alpha misurato: solo 0-4px di margine trasparente su
  ciascun lato) — un ritaglio come `process-upgrade-icon.ps1`/
  `process-arena-obstacle.ps1` avrebbe alterato il rapporto `3:2` di qualche
  pixel, disallineando le percentuali del cartiglio misurate sul master
  intero. Nuovo script `tools/process-boss-portrait.ps1`: resize bicubico
  puro che preserva l'aspect ratio esatto, derivato runtime `768×512`.
- **2026-09-14 — `-Profile Full` ha un fallimento pre-esistente non
  correlato.** `test_ps158_mature_build_anti_afk.gd` fallisce 3/3 volte su
  `-Profile Full` (sempre verde in isolamento) per un probabile timing fra
  `RunController.start_run()`/`is_running()` e `_exit_tree()` del Tiratore —
  zero file toccati da questa card intersecano quell'area. Diagnosticato e
  tracciato separatamente in [PS-177](../5_completed/PS-177-non-determinismo-full-proiettile-tiratore.md)
  invece di bloccare questa card. Vedi Verifica per l'esito esatto.
- 2026-09-19: chiusa dal proprietario con il passaggio in blocco di tutte le card `IN VERIFICA` a `COMPLETATO`.

## Documenti sincronizzati

- [x] `docs/enemies-bosses.md`: sezione "Boss Intro: identità individuale"
      (righe 164-185) descrive ancora medaglione/icona/tinta — va riscritta
      sul nuovo contratto (ritratto floating, nessuna icona/tinta).
- [x] `docs/visual-audio-identity.md`: riga sulla cartella `ui/boss` (riga 147,
      cornice PS-102/wiring PS-103) e sezioni "Stato dei ritratti Evil nella
      Boss Intro" (righe 198+) e "Cornice Boss Intro" (righe 226+) — entrambe
      descrivono il trattamento sostituito da questa card.

## Note

Il proprietario ha già confrontato la direzione con `direttore-artistico`
prima di aprire questa card (consultazione riportata nella richiesta
originale, non ripetuta come pianificazione `game-art-designer` separata:
qui il game-art-designer è stato comunque consultato in modalità
pianificazione per la geometria di consegna — percentuali del cartiglio,
scaling, font — riportata sopra). Il controllo percettivo di chiusura resta
comunque un gate separato con lo stesso agente, da eseguire sulla resa
cablata in scena.

Il proprietario può invocare `qa-esplorativo` per un passaggio esplorativo
sulla sequenza Piccione Malvagio → Evil in run consecutive e su
titoli/citazioni particolarmente lunghi, che gli smoke GUT deterministici non
coprono.

**Evidenza di verifica (2026-09-14):**

- `-Profile Relevant`: verde, `62/62` (`focused=1/1`, `regression=61/61`).
- `-Profile Full`: `focused=4/4` verde su tutte e tre le esecuzioni; la
  regressione generale è risultata `144/145` in tutte e tre le esecuzioni
  consecutive, sempre con lo stesso singolo fallimento pre-esistente non
  correlato (`test_ps158_mature_build_anti_afk.gd`, vedi Decisioni e
  [PS-177](../5_completed/PS-177-non-determinismo-full-proiettile-tiratore.md)).
  Nessun `SCRIPT ERROR`/`FATAL EXCEPTION` nei log.
- Screenshot della resa cablata reale (non simulazione: flusso
  welcome→selezione→play, poi `BossUI.show_intro()`) catturati con lo script
  di sviluppo dedicato `tools/_capture_boss_intro_ps176.gd` (pattern di
  `tools/_capture_ui_screenshots.gd`, invocazione `godot_console --path .
  --script tools/_capture_boss_intro_ps176.gd`, **senza** `--headless`) per
  tutte e 9 le varianti a 16:9 e 20:9 in
  `exports/ui-screenshots/ps176-boss-intro/` (non versionato). Controllo
  percettivo eseguito su questi scatti dall'agente `direttore-artistico`
  (non un'ispezione diretta mia): verdetto riportato sopra in Gate manuali.
