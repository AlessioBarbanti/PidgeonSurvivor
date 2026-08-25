# Verifica B18P — Dimensioni configurabili dei controlli touch

Data verifica: 25 agosto 2026  
Godot: `4.7.1.stable.official.a13da4feb`

Stato: `COMPLETATO`. I gate automatici, Windows, APK statico e Pixel 9 fisico
sono chiusi.

## Contratto implementato

- `TouchControlSettings` è l'autorità persistente condivisa fra welcome, pausa
  e runtime. Salva in `user://touch_control_settings.cfg`, applica subito ogni
  modifica e sincronizza entrambi i frontend senza riavvio.
- La dimensione abilità offre `100/125/150%`; il nuovo default `125%` porta il
  target B18K da `64×64` a `80×80` unità logiche e l'icona da `42` a `53`.
- La dimensione joystick offre `85/100/115%`, con default `100%`. Controllo,
  raggio input `84`, base visiva `68`, manopola `27` e deadzone assoluta scalano
  con lo stesso fattore.
- Valori non finiti, fuori intervallo o intermedi vengono normalizzati alla
  taglia supportata più vicina. Il file viene riscritto nella forma canonica.
- L'origine del joystick resta dinamica nella safe area utile. La scala non
  restringe l'acquisizione, non trasforma il controllo in un intercettore GUI e
  lascia al secondo dito l'attivazione ripetuta dell'abilità.

## Verifica automatica

Smoke dedicato:

```powershell
godot_console --headless --path . `
  --script tests/integration/_touch_control_settings_smoke.gd
```

Marker: `B18P_TOUCH_CONTROL_SETTINGS_SMOKE_OK`.

La fixture copre default, normalizzazione, persistenza, sincronizzazione
welcome/pausa, applicazione immediata e geometria delle sei taglie. Per ogni
coppia supportata verifica inoltre il gesto sintetico con un dito che mantiene
il joystick e un secondo dito che attiva l'abilità. La matrice responsive copre
`1280×720` (16:9), `1600×720` (20:9) e `960×720` (4:3), inclusi safe area,
margini anti-gesture e assenza di sovrapposizioni.

La regressione completa è verde `36/36`; sono verdi anche gli smoke mirati
B18K, B18L, B18N, B18O e audiovisivo. Il controllo
`tools/verify-toolchain.ps1 -RunProjectSmoke` è verde. I log non contengono
`SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o `CONTRACT_FAIL`.

## Windows x64

L'export debug finale è riuscito. L'eseguibile è stato avviato realmente a
`1280×720` con renderer Compatibility/OpenGL 3.3 su NVIDIA GeForce RTX 3060.
Il log contiene `SMOKE_OK`, tutti i contratti fino a `B18P_CONTRACT_OK` e
`B17A_READY`.

## Android ARM64 e Pixel 9

I controlli statici dell'APK finale confermano:

- package `com.ilgioco.pidgeonsurvivor`, versione `0.1.0`/code `1`;
- `minSdk 31`, `targetSdk 36`, `compileSdk 36`;
- label `Pidgeon Survivor` e sola ABI `arm64-v8a`;
- firma APK Signature Scheme v2 valida.

L'APK finale è stato installato con aggiornamento e avviato a freddo sul Pixel
9 `tokay`, risoluzione fisica `1080×2424` e finestra landscape `2424×1080`.
Il log runtime contiene `B18P_CONTRACT_OK` e non contiene crash o marker di
fallimento.

Sul dispositivo sono stati esercitati welcome e pausa, modifica immediata,
persistenza dopo force-stop/cold launch ed estremi `150%` abilità con `85%`
joystick; al termine sono stati ripristinati i default `125/100%`. Il
proprietario ha confermato il 25 agosto 2026 il test fisico richiesto: joystick
tenuto con un dito e attivazioni ripetute dell'abilità con il secondo dito. Il
gate multitouch reale è quindi chiuso e non viene confuso con la sola
simulazione automatica o con l'ispezione statica dell'APK.

## Artefatti verificati

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `exports/windows/PidgeonSurvivor.exe` | `103115264` | `BFA5766944AD646D797F3FEB0172A0287A65CFD9FF08B1B1E449955985BC85FA` |
| `exports/windows/PidgeonSurvivor.pck` | `9363176` | `40C391EC25ADDD591C599637D3820B9CC75F673F39B3EE1EFD8801882B490E97` |
| `exports/android/pidgeon-survivor-debug.apk` | `93869794` | `EB5253A3C45D75E53D1AEBACF708B2BF67EBBE7F049ED8028D4BE0697E088B94` |

Gli artefatti generati restano esclusi dal versionamento.
