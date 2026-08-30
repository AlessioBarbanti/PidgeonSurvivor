# B18L — Joystick dinamico

Data verifica: 24 agosto 2026
Godot: `4.7.1.stable.official.a13da4feb`
Target obbligatori: Windows x64 e Android ARM64

Stato: `COMPLETATO`; gate chiusi nel commit dedicato `d6625d7`.

## Contratto implementato

- Il joystick resta invisibile al neutro. Il primo tocco valido dentro safe area
  e margini anti-gesture ne determina origine e comparsa.
- Il vettore usa quell'origine fino al rilascio o alla cancellazione; altri
  tocchi non rubano ownership né modificano il movimento.
- HUD superiore, linea XP, pulsante abilità, Boss UI e overlay sono esclusi. Il
  `Control` dinamico usa `MOUSE_FILTER_IGNORE`, così il secondo dito raggiunge il
  pulsante abilità anche mentre il primo possiede il joystick.
- Deadzone, raggio input `84` e raggio visivo `68` restano unità logiche del
  viewport Godot, non pixel fisici. La zona valida usa tutta la safe area utile
  a 16:9, 20:9 e 4:3, sottraendo soltanto margini anti-gesture e UI.
- Ogni stato diverso da `RunController.RUNNING`, focus/app pause, touch
  cancellato e restart azzerano ownership e vettore. La ripresa resta esplicita
  e soggetta al neutral-to-rearm di `InputRouter`.

## Verifica automatica

Comandi principali:

```powershell
godot_console --headless --path . --resolution 1280x720 --script tests/integration/_dynamic_joystick_smoke.gd
godot_console --headless --path . --resolution 1280x720 --script tests/integration/_active_ability_smoke.gd
godot_console --headless --path . --resolution 1280x720 --script tests/integration/_platform_lifecycle_smoke.gd
godot_console --headless --path . --resolution 1280x720 --script tests/integration/_visual_identity_smoke.gd
.\tools\verify-toolchain.ps1 -RunProjectSmoke
```

Risultati:

- smoke dedicato: `B18L_DYNAMIC_JOYSTICK_SMOKE_OK`;
- contratto scena: `B18L_CONTRACT_OK`;
- regressione completa: `27/27`, senza `SCRIPT ERROR`, `FATAL EXCEPTION` o
  marker `*_FAIL`;
- primo tocco, drag, ownership, rilascio, nuova origine, tocco cancellato,
  secondo dito sull'abilità, pausa, focus loss, ripresa esplicita e restart
  coperti deterministicamente;
- zone valide ed esclusioni HUD/abilità verificate a 1280×720, 1600×720 e
  960×720, corrispondenti a 16:9, 20:9 e 4:3.
- regressione sul difetto rilevato durante la prova fisica: anche un'origine
  vicina al bordo inferiore/sinistro viene acquisita; il raggio della grafica
  non restringe più la zona valida del tocco.

## Windows x64

L'export debug è riuscito. L'eseguibile è stato avviato realmente a `1280×720`
con renderer Compatibility/OpenGL sulla GPU NVIDIA e ha emesso
`B18L_CONTRACT_OK`, senza errori script o crash. Lo smoke mirato sintetizza gli
eventi touch perché l'host Windows non espone un touchscreen.

## Android ARM64

Godot ha prodotto l'APK, poi la CLI di export è rimasta appesa senza processi
Godot, Java o Gradle residui ed è stata terminata. La build separata da
`android\build` con `gradlew.bat --no-daemon assembleDebug --console=plain` è
terminata con `BUILD SUCCESSFUL`.

I controlli statici dell'APK confermano:

- package `com.ilgioco.friendshipsurvival`, versione `0.1.0`;
- `minSdk 31`, `targetSdk 36`, `compileSdk 36`;
- sola ABI `arm64-v8a`;
- firma APK Signature Scheme v2 valida.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `exports/android/friendship-survival-debug.apk` | `84819674` | `67D3F3ADC1FC8DFA955C89C5507AABA29C8EEEB315DEFF6B9D890CE03D95CD7D` |

Il Pixel 9 `tokay` Android 17/API 37 è stato collegato dopo l'export:

- `adb install -r -t` riuscito e cold launch completato in `321 ms` tramite
  `com.godot.game.GodotAppLauncher`;
- runtime `arm64-v8a` con viewport logico `1616×720`, safe area derivata dal
  display fisico `2424×1080`, `SMOKE_OK`, `B18L_CONTRACT_OK` e `B17A_READY
  os=Android`;
- catture locali ignorate da Git: `b18l_android_game.png` conferma il neutro
  senza joystick, `b18l_android_drag.png` conferma origine floating, knob e
  movimento durante un drag ADB mantenuto; `b18l_edge_fix_drag.png` conferma
  l'acquisizione vicino al bordo dopo la correzione delle fasce morte;
- Android Back apre la pausa e rimuove il joystick; un secondo Back riprende.
  Home e ritorno all'activity lasciano la run in pausa fino a `RIPRENDI`;
- sleep/wake mantiene vivo il processo e la ripresa dopo sblocco sicuro è stata
  provata fisicamente;
- log del processo senza `SCRIPT ERROR`, `FATAL EXCEPTION`, `ANR`, `SMOKE_FAIL`
  o `CONTRACT_FAIL`.

## Gate fisico finale e regressione lock/resume

La prova con due dita fisiche ha confermato ownership del joystick, attivazioni
ripetute dell'abilità col secondo dito, nuova origine dopo rilascio e restart
senza grafica o direzione residue.

La prima prova lock/sblocco ha rilevato uno spostamento del Player. I log di
sistema mostravano un passaggio transitorio del task da landscape `2424×1080` a
portrait `1080×2424` prima del ritorno landscape; `ArenaLayout` riclampava il
Player su quella geometria intermedia. La correzione:

- ignora il passaggio portrait transitorio quando esiste già un playfield
  landscape stabile;
- impedisce al Player di riclamparsi per un cambio layout fuori da `RUNNING`;
- aggiunge regressioni a `_movement_slice_smoke.gd` e
  `_platform_lifecycle_smoke.gd`.

La suite completa resta `27/27`; la controprova fisica con Bea fuori centro ha
confermato posizione invariata prima e dopo `RIPRENDI`.
