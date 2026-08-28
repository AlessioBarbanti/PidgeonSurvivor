# B18O — Welcome screen

Data verifica: 24 agosto 2026  
Godot: `4.7.1.stable.official.a13da4feb`

## Contratto implementato

Stato corrente: flusso funzionale e variante finale del cast verificati su
automatici, Windows, APK statico e Pixel 9 fisico a 20:9.

- `WelcomeScreen` è il frontend iniziale always-process dentro `SafeAreaRoot`.
  Al cold launch `RunController` resta in `BOOT`, con clock e seed a zero,
  input gameplay sospeso, spawner vuoto, HUD e joystick nascosti.
- `GIOCA` apre il selettore senza creare la run. Soltanto la conferma del
  profilo equipaggia il personaggio, assegna il seed, passa a `RUNNING` e
  riattiva HUD, joystick e input gameplay.
- `IMPOSTAZIONI` espone volume effetti, mute e Flash ridotti usando le autorità
  persistenti già condivise con la pausa. Le modifiche sono applicate subito e
  i due frontend restano sincronizzati.
- Welcome, impostazioni e selettore hanno focus iniziale o di ritorno, target
  touch da almeno `44` unità logiche e navigazione mouse, tastiera, controller
  e touch. Back chiude prima le impostazioni; dal selettore riapre la welcome
  conservando `BOOT` e senza stato residuo.
- Gli smoke storici headless continuano ad auto-avviare Magno per preservare le
  fixture. Il flusso reale resta quello di release; il solo smoke B18O forza la
  welcome tramite un flag `ProjectSettings` limitato al processo di test.

## Refresh visuale ImageGen

La baseline verificata il 24 agosto usa la variante pixel-art `1634×919` prodotta con la modalità
built-in di OpenAI ImageGen a partire dalla reference fornita e approvata dal
proprietario. L'edit rimuove insegna, testi e pulsanti incorporati, ricostruisce
lo scenario centrale e sposta i personaggi quanto basta per lasciare volti,
costumi e oggetti abilità fuori dall'area menu. Gli otto archetipi fittizi
restano energumeno tellurico bovino, pattinatrice in viola senza casco e dai
capelli lunghi ricci, infermiera elettrica con caschetto e divisa bianco-ciano,
ballerina, muratore, cosplayer sopravvissuto dai capelli scuri, donna zen con
occhiali e ballerina reggaeton dai capelli neri molto lunghi. Piccioni,
grigliata e luci da festa restano ai bordi; nessuna fotografia o persona reale è
stata usata.

Il logo RGBA `1536×1024` fornito e poi aggiornato dal proprietario è mostrato al
centro senza trasformazioni locali, in un `TextureRect` proporzionale separato
dal pannello azioni. Contiene già il titolo ufficiale `Pidgeon Survivor` e il
sottotitolo esatto `It's grilling time!`, quindi il rebrand del 24 agosto non ne
modifica pixel, dimensioni o SHA-256. `GIOCA` è una CTA arancione profonda e le azioni secondarie
usano pannelli blu-ciano. Quando si aprono le impostazioni, il logo viene
nascosto e il pannello si ricentra senza coprire Marghe, Bea o Migi; Back
ripristina la composizione principale. Pulsanti, slider, focus e target touch
restano nodi Godot, non pixel incorporati nel fondale.

Prompt finale, generatore, origine, autore, licenza, trasformazioni e SHA-256
sono registrati nel
[`manifest welcome`](../assets/art/ui/welcome/ASSET-MANIFEST.md). Il fondale è
dedicato al frontend B18O e non anticipa né sostituisce lo sfondo arena B18S.

## Verifica automatica

Smoke dedicato:

```powershell
godot_console --headless --path . `
  --script tests/integration/_welcome_flow_smoke.gd
