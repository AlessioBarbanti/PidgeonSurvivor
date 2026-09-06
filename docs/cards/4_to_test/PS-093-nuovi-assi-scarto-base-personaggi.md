---
id: PS-093
titolo: Introduci cinque nuovi assi di scarto base per personaggio
tipo: feat
area: gameplay
stato: IN VERIFICA
priorita: media
dipende_da: [PS-087]
origine: conversazione del proprietario 2026-09-04
creato: 2026-09-04
aggiornato: 2026-09-06
---

# PS-093 — Introduci cinque nuovi assi di scarto base per personaggio

## Contesto

[PS-087](../5_completed/PS-087-definisci-statistiche-base-personaggi.md) ha
concluso che i tre assi B47 esistenti (salute, velocità, cadenza) bastano a
differenziare gli otto personaggi dal proprio ruolo, e non ha raccomandato un
nuovo asse — [PS-091](../6_rejected/PS-091-genera-placeholder-powerup-nuove-statistiche.md)
si è scartata di conseguenza. Il proprietario ha comunque chiesto, in una
conversazione successiva, di esplorare nuovi assi indipendentemente da quella
necessità meccanica: non per colmare un buco di differenziazione, ma per
allargare lo spazio di identità statistica del cast.

Cinque candidati sono stati discussi e approvati:

1. **Danno inflitto** — moltiplicatore sul danno dell'arma automatica (e,
   opzionalmente, delle abilità attive).
2. **Avidità** — moltiplicatore sull'XP ottenuta. Deliberatamente non
   chiamato "fortuna": quel nome è già l'identità di Alea (la sua passiva
   L'Aquila Non Sbaglia Mai è un tiro casuale che si carica uccidendo), e uno
   scarto universale con lo stesso nome ma un effetto diverso (XP, non un
   tiro casuale) rischiava di confondersi con quella meccanica specifica.
3. **Raggio di raccolta pickup** — moltiplicatore sul raggio con cui il
   Player raccoglie i cristalli XP.
4. **Riduzione danno subito (difesa)** — moltiplicatore sul danno che il
   Player incassa. Il proprietario ha confermato di volerlo comunque
   nonostante il dubbio di sovrapposizione concettuale con salute (vedi
   Decisioni): la card deve risolvere esplicitamente la distinzione di ruolo
   fra i due assi, non limitarsi ad aggiungerlo.
5. **Probabilità critica** — chance che un colpo dell'arma automatica infligga
   danno critico. Sostituisce "area/raggio delle abilità attive", scartata
   dal proprietario per l'eterogeneità delle otto abilità (vedi Decisioni).
   Nessun meccanismo di danno critico esiste oggi nel runtime: questo asse
   introduce l'intero sistema da zero, non solo lo scarto per personaggio.

Un sesto candidato, **rigenerazione vita nel tempo**, è stato esplicitamente
escluso da questa card come scarto base: il proprietario lo approva solo come
idea per un futuro powerup del catalogo ordinario, non come scarto per
personaggio. Non è oggetto di questa card né di alcuna card aperta.

Ricognizione tecnica dei punti di applicazione runtime, per ciascun asse:

