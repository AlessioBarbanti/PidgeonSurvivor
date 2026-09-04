---
id: PS-058
titolo: Generare l'arte definitiva dei nuovi prop dell'arena
tipo: art
area: arte
stato: IN VERIFICA
priorita: media
dipende_da: [PS-045]
origine:
creato: 2026-09-01
aggiornato: 2026-09-01
---

# PS-058 — Generare l'arte definitiva dei nuovi prop dell'arena

## Contesto

[PS-045](./PS-045-gerarchia-visiva-arena-di-run.md) ha riequilibrato la
composizione dell'arena e, su indicazione del proprietario, ha introdotto due
nuovi `StaticObstacle` in `scenes/game/movement_slice.tscn` (nodo
`World/Obstacles`) per colmare due vuoti compositivi a est e sud-est del
centro: `IceCooler` (ghiacciaia, `footprint_size = Vector2(90, 70)`) e
`WoodCrateStack` (cataste di casse, `footprint_size = Vector2(130, 110)`).
Prima di questa card restavano segnaposto: nessuna `texture` assegnata, solo il
rettangolo colorato disegnato di default da `StaticObstacle`.

## Comportamento atteso

I due prop hanno una texture ImageGen definitiva coerente con lo stile
raster/pixel-art già stabilito dagli altri cinque prop dell'arena (camino,
tavolo, panca, stendino, lavatoio) in `assets/art/arena/generated/`, senza
alterare footprint, posizione, collisione o bilanciamento.

## Criteri di accettazione

- [x] `IceCooler` ha una texture ImageGen definitiva assegnata al posto del
      segnaposto, leggibile come ghiacciaia alla scala di gioco reale.
- [x] `WoodCrateStack` ha una texture ImageGen definitiva assegnata al posto
      del segnaposto, leggibile come catasta di casse alla scala di gioco
      reale.
- [x] Entrambe le texture condividono palette, trattamento luce/ombra e
      densità di dettaglio con i cinque prop esistenti, senza introdurre uno
      stile visivo distinto.
- [x] `footprint_size`, `position` e collisione dei due nodi restano
      invariati; questa card sostituisce solo l'arte.
- [x] Nessun valore di gameplay, spawn o bilanciamento cambia.
- [x] Ogni nuovo file possiede master HD e derivato runtime separati, prodotti
      con la pipeline VFX/arena esistente (`tools/process-*.ps1` pertinente).
- [x] `assets/art/arena/ASSET-MANIFEST.md` registra percorso, prompt/origine,
      autore, licenza, trasformazioni e SHA-256 per entrambi gli asset; i
      master HD restano esclusi dai preset export.

## Ambito

- `assets/art/arena/hd/` e `assets/art/arena/generated/` (nuovi file per
  `ice_cooler` e `wood_crate_stack`, nomi definitivi a discrezione della
  pipeline di generazione).
- `scenes/game/movement_slice.tscn`, nodi `World/Obstacles/IceCooler` e
  `World/Obstacles/WoodCrateStack`, solo per assegnare `texture`.
- `assets/art/arena/ASSET-MANIFEST.md`.
- `tests/unit/test_b38_arena_world.gd`: rimuovere `IceCooler` e
  `WoodCrateStack` dalla lista `pending_art_obstacles` una volta assegnata la
  texture.

Non toccare:

- posizione, `footprint_size` o collisione di qualunque ostacolo
  dell'arena, inclusi i cinque prop esistenti sistemati da PS-045;
- composizione, raggruppamenti o altri nodi di `World/Obstacles`;
- `RunController`, `GameDirector`, curve di difficoltà e spawn;
- bilanciamento, danni, velocità.

## Verifica

- Smoke: estendi `tests/unit/test_ps045_arena_visual_hierarchy.gd` e
  `tests/unit/test_b38_arena_world.gd` per verificare che `IceCooler` e
  `WoodCrateStack` abbiano `texture != null`.
