# Characters — Elenco e descrizioni

Questo file raccoglie le descrizioni correnti dei personaggi. La prima proposta
da cui sono state estratte è conservata soltanto come
[materiale storico](./archive/game-design-proposal-legacy.md).
Nomi e testi sono stati approvati dal proprietario del progetto il 17 agosto
2026. La fonte runtime è `data/friends/*.tres`.

## Magno

Ruolo: Mobilità e controllo delle orde.  
Passiva — Flusso Aerodinamico Bovino: Muovendosi dritto accumula slancio: più è veloce, più forte è la sua onda.  
Attiva — Onda d'Urto Tellurica: Genera un'onda d'urto che danneggia e respinge i nemici vicini, più forte quanto più slancio Magno ha accumulato.
Boss: Evil Magno — Signature *Onda d'Urto Tellurica*: dopo un forte impatto a terra telegrafato, un fronte anulare parte dal Boss e si espande verso l'esterno, danneggiando e respingendo una sola volta chi attraversa. La versione Boss non usa lo slancio del Player.

## Bea

Ruolo: Evasione e riposizionamento.  
Passiva — Sesto Senso Equino: Ogni 9 secondi annulla il colpo che la colpirebbe: Bea scarta d'istinto lontano dal pericolo e resta invulnerabile per un istante.<br>
Attiva — Powerslide: Scatto istantaneo nell'ultima direzione di movimento, invulnerabile all'atterraggio, che lascia dietro di sé una scia di fuoco.
Boss: Evil Bea — Signature *Powerslide*: una linea di preavviso mostra direzione e traiettoria, poi Bea scatta lungo quella linea e lascia una scia di fuoco che infligge danno nel tempo e restringe temporaneamente lo spazio sicuro.

## Zat

Ruolo: Gestione del danno e sopravvivenza.  
Passiva — Guarigione Ritardata: Parte del danno subito resta recuperabile: se Zat evita altri colpi per qualche secondo, quella quota torna indietro.  
Attiva — Tempesta di Tuoni: Fotografa tutti i nemici vivi presenti in quel momento e li colpisce con un'unica scarica ciascuno; il danno per bersaglio scala con la quota di HP recuperabili accumulata da Guarigione Ritardata (PS-004).
Boss: Evil Zat — Signature *Tempesta di Tuoni*: l'aura orbitante di PS-004 dichiara la fascia di carica, che qui sale con il danno già subito dal Boss; dopo il telegraph il Tuono colpisce soltanto dentro il raggio annunciato, quindi resta evitabile.

Contratto runtime di Guarigione Ritardata (confermato da PS-003; i valori vivono
in `data/friends/zat.tres`, la logica in `FriendPassiveController`):

- La quota recuperabile è il `recoverable_fraction` (35%) del danno
  **applicato**, cioè dopo riduzioni e moltiplicatori e comunque limitato alla
  vita residua.
- Il recupero parte dopo `recovery_delay` (3 s) senza subire alcun danno.
- Il recupero è progressivo e lineare su `recovery_duration` (4 s): la quota si
  svuota esattamente a fine finestra.
- Un nuovo colpo somma la propria quota al residuo non ancora restituito e
  riavvia da capo sia l'attesa sia la finestra di recupero: la penalità è il
  tempo, mai la quota.
- L'accumulo non ha tetto e può superare la vita residua.
- A vita piena — o quando il tetto degli HP massimi è già raggiunto — la quota
  residua viene scartata per intero al primo tick di recupero.
- La quota non assorbe il danno letale e non resuscita Zat.
- Attesa e recupero avanzano solo in `RUNNING`: pausa, level-up e Boss intro li
  congelano senza consumarli.
- Restart e cambio personaggio azzerano quota e timer.
- `get_recoverable_health()` e il segnale `delayed_healing_changed` espongono la
  quota corrente senza consumarla.

Contratto runtime di Tempesta di Tuoni (PS-004; i valori vivono in
`data/abilities/zat_lightning_storm.tres` e `data/friends/zat.tres`, la logica
in `scripts/abilities/lightning_storm.gd` e `FriendPassiveController`):

