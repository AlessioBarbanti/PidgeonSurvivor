---
id: PS-130
titolo: Rigenera come candidati le otto icone passive del cast
tipo: art
area: arte
stato: PRONTO
priorita: media
dipende_da: [PS-105]
origine:
creato: 2026-09-08
aggiornato: 2026-09-08
---

# PS-130 — Rigenera come candidati le otto icone passive del cast

## Contesto

Una revisione del direttore-artistico su tutte e otto le icone passive in
`assets/art/icons/passives/generated/` ha misurato copertura e saturazione
del ciano pixel per pixel e trovato uno style drift: la regola "ciano solo
come alone/spirale minoritario, desaturato, aperto" esiste oggi solo nel
prompt documentato di `magno_aerodynamic_flow` (icona di calibrazione), ma
tre icone la violano — `migi_turtle_shell` (guscio verde dominante, anello
chiuso, quattro scudetti ghiaccio), `lollo_hyperactivity` (stivale blu
cobalto come colore di soggetto, tre elementi freddi) e `bea_sixth_sense`
(doppia spirale chiusa, gemma frontale ciano satura). Le altre quattro
(Marghe, Zat, Aleo, Magno) rispettano già la regola.

In parallelo, `alea_eagle_never_misses` è tematicamente disallineata: la
passiva di Alea è passata da "L'Aquila Non Sbaglia Mai" a "Due Dita e Parto"
(tema vino/sobrietà, [PS-105](../4_to_test/PS-105-nuova-passiva-alea-due-dita-e-parto.md)),
e l'aquila non comunica più nulla di pertinente.

Il proprietario ha deciso di andare oltre la sola correzione mirata: vuole
rigenerare tutte e otto le icone come candidati da confrontare contro le
attuali, per poi scegliere icona per icona se promuovere la nuova o tenere
la vecchia. Il game-art-designer ha pianificato i brief e la geometria di
consegna in modalità pianificazione (PS-109); tre decisioni erano del
proprietario e sono state raccolte con `AskUserQuestion` (vedi Decisioni).

## Comportamento atteso

Esistono, in `assets/art/icons/passives/_review/v2/` (area di revisione con
proprio `.gdignore`, esclusa da import/export Godot), otto candidati di
rigenerazione — un master HD + un derivato `128×128` per ciascuna delle otto
icone passive del cast — pensati per un confronto diretto vecchio/nuovo da
parte del proprietario, **senza sostituire alcun file wired** in `hd/`/
`generated/`. Ogni candidato rispetta lo stile pixel-art 32-bit già
calibrato su Magno (emblema centrato, silhouette forte, sfondo chroma-key,
nessun testo/cornice/ombra) e la regola dell'accento freddo fissata
dall'analisi ciano: palette caldo-dominante (oro/bronzo/pelle) per soggetto
e bordo, ciano ammesso solo come alone/spirale minoritario **aperto** (mai
anello chiuso), desaturato verso bianco-ghiaccio (mai ciano puro), copertura
≤10% dei pixel visibili, un'unica tonalità fredda per icona, mai un secondo
elemento a tinta piena in un blu diverso. Bea, Lollo e Migi correggono
violazioni accertate della regola; Magno, Marghe e Zat vengono ridipinte
liberamente nello stesso stile (libertà su dettagli/posa/luce, soggetto e
palette calda invariati); Aleo rigenera la stessa composizione a split
caldo/freddo con una barra di sostituzione alta; Alea cambia soggetto in una
bottiglia di vino in movimento, tematicamente allineata a "Due Dita e Parto"
e visivamente distinta dal calice HUD di PS-104.

## Criteri di accettazione

**Geometria di consegna (vale per tutte e otto)**

- [ ] Nessun file in `assets/art/icons/passives/hd/*_source.png` o
      `assets/art/icons/passives/generated/*.png` (i wired attuali) viene
      modificato, rinominato o sovrascritto da questa card.
- [ ] Esiste `assets/art/icons/passives/_review/v2/.gdignore` (vuoto) e sotto
      quella cartella un master HD (`<slug>_source.png`) + un derivato
      `128×128` RGBA (`<slug>.png`) per ciascuna delle otto icone, prodotto
      con `tools/process-passive-icon.ps1` (stessi parametri già in
      manifest: soglia alpha `8`, padding `12`, riduzione nearest-neighbor).
