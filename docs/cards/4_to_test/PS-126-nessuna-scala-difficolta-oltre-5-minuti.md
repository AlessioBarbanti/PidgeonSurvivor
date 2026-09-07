---
id: PS-126
titolo: Introduci una curva di pressione oltre il minuto 5 (Boss ricorrente trivializzato)
tipo: feat
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: [PS-055]
origine:
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-126 — Introduci una curva di pressione oltre il minuto 5 (Boss ricorrente trivializzato)

## Contesto

Un'analisi quantitativa di bilanciamento (sessione 2026-09-07,
`analista-bilanciamento`) ha verificato cosa continua a crescere, lato
nemico, dopo il minuto 5 di run:

- `min_spawn_interval` è saturo a `t=160s`
  ([data/spawn_profiles/default_enemy_spawn_profile.tres:7-9](../../../data/spawn_profiles/default_enemy_spawn_profile.tres)).
- Pesi archetipo, `sector_multi` e `spike_chance` sono congelati a
  `late_run_curve_full_seconds=300s`.
- `first_boss.tres:health_max=2400.0` è fisso;
  [scripts/bosses/boss_encounter.gd:167-200](../../../scripts/bosses/boss_encounter.gd#L167-L200)
  `resolve_variant()` cambia solo identità/Signature dell'Evil, mai
  HP/danno/pattern, alle ricorrenze successive
  (`recurring_boss_window_seconds=240s`: Boss a 2:00, 6:00, 10:00...).
- Le carte ripetibili senza tetto di rango
  ([scripts/progression/upgrade_effect_registry.gd:53-62](../../../scripts/progression/upgrade_effect_registry.gd#L53-L62))
  continuano invece a scalare: `meat_fork_damage`/`rapid_fire` saturano al
  rango 12, non al rango 5 tipico delle altre.

Il calcolo del report: al Boss di 2:00 il DPS nominale atteso (~106) rende
un tempo-per-uccidere realistico di 50-80s (Boss + coda residua da
smaltire); al Boss di 6:00 (~400 DPS) scende a 6s; al Boss di 10:00 (~650
DPS) a 3.7s. Con le sole carte di catalogo al tetto il DPS teorico arriva a
758; con le Specialità d'arma al massimo (multishot 3 + pierce 4), a 5756 —
15× il flusso nemico in ingresso.

**Decisione presa (PS-055, 2026-09-07): le run di Sopravvivenza sono
endless, senza vittoria.** Questo risolve la domanda che teneva questa card
`DA DEFINIRE`: non c'è una fine da raggiungere, quindi serve una leva di
pressione che continui a crescere oltre i 5 minuti, coerente con
l'obiettivo dichiarato "sopravvivere il più a lungo possibile" — altrimenti
la caccia al record smette di essere una sfida crescente.

## Comportamento atteso

Oltre `late_run_curve_full_seconds` (300s), la pressione nemica continua a
crescere invece di restare piatta: sia i nemici ordinari (piccione base e
archetipi) sia il Boss ricorrente diventano gradualmente più duri con il
tempo/le ricorrenze, mantenendo il ritmo di sfida coerente con
l'obiettivo "sopravvivere il più a lungo possibile" invece di rendere la
run trivialmente vincibile dopo pochi minuti.

## Criteri di accettazione

- [x] `EnemySpawnProfile` espone `post_curve_growth_per_minute` e
      `get_post_curve_pressure_multiplier(run_time)`, che restituisce `1.0`
      per `run_time ≤ late_run_curve_full_seconds` e cresce linearmente oltre
      quella soglia.
- [x] Il moltiplicatore si applica a `health_max` e `contact_damage` di ogni
      nemico spawnato (piccione base incluso, non solo gli archetipi) nel
      punto comune di finalizzazione dello spawn
      (`scripts/game/enemy_spawner.gd:_finalize_spawned_enemy` →
      `_apply_post_curve_pressure`), non nei singoli `.tres` di archetipo.
- [x] A `run_time ≤ late_run_curve_full_seconds` il comportamento è
      identico a oggi (moltiplicatore `1.0`): nessuna regressione sulla
      finestra 0-5 minuti già oggetto di
      [PS-123](./PS-123-ricalibra-hp-danno-archetipi-nemici-post-ps076.md)/[PS-124](./PS-124-eventi-ondata-che-riducono-la-pressione.md)
      (confermato da `Relevant` verde sull'intero batch). [PS-125](../6_rejected/PS-125-scala-xp-costante-lungo-la-curva-late-run.md)
      era nello stesso batch ma è stata scartata: la sua diagnosi era
      sbagliata, vedi la card per i dettagli — non tocca questa.
- [x] `GameDirectorProfile` espone `boss_recurrence_growth_per_occurrence` e
      `get_boss_recurrence_multiplier(schedule_index)`, che restituisce
      `1.0` alla prima occorrenza (`schedule_index=0`) e cresce con le
      ricorrenze successive.
- [x] Il moltiplicatore Boss si applica a `health_max` e `contact_damage`
      del Boss dopo `configure_signature()` in
      `BossEncounter._spawn_boss()` (nuovo `_apply_recurrence_scaling`),
      senza toccare `resolve_variant()` né l'identità/Signature dell'Evil.
- [x] Alla prima occorrenza (`schedule_index=0`) il Boss ha esattamente le
      statistiche dichiarate in `first_boss.tres`: nessuna regressione sul
      primo incontro (verificato dal test con un Boss reale attraverso
      `RunController`/`BossEncounter`).
- [x] **(esteso dopo riverifica, vedi Decisioni)** Il moltiplicatore Boss si
      applica anche al danno della raffica radiale e del colpo mirato
      (`FirstBoss._spawn_radial_volley`/`_execute_targeted_blast`) e al
      danno di ogni Signature Evil (`FirstBoss._spawn_signature_area`,
      composto con l'eventuale carica del Tuono di Evil Zat invece di
      sostituirla). Il moltiplicatore nemici ordinari si applica anche al
      danno del proiettile del tiratore (`RangedEnemy._fire_projectile`),
      tramite il nuovo campo pubblico `BaseEnemy.pressure_multiplier`
      assegnato da entrambe le leve. Senza questo, tiratore/Boss a distanza
      sarebbero rimasti piatti per sempre mentre HP/danno da contatto
      crescevano (finding N2 della riverifica).
- [x] Un test GUT verifica la monotonicità del moltiplicatore ordinario per
      `t ∈ {300, 480, 900}` e della crescita di ricorrenza Boss per
      `schedule_index ∈ {0, 1, 2}`; che un nemico ordinario, un tiratore e
      un Boss reale fatto ricorrere due volte ricevano il moltiplicatore
      atteso su `pressure_multiplier`/`health_max`/`contact_damage`. Più
      diretto della metrica composita "flusso HP/s + tempo-per-uccidere"
      proposta in apertura: verifica i meccanismi separatamente, sulla loro
      reale API pubblica, invece di ricalcolare una stima aggregata dentro
      il test.
- [x] Con i due nuovi moltiplicatori a crescita nulla (`post_curve_growth_per_minute=0.0`/
      `boss_recurrence_growth_per_occurrence=0.0`) il comportamento resta
      bit-per-bit quello pre-PS-126: entrambi i metodi restituiscono `1.0` a
      crescita nulla per costruzione della formula (`1.0 + delta*rate`, mai
      chiamato con `rate` diverso da quello dichiarato). I default scelti
      per il merge sono `0.15`/minuto e `1.2`/ricorrenza (non `0.0`: vedi
      Decisioni), pertinenti alla riga precedente.

## Ambito

- `scripts/game/enemy_spawn_profile.gd`: nuovo parametro e metodo per il
  moltiplicatore post-curva.
- `data/spawn_profiles/default_enemy_spawn_profile.tres`: valore del nuovo
  parametro.
- `scripts/game/enemy_spawner.gd`: applicazione del moltiplicatore in
  `_finalize_spawned_enemy()`, assegnazione a `BaseEnemy.pressure_multiplier`.
- `scripts/actors/base_enemy.gd`: nuovo campo pubblico `pressure_multiplier`.
- `scripts/actors/ranged_enemy.gd`: applicazione del moltiplicatore al
  danno del proiettile in `_fire_projectile()` (esteso dopo riverifica).
- `scripts/game/game_director_profile.gd`: nuovo parametro e metodo per il
  moltiplicatore di ricorrenza Boss.
- `data/director_profiles/default_game_director_profile.tres`: valore del
  nuovo parametro.
- `scripts/bosses/boss_encounter.gd`: applicazione del moltiplicatore in
  `_spawn_boss()`, dopo `configure_signature()`, assegnazione a
  `boss.pressure_multiplier`.
- `scripts/bosses/first_boss.gd`: applicazione del moltiplicatore al danno
  della raffica radiale, del colpo mirato e delle Signature (esteso dopo
  riverifica).
- `scripts/bosses/boss_signature_area.gd`: `_damage_scale` applicato anche
  ai tre modi che prima lo ignoravano (fronte, periodico, due fasi) — fix
  di un'applicazione parziale preesistente, necessario perché il
  moltiplicatore di ricorrenza altrimenti sarebbe rimasto inerte per 5
  Signature su 6 (esteso dopo riverifica, vedi Decisioni).

Non toccare:

- `resolve_variant()` e la scelta identità/Signature dell'Evil;
- i tetti di rango delle carte/Specialità (PS-121) e `late_run_curve_start_seconds`/`late_run_curve_full_seconds`;
- la finestra 0-5 minuti (oggetto di PS-123/PS-124): il moltiplicatore deve
  valere `1.0` fino a `late_run_curve_full_seconds`;
- `RunController` e l'assenza di `VICTORY` in Sopravvivenza (PS-055);
- la carica del Tuono di Evil Zat (`_get_thunder_damage_scale`): si compone
  con il moltiplicatore di ricorrenza, non viene sostituita.

## Verifica

- Smoke: `tests/unit/test_ps126_post_curve_pressure.gd` → marker
  `PS126_POST_CURVE_PRESSURE_SMOKE_OK` — verifica moltiplicatore `1.0` fino
  alla soglia e crescita/monotonicità oltre, applicazione a un nemico
  ordinario e a un tiratore spawnati via `EnemySpawner`
  (`pressure_multiplier`), moltiplicatore Boss `1.0` alla prima occorrenza e
  crescente alle successive, e un Boss reale fatto ricorrere due volte con
  HP e `pressure_multiplier` scalati di conseguenza.
- Profilo minimo prima della chiusura: `Relevant` — eseguito insieme a
  PS-123/PS-124 (stesso batch), 53/53 verdi, nessun `SCRIPT ERROR`/
  `FATAL EXCEPTION` nei log. PS-125 era nello stesso batch alla prima
  esecuzione (54/54) ma è stata scartata dopo, vedi la sua card.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run di almeno 10 minuti con almeno
      due ricorrenze Boss, valutare se la crescita si legge come pressione
      credibile e non come uno scatto improvviso)
- [ ] Controllo percettivo richiesto: sì — i tassi di crescita proposti sono
      un punto di partenza numerico, non un valore finale: la taratura vera
      è percettiva

## Decisioni

- **2026-09-07 — Sbloccata da PS-055.** La domanda che teneva questa card
  `DA DEFINIRE` ("le run devono avere una fine?") è stata risposta: no, le
  run di Sopravvivenza restano endless. Questa card implementa quindi
  l'opzione 1 del ventaglio originale (leva di scala oltre i 5 minuti),
  scartando le opzioni 2 e 3.
- **2026-09-07 — Meccanismo separato per nemici ordinari e Boss.** Un solo
  moltiplicatore temporale per i nemici ordinari (ancorato a
  `late_run_curve_full_seconds`, coerente con le altre curve late-run già
  esistenti) e un moltiplicatore per ricorrenza per il Boss (ancorato a
  `schedule_index`, già usato da PS-006/resolve_variant per la stessa
  numerazione): sono readibili e testabili separatamente, invece di un
  unico coefficiente globale che confonderebbe le due sorgenti di
  pressione.
- **2026-09-07 — Tassi di crescita non fissati qui.** La card impone il
  meccanismo (moltiplicatore configurabile, monotono, disattivabile) ma
  lascia i valori numerici esatti a chi implementa/testa percettivamente:
  bilanciarli male sarebbe un problema quanto non averli, e la taratura fine
  è materia di playtest ripetuto, non di analisi statica.
- **2026-09-07 — Default iniziali: `0.15`/minuto (nemici), `0.6`/ricorrenza
  (Boss).** Non a `0.0`: un meccanismo spento di default lascerebbe il
  problema aritmeticamente ancora aperto (nessuna pressione oltre i 5
  minuti) mentre la card lo dichiarerebbe chiuso. Punto di partenza
  dichiaratamente non tarato.
- **2026-09-07 — Riverifica indipendente (seconda sessione
  `analista-bilanciamento`) e correzioni conseguenti.** Confermato che il
  cablaggio è corretto (ordine di applicazione, nessuna doppia scalatura,
  Boss baseline non accumula fra ricorrenze perché si scala il componente
  non la risorsa condivisa). Due problemi quantitativi trovati e corretti:
  - **Tasso Boss troppo lento.** Il DPS del giocatore cresce ~6.4× dentro
    la sola finestra 2:00→6:00 (prima ricorrenza): nessun moltiplicatore
    lineare per ricorrenza può inseguire una crescita a gradino così
    ripida. A `0.6` il secondo Boss durava 5.4s (1.6 pattern) contro i
    3.4s pre-card: un miglioramento reale ma non un incontro paragonabile
    al primo (20s, 7.5 pattern). **Alzato a `1.2`**: il secondo Boss
    (5280 HP) dura ~7.4s (2.4 pattern) contro un DPS realistico di ~712 a
    quel punto. Ancora non risolve la forma sbagliata della leva (lineare
    contro un gradino), ma sposta la scommessa nella direzione corretta;
    resta soggetto a taratura percettiva.
  - **Danno a distanza mai scalato (N2).** `_apply_post_curve_pressure` e
    `_apply_recurrence_scaling` toccavano solo HP e danno da contatto:
    proiettile del tiratore, raffica radiale, colpo mirato e danno delle
    Signature restavano piatti per sempre. Poiché il tiratore è
    l'archetipo più pesato in late run (`late_run_weight_multiplier=2.5`)
    e il suo colpo è l'unico danno ordinario non schivabile muovendosi,
    lasciarlo piatto mentre gli altri nemici diventano più duri lo rendeva
    proporzionalmente sempre più debole — l'opposto dell'intento della
    card. Esteso `pressure_multiplier` (nuovo campo su `BaseEnemy`) a
    `RangedEnemy._fire_projectile()` e ai tre punti di danno del Boss in
    `first_boss.gd`. Estendendo la copertura è emerso un bug preesistente
    e indipendente: `BossSignatureArea._damage_scale` (usato dalla carica
    del Tuono di Evil Zat) veniva letto solo da `_apply_instant_burst()`,
    non dagli altri tre modi area (fronte, periodico, due fasi) — quindi
    la stessa leva sarebbe rimasta inerte per 5 Signature su 6. Corretto
    nello stesso passaggio perché altrimenti l'estensione a "Signature"
    dichiarata da questo criterio sarebbe stata vera solo sulla carta.
  - **Non toccato**: il danno delle abilità attive del roster giocabile
    (`data/abilities/*.tres`, N6 della riverifica) resta costante e non
    scala con `M(t)`/`weapon_damage_multiplier` — preesistente, fuori
    ambito da questa card, non segnalato come bloccante.

## Documenti sincronizzati

- [x] `docs/systems-difficulty.md`: nota "PS-126 — pressione oltre il
      minuto 5" nella sezione "Soglie Boss e ricorrenza", aggiornata con
      entrambe le leve estese (contatto + a distanza), il tasso Boss `1.2`
      e il gate percettivo ancora aperto.
- [x] `docs/prd.md` — non pertinente: la curva post-5-minuti resta un
      meccanismo di bilanciamento interno (due moltiplicatori dati), non un
      nuovo contratto di prodotto da dichiarare a parte.

## Note

Card sorella: [PS-055](../5_completed/PS-055-filosofia-della-vittoria.md)
(ha fissato la filosofia endless che rende questa card necessaria). Il
report segnala questo come il finding più importante ma anche il più legato
a una decisione di design piuttosto che a una patch pura — la decisione è
ora presa, resta la taratura percettiva dei tassi di crescita.
