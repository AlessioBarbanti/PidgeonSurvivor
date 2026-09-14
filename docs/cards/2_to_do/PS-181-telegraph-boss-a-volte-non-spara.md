---
id: PS-181
titolo: Il telegraph di attacco del Boss a volte non si risolve in un colpo (visto su Evil Alea)
tipo: fix
area: gameplay
stato: PRONTO
priorita: alta
dipende_da: []
origine: test reale su Pixel 9 della v0.3.0, 2026-09-15
creato: 2026-09-15
aggiornato: 2026-09-15
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
      modo deterministico o quasi, su Evil Alea.
- [ ] Identificata la condizione esatta che lo causa (`is_alive()`
      transitorio, `run_controller.is_running()`, interruzione da Signature
      Motion, altro).
- [ ] Corretto senza introdurre colpi "fantasma" quando il Boss muore
      davvero durante un telegraph: quel caso deve restare pulito (nessun
      proiettile sparato da un Boss già sconfitto).
- [ ] Verificato su almeno due Evil diversi oltre ad Alea, e sul Piccione
      Malvagio baseline, non solo sul caso segnalato.

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

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (gate primario: il sintomo è stato riportato
      lì, su Evil Alea)
- [ ] Controllo percettivo richiesto: sì — "il colpo non è mai mancato" va
      confermato in gioco reale su più Evil, non solo dal test automatico

## Decisioni

- **2026-09-15 — Ipotesi di lavoro sulla guardia di `_advance_attack_cycle`.**
  Da confermare con un caso riprodotto prima di modificare la logica alla
  cieca; se la causa reale è un'altra, aggiornare questa decisione.

## Documenti sincronizzati

- [ ] `docs/enemies-bosses.md` se la diagnosi rivela un contratto di timing
      da formalizzare oltre quanto già scritto.

## Note

Segnalato dal proprietario durante il test reale su Pixel 9 della v0.3.0,
insieme ad altri cinque problemi nella stessa sessione (PS-178..PS-180,
PS-182, PS-183).
