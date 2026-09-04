---
id: PS-063
titolo: Il MetaPanel delle carte upgrade esce dal bordo della carta
tipo: fix
area: ui
stato: COMPLETATO
priorita: alta
dipende_da: [PS-047]
origine:
creato: 2026-09-01
aggiornato: 2026-09-04
---

# PS-063 — Il MetaPanel delle carte upgrade esce dal bordo della carta

## Contesto

Il proprietario, guardando gli screenshot generati per validare PS-059, ha
segnalato che le carte upgrade sono "fatte male": il riquadro
danno/rango (`MetaPanel`, introdotto da PS-047) appare incastrato in basso.

Misurato con Godot reale (non a occhio): il `MetaPanel` usciva davvero
16-30px oltre il bordo arrotondato della carta. Causa: `UpgradeCard`
(`upgrade_card.tscn`) dichiara `custom_minimum_size.y = 392` fisso, ma il
contenuto reale — icona 198px, header, titolo, descrizione, `MetaPanel`,
margini — richiede da 465 a 524px a seconda del testo dell'offerta. La
carta non si è mai adattata al contenuto vero: PS-047 aveva reso la *riga*
di carte "shrink to natural height" (`SIZE_SHRINK_CENTER` su `Cards`), ma
la singola carta restava vincolata a un numero fisso che non copriva il
caso reale.

## Comportamento atteso

In ogni offerta (livello, Specialità Barb, bonus Barb) il riquadro
danno/rango resta interamente dentro il bordo della carta, con lo stesso
margine visibile sopra e sotto, indipendentemente dalla lunghezza di
titolo/descrizione.

## Criteri di accettazione

- [x] Il `MetaPanel` non esce mai dal rettangolo della carta: verificato
      per l'offerta normale, `BARB_SPECIALITY` e `BARB_BONUS`.
      *Misurato via GDScript nel motore reale (non solo il test): con le
      dimensioni finali, `bottom_overflow` è negativo (margine reale) in
      tutti i casi provati.*
- [x] Le tre carte di una riga restano della stessa altezza fra loro
      (contratto di PS-047, non va perso).
      *`Cards` continua a stirare (`size_flags_vertical = 3`) ogni carta
      alla stessa altezza; la carta più esigente della riga decide
      l'altezza comune.*
- [x] La carta non cresce oltre il necessario solo perché il modal ha più
      spazio verticale disponibile (contratto di PS-047, non va perso).
      *La crescita dipende solo dal contenuto reale (somma delle altezze
      minime dei figli), mai dallo spazio del modal.*
- [x] L'icona resta riconoscibile: nessun limite superiore posto da questa
      card, ma la card documenta la scelta esplicita del proprietario di
      ridurla per far entrare il contenuto in un'altezza compatta.
      *Ridotta da 192×192 a 106×106 (`IconCenter` da 198 a 112) — scelta
      del proprietario, non un default tecnico.*
