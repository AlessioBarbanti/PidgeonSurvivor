---
id: PS-189
titolo: Isola e riduci il lag residuo con Marghe prima del minuto 2
tipo: perf
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: [PS-178]
origine: seguito della diagnosi PS-178 e richiesta del proprietario del 2026-09-16
creato: 2026-09-16
aggiornato: 2026-09-21
---

# PS-189 — Isola e riduci il lag residuo con Marghe prima del minuto 2

## Contesto

[PS-178](../5_completed/PS-178-lag-al-minuto-2-arrivo-primo-boss.md) ha ridotto
il costo della separazione dei nemici, ma il rallentamento resta
riproducibile su Windows headless. Nella finestra RUNNING 110-120 s, il p95
del tempo per frame è **139,074 ms con clone** e **31,295 ms senza abilità**;
prima dell'ottimizzazione erano rispettivamente 275,145 e 271,307 ms.
Il sintomo originale è stato segnalato su **Pixel 9 con Marghe**.

L'ammassamento dei nemici attorno all'esca è un'ipotesi da misurare: il
confronto attuale cambia anche popolazione, posizioni e bersagli, quindi
non dimostra che il costo sia nel codice del clone. Le misure Windows
headless non includono il rendering e non chiudono il gate Pixel.

## Comportamento atteso

Marghe mantiene una risposta fluida anche con l'orda raccolta attorno al
clone, prima e dopo il primo Boss. Il riferimento è il contratto corrente
di 60 FPS (circa 16,7 ms per frame), conservando spawn, statistiche,
separazione, attrazione dell'esca e comportamento degli attacchi.

## Criteri di accettazione

- [x] Riprodotta la finestra 90-126 s sulla baseline ottimizzata PS-178,
      registrando commit, Godot, hardware, profilo, seed, build del
      personaggio e facilitazioni della sonda. Analisi distinta per
      RUNNING 110-120 s, transizione Boss e ripresa dopo l'intro.
- [x] Attribuito il costo dei frame lenti a misure separate di separazione,
      movimento/collisioni, ricerca e reindirizzamento dei bersagli,
      attacchi/proiettili del clone. Registrati anche numero di passi
      fisici per frame, popolazione e densità locale. Eventuali costi
      residui dell'engine o del rendering sono identificati come tali.
- [x] Creata una fixture prestazionale ripetibile dalla situazione critica:
      stessi nemici, posizioni, raggi, velocità, bersagli e stato rilevante.
      Confrontati prima/dopo a popolazione fissa; il solo seed non vale
      come garanzia di equivalenza. Le prove che isolano un sottosistema
      dichiarano quali interazioni sospendono e restano diagnostiche.
- [x] Corretto il collo di bottiglia dimostrato. In almeno tre esecuzioni
      comparabili per configurazione, riportati p50/p95/p99, massimo e
      durata degli intervalli lenti, per finestre brevi e per tutta la
      cattura. Il miglioramento deve ripetersi nella finestra 110-120 s,
      senza regressioni nel percorso senza abilità o dopo il Boss.
- [x] Test GUT deterministici coprono il comportamento interessato dal fix,
      inclusi separazione, bersagli del clone, morte e restart ove toccati.
      Nessuna modifica a spawn, HP, danni, velocità o cadenze per ottenere
      il risultato; invariati i contratti delle abilità.
- [x] Installata la build candidata sul Pixel 9 e ripetuto il percorso con
      Marghe almeno tre volte fino a oltre 126 s, con clone attivo.
      Obiettivo: p95 entro 16,7 ms nella finestra critica RUNNING;
      ogni picco oltre 50 ms deve essere localizzato e spiegato. Se il
      budget o la fluidità percepita non sono raggiunti, registrare il
      residuo e lasciare aperta la chiusura prestazionale.
      **Su Pixel 9 nessun frame oltre 50 ms in 3 run su 3; resta la
      riserva sulla metrica, per secondo e non per frame (vedi Note).**

## Ambito

- `tools/_diagnose_boss_lag_ps178.gd` e
  `tools/_profile_enemy_separation_ps178.gd`: estendere la strumentazione
  esistente, con timeout reale e costo di misura dichiarato.
- `scripts/actors/base_enemy.gd`, `scripts/actors/ranged_enemy.gd`,
  `scripts/combat/targeting_system.gd`, `scripts/abilities/illusion_decoy.gd`
  e `scripts/abilities/ability_effect_registry.gd`: intervenire soltanto
  sui percorsi che la diagnosi dimostra costosi.
