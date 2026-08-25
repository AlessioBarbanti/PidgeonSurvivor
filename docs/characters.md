# Characters — Elenco e descrizioni

Questo file raccoglie in forma separata le descrizioni dei personaggi presenti in `Test_proposta_game_design.md`.
Nomi e testi sono stati approvati dal proprietario del progetto il 17 agosto
2026. La fonte runtime è `data/friends/*.tres`; il registro completo è in
[`content-approvals.md`](./content-approvals.md).

## Magno

Ruolo: Mobilità e controllo delle orde.  
Passiva — Flusso Aerodinamico Bovino: Aumenta la velocità di movimento base.  
Attiva — Onda d'Urto Tellurica: Genera un'onda d'urto circolare che infligge danni e respinge i nemici vicini.
Boss: Evil Magno.

## Bea

Ruolo: Evasione e riposizionamento.  
Passiva — Sesto Senso Equino: Probabilità di evitare completamente un colpo ricevuto.  
Attiva — Powerslide: Si teletrasporta nell'ultima direzione guardata e lascia una scia di fuoco persistente.
Boss: Evil Bea.

## Zat

Ruolo: Gestione del danno e sopravvivenza.  
Passiva — Guarigione Ritardata: Parte del danno diventa una quantità recuperabile nel tempo se il giocatore evita danni successivi.  
Attiva — Tempesta di Tuoni: Un tuono colpisce tutti i nemici dopo un breve preavviso.
Boss: Evil Zat.

## Alea

Ruolo: Progressione e crescita.  
Passiva — L’Aquila Non Sbaglia Mai: a intervalli regolari ottiene un effetto casuale temporaneo, positivo o negativo, con una maggiore probabilità che sia positivo.  
Attiva — Gran Piroetta: Rotazione rapida che colpisce ripetutamente i nemici vicini.
Boss: Evil Alea.

## Aleo

Ruolo: Resistenza e controllo del territorio.  
Passiva — Struttura Solida: Riduce una percentuale dei danni e aumenta la resistenza al knockback.  
Attiva — Colata di Cemento: Crea una zona di cemento che rallenta e infligge danno nel tempo.
Boss: Evil Aleo.

## Lollo

Ruolo: Velocità, caos e imprevedibilità.  
Passiva — Iperattività ADHD: Aumenta velocità di movimento e rapidità offensiva.  
Attiva — Cosplay Casuale: Usa casualmente l'attiva di un altro personaggio.
Boss: Evil Lollo.

## Migi

Ruolo: Difesa e controllo delle orde.  
Passiva — Guscio Tartarughina: Aumenta difesa; sotto soglia genera uno scudo temporaneo (con cooldown).  
Attiva — Rallentamento Zen: Zona che rallenta fortemente i nemici.
Boss: Evil Migi.

## Marghe

Ruolo: Indebolimento e manipolazione dell'aggro.  
Passiva — Sorriso Contagioso: Riduce la salute massima dei nemici (concetto: -5% come valore indicativo).  
Attiva — Reggeton time!: Genera un clone che balla reggaeton e devia l'aggro dei nemici.
Boss: Evil Marghe.

## Direzione visuale del cast

Questi archetipi originali sono la direzione presentazionale approvata per il
fondale della welcome B18O. Non rappresentano persone reali e traducono passive
e abilità in silhouette immediatamente riconoscibili; non modificano i contratti
gameplay dei profili.

| Personaggio | Descrizione visuale |
|---|---|
| Magno | Energumeno tellurico con richiami bovini, posa pesante e onda d'urto che crepa il terreno. |
| Bea | Pattinatrice agile senza casco, con capelli scuri lunghi e ricci e un capo sportivo viola durante un Powerslide basso, accompagnato da una breve scia di fuoco dietro i roller. |
| Zat | Infermiera elettrica con taglio a caschetto e divisa bianco-ciano, simbolo medico generico a cuore, luce curativa e fulmine giallo-ciano. |
| Alea | Ballerina classica nel pieno di una Gran Piroetta, circondata da un nastro circolare e un richiamo d'aquila. |
| Aleo | Muratore robusto con casco, cazzuola, secchio e una piccola colata di cemento ai piedi. |
| Lollo | Cosplayer iperattivo dai capelli scuri, con un costume originale da sopravvissuto retrofuturista post-apocalittico: tuta blu, dettagli gialli e accessori da wasteland senza marchi. |
| Migi | Donna con occhiali e capelli neri, calma e concentrata dentro uno scudo ciano a guscio di tartaruga e onde rallentanti; non è vincolata a un archetipo monastico. |
| Marghe | Ballerina reggaeton dalla corporatura morbida, con capelli neri molto lunghi, accenti magenta-oro e un clone d'ombra che replica la posa come VFX. |

---

Note:

- Questo file è il riferimento per ruoli e descrizioni dei personaggi. Le specifiche numeriche di passive e abilità attive sono definite nelle sezioni 3.4 e 3.6 di `docs/prd.md` e nei data resource (`data/friends/*.tres` e `data/abilities/*.tres`).
- Per modifiche o aggiunte aggiornare `docs/characters.md`, `docs/content-approvals.md`, la sezione delle abilità attive in `docs/prd.md` e i relativi data resource.
