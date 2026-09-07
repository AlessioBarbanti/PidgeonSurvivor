---
id: PS-125
titolo: Rendi costante la scala XP/kill lungo la curva late-run
tipo: fix
area: gameplay
stato: SCARTATA
priorita: alta
dipende_da: []
origine:
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-125 — Rendi costante la scala XP/kill lungo la curva late-run

**SCARTATA (2026-09-07).** Una riverifica indipendente (seconda sessione
`analista-bilanciamento`, la stessa che ha validato PS-123/PS-124) ha
dimostrato che la diagnosi di questa card era sbagliata: vedi l'ultima voce
in Decisioni. Il fix è stato revertito integralmente (i due campi
`.tres` sono tornati ai valori originali, lo smoke è stato rimosso). Il
resto della card resta storico, incluso il contesto originale che ha portato
all'apertura — utile a capire cosa NON rifare, non un contratto valido.

## Contesto

`get_experience_reward_scale()`
([scripts/game/enemy_spawn_profile.gd:171-180](../../../scripts/game/enemy_spawn_profile.gd#L171-L180))
calcola `get_spawn_interval(t) / get_progression_reference_spawn_interval(t)
× 1.5`. Le due curve al numeratore e denominatore non sono proporzionali: la
curva reale tocca il pavimento a `t=160s`
(`base_spawn_interval=0.35`, `min_spawn_interval=0.07`,
`spawn_acceleration=0.00175`), quella di riferimento a `t=300s`
(`progression_reference_min_spawn_interval=0.25`,
`progression_reference_spawn_acceleration=0.0025`,
[data/spawn_profiles/default_enemy_spawn_profile.tres:12-15](../../../data/spawn_profiles/default_enemy_spawn_profile.tres)).

Un'analisi quantitativa di bilanciamento (sessione 2026-09-07,
`analista-bilanciamento`) ha calcolato la scala risultante nel tempo:

| t | 0:00 | 1:00 | 2:00 | 2:40 | 4:00 | 5:00+ |
|---|---|---|---|---|---|---|
| XP/kill | 0.525 | 0.432 | 0.300 | **0.175** | 0.263 | 0.420 |

Per un giocatore limitato dal proprio DPS (la condizione normale dopo 2:00,
dove servono ~318 HP/s contro i ~140 nominali di una build media), HP e XP
medi per corpo restano quasi costanti: l'XP/s segue quindi direttamente
questa scala. Il minimo assoluto cade a **2:40**, 40 secondi dopo il primo
Boss (`boss_thresholds_seconds=[120]`) — il momento di massimo bisogno di
potenza — e la scala non torna mai al valore di 1:00. È un anti-recupero
involontario: chi resta indietro guadagna meno XP, quindi meno carte, quindi
resta più indietro.

## Comportamento atteso

La scala di ricompensa XP resta costante lungo tutta la curva late-run
(entro una tolleranza numerica minima), cosicché l'XP/s per un giocatore
saturo sul proprio DPS segua linearmente la densità nemica invece di
attraversare un minimo a metà run.

## Criteri di accettazione

- [x] `get_experience_reward_scale()` restituisce un valore costante (entro
      1e-4) per qualunque `t` lungo l'intera curva late-run, invece della
      curva a V attuale che tocca il minimo a `t≈160s`.
- [x] Il valore costante coincide con quello attuale a `t=0` (`0.525`), così
      la progressione iniziale della run non cambia percettibilmente.
- [x] Nessuna modifica a `base_spawn_interval`, `min_spawn_interval`,
      `spawn_acceleration` (la pressione nemica, oggetto di
      [PS-123](./PS-123-ricalibra-hp-danno-archetipi-nemici-post-ps076.md)/[PS-124](./PS-124-eventi-ondata-che-riducono-la-pressione.md),
      resta invariata da questa card).
- [x] I soli campi toccati sono `progression_reference_spawn_acceleration` e
      `progression_reference_min_spawn_interval` (valori usati esattamente
      come suggerito dal report: `0.0025→0.005` e `0.25→0.20`).

## Ambito

- `data/spawn_profiles/default_enemy_spawn_profile.tres`: solo i due campi
  di riferimento progressione.

Non toccare:

- `base_spawn_interval`, `min_spawn_interval`, `spawn_acceleration` e i pesi
  archetipo (pressione nemica);
- `scripts/game/enemy_spawner.gd` oltre al punto di lettura già esistente
  della scala.

## Verifica

**Superata da SCARTATA.** Lo smoke `tests/unit/test_ps125_xp_scale_invariance.gd`
è stato rimosso insieme al revert: verificava un'invarianza (`scale`
costante) che non è mai stata il problema reale — vedi ultima voce in
Decisioni. Nessun sostituto: il comportamento del reddito XP/s è tornato
quello pre-card, già corretto per costruzione (vedi Decisioni).