- [ ] `<slug>` coincide col nome file wired attuale per le sette icone che
      non cambiano soggetto (`bea_sixth_sense`, `lollo_hyperactivity`,
      `migi_turtle_shell`, `marghe_contagious_smile`, `zat_delayed_healing`,
      `aleo_internal_thermostat`, `magno_aerodynamic_flow`); per Alea è
      `alea_two_fingers_and_go` (nuovo `passive_id` da
      `data/friends/alea.tres`, non più `alea_eagle_never_misses`).
- [ ] `assets/art/icons/passives/ASSET-MANIFEST.md` riceve una nuova sezione
      `## Candidati v2 — in revisione, non wired` con: data, prompt usato
      per ciascuna icona, tabella master/derivato con SHA-256 di entrambi
      per gli otto percorsi `_review/v2/`, e nota esplicita che nessuna riga
      è referenziata da scene/`.tres`/script.

**Alea — nuovo soggetto: bottiglia in movimento**

- [ ] Il candidato sostituisce l'aquila con una bottiglia di vino
      inclinata/versante, palette calda dominante (vetro verde bottiglia
      scuro o ambrato, etichetta/capsula oro, filo di vino rosso versato
      reso in tono caldo, non ciano), con una spirale di moto (non un anello
      chiuso) che suggerisce velocità/rotazione attorno o dietro alla
      bottiglia.
- [ ] L'unico accento freddo è quella spirale di moto: aperta, desaturata
      verso bianco-ghiaccio, copertura ≤10% dei pixel visibili, nessun
      secondo elemento blu a tinta piena.
- [ ] L'inquadratura è dinamica (bottiglia inclinata/in versamento, con
      linee di moto), non frontale e statica come il calice HUD di PS-104
      (`alea_sobriety_glass_empty.png`/`alea_sobriety_wine_fill.png`): le
      due icone restano riconoscibili come asset distinti a colpo d'occhio,
      pur condividendo il tema vino.
- [ ] Nessun testo, etichetta leggibile o marchio reale sulla bottiglia.

**Aleo — stessa composizione a split, bar alta**

- [ ] Il candidato mantiene lo split verticale caldo/freddo (fiamma/tizzone
      da un lato, fiocco di neve/ghiaccio dall'altro, ago del quadrante,
      cornice oro) della versione wired: nessun cambio di concetto, solo un
      tentativo di esecuzione più pulita.
- [ ] Nota per la fase di scelta: essendo un'eccezione di design già
      conforme, il candidato v2 si promuove solo se percettibilmente più
      leggibile/pulito della versione attuale — a parità di qualità resta
      la wired.

**Bea — correzione ciano obbligata**

- [ ] Il candidato mantiene la testa di cavallo baia/castana calda con
      criniera scura come soggetto.
- [ ] Il terzo occhio/gemma frontale è in tono caldo (ambra/oro) o ridotto a
      dettaglio minimo, non più ciano saturo.
- [ ] La doppia spirale chiusa attorno alla testa è sostituita da un'unica
      spirale aperta, desaturata verso bianco-ghiaccio, copertura ≤10% dei
      pixel visibili.

**Lollo — correzione ciano obbligata**

- [ ] Il candidato mantiene lo stivale come soggetto ma ricolorato in pelle
      calda (cuoio/tan o bordeaux con impunture/fibbie oro), non più blu
      cobalto come colore dominante del soggetto.
- [ ] L'energia di velocità (fulmine/scintille) è resa in oro/ambra, non in
      ciano.
- [ ] Resta un'unica spirale ciano aperta e desaturata come accento freddo
      residuo; le sfere orbitanti blu extra sono rimosse o riconvertite a
      tono caldo; copertura freddo complessiva ≤10% dei pixel visibili.

**Migi — correzione ciano obbligata**

- [ ] Il candidato mantiene la forma di guscio di tartaruga come soggetto,
      ricolorato in palette calda (ambra/miele/bronzo con venature scure,
      tipo carapace reale), non più verde smeraldo come colore dominante.
- [ ] Il bordo oro esistente è preservato.
- [ ] I quattro scudetti ghiaccio/bianco ai punti cardinali sono rimossi.
- [ ] L'anello ciano chiuso a doppia linea è sostituito da un'unica spirale
      aperta, desaturata verso bianco-ghiaccio, copertura ≤10% dei pixel
      visibili.

**Magno — ridipintura libera nello stesso stile**

- [ ] Il candidato mantiene la testa di toro bronzo/avorio come soggetto e
      la palette calda-dominante già in uso, con libertà di variare posa,
      angolazione, luce e dettagli rispetto alla versione wired.
- [ ] La spirale ciano di accento resta aperta, desaturata verso
      bianco-ghiaccio, unica tonalità fredda, copertura ≤10% dei pixel
      visibili (nessuna regressione sulla regola già rispettata dalla
      wired).

