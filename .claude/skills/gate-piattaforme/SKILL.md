---
name: gate-piattaforme
description: Esegui e riporta onestamente i gate Windows e Android di Pidgeon Survivor — export, ispezione statica dell'APK, installazione e prova fisica su Pixel 9, touch e multitouch, lifecycle. Usala quando si parla di export, APK, adb, device, prova su telefono, chiusura di un gate di piattaforma o quando un milestone sta per passare a VERIFICATO.
---

# Gate Windows e Android

Tre risultati **distinti**, mai fusi in uno solo:

| Gate | Come si chiude | Chi può chiuderlo |
|---|---|---|
| Runtime Windows | Export debug + avvio dell'eseguibile, log puliti | Automatizzabile |
| Validazione statica Android | Export APK + `inspect-android-artifact.ps1` verde | Automatizzabile |
| Runtime fisico Android | APK corrente installato su device collegato, percorso modificato esercitato, log letti | **Solo con device reale** |

## Automatico

```powershell
.\tools\run-milestone-checks.ps1 -Milestone B23 -Profile Release
```

`Release` esegue `Full`, refresh editor, export/runtime Windows, export e
ispezione statica Android. Può recuperare il caso Windows in cui l'exporter
Android resta agganciato dopo aver scritto un APK nuovo e stabile: termina solo
il processo avviato dal runner e accetta `RECOVERED` **soltanto** con package,
SDK, ABI, firma e struttura ZIP verdi. Questo non prova nulla sul device.

Ispezione mirata dell'artefatto (deriva i valori attesi da `export_presets.cfg`:
package, SDK, ABI, firma, hash, launcher, stato ADB):

```powershell
.\tools\inspect-android-artifact.ps1
```

Toolchain e project smoke:

```powershell
.\tools\verify-toolchain.ps1 -RunProjectSmoke
```

## Fisico

1. Installa **l'APK appena costruito**, non uno vecchio.
2. Cold launch, poi esercita esattamente il percorso modificato.
3. Leggi i log del device: `SCRIPT ERROR` e `FATAL EXCEPTION` sono fallimenti
   anche se il gioco sembra funzionare.
4. Per modifiche al touch: tieni fisicamente il joystick con un dito mentre attivi
   ripetutamente l'abilità o il controllo con un secondo dito. Il multitouch non è
   automatizzabile su questo device — richiede il proprietario.
5. Per lifecycle: lock/unlock, cambio app, ritorno. La run **non** deve riprendere
   da sola.

## Onestà

- Se il device non è disponibile: implementa, chiudi automatici e statico, e
  dichiara il gate di runtime fisico **APERTO**. Non è un fallimento, è uno stato.
- Non convertire in evidenza tecnica prove non registrate ("l'ho provato e
  andava"). Se il proprietario accetta operativamente una chiusura, scrivilo
  come accettazione del proprietario, distinta dall'evidenza.
- Non sostituire con smoke o screenshot un controllo percettivo, geometrico, con
  controller o su device che è stato richiesto.
- Registra ogni risultato nella nota `docs/b<ID>-verification.md` con data,
  comando e marker esatti.