- [x] Nessun valore di rango, effetto, probabilità o bilanciamento upgrade
      cambia: la modifica è solo di layout/presentazione.
      *Toccati solo `upgrade_card.tscn` (dimensioni/margini) e
      `upgrade_card.gd` (calcolo dell'altezza minima); nessun file in
      `data/upgrades/` modificato.*
- [x] Il contratto icona 192×192 di `test_b11_upgrade_overlay.gd` è
      aggiornato coerentemente, non semplicemente disattivato.
      *Aggiornato a 106×106, stesso criterio (icona + `IconCenter` di
      altezza minima adeguata), non rimosso.*

## Ambito

- `scenes/ui/upgrade_card.tscn` (`IconCenter`/`Icon`, margini, separazione).
- `scripts/ui/upgrade_card.gd` (calcolo dinamico dell'altezza minima come
  rete di sicurezza per testi eccezionalmente lunghi).
- `tests/unit/test_b11_upgrade_overlay.gd` (contratto dimensione icona).

Non toccare:

- gerarchia dei gruppi (identità > descrizione > effetto/rango), contratto
  di PS-047 già validato;
- `Dimmer`/`SafeMargins` e il loro ordine di disegno (PS-059);
- `RunController`, generazione dell'offerta, `UpgradeEffectRegistry`.

## Verifica

- Smoke esistenti riusati, non duplicati: `tests/unit/test_ps047_upgrade_card_hierarchy.gd`,
  `tests/unit/test_b11_upgrade_overlay.gd`.
- **Eseguito 2026-09-01, localmente in sandbox** (Godot 4.7.1 via
  `tools/setup-remote-sandbox.sh`):
  ```
  godot --headless --path . -s addons/gut/gut_cmdln.gd \
    -gtest=res://tests/unit/test_ps047_upgrade_card_hierarchy.gd,res://tests/unit/test_ps059_upgrade_modal_contrast.gd,res://tests/unit/test_ps046_level_up_modal_isolation.gd,res://tests/unit/test_b11_upgrade_overlay.gd,res://tests/unit/test_ps036_barb_reward_visual_identity.gd,res://tests/unit/test_ps012_barb_specialities.gd \
    -gexit
  ```
  → tutti verdi **tranne** le assert "carta fuori safe area" di
  `test_ps047`/`test_b11`/`test_ps036`, che falliscono per un bug
  preesistente e indipendente da questa card — vedi PS-064. Confermato
  rieseguendo la stessa suite con queste modifiche completamente stashate:
  falliscono identicamente anche senza alcuna modifica di questa card.
- Cattura UI reale (`tools/_capture_ui_screenshots.gd` via Xvfb) ispezionata
  a occhio su profilo `16x9` (1280×720) e `20x9` Pixel 9: `MetaPanel`
  contenuto con margine visibile in entrambi.

## Gate manuali

- [x] Runtime Windows: confermato dal proprietario.
- [x] Validazione statica APK: confermata via CI (workflow PS-060,
      `android-debug-release.yml`) sul commit `d3c72b0`. Il primo run
      (`33501795354`, tentativo 1) era fallito al passo "Export Android APK
      preset" con `ERROR: Export: Target folder does not exist or is
      inaccessible: "exports/android"` dopo soli ~22s (contro i ~2.5min
      normali) — nessuna causa reale trovata nel log (workflow YAML e
      sequenza `mkdir -p`/export identiche ai due run precedenti riusciti,
      nessun asset o file di workflow toccato da questa card): trattato come
      flake del runner. Riesguito con `rerun_failed_jobs`: tentativo 2
      completato con successo, `aapt2 dump badging` e `apksigner verify`
      passati, APK pubblicato su
      https://github.com/AlessioBarbanti/PidgeonSurvivor/releases/tag/android-debug-latest
      (asset `pidgeon-survivor-debug.apk`, 105 MB, corpo release che cita
      `d3c72b0aa43adf2d08fe2e8f1ef65de9bd96f897`).
- [x] Runtime fisico Pixel 9: confermato dal proprietario sulla build
      pubblicata (il fix precedente del velo, PS-059, era già confermato;
      questa card cambia solo le carte).
- [x] Controllo percettivo richiesto: sì — confermato dal proprietario sia
      sugli screenshot sia sul device fisico con la build pubblicata.

## Decisioni

- **2026-09-01 — Icona rimpicciolita, non carta lasciata crescere sempre.**
  Proposte al proprietario due strade equivalenti sul piano tecnico
  (icona più piccola con carta quasi sempre fissa a 392px, oppure icona
  192×192 con carta che cresce dinamicamente fino a ~524px). Il
  proprietario ha scelto esplicitamente la prima, accettando di aggiornare
  il contratto icona di `test_b11`.
- **2026-09-01 — Tenuta comunque una rete di sicurezza dinamica.** Anche
  con l'icona più piccola, `upgrade_card.gd` calcola l'altezza minima reale
  dal contenuto (somma dei figli) invece di fidarsi ciecamente di un numero
  fisso: se in futuro un'offerta con testo eccezionalmente lungo dovesse
  ancora superare 392px, la carta cresce invece di traboccare di nuovo. Il
  numero fisso da solo aveva già dimostrato di potersi sbagliare una volta.
- **2026-09-01 — Il calcolo dell'altezza minima somma i figli invece di
  interrogare `Margins.get_combined_minimum_size()` in blocco.** Misurato
  che quest'ultimo, interrogato prima che la riga assegni la larghezza
  reale della carta, restituisce un'altezza enormemente gonfiata (un'
  etichetta con autowrap misurata a larghezza quasi zero va a capo come se
  fosse strettissima). Sommare le altezze minime dei singoli figli — lette
  dopo un paio di frame, quando ciascuno riflette la propria larghezza
  reale — evita il problema. Vedi commenti in `upgrade_card.gd`.
- **2026-09-01 — Scoperto un bug preesistente e separato durante la
  verifica, non causato da questa card.** I test "carta fuori safe area"
  di `test_ps047`/`test_b11`/`test_ps036` falliscono in isolamento a causa
  di `top_level = true` su `SafeMargins` (PS-059, stessa sessione, alcune
  ore prima): il fixture di quei test simula un safe-rect ristretto
  posizionando un `Control` nudo (senza `CanvasLayer` reale), e i nodi
  `top_level` ignorano quella posizione simulata. Segnalato con card
  separata (PS-064) invece di allargare questa; verificato che il fallimento
  è identico anche con questa card completamente stashata.

## Documenti sincronizzati

- [x] Nessuno: modifica di presentazione interna, nessun contratto
      durevole in `docs/ui-ux-flow.md` cambia oltre a quanto già coperto da
      PS-047.

## Note

Nata da uno screenshot reale mandato al proprietario per validare PS-059:
senza quella cattura visiva, il difetto (già presente prima di questa
sessione) sarebbe rimasto invisibile ai test automatici esistenti, che non
controllavano il contenimento del `MetaPanel` nel rettangolo della carta.
