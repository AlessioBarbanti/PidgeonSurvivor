---
id: PS-040
titolo: Aggiungi i-frame all'atterraggio della Powerslide di Bea
tipo: feat
area: gameplay
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-040 — Aggiungi i-frame all'atterraggio della Powerslide di Bea

## Contesto

Il proprietario ha chiesto di aggiungere un po' di invulnerabilità alla fine
della Powerslide di Bea. Lo scatto è istantaneo (il teletrasporto avviene in
un solo frame in `FireZTrail.initialize()`), mentre la scia di fuoco resta
attiva altri secondi dopo (`trail_duration`, 4-5s a seconda del rank).
Chiarito con il proprietario: l'invulnerabilità deve proteggere
l'**atterraggio** (il momento più rischioso: Bea si teletrasporta in una
nuova posizione, potenzialmente vicino a un nemico), non arrivare a fine
scia.

## Comportamento atteso

Subito dopo il teletrasporto dello scatto, Bea diventa brevemente
invulnerabile, con la stessa infrastruttura di i-frame già usata dal Sesto
Senso Equino (`HealthComponent.grant_invulnerability()`). La finestra è
breve ("un po'"), configurabile via dati, e non si somma ad altre fonti di
invulnerabilità già attive (usa lo stesso meccanismo "prendi il massimo" di
`grant_invulnerability`).

## Criteri di accettazione

- [x] Subito dopo l'attivazione della Powerslide,
      `HealthComponent.is_invulnerable()` del Player è `true` per la durata
      dichiarata dal dato. Verificato da
      `test_activation_grants_invulnerability_matching_the_declared_duration`.
- [x] La finestra di invulnerabilità è un nuovo parametro `iframe_duration`
      in `effect_parameters` di `bea_fire_z_trail.tres` (base + ogni rank),
      letto con `get_effect_float`, non hardcoded nello script.
- [x] Un valore `0.0` (o assente) disabilita la concessione senza errori:
      `_grant_landing_invulnerability` fa `return` subito se
      `iframe_duration <= 0.0`, coerente con lo stile degli altri parametri
      opzionali dell'abilità (`get_effect_float` clampa al minimo `0.0`).
- [x] L'invulnerabilità non si somma ad altre fonti attive. Verificato da
      `test_landing_invulnerability_does_not_stack_with_an_active_window`
      (usa `grant_invulnerability`, che prende il massimo residuo).
- [x] Danno, tick, hitbox, direzione e distanza della Powerslide restano
      invariati. `_apply_damage_tick`, `_is_point_near_trail` e
      `_build_straight_path` non sono stati toccati; il primo tick di danno
      è coperto da `test_activation_still_deals_damage_on_the_first_tick`.
- [x] Restart e cambio personaggio non lasciano invulnerabilità residua
      fuori dal contratto esistente di `HealthComponent`/`RunController`.
      Non introdotto alcun nuovo stato persistente: `grant_invulnerability`
      scrive sullo stesso `_invulnerability_remaining` di `HealthComponent`,
      già azzerato da `RunController.restart_prepared` per ogni altro
      sistema che lo consuma (nessuna modifica a `HealthComponent`).
- [x] Il testo pubblico dell'abilità (`characters.md`,
      `active_ability_description` di `bea.tres`, `description` del dato
      abilità) riflette la nuova invulnerabilità all'atterraggio.

## Ambito

- `data/abilities/bea_fire_z_trail.tres`: nuovo parametro `iframe_duration` in `effect_parameters` (base + ogni rank), `description`.
- `scripts/abilities/fire_z_trail.gd`: concessione dell'invulnerabilità subito dopo il teletrasporto in `initialize()`.
- `data/friends/bea.tres`: `active_ability_description` (copia pubblica della stessa descrizione, mostrata dal selettore personaggio).
- `docs/characters.md`: riga dell'attiva di Bea.

Non modificare:

- `HealthComponent` (usa l'API pubblica esistente `grant_invulnerability`, non ne serve una nuova);
- danno, tick, hitbox, direzione, distanza, cooldown della Powerslide;
- il Sesto Senso Equino (passiva di Bea) e il suo `iframe_duration` separato in `data/friends/bea.tres`;
- texture della scia e VFX (PS-027, appena chiuso).

## Verifica

- Test: `tests/unit/test_ps040_bea_powerslide_landing_iframe.gd`
  (`extends GutGameplayTest`).
- Registrato in `tools/milestone-test-map.json` sotto la regola
  `scripts/abilities/*` / `data/abilities/*`.
- Profilo minimo prima della chiusura: `Relevant` con
  `-FocusedSmoke tests/unit/test_ps040_bea_powerslide_landing_iframe.gd`
  (coperto dall'evidenza preesistente sotto).
- Evidenza preesistente riusata senza rilanciare test, su richiesta del
  proprietario: profilo `Full` Windows `20260831-230124-PS-039`, suite
  `tests/unit/test_ps040_bea_powerslide_landing_iframe.gd` 3/3, zero
  failure/skipped; intero batch 240/240, toolchain e project smoke verdi,
  nessun marker bloccante.

## Gate manuali

- [x] Runtime Windows — project smoke dell'evidenza `Full` preesistente.
- [x] Validazione statica APK — non pertinente.
- [x] Runtime fisico Pixel 9 — non richiesto, nessuna superficie touch
      specifica coinvolta.
- [ ] Controllo percettivo richiesto: sì — conferma che la finestra di
      i-frame si "senta" giusta (né invisibile né eccessiva) resta un
      giudizio di playtest.

## Decisioni

- **2026-08-31 — L'invulnerabilità protegge l'atterraggio, non la fine della
  scia.** Confermato dal proprietario: parte subito dopo il teletrasporto
  istantaneo dello scatto, non ai 4-5s di fine `trail_duration`.
- **2026-08-31 — Valore iniziale non definitivo.** `iframe_duration = 0.3s`
  per ogni rank (stesso ordine di grandezza dell'`iframe_duration = 0.4s`
  del Sesto Senso Equino, leggermente inferiore perché qui è concesso a ogni
  singola attivazione dell'abilità, non filtrato da un cooldown di 9s come
  la passiva). Resta soggetto a conferma con playtest reale.
- **2026-08-31 — Riuso di `grant_invulnerability`, nessuna nuova API.** Stesso
  meccanismo già usato dal Sesto Senso Equino: "prende il massimo" invece di
  sommarsi, quindi non crea finestre di invulnerabilità anomale se si
  sovrappone ad altre fonti.

## Documenti sincronizzati

- [x] `characters.md` — riga dell'attiva di Bea aggiornata per menzionare
      l'invulnerabilità all'atterraggio.

## Note

**Stato in verifica (2026-08-31).** L'implementazione del commit `ebe9d08`,
la suite dedicata e il project smoke Windows sono già verdi. Il proprietario
ha chiesto di non rilanciare test perché l'audit non ha modificato il runtime.
Resta aperto soltanto il controllo percettivo sul valore iniziale `0.3s`, che
non viene sostituito da un test automatico.
