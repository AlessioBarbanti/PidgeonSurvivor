---
id: PS-014
titolo: Riporta il logo della welcome dentro il viewport
tipo: fix
area: ui
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-014 — Riporta il logo della welcome dentro il viewport

## Contesto

Il logo decorativo della welcome screen esce dai confini del viewport su
tutti e tre i profili di layout testati (1280x720, 1600x720, 960x720).
Scoperto durante la migrazione dei test da smoke legacy a GUT; riprodotto
identico rilanciando lo smoke legacy originale (`_welcome_flow_smoke.gd`,
non toccato) in isolamento prima che venisse cancellato: non è quindi un
problema introdotto dalla migrazione.

## Comportamento atteso

Il logo della welcome screen resta interamente contenuto nel viewport (o
nella safe area, a seconda di quale sia il contratto di posizionamento
corretto da confermare) su qualunque aspect ratio supportato.

## Criteri di accettazione

- [ ] Il rettangolo del logo è interamente contenuto nel viewport su
      1280x720.
- [ ] Il rettangolo del logo è interamente contenuto nel viewport su
      1600x720 (20:9 con cutout simulato).
- [ ] Il rettangolo del logo è interamente contenuto nel viewport su
      960x720 (4:3).
- [ ] Il logo resta leggibile e proporzionato su tutti e tre i profili
      (nessun ridimensionamento degenere).

## Ambito

- Scena/script della welcome screen responsabili del posizionamento e
  dimensionamento del logo.

Non modificare:

- il flusso `welcome → tutorial → selezione → run`;
- i pulsanti GIOCA/TUTORIAL/impostazioni e il loro focus.

## Verifica

- Test: `tests/unit/test_b18o_welcome_flow.gd` — fallisce oggi su questo
  controllo per tutti e tre i profili.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: apri la welcome, verifica il logo su
      orientamento e cutout reali del device)
- [ ] Controllo percettivo richiesto: sì
- [ ] Il logo non risulta tagliato o schiacciato su nessun aspect ratio
      provato.

## Decisioni

- **2026-08-30 — Scoperto durante la migrazione GUT, non introdotto da
  essa.** Riprodotto rilanciando lo smoke legacy originale in isolamento
  prima che venisse cancellato: falliva identico.

## Documenti sincronizzati

- [ ] Nessuno previsto; fix visivo interno senza impatto su contratti di
      prodotto.

## Note

Nessuna alternativa scartata: la card nasce da un'osservazione automatica,
il gate percettivo deciderà la soluzione esatta (riscalare, riposizionare o
ridurre il logo).
