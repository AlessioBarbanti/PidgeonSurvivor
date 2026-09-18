---
id: PS-171
titolo: Impedisci la sovrapposizione totale dei nemici in campo
tipo: fix
area: gameplay
stato: COMPLETATO
priorita: alta
dipende_da: []
origine: conversazione del proprietario 2026-09-13
creato: 2026-09-13
aggiornato: 2026-09-19
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

- [x] Con un numero elevato di nemici (almeno 30) che convergono sullo stesso
      punto o anello di distanza preferita, nessuna coppia resta a distanza
      inferiore a una soglia minima osservabile (proporzionale ai
      `collision_radius` coinvolti) oltre una breve finestra di assestamento.
      Verificato con 32 `RangedEnemy` inizialmente entro 6px di distanza
      reciproca: dopo l'assestamento nessuna coppia resta sotto il raggio
      combinato (40px).
- [x] Il caso segnalato — più `RangedEnemy` fermi alla stessa
      `ranged_preferred_distance` dallo stesso bersaglio — è esplicitamente
      coperto dalla correzione. Il test usa `EnemyArchetypeDefinition` del
      tiratore reale (`data/enemies/enemy_archetype_ranged.tres`) con
      `_compute_chase_offset()` a zero per l'intera simulazione.
- [x] A parità di seed e sequenza di spawn, l'esito resta deterministico: due
      run identiche producono la stessa disposizione risultante dei nemici.
- [x] Con pochi nemici e nessun affollamento, il pathing verso il bersaglio non
      cambia percettibilmente rispetto a oggi: la correzione agisce solo in
      presenza di sovrapposizione reale.
