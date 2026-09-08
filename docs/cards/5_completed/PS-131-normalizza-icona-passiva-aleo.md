---
id: PS-131
titolo: Normalizza l'icona della passiva di Aleo allo stile delle altre sette
tipo: art
area: arte
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-09-08
aggiornato: 2026-09-08
---

# PS-131 — Normalizza l'icona della passiva di Aleo allo stile delle altre sette

## Contesto

Prima di PS-131, `assets/art/icons/passives/generated/aleo_internal_thermostat.png`
era l'unica delle otto icone passive a essere fuori famiglia, e non per
sfumature. Le altre
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

Terzo scarto: lo split verticale ~50/50 dell'icona attuale vive dentro un
quadrante e usa tre fiocchi di neve in blu saturo. Il problema non è più la
quantità di freddo — il proprietario ha approvato uno split materiale 50/50 —
ma la grammatica da strumento incorniciato e i simboli freddi separati.

Questa card **sostituisce** il blocco «Aleo — stessa composizione a split, bar
alta» di [PS-130](../1_idea/PS-130-rigenera-otto-icone-passive-cast.md), che
trattava Aleo come eccezione già conforme da rigenerare mantenendo lo split.
PS-130 è ora parcheggiata in `1_idea` e quel criterio non va eseguito.

## Comportamento atteso

Esiste un candidato di icona per la passiva di Aleo che appartiene visivamente
alla stessa famiglia delle altre sette: soggetto singolo a silhouette libera su
trasparenza, nessun anello o cornice strutturale, nessun fondo opaco, contrasto
caldo/freddo interno allo stesso oggetto.

Il soggetto è un **tizzone ardente** — carbone/brace incandescente — con una
sua metà congelata: la stessa massa passa da brace viva a crosta di
brina/ghiaccio aderente, senza elementi freddi separati. Il
candidato vive in un'area di revisione non wired: nessun file oggi in uso viene
sostituito finché il proprietario non ha confrontato vecchio e nuovo.

L'icona mantiene quindi una dualità 50/50, ma la trasferisce dal quadrante a un
cambio di materia leggibile sul singolo tizzone. Testo, tell termici di
PS-098/PS-099 e aura descritta in `docs/characters.md` restano invariati.

## Criteri di accettazione

**Appartenenza alla famiglia**

- [x] Il candidato non ha alcun anello, bezel o cornice strutturale che
      racchiuda il soggetto: silhouette libera, come le altre sette.
- [x] Il candidato non ha alcun fondo interno opaco dietro il soggetto: solo
      trasparenza, o accenti aperti (aloni, scintille, spirali).
- [x] Nessun testo, lettera, numero, logo, watermark, ombra proiettata o
      riflesso.
- [x] Il soggetto resta leggibile come singola silhouette alla dimensione a cui
      l'icona è mostrata nel selettore personaggi, non solo a piena risoluzione.

**Contrasto caldo/freddo**

- [x] Il singolo tizzone mostra uno split materiale circa `50/50`: una metà è
      brace viva arancio-oro, l'altra è carbone congelato bianco-ghiaccio/ciano.
- [x] Il confine caldo/freddo attraversa la massa del tizzone ed è leggibile a
      `128×128`; non è un anello, un quadrante o una cornice che lo racchiude.
- [x] Il freddo resta aderente allo stesso oggetto: nessuna spirale separata,
      fiocco di neve o seconda icona fredda.

**Soggetto e distinzione dagli asset termici già esistenti**

- [x] Il soggetto è un tizzone/carbone ardente, non un termometro: esistono già
      `assets/art/vfx/state_tells/generated/thermometer_hot.png` e
      `thermometer_cold.png` (PS-098), emblemi caldi a silhouette libera nello
      stesso stile — un'icona-termometro sarebbe un doppione a colpo d'occhio.
- [x] La composizione resta distinta da
      `assets/art/icons/signatures/generated/evil_aleo_thermal_shock.png`, che è
      un'esplosione calda circondata da cristalli di ghiaccio: qui esiste un
      solo tizzone, senza esplosione centrale, cristalli separati o corona
      radiale. Le due icone non devono leggersi come varianti della stessa
      immagine.

**Geometria di consegna**

- [x] Esiste `assets/art/icons/passives/_review/aleo_normalize/.gdignore`
      (vuoto) e, sotto quella cartella, il master HD
      `aleo_internal_thermostat_v2_source.png` e il derivato `128×128` RGBA
      `aleo_internal_thermostat_v2.png`, prodotto con
      `tools/process-passive-icon.ps1` ai valori di default già usati per tutte
      le sorelle (`-Size 128 -VisibleAlphaThreshold 8 -Padding 12`).
- [x] Nessun file in `assets/art/icons/passives/hd/` o `generated/` viene
      modificato, rinominato o sovrascritto da questa card.
- [x] `data/friends/aleo.tres` non viene toccato.
- [x] `assets/art/icons/passives/ASSET-MANIFEST.md` riceve una sezione
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

- [x] Confronto percettivo del proprietario fra il candidato e l'icona wired,
      per decidere la promozione.

Non pertinenti: runtime Windows, validazione statica dell'APK, runtime fisico
Pixel 9 — nessun wiring, nessun file di gioco toccato.

## Decisioni

