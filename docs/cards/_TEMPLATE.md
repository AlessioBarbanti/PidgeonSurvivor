---
id: PS-000
titolo: Titolo breve e imperativo
tipo: feat            # feat | fix | art | ux | perf | chore
area: gameplay        # gameplay | ui | audio | arte | piattaforma | tooling | docs
stato: PRONTO         # DA DEFINIRE | BLOCCATO | PRONTO | IN CORSO | IN VERIFICA | VERIFICATO | COMPLETATO
priorita: media       # alta | media | bassa
milestone:            # ID B-series collegato, se esiste
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

## Note

Decisioni prese durante la risoluzione, alternative scartate, evidenze.
