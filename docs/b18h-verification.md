# B18H — Nemici piccione

Data verifica: 24 agosto 2026
Godot: `4.7.1.stable.official.a13da4feb`
Target obbligatori: Windows x64 e Android ARM64

## Stato

`COMPLETATO`. Il nemico ordinario usa il piccione base animato; la variante
speciale è disponibile come fixture senza entrare nello spawn. Smoke, regressione,
toolchain, runtime Windows, export Android statico e controllo visuale sul Pixel 9
sono verdi.

## Contratto implementato

- due strip originali OpenAI-assisted del progetto in PNG RGBA `144x48`, ciascuna
  composta da posa neutra, ali alte e ali basse su canvas `48x48`;
- base grigio-blu, petto chiaro, collo verde/viola e becco arancio;
- speciale antracite/indaco, collare magenta e accenti oro;
- bordo scuro, filtro nearest e silhouette leggibile a circa `40` unità logiche;
- `AnimatedSprite2D` del nemico ordinario con flip verso il target; il movimento
  verticale conserva l'ultimo verso orizzontale;
- animazione presentazionale attiva soltanto in `RunController.RUNNING`;
- variante base predefinita nello spawner; speciale selezionabile soltanto via
  fixture/profilo futuro, senza statistiche o probabilità nascoste;
- Boss, collisione circolare da `20`, velocità `140`, `40` HP, danno da contatto
  `20`, drop XP e logica di spawn invariati.

Provenienza, prompt normalizzati, trasformazioni e hash sono registrati in
[`assets/art/enemies/pigeons/ASSET-MANIFEST.md`](../assets/art/enemies/pigeons/ASSET-MANIFEST.md).

## Verifica automatica

Smoke dedicato:

```powershell
godot_console --headless --path . `
  --script tests/integration/_pigeon_enemy_smoke.gd
```

Marker: `B18H_PIGEON_ENEMIES_SMOKE_OK`.

La fixture controlla hash, dimensioni e trasparenza dei due sheet; tre frame per
variante; default base e selezione speciale; nearest, flip e persistenza del
verso; stop/resume dell'animazione; collisione, velocità, HP, danno e XP invariati.

La regressione completa è `31/31`. Le regressioni mirate includono spawner,
combat slice, feedback B18B, Boss e run completa. Exit code e log sono privi di
`SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` e `CONTRACT_FAIL`.
`tools/verify-toolchain.ps1 -RunProjectSmoke` è verde e la scena composta emette
`B18H_CONTRACT_OK`.

## Windows x64

Export debug completato. L'eseguibile è stato avviato realmente a `1280x720`
con renderer Compatibility/OpenGL 3.3 su NVIDIA GeForce RTX 3060. Il log runtime
contiene `SMOKE_OK` e `B18H_CONTRACT_OK` e non contiene errori o marker di
fallimento.

## Android ARM64 e Pixel 9

L'export APK debug e i controlli statici confermano:

- package `com.ilgioco.friendshipsurvival`, versione `0.1.0`/code `1`;
- `minSdk 31`, `targetSdk 36`, `compileSdk 36`;
- orientamento landscape (`screenOrientation=0`) e activity ridimensionabile;
- sola ABI `arm64-v8a` e firma APK Signature Scheme v2 valida;
- installazione aggiornata e cold launch sul Pixel 9, Android 17/API 37;
- viewport Godot `1616x720` su display fisico landscape `2424x1080`;
- piccioni base visibili e leggibili nel campo reale a 20:9, con verso coerente
  rispetto al Player e senza sfere rosse residue;
- `SMOKE_OK`, `B18H_CONTRACT_OK` e `B17A_READY` presenti nel log del processo;
  nessun `SCRIPT ERROR`, `FATAL EXCEPTION`, `ANR`, `SMOKE_FAIL` o
  `CONTRACT_FAIL`.

Le catture tecniche `b18h-launch.png` e `b18h-gameplay.png` restano nella
directory ignorata `exports/android/` e non vengono committate.

## Artefatti verificati

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `exports/windows/FriendshipSurvival.exe` | `103033344` | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `exports/windows/FriendshipSurvival.pck` | `1091124` | `C45A8A4F2EAF25A122A795B321FB0792FE6AC49C624EF61CFCD19F6AC9000BAA` |
| `exports/android/friendship-survival-debug.apk` | `84904500` | `384563C7B2C5CFF0B7FE1B84EC85411B46796B32FC4BBDFDA969D400B2786C66` |
