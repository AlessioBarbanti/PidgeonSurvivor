---
id: PS-189
titolo: Isola e riduci il lag residuo con Marghe prima del minuto 2
tipo: perf
area: gameplay
stato: PRONTO
priorita: alta
dipende_da: [PS-178]
origine: seguito della diagnosi PS-178 e richiesta del proprietario del 2026-09-16
creato: 2026-09-16
aggiornato: 2026-09-17
---

# PS-189 — Isola e riduci il lag residuo con Marghe prima del minuto 2

## Contesto

[PS-178](../4_to_test/PS-178-lag-al-minuto-2-arrivo-primo-boss.md) ha ridotto
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

- [ ] Riprodotta la finestra 90-126 s sulla baseline ottimizzata PS-178,
      registrando commit, Godot, hardware, profilo, seed, build del
      personaggio e facilitazioni della sonda. Analisi distinta per
      RUNNING 110-120 s, transizione Boss e ripresa dopo l'intro.
- [ ] Attribuito il costo dei frame lenti a misure separate di separazione,
      movimento/collisioni, ricerca e reindirizzamento dei bersagli,
      attacchi/proiettili del clone. Registrati anche numero di passi
      fisici per frame, popolazione e densità locale. Eventuali costi
      residui dell'engine o del rendering sono identificati come tali.
- [ ] Creata una fixture prestazionale ripetibile dalla situazione critica:
      stessi nemici, posizioni, raggi, velocità, bersagli e stato rilevante.
      Confrontati prima/dopo a popolazione fissa; il solo seed non vale
      come garanzia di equivalenza. Le prove che isolano un sottosistema
      dichiarano quali interazioni sospendono e restano diagnostiche.
- [ ] Corretto il collo di bottiglia dimostrato. In almeno tre esecuzioni
      comparabili per configurazione, riportati p50/p95/p99, massimo e
      durata degli intervalli lenti, per finestre brevi e per tutta la
      cattura. Il miglioramento deve ripetersi nella finestra 110-120 s,
      senza regressioni nel percorso senza abilità o dopo il Boss.
- [ ] Test GUT deterministici coprono il comportamento interessato dal fix,
      inclusi separazione, bersagli del clone, morte e restart ove toccati.
      Nessuna modifica a spawn, HP, danni, velocità o cadenze per ottenere
      il risultato; invariati i contratti delle abilità.
- [ ] Installata la build candidata sul Pixel 9 e ripetuto il percorso con
      Marghe almeno tre volte fino a oltre 126 s, con clone attivo.
      Obiettivo: p95 entro 16,7 ms nella finestra critica RUNNING;
      ogni picco oltre 50 ms deve essere localizzato e spiegato. Se il
      budget o la fluidità percepita non sono raggiunti, registrare il
      residuo e lasciare aperta la chiusura prestazionale.

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

- Baseline tecnica: commit `e97fde0` sul branch
  `refactor/test-cleaning-2026-09-16`; evidenze raccolte in PS-178.
  Prima dell'implementazione verificare che il checkout contenga quel fix.
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

## Gate manuali

- [ ] Runtime Windows con rendering: percorso Marghe 90-126 s.
- [ ] Export e validazione statica APK corrente.
- [ ] Installazione, log e runtime fisico Pixel 9: almeno tre run comparabili.
- [ ] Controllo percettivo del proprietario: fluidità con clone e primo Boss.

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

## Documenti sincronizzati

- [x] Board e collegamento dalla card PS-178.
- [ ] Dopo l'implementazione: aggiornare soltanto i contratti effettivamente
      cambiati in `docs/enemies-bosses.md` o `docs/verification-workflow.md`.

## Note

Card creata su richiesta del proprietario; implementazione non avviata.
Le misure riportate sono quelle Windows della sessione PS-178, non nuove
misure del Pixel. Decisioni, nuovi risultati e gate restano in questa card.

**2026-09-17 — Osservazione non verificata, non un'evidenza.** Durante la
prova reale di PS-185 il proprietario ha notato: "il lag pre minuto 2 è
scomparso". Nessuna delle due card in sessione ha toccato nemici, clone,
targeting o separazione — non è chiaro se derivi da varianza del device
(termica, stato del sistema) o da altro. Non chiude alcun criterio: restano
validi il profilo p95 richiesto, la fixture prestazionale ripetibile e le
almeno tre run comparabili su Pixel 9 prima di dichiarare risolto.
