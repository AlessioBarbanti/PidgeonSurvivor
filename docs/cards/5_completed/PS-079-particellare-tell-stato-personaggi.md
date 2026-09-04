---
id: PS-079
titolo: Sostituisci il contorno bocciato con un particellare non aderente
tipo: ux
area: arte
stato: COMPLETATO
priorita: alta
dipende_da: []
origine: PS-001, PS-029
creato: 2026-09-02
aggiornato: 2026-09-04
---

# PS-079 — Sostituisci il contorno bocciato con un particellare non aderente

## Contesto

[PS-001](../4_to_test/PS-001-tell-di-stato-senza-snaturare-lo-sprite.md) ha
sostituito la tinta piena di B44 con un contorno colorato a 8 direzioni
(`PassiveStateOutline`, `scripts/vfx/passive_state_outline.gd`) per comunicare
la fase attiva della passiva di Aleo (caldo/freddo), Lollo
(iperfocus/distratto), Alea (positivo/negativo) e Migi (guscio/scudo).
[PS-029](../4_to_test/PS-029-rendi-tell-stato-personaggi-piu-visibili.md) ha
poi rinforzato lo stesso meccanismo per la leggibilità in combattimento.

Il proprietario, giocando la run, ha bocciato il meccanismo stesso per tutti
e quattro i personaggi: il contorno rompe la leggibilità della silhouette
pixel-art e non si integra esteticamente con lo stile del gioco (dettagli e
diagnosi completa nelle Decisioni di PS-001 e PS-029).

Il problema originale resta valido: senza un segnale visibile, il Player non
sa in che fase si trova un personaggio senza leggere statistiche indirette
(B44). Fra le direzioni proposte come alternativa, il proprietario ha scelto
il particellare non aderente al contorno: piccole particelle che orbitano o
si sollevano dal personaggio senza ricalcarne il profilo, restando
puramente procedurali (nessun nuovo asset grafico da approvare).

## Comportamento atteso

La fase attiva della passiva resta riconoscibile a colpo d'occhio tramite un
piccolo sistema di particelle proprio del personaggio, distinto per le due
fasi opposte, che non tocca né altera il contorno dello sprite. Il segnale si
aggiunge accanto al personaggio, non sopra la sua sagoma.

## Criteri di accettazione

- [x] Nessuna particella disegna sopra o lungo il profilo dello sprite: resta
      sempre visivamente separata dalla sagoma (offset, orbita o sollevamento
      rispetto al corpo). Garantito per costruzione: l'orbita e' centrata
      48 unita' sopra l'origine del Player, con escursione verticale massima
      (raggio + jitter + bob + raggio del pallino disegnato) di ~11 unita' —
      resta quindi sempre a y ≤ -36.75, comodamente sopra il bordo superiore
      della hitbox del texture 32x32 alla scala fissa 1.65×1.25 (y=-33), che
      a sua volta e' piu' largo della sagoma pixel-art visibile. Conferma
      finale sulla sagoma reale nel gate percettivo sotto.
- [x] La fase attiva di Aleo, Lollo, Alea e Migi è distinguibile a colpo
      d'occhio con il Player fermo e in movimento. *Percettivo.*
- [x] Le due fasi opposte dello stesso personaggio restano distinguibili fra
      loro (colore, forma o comportamento delle particelle, non solo
      intensità). *Percettivo.*
- [x] Il particellare resta leggibile sopra lo sfondo arena e durante orde
      dense, restando visibile anche quando il corpo del personaggio è
      parzialmente coperto dai nemici. *Percettivo.*
- [x] Il flash da danno mantiene la precedenza sul tell di stato. Smoke:
      `test_ps079_damage_flash_takes_precedence_over_tell`.
- [x] Il tell resta puramente presentazionale: nessun cambiamento a
      collisioni, statistiche, timing o bilanciamento delle fasi. Per
      costruzione (il particellare legge solo un colore) e confermato dal
      resto della suite B44/PS-003/PS-004 rimasta verde senza modifiche di
      logica.
