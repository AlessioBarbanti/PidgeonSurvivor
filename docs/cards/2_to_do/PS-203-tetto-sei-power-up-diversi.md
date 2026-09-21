---
id: PS-203
titolo: Limita a sei i power up diversi di una run
tipo: feat
area: gameplay
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-09-22
aggiornato: 2026-09-22
---

# PS-203 — Limita a sei i power up diversi di una run

## Contesto

Oggi il level-up può offrire in qualunque momento tutte le 10 carte
statistiche ordinarie più la carta dell'abilità attiva: una run lunga finisce
per raccoglierne quasi tutte, a ranghi bassi, e la build non ha una forma
riconoscibile. Il proprietario chiede un tetto ai power up **diversi** che si
possono prendere, per ora **6**.

## Comportamento atteso

Finché il giocatore possiede meno di 6 power up diversi, le offerte restano
quelle di oggi. Appena ne possiede 6, il level-up (e il bonus di Barb) propone
solo i ranghi successivi di quei 6, più le Specialità di Barb già sbloccate:
nessuna nuova carta ordinaria o abilità entra più nella build.

Contano verso il tetto le carte statistiche ordinarie e la carta che
potenzia l'abilità attiva. Le Specialità di Barb restano fuori: sono un
registro a parte e non occupano posti.

## Criteri di accettazione

- [ ] Con meno di 6 power up diversi posseduti, offerte e sequenza RNG sono
      identiche a oggi a parità di seed.
- [ ] Con 6 power up diversi posseduti, nessuna offerta di level-up contiene
      una carta ordinaria o la carta dell'abilità non già posseduta.
- [ ] Con 6 power up diversi posseduti, le Specialità di Barb sbloccate
      continuano a comparire nelle offerte come oggi.
- [ ] Sbloccare una Specialità di Barb non riduce i posti disponibili: con 5
      power up ordinari e 3 Specialità, il level-up offre ancora carte nuove.
- [ ] Il bonus di Barb (modalità con tutte le Specialità sbloccate) rispetta
      lo stesso tetto, passando dallo stesso percorso di filtro di PS-190.
- [ ] Con 6 power up diversi tutti saturi (PS-120), l'offerta non è mai vuota
      e non ripropone carte fuori dai 6.
- [ ] Il tetto è un unico valore in `UpgradeService`, con default 6: cambiarlo
      cambia il comportamento senza toccare altro codice o dati.
- [ ] Restart e cambio personaggio riportano la build a zero posti occupati.

## Ambito

- `scripts/progression/upgrade_service.gd`: un filtro in
  `_get_offer_candidates()`, **prima** di `_filter_saturated_repeatable_candidates`
  (l'ordine dei filtri è contratto: il fallback di saturazione valuta solo i
  candidati rimasti). Il conteggio legge `_ranks`, già posseduto dal servizio,
  escludendo le voci `is_speciality`.
- Nessun nuovo stato in `RunController`, nessun dato `.tres` modificato,
  nessun cambio a `UpgradeEffectRegistry` o ai valori delle carte.
- Non toccare il flusso `welcome → tutorial → selezione → run → pausa`, né
  l'arbitraggio dei modali: il level-up resta lo stesso modale con 3 carte
  (o meno, come già ammesso da PS-120).

## Verifica

- Test: `tests/unit/test_ps203_distinct_upgrade_cap.gd`.
- Regressioni: PS-012, PS-077, PS-120, PS-161, PS-190 (filtri e fallback
  delle offerte); aggiornare `tools/milestone-test-map.json`.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows (run fino a 6 power up diversi, controllo che il
      level-up successivo offra solo ranghi di quei 6)
- [ ] Validazione statica APK
- Runtime fisico Pixel 9: non pertinente, logica indipendente dalla
  piattaforma.
- Controllo percettivo: non richiesto, nessun cambio visivo.

## Decisioni

- **2026-09-22 — Tetto a 6 power up diversi.** Richiesta del proprietario,
  valore provvisorio ("per ora 6"): per questo resta un solo parametro.
- **2026-09-22 — Cosa conta.** Confermato dal proprietario: carte statistiche
  ordinarie + carta dell'abilità attiva. Le Specialità di Barb sono escluse
  dal conteggio e non vengono filtrate dal tetto.
- **Aperta:** nessuna.

## Documenti sincronizzati

- [ ] `docs/powerup-catalog.md` — il tetto di power up diversi accanto alla
      regola "ripetibile all'infinito".
- [ ] `docs/systems-difficulty.md` — il tetto nel loop di progressione della
      run.
- [ ] `tools/milestone-test-map.json` — regressioni del nuovo test.

## Note

- Rischio di bilanciamento da osservare in playtest, non un criterio: la
  calibrazione di PS-157/PS-158 è stata fatta con build larghe; con 6 posti
  i ranghi alti arrivano prima.
- La lista a schermo dei 6 posti è PS-204, che dipende da questa card.
