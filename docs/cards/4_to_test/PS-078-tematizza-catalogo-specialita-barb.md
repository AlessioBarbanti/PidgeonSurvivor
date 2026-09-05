---
id: PS-078
titolo: Tematizza le Specialità di Barb come pezzi di carne alla griglia
tipo: art
area: arte
stato: IN VERIFICA
priorita: media
dipende_da: [PS-077]
origine:
creato: 2026-09-02
aggiornato: 2026-09-05
---

# PS-078 — Tematizza le Specialità di Barb come pezzi di carne alla griglia

## Contesto

[docs/powerup-catalog.md](../powerup-catalog.md) dichiara già la direzione
visiva comune del catalogo upgrade: **grigliatori** — carne, utensili da
barbecue, pirofile, brace, condimenti, oggetti da cucina, mai piccioni come
soggetto dei powerup positivi. Le carte statistiche ordinarie la seguono già
(`A Tutta Brace!`, `Pinza Lunga`, `Il condimento di Barb`, `Forchettone da
Braciere`, ecc.).

Le Specialità di Barb non hanno mai ricevuto questo trattamento. Nomi e
icone restano un linguaggio generico da upgrade d'arma/abilità, scollegato
dall'identità di Barb come grigliatore che premia il Player con un "pezzo
speciale" dopo ogni Boss: `Gossip`, `Colpo Perforante`, `Raffica Doppia`,
`Esplosione Finale`, e — dopo
[PS-077](../5_completed/PS-077-espandi-pool-specialita-barb.md) — anche `L'Ansia`,
`Birre di classe di Lollo`, `Ritardo Cronico`, `Non Ho Tempo Per Questo`.
Le icone attuali di queste ultime quattro (`anxiety.png`, `beer.png`,
`chronic_delay.png`, `no_time.png`) non appartengono al linguaggio visivo
grigliatore già stabilito per il resto del catalogo.

La finzione che regge la ricompensa la rende più precisa di un generico
"tema barbecue". Barb è il grigliatore, e il Boss è la minaccia da cui il
Player lo difende: mentre il Player regge lo scontro, Barb ha il tempo di
cucinare. Quello che consegna alla fine non è un attrezzo né un condimento —
è **un pezzo di carne**, la sua specialità, cotta apposta. Le sette Specialità
sono quindi tutte tagli e pezzi di carne alla griglia, ed è esattamente
questo a distinguerle a colpo d'occhio dal catalogo statistico ordinario, che
resta sul registro più largo di utensili, pirofile, brace e condimenti.

## Comportamento atteso

Ognuna delle sette Specialità si presenta come un pezzo di carne alla griglia
cucinato da Barb: nome, descrizione e icona di un taglio riconoscibile,
coerenti con l'identità grigliatore già stabilita per il resto del catalogo,
senza alterare l'effetto meccanico che rappresentano.

## Criteri di accettazione

- [x] Ognuna delle sette Specialità ha per nome un pezzo di carne alla
      griglia — un taglio o una preparazione riconoscibile, non un utensile
      e non un condimento — mantenendo leggibile a colpo d'occhio l'effetto
      rappresentato.
- [x] I sette nomi non si ripetono e non si sovrappongono ai nomi già usati
      dal catalogo statistico ordinario (`A Tutta Brace!`, `Pinza Lunga`,
      `Il condimento di Barb`, `Forchettone da Braciere`, ecc.).
- [x] Ogni Specialità ha una nuova icona che raffigura quel pezzo di carne,
      coerente con la direzione visiva dichiarata in
      `docs/powerup-catalog.md` (nessun piccione come soggetto principale,
      stile pixel-art già stabilito nel resto del catalogo).
- [ ] Le sette icone si leggono come una famiglia: un menù di tagli diversi
      dello stesso grigliatore, non sette illustrazioni scollegate.
- [x] `effect_id`, `effect_parameters`, `weight`, `max_rank` e ogni altro
      dato meccanico restano bit-per-bit identici: la card cambia solo
      identità (`title`, `description`, `effect_summary`, `icon`), mai
      gameplay. Scrivere questi quattro campi sui sette `.tres` già
      esistenti (nessun nuovo componente, scena o registry) è l'unica
      integrazione di questa card, esplicitamente ammessa come eccezione
      "banale" alla regola generale di PS-090 — vedi Decisioni.
- [ ] Le sette Specialità restano distinguibili fra loro e dagli upgrade
      statistici ordinari già tematizzati, senza sovrapposizioni semantiche
      (stesso principio già dichiarato per le due pirofile in
      `powerup-catalog.md`).
