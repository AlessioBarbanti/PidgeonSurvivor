---
id: PS-047
titolo: Compattare e gerarchizzare le carte upgrade
tipo: ux
area: ui
stato: IN VERIFICA
priorita: alta
dipende_da: [PS-046]
origine:
creato: 2026-08-31
aggiornato: 2026-09-01
---

# PS-047 — Compattare e gerarchizzare le carte upgrade

## Contesto

La nuova cattura
[05_upgrade_overlay.png](../../../exports/ui-screenshots/pixel9-20x9/05_upgrade_overlay.png)
mostra che descrizione, riepilogo dell'effetto e rango sono già separati e
leggibili. Il difetto reale è il ritmo verticale: le carte sono molto alte,
ma icona, titolo e testi occupano piccole isole lasciando grandi vuoti interni.
Lo stesso schema compare nelle carte Barb di
[05b_barb_speciality.png](../../../exports/ui-screenshots/pixel9-20x9/05b_barb_speciality.png)
e
[05c_barb_bonus.png](../../../exports/ui-screenshots/pixel9-20x9/05c_barb_bonus.png).

Non è giustificato introdurre un nuovo schema dati per chip numerici o ridurre
forzatamente tutte le descrizioni a una riga: la card deve prima correggere
composizione, densità e stato selezionato.

## Comportamento atteso

Ogni carta si legge come un unico oggetto: identità in alto, spiegazione al
centro, effetto e rango raccolti in basso. Le tre scelte sfruttano il modal
senza apparire né vuote né compresse e mantengono la stessa grammatica nelle
offerte normali, Speciality e bonus Barb.

## Criteri di accettazione

- [x] Icona, titolo, descrizione, riepilogo effetto e rango formano gruppi
      visivi coerenti; non restano grandi intervalli vuoti senza funzione.
      *Riepilogo effetto e rango sono ora raccolti in un `MetaPanel`
      (`PanelContainer` con sfondo e bordo superiore dedicati) distinto dalla
      descrizione sopra di esso. Verificato da
      `test_ps047_upgrade_card_hierarchy.gd`: ordine identità > descrizione >
      gruppo effetto/rango e contenimento di effetto+rango nello stesso
      rettangolo.*
- [x] Le tre carte usano in modo equilibrato lo spazio utile del modal 20:9 e
      non vengono allungate solo per riempire l'altezza dello schermo.
      *Causa radice: il contenitore `Cards` aveva `size_flags_vertical = 3`
      (espande per riempire tutto lo spazio verticale residuo del modal), che
      a sua volta stirava ogni carta figlia. Cambiato a `4`
      (`SIZE_SHRINK_CENTER`): la riga delle carte assume ora la propria
      altezza naturale ed è centrata nello spazio residuo, mentre le carte fra
      loro restano di altezza uniforme (invariato `size_flags_vertical = 3`
      sulla singola `UpgradeCard`, relativo alla riga non più forzata). Lo
      smoke verifica che la stessa carta non cresca fra un modal di 680px e
      uno di 1400px di altezza disponibile.*
- [x] Le descrizioni complete già approvate restano disponibili e leggibili;
      non viene introdotto un limite artificiale di una riga.
      *`DescriptionLabel` mantiene `autowrap_mode` e nessun limite di righe;
      nessun testo è stato accorciato nei dati.*
- [x] Testi lunghi reali, incluso `Pinza Lunga`, entrano senza troncamenti,
      sovrapposizioni o riduzioni illeggibili.
      *Lo smoke forza un'offerta con pool di sole tre definizioni includendo
      `wide_magnet.tres` ("Pinza Lunga"), cosi' compare sempre, e verifica che
      l'altezza assegnata alla label sia almeno quella richiesta dal proprio
      wrapping (`get_minimum_size()`), su tutte le carte visibili.*
- [x] Il riepilogo dell'effetto e il rango restano distinti dalla descrizione
      e confrontabili fra le tre scelte.
      *Stessa struttura (`MetaPanel`) identica sulle tre carte in ogni
      modalità di offerta.*
- [x] La carta selezionata è evidente con focus, bordo o luce, senza cambiare
      dimensione e spostare le altre carte.
      *Comportamento preesistente non toccato (stili di focus/pressed della
      `Button`); lo smoke aggiunge la verifica esplicita che `card.size` non
      cambi dopo `grab_focus()`.*
