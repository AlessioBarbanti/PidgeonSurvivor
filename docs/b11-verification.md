# Verifica B11 — Overlay e navigazione completa

Data: 17 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione, test automatici, export e gate runtime Windows completati; runtime Android fisico aperto perché nessun device è attualmente visibile ad `adb`

## Risultato

B11 completa il tratto fra l'offerta dati B10 e la futura applicazione degli
effetti B12:

- `UpgradeOverlay` è un modal always-process dentro `SafeAreaRoot`, quindi le
  carte restano interattive mentre `LEVEL_UP` sospende il `SceneTree`;
- le tre `UpgradeCard` mostrano icona, titolo, descrizione, tipo e transizione
  di rank leggendo esclusivamente le `UpgradeDefinition` dell'offerta corrente;
- ogni carta è un unico `Button` ampio, con focus visibile e circolare;
- mouse e touch selezionano l'intero riquadro; frecce, WASD e D-pad navigano;
  Invio, Spazio, pulsante sud/A e i tasti 1–3 confermano;
- `ui_accept` include esplicitamente il pulsante sud del controller. Durante
  la run lo stesso pulsante continua a essere l'azione dell'abilità attiva,
  mentre in `LEVEL_UP` `InputRouter` è sospeso e il focus appartiene alle carte;
- prima di chiamare `UpgradeService.select_upgrade()`, l'overlay chiude il
  proprio gate e disabilita tutte le carte. Callback o input residui non possono
  applicare una seconda scelta alla stessa offerta;
- una coda di level-up mostra subito l'offerta successiva senza un frame
  `RUNNING`; l'ultima scelta chiude il modal e riprende la run;
- il joystick touch viene azzerato e nascosto per tutta l'offerta, poi torna
  alla sua visibilità precedente;
- clear, terminale e restart scollegano offerta, focus e stato UI senza
  conservare rank o riferimenti propri nell'overlay.

Gli effetti descritti dalle carte non vengono ancora applicati a Player o arma:
questo resta il perimetro di B12.

## Test automatici

Comando dedicato:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_upgrade_overlay_smoke.gd
```

Lo smoke copre:

- mapping da tastiera e controller, incluso `ui_accept` sul pulsante A;
- layout e assenza di sovrapposizioni su 16:9, 20:9 con cutout e 4:3;
- tre target touch da almeno `250 × 360` unità, interamente nella safe area;
- testi, icone, rank e offerta autorevole sulle tre carte;
- pausa totale, sospensione dell'input gameplay e joystick nascosto;
- quattro level-up accodati e confermati con tastiera, controller, mouse e
  touch sintetici instradati dal `Viewport`;
- esattamente un rank per conferma, passaggio immediato all'offerta successiva,
  ripresa finale e rifiuto degli eventi residui;
- reset dell'overlay e ripristino del joystick.

Esito dedicato:

```text
B11_UPGRADE_OVERLAY_SMOKE_OK
```

È stata rieseguita l'intera suite B03–B11: dodici smoke test verdi, tutti con
codice `0` e marker `*_SMOKE_OK`. Anche
`tools/verify-toolchain.ps1 -RunProjectSmoke` termina con codice `0`; la scena
principale e l'export Windows stampano:

```text
B11_CONTRACT_OK
B11_READY
```

## Export Windows e Android

Gli export debug sono stati rigenerati nelle directory ignorate. Lo smoke
dell'eseguibile Windows esportato termina con codice `0` e risolve il contratto
B11 completo.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.console.exe` | 101.376 | `6948E3214518231D0E009A43D013014A17D214E1EB5807E5AC309617860E07EA` |
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `FriendshipSurvival.pck` | 372.396 | `006BDD27FEDCC1A2D0EE0CF0CEF90B28FE607B7B8C9F3C12912F5ED84E0DF9A7` |
| `friendship-survival-debug.apk` | 84.236.614 | `9D2E3D6DB0716B9121702D3ED6E174218C267149709D8452DFF351C57CDA14A1` |

`aapt2`, `apksigner` e l'ispezione ZIP confermano package
`com.ilgioco.friendshipsurvival`, versione `0.1.0`/code 1, minSdk 31,
target/compileSdk 36, sola ABI `arm64-v8a` e firma debug APK Signature Scheme
v2 valida.

## Gate ancora aperti

Al momento della verifica `adb devices -l` non elenca dispositivi, quindi l'APK
B11 non è stato installato sul Pixel 9 in questa iterazione. Restano da chiudere:

- tap reali sulle tre carte e ripristino del joystick sul Pixel 9 o altro device
  Android ARM64;
- layout con safe area/cutout reale e coda di level-up multipla su Android;
- controller USB/Bluetooth reale su Windows e Android;
- profili esatti Android 12/API 31 e Android 16/API 36;
- applicazione e stacking degli effetti statistici, appartenenti a B12.
