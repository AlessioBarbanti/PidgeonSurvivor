---
id: PS-182
titolo: Il primo Boss (minuto 2) ha troppa vita
tipo: fix
area: gameplay
stato: COMPLETATO
priorita: alta
dipende_da: []
origine: test reale su Pixel 9 della v0.3.0, 2026-09-15
creato: 2026-09-15
aggiornato: 2026-09-19
---

# PS-182 — Il primo Boss (minuto 2) ha troppa vita

## Contesto

Il proprietario segnala che "il primo boss ha troppa vita", testando la
build reale v0.3.0. La soglia del primo Boss è a `t=120s`
(`GameDirectorProfile.boss_thresholds_seconds`,
[scripts/game/game_director_profile.gd:8](../../../scripts/game/game_director_profile.gd)).
Confermato dal proprietario (2026-09-15): l'incontro era **Evil Alea**, non
il Piccione Malvagio baseline — quindi è scattata l'estrazione rara di
PS-127 (~10%) già alla prima ricorrenza.

Verificato in [scripts/bosses/boss_encounter.gd:225](../../../scripts/bosses/boss_encounter.gd)
(`resolve_variant`, `evil_definition := baseline.duplicate(true)`): un
Evil è un duplicato del `BossDefinition` baseline che cambia solo
`visual_kind`/identità, **non** `health_max`. Evil Alea ha quindi lo stesso
`health_max = 2400.0` del Piccione Malvagio
([data/bosses/first_boss.tres:19](../../../data/bosses/first_boss.tres)),
pur non ereditando lo split a metà vita di PS-127 (gating
`not is_evil_variant()`): i due incontri non sono direttamente comparabili
a parità di HP nominale. A `t=120s` il personaggio ha avuto poco tempo per
accumulare upgrade offensivi, quindi 2400 HP può risultare uno scontro
percepito come troppo lungo/spugnoso — tanto sul baseline quanto su un Evil.

## Comportamento atteso

Il primo scontro Boss della run (minuto 2) ha una durata percepita come
giusta, non eccessivamente lunga o spugnosa, mantenendo comunque la sua
identità di scontro "importante" della run.

## Criteri di accettazione

- [x] Confermato con il proprietario quale Boss ha affrontato quando ha dato
      il feedback (baseline o Evil raro), per non ricalibrare il Boss
      sbagliato. *Già confermato in Contesto (2026-09-15): Evil Alea, non il
      baseline. Poiché baseline ed Evil condividono lo stesso
      `data/bosses/first_boss.tres` (l'Evil è un duplicato che cambia solo
      identità/visual_kind, non `health_max`), la ricalibrazione si applica a
      entrambi senza dover distinguere due valori.*
- [x] `health_max` del Boss baseline (e/o degli Evil se il feedback riguarda
      loro) ricalibrato, con motivazione esplicita legata al DPS atteso del
      personaggio a `t=120s` (non un numero scelto a sensazione). *Vedi
      Decisioni: `health_max` da `2400.0` a `1500.0`.*
- [x] Nessuna regressione sul contratto "Piccione Malvagio più difficile di
      ogni Evil" di [PS-127](../4_to_test/PS-127-piccione-malvagio-boss-raro-e-piu-difficile-degli-evil.md),
      se il baseline viene toccato. *Il vantaggio del baseline su un Evil
      (terzo pattern, cooldown ridotto, split a metà vita) non deriva da
      `health_max` — riducendolo proporzionalmente su entrambe le varianti la
      differenza relativa resta intatta; confermato da `test_ps127_...` verde
      (vedi Verifica).*
- [ ] Verificato su almeno due personaggi diversi che il nuovo tempo di
      scontro si senta giusto in gioco reale. *Gate percettivo su device, non
      eseguibile da questa sessione remota (vedi Gate manuali).*

## Ambito

- `data/bosses/first_boss.tres` (`health_max`).
- `data/friends/*.tres` solo se il feedback riguarda un Evil specifico, da
  confermare prima.
- Non toccare pattern, telegraph o Signature: questa card copre solo HP.

## Verifica

- Test GUT esistenti su HP/durata scontro Boss, aggiornati se il valore
  atteso cambia.
- Profilo minimo prima della chiusura: `Relevant`.
- **Eseguito** (sandbox remoto Linux via `tools/setup-remote-sandbox.sh`,
  Godot 4.7.1 headless — non sostituisce i runner Windows/Android):
  - Focused: `test_b15_boss_encounter.gd` → `2/2 passed`, nessun
    `SCRIPT ERROR`/`FATAL EXCEPTION`.
  - Relevant (gruppo `data/bosses/*` di
    `tools/milestone-test-map.json`): `test_b15_boss_encounter.gd`,
    `test_b16_complete_run.gd`, `test_b22_evil_boss_variants.gd`,
    `test_b17_friend_content.gd`, `test_b33_recurring_boss.gd`,
    `test_b38_arena_world.gd`, `test_ps006_evil_signature_abilities.gd`,
    `test_ps026_boss_baseline_display_name.gd`,
    `test_ps051_boss_intro_identity.gd`,
    `test_ps101_evil_hunger_narrative.gd`,
    `test_ps103_boss_intro_frame_wiring.gd`,
    `test_ps176_boss_intro_floating_portrait.gd`,
    `test_ps126_post_curve_pressure.gd`,
    `test_ps127_piccione_malvagio_hard_rare.gd` → `68/68 passed`, log puliti.
  - Nessun test hardcoda `2400`/`health_max` come valore atteso assoluto: le
    asserzioni leggono `boss_health.health_max`/`definition.health_max` a
    runtime, quindi restano valide col nuovo valore senza modifiche al
    codice dei test.
  - Profilo `Full` non eseguito: fuori dal minimo dichiarato dalla card e non
    giustificato, l'unica modifica di codice/dati è il singolo float
    `health_max` (nessun tocco a pattern/telegraph/Signature, come da
    Ambito).

