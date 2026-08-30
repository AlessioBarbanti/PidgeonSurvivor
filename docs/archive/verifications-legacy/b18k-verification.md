# B18K — Pulsante abilità con cooldown circolare

Data verifica: 24 agosto 2026
Godot: `4.7.1.stable.official.a13da4feb`
Target obbligatori: Windows x64 e Android ARM64

Stato: `COMPLETATO`; gate chiusi nel commit dedicato `81b47f6`.

## Contratto implementato

- `TouchAbilityButton` usa direttamente l'icona della definizione equipaggiata
  come superficie di attivazione `64×64` unità logiche.
- Il cooldown disegna sopra l'icona una maschera radiale proporzionale al tempo
  residuo e i secondi interi arrotondati per eccesso.
- A cooldown concluso maschera e numero spariscono; un anello luminoso comunica
  lo stato pronto e il normale impulso B18B resta attivo.
- Nome, label di stato, card `246×94` e sfondo rettangolare del `Button` sono
  rimossi. Il contenitore coincide con il target `64×64` e non disegna nulla:
  nell'arena resta visibile soltanto l'icona.
- Il pulsante osserva soltanto `AbilityController`: non possiede un clock e non
  applica effetti. Pausa e stati non `RUNNING` congelano il valore autorevole;
  il restart elimina ogni residuo.
- L'icona resta nella safe area e separata dal joystick nei profili 16:9, 20:9
  con cutout e 4:3.

## Verifica automatica

Comandi principali:

```powershell
godot_console --headless --path . --resolution 1280x720 --script tests/integration/_ability_button_cooldown_smoke.gd
godot_console --headless --path . --resolution 1280x720 --script tests/integration/_hud_smoke.gd
godot_console --headless --path . --resolution 1280x720 --script tests/integration/_active_ability_smoke.gd
godot_console --headless --path . --resolution 1280x720 --script tests/integration/_visual_identity_smoke.gd
.\tools\verify-toolchain.ps1 -RunProjectSmoke
```

Risultati:

- smoke dedicato: `B18K_ABILITY_BUTTON_COOLDOWN_SMOKE_OK`;
- contratto scena: `B18K_CONTRACT_OK`;
- regressione completa: `26/26`, senza `SCRIPT ERROR` o `FATAL EXCEPTION`;
- project smoke e toolchain: superati;
- pausa, ripresa, fine cooldown e restart coperti dallo smoke dedicato;
- safe area e target touch coperti a 16:9, 20:9 con cutout e 4:3 dallo smoke
  HUD.

## Windows x64

L'export debug è riuscito. L'eseguibile è stato avviato con log esplicito e ha
emesso `B18K_CONTRACT_OK` senza errori runtime. Una sessione non headless a
`1280×720` ha catturato il pulsante a metà cooldown; la cattura locale ignorata
da Git è `exports/screenshots/b18k_cooldown.png` e conferma icona unica, maschera
radiale e numero centrale leggibile, senza nome, card o rettangolo esterno.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `exports/windows/FriendshipSurvival.exe` | `103033344` | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `exports/windows/FriendshipSurvival.pck` | `980740` | `95803F5FD678A3F3DB8EB50D2FD344EF38EB13785ECE947A22B167279BBA64FD` |

## Android ARM64

L'export debug APK è riuscito. I controlli statici confermano:

- package `com.ilgioco.friendshipsurvival`, versione `0.1.0`;
- `minSdk 31`, `targetSdk 36`, `compileSdk 36`;
- sola ABI `arm64-v8a`;
- firma APK Signature Scheme v2 valida.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `exports/android/friendship-survival-debug.apk` | `84819674` | `67D3F3ADC1FC8DFA955C89C5507AABA29C8EEEB315DEFF6B9D890CE03D95CD7D` |

Il 24 agosto il nuovo APK B18L è stato installato e avviato sul Pixel 9 Android
17/API 37. Il pulsante B18K ha accettato un tap ADB, mostrato il cooldown radiale
con `7` secondi residui ed è rimasto leggibile nel viewport logico `1616×720`;
Back e Home hanno conservato la pausa esplicita e i log sono rimasti puliti.
Nella sessione finale lo stesso APK è stato provato con due dita fisiche:
joystick posseduto dal primo dito, attivazioni ripetute col secondo, cooldown
radiale, secondi residui, stato pronto, pausa e restart sono stati approvati. Il
processo è rimasto attivo e i log non contengono errori o marker di fallimento.
