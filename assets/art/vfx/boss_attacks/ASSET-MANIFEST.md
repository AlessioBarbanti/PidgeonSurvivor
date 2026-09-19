# Manifest VFX attacchi Boss — PS-144

Produzione: 2026-09-19. Origine/autore: progetto Pidgeon Survivor con
assistenza OpenAI ImageGen built-in, quattro generazioni originali.
Licenza: asset generati per il progetto; nessuna fonte di terzi incorporata.
Prompt integrali e ruoli dei riferimenti: [hd/PROMPTS.md](hd/PROMPTS.md).
Nessun riferimento privato del cast utilizzato. Approvazione del proprietario
ancora aperta; integrazione e catture runtime appartengono a PS-141.

## Derivazione e geometria

Comando riproducibile dalla root: `./tools/process-boss-attack-vfx.ps1`.
Alpha reale del master conservata; pixel con alpha <32 rimossi, crop sui bounds,
centratura, nearest-neighbor e conversione RGB in grigio neutro. Nessuno sfondo
chroma e nessuna forma sostitutiva disegnata da codice. Tutti i master hanno
dimensione 1254x1254; runtime 512x512 salvo mirino 128x128.

Origine al centro del canvas. Ring/blast/mirino confinati entro raggio
`0.46 * dimensione`: per un raggio gameplay R usare un quad di lato `2R/0.92`.
Il bordo rimane materico/frastagliato dentro questo limite; non promette un
contorno opaco continuo su ogni angolo. Nessuna decorazione oltre il limite.
Per una fascia di danno sottile PS-141 può campionare il ring in una mesh UV
ancorata ai limiti della fascia, senza primitive visive di debug.

| Asset | Bounds alpha (x,y,w,h) | Uso |
|---|---|---|
| danger_ring | 28,26,456,460 | Perimetro telegraph, volley e fascia radiale |
| blast | 37,41,438,430 | Impatto/decal centrale |
| reticle | 11,6,106,116 | Nucleo brace di puntamento; nessuna croce vettoriale |
| corridor | 21,203,470,106 | Fascia orizzontale orientata +X; usare questo crop UV |

Modulazione: rosso/arancio Boss, magenta Evil secondo palette runtime esistente.
Il grayscale evita che una tinta nativa falsi il riconoscimento ostile.
I PNG source rimangono in `hd/` escluso dall'import con `.gdignore`.
Esclusione esplicita `assets/art/vfx/boss_attacks/hd/**` verificata nei tre
preset Windows/APK/AAB.

Prova isolata non runtime: `hd/scale_review.png` (520x220), composizione
System.Drawing nearest dei derivati su fondo RGB(42,45,38): ring 160x160,
blast 100x100, reticle 18x18, crop corridor 180x40. SHA-256:
`5CE01866340A1D4EE1B76A87769884987AECFDC0E44E4BFE92C01C1E0C150D12`.
È un'evidenza tecnica derivata dagli asset sopra, non un nuovo master artistico.

| Asset | Master | Derivato | SHA-256 master | SHA-256 derivato |
|---|---|---|---|---|
| danger_ring | `hd/boss_danger_ring_source.png` | `generated/boss_danger_ring.png` | `EBC2EC009E55D2F7CD6C6DE6EE31ECDC8CB6C62109741927B28BF94F77C7DF67` | `3E335AB802B85D301A99F55FCF1B11F6BBF6D63A5BAEFF3C009F7572502F1E29` |
| blast | `hd/boss_blast_source.png` | `generated/boss_blast.png` | `F0CD380C09F96F7EA81086315C316B2D147836DC7B0F8592A6C90EB44C90ABBC` | `B671BB0BFB0BE03A4F8A17361B04025435574E8118EB0DBBEBDC1DC5C8C13057` |
| reticle | `hd/boss_reticle_source.png` | `generated/boss_reticle.png` | `1052A19FFEEB6B1B5526585510FF1532D891F1D3B8D60F4FA1D8D4F70CAFCB54` | `96A1CCDB514AC252284CFBFC476CF29AE86672398846664CE55CDA79BD9E95AD` |
| corridor | `hd/boss_corridor_source.png` | `generated/boss_corridor.png` | `00AC7A9777C4CC4A06C59A8E17E319E820CC0907E63C202522FA0739F39289E0` | `783D92CFE851BB89EE141A3651FB81A30920784F1FB3FA91F1FB3B1B642F35CF` |

## Riuso della famiglia Signature

Tutti i percorsi seguenti sono sotto `assets/art/vfx/abilities/generated/`;
provenienza e hash originali restano nel manifest VFX superiore.

| Famiglia | Asset esistente | Motivo del riuso |
|---|---|---|
| Onda/terremoto | `earthquake_wave.png` | Rocce e crepe radiali già leggibili |
| Corridoio/fuoco | `fire_trail.png` | Scia di fuoco orizzontale |
| Rotazione | `grand_spin.png` | Materia tangenziale, verso della rotazione |
| Freddo/caldo | `thermal_frost.png`, `thermal_bloom.png` | Cristalli e fiamme distinti |
| Zona | `zen_field.png` | Decal di campo persistente |
| Fulmine | `lightning_impact.png` | Impatto elettrico |
| Evocazione | `cosplay_reveal.png`, `reggaeton_decoy.png` | Accento e apparizione già nel lessico del cast |

Per le note dei cloni: regione ciano di `reggaeton_decoy.png`
`Rect2(421,177,68,70)`, mostrata a 14x14; preservare la silhouette dei cloni.
L'aura fulmine Boss riusa `lightning_impact.png`; il Player non cambia.

Conservare tinta nativa dei motivi Signature come decorazione, accompagnata dal
perimetro ostile Boss/Evil; i proiettili/piume riusano
`assets/art/vfx/projectiles/generated/enemy_projectile.png`.
