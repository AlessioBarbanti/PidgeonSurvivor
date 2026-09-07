---
id: PS-121
titolo: Le carte ripetibili che hanno raggiunto il proprio tetto runtime escono dal pool di scelta
tipo: fix
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: []
origine: segnalazione del proprietario 2026-09-07 (Tagliata, "ha solo due rank?")
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-121 — Le carte ripetibili che hanno raggiunto il proprio tetto runtime escono dal pool di scelta

## Contesto

Il proprietario ha segnalato: "non mi torna il numero di proiettili sparato
a seguito dello sblocco del Power up Tagliata", notato dopo averla ripescata
una seconda volta (rango massimo).

Indagine: `Tagliata` (`double_barrel`, effetto `weapon_multishot`) ha
`max_rank = 2` **per progetto** — il piano originale B41 (28 agosto 2026)
la definisce esplicitamente "fino a 3 proiettili per colpo", raggiunti in
2 ranghi (base 1 + 1 per rango × 2 = 3, capped da
`max_weapon_multishot_count = 3`). L'aritmetica per rango era corretta.

Il bug reale è nell'idoneità: `UpgradeDefinition.is_eligible()`
(`scripts/progression/upgrade_definition.gd`) ignora `max_rank` per ogni
carta `repeatable = true`:

```gdscript
if not repeatable and get_current_rank(current_ranks) >= max_rank:
    return false
```

Tutte e quattro le carte "forma d'arma" (`double_barrel`, `piercing_rounds`,
`death_burst`, `gossip_projectiles`) e `ability_cooldown.tres`
("Ravviva la Brace!") sono `repeatable = true`: restano nel pool di scelta
**all'infinito** anche dopo aver raggiunto il proprio tetto runtime
(`max_weapon_multishot_count`, `max_weapon_pierce_count`,
`max_weapon_death_burst_damage_multiplier`, `max_gossip_chain_jumps`,
`min_active_ability_cooldown_multiplier`), continuando a comparire nei
level-up senza dare più alcun beneficio. Il proprietario aveva ripescato
Tagliata una terza volta aspettandosi un quarto proiettile: scelta sprecata
senza saperlo.

Verificato **non essere un fix sicuro come "hard cap a `max_rank` per
tutti"**: le sette carte statistiche ordinarie ripetibili (`swift_steps`,
`rapid_fire`, `wide_magnet`, `meat_fork_damage`,
`reinforced_roasting_tray`, `projectile_speed`, `barb_seasoning_xp`) hanno
tutte `max_rank = 5` in modo puramente convenzionale, **non** calibrato al
proprio tetto reale: es. `swift_steps` (`×1,1` per rango, tetto
`max_move_speed_multiplier = 2,0`) raggiunge il rango 5 a soli `×1,61`,
ben lontano dal proprio tetto (satura realisticamente al rango ~7-8). Un
hard cap a `max_rank = 5` per queste carte le avrebbe **nerfate**
silenziosamente. Serve una vera verifica di saturazione runtime, non un
blocco su `max_rank`.

## Comportamento atteso

