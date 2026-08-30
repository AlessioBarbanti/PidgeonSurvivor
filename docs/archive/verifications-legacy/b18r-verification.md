# B18R — Durata e leggibilità di animazioni e VFX

Data verifica: 25 agosto 2026
Godot: `4.7.1.stable.official.a13da4feb`
Stato: `COMPLETATO`

## Esito

B18R centralizza i timing puramente presentazionali e rende più leggibili gli
effetti one-shot senza estendere la loro autorità gameplay. Il proprietario ha
confermato esplicitamente che la verifica umana Windows/Pixel 9 è andata bene;
il gate percettivo della slice è quindi chiuso.

## Timing congelati

| Feedback | Durata finale |
| --- | ---: |
| Burst icona abilità | `1,20 s` |
| Entrata / uscita burst | `0,18 s` / `0,38 s` |
| Accento Cosplay | `1,00 s` |
| Flash Player / nemico | `0,075 s` / `0,08 s` |
| Reazione Player / nemico | `0,30 s` / `0,26 s` |
| Hit spark | `0,14 s` |
| Morte nemico | `0,78 s` |
| Burst danno Player | `0,46 s` |
| Transizione vita HUD | `0,36 s` |
| Impulso abilità pronta | `0,60 s` |

La sorgente unica è `PresentationTimings`. Walk cycle e animazioni continue
restano legati al relativo stato e non consumano questi valori one-shot.

## Separazione gameplay e lifecycle

Il burst icona e l'accento Cosplay vivono come code visive sibling sotto il
contenitore effetti. La durata reale dell'abilità termina indipendentemente e
la coda non ha collisioni, danno, tick, raggio o input. Pausa, level-up e Boss
intro congelano l'avanzamento tramite il tempo logico `RUNNING`; terminali,
restart e cambio personaggio eliminano code, timer e nodi residui.

Lo smoke verifica anche che i valori gameplay di riferimento restino invariati
(cooldown `8 s`, raggio `220`, danno `20` per l'onda di Magno), che la coda possa
sopravvivere soltanto come dissolvenza non interattiva e che due run consecutive
partano senza residui.

## Verifica automatica e Windows

- smoke dedicato: `B18R_VISUAL_TIMING_SMOKE_OK`;
- contratto runtime: `B18R_CONTRACT_OK`;
- regressione completa: `42/42`;
- project smoke e runtime Windows debug: exit `0`, `SMOKE_OK`;
- export Windows debug: riuscito.

Log regressione:
`%TEMP%\il-gioco-verification\20260825-162430-B18R`

## Android e Pixel 9

L'exporter Godot ha prodotto un APK corrente e staticamente valido, poi è
rimasto inattivo oltre il timeout del runner; non si attribuisce quindi un exit
code positivo a quel processo. Il build Gradle diretto `assembleDebug` è invece
terminato con exit `0` e ha prodotto gli APK debug il 25 agosto 2026.

L'APK Godot verificato e installato ha:

- package `com.ilgioco.pidgeonsurvivor`;
- launcher `com.godot.game.GodotAppLauncher`;
- minSdk `31`, targetSdk `36`, sola ABI `arm64-v8a`, firma v2;
- SHA-256 `A55791FDA2007EF87097043F3E4D3C4606024F67770A3D35123876167A752CA2`.

Sul Pixel 9 `49140DLAQ0010Y` l'installazione e il cold launch sono riusciti. Il
percorso welcome → selezione Magno → run → attivazione abilità → pausa/ripresa
ha mostrato la coda icona mentre il cooldown era già iniziato. Due catture a un
secondo di distanza durante la pausa avevano SHA-256 identico, confermando il
freeze; il log conteneva `B18R_CONTRACT_OK` senza `SCRIPT ERROR`,
`FATAL EXCEPTION` o `CONTRACT_FAIL`. Le catture tecniche sono rimaste in una
cartella temporanea e non sono state aggiunte al repository.

La prova ADB documenta il comportamento tecnico; l'approvazione umana esplicita
del proprietario chiude separatamente la percezione dei timing su schermo reale.