- [x] La gerarchia funziona nelle offerte normali, `BARB_SPECIALITY` e
      `BARB_BONUS`, mantenendo riconoscibili le identità introdotte da PS-036.
      *Stessa scena `upgrade_card.tscn` riusata da entrambi gli overlay;
      trattamento visivo Speciality di PS-036 (`set_speciality_treatment`) non
      toccato. Verificato dallo smoke in tutte e tre le modalità.*
- [x] Focus da tastiera e gamepad, touch, scorciatoie numeriche e lock
      anti-tap restano invariati.
      *Nessuna logica di input, focus o `SELECTION_LOCK_SECONDS` modificata:
      solo contenitori e stili.*
- [x] Nessun valore, effetto, probabilità o rango di gameplay cambia.
      *Nessun file in `data/upgrades/`, `UpgradeEffectRegistry` o
      `UpgradeService` toccato.*
- [x] Nessun nuovo campo nei dati upgrade viene aggiunto salvo necessità
      dimostrata da un testo reale che non può essere composto con i campi
      esistenti.
      *Nessun campo aggiunto a `UpgradeDefinition`; il `MetaPanel` è solo
      presentazione dei campi `effect_summary` e rango già esistenti.*

## Ambito

- `scripts/ui/upgrade_card.gd`, `scenes/ui/upgrade_card.tscn`.
- Contenitori delle carte in `upgrade_overlay.tscn` e
  `barb_reward_overlay.tscn`, solo per spaziatura e dimensioni.
- Stili di focus e selezione già usati dalle carte.

Non toccare:

- `UpgradeEffectRegistry`, dati e logica degli effetti;
- generazione dell'offerta, RNG e probabilità;
- valori di bilanciamento;
- isolamento del modal, contratto di PS-046.

## Verifica

- Smoke: `tests/unit/test_ps047_upgrade_card_hierarchy.gd` → marker
  `UPGRADE_CARD_HIERARCHY_SMOKE_OK` — verifica contenimento dei testi campione,
  ordine dei gruppi, dimensioni invarianti durante il focus e riuso nelle tre
  modalità di offerta.
- Profilo minimo prima della chiusura: `Relevant`
- **Eseguito 2026-09-01:** `.\tools\run-milestone-checks.ps1 -Milestone PS-047
  -Profile Relevant -FocusedSmoke tests/unit/test_ps047_upgrade_card_hierarchy.gd`
  → `PASS focused=1/1 regression=24/24 steps=25/25`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: offerta normale e due offerte Barb, navigazione
      touch e gamepad
- [ ] Controllo percettivo richiesto: sì — densità, leggibilità e chiarezza
      della selezione alla scala reale

## Decisioni

- **2026-08-31 — Nessun sistema di chip obbligatorio.** Le nuove catture non
  mostrano un problema di struttura dei dati; introdurlo ora allargherebbe la
  card senza risolvere il vuoto compositivo.
- **2026-08-31 — La selezione non cambia scala.** Il confronto fra le tre
  opzioni deve restare stabile.
- **2026-08-31 — Card bloccata su PS-046.** Le scene condivise vengono prima
  isolate dall'HUD e poi rifinite internamente.
- **2026-09-01 — Sbloccata in sprint con PS-046 ancora `IN CORSO`.** Il
  proprietario ha chiesto di lavorare l'intero blocco PS-045/046/047 nello
  stesso sprint con verifica rimandata alla fine; PS-046 è già implementata e
  con smoke verde, resta solo il passaggio formale a `IN VERIFICA` a fine
  sprint. Implementare PS-047 ora evita di riaprire due volte le stesse scene
  condivise (`upgrade_overlay.tscn`, `barb_reward_overlay.tscn`).
- **2026-09-01 — `SIZE_SHRINK_CENTER` sul contenitore `Cards`, non sulla
  singola carta.** Cambiare il flag sulla riga (non sulla carta) mantiene le
  tre carte della stessa altezza fra loro — continuano a riempirsi a vicenda
  dentro la riga — evitando un'altezza diversa per carta in base alla
  lunghezza della propria descrizione, che avrebbe reso irregolare il
  confronto fra le tre scelte.

## Documenti sincronizzati

- [ ] `docs/ui-ux-flow.md`: anatomia della carta upgrade, se cambia il
      contratto durevole.

## Note

L'obiettivo è aumentare la qualità percepita della scelta senza riscrivere il
catalogo upgrade.
