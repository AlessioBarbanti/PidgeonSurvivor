# B26/B27 — Forchettone da Braciere e refresh icone upgrade

Ultimo aggiornamento: 26 agosto 2026  
Stato: **IN VERIFICA**

## Contratti implementati

- B26 aggiunge `meat_fork_damage`, nome pubblico **Forchettone da Braciere**,
  ripetibile `×1,15` sul solo `weapon_damage_multiplier`. Insieme a
  **Dai che si fredda!**, Ritmo Serrato e Campo Ampio sostituisce le Resource
  fallback duplicate: non esiste più una categoria fallback. Il valore si compone
  con altri modificatori, rispetta il cap del registry, non modifica `WeaponProfile`
  né la cadenza e si azzera a restart/cambio personaggio.
- B27 sostituisce le icone runtime di Dai che si fredda!, Ritmo Serrato, Campo Ampio,
  L'Ansia, Birra, Ritardo Cronico, Forchettone da Braciere, Gossip, Non Ho Tempo
  Per Questo e Grigliata estiva.
  I master già forniti sono preservati in `hd/`; i derivati RGBA `128×128` sono
  prodotti con `tools/process-upgrade-icon.ps1` e sono gli unici referenziati
  dalle dieci carte.
- Il riferimento storico a un file prompt separato è stato rimosso: non esiste
  e non viene ricreato. Origine, mapping, trasformazione e hash sono nel
  [`manifest upgrade`](../assets/art/icons/upgrades/ASSET-MANIFEST.md).

## Evidenza automatica

| Area | Risultato | Evidenza |
|---|---|---|
| Cache/import Godot | Verde | `godot_console --headless --editor --path . --quit` reimporta i dieci PNG senza errori |
| Smoke B26 | Verde | `_damage_upgrade_smoke.gd` → `B26_DAMAGE_UPGRADE_SMOKE_OK`: stacking, sesto rank, Gossip, Birra, snapshot proiettile, Boss e reset |
| Smoke B27 | Verde | `_upgrade_icon_refresh_smoke.gd` → `B27_UPGRADE_ICON_REFRESH_SMOKE_OK`: dieci texture `128×128`, adattamento e centering a 16:9, 20:9 e 4:3 |
| Focused | Verde | B26 e B27 `1/1` |
| Relevant | Verde | B26 e B27 `46/46` regressioni |
| Full | Verde | B26 e B27 `46/46` regressioni + toolchain `1/1` |
| Marker negativi | Assenti | Nessun `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o `CONTRACT_FAIL` nei checkpoint |

Log principali:

- `%LOCALAPPDATA%\Temp\il-gioco-verification\20260826-094857-B26`;
- `%LOCALAPPDATA%\Temp\il-gioco-verification\20260826-094900-B27`;
- `%LOCALAPPDATA%\Temp\il-gioco-verification\20260826-095234-B26`;
- `%LOCALAPPDATA%\Temp\il-gioco-verification\20260826-095243-B27`;
- `%LOCALAPPDATA%\Temp\il-gioco-verification\20260826-095318-B26`;
- `%LOCALAPPDATA%\Temp\il-gioco-verification\20260826-095443-B27`.

## Windows

Release B26 e B27 verde: export e runtime Windows `2/2`. L'eseguibile
`exports/windows/PidgeonSurvivor.exe` ha SHA-256
`BFA5766944AD646D797F3FEB0172A0287A65CFD9FF08B1B1E449955985BC85FA`.

## Android statico e runtime installato

- APK debug corrente: SHA-256
  `88AE9C610C8F84E47EEBA6BF32ED48A3FBC2749EBA336F7C32BD9AA9D9D76ABD`,
  `96326457` byte, package `com.ilgioco.pidgeonsurvivor`, `minSdk=31`,
  `targetSdk=36`, sola ABI `arm64-v8a`, firma v2 valida e launcher
  `com.godot.game.GodotAppLauncher`.
- L'ispezione dell'APK rileva `UPGRADE_HD_ENTRY_COUNT=0` e
  `UPGRADE_RUNTIME_ENTRY_COUNT=7`: i master non entrano nel pacchetto.
- Il 26 agosto l'APK è stato installato sul Pixel 9 `49140DLAQ0010Y`; il
  launcher è diventato la finestra in focus, Godot ha completato il bootstrap
  Android e il log runtime non contiene marker negativi.

## Gate ancora aperti

- La sola installazione/boot Android non prova la selezione reale della carta
  B26 in una run né il suo comportamento percettivo in combattimento.
- Il controllo umano delle dieci carte, della loro uniformità e leggibilità a
  16:9, 20:9 e 4:3 resta aperto su Windows e Pixel 9. Lo smoke B27 copre
  geometria e risorse, non sostituisce questa valutazione.

## Aggiornamento 26 agosto 2026 — carte ripetibili e APK corrente

- Le Resource `fallback_power`, `fallback_haste` e `fallback_reach` sono state
  rimosse. `Dai che si fredda!`, Ritmo Serrato, Campo Ampio e Forchettone da
  Braciere sono ora carte normali ripetibili; nessuna Resource, API o
  riferimento runtime upgrade usa più SVG o fallback.
- I focused smoke B26 e B27 sono verdi, insieme alle regressioni dirette B11,
  B13, B18J, B18T e B18W aggiornate per la nuova pesca e l'icona attiva `152×152`.
- APK corrente: SHA-256
  `C99608039DCAE2E44FE8B06EDC4BCEEDF11E3FAEF3C7B9D93A5E6BE64CF6AFFD`,
  `96379356` byte. `inspect-android-artifact.ps1` conferma package,
  `minSdk=31`, `targetSdk=36`, ABI `arm64-v8a`, firma v2 e assenza dei master HD.
- L'APK è stato installato il 26 agosto sul Pixel 9 `49140DLAQ0010Y`;
  `com.godot.game.GodotAppLauncher` è l'attività ripresa e il log recente non
  contiene `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o `CONTRACT_FAIL`.

## Aggiornamento 26 agosto 2026 — scala delle icone nelle offerte

Ogni carta dell'overlay level-up riserva ora un'area `192×192` per l'icona
runtime, contro i precedenti `76×76`: la superficie utile è oltre sei volte
quella originaria. Il
layout conserva titolo, descrizione, rango e target touch delle tre carte a
`16:9`, `20:9` e `4:3`; `_upgrade_overlay_smoke.gd` impone sia la dimensione
dell'icona sia l'altezza del relativo contenitore. Resta aperto il controllo
percettivo umano delle offerte sul Pixel 9 e su Windows.

`B11_UPGRADE_OVERLAY_SMOKE_OK` è verde con il nuovo vincolo a tre geometrie.
L'APK `pidgeon-survivor-debug.apk` aggiornato il 26 agosto 2026 ha SHA-256
`C9C8822CCA4AFC25993C62B2CD81E39BA45935AE9973BBCAD5CE9BE8AD653210`,
misura `96.379.920` byte, supera il controllo statico Android ed è installato
sul Pixel 9. Il launcher ha consegnato l'intent all'istanza Godot già in primo
piano; il controllo visivo umano delle nuove carte resta aperto.

Aggiornamento successivo del 26 agosto 2026: le icone nelle offerte sono ora
`192×192`; `B11_UPGRADE_OVERLAY_SMOKE_OK` conserva il layout a `16:9`, `20:9`
e `4:3`. L'APK corrente misura `96.379.948` byte, SHA-256
`CA162891F9AA362DB83EC51B3F50CE281DE7CE3C717F3F0E44251358D0F128F3`, è
staticamente valido e ha completato cold launch sul Pixel 9 senza marker runtime
negativi.