- **Danno arma**: `WeaponController` ha già uno slot pronto,
  `_character_damage_multiplier`
  ([scripts/combat/weapon_controller.gd:21,256,404](../../../scripts/combat/weapon_controller.gd#L21)),
  alimentato da `set_character_stat_multipliers(fire_rate, damage=1.0)`
  ([weapon_controller.gd:244-257](../../../scripts/combat/weapon_controller.gd#L244)).
  Oggi `FriendPassiveController` chiama questo setter passando `damage=1.0`
  fisso ([scripts/content/friend_passive_controller.gd:774](../../../scripts/content/friend_passive_controller.gd#L774));
  serve solo leggere il nuovo scarto invece della costante.
- **Danno abilità**: nessun hook equivalente esiste oggi. Il danno delle
  abilità vive in `AbilityRankSnapshot.damage`
  ([scripts/abilities/ability_rank_snapshot.gd:8](../../../scripts/abilities/ability_rank_snapshot.gd#L8))
  e viene letto direttamente dagli script effetto
  (`earthquake_wave.gd`, `thermal_shock.gd`, `lightning_storm.gd`,
  `ability_area_effect.gd`). Includere le abilità in questo asse richiede un
  nuovo moltiplicatore in `AbilityController`, accanto al pattern già usato da
  `set_upgrade_cooldown_multiplier`
  ([scripts/abilities/ability_controller.gd:209-216](../../../scripts/abilities/ability_controller.gd#L209)).
- **XP (Avidità)**: nessuno slot "character" in `ExperienceSystem`. Il
  moltiplicatore da upgrade vive in `_upgrade_value_multiplier`
  ([scripts/progression/experience_system.gd:47-48,191-194](../../../scripts/progression/experience_system.gd#L47)),
  alimentato da `barb_seasoning_xp`/"Il condimento di Barb"
  (`effect_id = &"xp_value_multiplier"`,
  [data/upgrades/barb_seasoning_xp.tres:13-16](../../../data/upgrades/barb_seasoning_xp.tres#L13)).
  Serve un nuovo stadio "character" analogo, composto moltiplicativamente con
  quello da upgrade — stesso pattern a due stadi già in uso per cadenza
  (vedi sotto).
- **Raggio pickup**: slot "character" già presente ma cablato a `1.0` fisso,
  `_character_pickup_radius_multiplier`
  ([scripts/actors/player.gd:77,407,541,633](../../../scripts/actors/player.gd#L77)),
  passato oggi come `1.0` da
  [friend_passive_controller.gd:773](../../../scripts/content/friend_passive_controller.gd#L773).
  Compone con `wide_magnet`/"Pinza Lunga"
  (`player_pickup_radius_multiplier`,
  [upgrade_effect_registry.gd:16](../../../scripts/progression/upgrade_effect_registry.gd#L16)).
- **Riduzione danno subito**: nessuno slot "character",
  `_damage_taken_multiplier` in `player.gd:82,277,387` è alimentato solo da
  upgrade (`reinforced_roasting_tray`/"Pirofila Rinforzata",
  `player_damage_taken_multiplier`). Serve un nuovo stadio "character".
- **Probabilità critica**: nessun riscontro di "critic"/"crit" in tutto il
  runtime (`weapon_controller.gd`, `upgrade_effect_registry.gd`). L'unico
  precedente è "Salamoia Bolognese" in `docs/powerup-catalog.md` (`+5` punti
  percentuali per rango, danno critico `1,75×`, cap `35%`), proposta di
  seconda ondata **mai implementata**: nessun `.tres` reale la referenzia.
  Questo asse introduce l'intero sistema (chance + moltiplicatore di danno
  critico) in `WeaponController`, non solo un secondo stadio su un campo
  già esistente come gli altri quattro assi.

**Audit del catalogo ordinario (2026-09-04, richiesto dal proprietario:
"ci deve essere un upgrade per ogni statistica")**: confermato che danno,
avidità, raggio pickup e riduzione danno subito hanno già una carta reale
nel catalogo — non serve crearne di nuove per questi quattro:

| Asse | Carta esistente | `effect_id` |
|---|---|---|
| Danno inflitto | `meat_fork_damage`/"Forchettone da Braciere" | `weapon_damage_multiplier` |
| Avidità (XP) | `barb_seasoning_xp`/"Il condimento di Barb" | `xp_value_multiplier` |
| Raggio pickup | `wide_magnet`/"Pinza Lunga" | `player_pickup_radius_multiplier` |
| Riduzione danno subito | `reinforced_roasting_tray`/"Pirofila Rinforzata" | `player_damage_taken_multiplier` |

**Probabilità critica è l'unico buco reale**, e questa card ora si impegna a
chiuderlo: non basta il sistema in `WeaponController`, serve anche la carta
catalogo che lo espone come scelta di livello, altrimenti l'asse resta senza
sbocco per il giocatore (incoerente con tutti gli altri sette). Trovato un
asset orfano riutilizzabile:
`assets/art/icons/upgrades/hd/upgrade_salamoia_bolognese.png` — master HD
mai derivato (nessun file in `generated/`, nessuna riga nel manifest),
residuo della proposta "Salamoia Bolognese" mai costruita. Derivarlo con lo
script esistente (`process-upgrade-icon.ps1`) è riuso/adattamento di arte
già esistente, non nuova generazione: **non richiede delega a
`game-art-designer`** per la regola di board
([docs/cards/README.md](../README.md), "non la sola integrazione,
l'adattamento geometrico/procedurale o il riuso di arte esistente") — ma
resta comunque soggetto ad art review prima di accettarlo, perché è stato
prodotto per un contesto mai arrivato in gioco e potrebbe non reggere il
confronto con la famiglia visiva attuale del catalogo.

Pattern di composizione di riferimento già in uso (cadenza × `rapid_fire`):
due stadi moltiplicativi indipendenti — uno "character" alimentato dallo
scarto base B47, uno "upgrade" alimentato dal catalogo — mai un unico campo
condiviso
([weapon_controller.gd:399-400,427-428](../../../scripts/combat/weapon_controller.gd#L399)).
Questo è il pattern da replicare per i cinque nuovi assi.

## Comportamento atteso

Ogni personaggio dichiara, per ciascuno dei cinque nuovi assi effettivamente
implementati da questa card, uno scarto base motivato dal proprio ruolo
(stesso principio di PS-087), composto moltiplicativamente con l'eventuale
upgrade del catalogo che tocca lo stesso numero, senza mutare i dati base
condivisi di Player, arma o abilità.

## Criteri di accettazione

- [x] `FriendDefinition` guadagna i nuovi campi scarto moltiplicativi (nomi
      tecnici in inglese, es. `base_damage_multiplier`,
      `base_xp_gain_multiplier`, `base_pickup_radius_multiplier`,
      `base_damage_taken_multiplier`), default neutro `1,0`, range
      `0,5–2,0`, normalizzati con lo stesso meccanismo già in uso per i tre
      assi B47 esistenti (nessuna modifica a quel meccanismo, solo
      estensione con lo stesso pattern).
- [x] Danno arma, XP, raggio pickup e riduzione danno subito compongono a
      runtime con lo stadio "character" identificato in Contesto (nuovo o già
      presente ma cablato a `1,0`), mantenendo lo stadio "upgrade" esistente
      indipendente e componendo moltiplicativamente i due, come già avviene
      per la cadenza.
- [x] Danno abilità è incluso in questa card solo se l'implementazione resta
      pulita; se il nuovo hook in `AbilityController` risulta sproporzionato
      rispetto al resto della card, la card lo dichiara esplicitamente in
      `Decisioni` e propone una card di follow-up invece di forzarlo o di
      ometterlo in silenzio. **Escluso**: vedi Decisioni.
- [x] Probabilità critica: `FriendDefinition` dichiara uno scarto per
      personaggio su un campo **non moltiplicativo-neutro-1,0** ma additivo
      su punti percentuali (es. `base_critical_chance_bonus`, default `0,0`,
      range da motivare — non riusa il pattern `×1,0`/`0,5–2,0` degli altri
      assi perché una probabilità non è un moltiplicatore di una baseline).
      `WeaponController` guadagna il sistema di risoluzione critica (chance +
      moltiplicatore di danno) da zero, con un cap esplicito sulla chance
      totale (coerente con `35%` già proposto per "Salamoia Bolognese").
- [ ] Il critico ha una carta nel catalogo ordinario (nuovo
      `data/upgrades/*.tres`, es. riprendendo `salamoia_bolognese_crit`/
      "Salamoia Bolognese" già proposta in `docs/powerup-catalog.md`: `+5`
      punti percentuali di chance per rango, danno critico `1,75×`, cap
      `35%`), che compone con lo scarto base come "character" + "upgrade",
      stesso pattern degli altri quattro assi: **nessuno dei cinque assi
      introdotti da questa card resta senza una carta che lo esponga come
      scelta di livello** (richiesta esplicita del proprietario). **Parziale**:
      `data/upgrades/cooking_point_crit.tres` esiste, è meccanicamente
      completa e coperta dagli smoke, ma non è ancora nell'array
      `UpgradeRegistry.definitions` di `movement_slice.tscn` — l'icona non è
      accettata (vedi criterio successivo). Il pool pescabile in run resta
      quindi senza una carta per il critico finché
      [PS-108](../2_to_do/PS-108-integra-carta-punto-di-cottura.md) non
      chiude. Vedi Decisioni.
- [x] L'icona della carta critico deriva dal master HD già presente
      (`assets/art/icons/upgrades/hd/upgrade_salamoia_bolognese.png`) con lo
      script `process-upgrade-icon.ps1`, dopo art review che confermi sia
      ancora coerente con la famiglia visiva attuale del catalogo; se la
      review lo boccia, la card lo dichiara in `Decisioni` e propone una
      rigenerazione (delegata a `game-art-designer`) invece di forzare un
      derivato scadente. **La review ha bocciato** il derivato: contingenza
      eseguita esattamente come previsto dal criterio, vedi Decisioni e
      [PS-107](../2_to_do/PS-107-rigenera-icona-punto-di-cottura.md).
- [x] Per ogni asse effettivamente implementato, `docs/characters.md`
      contiene, per ciascuno degli otto personaggi, il valore e una riga di
      motivazione legata al ruolo già dichiarato — stesso formato già usato
      da PS-087 per i tre assi esistenti.
- [x] Per ogni asse implementato, i valori non sono tutti identici fra gli
      otto personaggi: un asse dove tutti i profili dichiarano lo stesso
      numero non aggiunge identità statistica e va evitato.
- [x] La distinzione di ruolo fra "riduzione danno subito" e "salute" è resa
      esplicita in `docs/characters.md` (es. salute = quanta capacità totale
      di assorbire danno nel tempo, difesa = quanto pesa il singolo colpo) o,
      se in fase di stesura risultasse che i due assi restano ridondanti per
      troppi personaggi, la card lo dichiara in `Decisioni` invece di forzare
      una differenziazione debole.
- [x] Ogni upgrade del catalogo ordinario che tocca lo stesso numero di un
      nuovo asse (confermati: `meat_fork_damage`, `barb_seasoning_xp`,
      `wide_magnet`, `reinforced_roasting_tray` — vedi tabella in Contesto)
      resta invariato nel proprio effetto: il nuovo scarto si compone, non
      sostituisce né duplica quel numero.
- [x] `docs/prd.md` riporta lo stesso risultato sincronizzato con
      `characters.md`, nello stesso formato tabellare già usato per i tre
      assi B47 esistenti.
- [x] La rigenerazione vita nel tempo **non** viene introdotta come scarto
      base da questa card: resta fuori ambito, come idea di un futuro
      powerup separato (vedi Contesto e Note).

## Ambito

- `scripts/content/friend_definition.gd`: nuovi campi scarto e relativi
  getter normalizzati.
- `scripts/combat/weapon_controller.gd`: composizione danno arma; nuovo
  sistema di risoluzione del colpo critico (chance + moltiplicatore danno).
- `scripts/content/friend_passive_controller.gd`: lettura dei nuovi scarti
  invece delle costanti `1,0` cablate, passaggio ai rispettivi setter.
- `scripts/progression/experience_system.gd`: nuovo stadio "character" per
  l'XP.
- `scripts/actors/player.gd`: nuovo stadio "character" per riduzione danno
  subito; lettura del nuovo scarto raggio pickup al posto del cablaggio
  fisso.
- `scripts/abilities/ability_controller.gd`: solo se il danno abilità resta
  dentro l'ambito di questa card (vedi Criteri).
- `data/friends/*.tres`: nuovi campi sugli otto profili.
- `data/upgrades/`: nuova carta catalogo per il critico.
- `assets/art/icons/upgrades/hd/upgrade_salamoia_bolognese.png` (esistente,
  derivazione soltanto) e `assets/art/icons/upgrades/generated/`,
  `assets/art/icons/upgrades/ASSET-MANIFEST.md`.
- `docs/characters.md`, `docs/prd.md`, `docs/powerup-catalog.md`
  (sincronizzazione del risultato).

Non toccare:

- i tre assi B47 esistenti (salute, velocità, cadenza) e i loro valori
  decisi da PS-087;
- `passive_parameters`, tag, ruoli testuali, arte, portrait;
- gli `effect_id`/`effect_parameters` degli upgrade del catalogo ordinario
  che compongono con i nuovi assi: restano bit-per-bit identici;
- rigenerazione vita nel tempo, in qualunque forma: fuori ambito per
  contratto (vedi Comportamento atteso).

## Verifica

- Smoke: `tests/unit/test_ps093_extended_base_stats.gd` → marker
  `EXTENDED_BASE_STATS_SMOKE_OK` — per i quattro assi moltiplicativi:
  default neutro, range B47, composizione a due stadi corretta con
  l'upgrade corrispondente, nessuna mutazione dei dati base condivisi dopo
  reset. Per la probabilità critica: risoluzione deterministica su un RNG
  seminato (nessuna dipendenza da tempo reale o ordine casuale non
  seminato), cap rispettato, nessun critico quando la chance è `0`, la
  nuova carta catalogo compone correttamente con lo scarto "character"
  (stesso pattern a due stadi degli altri quattro).
- La differenziazione fra coppie di personaggi sui nuovi assi non è
  coperta da questa card: se il proprietario la vuole, è materia di
  un'estensione di [PS-088](../5_completed/PS-088-verifica-differenziazione-statistiche-personaggi.md)
  (oggi verifica solo i tre assi B47 originali), da aprire come card
  separata quando questa è chiusa.
- Profilo minimo prima della chiusura: `Relevant`.

**Risultato effettivo (2026-09-06):** `tests/unit/test_ps093_extended_base_stats.gd`
scritto e registrato in `tools/milestone-test-map.json` (regole 1, 7, 10, 14,
25; `scripts/content/friend_definition.gd` aggiunto come pattern nuovo alla
regola 1, prima privo di copertura). Marker `EXTENDED_BASE_STATS_SMOKE_OK`,
9 funzioni di test, 295 assert, tutte verdi. Copre: default neutro e range
normalizzato sui quattro assi moltiplicativi, composizione a due stadi
"character" × "upgrade" per ciascuno, nessuna mutazione del `Resource`
condiviso dopo reset, determinismo del critico su RNG seminato (stessa run
seed → stessa sequenza, seed diversi → sequenze diverse), rispetto del cap
`35%`, nessun critico quando la chance è `0`, persistenza dello scarto
personaggio attraverso `prepare_restart()` e reset corretto a `1,0`/`0,0`
solo quando il personaggio viene esplicitamente scollegato
(`passive._definition = null` + i tre `reset_*` dei rispettivi controller).

Suite completa rieseguita dopo l'implementazione: **334/334 test verdi**,
nessun `SCRIPT ERROR`/`FATAL EXCEPTION` nei log, exit code `0`. La
rilevazione delle prime 5 regressioni pre-esistenti (non bug di questa
card: vedi Decisioni) e la loro correzione sono avvenute in questo stesso
giro di verifica.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: non richiesto per soli dati numerici, salvo
      dubbi emersi in playtest
- [ ] Controllo percettivo richiesto: sì — cinque nuovi assi cambiano il
      feeling del cast in modo più marcato dei tre esistenti; playtest su
      almeno tre personaggi con profili diversi prima di dichiarare
      `COMPLETATO`. Include la nuova icona critico a dimensione carta reale
      (art review del derivato, vedi Criteri).

## Decisioni

- **2026-09-04 — Cinque assi approvati dal proprietario in conversazione**,
  indipendentemente dalla necessità meccanica: PS-087 non ne raccomandava
  nessuno, questa card nasce da una richiesta di allargare lo spazio di
  identità statistica, non da un buco da colmare.
- **2026-09-04 — "Avidità", non "fortuna".** Il proprietario ha confermato
  la rinomina per non confondersi con l'identità di Alea (rischio/fortuna
  già sua tramite la passiva).
- **2026-09-04 — Riduzione danno subito inclusa nonostante il dubbio.** Il
  proprietario ha confermato di volerla comunque; la card deve risolvere
  esplicitamente la distinzione con salute invece di ignorare il dubbio.
- **2026-09-04 — Rigenerazione vita esclusa come scarto, approvata solo come
  idea di powerup.** Non è implementata né aperta come card qui: se il
  proprietario la vuole perseguita, serve una card `card-crea` dedicata al
  catalogo ordinario, non un criterio di questa.
- **2026-09-04 — Dipende da PS-087 solo per lignaggio, non per blocco.**
  PS-087 è già `IN VERIFICA`: la dipendenza è dichiarata per tracciare che
  questa card estende lo stesso meccanismo, non perché sblocchi qualcosa.
- **2026-09-04 — "Area/raggio abilità" sostituita da "probabilità
  critica".** Il proprietario ha giudicato l'area abilità troppo
  disomogenea da gestire bene (Bea su un campo diverso, Lollo e Marghe senza
  alcun concetto di raggio — vedi la ricognizione originale in Contesto,
  ora superata) e ha chiesto di sostituirla col critico. Il critico è però
  un asse di natura diversa dagli altri quattro: non un secondo stadio su
  un moltiplicatore già esistente, ma un sistema nuovo di zecca (chance +
  danno critico) da costruire in `WeaponController`.
- **2026-09-04 — "Un upgrade per ogni statistica", richiesta esplicita del
  proprietario.** Audit del catalogo ordinario: danno, avidità, raggio
  pickup e riduzione danno subito hanno già una carta reale (tabella in
  Contesto) — nessun lavoro aggiuntivo lì. Il critico no: questa card ora
  include esplicitamente la costruzione della carta catalogo (non solo il
  meccanismo), riprendendo i numeri già proposti per "Salamoia Bolognese" e
  riusando il master HD orfano già presente
  (`upgrade_salamoia_bolognese.png`, mai derivato). La derivazione di un
  master già esistente è riuso di arte, non nuova generazione: non richiede
  delega a `game-art-designer` per la regola di board, ma resta soggetta ad
  art review prima di essere accettata.
- **2026-09-06 — Danno abilità escluso dall'ambito.** Toccare
  `AbilityController` avrebbe richiesto un nuovo moltiplicatore composto
  dentro ciascuno dei quattro script effetto abilità
  (`earthquake_wave.gd`, `thermal_shock.gd`, `lightning_storm.gd`,
  `ability_area_effect.gd`), ognuno con la propria lettura diretta di
  `AbilityRankSnapshot.damage` — sproporzionato rispetto al resto della
  card, che tocca un solo punto di composizione per asse. L'asse "Danno
  inflitto" resta quindi limitato all'arma automatica, come già indicato in
  Contesto. Proposta di follow-up: una card dedicata
  (`card-crea`, tipo `feat`) che estenda `AbilityController` con un
  moltiplicatore "character" analogo a `set_upgrade_cooldown_multiplier`,
  applicato ai quattro script effetto in un unico punto di lettura invece
  che quattro.
- **2026-09-06 — "Salamoia Bolognese" rinominata "Punto di Cottura"
  (`cooking_point_crit`).** Scoperto durante la verifica a suite completa:
  `test_ps089_ordinary_catalog_meat_audit.gd` proibisce la parola
  `salamoia` nel titolo di qualunque carta del catalogo ordinario (riservata
  alle Specialità di Barb, PS-089). La proposta originale in
  `docs/powerup-catalog.md` (31 agosto 2026) precedeva quella regola.
  Rinominati file, `id`, `title`, `description`; nessun cambio al
  meccanismo o ai numeri (`+5%`/rango, danno critico `1,75×`, cap `35%`).
- **2026-09-06 — Icona bocciata in art review, scorporata in PS-107/PS-108.**
  `direttore-artistico` ha dato verdetto "Da rifare" sul derivato del
  master orfano: composizione a tre nuclei visivi separati, illeggibile a
  48×48 (dimensione reale d'uso in HUD/fine run), confondibile con "Il
  condimento di Barb" (stesso soggetto ciotola/vaso di spezie). Il crop/
  resize automatico non è la causa (verificato pixel-per-pixel contro un
  derivato ufficiale esistente della stessa serie): il problema è nel
  master stesso. Per non forzare un derivato scadente in gioco né bloccare
  il resto della card su un unico asset d'arte, il derivato rifiutato è
  stato eliminato, `cooking_point_crit.tres` resta mecca­nicamente completo
  e testato ma **non registrato** in `UpgradeRegistry.definitions` di
  `movement_slice.tscn` (`UpgradeDefinition.is_valid()` non richiede
  un'icona non nulla — verificato in `upgrade_definition.gd`/
  `upgrade_registry.gd`, quindi il file resta valido e testabile sul disco
  senza raggiungere il pool pescabile in run). Aperte
  [PS-107](../2_to_do/PS-107-rigenera-icona-punto-di-cottura.md) (nuovo
  master, delegata a `game-art-designer`) e
  [PS-108](../2_to_do/PS-108-integra-carta-punto-di-cottura.md) (wiring nel
  catalogo live, bloccata da PS-107) — stessa forma già usata in questa
  sessione per PS-102/103 e PS-104/106.
- **2026-09-06 — Numeri per personaggio delegati a `analista-bilanciamento`**
  (richiesta esplicita del proprietario). L'agente ha analizzato i cinque
  assi contro ruolo, passiva e scarti B47 già esistenti di ciascun
  personaggio, evitando in particolare doppioni con mitigazioni già
  presenti nel kit (Aleo, Migi, Zat restano neutri o quasi su danno/difesa
  dove il proprio meccanismo passivo già copre lo stesso spazio; Alea resta
  a `+0%` critico perché PS-105 ha rimosso ogni RNG dal suo kit e un critico
  probabilistico contraddirebbe quel redesign; Lollo ha il critico più alto
  del cast, `+6%`, perché la sua passiva resta esplicitamente casuale). I
  valori finali sono in `data/friends/*.tres`, `docs/characters.md` e
  `docs/prd.md`. L'agente ha inoltre segnalato che
  `player.get_damage_taken_multiplier()` compone lo scarto "character" con
  quello "upgrade" senza un pavimento (`clampf`) esplicito sul prodotto
  finale: con scarti estremi multipli (fuori dal range `0,5–2,0` attuale)
  il moltiplicatore composito potrebbe scendere sotto zero. Nessun
  personaggio o carta attuale raggiunge quella soglia; segnalato qui come
  nota di manutenzione, non corretto in codice perché fuori dai valori
  realmente in gioco.
- **2026-09-06 — 5 regressioni pre-esistenti trovate e corrette durante la
  verifica a suite completa.** Tutte causate dall'introduzione di scarti
  "character" non neutri sul personaggio di default (Magno,
  `base_damage_multiplier 0,98`, `base_xp_gain_multiplier 1,02`): prima di
  questa card ogni personaggio era neutro `×1,0` su ogni asse, quindi
  alcuni test avevano assunzioni implicite mai messe alla prova.
  `test_b05_combat_slice.gd`: la fixture nemico usava `weapon_profile.damage`
  grezzo per un one-shot esatto, ora usa `weapon.get_effective_damage()`.
  `test_b12_upgrade_effects.gd` e `test_b26_damage_upgrade.gd`: le
  asserzioni "Resource condiviso non mutato" confrontavano
  `get_base_damage()` (che ora include correttamente lo stadio character)
  contro sé stesso invece che contro il valore grezzo del `Resource`; ora
  usano uno snapshot separato del valore grezzo. `test_powerup_first_wave.gd`:
  la XP di innesco usata solo per far comparire l'offerta di livello
  lasciava un credito frazionario che si sommava silenziosamente alla XP
  reale misurata dal test; ora chiama
  `experience.reset_upgrade_value_multiplier()` subito dopo l'innesco.
  Nessuna delle cinque era un bug del codice nuovo: tutte assunzioni di
  test coincidenti col vecchio default sempre-neutro.

## Documenti sincronizzati

- [x] `docs/characters.md`: tabella scarti + motivazione per personaggio,
      per ogni asse implementato.
- [x] `docs/prd.md`: stesso risultato, sincronizzato con `characters.md`.
- [x] `docs/powerup-catalog.md`: la voce passa da "Salamoia Bolognese"
      (proposta non implementata) a "Punto di Cottura" (carta reale del
      catalogo runtime, meccanismo mergiato), con lo stato icona
      esplicitamente bloccato e riferimento a PS-107/PS-108.
- [ ] `assets/art/icons/upgrades/ASSET-MANIFEST.md`: nuova riga per il
      derivato del critico. **Non applicabile a questa card**: il derivato
      rifiutato è stato eliminato, nessun file valido da manifestare finché
      PS-107 non produce un nuovo master accettato.

## Note

Rigenerazione vita nel tempo come **powerup** (non scarto base) resta
un'idea approvata dal proprietario ma non ancora una card: se la si vuole
perseguire, va aperta separatamente con `card-crea` contro il catalogo
ordinario (`docs/powerup-catalog.md`), fuori da questa card.

Possibile riferimento per l'implementazione: il pattern a due stadi
"character" + "upgrade" già maturo su cadenza
(`weapon_controller.gd:399-400,427-428`) è la specifica più precisa di cosa
replicare per ciascun nuovo asse — copiarlo invece di reinventare la
composizione da zero.