- [x] Le nuove icone hanno una riga nell'`ASSET-MANIFEST.md` pertinente con
      origine, autore/licenza, trasformazioni e hash SHA-256.
- [x] `BarbRewardOverlay` (PS-036) mostra correttamente i nuovi nomi e le
      nuove icone senza modifiche al proprio layout o alla propria logica.

## Ambito

- `data/upgrades/specialities/*.tres` (le sette definizioni tematizzate:
  `title`, `description`, `effect_summary`, `icon`).
- `assets/art/icons/upgrades/` per le nuove icone, con relativo
  `ASSET-MANIFEST.md`.

Non toccare:

- `effect_id`, `effect_parameters`, `weight`, `max_rank`, `tags` meccanici;
- layout e logica di `BarbRewardOverlay` (contratto PS-036);
- `UpgradeService`, `UpgradeRegistry` e la logica di sblocco
  (contratti PS-012/PS-077);
- il catalogo upgrade ordinario: `docs/powerup-catalog.md` resta la fonte
  per quel catalogo e non viene duplicato qui.

## Verifica

- Smoke: `tests/unit/test_ps078_barb_speciality_theming.gd` → marker
  `BARB_SPECIALITY_THEMING_SMOKE_OK` — verifica che `effect_id`,
  `effect_parameters`, `weight` e `max_rank` restino identici ai valori
  pre-restyle mentre `title`/`description`/`icon` cambiano, e che
  `BarbRewardOverlay` risolva le nuove icone senza riferimenti nulli.
- Profilo minimo prima della chiusura: `Relevant`.

**Eseguita il 5 settembre 2026.**
`run-milestone-checks.ps1 -Milestone PS-078 -Profile Relevant -FocusedSmoke
tests/unit/test_ps078_barb_speciality_theming.gd` →
`status=PASS focused=1/1 regression=10/10 steps=11/11`, log
`20260905-163654-PS-078`, nessun `SCRIPT ERROR` né `FATAL EXCEPTION`, marker
`BARB_SPECIALITY_THEMING_SMOKE_OK` e `ORDINARY_CATALOG_MEAT_AUDIT_SMOKE_OK`
presenti. Le dieci regressioni includono `test_b41_weapon_shapes.gd` (le tre
icone sostituite), `test_ps012_barb_specialities.gd`,
`test_ps077_barb_speciality_pool_expansion.gd` e
`test_ps089_ordinary_catalog_meat_audit.gd`.

Il primo giro era `FAIL` per un difetto del test, non del gioco: l'asserzione
sul titolo mostrato confrontava `Hamburger` con `HAMBURGER`, mentre la carta
stampa il titolo in maiuscolo per scelta di layout di PS-047. Corretta
l'asserzione, non la UI.

**Rieseguita dopo la rigenerazione di `Alette`**, con `-RefreshEditor` perché
il derivato ha lo stesso nome file e contenuto nuovo:
`status=PASS focused=1/1 regression=10/10 steps=12/12`, log
`20260905-193609-PS-078`, nessun `SCRIPT ERROR` né `FATAL EXCEPTION`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: apri la schermata Barb con le nuove
      Specialità, verifica leggibilità di nome e icona a dimensione reale
- [ ] Controllo percettivo richiesto: sì — le sette icone devono leggersi come
      sette pezzi di carne distinti dello stesso menù, riconoscibili l'uno
      dall'altro a dimensione carta, non come restyle cosmetico casuale
- [x] Approvazione del proprietario sui nomi prima di generare le
      icone: il nome decide il soggetto del disegno, rifarlo dopo costa una
      seconda generazione — concessa il 5 settembre 2026, vedi Decisioni

## Decisioni

- **2026-09-05 — `Alette` rigenerata: la coscia è già il pickup della vita.**
  La prima versione raffigurava cosce con osso sporgente invece di ali. Il
  `game-art-designer` l'aveva segnalata come riserva minore e accettata; il
  proprietario l'ha bocciata portando la ragione decisiva, che non era nota a
  nessuno dei due al momento della generazione: **il pickup della vita
  (`assets/art/pickups/generated/health_pickup.png`) è esattamente una coscia
  di pollo**. Non era quindi solo il taglio sbagliato rispetto al nome, ma una
  collisione di leggibilità con un elemento che il giocatore impara a
  riconoscere a colpo d'occhio come "vita": un upgrade non deve mai somigliare
  a un pickup. Rigenerata in place, stessi nomi file e wiring invariato: tre
  cunei piatti col gomito a vista, nessun osso esposto, ancora divergenti per
  raccontare la dispersione. Conseguenza durevole oltre questa card: il
  soggetto "coscia di pollo" è occupato dal pickup vita e non è disponibile
  per nessuna icona di upgrade.
