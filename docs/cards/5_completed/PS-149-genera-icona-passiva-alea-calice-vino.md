---
id: PS-149
titolo: Genera la nuova icona della passiva di Alea — calice di vino brilla
tipo: art
area: arte
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-149 — Genera la nuova icona della passiva di Alea — calice di vino brilla

## Contesto

L'icona passiva di Alea nel selettore personaggi
(`assets/art/icons/passives/generated/alea_eagle_never_misses.png`, un'aquila)
è rimasta tematicamente disallineata: [PS-105](./PS-105-nuova-passiva-alea-due-dita-e-parto.md)
ha sostituito la passiva "L'Aquila Non Sbaglia Mai" con "Due Dita e Parto"
(tema vino/sobrietà) e ha già rinominato `passive_id` in
`data/friends/alea.tres` in `alea_two_fingers_and_go`, ma `passive_icon`
punta ancora al file dell'aquila — l'unico disallineamento rimasto.

[PS-130](../1_idea/PS-130-rigenera-otto-icone-passive-cast.md) aveva già
raccolto con `AskUserQuestion` la direzione per il caso Alea prima di essere
parcheggiata "DA DEFINIRE" per le altre sette icone (nessuna violazione o
disallineamento accertato lì): questa card estrae solo il caso Alea, stessa
forma già usata per [PS-131](../5_completed/PS-131-normalizza-icona-passiva-aleo.md)
con Aleo.

A differenza di PS-131 (rinfresco in-place allo stesso percorso wired), qui
il soggetto cambia da un'aquila a un calice: il file prende un nome
nuovo, quindi la promozione richiede ripuntare `ExtResource` in
`data/friends/alea.tres` — per questo la produzione resta separata
dall'integrazione (PS-090), a differenza di PS-131.

## Comportamento atteso

Esiste un candidato di icona per la passiva di Alea che appartiene
visivamente alla stessa famiglia delle altre sette (soggetto singolo a
silhouette libera su trasparenza) e comunica il tema "Due Dita e Parto"
invece dell'aquila. Il candidato vive in un'area di revisione non wired:
nessun file oggi in uso viene sostituito finché il proprietario non ha
confrontato vecchio e nuovo.

Il soggetto è un **calice di vino rosso fortemente inclinato**, con il vino
che sborda dal bordo e una sola stellina sopra il calice, accompagnata da una
breve scia curva: il gesto deve comunicare immediatamente «sono brilla e vedo
le stelle». Vetro freddo, vino borgogna e dettagli oro riprendono la famiglia
visiva di Alea senza confondere l'icona con il calice HUD verticale.

## Criteri di accettazione

**Appartenenza alla famiglia**

- [x] Il candidato non ha alcun anello, bezel o cornice strutturale che
      racchiuda il soggetto: silhouette libera, come le altre sette icone
      passive.
- [x] Il candidato non ha alcun fondo interno opaco dietro il soggetto: solo
      trasparenza, o accenti aperti (aloni, scintille, spirali).
- [x] Nessun testo, lettera, numero, logo, watermark, etichetta leggibile o
      marchio reale, ombra proiettata o riflesso.
- [x] Il soggetto resta leggibile come singola silhouette alla dimensione a
      cui l'icona è mostrata nel selettore personaggi, non solo a piena
      risoluzione.

**Soggetto e stato “brilla”**

- [x] Il soggetto è un calice di vino rosso fortemente inclinato, con una
      porzione evidente di vino borgogna che supera e sborda dal bordo; il
      vetro usa riflessi freddi e dettagli oro coerenti con Alea.
- [x] Sopra il calice compare una sola stellina dorata, con una breve scia
      curva aperta che ne suggerisce il movimento: insieme allo sbordo deve
      comunicare «sono brilla e vedo le stelle», senza spirali chiuse,
      costellazioni o ulteriori simboli.
- [x] L'inquadratura è dinamica (calice diagonale, vino in sbordo e stella in
      moto), non frontale e statica come il calice HUD di PS-104
      (`alea_sobriety_glass_empty.png`/`alea_sobriety_wine_fill.png`): le due
      icone restano riconoscibili come asset distinti a colpo d'occhio, pur
      condividendo il tema vino.

**Geometria di consegna**

- [x] Esiste `assets/art/icons/passives/_review/alea_goblet/.gdignore`
      (vuoto) e, sotto quella cartella, il master HD
      `alea_two_fingers_and_go_source.png` e il derivato `128×128` RGBA
      `alea_two_fingers_and_go.png`, prodotto con
      `tools/process-passive-icon.ps1 -Size 128 -VisibleAlphaThreshold 8
      -Padding 12`.
- [x] Nessun file in `assets/art/icons/passives/hd/` o `generated/` viene
      modificato, rinominato o sovrascritto da questa card; il file corrente
      `alea_eagle_never_misses.png` resta invariato.
- [x] `data/friends/alea.tres` non viene toccato.
- [x] `assets/art/icons/passives/ASSET-MANIFEST.md` riceve una sezione
      `## Candidato — icona passiva Alea (in revisione, non wired)` con data,
      prompt usato, generatore, licenza, trasformazione e SHA-256 di master e
      derivato, più la nota esplicita che nessuna riga è referenziata da
      scene, `.tres` o script.

