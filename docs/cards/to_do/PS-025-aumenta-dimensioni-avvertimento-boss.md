---
id: PS-025
titolo: Aumenta le dimensioni dell'avvertimento Boss
tipo: ux
area: ui
stato: PRONTO
priorita: media
dipende_da: []
origine: PS-005
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-025 — Aumenta le dimensioni dell'avvertimento Boss

## Contesto

L'avvertimento che anticipa l'arrivo del Boss è presente ma risulta troppo piccolo rispetto alla quantità di elementi e movimento presenti durante il combattimento.

Il Player deve poterlo percepire senza dover cercare intenzionalmente il testo nell'HUD.

## Comportamento atteso

L'avvertimento `BOSS IN ARRIVO` e il relativo countdown devono avere dimensioni visive maggiori rispetto alla versione corrente.

L'aumento deve interessare il blocco informativo necessario alla lettura dell'avviso senza trasformarlo in una seconda Boss Intro e senza interrompere il gameplay.

L'avviso resta responsive e deve conservare una gerarchia chiara rispetto a XP, HP, timer, pausa e controllo abilità.

## Criteri di accettazione

- [ ] `BOSS IN ARRIVO` è visibilmente più grande rispetto alla versione corrente.
- [ ] Il countdown finale è leggibile durante un'orda densa senza dover fissare intenzionalmente l'HUD.
- [ ] L'avvertimento non copre il Player, i telegraph principali o una porzione significativa del playfield.
- [ ] L'avvertimento non si sovrappone a XP, HP, timer, pausa o controllo abilità.
- [ ] La Boss Intro resta visivamente più importante dell'avvertimento preventivo.
- [ ] Le dimensioni restano corrette su 16:9, 20:9 e 4:3.
- [ ] L'aumento delle dimensioni non modifica timing, countdown o scheduler del Boss.

## Ambito

- UI dell'avvertimento Boss.
- Font size, contenitore, padding e dimensionamento responsive del warning.
- Eventuali costanti presentazionali dedicate.

Non modificare:

- timing di comparsa del warning;
- countdown;
- soglia di spawn del Boss;
- Boss Intro;
- stato della run;
- logica di spawn o selezione del Boss.

## Verifica

- Smoke: `tests/integration/_boss_warning_layout_smoke.gd` → marker `BOSS_WARNING_LAYOUT_SMOKE_OK`
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run fino al warning Boss → verifica `BOSS IN ARRIVO` e countdown durante orda densa)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-08-30 — Il warning Boss deve avere maggiore priorità visiva.** Aumentare dimensioni e leggibilità senza trasformarlo in un modal o in una seconda Boss Intro.
- **Sostituisce:** dimensionamento percettivo corrente dell'avvertimento Boss.

## Documenti sincronizzati

- [ ] `prd.md` o `CLAUDE.md`, solo se viene formalizzato un nuovo contratto dimensionale della UI.
- [ ] `characters.md`, `powerup-catalog.md` o `content-approvals.md`: non richiesto.
- [ ] Nota `*-verification.md`, se sono state prodotte nuove evidenze.

## Note

Il valore esatto di font size, scala e padding va scelto tramite confronto percettivo su Windows e Pixel 9.