Una carta ripetibile che ha raggiunto il proprio tetto/pavimento runtime
(un rango in più non cambierebbe l'effetto applicato in gioco) esce dal
pool di scelta, come una carta non ripetibile a rango massimo. Nessuna
carta ancora lontana dal proprio tetto reale viene esclusa prima del tempo.

## Criteri di accettazione

- [x] `UpgradeEffectRegistry.is_rank_saturated(definition, current_rank)`
      determina se salire di un rango cambierebbe l'effetto applicato,
      usando le stesse formule di `recalculate_effects()` (nessuna
      duplicazione a rischio di disallineamento): tetti interi per le
      quattro carte forma d'arma, formula a moltiplicatore composto capped
      per le carte generiche (incluso `ability_cooldown`), scarto base
      personaggio + carta per il critico (`cooking_point_crit`, l'unico
      caso non a proprietario singolo sull'`effect_id`).
- [x] `UpgradeService` collega il filtro a entrambi i punti di generazione
      offerta (level-up ordinario e bonus Barb), applicandolo solo alle
      carte `repeatable` (le non ripetibili restano gestite dal cap
      ordinario di `max_rank`, invariato).
- [x] Il filtro non svuota mai un'offerta: se ogni candidato residuo
      risultasse saturo, l'offerta li ripropone comunque piuttosto che
      lasciare un level-up senza nulla da scegliere.
- [x] `UpgradeService.select_upgrade()` accetta un'offerta più corta di
      `offer_size` (scoperto durante l'implementazione: il filtro può far
      scendere l'offerta sotto le tre carte nominali, e il controllo
      preesistente `_current_offer.size() != offer_size` rifiutava *ogni*
      selezione, anche su carte valide, bloccando il level-up per sempre).
- [x] Le sette carte statistiche ordinarie ripetibili non vengono escluse
      prima di aver davvero raggiunto il proprio tetto reale (verificato
      esplicitamente per `swift_steps` al rango 5).
- [x] Nessuna carta esistente cambia `effect_id`, `effect_parameters`,
      `weight`, `max_rank` o `repeatable`: il fix è solo nell'idoneità,
      nessun dato del catalogo tocca.

## Ambito

- `scripts/progression/upgrade_effect_registry.gd`: nuovi
  `is_rank_saturated()`/`_resolve_capped_contribution()`.
- `scripts/progression/upgrade_service.gd`: nuovo campo
  `_effect_registry` (opzionale, cablato separatamente da `configure()`),
  `_filter_saturated_repeatable_candidates()`, fix a `select_upgrade()`.
- `scripts/game/movement_slice.gd`: `_upgrade_service.set_effect_registry(...)`.
- `tests/unit/test_b41_weapon_shapes.gd`: nuovo test dedicato.
- `tests/unit/test_b12_upgrade_effects.gd`: aggiornata un'assert che
  codificava esplicitamente il vecchio comportamento ("un fallback
  ripetibile deve restare consumabile al cap") — scoperta solo dal profilo
  `Full`, non da `Relevant` (vedi Decisioni).
- Scoperto durante l'implementazione: `tools/milestone-test-map.json` non
  associava `test_b10_upgrade_service.gd`/`test_b12_upgrade_effects.gd` a
  `scripts/progression/upgrade_*` (solo a `data/upgrades/*`) — un cambio di
  codice a questi due file non li avrebbe fatti girare in `Relevant`.

Non toccare:

- `UpgradeDefinition.is_eligible()`: il gate `max_rank` per le carte non
  ripetibili resta l'unica fonte di verità per quel caso, invariato.
- i dati (`effect_parameters`, `max_rank`, `repeatable`) di ogni carta:
  nessuna `.tres` modificata da questa card.

## Verifica

- Smoke: `tests/unit/test_b41_weapon_shapes.gd` → nuova
  `test_saturated_repeatable_cards_stop_being_offered` → marker
  `SATURATED_REPEATABLE_CARDS_SMOKE_OK`. Verifica: Tagliata sparisce dal
  pool per 24 pesche dopo il rango 2 (senza intaccare le tre carte di
  riserva), `is_rank_saturated()` corretto sia per Tagliata (rango 1 falso,
  rango 2 vero) sia per una carta generica lontana dal proprio tetto
  (`swift_steps` al rango 5, falso).
- **Prova di regressione genuina**: verificato che il nuovo test fallisce
  con `Invalid call: is_rank_saturated` ripristinando temporaneamente il
  codice pre-fix (`git stash`), poi ripristinato e riconfermato verde.
- Eseguito: Focused 1/1 PASS, Relevant 59/59 PASS, **Full 119/119 PASS**
  (compreso il toolchain check) — profilo Full scelto deliberatamente oltre
  il minimo richiesto per un cambio che tocca il cuore del sistema upgrade
  condiviso da ogni carta del catalogo; ha infatti trovato la regressione
  in `test_b12_upgrade_effects.gd` che `Relevant` non copriva (vedi
  Decisioni). Nessun `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Profilo minimo prima della chiusura: `Relevant`. ✅ (qui elevato a `Full`)

## Gate manuali

- [ ] **Aperto** — Runtime Windows: non eseguito in questa sessione.
- [ ] **Aperto** — Validazione statica APK: non eseguita in questa sessione.
- [ ] **Aperto** — Runtime fisico Pixel 9: porta Tagliata al rango 2, verifica
      che non compaia più nelle offerte di level-up successive. Nessun
      device collegato in questa sessione.
- [ ] Controllo percettivo richiesto: no.

## Decisioni

- **2026-09-07 — Verifica di saturazione runtime, non un cap su `max_rank`.**
  `max_rank` non è calibrato uniformemente nel catalogo: per le quattro
  carte forma d'arma e Ravviva la Brace! coincide (quasi) col tetto reale,
  per le sette carte statistiche ordinarie è un valore convenzionale (`5`)
  del tutto slegato dal proprio tetto effettivo. Un hard cap su `max_rank`
  avrebbe corretto Tagliata ma nerfato silenziosamente le altre sette.
  L'unica soluzione sicura confronta il contributo effettivo (capped) a
  rango N e N+1.
- **2026-09-07 — Ogni `effect_id` coinvolto appartiene a una sola carta.**
  Verificato con una ricerca esaustiva sul catalogo: nessun `effect_id` tra
  quelli generici o delle quattro carte forma d'arma è condiviso da più di
  una carta. Questo rende il contributo isolato di ciascuna carta
  equivalente all'effettivo, eccetto il critico (vedi sotto), evitando la
  necessità di un ricalcolo completo del catalogo (costoso e con effetti
  collaterali) solo per decidere se offrire una carta.
- **2026-09-07 — Il critico (`cooking_point_crit`) richiede lo stato live
  del `WeaponController`.** Il suo tetto (`WeaponController.MAXIMUM_CRITICAL_CHANCE`)
  si applica alla *somma* di scarto base del personaggio e bonus della
  carta: la saturazione dipende quindi da quale personaggio si sta
  giocando, non solo dal rango della carta. Letto da
  `_weapon_controller.get_character_critical_chance_bonus()` al momento
  del controllo.
- **2026-09-07 — Mai svuotare un'offerta.** Se ogni candidato residuo
  fosse saturo (cataloghi molto piccoli, o un tardo endgame che ha esaurito
  ogni carta), il filtro si autodisattiva per quella sola offerta invece di
  lasciare zero scelte: meglio riproporre una carta inutile che bloccare un
  level-up.
- **2026-09-07 — Scoperto durante l'implementazione: `select_upgrade()`
  richiedeva un'offerta di esattamente `offer_size` elementi.** Un catalogo
  isolato di test a tre carte, con una diventata satura, produceva
  un'offerta di due: `_current_offer.size() != offer_size` rifiutava
  *qualunque* selezione (anche su una carta valida), lasciando
  `RunController` bloccato in `LEVEL_UP` per il resto della run. Il
  controllo era già più permissivo altrove (`select_barb_speciality`/
  `select_barb_bonus_upgrade` non lo impongono): allineato a
  `_current_offer.is_empty()`, che non può mai verificarsi grazie alla
  guardia precedente ma resta a protezione di filtri futuri.
- **2026-09-07 — `test_b12_upgrade_effects.gd` codificava il vecchio
  comportamento come contratto esplicito.** L'assert "Un fallback
  ripetibile deve restare consumabile al cap" testava esattamente il
  comportamento che il proprietario ha chiesto di cambiare. Capovolta
  nell'assert opposta (non più offerta al tetto, rango invariato,
  statistica invariata). Trovata solo dal profilo `Full`: `Relevant` non
  associava questo file ai file toccati, gap ora chiuso in
  `milestone-test-map.json`.

## Documenti sincronizzati

- [ ] Nessuno: nessun contratto di prodotto/architettura documentato in
      `prd.md`/`CLAUDE.md` descriveva "le carte ripetibili restano offerte
      oltre il proprio tetto" come comportamento voluto — era un'assunzione
      implicita del codice, non un contratto pubblicato.

## Note

Bug scoperto per accumulazione: la sessione di test del proprietario ha
prima riportato una discrepanza sul conteggio proiettili di Tagliata, poi
("aspetta, ha solo due rank?") l'attenzione si è spostata sul design del
rango massimo, rivelando che il vero difetto era l'idoneità della carta
oltre quel rango, non l'aritmetica del conteggio.
