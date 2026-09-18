---
id: PS-181
titolo: Il telegraph di attacco del Boss a volte non si risolve in un colpo (visto su Evil Alea)
tipo: fix
area: gameplay
stato: IN CORSO
priorita: alta
dipende_da: []
origine: test reale su Pixel 9 della v0.3.0, 2026-09-15
creato: 2026-09-15
aggiornato: 2026-09-18
---

# PS-181 — Il telegraph di attacco del Boss a volte non si risolve in un colpo (visto su Evil Alea)

## Contesto

Il proprietario segnala che, testando la build reale v0.3.0, il Boss a volte
mostra l'avvertimento (telegraph) di un attacco a proiettili ma poi non
spara — osservato su Evil Alea, non ancora verificato sugli altri Evil o sul
Piccione Malvagio baseline.

In [scripts/bosses/first_boss.gd:564-581](../../../scripts/bosses/first_boss.gd)
(`_advance_attack_cycle`), se durante un telegraph attivo `is_alive()` o
`run_controller.is_running()` risultano falsi anche solo per un frame, la
funzione ritorna subito senza decrementare `_telegraph_remaining` né
chiamare `_execute_active_pattern()`: il telegraph resterebbe "congelato"
visivamente pronto ma non si risolverebbe mai in un colpo né verrebbe
ripulito. Ipotesi di lavoro coerente col sintomo, non confermata: va
verificato se e quando `is_alive()`/`is_running()` possono diventare
transitoriamente falsi mentre un telegraph di Evil Alea è in corso (per
esempio durante una fase di Signature Motion, un cambio di stato legato alla
sua identità, o un'interazione con `RunController` non ancora individuata).

## Comportamento atteso

Ogni telegraph di attacco del Boss si risolve sempre in un colpo effettivo,
oppure viene esplicitamente annullato in modo pulito (nessun residuo
visivo); non resta mai "a metà" senza sparo né pulizia.

## Criteri di accettazione

- [ ] Riprodotto il sintomo (telegraph → nessun colpo) almeno una volta in
      modo deterministico o quasi, su Evil Alea. *Non riprodotto in questa
      sessione: vedi Decisioni. L'unica ipotesi di lavoro registrata (la
      guardia `is_alive()`/`is_running()`) è stata forzata deterministicamente
      e si è rivelata già corretta (atomica, si autoripristina), non la causa
      del sintomo osservato su device.*
- [ ] Identificata la condizione esatta che lo causa (`is_alive()`
      transitorio, `run_controller.is_running()`, interruzione da Signature
      Motion, altro). *Non identificata. L'ipotesi registrata è stata esclusa
      (vedi sopra); la causa reale resta sconosciuta e richiede probabilmente
      telemetria da un playtest reale su Pixel 9 (stesso approccio già usato
      per PS-127, marker `PS_BALANCE_TELEMETRY`), non ulteriori ipotesi alla
      cieca da codice statico.*
- [x] Corretto senza introdurre colpi "fantasma" quando il Boss muore
      davvero durante un telegraph: quel caso deve restare pulito (nessun
      proiettile sparato da un Boss già sconfitto). *Verificato che il
      comportamento attuale è già corretto (nessuna correzione necessaria) e
      ora è coperto da un test di regressione permanente
      (`test_boss_death_during_paused_telegraph_produces_no_phantom_shot`).*
- [ ] Verificato su almeno due Evil diversi oltre ad Alea, e sul Piccione
      Malvagio baseline, non solo sul caso segnalato. *Coperto solo per
      l'ipotesi esclusa (Alea, Magno, Marghe + baseline, automatico). Il
      sintomo reale su device, se ha un'altra causa, resta da verificare lì.*

## Ambito

- `scripts/bosses/first_boss.gd` (`_advance_attack_cycle`,
  `_begin_next_pattern`, `_execute_active_pattern`, gestione di
  `is_alive()`/`run_controller` durante un telegraph attivo).
- Eventuali script di Signature specifici di Alea, se la causa è lì.
- Non toccare il contratto "nessun telegraph" del Tiratore (PS-158): è
  un'entità diversa (nemico ordinario, non Boss) e non è in discussione qui.

## Verifica

- Nuovo test GUT che forza le condizioni sospette (`is_alive()`/
  `is_running()` transitori) durante un telegraph attivo e verifica che si
  risolva sempre in un colpo o in una pulizia esplicita.
