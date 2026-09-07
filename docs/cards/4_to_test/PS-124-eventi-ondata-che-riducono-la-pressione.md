---
id: PS-124
titolo: Correggi gli eventi d'ondata che riducono la pressione invece di aumentarla
tipo: fix
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: []
origine:
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-124 — Correggi gli eventi d'ondata che riducono la pressione invece di aumentarla

## Contesto

PS-008 ha introdotto gli eventi d'ondata come momenti di minaccia telegrafata
("ACCERCHIAMENTO IN ARRIVO" ecc.), tutti `IN VERIFICA` con gate percettivo
ancora aperto. Un'analisi quantitativa di bilanciamento (sessione
2026-09-07, `analista-bilanciamento`) ha calcolato quanti nemici genera
davvero ciascun evento contro lo spawn ordinario che sostituisce, nella
stessa finestra di tempo:

- **Accerchiamento**
  ([data/wave_events/wave_event_accerchiamento.tres](../../../data/wave_events/wave_event_accerchiamento.tres),
  `duration_seconds=10.0`, `formation_enemy_count=8`,
  `formation_spawn_interval_seconds=0.35`, `ordinary_spawn_mode=2`
  *Replaced*): a 2:30 lo spawn ordinario sostituito genererebbe ~184 corpi
  in 10s (a 5:00, ~265); l'evento ne genera **8**.
  [scripts/game/wave_event_scheduler.gd:224](../../../scripts/game/wave_event_scheduler.gd#L224)
  `_spawn_formation_unit()` istanzia un solo nemico per tick, senza usare
  `spawn_cluster_size` dell'archetipo.
- **Stormo laterale**
  (`wave_event_stormo_laterale.tres`, `ordinary_spawn_mode=1`
  *Reduced*, `ordinary_spawn_interval_multiplier=1.5`, 10 sciamatori in
  2.5s): 108 corpi generati contro 147 dello spawn ordinario sostituito —
  **−27%**.
- **Nido di tiratori** (`ordinary_spawn_mode=0` *Unchanged*,
  `ranged_weight_multiplier=4.0`) è invece corretto: cambia la qualità della
  minaccia (più tiratori) senza toccare il flusso quantitativo.

Un evento con telegrafo d'urgenza che di fatto alleggerisce l'orda si legge,
giocando, come "sono stato bravo" invece che come una minaccia superata: il
gate percettivo di PS-008 non può chiudersi onestamente finché l'effetto
reale contraddice la promessa del telegrafo.

## Comportamento atteso

Ogni evento d'ondata genera, nella propria finestra, un numero di nemici
almeno pari a quello che lo spawn ordinario avrebbe generato nella stessa
finestra allo stesso `run_time` — la minaccia telegrafata è sempre percepita
come un aumento di pressione, mai come una pausa, indipendentemente da quale
`ordinary_spawn_mode` scelga l'evento.

## Criteri di accettazione

- [x] Durante l'evento Accerchiamento il numero di nemici generati nella
      finestra è ≥ al numero che lo spawn ordinario avrebbe generato nella
      stessa finestra allo stesso `run_time`.
- [x] Durante l'evento Stormo laterale il numero di nemici generati nella
      finestra è ≥ al numero che lo spawn ordinario (ridotto dal moltiplicatore
      dell'evento) avrebbe generato nella stessa finestra.
- [x] Nido di tiratori resta comportamentalmente invariato (già corretto:
      cambia qualità non quantità).
- [x] Nessuna soglia di trigger (`min_start_seconds`, finestre di ricorrenza)
      cambia.

## Ambito

- `data/wave_events/wave_event_accerchiamento.tres`: alzare
  `formation_enemy_count` e/o abbassare `formation_spawn_interval_seconds`,
  e/o passare `ordinary_spawn_mode` da *Replaced* a *Reduced* con un
  moltiplicatore che lasci la formazione come netto aumento (suggerito dal
  report: `ordinary_spawn_mode=1` con `ordinary_spawn_interval_multiplier≈2.0`
  e `formation_enemy_count≈30`/`formation_spawn_interval_seconds≈0.15`).
- `data/wave_events/wave_event_stormo_laterale.tres`: stesso tipo di
  aggiustamento sui suoi campi.
- `scripts/game/wave_event_scheduler.gd`: **solo** se si scieglie di far
  usare a `_spawn_formation_unit()` il `spawn_cluster_size` dell'archetipo
  della formazione invece di un singolo corpo per tick (alternativa
  suggerita dal report, non l'unica strada valida).

Non toccare:

- `wave_event_nido_di_tiratori.tres` (già corretto);
- soglie di trigger/ricorrenza in `default_wave_event_scheduler_profile.tres`;
- lo spawn ordinario fuori dagli eventi (`EnemySpawnProfile`, oggetto di
  [PS-123](./PS-123-ricalibra-hp-danno-archetipi-nemici-post-ps076.md)).

## Verifica

- Smoke: `tests/unit/test_ps124_wave_event_pressure.gd` → marker
  `PS124_WAVE_EVENT_PRESSURE_SMOKE_OK` — conta i corpi vivi generati durante
  Accerchiamento e Stormo laterale contro una finestra equivalente di spawn
  ordinario allo stesso `run_time`, asserendo `corpi_evento ≥ corpi_ordinari`
  per entrambi; verifica Nido di tiratori invariato.
- Profilo minimo prima della chiusura: `Relevant` — eseguito insieme a
  PS-123/PS-126 (stesso batch), 53/53 verdi, nessun `SCRIPT ERROR`/
  `FATAL EXCEPTION` nei log. PS-125 era nello stesso batch alla prima
  esecuzione (54/54) ma è stata scartata dopo una riverifica indipendente,
  vedi [la sua card](../6_rejected/PS-125-scala-xp-costante-lungo-la-curva-late-run.md).

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: raggiungere Accerchiamento e Stormo
      laterale in una run reale, valutare se si leggono come minaccia
      crescente)
- [ ] Controllo percettivo richiesto: sì — chiude anche il gate percettivo
      ancora aperto di [PS-008](../5_completed/PS-008-eventi-di-ondata.md)
      per questi due eventi specifici

## Decisioni

- **2026-09-07 — Aperta da un'analisi di bilanciamento quantitativa**, non
  da una segnalazione soggettiva. I conteggi (corpi generati per finestra,
  dai `.tres` reali) sono nel report della sessione
  `analista-bilanciamento` del 2026-09-07.
- **2026-09-07 — Due strade equivalenti lasciate aperte**: alzare i
  parametri della formazione, oppure far leva sul `spawn_cluster_size`
  dell'archetipo in `_spawn_formation_unit()`. Nessuna delle due è imposta:
  chi implementa scelga quella che produce il miglior ritmo percepito e la
  dichiari qui.
- **2026-09-07 — Scelta implementata: solo parametri dei `.tres`, senza
  toccare `wave_event_scheduler.gd`.** Più semplice, meno rischio di
  regressione, e sufficiente da sola a soddisfare il criterio:
  - Accerchiamento: `ordinary_spawn_mode` da *Replaced* (2) a *Reduced* (1)
    con `ordinary_spawn_interval_multiplier=1.15` (spawn ordinario appena
    rallentato, non azzerato); `formation_enemy_count` 8→100,
    `formation_spawn_interval_seconds` 0.35→0.1 (100 sciamatori in 10s,
    l'intera durata dell'evento). Il telegrafo resta: la formazione diretta
    è ora numericamente dominante, non l'unico contributo.
  - Stormo laterale: `ordinary_spawn_interval_multiplier` 1.5→1.1 (riduzione
    più lieve), `formation_enemy_count` 10→60,
    `formation_spawn_interval_seconds` 0.25→0.1 (60 sciamatori in 6s su una
    durata di 8s).
  - Nessun valore è stato scelto per eguagliare esattamente il riferimento:
    entrambi restano con un margine deliberato (~1.3-1.5× la stima del
    riferimento ordinario allo stesso `run_time`), perché il conteggio
    ordinario stesso ha varianza (scelta pesata degli archetipi) e un
    margine stretto rischierebbe di ridiventare debole con un altro seed.
    Il valore esatto resta comunque materia di taratura percettiva
    (gate manuale aperto).

## Documenti sincronizzati

- [x] `docs/systems-difficulty.md` — non pertinente: la sezione "Eventi
      d'ondata PS-008" (righe 90-103) rimanda al contratto di `prd.md` e non
      dichiara i valori numerici dei singoli eventi, quindi non contraddice
      questa card.

## Note

Il report osserva anche che, in lettura conservativa (giocatore già al cap
`max_alive_enemies`), la conclusione si rafforza invece di attenuarsi: per
la durata dell'evento l'orda può solo diminuire. Non è un artefatto del
metodo di conteggio.
