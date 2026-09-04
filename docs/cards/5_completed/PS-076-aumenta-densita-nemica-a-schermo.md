---
id: PS-076
titolo: Aumenta la densità nemica a schermo a parità di rischio e progressione
tipo: chore
area: gameplay
stato: COMPLETATO
priorita: alta
dipende_da: []
origine:
creato: 2026-09-02
aggiornato: 2026-09-04
---

# PS-076 — Aumenta la densità nemica a schermo a parità di rischio e progressione

## Contesto

Il proprietario ha giocato la curva attuale e l'ha trovata "troppo poco
frenetica": pochi nemici vicino al Player in ogni istante, il conteggio
totale a schermo resta basso anche avanti nella run, e i nemici muoiono più
in fretta di quanto riescano ad accumularsi. La difficoltà percepita è
invece già quella giusta: non va toccata.

Non è il primo intervento su questo asse. **B37** ("Densità leggibile e
direzione delle orde") ha già ridotto la vita base del nemico comune da `24`
a `18 HP` (-25%) proprio per attenuare l'effetto "muro di piccioni", insieme
a offset di inseguimento e scheduler di settori N/E/S/O
(`docs/archive/development-plan-through-b54-2026-08-30.md:1543-1618`). La
sensazione di scarsità persiste comunque, quindi questa card spinge oltre
sullo stesso asse, aggiungendo anche il **ritmo di spawn**, non solo l'HP.

Curva ordinaria attuale (`data/spawn_profiles/default_enemy_spawn_profile.tres`,
dichiarata e testata in
[tests/unit/test_b28_horde_density.gd](../../../tests/unit/test_b28_horde_density.gd)):
`max_alive_enemies=140`, `base_spawn_interval=0,60s → min_spawn_interval=0,12s`,
`spawn_acceleration=0,003`, HP nemico base `18` (B37),
`progression_experience_multiplier=1,50`. L'XP per kill è già scalata
sull'intervallo di spawn corrente (**Densità B28**, `prd.md:644-650`), quindi
il meccanismo per compensare un ritmo diverso senza sballare l'economia XP
esiste già — va solo esteso allo stesso principio per HP e danno da contatto.

## Comportamento atteso

A parità di tempo trascorso e di build, il Player vede più nemici a schermo e
più affollamento nelle vicinanze, ma il rischio complessivo (danno atteso nel
tempo) e il ritmo di progressione (XP nel tempo) restano equivalenti a oggi:
più bersagli, non più difficoltà.

## Criteri di accettazione

- [x] Il ritmo di spawn ordinario aumenta rispetto ai valori attuali
      (`base_spawn_interval=0,60s → min_spawn_interval=0,12s`): più nemici
      arrivano nella stessa finestra di tempo. Verificato: nuova cadenza
      `0,35s → 0,07s`, fattore costante `12/7 ≈ 1,71×` a ogni istante di run.
- [x] HP e danno da contatto del nemico base scendono in proporzione
      all'aumento del ritmo di spawn, seguendo lo stesso principio già usato
      per l'XP (Densità B28): il danno atteso al Player nel tempo resta
      equivalente, entro una tolleranza dichiarata in fase di
      implementazione, ai valori attuali dello stesso profilo. Tolleranza
      dichiarata: ±10%; scarto reale +2,86% (HP `18→10`, danno `20→12`).
- [x] Il valore XP per kill resta coerente con la scala già esistente
      (`progression_experience_multiplier` e intervallo corrente): l'XP
      guadagnato nel tempo resta equivalente a oggi. Il meccanismo B28 usa
      l'intervallo di *riferimento* (invariato), non quello ordinario: il
      budget XP/s resta identico per costruzione, nessuna costante toccata.
- [x] `max_alive_enemies` viene rivisto se il nuovo ritmo rischia di
      raggiungere il cap attuale (140) e diventarne collo di bottiglia.
      Alzato a `250`: prima a `150` (limite B18V allora validato), poi il
      proprietario ha riportato prova diretta su device che sia Windows sia
      Android reggono 250 nemici a 60 FPS, quindi lo stress B18V stesso è
      stato alzato di conseguenza (vedi Decisioni).
- [x] Il numero medio di nemici vivi entro un raggio di ingaggio ravvicinato
      al Player aumenta misurabilmente rispetto al profilo attuale, a parità
      di seed e di tempo di run. Il ritmo di arrivo piu' alto e' verificato
      automaticamente (smoke); l'accumulo vicino al Player e' stato
      confermato a percezione dal proprietario nei Gate manuali.
- [x] Nessuna variazione ai pesi per archetipo, alla curva late-run
      ([PS-007](../5_completed/PS-007-impedire-run-AFK-lategame.md)), agli eventi
      d'ondata ([PS-008](../5_completed/PS-008-eventi-di-ondata.md)) o al sistema Boss,
      oltre a quanto richiesto per riequilibrare HP/danno/XP del nemico
      base. Nessun archetipo (`data/enemies/*.tres`), boss o wave event e'
      stato toccato.
- [x] Determinismo e seed restano quelli di `EnemySpawner`: stesso seed
      produce la stessa sequenza. Nessuna modifica alla logica RNG, solo ai
      dati; verificato con doppia run seedata sullo stesso profilo.
- [x] `tests/unit/test_b28_horde_density.gd` è aggiornato per riflettere le
      nuove costanti dichiarate (oggi pinna esplicitamente `140`,
      `0,60/0,12s` e `18 HP`), non lasciato a puntare a numeri superati.
- [x] Le costanti numeriche finali vivono nei dati (`EnemySpawnProfile`,
      archetipo del nemico base), non nel codice, coerente col contratto
      dati-vs-logica.

## Ambito

- `data/spawn_profiles/default_enemy_spawn_profile.tres`.
- Dati dell'archetipo nemico base (HP, danno da contatto, valore XP) —
  `scenes/actors/base_enemy.tscn` e/o `data/enemies/enemy_archetype_*.tres`
  pertinente.
- `tests/unit/test_b28_horde_density.gd`, per allinearlo alle nuove
  costanti.
- `scripts/game/enemy_spawner.gd`, solo se `max_alive_enemies` o la gestione
  del cap richiedono una modifica strutturale, non per la logica di
  selezione settori/archetipi.

Non toccare:

- pesi per archetipo, curva late-run PS-007, eventi d'ondata PS-008, soglie
  e pattern del sistema Boss/Signature;
- targeting, danno e bilanciamento delle armi/abilità del Player;
- offset di inseguimento e scheduler di settori (contratto B37, già
  approvato);
- `PerformanceProfile` e i cap di stress B18V, salvo evidenza da profiler
  che il nuovo ritmo li richieda (in quel caso, gate manuale separato, non
  criterio automatico di questa card).

## Verifica

- Smoke: `tests/unit/test_ps076_enemy_density_rebalance.gd` → marker
  `ENEMY_DENSITY_REBALANCE_SMOKE_OK` — verifica, a parità di seed e finestra
  temporale, che il nuovo profilo produca più nemici vivi contemporaneamente
  del profilo precedente, che il danno atteso/sec e l'XP/sec restino entro
  la tolleranza dichiarata, e che il determinismo regga su restart.
- Aggiornare `tests/unit/test_b28_horde_density.gd` con le nuove costanti.
- Profilo minimo prima della chiusura: `Relevant`; dato che la card tocca la
  curva centrale su cui si appoggiano PS-007 e PS-008, è raccomandato un
  passaggio `Full` prima di dichiararla `COMPLETATO`.
- **Risultati 2026-09-03 (prima del cap 250):** `Focused` (1/1) e `Relevant`
  (11/11 + 1 focused) verdi, marker `ENEMY_DENSITY_REBALANCE_SMOKE_OK`
  emesso. Il primo `Full` lanciato a quel cap è stato interrotto a metà
  corsa perché nel frattempo `max_alive_enemies` è salito a 250 (vedi
  Decisioni): un singolo processo Godot carica tutte le risorse una sola
  volta all'avvio, quindi una run già in corso non avrebbe riflesso il dato
  aggiornato in modo affidabile.
- **Risultati 2026-09-03 (dopo il cap 250):** `Focused` (1/1) e `Relevant`
  (12/12 + 1 focused) rilanciati da zero e verdi — soddisfano il profilo
  minimo dichiarato in Verifica. `Full` è stato avviato a scopo
  precauzionale ma interrotto su richiesta del proprietario in questa
  sessione (non c'era tempo per attenderlo); rieseguito successivamente dal
  proprietario, verde.

## Gate manuali

- [x] Runtime Windows — confermato dal proprietario.
- [x] Validazione statica APK — confermata dal proprietario.
- [x] Runtime fisico Pixel 9 — cap B18V: il proprietario ha verificato di
      persona (2026-09-03) che sia Windows sia Android reggono 250 nemici
      vivi a 60 FPS, base per l'aumento `stress_enemy_count 150→250`.
- [x] Runtime fisico Pixel 9: playtest di almeno 5 minuti coprendo
      early/mid/late run — confermato dal proprietario.
- [x] Controllo percettivo richiesto: sì — è il punto della card. Il
      proprietario ha giocato la run e confermato "più frenetico, stessa
      difficoltà".

## Decisioni

- **2026-09-02 — Sintomo isolato con il proprietario.** I nemici muoiono
  troppo in fretta per accumularsi, il conteggio totale a schermo resta
  basso, pochi nemici vicino al Player in ogni istante.
- **2026-09-02 — Compromesso scelto: più nemici, singolarmente più
  deboli.** A parità di rischio e progressione nel tempo, non un aumento di
  difficoltà. Alternative scartate: "nemici più vicini/aggregati a parità di
  numero" (non risolve il sintomo "muoiono troppo in fretta") e "più nemici
  e più difficile insieme" (il proprietario ha esplicitamente detto che la
  difficoltà attuale è già quella giusta).
- **2026-09-02 — Estende B37, non lo sostituisce.** B37 aveva già mosso
  l'HP; qui si aggiunge il ritmo di spawn come seconda leva sullo stesso
  obiettivo dichiarato da B37.
- **Aperto — costanti numeriche esatte.** Questa card non fissa i nuovi
  valori: vanno scelti in implementazione e validati a playtest. Una
  modellazione quantitativa del compromesso rischio/densità (per esempio con
  l'agente `analista-bilanciamento`, invocabile solo su richiesta esplicita)
  è consigliata prima di scegliere le costanti finali, invece di regolarle
  "a sensazione".
- **2026-09-03 — Costanti scelte: fattore uniforme `12/7` su cadenza,
  HP e danno.** `base_spawn_interval 0,60→0,35s`, `min_spawn_interval
  0,12→0,07s`, `spawn_acceleration 0,003→0,00175` (stesso rapporto `5:1`
  base/min e stessa finestra di 160s per raggiungere il minimo: solo la
  cadenza si infittisce, non la sua forma). HP nemico base `18→10`, danno da
  contatto `20→12` (scarto dal fattore esatto scelto per restare su numeri
  interi leggibili nei dati; verificato in tolleranza ±10% dal danno atteso
  equivalente, scarto reale +2,86%). `max_alive_enemies 140→150`: alzato
  fino al limite allora validato dallo stress B18V (150 su Windows e
  mobile), non oltre — coerente col vincolo "Non toccare" di questa card
  sui cap B18V senza nuova evidenza profiler.
- **2026-09-03 — Cap alzato a `250`: nuova evidenza profiler del
  proprietario.** Il proprietario ha riportato di aver verificato di
  persona che sia Windows sia Android reggono fino a 250 nemici vivi a 60
  FPS ("Reggono sia windows che android, quindi possiamo mantenere il cap
  condiviso"). Questa è esattamente l'eccezione già prevista dal vincolo
  "Non toccare" sui cap B18V ("salvo evidenza da profiler... gate manuale
  separato, non criterio automatico di questa card"): `max_alive_enemies`
  passa da `150` a `250`, e lo stress B18V stesso è stato alzato di
  conseguenza in entrambi i `PerformanceProfile`
  (`stress_enemy_count 150→250` su `windows_performance_profile.tres` e
  `mobile_performance_profile.tres`) cosicché il test automatico
  "il cap non deve superare lo stress B18V" resti coerente con dati reali,
  non con un valore ormai superato. Questa evidenza è il resoconto diretto
  del proprietario, non un `--b18v-stress` rieseguito da questa sessione:
  il gate manuale "Runtime fisico Pixel 9" nella sezione Gate manuali
  riporta questa provenienza esplicitamente invece di dichiararsi
  automatico.
- **2026-09-03 — Nessuna modifica al meccanismo di scaling XP.**
  `get_experience_reward_scale` usa gli intervalli di *riferimento*
  (`progression_reference_*`, invariati da questa card), non
  `base_spawn_interval`/`min_spawn_interval`: il budget XP/s resta identico
  per costruzione a qualunque cadenza ordinaria, senza toccare
  `progression_experience_multiplier`. Di conseguenza,
  `test_fractional_xp_budget_compensates_across_kills` (che conta XP su un
  numero fisso di kill, non su una finestra di tempo fissa) ora richiede
  solo `>= 2` XP invece di `>= 4`: a parità di kill contate, ogni kill vale
  meno perché la cadenza è più fitta, ma l'XP per **secondo** resta
  invariato (verificato separatamente).
- **2026-09-03 — Test preesistenti allineati alla nuova baseline.**
  `test_b37_density_direction.gd`, `test_b18h_pigeon_enemies.gd`,
  `test_b06_player_survival.gd` (incluso il calcolo a cascata delle hit
  successive nella finestra di invulnerabilità),
  `test_b17a_complete_roster_abilities.gd` (baseline salute Marghe) e
  `test_b42_measurable_passives.gd` (costante `BASE_ENEMY_HEALTH` e la
  dimostrazione "l'aura toglie un colpo", ricalcolata a danno `8,0` invece
  di `15,2` perché con HP `10` un solo colpo da `15,2` uccideva già senza
  amplificazione, invalidando la dimostrazione) puntavano tutti alla
  baseline B37 (`18 HP`/`20` danno) o al cap `140`: aggiornati agli stessi
  valori, non lasciati a puntare a numeri superati.

## Documenti sincronizzati

- [x] `docs/systems-difficulty.md`, sezione "Spawn e curva di difficoltà"
      (solo i riferimenti di riga a `prd.md`, il contratto numerico non è
      duplicato lì).
- [x] `docs/prd.md`, sezione "Densità B28/PS-076".
- [x] `docs/enemies-bosses.md`, riga "Piccione base" della tabella archetipi
      (non elencato nell'Ambito originale della card, ma è il catalogo
      corrente dei nemici e conteneva gli stessi numeri superati).

## Note

Se il playtest mostrasse che "più nemici, singolarmente più deboli" non
risolve la sensazione di scarsità (per esempio perché il vero collo di
bottiglia è il raggio o l'area delle armi del Player, non il ritmo di
spawn), aprire una card separata sul bilanciamento delle armi invece di
allargare questa.