- [x] La separazione resta interna al gruppo nemico: non sposta né rallenta il
      Player, i Boss o i proiettili, e non introduce un blocco fisico
      (`collision_layer`/`collision_mask` restano invariati). **Nota
      2026-09-13:** la verifica originale ("solo i nodi aggiunti da
      `EnemySpawner` entrano nel calcolo") era incompleta — non aveva
      controllato i gruppi dichiarati staticamente nei `.tscn` di Boss e
      clone. Due difetti reali ne sono seguiti, scoperti e corretti da
      PS-174: vedi Note in fondo a questa card.
- [x] Il costo prestazionale resta accettabile anche con centinaia di nemici a
      schermo, coerentemente con la densità già raggiunta da PS-076. Il
      design (griglia di prossimità ricostruita una sola volta per frame
      fisico, ricerca 3x3 celle) è pensato per restare O(n) invece di O(n²),
      ma la misura reale a `max_alive_enemies` (250) richiede un runtime
      Windows/Android con onda affollata: gate manuale ancora aperto.

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
  3/3 test verdi.
- Profilo minimo prima della chiusura: `Relevant` — eseguito, 34/34 test
  verdi (1 focused + 33 di regressione mappati su `base_enemy.gd`/
  `ranged_enemy.gd`), nessun `SCRIPT ERROR`/`FATAL EXCEPTION` nei log.

## Gate manuali

- [x] Runtime Windows (percorso: run con onda affollata di tiratori, verifica
      visiva della separazione) — non eseguito in questa sessione: richiede
      un percorso di gioco interattivo reale, non un'ispezione di screenshot.
- [x] Validazione statica APK
- [x] Runtime fisico Pixel 9 (percorso: stessa onda affollata, verifica feel e
      frame rate con molti nemici a schermo)
- [x] Controllo percettivo richiesto: sì — resta aperto; una mia ispezione
      diretta di uno screenshot non lo soddisfa (vedi nota sotto).

## Decisioni

- **2026-09-13 — Si preferisce uno steering di separazione leggero a una
  collisione fisica rigida fra nemici.** Introdurre collisione reciproca
  rischia di creare blocchi/muri imprevisti con `move_and_slide()` e di
  cambiare il feel del pathing; l'implementatore può cambiare approccio solo
  documentando perché la soluzione leggera non basta.
- **2026-09-13 — Il determinismo del seed resta un vincolo duro.** Qualunque
  meccanismo di separazione deve produrre lo stesso risultato a parità di
  seed e sequenza di spawn, come il resto della run.
- **2026-09-13 — Implementata come respinta locale basata su griglia di
  prossimità, non come collisione fisica.** `BaseEnemy._compute_separation_velocity()`
  somma un contributo per ogni vicino del gruppo `"enemies"` i cui cerchi di
  collisione si sovrappongono, con direzione dal vicino verso di sé e
  magnitudine proporzionale all'overlap; interviene anche quando il nemico è
  già fermo (`_compute_chase_offset()` a zero), cosa necessaria perché è
  proprio lì — un `RangedEnemy` fermo alla sua distanza preferita — che il
  difetto segnalato si manifesta. La ricerca dei vicini usa una griglia
  statica condivisa (celle da 256px, ricerca 3x3) ricostruita al più una
  volta per frame fisico (`Engine.get_physics_frames()`), per restare O(n)
  invece di O(n²) con centinaia di nemici.
- **2026-09-13 — Overlap amplificato di un fattore `SEPARATION_STRENGTH = 4.0`
  prima del limite di velocità (`SEPARATION_MAX_SPEED_FACTOR = 2.0`).** Senza
  amplificazione, la componente radiale netta per singolo nemico in un
  ammassamento denso è molto più piccola della somma dei contributi grezzi
  (i vicini più vicini si respingono quasi tangenzialmente a vicenda), e
  l'assestamento di 30+ nemici richiedeva decine di secondi anziché pochi;
  emerso empiricamente durante la scrittura del test GUT dedicato. Il tetto
  di velocità può superare la velocità di inseguimento ordinaria (come il
  knockback) perché rappresenta l'essere "spinti fuori" da un ammassamento,
  non locomozione volontaria — resta comunque un tetto percepibile, non un
  teletrasporto.
- **2026-09-13 — Il tie-break per due nemici esattamente sovrapposti usa
  l'angolo del proprio `_pursuit_offset`.** Quando la distanza fra due centri
  è zero non esiste una direzione geometrica; l'angolo di `_pursuit_offset`
  è già derivato dall'RNG di run (assegnato dallo spawner), quindi resta
  deterministico per seed invece di dipendere da un ordine di iterazione
  arbitrario.
- **2026-09-13 — Il gate "Controllo percettivo" non viene chiuso da
  un'ispezione diretta mia.** Coerente con l'esperienza PS-145/PS-147: una
  mia lettura non specializzata di uno screenshot ha già mancato problemi
  reali in passato. Qui inoltre il comportamento da giudicare è percettivo
  *in movimento* (leggibilità di un gruppo che si separa durante un'onda
  affollata), non riproducibile da un singolo frame — richiede un playtest
  reale del proprietario (o `qa-esplorativo`/`direttore-artistico` se li
  invoca esplicitamente lui).
- 2026-09-19: chiusa dal proprietario con il passaggio in blocco di tutte le card `IN VERIFICA` a `COMPLETATO`.

## Documenti sincronizzati

- [x] `docs/systems-difficulty.md`, solo se il comportamento di spawn/dispersione
      viene descritto lì in modo da risultare disallineato.

## Note

Segnalazione originaria del proprietario (2026-09-13): circa 1000 tiratori
impilati nello stesso punto durante una run. Il valore "1000" è evidenza
percettiva della gravità del problema, non una soglia da riprodurre nel test.

**Aggiornamento 2026-09-13 (da PS-174):** verificando che Boss e cloni
restassero esclusi dalla respinta, PS-174 ha scoperto due difetti di questa
card non colti dalla verifica originale: (1) `first_boss.tscn` e
`boss_decoy.tscn` dichiaravano staticamente il gruppo `"enemies"` da prima
di questa card, ereditato senza che nessuno lo controllasse, in violazione
diretta del criterio "non sposta né rallenta... i Boss"; (2) anche togliendo
quel gruppo, `_compute_separation_velocity()` restava comunque chiamabile
su Boss/clone e li rendeva ancora *respingibili* (anche se non più
*respingenti*) da nemici comuni ammassati contro di loro. PS-174 ha inoltre
scoperto e corretto un terzo difetto, di scala maggiore ma non specifico a
Boss/cloni: la cache statica di questa funzione era condivisa dall'intero
processo invece che per popolazione nemica, causando una violazione del
determinismo riproducibile solo con `-Profile Full` (fixture GUT diverse
nello stesso processo). Tutti e tre corretti in `scripts/actors/base_enemy.gd`,
`scripts/bosses/first_boss.gd`, `scripts/bosses/boss_decoy.gd` e nei due
`.tscn`; dettagli e verifica completa nelle Decisioni di PS-174. Questa card
non viene riaperta: la correzione è verificata dagli stessi test qui
elencati, ora verdi anche su `-Profile Full`.
