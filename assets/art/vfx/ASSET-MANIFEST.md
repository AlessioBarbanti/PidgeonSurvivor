# Manifest grafico VFX

## PS-002 — proiettili giocatore e ostili — 29 agosto 2026

Due master originali sono stati generati separatamente con OpenAI ImageGen
built-in per il progetto IL GIOCO. Origine e autore: progetto IL GIOCO con
assistenza OpenAI ImageGen; licenza: Licenza del progetto. Entrambi gli output
sono arrivati direttamente come PNG RGBA con angoli trasparenti, quindi non è
stata applicata rimozione chroma.

Prompt condiviso finale: master raster per un minuscolo sprite di proiettile in
un survival arcade mobile top-down; pixel art 8-bit estremamente minimale,
grandi blocchi, colori piatti, bordi duri e silhouette leggibile in movimento;
un solo soggetto orizzontale orientato rigorosamente verso destra, interamente
visibile e centrato; sfondo piatto `#00FF00` per eventuale rimozione chroma,
senza ombre, gradienti, texture, riflessi o variazioni; nessun dettaglio minuto,
particella, testo, elemento UI, badge, cornice, watermark, sheet o variante.

Prompt specifico finale giocatore, approvato dal proprietario: brace dorata
ultra-semplice; testa a losanga, corpo oro `#FFB51B`, piccolo nucleo
`#FFE85A`, una sola coda trapezoidale arancio bruciato `#E64A19` e bordo
continuo borgogna quasi nero `#2E0612`; profilo `2:1`, massimo quattro colori,
nessun ciano, fiamma separata, scintilla, crepa, venatura o cibo riconoscibile.

Prompt specifico finale ostile, approvato dal proprietario: piuma-punta magenta
ultra-semplice, più simile a un dardo che a una piuma realistica; grande punta
verso destra, corpo `#FF2F91`, rachide `#D4145A`, una sola tacca larga sopra e
sotto e bordo continuo viola quasi nero `#26052F`; massimo tre colori, nessuna
barba multipla, venatura, particella, fiamma o dettaglio sottile.

`tools/process-projectile-vfx.ps1` ritaglia i bounds alpha complessivi, conserva
il rapporto d'aspetto, applica padding trasparente, ricampiona nearest-neighbor,
azzera l'alpha residuo e quantizza opzionalmente verso una palette esatta.
Parametri finali: giocatore `32×16`, `Padding 1`, palette `#2E0612`, `#E64A19`,
`#FFB51B`, `#FFE85A`; ostile `24×16`, `Padding 1`, palette `#26052F`,
`#D4145A`, `#FF2F91`; soglia alpha visibile `32`, trasparente `16`. La metà
della risoluzione interna viene mostrata nearest alla stessa dimensione fisica
del candidato precedente: meno dettaglio, non meno visibilità. I master vivono
in `hd/` con `.gdignore` e sono esclusi da tutti i preset; il runtime referenzia
soltanto i derivati in `generated/`. La scala dello `Sprite2D` deriva dal raggio
autorevole della `CircleShape2D`; gli asset non modificano collisione, danno,
velocità o traiettoria.

| Ruolo | Master HD | Runtime | Dimensioni master/runtime | SHA-256 master | SHA-256 runtime |
|---|---|---|---|---|---|
| Giocatore | `assets/art/vfx/projectiles/hd/player_projectile_source.png` | `assets/art/vfx/projectiles/generated/player_projectile.png` | `1774×887` / `32×16` | `f6da9649e45838ca804a814bd4f6dac540fa21d4f1d43cc42240ee594834d384` | `4db8de9a77d35bcc717375da2ab863e1eeee5f5f1f368c538dc72e76e5791f01` |
| Nemico/Boss | `assets/art/vfx/projectiles/hd/enemy_projectile_source.png` | `assets/art/vfx/projectiles/generated/enemy_projectile.png` | `1774×887` / `24×16` | `2008a6a83beaa7dfc644f92810c831ab742e0a2c0dd402aa6851aa13c306cd16` | `10c2c5f90f32ee6613dc6c8af32ed788c888e1d1cb225dd55fe78668a6134930` |

## Refresh VFX runtime — 29 agosto 2026