- All'attivazione vengono fotografati i nemici vivi in quel momento
  (`TargetingSystem.get_alive_targets()`); dopo un breve preavviso
  (`warning_seconds`, `0,35` s) ricevono tutti un'unica istanza di danno. I
  nemici comparsi dopo lo snapshot non vengono colpiti.
- Il danno per bersaglio è `damage` del rank corrente moltiplicato per la
  fascia di carica al momento dell'attivazione: `×1` sotto il `5%` di HP
  recuperabili (rispetto alla vita massima di Zat), `×2` fra `5%` e `12%`,
  `×3` da `12%` in su. Al rank 1: `12 / 24 / 36`.
- La quota recuperabile non viene consumata dall'attivazione: è solo letta
  (`FriendPassiveController.get_thunder_charge_tier()`).
- La stessa fascia guida un'aura orbitante persistente attorno a Zat (1
  fulmine verde in fascia bassa, 2 gialli in media, 3 rossi in alta, con
  rotazione crescente): è il tell della quota recuperabile anche fuori
  dall'attivazione (PS-003, D3), e si azzera in un frame quando la quota
  viene scartata a vita piena (PS-003, D2).
- L'aura è puramente visiva: nessuna Area2D, nessuna collisione, nessun
  effetto di gameplay.
- Aura e preavviso avanzano solo in `RUNNING`; restart e cambio personaggio
  rimuovono fascia e VFX residui.

## Alea

Ruolo: Rischio, fortuna e mischia.  
Passiva — L’Aquila Non Sbaglia Mai: Ogni 10 secondi tira un effetto a caso: uccidere nemici aiuta la sorte (ogni kill carica la fortuna del tiro successivo, che la spende per intero).  
Attiva — Gran Piroetta: Una rotazione rapida che colpisce ripetutamente tutti i nemici vicini.
Boss: Evil Alea — Signature *Gran Piroetta*: entra in rotazione con un'area di contatto sempre visibile e insegue a velocità ridotta senza poter cambiare direzione all'istante.

## Aleo

Ruolo: Sbalzo termico e gestione del danno.  
Passiva — Termostato Interno: Sopra metà vita scalda e infligge più danno; sotto metà raffredda, incassa meno e la brina rallenta e logora i nemici vicini. Un piccolo particellare ciano o arancio, sospeso sopra la testa, dichiara sempre la modalità corrente.  
Attiva — Shock Termico: Congela un'area per un istante, poi la fa esplodere di calore: i nemici ancora brinati subiscono danno raddoppiato.
Boss: Evil Aleo — Signature *Shock Termico*: un'area ciano rallenta chi vi resta dentro, poi la stessa area detona; il rallentamento lascia comunque il tempo di uscire.

## Lollo

Ruolo: Velocità, caos e imprevedibilità.  
Passiva — Iperfocus ADHD: Alterna a intervalli casuali una fase di iperfocus (movimento e cadenza di fuoco molto più rapidi) e una fase distratta (movimento e cadenza sotto la norma); ogni nemico ucciso accorcia la sola distrazione. Un piccolo particellare sospeso sopra la testa dichiara la fase corrente senza alterare i colori del personaggio.<br>
Attiva — Cosplay Casuale: Estrae in anticipo l'abilità di un altro personaggio e la mostra sul pulsante: la prossima attivazione lancia quella.
Boss: Evil Lollo — Signature *Cosplay Casuale*: prepara in anticipo la Signature di un altro Evil, la annuncia disegnandone il telegraph e la esegue con i parametri Boss di quella copiata. Non può copiare Cosplay Casuale, quindi non genera ricorsione.

## Migi

Ruolo: Difesa e controllo delle orde.  
Passiva — Guscio Tartarughina: Le placche del guscio annullano i primi colpi e si ricaricano; sotto il 35% di vita la Tartarughina tira fuori il carapace.  
Attiva — Rallentamento Zen: Crea una zona che rallenta fortemente i nemici vicini e assorbe i proiettili che vi entrano.
Boss: Evil Migi — Signature *Rallentamento Zen*: una zona attorno al Boss rallenta il Player e assorbe i proiettili alleati che vi entrano, senza infliggere danno diretto.