- **2026-09-05 — I sette derivati orfani sono stati rimossi.** `beer.png`,
  `chronic_delay.png`, `no_time.png`, `gossip.png`, `death_burst.png`,
  `double_barrel.png` e `piercing_rounds.png` non erano più referenziati da
  nessun `.tres`, `.tscn`, `.gd` e sarebbero comunque finiti negli export.
  Rimossi con i rispettivi `.import`. `anxiety.png` resta: quella carta è
  materia di PS-100. I master storici in `hd/` restano come evidenza, esclusi
  da import ed export dal `.gdignore` già presente.
- **2026-09-05 — Da otto a sette: `L'Ansia` esce dal gioco, non viene
  rinominata.** Mentre si approvavano i nomi il proprietario ha deciso che la
  carta non gli piace e va rimossa dal pool. La rimozione tocca
  `UpgradeEffectRegistry`, la lista di definizioni di `movement_slice.gd` e
  cinque suite di regressione: è gameplay, non identità, quindi è stata aperta
  [PS-100](../2_to_do/PS-100-rimuovi-ansia-dalle-specialita-di-barb.md) invece
  di allargare questa card. PS-078 tematizza le sette Specialità rimaste e non
  produce alcuna icona per `anxiety_signature`, che resta com'è finché PS-100
  non la elimina. Le due card sono indipendenti: nessuna blocca l'altra.
- **2026-09-05 — Vincolo stretto: solo cotture alla griglia.** Il primo set a
  menù secco proponeva `Straccetti`, `Polpette` e `Stracotto`; il proprietario
  li ha bocciati perché si cuociono in padella o in pentola, non sulla brace.
  Il criterio non è quindi "carne" ma "carne che finisce sulla griglia", ed è
  il filtro che ha scartato anche le alternative in umido.
- **2026-09-05 — I sette nomi definitivi, approvati dal proprietario.**
  `Alette` (`beer_signature`), `Costine` (`chronic_delay`), `Hamburger`
  (`damage_shockwave`), `Fiorentina` (`death_burst`), `Tagliata`
  (`double_barrel`), `Salsiccia` (`gossip_projectiles`), `Arrosticini`
  (`piercing_rounds`). L'abbinamento non è decorativo: ogni taglio è stato
  scelto perché la sua cottura racconta l'effetto — le costine sono la cottura
  lenta, l'hamburger si schiaccia sulla piastra come l'onda d'urto, la
  tagliata è il pezzo che arriva già diviso in fette, la salsiccia a nodi è
  una catena, l'arrosticino infilza bocconi in fila. `Tagliata` è stata
  spostata su `double_barrel` per richiesta esplicita del proprietario
  ("la vedo meglio come proiettile diviso"), e questo ha liberato `Alette`
  per `beer_signature`, eliminando l'unica sovrapposizione rimasta del set
  precedente (due insaccati, `Wurstel` e `Salsiccia`).
- **2026-09-05 — Registro approvato: menù secco, un taglio per nome.**
  Al proprietario è stato sottoposto un primo set con taglio più qualificatore
  (`Straccetti Nervosi`, `Alette Brille di Lollo`, ...) e ha chiesto di
  ripensare l'intero registro. Fra tre direzioni alternative — sagra di paese
  con carne popolare, menù secco a una parola, battuta conservata con la carne
  spostata su icona e descrizione — ha scelto il **menù secco**: il nome è il
  solo taglio, senza aggettivi, come una lavagna del grigliatore. Gli otto
  nomi approvati sono quindi `Straccetti`, `Alette`, `Stracotto`, `Salsiccia`,
  `Fiorentina`, `Costine`, `Polpette`, `Arrosticini`. Conseguenza operativa:
  la leggibilità dell'effetto non può più appoggiarsi al titolo, quindi
  `description` ed `effect_summary` restano invariati nel contenuto meccanico
  e diventano l'unico veicolo testuale dell'effetto; il tema vive in titolo e
  icona.
