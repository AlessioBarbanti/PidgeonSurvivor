---
name: asset-pipeline
description: Integra nel repository un asset grafico o audio di Pidgeon Survivor — master fornito dal proprietario, icona, ritratto, sprite del cast, VFX, ostacolo, musica o cue. Copre derivazione con gli script tools/process-*.ps1, esclusione dei master HD dagli export e la riga obbligatoria nel ASSET-MANIFEST.md. Usala quando arrivano nuovi PNG/audio, quando un'icona va rigenerata o quando un manifest è da aggiornare.
---

# Pipeline degli asset

Regola d'oro: **il runtime referenzia solo i derivati**, i master restano nel
repository come sorgente ma fuori da import, EXE, APK e AAB.

Questa skill copre l'intera pipeline, ma non tutte le sue fasi appartengono
alla stessa card (PS-090). I passi **1–3** (deriva, tieni i master fuori
dagli export, aggiorna il manifest) sono lavoro di produzione: li esegue
sempre chi genera l'asset, tipicamente una card `tipo: art` delegata a
`game-art-designer`. Il passo **4** (verifica: wiring, refresh import, smoke,
`Relevant`, gate percettivo) presuppone l'asset già collegato al componente
che lo consuma: appartiene alla card di integrazione che referenzia il nuovo
derivato in un `.tres`/scena/registry, non alla card che ha solo generato
l'asset.

## 1. Deriva

Un master consegnato non entra mai direttamente in gioco. Usa lo script
dedicato in [tools/](../../../tools/):

| Tipo | Script | Output tipico |
|---|---|---|
| Icona potenziamento | `process-upgrade-icon.ps1` | `128×128` RGBA |
| Icona passiva | `process-passive-icon.ps1` | icona del cast |
| Ritratto carosello | `process-carousel-portrait.ps1` | selezione personaggi |
| Sprite del cast | `process-cast-sprite.ps1` | sprite giocatore |
| VFX abilità | `process-ability-vfx.ps1` | decal/effetto |
| Ostacolo arena | `process-arena-obstacle.ps1` | prop del mondo |
| CTA selezione | `process-character-select-cta.ps1` | placca UI |

```powershell
.\tools\process-upgrade-icon.ps1 `
  -InputPath assets\art\icons\upgrades\hd\upgrade_nuova.png `
  -OutputPath assets\art\icons\upgrades\generated\nuova.png
```

Gli script ritagliano sui bounds alpha, applicano padding quadrato e riducono
con nearest-neighbor. Non introdurre una derivazione a mano quando esiste già lo
script: la riproducibilità è parte dell'evidenza.

## 2. Tieni i master fuori dagli export

- I master vivono in `hd/` accanto ai derivati, con un `.gdignore` nella
  cartella.
- Verifica che i tre preset in `export_presets.cfg` (Windows, APK, AAB) li
  escludano ancora.
- I derivati in `generated/` sono gli unici percorsi citati da `.tres`, scene e
  smoke.

## 3. Aggiorna il manifest

Ogni cartella di asset ha un `ASSET-MANIFEST.md`. Aggiungi una sezione per la
slice con: data di integrazione, **origine** (chi l'ha fornito o la fonte CC0
con autore e licenza), trasformazione applicata (script e parametri), nota sul
runtime, e una tabella con master, derivato, dimensioni e **SHA-256 di
entrambi**.

```powershell
(Get-FileHash -Algorithm SHA256 'assets\art\icons\upgrades\generated\nuova.png').Hash
```

Non inventare prompt, generatore, autore o licenza che non ti sono stati
consegnati. Se il proprietario fornisce un master senza provenienza di terzi,
scrivi esattamente questo: asset del progetto fornito dal proprietario.

Per contenuti che ritraggono persone reali del cast, l'approvazione va
registrata nella card pertinente.

## 4. Verifica (card di integrazione, non la card `art`)

1. Rinfresca la cache di import dell'editor prima degli smoke: un asset nuovo
   non importato fa fallire i test per risoluzione risorsa, non per contratto.
2. Uno smoke che controlla percorsi d'arte deve verificare i **derivati runtime**,
   mai i master `hd/` o il manifest.
3. `-Profile Relevant` copre le regressioni d'arte tramite
   [tools/milestone-test-map.json](../../../tools/milestone-test-map.json):
   aggiungi lì il percorso della nuova cartella se non c'è.
4. La resa finale di un asset è un gate percettivo Windows/Pixel 9: non chiuderlo
   con uno screenshot headless.
