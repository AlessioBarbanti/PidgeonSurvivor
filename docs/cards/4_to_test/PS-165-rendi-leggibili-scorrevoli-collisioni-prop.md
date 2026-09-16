---
id: PS-165
titolo: Rendi leggibili e scorrevoli le collisioni con i prop
tipo: fix
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: [PS-159]
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-13
---

# PS-165 — Rendi leggibili e scorrevoli le collisioni con i prop

## Contesto

Il playtest segnala due aspetti dello stesso problema: alcune hitbox dei prop, in particolare il filo dei panni (`Clothesline`), non corrispondono chiaramente alla sagoma visiva; quando il Player urta il collider può inoltre inchiodarsi invece di scorrere lungo il bordo. Il Player usa già `CharacterBody2D.move_and_slide()` e `StaticObstacle` possiede già `collision_segments`; i due Clothesline sono già configurati con due segmenti verticali. La card deve quindi verificare e tarare la geometria esistente prima di introdurre un nuovo sistema di collisione.

## Comportamento atteso

Il volume occupato da un prop deve essere intuibile dalla sua grafica e un urto obliquo non deve arrestare completamente il Player. Il giocatore deve poter costeggiare un ostacolo senza dover allontanarsi e riallinearsi manualmente.

## Criteri di accettazione

- [x] Per ogni prop collidibile dell'arena, la collisione resta contenuta nella
      porzione visivamente solida dell'oggetto e non blocca il Player su
      trasparenze o sporgenze decorative. Auditati tutti i 7 prop reali
      (`obstacle_fireplace/wooden_table/bench/stone_washbasin/ice_cooler/
      wood_crate_stack/clothesline.png`, footprint intero senza segmenti
      tranne il filo dei panni): sei texture hanno la bounding box a filo del
      footprint con l'80±8% di pixel opachi (solo smussatura degli angoli,
      nessun difetto). Solo `obstacle_clothesline.png` era realmente
      sbagliata — vedi Decisioni.
- [x] Con input diagonale contro il lato di un ostacolo, il Player mantiene
      una componente di movimento tangenziale e scorre lungo il bordo. Il
      meccanismo esiste già (`CharacterBody2D.MOTION_MODE_FLOATING` +
      `move_and_slide()`, usato da `player.gd`); verificato con un test
      dedicato, nessuna modifica necessaria a `player.gd`.
- [x] Un corridoio visivamente attraversabile largo almeno quanto il diametro
      del collider Player resta realmente attraversabile. Verificato con un
      corridoio di 56px (diametro 48px + una tolleranza minima) — il gap più
      stretto fra prop reali dell'arena è 92px, quindi resta un margine di
      sicurezza. Nota su un caso degenere trovato: vedi Decisioni.
- [x] La correzione non permette di attraversare il nucleo solido dei prop né
      di uscire dai world bounds. Coperto da `test_obstacle_blocks_movement`
      (invariato) e dai due nuovi probe sul legno reale dei pali del filo dei
      panni; i world bounds non sono nell'ambito di questa card e restano
      coperti dai test esistenti di `ArenaWorld`.
- [ ] Almeno lo stendino citato nel playtest viene incluso esplicitamente nel
      percorso di verifica manuale. Descritto nel gate manuale Pixel 9/Windows
      sotto; resta da eseguire davvero su device/desktop (gate aperto).

## Ambito

- `scripts/actors/player.gd` per il comportamento di scorrimento solo se necessario.
- `scenes/game/movement_slice.tscn`: `footprint_size` e `collision_segments` delle istanze reali dei prop.
- `scripts/game/obstacles/static_obstacle.gd` solo se il modello a segmenti esistente non può rappresentare correttamente una silhouette necessaria.
- Non cambiare il raggio del Player solo per nascondere collider dei prop errati.

## Verifica

- GUT: `tests/unit/test_b38_arena_world.gd` → marker
  `PS165_PROP_COLLISION_SLIDE_SMOKE_OK`, con tre test nuovi:
  `test_ps165_clothesline_collision_matches_visual_poles` (probe verticali
  sulle due colonne del filo dei panni, con gli stessi `collision_segments`
  ora in produzione),
  `test_ps165_diagonal_movement_slides_along_obstacle_edge` (urto obliquo
  contro un muro dritto, verifica che la componente tangenziale sopravviva),
  `test_ps165_corridor_as_wide_as_player_diameter_is_crossable` (corridoio di
  poco superiore al diametro del Player, resta attraversabile).
- Focused: 11/11 verdi (era 10/11 prima del fix di determinismo descritto
  nelle Decisioni), nessun `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Relevant: 32/32 (1 focused + 31 regressione mappate su
  `scenes/game/movement_slice.tscn`), nessun `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Full: 142/142 regressione + 1/1 focused + toolchain PASS (144/144 step),
  eseguito due volte per lo stesso motivo di cautela di PS-171/PS-174 (file
  condiviso da tutta la suite). Il primo tentativo ha fallito su
  `test_ps171_enemy_overlap_separation.gd` (un residuo intermittente dello
  stesso flake di determinismo diagnosticato da PS-174, non toccato da questa
  card); il secondo tentativo è verde — vedi Decisioni.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: slalom e urti obliqui contro stendino e almeno due prop con silhouette diverse)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-09-11 — Hitbox poco leggibile e arresto sul bordo vengono tenuti nella stessa card perché vanno verificati sugli stessi prop e insieme determinano il feel della collisione.**
