---
id: PS-194
titolo: Fai vagare la copia fantasma dello specchio invece di farla orbitare in cerchio fisso
tipo: ux
area: gameplay
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-09-18
aggiornato: 2026-09-18
---

# PS-194 — Fai vagare la copia fantasma dello specchio invece di farla orbitare in cerchio fisso

## Contesto

Il proprietario segnala che, quando il Piccione Malvagio baseline attiva lo
specchio a doppio attacco (sotto `split_health_ratio`, PS-127), la copia
"fantasma" da cui ripete ogni pattern è brutta da vedere perché orbita
attorno al Boss reale: tutti gli attacchi telegrafati dalla copia finiscono
per avere sempre la stessa geometria relativa. Preferirebbe che la copia
"passeggiasse in giro" invece di seguire un'orbita.

La causa è in
[scripts/bosses/first_boss.gd:283-291](../../../scripts/bosses/first_boss.gd)
(`_advance_split_ghost`): `_split_ghost_offset =
Vector2.RIGHT.rotated(_split_orbit_angle) * definition.split_ghost_distance`,
con `_split_orbit_angle` che avanza a velocità angolare costante
(`split_ghost_orbit_speed`). È un'orbita circolare pura a raggio fisso — una
funzione puramente periodica del tempo trascorso da quando lo specchio si è
attivato — quindi la posizione della copia rispetto al Boss reale, e con essa
la configurazione di ogni pattern che ripete da lì (raffica radiale, area
mirata, Scia di Piume:
[first_boss.gd:633](../../../scripts/bosses/first_boss.gd),
[:653](../../../scripts/bosses/first_boss.gd),
[:1117](../../../scripts/bosses/first_boss.gd),
[:1210](../../../scripts/bosses/first_boss.gd)), si ripete sempre uguale.

Non è un bug rispetto a un contratto dichiarato (nessuna card garantisce
un'orbita circolare), è un miglioramento di game-feel sulla varietà percepita
degli attacchi della copia.

## Comportamento atteso

Durante lo specchio attivo, l'origine della copia si muove attorno al Boss
reale con un percorso che non è una semplice orbita circolare a raggio e
velocità costanti: la sua posizione varia in modo meno prevedibile nel tempo,
così i pattern che ripete da lì non si leggono più sempre nella stessa
configurazione geometrica. Restano invariati: nessuna seconda entità/
`HealthComponent`, attivazione irreversibile per l'intero incontro, e offset
sempre relativo alla posizione corrente del Boss (nessuna dipendenza da
`ArenaLayout` o coordinate assolute).

## Criteri di accettazione

- [ ] L'offset della copia fantasma non è più calcolato con la formula
      circolare a raggio fisso attuale (`Vector2.RIGHT.rotated(angle) *
      distance` a velocità angolare costante).
- [ ] Il movimento resta deterministico a parità di seed di run, con lo
      stesso principio di seeding già usato per
      `_build_feather_fan_directions`
      ([first_boss.gd:667-684](../../../scripts/bosses/first_boss.gd)): due
      run con lo stesso seed producono lo stesso percorso della copia.
- [ ] L'offset resta sempre relativo a `global_position` del Boss (nessuna
      lettura di `ArenaLayout` o coordinate assolute di schermo).
- [ ] La distanza fra Boss reale e copia resta entro un intervallo dichiarato
      esplicitamente in `Decisioni` (né sovrapposta al Boss reale, né così
      lontana da leggersi come un'entità slegata).
- [ ] Nessuna regressione sul contratto PS-127: la copia non genera un
      secondo `HealthComponent`, l'attivazione resta irreversibile per
      l'intero incontro e si azzera solo su `reset_attack_cycle`.
- [ ] Verificato in gioco reale che, con lo specchio attivo, gli attacchi
      della copia non si leggano più come sempre nella stessa disposizione
      rispetto al Boss reale.

## Ambito

- `scripts/bosses/first_boss.gd`: `_advance_split_ghost` e l'eventuale nuovo
  stato di supporto (es. bersaglio di wander corrente, timer di retarget).
- `scripts/bosses/boss_definition.gd:38-39`: `split_ghost_distance`/
  `split_ghost_orbit_speed` possono essere sostituiti o affiancati da nuovi
  campi coerenti col wander scelto (nome e range a scelta
  dell'implementazione).
- `data/bosses/first_boss.tres:26-28`: valori aggiornati coerenti coi nuovi
  campi.
- Non toccare:
  - `split_health_ratio` e la logica di attivazione irreversibile
    (`_on_health_changed`,
    [first_boss.gd:263-278](../../../scripts/bosses/first_boss.gd));
  - il fatto che la copia non genera una seconda entità/`HealthComponent`
    (contratto PS-127);
  - i pattern d'attacco stessi e la loro cadenza (ambito di
    [PS-193](./PS-193-aumenta-cadenza-attacco-boss-non-pausa-ondate.md));
  - la presentazione visiva di base del telegraph (ambito di
    [PS-141](../4_to_test/PS-141-arricchisci-telegraph-attacchi-boss.md));
  - `_draw_split_ghost` oltre a quanto serve per seguire il nuovo offset (lo
    sprite disegnato resta lo stesso, nessun nuovo asset).

## Verifica

- Smoke: `tests/unit/test_ps194_boss_split_ghost_wander.gd` → marker
  `PS194_BOSS_SPLIT_GHOST_WANDER_SMOKE_OK` — asserisce: riproducibilità a
  parità di seed, distanza dal Boss sempre entro i limiti dichiarati, offset
  che varia nel tempo (non stazionario), nessuna seconda entità/
  `HealthComponent` generata.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK — non pertinente, nessun nuovo asset
- [ ] Runtime fisico Pixel 9
- [ ] Controllo percettivo richiesto: sì — "la copia si muove in giro, non
      sempre nella stessa orbita" è un giudizio visivo di playtest reale, va
      raggiunto lo specchio attivo (sotto metà vita del baseline) in una run
      reale

## Decisioni

- **2026-09-18 — Aperta da feedback diretto del proprietario**: l'orbita
  circolare a raggio fisso della copia fantasma rende ogni pattern ripetuto
  sempre uguale nella disposizione geometrica.
- **Algoritmo di wander esatto lasciato aperto** a chi implementa (es.
  retargeting periodico con interpolazione verso un nuovo punto entro un
  raggio min/max, seedato come `_build_feather_fan_directions`): dichiarare
  qui parametri scelti (raggio min/max, velocità, intervallo di retarget) e
  motivazione prima della chiusura.

## Documenti sincronizzati

- [ ] `docs/enemies-bosses.md:137-144` (sezione "Specchio a doppio attacco")
      — se il comportamento descritto cambia in modo stabile.

## Note

Segnalato dal proprietario nella stessa sessione di
[PS-193](./PS-193-aumenta-cadenza-attacco-boss-non-pausa-ondate.md), ma
problema indipendente: PS-193 tocca la cadenza fra un attacco e l'altro,
questa card tocca solo la geometria di dove la copia si trova quando
attacca.
