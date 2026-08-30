---
id: PS-026
titolo: Rinomina Piccione Speciale in Piccione Malvagio
tipo: chore
area: gameplay
stato: PRONTO
priorita: media
dipende_da: []
origine: B22
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-026 — Rinomina Piccione Speciale in Piccione Malvagio

## Contesto

Il Boss baseline viene ancora presentato con il nome `Piccione Speciale`.

Il nome non comunica correttamente il ruolo antagonista del Boss e deve essere sostituito con **Piccione Malvagio**.

## Comportamento atteso

Ogni testo pubblico che identifica il Boss baseline come `Piccione Speciale` deve mostrare **Piccione Malvagio**.

La modifica riguarda il nome visibile al giocatore e la documentazione autorevole. ID tecnici, path e riferimenti interni possono restare invariati quando la loro modifica non è necessaria al risultato pubblico.

Le varianti `Evil <Nome>` restano invariate.

## Criteri di accettazione

- [ ] La Boss Intro mostra `Piccione Malvagio` per il Boss baseline.
- [ ] Ogni altra UI runtime che mostra il nome del Boss baseline usa `Piccione Malvagio`.
- [ ] Nessun testo pubblico runtime mostra ancora `Piccione Speciale`.
- [ ] Le controparti `Evil <Nome>` conservano i propri nomi.
- [ ] Il cambio di nome non modifica statistiche, sprite, hitbox, pattern o probabilità di selezione del Boss.
- [ ] Gli ID tecnici e i path non vengono rinominati senza una necessità esplicita.
- [ ] Restart e selezione seedata dei Boss restano invariati.

## Ambito

- `BossDefinition` del Boss baseline.
- Copy della Boss Intro e delle UI che mostrano il nome.
- Documentazione che usa il nome pubblico del Boss baseline.
- Test di contenuto relativi ai Boss.

Non modificare:

- asset grafico del Boss;
- probabilità di sostituzione con un `Evil <Nome>`;
- pattern e statistiche;
- ID tecnici stabili salvo necessità dimostrata;
- nomi delle varianti Evil.

## Verifica

- Smoke: `tests/integration/_evil_pigeon_name_smoke.gd` → marker `EVIL_PIGEON_NAME_SMOKE_OK`
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: genera Boss baseline → verifica nome in Boss Intro e HUD)
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-08-30 — Il Boss baseline si chiama pubblicamente `Piccione Malvagio`.** Il precedente nome `Piccione Speciale` viene rimosso dal copy rivolto al giocatore.
- **Sostituisce:** nome pubblico `Piccione Speciale`.

## Documenti sincronizzati

- [ ] `prd.md`, se contiene il nome pubblico precedente.
- [ ] `content-approvals.md`, se il nome del Boss baseline è registrato nel catalogo approvato.
- [ ] Nota `*-verification.md`, se sono state prodotte nuove evidenze.

## Note

Preferire un cambio di contenuto localizzato. Non rinominare automaticamente file e ID storici solo per uniformarli al nuovo copy.
