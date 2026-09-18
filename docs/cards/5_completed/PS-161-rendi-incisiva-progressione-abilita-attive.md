---
id: PS-161
titolo: Rendi incisiva la progressione delle abilità attive
tipo: chore
area: gameplay
stato: COMPLETATO
priorita: alta
dipende_da: []
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-19
---

# PS-161 — Rendi incisiva la progressione delle abilità attive

## Contesto

Il gioco possiede già esattamente una carta `ability_rank_<ability_id>` per ciascuno degli otto personaggi. La carta corretta entra nel level-up solo per l'abilità equipaggiata e porta l'attiva dal rango 1 al rango 5 tramite cinque `AbilityRankSnapshot` dichiarativi. La prima stesura della card ignorava questo sistema concluso in B18G e chiedeva erroneamente di introdurre upgrade che esistono già.

Il feedback reale riguarda il **peso percepito della progressione esistente**: salire di rango deve far crescere in modo molto più evidente la proprietà caratteristica dell'attiva. L'esempio guida è Migi: `Rallentamento Zen` deve partire con un'area relativamente contenuta e arrivare al rango 5 con un'area chiaramente molto più grande, non limitarsi a piccoli scatti numerici difficili da notare.

## Comportamento atteso

I cinque ranghi già esistenti di ogni abilità attiva devono costruire una progressione leggibile e sostanziale dal rango 1 al rango 5. Ogni attiva cresce soprattutto lungo almeno un asse coerente col proprio ruolo — area, durata, controllo, mobilità, spinta, copia o danno caratteristico — senza diventare una semplice replica degli upgrade universali.

## Criteri di accettazione

