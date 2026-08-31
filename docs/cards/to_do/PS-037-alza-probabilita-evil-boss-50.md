---
id: PS-037
titolo: Alza la probabilità Evil Boss dal 25% al 50%
tipo: chore
area: gameplay
stato: IN CORSO
priorita: media
dipende_da: []
origine: B22
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-037 — Alza la probabilità Evil Boss dal 25% al 50%

## Contesto

`BossEncounter.evil_boss_chance` (default dati `0.25`, decisione BOSS-004) fa
sì che ogni incontro Boss abbia il 75% di probabilità di risolversi nel
baseline (`Piccione Malvagio`, ex `Piccione Speciale`, PS-026) e solo il 25%
ripartito sugli otto `Evil <Nome>` — circa il 3,1% ciascuno. Con una sola
soglia Boss schedulata per run (`120s`, poi ricorrenza ogni `240s`), il
proprietario segnala di vedere quasi sempre il baseline dopo diverse run: è il
comportamento statisticamente atteso col 25%, confermato leggendo
`scripts/bosses/boss_encounter.gd:22` e
`tests/unit/test_b22_evil_boss_variants.gd`. Il proprietario ha chiesto
esplicitamente di alzare la probabilità a un 50/50.

## Comportamento atteso

Ogni incontro Boss ha il 50% di probabilità di risolversi nel baseline e il
50% ripartito sugli otto Evil (~6,25% ciascuno), a parità di seed della run e
indice della soglia già in uso. Nessun altro comportamento del Boss cambia.

## Criteri di accettazione

- [x] Il default dati di `evil_boss_chance` è `0.5` invece di `0.25`.
      `scripts/bosses/boss_encounter.gd:22`.
- [x] La selezione resta deterministica per seed-run + indice soglia (nessuna
      modifica alla formula di `resolve_variant`/`resolve_definition_for_event`).
      Nessuna riga toccata in `resolve_variant`/`resolve_definition_for_event`
      (`scripts/bosses/boss_encounter.gd:141-201`).
- [ ] Su un campione ampio di seed a `evil_boss_chance` di default, la quota di
      esiti Evil è statisticamente vicina al 50% (non più al 25%). Aggiornato
      `tests/unit/test_b22_evil_boss_variants.gd:79-87` (400 seed, atteso
      `160-240` esiti Evil su media 200); non spuntato perché non ho potuto
      eseguire il test in questo ambiente (vedi Note).
- [ ] `evil_boss_chance = 0.0` sceglie sempre il baseline ed
      `evil_boss_chance = 1.0` sceglie sempre un Evil, come oggi. Invariato nel
      codice (`resolve_variant` tratta gli estremi allo stesso modo
      indipendentemente dal default); coperto dagli stessi test esistenti, non
      eseguiti in questa sessione.
- [x] Statistiche, hitbox, pattern, Signature e nome pubblico del Boss non
      cambiano. Unica riga di logica toccata è il default `evil_boss_chance`.
- [x] La guardia di regressione in `movement_slice.gd` verifica il nuovo
      default `0.5` invece di `0.25`.
      `scripts/game/movement_slice.gd:1060-1061`.

## Ambito

- `scripts/bosses/boss_encounter.gd:22` — default `@export` di
  `evil_boss_chance`.
- `scripts/game/movement_slice.gd:1060-1061` — guardia anti-regressione che
  oggi impone esplicitamente `0.25`; va aggiornata a `0.5`, non rimossa.
- `tests/unit/test_b22_evil_boss_variants.gd:79-87` — il blocco che verifica
  la distribuzione del *default* al 25% (`evil_count >= 70 and <= 130` su 400
  seed) va riallineato alla nuova soglia attesa al 50%.
- Documentazione: `docs/prd.md` (§3.5A cita la probabilità iniziale `25%`).

Non modificare:

- la formula di risoluzione seedata (`resolve_variant`,
  `resolve_definition_for_event`);
- cadenza e soglie degli incontri Boss (`director_profiles`);
- statistiche, sprite, hitbox, pattern, Signature Ability o nome pubblico dei
  Boss;
- gli altri usi espliciti di `evil_boss_chance = 0.0/1.0` nei test esistenti
  (`test_b30_boss_no_circular_aura.gd`, `test_ps006_evil_signature_abilities.gd`,
  `test_b22_evil_boss_variants.gd`), che testano gli estremi e restano validi
  a prescindere dal default.

## Verifica

- Test: `tests/unit/test_b22_evil_boss_variants.gd` (blocco distribuzione
  default riallineato al 50%) più i test che già forzano `evil_boss_chance`
  agli estremi.
- Profilo minimo prima della chiusura: `Relevant` con
  `-FocusedSmoke tests/unit/test_b22_evil_boss_variants.gd`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: non richiesto, nessuna superficie
      touch coinvolta)
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-08-31 — 50/50 su richiesta esplicita del proprietario.** Sostituisce
  la decisione BOSS-004 (25% iniziale) limitatamente al valore di default;
  la formula di risoluzione seedata e la cadenza degli incontri non cambiano.
- **Sostituisce:** default `evil_boss_chance = 0.25` (BOSS-004).
- **2026-08-31 — Verifica automatica non eseguita in questa sessione.** Ho
  aggiornato codice, guardia di regressione e test, ma non ho potuto lanciare
  `run-milestone-checks.ps1`: l'ambiente di questa sessione è Linux senza
  Godot né PowerShell, mentre il toolchain di verifica del progetto è
  Windows-only (`docs/setup.md`). Stessa limitazione già registrata su
  PS-026 nella stessa sessione.

## Documenti sincronizzati

- [x] `prd.md` — aggiornata la probabilità iniziale citata in §3.5A da `25%`
      a `50%` (con richiamo a PS-037).

## Note

Alternativa scartata: alzare anche la frequenza degli incontri Boss (soglie
più fitte) per mostrare più Evil per run. Non richiesta dal proprietario in
questo giro; se servisse, apre una card a parte perché tocca
`director_profiles` e il bilanciamento della run, non la sola probabilità.

**Stato aperto (2026-08-31).** Implementazione e sincronizzazione doc
completate; nessun gate automatico o manuale è stato eseguito in questa
sessione per assenza del toolchain Windows/Godot. Prima di portare la card a
`COMPLETATO` serve: `Relevant` su Windows con
`-FocusedSmoke tests/unit/test_b22_evil_boss_variants.gd`, più i gate manuali
elencati sopra.
