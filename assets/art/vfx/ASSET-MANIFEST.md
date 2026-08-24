# Manifest grafico B18M

La baseline B18M usa disegno procedurale e le otto icone già approvate. Per i
VFX vale `origine: progetto IL GIOCO`; autore: progetto IL GIOCO; Licenza del
progetto. Non sono stati usati asset grafici esterni, shader custom o generatori
per produrre gli effetti. Il pittogramma Powerslide conserva invece la licenza
CC0 1.0 e la provenienza Pinhead già documentate nel relativo file `LICENSE.md`.

## Sorgenti procedurali runtime

| Percorso | Origine | Autore | Licenza | Trasformazioni | SHA-256 |
|---|---|---|---|---|---|
| `scripts/abilities/earthquake_wave.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Anelli concentrici e crepe disegnati con primitive `CanvasItem` | `dcba84a86bef2c0b337df98817eae1aaf4f9f809f318a5c3e4a36aa9fa466b84` |
| `scripts/abilities/fire_z_trail.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Nastro a due livelli e 16 scintille deterministiche | `c2a7a1a51197578b7b1d5545fe71515aa3e2bcfeedf430b6db1cb1caf465c541` |
| `scripts/abilities/lightning_storm.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Nube, saetta, onde del tuono e overlay accessibile | `2c84564d1ada2fd92765baa225ca154321e66f6cdab9f86e0911c4e69220f987` |
| `scripts/abilities/ability_area_effect.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Archi rotanti, pozza con bolle e campo zen con anelli e moti lenti | `f1e40c89f75fe38893e16853ad96d5180f383a239636865c8d519f8cb8e0c988` |
| `scripts/abilities/cosplay_accent.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Burst da 18 coriandoli nella palette dell'abilità copiata | `eef04d3ce27d106d860e3bd56cccae78cc7a199ebaf0d7b01194fe10bb5a5f07` |
| `scripts/abilities/illusion_decoy.gd` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Clone ballerino, cassa pulsante e sei note musicali | `01df1dc441abf245404b8cb6bf794753b6df77b2efb893c3c3d15acf74ace07d` |

## Icone definitive

| Percorso | Origine | Autore | Licenza | Trasformazioni | SHA-256 |
|---|---|---|---|---|---|
| `assets/art/icons/abilities/earthquake.svg` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Pittogramma SVG originale, invariato in B18M | `24e33383bd5f1bc5cb8d8721920e73944abe083ab1c0fa1cb2a158fd7e5de3d7` |
| `assets/art/icons/abilities/powerslide.svg` | Pinhead `v15.17.0` | Pictogrammers/Pinhead contributors | CC0 1.0 | Derivato runtime con cornice e palette del progetto, invariato in B18M | `cef3584d94220cb3dc499b601d48aa7de7dd08a0b37b9eb9a8e885fe7f9b108e` |
| `assets/art/icons/abilities/lightning.svg` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Pittogramma SVG originale, invariato in B18M | `aba433569a9ee310b7aa70be8ff34b54aaf7aa4e4b000971a57c718f4ed18c1a` |
| `assets/art/icons/abilities/grand_spin.svg` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Pittogramma SVG originale, invariato in B18M | `917f14b98ec41b9754a39a5a3967768828867be2ed8021d4699dd72a357f392e` |
| `assets/art/icons/abilities/cement.svg` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Pittogramma SVG originale, invariato in B18M | `acae3208c71b81bd3bb6fde4b65345d643ee63747975519b71e7c0055317304d` |
| `assets/art/icons/abilities/cosplay.svg` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Pittogramma SVG originale, invariato in B18M | `c6588e6d6dc796a046a1e89a99973597c67d5dc37034e730f3bd2023889e8ef7` |
| `assets/art/icons/abilities/zen.svg` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Pittogramma SVG originale, invariato in B18M | `59e14cd093451ba6025bb6932e1edbb01037ae7e5af0b47902431e9d0c598a83` |
| `assets/art/icons/abilities/reggaeton.svg` | progetto IL GIOCO | progetto IL GIOCO | Licenza del progetto | Pittogramma SVG originale, invariato in B18M | `b14f80670077d0b919a0fffe4168e9365a5cf44fb98dc2cc3e4e5264662a531a` |

Il budget dichiarato è verificato da `_ability_visuals_smoke.gd`: per singola
attivazione non più di un overlay fullscreen, 64 particelle logiche e due
materiali aggiuntivi. Queste implementazioni usano zero materiali custom; il
solo overlay fullscreen appartiene a Tempesta di Tuoni.
