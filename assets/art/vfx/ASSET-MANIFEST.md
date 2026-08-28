# Manifest grafico B18M

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
| `scripts/abilities/fire_z_trail.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Nastro a due livelli e 16 scintille deterministiche | `e5b7f395566944412d67852c4284e8cc808d9076d59f5e756d5ef1e2b94da305` |
| `scripts/abilities/lightning_storm.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Nubi e saette telegrafate per fulmine, bagliori residui e overlay accessibile (B43) | `9f55fe6858eaeb32c673b1c237ae26f74aa4f5da9109e363a3bafba6e63b6c63` |
| `scripts/abilities/ability_area_effect.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Archi rotanti, pozza con bolle e campo zen con anelli e moti lenti; il campo zen assorbe anche i proiettili ostili nel raggio, stesso disegno (B45) | `4a5eabf0409b07b9dfd95787cf2d0346c92296db5263ec41afdd40206e611578` |
| `scripts/abilities/cosplay_accent.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Coda B18R non interattiva da 18 coriandoli, con entrata/uscita centralizzate nella palette dell'abilità copiata | `8d62630788467479ff2fbbf1587f753c2212c32e8720e81e1379b80bd2b9cff1` |
| `scripts/abilities/thermal_shock.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Corona di brina contrattile con 12 schegge e bloom di calore a tre anelli | `581ae10c475c789b2f9c1d623d9b31938181703a4f4e2d58ba8207c526276836` |
| `scripts/abilities/illusion_decoy.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Clone ballerino, cassa pulsante e sei note musicali | `01df1dc441abf245404b8cb6bf794753b6df77b2efb893c3c3d15acf74ace07d` |
| `scripts/abilities/ability_icon_burst.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Otto profili B18R da `1,20 s` con entrata/uscita centralizzate; coda non interattiva e clock solo `RUNNING` | `19790185309cbda01378ed93fad00f6554687129c9e741841178fc68e066f9e5` |
| `scripts/abilities/instinctive_dodge_accent.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Tell dello Scarto Istintivo di Bea (B45): sagoma a ferro di cavallo e scia viola non interattiva, stesso schema di entrata/uscita centralizzata delle altre code | `57d9f40966aa37c523f4d67f4a235d3ff5671d4b746097d0aca7a29c073847b6` |

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

Il budget dichiarato è verificato da `_ability_visuals_smoke.gd`: per singola
attivazione non più di un overlay fullscreen, 64 particelle logiche, un emblema
ImageGen e due materiali aggiuntivi. Queste implementazioni usano zero materiali
custom; il solo overlay fullscreen appartiene a Tempesta di Tuoni.
