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

### Manifest degli asset grafici

Quando una slice aggiunge o modifica file grafici, icone o sorgenti VFX
procedurali, aggiornare il relativo `ASSET-MANIFEST.md` con percorso, origine,
autore, licenza, trasformazioni e SHA-256. Per calcolare l'hash dalla root:

```powershell
(Get-FileHash -Algorithm SHA256 '<percorso>').Hash.ToLowerInvariant()
```

Il manifest è documentazione di sorgente e non deve diventare una dipendenza
del gioco esportato: gli smoke repository possono verificarlo, mentre i marker
runtime devono controllare soltanto risorse incluse nel PCK/APK.

## Export di debug

Gli output sono esclusi da Git. Dalla root del repository:

Chiudere eventuali altre istanze dell'editor sullo stesso progetto prima di un
export CLI: la build riesce anche con l'editor aperto, ma su Windows la console
può restare agganciata all'istanza già attiva.

```powershell
New-Item -ItemType Directory -Force exports\windows, exports\android | Out-Null

godot_console --headless --path . `
  --export-debug "Windows Desktop" `
  exports\windows\PidgeonSurvivor.exe

godot_console --headless --path . `
  --install-android-build-template `
  --export-debug "Android APK" `
  exports\android\pidgeon-survivor-debug.apk

godot_console --headless --path . `
  --export-debug "Android AAB (future)" `
  exports\android\pidgeon-survivor-debug.aab
```

Per lo smoke dell'eseguibile Windows esportato, separare le opzioni motore dagli
argomenti letti da `OS.get_cmdline_user_args()` con `--`:

```powershell
.\exports\windows\PidgeonSurvivor.exe `
  --resolution 1280x720 -- `
  --smoke-test --run-seed=1
```

Senza il separatore, Godot tratta `--smoke-test` come opzione motore e la scena
non esegue l'auto-quit previsto dallo smoke.

Il template Gradle generato vive in `android/build/` ed è escluso dal
repository: va rigenerato quando cambia la patch di Godot. I preset mantengono
`compileSdk=36` nel template 4.7.1, `minSdk=31`, `targetSdk=36` e la sola ABI
ARM64.

Dopo ogni `--install-android-build-template` (rigenerazione del template,
prima installazione, aggiornamento della patch di Godot), aggiungere
`org.gradle.daemon=false` in `android/build/gradle.properties`: buona norma
per non accumulare daemon Gradle a lungo termine.

**Nota (28 agosto 2026, verificata su Godot 4.7.1):** contrariamente a quanto
scritto qui in precedenza, questa impostazione **non elimina** l'attesa dopo
`[ DONE ] export`. Con un test mirato (log catturato subito dopo la comparsa
di `[ DONE ]`) nessun processo `java` risultava più vivo: Gradle aveva già
terminato la sua JVM, quindi non può essere il suo daemon a trattenere
l'handle. Il ritardo (tipicamente oltre gli `8s` di stabilità che
`run-milestone-checks.ps1` attende prima di terminare il processo) è lato
Godot: l'editor headless non chiude sempre in tempi brevi dopo un export
Android, con o senza `org.gradle.daemon=false` e con o senza
`--install-android-build-template` nella stessa invocazione. La mitigazione sta in
`run-milestone-checks.ps1`: non attendere l'uscita del processo, ma un segnale
di completamento, poi terminare quel processo e validare l'APK prodotto,
classificando l'esito come `RECOVERED` solo se l'ispezione statica passa. Per
un export manuale fuori da quello script, vedere "APK aggiornato ma processo
di export ancora aperto" più sotto invece di aspettarsi che disattivare il
daemon risolva l'attesa.

**Aggiornamento (29 agosto 2026):** il segnale primario non è più la stabilità
dell'artefatto ma il marker che Godot stampa da sé, `[ DONE ] export`. Il
runner legge stdout/stderr in modo incrementale (non più `ReadToEndAsync`, che
restituisce solo all'EOF della pipe), ripulisce ogni riga dai codici ANSI e
confronta con `^\[ DONE \]\s+export\b`. Il passo va nominato: la stessa
etichetta `[ DONE ]` compare anche per `first_scan_filesystem`, molto prima che
l'APK esista. Dopo il marker il runner concede `CompletionGraceMs` (2 s di
default) perché il processo esca da solo, poi termina il suo albero e
restituisce exit `126`. La stabilità dell'artefatto
(`-StableArtifactPath`/`-StableArtifactSeconds`, exit `125`) resta come ripiego
per gli strumenti che non dichiarano nulla di riconoscibile, e il timeout
(exit `124`) come scadenza esterna. In tutti i casi il criterio di successo
resta l'ispezione statica dell'APK, non il codice di uscita.

`run-milestone-checks.ps1` applica comunque `org.gradle.daemon=false` in
automatico dopo ogni export Android (funzione `Set-AndroidGradleDaemonDisabled`)
e passa `--install-android-build-template` soltanto se il template non è
ancora installato, cosicché un export di routine non rigeneri
`gradle.properties` perdendo l'impostazione a ogni corsa.

`--install-android-build-template` è valido soltanto insieme a un comando di
export. Se eseguito da solo, avvia l'editor headless senza completare il flusso.

## Verifica dell'APK

```powershell
$buildTools = Join-Path $env:ANDROID_HOME 'build-tools\36.1.0'

