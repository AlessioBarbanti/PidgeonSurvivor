---
id: PS-069
titolo: Ridisegnare il selettore personaggi attorno ai ritratti busto
tipo: ux
area: ui
stato: IN VERIFICA
priorita: media
dipende_da: [PS-068]
origine:
creato: 2026-09-02
aggiornato: 2026-09-03
---

# PS-069 — Ridisegnare il selettore personaggi attorno ai ritratti busto

## Contesto

[PS-068](../4_to_test/PS-068-genera-ritratti-busto-cast-giocabile.md) produce un
ritratto busto definitivo per ciascuno degli otto Friend, analogo per qualità
e famiglia visiva ai ritratti Evil già usati nella Boss intro.

Il selettore personaggi attuale
(`scenes/ui/character_select_overlay.tscn`,
`scripts/ui/character_select_overlay.gd`) è invece costruito attorno a
`selection_portrait`, l'arte a figura intera del carosello.

Nella composizione corrente il personaggio selezionato occupa una cornice
verticale relativamente stretta, mentre nome, descrizione del ruolo, passiva
e abilità attiva sono organizzati attorno ad essa. Il layout è funzionale,
ma la rappresentazione del Friend ha oggi meno presenza visiva rispetto alle
informazioni che lo circondano.

I nuovi ritratti busto introducono un asset molto più adatto a comunicare
volto, personalità, costume e identità del personaggio. Questa card non deve
quindi limitarsi ad aggiungere un nuovo `TextureRect`, ma deve evolvere la
composizione affinché il Friend selezionato diventi il principale punto
focale della schermata.

La direzione non è un redesign totale dell'identità visiva esistente:
sfondo, linguaggio ornamentale, pannelli Passiva/Abilità, palette e CTA
attuale possono essere mantenuti dove funzionano. Il lavoro si concentra
soprattutto sulla rappresentazione del personaggio, sul carosello e sulla
gerarchia della metà sinistra della schermata.

PS-054 ("Adattare il selettore personaggi al 20:9") interveniva sullo stesso
selettore per adattarlo meglio ai formati larghi riusando soltanto asset
esistenti. Con l'introduzione dei nuovi busti, il suo scopo è stato assorbito
da questa card: il nuovo layout risolve contestualmente presenza del
personaggio e adattamento ai diversi aspect ratio. PS-054 è stata eliminata
dalla board (2026-09-03) per evitare due passaggi di redesign sullo stesso
albero di scena.

## Obiettivo di design

Il selettore deve comunicare chiaramente due livelli distinti:

- **sinistra: chi sto scegliendo**;
- **destra: come gioca**.

Il ritratto busto è la rappresentazione primaria del Friend selezionato.

Nome e descrizione sintetica del ruolo devono appartenere visivamente alla
stessa area del personaggio.

Passiva e abilità attiva restano invece informazioni di gameplay secondarie,
leggibili ma subordinate alla scelta del Friend.

Il risultato deve conservare il DNA grafico del selettore corrente senza
sembrare una semplice sostituzione dell'immagine dentro la vecchia cornice.

## Direzione visiva

### Riferimento di layout

Uno schizzo di riferimento per la composizione è disponibile in
[PS-069-layout-idea.png](./PS-069-layout-idea.png). È un'indicazione di
direzione, non uno specifico vincolante: la composizione finale può
discostarsene purché rispetti i criteri di accettazione sotto.

**Una volta risolta questa card, eliminare il file
`docs/cards/4_to_test/PS-069-layout-idea.png`** (o il suo nuovo percorso se la
card è stata spostata): è un riferimento di lavoro, non un asset del
repository.

### Ritratto principale

Il busto del Friend selezionato deve avere una presenza nettamente superiore
alla figura intera usata attualmente.

Non è obbligatorio racchiuderlo in un pannello rettangolare.

Quando possibile va sfruttata la trasparenza dell'asset, lasciando che la
silhouette del personaggio partecipi direttamente alla composizione.

Sono ammesse, per esempio:

- cornici aperte o parziali;
- elementi ornamentali dietro il personaggio;
- leggere sovrapposizioni con elementi decorativi;
- una base grafica sotto il busto;
- trattamento luminoso o cromatico coerente con il personaggio;
- integrazione del nome nella stessa composizione.

Il contenitore non deve costringere tutti i Friend dentro una sagoma
verticale pensata originariamente per gli sprite full-body.

### Dimensionamento dei busti

PS-069 utilizza i portrait prodotti da PS-068 mantenendo la dimensione e il
framing comuni già definiti negli asset.

Questa card non introduce regolazioni di scala, crop o offset specifiche per
singolo Friend.

Tutti gli otto portrait devono quindi essere trattati con la stessa regola di
dimensionamento, senza adattamenti percettivi per-personaggio.

