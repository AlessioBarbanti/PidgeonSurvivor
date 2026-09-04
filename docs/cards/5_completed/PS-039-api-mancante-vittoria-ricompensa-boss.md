---
id: PS-039
titolo: Regressione sulla ricompensa XP del Boss dopo PS-006
tipo: fix
area: gameplay
stato: COMPLETATO
priorita: alta
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-039 — Regressione sulla ricompensa XP del Boss dopo PS-006

## Contesto

Scoperta durante la ricognizione per PS-038 (documentazione di game design),
come API mancante isolata sul solo ramo `VICTORY`. Un'indagine più a fondo
(`git log -p -S "experience_reward"`) ha mostrato che il problema reale è
molto più ampio di quanto inizialmente descritto: **il criterio originale di
questa card era sottostimato e viene corretto qui, non riscritto di
nascosto.**

Il commit `8d0d108` (`feat(PS-006): dai agli Evil una Signature Ability`) ha
rimosso da `BossDefinition` il campo
`@export var experience_reward := 50` e, in `BossEncounter`, il meccanismo
che lo leggeva (`_last_experience_reward`, `get_last_experience_reward()`,
la chiamata a `_experience_system.add_experience(...)` in `_on_boss_died`,
il secondo parametro del segnale `boss_defeated`). Non ha però aggiornato
tutti i consumatori rimasti:

1. **`movement_slice.gd:83-84`** (ora `84-85`) collegava
   `_on_boss_defeated_for_horde_pause(_boss, _experience_reward)` e
   `_on_boss_defeated_for_barb_reward(_boss, _experience_reward)` — entrambi
   con due parametri obbligatori senza default — al segnale
   `boss_defeated(boss)`, ora a un solo argomento. In Godot 4, collegare un
   metodo con più parametri obbligatori di quelli emessi dal segnale genera
   un errore a runtime **a ogni singola morte del Boss** (path `DEFEAT`,
   quindi pienamente raggiungibile in produzione, non solo `VICTORY`).
2. **`movement_slice.gd:1797`** chiamava
   `_boss_encounter.get_last_experience_reward()`, metodo non più esistente
   — ma solo sul ramo `VICTORY`, oggi non raggiungibile in produzione (vedi
   `docs/systems-difficulty.md`).
3. **Il Boss non grantiva più alcuna XP al giocatore**: la chiamata a
   `_experience_system.add_experience(...)` era dentro il blocco rimosso da
   PS-006 e non aveva un sostituto altrove. Il Boss non passa dallo spawner
   ordinario, quindi non riceve nemmeno il drop automatico di
   `ExperienceDropper` riservato ai nemici comuni.
