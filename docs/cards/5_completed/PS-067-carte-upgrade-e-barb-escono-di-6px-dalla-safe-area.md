---
id: PS-067
titolo: Le carte upgrade e Barb escono di 6px dalla safe area
tipo: fix
area: ui
stato: IN VERIFICA
priorita: alta
dipende_da: []
origine:
creato: 2026-09-01
aggiornato: 2026-09-02
---

# PS-067 — Le carte upgrade e Barb escono di 6px dalla safe area

## Contesto

Scoperto il 2026-09-01 lavorando sul blocco PS-031/PS-042/PS-048/PS-050/PS-053:
`tests/unit/test_ps036_barb_reward_visual_identity.gd` e
`tests/unit/test_ps047_upgrade_card_hierarchy.gd` falliscono entrambi con
"carta fuori safe area", su offerta normale, `BARB_SPECIALITY` e
`BARB_BONUS`, su tutti e tre i profili di aspect ratio testati (16:9, 20:9
cutout, 4:3).

Il pattern è identico ovunque: rettangolo interno con `position.y = 314.0` e
`size.y = 392.0` (bottom = `706.0`) contro un safe rect con bottom `700.0`
(`position.y = 20.0`, `size.y = 680.0` in tutti e tre i profili — solo la
larghezza cambia fra i profili). L'overflow verticale è sempre esattamente
**6px**, indipendente dall'aspect ratio: la card ha l'altezza minima attesa
(`custom_minimum_size = Vector2(250, 392)` da
[scenes/ui/upgrade_card.tscn](../../../scenes/ui/upgrade_card.tscn)), ma il
contenitore che la posiziona non lascia margine sufficiente sotto per
rispettare la safe area su nessun profilo.

Non è causato dal lavoro di questa sessione: nessuna delle card in corso
(PS-042, PS-048, PS-050, PS-053) tocca `upgrade_card.*`,
`upgrade_overlay.*` o `barb_reward_overlay.*`. Riprodotto isolando i due
file di test dal resto della suite:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-067 -Profile Custom `
  -RegressionSmoke tests/unit/test_ps036_barb_reward_visual_identity.gd,tests/unit/test_ps047_upgrade_card_hierarchy.gd `
  -NoCache
