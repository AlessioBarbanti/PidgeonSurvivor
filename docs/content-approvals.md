# Registro approvazioni contenuti

Ultimo aggiornamento: 27 agosto 2026
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
| L'Ansia, Gossip, Ritardo Cronico, Birra, Non Ho Tempo Per Questo, Grigliata estiva | Approvato | Titoli generici correnti, senza attribuzioni personali aggiuntive |
| Ritratto hero/Evil CC0 | Approvato come placeholder | Asset temporanei sostituibili dai singoli `FriendDefinition` |
| Piccioni B18H base/speciale | Approvato e integrato | Due sprite originali OpenAI-assisted del progetto secondo silhouette, palette e animazione definite nel piano; manifest, trasformazioni e hash conservati, nessun input grafico di terzi |
| Varianti Boss B22 | Approvate come riuso | Il piccione speciale B18H è la baseline; gli otto Evil riusano gli sprite Player B18U già approvati con sola modulazione viola/magenta runtime. Nessun nuovo raster, citazione, voce, passiva o abilità personale entra in B22 |
| Icone e VFX B18M | Approvato e integrato; timing B18R verificati | Otto emblemi PNG originali OpenAI ImageGen sostituiscono gli SVG e animano l'attivazione; prompt, trasformazioni, licenza e hash sono nel manifest. Il burst da `1,20 s` e le code non interattive hanno superato automatici, Windows, Android e verifica umana il 25 agosto 2026 |
| Icone passive del roster B18W | Approvate e integrate | Otto PNG raster dedicati (Magno più sette master RGBA forniti dal proprietario) sostituiscono il fallback al ritratto nel kit. Prompt, origine, trasformazioni e hash sono in `assets/art/icons/passives/ASSET-MANIFEST.md`; confronto percettivo fisico chiuso il 25 agosto 2026 |
| Fondale e logo welcome B18O | Approvato e integrato | La reference pixel-art approvata dal proprietario è stata ripulita con OpenAI ImageGen built-in: nessuna UI resta nel fondale, gli otto archetipi sono ai bordi e il centro è protetto. `welcome_logo.png`, fornito dal proprietario, occupa il centro senza trasformazioni; autore, generatore e licenza a monte non dichiarati non vengono inventati. Nessuna foto o persona reale; prompt, origine, crop e SHA-256 sono nel manifest dedicato |
| Sfondo arena B18S | Approvato e integrato | Due varianti originali OpenAI ImageGen built-in sono state confrontate; soltanto la texture materica non semantica scelta entra nel runtime come PNG RGB `768×512`. Prompt, autore, licenza, downscale nearest-neighbor e SHA-256 sono nel manifest; automatici, Windows, APK, Pixel 9 20:9 e confronto finale a luminosità controllata sono chiusi |
| Identità pubblica | Approvata | Titolo esatto `Pidgeon Survivor`; sottotitolo esatto `It's grilling time!`. Il logo B18O fornito dal proprietario contiene già entrambe le stringhe corrette e resta invariato |
| Icona applicazione | Approvata e integrata | Su richiesta del proprietario, master quadrato OpenAI ImageGen built-in con un piccione, occhiali pixel, collo iridescente e alone da griglia; nessun testo. Un secondo output trasparente è il foreground adattivo Android. Uso progetto/Windows/Android, prompt, trasformazioni e SHA-256 sono nel manifest dedicato |
| Sprite Player B18U | Approvati e integrati | Otto archetipi fittizi OpenAI ImageGen built-in confrontati con il fondale welcome B18O e con la conversazione di approvazione del 24 agosto; Magno, Zat, Alea, Aleo e Marghe sono stati corretti per riallinearli. Le strisce runtime, le sorgenti HD trasparenti escluse dagli export, prompt, trasformazioni, licenza e SHA-256 sono nel manifest dedicato; gate percettivo chiuso il 25 agosto 2026 |
| Citazioni personali dei Boss | Non fornite | La UI usa il placeholder neutro del `BossDefinition`; nessuna citazione personale viene inventata |
| Audio o voce personale | Non fornito | Il campo resta nullo e il runtime rimane silenzioso |
| Musica di sottofondo B29 | Integrata, verifica percettiva aperta | `Super Wreck Roadway (loop)` di Umplix, da OpenGameArt, CC0 1.0 Universal. La fonte pubblica espone il loop WAV; il proprietario ha fornito l'OGG runtime. URL, licenza, data di acquisizione, trasformazione dichiarata e SHA-256 sono in `assets/audio/third_party/super_wreck_roadway_loop.MANIFEST.md`; il credito volontario è in `docs/credits.md` |
| Welcome B32 | Riuso nativo, verifica percettiva aperta | `GIOCA` riusa esclusivamente `character_select_cta_base.png`, già approvata per B18W; testo, ingranaggio, focus e pressed sono controlli Godot nativi. Non entra alcun nuovo raster né nuovo contenuto personale. |

Da B22 `data/bosses/first_boss.tres` descrive il piccione speciale baseline.
`BossEncounter` può derivarne in modo seed-deterministico uno degli otto
`Evil <Nome>` senza modificare gli asset sorgente o attribuire contenuti
personali non approvati.

## Icone upgrade B26/B27

Dieci master PNG RGBA sono stati forniti già generati dal proprietario in
`assets/art/icons/upgrades/hd/`. Non sono stati forniti prompt, generatore,
autore o licenza terza riproducibile: tali dati non vengono inventati. Il
proprietario ne autorizza l'uso nel progetto; non sono dichiarate persone reali,
marchi o sorgenti di terzi.

`tools/process-upgrade-icon.ps1` individua la silhouette alpha, aggiunge `12`
pixel di margine quadrato e riduce nearest-neighbor a `128×128` RGBA. Soltanto
i derivati `generated/` sono referenziati dalle carte; master, trasformazioni,
mapping e SHA-256 sono nel
[`manifest upgrade`](../assets/art/icons/upgrades/ASSET-MANIFEST.md).

## Sprite originali B18H

I piccioni base e speciale sono asset originali commissionati dal progetto con
il tool integrato di generazione immagini OpenAI, senza immagini sorgente o
personaggi di terzi. Le strisce finali sono PNG RGBA `144x48` con tre canvas
`48x48`: posa neutra, ali alte e ali basse. La variante base entra nello spawn
ordinario; la speciale è il Boss baseline B22.

Prompt normalizzati, trasformazioni nearest-neighbor, stato d'uso e SHA-256 sono
registrati in
[`assets/art/enemies/pigeons/ASSET-MANIFEST.md`](../assets/art/enemies/pigeons/ASSET-MANIFEST.md).

## Sprite Player originali B18U

Gli otto sprite gameplay sono asset originali del progetto generati con OpenAI
ImageGen built-in e confrontati direttamente con il cast approvato della
welcome B18O. Non rappresentano persone reali e non contengono marchi o loghi;
Zat usa soltanto un simbolo medico generico a cuore.

Le strisce runtime `96×32` contengono passo A, idle e passo B. Le corrispondenti
sorgenti RGBA `1536×1024` sono conservate in
`assets/art/characters/players/hd/` per riusi futuri, ma `.gdignore` e i filtri
di export impediscono che entrino nel runtime o nei pacchetti distribuiti.
Prompt finali, correzioni rispetto alla welcome, pipeline deterministica e hash
sono registrati nel
[manifest B18U](../assets/art/characters/players/ASSET-MANIFEST.md).

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