```

Marker: `B18O_WELCOME_FLOW_SMOKE_OK`.

La fixture copre welcome → impostazioni → Back, welcome → selettore → Back,
Android Back nel selettore, scelta Bea → run, sincronizzazione delle
impostazioni e profili `1280×720` (16:9), `1600×720` (20:9) e `960×720` (4:3).
Verifica esplicitamente `BOOT`, clock e seed a zero, assenza di spawn, input
sospeso e frontend contenuto nella safe area. Lo smoke valida inoltre fondale
`1634×919`, logo `1536×1024`, relativi SHA-256 e manifest. La matrice controlla
che logo e azioni siano due blocchi distinti nella safe area e che il gruppo non
superi il `72%` dell'altezza utile; il flusso impostazioni verifica anche
scomparsa e ripristino del logo.

La regressione completa è `34/34`; sono verdi anche gli smoke mirati B18N,
lifecycle, roster, audiovisivo e identità visiva. Anche
`tools/verify-toolchain.ps1 -RunProjectSmoke` è verde. Exit code e log sono
privi di `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` e `CONTRACT_FAIL`.

## Windows x64

L'export debug `Windows Desktop` è riuscito. L'eseguibile è stato avviato
realmente a `1280×720` con renderer Compatibility/OpenGL 3.3 su NVIDIA GeForce
RTX 3060. Il log contiene `SMOKE_OK`, `B18O_CONTRACT_OK`,
`B18O_WELCOME_SHOWN` e `B17A_READY ... seed=0`; la welcome resta attiva senza
avviare clock, spawn o input gameplay. Il refresh visuale usa il fondale e gli
stili definitivi senza errori di import o runtime.

## Android ARM64 e Pixel 9

L'export APK debug è riuscito. I controlli statici confermano:

- package `com.ilgioco.friendshipsurvival`, versione `0.1.0`/code `1`;
- `minSdk 31`, `targetSdk 36`, `compileSdk 36`;
- orientamento landscape e sola ABI `arm64-v8a`;
- firma APK Signature Scheme v2 valida.

L'APK è stato installato e avviato sul Pixel 9 fisico con Android 17/API 37,
risoluzione fisica `1080×2424`, finestra landscape `2424×1080` e viewport Godot
`1616×720`. Il cold launch registra `B18O_WELCOME_SHOWN` e
`B17A_READY ... friend=magno seed=0`.

Il percorso è stato esercitato sul dispositivo con tap e Back iniettati via
ADB:

1. cold launch sulla welcome, con pannello e target interamente nella safe area
   20:9;
2. `IMPOSTAZIONI` → Back → welcome;
3. `GIOCA` → selettore → Back → welcome;
4. `GIOCA` → Bea → `GIOCA CON BEA`, ottenendo
   `B18O_RUN_STARTED friend=bea` e la run con ritratto, HUD e abilità di Bea;
5. nuovo cold launch → Home → rientro, ancora sulla welcome con seed `0` e
   nessun `B18O_RUN_STARTED`.

Le schermate acquisite sulla prima variante confermano leggibilità, focus e
assenza di debordi a 20:9: gruppo e piccioni incorniciano il pannello, il centro
conserva contrasto e i pulsanti restano interamente nella safe area. L'ultimo log
scan non contiene `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL`,
`CONTRACT_FAIL` o ANR. Le interazioni sono avvenute sul Pixel 9 reale, non
simulate da uno smoke headless.

La variante finale del cast è stata installata e ricontrollata sul Pixel 9 con
finestra `2424×1080` e viewport Godot `1616×720`. Gli screenshot
`exports/android/b18o-bea-curly.png` e
`exports/android/b18o-lollo-zat.png` confermano il pannello interamente nella
safe area e il centro leggibile. Bea resta senza casco, con giacca viola e
capelli scuri lunghi e ricci; Lollo mantiene il costume retrofuturista e ha
capelli scuri; Zat ha un taglio a caschetto, nessun copricapo e una divisa
bianco-ciano da infermiera. Migi, Marghe e gli altri archetipi restano coerenti
e non debordano. I log contengono
`B18O_CONTRACT_OK`, `B18O_WELCOME_SHOWN` e `B17A_READY ... seed=0`, senza
`SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL`, `CONTRACT_FAIL` o ANR.

La ricomposizione dalla reference e il logo finale aggiornato sono stati
installati con un nuovo cold launch sullo stesso Pixel 9. Gli screenshot
`exports/android/b18o-reference-logo-final.png` e
`exports/android/b18o-reference-logo-settings.png` mostrano a `2424×1080` il
logo centrale proporzionato, i due pulsanti nella safe area e tutti gli otto
volti fuori dal pannello. Nelle impostazioni il logo scompare, il pannello si
ricentra e Marghe, Bea e Migi restano leggibili. I log della build finale
contengono `SMOKE_OK`, `B18O_CONTRACT_OK`, `B18O_WELCOME_SHOWN` e viewport
`1616×720`, senza errori Godot o `AndroidRuntime`.

Due micro-regolazioni successive portano l'area finale del logo da `405×270` a
`465×310`. Il contenitore conserva `290 px` di altezza e il logo sborda in modo
controllato di `10 px` sopra e sotto: l'insegna cresce e sale senza spingere i
pulsanti verso il cast inferiore. La resa è stata controllata su un frame reale
a `1280×720`; lo smoke responsive verifica anche il rettangolo effettivo del
logo e resta verde a `1280×720`, `1600×720` e `960×720`, così come gli export
Windows e Android. Il Pixel 9 non era collegato per ripetere il gate fisico su
queste sole micro-regolazioni; le evidenze fisiche precedenti restano quindi
riferite alla composizione `405×270`.

## Artefatti verificati

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `assets/art/ui/welcome/welcome_ability_cast_background.png` | `2992305` | `93F85FD7F2A76F889A56961ED17DDE667E0C8621EE085FE402AA0349F17C24D0` |
| `assets/art/ui/welcome/welcome_logo.png` | `1856853` | `C2A63ADD4753ECE374CF673D636D12CCE55E55CD43624AED645BF8F5C347FA9F` |
| `exports/windows/FriendshipSurvival.exe` | `103033344` | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `exports/windows/FriendshipSurvival.pck` | `6566208` | `EE088E3D5D658164B9000454FA7269AA142DEDED42F50A087461D1663FCA4069` |
| `exports/android/friendship-survival-debug.apk` | `90357808` | `E5CE0BCC0E62A163A85253DCA38B2917BA7475CB4300BE149C4136EF6E6BA558` |

Gli artefatti e le schermate di verifica restano esclusi dal versionamento.

## Refresh identità del cast — 28 agosto 2026

Il fondale runtime è stato sostituito con una composizione `1664×936` che usa i
master correnti in `assets/art/characters/players/hd/`: Aleo termotecnico,
Magno muscoloso con motivo bovino, Alea ballerina bionda, Marghe più morbida,
Lollo retrofuturista, Migi nello scudo tartaruga, Bea con bandana e pattini a
terra, Zat medico elettrico. La pulizia finale conserva esattamente otto persone
e lascia libera l'area menu; Lollo è stato abbassato finché entrambi gli stivali
poggiano visibilmente sulla piattaforma. Magno mostra una coppia più leggibile
di corna decorative montate sull'armatura; le onde ciano davanti ai pattini di
Bea sono state rimosse senza toccare la scia arancione. Il master completo
`1672×941` è in `assets/art/ui/welcome/hd/`, esclusa da import ed export; i raster intermedi
delle prove precedenti e il fondale base senza cast sono stati rimossi dal
repository e restano recuperabili dalla cronologia git.

SHA-256 runtime:
`FE721F5A98048FB8DB4093700AF50B0AC9A070B1AF92582B4B16059D9D8F1BA9`.
Le verifiche automatiche del refresh sono registrate nella sessione corrente;
il nuovo controllo percettivo del proprietario e il passaggio fisico Pixel 9
restano aperti e non sono confusi con le evidenze storiche del 24 agosto.

Verifiche eseguite il 28 agosto:

- refresh import editor Godot 4.7.1 completato senza errori;
- `run-milestone-checks.ps1 -Milestone B18O -Profile Focused -NoCache`: PASS
  `1/1`, marker `B18O_WELCOME_FLOW_SMOKE_OK`;
- profilo `Relevant -NoCache`: il controllo B18O e 22 regressioni su 23 sono
  verdi; `_complete_roster_abilities_smoke.gd` fallisce sul pannello roster
  fuori safe area a causa del rework Lollo già presente nel worktree, separato
  dal fondale welcome;
- nessun `.import` nella cartella HD e filtro di esclusione presente in tutti e
  tre i preset; hash runtime e dimensioni corrispondono al manifest.

## Rebrand ufficiale — 24 agosto 2026

Il nome pubblico è ora `Pidgeon Survivor` e il sottotitolo esatto è
`It's grilling time!`. Il logo welcome conteneva già entrambe le stringhe nella
forma approvata ed è rimasto invariato: SHA-256
`C2A63ADD4753ECE374CF673D636D12CCE55E55CD43624AED645BF8F5C347FA9F`.
Le righe precedenti conservano nomi e hash dei vecchi artefatti come evidenza
storica; i nuovi output usano l'identità aggiornata.

