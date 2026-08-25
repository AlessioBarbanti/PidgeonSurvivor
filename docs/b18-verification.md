# B18 — Art, VFX, audio, contrasto e volume

Data: 17 agosto 2026  
Stato: implementazione e gate automatici completati; layout e controlli mixer
verificati sul Pixel 9. Restano l'ascolto e il controllo percettivo ad alta
densità su Windows/Pixel 9.

## Perimetro consegnato

- Le otto `AbilityDefinition` usano otto icone SVG dedicate; gli undici upgrade
  usano pittogrammi coerenti per effetto o signature e nessun contenuto gameplay
  punta più a `assets/art/icon.svg`.
- Onda tellurica, tuoni, aree persistenti e telegraph mirato hanno contorni e
  pattern geometrici aggiuntivi, quindi non dipendono soltanto dal colore.
- Il mondo usa una gerarchia esplicita: pickup `-1`, VFX alleati `0`,
  nemici/telegraph `2`, Player `4`, proiettili alleati `6`, proiettili Boss `10`.
  Le aree alleate non possono quindi coprire un attacco ostile.
- `GameAudio` collega sparo, hit, danno Player, pickup, level-up, attivazione e
  ricarica abilità, warning/attacco Boss, conferme UI, pausa/ripresa e finali.
  Un pool da dodici voci evita che cue simultanei si interrompano a vicenda;
  sparo, hit e pickup hanno un rate limit esclusivamente sonoro.
- Il menu di pausa espone slider `0–100%` e mute con target touch da almeno
  `44` unità logiche. Le impostazioni operano anche a SceneTree in pausa e sono
  persistite in `user://audio_settings.cfg`.

Nessun ID, cooldown, durata, raggio, danno o parametro runtime B17A è stato
modificato. Le distanze citate restano unità logiche del mondo Godot, non pixel
fisici del display.

## Asset e licenze

I quattordici `.ogg` sono un subset dei pacchetti Kenney `Interface Sounds 1.0`,
`Impact Sounds 1.0` e `Music Jingles 1.0`, tutti Creative Commons Zero 1.0.
Le licenze originali, il mapping dei nomi e gli SHA-256 sono conservati in
[`assets/audio/third_party/kenney_b18/ASSET-MANIFEST.md`](../assets/audio/third_party/kenney_b18/ASSET-MANIFEST.md).
Le icone SVG sono originali del progetto e non derivano dai pacchetti scaricati.
Le voci personali dei personaggi non sono state inventate e restano assenti.

## Gate automatici

Comandi eseguiti nella verifica finale:

```powershell
godot_console --headless --path . --editor --quit
godot_console --headless --path . --script tests/integration/_audiovisual_feedback_smoke.gd
godot_console --headless --path . -- --smoke-test
```

Lo smoke B18 verifica cue e licenze, bus/pool, volume e mute, persistenza su una
fixture isolata, sincronizzazione UI, icone non generiche, layering e contrasto
del testo primario HUD almeno `4.5:1`. Il marker atteso è
`B18_AUDIOVISUAL_SMOKE_OK`; il contratto della scena stampa `B18_CONTRACT_OK`.

Risultati del 17 agosto 2026:

- import headless, `verify-toolchain.ps1 -RunProjectSmoke` e project smoke:
  superati senza `SCRIPT ERROR` o `FATAL EXCEPTION`;
- tutti i 20 smoke script di integrazione: exit code `0` e marker attesi;
- export Windows debug avviato con `--headless -- --smoke-test`:
  `B18_CONTRACT_OK`;
- export Android debug ARM64: installazione aggiornata riuscita sul Pixel 9;
  lancio pulito con Godot 4.7.1, OpenGL ES 3.2 Compatibility e
  `B18_CONTRACT_OK`, senza errori script o crash;
- APK `exports/android/friendship-survival-debug.apk`: `84.732.323` byte,
  SHA-256 `8FEAD10692CAE63069AB7CAD497267A1C76BB646D1C918829EAA81171E829501`;
- Windows PCK `exports/windows/FriendshipSurvival.pck`: `907.372` byte,
  SHA-256 `1A0714E54DD4103AA8B8489AAD1CD72405096C191D26D630F91DF781B1209F23`.

## Verifica fisica Pixel 9

Il device collegato (`Pixel 9`, Android 17/API 37) ha eseguito l'APK in
landscape `2424×1080`. Godot ha calcolato un viewport `1616×720` e una safe area
logica `[P: (135.3333, 20.0), S: (1460.667, 680.0)]`; sono state ispezionate selezione
personaggio, run e pausa senza clipping o sovrapposizioni con il cutout.

L'Onda d'Urto Tellurica è stata attivata via touch: anello, riempimento tenue e
crepe radiali sono risultati visibili, mentre Player e proiettile alleato sono
rimasti davanti all'area. L'HUD ha aggiornato immediatamente lo stato a
`RICARICA 7.8 s`.

Durante la pausa lo slider è stato portato realmente da `80%` a `30%` e il mute
è stato attivato; entrambi hanno aggiornato subito lo stato visivo mentre il
SceneTree era fermo. Prima di chiudere il test sono stati ripristinati `80%` e
audio attivo. Le schermate di prova restano negli artefatti esclusi dal source
control sotto `exports/screenshots/`.

## Gate manuale residuo

1. Su Windows, ascoltare una run con densità alta e verificare che sparo/hit non
   saturino level-up, abilità pronta e warning Boss.
2. Su Windows, provare volume minimo, intermedio, massimo e mute; chiudere e
   riaprire il gioco e confermare la persistenza percepita. La persistenza dati
   è già coperta dallo smoke e l'interazione touch `30%`/mute dal Pixel 9.
3. Su Pixel 9, mantenere il joystick con un dito e attivare con il secondo;
   confermare che VFX e audio non introducano input perso o frame spike visibili.
4. Con area persistente, tuoni e Boss insieme, confermare che telegraph e
   proiettili ostili restino sempre distinguibili a 16:9, 20:9 e 4:3.

Il test fisico esteso Android 12/API 31, Android 16/API 36 e controller Windows
resta il gate pianificato di B18T.
