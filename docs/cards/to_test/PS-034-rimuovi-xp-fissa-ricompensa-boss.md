---
id: PS-034
titolo: Rimuovi la ricompensa XP fissa dalla sconfitta del Boss
tipo: fix
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: []
origine:
milestone:
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-034 — Rimuovi la ricompensa XP fissa dalla sconfitta del Boss

## Contesto

PS-012 ha introdotto le Specialità di Barb come ricompensa dedicata alla
sconfitta di un Boss (`RunController.BARB_REWARD`), ma non ha rimosso il
vecchio meccanismo pre-esistente: `BossEncounter._on_boss_died()` continua a
chiamare `_experience_system.add_experience(defeated_definition.experience_reward)`
con `experience_reward = 50` (`data/bosses/first_boss.tres`), assegnando XP
istantanea in aggiunta alla ricompensa Barb. Il proprietario ha chiesto che le
Specialità restino l'unica ricompensa per il Boss sconfitto.

## Comportamento atteso

Alla sconfitta di un Boss non viene più assegnata alcuna esperienza fissa.
L'unica ricompensa osservabile resta l'apertura della ricompensa Barb
(Specialità o, a Specialità esaurite, i due bonus upgrade consecutivi già
previsti da PS-012). La schermata finale di vittoria non mostra più un valore
XP legato al Boss.

## Criteri di accettazione

- [x] Sconfiggere un Boss non aumenta `ExperienceSystem.experience_total` —
      verificato in `test_b15_boss_encounter.gd`, `test_b16_complete_run.gd`
      (5 run consecutive) e `test_b22_evil_boss_variants.gd` (baseline ed Evil).
- [x] `BossDefinition` non espone più un campo di ricompensa XP inutilizzato
      (`experience_reward` rimosso da script e da `data/bosses/first_boss.tres`,
      nessun riferimento residuo nel repository).
- [x] La ricompensa Barb (Specialità o fallback bonus) continua a funzionare
      esattamente come in PS-012, inclusa la sequenza deterministica da seed —
      `test_ps012_barb_specialities.gd` resta verde nel profilo `Relevant`.
- [ ] La end screen di vittoria non mostra più il testo `+N XP` legato al Boss —
      corretto a livello di codice (`EndScreen.show_victory()` non riceve più
      un valore XP), ma nessun test asserisce il testo del riepilogo e lo stato
      `VICTORY` non è mai richiesto a runtime nel design a Boss ricorrenti
      (B33): `RunController.request_victory()` non ha chiamanti nel codice
      attuale, quindi il percorso resta strutturalmente corretto ma non
      esercitato né dai test né a runtime. Preesistente a questa card, non
      indagato oltre perché fuori ambito.
- [x] Nessun test esistente asserisce ancora che la morte del Boss assegni XP —
      grep di `experience_reward` nel repository non trova più asserzioni sul
      vecchio comportamento.

## Ambito

- `scripts/bosses/boss_encounter.gd`: rimuovere la chiamata
  `_experience_system.add_experience(...)` in `_on_boss_died()` e lo stato di
  supporto (`_last_experience_reward`, `get_last_experience_reward()`) se
  restano senza consumatori.
- `scripts/bosses/boss_definition.gd`: rimuovere `experience_reward` e il
  relativo controllo in `is_valid()`.
- `scripts/bosses/first_boss.gd`: rimuovere l'assegnazione
  `experience_amount = definition.experience_reward` in `configure_boss()`.
- `data/bosses/first_boss.tres`: rimuovere la riga `experience_reward = 50`.
- `scripts/ui/end_screen.gd`: `show_victory()` non riceve più/non mostra più
  un valore XP del Boss.
- `scripts/game/movement_slice.gd`: aggiornare la firma dei gestori di
  `boss_defeated` e la chiamata a `_end_screen.show_victory(...)` di
  conseguenza.
- Test da aggiornare: `tests/unit/test_b15_boss_encounter.gd`,
  `tests/unit/test_b16_complete_run.gd`, `tests/unit/test_b22_evil_boss_variants.gd`.
