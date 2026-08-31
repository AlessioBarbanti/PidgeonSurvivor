---
id: PS-047
titolo: Compattare e gerarchizzare le carte upgrade
tipo: ux
area: ui
stato: BLOCCATO
priorita: alta
dipende_da: [PS-046]
origine:
creato: 2026-08-31
aggiornato: 2026-08-31
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

- [ ] Icona, titolo, descrizione, riepilogo effetto e rango formano gruppi
      visivi coerenti; non restano grandi intervalli vuoti senza funzione.
- [ ] Le tre carte usano in modo equilibrato lo spazio utile del modal 20:9 e
      non vengono allungate solo per riempire l'altezza dello schermo.
- [ ] Le descrizioni complete già approvate restano disponibili e leggibili;
      non viene introdotto un limite artificiale di una riga.
- [ ] Testi lunghi reali, incluso `Pinza Lunga`, entrano senza troncamenti,
      sovrapposizioni o riduzioni illeggibili.
- [ ] Il riepilogo dell'effetto e il rango restano distinti dalla descrizione
      e confrontabili fra le tre scelte.
- [ ] La carta selezionata è evidente con focus, bordo o luce, senza cambiare
      dimensione e spostare le altre carte.
- [ ] La gerarchia funziona nelle offerte normali, `BARB_SPECIALITY` e
      `BARB_BONUS`, mantenendo riconoscibili le identità introdotte da PS-036.
- [ ] Focus da tastiera e gamepad, touch, scorciatoie numeriche e lock anti-tap
      restano invariati.
- [ ] Nessun valore, effetto, probabilità o rango di gameplay cambia.
- [ ] Nessun nuovo campo nei dati upgrade viene aggiunto salvo necessità
      dimostrata da un testo reale che non può essere composto con i campi
      esistenti.

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

## Documenti sincronizzati

- [ ] `docs/ui-ux-flow.md`: anatomia della carta upgrade, se cambia il
      contratto durevole.

## Note

L'obiettivo è aumentare la qualità percepita della scelta senza riscrivere il
catalogo upgrade.
