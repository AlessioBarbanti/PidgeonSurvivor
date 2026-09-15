---
id: PS-180
titolo: La citazione del Boss è leggermente nascosta su device reale (gate Pixel di PS-176)
tipo: fix
area: ui
stato: PRONTO
priorita: alta
dipende_da: []
origine: test reale su Pixel 9 della v0.3.0, 2026-09-15
creato: 2026-09-15
aggiornato: 2026-09-15
---

# PS-180 — La citazione del Boss è leggermente nascosta su device reale (gate Pixel di PS-176)

## Contesto

[PS-176](../4_to_test/PS-176-ritratti-boss-fluttuanti-senza-cornice.md)
(ritratti Boss fluttuanti) ha il gate "Runtime fisico Pixel 9" esplicitamente
lasciato aperto proprio per questo controllo — mai eseguito in sessione,
solo validato via screenshot dall'agente `direttore-artistico`. Testando la
build reale v0.3.0 su Pixel 9, il proprietario segnala che la scritta
(citazione) del Boss è "leggermente nascosta". Non ancora chiaro se è
overflow dietro il cartiglio, sovrapposizione con un altro elemento
(pulsante AFFRONTA, HUD), o clipping ai bordi della safe area su questo
specifico rapporto d'aspetto (Pixel 9 ≈ 20:9, 2424×1080) — diverso dai
profili 16:9/20:9 "sintetici" già catturati in sessione.

## Comportamento atteso

La citazione è interamente leggibile, senza essere nascosta o tagliata, su
Pixel 9 reale, per tutte e 9 le varianti e con citazioni sia corte che al
limite di lunghezza.

## Criteri di accettazione

- [ ] Riprodotto e identificato esattamente cosa nasconde la scritta
      (z-order, clipping del `RichTextLabel`, sovrapposizione con altro
      nodo, contrasto insufficiente) su screenshot/registrazione del device
      reale.
- [ ] Corretto mantenendo il contratto di PS-176 (ancore percentuali
      misurate su `REFERENCE.png`, `contain` scaling, nessun pannello/
      cornice reintrodotto).
- [ ] Verificato su almeno un Evil e sul Piccione Malvagio, incluso con la
      citazione di stress (167 caratteri) già usata nei test automatici.

## Ambito

- `scripts/ui/boss_ui.gd`, `scenes/ui/boss_ui.tscn` (stesso perimetro di
  PS-176).
- Non reintrodurre il trattamento a pannello/medaglione/cornice scartato da
  PS-176 (PS-102/PS-103 restano storiche e scartate).

## Verifica

- GUT: eventuale nuova asserzione in
  `tests/unit/test_ps176_boss_intro_floating_portrait.gd` se la causa è
  geometrica e riproducibile headless.
- Screenshot reale da device Pixel 9, non solo cattura sintetica via
  `godot_console`.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (gate primario, già in corso — questa card ne
      è la diretta continuazione)
- [ ] Controllo percettivo richiesto: sì — leggibilità del testo è un
      giudizio visivo diretto sul device reale

## Decisioni

- **2026-09-15 — Non duplica PS-176, la completa.** Questa card nasce dal
  gate Pixel 9 di PS-176 rimasto esplicitamente aperto: a risoluzione
  avvenuta, aggiornare anche PS-176 invece di lasciarla disallineata.

## Documenti sincronizzati

- [ ] Nessuno atteso oltre a quanto già sincronizzato da PS-176, salvo che
      la causa riveli un vincolo geometrico nuovo da documentare.

## Note

Segnalato dal proprietario durante il test reale su Pixel 9 della v0.3.0,
insieme ad altri cinque problemi nella stessa sessione (PS-178, PS-179,
PS-181..PS-183).
