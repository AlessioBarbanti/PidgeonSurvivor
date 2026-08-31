---
id: PS-024
titolo: Riduci il danno dell'Onda d'Urto di Magno
tipo: fix
area: gameplay
stato: IN CORSO
priorita: alta
dipende_da: []
origine: B45
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-024 — Riduci il danno dell'Onda d'Urto di Magno

## Contesto

L'Onda d'Urto Tellurica di Magno infligge attualmente abbastanza danno da eliminare in un solo colpo nemici comuni, facendo percepire l'abilità soprattutto come fonte di burst damage.

L'identità desiderata è invece controllo dell'orda: il knockback deve essere il valore principale dell'attiva e il danno deve restare secondario.

## Comportamento atteso

L'Onda d'Urto Tellurica continua a danneggiare i nemici vicini, ma il danno viene ridotto in modo che l'abilità sia usata principalmente per creare spazio e riposizionare l'orda.

Il momentum di Magno continua a potenziare l'abilità secondo il contratto corrente, ma non deve trasformare sistematicamente l'Onda d'Urto in un attacco che elimina istantaneamente i nemici comuni a vita piena.

Il knockback deve restare chiaramente percepibile e rappresentare l'effetto dominante dell'attivazione.

## Criteri di accettazione

- [x] Al rank 1, un nemico comune standard a vita piena non viene eliminato da una singola Onda d'Urto Tellurica. Danno rank 1 ridotto da `20` a `8` (< `18` HP del piccione base), verificato da
      `test_ps024_magno_shockwave_balance.gd`.
- [x] Il danno dell'Onda d'Urto resta nettamente inferiore al danno necessario per usarla come principale fonte di clear dell'orda. Danno massimo a slancio pieno (rank 5, il rank più alto): `11 × 1.5 = 16.5`, sempre sotto i `18` HP del piccione base e ben sotto `armored` (`54`) e `splitter` (`26`).
- [x] I nemici colpiti vengono respinti in modo chiaramente percepibile. `knockback_force` invariato (`300`–`380` a seconda del rank): non toccato da questa card.
- [x] Il momentum continua a modificare l'efficacia dell'abilità secondo il contratto corrente. `momentum_damage_bonus_max`/`momentum_knockback_bonus_max` e la formula in `_apply_earthquake_to_targets` non sono stati modificati.
- [x] L'effetto del momentum non rende il danno il beneficio principale dell'abilità. Anche a slancio pieno e rank massimo, il danno resta sotto la vita di un nemico comune standard (vedi sopra).
- [x] Cooldown, raggio, telegraph e input dell'attiva restano invariati salvo modifica esplicitamente necessaria al bilanciamento. Solo `damage` è stato toccato per ogni rank; `cooldown_seconds` e `area_radius` sono identici a prima.
- [x] I Boss continuano a ricevere il comportamento di danno e knockback previsto dai contratti esistenti senza introdurre one-shot o regressioni. L'attiva di Magno resta un'abilità del roster giocabile; le Signature Ability Boss (PS-006) hanno parametri propri e separati in `data/bosses/signatures/*.tres`, non toccati da questa card.
- [x] Restart e cambio personaggio ripristinano i valori runtime corretti. Nessun nuovo stato runtime introdotto: i valori restano quelli dichiarati nella `Resource` `.tres`, letti freschi a ogni equip come per ogni altra abilità.

## Ambito

- Definizione dati di Onda d'Urto Tellurica.
- Parametri di danno e scaling con il momentum.
- Test di bilanciamento dell'attiva di Magno.
- Eventuali descrizioni pubbliche che presentano l'abilità come strumento di controllo.

Non modificare:

- accumulo e decadimento del momentum di Magno;
- identità della passiva Flusso Aerodinamico Bovino;
- meccanica di knockback;
- input, cooldown e sistema generale dei rank delle abilità;
- comportamento delle altre abilità attive.

## Verifica