**Marghe — ridipintura libera nello stesso stile**

- [ ] Il candidato mantiene la maschera teatrale dorata (sorriso, cuoricini,
      sparkle) come soggetto e la palette calda-dominante (oro/rosso/rosa)
      già in uso, con libertà di variare posa, espressione, luce e dettagli
      rispetto alla versione wired.
- [ ] Nessun elemento ciano/blu introdotto: la wired non ne ha e il
      candidato non deve regredire sulla regola.

**Zat — ridipintura libera nello stesso stile**

- [ ] Il candidato mantiene la clessidra (legno/oro, cuore rosso, viti
      verdi) come soggetto e la palette calda-dominante già in uso, con
      libertà di variare posa, dettagli e luce rispetto alla versione
      wired.
- [ ] Il piccolo cristallo/dettaglio freddo alla base resta un'unica
      tonalità, desaturato verso bianco-ghiaccio, copertura ≤10% dei pixel
      visibili (se il candidato lo rendesse più saturo del previsto, va
      corretto prima di considerarlo completo).

## Ambito

- Nuovi master e derivati sotto `assets/art/icons/passives/_review/v2/`.
- `ASSET-MANIFEST.md` di `assets/art/icons/passives/`.

Non toccare:

- `assets/art/icons/passives/hd/*_source.png` e
  `assets/art/icons/passives/generated/*.png` wired attuali;
- `data/friends/*.tres` e qualunque scena o script (nessun wiring in questa
  card, per convenzione PS-090);
- l'icona calice HUD di Alea (`alea_sobriety_glass_empty.png`/
  `alea_sobriety_wine_fill.png`, PS-104/PS-106): asset distinto, non toccato
  qui.

## Verifica

- Nessuno smoke GUT: card `tipo: art`, verificata da art review e manifest
  come da convenzione PS-090.

## Gate manuali

- Non pertinenti: nessun wiring, nessuna scena o script toccati da questa
  card. Restano dei gate della/e card di promozione successiva, una volta
  che il proprietario avrà scelto quali candidati sostituiscono i wired.

## Decisioni

- **2026-09-08 — Rigenerazione completa delle otto icone, non solo delle tre
  in violazione.** Il proprietario ha confermato di voler confrontare
  vecchio e nuovo su tutto il set, non solo su Bea/Lollo/Migi, con
  promozione decisa in seguito icona per icona.
- **2026-09-08 — Geometria di consegna: candidati non wired in
  `_review/v2/`.** Decisione tecnica del game-art-designer in pianificazione
  (PS-109): i candidati non sostituiscono i file wired, per permettere il
  confronto diretto richiesto dal proprietario. Una card successiva
  promuoverà i vincitori ai percorsi canonici.
- **2026-09-08 — Soggetto Alea: bottiglia di vino in movimento.** Confermato
  dal proprietario tra le opzioni proposte (bottiglia in movimento, gesto
  "due dita" col bicchiere, calice in piroetta, dadi in volo con vino);
  scelta la bottiglia per restare più distinta dal calice HUD di PS-104.
- **2026-09-08 — Magno, Marghe, Zat: ridipintura libera, non mero
  re-render.** Confermato dal proprietario: per le icone già conformi alla
  regola del ciano (esclusa Aleo, trattata a parte), il candidato v2 ha
  libertà di variare posa/dettagli/luce a parità di soggetto e palette,
  invece di limitarsi a una verifica di riproducibilità 1:1.
- **2026-09-08 — Aleo incluso nel giro nonostante sia un'eccezione
  conforme.** Confermato dal proprietario: stessa composizione a split,
  promozione solo se la v2 risulta chiaramente più pulita della wired.

## Documenti sincronizzati

- [ ] Nessuno a questo stadio: la card si ferma a candidati non wired.
      `docs/visual-audio-identity.md` e `assets/art/icons/passives/
      ASSET-MANIFEST.md` (sezione wired) ricevono il risultato solo dalla
      card di promozione successiva, una volta scelti i vincitori.

## Note

Card di sola produzione candidati (PS-090): la promozione dei vincitori a
percorsi canonici, l'eventuale rinomina definitiva dei file di Alea e
l'aggiornamento della tabella wired del manifest sono compito di una card
successiva, aperta quando il proprietario avrà scelto icona per icona quale
candidato tenere. Esecuzione: game-art-designer per direzione e manifest;
sintesi vera (ImageGen) esclusiva di Codex (PS-112) — se un master v2 non
esiste già, la card resta "direzione pronta, generazione di competenza
Codex" finché Codex non produce i master.