Le icone HUD non vengono piu sovrapposte nell'arena. Le otto abilita usano ora
decal ImageGen dedicati, ancorati alla posizione, al raggio e alla fase del VFX;
non viene disegnato alcun cerchio procedurale sotto i decal, mentre restano le
sole particelle di supporto. `origine: progetto IL GIOCO`; autore: progetto IL GIOCO con assistenza
OpenAI ImageGen; licenza: Licenza del progetto.

Prompt condiviso: VFX pixel-art top-down per survival arcade mobile, forme
chunky leggibili sopra un'arena affollata, centro libero quando contiene il
Player, nessun testo, icona, badge, cornice, card, marchio o watermark. Ogni
richiesta ha specificato un fondale cromatico uniforme; ImageGen built-in ha
restituito direttamente PNG RGBA con angoli trasparenti, quindi la rimozione
chroma non e stata necessaria.

Eccezione PS-028, 1 settembre 2026: la rigenerazione della Gran Piroetta ha
usato come riferimento il raster precedente e un fondale uniforme `#00FF00`,
perché i primi output trasparenti incorporavano il motivo a scacchi. Il chroma
è stato rimosso con alpha morbido basato sull'eccesso di verde
`G - max(R, B)` e despill dei bordi; il master RGBA risultante è stato poi
ricampionato senza crop a `512×512` con `tools/process-ability-vfx.ps1` e
soglia alpha `32`. Generatore: OpenAI ImageGen built-in; autore: progetto IL
GIOCO con assistenza OpenAI ImageGen; licenza: Licenza del progetto.

I master `1254x1254` sono conservati in `assets/art/vfx/abilities/hd/`, esclusi
da import ed export con `.gdignore` e preset. `tools/process-ability-vfx.ps1`
li ricampiona sull'intero canvas a `512x512` RGBA con bicubica di alta qualita e
azzera soltanto l'alpha residuo sotto `32`, senza crop o deformazioni. Il runtime
lascia al decal la comunicazione visiva dell'area, senza una base circolare, e usa
filtro nearest sui master pixel-art; `earthquake_wave` e' pittorico e usa filtro
lineare, perche' nearest su un rescale non intero sfarfallava in espansione.
`zen_field` e `thermal_frost` sono altrettanto pittorici ma condividono il nodo
con un master pixel-art (`grand_spin`, `thermal_bloom`): la scelta fra
rigenerarli in pixel-art e separarli in CanvasItem distinti resta aperta.

