# B18Q — Arena e HUD minimo a barre

Data: 25 agosto 2026
Stato: `COMPLETATO`

## Contratto implementato

- Il HUD superiore contiene soltanto due barre full-width più corpose e
  arrotondate: esperienza `18` unità con tag fisso `XP`, vita `20` unità con tag
  fisso `HP`. Ritratto, livello e valori numerici restano assenti.
- Pausa conserva il target `48×48` e fluttua sopra l'estremità destra senza
  ridurre le barre. Il cronometro usa font `28`, è centrato sotto le barre e non
  possiede label `Tempo`, card o sfondo.
- `GameHud.GAMEPLAY_TOP_INSET` vale `88` unità logiche. `MovementSlice` lo
  consegna ad `ArenaLayout`, che sottrae la fascia dalla safe area prima del fit
  responsive e conserva il filtro dei layout portrait transitori.
- Player e pickup usano il clamp circolare del nuovo playfield; spawn, anello di
  ingresso e despawn derivano dallo stesso rect. Boss e telegraph continuano a
  consumare il playfield autorevole.

## Verifica automatica

Smoke dedicato:

```powershell
godot_console --headless --path . --script tests/integration/_arena_hud_minimal_smoke.gd
```

Risultato: `B18Q_ARENA_HUD_MINIMAL_SMOKE_OK` su `1280×720`, `1440×720`,
`1600×720` e `960×720`. Il test copre barre/tag, timer trasparente, pausa,
centro, lati, angoli, pickup, spawn/despawn, Boss e clock fuori da `RUNNING`.

La regressione completa del repository è verde `41/41`. Dopo il raffinamento
`XP`/`HP` sono inoltre verdi HUD, identità visuale, lifecycle e impostazioni
touch. La pipeline compatta chiude refresh editor, project smoke e toolchain.

## Windows

- Export debug `exports/windows/PidgeonSurvivor.exe`: completato.
- Runtime export a `1280×720`: `SMOKE_OK` e `B18Q_CONTRACT_OK`, senza
  `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o `CONTRACT_FAIL`.
- La matrice percettiva manuale 16:9/18:9/20:9/4:3 è stata completata il
  25 agosto 2026.

## Android e Pixel 9

Artefatto finale verificato:

- file: `exports/android/pidgeon-survivor-b18q-debug.apk`;
- SHA-256: `89814A51BFF255BE6DAF71877072BB1086FE14FA7A029691D769F98AA3038685`;
- package `com.ilgioco.pidgeonsurvivor`, minSdk `31`, targetSdk `36`, ABI
  `arm64-v8a`, firma v2 e launcher `com.godot.game.GodotAppLauncher`: verdi;
- installazione `adb install -r`: riuscita sul Pixel 9 `49140DLAQ0010Y`;
- cold launch e percorso welcome → selezione → run via ADB: riusciti;
- runtime logico `1616×720`, safe area `[P: (135.3333, 20), S: (1460.667,
  680)]`, playfield finale `[P: (339.4444, 108), S: (1052.444, 592)]`;
- logcat: `B18Q_CONTRACT_OK`, nessun errore Godot o crash Android pertinente.

I tap ADB e lo screenshot del device confermano il percorso runtime e la
composizione renderizzata; il controllo separato con dito e la valutazione
percettiva sul pannello fisico, inclusi leggibilità, spessore percepito e
interazione manuale, sono stati completati il 25 agosto 2026.

## Nota tooling

Un vecchio exporter Godot rimasto attivo sul nome APK standard è stato
identificato per PID e terminato su autorizzazione del proprietario. È stata
anche corretta `tools/inspect-android-artifact.ps1`: il validatore non avvia più
il daemon ADB dentro la pipeline con output catturato, perché su Windows il
daemon può ereditare la pipe e impedire al runner di ricevere EOF. Con ADB
spento la pipeline ora termina in circa dieci secondi con
`OPEN_ADB_SERVER_NOT_RUNNING`; con ADB già avviato rileva correttamente il
device collegato.

Durante l'ultimo export Android, Godot ha completato la scrittura dell'APK ma è
rimasto inattivo senza figli Gradle; il processo task-owned è stato terminato
dopo verifica di timestamp e stabilità. L'artefatto risultante ha poi superato
tutti i controlli statici ed è stato installato ed eseguito sul Pixel 9.