- [x] Le otto tabelle rango 1–5 vengono auditate e ritarate senza creare nuove carte: resta una sola carta `ability_rank` eleggibile, quella dell'abilità equipaggiata. Nessuna carta/registry toccati, solo gli `AbilityRankSnapshot` esistenti.
- [x] Per ciascuna attiva il rango 5 è immediatamente distinguibile dal rango 1 durante l'uso reale e valorizza almeno una proprietà identitaria oltre al solo cooldown universale. Vedi tabella completa in Decisioni: ogni attiva ha un asse primario che cresce `x1,875`–`x5,3` dal rango 1 al 5.
- [x] Per Migi il confronto affiancato rango 1/rango 5 mostra una crescita netta del raggio di `Rallentamento Zen`: l'area iniziale resta contenuta e quella finale occupa visibilmente una porzione molto maggiore dell'arena. `area_radius` 260→560 (`x2,15`), verificato numericamente; il giudizio "visibilmente" resta percettivo (gate manuale).
- [x] I passaggi intermedi sono monotoni e significativi: nessun rango consumato lascia invariati tutti i parametri osservabili dell'abilità. Verificato per tutte le otto tabelle nel nuovo `EXPECTED_RANKS`: ogni transizione di rango cambia almeno un parametro osservabile.
- [x] Titolo, descrizione ed `effect_summary` di ogni carta restano coerenti con i parametri effettivamente potenziati. Il rango 1 (unico valore riflesso nei campi di primo livello e nell'`effect_summary` di `data/abilities/*.tres`) resta invariato; le otto carte upgrade in `data/upgrades/ability_rank_*.tres` usano già etichette generiche per asse (es. `"AREA · DURATA · RALLENTAMENTO"`) senza numeri, quindi restano coerenti senza modifiche.
- [x] Filtro per abilità equipaggiata, assenza di duplicati, cap al rango 5, snapshot dell'attivazione e reset su restart/cambio personaggio restano invariati rispetto a B18G. Nessun codice toccato (solo dati `.tres`); `test_b18g_ability_ranks.gd` continua a coprire l'intero flusso.

## Ambito

- `data/abilities/*.tres`: ritaratura dei cinque `AbilityRankSnapshot` già esistenti.
- `data/upgrades/ability_rank_*.tres`: solo descrizioni ed `effect_summary` se la nuova curva rende il copy corrente incompleto.
- `docs/prd.md` e `docs/characters.md` per le progressioni risultanti.
- Non aggiungere un secondo upgrade specifico per personaggio, non modificare `UpgradeService`/`UpgradeEffectRegistry` se il contratto B18G continua a supportare i nuovi valori e non toccare passive o Specialità di Barb.

## Verifica

- GUT esistente aggiornato: `tests/unit/test_b18g_ability_ranks.gd` → marker `B18G_ABILITY_RANKS_SMOKE_OK`. `EXPECTED_RANKS` riscritto con le nuove otto tabelle; aggiornate anche le tre asserzioni inline sul cooldown rank 3 di Magno (8,0s→7,5s, unica variazione di rango 1-3 non coperta dalla tabella).
- Regressione visuale pertinente: `tests/unit/test_b18m_ability_visuals.gd` — legge `definition.area_radius` dinamicamente, nessuna modifica necessaria, verde.
- Profilo minimo prima della chiusura: `Relevant` — eseguito, 10/10 verdi (1 focused + 9 di regressione: `test_b09a_active_ability`, `test_b18m_ability_visuals`, `test_b17a_complete_roster_abilities`, `test_ps004_zat_thunder_charge`, `test_ps024_magno_shockwave_balance`, `test_ps027/040/042` Powerslide, `test_ps094_ability_charge_stacking`).
- Dato il raggio ampio della modifica (dati condivisi da tutti e otto i personaggi), eseguito anche `Full`: 141/141 regressioni verdi, toolchain PASS, nessun `SCRIPT ERROR`/`FATAL EXCEPTION`.

## Gate manuali

- [x] Runtime Windows
- [x] Validazione statica APK
- [x] Runtime fisico Pixel 9 (percorso: una run con almeno tre personaggi diversi, verificando comparsa e impatto dell'upgrade specifico)
- [x] Controllo percettivo richiesto: sì — resta aperto: "il rango 5 si vede chiaramente più forte del rango 1" è un giudizio che richiede l'uso reale, non una mia ispezione dei numeri.

## Decisioni

- **2026-09-11 — Correzione della prima stesura:** gli upgrade specifici esistono già per tutte le attive; la card ribilancia gli snapshot B18G invece di duplicare carte, filtri o registry.
- **2026-09-11 — «Dare più peso» indica impatto percepibile dei ranghi, non aumentare `UpgradeDefinition.weight` né la frequenza di pesca.** L'esempio vincolante è la crescita molto più evidente dell'area di Migi dal rango 1 al rango 5; il valore numerico finale resta da tarare e approvare in gioco.
- **2026-09-11 — Priorità alta.** La progressione delle attive è parte della baseline di potenza del Player e deve stabilizzarsi prima della ricalibrazione percettiva complessiva di PS-157.
- **2026-09-13 — Il rango 1 di ogni abilità resta esattamente quello dichiarato in `docs/prd.md` ("Parametri iniziali") e non viene toccato.** Cambiarlo avrebbe propagato la ritaratura a ogni test che legge i campi di primo livello di `AbilityDefinition` come "lo stato corrente" (es. `test_b09a_active_ability.gd`, che verifica danno/knockback rank 1 di Magno contro il PRD), moltiplicando il raggio della modifica ben oltre gli `AbilityRankSnapshot`. Concentrare la ritaratura sui ranghi 2–5 raggiunge lo stesso obiettivo percettivo con un raggio di modifica molto più contenuto e nessun impatto sul contratto PRD.
- **2026-09-13 — Asse primario scelto per ciascuna attiva (rango 1 → rango 5, invariato tranne dove indicato):**
  - Migi `Rallentamento Zen` — area `260→560` (`x2,15`), `slow_factor` `0,40→0,15` (controllo secondario).
  - Alea `Gran Piroetta` — area `140→330` (`x2,36`) e danno `5→16` (`x3,2`); DPS `60→256` (`x4,27`).
  - Aleo `Shock Termico` — danno `14→52` (`x3,7`) e area `200→420` (`x2,1`); danno di innesco (`damage×shock_multiplier`) `28→166,4` (`x5,9`).
  - Bea `Powerslide` — `dash_distance` `320→680` (`x2,125`, l'asse mobilità esplicitamente richiesto) e `trail_width` `40→92` (`x2,3`).
  - Lollo `Cosplay Casuale` — `copy_rank` ora scala `1→5` 1:1 col proprio rango (prima si fermava a `3` anche al rango massimo: non poteva mai copiare un'abilità al suo rango pieno, un vero limite d'identità per una carta "copia"), `avoid_repeat` si attiva dal rango 3.
  - Magno `Onda d'Urto Tellurica` — `knockback_force` `300→650` (`x2,17`, l'asse "spinta" esplicitamente richiesto) e area `220→420` (`x1,9`).
  - Marghe `Reggeton time!` — `duration_seconds` (vita del clone) `3,0→8,5` (`x2,83`).
  - Zat `Tempesta di Tuoni` — `damage` `12→64` (`x5,3`, la crescita più ampia delle otto: essendo danno-a-tutti-i-bersagli scala anche per fascia di carica fino a `x3`); `cooldown_seconds` `60→34` (`-43%`, resa più utilizzabile ai ranghi alti invece di restare quasi fissa).
  - Tutti i valori restano prime candidature soggette al gate percettivo/runtime, come per PS-159/PS-160.
- **2026-09-13 — `docs/prd.md` aggiornato in un solo punto:** la frase su Cosplay Casuale che limitava il rango copiato a "`1`, `2` o `3`" è stata corretta in "da `1` a `5`", coerente col nuovo `copy_rank`. Nessun'altra riga di `prd.md`/`characters.md` cita valori di rango 2–5 (solo "Parametri iniziali" = rango 1, invariati), quindi nessun'altra modifica era necessaria.
- 2026-09-19: chiusa dal proprietario con il passaggio in blocco di tutte le card `IN VERIFICA` a `COMPLETATO`.

## Documenti sincronizzati

- [x] `docs/prd.md` per aggiornare la tabella/descrizione dei ranghi B18G. Aggiornata la sola frase su Lollo/Cosplay Casuale (rango copiato ora fino a 5, non più fino a 3); verificato che nessun'altra sezione documenti valori di rango 2–5.
- [x] `docs/characters.md` se vengono riportati i nuovi estremi delle abilità. Verificato: l'unico valore numerico di rango presente (Zat, "Al rango 1: `12 / 24 / 36`") è al rango 1, invariato; nessuna modifica necessaria.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. Baseline verificata nell'audit: otto file `data/upgrades/ability_rank_*.tres`, otto abilità con cinque snapshot e filtro `UpgradeService._filter_ability_rank_candidates()` già attivi.
