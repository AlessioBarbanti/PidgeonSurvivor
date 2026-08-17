# Verifica B15 — Primo Boss completo

Data: 17 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione, smoke dedicato, regressioni, export Windows/Android e
flusso runtime diagnostico su Pixel 9 completati

## Risultato

B15 aggiunge un `BossDefinition` dati, `BossEncounter`, il primo `FirstBoss`, i
proiettili ostili e una `BossUI` nella safe area. L'evento
`GameDirector.boss_event_requested` porta la run in `BOSS_INTRO`, crea il Boss
nel punto valido più lontano dal Player, lo registra nel `GameDirector` e nel
`TargetingSystem` e mostra nome, citazione e HP prima di riprendere il gameplay
con `AFFRONTA`.

Il contenuto personale resta protetto dal gate `quote_approved`. Il Resource
contiene una stringa provvisoria non approvata, ma la UI mostra soltanto
`Il Boss entra nell'arena.` finché il flag resta falso. Testo e pannello sono
contenuti nella safe area; sul Pixel 9 il cutout fisico non li interseca.

Il Boss riusa `HealthComponent`, `Hurtbox`, `ContactDamage` e il targeting dei
nemici base. Le ondate ordinarie non vengono sospese durante lo scontro. La morte
è atomica, rimuove i proiettili ostili ancora attivi, rilascia il lock del
Director e assegna una sola ricompensa da `50 XP`.

## Pattern e parametri

Il profilo `data/bosses/first_boss.tres` usa:

- `2400 HP`, velocità `85`, danno da contatto `25`;
- raffica radiale: telegraph `0,75 s`, `12` proiettili, danno `14`, velocità
  `270`, lifetime `4 s`, raggio proiettile `9`;
- esplosione mirata: telegraph `1 s`, raggio `115`, danno `26`;
- intervallo fra pattern `2,5 s`, alternanza deterministica e primo attacco dopo
  `1,5 s`.

Velocità, distanze e raggi sono unità logiche del mondo Godot, non pixel fisici.
Il playfield 16:9 resta centrato dentro la safe area, quindi DPI e risoluzione
fisica non cambiano il raggio `115` o la velocità `270`.

Entrambi i telegraph e i proiettili avanzano soltanto in `RUNNING`. Intro, pausa,
level-up, vittoria e sconfitta non consumano durata, cooldown o lifetime.

## Test automatico

Comando dedicato:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_boss_encounter_smoke.gd
```

Esito:

```text
B15_BOSS_ENCOUNTER_SMOKE_OK
```

Lo smoke copre validazione dati e filtro della citazione, spawn nel playfield,
`BOSS_INTRO`, barra HP, pausa del telegraph, due pattern, Boss e nemico base
insieme, danno condiviso, ricompensa singola, vittoria e restart pulito.

## Runtime Pixel 9

Per attraversare il flusso senza attendere quattro minuti è stato prodotto un
APK diagnostico temporaneo con soglia `00:01`, Boss `10 HP` e spawn ordinario
ritardato. Sul Pixel 9 (`tokay`, Android 17/API 37, ARM64) sono stati verificati:

- intro completa dentro la safe area e placeholder sicuro visibile;
- tap reale su `AFFRONTA`;
- Boss bersagliato e sconfitto, ricompensa `+50 XP` e schermata `VITTORIA`;
- tap reale su `NUOVA RUN` e seconda intro a `00:01`, senza stato visibile della
  run precedente;
- zero `SCRIPT ERROR`, `FATAL EXCEPTION` o errori Godot nel log del processo.

I tre override diagnostici sono stati ripristinati subito dopo la prova. L'APK
finale con soglia `04:00`, `2400 HP` e spawn iniziale `0,75 s` è stato reinstallato
e avviato sullo stesso device; stampa `B15_CONTRACT_OK` senza errori runtime. Le
schermate diagnostiche restano in `exports/android/b16-runtime/`, directory
ignorata e non inclusa negli artefatti.

## Gate ancora aperti

- playtest reale del combattimento con valori finali e ondate ordinarie dense;
- verifica dei due telegraph su Android 12/API 31 e Android 16/API 36 esatti;
- prova manuale con controller fisico.
