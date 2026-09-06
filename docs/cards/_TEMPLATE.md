---
id: PS-000
titolo: Titolo breve e imperativo
tipo: feat            # feat | fix | art | ux | perf | chore
area: gameplay        # gameplay | ui | audio | arte | piattaforma | tooling | docs
stato: PRONTO         # DA DEFINIRE | BLOCCATO | PRONTO | IN CORSO | IN ATTESA ASSET | IN VERIFICA | COMPLETATO | SCARTATA
priorita: media       # alta | media | bassa
dipende_da: []        # ID card, per esempio [PS-003, PS-008]
origine:              # riferimento storico facoltativo, per esempio B23
creato: 2026-08-29
aggiornato: 2026-08-29
---

# PS-000 — Titolo breve e imperativo

## Contesto

Cosa succede oggi e perché non va bene. Due o tre frasi, niente storia del
progetto.

## Comportamento atteso

Cosa deve succedere dopo la modifica, in termini osservabili da chi gioca.

## Criteri di accettazione

- [ ] Criterio verificabile, non una descrizione di implementazione.
- [ ] Un criterio per riga, ognuno vero o falso senza interpretazione.

## Ambito

- File o sistemi che ci si aspetta di toccare.
- Contratti che **non** vanno cambiati.

## Verifica

- Smoke: `tests/integration/_<nome>_smoke.gd` → marker `<NOME>_SMOKE_OK`
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: ...)
- [ ] Controllo percettivo richiesto: sì/no

## Decisioni

- **YYYY-MM-DD — Decisione.** Motivazione e conseguenze osservabili.
- **Sostituisce:** card o decisione precedente, se applicabile.

Le decisioni restano nella card. Se cambiano il contratto corrente, riportare
solo il risultato nel documento durevole pertinente.

## Documenti sincronizzati

- [ ] `prd.md` o `CLAUDE.md`, se cambia un contratto di prodotto/architettura.
- [ ] `characters.md`, `powerup-catalog.md` o `content-approvals.md`, se cambia
      un catalogo o un'approvazione.
- [ ] Nota `*-verification.md`, se sono state prodotte nuove evidenze.

## Note

Alternative scartate, comandi, marker ed evidenze puntuali.
