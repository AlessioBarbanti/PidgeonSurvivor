---
id: PS-174
titolo: Il clone di Evil Marghe spara e si accumula se non ucciso
tipo: feat
area: gameplay
stato: COMPLETATO
priorita: media
dipende_da: []
origine: conversazione del proprietario 2026-09-13
creato: 2026-09-13
aggiornato: 2026-09-19
---

# PS-174 — Il clone di Evil Marghe spara e si accumula se non ucciso

## Contesto

Oggi la Signature *Reggaeton time!* di Evil Marghe genera un solo clone
(`BossDecoy`) alla volta, senza danno da contatto e senza attacco a
distanza: è puro bersaglio-esca per l'auto-targeting del Player. Il
proprietario lo giudica poco minaccioso ("un clone spawnato lontano non fa
paura"): se il clone spara davvero e, non uccidendolo, il Boss può
accumularne altri, ignorarlo diventa una scelta rischiosa invece di un
comportamento senza conseguenze.

## Comportamento atteso

Ogni clone attivo spara periodicamente al Player finché è vivo o scade,
riusando lo stesso schema telegraph→proiettile già validato per i nemici a
distanza. Il clone resta immobile (non insegue). Se la Signature viene
rieletta mentre uno o più cloni precedenti sono ancora vivi, il Boss ne
genera uno aggiuntivo invece di essere bloccato dal vincolo attuale "un
clone alla volta", fino a un tetto massimo configurabile: superato il
tetto, la Signature non aggiunge altri cloni finché uno non scade o muore.

## Criteri di accettazione

- [x] Ogni clone spara periodicamente al Player riusando lo schema
      telegraph→`BossProjectile` già usato da `RangedEnemy`, non un nuovo
      canale di danno ostile parallelo. Verificato: dopo l'intervallo
      (`2,5s`) e il telegraph (`0,8s`) dichiarati nei dati, il clone produce
      un `BossProjectile` tracciato (`get_active_projectile_count() > 0`).
- [x] Il clone resta immobile: solo il comportamento d'attacco cambia,
      il movimento resta quello attuale (nessun inseguimento). Verificato:
      la posizione resta invariata durante l'intero ciclo d'attacco.
- [x] Se la Signature viene rieletta con un clone precedente ancora vivo, il
      Boss genera un clone aggiuntivo invece di essere bloccato dal vincolo
      "un solo clone alla volta", fino a un tetto massimo configurabile di
      cloni simultanei; oltre il tetto la Signature non aggiunge altri
      cloni finché uno non scade/muore. Verificato fino al tetto dichiarato
      nei dati (`max_active_clones: 3`): una quarta rielezione non produce
      un quarto clone.
- [x] Uccidere un clone lo rimuove immediatamente, senza respawn automatico
      dello stesso, coerente con il sistema HP/morte esistente di
      `BaseEnemy`. Verificato con `take_damage()` letale su un clone
      specifico: il conteggio scende immediatamente, gli altri restano.
- [x] Nessun clone sopravvive a un restart o alla fine dell'encounter Boss.
      Comportamento ereditato invariato da `clear_signature_runtime()`
      (ora itera una lista invece di un singolo riferimento), coperto dal
      test di cleanup preesistente `test_boss_death_removes_every_signature_residue`.
- [x] `test_marghe_decoy_diverts_targeting_and_stays_distinguishable`
      (`tests/unit/test_ps006_evil_signature_abilities.gd`) resta verde
      senza riscritture: il caso a singolo clone resta identico.
- [x] (Difetto scoperto durante l'analisi, non nuova funzionalità)
      `first_boss.tscn` e `boss_decoy.tscn` non devono più appartenere al
      gruppo `"enemies"`. Rimosso da entrambi i `.tscn`; vedi Decisioni per
      un secondo difetto correlato scoperto e corretto nello stesso punto.

## Ambito

- `scripts/bosses/boss_decoy.gd`: ora `extends RangedEnemy` invece di
  `BaseEnemy`; `_compute_chase_offset()` e `_compute_separation_velocity()`
  sovrascritti per restare sempre fermo e immune alla respinta PS-171,
  indipendentemente dai parametri ranged; target impostato al Player
  invece che a `null` (necessario al ciclo d'attacco ereditato).
- `scripts/bosses/first_boss.gd`: `_spawn_signature_decoy()` diventa
  multi-istanza con tetto massimo; costruzione di un
  `EnemyArchetypeDefinition` ad-hoc (non caricato da `.tres`) per i
  parametri di tiro letti dalla Signature; `_active_decoy` (singolare)
  diventa una lista, con `get_active_decoy()` mantenuto per compatibilità
  (primo clone vivo) e nuovo `get_active_decoys()`; anche qui
  `_compute_separation_velocity()` sovrascritto per lo stesso motivo.
- `scripts/actors/base_enemy.gd`: cache di `_compute_separation_velocity()`
  (PS-171) resa per-`RunController` invece che globale, con ordinamento
  per `instance_id` prima di sommare (vedi Decisioni, terzo difetto).
- `data/bosses/signatures/evil_marghe_reggaeton_clone.tres`: nuovi
  `effect_parameters` (danno, cadenza, telegraph, velocità/vita/raggio
  proiettile, tetto cloni simultanei).
- `scenes/actors/first_boss.tscn`, `scenes/actors/boss_decoy.tscn`:
  rimozione del gruppo `enemies` (vedi criterio dedicato);
  `boss_decoy.tscn` riceve anche l'assegnazione di `projectile_scene`
  (`res://scenes/combat/boss_projectile.tscn`).
- Non toccare i pattern comuni del Boss (`RADIAL_VOLLEY`, ecc.), il
  telegraph/esecuzione della Signature stessa, o le altre sette Signature
  Evil.

## Verifica

- Nuovo test in `tests/unit/test_ps006_evil_signature_abilities.gd`
  (stessa fixture esistente, stesso file: la funzionalità estende una
  Signature Evil già coperta lì) → marker
  `PS174_EVIL_MARGHE_CLONE_THREAT_SMOKE_OK`. 18/18 test del file verdi.
- Regressione dedicata: `test_marghe_decoy_diverts_targeting_and_stays_distinguishable`
  (stesso file, verde senza modifiche) e
  `tests/unit/test_ps171_enemy_overlap_separation.gd` (verifica
  l'esclusione di Boss/cloni dalla respinta anti-sovrapposizione).
- Profilo minimo prima della chiusura: `Relevant` — eseguito, 15/15 verdi.
  Data l'ampiezza del cambiamento (tocca `base_enemy.gd`, condiviso da ogni
  nemico), eseguito anche `Full` due volte di seguito: 143/143 verdi
  entrambe le volte (142 regressioni + toolchain), nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION`.

## Gate manuali

- [x] Runtime Windows
- [x] Validazione statica APK
- [x] Runtime fisico Pixel 9 (percorso: incontro con Evil Marghe, ignorare
      deliberatamente un clone e osservare l'accumulo)
- [x] Controllo percettivo richiesto: sì

## Decisioni

- **2026-09-13 — Riuso integrale dello schema telegraph→proiettile di
  `RangedEnemy` via ereditarietà (`BossDecoy extends RangedEnemy`) invece
  di duplicare un ciclo d'attacco dedicato.** `EnemyArchetypeDefinition` non
  richiede di essere caricato da `.tres` per alimentare
  `configure_ranged()`: un'istanza costruita a runtime con i soli campi
  `ranged_*` valorizzati dalla Signature è sufficiente, evitando di
  introdurre un secondo formato dati per lo stesso concetto.
- **2026-09-13 — Il clone resta immobile per scelta esplicita, non per
  limite tecnico.** `_compute_chase_offset()` viene sovrascritto per
  restituire sempre zero: il comportamento "sta fermo e spara" è quello
  richiesto, l'ereditarietà da `RangedEnemy` serve solo a riusare il ciclo
  di tiro, non il movimento.
- **2026-09-13 — L'accumulo ha un tetto massimo configurabile, non è
  illimitato.** Senza un tetto, ignorare sistematicamente i cloni
  produrrebbe una crescita di minaccia senza limite superiore, incoerente
  con qualunque bilanciamento; il tetto vive come parametro della
  Signature (`max_active_clones`), non hardcoded.
- **2026-09-13 — Difetto scoperto e corretto in questa card: `"enemies"`
  nel gruppo statico di `first_boss.tscn`/`boss_decoy.tscn` precede PS-171
  ed era innocuo finché nulla interrogava quel gruppo.** PS-171 ha
  introdotto la prima query reale (`base_enemy.gd`, respinta anti-
  sovrapposizione) e ha ereditato involontariamente Boss e clone
  nell'insieme dei nemici respinti-fra-loro, violando il proprio criterio
  "non sposta né rallenta... i Boss". Corretto qui perché scoperto
  analizzando `boss_decoy.tscn` per questa card, e perché lasciarlo aperto
  comprometterebbe visibilmente il nuovo comportamento ad accumulo (Boss e
  cloni si spingerebbero a vicenda).
- **2026-09-13 — Secondo difetto correlato, scoperto verificando il primo:
  rimuovere Boss/clone dal gruppo `"enemies"` li rende invisibili come
  vicini per gli altri, ma non li rende immuni dall'*essere* respinti da
  nemici comuni ammassati contro di loro.** `_compute_separation_velocity()`
  di `BaseEnemy` viene comunque chiamata per ogni nemico che processa
  fisica, Boss e `BossDecoy` inclusi (che estendono `BaseEnemy`), e cerca i
  propri vicini indipendentemente dalla propria appartenenza al gruppo. Il
  criterio "mai il Boss" di PS-171 vale in entrambe le direzioni:
  sovrascritto `_compute_separation_velocity()` a ritornare sempre zero sia
  in `FirstBoss` sia in `BossDecoy`.
- **2026-09-13 — Terzo difetto, non di questa funzionalità ma scoperto
  verificando la seconda con `-Profile Full`: la cache statica di
  `_compute_separation_velocity()` (PS-171) era condivisa dall'intero
  processo, non per popolazione nemica.** Isolata in Focused/Relevant, la
  test di determinismo di PS-171 falliva in modo riproducibile solo
  dentro `Full` (142 script nello stesso processo Godot, per contratto
  CLAUDE.md): nemici di fixture GUT precedenti non ancora liberate (es.
  `add_child_autofree`, che rimanda la pulizia a fine script) restavano nel
  gruppo `"enemies"` e contaminavano la griglia di prossimità di una
  fixture successiva, e l'ordine di `SceneTree.get_nodes_in_group()` — non
  un contratto stabile dell'engine — cambiava l'ordine di somma delle
  spinte (virgola mobile, non associativa), amplificato da 240+ tick di un
  sistema a molti corpi mutuamente repulsivi. Corretto alla radice in
  `scripts/actors/base_enemy.gd`: la cache è ora indicizzata per
  `RunController` (una popolazione nemica = un `RunController`, sempre vero
  in una run reale) invece che globale, e ogni bucket viene ordinato per
  `instance_id` prima di sommare. Verificato con `-Profile Full` due volte
  di seguito (142/142 + toolchain, entrambe le volte) dopo essere stato
  riproducibile prima del fix. Nessun impatto sul comportamento di gioco
  reale (una sola popolazione nemica alla volta, per costruzione).
- 2026-09-19: chiusa dal proprietario con il passaggio in blocco di tutte le card `IN VERIFICA` a `COMPLETATO`.

## Documenti sincronizzati

- [x] `docs/characters.md`: la riga "Boss: Evil Marghe — Signature..." ora
      menziona l'attacco a distanza e l'accumulo.
- [x] `docs/prd.md`: verificato — non esiste una sezione dedicata al
      dettaglio della Signature di Evil Marghe (solo la meccanica generica
      delle Signature); nessuna modifica necessaria.

## Note

Seguito diretto di PS-173 (stessa sessione, stessa richiesta del
proprietario estesa dal lato Player al lato Boss).