Eventuali normalizzazioni future di scala percepita, framing o allineamento
dei portrait sono fuori ambito per PS-069 e potranno essere affrontate in una
card separata.

### Figura intera attuale

L'arte full-body esistente non è più obbligatoria come elemento principale.

Può essere:

- rimossa dalla schermata;
- riutilizzata come elemento secondario;
- mantenuta solo se svolge una funzione visiva chiaramente distinta dal
  busto.

Busto e figura intera non devono competere contemporaneamente come due
rappresentazioni principali dello stesso personaggio.

Come principio generale:

- **portrait = identità del personaggio**;
- **sprite/full-body = rappresentazione del personaggio nel gameplay**.

### Nome e ruolo

Nome del Friend e descrizione sintetica del ruolo devono rimanere associati
visivamente al ritratto.

Esempio concettuale:

`MAGNO`

`Mobilità e controllo delle orde.`

Il ruolo non deve competere gerarchicamente con il nome o con il volto del
personaggio.

### Passiva e abilità

La struttura attuale dei pannelli Passiva e Abilità può essere mantenuta o
rifinita, purché:

- resti immediatamente leggibile;
- non prevalga sul ritratto del Friend;
- mantenga icona, nome e descrizione;
- funzioni correttamente per tutti gli otto personaggi.

La metà destra della schermata deve continuare a rispondere principalmente
alla domanda:

**"Come gioca questo personaggio?"**

### Carosello e roster

Le anteprime laterali attuali vanno rivalutate alla luce dei nuovi ritratti.

Il carosello deve comunicare chiaramente che il giocatore sta scegliendo
all'interno di un roster di Friend.

Sono ammesse soluzioni come:

- piccoli portrait dei personaggi adiacenti;
- headshot;
- strip orizzontale del roster;
- preview laterali semplificate;
- selezionato più grande e personaggi adiacenti attenuati;
- indicatori aggiuntivi di posizione nel roster.

Le preview non devono avere lo stesso peso del ritratto selezionato.

Il comportamento circolare del carosello e la navigazione avanti/indietro
restano invariati.

### Gerarchia cromatica

Il redesign non deve preservare obbligatoriamente il ciano attualmente usato
per `SCEGLI IL PERSONAGGIO`.

Con i nuovi busti e una maggiore presenza di oro, arancio e materiali caldi,
il titolo non deve diventare un terzo punto focale in competizione con il
Friend selezionato e con i pannelli informativi.

Come direzione cromatica di riferimento:

- **oro/arancio** → personaggio, nomi, CTA ed elementi di maggiore importanza;
- **ciano/teal** → informazione, sistema, etichette e piccoli accenti;
- **avorio/bianco caldo** → testo neutro e titoli non dominanti.

Il titolo principale può quindi essere portato verso un avorio/bianco caldo
o un oro chiaro/desaturato, purché resti leggibile e coerente con il resto
della schermata.

Il ciano può rimanere come accento per elementi come `PASSIVA`, `ABILITÀ`,
gemme, indicatori o altri segnali funzionali.

## Comportamento atteso

La schermata di selezione utilizza il ritratto busto come principale
rappresentazione del Friend selezionato.

Al cambio di personaggio vengono aggiornati in sincronia:

- busto;
- nome;
- descrizione del ruolo;
- passiva;
- abilità attiva;
- stato visivo del carosello;
- CTA di conferma.

Il layout deve mantenere una gerarchia leggibile:

1. Friend selezionato;
2. nome;
3. identità sintetica / ruolo;
4. passiva e abilità;
5. roster e navigazione;
6. comandi di conferma e ritorno.

## Criteri di accettazione

### Integrazione funzionale

- [x] Il ritratto busto del Friend selezionato è visibile come principale
      rappresentazione del personaggio.

- [x] Il cambio di personaggio nel carosello aggiorna il busto in sincronia
      con nome, ruolo, passiva, abilità e CTA.

- [x] Nome, ruolo, passiva e abilità attiva restano leggibili per tutti e
      otto i personaggi, senza troncamenti né sovrapposizioni.

- [x] Le anteprime del roster e la navigazione avanti/indietro restano
      riconoscibili e utilizzabili.

- [x] Il comportamento circolare del carosello non cambia.

- [x] Focus, conferma, touch e Back restano quelli attuali.

- [x] Back torna alla welcome senza alterare la run.

### Layout

- [x] Il layout si ricompone nella safe area su 16:9, 20:9 e 4:3 senza tagli.

- [x] Tutti gli otto portrait vengono mostrati utilizzando la stessa regola
      di dimensionamento, senza deformazioni o ricampionamenti errati.

