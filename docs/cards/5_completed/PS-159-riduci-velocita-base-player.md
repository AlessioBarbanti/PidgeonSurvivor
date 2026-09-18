---
id: PS-159
titolo: Riduci la velocità base del Player
tipo: fix
area: gameplay
stato: COMPLETATO
priorita: alta
dipende_da: [PS-087]
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-19
---

# PS-159 — Riduci la velocità base del Player

## Contesto

Entrambi i playtester descrivono il movimento iniziale come eccessivamente rapido e sensibile: «l'omino decolla» e la camera scorre abbastanza velocemente da risultare affaticante. Il valore base precedente del Player era `360.0`; gli scarti per personaggio devono continuare a comporsi sopra la baseline definita dal sistema statistiche.

## Comportamento atteso

Il movimento base deve restare immediato ma più controllabile. A input pieno il Player deve poter correggere traiettoria vicino a nemici e prop senza grandi sovracorrezioni, e lo scorrimento della camera non deve risultare visivamente frenetico.

## Criteri di accettazione

- [x] La velocità base del Player è inferiore al precedente `360.0` ed è dichiarata in un solo punto autorevole.
- [x] Gli scarti di velocità dei personaggi continuano a essere applicati come moltiplicatori della nuova baseline senza essere appiattiti.
- [x] Magno conserva il proprio rapporto fra movimento e meccanica di Slancio: la card non rimuove il valore identitario della velocità per i personaggi che la usano nel kit.
- [ ] Su Windows e Pixel 9, un percorso a zig-zag attorno a tre ostacoli consecutivi non viene giudicato eccessivamente sensibile nel controllo percettivo.

## Ambito

- `scripts/actors/player.gd`: baseline `move_speed` / `_base_move_speed`.
- `data/friends/*.tres` e sistema scarti statistiche solo per verificare la composizione, non per normalizzare tutti i personaggi allo stesso valore.
- `scripts/game/movement_slice.gd` e camera solo per verificare che non esistano compensazioni dipendenti dal vecchio valore.
- Non modificare pickup radius, velocità dei proiettili o accelerazione dei nemici.

## Verifica

- Smoke: `tests/unit/test_ps159_player_base_speed.gd` → marker `PS159_PLAYER_BASE_SPEED_SMOKE_OK`
- Profilo minimo prima della chiusura: `Relevant`
- `Focused` PASS: `focused=1/1`, log `20260911-182234-PS-159`.
- `Relevant` PASS: `focused=1/1`, `regression=22/22`, log `20260911-182246-PS-159`; nessun `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o `CONTRACT_FAIL` nei log correnti.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: percorso libero + slalom fra prop con almeno Magno e un personaggio senza bonus velocità)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-09-11 — La prima taratura implementata è `300.0 px/s`.** Riduce del 16,7% la baseline precedente senza avvicinare il Player neutro alla velocità massima degli archetipi ordinari fino a cancellarne il margine di manovra. Gli scarti restano moltiplicativi: Migi parte a `270`, Bea a `330`, Magno a `285` e arriva a `384,75` con Slancio massimo. Il valore resta soggetto al gate percettivo Windows/Pixel 9.
- **2026-09-11 — `Player.DEFAULT_MOVE_SPEED` è l'unica dichiarazione numerica della baseline.** Sia l'export `move_speed` sia `_base_move_speed` derivano dalla costante, evitando divergenze fra valore Inspector e reset runtime.
- **2026-09-11 — La card passa a `IN VERIFICA` dopo Focused e Relevant verdi.** I gate manuali e percettivi restano aperti; PS-160 e PS-165 possono comunque partire perché il workflow considera soddisfatta una dipendenza arrivata in `IN VERIFICA`.
- 2026-09-19: chiusa dal proprietario con il passaggio in blocco di tutte le card `IN VERIFICA` a `COMPLETATO`.

## Documenti sincronizzati

- [x] `docs/characters.md` e `docs/prd.md` verificati: descrivono moltiplicatori/attributi, non riportano la vecchia baseline assoluta; nessuna modifica necessaria.
- [ ] Nota `*-verification.md`, se viene registrata la taratura percettiva.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. I valori o gli esempi citati nel feedback sono trattati come evidenza percettiva e non come specifica numerica, salvo dove la card lo dichiara esplicitamente.

Il primo tentativo Focused (`20260911-182212-PS-159`) non ha eseguito test per una costante di tolleranza mancante nella nuova fixture; il runner ha poi fallito interpretando il JUnit vuoto. La fixture è stata corretta e i profili correnti sopra riportati sono passati.
