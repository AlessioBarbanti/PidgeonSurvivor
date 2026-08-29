---
name: build-apk
description: Compila l'APK Android di Pidgeon Survivor e, se richiesto, lo installa e lo avvia sul telefono collegato. Copre l'export headless, il caso Windows in cui il processo di export resta appeso dopo che l'APK è già completo, la validazione statica dell'artefatto e adb install. Usala per "fammi l'apk", "compila per Android", "mettilo sul telefono", "l'export è appeso", "installa la build sul Pixel".
---

# Build e installazione dell'APK

## Perché l'export sembra appeso

Su Windows il processo `godot_console --export-debug "Android APK"` spesso **non
esce** dopo aver stampato `[ DONE ]`, anche con l'APK già scritto e completo.
Chi legge il suo output aspettando l'EOF resta appeso a build finita.

Attenzione: `org.gradle.daemon=false` **non risolve** questa attesa. È stato
verificato il 28 agosto 2026 su Godot 4.7.1 — subito dopo `[ DONE ]` nessun
processo `java` è più vivo, quindi non è il daemon Gradle a trattenere l'handle:
il ritardo è dell'editor headless di Godot. L'impostazione resta comunque
applicata (buona norma, evita accumulo di daemon) e
`run-milestone-checks.ps1` la riapplica da sé dopo ogni export, perché
`--install-android-build-template` rigenera `gradle.properties` e la
cancella.

La mitigazione è **non aspettare l'uscita del processo ma un segnale di
completamento**. Dal 29 agosto 2026 il runner usa il marker che Godot stampa da
sé, `[ DONE ] export`: legge stdout/stderr riga per riga mentre arrivano, toglie
i codici ANSI e confronta con `^\[ DONE \]\s+export\b`. Il passo va nominato,
perché la stessa etichetta `[ DONE ]` compare anche per `first_scan_filesystem`,
molto prima che l'APK esista. Poi concede 2 s perché il processo esca da solo e
infine termina il suo albero.

Gli esiti si distinguono dal codice di uscita nei log:

| Exit | Significato |
|---|---|
| `0` | l'exporter è uscito da solo |
| `126` | terminato dopo `[ DONE ] export` |
| `125` | terminato dopo un APK rimasto stabile (ripiego) |
| `124` | scaduto senza alcun segnale |

In tutti i casi il criterio di successo resta l'**ispezione statica dell'APK**,
non il codice di uscita: `RECOVERED` si accetta solo con package, SDK, ABI,
firma e struttura ZIP verdi.

## 1. Compila (percorso raccomandato)

```powershell
# Solo export Android + validazione statica (abilita -InspectAndroid da sé).
.\tools\run-milestone-checks.ps1 -Milestone B23 -ExportAndroid

# Candidata completa: Full + refresh editor + export/runtime Windows + Android.
.\tools\run-milestone-checks.ps1 -Milestone B23 -Profile Release
```

Note operative:

- Con `-Milestone` il runner esegue **anche** lo smoke focalizzato di quel
  milestone se ne trova uno col marker corrispondente. Va bene: è una prova in
  più prima di impacchettare.
- `--install-android-build-template` viene passato **solo** se il template non è
  ancora installato, così gli export di routine non perdono `gradle.properties`.
- Se l'export non esce da solo ma l'APK è valido e l'ispezione statica è tutta
  verde, lo step diventa `RECOVERED`. È un esito accettabile e va riportato come
  tale, non come `PASS` silenzioso.
- Se serve più margine su una macchina lenta: `-ExportTimeoutSeconds 300` e
  `-AndroidArtifactStableSeconds 12`.
- Chiudi le altre istanze dell'editor sullo stesso progetto prima di un export
  CLI: la build riesce comunque, ma la console può restare agganciata
  all'istanza già attiva.

## 2. Export manuale (solo se il runner non è utilizzabile)

```powershell
New-Item -ItemType Directory -Force exports\android | Out-Null
godot_console --headless --path . `
  --export-debug "Android APK" `
  exports\android\pidgeon-survivor-debug.apk
```

Se resta appeso, **non** aspettare l'EOF e **non** uccidere genericamente tutti i
processi Godot o Java. Verifica prima che l'APK sia fermo:

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

Poi individua **il solo** processo il cui `CommandLine` contiene l'export
Android corrente e termina quello. Un daemon Gradle ancora vivo è normale e si
ferma con `android\gradlew.bat --stop` solo se nessun'altra build è in corso.

## 3. Valida l'artefatto

La presenza del file non prova il successo.

```powershell
.\tools\inspect-android-artifact.ps1
```

Controlla package `com.ilgioco.pidgeonsurvivor`, `minSdk 31`, `targetSdk 36`,
solo `arm64-v8a`, firma v2 valida, launcher MAIN/LAUNCHER, hash e stato ADB —
derivando le attese da `export_presets.cfg`. Registra dimensione, data e
SHA-256 nella nota di verifica.

## 4. Installa sul telefono

Prerequisito: device ARM64 collegato, debug USB attivo e **autorizzato** sul
telefono.

```powershell
adb devices -l
adb install -r exports\android\pidgeon-survivor-debug.apk
adb shell monkey -p com.ilgioco.pidgeonsurvivor -c android.intent.category.LAUNCHER 1
```

Trappola nota, stessa famiglia del problema sopra: **avvia il server adb prima**,
in un comando separato (`adb start-server`), se non è già in esecuzione. Un
`adb` che deve avviare il proprio daemon da dentro un processo con output
catturato può lasciare appeso chi legge quell'output — per questo motivo
`inspect-android-artifact.ps1` rileva i device solo se il server è già attivo e
non lo avvia mai da sé.

Se `adb install` fallisce con `INSTALL_FAILED_UPDATE_INCOMPATIBLE` (firma
diversa da quella già installata): `adb uninstall com.ilgioco.pidgeonsurvivor`
e reinstalla. Perde i dati locali dell'app, che in questo progetto sono solo le
impostazioni.

Per leggere i log del gioco durante la prova:

```powershell
adb logcat -c
adb logcat -s godot:V
```

`SCRIPT ERROR` e `FATAL EXCEPTION` nel logcat sono fallimenti anche se il gioco
sembra funzionare.

## 5. Riporta

Installare l'APK **non** chiude il gate di runtime fisico: quello richiede di
esercitare il percorso modificato sul device e leggere i log. Riporta
separatamente build (`PASS`/`RECOVERED`), validazione statica, installazione e
prova fisica. Vedi la skill `gate-piattaforme` per la disciplina di chiusura.
