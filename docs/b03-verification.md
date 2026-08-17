# Verifica B03 — movimento, touch e arena

Data: 12 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione completata, gate Windows e Pixel 9 superato

## Risultato

Il vertical slice B03 è la scena principale del progetto. Include:

- movimento del Player tramite tastiera, frecce, stick sinistro e joystick touch;
- intensità analogica graduata e diagonale limitata al cerchio unitario;
- priorità del touch mentre il joystick possiede un dito;
- arena 16:9 ricavata dal viewport dinamico, con clamp che include il raggio del Player;
- safe area trasformata in coordinate viewport e margine aggiuntivo per le gesture Android;
- sospensione dell'input su focus loss/app pause e riarmo soltanto dopo il ritorno al neutro.

## Test automatici

Comandi eseguiti con Godot `4.7.1.stable.official.a13da4feb`:

```powershell
godot_console --headless --path . `
  --script tests/integration/_input_subsystem_smoke.gd

godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_movement_slice_smoke.gd

.\tools\verify-toolchain.ps1 -RunProjectSmoke
```

Esito:

```text
INPUT_SUBSYSTEM_SMOKE_OK
B03_MOVEMENT_SLICE_SMOKE_OK
SMOKE_OK version=4.7.1 renderer=gl_compatibility os=Windows
B03_CONTRACT_OK
```

La suite copre InputMap, touch ownership, secondo dito, cancel/release, deadzone,
priorità delle sorgenti, input held durante focus loss, neutral-to-rearm, ordine
parent-before-child delle notifiche di resume, movimento
nei frame fisici, clamp con raggio, layout 20:9 e 4:3, cutout, fallback della safe
area e padding anti-gesture. Il caso parent-before-child ora verifica che le
notifiche di focus-in richiedano la conferma esplicita introdotta da B06A. Il
dispatch touch nella suite è diretto: hit-testing e
routing dell'OS sono verificati separatamente sul telefono.

## Build Windows

La build debug Windows x64 è stata rigenerata e avviata dal wrapper console.
Ha terminato con codice `0` e ha stampato `SMOKE_OK` e `B03_CONTRACT_OK`.

| File | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `FriendshipSurvival.pck` | 81.972 | `AAB25E876041F3A8037EE16B6ABCAA9BDDBE0864D052DF4A4AA1B51CFEA84818` |

## Build e smoke Android

L'APK debug è stato rigenerato, verificato e installato con `adb install -r` sul
Pixel 9 collegato.

| Campo | Valore verificato |
|---|---|
| APK | 83.961.412 byte |
| SHA-256 | `3650DB9FF88E28C5D545D520C17DFCECD0EF2A49BDB6881282CBB7CE4E0F59F3` |
| Package | `com.ilgioco.friendshipsurvival` |
| SDK | minimo 31, target 36, compile 36 |
| ABI | solo `arm64-v8a` |
| Firma debug | APK Signature Scheme v2 valida |
| Device | Pixel 9, Android 17/API 37, ARM64, 2424×1080 landscape |

Marker runtime:

```text
SMOKE_OK version=4.7.1 renderer=gl_compatibility os=Android
B03_CONTRACT_OK
B03_READY os=Android viewport=1616x720 window=2424x1080
```

Sul Pixel il display cutout produce un inset fisico sinistro di 173 px. Il
rettangolo del joystick risulta a `x=263..599`, `y=630..966` px: resta a destra
del cutout e 30 px sopra l'inizio della mandatory gesture area inferiore
(`y=996`).

Il gate fisico ha verificato:

- drag touch instradato al joystick e movimento del Player;
- rilascio con ritorno a `INPUT +0.00,+0.00 • idle`;
- clamp destro esatto del centro Player a `x=1446`, includendo il raggio 24;
- Home/resume con lo stesso processo, joystick centrato e un nuovo drag opposto
  accettato correttamente dopo il ritorno;
- Back senza chiusura o perdita del processo;
- nessun `SCRIPT ERROR`, `FATAL EXCEPTION` o errore Godot nel log esaminato.

## Gate ancora aperti

- prova con un controller USB/Bluetooth reale su Windows: mapping e logica sono
  coperti automaticamente, ma non l'hardware;
- prova su Android 12/API 31, che resta il minimo supportato;
- multitouch fisico con un dito sul joystick e uno su un futuro pulsante/overlay;
- profiling e soak termico, pianificati in B19.

Gli artefatti e gli screenshot diagnostici sono locali e restano esclusi da Git.
