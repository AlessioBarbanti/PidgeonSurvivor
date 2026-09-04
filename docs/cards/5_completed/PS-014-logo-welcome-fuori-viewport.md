---
id: PS-014
titolo: Riporta il logo della welcome dentro il viewport
tipo: fix
area: ui
stato: IN VERIFICA
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

- [x] Il rettangolo del logo è interamente contenuto nel viewport su
      1280x720.
- [x] Il rettangolo del logo è interamente contenuto nel viewport su
      1600x720 (20:9 con cutout simulato).
- [x] Il rettangolo del logo è interamente contenuto nel viewport su
      960x720 (4:3).
- [x] Il logo resta leggibile e proporzionato su tutti e tre i profili
      (nessun ridimensionamento degenere): dimensioni e aspect ratio del
      `WelcomeLogo` non toccati, solo la posizione verticale del blocco
      centrato è cambiata.

Automatico verificato con `-Profile Focused` e `-Profile Relevant`
(`-FocusedSmoke tests/unit/test_b18o_welcome_flow.gd`, 7/7 test di
regressione verdi incluse le card PS-016 collegate); i gate manuali sotto
restano aperti.

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
- **2026-08-30 — Contratto confermato: il logo resta ancorato al
  viewport, non alla safe area.** Il logo è decorativo (nessun target
  touch), quindi può sporgere oltre la safe area verso i bordi fisici; il
  criterio corretto è restare interamente visibile nel viewport, come già
  scritto nel test (`viewport_rect.encloses(logo_rect)`), non nella safe
  area più stretta.
- **2026-08-30 — Causa: il logo sporge 87px sopra `TitlePlaque` per
  design (l'immagine include margine per il payoff sotto il testo), e il
  centraggio verticale puro di `ContentPanel` (via `CenterContainer`
  prima di PS-016, poi via lo stesso calcolo esplicito in
  `welcome_screen.gd`: le due formule producono le stesse coordinate) non
  teneva conto di questa sporgenza.** Il difetto è confermato pre-PS-016
  (riprodotto anche sul codice precedente con `git stash`). Su tutti e
  tre i profili testati (safe area alta 680px) il centraggio piazzava
  `ContentPanel` a y=67, portando il top del logo a y=-20 (fuori
  viewport).
- **2026-08-30 — Fix: calcolato lo spazio minimo dall'alto dalla
  geometria reale di `TitlePlaque`/`WelcomeLogo`, non con una costante.**
  Aggiunta `_minimum_content_panel_top()` in `welcome_screen.gd`, che
  deriva la sporgenza dalle posizioni locali correnti dei nodi (si
  adegua da sola se il logo o l'insegna cambiano dimensione in futuro) e
  la usa come pavimento per il centraggio verticale di `ContentPanel`
  (l'unico punto ormai responsabile di quel calcolo, dopo la riscrittura
  di PS-016). Il resto della geometria (gap logo/azioni, ingranaggio
  impostazioni) è invariato perché lo spostamento è uniforme su tutto il
  blocco.

## Documenti sincronizzati

- [ ] Nessuno previsto; fix visivo interno senza impatto su contratti di
      prodotto.

## Note

Nessuna alternativa scartata: la card nasce da un'osservazione automatica,
il gate percettivo deciderà la soluzione esatta (riscalare, riposizionare o
ridurre il logo).
