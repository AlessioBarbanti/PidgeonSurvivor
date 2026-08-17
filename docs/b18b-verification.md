# B18B — Identità visiva, HUD compatto e combat feedback

Data: 17 agosto 2026  
Stato: implementazione, gate automatici, confronto Windows 16:9 ed export
Windows/Android completati. L'APK è installato e avviato sul Pixel 9 con
contratto verde. Restano i gate percettivi gameplay 20:9/4:3, densità elevata e
multitouch fisico prima del freeze per B19.

## Perimetro consegnato

- Il HUD usa una fascia superiore alta `64` unità logiche e una linea XP alta
  `8`. Ritratto, livello e vita sono a sinistra, il timer resta centrato e pausa
  occupa un target `48×48`.
- La card dell'abilità è `246×94` unità logiche e il pulsante misura almeno
  `44` unità per lato. Icona, nome, stato e cooldown restano sincronizzati dai
  segnali esistenti; il ritorno a `PRONTA` produce un singolo impulso visivo.
- Il joystick conserva area di acquisizione `224×224`, raggio input `84`,
  deadzone e curva di normalizzazione. Solo il disegno passa a raggio `68`, knob
  `27` e opacità a riposo `0,38`.
- `ArenaView` non disegna più griglia regolare o rettangolo ciano. Variazioni
  tonali, giunti spezzati, macchie e crepe sono generate in modo deterministico
  dal rettangolo di playfield e non introducono collisioni o ostacoli.
- Nemici e Player applicano flash da `0,075–0,08 s` e squash nel solo draw; il
  transform fisico non cambia. `CombatFeedback` disegna hit spark, anelli e nove
  particelle procedurali alla morte, reagisce anche al Boss e si pulisce al
  restart.
- Il proiettile alleato usa una scia stratificata con due afterimage. Il feedback
  B18B resta a `z_index=3`: sopra le aree alleate, sotto Player e proiettili.
- Con display driver `headless`, `GameAudio` verifica stream, mute, rate-limit e
  segnale `cue_played` senza creare playback OGG non udibile. Windows e Android
  continuano a usare il pool reale da dodici voci.

Tutte queste misure sono unità logiche del viewport Godot, non pixel fisici del
display. Collisioni, raggi, danni, cooldown, statistiche e parametri B17A/B18 non
sono stati modificati.

## Gate automatici

Comandi principali eseguiti:

```powershell
godot_console --headless --path . --editor --quit
godot_console --headless --path . --resolution 1280x720 --script tests/integration/_hud_smoke.gd
godot_console --headless --path . --resolution 1280x720 --script tests/integration/_audiovisual_feedback_smoke.gd
godot_console --headless --path . --resolution 1280x720 --script tests/integration/_visual_identity_smoke.gd
godot_console --headless --path . -- --smoke-test
godot_console --headless --path . --export-debug "Windows Desktop" exports/windows/FriendshipSurvival.exe
godot_console --headless --path . --export-debug "Android APK" exports/android/friendship-survival-debug.apk
```

Risultati:

- import e parse: superati;
- tutti i `21` smoke in `tests/integration/`: exit code `0`, marker atteso e log
  privi di `SCRIPT ERROR`, `FATAL EXCEPTION`, leak `ObjectDB` o risorse residue;
- marker nuovo: `B18B_VISUAL_IDENTITY_SMOKE_OK`;
- contratto della scena: `B18B_CONTRACT_OK`;
- project smoke: superato con tutti i contratti B03–B18B;
- export Windows avviato con `--headless -- --smoke-test`: exit code `0`,
  `B18B_CONTRACT_OK` e log senza errori;
- export Android installato con `adb install -r` e avviato sul Pixel 9:
  `B18B_CONTRACT_OK`, nessun `SCRIPT ERROR` o `FATAL EXCEPTION`.

Artefatti generati, esclusi dal source control:

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `exports/windows/FriendshipSurvival.exe` | `103.033.344` | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `exports/windows/FriendshipSurvival.pck` | `938.400` | `297D0CE87F0B5979E7E09ED7D7665473FD1CE842BE0A9772BA1432F2E6EB4EDF` |
| `exports/android/friendship-survival-debug.apk` | `84.762.179` | `0FD14E9350142C59780F5E1ABAA2497B2D7CBBFA664650DFB19BE1BF06B27628` |

Lo smoke B18B verifica ingombri HUD, target touch, separazione joystick/abilità,
assenza della griglia debug, budget degli elementi procedurali, invarianza del
raggio input, flash e squash, conteggio atomico di hit/death/Player feedback,
impulso di prontezza e cleanup al restart. `_hud_smoke.gd` copre inoltre i safe
rect sintetici 16:9, 20:9 con cutout e 4:3.

## Confronto visivo Windows 16:9

La scena è stata registrata a `1280×720`, seed `1`, Compatibility/OpenGL 3.3 su
NVIDIA GeForce RTX 3060. I frame esclusi dal source control sono:

- prima: `exports/screenshots/before_b19_gameplay00000004.png`;
- dopo: `exports/screenshots/after_b18b_gameplay00000004.png`.

Il confronto conferma che la fascia HUD e la card abilità occupano meno campo,
la pausa è riconoscibile come icona, il joystick inattivo è meno dominante e il
pavimento non appare più come una griglia di debug. Player, nemici e proiettile
restano il primo livello di lettura. La cattura non sostituisce i controlli
percettivi su densità elevata o device fisico.

## Avvio Pixel 9

Il device collegato (`Pixel 9`, Android 17/API 37) ha avviato l'APK aggiornato in
landscape `2424×1080`. Godot ha calcolato viewport `1616×720`, playfield con
posizione logica `(261,22; 20)` e dimensione `(1208,89; 680)`, e safe area con
posizione logica `(135,33; 20)` e dimensione `(1460,67; 680)`. La selezione
degli otto profili resta interamente nella
safe area; la schermata è conservata in
`exports/screenshots/b18b_pixel9_selection_after.png`. L'avvio non ha prodotto
errori script o crash. Il controllo gameplay e il gesto reale a due dita non
sono inferiti dall'avvio ADB e restano manuali.

## Gate manuali residui

1. Verificare sul Pixel 9 il gameplay 20:9 e su output reale 4:3: HUD, Boss UI,
   level-up, pausa e terminali non devono sovrapporsi. Selezione e rettangoli sono
   già coperti, ma la qualità percettiva richiede il controllo in run.
2. Sul Pixel 9, mantenere il joystick con un dito e attivare ripetutamente con il
   secondo usando Bea, Aleo/Migi e Lollo; non devono comparire input persi o frame
   spike visibili.
3. Combinare Boss, area persistente, fulmini e densità elevata e confermare che
   telegraph e proiettili ostili restino distinguibili sopra burst e VFX alleati.
4. Provare una run Windows interattiva a densità elevata e controllare che il
   polish non introduca stutter o oscuri il mix audio.
5. Chiudere il gate percettivo audio B18 già elencato in
   [`b18-verification.md`](./b18-verification.md).

Android 12/API 31, Android 16/API 36, controller fisico, profiling e soak restano
nel perimetro B19 dopo il freeze della presentazione.
