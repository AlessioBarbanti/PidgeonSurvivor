---
id: PS-009
titolo: Rendi trasparente la Boss UI sotto il Player
tipo: ux
area: ui
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-009 — Rendi trasparente la Boss UI sotto il Player

## Contesto

Il riquadro HUD con nome e vita del Boss può sovrapporsi visivamente al personaggio quando il Player passa nella zona occupata dalla Boss UI.

Il pulsante dell'abilità utilizza già un comportamento equivalente: quando il personaggio passa sotto il controllo, questo diventa parzialmente trasparente per non nascondere il gameplay.

La Boss UI deve adottare lo stesso principio.

## Comportamento atteso

Quando il Player entra visivamente sotto il riquadro della vita del Boss, l'intero blocco Boss UI diventa parzialmente trasparente.

Quando il Player esce dalla zona occupata dal riquadro, la Boss UI torna automaticamente alla propria opacità normale.

La trasparenza:

* riguarda l'intero riquadro Boss rilevante, inclusi barra HP, nome, bordo e sfondo;
* è esclusivamente presentazionale;
* non modifica posizione, dimensioni o comportamento del Boss;
* non modifica il playfield;
* non modifica collisioni o movimento del Player;
* non rende la Boss UI completamente invisibile;
* deve usare una transizione visiva breve e non un cambio brusco.

La logica deve seguire lo stesso principio già utilizzato dal controllo dell'abilità quando il Player gli passa sotto.

Il valore di opacità ridotta deve restare configurabile.

## Criteri di accettazione

* [ ] Con un Boss attivo, la Boss UI resta normalmente alla propria opacità standard.
* [ ] Quando il Player entra sotto il riquadro Boss, l'intero blocco diventa parzialmente trasparente.
* [ ] Quando il Player esce dalla zona, il blocco torna all'opacità standard.
* [ ] La transizione tra i due stati non avviene tramite uno stacco visivo brusco.
* [ ] La Boss UI resta leggibile anche nello stato trasparente.
* [ ] Il Player resta chiaramente visibile sotto il riquadro trasparente.
* [ ] Il comportamento si basa sulla sovrapposizione visiva effettiva con il Player e non su coordinate fisse per una singola risoluzione.
* [ ] Il comportamento funziona con aspect ratio differenti.
* [ ] La trasparenza non modifica hitbox, movimento, targeting o statistiche.
* [ ] Boss Intro, pausa e altri overlay non producono stati di opacità residui.
* [ ] Alla scomparsa del Boss la UI viene ripulita senza mantenere stato locale.
* [ ] Restart ripristina sempre l'opacità standard.

## Ambito

* Boss HUD / riquadro vita Boss.
* Rilevamento della sovrapposizione visuale Player ↔ Boss UI.
* Stato di opacità della Boss UI.
* Transizione tra opacità normale e ridotta.
* Cleanup alla morte del Boss e al restart.

Riutilizzare, dove possibile, lo stesso criterio già adottato per la trasparenza del pulsante abilità.

Non modificare:

* posizione della Boss UI;
* dimensioni della barra Boss;
* HP o statistiche del Boss;
* layout del playfield;
* collisioni del Player;
* comportamento del pulsante abilità.

## Verifica

* Smoke: `tests/integration/_boss_ui_player_overlap_smoke.gd` → marker `BOSS_UI_PLAYER_OVERLAP_SMOKE_OK`
* Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

* [ ] Runtime Windows
* [ ] Validazione statica APK
* [ ] Runtime fisico Pixel 9 (percorso: raggiungi un Boss → porta il Player sotto il riquadro HP → esci dalla zona → ripeti durante combattimento)
* [ ] Controllo percettivo richiesto: sì
* [ ] La Boss UI diventa abbastanza trasparente da non nascondere il Player.
* [ ] HP e nome del Boss restano comunque leggibili.
* [ ] La transizione di entrata e uscita risulta fluida.
* [ ] Non si osserva flickering quando il Player si muove vicino al bordo del riquadro.
* [ ] Il comportamento risulta coerente con quello del pulsante abilità.

## Decisioni

- **2026-08-30 — La Boss UI sfuma, non si sposta.** Il comportamento è
  esclusivamente presentazionale e segue il principio già usato dal controllo
  abilità.
- **Baseline percettiva — alpha e transizione configurabili.** I valori finali
  vengono scelti nel gate visivo senza rendere il riquadro invisibile.

## Documenti sincronizzati

- [ ] `prd.md`: regola di leggibilità della Boss UI, se diventa contratto
      generale.
- [ ] Nota di verifica percettiva Windows/Pixel 9.

## Note

Principio di riferimento:

**la UI può sovrapporsi al gameplay, ma non deve nascondere il Player.**

La Boss UI non deve spostarsi quando il Player le passa sotto: cambia soltanto la propria opacità.

Il valore esatto dell'alpha ridotto e la durata della transizione restano configurabili e devono essere scelti tramite controllo percettivo.
