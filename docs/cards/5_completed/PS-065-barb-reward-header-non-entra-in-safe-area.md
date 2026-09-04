---
id: PS-065
titolo: L'header del premio Barb non entra nel rettangolo sicuro a risoluzioni compatte
tipo: fix
area: ui
stato: COMPLETATO
priorita: media
dipende_da: [PS-064]
origine:
creato: 2026-09-01
aggiornato: 2026-09-04
---

# PS-065 — L'header del premio Barb non entra nel rettangolo sicuro a risoluzioni compatte

## Contesto

PS-064 ha corretto il bug di posizione/dimensione di `SafeMargins`
(`top_level` che si ancorava all'intero viewport invece che al rettangolo
sicuro). Una volta corretto, `test_ps047_upgrade_card_hierarchy.gd` (casi
`BARB_SPECIALITY`/`BARB_BONUS`) e `test_ps036_barb_reward_visual_identity.gd`
restano rossi per un motivo **diverso e indipendente**, prima mascherato:
`BarbRewardOverlay` riserva `HeaderPanel` (ritratto di Barb + titolo, altezza
fissa 148px) sopra le carte, e la somma di margine HUD (140px) + header
(148px) + separazione + carta (392px, il minimo di PS-063) + margine
inferiore supera l'altezza del rettangolo sicuro a risoluzioni compatte
(es. 680px, corrispondente a un viewport 1280×720 con l'inset strutturale
`edge_inset=20`).

Confermato preesistente e indipendente da PS-064: isolando le modifiche di
PS-064 con `git stash` e ripetendo la stessa suite sul baseline, gli stessi
casi Barb Reward fallivano già (con numeri diversi, perché il bug di offset
di PS-064 gonfiava artificialmente lo spazio disponibile mascherando lo
sconfinamento reale).

**Mitigazione già applicata in PS-064** (nessun rischio visivo): `Layout`
in `barb_reward_overlay.tscn` ha `separation` ridotta da 10 a 6 e
`margin_bottom` da 16 a 10. Riduce ma non elimina lo sconfinamento residuo:

- 16:9 (1240×680): carta sconfina di ~6px oltre il bordo inferiore del
  rettangolo sicuro.
- 20:9 con cutout (1472×680): stesso ~6px.
- 4:3 (920×680): ~21px (le carte crescono a 407px di altezza qui, il testo
  va a capo di più alla larghezza più stretta).

Visivamente, alla risoluzione reale testata (1280×720), lo sconfinamento non
è percepibile a schermo (il rettangolo sicuro lascia comunque ~20px di
margine reale dal bordo fisico del viewport per i gesti di navigazione): il
problema è un margine di sicurezza eroso, non un artefatto visivo attuale.
Su un device con un inset reale più grande (notch, gesture bar più alta)
potrebbe diventare visibile.

## Comportamento atteso

Header e carte del premio Barb restano interamente dentro il rettangolo
sicuro corrente, in tutti i profili già coperti dai test (16:9, 20:9 con
cutout, 4:3), senza intaccare la leggibilità del ritratto di Barb o del
titolo.

## Criteri di accettazione

- [x] `test_ps047_upgrade_card_hierarchy.gd` (`BARB_SPECIALITY`,
      `BARB_BONUS`) e `test_ps036_barb_reward_visual_identity.gd` tornano
      verdi sulle assert "carta fuori safe area", senza indebolire
      `LAYOUT_TOLERANCE` né rimuovere il controllo. Verificato sui tre
      profili (16:9, 20:9 cutout, 4:3) coperti da `test_ps036`: tutti verdi
      senza modifiche a questa card (vedi Decisioni).
- [x] Il ritratto di Barb resta riconoscibile: **nessuna riduzione è stata
      necessaria**, quindi non serve una conferma del proprietario su un
      cambiamento che non è avvenuto.
- [x] Nessuna regressione sul contratto di altezza uniforme delle carte
      (PS-047) né sul minimo di 392px stabilito da PS-063: entrambi restano
      intatti, verificato dagli stessi smoke.

## Ambito

- `scenes/ui/barb_reward_overlay.tscn` (`HeaderPanel`, `HeaderContent`,
  `BarbPortrait`).
- Eventuale asset del ritratto (`assets/art/ui/barb_reward/generated/barb_portrait.png`)
  solo se il proprietario conferma esplicitamente una riduzione — con la
  riga corrispondente aggiornata in `ASSET-MANIFEST.md`.

