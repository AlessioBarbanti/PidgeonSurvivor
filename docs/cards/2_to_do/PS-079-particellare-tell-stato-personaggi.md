---
id: PS-079
titolo: Sostituisci il contorno bocciato con un particellare non aderente
tipo: ux
area: arte
stato: PRONTO
priorita: alta
dipende_da: []
origine: PS-001, PS-029
creato: 2026-09-02
aggiornato: 2026-09-02
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

- [ ] Nessuna particella disegna sopra o lungo il profilo dello sprite: resta
      sempre visivamente separata dalla sagoma (offset, orbita o sollevamento
      rispetto al corpo).
- [ ] La fase attiva di Aleo, Lollo, Alea e Migi è distinguibile a colpo
      d'occhio con il Player fermo e in movimento. *Percettivo.*
- [ ] Le due fasi opposte dello stesso personaggio restano distinguibili fra
      loro (colore, forma o comportamento delle particelle, non solo
      intensità). *Percettivo.*
- [ ] Il particellare resta leggibile sopra lo sfondo arena e durante orde
      dense, restando visibile anche quando il corpo del personaggio è
      parzialmente coperto dai nemici. *Percettivo.*
- [ ] Il flash da danno mantiene la precedenza sul tell di stato.
- [ ] Il tell resta puramente presentazionale: nessun cambiamento a
      collisioni, statistiche, timing o bilanciamento delle fasi.
- [ ] Il tell avanza solo in `RunController.RUNNING`, sparisce in pausa e nei
      modali, e si azzera al restart e al cambio personaggio, riprendendo la
      fase iniziale della passiva.
- [ ] Il numero di particelle rispetta `PerformanceProfile` (nessun impatto
      percettibile su Windows o mobile con più personaggi/VFX a schermo,
      dato che qui è un solo Player, non un'orda).
- [ ] `PassiveStateOutline` non viene più usato per nessuno dei quattro
      personaggi: sostituito, non affiancato.

## Ambito

- Nuovo VFX procedurale (`Node2D` figlio del `CharacterSprite`, sullo schema
  già rodato di `CosplayAccent`/`InstinctiveDodgeAccent`/
  `PassiveStateOutline` stesso) per il particellare non aderente.
- `scripts/actors/player.gd`: sostituisce i punti di aggancio
  `set_passive_state_outline`/`clear_passive_state_outline`/
  `get_passive_state_outline_color`/`has_passive_state_outline` con
  l'equivalente per il nuovo sistema (nomi da non ereditare se mentirebbero,
  stesso principio già seguito da PS-001 per `TINT_*` → `OUTLINE_*`).
- `scripts/content/friend_passive_controller.gd`: le costanti `OUTLINE_*`
  diventano parametri del particellare (colore, eventualmente densità/
  velocità per fase) mantenendo lo stesso significato di fase.
- `scripts/vfx/passive_state_outline.gd`: rimosso se non riusato da nessun
  altro sistema, altrimenti lasciato ma scollegato dal tell di stato.

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

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run con Aleo, Lollo, Alea e Migi fino
      al cambio di fase di ciascuno, anche durante un'ondata densa)
- [ ] Controllo percettivo richiesto: sì — data la bocciatura precedente, non
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

## Documenti sincronizzati

- [ ] `docs/characters.md`: descrizioni pubbliche del tell di Aleo/Lollo/
      Alea/Migi ("un contorno colorato... dichiara la fase") da riscrivere
      per descrivere il particellare.

## Note

Se il particellare puro non risultasse abbastanza leggibile a densità
massima in playtest, valutare un piccolo aumento di dimensione/luminosità
delle particelle prima di tornare a considerare le altre due direzioni
scartate: non è detto che la prima resa sia già quella definitiva.