- **2026-09-11 — Non si riduce globalmente `collision_radius=24` senza evidenza che il problema sia il Player anziché la geometria ambientale.**
- **2026-09-11 — Sbloccata da PS-159 in `IN VERIFICA`.** La verifica dello scorrimento può usare la baseline candidata di `300 px/s`, mantenendo distinto un eventuale difetto geometrico dal gate percettivo ancora aperto sulla taratura finale.
- **2026-09-11 — Priorità alta nel filone del movimento.** Lo scorrimento sui prop deve essere stabile prima del playtest 0–5 di PS-157, perché collisioni poco leggibili alterano direttamente la pressione e la capacità di fuga percepite.
- **2026-09-13 — Causa radice del filo dei panni: prospettiva diagonale, non
  un margine sbagliato.** L'analisi pixel di `obstacle_clothesline.png`
  (60×100, footprint 150×250) mostra i due pali disegnati a due altezze
  diverse per dare l'illusione della corda che pende (palo sinistro solo
  nella metà inferiore, y unitaria 0.03–0.5; palo destro solo nella metà
  superiore, y unitaria -0.5– -0.05), non a piena altezza. I
  `collision_segments` esistenti (introdotti prima di questa card) erano già
  corretti in larghezza ma erano a piena altezza (`-0.5..0.5` per entrambi),
  bloccando il Player sul "cielo" vuoto sopra il palo sinistro e sotto il
  palo destro — esattamente il difetto segnalato dal playtest. Corretti in
  `Rect2(-0.43, 0.03, 0.19, 0.47)` (palo sinistro) e
  `Rect2(0.27, -0.5, 0.19, 0.45)` (palo destro) su entrambe le istanze
  (`Clothesline`, `ClotheslineB`), verificati per sovrapposizione visiva
  sullo sprite prima di applicarli.
- **2026-09-13 — Nessuna modifica a `player.gd`.** Lo scorrimento tangenziale
  su un urto obliquo contro un bordo dritto è già garantito da
  `CharacterBody2D.MOTION_MODE_FLOATING` + `move_and_slide()` (già in uso);
  verificato empiricamente con un test dedicato prima di escludere una
  modifica al Player, come richiesto dall'Ambito ("solo se necessario").
- **2026-09-13 — Corridoio di verifica a diametro+8px, non a zero clearance
  esatto.** Un gap esattamente pari al diametro del Player (48px, zero
  margine) produce un doppio contatto d'angolo simultaneo alla bocca del
  corridoio che può incastrare `move_and_slide()` — verificato empiricamente
  con un probe di debug (si ferma esattamente sullo spigolo). È un
  comportamento del motore fisico su una geometria degenere, non specifico a
  nessun prop di questo gioco: il gap più stretto fra prop reali dell'arena
  misura 92px (Clothesline–BenchD, calcolato su tutte le coppie), quindi non
  rientra nell'ambito di questa card introdurre una mitigazione per un caso
  che oggi non esiste in nessun punto del gioco.
- **2026-09-13 — Corretto un gap di determinismo pre-esistente in
  `test_camera_relative_spawn_reference`, necessario per usare questo file
  come target `-FocusedSmoke` della card.** A differenza di molti altri test
  che dipendono dallo schermo (es. `test_b18o_welcome_flow.gd`,
  `test_b18l_dynamic_joystick.gd`), questo test non forzava esplicitamente
  `get_tree().root.size`/`content_scale_size` prima di leggere il viewport:
  quando è fra i primi test eseguiti in un processo Godot appena avviato,
  `get_viewport().get_visible_rect()` può restare temporaneamente su una
  dimensione transitoria (osservato: `1280×1280` invece di `1280×720`)
  finché il resize richiesto da `--resolution` non si è assestato. Applicato
  lo stesso pattern difensivo già in uso altrove nella suite
  (`get_tree().root.content_scale_size/size = INITIAL_VIEWPORT_SIZE` seguito
  da `await wait_process_frames(2)`). Nessuna relazione con i prop; corretto
  perché bloccava la verifica automatica di questa card, non per allargarne
  l'ambito.
- **2026-09-13 — `test_ps171_enemy_overlap_separation.gd` ha fallito una
  volta su `-Profile Full`, poi è passato al secondo tentativo, senza alcuna
  modifica nel frattempo.** Nessun file toccato da questa card interseca la
  logica di separazione fra nemici (`base_enemy.gd`, `ranged_enemy.gd`); il
  fallimento (posizioni assestate diverse per ~1-2px su alcuni tiratori) è
  identico nella forma al flake di determinismo già diagnosticato e in gran
  parte corretto da PS-174 (somma in virgola mobile sensibile all'ordine,
  amplificata da centinaia di tick fisici caotici). Non essendo introdotto né
  aggravato da questa card, non viene investigato oltre qui: aperta
  [PS-175](./PS-175-residuo-non-determinismo-separazione-nemici-full.md)
  per diagnosticarlo separatamente.

## Documenti sincronizzati

- [ ] `docs/prd.md` solo se viene formalizzato un nuovo contratto generale
      sulle collisioni — non necessario qui: nessun nuovo contratto generale,
      solo dati (`collision_segments`) corretti su istanze esistenti e
      conferma che il meccanismo di scorrimento già documentato funziona.
- [ ] Nota `*-verification.md`, se vengono salvate catture/clip dei prop corretti.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. I valori o gli esempi citati nel feedback sono trattati come evidenza percettiva e non come specifica numerica, salvo dove la card lo dichiara esplicitamente.
