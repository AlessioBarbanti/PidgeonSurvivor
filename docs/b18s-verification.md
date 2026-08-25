# B18S — Sfondo arena ImageGen

Data verifica: 25 agosto 2026  
Godot: `4.7.1.stable.official.a13da4feb`  
Target obbligatori: Windows x64 e Android ARM64

## Stato

`COMPLETATO`. Lo sfondo ImageGen, il crop responsive, la tracciabilità, gli
automatici, il runtime Windows, l'APK statico e il passaggio Pixel 9 a 20:9 sono
chiusi. Dopo B18Q e B18R, il confronto sul playfield definitivo durante i VFX
allungati e a luminosità fisica controllata è stato completato il 25 agosto
2026.

## Asset e integrazione

OpenAI ImageGen built-in ha prodotto due varianti originali senza immagini di
input. È stata scelta la prima: una superficie top-down notte, materica e a
basso contrasto. La seconda è stata scartata perché i molti blocchi regolari
potevano essere interpretati come ostacoli.

Il solo derivato scelto entra nel repository:
`assets/art/arena/arena_floor_imagegen.png`, PNG RGB `768×512`, ottenuto con
downscale esatto `2:1` nearest-neighbor dall'output `1536×1024`. Prompt finale,
generatore, data, autore, licenza, trasformazioni, hash sorgente e hash runtime
sono in [`assets/art/arena/ASSET-MANIFEST.md`](../assets/art/arena/ASSET-MANIFEST.md).

`ArenaView` disegna il raster sul solo `playfield_rect` con crop centrale
aspect-cover, senza deformazione su 16:9, 20:9 o 4:3. Il filtro resta nearest e
una modulazione scura conserva la priorità di Player, pickup, nemici, telegraph
e proiettili. Il pavimento B18B resta disponibile soltanto come fallback se la
texture non è assegnata; nessuna geometria, collisione o coordinata gameplay è
stata modificata.

## Verifica automatica

Smoke dedicato:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_arena_background_smoke.gd
```

Marker: `B18S_ARENA_BACKGROUND_SMOKE_OK`.

Lo smoke controlla assegnazione runtime, filtro nearest, dimensioni RGB,
SHA-256 e completezza del manifest; campiona la luminanza (`media <= 0,22`,
`massimo <= 0,52`), verifica crop aspect-cover 16:9/20:9/4:3 e dimostra che il
calcolo presentazionale non modifica il playfield. La regressione completa è
`37/37`; `tools/verify-toolchain.ps1 -RunProjectSmoke` è verde. I log sono privi
di `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` e `CONTRACT_FAIL`.

## Windows x64

L'export debug `PidgeonSurvivor.exe` è riuscito. L'eseguibile è stato avviato
realmente a `1280×720` con renderer Compatibility/OpenGL 3.3 su NVIDIA GeForce
RTX 3060: exit `0`, `SMOKE_OK` e `B18S_CONTRACT_OK`.

La modalità opzionale `--capture-b18s` dello smoke ha prodotto nello stesso
runtime il confronto fra fallback B18B e raster B18S, conservato negli artefatti
ignorati `exports/windows/b18s-arena-procedural-baseline.png` e
`exports/windows/b18s-arena-imagegen.png`. Il raster elimina cerchi, giunti e
crepe leggibili come segni semantici, mantenendo Player, HUD, proiettili e icona
abilità nettamente prioritari.

## Android ARM64 e Pixel 9

L'APK debug esportato conferma:

- package `com.ilgioco.pidgeonsurvivor`, versione `0.1.0`/code `1`;
- `minSdk 31`, `targetSdk 36`, `compileSdk 36`;
- sola ABI `arm64-v8a` e firma APK Signature Scheme v2 valida.

La build è stata installata e avviata realmente sul Pixel 9 `tokay`, viewport
fisico `2424×1080` e logico `1616×720`, renderer Compatibility/OpenGL ES 3.2 su
Mali-G715. Il percorso `welcome → selezione Magno → run` ha mostrato il raster
20:9 con Player, piccioni, proiettili, pickup XP, HUD e cooldown leggibili. Home
e ritorno all'app hanno prodotto `OnPause`/`OnResume` senza crash; il fondale è
rimasto coerente anche sul terminale di sconfitta. Il log del processo contiene
`SMOKE_OK` e `B18S_CONTRACT_OK`, con conteggi zero per `SCRIPT ERROR`,
`FATAL EXCEPTION` e `CONTRACT_FAIL`.

Le catture tecniche sono conservate soltanto in `exports/android/` e restano
fuori dal repository. La prova separata a luminosità controllata, necessaria
per certificare la percezione sul pannello fisico, è stata completata il
25 agosto 2026.

## Artefatti verificati

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `assets/art/arena/arena_floor_imagegen.png` | `517364` | `210523A96CF0370885BE49E937D85EBD035DF992D8FBC2089A89F36347A615BC` |
| `exports/windows/PidgeonSurvivor.exe` | `103115264` | `BFA5766944AD646D797F3FEB0172A0287A65CFD9FF08B1B1E449955985BC85FA` |
| `exports/windows/PidgeonSurvivor.pck` | `9722412` | `FA0339EAC3E93EBAA475094AC99846159BC65C7B166F3C804897C86612EA695F` |
| `exports/android/pidgeon-survivor-debug.apk` | `94229471` | `4C5839AFD22527654DED1FA3B360476398F0366A2AE0B0178118929A770E688C` |

## Gate chiusi il 25 agosto 2026

- B18Q chiuso e crop verificato sul nuovo playfield sotto HUD/XP;
- priorità ricontrollata durante i VFX B18R allungati e a densità alta;
- luminosità bassa/alta confrontata fisicamente su Windows e Pixel 9;
- passaggio combinato 16:9/20:9/4:3 completato prima del freeze B18V.
