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
direttamente PNG RGBA trasparenti. Trasformazioni comuni: crop sul bounding box
alpha, ricentratura con circa `8%` di margine per lato, downscale Lanczos a
`256×256` e ottimizzazione PNG.

| Percorso | Origine | Autore | Licenza | Prompt specifico e trasformazioni | SHA-256 |
|---|---|---|---|---|---|
| `assets/art/icons/abilities/generated/earthquake.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Roccia spaccata, due anelli d'impatto e polvere; trasformazioni comuni | `0ee0863fea71bbebba35faaad12048b8f72e74150a13c8b8ac74f6e3150f615b` |
| `assets/art/icons/abilities/generated/powerslide.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Pattino inline, scia a Z e scintille; trasformazioni comuni | `37a0749e56ad6b239080c733879f47af3e65a2518474160f746dbf05983cd1e7` |
| `assets/art/icons/abilities/generated/lightning.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Nube, singolo fulmine e onde del tuono; trasformazioni comuni | `0cfc33132b2a9302defc28a00a085e7b85711f3107339829dffbdeb3ffbf1cd2` |
| `assets/art/icons/abilities/generated/grand_spin.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Gonna da piroetta, archi opposti e scintille; trasformazioni comuni | `e51d21c4b29bd3b5bb7eac2c912dea0945d56d063fbccbc9fd9287d13d5b081c` |
| `assets/art/icons/abilities/generated/cement.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Secchio, colata e bolle di cemento; trasformazioni comuni | `5b80a05e9c538fa664aef5b5d9b70f554cdb452c9e2d79f508f244a6aea64306` |
| `assets/art/icons/abilities/generated/cosplay.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Maschera, stella mistero e coriandoli; trasformazioni comuni | `b77e7437e431cd4c53594b7650fde9a903482529348a1036c238c9ff3878eddf` |
| `assets/art/icons/abilities/generated/zen.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Loto, onde di respiro e moti; trasformazioni comuni | `af9262d7eec8236af8a025919b6a1fade6e1c3fa3b9f9627c43ac78c2e4157b5` |
| `assets/art/icons/abilities/generated/reggaeton.png` | OpenAI ImageGen built-in | progetto IL GIOCO + OpenAI ImageGen | Licenza del progetto | Cassa, silhouette danzante e note; trasformazioni comuni | `82ec7c628fd46dd35d3d6b9ff2d940bf8a448611b2696612c96b7957c409e0ca` |

Il budget dichiarato è verificato da `_ability_visuals_smoke.gd`: per singola
attivazione non più di un overlay fullscreen, 64 particelle logiche, un emblema
ImageGen e due materiali aggiuntivi. Queste implementazioni usano zero materiali
custom; il solo overlay fullscreen appartiene a Tempesta di Tuoni.
