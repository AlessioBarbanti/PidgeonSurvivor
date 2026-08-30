# B18V — Hardening Windows/Android e performance

Ultimo aggiornamento: 25 agosto 2026
Stato: **COMPLETATO**

Il 25 agosto 2026 il proprietario del progetto ha chiesto esplicitamente di
considerare B18V completato. Questa è una chiusura operativa della milestone:
le evidenze automatiche e statiche sotto restano valide, mentre emulatori e
soak fisico non registrati non vengono retroattivamente dichiarati eseguiti.
Il prerequisito tecnico B18V di B20 è quindi sbloccato; il piano corrente
posticipa comunque il packaging dopo B22 e B23.

## Contratto implementato

- `PerformanceProfile` scene-local: 60 FPS, 150 nemici, 200 proiettili e 200
  pickup per Windows e mobile. I soli cap introdotti sono FIFO sui feedback
  transitori: 300 Windows e 150 mobile.
- `PerformanceMonitor` è nascosto per default e disponibile nelle debug build
  solo con `--performance-overlay`. Ogni campione `B18V_PERF_SAMPLE` contiene
  FPS/frame time, memoria, nodi/oggetti, entità, VFX, voci audio e profilo.
- `--b18v-stress` istanzia le scene reali di nemici, proiettili e pickup,
  esercita controller/targeting/VFX/audio e ripete cinque restart/cambi profilo;
  il termine pulito stampa `B18V_PERFORMANCE_OK`. Il contratto stampa anche
  `B18V_CONTRACT_OK`.
- Nessun valore gameplay, timing, pool audio (12 voci), danno, cooldown, raggio
  o spawn è stato modificato. La scala interna mobile resta `1,0`: il fallback
  `0,85` non è stato applicato e quindi non richiede un nuovo gate percettivo.

## Evidenza automatica e artefatti

| Area | Risultato | Evidenza |
|---|---|---|
| Cache classi Godot | Verde | `godot_console --headless --editor --path . --quit` |
| Smoke B18V | Verde | `_hardening_performance_smoke.gd` → `B18V_HARDENING_PERFORMANCE_SMOKE_OK` |
| Regressione | Verde | 43 smoke totali e project smoke; nessun `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o `CONTRACT_FAIL` |
| Export/runtime Windows | Verde tecnico | export debug e runtime a 1280×720 con `--skip-character-select --b18v-stress --performance-overlay`; marker B18V e densità 150/200/200 osservati |
| APK statico | Verde | debug APK ARM64, `minSdk=31`, `targetSdk=36`, firma v2 e launcher corretti |

APK: `exports/android/pidgeon-survivor-debug.apk`

SHA-256: `E9BFC3D39738C2D650A3207DBEE0DE5B2EBD25681169D0065E44622EC0671B73`

Dimensione: 96,095,165 byte
Package: `com.ilgioco.pidgeonsurvivor` — `Pidgeon Survivor`

Il run Windows da 60 s ha prodotto 11 campioni utili dopo il cold start, con
mediana 63 FPS e p95 frame time 19,23 ms. È un'osservazione tecnica, non una
chiusura del budget: non certifica il requisito di assenza di sequenze ripetute
oltre 33,3 ms né la validazione fisica Android.

## Matrice tecnica al momento della chiusura accettata

| Ambiente | Stato | Gate rimanente |
|---|---|---|
| Windows runtime | Parziale | resize, fullscreen, focus-loss e stress interattivo sia 1280×720 sia fullscreen con raccolta completa dei campioni |
| APK statico | Verde | nessuno statico |
| AVD Android 12/API 31, 4 GB, 720×1600 | Bloccato esterno | `sdkmanager` richiede l'accettazione esplicita della licenza dell'immagine di sistema |
| AVD Android 16/API 36 | Aperto | cold/update install e percorso welcome→run→pause su target/layout e 4:3 |
| Pixel 9 API 37 fisico | Aperto | cutout 20:9, multitouch reale, Back/Home/lock/interruzione, ripresa esplicita, Boss/finali/cambio personaggio e soak 20 min/5 cicli |

L'APK corrente è stato reinstallato sul Pixel 9 collegato. Un tentativo di
passare `--b18v-stress` attraverso l'activity launcher non ha inoltrato gli
argomenti alla activity Godot non esportata; non viene trattato come test di
stress né come evidenza fisica.

Il contratto originario richiedeva sul Pixel 9: mediana almeno 59 FPS, almeno 95% dei
campioni a 55 FPS o più, nessuna sequenza ripetuta oltre 33,3 ms, nessun calo
sostenuto oltre 10%, cleanup azzerato, pendenza memoria non oltre 1 MiB/min,
memoria finale entro max(10%, 32 MiB) dal warm-up e nessuno stato termico
severe/critical. Questi valori restano storico del gate non registrato e non
sono attribuiti a una sessione inesistente; l'accettazione del proprietario ha
chiuso il prerequisito tecnico B18V di B20. La roadmap mantiene B20
`POSTICIPATO` dopo B22 e B23.
