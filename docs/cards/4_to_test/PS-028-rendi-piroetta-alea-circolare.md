---
id: PS-028
titolo: Rendi circolare la rotazione della Gran Piroetta
tipo: art
area: arte
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-09-01
---

# PS-028 — Rendi circolare la rotazione della Gran Piroetta

## Contesto

Il VFX/forma visiva della Gran Piroetta di Alea appare ovale durante la rotazione.

L'effetto fa percepire il movimento come pesante sui due lati invece che come una rotazione continua e circolare attorno al personaggio.

## Comportamento atteso

La Gran Piroetta deve avere una silhouette visiva più tonda e una lettura chiaramente rotativa.

Durante l'animazione il volume apparente dell'effetto deve restare equilibrato in tutte le direzioni, senza schiacciamento orizzontale o verticale evidente.

La modifica è presentazionale: area gameplay, raggio dei colpi, durata, frequenza dei tick e danno restano invariati.

## Criteri di accettazione

- [ ] La forma della Gran Piroetta appare sostanzialmente circolare durante l'intera animazione.
      *Il raster statico è circolare; non confermato in animazione perché i gate non sono stati eseguiti su richiesta del proprietario.*
- [ ] Non è percepibile un allungamento ovale dominante sull'asse orizzontale.
      *Il raster statico non mostra un asse dominante; resta aperto il controllo percettivo in rotazione.*
- [ ] Non è percepibile un allungamento ovale dominante sull'asse verticale.
      *Il raster statico non mostra un asse dominante; resta aperto il controllo percettivo in rotazione.*
- [ ] Il movimento comunica una rotazione continua attorno ad Alea.
      *Richiede runtime.*
- [ ] Il peso visivo resta distribuito in modo uniforme durante il ciclo.
      *Il master distribuisce la corona sui quattro quadranti; il ciclo non è stato osservato in runtime.*
- [x] Il centro visuale della Piroetta resta allineato ad Alea.
      *Master e runtime hanno canvas quadrato, centro alpha aperto in `(627, 627)` e `(256, 256)` e il consumer centrato non è stato modificato.*
- [x] Il raggio gameplay dell'abilità resta invariato.
      *Nessun file di codice o dati gameplay modificato.*
- [x] Danno, durata e frequenza dei colpi restano invariati.
      *Nessun file di codice o dati gameplay modificato.*
- [x] La modifica non altera collisioni o posizione del Player.
      *Il cambiamento è limitato ai due PNG e alla documentazione.*
- [ ] Il VFX resta leggibile durante orde dense.
      *Gate percettivo non eseguito.*

## Ambito

- VFX e animazione della Gran Piroetta.
- Texture, sprite, trasformazioni o parametri visuali che producono l'attuale forma ovale.
- Eventuale pipeline di generazione/processing dell'asset se l'origine del difetto è nel raster.

Non modificare:

- `area_radius`;
- `damage_per_hit`;
- `hits_per_second`;
- `duration_seconds`;
- cooldown e rank;
- comportamento melee dell'abilità;
- sprite base di Alea fuori dalla Piroetta.

## Verifica

- Smoke corrente: `tests/unit/test_b18m_ability_visuals.gd` (GUT). Il percorso
  legacy indicato all'apertura, `tests/integration/_alea_gran_piroetta_visual_smoke.gd`,
  non esiste nel repository dopo il cutover GUT.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: Alea → attiva Gran Piroetta ferma e in movimento → osserva l'intero ciclo)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-08-30 — La Gran Piroetta deve leggere come rotazione circolare.** Eliminare l'aspetto ovale/pesante sui due lati senza cambiare il contratto gameplay dell'abilità.
- **Sostituisce:** forma visuale ovale corrente della Piroetta.
- **2026-09-01 — Rigenerazione ImageGen del raster invece di uno scaling correttivo.**
  La forma ovale era incorporata nel peso delle falci del master: il nuovo
  asset usa una corona radiale continua, centro aperto e nessuna stella grande,
  mantenendo palette, pixel-art, nome e percorso. Il master `1254×1254` viene
  ricampionato a `512×512` con la pipeline VFX esistente.
- **2026-09-01 — PS-029 è la card percettiva collegata.** Il controllo dei tell
  attivi di Alea va eseguito anche durante la Gran Piroetta aggiornata. Il
  collegamento non è una dipendenza e non cambia lo stato di PS-029.

## Documenti sincronizzati

- [x] `prd.md` o `CLAUDE.md`: non richiesto; il contratto gameplay resta invariato.
- [x] `characters.md` o `content-approvals.md`: non richiesto; identità e descrizione pubblica della Gran Piroetta restano invariate.
- [x] `assets/art/vfx/ASSET-MANIFEST.md`: aggiornati prompt specifico, trasformazione e SHA-256 di master e runtime.
- [ ] Nota `*-verification.md`, se sono state prodotte nuove evidenze.

## Note

### Card collegata

- [PS-029 — Rendi più visibili i tell di stato dei personaggi](./PS-029-rendi-tell-stato-personaggi-piu-visibili.md): durante il futuro controllo percettivo verificare che il tell attivo di Alea resti leggibile sotto la nuova corona della Gran Piroetta.

### Asset sostituiti

- `assets/art/vfx/abilities/hd/grand_spin_source.png`: master RGBA `1254×1254`.
- `assets/art/vfx/abilities/generated/grand_spin.png`: runtime RGBA `512×512`, prodotto con `tools/process-ability-vfx.ps1` senza crop o deformazioni.

### Verifica eseguita

- Controllo statico dei due PNG: dimensioni corrette, formato RGBA, quattro
  angoli e centro trasparenti; diff limitato agli asset e alla documentazione.
- SHA-256 master: `d6c32c1844bdd5273616f5728ea411ee5befa77be61449df41b530acec2923bf`.
- SHA-256 runtime: `cb9db79e4c11a50f8dee24730e63f6fc41824625b2badf0fc8d9948b5084d918`.

### Verifica non eseguita

Su richiesta esplicita del proprietario non sono stati eseguiti smoke, profilo
`Relevant`, runtime Windows, validazione APK, runtime Pixel 9 o controllo
percettivo. Tutti questi gate restano aperti e la card resta `IN VERIFICA`.
