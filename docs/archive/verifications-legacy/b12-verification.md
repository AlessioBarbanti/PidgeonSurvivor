# Verifica B12 — Upgrade statistici, stacking e cap

Data: 17 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione, suite, export Windows e runtime automatizzato Pixel 9 completati; test manuali touch/controller e profili Android 12/16 esatti ancora aperti

## Risultato

B12 collega le scelte B10–B11 alle statistiche effettive della run:

- `UpgradeEffectRegistry` valida e interpreta gli `effect_id`
  `player_move_speed_multiplier`, `player_pickup_radius_multiplier`,
  `weapon_fire_rate_multiplier` e `weapon_damage_multiplier`;
- ogni ricalcolo parte dai valori base e compone i rank in modo
  moltiplicativo, quindi applica i cap esportati `×2`, `×3`, `×3` e `×5`;
- `swift_steps`, `rapid_fire` e `wide_magnet` applicano rispettivamente
  velocità Player, frequenza dell'arma e raggio pickup; i tre fallback
  riutilizzano lo stesso percorso per danno, frequenza e raggio;
- Player e `WeaponController` conservano moltiplicatori runtime separati dai
  `Resource`: `default_weapon_profile.tres` non viene mai mutato;
- i proiettili creati dopo Potenza ricevono il danno effettivo aggiornato;
- un cambio di frequenza non riscrive il cooldown già iniziato, mentre il
  colpo successivo usa il nuovo intervallo;
- rank ripetibili oltre il cap restano tracciati senza aumentare ancora la
  statistica, così i fallback non bloccano l'overlay;
- restart e seconda run azzerano rank, cache, moltiplicatori e cooldown.
- `UpgradeService` pubblica `upgrade_selected` soltanto dopo che la progressione
  ha confermato la scelta, evitando effetti runtime se il commit fallisce.

Il contratto della scena espone ora `B12_CONTRACT_OK` e `B12_READY` e verifica
che service, catalogo, registry, Player e arma siano collegati con valori base
coerenti all'avvio.

## Test automatici

Comando dedicato:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_upgrade_effects_smoke.gd
```

Lo smoke copre:

- rifiuto di `effect_id` sconosciuti e moltiplicatori assenti o non numerici;
- applicazione reale dei tre upgrade primari fino al rank massimo;
- composizione fra primarie e fallback sullo stesso effetto;
- cap della frequenza e fallback ripetibile oltre il cap;
- cooldown in corso invariato e intervallo aggiornato dal colpo successivo;
- danno effettivo copiato in un nuovo proiettile;
- immutabilità del `WeaponProfile` condiviso;
- sconfitta, restart e seconda run con valori base e rank vuoti.

Esito dedicato:

```text
B12_UPGRADE_EFFECTS_SMOKE_OK
```

È stata rieseguita l'intera suite B03–B12: tredici smoke test verdi, tutti con
codice `0`, marker `*_SMOKE_OK` e nessun `SCRIPT ERROR` o `CONTRACT_FAIL`.
Anche `tools/verify-toolchain.ps1 -RunProjectSmoke` termina con codice `0`.

## Export Windows e Android

Gli export debug sono stati rigenerati nelle directory ignorate. Lo smoke
dell'eseguibile Windows esportato termina con codice `0` e stampa
`B12_CONTRACT_OK` e `B12_WINDOWS_EXPORT_SMOKE_OK`.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.console.exe` | 101.376 | `6948E3214518231D0E009A43D013014A17D214E1EB5807E5AC309617860E07EA` |
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `FriendshipSurvival.pck` | 391.504 | `7A8124E56EAAB3382F4624C48393261192D204B2FB43B764909AB62547BAD4FE` |
| `friendship-survival-debug.apk` | 84.255.798 | `1AA835F677594092BA0D9B614BB315B842A4DFFD6DAF4E365FCD61A58CABD95B` |

`aapt2`, `apksigner` e l'ispezione ZIP confermano package
`com.ilgioco.friendshipsurvival`, versione `0.1.0`/code 1, minSdk 31,
target/compileSdk 36, sola ABI `arm64-v8a` e firma debug APK Signature Scheme
v2 valida.

## Runtime Pixel 9

L'APK B12 è stato installato con `adb install -r` sul Pixel 9 (`tokay`),
Android 17/API 37, ARM64. Il processo usa Compatibility/OpenGL ES 3.2 su
Mali-G715 e ha stampato:

```text
SMOKE_OK version=4.7.1 renderer=gl_compatibility os=Android
B11_CONTRACT_OK
B12_CONTRACT_OK
B12_READY os=Android viewport=(1616, 720) window=(2424, 1080)
B12_EFFECT id=swift_steps rank=1 move=1.1000 pickup=1.0000 fire=1.0000 damage=1.0000
```

Un input touch iniettato tramite ADB sul device fisico ha mosso il Player,
raccolto XP, aperto il level-up, confermato una carta e ripreso la run. Il log
`B12_EFFECT` prova che la scelta `swift_steps` ha raggiunto il registry e
portato la velocità effettiva a `×1,1`. Safe area e playfield coincidono con i
valori già verificati sul Pixel 9; non risultano `SCRIPT ERROR`,
`FATAL EXCEPTION` o crash. Le schermate restano in
`exports/android/b12-runtime/`, directory ignorata.

## Gate ancora aperti

- ripetere a dito la scelta delle carte, il ripristino del joystick e una coda
  multipla; l'input ADB automatizzato non sostituisce ergonomia e multitouch;
- controller USB/Bluetooth reale su Windows e Android;
- profili esatti Android 12/API 31 e Android 16/API 36;
- playtest e ribilanciamento dei quattro cap provvisori.
