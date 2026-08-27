# B31 — Padding esterno pausa e abilità

Data: 27 agosto 2026  
Stato: `IN VERIFICA`.

## Implementazione

- `MovementSlice` espone `hud_control_edge_padding` configurabile a `20` unità
  logiche dalla safe area.
- Il pulsante pausa conserva il target `48×48` e si stacca di `20` unità dai
  bordi superiore e destro.
- Il pulsante abilità somma lo stesso inset ai margini obbligatori di gesture:
  `36` unità a destra e `52` in basso con i valori correnti, senza modificare
  la zona dinamica di acquisizione del joystick.
- Il target base abilità raddoppia a `128×128`; le taglie B18P
  `100/125/150%` restano persistenti e corrispondono a `128/160/192`.
  Icona e testo cooldown scalano insieme al target.

## Evidenza automatica

```powershell
godot_console --headless --editor --path . --quit
.\tools\run-milestone-checks.ps1 -Milestone B31 -Profile Focused -NoCache -OutputMode Detailed
.\tools\run-milestone-checks.ps1 -Milestone B31 -Profile Relevant -NoCache -OutputMode Detailed
```

Risultati del 27 agosto 2026:

- Focused: `PASS`, marker
  `B31_PAUSE_ABILITY_OUTER_PADDING_SMOKE_OK` e
  `B18P_TOUCH_CONTROL_SETTINGS_SMOKE_OK`.
- Relevant: `PASS`, B31 più dieci regressioni (HUD, B18Q, cooldown B18K,
  joystick/lifecycle, carousel/welcome, overlay e run completa). Log:
  `%LOCALAPPDATA%\Temp\il-gioco-verification\20260827-015424-B31`.

Lo smoke attraversa `16:9`, `20:9` e `4:3`, controlla i margini esatti,
conserva la dimensione configurabile e verifica il secondo dito sull'abilità
mentre il primo mantiene il joystick.

## Evidenza piattaforma

Da aggiornare dopo il profilo Release e l'installazione dell'APK corrente sul
Pixel 9. L'installazione non sostituisce la prova touch fisica o il controllo
percettivo della nuova gerarchia visiva.

