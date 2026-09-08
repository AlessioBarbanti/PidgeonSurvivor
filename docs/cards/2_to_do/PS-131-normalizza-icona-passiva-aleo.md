---
id: PS-131
titolo: Normalizza l'icona della passiva di Aleo allo stile delle altre sette
tipo: art
area: arte
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-09-08
aggiornato: 2026-09-08
---

# PS-131 — Normalizza l'icona della passiva di Aleo allo stile delle altre sette

## Contesto

`assets/art/icons/passives/generated/aleo_internal_thermostat.png` è l'unica
delle otto icone passive a essere fuori famiglia, e non per sfumature. Le altre
sette (toro di Magno, clessidra di Zat, maschera di Marghe, guscio di Migi,
testa di cavallo di Bea, stivale di Lollo, aquila di Alea) sono emblemi liberi
su trasparenza. Aleo è un **quadrante circolare chiuso**: un bezel bronzo/oro
spesso che racchiude il soggetto a 360°, con un **fondo interno opaco scuro**.

È esattamente ciò che il prompt di calibrazione di Magno — l'unica direzione
documentata del set, in `assets/art/icons/passives/ASSET-MANIFEST.md` — elenca
sotto `Constraints:` e `Avoid:`: «no enclosing card or outer frame», «circular
app-icon container».

Il fondo opaco è anche ridondante nel runtime: l'icona vive dentro `PassiveCard`
di `scenes/ui/character_select_overlay.tscn`, un `PanelContainer` con
`StyleBoxFlat_info_panel` quasi nero e bordo spesso. La cornice scura c'è già
attorno; Aleo la duplica dentro l'icona.

Terzo scarto: l'icona è **fredda per metà**, con uno split verticale ~50/50 e
tre fiocchi di neve in blu saturo. La regola d'accento fissata dall'analisi
ciano vuole il freddo come alone/spirale minoritario, **aperto**, desaturato
verso bianco-ghiaccio, un'unica tonalità, copertura ≤10% dei pixel visibili.

Questa card **sostituisce** il blocco «Aleo — stessa composizione a split, bar
alta» di [PS-130](../1_idea/PS-130-rigenera-otto-icone-passive-cast.md), che
trattava Aleo come eccezione già conforme da rigenerare mantenendo lo split.
PS-130 è ora parcheggiata in `1_idea` e quel criterio non va eseguito.

## Comportamento atteso

Esiste un candidato di icona per la passiva di Aleo che appartiene visivamente
alla stessa famiglia delle altre sette: soggetto singolo a silhouette libera su
trasparenza, nessun anello o cornice strutturale, nessun fondo opaco, palette
caldo-dominante, e il freddo ridotto a un unico accento aperto e minoritario.

Il soggetto è un **tizzone ardente** — carbone/brace incandescente — con una
sottile spirale di brina aperta che lo sfiora senza chiuderglisi attorno. Il
candidato vive in un'area di revisione non wired: nessun file oggi in uso viene
sostituito finché il proprietario non ha confrontato vecchio e nuovo.

L'icona smette quindi di dichiarare uno split 50/50 caldo/freddo. La dualità
della passiva resta raccontata dove già vive: dal testo della card nel
selettore, e in gioco dai tell termici di PS-098/PS-099 e dall'aura descritta
in `docs/characters.md`.

## Criteri di accettazione

**Appartenenza alla famiglia**

- [ ] Il candidato non ha alcun anello, bezel o cornice strutturale che
      racchiuda il soggetto: silhouette libera, come le altre sette.
- [ ] Il candidato non ha alcun fondo interno opaco dietro il soggetto: solo
      trasparenza, o accenti aperti (aloni, scintille, spirali).
- [ ] Nessun testo, lettera, numero, logo, watermark, ombra proiettata o
      riflesso.
- [ ] Il soggetto resta leggibile come singola silhouette alla dimensione a cui
      l'icona è mostrata nel selettore personaggi, non solo a piena risoluzione.

**Regola dell'accento freddo**

- [ ] La palette è caldo-dominante (brace, arancio, oro, bronzo) per soggetto e
      bordo.
- [ ] L'accento freddo è **una sola** tonalità, **aperta** (mai un anello o uno
      split chiuso), desaturata verso bianco-ghiaccio, con copertura ≤10% dei
      pixel visibili del derivato `128×128`.