| Abilita/fase | Master HD | Runtime | Prompt specifico | SHA-256 master | SHA-256 runtime |
|---|---|---|---|---|---|
| Onda d'Urto Tellurica | `assets/art/vfx/abilities/hd/earthquake_wave_source.png` | `assets/art/vfx/abilities/generated/earthquake_wave.png` | Anello irregolare, otto crepe radiali, pietre e polvere ocra, centro aperto | `a66138b384e95efb63148c089947bb2728fad0952f8b6d3ae35177197596e858` | `9c33cb3ab22902ea7375d43b31a835252513171000687d07c07c5641ec905383` |
| Powerslide | `assets/art/vfx/abilities/hd/fire_trail_source.png` | `assets/art/vfx/abilities/generated/fire_trail.png` | Nastro orizzontale di fiamma con nucleo crema, corpo arancio e bordo magenta raccordabile | `09105cd15307dba9cc29889a08d570af2800004667ef599a61ba292179f1214e` | `4a6e63783e4a7d3f48f331abc612bca8c9db53e2bd57d8e07c393f519b9aaeae` |
| Tempesta di Tuoni | `assets/art/vfx/abilities/hd/lightning_impact_source.png` | `assets/art/vfx/abilities/generated/lightning_impact.png` | Impatto elettrico con starburst, archi spezzati e quattro forche radiali | `7b564bdb06ee057b5b1e3b94bcee918226ef2654174a90f64cd5eab0c5195f5c` | `96edc537d5ae9a533aee35d7c8901e7c9243b14508a3f626761bd3463453bb90` |
| Gran Piroetta | `assets/art/vfx/abilities/hd/grand_spin_source.png` | `assets/art/vfx/abilities/generated/grand_spin.png` | Corona pixel-art rosa/magenta, crema e oro realmente circolare, centro aperto, peso uniforme sui quattro quadranti, moto orario continuo e nessuna stella; stesso centro e raggio apparente del riferimento | `d6c32c1844bdd5273616f5728ea411ee5befa77be61449df41b530acec2923bf` | `cb9db79e4c11a50f8dee24730e63f6fc41824625b2badf0fc8d9948b5084d918` |
| Shock Termico - brina | `assets/art/vfx/abilities/hd/thermal_frost_source.png` | `assets/art/vfx/abilities/generated/thermal_frost.png` | Corona di lastre e dodici punte di ghiaccio rivolte verso il centro | `4b5bcf8148305ffc90a2ce7188d75fc1e0c4ac3a22b00e03bd8dc55cb2d51e17` | `22d59f73f0ef4516e4242903d744836857513ab12a95d2e40980b593b5b041a6` |
| Shock Termico - bloom | `assets/art/vfx/abilities/hd/thermal_bloom_source.png` | `assets/art/vfx/abilities/generated/thermal_bloom.png` | Detonazione arancio con nucleo bianco e tre anelli spezzati | `31d2586485bfd7b604e922b6e1bebb3e91271a1032d713c1e14c3b6b52e6fa86` | `04a279732475d5019a73eae403b6b56f938fa125a3d2f3548ed7ec266ac88952` |
| Cosplay Casuale | `assets/art/vfx/abilities/hd/cosplay_reveal_source.png` | `assets/art/vfx/abilities/generated/cosplay_reveal.png` | Reveal stellato con nastri ciano, viola e oro, piu coriandoli radi | `dda7841cb5f68c0986488502f05762e92ec9aca49f8c9ef5c59a55bfb03c47e2` | `7564e6792f9c2dd42cf2c27a3c3a796460185e38986070d4a972b82df6206999` |
| Rallentamento Zen | `assets/art/vfx/abilities/hd/zen_field_source.png` | `assets/art/vfx/abilities/generated/zen_field.png` | Onde acqua spezzate, foglie lente e geometria di loto suggerita | `25ee829abb731d5f266e7fb2f2767f07fad8017d0c4892ffbab80f8b15a819d6` | `73412c3ae7db1b4dc72a9affc91b0d50a39040c4cdfb7478f1265ec683709a06` |
| Reggaeton time! | `assets/art/vfx/abilities/hd/reggaeton_decoy_source.png` | `assets/art/vfx/abilities/generated/reggaeton_decoy.png` | Clone anonimo viola e boombox neon in vista top-down tre quarti | `fa3b1189fe7771245da4afe1fc2e1fbb5db62bcf8c44ab813ebd17f3a7c00963` | `bf4c4d2c9265b5de7547f9378e28d3fc9302202a3f9e0a83e9fd18d2da8b48c7` |

Integrazione corrente (i record procedurali successivi restano lo storico
B18M precedente al refresh):

| Percorso | Funzione corrente | SHA-256 |
|---|---|---|
| `scripts/abilities/earthquake_wave.gd` | Decal tellurico senza cerchio sottostante, in espansione entro il 15% della durata e con opacita' massima `0,62` | `cbc9f558b687f307eb8c0ce7b6730b8b19d84bc86f31f76063ded667f7074d2e` |
| `scripts/abilities/fire_z_trail.gd` | Tasselli di fiamma specchiati a alternanza lungo il segmento e scintille subordinate al nastro per opacita', taglia e tinta (PS-042) | `39346b07d7aef0f95b88b2dd29092bfd02150e2ff52c0ec4166fe07fec54193c` |
| `scripts/abilities/lightning_storm.gd` | Preavviso e decal d'impatto inscritti per ogni bersaglio fotografato, tinti per fascia di carica, senza flash fullscreen (PS-004) | `d111ad7172d77c2dc5abbab003b25ce6581ff83c0b1c99529282bcf98203d68e` |
| `scripts/abilities/ability_area_effect.gd` | Decal Piroetta e Zen senza base circolare; Piroetta a due giri per attivazione | `7e7ed0664d50609d423a9b10bfb68402dac650e6d91bf6746bf43e575eaae31d` |
| `scripts/abilities/cosplay_accent.gd` | Decal reveal e coriandoli senza anello sottostante | `72521e3e91469c6fc9b4160e8853e5c1d027eb0dd863097996c09b05d0af9664` |
| `scripts/abilities/thermal_shock.gd` | Decal separati per brina e bloom senza basi o anelli procedurali | `4316a441084c661934991561309e0f18059d7fb344c880dc37b3c2d5814bb09c` |
| `scripts/abilities/illusion_decoy.gd` | Clone e boombox raster con note animate, senza aura circolare | `44126e90d493708de81e63167c4e75249aa75a855ced1a8b85d347c212053bde` |
| `scripts/abilities/instinctive_dodge_accent.gd` | Tell Sesto Senso Equino invariato | `6a07ae5b742a3bc92d5a79a4288c075d6e73005a7e00a803e46185dc331c8aa7` |

