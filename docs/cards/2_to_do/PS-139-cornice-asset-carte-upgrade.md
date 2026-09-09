---
id: PS-139
titolo: Applica la cornice asset esistente alle carte upgrade
tipo: ux
area: ui
stato: PRONTO
priorita: bassa
dipende_da: []
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-139 — Applica la cornice asset esistente alle carte upgrade

## Contesto

Le tre carte di scelta upgrade (`scenes/ui/upgrade_card.tscn`) usano uno
`StyleBoxFlat` piatto (bordo 3px uniforme, `border_color = Color(0.19, 0.48,
0.68, 0.9)`), mentre il modale pausa e il bottone azione della selezione
personaggio usano già `assets/art/ui/pause/pause_panel_frame.png`, una
texture nine-slice dorata a rivetti pensata per essere riusata. Consultato in
merito, il direttore-artistico conferma che le carte upgrade — l'unico
momento "premiante" della UI — sono rimaste nel linguaggio grezzo delle prime
iterazioni mentre pausa, selezione personaggio e boss intro sono già passate
alla cornice asset: è drift di produzione, non solo estetico.

## Comportamento atteso

Le carte upgrade mostrano un trattamento di cornice coerente con l'estetica
dorata a rivetti già stabilita altrove nella UI, senza risultare pesanti o
ripetitive quando tre carte sono affiancate.

## Criteri di accettazione

- [ ] Lo sfondo/bordo delle carte upgrade (stato normale) non è più lo
      `StyleBoxFlat` piatto blu-grigio attuale: usa `pause_panel_frame.png`
      (o un ritaglio nine-slice dello stesso asset limitato al perimetro,
      senza il crest superiore/inferiore) come `StyleBoxTexture`.
- [ ] Con tre carte affiancate a schermo (livello up con tre opzioni), il
      risultato non produce ripetizione visiva pesante né un crest duplicato
      tre volte: se il test visivo con l'asset a piena cornice risulta
      pesante, si usa la variante solo-perimetro.
- [ ] Gli stati `hover`, `pressed`, `focus` e `disabled` restano leggibili e
      distinguibili fra loro quanto lo sono oggi (nessuna regressione di
      feedback di interazione).
- [ ] Il contenuto della carta (icona, titolo, descrizione, MetaPanel con
      rango) resta interamente leggibile e non tagliato dai nuovi margini
      della cornice.

## Ambito

- File attesi: `scenes/ui/upgrade_card.tscn` (StyleBox delle carte),
  eventualmente `scripts/ui/upgrade_card.gd` se serve regolare margini di
  contenuto per la nuova cornice.
- Non toccare: logica di `UpgradeService`/`UpgradeEffectRegistry`, il layout
  del `MetaPanel` (PS-047/PS-063), la scena `barb_reward_overlay` (stile
  diverso, non oggetto di questa card).
- Se il test visivo mostra che serve una variante ritagliata dedicata
  dell'asset (non il file esistente così com'è), quella derivazione è
  materiale da card `tipo: art` separata, delegata a `game-art-designer` e
  collegata qui via `dipende_da` — non va prodotta dentro questa card.

## Verifica

- Smoke: `tests/unit/test_ps139_upgrade_card_frame.gd` → marker
  `PS139_UPGRADE_CARD_FRAME_OK`, verifica che lo StyleBox normale della carta
  non sia più il colore/bordo `StyleBoxFlat` attuale e che gli stati
  hover/pressed/focus/disabled restino distinti.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: verifica percettiva della leggibilità
      delle tre carte affiancate su schermo compatto)
- [ ] Controllo percettivo richiesto: sì — confronto screenshot
      `05_upgrade_overlay.png` prima/dopo

## Decisioni

- **2026-09-10 — Consultato il direttore-artistico prima di aprire la card**
  (richiesta del proprietario dopo revisione screenshot). Ha confermato che
  l'intervento è riuso di un asset già esistente (`pause_panel_frame.png`),
  non nuova arte, e ha sconsigliato la cornice piena con crest ripetuto tre
  volte a favore di un trattamento solo-perimetro. Motivazione integrale
  nella conversazione di apertura card, non duplicata qui.

## Documenti sincronizzati

- [ ] `docs/visual-audio-identity.md`, se il risultato finale introduce una
      regola esplicita su quando usare la cornice asset vs uno StyleBox
      piatto (vedi anche PS-140, stessa osservazione sul bordo HUD).

## Note

Alternativa scartata: cornice piena identica al modale pausa applicata a
ciascuna carta — il direttore-artistico la sconsiglia per ripetizione visiva
pesante a tre carte affiancate.