## Marghe

Ruolo: Indebolimento e distrazione dei nemici.  
Passiva — Sorriso Contagioso: I nemici vicini subiscono più danno da ogni fonte, arma e abilità comprese (i Boss non ne risentono), e sono marcati da una tinta magenta riconoscibile.  
Attiva — Reggaeton time!: Genera un clone che balla reggaeton e diventa il bersaglio dei nemici vicini.
Boss: Evil Marghe — Signature *Reggaeton time!*: genera un clone ballerino distinguibile dal Boss reale, che l'auto-targeting del Player può preferire mentre Marghe continua a usare i propri pattern.

## Direzione visuale del cast

Questi archetipi originali sono la direzione presentazionale approvata per il
fondale della welcome B18O. Traducono passive e abilità in silhouette
immediatamente riconoscibili e non modificano i contratti gameplay dei profili.
Le fotografie personali autorizzate in `docs/characters/references/<id>/`
forniscono soltanto citazioni fisionomiche semplificate: i profili non sono
ritratti realistici né copie delle persone fotografate. Aleo conserva inoltre
il consenso esplicito già registrato per il rework del 28 agosto 2026; anche la
sua resa resta una caricatura pixel-art.

Il 28 agosto 2026 tutte e otto le strisce sprite sono state rigenerate dal
proprietario in un passaggio di identità, insieme alle due icone di Aleo. La
tabella qui sotto resta la direzione approvata; ciò che è effettivamente entrato
nel runtime, con versioni promosse e hash, è in
`assets/art/characters/ASSET-MANIFEST.md`.

| Personaggio | Descrizione visuale |
|---|---|
| Magno | Energumeno tellurico con richiami bovini, posa pesante e onda d'urto che crepa il terreno. |
| Bea | Pattinatrice agile senza casco, con capelli scuri lunghi e ricci e un capo sportivo viola durante un Powerslide basso, accompagnato da una breve scia di fuoco dietro i roller. |
| Zat | Infermiera elettrica con taglio a caschetto e divisa bianco-ciano, simbolo medico generico a cuore, luce curativa e fulmine giallo-ciano. |
| Alea | Ballerina classica nel pieno di una Gran Piroetta, circondata da un nastro circolare e un richiamo d'aquila. |
| Aleo | Termotecnico giovane e robusto, occhiali e barba ramata, chiave regolabile e manometro alla cintura, metà aura ciano di brina e metà aura arancio di calore. |
| Lollo | Cosplayer iperattivo dai capelli scuri, con un costume originale da sopravvissuto retrofuturista post-apocalittico: tuta blu, dettagli gialli e accessori da wasteland senza marchi. |
| Migi | Donna con occhiali e capelli neri, calma e concentrata dentro uno scudo ciano a guscio di tartaruga e onde rallentanti; non è vincolata a un archetipo monastico. |
| Marghe | Ballerina reggaeton dalla corporatura morbida, con capelli neri molto lunghi, accenti magenta-oro e un clone d'ombra che replica la posa come VFX. |

Dal 3 settembre 2026 PS-068 integra per tutti gli otto profili un busto Player
dedicato `assets/art/characters/<id>/generated/portrait.png`, 256×256 con alfa
reale. `portrait` e `portrait_placeholder` usano questo derivato approvato e
`portraits_are_placeholders` è `false`; il precedente `AtlasTexture` CC0 non è
più usato per i ritratti Player. Gli otto busti condividono taglio dalla vita,
proporzioni coerenti con `poses.png` e pixel-art arcade non fotorealistica.

---

Note:

- Questo file è il riferimento per ruoli e descrizioni dei personaggi. Le specifiche numeriche di passive e abilità attive sono definite nelle sezioni 3.4 e 3.6 di `docs/prd.md` e nei data resource (`data/friends/*.tres` e `data/abilities/*.tres`).
- Per modifiche o aggiunte aggiornare `docs/characters.md`, la sezione delle abilità attive in `docs/prd.md` e i relativi data resource.