- [x] Il tell avanza solo in `RunController.RUNNING`, sparisce in pausa e nei
      modali, e si azzera al restart e al cambio personaggio, riprendendo la
      fase iniziale della passiva. Smoke:
      `test_ps079_particles_advance_only_while_running`,
      `test_ps079_tell_resets_on_restart_and_character_change`.
- [x] Il numero di particelle rispetta `PerformanceProfile` (nessun impatto
      percettibile su Windows o mobile con più personaggi/VFX a schermo,
      dato che qui è un solo Player, non un'orda). 5 particelle costanti,
      nessuna scala richiesta per un singolo Player (vedi Decisioni). Smoke:
      `test_ps079_particle_count_stays_bounded`.
- [x] `PassiveStateOutline` non viene più usato per nessuno dei quattro
      personaggi: sostituito, non affiancato. File rimosso
      (`scripts/vfx/passive_state_outline.gd`), non solo scollegato. Smoke:
      `test_ps079_outline_system_is_no_longer_hooked`.

## Ambito

- Nuovo VFX procedurale `PassiveStateParticles`
  (`scripts/vfx/passive_state_particles.gd`), `Node2D` **fratello** di
  `CharacterSprite` sotto `Player` (stesso schema di `ThunderChargeAura`, non
  di `PassiveStateOutline` che viveva figlio dello sprite per erederne
  trasformazione — qui serve il contrario: restare staccato dal profilo per
  costruzione).
- `scripts/actors/player.gd`: sostituisce i punti di aggancio
  `set_passive_state_outline`/`clear_passive_state_outline`/
  `get_passive_state_outline_color`/`has_passive_state_outline`/
  `is_passive_state_outline_presented` con l'equivalente
  `set_passive_state_tell`/`clear_passive_state_tell`/
  `get_passive_state_tell_color`/`has_passive_state_tell`/
  `is_passive_state_tell_presented` (nomi da non ereditare se mentirebbero,
  stesso principio già seguito da PS-001 per `TINT_*` → `OUTLINE_*`), più
  `advance_passive_state_particles`/`is_passive_state_tell_effectively_visible`/
  `get_passive_state_particles_orbit_angle` per l'animazione e
  l'osservabilità da test.
- `scripts/content/friend_passive_controller.gd`: le costanti `OUTLINE_*`
  diventano `TELL_*`, mantenendo esattamente gli stessi valori di colore
  (già calibrati per contrasto in PS-029) e lo stesso significato di fase.
- `scripts/vfx/passive_state_outline.gd`: rimosso (nessun altro sistema lo
  riusava).

Non toccare:

- bilanciamento, durata o logica delle fasi di Aleo, Lollo, Alea e Migi;
- l'autorità di `RunController` su stato, pausa e restart;
- gli sprite approvati del cast (`characters.md`);
- gli altri VFX/accent esistenti (`CosplayAccent`, `InstinctiveDodgeAccent`,
  ecc.), che restano un riferimento di schema ma non vengono toccati.

## Verifica

- Smoke: `tests/unit/test_ps079_state_tell_particles.gd` → marker
  `STATE_TELL_PARTICLES_SMOKE_OK` — verifica distinguibilità delle due fasi
  per ciascun personaggio, priorità del flash da danno, avanzamento solo in
  `RUNNING`, reset su restart e cambio personaggio, e che
  `PassiveStateOutline` non sia più agganciato al tell di stato.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [x] Runtime Windows
- [x] Validazione statica APK
- [x] Runtime fisico Pixel 9 (percorso: run con Aleo, Lollo, Alea e Migi fino
      al cambio di fase di ciascuno, anche durante un'ondata densa)
- [x] Controllo percettivo richiesto: sì — data la bocciatura precedente, non
      dichiarare `COMPLETATO` senza che il proprietario l'abbia vista in gioco

## Decisioni

- **2026-09-02 — Bocciatura del contorno registrata in PS-001/PS-029.**
  Fonte: il proprietario, giocando la run. Motivo: rottura della silhouette
  pixel-art ed estetica che non si integra. Ambito: tutti e quattro i
  personaggi con questo tell.
- **2026-09-02 — Direzione scelta: particellare non aderente.** Fra le tre
  proposte (icona fluttuante, particellare, animazione/andatura), il
  proprietario ha scelto il particellare: resta procedurale, non richiede
  nuovi asset grafici da approvare, e per costruzione non tocca mai il
  profilo dello sprite.
- **Alternative scartate — icona di stato fluttuante e segnale nell'andatura.**
  L'icona avrebbe richiesto nuove icone pixel-art dedicate (lavoro
  `game-art-designer`); il segnale nell'andatura avrebbe richiesto nuovi
  frame di animazione per fase × personaggio ed è il più a rischio sulla
  leggibilità "a colpo d'occhio anche a densità massima" già richiesta da
  PS-029.
- **Sostituisce:** l'implementazione corrente di PS-001/PS-029
  (`PassiveStateOutline`), non il loro obiettivo originale (B44).
- **2026-09-03 — Il particellare orbita sopra la testa, non attorno al
  corpo.** Un'orbita a raggio fisso centrata sul Player avrebbe dovuto
  restare piu' larga della mezza diagonale dello sprite (~46.7 unita' alla
  scala fissa del cast) per non sconfinare mai sul profilo in nessun punto
  dell'orbita, allontanando il tell dal personaggio. Un piccolo gruppo di
  particelle che orbita/si solleva in una zona compatta sopra la testa
  (offset verticale fisso -48) resta visivamente ancorato al personaggio pur
  restando garantito fuori dal suo riquadro, con lo stesso principio
  suggerito dal comportamento atteso ("orbitano o si sollevano").
