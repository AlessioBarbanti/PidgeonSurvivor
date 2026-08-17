# Verifica B14 — Game Director e scheduler Boss

Data: 17 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione, suite, export e smoke Windows e verifica statica APK completati; runtime Android fisico non eseguito perché nessun device era collegato

## Risultato

B14 aggiunge un `GameDirector` scene-local e un `GameDirectorProfile` dati. Il
profilo predefinito assegna a `EnemySpawner` il profilo di spawn ordinario e
schedula un solo evento Boss a `240` secondi di clock logico della run (`04:00`).
La soglia non rappresenta millisecondi reali né pixel: avanza esclusivamente
quando `RunController` è in `RUNNING`, quindi pausa, level-up, intro Boss e stati
terminali non la consumano.

Le soglie dati vengono filtrate come valori positivi e finiti, ordinate e rese
uniche. Un salto del clock accoda tutte le soglie attraversate, ma il Director
espone al massimo un evento Boss richiesto o un Boss registrato come vivo. Il
Boss successivo resta in coda fino all'uscita del precedente. Al restart vengono
azzerati soglie consumate, coda, richiesta in volo e lock; un Boss registrato
dalla run precedente viene eliminato.

Il confine per B15 è esplicito: `boss_event_requested` comunica indice e soglia,
`register_active_boss()` registra l'istanza creata dal sistema Boss e
`tree_exiting` completa automaticamente l'evento. B14 non implementa intro, UI,
pattern o ricompensa del Boss.

La scena composta espone `B14_CONTRACT_OK` e `B14_READY`.

## Test automatici

Comando dedicato:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_game_director_smoke.gd
```

Lo smoke copre:

- filtro, ordinamento e deduplicazione delle soglie dati;
- nessun consumo in `BOOT` o pausa e attivazione esatta alla soglia;
- salto attraverso più soglie senza perdita di eventi;
- un solo evento richiesto finché il Boss precedente è in volo o vivo;
- conclusione del Boss in pausa con rilascio del successivo solo al ritorno in
  `RUNNING`;
- completamento automatico all'uscita del Boss;
- restart con Boss vivo e seconda run senza stato o segnali duplicati;
- composizione reale con soglia unica a 240 secondi e profilo di spawn assegnato
  dal Director.

Esito dedicato:

```text
B14_GAME_DIRECTOR_SMOKE_OK
```

È stata rieseguita l'intera suite B03–B14: quindici smoke test verdi, tutti con
codice `0`, marker `*_SMOKE_OK` e nessun `SCRIPT ERROR`, `FATAL EXCEPTION` o
`SMOKE_FAIL`. Anche `tools/verify-toolchain.ps1 -RunProjectSmoke` termina con
codice `0`.

## Export Windows

L'export debug Windows è stato rigenerato. Lo smoke del binario esportato
termina con codice `0`, stampa `B14_CONTRACT_OK` e non contiene errori runtime.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.console.exe` | 101.376 | `6948E3214518231D0E009A43D013014A17D214E1EB5807E5AC309617860E07EA` |
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `FriendshipSurvival.pck` | 452.480 | `034DF4377A27B1BE476066D4E7121B5ADBEA405178892574944F9AAB08EC642F` |

## Export Android

L'APK è stato scritto alle 10:30:52 ed è rimasto stabile a 84.315.387 byte. Il
processo CLI Godot è rimasto aperto senza output anche dopo il completamento
dell'artefatto; prima di terminarne il PID specifico sono stati verificati:

- package `com.ilgioco.friendshipsurvival`, versione `0.1.0`/code 1;
- `minSdk=31`, `targetSdk=36`, `compileSdk=36`;
- sola ABI `arm64-v8a` nell'ispezione ZIP;
- firma APK Signature Scheme v2 valida;
- SHA-256
  `7114CE13E80744E3A718A89FBC63CC10EC693CA49F4CD3C3EBEE411C8B532234`.

La procedura riutilizzabile per riconoscere e recuperare questo caso è stata
aggiunta a [`setup.md`](./setup.md), nella sezione “APK aggiornato ma processo di
export ancora aperto”.

## Gate ancora aperti

- nessun dispositivo è comparso in `adb devices -l`, quindi installazione,
  avvio e osservazione del runtime B14 su Android fisico non sono stati eseguiti;
- i profili esatti Android 12/API 31 e Android 16/API 36 restano da validare;
- B15 deve consumare l'evento schedulato e verificare insieme Boss e nemici base,
  intro sicura, morte e ricompensa;
- la soglia `04:00` resta una baseline di vertical slice da confermare nel
  playtest della run completa.