4. **Tre test referenziavano il campo rimosso** (`definition.experience_reward`
   / `baseline.experience_reward` su una `BossDefinition` tipizzata, quindi
   un errore di parsing, non solo un'asserzione rossa):
   `tests/unit/test_b15_boss_encounter.gd:149`,
   `tests/unit/test_b16_complete_run.gd:113`,
   `tests/unit/test_b22_evil_boss_variants.gd:152,184`.
5. **`data/bosses/first_boss.tres`** dichiarava ancora `experience_reward = 50`,
   valore dati orfano ignorato al load da quando il campo non esiste più
   sulla classe.

Il commit PS-006 dichiara "Verifica: profili Focused (17 test, 1318 assert)
e Relevant verdi, senza SCRIPT ERROR nei log" — non è stato possibile
riconciliare questa affermazione con lo stato del codice trovato; non è
oggetto di questa card stabilire perché, solo correggere lo stato attuale.

## Comportamento atteso

- Ogni morte del Boss (baseline o Evil) continua a sospendere/riprendere lo
  spawn ordinario e ad accodare la ricompensa Barb, senza errori a runtime.
- Ogni morte del Boss assegna al giocatore la stessa quantità di XP
  dichiarata sulla scena (`experience_amount` di `BaseEnemy`), esattamente
  come prima della rimozione PS-006 introduceva il regresso.
- Il ramo `VICTORY` di `_show_terminal_screen` compila ed esegue senza
  chiamare API inesistenti, mostrando in `EndScreen` la ricompensa XP
  realmente assegnata dall'ultimo Boss sconfitto.
- I test Boss tornano a fare riferimento solo a campi/metodi realmente
  esistenti.

## Criteri di accettazione

- [x] `_on_boss_defeated_for_horde_pause` e `_on_boss_defeated_for_barb_reward`
      hanno la stessa arità del segnale `boss_defeated(boss: FirstBoss)`
      (un solo parametro): niente più errore "troppo pochi argomenti" a ogni
      morte del Boss.
- [x] Il Boss (baseline ed Evil) accredita XP al giocatore alla morte,
      tramite un nuovo handler dedicato
      (`_on_boss_defeated_for_experience_reward`) che legge
      `BaseEnemy.get_experience_reward_value()` sul Boss appena sconfitto e
      chiama `ExperienceSystem.add_experience()`.
- [x] `_show_terminal_screen` non chiama più `get_last_experience_reward()`
      su `BossEncounter`: usa il valore già noto da
      `_last_boss_experience_reward`, azzerato a ogni `restart_run()`.
- [x] Il ramo `DEFEAT` di `_show_terminal_screen` non cambia comportamento
      (nessuna riga toccata in quel ramo).
- [x] Nessuna modifica al valore XP realmente erogato al giocatore: resta
      `experience_amount = 50` dichiarato sulla scena, solo la via di lettura
      cambia.
- [x] I tre test che referenziavano `experience_reward` su `BossDefinition`
      sono stati aggiornati per leggere
      `BaseEnemy.get_experience_reward_value()` invece del campo rimosso.
- [x] Il campo dati orfano `experience_reward = 50` è stato rimosso da
      `data/bosses/first_boss.tres` (nessun consumer lo legge più; lasciarlo
      avrebbe continuato a suggerire una fonte di verità sbagliata).

## Ambito

- `scripts/game/movement_slice.gd`: firme dei due handler esistenti, nuovo
  handler per la ricompensa XP, nuovo campo `_last_boss_experience_reward`,
  reset al restart, ramo `VICTORY` di `_show_terminal_screen`.
- `tests/unit/test_b15_boss_encounter.gd`,
  `tests/unit/test_b16_complete_run.gd`,
  `tests/unit/test_b22_evil_boss_variants.gd`: sostituita la lettura del
  campo rimosso con il valore reale letto dal Boss.
- `data/bosses/first_boss.tres`: rimossa la riga dati orfana.
- `docs/enemies-bosses.md`: sezione sulla ricompensa XP del Boss aggiornata
  allo stato post-fix (era stata scritta da PS-038 come segnalazione del
  problema, non più accurata dopo questo fix).

Non modificare:

- `scripts/bosses/boss_encounter.gd`: la firma del segnale `boss_defeated`
  resta a un solo parametro come l'ha lasciata PS-006; la responsabilità
  della ricompensa XP resta in `movement_slice.gd`, che già possiede
  `ExperienceSystem`, invece di reintrodurre quella dipendenza in
  `BossEncounter`;
- alcuna probabilità, statistica o pattern Boss;
- il valore di `experience_amount` sulla scena (resta `50`);
- lo stato `VICTORY` stesso o le condizioni che lo raggiungono: questa card
  corregge un ramo già esistente, non introduce una condizione di vittoria.

## Verifica

- Test esistenti aggiornati (non nuovi): `tests/unit/test_b15_boss_encounter.gd`,
  `tests/unit/test_b16_complete_run.gd`,
  `tests/unit/test_b22_evil_boss_variants.gd` coprono già la morte del Boss
  baseline ed Evil, singola e su due run consecutive; con il fix tornano a
  parsare ed eseguire, verificando la ricompensa XP con il valore reale
  invece del campo rimosso.
- Profilo minimo prima della chiusura: `Relevant` con
  `-FocusedSmoke tests/unit/test_b15_boss_encounter.gd`.
- **2026-08-31 — `Relevant` PASS su Windows** con focused
  `tests/unit/test_b15_boss_encounter.gd`: 2 test focused e 50 test di
  regressione, zero failure JUnit; nessun `SCRIPT ERROR`, `FATAL EXCEPTION`,
  `SMOKE_FAIL` o `CONTRACT_FAIL` nei log.
- **2026-08-31 — `Full` PASS su Windows**: 2 test focused e 240 test di
  regressione, zero failure JUnit; toolchain e project smoke superati. Il log
  di teardown contiene leak di risorse/RID già tollerati dal runner, ma
  nessuno dei marker bloccanti del contratto.

## Gate manuali

- [x] Runtime Windows — project smoke superato dal profilo `Full` del
      2026-08-31.
- [x] Validazione statica APK — non pertinente, nessuna superficie Android
      specifica.
- [x] Runtime fisico Pixel 9 — non richiesto per questo fix (nessuna
      superficie touch/lifecycle coinvolta).
- [x] Controllo percettivo richiesto: no.

## Decisioni

- **2026-08-31 — Scoperta durante PS-038, corretta come card separata.** La
  ricognizione per la documentazione di game design non modifica codice: il
  problema è stato aperto qui invece di allargare PS-038.
- **2026-08-31 — Criterio originale sottostimato, corretto qui.** La prima
  stesura di questa card copriva solo il ramo `VICTORY` (priorità bassa,
  dormiente). L'indagine per implementarla ha mostrato che lo stesso
  regresso rompe anche il ramo `DEFEAT` a ogni singola morte del Boss
  (i due handler con arità sbagliata) e azzera silenziosamente la ricompensa
  XP del Boss in ogni run. Priorità alzata da bassa ad alta di conseguenza.
- **2026-08-31 — Responsabilità della ricompensa XP resta in
  `movement_slice.gd`, non reintrodotta in `BossEncounter`.** PS-006 aveva
  deliberatamente rimosso la dipendenza da `ExperienceSystem` dentro
  `BossEncounter`; reintrodurla per questo fix avrebbe ampliato la
  superficie toccata senza necessità, dato che `movement_slice.gd` possiede
  già entrambi i riferimenti ed è già il punto che ascolta `boss_defeated`.
- **2026-08-31 — Rimosso il campo dati orfano nel `.tres`.** Lasciarlo
  avrebbe continuato a suggerire (falsamente) che `BossDefinition` fosse la
  fonte della ricompensa XP.

- **2026-08-31 — La concessione XP di questa card è revocata da PS-034.**
  Il proprietario ha confermato che la rimozione della ricompensa XP del Boss
  operata da PS-006 era **voluta**, non una regressione: le Specialità di Barb
  sono l'unica ricompensa della sconfitta di un Boss. Al merge di questo ramo
  in `main` sono stati quindi disfatti `_on_boss_defeated_for_experience_reward`,
  `_last_boss_experience_reward` e il valore XP passato a
  `EndScreen.show_victory()`. **Resta valido e in `main`** il resto della card:
  la correzione dell'arità dei due handler di `boss_defeated`
  (`_on_boss_defeated_for_horde_pause`, `_on_boss_defeated_for_barb_reward`),
  che era il regresso reale sul ramo `DEFEAT`. Vedi
  [PS-034](./PS-034-rimuovi-xp-fissa-ricompensa-boss.md).

## Documenti sincronizzati

- [x] `docs/enemies-bosses.md` — sezione "Ricompensa XP del Boss" riscritta
      per descrivere il meccanismo corrente invece della segnalazione del
      bug.

## Note

**Verifica eseguita su Windows il 2026-08-31.** `Relevant` e `Full` sono
passati sull'HEAD che contiene sia il fix di arità sopravvissuto sia la
decisione successiva di PS-034. L'evidenza chiude quindi il regresso runtime
ancora valido senza reintrodurre la ricompensa XP esplicitamente revocata.
Log: `%TEMP%\il-gioco-verification\20260831-225256-PS-039` e
`%TEMP%\il-gioco-verification\20260831-230124-PS-039`.

Priorità alzata da bassa ad alta durante l'implementazione: il regresso
sul ramo `DEFEAT` (handler con arità sbagliata a ogni morte del Boss) e
l'azzeramento silenzioso della ricompensa XP del Boss erano entrambi già in
produzione su `main`, non solo un rischio futuro sul ramo `VICTORY` come
la stesura iniziale della card lasciava intendere.
