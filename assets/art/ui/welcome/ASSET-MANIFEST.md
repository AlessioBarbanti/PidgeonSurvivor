# Manifest grafico welcome B18O

Fondale della schermata iniziale di Pidgeon Survivor, prodotto con la modalità
built-in di OpenAI ImageGen. La versione runtime corrente è il refresh identità
del cast del 28 agosto 2026: usa come edit target la reference pixel-art
approvata e come riferimenti di identità gli otto master del proprietario in
`assets/art/characters/<id>/hd/poses.png`. I riferimenti derivano da fotografie di
persone reali fornite e autorizzate esplicitamente dal proprietario; il
risultato resta una caricatura pixel-art non fotorealistica. Il runtime non
dipende dal servizio di generazione.

Origine: OpenAI ImageGen built-in.  
Autore: progetto IL GIOCO con assistenza OpenAI ImageGen.  
Licenza: Licenza del progetto.

## File runtime

| Percorso | Dimensioni | Trasformazioni | SHA-256 |
|---|---:|---|---|
| `welcome_ability_cast_background.png` | `1664×936` RGB PNG | Refresh identità del 28 agosto dai master B18U; Lollo appoggiato, corna decorative di Magno rafforzate e onde ciano davanti a Bea rimosse; poi crop centrale 16:9 senza ricampionamento; mostrato con `KEEP_ASPECT_COVERED` più tint runtime | `fe721f5a98048fb8db4093700af50b0ac9a070b1af92582b4b16059d9d8f1ba9` |
| `welcome_logo.png` | `1536×1024` RGBA PNG | Versione finale modificata e fornita dal proprietario, nessuna trasformazione locale; visualizzata proporzionalmente in un `TextureRect` centrale | `c2a63add4753ece374cf673d636d12cce55e55cd43624aed645bf8f5c347fa9f` |

Sorgente HD conservato fuori dall'import e dai tre preset di export:

| Percorso | Dimensioni | SHA-256 |
|---|---:|---|
| `hd/welcome_ability_cast_identity_source.png` | `1672×941` RGB PNG | `ea746bbe40d4aa9c575fbf1728218c16fbb16b30c9acdc137d7ef86db58d2bda` |

La cartella `hd/` contiene `.gdignore` ed è esclusa esplicitamente dai preset
Windows, Android APK e Android AAB.

Il fondale è dedicato alla welcome e non sostituisce lo sfondo arena pianificato
in B18S. Il pannello, il titolo e i pulsanti restano UI nativa Godot per
preservare testo esatto, focus, safe area e accessibilità multipiattaforma.

## Catena di trasformazione della versione runtime

L'edit di refresh ha prodotto un PNG RGB `1672×941`, conservato come sorgente HD.
Per ottenere il file runtime è stato applicato soltanto un crop centrale senza
ricampionamento: `4 px` per lato, `2 px` sopra e `3 px` sotto, ottenendo un PNG
RGB 16:9 esatto `1664×936`. Nessun ritocco manuale, ridimensionamento o testo
raster è stato aggiunto.

## Logo welcome fornito

`welcome_logo.png` è stato fornito dal proprietario del progetto nella sessione
del 24 agosto 2026 con richiesta esplicita di usarlo al centro della welcome.
Autore, generatore e licenza a monte non sono stati dichiarati; il registro non
li inventa. Il file viene consumato senza trasformazioni come `TextureRect`
proporzionale. Il testo e l'insegna appartengono al logo, mentre pulsanti,
impostazioni, focus e target touch restano UI nativa Godot.
Il rebrand confermato nella stessa data riconosce come esatte le stringhe già
presenti nel raster: titolo `Pidgeon Survivor` e sottotitolo
`It's grilling time!`; il file non richiede trasformazioni.

## Prompt fondale base

Definisce ambiente, palette, illuminazione, piccioni e area menu protetta che
ogni versione successiva ha dovuto preservare.

```text
Use case: stylized-concept
Asset type: 16:9 game title-screen background for a Windows and Android friendship-survival arcade game
Primary request: create an original, polished pixel-art splash background that feels playful, warm, chaotic, and unmistakably like a real game menu rather than a debug screen
Scene/backdrop: a whimsical night-time outdoor survival arena inspired by an Italian summer party, with warm string lights, a few picnic tables and barbecue glow in the far background, subtle city silhouettes and an energetic flock of pigeons swooping around the outer edges
Subject: a small ensemble of eight distinct, silly chibi adventurer friends gathered along the lower left and lower right edges, ready for absurd action; readable as a friendly ensemble but not based on real people
Style/medium: professional hand-crafted 2D pixel-art arcade illustration, crisp clustered pixels, chunky silhouettes, limited but rich palette, playful caricature, not photorealistic, not painterly, not cyber-tech
Composition/framing: wide landscape 16:9; keep the central 45% of the canvas visually quiet, dark, and low-detail as protected negative space for a title and menu panel; place characters, pigeons, props, sparks, confetti, and brighter accents mainly around the left/right edges and lower corners; support safe cropping to 20:9 and 4:3
Lighting/mood: deep navy twilight, warm amber barbecue and string-light highlights, cyan moonlight accents, small magenta details; cheerful and adventurous with gentle depth
Color palette: deep navy and indigo base, warm amber and golden yellow, cyan highlights, restrained magenta accents; sufficient dark midtones behind UI
Constraints: no text, no letters, no numbers, no logo, no UI controls, no frame, no watermark; no realistic faces; no gore; no guns; no false obstacle grid; no bulky sci-fi panels; maintain strong readability and low contrast in the central UI-safe area; the image itself must fill the full canvas without a border
```