- `scripts/platform/performance_monitor.gd`, test GUT e mappa delle
  regressioni, se necessari alla misurazione o alla correzione.
- Il redesign dell'attacco del clone resta in PS-183; il freeze Android
  intorno a 25 minuti resta in PS-172. Nessun nuovo sistema globale di
  gestione dei nemici richiesto a priori.

## Verifica

- Baseline tecnica: il fix PS-178 è nel tronco (`develop`, `402be66`), quindi
  il confronto parte da lì e non dal branch citato alla creazione della card.
- Benchmark Windows iniziale possibile anche senza device. Confrontare
  configurazioni separatamente, senza altri benchmark concorrenti;
  distinguere misure strumentate da run senza profiler.
- GUT: nuovo scenario deterministico sotto `tests/unit/test_*.gd` e
  regressioni `test_ps171_enemy_overlap_separation.gd` e
  `test_ps178_enemy_separation_query.gd`, più quelle dei percorsi toccati.
  Aggiornare `tools/milestone-test-map.json`.
- Runner unico: `Focused` esplicito, `Relevant`, poi `Full` nello stesso
  processo GUT per verificare anche l'isolamento delle fixture. `Release`
  per export/runtime Windows e APK statico della candidata.
- Controllare JUnit e marker `SCRIPT ERROR`, `FATAL EXCEPTION`,
  `SMOKE_FAIL`, `CONTRACT_FAIL`. I test funzionali verdi e le misure
  prestazionali sono evidenze distinte; evitare soglie temporali GUT
  dipendenti dalla velocità della macchina CI.

### Diagnosi: il meccanismo, non solo il sintomo

Windows headless, Godot 4.7.1, Intel Core i7-8700 a 3,20 GHz, profilo mobile,
seed 20260915, Marghe, clone attivo. La sonda ora registra anche i **passi
fisici accumulati fra due frame disegnati** e l'**occupazione massima di una
cella** da 64 px (`physics_steps`, `max_cell`).

Il tempo per frame non sta in un singolo passo: è un effetto di recupero.

