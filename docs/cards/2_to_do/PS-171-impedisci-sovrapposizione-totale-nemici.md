---
id: PS-171
titolo: Impedisci la sovrapposizione totale dei nemici in campo
tipo: fix
area: gameplay
stato: PRONTO
priorita: alta
dipende_da: []
origine: conversazione del proprietario 2026-09-13
creato: 2026-09-13
aggiornato: 2026-09-13
---

# PS-171 — Impedisci la sovrapposizione totale dei nemici in campo

## Contesto

Il proprietario si è trovato circa 1000 tiratori impilati esattamente nello
stesso punto durante una run. `BaseEnemy` assegna già a ogni nemico un
`_pursuit_offset` allo spawn per disperdere il punto inseguito attorno al
bersaglio (`set_pursuit_offset`, B37), ma il commento del metodo dichiara
esplicitamente l'assunzione corrente: i nemici restano "privi di collisione
reciproca". Le scene (`base_enemy.tscn`, `configurable_enemy.tscn`,
`ranged_enemy.tscn`, `splitter_enemy.tscn`) confermano che il corpo fisico ha
`collision_layer = 0` e non collide mai con gli altri nemici. `RangedEnemy` si
ferma inoltre a `ranged_preferred_distance` dal bersaglio: più tiratori con lo
stesso `_pursuit_offset` insufficiente a separarli convergono quindi sullo
stesso anello e possono collassare visivamente in un unico punto.

## Comportamento atteso

Un gruppo numeroso di nemici, in particolare tiratori fermi alla stessa
distanza preferita dal bersaglio, deve restare visivamente distinguibile:
nessuna coppia di nemici deve poter occupare stabilmente lo stesso punto. I
nemici si respingono quel tanto che basta a restare leggibili, senza
introdurre una collisione fisica rigida che li blocchi contro ostacoli o crei
un muro impenetrabile per il Player.

## Criteri di accettazione

- [ ] Con un numero elevato di nemici (almeno 30) che convergono sullo stesso
      punto o anello di distanza preferita, nessuna coppia resta a distanza
      inferiore a una soglia minima osservabile (proporzionale ai
      `collision_radius` coinvolti) oltre una breve finestra di assestamento.
- [ ] Il caso segnalato — più `RangedEnemy` fermi alla stessa
      `ranged_preferred_distance` dallo stesso bersaglio — è esplicitamente
      coperto dalla correzione.
- [ ] A parità di seed e sequenza di spawn, l'esito resta deterministico: due
      run identiche producono la stessa disposizione risultante dei nemici.
- [ ] Con pochi nemici e nessun affollamento, il pathing verso il bersaglio non
      cambia percettibilmente rispetto a oggi: la correzione agisce solo in
      presenza di sovrapposizione reale.
- [ ] La separazione resta interna al gruppo nemico: non sposta né rallenta il
      Player, i Boss o i proiettili, e non introduce un blocco fisico che
      impedisca al Player di attraversare un varco altrimenti libero.
- [ ] Il costo prestazionale resta accettabile anche con centinaia di nemici a
      schermo, coerentemente con la densità già raggiunta da PS-076.

## Ambito

- `scripts/actors/base_enemy.gd`: eventuale steering di separazione o
  ampliamento della dispersione esistente (`_pursuit_offset`,
  `_compute_chase_offset`, `_physics_process`).
- `scripts/actors/ranged_enemy.gd`: verifica che il caso dei tiratori fermi
  alla distanza preferita sia coperto dalla stessa soluzione.
- `scripts/game/enemy_spawner.gd`: solo se la soluzione richiede tarare
  `_sample_pursuit_offset()` o i raggi min/max del profilo di spawn.
- Non introdurre `collision_layer`/`collision_mask` che facciano collidere
  fisicamente i nemici fra loro con `move_and_slide()`, salvo che la card
  documenti esplicitamente perché l'alternativa più leggera (steering di
  separazione) non basta.
- Non toccare densità di spawn, pesi degli archetipi o la curva di
  difficoltà: qui si corregge la leggibilità/posizionamento, non il bilancio
  di PS-076/PS-123/PS-124.

## Verifica

- GUT: `tests/unit/test_ps171_enemy_overlap_separation.gd` → marker
  `PS171_ENEMY_OVERLAP_SEPARATION_SMOKE_OK`, con un caso a nemici numerosi
  convergenti sullo stesso punto/anello e un caso a determinismo di seed.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows (percorso: run con onda affollata di tiratori, verifica
      visiva della separazione)
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: stessa onda affollata, verifica feel e
      frame rate con molti nemici a schermo)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-09-13 — Si preferisce uno steering di separazione leggero a una
  collisione fisica rigida fra nemici.** Introdurre collisione reciproca
  rischia di creare blocchi/muri imprevisti con `move_and_slide()` e di
  cambiare il feel del pathing; l'implementatore può cambiare approccio solo
  documentando perché la soluzione leggera non basta.
- **2026-09-13 — Il determinismo del seed resta un vincolo duro.** Qualunque
  meccanismo di separazione deve produrre lo stesso risultato a parità di
  seed e sequenza di spawn, come il resto della run.

## Documenti sincronizzati

- [ ] `docs/systems-difficulty.md`, solo se il comportamento di spawn/dispersione
      viene descritto lì in modo da risultare disallineato.

## Note

Segnalazione originaria del proprietario (2026-09-13): circa 1000 tiratori
impilati nello stesso punto durante una run. Il valore "1000" è evidenza
percettiva della gravità del problema, non una soglia da riprodurre nel test.