- **2026-09-05 — Le icone prendono nomi file nuovi, i vecchi derivati
  spariscono.** I derivati runtime storici (`anxiety.png`, `beer.png`,
  `chronic_delay.png`, `no_time.png`, `gossip.png`, `death_burst.png`,
  `double_barrel.png`, `piercing_rounds.png`) portano il nome dell'effetto o
  della battuta precedente e non descrivono più il soggetto. I nuovi derivati
  prendono il nome del taglio; i vecchi vengono rimossi da `generated/`
  perché resterebbero orfani ed entrerebbero comunque negli export. Le righe
  storiche di manifest restano come evidenza, marcate come superate.
- **2026-09-05 — `test_b41_weapon_shapes.gd` va riallineato.** Il test B41
  fissa percorso e SHA-256 delle icone di `piercing_rounds`, `double_barrel`
  e `death_burst`: la sostituzione delle icone lo rompe per costruzione.
  L'intento del test (le tre Specialità hanno un'icona dedicata 128×128
  registrata nel manifest) resta valido e viene conservato; cambiano solo
  file e hash attesi. Non è un allargamento d'ambito ma la manutenzione
  obbligata di una regressione esistente.
- **2026-09-04 — Il tema è "pezzo di carne", non "barbecue" in generale.**
  Richiesta esplicita del proprietario, con la sua motivazione narrativa: il
  Player difende Barb dal Boss, Barb ne approfitta per cucinare e consegna la
  sua specialità, cioè un pezzo di carne. Il criterio passa quindi da
  "coerente col mondo grigliatore" (che ammetteva anche utensili e
  condimenti) a "è un taglio di carne alla griglia", che è più stretto e
  rende le otto carte immediatamente distinguibili dal catalogo ordinario.
- **2026-09-04 — Il catalogo statistico ordinario non viene rinominato.**
  Confermato dal proprietario: le Specialità di Barb sono pezzi di carne, le
  altre carte restano a tema ma non sono carne — forchettone, condimento,
  pinza, pirofila. Sono due registri distinti dentro lo stesso mondo
  grigliatore, ed è proprio quel contrasto a far leggere una Specialità come
  "il pezzo speciale" invece che come l'ennesimo attrezzo. La divisione è
  anche il criterio anti-collisione: se un nome di questa card potesse stare
  nel catalogo ordinario, non è abbastanza "carne".
- **2026-09-04 — Rivista contro PS-090, resta card singola.**
  [PS-090](./PS-090-separa-generazione-integrazione-card-art.md) impone di
  default due card collegate quando una richiesta implica sia generare arte
  sia usarla in gioco, con l'eccezione esplicita del lavoro di integrazione
  "banale a sufficienza da restare un singolo criterio di accettazione
  marcato come tale". Qui l'integrazione si riduce a scrivere quattro campi
  di identità (`title`, `description`, `effect_summary`, `icon`) su otto
  `.tres` già esistenti — nessun nuovo componente, scena, registry o
  modifica a `BarbRewardOverlay` — quindi resta dentro questa card invece di
  aprire sette card di wiring separate. Il criterio di accettazione
  corrispondente è stato marcato esplicitamente come tale.
- **2026-09-04 — Sbloccata.** PS-077 è entrata in `4_to_test/` con stato
  `IN VERIFICA`: la regola di dipendenza della board è soddisfatta e questa
  card passa a `PRONTO`.
