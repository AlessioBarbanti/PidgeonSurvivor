# Verifica B17 — Contenuti definitivi degli amici

Data: 17 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione, suite completa, project smoke ed export Windows/Android
completati; runtime fisico non ripetuto perché nessun device ADB era collegato

## Risultato

B17 aggiunge otto `FriendDefinition` versionabili e un `FriendRegistry`
scene-local. Ogni profilo contiene identità, ruolo, passiva, titolo e testo
dell'attiva, ID abilità destinato a B17A, controparte `Evil`, ritratto hero,
ritratto Boss, fonte dell'asset e record di approvazione.

Magno è il profilo del Player corrente e il suo ID attiva coincide con
`magno_earthquake_shockwave`. Il primo Boss usa il profilo `Bea` e risolve nome
e ritratto pubblici come `Evil Bea`; le altre sette controparti sono già dati,
ma B17 non aggiunge i loro incontri o pattern.

Testi e asset si sostituiscono modificando `.tres`, senza GDScript. I getter
pubblici impediscono a copy o asset non approvati di raggiungere la UI e
ritornano fallback neutri. Un'approvazione priva di approvatore, data ISO o
riferimento invalida il profilo.

## Asset placeholder

I sedici ritagli hero/Evil provengono dal foglio top-down 32×32 di Eldiran,
licenza CC0 1.0. Il sorgente usa magenta come color key; il derivato incluso
converte soltanto quel colore in alpha trasparente. Sorgente, licenza, modifica
e hash sono registrati in `content-approvals.md` e nel file `LICENSE.md` accanto
all'asset.

I 32×32 sono pixel del file sorgente usati per il ritaglio dell'`AtlasTexture`;
non sono unità del mondo né pixel fisici del display. L'aspetto gameplay resta
governato dal viewport logico e da `ArenaLayout`.

## Test automatico dedicato

Comando:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_friend_content_smoke.gd
```

Esito iniziale:

```text
B17_CONTRACT_OK
B17_FRIEND_CONTENT_SMOKE_OK
```

Lo smoke verifica catalogo di otto ID, record di approvazione, convenzione
`Evil <Nome>`, ID abilità unici, ritagli 32×32, fonte CC0, hash del derivato,
fallback per contenuti pending, sostituzione di asset senza codice, rifiuto di
ID duplicati e composizione Player Magno/Boss Evil Bea.

## Regressioni e toolchain

Sono stati eseguiti tutti i 18 smoke B03–B17: ogni processo termina con codice
`0`, espone il proprio marker `*_SMOKE_OK` e non contiene `SCRIPT ERROR`,
`FATAL EXCEPTION` o `SMOKE_FAIL`.

```text
TOTAL=18 FAILURES=0
```

Anche `tools/verify-toolchain.ps1 -RunProjectSmoke` termina con codice `0` e
conferma Godot 4.7.1, JDK 17, SDK 31/36, Build Tools 36.1.0, NDK, template,
import e project smoke.

## Export Windows

L'export debug Windows termina con codice `0`. Il binario esportato viene
avviato headless con `--smoke-test` e stampa `SMOKE_OK`, `B17_CONTRACT_OK` e
`B17_READY` senza errori runtime. Il log di packaging include il texture atlas
importato e tutti gli otto Resource in `data/friends/`.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.console.exe` | 101.376 | `6948E3214518231D0E009A43D013014A17D214E1EB5807E5AC309617860E07EA` |
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `FriendshipSurvival.pck` | 599.032 | `A177033ECE1C0003B0F44ECD4E7CDE20FF241308C1D61B4974D83068924DBEC3` |

## Export Android

L'export debug Android termina con codice `0` e produce:

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `friendship-survival-debug.apk` | 84.450.927 | `7F4CBC4AD47759AD115C777EACF99D233361E4844516A7E827C42575DDE4D646` |

`aapt2` conferma package `com.ilgioco.friendshipsurvival`, versione
`0.1.0`/code 1, `minSdk=31`, `targetSdk=36`, `compileSdk=36` e sola ABI
`arm64-v8a`. `apksigner` conferma APK Signature Scheme v2 valida.

`adb devices -l` non ha rilevato device collegati, quindi installazione e avvio
fisico non sono stati ripetuti in questa sessione. B17 cambia dati e asset P1,
non input o gameplay P0; il gate fisico completo resta pianificato in B19.

## Ambito rimandato

- B17A implementa le altre sette `AbilityDefinition` e i relativi effetti;
- B18 sostituisce o rifinisce art, VFX e audio;
- le citazioni personali Boss e le voci restano assenti finché non vengono
  fornite, anche se tutto il copy attuale è approvato.
