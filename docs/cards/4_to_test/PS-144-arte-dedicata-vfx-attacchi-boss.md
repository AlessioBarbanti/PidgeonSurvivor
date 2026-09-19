---
id: PS-144
titolo: Asset dedicati per tutti gli attacchi Boss
tipo: art
area: arte
stato: IN VERIFICA
priorita: bassa
dipende_da: []
origine:
creato: 2026-09-10
aggiornato: 2026-09-20
---

# PS-144 — Asset dedicati per tutti gli attacchi Boss

## Contesto

La presentazione procedurale degli attacchi Boss viene percepita dal
proprietario come grafica di debug. Dopo la richiesta iniziale di arricchire
solo i telegraph, il 2026-09-19 il proprietario ha confermato la necessità di
asset per tutti gli attacchi e autorizzato questa card in sprint.
[PS-141](./PS-141-arricchisci-telegraph-attacchi-boss.md) ne integra la resa.

## Comportamento atteso

Tutti gli attacchi Boss, inclusi gli Evil e le Signature, usano asset
leggibili e coerenti con la pixel-art del gioco: niente aspetto da debug.
La precedente valutazione condizionale dopo PS-141 è superata dalla
richiesta esplicita del proprietario del 2026-09-19.

## Criteri di accettazione

- [x] Copertura raster di volley radiale, blast mirato, mirino, scia di piume
      e famiglie Signature (onda, corridoio, rotazione, freddo/caldo, zona,
      fulmine, evocazione); riuso motivato degli asset già esistenti.
- [x] Asset trasparenti leggibili alla scala reale, coerenti con la famiglia
      VFX esistente, senza cerchi vettoriali uniformi come soggetto.
- [x] Master esclusi dall'export, derivati e manifest con provenienza/hash.
- [x] Review visiva dei master e derivati isolati a scala reale.
- [ ] Approvazione percettiva del proprietario.

I quattro derivati sono ora consumati a runtime da PS-141: le catture in
`exports/ui-screenshots/ps141-boss-telegraphs/` mostrano ogni asset alla scala
reale su tutti i pattern, ed è quello il materiale su cui si esprime
l'approvazione. Nessun asset è rimasto inutilizzato.

## Ambito

Produzione e verifica asset in questa card; PS-141 possiede l'integrazione.
Nessuna modifica a danno, durata, geometria delle collisioni o palette di
riconoscimento Boss/Evil. Si evitano al massimo draw_arc/draw_circle e
primitive analoghe per la presentazione degli attacchi.

## Decisioni

- **2026-09-19 — Direzione del proprietario:** «tutti gli attacchi hanno
  bisogno di asset», evitare al massimo draw_arc/draw_circle e simili;
  autorizzato lo spostamento in sprint e superata l'attesa di valutazione
  del solo arricchimento procedurale di PS-141.
- **2026-09-19 — Separazione produzione/integrazione:** PS-144 produce gli
  asset, PS-141 li integra. Rimossa la dipendenza inversa per evitare un
  ciclo: PS-141 dipende ora dalla consegna PS-144.
- **2026-09-19 — Geometria di consegna:** quattro PNG RGBA neutri in
  `assets/art/vfx/boss_attacks/generated/`: `boss_danger_ring.png`,
  `boss_blast.png`, `boss_corridor.png` a 512x512 e `boss_reticle.png` a
  128x128. Origine centrale; alpha di ring/blast/mirino confinata entro
  raggio `0.46 * lato`; quad per raggio gameplay R di lato `2R/0.92`.
  Corridor orientato +X, crop UV `Rect2(21,203,470,106)`.
  Bordo materico irregolare interno al limite: PS-141 ancora la fascia
  ai raggi autorevoli, senza far avanzare il confine di danno col countdown.
- **2026-09-19 — Riuso Signature:** terremoto `earthquake_wave`, corridoio
  `fire_trail`, rotazione `grand_spin`, freddo/caldo `thermal_frost` e
  `thermal_bloom`, zona `zen_field`, fulmine `lightning_impact`, evocazione
  `cosplay_reveal` e `reggaeton_decoy`, tutti sotto
  `assets/art/vfx/abilities/generated/`. Note dei cloni: regione ciano
  `Rect2(421,177,68,70)` di `reggaeton_decoy.png` a 14x14, preservando
  la silhouette. Piume: proiettile raster ostile esistente. Motivi Signature
  in tinta nativa, segnale perimetrale arancio/magenta per Boss/Evil.

## Note

Produzione asset completata il 2026-09-19 con ImageGen built-in. Quattro
master 1254x1254 originali, alpha reale; prompt integrali in
`assets/art/vfx/boss_attacks/hd/PROMPTS.md`. Derivazione riproducibile:
`tools/process-boss-attack-vfx.ps1` (crop, centratura, nearest, grayscale,
normalizzazione al raggio canonico). Corretto il padding eccessivo del
mirino sorgente; pulito alpha residuo sotto 32 senza rimuovere lo sfondo
con una chroma key. Nessun wiring runtime eseguito da questa card.

Manifest locale completo con origine, autore/licenza, geometria e SHA-256
di ciascuna coppia master/derivato:
`assets/art/vfx/boss_attacks/ASSET-MANIFEST.md`.
`hd/.gdignore` presente; esclusione esplicita verificata nei tre preset.
Audit `PS144_ALPHA_AUDIT_OK` su tutti i derivati: corner alpha 0, palette
neutra, nessun pixel oltre il raggio dichiarato per i tre motivi radiali.

Review isolata: master e quattro derivati aperti; prova di scala in
`assets/art/vfx/boss_attacks/hd/scale_review.png` con ring 160x160,
blast 100x100, mirino 18x18 e corridoio 180x40 su fondo scuro. La materia,
il centro libero del ring e la direzione del corridoio restano leggibili.
Questa prova non sostituisce le catture runtime Windows, il device Pixel 9
o l'approvazione del proprietario; integrazione e catture appartengono a
PS-141, approvazione percettiva ancora aperta.
