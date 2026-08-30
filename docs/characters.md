# Characters — Elenco e descrizioni

Questo file raccoglie le descrizioni correnti dei personaggi. La prima proposta
da cui sono state estratte è conservata soltanto come
[materiale storico](./archive/game-design-proposal-legacy.md).
Nomi e testi sono stati approvati dal proprietario del progetto il 17 agosto
2026. La fonte runtime è `data/friends/*.tres`; il registro completo è in
[`content-approvals.md`](./content-approvals.md).

## Magno

Ruolo: Mobilità e controllo delle orde.  
Passiva — Flusso Aerodinamico Bovino: Muovendosi dritto accumula slancio: più è veloce, più forte è la sua onda.  
Attiva — Onda d'Urto Tellurica: Genera un'onda d'urto che danneggia e respinge i nemici vicini, più forte quanto più slancio Magno ha accumulato.
Boss: Evil Magno.

## Bea

Ruolo: Evasione e riposizionamento.  
Passiva — Sesto Senso Equino: Ogni 9 secondi annulla il colpo che la colpirebbe: Bea scarta d'istinto lontano dal pericolo e resta invulnerabile per un istante.<br>
Attiva — Powerslide: Scatto istantaneo nell'ultima direzione di movimento, che lascia dietro di sé una scia di fuoco.
Boss: Evil Bea.

## Zat

Ruolo: Gestione del danno e sopravvivenza.  
Passiva — Guarigione Ritardata: Parte del danno subito resta recuperabile: se Zat evita altri colpi per qualche secondo, quella quota torna indietro.  
Attiva — Tempesta di Tuoni: Una tempesta di fulmini telegrafati cade su punti fissi attorno a Zat, colpendo ogni nemico che si trova sotto le zone d'impatto; il valore sta nel portarci sopra orde e Boss (B43).
Boss: Evil Zat.

## Alea

Ruolo: Rischio, fortuna e mischia.  
Passiva — L’Aquila Non Sbaglia Mai: Ogni 10 secondi tira un effetto a caso: uccidere nemici aiuta la sorte (ogni kill carica la fortuna del tiro successivo, che la spende per intero).  
Attiva — Gran Piroetta: Una rotazione rapida che colpisce ripetutamente tutti i nemici vicini.
Boss: Evil Alea.

## Aleo

Ruolo: Sbalzo termico e gestione del danno.  
Passiva — Termostato Interno: Sopra metà vita scalda e infligge più danno; sotto metà raffredda, incassa meno e la brina rallenta e logora i nemici vicini. Un'aura ciano o arancio dichiara sempre la modalità corrente.  
Attiva — Shock Termico: Congela un'area per un istante, poi la fa esplodere di calore: i nemici ancora brinati subiscono danno raddoppiato.
Boss: Evil Aleo.

## Lollo

Ruolo: Velocità, caos e imprevedibilità.  
Passiva — Iperfocus ADHD: Alterna a intervalli casuali una fase di iperfocus (movimento e cadenza di fuoco molto più rapidi) e una fase distratta (movimento e cadenza sotto la norma); ogni nemico ucciso accorcia la sola distrazione. Una tinta dedicata dichiara la fase corrente.  
Attiva — Cosplay Casuale: Estrae in anticipo l'abilità di un altro personaggio e la mostra sul pulsante: la prossima attivazione lancia quella.
Boss: Evil Lollo.

## Migi

Ruolo: Difesa e controllo delle orde.  
Passiva — Guscio Tartarughina: Le placche del guscio annullano i primi colpi e si ricaricano; sotto il 35% di vita la Tartarughina tira fuori il carapace.  
Attiva — Rallentamento Zen: Crea una zona che rallenta fortemente i nemici vicini e assorbe i proiettili che vi entrano.
Boss: Evil Migi.

## Marghe

Ruolo: Indebolimento e distrazione dei nemici.  
Passiva — Sorriso Contagioso: I nemici vicini subiscono più danno da ogni fonte, arma e abilità comprese (i Boss non ne risentono), e sono marcati da una tinta magenta riconoscibile.  
Attiva — Reggaeton time!: Genera un clone che balla reggaeton e diventa il bersaglio dei nemici vicini.
Boss: Evil Marghe.

## Direzione visuale del cast

Questi archetipi originali sono la direzione presentazionale approvata per il
fondale della welcome B18O. Traducono passive e abilità in silhouette
immediatamente riconoscibili e non modificano i contratti gameplay dei profili.
Con l'eccezione di Aleo, non rappresentano persone reali: dal rework del 28
agosto 2026 la sua direzione visuale è ispirata ai tratti di una persona reale,
con consenso esplicito dichiarato dal proprietario del progetto, e resta una
caricatura pixel-art e non una somiglianza fotografica.

Il 28 agosto 2026 tutte e otto le strisce sprite sono state rigenerate dal
proprietario in un passaggio di identità, insieme alle due icone di Aleo. La
tabella qui sotto resta la direzione approvata; ciò che è effettivamente entrato
nel runtime, con versioni promosse e hash, è in
`assets/art/characters/players/ASSET-MANIFEST.md`.

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

---

Note:

- Questo file è il riferimento per ruoli e descrizioni dei personaggi. Le specifiche numeriche di passive e abilità attive sono definite nelle sezioni 3.4 e 3.6 di `docs/prd.md` e nei data resource (`data/friends/*.tres` e `data/abilities/*.tres`).
- Per modifiche o aggiunte aggiornare `docs/characters.md`, `docs/content-approvals.md`, la sezione delle abilità attive in `docs/prd.md` e i relativi data resource.
