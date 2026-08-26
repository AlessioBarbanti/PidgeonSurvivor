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
| `scripts/abilities/fire_z_trail.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Nastro a due livelli e 16 scintille deterministiche | `c2a7a1a51197578b7b1d5545fe71515aa3e2bcfeedf430b6db1cb1caf465c541` |
| `scripts/abilities/lightning_storm.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Nube, saetta, onde del tuono e overlay accessibile | `2c84564d1ada2fd92765baa225ca154321e66f6cdab9f86e0911c4e69220f987` |
| `scripts/abilities/ability_area_effect.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Archi rotanti, pozza con bolle e campo zen con anelli e moti lenti | `f1e40c89f75fe38893e16853ad96d5180f383a239636865c8d519f8cb8e0c988` |
| `scripts/abilities/cosplay_accent.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Coda B18R non interattiva da 18 coriandoli, con entrata/uscita centralizzate nella palette dell'abilità copiata | `8d62630788467479ff2fbbf1587f753c2212c32e8720e81e1379b80bd2b9cff1` |
| `scripts/abilities/illusion_decoy.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Clone ballerino, cassa pulsante e sei note musicali | `01df1dc441abf245404b8cb6bf794753b6df77b2efb893c3c3d15acf74ace07d` |
| `scripts/abilities/ability_icon_burst.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Otto profili B18R da `1,20 s` con entrata/uscita centralizzate; coda non interattiva e clock solo `RUNNING` | `a963236264bfe3dfa1329c11a96649f105ab16e642065cf6cfd83134a61e32eb` |

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
| `assets/art/icons/abilities/generated/cement.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Secchio, colata e bolle di cemento; crop quadrato stretto, ricampionamento Lanczos e ottimizzazione PNG | `13475b5003ebef8949985c16321a839dbcda1302df916a1e50a5c7838a8f4dc4` |
| `assets/art/icons/abilities/generated/cosplay.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Maschera, stella mistero e coriandoli; crop quadrato stretto, ricampionamento Lanczos e ottimizzazione PNG | `6b9e92a085ae43cc0ddb35b908977bdfbece064a47d4a503291cee6692ede2b2` |
| `assets/art/icons/abilities/generated/zen.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Loto, onde di respiro e moti; crop quadrato stretto, ricampionamento Lanczos e ottimizzazione PNG | `dd51818ed667b92f56d131fca316f4b9f51035c0a8c111b368e062004c6ad483` |
| `assets/art/icons/abilities/generated/reggaeton.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Cassa, silhouette danzante e note; crop quadrato stretto, ricampionamento Lanczos e ottimizzazione PNG | `f315f7ce9cab7f736742278c5e2817f32e6619b3f18382a90d0e5c77f1718555` |

Il budget dichiarato è verificato da `_ability_visuals_smoke.gd`: per singola
attivazione non più di un overlay fullscreen, 64 particelle logiche, un emblema
ImageGen e due materiali aggiuntivi. Queste implementazioni usano zero materiali
custom; il solo overlay fullscreen appartiene a Tempesta di Tuoni.