& "$buildTools\aapt2.exe" dump badging `
  exports\android\pidgeon-survivor-debug.apk

& "$buildTools\apksigner.bat" verify --verbose --print-certs `
  exports\android\pidgeon-survivor-debug.apk
```

Controllare package `com.ilgioco.pidgeonsurvivor`, nome applicazione
`Pidgeon Survivor`, API minima 31, target 36,
`arm64-v8a`, landscape e assenza di permessi inattesi.

### APK aggiornato ma processo di export ancora aperto

Su Windows può accadere che Gradle abbia già scritto un APK completo mentre il
processo `godot_console --export-debug "Android APK"` resta aperto senza nuovo
output. Per le card usare il profilo `Release`: il runner osserva soltanto
il processo avviato da quella esecuzione, attende che un APK nuovo rimanga
stabile e lo termina prima dell'ispezione statica. L'esito diventa `RECOVERED`
solo se tutti i controlli dell'APK passano:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-011 -Profile Release
```

Per una diagnosi manuale, la sola presenza del file non prova il successo.
Prima di interrompere il processo, verificare che dimensione e data non cambino
fra due letture:

```powershell
$apk = Resolve-Path exports\android\pidgeon-survivor-debug.apk
$before = Get-Item -LiteralPath $apk
Start-Sleep -Seconds 2
$after = Get-Item -LiteralPath $apk

if ($before.Length -ne $after.Length -or
    $before.LastWriteTimeUtc -ne $after.LastWriteTimeUtc) {
    throw 'APK ancora in scrittura.'
}
```

Eseguire quindi i controlli `aapt2` e `apksigner` sopra. L'export è recuperabile
come completato soltanto se il manifest riporta package, `minSdk`, `targetSdk`
e ABI attesi, la firma v2 è valida e l'ispezione ZIP contiene esclusivamente
`lib/arm64-v8a/*.so`. Registrare dimensione, data e SHA-256 nelle note di
verifica del backlog:

```powershell
Get-FileHash -Algorithm SHA256 -LiteralPath $apk
```

Se tutti i controlli passano ma la CLI resta aperta, individuare il solo
processo il cui `CommandLine` contiene l'export Android corrente e terminarlo;
non chiudere genericamente tutti i processi Godot o Java. Il daemon Gradle può
restare vivo per riuso ed è normale; fermarlo con `android\gradlew.bat --stop`
soltanto se nessun'altra build Gradle è in corso.

Con un dispositivo ARM64 collegato e autorizzato:

```powershell
adb devices -l
adb install -r exports\android\pidgeon-survivor-debug.apk
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