- **2026-09-04 — Possibile nona Specialità in arrivo.**
  [PS-094](../2_to_do/PS-094-specialita-cariche-abilita-attiva.md) propone
  una nuova Specialità (cariche multiple per l'abilità attiva). Se PS-094
  viene presa in carico prima che questa card sia chiusa, il proprio
  criterio la obbliga ad aggiornare questa card da "otto" a "nove"
  Specialità invece di aprire un secondo passaggio di tematizzazione.
- **2026-09-02 — Bloccata da PS-077.** PS-077 era ancora `PRONTO`, non aveva
  raggiunto `IN VERIFICA`: la card è restata `BLOCCATO` fino a quel momento,
  coerente con la regola di dipendenza della board.
- **2026-09-02 — Card `art`: delega a `game-art-designer`.** Richiede nuove
  icone generate, non solo adattamento di arte esistente; per contratto di
  board (`docs/cards/README.md`) va delegata all'agente Game Art Designer,
  non implementata direttamente da `card-risolvi`.
- **2026-09-02 — Dipende da PS-077.** Copre le sette Specialità risultanti
  dall'espansione del pool; tematizzare solo le quattro attuali richiederebbe
  un secondo passaggio quando arrivano le altre quattro.
- **2026-09-02 — Nessun nuovo effetto o rank.** Stesso principio già
  dichiarato da PS-012 ("il loro design gameplay non deve essere
  modificato"): qui si applica a identità invece che a meccanica di
  sblocco.

## Documenti sincronizzati

- [x] `docs/prd.md`: il contratto elencava le Specialità per titolo, quindi la
      rinomina lo rendeva falso. La lista ora riporta i sette tagli con
      l'effetto accanto, dichiara il registro riservato e segnala che `L'Ansia`
      resta nel pool finché non la rimuove PS-100. La sezione "Idee per i
      potenziamenti" conserva i titoli originali come storia del design, con
      una nota che rimanda al contratto.
- [x] `tests/unit/test_ps089_ordinary_catalog_meat_audit.gd`: la lista di
      parole vietate al catalogo ordinario è stata estesa con `alette`,
      `costine`, `fiorentina` e `arrosticini`, come chiedeva il commento del
      test stesso. Senza questa estensione la separazione fra i due registri
      sarebbe rimasta dichiarata ma non verificata.
- [x] `docs/powerup-catalog.md`: il proprietario ha chiesto di documentarle lì.
      Aggiunta la sezione "I due registri del catalogo", che dichiara la
      separazione fra carte ordinarie (utensili, pirofile, brace, condimenti) e
      Specialità (tagli alla griglia), elenca i sette nomi con l'effetto e la
      ragione del taglio, e registra due conseguenze operative: il test PS-089
      che fa da guardia alla separazione, e il fatto che le proposte non
      implementate `Pancetta Croccante` e `Spiedo Passante` la violano e vanno
      rinominate prima di diventare carte runtime.

## Note

Se in fase di implementazione il nuovo nome di una carta rendesse l'effetto
meno leggibile rispetto a oggi, va preferita la leggibilità: segnalarlo
invece di forzare un titolo a effetto ma ambiguo. Il vincolo "pezzo di carne"
riguarda il soggetto, non impedisce di qualificarlo: un taglio più una parola
che punta all'effetto resta dentro il tema e mantiene la carta leggibile.

**Superata dalle Decisioni del 5 settembre 2026.** La tabella qui sotto è la
prima ipotesi di soggetti, scritta quando la card è stata aperta e mai
approvata: resta come evidenza di cosa era stato considerato. I nomi
effettivi, approvati dal proprietario, sono i sette elencati in `Decisioni`, e
tre dei candidati storici (`Straccetti`, `Stracotto`, la salsiccia come
soggetto dell'onda d'urto) sono stati esplicitamente bocciati perché non si
cuociono sulla griglia o perché il taglio è stato riassegnato a un altro
effetto.

| Specialità (ID) | Effetto | Candidato taglio/preparazione |
|---|---|---|
| `anxiety_signature` | +velocità, -vita max, bordi offuscati | Straccetti (striscioline sottili e nervose: "ansia" = agitazione) |
| `beer_signature` | +cadenza, dispersione del colpo | Spiedini "alticci" (leggermente storti/sbandati, come dopo una birra) |
| `chronic_delay` | rallenta i nemici a intervalli | Stracotto (cottura lenta: "ritardo cronico" come pun letterale) |
| `damage_shockwave` | onda d'urto quando Barb subisce danno | Salsiccia scoppiettante (che sfrigola/scoppietta sulla brace) |
| `weapon_death_burst` | esplosione alla morte del nemico | Costata flambé (fiammata finale, letterale) |
| `weapon_multishot` | proiettili aggiuntivi a ventaglio | Doppio spiedino (due pezzi affiancati) |
| `gossip_projectiles` | rimbalzi in catena fra nemici | Salsicce a catena (i link fisici = il rimbalzo che "passa parola") |
| `weapon_pierce` | il colpo attraversa più bersagli | Spiedone trafiggente (attraversa più pezzi infilzati) |

Prompt di generazione di base (da adattare per soggetto e ripetere per le
otto varianti, mantenendo identica l'impostazione per la coerenza di
famiglia richiesta dai criteri):

> Pixel-art icon, 128×128, game upgrade card icon for a backyard-grill
> survivor game, part of an eight-icon "chef's specialities" family handed
> out by the grill master character after defeating a boss. Subject:
> [candidato taglio/preparazione], freshly grilled/cooked, presented as a
> single hero cut on a plate or skewer with warm embers/smoke accents.
> Clean readable silhouette at small size, thick outline, flat cel-shaded
> pixel art matching an established barbecue visual family (same palette,
> outline weight and lighting as the other seven). No pigeons. Centered
> composition, transparent background.
