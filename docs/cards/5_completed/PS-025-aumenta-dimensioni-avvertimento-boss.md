---
id: PS-025
titolo: Aumenta le dimensioni dell'avvertimento Boss
tipo: ux
area: ui
stato: IN VERIFICA
priorita: media
dipende_da: []
origine: PS-005
creato: 2026-08-30
aggiornato: 2026-09-01
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

- [x] `BOSS IN ARRIVO` è visibilmente più grande rispetto alla versione corrente.
      *`font_size` di `BossWarningLabel` portato da 16 a 23 (+44%); il testo
      del countdown condivide la stessa etichetta. Verificato da
      `test_ps025_boss_warning_size.gd`. La qualità percettiva reale resta un
      gate manuale.*
- [x] Il countdown finale è leggibile durante un'orda densa senza dover fissare
      intenzionalmente l'HUD.
      *`BOSS IN %d` usa la stessa `BossWarningLabel`, quindi eredita
      automaticamente l'aumento; la leggibilità durante un'orda reale resta un
      gate manuale (non automatizzabile).*
- [x] L'avvertimento non copre il Player, i telegraph principali o una
      porzione significativa del playfield.
      *Resta confinato alla fascia HUD superiore (`TopBand`, altezza
      riservata invariata); non si estende nell'area di gioco.*
- [x] L'avvertimento non si sovrappone a XP, HP, timer, pausa o controllo
      abilità.
      *Verificato da `test_ps025_boss_warning_size.gd` (riuso della stessa
      logica di `test_ps005_boss_warning.gd`) su 16:9, 20:9 e 4:3.*
- [x] La Boss Intro resta visivamente più importante dell'avvertimento
      preventivo.
      *Boss Intro non toccata da questa card: nessuna scena o script
      modificato in quell'ambito.*
- [x] Le dimensioni restano corrette su 16:9, 20:9 e 4:3.
      *Verificato da `test_ps025_boss_warning_size.gd` ridimensionando il
      viewport ai tre profili.*
- [x] L'aumento delle dimensioni non modifica timing, countdown o scheduler
      del Boss.
      *Nessun file in `scripts/game/game_director.gd`,
      `game_director_profile.gd` o `data/director_profiles/` toccato; solo
      `scenes/ui/hud.tscn` (geometria/font) e `scripts/ui/hud.gd` (un getter
      di sola lettura per lo smoke).*

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

- Smoke: `tests/unit/test_ps025_boss_warning_size.gd` (GUT). Il percorso
  originale indicato all'apertura, `tests/integration/_boss_warning_layout_smoke.gd`,
  non esiste nel repository dopo il cutover GUT (vedi PS-029).
- Profilo minimo prima della chiusura: `Relevant`
- **Eseguito 2026-09-01:** `.\tools\run-milestone-checks.ps1 -Milestone PS-025
  -Profile Relevant -FocusedSmoke tests/unit/test_ps025_boss_warning_size.gd`
  → `PASS focused=1/1 regression=14/14 steps=15/15`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run fino al warning Boss → verifica `BOSS IN ARRIVO` e countdown durante orda densa)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-08-30 — Il warning Boss deve avere maggiore priorità visiva.** Aumentare dimensioni e leggibilità senza trasformarlo in un modal o in una seconda Boss Intro.
- **Sostituisce:** dimensionamento percettivo corrente dell'avvertimento Boss.
- **2026-09-01 — Il riquadro cresce verso il basso, non verso l'alto.** Il
  `TimerSlot` sopra il warning dichiara un'altezza nominale di 39px ma il
  font `HudTimer` la porta già a 48px reali (il `CenterContainer` rispetta il
  proprio minimo anche in modalità ancoraggio a offset fissi): non c'è
  margine sopra `BossWarningSlot` senza toccare il cronometro. L'aumento del
  font del warning fa quindi crescere `BossWarningSlot` verso il basso per lo
  stesso motivo; verificato che resti comunque dentro la safe area su tutti
  e tre i profili.
- **2026-09-01 — Larghezza dello slot allargata da 640px a 720px.** Margine
  per il countdown/preavviso al font più grande senza rischiare
  troncamenti; non richiesto un limite di riga dal criterio di accettazione.

## Documenti sincronizzati

- [ ] `prd.md` o `CLAUDE.md`, solo se viene formalizzato un nuovo contratto dimensionale della UI.
- [ ] `characters.md`, `powerup-catalog.md` o `content-approvals.md`: non richiesto.
- [ ] Nota `*-verification.md`, se sono state prodotte nuove evidenze.

## Note

Il valore esatto di font size, scala e padding va scelto tramite confronto percettivo su Windows e Pixel 9.
