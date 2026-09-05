---
id: PS-098
titolo: Genera l'aura di potenziamento di Lollo e i tell termici di Aleo
tipo: art
area: arte
stato: PRONTO
priorita: media
dipende_da: []
origine: PS-079
creato: 2026-09-05
aggiornato: 2026-09-05
---

# PS-098 — Genera l'aura di potenziamento di Lollo e i tell termici di Aleo

## Contesto

Il tell di stato delle passive a fasi è stato rilavorato tre volte. B44 tingeva
lo sprite; [PS-001](../6_rejected/PS-001-tell-di-stato-senza-snaturare-lo-sprite.md)
l'ha sostituito con un contorno a 8 direzioni e
[PS-029](../6_rejected/PS-029-rendi-tell-stato-personaggi-piu-visibili.md) l'ha
rinforzato, ma il proprietario ha bocciato il meccanismo stesso: ricalcava il
profilo e rompeva la silhouette pixel-art.
[PS-079](../5_completed/PS-079-particellare-tell-stato-personaggi.md) l'ha
sostituito con un particellare procedurale sospeso sopra la testa, oggi usato da
Aleo, Lollo, Alea e Migi
([passive_state_particles.gd](../../../scripts/vfx/passive_state_particles.gd)).

Il particellare funziona ed è passato per intero dai gate percettivi, ma è
deliberatamente generico: cinque pallini identici per tutti e quattro i
personaggi, dove cambia solo la tinta. PS-079 stesso lo aveva messo per
iscritto — "le due fasi restano distinte solo per colore, non anche per
comportamento... si riconsidererà solo se il gate percettivo lo segnala" — e
lasciava aperta in Note la possibilità che la prima resa non fosse quella
definitiva. Il proprietario vuole ora un tell che appartenga al personaggio
invece di essere lo stesso effetto ricolorato, e in particolare vuole che
l'iperfocus di Lollo si legga come un **potenziamento**, sulla falsariga della
scena classica in cui un personaggio si carica e gli si accende l'aura attorno,
non come un cambio di colore.

Questa card si ferma alla produzione degli asset. Il cablaggio in gioco è
[PS-099](./PS-099-aura-iperfocus-lollo-e-tell-termico-aleo.md), come impone
[PS-090](../5_completed/PS-090-separa-generazione-integrazione-card-art.md).

## Comportamento atteso

Esistono, derivati e a manifest, i cinque asset che PS-099 dovrà cablare:
un'aura di potenziamento per l'iperfocus di Lollo, due aure a terra per le
modalità calda e fredda di Aleo, e i due termometri che ne annunciano il
passaggio.

## Criteri di accettazione

- [ ] Esiste il master `hyperfocus_aura_source.png`: aura di potenziamento che
      si alza attorno e dietro al personaggio, dorata, coerente con il colore di
      fase già in uso (`TELL_LOLLO_FOCUSED`, `Color(1.0, 0.88, 0.28)`).
- [ ] L'aura di Lollo è una **silhouette propria** — una forma di energia con un
      contorno suo — e non il ricalco del profilo di uno sprite del cast: è il
      difetto che ha fatto bocciare PS-001 e non va reintrodotto per via grafica.
- [ ] Esistono i master `thermal_aura_hot_source.png` e
      `thermal_aura_cold_source.png`: due aure a terra, schiacciate in
      prospettiva (più larghe che alte), pensate per stare sotto i piedi del
      personaggio. Arancio di brace la calda, azzurra di brina la fredda,
      coerenti con `TELL_ALEO_HOT` e `TELL_ALEO_COLD`.
- [ ] Le due aure di Aleo si distinguono anche per soggetto e non solo per
      tinta: la calda legge come calore/brace, la fredda come brina/gelo.
- [ ] Esistono i master `thermometer_hot_source.png` e
      `thermometer_cold_source.png`: due termometri, rosso con il segno `+` e
      azzurro con il segno `−`.
- [ ] I due termometri restano distinguibili l'uno dall'altro **anche a
      saturazione azzerata**: il segno e il livello della colonnina bastano a
      dire quale sia, senza dipendere dal solo colore (stesso principio già
      imposto da PS-029 alle coppie di stato).
- [ ] I due termometri sono leggibili alla dimensione a cui compariranno
      accanto a un personaggio da 32×32, non solo a piena risoluzione.
- [ ] Tutti e cinque i master hanno canvas **quadrato** e angoli trasparenti:
      sono i due vincoli che
      [tools/process-ability-vfx.ps1](../../../tools/process-ability-vfx.ps1)
      verifica, ed è il pipeline con cui vanno derivati.
- [ ] I cinque derivati esistono in `assets/art/vfx/state_tells/generated/` e si
      importano in Godot senza errori.
- [ ] I cinque master e i cinque derivati hanno una riga in
      [assets/art/vfx/ASSET-MANIFEST.md](../../../assets/art/vfx/ASSET-MANIFEST.md)
      con percorso, origine, autore, licenza, trasformazioni e SHA-256.
- [ ] I cinque asset si leggono come una famiglia coerente con i VFX già
      approvati in `assets/art/vfx/abilities/`: stesso peso di contorno, stessa
      resa pixel-art, stessa logica di trasparenza.
- [ ] **Nessuna integrazione**: nessun `.gd`, `.tscn`, `.tres` o registry viene
      toccato da questa card. È PS-099 a cablare gli asset.

## Ambito

- `assets/art/vfx/state_tells/hd/` — i cinque master, nuova cartella sullo
  schema di `assets/art/vfx/abilities/hd/`.
