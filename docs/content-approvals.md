# Registro approvazioni contenuti

Ultimo aggiornamento: 24 agosto 2026
Ambito: nomi, testi, controparti Boss, ritratti placeholder, audio e direzione
degli asset originali B18

## Approvazione del proprietario

Il proprietario del progetto ha approvato esplicitamente il 17 agosto 2026
tutti i nomi e i testi attualmente presenti nel catalogo e ha confermato che i
Boss sono le versioni malvagie degli amici, con convenzione `Evil <Nome>`.
Il 24 agosto 2026 il profilo di Bea è stato aggiornato con il nome e il copy
operativo di `Powerslide`, come richiesto nel tracker gameplay.
Nella stessa data il proprietario ha corretto il nome dell'attiva di Zat in
`Tempesta di Tuoni`: il contenuto pubblico e la presentazione non devono
descriverla come una tempesta di fulmini; gli ID tecnici storici restano stabili.

Riferimento registrato nei `FriendDefinition`:

- approvatore: `Proprietario del progetto`;
- data: `2026-08-17`;
- evidenza: conferma esplicita nella sessione Codex del 17/08/2026.

Il solo profilo Zat registra invece data `2026-08-24` e il riferimento alla
correzione esplicita **Tempesta di Tuoni** della sessione odierna.

| Contenuto | Stato | Nota pubblica |
|---|---|---|
| Magno, Bea, Zat, Alea, Aleo, Lollo, Migi, Marghe | Approvato | Nomi, ruoli, passive e descrizioni delle attive in `data/friends/*.tres` |
| Reggeton time! | Approvato | Retheme reggaeton dell'attiva di Marghe; comportamento gameplay invariato |
| Powerslide | Approvato | Nome, copy e icona inline-skate CC0 richiesti nel tracker gameplay; valori runtime registrati nel PRD |
| Tempesta di Tuoni | Approvato | Nome e copy corretti dal proprietario; nube, onde e flash comunicano il tuono senza cambiare gli ID tecnici storici |
| Evil Magno, Evil Bea, Evil Zat, Evil Alea, Evil Aleo, Evil Lollo, Evil Migi, Evil Marghe | Approvato | Ogni profilo amico contiene la propria controparte Boss |
| L'Ansia, Gossip, Ritardo Cronico, Birra, Non Ho Tempo Per Questo | Approvato | Titoli generici correnti, senza attribuzioni personali aggiuntive |
| Ritratto hero/Evil CC0 | Approvato come placeholder | Asset temporanei sostituibili dai singoli `FriendDefinition` |
| Piccioni B18H base/speciale | Baseline operativa da produrre | Due sprite originali del progetto secondo silhouette, palette e animazione definite nel piano; nessuna fonte esterna |
| Icone e VFX B18M | Baseline operativa da rifinire | Icone correnti conservate; VFX originali e procedurali secondo la grammatica delle otto abilità, con manifest prima del gate |
| Citazioni personali dei Boss | Non fornite | La UI usa il placeholder neutro del `BossDefinition`; nessuna citazione personale viene inventata |
| Audio o voce personale | Non fornito | Il campo resta nullo e il runtime rimane silenzioso |

Il primo incontro della vertical slice usa `Evil Bea`. È una scelta dati:
cambiare `friend_profile` in `data/bosses/first_boss.tres` seleziona un'altra
controparte senza modificare GDScript.

## Sprite placeholder CC0

Il foglio selezionato è **32x32 RPG Character Sprites** di Eldiran:

- pagina sorgente: https://opengameart.org/content/32x32-rpg-character-sprites;
- licenza dichiarata: CC0 1.0 Universal;
- 20 personaggi top-down, sufficienti per otto profili e otto controparti;
- file originale SHA-256:
  `40345D2EEE59F06006B2FE420F83EED288A084F7E19E9C4BA1DBD16A861C75B7`;
- derivato con il solo color key magenta convertito in trasparenza SHA-256:
  `60A60B1BEC00296E31EA2121FF1B461EDABD31075765066AF52A538B05CAE2AF`.

Licenza, provenienza e trasformazione sono conservate in
`assets/art/third_party/eldiran_rpg_characters/LICENSE.md`. CC0 consente l'uso
anche senza attribuzione; il credito viene mantenuto volontariamente per
tracciabilità.

I ritagli sono `AtlasTexture` 32×32 nei Resource dei profili. Sono coordinate
dello sprite sheet sorgente, non distanze o pixel fisici del gameplay.

## Regola di sostituzione

Per sostituire un testo o un asset non serve cambiare codice:

1. modificare il relativo `data/friends/<id>.tres`;
2. aggiornare fonte e flag `portraits_are_placeholders` per un nuovo ritratto;
3. conservare `content_approved`/`portraits_approved` soltanto con approvatore,
   data ISO e riferimento compilati;
4. rilanciare `_friend_content_smoke.gd`.

Se un flag di approvazione viene rimosso, i getter pubblici restituiscono copy e
ritratti di fallback. Un flag approvato senza record completo invalida invece
il profilo e blocca il contratto della scena.
