---
id: PS-039
titolo: API mancante su BossEncounter nel ramo VICTORY dell'EndScreen
tipo: fix
area: gameplay
stato: PRONTO
priorita: bassa
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-039 — API mancante su `BossEncounter` nel ramo `VICTORY` dell'EndScreen

## Contesto

Scoperta durante la ricognizione per PS-038 (documentazione di game design),
non nel suo ambito perché quella card è di sola documentazione.

`scripts/game/movement_slice.gd:1788-1798` (`_show_terminal_screen`), ramo
`RunController.RunState.VICTORY`:

```gdscript
RunController.RunState.VICTORY:
    _end_screen.show_victory(
        run_time,
        _boss_encounter.get_last_defeated_title(),
        _boss_encounter.get_last_experience_reward()
    )
```

`BossEncounter` (`scripts/bosses/boss_encounter.gd`) espone
`get_last_defeated_title()` ma **non** `get_last_experience_reward()`: il
metodo non esiste in nessun file del repository (verificato via grep su
`scripts/`). Se questo ramo venisse mai eseguito, la chiamata fallirebbe a
runtime.

Non è oggi un difetto osservabile: `RunController.request_victory()` non è
invocato da alcuno script di produzione (solo dai test), quindi lo stato
`VICTORY` è dormiente nella vertical slice attuale (vedi
`docs/systems-difficulty.md`). È comunque un'API rotta che romperebbe il
primo utilizzo reale di `VICTORY`, quando/se una condizione di vittoria
verrà cablata.

Correlata: `data/bosses/first_boss.tres` dichiara `experience_reward = 50`,
ma `BossDefinition` non ha alcun campo con quel nome — è un valore dati
orfano, ignorato al load. La XP reale del Boss viene invece da
`scenes/actors/first_boss.tscn:31` (`experience_amount = 50` di
`BaseEnemy`). Non è detto che la soluzione debba passare da
`BossDefinition`: potrebbe bastare far leggere a `_show_terminal_screen` la
ricompensa già nota altrove (es. dal segnale `boss_defeated` o da
`BaseEnemy.get_experience_reward_value()`), invece di aggiungere un metodo
nuovo a `BossEncounter`.

## Comportamento atteso

Il ramo `VICTORY` di `_show_terminal_screen` compila ed esegue senza
chiamare API inesistenti, mostrando in `EndScreen` una ricompensa XP
coerente con quella realmente assegnata dal Boss appena sconfitto.

## Criteri di accettazione

- [ ] `_show_terminal_screen` non chiama più `get_last_experience_reward()`
      su `BossEncounter` (o il metodo viene aggiunto con un'implementazione
      reale, a scelta di chi implementa — vedi Note per l'alternativa).
- [ ] Il valore passato a `EndScreen.show_victory` corrisponde alla
      ricompensa XP realmente assegnata alla morte dell'ultimo Boss (non un
      valore fisso o il campo orfano `experience_reward` del `.tres`).
- [ ] Il ramo `DEFEAT` di `_show_terminal_screen` non cambia comportamento.
- [ ] Nessuna modifica al valore XP realmente erogato al giocatore: è un fix
      dell'API di lettura per la UI, non del bilanciamento.

## Ambito

- `scripts/game/movement_slice.gd` (`_show_terminal_screen`).
- `scripts/bosses/boss_encounter.gd`, solo se la soluzione scelta aggiunge
  un metodo reale invece di leggere il valore da un'altra fonte già
  disponibile.

Non modificare:

- `data/bosses/first_boss.tres` (il campo `experience_reward` orfano può
  restare tale o essere ripulito in una card a parte se si decide di
  ricollegarlo a `BossDefinition`; non è richiesto da questa card);
- alcuna probabilità, statistica o pattern Boss;
- lo stato `VICTORY` stesso o le condizioni che lo raggiungono: questa card
  corregge solo la UI di un ramo già esistente, non introduce una condizione
  di vittoria.

## Verifica

- Test: nuovo `tests/unit/test_ps039_boss_victory_reward.gd` (o estensione
  di un test Boss esistente) che invoca `request_victory()` direttamente
  (come già fanno altri test) e verifica che `_show_terminal_screen` non
  sollevi errori e che `EndScreen` mostri la ricompensa corretta.
- Profilo minimo prima della chiusura: `Relevant` con
  `-FocusedSmoke tests/unit/test_ps039_boss_victory_reward.gd`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK — non pertinente, nessuna superficie Android
      specifica.
- [ ] Runtime fisico Pixel 9 — non richiesto, `VICTORY` resta dormiente in
      produzione anche dopo il fix.
- [ ] Controllo percettivo richiesto: no.

## Decisioni

- **2026-08-31 — Scoperta durante PS-038, aperta come card separata.** La
  ricognizione per la documentazione di game design non modifica codice: il
  problema va corretto in una card dedicata invece di allargare PS-038.

## Documenti sincronizzati

- [ ] Nessuno atteso: correzione interna, nessun contratto pubblico cambia.

## Note

Priorità bassa perché il ramo non è oggi raggiungibile in produzione: non è
urgente, ma lasciarlo rotto significa che il giorno in cui `VICTORY` verrà
cablato per davvero, l'EndScreen di vittoria fallirà silenziosamente o con
`SCRIPT ERROR` al primo utilizzo.
