# B18M — Migliorie grafiche delle abilità

Data verifica: 24 agosto 2026
Godot: `4.7.1.stable.official.a13da4feb`
Target obbligatori: Windows x64 e Android ARM64

## Stato

`COMPLETATO`. Le otto famiglie VFX sono implementate, registrate e verificate
automaticamente, su Windows e sul Pixel 9 nel commit dedicato `11329cf`.

## Contratto implementato

- Magno: tre anelli tellurici in espansione e otto crepe, contenuti nel raggio
  gameplay fotografato all'attivazione;
- Bea: nastro magenta a due livelli con sedici scintille deterministiche lungo
  il segmento rettilineo di Powerslide;
- Zat: nube, saetta e onde di preavviso, impatto per bersaglio e unico overlay
  fullscreen con alpha standard/ridotto già autorevole in B18E;
- Alea: quattro archi controrotanti e dodici punti luce, centrati sul Player per
  tutta la durata di Gran Piroetta;
- Aleo: pozza grigio-ciano irregolare, bordo esplicito e dieci bolle, tutta
  interna al raggio reale di Colata di Cemento;
- Lollo: diciotto coriandoli e anello breve nella palette dell'abilità copiata,
  figli dell'effetto copiato e ripuliti con esso;
- Migi: quattro anelli concentrici respiranti e diciotto moti lenti, con bordo
  esterno coincidente col raggio reale di Rallentamento Zen;
- Marghe: clone ballerino, cassa pulsante e sei note musicali per
  `Reggeton time!`, senza cambiare deviazione dell'aggro;
- un solo `CanvasItem` radice per famiglia, più il breve accento figlio di
  Cosplay; zero materiali custom, massimo un overlay fullscreen e massimo `34`
  elementi particellari logici nella combinazione più costosa, sotto il budget
  `1`/`64`/`2` del piano;
- `AbilityEffects` resta a `z_index=0`, sotto nemici, Player, proiettili e
  telegraph ostili. Nessun VFX modifica collisioni, raggio, danno, durata,
  cooldown, targeting o clock `RunController.RUNNING`.

Le sorgenti procedurali e le otto icone definitive sono registrate in
[`assets/art/vfx/ASSET-MANIFEST.md`](../assets/art/vfx/ASSET-MANIFEST.md).
Powerslide conserva il pittogramma Pinhead CC0 già approvato; gli altri file
sono originali del progetto. Nessun asset generato o pacchetto animato esterno è
stato aggiunto.

## Verifica automatica

Smoke dedicato:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_ability_visuals_smoke.gd
```

Marker: `B18M_ABILITY_VISUALS_SMOKE_OK`.

La fixture istanzia tutte le abilità e verifica famiglia visiva distinta,
budget, layer, corrispondenza fra estensione grafica e geometria gameplay,
palette/confetti di Cosplay, pausa e cleanup, manifest e SHA-256. La regressione
completa è `32/32`; le regressioni mirate di B09A, B17A, B18, B18D, B18E e B18F
sono verdi. `tools/verify-toolchain.ps1 -RunProjectSmoke` è verde. Exit code e
log sono privi di `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` e
`CONTRACT_FAIL`.

## Windows x64

Export debug e smoke reale dell'eseguibile completati a `1280x720` con renderer
Compatibility/OpenGL 3.3 su NVIDIA GeForce RTX 3060. Il log contiene `SMOKE_OK`
e `B18M_CONTRACT_OK`, termina con codice `0` e non contiene errori runtime.

Il primo smoke export ha correttamente segnalato che un manifest Markdown non è
una risorsa runtime nel PCK. La dipendenza è stata rimossa dal contratto della
scena: il manifest resta verificato dallo smoke sorgente, mentre l'eseguibile
valida soltanto risorse e codice realmente impacchettati.

## Android ARM64 e Pixel 9

L'export APK debug e i controlli statici confermano:

- package `com.ilgioco.friendshipsurvival`, versione `0.1.0`/code `1`;
- `minSdk 31`, `targetSdk 36`, `compileSdk 36`;
- sola ABI `arm64-v8a` e firma APK Signature Scheme v2 valida;
- installazione aggiornata e cold launch sul Pixel 9, Android 17/API 37;
- viewport Godot `1616x720` su display fisico landscape `2424x1080`;
- selezione, avvio e attivazione touch individuale riusciti per tutti gli otto
  personaggi; le otto grammatiche sono leggibili nelle catture a 20:9 e non
  coprono HUD, Player o proiettili;
- Home/ritorno durante `Reggeton time!` lascia la run in pausa fino a
  `RIPRENDI`; log lifecycle e processo privi di errori, ANR o crash;
- `SMOKE_OK`, `B18M_CONTRACT_OK` e `B17A_READY` presenti nel cold-launch log.

B18M non modifica hit area o routing touch. Il gate fisico multitouch di B18L,
già chiuso con due dita reali sullo stesso Pixel 9, resta l'evidenza autorevole
per joystick più abilità; l'iniezione ADB simultanea non viene conteggiata come
prova a due dita. Il test verrà ripetuto nel gate combinato B17A–B18M prima del
freeze del ciclo.

Le catture tecniche `b18m-launch.png`, `b18m-<personaggio>.png`,
`b18m-multitouch.png` e `b18m-resume.png` restano nella directory ignorata
`exports/android/` e non vengono committate.

## Artefatti verificati

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `exports/windows/FriendshipSurvival.exe` | `103033344` | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `exports/windows/FriendshipSurvival.pck` | `1108228` | `A9A2FB3B7591D8FA68D10E95C6EA1DDE369BB67840D6B136E11C0AC938F86117` |
| `exports/android/friendship-survival-debug.apk` | `84921822` | `FBE5F7C40BFE9F1C2F5B5126721789096F3B0B4E9E5A257CC3F01613CE38D8EC` |