- `docs/prd.md` §3.5: la frase "la morte atomica del Boss assegna una sola
  ricompensa XP" non è più corretta e va corretta per riflettere la ricompensa
  Barb.

Non toccare:

- il sistema di drop XP dei nemici ordinari (`ExperienceDropper`,
  `experience_reward_scale`, `BaseEnemy.get_experience_reward_value()`): è un
  meccanismo distinto e non è oggetto di questa card;
- la logica, le regole di eleggibilità o il fallback della ricompensa Barb
  definiti in PS-012;
- i pattern d'attacco, la salute o gli altri parametri di `BossDefinition`.

## Verifica

- Smoke: riusa/estende `tests/unit/test_b15_boss_encounter.gd` (già copre la
  morte atomica del Boss) invece di crearne uno nuovo. Aggiornati anche
  `test_b16_complete_run.gd`, `test_b22_evil_boss_variants.gd` e il commento
  in `test_ps012_barb_specialities.gd`.
- Profilo minimo prima della chiusura: `Relevant`

Eseguiti e verdi:

```
.\tools\run-milestone-checks.ps1 -Milestone PS-034 -Profile Focused `
  -FocusedSmoke tests/unit/test_b15_boss_encounter.gd
.\tools\run-milestone-checks.ps1 -Milestone PS-034 -Profile Relevant `
  -FocusedSmoke tests/unit/test_b15_boss_encounter.gd
```

`Relevant` (prima del merge con `main`): `PASS focused=1/1 regression=27/27
steps=28/28`.

Rieseguito **dopo il merge dei 23 commit remoti** in `main` (che includevano
PS-039, la cui concessione XP è stata revocata qui — vedi Decisioni):

```
.	oolsun-milestone-checks.ps1 -Milestone PS-034 -Profile Relevant `
  -FocusedSmoke tests/unit/test_b15_boss_encounter.gd -RefreshEditor