- `assets/art/vfx/state_tells/generated/` — i cinque derivati.
- [assets/art/vfx/ASSET-MANIFEST.md](../../../assets/art/vfx/ASSET-MANIFEST.md)
  — le righe obbligatorie.
- [tools/process-ability-vfx.ps1](../../../tools/process-ability-vfx.ps1) — usato
  come pipeline, non modificato.

Da **non** toccare:

- [scripts/vfx/passive_state_particles.gd](../../../scripts/vfx/passive_state_particles.gd),
  [scripts/actors/player.gd](../../../scripts/actors/player.gd) e
  [scripts/content/friend_passive_controller.gd](../../../scripts/content/friend_passive_controller.gd):
  sono ambito di PS-099;
- il particellare di Alea e Migi, che questa card non sostituisce;
- l'autorità di `RunController` su stato, pausa e restart;
- il flusso `welcome → (tutorial) → selezione → run → pausa`;
- gli sprite approvati del cast ([characters.md](../../characters.md));
- i registry degli effetti e qualunque valore di bilanciamento.

## Verifica

- Smoke: `tests/unit/test_ps098_state_tell_vfx_assets.gd` → marker
  `STATE_TELL_VFX_ASSETS_SMOKE_OK` — i cinque derivati si caricano come
  `Texture2D`, hanno canvas quadrato e contengono pixel trasparenti (cioè non
  sono rettangoli pieni).
- Profilo minimo prima della chiusura: `Focused`. Una card `art` di sola
  generazione non tocca il runtime: la regressione dell'area la esegue PS-099
  con `Relevant`.

## Gate manuali

- [ ] Controllo percettivo richiesto: **sì** — approvazione del proprietario sui
      cinque asset prima di considerarli definitivi. Dato lo storico (tre
      meccanismi di tell già bocciati o sostituiti), farli approvare da fermi
      costa meno che scoprirli sbagliati dopo il cablaggio.

Runtime Windows, validazione statica APK e runtime fisico Pixel 9 **non** sono
pertinenti a questa card: nessun asset entra ancora in scena. Restano aperti su
PS-099, dove il tell arriva davvero a schermo.

## Decisioni

- **2026-09-05 — Direzione scelta dal proprietario: aura di potenziamento per
  Lollo, aura a terra più termometro per Aleo.** Il tell smette di essere lo
  stesso effetto ricolorato per quattro personaggi e diventa un linguaggio per
  personaggio. Motivazione: l'iperfocus è meccanicamente un potenziamento
  (movimento e cadenza molto più rapidi) e va letto come tale, non come un
  cambio di tinta.
- **2026-09-05 — Una texture per elemento, animata proceduralmente da PS-099,
  non uno spritesheet.** Tutti i VFX esistenti del progetto sono texture singole
  animate da codice (`grand_spin`, `thermal_bloom`, `fire_trail`) e non esiste
  un pipeline per fogli di frame. In più la generazione non garantisce coerenza
  fra frame indipendenti: due fotogrammi d'aura generati separatamente
  sfarfallerebbero invece di animarsi. Il tremolio dell'aura è quindi
  responsabilità di PS-099 (scala, alfa, scorrimento verticale).
- **2026-09-05 — Due aure a terra distinte invece di una sola tintabile.**
  Ricolorare una singola texture avrebbe fatto ricadere la distinzione
  caldo/freddo interamente sul colore, esattamente ciò che PS-029 ha
  identificato come fragile. Brace e brina sono due soggetti diversi e restano
  leggibili anche a colore attenuato.
- **2026-09-05 — L'aura non riapre la bocciatura di PS-001.** Ciò che è stato
  bocciato è il *ricalco del profilo dello sprite*, non la presenza di un
  segnale attorno al personaggio: l'aura ha una forma propria, sta dietro alla
  sagoma e non ne segue il contorno. Il criterio corrispondente lo impone
  all'asset, prima ancora che al codice.
- **Non sostituisce PS-079** come meccanismo per Alea e Migi: il particellare
  resta il loro tell e non viene toccato.

## Documenti sincronizzati

- [ ] `assets/art/vfx/ASSET-MANIFEST.md`: cinque righe nuove (obbligatorio per
      igiene del repository).
- [x] `characters.md` — non da questa card: le descrizioni pubbliche del tell di
      Aleo e Lollo restano accurate finché gli asset non sono in gioco, ed è
      PS-099 a riscriverle.

## Note

Card `tipo: art` con generazione di nuovi asset: per contratto di board va
delegata all'agente `game-art-designer`, non implementata da `card-risolvi`.

Riferimenti di stile e vincoli tecnici già validi nel repository:

- Derivazione: `.\tools\process-ability-vfx.ps1 -InputPath <hd/..._source.png>
  -OutputPath <generated/....png> -Size 512`; lo script **rifiuta** master non
  quadrati o con angoli non trasparenti.
- I master HD restano esclusi dagli export, come il resto di `assets/art/vfx/`.
- Colori di riferimento già calibrati per contrasto in PS-029 e conservati da
  PS-079, in
  [friend_passive_controller.gd:49-52](../../../scripts/content/friend_passive_controller.gd#L49-L52):
  `TELL_ALEO_HOT` `Color(1.0, 0.55, 0.18)`, `TELL_ALEO_COLD`
  `Color(0.35, 0.78, 1.0)`, `TELL_LOLLO_FOCUSED` `Color(1.0, 0.88, 0.28)`.
- L'aura di Lollo deve funzionare **dietro** un personaggio alto circa 40 unità
  a schermo (texture 32×32 alla scala fissa 1,65 × 1,25): va composta in modo che
  il centro resti leggibile quando ci sta davanti un corpo di quelle proporzioni.