- [ ] Non esiste un secondo elemento freddo a tinta piena in un blu diverso.

**Soggetto e distinzione dagli asset termici già esistenti**

- [ ] Il soggetto è un tizzone/carbone ardente, non un termometro: esistono già
      `assets/art/vfx/state_tells/generated/thermometer_hot.png` e
      `thermometer_cold.png` (PS-098), emblemi caldi a silhouette libera nello
      stesso stile — un'icona-termometro sarebbe un doppione a colpo d'occhio.
- [ ] Il rapporto caldo/freddo è **invertito** rispetto a
      `assets/art/icons/signatures/generated/evil_aleo_thermal_shock.png`, che è
      dominato dal ghiaccio con un nucleo caldo: qui il caldo è il soggetto e il
      freddo è l'accento. Le due icone non devono leggersi come varianti della
      stessa immagine.

**Geometria di consegna**

- [ ] Esiste `assets/art/icons/passives/_review/aleo_normalize/.gdignore`
      (vuoto) e, sotto quella cartella, il master HD
      `aleo_internal_thermostat_v2_source.png` e il derivato `128×128` RGBA
      `aleo_internal_thermostat_v2.png`, prodotto con
      `tools/process-passive-icon.ps1` ai valori di default già usati per tutte
      le sorelle (`-Size 128 -VisibleAlphaThreshold 8 -Padding 12`).
- [ ] Nessun file in `assets/art/icons/passives/hd/` o `generated/` viene
      modificato, rinominato o sovrascritto da questa card.
- [ ] `data/friends/aleo.tres` non viene toccato.
- [ ] `assets/art/icons/passives/ASSET-MANIFEST.md` riceve una sezione
      `## Candidato — normalizzazione Aleo (in revisione, non wired)` con data,
      prompt usato, generatore, licenza, trasformazione e SHA-256 di master e
      derivato, più la nota esplicita che nessuna riga è referenziata da
      scene, `.tres` o script.

## Ambito

- Nuovi file sotto `assets/art/icons/passives/_review/aleo_normalize/`.
- `assets/art/icons/passives/ASSET-MANIFEST.md`.

Non toccare:

- `assets/art/icons/passives/hd/aleo_internal_thermostat_source.png` e
  `generated/aleo_internal_thermostat.png` (wired attuali);
- `data/friends/aleo.tres`, `scenes/ui/character_select_overlay.tscn` e
  qualunque scena, script o registry: nessun wiring in questa card;
- i tell termici di PS-098/PS-099 e l'icona signature di Evil Aleo, che restano
  asset distinti;
- le altre sette icone passive, materia dell'eventuale ripresa di PS-130.

## Verifica

- Nessuno smoke GUT: card `tipo: art`, verificata da art review e manifest come
  da convenzione PS-090.

## Gate manuali

- [ ] Confronto percettivo del proprietario fra il candidato e l'icona wired,
      per decidere la promozione.

Non pertinenti: runtime Windows, validazione statica dell'APK, runtime fisico
Pixel 9 — nessun wiring, nessun file di gioco toccato.

## Decisioni

- **2026-09-08 — Il game-art-designer è stato consultato in pianificazione
  (PS-109).** Ha confermato la diagnosi e aggiunto due elementi non evidenti:
  il fondo opaco duplica la cornice che `PassiveCard` fornisce già, e la
  clessidra di Zat dimostra che un «oggetto strumento» sta bene nella famiglia
  purché la sua sagoma *sia* il soggetto, non un frame che contiene altro.
- **2026-09-08 — Scelta del proprietario: soggetto singolo caldo con accento
  freddo minoritario.** Fra le tre direzioni proposte (A: oggetto termico caldo
  con brina minoritaria; B: quadrante mantenuto ma aperto, senza anello né
  fondo; C: accessorio del personaggio — manometro o chiave — con cristallo di
  ghiaccio) il proprietario ha scelto A, accettando esplicitamente che l'icona
  smetta di comunicare lo split 50/50. B era stata segnalata come la più
  delicata: uno spicchio freddo abbastanza grande da leggersi come «metà
  fredda» supera il 10%, e uno abbastanza piccolo da rispettarlo non comunica
  più la dualità.
