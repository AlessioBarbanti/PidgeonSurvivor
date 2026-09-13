---
id: PS-161
titolo: Rendi incisiva la progressione delle abilità attive
tipo: chore
area: gameplay
stato: PRONTO
priorita: alta
dipende_da: []
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-11
---

# PS-161 — Rendi incisiva la progressione delle abilità attive

## Contesto

Il gioco possiede già esattamente una carta `ability_rank_<ability_id>` per ciascuno degli otto personaggi. La carta corretta entra nel level-up solo per l'abilità equipaggiata e porta l'attiva dal rango 1 al rango 5 tramite cinque `AbilityRankSnapshot` dichiarativi. La prima stesura della card ignorava questo sistema concluso in B18G e chiedeva erroneamente di introdurre upgrade che esistono già.

Il feedback reale riguarda il **peso percepito della progressione esistente**: salire di rango deve far crescere in modo molto più evidente la proprietà caratteristica dell'attiva. L'esempio guida è Migi: `Rallentamento Zen` deve partire con un'area relativamente contenuta e arrivare al rango 5 con un'area chiaramente molto più grande, non limitarsi a piccoli scatti numerici difficili da notare.

## Comportamento atteso

I cinque ranghi già esistenti di ogni abilità attiva devono costruire una progressione leggibile e sostanziale dal rango 1 al rango 5. Ogni attiva cresce soprattutto lungo almeno un asse coerente col proprio ruolo — area, durata, controllo, mobilità, spinta, copia o danno caratteristico — senza diventare una semplice replica degli upgrade universali.

## Criteri di accettazione

- [ ] Le otto tabelle rango 1–5 vengono auditate e ritarate senza creare nuove carte: resta una sola carta `ability_rank` eleggibile, quella dell'abilità equipaggiata.
- [ ] Per ciascuna attiva il rango 5 è immediatamente distinguibile dal rango 1 durante l'uso reale e valorizza almeno una proprietà identitaria oltre al solo cooldown universale.
- [ ] Per Migi il confronto affiancato rango 1/rango 5 mostra una crescita netta del raggio di `Rallentamento Zen`: l'area iniziale resta contenuta e quella finale occupa visibilmente una porzione molto maggiore dell'arena.
- [ ] I passaggi intermedi sono monotoni e significativi: nessun rango consumato lascia invariati tutti i parametri osservabili dell'abilità.
- [ ] Titolo, descrizione ed `effect_summary` di ogni carta restano coerenti con i parametri effettivamente potenziati.
- [ ] Filtro per abilità equipaggiata, assenza di duplicati, cap al rango 5, snapshot dell'attivazione e reset su restart/cambio personaggio restano invariati rispetto a B18G.

## Ambito

- `data/abilities/*.tres`: ritaratura dei cinque `AbilityRankSnapshot` già esistenti.
- `data/upgrades/ability_rank_*.tres`: solo descrizioni ed `effect_summary` se la nuova curva rende il copy corrente incompleto.
- `docs/prd.md` e `docs/characters.md` per le progressioni risultanti.
- Non aggiungere un secondo upgrade specifico per personaggio, non modificare `UpgradeService`/`UpgradeEffectRegistry` se il contratto B18G continua a supportare i nuovi valori e non toccare passive o Specialità di Barb.

## Verifica

- GUT esistente da aggiornare: `tests/unit/test_b18g_ability_ranks.gd` → marker `B18G_ABILITY_RANKS_SMOKE_OK`; regressione visuale pertinente: `tests/unit/test_b18m_ability_visuals.gd`.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: una run con almeno tre personaggi diversi, verificando comparsa e impatto dell'upgrade specifico)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-09-11 — Correzione della prima stesura:** gli upgrade specifici esistono già per tutte le attive; la card ribilancia gli snapshot B18G invece di duplicare carte, filtri o registry.
- **2026-09-11 — «Dare più peso» indica impatto percepibile dei ranghi, non aumentare `UpgradeDefinition.weight` né la frequenza di pesca.** L'esempio vincolante è la crescita molto più evidente dell'area di Migi dal rango 1 al rango 5; il valore numerico finale resta da tarare e approvare in gioco.
- **2026-09-11 — Priorità alta.** La progressione delle attive è parte della baseline di potenza del Player e deve stabilizzarsi prima della ricalibrazione percettiva complessiva di PS-157.

## Documenti sincronizzati

- [ ] `docs/prd.md` per aggiornare la tabella/descrizione dei ranghi B18G.
- [ ] `docs/characters.md` se vengono riportati i nuovi estremi delle abilità.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. Baseline verificata nell'audit: otto file `data/upgrades/ability_rank_*.tres`, otto abilità con cinque snapshot e filtro `UpgradeService._filter_ability_rank_candidates()` già attivi.