## Gate manuali

Non pertinenti: nessuna modifica resta applicata da questa card.

## Decisioni

- **2026-09-07 — Aperta da un'analisi di bilanciamento quantitativa**, non
  da una segnalazione soggettiva. I valori della tabella sono calcolati dal
  report della sessione `analista-bilanciamento` del 2026-09-07 sulle due
  curve reali dichiarate nel `.tres` di produzione.
- **2026-09-07 — Perché esattamente `0.005`/`0.20` danno una costante
  esatta, non solo approssimata.** Il rapporto fra le due rampe lineari
  (`0.00175/0.005 = 0.35`) era già uguale al rapporto iniziale
  (`0.35/1.0 = 0.35`) prima ancora del fix: il problema non era la pendenza,
  era che le due curve toccano il proprio pavimento in istanti diversi
  (`t=160s` per quella reale, `t=300s` per quella di riferimento con i
  valori vecchi). Scegliendo `0.20` in modo che
  `(1.0-0.20)/0.005 = 160s` — lo stesso istante — le due curve diventano
  proporzionali su tutto il dominio, prima e dopo il pavimento, non solo
  nella parte lineare iniziale. Verificato analiticamente e confermato dal
  test (`get_experience_reward_scale` costante entro `1e-4` a
  `t ∈ {0, 60, 160, 300, 600}`).
- **2026-09-07 — Correzione minima proposta, non imposta.** Il report
  propone due campi specifici; se in implementazione questi introducono un
  effetto collaterale indesiderato sul ritmo dei level-up, la card autorizza
  di dichiarare valori diversi purché il criterio di costanza resti
  soddisfatto.
- **2026-09-07 — SCARTATA: la diagnosi era sbagliata.** Una riverifica
  indipendente ha mostrato che `get_experience_reward_scale()` si scompone
  in `get_spawn_interval(t) / get_progression_reference_spawn_interval(t) ×
  1.5`, e il **reddito XP al secondo** di un giocatore che uccide a ritmo
  costante è `xp_per_evento × 1.5 / get_progression_reference_spawn_interval(t)`
  — il termine `get_spawn_interval(t)` si semplifica via, quindi
  **non dipende mai dalla curva di spawn reale** ed era già monotono
  crescente per costruzione, prima ancora di questa card. Il "crollo del
  59%" della card era sul valore **per singola uccisione**, che scende
  perché la cadenza sale — esattamente l'effetto compensativo voluto dal
  meccanismo (commento originale del codice: "conservare il ritmo XP quando
  cambia la densità"), non un difetto.
  Il fix applicato aveva invece **cambiato il pacing reale**: il reddito
  XP/s anticipava il proprio plateau da 300s a 160s e lo alzava del 25%,
  con la copertura DPS-vs-pressione-nemica a 5:00 che saliva dal 111% al
  246% (tetto DPS di catalogo raggiunto a ~7' invece di ~10'). Lo smoke
  chiuso (`scale` costante entro 1e-4) era vero ma misurava la grandezza
  sbagliata: non il reddito XP/s che la card doveva correggere.
  **Revert**: `progression_reference_min_spawn_interval` e
  `progression_reference_spawn_acceleration` tornano a `0.25`/`0.0025`.
  Nessun'altra card di questo batch dipendeva dal fix.

## Documenti sincronizzati

- [x] `docs/systems-difficulty.md`: rimossa la nota sul fix, sostituita da
      una nota che spiega perché il reddito XP/s era già corretto e perché
      la card è stata scartata.

## Note

Il report segnala questo come "la correzione più piccola in assoluto — due
campi — per l'impatto più subdolo": nessun playtest isola facilmente questo
problema, perché si legge come "a due minuti mi blocco" invece che come un
difetto della curva di ricompensa.
