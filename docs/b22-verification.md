# B22 — Boss piccione speciale e varianti Evil

Ultimo aggiornamento: 26 agosto 2026  
Stato: **COMPLETATO**

## Contratto implementato

- `data/bosses/first_boss.tres` descrive il piccione speciale B18H come
  `BossDefinition` baseline.
- `BossEncounter.evil_boss_chance` è configurabile e vale `0,25` per default.
  Ogni evento risolve una scelta indipendente e riproducibile da seed della run
  più indice della soglia.
- Una variante Evil deriva dalla baseline e modifica soltanto ID, profilo,
  sprite e palette viola scura/magenta. Salute, velocità, hitbox, contatto,
  ricompensa, cadenza e due pattern restano identici.
- Gli otto sprite sono quelli gameplay B18U già approvati. B22 non assegna
  passive, abilità, citazioni personali o audio del profilo.
- `BossEncounter` conserva un solo Boss richiesto/attivo e usa la definizione
  risolta per intro, UI, ricompensa, vittoria e cleanup.
- La build debug Android dispone di un innesco fisico monouso, confinato a
  `OS.is_debug_build()` + Android e a un flag privato `user://`: forza il seed
  noto `4`, attraversa la soglia tramite il normale clock/Director e, dopo otto
  secondi di scontro reale, infligge il danno conclusivo. Definizione, scena,
  statistiche, pattern, UI, ricompensa e terminale restano quelli di B22; questo
  percorso prova integrazione e lifecycle, non bilanciamento o time-to-kill.

## Evidenza automatica

| Area | Risultato | Evidenza |
|---|---|---|
| Cache classi Godot | Verde | `godot_console --headless --editor --path . --quit` |
| Smoke B22 | Verde | `_evil_boss_variants_smoke.gd` → `B22_EVIL_BOSS_VARIANTS_SMOKE_OK` |
| Runner focalizzato | Verde | focused B22, `_boss_encounter_smoke.gd` e project/toolchain smoke; `IL_GIOCO_VERIFICATION milestone=B22 status=PASS` |
| Regressioni composte | Verde | `B15_BOSS_ENCOUNTER_SMOKE_OK`, `B17_FRIEND_CONTENT_SMOKE_OK`, `B16_COMPLETE_RUN_SMOKE_OK`, `B18N_PAUSE_CHANGE_CHARACTER_SMOKE_OK`, `B03_MOVEMENT_SLICE_SMOKE_OK`, `B18B_VISUAL_IDENTITY_SMOKE_OK` |
| Marker negativi | Assenti | Nessun `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o `CONTRACT_FAIL` nei log del checkpoint Windows |

Lo smoke B22 forza `evil_boss_chance=0` e `1`, verifica fallback, stessa scelta
per stesso seed/indice, copertura di tutti gli otto Evil, distribuzione del
default `25%`, invarianti gameplay, sprite/palette, UI, singola ricompensa e due
run senza stato residuo.

Log runner verde:  
`%LOCALAPPDATA%\Temp\il-gioco-verification\20260825-224203-B22`

## Windows

- Export debug prodotto: `exports/windows/PidgeonSurvivor.exe`.
- Runtime 1280×720 verde con `SMOKE_OK` e contratti B03–B18V/B18W.
- Dimensione: `103115264` byte.
- SHA-256:
  `BFA5766944AD646D797F3FEB0172A0287A65CFD9FF08B1B1E449955985BC85FA`.
- Log export/runtime:
  `%LOCALAPPDATA%\Temp\il-gioco-verification\20260825-224442-B22`.

## Android statico

L'exporter Godot raggiunge `[ DONE ] export` e produce ripetutamente lo stesso
APK, ma su questo host resta vivo dopo la finalizzazione e deve essere chiuso
manualmente. Anche `--quit` esplicito non cambia il comportamento. Il comando
non viene quindi dichiarato verde, pur essendo verde l'artefatto statico.

`tools/inspect-android-artifact.ps1` stampa `ANDROID_STATIC_VALID`:

- APK: `exports/android/pidgeon-survivor-debug.apk`;
- dimensione: `96110150` byte;
- SHA-256:
  `FAC4B627CC8783D25F438F71552382CF478436C4D8B9B796508F209E657C8C84`;
- package: `com.ilgioco.pidgeonsurvivor`;
- `minSdk=31`, `targetSdk=36`, ABI `arm64-v8a`;
- firma v2 valida;
- launcher `com.godot.game.GodotAppLauncher`;
- nessun PID export attivo dopo aver verificato due volte dimensione, timestamp
  e hash stabili e chiuso soltanto il processo avviato dal checkpoint.

## Pixel 9 fisico

- Device: Google Pixel 9 `tokay`, seriale `49140DLAQ0010Y`, Android API 37,
  `1080×2424`, densità fisica `420`.
- Installazione dell'APK con hash sopra completata alle `00:09:55`; package
  `com.ilgioco.pidgeonsurvivor`, `versionCode=1`, `versionName=0.1.0`, launcher
  `com.godot.game.GodotAppLauncher` in focus e lockscreen disattivata.
- Seed `4`: marker `B22_PHYSICAL_VERIFICATION_ARMED`, intro
  `id=evil_magno title=Evil Magno evil=true`, barra `2400/2400`, sprite B18U e
  palette viola/magenta leggibili nel layout 20:9 con `FLASH RIDOTTI` attivo.
- Home e rientro mantengono l'intro in pausa; `AFFRONTA` porta allo scontro e i
  frame fisici mostrano sia la raffica radiale sia il telegraph mirato ad alta
  densità. Back conserva la pausa esplicita e `RIPRENDI` la chiude.
- L'auto-defeat debug è arrivato dopo scontro osservabile: marker
  `B22_PHYSICAL_BOSS_AUTODEFEAT damage=2400.0`, schermata `VITTORIA` con
  `Evil Magno sconfitto in 04:08 • +50 XP`; `NUOVA RUN` torna a `00:03` senza
  Boss, UI o flag residui.
- Scansione log runtime pulita: nessun `SCRIPT ERROR`, `FATAL EXCEPTION`,
  `SMOKE_FAIL` o `CONTRACT_FAIL`.

Evidenza framebuffer fisica:
`%LOCALAPPDATA%\Temp\il-gioco-verification\b22-physical-20260826`.

## Chiusura gate

| Ambiente | Stato | Evidenza |
|---|---|---|
| Windows export/runtime | Chiuso | Export, runtime e regressioni verdi; leggibilità ad alta densità coperta anche dal device fisico |
| APK statico | Chiuso | Artefatto ARM64 firmato e stabile; l'hang host dopo `[ DONE ]` è un problema di terminazione dell'exporter distinto da B22 |
| Pixel 9 fisico | Chiuso | APK corrente installato; intro, pattern, flash ridotti, Home/rientro, Back/pausa, vittoria e restart verificati |

B22 è `COMPLETATO`: codice, test, documentazione e gate Windows, Android
statico e Pixel 9 fisico sono chiusi. L'uscita non pulita dell'exporter dopo la
creazione valida dell'APK resta una nota di toolchain host e non viene
reinterpretata come un fallimento del runtime o dell'artefatto B22.