| Passi fisici nel frame | Campioni | Frame medio |
|---|---:|---:|
| 1 | 1488 | 16,75 ms |
| 3 | 18 | 49,78 ms |
| 6 | 7 | 109,57 ms |
| 8 (tetto dell'engine) | 58 | 168,48 ms |

Quando un singolo passo supera il budget, l'engine ne accumula fino a otto per
frame disegnato e non recupera più finché la popolazione non cala: i frame da
150-200 ms sono otto passi, non un passo lento. La densità è la variabile che
innesca il passaggio: con `max_cell` fra 50 e 69 la media dei passi è 7,3,
sotto i 30 resta a 1,0. Nel frame peggiore della cattura **220 nemici vivi
puntano tutti l'esca** e 141 stanno entro 100 px da essa.

### Attribuzione a popolazione fissa

`tools/_profile_clone_pileup_ps189.gd` ricostruisce il frame a densità massima
dal JSON che la sonda salva con `--dump-fixture`: stessi nemici, posizioni,
raggi, velocità e bersaglio comune. Mediana di tre esecuzioni per colonna,
220 nemici, `cell_max` 46.

| Sottosistema | Prima | Dopo |
|---|---:|---:|
| Separazione, intera popolazione | 10,631 ms | 4,963 ms |
| Movimento e collisioni | — | 2,610 ms |
| Ricostruzione della griglia | 0,644 ms | 0,689 ms |
| Ricerca del bersaglio del clone | 0,526 ms | 0,532 ms |
| Reindirizzamento dei bersagli | 0,253 ms | 0,259 ms |
| **Passo fisico completo** | **16,075 ms** | **8,645 ms** |

La separazione è il 66% del passo prima e il 58% dopo; il clone in sé
(ricerca del bersaglio più reindirizzamento) costa meno di 0,8 ms e **non era
il collo di bottiglia**: lo era la densità che produce. La somma delle spinte
resta **identica bit a bit** in tutte e sei le esecuzioni
(`PS189_PROFILE_CHECKSUM separation=(-0.004957, -0.014709)`).

### Scelta della correzione, misurata

Banco temporaneo sulla stessa fixture, tre giri per variante:

| Variante | ms | Candidati |
|---|---:|---:|
| A — nodo dereferenziato e validato per ogni candidato (attuale) | 8,7-9,8 | 15 226 |
| B — geometria da array paralleli, nodo solo dopo il test | 3,6-4,8 | 15 226 |
| C — come B con celle da 32 px | 3,6-4,1 | 11 289 |

Vince B, a spinta identica. C riduce i candidati del 26% ma il guadagno
rientra nel rumore: la dimensione delle celle resta 64 px.

### Confronto della run, Windows headless, 110-120 s

Tre esecuzioni per configurazione, stessa sonda, nessun altro benchmark attivo.

| Run | p50 | p95 | p99 | max | Frame >50 ms |
|---|---:|---:|---:|---:|---:|
| Prima 1 | 23,14 ms | 158,02 ms | 183,43 ms | 195,98 ms | 61 |
| Prima 2 | 95,29 ms | 202,32 ms | 218,61 ms | 242,19 ms | 80 |
| Prima 3 | 68,06 ms | 172,46 ms | 193,67 ms | 197,75 ms | 81 |
| Dopo 1 | 15,87 ms | 30,15 ms | 38,36 ms | 55,38 ms | 1 |
| Dopo 2 | 18,57 ms | 209,19 ms | 242,87 ms | 298,75 ms | 61 |
| Dopo 3 | 20,11 ms | 90,16 ms | 118,60 ms | 175,53 ms | 44 |

Mediana del p95: **150,02 → 90,16 ms**. Su questa macchina il sistema resta
bistabile: la correzione alza la densità a cui scatta il recupero (Dopo 1 tiene
16,7 ms fino a 248 nemici e `max_cell` 54, cosa che nessuna run di baseline
fa), ma la run 2 entra comunque nella spirale. Il seed non garantisce
popolazioni uguali fra esecuzioni, ed è la ragione per cui la fixture a
popolazione fissa, e non questa tabella, è l'evidenza del guadagno.

Percorso **senza abilità**, stessa finestra: p95 30,183 ms e massimo 74,498 ms,
zero frame oltre 100 ms — invariato, nessuna regressione.

### Windows con rendering, 110-120 s

Stessa sonda senza `--headless`, quindi con GPU e `process_ms` che include il
renderer.

| Configurazione | p50 | p95 | max |
|---|---:|---:|---:|
| Prima | 166,93 ms | 306,34 ms | 336,27 ms |
| Dopo | 129,69 ms | 170,66 ms | 179,53 ms |

−44% sul p95. Su questo desktop del 2017 il budget di 60 FPS non è raggiunto
né prima né dopo: il collo di bottiglia residuo è la macchina, non il device
di riferimento.

### Runtime fisico Pixel 9

Pixel 9 (`tokay`, `49140DLAQ0010Y`), Android 17 / API 37, APK ARM64 debug
`com.ilgioco.pidgeonsurvivor`, 74 986 220 byte, SHA-256
`6D2659F14BE3D0713450076538904547415C920F08E6BE1378EFCCA4884583C5`.
Tre run per configurazione, percorso Marghe oltre 126 s con clone attivo,
Boss affrontato; misura sui secondi con **almeno 180 nemici vivi**.

| Run | Nemici max | FPS minimo | Frame peggiore | Secondi con un frame >50 ms |
|---|---:|---:|---:|---:|
| Prima 1 | 223 | 7 | 137,8 ms | 8 / 34 |
| Prima 2 | 202 | 58 | 33,3 ms | 0 / 25 |
| Prima 3 | 236 | 13 | 101,7 ms | 3 / 32 |
| Dopo 1 | 220 | 58 | 29,2 ms | **0 / 37** |
| Dopo 2 | 225 | 59 | 25,4 ms | **0 / 27** |
| Dopo 3 | 207 | 59 | 27,6 ms | **0 / 32** |

Il sintomo è riproducibile sul device: la baseline scende a 7 e 13 FPS con
oltre 220 nemici. La candidata non produce **nessun** frame oltre 50 ms in tre
run, con FPS mai sotto 58 e frame peggiore sotto i 30 ms. La run di baseline
che resta pulita è anche l'unica che non supera i 202 nemici, coerente con la
soglia di densità misurata su Windows.

### Test e profili del runner

- `Focused` `20260920-221956-PS-189`: 3 script / 13 casi verdi
  (PS-189, PS-178, PS-171).
- **Mutazione 1**, rimosso l'aggiornamento della posizione nella fotografia
  (`20260920-220205-PS-189`): falliscono esattamente i 2 casi di movimento e
  knockback nello stesso tick di PS-178. Ripristinato il sorgente.
- **Mutazione 2**, posizione aggiornata solo al cambio di cella, cioè la
  semantica precedente (`20260920-222033-PS-189`): PS-178 resta verde e
  fallisce solo il caso nuovo di PS-189. È la prova che il test aggiunto
  copre qualcosa che le regressioni esistenti non coprivano.
- `Relevant` `20260920-222517-PS-189`: 17 script / 76 casi verdi.
- `Full` `20260920-235459-PS-189`: **163 script / 509 casi verdi** nello
  stesso processo GUT, zero pending, zero marker di errore.
- `Release` `20260920-235832-PS-189`: GUT 163/163, toolchain, export e
  runtime Windows verdi. L'export Android di quel tentativo è andato in
  **TIMEOUT** (non "recuperato"): rifatto in `20260921-000536-PS-189` con
  `recovered=1` e APK staticamente valido. L'artefatto validato ha lo stesso
  SHA-256 di quello installato sul Pixel: l'export è deterministico.

## Gate manuali

- [x] Runtime Windows con rendering: percorso Marghe 90-126 s.
- [x] Export e validazione statica APK corrente.
- [x] Installazione, log e runtime fisico Pixel 9: almeno tre run comparabili.
- [ ] Controllo percettivo del proprietario: fluidità con clone e primo Boss.
      Il proprietario ha osservato "a me sembra che non ci sia più lag" durante
      la sessione, ma su una partita non strumentata e senza confronto diretto
      con la baseline: il gate resta aperto in attesa di un giudizio esplicito
      sulla build candidata.

## Decisioni

- **2026-09-16 — Seguito separato di PS-178.** Conservare le misure e la
  correzione già validate; questa card possiede l'indagine sul costo
  residuo. PS-178 mantiene aperti i propri gate fisici fino alla verifica.
- **2026-09-16 — Profilare prima di scegliere l'intervento.** La densità
  vicino all'esca è un indizio, non una diagnosi. Misurare i singoli costi
  ed eventualmente i passi fisici accumulati prima di cambiare algoritmi.
- **2026-09-16 — Confronti controllati.** Il p95 su tutta la cattura può
  nascondere un tratto lento, che produce meno campioni. Mostrare anche
  finestre brevi, massimi e durata del rallentamento.
- **2026-09-20 — Il clone non è il costo: lo è la densità che produce.**
  La misura a popolazione fissa assegna al clone meno di 0,8 ms per passo
  (ricerca del bersaglio più reindirizzamento) e alla separazione 10,6 ms.
  Nessun intervento su `illusion_decoy.gd`, `targeting_system.gd` o
  `ability_effect_registry.gd`: il redesign dell'attacco resta in PS-183.
- **2026-09-20 — Geometria negli array paralleli, nodo solo dopo il test.**
  Nel caso denso la grande maggioranza dei candidati non si sovrappone:
  dereferenziare il nodo e chiamare `is_instance_valid()` per ciascuno costava
  più della geometria. La fotografia di separazione porta ora `nodes`,
  `positions` e `radii` indicizzati per slot; il nodo si tocca solo quando i
  cerchi si sovrappongono davvero. Il risultato è identico bit a bit.
- **2026-09-20 — La posizione va riscritta a ogni movimento.** Da quando la
  posizione vive nella fotografia e non nel nodo, non basta più riassegnare
  la cella: uno spostamento dentro la stessa cella lascerebbe i vicini a
  leggere un valore vecchio di un tick. `_update_separation_cell` diventa
  `_sync_separation_snapshot` e aggiorna sempre la posizione.
- **2026-09-20 — Ordine deterministico senza lambda.** L'ordine per
  `instance_id` (contratto PS-174) si fissa una volta sull'intera popolazione
  con `PackedInt64Array.sort()`; gli slot lo ereditano, quindi le celle
  nascono ordinate e un cambio di cella si richiude con `Array.sort()`.
  Spariscono tutti i `sort_custom` con confronto GDScript.
- **2026-09-20 — Celle ancora da 64 px.** Celle da 32 px riducono i candidati
  del 26%, ma il guadagno misurato rientra nel rumore. Nessun cambio di
  costante senza un guadagno che si veda.
- **2026-09-20 — Godmode di sola diagnosi, su richiesta del proprietario.**
  Sul device la sonda headless non può girare e una guida automatica muore
  prima del minuto 1: senza una facilitazione il gate fisico non è
  ripetibile. Il flag riusa il pattern del flag monouso B22 (`user://`,
  solo build di debug), rinnova i-frame invece di curare, non tocca spawn,
  HP, danni né cadenze, e si dichiara nel log con `PS189_GODMODE_ON`.
  Rimosso dal device a fine sessione e verificato spento.
- **2026-09-20 — Picco reale per frame nel monitor.** `frame_ms` deriva da
  `Engine.get_frames_per_second()`, una media smussata che nasconde proprio i
  singoli frame lunghi da localizzare: il campione porta ora anche
  `frame_max_ms`, il peggiore dell'intervallo.
- **2026-09-20 — La sonda riprende dopo la pausa da perdita di fuoco.** Con
  rendering la finestra perde il fuoco e `PlatformLifecycle` mette in pausa,
  per contratto senza riprendere da sola. La sonda è un'imbracatura, non il
  lifecycle: chiede la ripresa come già fa per i modali, altrimenti la
  cattura con GPU non parte. Il contratto di `PlatformLifecycle` è intatto.

## Documenti sincronizzati

- [x] Board e collegamento dalla card PS-178.
- [x] `docs/enemies-bosses.md`: aggiornato il contratto della separazione con
      la fotografia per slot.
- [x] `docs/verification-workflow.md`: godmode di sola diagnosi e
      `frame_max_ms`, cioè come si misura un gate prestazionale su device.
- Spawn, HP, danni, velocità, cadenze e contratti delle abilità sono
  invariati: nessun altro documento cambia.

## Note

Card creata su richiesta del proprietario. Le misure di questa sezione sono
nuove: quelle citate nel Contesto restano quelle della sessione PS-178.

**2026-09-17 — Osservazione non verificata, non un'evidenza.** Durante la
prova reale di PS-185 il proprietario ha notato: "il lag pre minuto 2 è
scomparso". Nessuna delle due card in sessione ha toccato nemici, clone,
targeting o separazione.
**Chiuso il 2026-09-20:** con catture pulite la baseline scende a 7 e 13 FPS
su Pixel 9 con oltre 220 nemici, quindi il sintomo *è* ancora riproducibile.
L'osservazione dipendeva da una partita che non aveva raggiunto quella
popolazione (la run di baseline rimasta pulita si ferma a 202 nemici).

**Riserva sulla metrica del device.** `PerformanceMonitor` campiona una volta
al secondo: sul Pixel 9 esiste il **peggior frame di ogni secondo**, non un
p95 per frame. La soglia "ogni picco oltre 50 ms" è quindi verificata in senso
forte (nessun secondo contiene un frame oltre 50 ms), mentre "p95 entro
16,7 ms" è verificata solo indirettamente: la mediana del frame peggiore per
secondo è 16,7 ms. Un p95 per frame su device richiederebbe un registratore
per frame che qui non è stato aggiunto.

**Crash a spegnimento, non attribuito.** Un tentativo `Release`
(`20260920-234650-PS-189`) è uscito con `-1073741819` (access violation) a
report GUT verde — 507 casi passati, processo morto fuori dai test. Non
riprodotto nei tre `Full`/`Release` successivi sullo stesso albero. I marker
di oggetti ancora vivi a fine processo erano già registrati come preesistenti
in PS-178. Non attribuito a questa card: aperta
[PS-199](../1_idea/PS-199-crash-a-spegnimento-suite-gut.md).

Comandi usati come evidenza:

```powershell
godot_console --headless --path . --script tools/_diagnose_boss_lag_ps178.gd -- `
  --friend=marghe --run-seed=20260915 --mobile-profile --dump-fixture --tag=ps189-fixture
godot_console --headless --path . --script tools/_profile_clone_pileup_ps189.gd -- `
  --fixture=exports/diagnostics/ps189-fixture-ps189-fixture.json --label=dopo
godot_console --path . --script tools/_diagnose_boss_lag_ps178.gd -- `
  --friend=marghe --run-seed=20260915 --mobile-profile --wall-timeout=420 --tag=ps189-dopo-rendering
.\tools\run-milestone-checks.ps1 -Milestone PS-189 -Profile Full -NoCache
.\tools\run-milestone-checks.ps1 -Milestone PS-189 -Profile Release -NoCache
```

Godmode sul device (solo build di debug, da rimuovere a fine misura):

```powershell
adb shell "run-as com.ilgioco.pidgeonsurvivor sh -c 'echo ps189 > files/ps189_godmode.flag'"
adb shell "run-as com.ilgioco.pidgeonsurvivor rm -f files/ps189_godmode.flag"
```

CSV, JSON della fixture e log locali restano in `exports/diagnostics/`,
fuori dal commit.
