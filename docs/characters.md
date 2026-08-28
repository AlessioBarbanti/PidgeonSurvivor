# Characters — Elenco e descrizioni

Questo file raccoglie in forma separata le descrizioni dei personaggi presenti in `Test_proposta_game_design.md`.
Nomi e testi sono stati approvati dal proprietario del progetto il 17 agosto
2026. La fonte runtime è `data/friends/*.tres`; il registro completo è in
[`content-approvals.md`](./content-approvals.md).

## Magno

Ruolo: Mobilità e controllo delle orde.  
Passiva — Flusso Aerodinamico Bovino: Lo slancio cresce muovendosi dritto e decade cambiando direzione.  
Attiva — Onda d'Urto Tellurica: Genera un'onda d'urto circolare che infligge danni e respinge i nemici vicini, più forte con più slancio.
Boss: Evil Magno.

## Bea

Ruolo: Evasione e riposizionamento.  
Passiva — Scarto Istintivo: A cooldown, annulla il primo colpo che la colpirebbe e la scarta d'istinto lontano dal pericolo con un breve i-frame.  
Attiva — Powerslide: Si teletrasporta nell'ultima direzione guardata e lascia una scia di fuoco persistente.
Boss: Evil Bea.

## Zat

Ruolo: Gestione del danno e sopravvivenza.  
Passiva — Guarigione Ritardata: Parte del danno diventa una quantità recuperabile nel tempo se il giocatore evita danni successivi.  
Attiva — Tempesta di Tuoni: Una sequenza di fulmini telegrafati cade su posizioni fisse durante alcuni secondi; il valore sta nel portarci sopra orde e Boss (B43).
Boss: Evil Zat.

## Alea

Ruolo: Progressione e crescita.  
Passiva — L’Aquila Non Sbaglia Mai: a intervalli regolari tira un effetto temporaneo, forte in bene o in male; ogni nemico ucciso carica la fortuna del prossimo tiro, che la spende per intero.  
Attiva — Gran Piroetta: Rotazione rapida che colpisce ripetutamente i nemici vicini.
Boss: Evil Alea.

## Aleo

Ruolo: Sbalzo termico — brucia quando sta bene, raffredda quando è in difficoltà.  
Passiva — Termostato Interno: sopra metà salute lavora in riscaldamento e aumenta il danno inflitto; sotto metà passa in raffrescamento, riduce il danno subito e la brina rallenta ed erode i nemici vicini. Un'aura ciano o arancio dichiara sempre la modalità corrente.  
Attiva — Shock Termico: Congela un'area per un istante, poi la fa esplodere di calore con danno raddoppiato sui nemici brinati.
Boss: Evil Aleo.

## Lollo

Ruolo: Velocità, caos e imprevedibilità.  
Passiva — Iperfocus ADHD: Alterna a intervalli casuali una fase di iperfocus (movimento e cadenza di fuoco molto più rapidi) e una fase distratta (movimento e cadenza sotto la norma); ogni nemico ucciso accorcia la sola distrazione. Una tinta dedicata dichiara la fase corrente.  
Attiva — Cosplay Casuale: Usa l'attiva di un altro personaggio, estratta in anticipo e annunciata prima del lancio, così da poterci pianificare sopra.
Boss: Evil Lollo.

## Migi

Ruolo: Difesa e controllo delle orde.  
Passiva — Guscio Tartarughina: Placche che annullano i primi colpi e si ricaricano nel tempo; sotto soglia critica arriva uno scudo d'emergenza (con cooldown).  
Attiva — Rallentamento Zen: Zona che rallenta fortemente i nemici e assorbe i loro proiettili.
Boss: Evil Migi.

## Marghe

Ruolo: Indebolimento e manipolazione dell'aggro.  
Passiva — Sorriso Contagioso: I nemici vicini subiscono più danno da ogni fonte, arma e abilità comprese, e sono marcati da una tinta magenta riconoscibile.  
Attiva — Reggeton time!: Genera un clone che balla reggaeton e devia l'aggro dei nemici.
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