- **2026-09-03 — Le due fasi restano distinte solo per colore, non anche per
  comportamento.** Il criterio di accettazione ammette esplicitamente
  "colore, forma o comportamento... non solo intensità"; le coppie `TELL_*`
  ereditate da PS-029 sono già state calibrate a una distanza cromatica
  minima esplicita (non piu' affidata alla sola sfumatura). Aggiungere anche
  una differenza di comportamento (verso di rotazione, direzione del
  sollevamento) per le due fasi non era richiesto dai criteri e avrebbe
  aggiunto una superficie di configurazione per personaggio senza un
  problema noto da risolvere: si riconsiderà solo se il gate percettivo lo
  segnala.
- **2026-09-03 — Precedenza del flash da danno via getter dedicato, non via
  pixel.** `PassiveStateOutline` derivava la precedenza leggendo
  `_sprite.visible` dentro `_draw()`. Il particellare fa lo stesso
  internamente, ma espone anche `is_effectively_visible()` (via
  `Player.is_passive_state_tell_effectively_visible()`) cosi' lo smoke puo'
  verificare la precedenza deterministicamente senza leggere pixel renderizzati.
- **2026-09-03 — Costanti di forma/velocità fisse, non parametri per
  personaggio.** L'ambito ipotizzava eventuali parametri di densità/velocità
  per fase in `friend_passive_controller.gd`; nessun criterio richiede che
  Aleo/Lollo/Alea/Migi abbiano forme di particellare diverse fra loro, quindi
  restano costanti condivise in `PassiveStateParticles` e il controller passa
  solo il colore, come faceva con `PassiveStateOutline`.

## Documenti sincronizzati

- [x] `docs/characters.md`: descrizioni pubbliche del tell di Aleo ("Un'aura
      ciano o arancio...") e Lollo ("Un contorno colorato...") riscritte per
      descrivere il particellare sospeso sopra la testa. Alea e Migi non
      avevano testo pubblico dedicato al tell da aggiornare.

## Note

Se il particellare puro non risultasse abbastanza leggibile a densità
massima in playtest, valutare un piccolo aumento di dimensione/luminosità
delle particelle prima di tornare a considerare le altre due direzioni
scartate: non è detto che la prima resa sia già quella definitiva.