## Prompt refresh identità del cast — versione runtime corrente

```text
Use case: precise-object-edit
Asset type: 16:9 Windows and Android pixel-art welcome-screen background
Input: preserve the approved welcome background exactly; use the eight supplied
character masters only as identity, hairstyle, body-shape, costume and ability
references.

Replace the eight existing physical characters, keeping their established slots:
upper-left Aleo, lower-left Magno/Alea/Marghe, upper-right Lollo, lower-right
Migi/Bea/Zat. Preserve the deep navy night, moon, pigeons, platforms, barbecue
glow, palette, camera, pixel clusters and the dark protected menu-safe area
x=31%-69%, y=9%-70%.

Aleo: stocky brown-haired bearded thermotechnician with rectangular glasses,
black HVAC uniform, red/blue gauges, hoses and probe. Magno: fully human, very
muscular, swept brown hair and beard, bull-emblem outfit with decorative horn
motifs. Alea: slender blonde ballerina with glasses, white-gold costume and cyan
gems. Marghe: visibly fuller and softly curvy, round face, tortoiseshell glasses,
very long dark hair, purple-gold reggaeton outfit and one flat VFX shadow clone.
Lollo: lean angular face, dark swept pompadour, brass-blue goggles and original
blue-gold retrofuturist outfit. Migi: black low bun, round light-metal glasses,
teal-charcoal clothing and cyan turtle-shell shield. Bea: curvy athletic skater,
black glasses, voluminous curls, mandatory lavender bandana, purple roller outfit,
low powerslide with both skates correctly grounded and a short fire trail. Zat:
slender, long narrow smiling face, shoulder-length brown hair and white-cyan-gold
electric field-medic outfit.

Strict invariants: exactly eight physical humans; Marghe's shadow is VFX only.
No extra body, mannequin, duplicate, text, logo, UI, watermark, border, gun,
gore, branded costume or Red Cross emblem. Do not place faces, torsos or bright
props in the protected center. Keep the characters grounded and anatomically
coherent, with the left/right sprite identity distinctions reflected in pose.
```

Una passata di pulizia ha rimosso il corpo blu residuo sotto Lollo. Su richiesta
del proprietario, l'ultima correzione abbassa soltanto Lollo di pochi pixel e
porta entrambi gli stivali a contatto leggibile con la piattaforma superiore,
senza ridisegnare il personaggio o modificare gli altri sette.
La passata successiva rende più leggibile il motivo bovino di Magno con una
coppia simmetrica di corna curve montate sull'armatura e rimuove le onde ciano
sul terreno davanti ai pattini di Bea, conservando la scia di fuoco arancione.

## Passaggi superati

I raster intermedi delle prove precedenti sono stati rimossi: il repository
conserva soltanto la versione runtime corrente e il suo sorgente HD. I prompt
integrali dei passaggi superati restano recuperabili dalla cronologia git di
questo manifest.

| Data | Passaggio | Esito |
|---|---|---|
| 24 agosto 2026 | Fondale base senza cast, output built-in `1711×919` con crop centrale `38/39 px` a `1634×919` | Superato dal cast abilità |
| 24 agosto 2026 | Prima variante cast abilità: otto personaggi originali sulle slot esterne | Superato dalle correzioni successive |
| 24 agosto 2026 | Correzioni mirate su Migi, Marghe, Bea e Lollo | Superato dal refresh identità |
| 24 agosto 2026 | Correzione Bea, rimozione casco e capelli ricci lunghi | Superato dal refresh identità |
| 24 agosto 2026 | Correzione Lollo e Zat, capelli scuri e divisa da infermiera | Superato dal refresh identità |
| 24 agosto 2026 | Pulizia reference e ricomposizione cast per liberare l'area menu | Confluito nella versione corrente |
| 28 agosto 2026 | Refresh identità del cast dai master B18U, Lollo abbassato, corna di Magno rafforzate e onde ciano davanti a Bea rimosse | **Versione runtime corrente** |