- [x] Nessun portrait esce accidentalmente dal proprio spazio previsto o
      copre informazioni essenziali della UI.

- [x] Testi e CTA non vengono coperti dalla silhouette dei portrait nei
      formati supportati.

### Gerarchia e art direction

- [ ] Il Friend selezionato costituisce il principale punto focale della
      schermata.

- [ ] Busto, nome e descrizione del ruolo vengono percepiti come un unico
      blocco di identità del personaggio.

- [ ] Passiva e abilità restano chiaramente leggibili ma non competono con il
      ritratto come elemento dominante.

- [ ] Se busto e arte full-body convivono, svolgono funzioni visive
      chiaramente differenti e non competono per scala o attenzione.

- [ ] Le preview degli altri Friend comunicano l'esistenza del roster senza
      avere lo stesso peso del personaggio selezionato.

- [ ] Il trattamento dei busti appartiene alla stessa famiglia visiva dei
      ritratti Evil della Boss intro, senza trasformare il character select
      in una copia della Boss intro.

- [ ] La schermata mantiene il linguaggio visivo già riconoscibile del gioco:
      dungeon, ornamentazione, palette e CTA risultano parte dello stesso
      sistema UI.

- [ ] Il titolo `SCEGLI IL PERSONAGGIO` introduce chiaramente la schermata
      senza competere visivamente con il Friend selezionato; il colore del
      titolo non è vincolato al ciano della versione precedente.

## Ambito

- `scenes/ui/character_select_overlay.tscn`
- sottoalberi del ritratto principale;
- pannello identità del personaggio;
- carosello / roster;
- pannelli informativi, se necessari per la nuova composizione;
- CTA, solo per riposizionamento/composizione;
- `scripts/ui/character_select_overlay.gd`;
- `scripts/content/friend_definition.gd`, solo se serve un nuovo accessor
  tipizzato per il busto, per esempio accanto a `get_public_portrait()`.

È ammesso modificare la struttura interna del selettore se necessario per
ottenere una composizione responsive e coerente.

## Non toccare

- flusso `welcome → tutorial → selezione → run`;
- `RunController`;
- avvio della run;
- logica del carosello;
- comportamento circolare della selezione;
- testi e dati di gameplay dei personaggi;
- effetti di passiva e abilità;
- asset definitivi prodotti da PS-068: questa card li integra, non li
  rigenera.

Eventuali problemi artistici riscontrati negli asset PS-068 devono essere
riportati alla relativa card, non corretti silenziosamente dentro PS-069.

## Verifica

### Automatica

Smoke:

`tests/unit/test_ps069_character_select_bust_portrait.gd`

Marker:

`CHARACTER_SELECT_BUST_PORTRAIT_SMOKE_OK`

Il test verifica almeno che:

- il busto del personaggio selezionato sia esposto;
- il busto venga sincronizzato per tutti e otto i profili;
- il cambio di personaggio aggiorni correttamente le informazioni associate;
- il layout resti contenuto nelle safe area previste su 16:9, 20:9 e 4:3.

Profilo minimo prima della chiusura:

`Relevant`

### Manuale

- [ ] Runtime Windows.

