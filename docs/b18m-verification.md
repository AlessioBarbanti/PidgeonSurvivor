# B18M — Migliorie grafiche delle abilità

Data verifica refresh ImageGen: 24 agosto 2026
Godot: `4.7.1.stable.official.a13da4feb`
Target obbligatori: Windows x64 e Android ARM64

## Stato

`COMPLETATO`. Il refresh sostituisce le otto icone SVG runtime con emblemi PNG
ImageGen e li riusa in brevi animazioni di attivazione. Smoke, regressione,
toolchain, export/runtime Windows ed export Android statico sono verdi. La prova
percettiva sul Pixel 9 è stata completata il 25 agosto 2026.

Il precedente gate Pixel 9 del 24 agosto resta valido per primitive procedurali,
layer, lifecycle e input della baseline `11329cf`, ma non certifica leggibilità e
animazione dei nuovi asset.

## Emblemi ImageGen

La modalità built-in di OpenAI ImageGen ha prodotto un asset distinto per:

- Magno: roccia spaccata, anelli d'impatto e polvere;
- Bea: pattino inline, scia a Z e scintille;
- Zat: nube, singolo fulmine e onde del tuono;
- Alea: gonna da piroetta, archi opposti e scintille;
- Aleo: secchio, colata e bolle di cemento;
- Lollo: maschera, stella mistero e coriandoli;
- Migi: loto, onde di respiro e moti;
- Marghe: boombox, silhouette danzante e note per `Reggeton time!`.

Specifica condivisa: pixel-art arcade caricaturale, silhouette leggibile a
`42 px`, composizione centrata, palette limitata, nessun testo, numero, cornice,
card, marchio o watermark. Gli output built-in erano già PNG RGBA trasparenti;
sono stati croppati sul bounding box alpha, ricentrati con circa `8%` di margine,
ridotti Lanczos a `256×256` e ottimizzati. File finali:
[`assets/art/icons/abilities/generated/`](../assets/art/icons/abilities/generated/).

Prompt, origine, autore, licenza, trasformazioni e SHA-256 individuali sono nel
[`manifest B18M`](../assets/art/vfx/ASSET-MANIFEST.md). Le vecchie icone runtime
SVG sono state rimosse; la sorgente Pinhead CC0 resta come storico documentato e
non viene consumata dalla build.

## Animazioni di attivazione

`ability_icon_burst.gd` mostrava nella baseline B18M per `0,72 s` la stessa
texture usata da HUD e carte rank. B18R ha poi portato il valore finale a
`1,20 s`. I profili sono distinti: impatto e tremore, scorrimento, pulse del
tuono, rotazione, caduta/squash, reveal, respiro e beat. Ogni effetto usa un solo
emblema, zero materiali custom e `z_index=1`, quindi resta sotto nemici,
telegraph, Player e proiettili prioritari.

Il clock avanza soltanto in `RunController.RUNNING`; B18R separa la dissolvenza
come coda sibling non interattiva, mentre morte, cambio profilo e restart la
ripuliscono. Collisioni, raggio, danno, durata, cooldown, snapshot rank e routing
touch sono invariati.

## Verifica automatica

Smoke dedicato:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_ability_visuals_smoke.gd
```

Marker: `B18M_ABILITY_VISUALS_SMOKE_OK`.

La fixture istanzia tutte le abilità e verifica famiglia visiva, budget, layer,
geometria gameplay, manifest/hash, PNG ImageGen, corrispondenza texture HUD/VFX,
un solo emblema, zero materiali custom, pausa e cleanup. La regressione completa
è `32/32`; `tools/verify-toolchain.ps1 -RunProjectSmoke` è verde. Log ed exit
code sono privi di `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` e
`CONTRACT_FAIL`.

## Windows x64

L'export debug finale è riuscito. L'eseguibile è stato avviato realmente a
`1280×720` con renderer Compatibility/OpenGL 3.3 su NVIDIA GeForce RTX 3060. Il
log contiene `SMOKE_OK`, `B18M_CONTRACT_OK` e `B17A_READY`, senza errori runtime.
L'anteprima tecnica comparativa resta ignorata in
`exports/ability-icons-imagegen-preview.png`.

## Android ARM64

L'export APK debug finale è riuscito. I controlli statici confermano:

- package `com.ilgioco.friendshipsurvival`, versione `0.1.0`/code `1`;
- `minSdk 31`, `targetSdk 36`, `compileSdk 36`;
- orientamento landscape, activity ridimensionabile e sola ABI `arm64-v8a`;
- firma APK Signature Scheme v2 valida.

Nella sessione automatica precedente l'APK non era stato installato e le nuove
icone/animazioni non erano state provate fisicamente. Il 25 agosto 2026 il gate
Pixel 9 è stato chiuso con le otto attivazioni in movimento e densità elevata a
20:9, controllando leggibilità a `42 px`, priorità visive e assenza di residui
dopo pausa/restart.

## Artefatti verificati

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `exports/windows/FriendshipSurvival.exe` | `103033344` | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `exports/windows/FriendshipSurvival.pck` | `1564344` | `ADCA5F69F90737F4C8ECF9AA7A3E3E03F99E4AFFD8648B99CE451CC00FE778FB` |
| `exports/android/friendship-survival-debug.apk` | `85377683` | `351B1D91B58A8476A266AF96954D77B61652D952FCAE56E05FEE03E8BFBAF2A7` |