- **2026-09-08 — Dentro la direzione A il soggetto è il tizzone, non il
  termometro.** Il game-art-designer aveva lasciato aperta l'alternativa e
  segnalato che `docs/characters.md` cita già «un termometro che ne annuncia il
  passaggio», valutandolo come possibile rinforzo. Verificando gli asset è
  emerso che quel termometro **esiste già come file**:
  `assets/art/vfx/state_tells/generated/thermometer_hot.png` e
  `thermometer_cold.png` (PS-098) sono emblemi caldi a silhouette libera nello
  stesso stile pixel-art. Un'icona-termometro sarebbe stata un quasi-doppione
  di un asset in uso, quindi il tizzone. Decisione presa dall'orchestratore su
  evidenza verificabile, non dal proprietario: se in art review preferisce
  comunque il termometro, è reversibile senza rifare la card.
- **2026-09-08 — La finalizzazione del brief è stata fatta senza il
  sotto-agente.** Il game-art-designer aveva restituito diagnosi, opzioni,
  geometria di consegna e criteri; alla seconda invocazione, per rifinire il
  soggetto con la risposta del proprietario in mano, non ha più risposto e la
  sessione l'ha perso. Direzione artistica di dettaglio e mini art direction
  vanno quindi considerate **da confermare in art review**, non frutto di una
  seconda passata specialistica.
- **2026-09-08 — Candidato non wired, promozione come passo separato.**
  L'icona attuale è `content_approved` in `data/friends/aleo.tres` e già
  integrata: non va sovrascritta senza confronto. Alla promozione i file
  prendono i nomi canonici già esistenti, quindi il percorso `ExtResource` non
  cambia e **non serve una card di integrazione PS-090**: è un refresh del
  master allo stesso percorso, non un nuovo wiring.
- **Sostituisce:** il blocco di criteri «Aleo» di PS-130.

## Documenti sincronizzati

- [ ] Nessuno a questo stadio: la card si ferma al candidato non wired. Alla
      promozione andranno aggiornate la riga Aleo della tabella wired in
      `assets/art/icons/passives/ASSET-MANIFEST.md` e, se si vuole annotare che
      l'icona UI non usa più lo stesso split dell'aura di gioco, la sezione
      «Master e derivati correnti» di `docs/characters/aleo.md`.
      `docs/characters.md` riga 178 resta valida: descrive l'aura del
      personaggio, non l'icona.

## Note

**Mini art direction proposta**, nel formato del prompt di calibrazione di
Magno già documentato nel manifest. Da rifinire in produzione, non da prendere
come definitiva (vedi Decisioni sulla perdita del sotto-agente):

```text
Use case: stylized-concept
Asset type: passive ability icon for a Godot pixel-fantasy character selection screen
Primary request: create one square pixel-art emblem for the passive ability "Termostato Interno"
Subject: a single glowing ember coal radiating heat, warm orange and gold core with darker charred edges, brushed by one thin open wisp of pale frost that curls past it without enclosing it
Style/medium: polished 32-bit fantasy pixel art, crisp chunky pixels, readable when reduced to 72x72, matching a dark medieval-fantasy game UI, warm-dominant palette with a single desaturated ice-white cold accent
Composition/framing: centered single emblem, generous padding, strong silhouette, no enclosing card or outer frame
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for background removal
Constraints: one icon only; no text, no letters, no numbers, no logo, no watermark; no cast shadow, contact shadow, reflection, gradients or texture in the background; keep the subject fully separated from the background; the cold accent must stay open, desaturated and cover at most a tenth of the visible pixels; do not use #00ff00 anywhere in the emblem
Avoid: photorealism, smooth vector style, emoji style, circular app-icon container, UI mockup, multiple icons, a thermometer shape, an ice-dominant composition
```

Esecuzione: la sintesi vera è esclusiva di Codex (PS-112). Il
game-art-designer lato Claude può fare art review, derivazione con
`process-passive-icon.ps1` e manifest, ma non generare il master: finché Codex
non lo produce la card resta «direzione pronta, generazione di competenza
Codex».

Alla promozione, dopo l'approvazione del proprietario: sostituire in-place
`hd/aleo_internal_thermostat_source.png` e
`generated/aleo_internal_thermostat.png`, rinfrescare l'import Godot e
aggiornare la riga Aleo del manifest coi nuovi hash.