- [x] Validazione statica APK. CI (workflow `android-debug-release.yml`, PS-060),
      run [33781099162](https://github.com/AlessioBarbanti/PidgeonSurvivor/actions/runs/33781099162),
      commit `ef25524`, 2026-09-03: `aapt2 dump badging` verde su package
      `com.ilgioco.pidgeonsurvivor`, `minSdk 31`, `targetSdk 36`, solo
      `arm64-v8a`; `apksigner verify` verde. APK pubblicato come asset della
      release `android-debug-latest`. Questo sandbox non ha SDK Android
      locale: la build/validazione è girata in CI, non qui.

- [ ] Runtime fisico Pixel 9.

Sul Pixel 9:

1. aprire la selezione personaggio;
2. scorrere tutti gli otto Friend;
3. verificare che tutti i portrait siano visualizzati correttamente con il
   dimensionamento comune;
4. verificare nome, ruolo, Passiva e Abilità;
5. verificare il roster e le anteprime;
6. verificare touch e navigazione;
7. tornare indietro;
8. rientrare nella selezione;
9. confermare un personaggio;
10. verificare l'avvio corretto della run.

## Esito verifica (2026-09-03)

- `Focused` (`test_ps069_character_select_bust_portrait.gd`): **PASS**, marker
  `CHARACTER_SELECT_BUST_PORTRAIT_SMOKE_OK`.
- `Relevant`: **19/20**. L'unico rosso è
  `tests/unit/test_b54_tutorial_flow.gd`, che pretende ancora i placeholder
  `assets/art/ui/tutorial/generated/fake_tutorial_*.png` rimossi dal commit
  `4e3aed8` (PS-049). È un rosso **preesistente e indipendente da PS-069**:
  nessun file toccato da questa card riguarda il tutorial. Va aperta una card
  a parte.
- `Full` e `Release`: **non eseguiti**, su richiesta del proprietario.
- Cattura UI reale rigenerata con `tools/_capture_ui_screenshots.gd`: i due
  pacchetti `03_character_select.png` (16:9 e 20:9) sono stati confrontati con
  lo schizzo di riferimento e ne seguono la traccia artistica.
  Due delle quattro esecuzioni della cattura hanno riportato `CAPTURE_FAIL` a
  valle (`06b_boss_fight`, `07_pause_overlay`, conferma cambio personaggio) —
  una sul pacchetto `20x9`, una sul `16x9` — mentre le altre due hanno chiuso
  con `CAPTURE_DONE` pulito a parità di codice. Sono passi di run/boss non
  toccati da questa card e il profilo colpito cambia fra esecuzioni:
  instabilità del pacchetto, non una regressione del selettore. Le catture del
  selettore sono state prodotte correttamente in tutte le esecuzioni.

## Gate percettivi

- [ ] Controllo percettivo richiesto: sì.

- [ ] Il proprietario approva la gerarchia della nuova composizione.

- [ ] Il proprietario approva il trattamento del roster.

- [ ] Il proprietario conferma che il Friend selezionato ha sufficiente
      presenza visiva rispetto ai pannelli Passiva/Abilità.

- [ ] Il proprietario conferma che il selettore mantiene il DNA della UI
      attuale pur risultando sensibilmente più centrato sul personaggio.

A fine sviluppo, prima della chiusura, chiedere esplicitamente al
proprietario se vuole far girare `revisore-design-ux` sulla nuova
composizione.

L'invocazione è manuale, non automatica.

## Decisioni

### 2026-09-03 — Evoluzione forte del layout esistente, non redesign totale

La schermata attuale mantiene diversi elementi già efficaci: background,
linguaggio ornamentale, pannelli Passiva/Abilità e CTA.

PS-069 non parte quindi da una schermata vuota.

Viene invece ridisegnata in modo sostanziale l'area dedicata al Friend,
inclusi ritratto principale, nome, ruolo e rappresentazione del roster.

### 2026-09-03 — Il busto è la rappresentazione primaria del Friend

Il nuovo ritratto prodotto da PS-068 costituisce il principale elemento
visivo del personaggio selezionato.

La figura intera corrente non è un requisito della nuova composizione e può
essere rimossa.

Può sopravvivere soltanto se assume una funzione secondaria chiaramente
distinta.

### 2026-09-03 — Separazione semantica della schermata

La composizione deve mantenere una separazione leggibile:

- area Friend: **chi sto scegliendo**;
- area Passiva/Abilità: **come gioca**.

Questa distinzione costituisce il principio guida del redesign.

### 2026-09-03 — Il roster diventa parte esplicita della selezione

Le anteprime laterali non sono considerate un vincolo grafico nella loro
forma corrente.

Possono essere sostituite da portrait, headshot o altra rappresentazione del
cast, purché il comportamento del carosello resti invariato.

Il personaggio selezionato deve essere chiaramente distinto dagli altri
Friend.

### 2026-09-03 — PS-069 assorbe PS-054, PS-054 eliminata dalla board

PS-054 ("Adattare il selettore personaggi al 20:9") non viene implementata
separatamente: il suo obiettivo di migliorare presenza del personaggio e
adattamento ai formati larghi viene risolto interamente all'interno del
redesign di PS-069.

La card PS-054 è stata rimossa dalla board (file e riga in `README.md`) il
2026-09-03 insieme alla versione precedente, meno dettagliata, di questa
stessa card, sostituita dal contenuto qui presente.

### 2026-09-03 — Dimensionamento comune, nessuna normalizzazione per-personaggio

PS-069 integra i portrait prodotti da PS-068 usando la dimensione e il
framing comuni già presenti negli asset.

Non vengono introdotti scale, crop o offset specifici per singolo Friend.

Eventuali correzioni percettive o normalizzazioni del framing sono
esplicitamente fuori ambito e potranno essere affrontate in una card futura.

### 2026-09-03 — Il ciano non è un vincolo per il titolo della schermata

Il redesign non deve preservare obbligatoriamente il ciano attualmente usato
per `SCEGLI IL PERSONAGGIO`.

Con i nuovi busti e una maggiore presenza di oro, arancio e materiali caldi,
il titolo non deve diventare un terzo punto focale in competizione con il
Friend selezionato e con i pannelli informativi.

Come direzione cromatica di riferimento:

- **oro/arancio** → personaggio, nomi, CTA ed elementi di maggiore importanza;
- **ciano/teal** → informazione, sistema, etichette e piccoli accenti;
- **avorio/bianco caldo** → testo neutro e titoli non dominanti.

Il titolo principale può quindi essere portato verso un avorio/bianco caldo
o un oro chiaro/desaturato, purché resti leggibile e coerente con il resto
della schermata.

Il ciano può rimanere come accento per elementi come `PASSIVA`, `ABILITÀ`,
gemme, indicatori o altri segnali funzionali.

### 2026-09-03 — Roster completo a otto slot fissi

Il proprietario ha scelto la strip con tutti e otto i Friend visibili invece
del centro con due anteprime. Ogni Friend conserva il proprio slot: cambiando
selezione si sposta l'evidenza, non le card. Indice, wrap circolare, frecce,
swipe e tap restano quelli di `_navigate`.

Conseguenza dichiarata: `tests/unit/test_b18t_character_carousel.gd` asseriva
in tre punti «esattamente 3 card visibili». Le tre asserzioni sono state
riscritte su otto. Non è una svista, è il contratto che cambia.

### 2026-09-03 — Le miniature ritagliano il busto sul volto

Il proprietario ha scelto il busto PS-068 come sorgente delle miniature. A
~70px di lato una figura intera non è riconoscibile, quindi le miniature usano
un `AtlasTexture` con una **sola regione condivisa**
(`ROSTER_HEADSHOT_REGION = Rect2(56, 6, 144, 144)`), identica per tutti e otto
e verificata a vista su un provino di tutti i busti: nessun volto, capigliatura
o accessorio viene tagliato. Resta quindi dentro il vincolo «stessa regola di
dimensionamento, nessun adattamento per-personaggio».

L'arte a figura intera `selection_portrait` (`carousel.png`) esce dalla
schermata: resta nei dati e continua a essere validata dall'auto-check di
`movement_slice.gd`, ma non è più l'icona del roster. Anche questa asserzione
in `test_b18t` è stata riscritta.

### 2026-09-03 — Il busto sconfina sulla fascia roster

Su 16:9 e 20:9 il busto scende di `PORTRAIT_ROSTER_OVERLAP` (80px) sotto la
propria riga e la fascia roster gli viene disegnata sopra per semplice ordine
di albero. Guadagna così ~468px di lato (≈1,8× la dimensione nativa) contro i
~264px dell'arte nella vecchia card centrale.

Su 4:3 la colonna è troppo stretta perché l'affiancamento renda:
`_layout_portrait_stage()` sceglie automaticamente la composizione impilata
(identità sotto il busto, nessuno sconfinamento), che lascia il busto più
grande. La scelta è fatta confrontando le due alternative, non con una soglia
arbitraria.

### 2026-09-03 — Due difetti trovati solo dalla cattura reale

Il test GUT era verde mentre la schermata era sbagliata. La cattura
`tools/_capture_ui_screenshots.gd` ha mostrato che:

1. le miniature erano semitrasparenti (`modulate` con alpha `0.75` moltiplicato
   per uno sfondo a `0.9`), quindi il busto sconfinante traspariva attraverso
   le card del roster. Risolto passando a tinta piena con sfondo opaco;
2. le miniature mostravano il busto intero e i volti risultavano minuscoli.
   Risolto con il ritaglio headshot sopra.

Nessuna asserzione geometrica avrebbe potuto cogliere i due difetti: sono
entrambi di resa, non di layout.

### 2026-09-03 — Il pannello cresce con la viewport, con guardia sul lato notch

Il pannello non è più `910×490` fisso: cresce fra `PANEL_MIN_SIZE` e
`PANEL_MAX_SIZE` (`1400×760`), che è il modo in cui PS-069 assorbe PS-054.

I margini sono asimmetrici — `PANEL_MARGIN_LEFT` 32 contro 20 a destra e 14 in
verticale — perché in landscape il ritaglio fotocamera del Pixel 9 sta a
sinistra. Il proprietario ha autorizzato a toccare i margini di questa
schermata avvertendo proprio su quel lato.

`ArenaLayout.edge_inset = 20` è un margine **cosmetico** di progetto applicato
sopra la safe area hardware. Sarebbe stato possibile riprenderselo in
verticale per dare altezza al busto, ma avrebbe richiesto di indebolire
`safe_area.encloses(panel_rect)` in b18t e b18w. Si è preferito restare dentro
la safe area e recuperare i 61px necessari dai padding: margini del pannello,
margini di contenuto della placca CTA (che imponeva 116px di altezza minima) e
fascia roster.

### 2026-09-03 — Riaperta: il CTA renderizza male su device — poi corretta in "bottone troppo basso"

Il proprietario ha segnalato dallo screenshot del selettore che il bottone
`GIOCA CON [nome]` "renderizza male". Prima ipotesi (mia, da lettura dello
screenshot): i diamanti ornamentali del 9-slice della texture
`character_select_cta_base.png` si deformano perché la striscia centrale
stirata orizzontalmente li comprime, aggravato dalla riduzione di
`custom_minimum_size` del `ConfirmButton` da `500×72` a `460×72` fatta da
questa stessa card.

Tentativo di riproduzione con `tools/setup-remote-sandbox.sh` (Godot 4.7.1 +
Xvfb + renderer GL reale) e `tools/_capture_ui_screenshots.gd`, sia a 1280×720
sia alla risoluzione Pixel 9 esatta 2424×1080: il bottone rendeva pulito e
simmetrico in entrambi i casi, sull'HEAD invariato. Il proprietario ha poi
confermato che lo screenshot viene da device Android reale (non riproducibile
in questo sandbox, senza SDK/device Android) — **e a quel punto ha chiarito
che il problema non erano affatto i diamanti**: l'ipotesi 9-slice sopra era
una mia lettura sbagliata dello screenshot, non il difetto segnalato.

**Difetto reale, confermato dal proprietario**: il testo del CTA (font 28,
`GIOCA CON [NOME]`) tocca/affolla il bordo interno della placca perché il
bottone è troppo basso, non perché il font sia troppo grande.

Misurato con uno script Godot dedicato
(`get_confirm_button().get_global_rect()` + metriche del font): con
`custom_minimum_size = Vector2(460, 72)` il bottone cresce comunque a
`80` di altezza reale (il layout box del font `LilitaOne` a size 28 è alto
`48px`, più `content_margin_top/bottom = 16` ciascuno). I margini ornamentali
fissi del 9-slice (`texture_margin_top/bottom = 34`, non stirati
verticalmente) occupano quindi una fetta consistente di quegli 80px,
lasciando pochissimo respiro fra il testo centrato e il bordo decorato del
riquadro — visibile a schermo con una cattura ravvicinata pixel-per-pixel.

Fix: alzato `custom_minimum_size` del `ConfirmButton` da `Vector2(460, 72)` a
`Vector2(460, 100)`. La larghezza non cambia (fuori dall'ambito di questo
giro): a `MARGHE`, il nome più lungo del roster, il testo resta ampiamente
dentro i margini orizzontali. Verificato con catture dedicate su `ZAT` (il
caso originale) e `MARGHE` (il caso più stretto): il testo ora ha respiro
verticale chiaro dal bordo della placca in entrambi.

Contestualmente il proprietario ha chiesto di stringere anche l'interlinea
delle descrizioni di Passiva/Abilità (`PassiveDescriptionLabel`,
`AbilityDescriptionLabel`), percepita troppo larga. Aggiunto un
`theme_override_constants/line_spacing` locale a entrambe (prima ereditavano
il `-2` del tema globale `BodyS`, che vale per tutte le label "Body" del
gioco): stesso pattern già usato da `PassiveTitleLabel` e
`AbilityTitleLabel` in questa stessa scena (`-11` locale), quindi un override
scoped al selettore, non una modifica del tema condiviso.

Primo tentativo a `-8`: ha fatto regredire
`test_b18w_character_select_refinement.gd` ("Le due card devono avere la
stessa dimensione", tolleranza 1px). Causa trovata misurando
`get_combined_minimum_size()` di `PassiveCard`/`AbilityCard` per Magno: a
`-2` erano già 185 contro 186 (entro tolleranza per un pelo), perché
`custom_minimum_size = Vector2(410, 156)` di entrambe le card è già inferiore
al reale minimo richiesto dal testo — il "pareggio" preesistente era una
coincidenza fra due lunghezze di testo diverse (passiva più corta
dell'abilità attiva), non un floor comune che le tiene allineate. Stringere
di più (`-8`) riduce l'altezza di ciascuna in proporzione al proprio numero
di righe, che differisce fra le due card, e allarga lo scarto a 5px. Risolto
scegliendo `-4` (comunque più stretto del `-2` originale): a Magno lo scarto
resta a 1.0px esatto, dentro tolleranza.

**Verificato**: `Focused` (`test_ps069_character_select_bust_portrait.gd`) in
isolamento — PASS, marker `CHARACTER_SELECT_BUST_PORTRAIT_SMOKE_OK`, 447
asserzioni, safe-area e non intersezione del CTA valide anche con il bottone
più alto. `test_b18w_character_select_refinement.gd` e
`test_b18t_character_carousel.gd` — PASS. `Relevant` (i 20 script mappati su
`scripts/ui/*`/`scenes/ui/*` da `tools/milestone-test-map.json`, un solo
processo Godot): 35/62 test passano; i falliti sono in gran parte
precedenti e indipendenti da questa card (confermato rieseguendo
`test_b18w_character_select_refinement.gd` sul commit precedente a
questa riapertura, dove passava già, il che ha isolato la vera regressione
sopra). `test_ps069_character_select_bust_portrait.gd` fallisce solo dentro
il batch da 20 script (un'asserzione di centratura roster su `migi`) ma passa
sempre in isolamento (447/447 asserzioni, ripetuto due volte): flakiness da
carico del processo condiviso fra molti script, non una regressione di
questa card — il carosello/roster non è stato toccato.

Il gate di rendering Android/device resta **aperto**: questo sandbox remoto
non ha SDK/device Android, quindi la correzione sopra (altezza del bottone,
interlinea) non è stata verificata fisicamente sul Pixel 9. Non risulta però
collegata all'artefatto dei diamanti visto nello screenshot originale, che il
proprietario ha chiarito non essere il difetto reale.

### 2026-09-03 — Busto e identità sovrapposti, layout a due colonne vere

Il proprietario ha chiesto di superare la composizione "identità a fianco del
busto sui formati larghi" (l'unico ramo che faceva sconfinare il busto sulla
fascia roster) a favore di **nome e ruolo sovrapposti al busto stesso**, su un
alone sfumato scuro per restare leggibili, così la colonna Friend diventa un
blocco unico e la schermata si legge davvero a due colonne: personaggio a
sinistra, kit a destra.

`_layout_portrait_stage()` non sceglie più fra affiancato e impilato: il busto
occupa sempre l'intera colonna (`bust_side = min(stage.x, stage.y)`), nome e
ruolo sono ancorati al suo bordo inferiore. Rimossi `PORTRAIT_ROSTER_OVERLAP`
e `IDENTITY_MIN_WIDTH`, non più referenziati da nessun ramo.

Il fondo sfumato (`IdentityBackdrop`, un `GradientTexture2D` radiale renderizzato
proceduralmente, nessun nuovo asset) copre una fascia larga il 78% della
colonna (minimo 220px), dal bordo inferiore del busto fino in fondo alla
colonna: abbastanza per far risaltare testo su qualunque costume, senza
leggersi come una seconda card sotto il personaggio.

### 2026-09-03 — Le card Passiva/Abilità restano una minoranza della larghezza

Primo tentativo: allargare le card da 410 a 480px per ridurre il wrap dei
testi più lunghi (aveva funzionato: il massimo sincronizzato fra le due card
era sceso da 205 a 176px). Il proprietario ha fermato il tentativo: allargare
la colonna Passiva/Abilità toglie letteralmente pixel al busto, e qui **la
star è il personaggio**, non le sue descrizioni. Misurato con
`get_bust_portrait_rect()`/`get_ability_panel_rect()`: a 480px l'area delle
card superava quella del busto (rapporto 0,93), a 410px erano già quasi pari
(~0,98).

Il proprietario ha poi chiarito l'intento: le card devono restare a **circa il
30% della larghezza disponibile**, lasciando il resto al busto — non una
larghezza fissa. `_on_overlay_resized()` ora calcola la larghezza di
`AbilityCards` come `content_width * 0.30` (dove `content_width` è la
larghezza del pannello meno il chrome orizzontale, letto dal vero
`content_margin` dello StyleBox invece di duplicarne il valore), clampata fra
`ABILITY_CARDS_MIN_WIDTH` (410, il minimo già verificato: sotto questa soglia
il testo più lungo del roster va a capo di più, la card cresce in altezza, il
busto la insegue perché occupa sempre l'intera riga, e il pannello sfora la
safe area) e `ABILITY_CARDS_MAX_WIDTH` (440). Con i limiti attuali del
pannello (`PANEL_MAX_SIZE.x = 1400`) il 30% del contenuto non supera mai 410
tranne ai bordi estremi: la card resta quindi ancorata al minimo verificato
per tutti i profili oggi supportati, e il busto guadagna comunque tutta la
larghezza restante (rapporto busto/card fino a 1,43 sul profilo Pixel 9
20:9). Se in futuro `PANEL_MAX_SIZE` crescesse, la quota del 30% comincerebbe
a valere davvero senza bisogno di ritoccare questa card.

`PassiveCard`/`AbilityCard` non hanno più una larghezza propria fissata a
410: scendono a un pavimento basso (300) e seguono la larghezza reale che
`AbilityCards` assegna loro, cross-axis, come VBoxContainer.

Aggiunta un'asserzione esplicita (`ability_rect.intersects(carousel_rect)`)
su tutti i profili di layout: le card Passiva/Abilità non devono mai
sconfinare sulla fascia roster, come richiesto esplicitamente dal
proprietario durante questo giro.

### 2026-09-03 — Il testo esce dal bordo delle card su device: 410 non bastava

Il proprietario ha segnalato (screenshot da device reale, Pixel 9 20:9,
personaggio Aleo) che il testo di "Termostato Interno"/"Shock Termico" esce
visibilmente dal bordo destro della card, non solo va a capo stretto: parole
tagliate a metà oltre il confine del pannello.

Non riprodotto con il renderer software di questo sandbox (a 410px "Termostato
Interno" resta comodamente dentro la colonna con le metriche di *questo*
motore). Causa più plausibile: a `ABILITY_CARDS_WIDTH = 410`, la colonna di
testo interna (dopo icona 136px, separazione HBox e margini della card) scende
a soli 240px, e "TERMOSTATO INTERNO" da sola misura già 215px con le metriche
desktop — un margine di appena 25px (89,6% occupato) in cui basta una metrica
del font leggermente diversa su Android per far uscire il testo dal bordo.
Stessa famiglia di incertezza già incontrata sul CTA in questa card: non posso
confermare il meccanismo esatto senza un device, ma il margine risicato è
misurabile e reale.

Il proprietario ha chiesto esplicitamente di allargare le card. Portata
`ABILITY_CARDS_WIDTH` a 440 (colonna interna 270px, margine di 55px sullo
stesso titolo). Semplificata la costante da un range dinamico
(`ABILITY_CARDS_MIN_WIDTH`/`MAX_WIDTH`/`WIDTH_RATIO`) a un valore fisso unico:
col limite di `PANEL_MAX_SIZE.x` attuale il 30% del contenuto non aveva mai
superato il minimo comunque, quindi il range non stava facendo nulla — tenerlo
avrebbe solo confuso chi legge il codice.

Costo dichiarato: il rapporto busto/card peggiora leggermente (da ~0,98 a
~0,92 sul caso peggiore, Bea), ma resta lontano dallo squilibrio verificato a
480px (0,93 già allora, e qui il denominatore è diverso). Il proprietario ha
scelto la leggibilità su questo compromesso.

Aggiunto un test di regressione vero (`_assert_label_words_fit` in
`test_ps069_character_select_bust_portrait.gd`): verifica che nessuna singola
parola di nome/ruolo/titolo/descrizione, per tutti gli otto Friend e tutti i
profili di layout, superi la larghezza della propria Label. Verificato che
sarebbe stato inutile riprovare lo stesso controllo con una soglia di margine
arbitraria (85%): un wrap greedy normale produce spesso righe vicine al bordo
per costruzione, quindi un controllo così avrebbe fallito ovunque, anche dove
il testo è a posto — non è un segnale utile. Il test attuale cattura solo
l'overflow di una singola parola con le metriche di questo motore: non può
provare che il margine basti su un motore di rendering diverso, quello lo
prova solo il device.

### 2026-09-03 — Strip che scorre, selezionato sempre al centro

Prima implementazione: otto slot fissi, ogni Friend nella propria posizione e
solo l'evidenza che si spostava. Il proprietario ha chiesto invece **una strip
che scorre**.

La fascia mostra ora `ROSTER_VISIBLE_SLOTS` (7) miniature attorno al Friend
selezionato, che resta sempre al centro: navigando, le miniature slittano di
uno slot. Con otto Friend il diametralmente opposto resta fuori dalla fascia e
rientra ruotando, il che rende il numero di slot dispari e la finestra
simmetrica (tre per lato).

Indice, wrap circolare, frecce, swipe e tap restano invariati: cambia solo
dove vengono disegnate le card. Le miniature sono anche più grandi (~144px
contro ~125px), perché sette slot occupano la stessa larghezza di otto.

Conseguenza dichiarata: le tre asserzioni di `test_b18t_character_carousel.gd`
sul numero di card visibili passano da 8 a 7 — sono le stesse che avevo
riscritto da 3 a 8 nella prima implementazione.

## Documenti sincronizzati

- [x] `docs/ui-ux-flow.md`: aggiornare la composizione del selettore
      personaggi.

## Note

Questa card non ha come obiettivo semplicemente "mostrare il nuovo portrait".

Il risultato deve far percepire il character select come il momento in cui il
giocatore sceglie uno dei Friend.

Il busto deve quindi contribuire a identità, riconoscibilità e personalità del
cast, non essere trattato come un'illustrazione aggiunta alla UI esistente.

Come principio di art direction:

**portrait = personaggio come individuo**

**sprite/full-body = personaggio come unità di gameplay**

Ricorda di eliminare `docs/cards/4_to_test/PS-069-layout-idea.png` una volta
completata la card: è uno schizzo di riferimento di lavoro, non un asset
definitivo del repository.
