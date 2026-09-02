---
id: PS-076
titolo: Aumenta la densità nemica a schermo a parità di rischio e progressione
tipo: chore
area: gameplay
stato: PRONTO
priorita: alta
dipende_da: []
origine:
creato: 2026-09-02
aggiornato: 2026-09-02
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

- [ ] Il ritmo di spawn ordinario aumenta rispetto ai valori attuali
      (`base_spawn_interval=0,60s → min_spawn_interval=0,12s`): più nemici
      arrivano nella stessa finestra di tempo.
- [ ] HP e danno da contatto del nemico base scendono in proporzione
      all'aumento del ritmo di spawn, seguendo lo stesso principio già usato
      per l'XP (Densità B28): il danno atteso al Player nel tempo resta
      equivalente, entro una tolleranza dichiarata in fase di
      implementazione, ai valori attuali dello stesso profilo.
- [ ] Il valore XP per kill resta coerente con la scala già esistente
      (`progression_experience_multiplier` e intervallo corrente): l'XP
      guadagnato nel tempo resta equivalente a oggi.
- [ ] `max_alive_enemies` viene rivisto se il nuovo ritmo rischia di
      raggiungere il cap attuale (140) e diventarne collo di bottiglia.
- [ ] Il numero medio di nemici vivi entro un raggio di ingaggio ravvicinato
      al Player aumenta misurabilmente rispetto al profilo attuale, a parità
      di seed e di tempo di run.
- [ ] Nessuna variazione ai pesi per archetipo, alla curva late-run
      ([PS-007](./PS-007-impedire-run-AFK-lategame.md)), agli eventi
      d'ondata ([PS-008](./PS-008-eventi-di-ondata.md)) o al sistema Boss,
      oltre a quanto richiesto per riequilibrare HP/danno/XP del nemico
      base.
- [ ] Determinismo e seed restano quelli di `EnemySpawner`: stesso seed
      produce la stessa sequenza.
- [ ] `tests/unit/test_b28_horde_density.gd` è aggiornato per riflettere le
      nuove costanti dichiarate (oggi pinna esplicitamente `140`,
      `0,60/0,12s` e `18 HP`), non lasciato a puntare a numeri superati.
- [ ] Le costanti numeriche finali vivono nei dati (`EnemySpawnProfile`,
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

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: playtest di almeno 5 minuti coprendo
      early/mid/late run, verificando anche il frame rate con lo stress cap
      B18V (150 nemici)
- [ ] Controllo percettivo richiesto: sì — è il punto della card. Il
      proprietario deve giocarla e confermare "più frenetico, stessa
      difficoltà"; senza questa conferma la card non può chiudere a
      `COMPLETATO`

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

## Documenti sincronizzati

- [ ] `docs/systems-difficulty.md`, sezione "Spawn e curva di difficoltà".
- [ ] `docs/prd.md`, sezione "Densità B28", se il contratto numerico
      dichiarato lì cambia.

## Note

Se il playtest mostrasse che "più nemici, singolarmente più deboli" non
risolve la sensazione di scarsità (per esempio perché il vero collo di
bottiglia è il raggio o l'area delle armi del Player, non il ritmo di
spawn), aprire una card separata sul bilanciamento delle armi invece di
allargare questa.
