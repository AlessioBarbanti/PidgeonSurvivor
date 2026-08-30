---
id: PS-024
titolo: Riduci il danno dell'Onda d'Urto di Magno
tipo: fix
area: gameplay
stato: PRONTO
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

- [ ] Al rank 1, un nemico comune standard a vita piena non viene eliminato da una singola Onda d'Urto Tellurica.
- [ ] Il danno dell'Onda d'Urto resta nettamente inferiore al danno necessario per usarla come principale fonte di clear dell'orda.
- [ ] I nemici colpiti vengono respinti in modo chiaramente percepibile.
- [ ] Il momentum continua a modificare l'efficacia dell'abilità secondo il contratto corrente.
- [ ] L'effetto del momentum non rende il danno il beneficio principale dell'abilità.
- [ ] Cooldown, raggio, telegraph e input dell'attiva restano invariati salvo modifica esplicitamente necessaria al bilanciamento.
- [ ] I Boss continuano a ricevere il comportamento di danno e knockback previsto dai contratti esistenti senza introdurre one-shot o regressioni.
- [ ] Restart e cambio personaggio ripristinano i valori runtime corretti.

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

- Smoke: `tests/integration/_magno_shockwave_balance_smoke.gd` → marker `MAGNO_SHOCKWAVE_BALANCE_SMOKE_OK`
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: Magno → attiva rank 1 contro nemici comuni a vita piena → ripeti con momentum basso e alto)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-08-30 — Onda d'Urto Tellurica torna a essere prima di tutto controllo.** Il danno resta presente ma leggero; il knockback deve essere il beneficio principale e l'abilità non deve funzionare come clear istantaneo dei nemici comuni.
- **Sostituisce:** il bilanciamento corrente in cui il danno dell'attiva può one-shottare i nemici comuni.

## Documenti sincronizzati

- [ ] `prd.md`, se cambiano i valori autorevoli dell'abilità.
- [ ] `characters.md` e `content-approvals.md`, solo se cambia il copy pubblico o il contratto descrittivo.
- [ ] Nota `*-verification.md`, se sono state prodotte nuove evidenze.

## Note

Non fissare in questa card un nuovo valore numerico definitivo: il danno corretto va scelto tramite playtest mantenendo fermo il principio **knockback forte + danno leggero**.