```

fallisce identico anche da solo, senza altri file modificati nel working
tree collegati a quell'area (verificato con `git status --short`). PS-036 e
PS-047 risultano entrambe `IN VERIFICA` sulla board: o il difetto è
comparso dopo la loro ultima chiusura (una card successiva ha toccato
geometria condivisa), o il gate automatico era già rosso alla chiusura e non
è stato notato.

## Comportamento atteso

Le carte upgrade (offerta normale) e le carte Barb (`BARB_SPECIALITY` e
`BARB_BONUS`) restano interamente dentro la safe area su tutti i profili di
aspect ratio testati da PS-036/PS-047, senza ridurre l'altezza minima
`392` della carta né introdurre scroll.

## Criteri di accettazione

- [x] `tests/unit/test_ps036_barb_reward_visual_identity.gd` passa su tutti
      e tre i profili (16:9, 20:9 cutout, 4:3).
- [x] `tests/unit/test_ps047_upgrade_card_hierarchy.gd` passa, offerta
      normale e `BARB_SPECIALITY`/`BARB_BONUS`.
- [x] Il fix non riduce `custom_minimum_size` della carta né la fa crescere
      oltre le dimensioni verificate da PS-047 (invarianza su focus e su
      modal più alto del necessario). Nessuna modifica a
      `upgrade_card.gd`/`.tscn`: il fix resta interamente nel calcolo del
      margine dei due overlay.
- [x] Nessuna regressione sulla geometria di `test_b18m_ability_visuals.gd`,
      `test_ps046_level_up_modal_isolation.gd` e
      `test_ps059_upgrade_modal_contrast.gd`, che condividono lo stesso
      modal di scelta.

## Ambito

- `scripts/ui/upgrade_overlay.gd`, `scripts/ui/barb_reward_overlay.gd`,
  `scenes/ui/upgrade_overlay.tscn`, `scenes/ui/barb_reward_overlay.tscn`:
  il calcolo della posizione/altezza disponibile per la riga di carte
  rispetto al safe rect ricevuto.
- `scripts/ui/upgrade_card.gd`, `scenes/ui/upgrade_card.tscn`: solo se il
  fix richiede di rivedere il budget verticale interno della carta, non le
  dimensioni minime verificate da PS-047.

Non toccare:

- l'autorità di `RunController` e l'arbitraggio dei modali;
- il contratto della safe area calcolato da `ArenaLayout`/`SafeAreaRoot`
  (PS-064): questa card consuma quel rettangolo, non lo ridefinisce;
- la gerarchia visiva interna della carta chiusa da PS-047 (identità,
  descrizione, blocco effetto/rango).

## Verifica

- Smoke esistenti: `tests/unit/test_ps036_barb_reward_visual_identity.gd`,
  `tests/unit/test_ps047_upgrade_card_hierarchy.gd`. Non serve un nuovo
  smoke dedicato: il contratto è già coperto, è la sua violazione a essere
  il difetto.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows: verifica visiva delle tre schermate di scelta upgrade
      su almeno un profilo 20:9. **Aperto**: nessun ambiente Windows
      disponibile in questa sessione (sandbox Linux remoto), solo
      validazione headless via Godot/GUT.
- [ ] Validazione statica APK: non richiesta, il fix resta lato UI 2D.
- [ ] Runtime fisico Pixel 9: non richiesto per la sola geometria, utile se
      il fix cambia margini condivisi con altri modal (non è questo il
      caso: nessuna scena toccata, solo lo script che calcola il margine).
- [x] Controllo percettivo richiesto: no, il criterio è geometrico e già
      verificato dagli smoke esistenti.

## Decisioni

- **2026-09-01 — Card separata invece di allargare PS-042/048/050/053.** Il
  difetto è emerso durante la verifica di quel blocco ma è indipendente: le
  quattro card non toccano `upgrade_card`/`upgrade_overlay`/
  `barb_reward_overlay`.
- **2026-09-02 — Causa reale: `MarginContainer` che si autoingrandisce, non
  solo la formula di clamp.** Riprodotto il fallimento in un sandbox Linux
  con Godot 4.7.1 headless (`tools/setup-remote-sandbox.sh`, non c'è
  PowerShell in questa sessione). La prima ipotesi — che il ramo
  `min_top if max_top < min_top` di `_reflow_top_margin()` ignorasse il
  margine inferiore quando la clearance dalla fascia HUD e il contenuto non
  ci stanno insieme nella safe area — era necessaria ma non sufficiente:
  aggiungendo un clamp duro `[safe_top, safe_bottom - content_height]` il
  numero prodotto (314) restava identico. Instrumentando il calcolo è
  emerso che `_safe_margins` (un `MarginContainer`) viene forzato dal motore
  a crescere oltre il rettangolo assegnato quando il proprio contenuto
  (header/titolo + carte + margine) supera l'altezza disponibile — la sua
  `size` combacia con la propria minimum-size, non con quella assegnata da
  `apply_safe_area()`. Il codice rileggeva `_safe_margins.position`/`.size`
  a ogni `_reflow_top_margin()`, quindi la prima inflazione veniva scambiata
  per la "vera" safe area e ne causava altre a catena (700 → 710 → 716px di
  fondo osservati per l'offerta Barb, invece di 700). Fix: la safe area
  ricevuta va conservata (`_safe_rect`) e usata per tutta la matematica del
  margine, mai riletta dal nodo; il clamp duro resta comunque necessario per
  il caso (reale, sull'offerta Barb) in cui clearance HUD + contenuto +
  margine base eccedono l'altezza disponibile anche a bordi corretti — in
  quel caso si cede sulla clearance HUD (soft), mai sul contenimento nella
  safe area (hard). Applicato identico a `upgrade_overlay.gd` (stessa
  funzione duplicata) per coerenza, anche se l'offerta normale non
  manifestava il sintomo con le altezze attuali.

## Documenti sincronizzati

- [ ] Nessuno atteso: è una correzione geometrica entro un contratto già
      approvato da PS-046/PS-047/PS-059.

## Note

Evidenza puntuale (2026-09-01), offerta normale profilo 16:9:

```
carta fuori safe area. Interno [P: (40.0, 314.0), S: (390.0, 392.0)],
esterno [P: (20.0, 20.0), S: (1240.0, 680.0)]
```

`314 + 392 = 706` contro un fondo safe a `20 + 680 = 700`: overflow di 6px,
identico su `20:9 cutout` (`esterno` `S: (1472.0, 680.0)`) e `4:3`
(`esterno` `S: (920.0, 680.0)`) — la larghezza cambia, l'altezza disponibile
resta `680` ovunque, quindi l'overflow è indipendente dall'aspect ratio.
