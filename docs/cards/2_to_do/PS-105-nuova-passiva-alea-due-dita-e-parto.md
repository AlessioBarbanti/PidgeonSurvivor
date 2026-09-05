---
id: PS-105
titolo: Sostituisci la passiva di Alea con Due Dita e Parto
tipo: feat
area: gameplay
stato: BLOCCATO
priorita: media
dipende_da: [PS-104]
origine:
creato: 2026-09-05
aggiornato: 2026-09-05
---

# PS-105 — Sostituisci la passiva di Alea con Due Dita e Parto

## Contesto

La passiva attuale di Alea, "L'Aquila Non Sbaglia Mai"
(`alea_eagle_never_misses`,
[scripts/content/friend_passive_controller.gd](../../../scripts/content/friend_passive_controller.gd)
righe 372-454, 416-432), tira ogni 10 secondi un effetto casuale
positivo/negativo su movimento o cadenza; uccidere nemici carica
`_alea_luck_bonus`, che aumenta la probabilità dell'esito positivo al tiro
successivo e si azzera per intero a ogni tiro (`_charge_alea_luck()`,
`_activate_alea_effect()`). Il tell visivo associato,
`TELL_ALEA_POSITIVE`/`TELL_ALEA_NEGATIVE` (righe 53-54, 699), tinge il
particellare di stato di Alea in verde o rosso mentre l'effetto è attivo.

Il proprietario vuole sostituire l'intero meccanismo con **"Due dita e
parto"**: niente più RNG, un ciclo interamente prevedibile che il giocatore
impara a leggere in anticipo.

## Comportamento atteso

- Alea ha una **barra Sobrietà** che si riempie in modo lento e continuo nel
  tempo (non legata a kill, danno o RNG — un semplice accumulo temporale,
  salvo diversa indicazione del proprietario in fase di bilanciamento).
- Al raggiungimento della soglia, Alea entra **automaticamente** in
  **Brilla** per 5-6 secondi:
  - forte aumento di cadenza di fuoco e velocità di movimento;
  - il movimento diventa più **instabile** (va definita un'implementazione
    concreta: es. una deriva/jitter periodico sulla direzione effettiva di
    movimento, che il giocatore deve correggere, invece di un semplice
    moltiplicatore lineare — vedi Decisioni per l'ambito lasciato al
    resolver);
- Trascorsa la finestra di Brilla, Alea torna allo stato normale e la barra
  Sobrietà riparte da capo (o dal punto che il resolver ritiene più coerente
  col "ciclo prevedibile" — vedi Decisioni).
- La barra Sobrietà è visibile nella safe area, in alto a sinistra, come
  icona a calice di vino rosso (asset prodotto da
  [PS-104](./PS-104-icona-calice-sobrieta-alea.md)) che comunica il livello
  di riempimento.
- Il vecchio tell particellare verde/rosso (`TELL_ALEA_POSITIVE`/
  `TELL_ALEA_NEGATIVE`) non ha più senso con un esito sempre uguale e va
  sostituito da un tell coerente con "in Brilla" (icona del calice pieno
  riusata, o un nuovo colore di particellare — decisione legata a quella
  aperta in PS-104, vedi Decisioni).
- Nessun esito è più casuale: stessa durata di accumulo, stessa soglia,
  stessa durata di Brilla, ogni volta (a parità di bilanciamento scelto),
  cosicché il giocatore possa anticipare il momento in cui Alea "parte".

## Criteri di accettazione

- [ ] `alea_eagle_never_misses` (RNG, luck-per-kill, tell positivo/negativo)
      è rimosso dalla passiva di Alea: nessun residuo di `_alea_luck_bonus`,
      `_charge_alea_luck()`, `random_effect_started`/`luck_charge_changed`
      per questo profilo.
- [ ] Alea accumula una quota Sobrietà nel tempo, in `RUNNING`, che si
      azzera/congela coerentemente con pausa, level-up, Boss intro e
      restart (stesso contratto già rispettato dalle altre passive a
      soglia, es. Guarigione Ritardata di Zat).
- [ ] Al raggiungimento della soglia, Alea entra in Brilla per 5-6 secondi
      con un aumento misurabile di cadenza di fuoco e velocità di
      movimento, poi torna esattamente ai valori base.
- [ ] Durante Brilla il movimento è percettibilmente meno preciso/prevedibile
      da guidare rispetto al movimento normale, in un modo che il giocatore
      può imparare a compensare (non un effetto puramente estetico che non
      cambia il gameplay).
- [ ] Trascorsa Brilla, la barra Sobrietà riprende il proprio ciclo in modo
      deterministico: nessuna dipendenza da RNG in nessun punto del nuovo
      meccanismo.
- [ ] La barra Sobrietà è visibile nella safe area (in alto a sinistra,
      senza sovrapporsi a `HealthPanel`/`ExperiencePanel` già presenti in
      quella fascia, [scenes/ui/hud.tscn](../../../scenes/ui/hud.tscn) righe
      113-170) e riflette in tempo reale il livello di riempimento.