## Ambito

- Nuovi file sotto `assets/art/icons/passives/_review/alea_goblet/`.
- `assets/art/icons/passives/ASSET-MANIFEST.md`.

Non toccare:

- `assets/art/icons/passives/hd/alea_eagle_never_misses_source.png` e
  `generated/alea_eagle_never_misses.png` (wired attuali);
- `data/friends/alea.tres` e qualunque scena, script o registry: nessun
  wiring in questa card, di competenza di
  [PS-150](../2_to_do/PS-150-integra-icona-passiva-alea-calice-vino.md);
- il calice HUD di Alea (`alea_sobriety_glass_empty.png`/
  `alea_sobriety_wine_fill.png`, PS-104/PS-106): asset distinto;
- le altre sette icone passive, materia dell'eventuale ripresa di PS-130.

## Verifica

- Nessuno smoke GUT: card `tipo: art`, verificata da art review e manifest
  come da convenzione PS-090.

## Gate manuali

- [x] Confronto percettivo del proprietario fra il candidato e l'icona
      wired (aquila), per decidere la promozione: approvato.

Non pertinenti: runtime Windows, validazione statica dell'APK, runtime
fisico Pixel 9 — nessun wiring, nessun file di gioco toccato.

## Decisioni

- **2026-09-10 — Estratta da PS-130.** PS-130 aveva isolato il caso Alea prima
  di essere parcheggiata "DA DEFINIRE" per il resto del set; questa card ne
  mantiene il perimetro indipendente.
- **2026-09-10 — Soggetto aggiornato dal proprietario.** La bottiglia prevista
  inizialmente è sostituita da un calice di rosso inclinato, con vino che
  sborda e una sola stellina con scia sopra: il segnale narrativo richiesto è
  «sono brilla e vedo le stelle». La diagonale, lo sbordo e la stella
  distinguono l'emblema dal calice HUD verticale di PS-104.
- **2026-09-10 — Produzione separata dall'integrazione (PS-090), a
  differenza di PS-131.** Il soggetto cambia (aquila → calice), quindi il
  file prende un nuovo slug (`alea_two_fingers_and_go`, già il `passive_id`
  in `data/friends/alea.tres`) invece di rinfrescare lo stesso percorso: la
  promozione richiederà ripuntare `ExtResource`, un wiring reale che PS-090
  vieta di bundlare in una card `art`.

## Documenti sincronizzati

- [x] `assets/art/icons/passives/ASSET-MANIFEST.md`.

## Note

Esecuzione: la sintesi vera è esclusiva di Codex (PS-112). Il
game-art-designer lato Claude può fare art review, derivazione con
`process-passive-icon.ps1` e manifest, ma non generare il master.

Mini art direction, nel formato del prompt di calibrazione di Magno già
documentato nel manifest (da rifinire in produzione):

```text
Use case: stylized-concept
Asset type: passive ability icon for a Godot pixel-fantasy character selection screen
Primary request: create one square pixel-art emblem for the passive ability "Due Dita e Parto"
Subject: one strongly tilted wine goblet filled with burgundy red wine spilling visibly over the rim, with exactly one small golden star above it followed by a short open curved trail; together they communicate "tipsy and seeing stars"
Style/medium: polished 32-bit fantasy arcade pixel art, crisp chunky clusters, stepped edges, dark-plum outline, banded shading, readable when reduced to 72x72, matching the existing passive-icon family
Composition/framing: centered compact emblem, generous padding, strong diagonal silhouette, the spill and star remain inside the safe area, no enclosing card or outer frame
Scene/backdrop: genuinely transparent background
Constraints: one goblet, one continuous wine spill and exactly one star only; transparent pale-blue glass highlights, burgundy wine and restrained gold details; no text, letters, numbers, logo, watermark, cast shadow, contact shadow, background reflection, gradient or background texture; keep every visible element fully separated from the background; do not use #00ff00 anywhere in the emblem
Avoid: photorealism, smooth vector style, emoji style, circular app-icon container, UI mockup, multiple icons, bottle, static upright frontal goblet, closed ring, spiral around the goblet, constellation, multiple stars, bubbles, face, hands, real-world wine brand references, green background
```

Evidenza di produzione e art review:

- master ImageGen built-in `1254×1254` RGBA, angoli alpha `0`, SHA-256
  `8E844C28A267B6CDE5B7DE06EE2AC3D7E3CCDC31033CA7348CA224E6BDB37DBE`;
- derivato `128×128` RGBA prodotto dallo script prescritto, angoli alpha
  `0`, SHA-256
  `20D3FB3A56665529D8DE030EA0E74AA11333576A1CB1E1419D552D1DF5985614`;
- controllo isolato anche a `72×72`: calice, vino in sbordo e singola stella
  restano distinguibili; nessun wiring eseguito.

Approvazione del proprietario (2026-09-10): «ho generato gli assets per alea
e ho approvato il design». Promozione ai percorsi canonici e ripuntamento in
`data/friends/alea.tres` di competenza di
[PS-150](../2_to_do/PS-150-integra-icona-passiva-alea-calice-vino.md).