## Gate manuali

- [ ] Runtime Windows — non eseguibile da questa sessione (sandbox Linux
      remoto senza toolchain Windows, vedi `docs/setup.md`).
- [ ] Validazione statica APK — non eseguibile da questa sessione.
- [ ] Runtime fisico Pixel 9 (gate primario: il sintomo è stato riportato
      lì) — non eseguibile da questa sessione, nessun device collegato.
- [ ] Controllo percettivo richiesto: sì — "la durata si sente giusta" è un
      giudizio di playtest reale, non un numero isolato. Resta aperto finché
      il proprietario non prova lo scontro ricalibrato in gioco reale su
      almeno due personaggi.

## Decisioni

- **2026-09-15 — Aperta come card separata da PS-127.** PS-127 ha reso il
  Piccione Malvagio deliberatamente più difficile degli Evil come scelta di
  design; questa card ricalibra solo se quel valore risulta eccessivo nel
  contesto del minuto 2, non mette in discussione la scelta di PS-127.
- **2026-09-18 — `health_max` ricalibrato da `2400.0` a `1500.0`, motivato
  dal DPS atteso a `t=120s`.** L'arma di base è unica per tutto il roster
  (`data/weapons/default_weapon_profile.tres`: `shots_per_second = 4.0`,
  `damage = 10.0` → `40 dmg/s` di base, PS-160). Gli scarti statistici per
  personaggio (PS-087/PS-093,
  `base_damage_multiplier`/`base_fire_rate_multiplier` in `data/friends/*.tres`)
  restano stretti (danno `0.95`–`1.10`, cadenza `0.95`–`1.15`), quindi
  incidono poco sul DPS base. La curva XP (`data/progression/default_experience_curve.tres`,
  `10 + 5×(livello-1)`) combinata al ritmo di kill di
  `docs/systems-difficulty.md` porta a circa `9-10` level-up entro `t=120s`;
  nel pool ordinario solo 2 carte su ~10-11 sono danno/cadenza diretti
  (`meat_fork_damage.tres` +15%/rank, `rapid_fire.tres` +10%/rank), quindi a
  quel punto della run un personaggio tipico ha in media **~1 rank di
  ciascuna**, non di più: `40 × ~1.05 (scarto personaggio medio) × 1.15
  × 1.10 ≈ 53 dmg/s`, con un caso prudente (nessun upgrade offensivo ancora
  arrivato) a `~40-42 dmg/s`. Il precedente `2400.0` era stato calibrato in
  origine (vedi `docs/archive/verifications-legacy/b15-verification.md`,
  `b16-verification.md`) per una soglia Boss a `t=240s` (minuto 4, poi
  spostata al minuto 2 da una card successiva) assumendo `~60s` di scontro
  *prima* di considerare gli upgrade: la soglia si è spostata prima nel
  tempo ma l'HP non era mai stato riallineato, lasciando lo scontro reale
  vicino ai `45-60s` con molta meno build accumulata — la causa diretta del
  sintomo "troppa vita" riportato dal proprietario. Nuovo target: uno
  scontro sui `~30-35s` a DPS tipico (`1500 / 53 ≈ 28s`) e non oltre
  `~35-40s` nel caso prudente senza upgrade offensivi (`1500 / 42 ≈ 36s`) —
  dimezza la durata percepita mantenendo l'incontro nettamente più lungo di
  un nemico ordinario, quindi ancora "importante". Il valore è condiviso da
  baseline ed Evil (stesso `data/bosses/first_boss.tres`, l'Evil è un
  duplicato che non cambia `health_max`), quindi la riduzione si applica a
  entrambi in proporzione uguale senza toccare il vantaggio relativo del
  baseline stabilito da PS-127 (pattern extra, cooldown ridotto, split a
  metà vita — nessuno dei quali dipende da `health_max`).
- 2026-09-19: chiusa dal proprietario con il passaggio in blocco di tutte le card `IN VERIFICA` a `COMPLETATO`.

## Documenti sincronizzati

- [x] `docs/enemies-bosses.md`: `health_max` aggiornato a `1500.0` (PS-182)
      nella sezione "Baseline Piccione Malvagio".

## Note

Segnalato dal proprietario durante il test reale su Pixel 9 della v0.3.0,
insieme ad altri cinque problemi nella stessa sessione (PS-178..PS-181,
PS-183).
