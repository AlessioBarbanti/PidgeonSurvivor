# B29 — Musica di sottofondo

Data: 27 agosto 2026  
Stato: `IN VERIFICA`.

## Implementazione

- `GameAudio` mantiene il pool SFX B18 e aggiunge due player scene-local sul
  bus `Music`: quello della run (`-7 dB`) e quello dei menu (`-9 dB`).
- Il loop `Super Wreck Roadway (loop)` parte soltanto in `RUNNING`, si
  ferma e riprende dalla posizione corrente in pausa e modal, e viene azzerato
  a terminale, restart e teardown.
- Lo slider e mute già persistiti in `user://audio_settings.cfg` ora governano
  sia `SFX` sia `Music`; la UI li chiama perciò “Volume audio” e “Disattiva
  audio”.
- Asset, licenza CC0, download ufficiale, hash e credito sono tracciati in
  [`super_wreck_roadway_loop.MANIFEST.md`](../assets/audio/third_party/super_wreck_roadway_loop.MANIFEST.md)
  e [`credits.md`](./credits.md).

## Evidenza automatica

```powershell
.\tools\run-milestone-checks.ps1 -Milestone B29 -Profile Focused -NoCache -OutputMode Detailed
```

Risultato storico del 27 agosto 2026: `PASS`, marker
`B29_BACKGROUND_MUSIC_SMOKE_OK`, sul brano precedente. Lo smoke è stato
aggiornato per il nuovo asset, ma non è stato rieseguito su richiesta dopo la
sostituzione.

Il checkpoint mirato seguente è verde:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone B29 -Profile Custom `
  -FocusedSmoke tests\integration\_b29_background_music_smoke.gd `
  -RegressionSmoke tests\integration\_audiovisual_feedback_smoke.gd `
  -RefreshEditor -RunToolchain -RunProjectSmoke -ExportWindows -ExportAndroid `
  -InspectAndroid -ExportTimeoutSeconds 180 -RuntimeTimeoutSeconds 120 `
  -OutputMode Detailed
```

Risultato storico: `PASS`; `B29_BACKGROUND_MUSIC_SMOKE_OK`,
`B18_AUDIOVISUAL_SMOKE_OK`, toolchain, export/runtime Windows e ispezione
statica Android verdi sul brano precedente. L'export Android ha richiesto il recupero controllato
dopo aver scritto un APK nuovo e stabile (`RECOVERED`, exit `125`); l'ispezione
ha comunque validato il pacchetto.

`Relevant` e `Full` non sono verdi per un difetto preesistente B28, non causato
da B29: `default_enemy_spawn_profile.tres` imposta
`progression_experience_multiplier = 1.7`, mentre
`_b28_horde_density_smoke.gd` richiede `1.5`. Il tentativo `Full -KeepGoing` è
stato inoltre interrotto perché `_upgrade_effects_smoke.gd` è rimasto appeso;
il processo Godot figlio di quella suite è stato terminato senza toccare file.

Il 29 agosto 2026 il guadagno base della musica di run è passato da `-12 dB` a
`-7 dB` su richiesta del proprietario, ed è stato aggiunto il loop dei menu di
BOOT (welcome, selezione personaggio, tutorial) su un player separato:
`Menu Music (loop)` di wipics, CC0, tracciato in
[`menu_music_wipics/ASSET-MANIFEST.md`](../assets/audio/third_party/menu_music_wipics/ASSET-MANIFEST.md).
Il loop dei menu è continuo fra le tre schermate, si spegne all'avvio della run
e non si sovrappone mai al loop di gioco. Copertura:
`tests/integration/_menu_music_smoke.gd` (marker `MENU_MUSIC_SMOKE_OK`),
verde il 29 agosto 2026 insieme a `B29_BACKGROUND_MUSIC_SMOKE_OK`,
`B18_AUDIOVISUAL_SMOKE_OK`, `B54_TUTORIAL_FLOW_SMOKE_OK` e
`B18T_CHARACTER_CAROUSEL_SMOKE_OK`. Export e ispezione Android non sono stati
rieseguiti.

Il 27 agosto 2026 il proprietario ha sostituito la traccia runtime con
`super_wreck_roadway_loop.ogg`. Sono stati aggiornati soltanto il riferimento
della scena, il manifest, i crediti e i documenti B29; non sono stati rieseguiti
smoke, regressioni, export o ispezioni.

## Gate ancora aperti

- ascolto Windows reale: loop senza click/stacco, musica sotto SFX in un'orda
  B28 e pausa/ripresa percepita;
- export e ispezione statica dell'APK corrente;
- installazione e ascolto su Pixel 9: loop, mix, mute persistente, pausa/Home e
  due run consecutive. L'APK statico e gli smoke non chiudono questo gate.
