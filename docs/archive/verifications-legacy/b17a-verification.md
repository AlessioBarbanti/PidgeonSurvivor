# Verifica B17A — Roster giocabile completo e abilità attive

Data: 17 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione, test automatici, project smoke, export e installazione
Android completati; la regressione multitouch ripetuta è verificata sul Pixel 9,
mentre restano aperti keyguard e la matrice manuale completa del roster

## Perimetro aggiornato

B17A non è più limitato alle sette attive mancanti. Il piano include ora tutti
gli otto personaggi come roster realmente giocabile: selezione pre-run,
ritratto, passiva parametrica e abilità propria. La stima passa da 13 a 34 SP;
M5 passa da 36 a 57 SP e la candidata Windows/Android da 130 a 151 SP.

La selezione resta nello stato `BOOT`: clock, spawn ed effetti non avanzano
prima della conferma. `RIPROVA` conserva il profilo; `CAMBIA PERSONAGGIO` da
vittoria o sconfitta esegue prima il cleanup e poi riapre il roster.

## Roster runtime

| Profilo | Passiva B17A | Attiva |
|---|---|---|
| Magno | movimento `×1,15` | Onda d'Urto Tellurica |
| Bea | evasione `15%` | Scia di Fuoco Z |
| Zat | recupero differito `35%`, delay `3 s`, durata `4 s` | Tempesta di Tuoni |
| Alea | modificatore deterministico ogni `12 s` per `5 s` | Gran Piroetta |
| Aleo | danno `-15%`, resistenza knockback dati `×0,50` | Colata di Cemento |
| Lollo | movimento `×1,10`, fuoco `×1,15` | Cosplay Casuale |
| Migi | danno `-10%`, scudo sotto `35%` HP | Rallentamento Zen |
| Marghe | HP nemici base `×0,95`, Boss esclusi | Reggeton time! |

I moltiplicatori del personaggio e quelli degli upgrade restano separati e si
compongono moltiplicativamente. Random di Bea, Alea, tuoni e Cosplay usa il
seed della run. Cooldown, passive temporizzate, tick, aree, slow e illusioni
avanzano soltanto in `RUNNING`.

Dash, raggi, larghezze e aree sono unità logiche del mondo Godot, non pixel
fisici del display. `dash_distance=320`, `targeting_radius=800`, raggio Piroetta
`140`, Cemento `200` e Zen `260` mantengono quindi la stessa soglia gameplay su
16:9, 20:9 e 4:3; `ArenaLayout` continua a definire il playfield centrale.

## Test automatico dedicato

Comando:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_complete_roster_abilities_smoke.gd
```

Esito:

```text
B17A_CONTRACT_OK
B17A_COMPLETE_ROSTER_ABILITIES_SMOKE_OK
```

Lo smoke attraversa il selettore per tutti gli otto ID, conferma una run per
profilo, verifica ritratto, passiva, abilità assegnata, composizione con gli
upgrade, pausa degli effetti e cleanup tramite `CAMBIA PERSONAGGIO`. Controlla
inoltre dash e trail, tuoni, tick della Piroetta, slow/danno del Cemento,
filtro anti-ricorsione di Cosplay, aura Zen, clone e deviazione dell'aggro.

La suite completa contiene 19 smoke. Ogni processo termina con codice `0`, ha
un marker `*_SMOKE_OK` e non contiene `SCRIPT ERROR`, `FATAL EXCEPTION`,
`SMOKE_FAIL` o `CONTRACT_FAIL`:

```text
TOTAL=19 FAILURES=0
```

`tools/verify-toolchain.ps1 -RunProjectSmoke` termina con codice `0` e conferma
Godot 4.7.1, JDK 17, SDK 31/36, Build Tools 36.1.0, NDK, template, import e
project smoke.

### Retheme reggaeton di Marghe — 17 agosto 2026

`Esana Inganno d'Ombra` è diventata `Reggeton time!`. Titolo, copy e VFX
mostrano un clone ballerino con cassa pulsante; `marghe_shadow_deception`,
`shadow_deception`, cooldown `13 s`, durata `3 s`, deviazione dell'aggro e
cleanup restano invariati. Dopo il retheme, gli smoke contenuti e roster
completo terminano con:

```text
B17_FRIEND_CONTENT_SMOKE_OK
B17A_COMPLETE_ROSTER_ABILITIES_SMOKE_OK
```

Gli hash Windows riportati sotto documentano la build B17A precedente al ritocco
cosmetico; l'APK Android è stato invece rigenerato per questa correzione.

### Correzione multitouch ripetuto - 17 agosto 2026

Sul Pixel 9 è stato rilevato un caso Android in cui il primo tap dell'abilità
funzionava mentre i successivi non venivano inoltrati finché il primo dito
manteneva il joystick. Il percorso gameplay non dipende più dal solo latch del
`Button` GUI: `TouchAbilityButton` traduce ogni nuovo
`InputEventScreenTouch.pressed` dentro il proprio rettangolo in una singola
`activation_requested`, senza conservare l'indice del dito. Il segnale nativo
dello stesso gesto viene soppresso, mentre mouse, tastiera e controller
mantengono il percorso precedente.

`_active_ability_smoke.gd` ora mantiene il dito 0 sul joystick, esegue due tap
successivi con il dito 1 separati dal cooldown e verifica sia le due attivazioni
sia l'ownership continua del joystick. La suite completa resta a 19 smoke verdi,
senza errori runtime. Sulla build corretta l'utente ha poi confermato più
attivazioni consecutive sul Pixel 9 mantenendo il joystick: il gate fisico
specifico della regressione è chiuso.

## Export Windows

L'export debug e lo smoke dell'eseguibile esportato terminano con codice `0`.
Il runtime stampa `SMOKE_OK`, tutti i contratti B03–B17A e `B17A_READY`, senza
errori runtime.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.console.exe` | 101.376 | `6948E3214518231D0E009A43D013014A17D214E1EB5807E5AC309617860E07EA` |
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `FriendshipSurvival.pck` | 666.412 | `E05EA6FFBC55011C7DA88BA94BF4918EE70EFEB3E5194EC40C113EB2DD953693` |

## Export e installazione Android

L'export debug aggiornato con la correzione multitouch produce un APK di
84.518.164 byte con SHA-256
`E73111D801CA44EF6069F7FCDD622BB4729AC05764C73803FB0EEF2E94CE410B`.
`aapt2` conferma package `com.ilgioco.friendshipsurvival`, versione
`0.1.0`/code 1, `minSdk=31`, `targetSdk=36`, `compileSdk=36` e sola ABI
`arm64-v8a`; `apksigner` conferma APK Signature Scheme v2 valida.

L'aggiornamento in-place sul Pixel 9, Android 17/API 37, risulta installato alle
12:46:34 e l'activity è in foreground. Il runtime stampa `SMOKE_OK`, tutti i
contratti B03-B17A e `B17A_READY os=Android`. Anche dopo la prova fisica ripetuta
il log del processo non contiene `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL`
o `CONTRACT_FAIL`.

## Gate manuale ancora richiesto

Sul Pixel 9 sbloccato:

La sequenza base joystick mantenuto più attivazioni consecutive è passata sulla
build corretta. Restano da ampliare i controlli manuali ai profili e ai flussi
seguenti:

1. verificare che il roster mostri otto profili e che tap, focus e conferma
   assegnino ritratto, passiva e nome dell'attiva corretti;
2. tenere il joystick con un dito e attivare con il secondo, senza perdere il
   movimento, almeno con Bea, Aleo/Migi e Lollo;
3. controllare cooldown, pausa/ripresa esplicita, `RIPROVA` e
   `CAMBIA PERSONAGGIO` dopo un terminale;
4. ripetere il controllo durante B18T su Android 12/API 31, Android 16/API 36 e
   con controller Windows fisico.

B18 resta responsabile della rifinitura di art, VFX e audio; gli sprite e le
icone correnti sono placeholder sostituibili e non cambiano i contratti B17A.