Non toccare:

- il fix di posizione/size di `SafeMargins` (PS-064, già corretto);
- il minimo di 392px delle carte upgrade (PS-063) senza una nuova decisione
  esplicita del proprietario;
- `CONTENT_TOP_MARGIN`/`GameHud.GAMEPLAY_TOP_INSET` (margine HUD, contratto
  di PS-046, non è la causa qui).

## Verifica

- Smoke esistenti riusati: `tests/unit/test_ps047_upgrade_card_hierarchy.gd`,
  `tests/unit/test_ps036_barb_reward_visual_identity.gd`.
- Cattura UI reale (`tools/_capture_ui_screenshots.gd`) sui profili `16x9` e
  `20x9`: ispezione a occhio del ritratto e del titolo dopo qualunque
  riduzione.

## Gate manuali

- [x] Runtime Windows. Confermato dal proprietario.
- [x] Validazione statica APK. Confermata dal proprietario; il fix comunque
      non tocca asset o preset export.
- [x] Runtime fisico: non richiesto per questa card — nessuna modifica
      visiva è stata applicata (vedi Decisioni), quindi non c'è nulla da
      riprodurre su device oltre a quanto già coperto dagli smoke.
- [x] Controllo percettivo richiesto: no. Il ritratto di Barb non è stato
      toccato: la condizione che avrebbe richiesto conferma del proprietario
      (una riduzione visiva) non si è verificata.

## Decisioni

- **2026-09-01 — Aperta come card separata da PS-064**: la causa è
  indipendente (spazio insufficiente, non posizione sbagliata) e la
  soluzione plausibile tocca un asset visivo che richiede una decisione del
  proprietario, non un default tecnico deciso qui.
- **2026-09-02 — Risolta da PS-067 senza intervento diretto, nessuna
  riduzione visiva necessaria.** [PS-067](./PS-067-carte-upgrade-e-barb-escono-di-6px-dalla-safe-area.md)
  ha corretto lo stesso meccanismo di causa alla radice in
  `barb_reward_overlay.gd`/`upgrade_overlay.gd`: (1) `_reflow_top_margin()`
  rileggeva `_safe_margins.size`, che il motore forza a crescere oltre il
  rettangolo assegnato quando il contenuto non ci sta, innescando un loop di
  auto-inflazione della "safe area" percepita; (2) anche a bordi corretti, il
  vecchio ramo `min_top if max_top < min_top` ignorava del tutto il margine
  inferiore quando la clearance HUD e il contenuto non ci stavano insieme.
  Il fix di PS-067 conserva il rect ricevuto (`_safe_rect`, mai riletto dal
  nodo) e tratta il contenimento nella safe area come vincolo duro, con la
  clearance HUD come preferenza morbida che cede quando necessario — la
  stessa logica generale copre anche il caso Barb più alto (header 148px)
  descritto da questa card, incluso il profilo 4:3 con carte a 407px di
  altezza. Rieseguiti `test_ps036_barb_reward_visual_identity.gd` e
  `test_ps047_upgrade_card_hierarchy.gd` su `HEAD` (dopo PS-067 e PS-052,
  senza ulteriori modifiche): entrambi verdi su tutti i profili, incluso il
  caso 4:3 citato nel Contesto. Non è stata necessaria alcuna riduzione del
  ritratto di Barb, quindi il gate percettivo previsto da questa card non si
  applica più.

## Documenti sincronizzati

- [x] Nessuno atteso: il contratto risultante (contenimento nella safe area
      come vincolo duro) è già stato sincronizzato da PS-067 dove rilevante;
      questa card non introduce alcun cambiamento visivo o di contratto
      proprio.

## Note

Priorità `media`: lo sconfinamento non è oggi visivamente percepibile alla
risoluzione reale testata; resta un margine di sicurezza eroso da chiudere,
non un difetto visivo osservato.

Evidenza di chiusura (2026-09-02), Godot 4.7.1 headless in sandbox Linux:

```
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gtest=tests/unit/test_ps036_barb_reward_visual_identity.gd,tests/unit/test_ps047_upgrade_card_hierarchy.gd \
  -gexit
```

`3/3` e `2/2` test passati, nessun `SCRIPT ERROR`/`FATAL EXCEPTION` nei log.