Verifiche eseguite:

- import editor Godot 4.7.1 pulito;
- `_welcome_flow_smoke.gd` verde con `B18O_WELCOME_FLOW_SMOKE_OK` e assert
  espliciti su nome e sottotitolo;
- `verify-toolchain.ps1 -RunProjectSmoke` verde;
- smoke dell'EXE Windows completato con exit code `0`; proprietà PE
  `ProductName=Pidgeon Survivor` e
  `FileDescription=Pidgeon Survivor - It's grilling time!`;
- APK debug con package `com.ilgioco.pidgeonsurvivor`, label
  `Pidgeon Survivor`, `minSdk 31`, `targetSdk 36`, `compileSdk 36`, sola ABI
  `arm64-v8a` e firma v2 valida;
- installazione e cold launch reali sul Pixel 9: activity
  `com.ilgioco.pidgeonsurvivor/com.godot.game.GodotApp`, marker
  `B18O_WELCOME_SHOWN` e `B17A_READY ... os=Android ... seed=0`; la cattura
  `exports/android/pidgeon-survivor-pixel9-cold-launch.png` mostra titolo,
  sottotitolo e azioni interamente leggibili a `2424×1080`.

| Artefatto rebrand | Byte | SHA-256 |
|---|---:|---|
| `exports/windows/PidgeonSurvivor.exe` | `103033344` | `03F6E0DC9553BF3B06B9D72D96AD99214E53C2DF3AC9730DE8225170EB8D534E` |
| `exports/windows/PidgeonSurvivor.pck` | `6566528` | `6EAFB49FEDE049940D80CDC16EFFB6065F8587CCBA17BAB9B657AE4BE02FB7CD` |
| `exports/android/pidgeon-survivor-debug.apk` | `90358104` | `B3163C2FB5E1BAEF4356366B02B18793F98C050E8A4F40DA128F99B44731C415` |

