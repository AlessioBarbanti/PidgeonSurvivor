---
id: PS-165
titolo: Rendi leggibili e scorrevoli le collisioni con i prop
tipo: fix
area: gameplay
stato: PRONTO
priorita: alta
dipende_da: [PS-159]
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-11
---

# PS-165 — Rendi leggibili e scorrevoli le collisioni con i prop

## Contesto

Il playtest segnala due aspetti dello stesso problema: alcune hitbox dei prop, in particolare il filo dei panni (`Clothesline`), non corrispondono chiaramente alla sagoma visiva; quando il Player urta il collider può inoltre inchiodarsi invece di scorrere lungo il bordo. Il Player usa già `CharacterBody2D.move_and_slide()` e `StaticObstacle` possiede già `collision_segments`; i due Clothesline sono già configurati con due segmenti verticali. La card deve quindi verificare e tarare la geometria esistente prima di introdurre un nuovo sistema di collisione.

## Comportamento atteso

Il volume occupato da un prop deve essere intuibile dalla sua grafica e un urto obliquo non deve arrestare completamente il Player. Il giocatore deve poter costeggiare un ostacolo senza dover allontanarsi e riallinearsi manualmente.

## Criteri di accettazione

- [ ] Per ogni prop collidibile dell'arena, la collisione resta contenuta nella porzione visivamente solida dell'oggetto e non blocca il Player su trasparenze o sporgenze decorative.
- [ ] Con input diagonale contro il lato di un ostacolo, il Player mantiene una componente di movimento tangenziale e scorre lungo il bordo.
- [ ] Un corridoio visivamente attraversabile largo almeno quanto il diametro del collider Player resta realmente attraversabile.
- [ ] La correzione non permette di attraversare il nucleo solido dei prop né di uscire dai world bounds.
- [ ] Almeno lo stendino citato nel playtest viene incluso esplicitamente nel percorso di verifica manuale.

## Ambito

- `scripts/actors/player.gd` per il comportamento di scorrimento solo se necessario.
- `scenes/game/movement_slice.tscn`: `footprint_size` e `collision_segments` delle istanze reali dei prop.
- `scripts/game/obstacles/static_obstacle.gd` solo se il modello a segmenti esistente non può rappresentare correttamente una silhouette necessaria.
- Non cambiare il raggio del Player solo per nascondere collider dei prop errati.

## Verifica

- GUT esistente da estendere: `tests/unit/test_b38_arena_world.gd` → marker `PS165_PROP_COLLISION_SLIDE_SMOKE_OK`; aggiungere un test dedicato solo se lo scorrimento del `CharacterBody2D` non è esprimibile nella fixture B38.
- Profilo minimo prima della chiusura: `Relevant`

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

## Documenti sincronizzati

- [ ] `docs/prd.md` solo se viene formalizzato un nuovo contratto generale sulle collisioni.
- [ ] Nota `*-verification.md`, se vengono salvate catture/clip dei prop corretti.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. I valori o gli esempi citati nel feedback sono trattati come evidenza percettiva e non come specifica numerica, salvo dove la card lo dichiara esplicitamente.