```

`PASS bootstrap=1/1 focused=1/1 regression=21/21 steps=23/23` — 21 script, 62
test, 14.567 assert, tutti verdi. Nessun
`SCRIPT ERROR`/`FATAL EXCEPTION` nei log (`LOG_ROOT` verificato con grep
ricorsivo). `Full` non eseguito: la modifica è una rimozione mirata di un
segnale/campo con basso raggio di impatto (un solo punto di wiring in
`movement_slice.gd`) e il profilo `Relevant` copre già tutti i file toccati.

## Gate manuali

- [ ] Runtime Windows — non eseguito (né `-Profile Release` né export/runtime
      Windows in questa sessione).
- [x] Validazione statica APK — 2026-08-31, `PASS android=3/3`,
      `android_static_valid=true`, `issues=[]`. Package
      `com.ilgioco.pidgeonsurvivor`, `minSdk 31`, `targetSdk 36`, ABI
      `arm64-v8a`, firma v2 valida. APK 105.875.917 byte, SHA-256
      `DC6E0B8BFC5D4CF62F5683D32D56CCE9CBD2FC82C3C2361BDDEB12C1A425BB8A`.
- [ ] Runtime fisico Pixel 9 (percorso: sconfiggi un Boss → verifica assenza
      variazione XP non dovuta a drop nemici ordinari → verifica ricompensa
      Barb invariata) — **APERTO**. L'APK è stato installato sul Pixel 9
      (`49140DLAQ0010Y`, `tokay`) e avviato: welcome raggiunta, tutti i
      `*_CONTRACT_OK` verdi, 60 FPS stabili, nessun `SCRIPT ERROR` né
      `FATAL EXCEPTION` nel logcat. Ma il **percorso modificato non è stato
      esercitato**: serve giocare fino a un Boss e sconfiggerlo. Avvio e
      installazione non chiudono questo gate.
- [ ] Controllo percettivo richiesto: sì — spetta al proprietario.
- [ ] La schermata di vittoria non mostra più un valore XP legato al Boss —
      non verificabile a runtime: `RunController.request_victory()` non ha
      chiamanti nel design a Boss ricorrenti (B33).

## Decisioni

- **2026-08-31 — Le Specialità di Barb diventano l'unica ricompensa Boss.**
  Richiesta esplicita del proprietario a seguito del refactor PS-012: la
  doppia ricompensa (XP fissa + Barb) non è più il comportamento voluto.
- **Sostituisce:** la parte di PS-012 (non esplicitata come criterio, ma
  presente nel codice pre-esistente) che lasciava attiva la chiamata
  `add_experience()` alla morte del Boss.
- **2026-08-31 — Rimossa anche l'iniezione di `ExperienceSystem` in
  `BossEncounter`.** Dopo aver tolto `add_experience()` il parametro
  `experience_system` di `BossEncounter.configure()` e il relativo controllo
  in `has_valid_configuration()` restavano inutilizzati (nessun altro
  consumatore nel file). Rimossi insieme al resto invece di lasciare una
  dipendenza morta; unico punto di chiamata aggiornato in
  `movement_slice.gd:158`.
- **Firma di `boss_defeated` cambiata.** Il segnale non porta più il
  parametro `experience_reward: int` (ora `boss_defeated(boss: FirstBoss)`);
  aggiornati i due gestori in `movement_slice.gd`
  (`_on_boss_defeated_for_horde_pause`, `_on_boss_defeated_for_barb_reward`).
  Nessun altro punto del repository si connetteva al segnale.

- **2026-08-31 — Perché il fallback dà potenziamenti e non esperienza.**
  Chiarimento del proprietario: a Specialità esaurite il Boss deve concedere
  due potenziamenti scelti dallo stesso pool del level-up ordinario, ma **non**
  esperienza. Accreditare XP falserebbe le metriche che dipendono dalla curva
  di esperienza — ritmo dei level-up ordinari, scala di difficoltà, letture di
  bilanciamento — che devono restare guidate dal solo drop dei nemici comuni.
  È esattamente ciò che il codice fa già: `select_barb_bonus_upgrade()` alza il
  rank ed emette `upgrade_selected(..., 0)` senza toccare `ExperienceSystem`.
  Questa è la ragione per cui la rimozione della XP del Boss non va riletta
  come regressione (vedi la decisione successiva su PS-039).
- **2026-08-31 — Conflitto con PS-039 risolto a favore di questa card.**
  Una sessione remota ha aperto e mergiato PS-039 leggendo la rimozione della
  XP del Boss operata da PS-006 come una regressione, e l'ha ripristinata
  (`_on_boss_defeated_for_experience_reward`, `_last_boss_experience_reward`,
  valore XP a `EndScreen.show_victory()`). Il proprietario ha confermato che
  la rimozione era voluta: al merge quei tre elementi sono stati disfatti.
  È stata invece **conservata** la correzione di arità dei due handler di
  `boss_defeated` introdotta da PS-039, che era un difetto reale sul ramo
  `DEFEAT` e coincide con la firma già prevista da questa card.
- **`experience_amount = 50` sulla scena del Boss lasciato in sede.**
  `scenes/actors/first_boss.tscn:31` eredita il campo da `BaseEnemy`, ma resta
  inerte: il Boss non passa da `EnemySpawner.enemy_spawned`, quindi
  `ExperienceDropper` non lo osserva, e l'unico lettore esplicito è stato
  rimosso. Toccare la scena è rischio senza guadagno; il fatto è documentato
  in `docs/enemies-bosses.md`.

## Documenti sincronizzati

- [x] `docs/enemies-bosses.md`: sezione "Ricompensa della sconfitta del Boss"
      riscritta (era "Ricompensa XP del Boss", scritta da PS-039).
- [x] `docs/prd.md` §3.5: la frase sulla ricompensa XP del Boss ora rimanda
      alla ricompensa Barb (§3.3).

## Note

`docs/prd.md` §3.3 (sezione "Specialità di Barb (PS-012)") già descrive la
ricompensa Boss come solo Barb/Specialità e non menziona XP: non richiede
modifiche, solo §3.5 è disallineata.
