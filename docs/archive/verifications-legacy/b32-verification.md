# B32 — Welcome CTA coerente e impostazioni a ingranaggio

Data: 27 agosto 2026  
Stato: `IN VERIFICA`.

## Implementazione

- `GIOCA` riusa `character_select_cta_base.png` e i tre `StyleBoxTexture` del
  CTA B18W; il testo resta nativo nella welcome e la placca fluttua sul fondale
  senza il precedente riquadro/pannello esterno.
- Il precedente pulsante centrale `IMPOSTAZIONI` è sostituito da un ingranaggio
  Godot nativo `60×60`, ancorato in alto a destra e separato di `22` unità dal
  bordo del viewport.
- Navigazione focus circolare tra CTA e ingranaggio, tooltip accessibile e stato
  pressed, touch e Back continuano a usare il percorso B18O. Il focus resta
  funzionale ma non disegna un outline; aprire o chiudere le impostazioni non
  crea una run e conserva `BOOT`.

## Evidenza automatica

```powershell
godot_console --headless --editor --path . --quit
.\tools\run-milestone-checks.ps1 -Milestone B32 -Profile Focused `
  -FocusedSmoke tests\integration\_welcome_flow_smoke.gd -NoCache -OutputMode Detailed
```

Risultato del 27 agosto 2026: `PASS`, marker
`B32_WELCOME_CTA_SETTINGS_SMOKE_OK` e regressione B18O
`B18O_WELCOME_FLOW_SMOKE_OK`. Lo smoke verifica il riuso della texture CTA,
target touch, tooltip, focus invisibile/pressed, safe area e assenza di sovrapposizioni a
16:9, 20:9 e 4:3, oltre a welcome → impostazioni → welcome in `BOOT`.

Il checkpoint pertinente seguente è verde:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone B32 -Profile Relevant `
  -FocusedSmoke tests\integration\_welcome_flow_smoke.gd `
  -ChangedPath scripts\ui\welcome_screen.gd,scenes\ui\welcome_screen.tscn,tests\integration\_welcome_flow_smoke.gd `
  -NoCache -OutputMode Detailed
```

Risultato: `PASS` per smoke B32/B18O, HUD B09/B18Q, carosello B18T,
raffinamento B18W e overlay upgrade B11.

La suite `Full -NoCache -KeepGoing` ha completato 42 smoke consecutivi senza
marker d'errore, poi il runner ha superato il timeout dell'host prima del
riepilogo. Una successiva esecuzione dei test rimanenti si è fermata su un
difetto già presente B27: `_upgrade_icon_refresh_smoke.gd` richiede un target
icona `76×76` che non è mantenuto dal checkout. La suite completa non è quindi
dichiarata verde e il difetto non è attribuito alla UI B32.

## Evidenza piattaforma

- toolchain e import editor: verdi;
- export e runtime smoke Windows: verdi, con `SMOKE_OK` e contratti fino a
  `B18V_CONTRACT_OK`;
- APK corrente: `98631269` byte, SHA-256
  `40630F4F88621F6F49BC041B7C334C08427E7A513612A9C5A54A7C73D6F0D0FA`;
  ispezione statica verde per package `com.ilgioco.pidgeonsurvivor`, label
  `Pidgeon Survivor`, min SDK `31`, target SDK `36`, ABI `arm64-v8a`, firma v2
  e launcher Godot.

L'exporter Android ha lasciato aperto il solo processo Godot verificato del
runner dopo avere scritto l'APK stabile; è stato terminato prima dell'ispezione
finale. Questo non equivale a un runtime Android.

## Pixel 9 fisico

Il 27 agosto 2026 l'APK sopra indicato è stato installato sul Pixel 9 collegato
(`49140DLAQ0010Y`). Dopo cold launch landscape su `GodotAppLauncher`:

- un tap diretto sull'ingranaggio in alto a destra ha aperto Impostazioni;
- pannello, slider e `INDIETRO` sono rimasti leggibili e dentro la composizione;
- Back Android è tornato alla welcome con logo, CTA e ingranaggio visibili e
  senza sovrapposizioni;
- `logcat` non ha riportato `FATAL EXCEPTION`, `SCRIPT ERROR`, `SMOKE_FAIL`,
  `CONTRACT_FAIL` o `AndroidRuntime`.

Questo chiude il percorso touch/Back fisico Android di B32, ma non sostituisce
il controllo percettivo e tastiera/controller Windows né la suite completa.

### Revisione CTA flottante

Su richiesta del proprietario è stato rimosso il pannello esterno del CTA: il
27 agosto 2026 focused e Relevant B32 sono di nuovo `PASS`, includendo
l'asserzione `StyleBoxEmpty` sul contenitore della placca. L'APK aggiornato
(`98631413` byte, SHA-256
`7FB7BCB0016AFE440E2FC5C99FCC8C101933CCBA1788A2091EB48CFFBA196A01`) è stato
reinstallato sullo stesso Pixel 9: il CTA è osservato flottante sul fondale,
senza riquadro nero esterno; il normale outline ciano di focus resta leggibile.
Tap sull'ingranaggio e Back Android sono stati ripetuti senza errori in log.

### Focus senza outline

Su richiesta del proprietario sono stati resi vuoti gli stylebox `focus` di CTA,
ingranaggio e `INDIETRO`: la navigazione tastiera/controller conserva il focus
logico, ma non disegna più né l'outline ciano né un'alternativa colorata.

Focused e Relevant B32 sono verdi dopo questa modifica. L'APK aggiornato è stato
generato e ispezionato staticamente. Il 27 agosto 2026 il proprietario ha
confermato manualmente che la revisione senza outline funziona sul Pixel 9
sbloccato; non è stato eseguito un ulteriore capture su sua richiesta.

## Gate ancora aperti

- controllo reale Windows con tastiera/controller, resize e percezione della
  placca flottante/ingranaggio;
- completamento della suite `Full` dopo il difetto B27 e il timeout del runner.
