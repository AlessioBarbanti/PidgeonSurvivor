---
id: PS-205
titolo: Fai sentire lo slancio di Magno, con partenza lenta e perdita in curva
tipo: fix
area: gameplay
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-09-22
aggiornato: 2026-09-22
---

# PS-205 — Fai sentire lo slancio di Magno, con partenza lenta e perdita in curva

## Contesto

La passiva di Magno (Flusso Aerodinamico Bovino) promette che andando dritto
accumula slancio, ma in partita la sua corsa sembra costante:

- **Le curve non costano nulla.** `Player._advance_momentum()` confronta la
  direzione con quella del **frame precedente** (soglia coseno 0,85). Una
  curva fatta col joystick cambia poco da un frame all'altro, quindi resta
  sempre "allineata": girare in tondo o fare un'inversione a U graduale non
  interrompe mai lo slancio.
- **L'escursione è piccola.** Oggi Magno parte al 95% della velocità base
  condivisa (scarto 0,95 × passiva 1,0) e arriva al 128% (0,95 × 1,35) in
  1,4 s. La differenza si nota appena.

## Comportamento atteso

Magno è un treno: parte **lento**, accelera andando dritto e a pieno slancio
va più veloce di oggi. Quando gira perde slancio **in proporzione alla
curva**: a 90° circa metà, con un'inversione a U riparte da zero. Le piccole
correzioni col joystick non costano nulla.

Curva di velocità effettiva (base condivisa × scarto 0,95 × passiva):
**60% da fermo → 140% a slancio pieno, in 2,5 s** di corsa dritta. La
direzione continua a cambiare all'istante: cambia solo la velocità, non si
introduce un raggio di sterzata.

## Criteri di accettazione

- [ ] Da fermo, Magno si muove al 60% (±2%) della velocità base condivisa.
- [ ] Dopo 2,5 s di corsa dritta lo slancio è pieno e Magno si muove al 140%
      (±2%) della velocità base condivisa; a metà (1,25 s) è a metà strada.
- [ ] Da slancio pieno, una svolta di 90° (secca o graduale in 0,5 s) lascia
      lo slancio fra 0,4 e 0,6.
- [ ] Da slancio pieno, un'inversione a U (secca o graduale in 0,5 s) porta
      lo slancio a 0.
- [ ] Correzioni continue entro ±15° dalla direzione iniziale per 2,5 s non
      impediscono di arrivare a slancio pieno.
- [ ] Girare in tondo col joystick per 3 s, un giro completo al secondo, non
      porta mai lo slancio sopra 0,5.
- [ ] Fermarsi azzera ancora lo slancio come oggi, e restart e cambio
      personaggio lo riportano a 0 (PS-041).
- [ ] Velocità minima, velocità massima, tempo di rincorsa e perdita in curva
      stanno in `data/friends/magno.tres` (`passive_parameters`), non in
      costanti di codice.
- [ ] Gli altri sette personaggi si muovono esattamente come oggi.
- [ ] L'Onda d'Urto Tellurica continua a scalare con lo slancio con la stessa
      formula (`momentum_*_bonus_max` invariati).

## Ambito

- `scripts/actors/player.gd`: `_advance_momentum()` misura la curva rispetto
  a una direzione di riferimento che non si riallinea a ogni frame. Tempo di
  rincorsa e perdita in curva arrivano dalla passiva invece che da
  `MOMENTUM_RAMP_SECONDS`.
- `scripts/content/friend_passive_controller.gd`: ramo
  `MAGNO_AERODYNAMIC_FLOW`, lettura dei nuovi parametri.
- `data/friends/magno.tres`: nuovi valori della passiva.
- Test da aggiornare: `test_b45_role_identity.gd` (`test_magno_momentum`),
  `test_ps159_player_base_speed.gd` (slancio di Magno sopra la base).
- Non toccare: `RunController`, `AbilityEffectRegistry` (formula dell'Onda
  d'Urto), `WeaponController` e il Coperchio di PS-202, gli scarti base del
  personaggio (`base_move_speed_multiplier` resta 0,95), gli altri
  personaggi.

## Verifica

- Test: `tests/unit/test_ps205_magno_momentum_feel.gd`.
- Regressioni: B45, PS-024, PS-041, PS-159; aggiornare
  `tools/milestone-test-map.json`.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows (Magno: partenza, rettilineo lungo, svolta a 90°,
      inversione a U, giro in tondo)
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: stessi movimenti col joystick touch,
      dove le curve graduali sono il caso normale)
- [ ] Controllo percettivo richiesto: sì, sensazione di guida confermata dal
      proprietario in partita

## Decisioni

- **2026-09-22 — Perdita proporzionale alla curva.** Scelta del
  proprietario fra azzeramento secco, perdita proporzionale e calo graduale:
  a 90° circa metà, a 180° tutto, le piccole correzioni sono gratis.
- **2026-09-22 — Curva 60% → 140% in 2,5 s.** Scelta del proprietario come
  punto di partenza; i valori restano nei dati per il playtest.
- **2026-09-22 — Niente inerzia di sterzata.** La richiesta riguarda quanto
  va veloce Magno, non quanto gira: la direzione resta immediata.

## Documenti sincronizzati

- [ ] `docs/characters.md` — sezione Magno: curva di velocità e perdita in
      curva della passiva.
- [ ] `tools/milestone-test-map.json` — regressioni del nuovo test.

## Note

- Rischio da osservare, non un criterio: con la rincorsa più lunga e la
  perdita in curva, l'Onda d'Urto a pieno slancio diventa più difficile da
  ottenere, e con il Coperchio (PS-202, portata ~150 px) Magno entra in
  mischia più lentamente.
- Il 60% e il 140% sono relativi alla velocità base condivisa: con lo scarto
  0,95 i moltiplicatori della passiva sono circa 0,63 e 1,47.
