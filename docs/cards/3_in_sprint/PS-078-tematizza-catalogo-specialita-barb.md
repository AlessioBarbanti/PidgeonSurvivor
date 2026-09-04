---
id: PS-078
titolo: Tematizza le Specialità di Barb come pezzi di carne alla griglia
tipo: art
area: arte
stato: PRONTO
priorita: media
dipende_da: [PS-077]
origine:
creato: 2026-09-02
aggiornato: 2026-09-04
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
è **un pezzo di carne**, la sua specialità, cotta apposta. Le otto Specialità
sono quindi tutte tagli e pezzi di carne alla griglia, ed è esattamente
questo a distinguerle a colpo d'occhio dal catalogo statistico ordinario, che
resta sul registro più largo di utensili, pirofile, brace e condimenti.

## Comportamento atteso

Ognuna delle otto Specialità si presenta come un pezzo di carne alla griglia
cucinato da Barb: nome, descrizione e icona di un taglio riconoscibile,
coerenti con l'identità grigliatore già stabilita per il resto del catalogo,
senza alterare l'effetto meccanico che rappresentano.

## Criteri di accettazione

- [ ] Ognuna delle otto Specialità ha per nome un pezzo di carne alla
      griglia — un taglio o una preparazione riconoscibile, non un utensile
      e non un condimento — mantenendo leggibile a colpo d'occhio l'effetto
      rappresentato.
- [ ] Gli otto nomi non si ripetono e non si sovrappongono ai nomi già usati
      dal catalogo statistico ordinario (`A Tutta Brace!`, `Pinza Lunga`,
      `Il condimento di Barb`, `Forchettone da Braciere`, ecc.).
- [ ] Ogni Specialità ha una nuova icona che raffigura quel pezzo di carne,
      coerente con la direzione visiva dichiarata in
      `docs/powerup-catalog.md` (nessun piccione come soggetto principale,
      stile pixel-art già stabilito nel resto del catalogo).
- [ ] Le otto icone si leggono come una famiglia: un menù di tagli diversi
      dello stesso grigliatore, non otto illustrazioni scollegate.
- [ ] `effect_id`, `effect_parameters`, `weight`, `max_rank` e ogni altro
      dato meccanico restano bit-per-bit identici: la card cambia solo
      identità (`title`, `description`, `effect_summary`, `icon`), mai
      gameplay. Scrivere questi quattro campi sugli otto `.tres` già
      esistenti (nessun nuovo componente, scena o registry) è l'unica
      integrazione di questa card, esplicitamente ammessa come eccezione
      "banale" alla regola generale di PS-090 — vedi Decisioni.
- [ ] Le otto Specialità restano distinguibili fra loro e dagli upgrade
      statistici ordinari già tematizzati, senza sovrapposizioni semantiche
      (stesso principio già dichiarato per le due pirofile in
      `powerup-catalog.md`).
- [ ] Le nuove icone hanno una riga nell'`ASSET-MANIFEST.md` pertinente con
      origine, autore/licenza, trasformazioni e hash SHA-256.
- [ ] `BarbRewardOverlay` (PS-036) mostra correttamente i nuovi nomi e le
      nuove icone senza modifiche al proprio layout o alla propria logica.

## Ambito

- `data/upgrades/specialities/*.tres` (le otto definizioni: `title`,
  `description`, `effect_summary`, `icon`).
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

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: apri la schermata Barb con le nuove
      Specialità, verifica leggibilità di nome e icona a dimensione reale
- [ ] Controllo percettivo richiesto: sì — le otto icone devono leggersi come
      otto pezzi di carne distinti dello stesso menù, riconoscibili l'uno
      dall'altro a dimensione carta, non come restyle cosmetico casuale
- [ ] Approvazione del proprietario sugli otto nomi prima di generare le
      icone: il nome decide il soggetto del disegno, rifarlo dopo costa una
      seconda generazione

## Decisioni

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
  aprire otto card di wiring separate. Il criterio di accettazione
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
- **2026-09-02 — Dipende da PS-077.** Copre le otto Specialità risultanti
  dall'espansione del pool; tematizzare solo le quattro attuali richiederebbe
  un secondo passaggio quando arrivano le altre quattro.
- **2026-09-02 — Nessun nuovo effetto o rank.** Stesso principio già
  dichiarato da PS-012 ("il loro design gameplay non deve essere
  modificato"): qui si applica a identità invece che a meccanica di
  sblocco.

## Documenti sincronizzati

- [ ] `docs/powerup-catalog.md`: eventuale nota sulle Specialità tematizzate,
      se il proprietario vuole documentarle nello stesso file.

## Note

Se in fase di implementazione il nuovo nome di una carta rendesse l'effetto
meno leggibile rispetto a oggi, va preferita la leggibilità: segnalarlo
invece di forzare un titolo a effetto ma ambiguo. Il vincolo "pezzo di carne"
riguarda il soggetto, non impedisce di qualificarlo: un taglio più una parola
che punta all'effetto resta dentro il tema e mantiene la carta leggibile.

Non implementata in questa sessione (card `art` di sola generazione, delegata
a `game-art-designer`). Candidati di nome/soggetto per orientare il brief,
**non decisi**: restano da sottoporre all'approvazione del proprietario
(gate sopra) prima di generare qualunque icona, e sono solo un punto di
partenza — chi implementa può proporne di migliori.

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
