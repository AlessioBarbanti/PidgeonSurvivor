---
id: PS-149
titolo: Genera la nuova icona della passiva di Alea — bottiglia di vino in movimento
tipo: art
area: arte
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-149 — Genera la nuova icona della passiva di Alea — bottiglia di vino in movimento

## Contesto

L'icona passiva di Alea nel selettore personaggi
(`assets/art/icons/passives/generated/alea_eagle_never_misses.png`, un'aquila)
è rimasta tematicamente disallineata: [PS-105](../4_to_test/PS-105-nuova-passiva-alea-due-dita-e-parto.md)
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
il soggetto cambia da un'aquila a una bottiglia: il file prende un nome
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

Il soggetto è una **bottiglia di vino inclinata/versante**, palette calda
dominante (vetro verde bottiglia scuro o ambrato, etichetta/capsula oro, filo
di vino rosso versato in tono caldo, non ciano), con una spirale di moto
(non un anello chiuso) che suggerisce velocità/rotazione attorno o dietro
alla bottiglia come unico accento freddo.

## Criteri di accettazione

**Appartenenza alla famiglia**

- [ ] Il candidato non ha alcun anello, bezel o cornice strutturale che
      racchiuda il soggetto: silhouette libera, come le altre sette icone
      passive.
- [ ] Il candidato non ha alcun fondo interno opaco dietro il soggetto: solo
      trasparenza, o accenti aperti (aloni, scintille, spirali).
- [ ] Nessun testo, lettera, numero, logo, watermark, etichetta leggibile o
      marchio reale, ombra proiettata o riflesso.
- [ ] Il soggetto resta leggibile come singola silhouette alla dimensione a
      cui l'icona è mostrata nel selettore personaggi, non solo a piena
      risoluzione.

**Soggetto e contrasto caldo/freddo**

- [ ] Il soggetto è una bottiglia di vino inclinata o in atto di versare,
      palette calda dominante (vetro verde scuro o ambrato, etichetta/capsula
      oro, filo di vino rosso reso in tono caldo).
- [ ] L'unico accento freddo è una spirale di moto aperta (non un anello
      chiuso) attorno o dietro alla bottiglia, desaturata verso
      bianco-ghiaccio, copertura ≤10% dei pixel visibili, nessun secondo
      elemento a tinta piena in un blu diverso.
- [ ] L'inquadratura è dinamica (bottiglia inclinata/in versamento con linee
      di moto), non frontale e statica come il calice HUD di PS-104
      (`alea_sobriety_glass_empty.png`/`alea_sobriety_wine_fill.png`): le due
      icone restano riconoscibili come asset distinti a colpo d'occhio, pur
      condividendo il tema vino.

**Geometria di consegna**

- [ ] Esiste `assets/art/icons/passives/_review/alea_bottle/.gdignore`
      (vuoto) e, sotto quella cartella, il master HD
      `alea_two_fingers_and_go_source.png` e il derivato `128×128` RGBA
      `alea_two_fingers_and_go.png`, prodotto con
      `tools/process-passive-icon.ps1 -Size 128 -VisibleAlphaThreshold 8
      -Padding 12`.
- [ ] Nessun file in `assets/art/icons/passives/hd/` o `generated/` viene
      modificato, rinominato o sovrascritto da questa card; il file corrente
      `alea_eagle_never_misses.png` resta invariato.
- [ ] `data/friends/alea.tres` non viene toccato.
- [ ] `assets/art/icons/passives/ASSET-MANIFEST.md` riceve una sezione
      `## Candidato — icona passiva Alea (in revisione, non wired)` con data,
      prompt usato, generatore, licenza, trasformazione e SHA-256 di master e
      derivato, più la nota esplicita che nessuna riga è referenziata da
      scene, `.tres` o script.

## Ambito

- Nuovi file sotto `assets/art/icons/passives/_review/alea_bottle/`.
- `assets/art/icons/passives/ASSET-MANIFEST.md`.

Non toccare:

- `assets/art/icons/passives/hd/alea_eagle_never_misses_source.png` e
  `generated/alea_eagle_never_misses.png` (wired attuali);
- `data/friends/alea.tres` e qualunque scena, script o registry: nessun
  wiring in questa card, di competenza di
  [PS-150](./PS-150-integra-icona-passiva-alea-bottiglia-vino.md);
- il calice HUD di Alea (`alea_sobriety_glass_empty.png`/
  `alea_sobriety_wine_fill.png`, PS-104/PS-106): asset distinto;
- le altre sette icone passive, materia dell'eventuale ripresa di PS-130.

## Verifica

- Nessuno smoke GUT: card `tipo: art`, verificata da art review e manifest
  come da convenzione PS-090.

## Gate manuali

- [ ] Confronto percettivo del proprietario fra il candidato e l'icona
      wired (aquila), per decidere la promozione.

Non pertinenti: runtime Windows, validazione statica dell'APK, runtime
fisico Pixel 9 — nessun wiring, nessun file di gioco toccato.

## Decisioni

- **2026-09-10 — Estratta da PS-130.** PS-130 aveva già fissato la direzione
  per il caso Alea (bottiglia in movimento, scelta fra le opzioni proposte
  al proprietario per restare distinta dal calice HUD di PS-104) prima di
  essere parcheggiata "DA DEFINIRE" per il resto del set. Questa card ne
  eredita la direzione senza riaprirla.
- **2026-09-10 — Produzione separata dall'integrazione (PS-090), a
  differenza di PS-131.** Il soggetto cambia (aquila → bottiglia), quindi il
  file prende un nuovo slug (`alea_two_fingers_and_go`, già il `passive_id`
  in `data/friends/alea.tres`) invece di rinfrescare lo stesso percorso: la
  promozione richiederà ripuntare `ExtResource`, un wiring reale che PS-090
  vieta di bundlare in una card `art`.

## Documenti sincronizzati

- [ ] `assets/art/icons/passives/ASSET-MANIFEST.md`.

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
Subject: a single tilted wine bottle mid-pour, dark bottle-green or amber glass, gold label/foil capsule, a warm-toned stream of red wine pouring from the neck, with an open motion spiral (not a closed ring) suggesting spin/speed around or behind the bottle
Style/medium: polished 32-bit fantasy pixel art, crisp chunky pixels, readable when reduced to 72x72, matching a dark medieval-fantasy game UI, with immediate warm-dominant palette
Composition/framing: centered single emblem, generous padding, strong silhouette, dynamic tilt, no enclosing card or outer frame
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for background removal
Constraints: one icon and one continuous bottle silhouette only; no text, no letters, no numbers, no logo, no readable label, no watermark; no cast shadow, contact shadow, reflection, gradients or texture in the background; keep the subject fully separated from the background; the cold motion spiral must stay open, desaturated toward ice-white, coverage <=10% of visible pixels; do not use #00ff00 anywhere in the emblem
Avoid: photorealism, smooth vector style, emoji style, circular app-icon container, UI mockup, multiple icons, a static frontal wine glass, closed ring, snowflakes, separate ice crystals, saturated cyan, real-world wine brand references
```
