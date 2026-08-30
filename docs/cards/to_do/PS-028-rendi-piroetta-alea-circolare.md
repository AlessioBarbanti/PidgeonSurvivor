---
id: PS-028
titolo: Rendi circolare la rotazione della Gran Piroetta
tipo: art
area: arte
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-30
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
- [ ] Non è percepibile un allungamento ovale dominante sull'asse orizzontale.
- [ ] Non è percepibile un allungamento ovale dominante sull'asse verticale.
- [ ] Il movimento comunica una rotazione continua attorno ad Alea.
- [ ] Il peso visivo resta distribuito in modo uniforme durante il ciclo.
- [ ] Il centro visuale della Piroetta resta allineato ad Alea.
- [ ] Il raggio gameplay dell'abilità resta invariato.
- [ ] Danno, durata e frequenza dei colpi restano invariati.
- [ ] La modifica non altera collisioni o posizione del Player.
- [ ] Il VFX resta leggibile durante orde dense.

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

- Smoke: `tests/integration/_alea_gran_piroetta_visual_smoke.gd` → marker `ALEA_GRAN_PIROETTA_VISUAL_SMOKE_OK`
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: Alea → attiva Gran Piroetta ferma e in movimento → osserva l'intero ciclo)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-08-30 — La Gran Piroetta deve leggere come rotazione circolare.** Eliminare l'aspetto ovale/pesante sui due lati senza cambiare il contratto gameplay dell'abilità.
- **Sostituisce:** forma visuale ovale corrente della Piroetta.

## Documenti sincronizzati

- [ ] `prd.md` o `CLAUDE.md`: non richiesto se il contratto gameplay resta invariato.
- [ ] `characters.md` o `content-approvals.md`, solo se viene sostituito un asset approvato e serve aggiornare il registro.
- [ ] Nota `*-verification.md`, se sono state prodotte nuove evidenze.

## Note

Correggere prima trasformazioni, aspect ratio e scaling dell'effetto corrente. Rigenerare l'asset solo se la forma ovale è incorporata nella sorgente e non può essere corretta senza degradarne la qualità.