- Profilo minimo prima della chiusura: `Relevant`.
- **Eseguito** (sandbox remoto Linux via `tools/setup-remote-sandbox.sh`,
  Godot 4.7.1 headless — non sostituisce i runner Windows/Android): nuovo
  `tests/unit/test_ps181_boss_telegraph_survives_pause.gd` (7 casi,
  registrato in `tools/milestone-test-map.json` nel gruppo
  `data/bosses/*`/`scripts/bosses/*`), che forza deterministicamente un
  LEVEL_UP esattamente a cavallo della scadenza di ogni tipo di telegraph
  (Raffica Radiale e Area Mirata sul baseline, telegraph *e* stream della
  Scia di Piume sul baseline, Signature di Evil Alea/Magno/Marghe) e la
  morte del Boss durante un telegraph in pausa: `7/7 passed`. Relevant
  completo del gruppo Boss con il nuovo test incluso: `84/84 passed`, nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION` nei log. **Nessuna delle prove ha
  riprodotto il sintomo**: la guardia esistente è risultata già atomica e
  corretta in ogni caso forzato, quindi nessuna modifica di comportamento è
  stata necessaria — il test resta come regressione permanente su
  un'ipotesi ora esclusa, non come fix di un difetto trovato.

## Gate manuali

- [ ] Runtime Windows — non pertinente finché la causa reale non è
      identificata: non c'è ancora un fix da validare.
- [ ] Validazione statica APK — idem.
- [ ] Runtime fisico Pixel 9 (gate primario: il sintomo è stato riportato
      lì, su Evil Alea) — resta il modo più concreto per avanzare: serve
      riprodurre il sintomo con logging temporaneo (pattern attivo, stato
      `RunController`, `is_alive()`) per catturare la condizione reale invece
      di ipotizzarla da codice statico.
- [ ] Controllo percettivo richiesto: sì — "il colpo non è mai mancato" va
      confermato in gioco reale su più Evil, non solo dal test automatico

## Decisioni

- **2026-09-15 — Ipotesi di lavoro sulla guardia di `_advance_attack_cycle`.**
  Da confermare con un caso riprodotto prima di modificare la logica alla
  cieca; se la causa reale è un'altra, aggiornare questa decisione.
- **2026-09-18 — Ipotesi esclusa dopo indagine statica e test forzato.**
  `FirstBoss` eredita `process_mode = PROCESS_MODE_ALWAYS` da `BossEncounter`
  ([scripts/bosses/boss_encounter.gd:58](../../../scripts/bosses/boss_encounter.gd)),
  quindi il suo `_physics_process` gira anche quando `RunController` mette in
  pausa lo `SceneTree` (ogni stato diverso da `BOOT`/`RUNNING`, incluso ogni
  `LEVEL_UP` durante un combattimento Boss — molto comune, un personaggio
  tipico sale ~9-10 livelli in una run). La guardia in cima a
  `_advance_attack_cycle` (`is_alive()`/`run_controller.is_running()`) è
  quindi realmente esercitata a ogni level-up incontrato durante un Boss, non
  solo teoricamente. Il test `test_ps181_boss_telegraph_survives_pause.gd`
  forza esattamente questa condizione — un `LEVEL_UP` richiesto con il
  telegraph a un frame dalla scadenza — su Raffica Radiale, Area Mirata,
  telegraph e stream della Scia di Piume (baseline) e Signature di tre Evil
  diversi (Alea/Magno/Marghe): in ogni caso il telegraph resta congelato
  esattamente dov'era durante la pausa e si risolve correttamente e una sola
  volta alla ripresa, senza mai un conteggio a zero. La guardia è atomica per
  costruzione (il controllo avviene prima di qualunque decremento o
  esecuzione, in un solo `return`), quindi non esiste una finestra in cui
  possa "consumare" un telegraph senza eseguirlo. **Questa non è quindi la
  causa del sintomo riportato dal proprietario**: la vera causa resta da
  identificare, verosimilmente con telemetria da un playtest reale (stesso
  approccio del marker temporaneo `PS_BALANCE_TELEMETRY` usato per PS-127),
  non con ulteriori ipotesi statiche. La card resta aperta (`IN CORSO`) con
  questo vicolo cieco documentato, invece di essere chiusa su una correzione
  che non correggerebbe nulla di reale.

## Documenti sincronizzati

- [ ] `docs/enemies-bosses.md` se la diagnosi rivela un contratto di timing
      da formalizzare oltre quanto già scritto.

## Note

Segnalato dal proprietario durante il test reale su Pixel 9 della v0.3.0,
insieme ad altri cinque problemi nella stessa sessione (PS-178..PS-180,
PS-182, PS-183).