## Icona applicazione — 25 agosto 2026

La nuova icona ufficiale è un master ImageGen senza testo con un solo piccione,
occhiali pixel, collo iridescente e alone da griglia. Il master opaco è usato da
Godot e Windows e come icona Android classica; un secondo output ImageGen RGBA,
ridotto deterministicamente e centrato nella safe area, è il foreground
adattivo sul fondale notte `#071126`. Prompt, trasformazioni, licenza e hash
sono registrati in `assets/art/branding/ASSET-MANIFEST.md`.

Verifiche eseguite:

- import editor Godot 4.7.1 pulito e `_app_icon_smoke.gd` verde con
  `APP_ICON_SMOKE_OK`;
- `verify-toolchain.ps1 -RunProjectSmoke` verde;
- export e runtime smoke Windows verdi: l'icona estratta dall'EXE a `32×32`
  conserva piccione, occhiali e alone;
- APK con package `com.ilgioco.pidgeonsurvivor`, label `Pidgeon Survivor`,
  `targetSdk 36`, sola ABI `arm64-v8a`, adaptive icon compilata e firma v2
  valida;
- installazione reale sul Pixel 9 riuscita. La schermata Informazioni app mostra
  la maschera circolare senza tagliare becco, occhiali o alone; il cold launch
  porta in foreground
  `com.ilgioco.pidgeonsurvivor/com.godot.game.GodotAppLauncher`.

| Artefatto icona/build | Byte | SHA-256 |
|---|---:|---|
| `assets/art/branding/pidgeon_survivor_app_icon.png` | `1271719` | `99E86E1354361736973E789E80F0C2382650D54EF4F5160C49C04FE856C5BA32` |
| `assets/art/branding/pidgeon_survivor_adaptive_foreground.png` | `1063165` | `A1A0EA8BB66A3A1818F285B8C46AA110DB4A74F02CD696D1D9D9E3206CE43A4F` |
| `assets/art/branding/pidgeon_survivor_adaptive_background.png` | `1760` | `86EC85DBE31E6DCCC77933B6B7F0D595C1F6068B90D95A99435441B5BFC6AD4F` |
| `exports/windows/PidgeonSurvivor.exe` | `103115264` | `BFA5766944AD646D797F3FEB0172A0287A65CFD9FF08B1B1E449955985BC85FA` |
| `exports/windows/PidgeonSurvivor.pck` | `8883348` | `A466C6DA302F5D4D3945E6088467C09DB7D4616AB656E273B3AA15E13EE647AA` |
| `exports/android/pidgeon-survivor-debug.apk` | `93847074` | `A6EDAE5B0D955BE43B165743BEE55B7065FEBD3A78D8E9D76F8749869111A7A9` |

Gli output e gli screenshot di verifica restano esclusi dal versionamento.