Budget corrente: massimo un overlay fullscreen, 64 particelle logiche e due
materiali aggiuntivi per attivazione; zero materiali custom nelle otto famiglie.
Il vecchio `ability_icon_burst.gd` resta storico ma non viene piu istanziato.

La baseline B18M conserva le primitive procedurali e usa otto nuovi emblemi
pixel-art originali prodotti il 24 agosto 2026 con la modalità built-in di
OpenAI ImageGen. Gli emblemi sono sia icone HUD sia texture delle rispettive
animazioni di attivazione scene-local. Non sono stati usati marchi, personaggi o
asset grafici esterni. `origine: progetto IL GIOCO`; autore dichiarato con
assistenza OpenAI ImageGen; licenza: Licenza del progetto.

Il vecchio pittogramma Powerslide Pinhead CC0 resta nel repository come fonte
storica documentata, ma non è più consumato dal runtime.

## Sorgenti procedurali runtime

| Percorso | Origine | Autore | Licenza | Trasformazioni | SHA-256 |
|---|---|---|---|---|---|
| `scripts/abilities/earthquake_wave.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Anelli concentrici e crepe disegnati con primitive `CanvasItem` | `dcba84a86bef2c0b337df98817eae1aaf4f9f809f318a5c3e4a36aa9fa466b84` |
| `scripts/abilities/fire_z_trail.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Nastro a due livelli e 16 scintille deterministiche, subordinate al nastro per opacita', taglia e tinta (PS-042) | `39346b07d7aef0f95b88b2dd29092bfd02150e2ff52c0ec4166fe07fec54193c` |
| `scripts/abilities/lightning_storm.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Fotografa i nemici vivi e colpisce ciascuno con un decal tinto per fascia di carica, nessuna posizione telegrafata fissa (PS-004) | `d111ad7172d77c2dc5abbab003b25ce6581ff83c0b1c99529282bcf98203d68e` |
| `scripts/abilities/ability_area_effect.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Archi rotanti, pozza con bolle e campo zen con anelli e moti lenti; il campo zen assorbe anche i proiettili ostili nel raggio, stesso disegno (B45) | `4a5eabf0409b07b9dfd95787cf2d0346c92296db5263ec41afdd40206e611578` |
| `scripts/abilities/cosplay_accent.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Coda B18R non interattiva da 18 coriandoli, con entrata/uscita centralizzate nella palette dell'abilità copiata | `8d62630788467479ff2fbbf1587f753c2212c32e8720e81e1379b80bd2b9cff1` |
| `scripts/abilities/thermal_shock.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Corona di brina contrattile con 12 schegge e bloom di calore a tre anelli | `581ae10c475c789b2f9c1d623d9b31938181703a4f4e2d58ba8207c526276836` |
| `scripts/abilities/illusion_decoy.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Clone ballerino, cassa pulsante e sei note musicali | `01df1dc441abf245404b8cb6bf794753b6df77b2efb893c3c3d15acf74ace07d` |
| `scripts/abilities/ability_icon_burst.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Otto profili B18R da `1,20 s` con entrata/uscita centralizzate; coda non interattiva e clock solo `RUNNING` | `19790185309cbda01378ed93fad00f6554687129c9e741841178fc68e066f9e5` |
| `scripts/abilities/instinctive_dodge_accent.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Tell del Sesto Senso Equino di Bea (B45): sagoma a ferro di cavallo e scia viola non interattiva, stesso schema di entrata/uscita centralizzata delle altre code | `57d9f40966aa37c523f4d67f4a235d3ff5671d4b746097d0aca7a29c073847b6` |

## Emblemi ImageGen definitivi

Prompt condiviso: icona e texture VFX pixel-art arcade caricaturale, silhouette
netta leggibile a `42 px`, composizione quadrata centrata, margine uniforme,
palette limitata, nessun testo, numero, cornice, card, marchio o watermark.
Ogni richiesta ha usato uno sfondo cromatico uniforme; il built-in ha restituito
direttamente PNG RGBA trasparenti. Il 26 agosto 2026 il padding trasparente
residuo è stato eliminato con un crop quadrato minimo sul bounding box alpha,
senza deformare il soggetto; ogni immagine è stata quindi ricampionata Lanczos
a `256×256` e ottimizzata PNG.

| Percorso | Origine | Autore | Licenza | Prompt specifico e trasformazioni | SHA-256 |
|---|---|---|---|---|---|
| `assets/art/icons/abilities/generated/earthquake.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Roccia spaccata, due anelli d'impatto e polvere; crop quadrato stretto, ricampionamento Lanczos e ottimizzazione PNG | `4e70c0709feeab212b9b98047644e502cb97ecb5d1243f8a6af6f45e2867554c` |
| `assets/art/icons/abilities/generated/powerslide.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Pattino inline, scia a Z e scintille; crop quadrato stretto, ricampionamento Lanczos e ottimizzazione PNG | `0f5f63863cbc75484f6fc6588d359a850aacb925b951f3cccf473f3d430b18d7` |
| `assets/art/icons/abilities/generated/lightning.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Nube, singolo fulmine e onde del tuono; crop quadrato stretto, ricampionamento Lanczos e ottimizzazione PNG | `b4855096b97e52894cfc13904d85520ad3db38381c684e0f68a4078d7b930603` |
| `assets/art/icons/abilities/generated/grand_spin.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Gonna da piroetta, archi opposti e scintille; crop quadrato stretto, ricampionamento Lanczos e ottimizzazione PNG | `5bbb7d19d5b89d8353ee28433167298f5d7ca69863700f61ac1998a9f3722014` |
| `assets/art/icons/abilities/generated/thermal_shock.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Corona di schegge di ghiaccio attorno a un nucleo di calore esploso, con due volute di vapore; chroma key rimosso con despill sui bordi, crop quadrato stretto sul bounding box alpha, ricampionamento Lanczos a `256×256` e ottimizzazione PNG. Master trasparente conservato in `hd/thermal_shock_source.png` (`a50dbe37fb0deb8a2964f8e637862f0ffb499b0893b8113fb4b79de25f550ffc`), escluso da import ed export | `f5a5f9900b8eebeca6392e7680b9fb4b501d3ddd69c96e65ec78ed64124493c3` |
| `assets/art/icons/abilities/generated/cosplay.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Maschera, stella mistero e coriandoli; crop quadrato stretto, ricampionamento Lanczos e ottimizzazione PNG | `6b9e92a085ae43cc0ddb35b908977bdfbece064a47d4a503291cee6692ede2b2` |
| `assets/art/icons/abilities/generated/zen.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Loto, onde di respiro e moti; crop quadrato stretto, ricampionamento Lanczos e ottimizzazione PNG | `dd51818ed667b92f56d131fca316f4b9f51035c0a8c111b368e062004c6ad483` |
| `assets/art/icons/abilities/generated/reggaeton.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Cassa, silhouette danzante e note; crop quadrato stretto, ricampionamento Lanczos e ottimizzazione PNG | `f315f7ce9cab7f736742278c5e2817f32e6619b3f18382a90d0e5c77f1718555` |

Il budget dichiarato è verificato da `tests/unit/test_b18m_ability_visuals.gd`: per singola
attivazione non più di un overlay fullscreen, 64 particelle logiche, un emblema
ImageGen e due materiali aggiuntivi. Queste implementazioni usano zero materiali
custom; il solo overlay fullscreen appartiene a Tempesta di Tuoni.