- Test: `tests/unit/test_ps024_magno_shockwave_balance.gd` (`extends
  GutGameplayTest`). La card indicava originariamente uno smoke a script
  `SceneTree` in `tests/integration/`: quel contratto non è la convenzione
  corrente (vedi `docs/verification-workflow.md`, tutti i test vivono in
  `tests/unit/test_*.gd` con report GUT), quindi la formulazione è corretta
  qui invece di crearne uno stile obsoleto.
- Registrato in `tools/milestone-test-map.json` sotto la regola
  `scripts/abilities/*` / `data/abilities/*`.
- Profilo minimo prima della chiusura: `Relevant` con
  `-FocusedSmoke tests/unit/test_ps024_magno_shockwave_balance.gd`
  (non ancora eseguito, vedi Note).

## Gate manuali

- [ ] Runtime Windows — necessario prima di `COMPLETATO`: nessun Godot
      disponibile in questa sessione per eseguirlo.
- [ ] Validazione statica APK — non pertinente, nessuna superficie Android
      specifica.
- [ ] Runtime fisico Pixel 9 (percorso: Magno → attiva rank 1 contro nemici
      comuni a vita piena → ripeti con momentum basso e alto) — richiesto dal
      `Controllo percettivo`, non eseguito in questa sessione.
- [ ] Controllo percettivo richiesto: sì — il "feel" di knockback-dominante
      va confermato a schermo, non solo per lettura dei numeri.

## Decisioni

- **2026-08-30 — Onda d'Urto Tellurica torna a essere prima di tutto controllo.** Il danno resta presente ma leggero; il knockback deve essere il beneficio principale e l'abilità non deve funzionare come clear istantaneo dei nemici comuni.
- **Sostituisce:** il bilanciamento corrente in cui il danno dell'attiva può one-shottare i nemici comuni.
- **2026-08-31 — Solo `damage` toccato, per ogni rank.** `knockback_force`,
  `momentum_damage_bonus_max`, `momentum_knockback_bonus_max`,
  `cooldown_seconds`, `area_radius` e `stun_duration` restano identici: la
  card corregge il bilanciamento del danno, non la formula del momentum né
  la meccanica di knockback.
- **2026-08-31 — Valore scelto per playtest, non definitivo.** Danno per
  rank: `8 / 9 / 9 / 9 / 11` (era `20 / 26 / 26 / 26 / 36`), scelto perché
  anche a rank 5 con slancio pieno (`11 × 1,5 = 16,5`) resta sotto i `18` HP
  del piccione base — mai un clear garantito nemmeno al massimo
  investimento. Resta soggetto a conferma con playtest reale (vedi Note).

## Documenti sincronizzati

- [ ] `prd.md`, se cambiano i valori autorevoli dell'abilità — non
      aggiornato: `prd.md` non elenca i valori numerici di rank delle
      abilità attive (solo la descrizione qualitativa in 3.4), quindi resta
      accurato senza modifiche.
- [ ] `characters.md` e `content-approvals.md`, solo se cambia il copy
      pubblico o il contratto descrittivo — non richiesto: la descrizione
      "Genera un'onda d'urto che danneggia e respinge i nemici vicini" resta
      vera, solo l'intensità del danno cambia.
- [ ] Nota `*-verification.md`, se sono state prodotte nuove evidenze — non
      applicabile, nessuna verifica Windows/Android eseguita in questa
      sessione.

## Note

Non fissare in questa card un nuovo valore numerico definitivo: il danno corretto va scelto tramite playtest mantenendo fermo il principio **knockback forte + danno leggero**.

**Verifica non eseguita.** Il fix è stato implementato e controllato per
lettura (valori dati, formula del momentum invariata, nuovo test), ma non è
stato lanciato `run-milestone-checks.ps1`: nessun Godot/PowerShell
disponibile in questo ambiente. Il profilo `Relevant` su Windows e il
controllo percettivo su device restano i gate aperti prima di poter chiudere
la card `COMPLETATO`.