- **2026-09-08 — Produzione avviata come candidato non wired.** Ownership
  limitata a `_review/aleo_normalize/` e al manifest delle icone passive;
  master e derivato correnti, `data/friends/aleo.tres` e runtime restano
  invariati fino alla review del proprietario.
- **2026-09-08 — Il proprietario sostituisce la regola freddo minoritario con
  uno split materiale circa 50/50.** Dopo aver visto il candidato caldo con
  spirale di brina, lo ha giudicato privo di sufficiente contrasto e ha scelto
  un tizzone congelato da un lato. La nuova regola preserva il soggetto unico
  e la silhouette libera, ma rende caldo e freddo due metà dello stesso
  oggetto; supera la precedente scelta dell'accento freddo ≤10%.
- **2026-09-08 — Candidato split prodotto e posto in verifica.** Selezionato
  l'output ImageGen `exec-6346a973-ba75-4d7a-9f5b-1fdd64c6414f.png` dopo aver
  scartato le varianti con spirale fredda. Il master con alpha reale e il
  derivato `128×128` vivono solo in `_review/aleo_normalize/`; la review
  isolata conferma contrasto, silhouette unica e distinzione dalla Signature
  Evil. La promozione resta subordinata al confronto del proprietario.
- **2026-09-08 — Candidato approvato e promosso.** Il proprietario ha risposto
  «Promosso!». Master e derivato approvati hanno sostituito i file canonici
  mantenendo invariato il percorso già referenziato da `data/friends/aleo.tres`;
  nessun wiring, scena, script o dato è stato modificato.

- **2026-09-08 — Il game-art-designer è stato consultato in pianificazione
  (PS-109).** Ha confermato la diagnosi e aggiunto due elementi non evidenti:
  il fondo opaco duplica la cornice che `PassiveCard` fornisce già, e la
  clessidra di Zat dimostra che un «oggetto strumento» sta bene nella famiglia
  purché la sua sagoma *sia* il soggetto, non un frame che contiene altro.
- **2026-09-08 — Scelta precedente del proprietario, superata: soggetto
  singolo caldo con accento freddo minoritario.** Fra le tre direzioni proposte (A: oggetto termico caldo
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

- [x] `assets/art/icons/passives/ASSET-MANIFEST.md`: aggiunta la sezione del
      candidato non wired con prompt, provenienza, trasformazioni e hash. Alla
      promozione andranno aggiornate la riga Aleo della tabella wired in
      `assets/art/icons/passives/ASSET-MANIFEST.md` e, se si vuole annotare che
      l'icona UI non usa più lo stesso split dell'aura di gioco, la sezione
      «Master e derivati correnti» di `docs/characters/aleo.md`.
      `docs/characters.md` riga 178 resta valida: descrive l'aura del
      personaggio, non l'icona.
- [x] `docs/characters/aleo.md`: aggiunta la direzione durevole dell'icona
      approvata e i percorsi canonici di master e derivato.

## Note

**Mini art direction proposta**, nel formato del prompt di calibrazione di
Magno già documentato nel manifest. Da rifinire in produzione, non da prendere
come definitiva (vedi Decisioni sulla perdita del sotto-agente):

```text
Use case: stylized-concept
Asset type: passive ability icon for a Godot pixel-fantasy character selection screen
Primary request: create one square pixel-art emblem for the passive ability "Termostato Interno"
Subject: a single ember coal split materially in two, one half glowing with orange-gold heat and the other half frozen under an attached ice-white/cyan frost crust
Style/medium: polished 32-bit fantasy pixel art, crisp chunky pixels, readable when reduced to 72x72, matching a dark medieval-fantasy game UI, with immediate balanced warm/cold contrast
Composition/framing: centered single emblem, generous padding, strong silhouette, no enclosing card or outer frame
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for background removal
Constraints: one icon and one continuous coal silhouette only; no text, no letters, no numbers, no logo, no watermark; no cast shadow, contact shadow, reflection, gradients or texture in the background; keep the subject fully separated from the background; the material split may be approximately 50/50; do not use #00ff00 anywhere in the emblem
Avoid: photorealism, smooth vector style, emoji style, circular app-icon container, UI mockup, multiple icons, a thermometer shape, detached frost spiral, snowflakes, separate ice crystals, explosive radial composition
```

Esecuzione: la sintesi vera è esclusiva di Codex (PS-112). Il
game-art-designer lato Claude può fare art review, derivazione con
`process-passive-icon.ps1` e manifest, ma non generare il master: finché Codex
non lo produce la card resta «direzione pronta, generazione di competenza
Codex».

Promozione eseguita in-place su `hd/aleo_internal_thermostat_source.png` e
`generated/aleo_internal_thermostat.png`; la riga Aleo del manifest usa ora
gli hash approvati. Il refresh headless dell'editor Godot 4.7.1 ha reimportato
`aleo_internal_thermostat.png` con marker `[ DONE ] reimport` e senza errori.

Evidenza candidata: master `1254×1254`, SHA-256
`DE7C74482368403EEDAFB78B37DDE60184AA856C8244A1CC1A54797BF7FDE009`;
derivato `128×128`, SHA-256
`4682CAE23E55D5D4CBDBF884A84C3C3E49CC1B35252C8AEC0B8B77246A9FDE74`.
I quattro angoli hanno alpha `0`; nessun pixel visibile resta verde-dominante.