- Profilo minimo prima della chiusura: `Relevant`
- **Eseguito 2026-09-01:** `./tools/run-milestone-checks.ps1 -Milestone PS-058
  -Profile Relevant -FocusedSmoke
  tests/unit/test_ps045_arena_visual_hierarchy.gd -RefreshEditor` → `PASS`,
  bootstrap `1/1`, focused `1/1`, regressioni `17/17`, step `19/19`;
  `ARENA_VISUAL_HIERARCHY_SMOKE_OK`, JUnit con zero failure e nessun
  `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o `CONTRACT_FAIL` nei log.
- **Controllo export statico 2026-09-01:** tutti e tre i preset (`Windows
  Desktop`, `Android APK`, `Android AAB (future)`) contengono
  `assets/art/arena/hd/**` nell'`exclude_filter`. Non e' stata prodotta o
  ispezionata una nuova build APK: il relativo gate resta aperto.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK — master HD esclusi dai tre preset
- [ ] Runtime fisico Pixel 9: i due prop leggibili durante una run reale
- [ ] Controllo percettivo richiesto: sì — coerenza stilistica con gli altri
      cinque prop dell'arena

## Decisioni

- **2026-09-01 — Solo arte, nessun nuovo comportamento.** PS-045 ha già
  fissato footprint, posizione e ruolo compositivo dei due prop; questa card
  non li rinegozia.
- **2026-09-01 — Mini art direction dei nuovi prop.** Entrambi sono cutout
  RGBA centrati, con vista ortografica leggermente frontale, contorno
  bruno-nero netto, luce calda dall'alto a sinistra e cluster pixel grossi
  compatibili con camino, tavolo, panca, stendino e lavatoio. La ghiacciaia
  deve essere riconoscibile da coperchio bianco-azzurro, corpo azzurro
  desaturato e maniglie scure; la catasta da tre casse sfalsate, assi, chiodi
  e cavità scure. I dettagli restano subordinati alla silhouette e devono
  sopravvivere rispettivamente nei box runtime `90×70` e `130×110`, senza
  ombre proiettate fuori sagoma che suggeriscano una collisione diversa.
- **2026-09-01 — Correzione del master ghiacciaia.** Il primo candidato
  incorporava una scacchiera in un PNG RGB; e' stato scartato e corretto con
  un passaggio ImageGen di background extraction. Il master conservato e il
  derivato sono RGBA con alfa reale, senza alone o scacchiera residua.
- **Sostituisce:** il rendering segnaposto (`placeholder_color`) di
  `IceCooler` e `WoodCrateStack` introdotto da PS-045.

## Documenti sincronizzati

- [x] `assets/art/arena/ASSET-MANIFEST.md`.

## Note

Segue lo schema testo/segnaposto-poi-arte già usato da PS-048→PS-049 e
PS-051→PS-052.

Art review eseguita su entrambi i master e sui derivati reali `90×70` e
`130×110`: silhouette, contorno scuro, luce alto-sinistra, densita' dei
cluster e materiali restano compatibili con i cinque fratelli B38; la
ghiacciaia conserva coperchio e latch, la catasta conserva le tre casse e le
cavita' scure alla scala runtime.

Il pacchetto `tools/_capture_ui_screenshots.gd` ha concluso con
`CAPTURE_DONE` su Windows/OpenGL e ha prodotto le viste 16:9 e 20:9 a freddo e
sotto pressione. L'ispezione delle quattro catture mostra entrambi i prop
leggibili e senza crop o sovrapposizioni essenziali, ma non chiude il controllo
percettivo manuale né il runtime fisico Pixel 9. Durante la fase sotto
pressione il capture ha inoltre riprodotto gli errori di physics flush dello
splitter gia' tracciati dalla card PS-057: sono fuori ambito e impediscono di
considerare il capture un runtime Windows pulito, mentre il Relevant PS-058 e'
rimasto privo di marker d'errore.
