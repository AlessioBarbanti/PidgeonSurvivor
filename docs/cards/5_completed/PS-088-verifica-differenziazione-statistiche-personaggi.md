---
id: PS-088
titolo: Verifica automaticamente la differenziazione statistica dei personaggi
tipo: chore
area: tooling
priorita: alta
stato: BLOCCATO
dipende_da: [PS-087]
origine: conversazione del proprietario 2026-09-04
creato: 2026-09-04
aggiornato: 2026-09-04
---

# PS-088 — Verifica automaticamente la differenziazione statistica dei personaggi

## Contesto

[PS-087](./PS-087-definisci-statistiche-base-personaggi.md) fissa gli scarti
di statistiche base per personaggio con una soglia di differenziazione
dichiarata (`0,03` per asse fra ogni coppia). Quella soglia è verificata a
mano una sola volta, al momento della scrittura: un futuro rebalance,
l'aggiunta di un nono personaggio o una modifica distratta a un `.tres`
potrebbe silenziosamente far collassare due profili sullo stesso scarto senza
che nessun test se ne accorga, esattamente come è già successo fra Zat e Aleo.

## Comportamento atteso

Ogni esecuzione della suite rileva automaticamente se due personaggi
condividono uno scarto di statistiche base troppo simile, o se un personaggio
è tornato interamente neutro, così la regola scritta in PS-087 resta vera nel
tempo invece di decadere alla prima modifica successiva.

## Criteri di accettazione

- [ ] Uno smoke GUT legge `base_health_multiplier`,
      `base_move_speed_multiplier` e `base_fire_rate_multiplier` da tutti gli
      otto `data/friends/*.tres` runtime (non valori duplicati a mano nel
      test) e fallisce se una coppia qualunque condivide la stessa tripla
      entro la soglia dichiarata da PS-087.
- [ ] Lo smoke fallisce anche se un personaggio dichiara `1,0` su tutti e tre
      gli assi contemporaneamente.
- [ ] Aggiungere un nuovo personaggio con scarti duplicati o interamente
      neutri fa fallire lo smoke senza richiedere di aggiornarlo a mano: la
      lista dei profili viene scoperta, non elencata staticamente nel test.
- [ ] Lo smoke resta deterministico e non dipende dall'ordine di caricamento
      dei `.tres`.
- [ ] Registrato in `tools/milestone-test-map.json` sul pattern
      `data/friends/*`, così ogni futura modifica a un profilo lo esegue in
      `Relevant`.

## Ambito

- Nuovo `tests/unit/test_ps088_base_stat_differentiation.gd`.
- `tools/milestone-test-map.json`: nuova voce sul pattern `data/friends/*`.

Non toccare:

- `data/friends/*.tres` e i valori decisi da PS-087: questa card verifica,
  non ribilancia;
- `FriendDefinition` e il meccanismo B47;
- statistiche derivate (danno arma, passive, upgrade): la card copre solo i
  tre scarti base dichiarativi.

## Verifica

- Smoke: `tests/unit/test_ps088_base_stat_differentiation.gd` → marker
  `BASE_STAT_DIFFERENTIATION_SMOKE_OK`.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: non richiesto, la card è solo copertura test
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-09-04 — Guardrail permanente, non un audit una tantum.** Il
  proprietario ha chiesto di "controllare" la differenziazione: un controllo
  fatto una sola volta smette di valere alla prima modifica futura, quindi
  questa card lo implementa come test automatico invece che come verifica
  manuale contro `docs/characters.md`.
- **2026-09-04 — Dipende da PS-087.** Non ha senso scrivere la soglia di
  differenziazione prima che PS-087 l'abbia dichiarata: questa card verifica
  quel contratto, non lo inventa.

## Documenti sincronizzati

- [ ] Nessuno: questa card produce solo copertura test, nessun contratto di
      prodotto cambia.

## Note

Nessuna.
