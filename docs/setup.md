# Setup di sviluppo

Baseline verificata per il progetto:

| Componente | Versione/configurazione |
|---|---|
| Godot | 4.7.1 Standard, GDScript, Compatibility |
| Windows | x86_64 |
| Java | OpenJDK 17 |
| Android minimo | Android 12, API 31 |
| Android target/compile | Android 16, API 36 |
| Build Tools | 36.1.0 |
| NDK | 29.0.14206865 |
| CMake | 3.10.2.4988404 |
| ABI | `arm64-v8a` |
| Orientamento | landscape |

La versione NDK segue il template Gradle del tag esatto Godot 4.7.1:
[config.gradle 4.7.1](https://github.com/godotengine/godot/blob/4.7.1-stable/platform/android/java/app/config.gradle).

## Variabili locali

Configurare, senza inserire percorsi personali nel repository:

```powershell
[Environment]::SetEnvironmentVariable('JAVA_HOME', '<percorso-jdk-17>', 'User')
[Environment]::SetEnvironmentVariable('ANDROID_HOME', "$env:LOCALAPPDATA\Android\Sdk", 'User')
```

Riaprire il terminale dopo una modifica alle variabili. In Godot, sotto
`Editor > Editor Settings > Export > Android`, impostare:

- `Java SDK Path` alla root del JDK 17;
- `Android SDK Path` alla root che contiene `platform-tools/adb`.

## Verifica automatica

Il controllo è in sola lettura, salvo le cache di import generate normalmente da
Godot:

```powershell
.\tools\verify-toolchain.ps1 -RunProjectSmoke
```

Lo smoke test deve stampare `SMOKE_OK` e terminare con codice `0`.

## Export di debug

Gli output sono esclusi da Git. Dalla root del repository:

Chiudere eventuali altre istanze dell'editor sullo stesso progetto prima di un
export CLI: la build riesce anche con l'editor aperto, ma su Windows la console
può restare agganciata all'istanza già attiva.

```powershell
New-Item -ItemType Directory -Force exports\windows, exports\android | Out-Null

godot_console --headless --path . `
  --export-debug "Windows Desktop" `
  exports\windows\FriendshipSurvival.exe

godot_console --headless --path . `
  --install-android-build-template `
  --export-debug "Android APK" `
  exports\android\friendship-survival-debug.apk

godot_console --headless --path . `
  --export-debug "Android AAB (future)" `
  exports\android\friendship-survival-debug.aab
```

Il template Gradle generato vive in `android/build/` ed è escluso dal
repository: va rigenerato quando cambia la patch di Godot. I preset mantengono
`compileSdk=36` nel template 4.7.1, `minSdk=31`, `targetSdk=36` e la sola ABI
ARM64.

`--install-android-build-template` è valido soltanto insieme a un comando di
export. Se eseguito da solo, avvia l'editor headless senza completare il flusso.

## Verifica dell'APK

```powershell
$buildTools = Join-Path $env:ANDROID_HOME 'build-tools\36.1.0'

& "$buildTools\aapt2.exe" dump badging `
  exports\android\friendship-survival-debug.apk

& "$buildTools\apksigner.bat" verify --verbose --print-certs `
  exports\android\friendship-survival-debug.apk
```

Controllare package `com.ilgioco.friendshipsurvival`, API minima 31, target 36,
`arm64-v8a`, landscape e assenza di permessi inattesi.

Con un dispositivo ARM64 collegato e autorizzato:

```powershell
adb devices -l
adb install -r exports\android\friendship-survival-debug.apk
```

## Firma release e Google Play futuro

Il debug usa il keystore locale di Godot. Il keystore release non deve mai
entrare nel repository. Quando verrà creato, passare firma e credenziali tramite:

- `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`;
- `GODOT_ANDROID_KEYSTORE_RELEASE_USER`;
- `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`.

Il preset AAB serve soltanto a verificare che la pipeline sia predisposta: non
effettua upload, non richiede oggi un account Google Play e non sostituisce il
backup sicuro del futuro keystore.

L'AAB debug può risultare non firmato: è sufficiente per questo smoke test
strutturale. Una build release destinata allo store dovrà invece essere firmata
con il keystore esterno configurato tramite le variabili sopra.

Godot è bloccato localmente alla versione 4.7.1 con un pin WinGet. Quando si
deciderà esplicitamente una migrazione, il pin può essere rimosso con:

```powershell
winget pin remove --id GodotEngine.GodotEngine --exact
```

## Limiti del gate M0

Un export locale verifica toolchain, packaging, manifest e firma debug. Touch,
safe area, Back/Home, lifecycle, frame pacing e temperatura richiedono comunque
un telefono Android fisico e rientrano nelle milestone successive.

Esito dettagliato del setup corrente: [`m0-verification.md`](./m0-verification.md).
