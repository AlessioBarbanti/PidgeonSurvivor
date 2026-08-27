# Verifica B13 — Upgrade signature del PRD

Data: 17 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione, suite, export Windows e verifica statica APK completati; il rerun fisico del build rinominato su Pixel 9, i playtest manuali e i profili Android 12/16 esatti restano aperti

## Risultato

B13 aggiunge al catalogo i cinque upgrade signature del PRD come `Resource`
data-driven a rank singolo:

- **L'Ansia** compone `velocità ×1,35` e `vita massima ×0,80`, conserva la
  percentuale di HP e abilita una vignetta shader puramente visiva;
- **Gossip** rende i nuovi proiettili concatenabili: il colpo salta due volte
  entro 260 unità, conserva gli ID dei bersagli già colpiti e applica il
  falloff `0,65` a ogni passaggio;
- **Ritardo Cronico** schedula ogni 12 secondi di `RUNNING` uno slow locale
  `×0,50` per 3 secondi; pausa e modali non consumano i timer e un nemico
  registrato durante il pulse riceve lo stesso status identificato;
- **Birra** compone `frequenza ×1,25` e fotografa sui nuovi
  proiettili una dispersione casuale di `±24°`, derivata dal seed della run;
- **Non Ho Tempo Per Questo** reagisce soltanto al danno Player effettivamente
  accettato, applica knockback entro 220 unità e crea un anello VFX scene-local.

`UpgradeEffectRegistry` valida schema, tipi e dipendenze di ciascun effetto,
ricalcola statistiche e profili runtime senza mutare i `.tres` e conserva i
timer già avviati quando viene scelta un'altra carta. Restart e nuova run
rimuovono rank, status nemici, shockwave, vignetta, timer e modificatori dei
proiettili.

La scena espone `B13_CONTRACT_OK`, `B13_READY` e log `B13_EFFECT` con i
moltiplicatori effettivi e le signature attive.

## Test automatici

Comando dedicato:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_signature_upgrades_smoke.gd
```

Lo smoke copre:

- rifiuto di parametri mancanti, tipi errati, dispersione nulla e signature
  ripetibili;
- acquisizione e composizione simultanea delle cinque carte;
- rapporto HP preservato, vignetta e statistiche composte;
- tre bersagli concatenati senza doppia hit, danno progressivamente ridotto e
  deviazione angolare con rischio di mancare il bersaglio;
- slow alla soglia, stop in pausa, rimozione dopo tre secondi e ingresso di un
  nuovo nemico durante il pulse;
- shockwave e slow sullo stesso nemico, filtro per raggio e mancata
  riattivazione durante gli i-frame;
- sconfitta e seconda run senza rank, bersagli, proiettili, status, timer o VFX
  residui.

Esito dedicato:

```text
B13_SIGNATURE_UPGRADES_SMOKE_OK
```

### Aggiornamento Birra — 27 agosto 2026

La sinusoide è stata sostituita da una dispersione iniziale di `±24°`: la
cadenza resta `×1,25`, ma ogni colpo può mancare il bersaglio mirato. Lo stream
RNG dell'arma è locale e derivato dal seed della run, perciò non altera pesca o
spawn e la sequenza resta riproducibile. I rerun freschi focalizzati di B13 e
B26 passano rispettivamente con `B13_SIGNATURE_UPGRADES_SMOKE_OK` e
`B26_DAMAGE_UPGRADE_SMOKE_OK`.

Il profilo Relevant B13 ha invece interrotto sulle sei asserzioni B18W di
selezione personaggio già incompatibili con il worktree UI B34 (`icona abilità`,
`blocco nome/ruolo`, `frecce`); nessun fallimento riguarda Birra o B13.

L'APK `pidgeon-survivor-debug.apk` SHA-256
`22809DD2757108629D71A16EA634042BA8B832C13E88B1DD8555D3894279E075` è stato
validato staticamente (`minSdk 31`, `targetSdk 36`, `arm64-v8a`, firma v2) e
installato con successo sul Pixel 9 il 27 agosto 2026. Avvio, selezione della
carta Birra, percezione della dispersione e log runtime restano da eseguire.

È stata rieseguita l'intera suite B03–B13: quattordici smoke test verdi, tutti
con codice `0`, marker `*_SMOKE_OK` e nessun `SCRIPT ERROR` o
`CONTRACT_FAIL`. Anche `tools/verify-toolchain.ps1 -RunProjectSmoke` termina
con codice `0`.

## Export Windows e Android

Gli export debug sono stati rigenerati nelle directory ignorate. Lo smoke
dell'eseguibile Windows esportato termina con codice `0` e stampa
`B13_CONTRACT_OK`.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.console.exe` | 101.376 | `6948E3214518231D0E009A43D013014A17D214E1EB5807E5AC309617860E07EA` |
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `FriendshipSurvival.pck` | 436.056 | `FCCA7372D5D955D2919F2A95726A5BA60B58152C04AF9A46C9D338BCFF5B2C2E` |
| `friendship-survival-debug.apk` | 84.298.890 | `EAA4C3754E46575707079DE16E8A8C91F87B5D40DA45C45A8C5C8EA683377E72` |

`aapt2`, `apksigner` e l'ispezione ZIP confermano package
`com.ilgioco.friendshipsurvival`, versione `0.1.0`/code 1, minSdk 31,
target/compileSdk 36, sola ABI `arm64-v8a` e firma debug APK Signature Scheme
v2 valida.

## Runtime Pixel 9

Il build rinominato è stato verificato staticamente con `aapt2` e `apksigner`.
In questa sessione `adb devices` non ha rilevato il Pixel 9 (`tokay`), quindi
installazione, avvio e prova fisica di Gossip/Birra vanno ripetuti quando il
device torna disponibile. Il precedente avvio B13 resta evidenza della baseline
Android, non del nuovo APK rinominato.

## Gate ancora aperti

- acquisire e valutare manualmente tutte le signature, incluse leggibilità
  della vignetta, catena Gossip, traiettoria Birra e shockwave in un'orda reale;
- ripetere il flusso con controller fisico e multitouch/joystick su Android;
- eseguire i profili esatti Android 12/API 31 e Android 16/API 36;
- ribilanciare falloff/raggio della catena Gossip, dispersione Birra,
  intensità della vignetta, raggio/forza della shockwave e
  intervallo dello slow dopo playtest.
