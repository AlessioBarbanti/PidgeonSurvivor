---
id: PS-058
titolo: Generare l'arte definitiva dei nuovi prop dell'arena
tipo: art
area: arte
stato: PRONTO
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
Restano segnaposto: nessuna `texture` assegnata, solo il rettangolo colorato
disegnato di default da `StaticObstacle`.

## Comportamento atteso

I due prop hanno una texture ImageGen definitiva coerente con lo stile
raster/pixel-art già stabilito dagli altri cinque prop dell'arena (camino,
tavolo, panca, stendino, lavatoio) in `assets/art/arena/generated/`, senza
alterare footprint, posizione, collisione o bilanciamento.

## Criteri di accettazione

- [ ] `IceCooler` ha una texture ImageGen definitiva assegnata al posto del
      segnaposto, leggibile come ghiacciaia alla scala di gioco reale.
- [ ] `WoodCrateStack` ha una texture ImageGen definitiva assegnata al posto
      del segnaposto, leggibile come catasta di casse alla scala di gioco
      reale.
- [ ] Entrambe le texture condividono palette, trattamento luce/ombra e
      densità di dettaglio con i cinque prop esistenti, senza introdurre uno
      stile visivo distinto.
- [ ] `footprint_size`, `position` e collisione dei due nodi restano
      invariati; questa card sostituisce solo l'arte.
- [ ] Nessun valore di gameplay, spawn o bilanciamento cambia.
- [ ] Ogni nuovo file possiede master HD e derivato runtime separati, prodotti
      con la pipeline VFX/arena esistente (`tools/process-*.ps1` pertinente).
- [ ] `assets/art/arena/ASSET-MANIFEST.md` registra percorso, prompt/origine,
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
- **Sostituisce:** il rendering segnaposto (`placeholder_color`) di
  `IceCooler` e `WoodCrateStack` introdotto da PS-045.

## Documenti sincronizzati

- [ ] `assets/art/arena/ASSET-MANIFEST.md`.

## Note

Segue lo schema testo/segnaposto-poi-arte già usato da PS-048→PS-049 e
PS-051→PS-052.