- [ ] `docs/characters.md` (sezione Alea) e `passive_title`/
      `passive_description`/`passive_parameters` di `data/friends/alea.tres`
      riflettono la nuova passiva; il ruolo dichiarato di Alea
      ("Rischio, fortuna e mischia") è rivisto se il proprietario conferma
      che l'identità cambia insieme al meccanismo (vedi Decisioni).
- [ ] La Signature Evil Alea ("Gran Piroetta", abilità attiva) resta
      invariata: questa card tocca solo la passiva, non l'attiva né il Boss.

## Ambito

- `scripts/content/friend_passive_controller.gd`: rimozione del ramo Alea
  esistente, nuova logica Sobrietà/Brilla.
- `data/friends/alea.tres`: `passive_title`, `passive_description`,
  `passive_parameters`.
- `scenes/ui/hud.tscn` / `scripts/ui/hud.gd`: nuovo elemento barra Sobrietà
  in alto a sinistra, usando l'asset di
  [PS-104](./PS-104-icona-calice-sobrieta-alea.md).
- `docs/characters.md`: sezione Alea.

Non toccare:

- `active_ability_id`/`active_ability_title` di Alea ("Gran Piroetta") e la
  Signature Evil Alea — restano quelli attuali;
- le altre sette passive del cast e i rispettivi tell;
- `BossEncounter`/`BossDefinition` e il contratto Boss Intro (PS-051).

## Verifica

- Smoke: `tests/unit/test_ps105_alea_sobriety_cycle.gd` → marker
  `ALEA_SOBRIETY_CYCLE_SMOKE_OK` — verifica accumulo deterministico della
  quota Sobrietà, trigger automatico di Brilla alla soglia, moltiplicatori
  di cadenza/movimento applicati e rimossi correttamente, nessuna chiamata a
  `RandomNumberGenerator` nel nuovo percorso Alea, e congelamento della
  quota fuori da `RUNNING`.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run con Alea fino ad almeno due
      cicli Brilla, per sentire cadenza/movimento e instabilità)
- [ ] Controllo percettivo richiesto: sì — l'instabilità di movimento deve
      sentirsi come una sfida gestibile, non come una perdita di controllo
      frustrante; la barra Sobrietà deve leggersi chiaramente durante il
      gameplay reale, non solo in un provino statico

## Decisioni

- **2026-09-05 — Niente più RNG per Alea: ciclo interamente deterministico.**
  Richiesta esplicita del proprietario ("Non è fortuna: è un ciclo
  prevedibile"): sostituisce integralmente `alea_eagle_never_misses`.
- **Aperto per il resolver — implementazione esatta di "movimento più
  instabile".** Il proprietario ha descritto l'effetto ma non il
  meccanismo. Opzioni plausibili: deriva laterale periodica sull'input di
  movimento, occasional overshoot sulla velocità, o un rumore procedurale
  sulla direzione effettiva. La scelta deve restare "gestibile" per il
  giocatore (vedi Gate manuali), non una perdita di controllo totale.
- **Aperto per il resolver, in coordinamento con
  [PS-104](./PS-104-icona-calice-sobrieta-alea.md) — il calice raddoppia
  anche come tell di stato "in Brilla"?** Se sì, questa card userà
  l'icona a livelli di PS-104 al posto del vecchio particellare colorato;
  se no, introduce un nuovo colore di particellare dedicato (es. ambra/oro)
  sullo stesso meccanismo già usato da Aleo/Lollo/Migi.
- **Aperto per il resolver/proprietario — la barra si azzera a zero dopo
  Brilla o riparte da una quota residua?** Il testo del proprietario non lo
  specifica; l'assunzione di default è azzeramento completo (ciclo pulito,
  più facile da imparare a leggere), ma è una scelta di bilanciamento
  legittima da confermare.
- **Aperto per il proprietario — il ruolo di Alea resta "Rischio, fortuna e
  mischia"?** La fortuna esce dal meccanismo; se il proprietario vuole
  aggiornare anche l'etichetta di ruolo in `docs/characters.md` (es. verso
  qualcosa come "Ciclo di potenziamento e mischia"), va deciso insieme
  all'approvazione dei nuovi testi.

## Documenti sincronizzati

- [ ] `docs/characters.md`: sezione Alea (passiva, eventualmente ruolo).
- [ ] `docs/prd.md` §3.4 se descrive nel dettaglio la passiva attuale di
      Alea (verificare in fase di risoluzione).

## Note

Card gemella e dipendente da
[PS-104](./PS-104-icona-calice-sobrieta-alea.md) (icona del calice): resta
`BLOCCATO` finché quella non raggiunge almeno `IN VERIFICA`.

Buon candidato per l'agente `analista-bilanciamento` (invocazione solo
manuale, su richiesta esplicita del proprietario): la durata dell'accumulo,
la soglia, la durata di Brilla e i moltiplicatori di cadenza/movimento sono
esattamente il tipo di numeri che quell'agente sa mettere in prospettiva
contro il resto del bilanciamento del cast, prima o dopo l'implementazione.
