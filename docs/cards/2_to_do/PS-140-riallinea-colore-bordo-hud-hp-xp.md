---
id: PS-140
titolo: Riallinea il colore del bordo HP/XP alla palette oro esistente
tipo: fix
area: ui
stato: PRONTO
priorita: bassa
dipende_da: []
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-140 — Riallinea il colore del bordo HP/XP alla palette oro esistente

## Contesto

Le barre HP e XP nell'HUD (`scenes/ui/hud.tscn`,
`StyleBoxFlat_bar_background`) hanno `border_color = Color(0.49, 0.39, 0.24,
1)`, un marrone/tan desaturato che risulta una tinta isolata rispetto alla
famiglia oro già usata altrove nella stessa vista (bottone pausa `Color(0.72,
0.52, 0.24, 1)`, focus delle carte upgrade `Color(1, 0.84, 0.25, 1)`, anello
di carica dell'indicatore Alea). Consultato in merito, il direttore-artistico
conferma che il trattamento piatto e sottile del bordo va mantenuto — l'HUD è
permanente durante l'azione e non deve appesantirsi con la cornice a rivetti
riservata a modali/overlay non permanenti — ma il valore cromatico va
riportato dentro la famiglia oro invece di restare una tinta a sé.

## Comportamento atteso

Il bordo delle barre HP/XP resta piatto e sottile come oggi, ma il suo colore
appartiene visivamente alla stessa famiglia oro/bronzo usata dal bottone
pausa e dagli altri accenti dorati dell'HUD, invece di leggersi come una
tinta scollegata.

## Criteri di accettazione

- [ ] `border_color` di `StyleBoxFlat_bar_background` (barre HP e XP) non è
      più `Color(0.49, 0.39, 0.24, 1)`: il nuovo valore è percepibilmente
      nella stessa famiglia oro del bordo del bottone pausa
      (`Color(0.72, 0.52, 0.24, 1)`) o del bronzo già documentato per
      l'indicatore Alea in `docs/visual-audio-identity.md`.
- [ ] Il bordo resta uno `StyleBoxFlat` piatto (nessuna cornice a rivetti o
      texture aggiunta): la forma non cambia, solo il colore.
- [ ] Il contrasto fra il bordo e il riempimento delle barre (blu XP, rosso
      HP) resta leggibile quanto oggi a colpo d'occhio durante il gameplay
      attivo.

## Ambito

- File atteso: `scenes/ui/hud.tscn` (`StyleBoxFlat_bar_background`).
- Non toccare: `StyleBoxFlat_pause_normal`/`_hover`/`_disabled` (già nella
  famiglia oro corretta, restano riferimento), il layout o la logica di
  riempimento delle barre in `scripts/ui/hud.gd`, l'indicatore Alea
  (PS-138, già trattato con la propria palette).

## Verifica

- Smoke: `tests/unit/test_ps140_hud_bar_border_color.gd` → marker
  `PS140_HUD_BAR_BORDER_OK`, verifica che il `border_color` dello StyleBox
  delle barre HP/XP non sia più il valore marrone attuale.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: leggibilità HUD a schermo pieno in
      combattimento)
- [ ] Controllo percettivo richiesto: sì — confronto screenshot
      `04_gameplay_hud.png` prima/dopo

## Decisioni

- **2026-09-10 — Consultato il direttore-artistico prima di aprire la card**
  (richiesta del proprietario dopo revisione screenshot). Ha confermato che
  il bordo piatto per l'HUD permanente è corretto (la cornice a rivetti resta
  riservata a overlay/modali non permanenti) e che il problema è solo il
  valore cromatico, non la forma del bordo.

## Documenti sincronizzati

- [ ] `docs/visual-audio-identity.md` — il direttore-artistico propone di
      fissare esplicitamente la regola "HUD permanente = bordo piatto,
      overlay/modali = cornice a rivetti", oggi solo implicita nel codice.
      Sincronizzare insieme a PS-139 se entrambe confermano la stessa regola.

## Note

Valore di riferimento indicato dal direttore-artistico:
`Color(0.72, 0.52, 0.24, 1)` (bottone pausa) o il bronzo `#A67B35` già
documentato per l'anello Alea — la scelta esatta fra i due resta a
`card-risolvi` in base a quale risulta più leggibile in gioco.
