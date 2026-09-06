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
  - il movimento diventa più **instabile** tramite una **deriva periodica
    sull'input**: a intervalli, la direzione di movimento effettiva viene
    deviata per un istante rispetto a quella voluta dal giocatore, che deve
    correggerla — non un rumore continuo né una perdita di controllo totale
    (confermato dal proprietario, vedi Decisioni);
- Trascorsa la finestra di Brilla, Alea torna allo stato normale e la barra
  Sobrietà **si azzera completamente** e ricomincia il ciclo da zero
  (confermato dal proprietario, vedi Decisioni).
- La barra Sobrietà è visibile nella safe area, in alto a sinistra, come
  icona a calice di vino rosso (asset prodotto da
  [PS-104](./PS-104-icona-calice-sobrieta-alea.md)) che comunica il livello
  di riempimento. L'icona resta **solo** l'indicatore HUD (confermato dal
  proprietario, vedi Decisioni).
- Il vecchio tell particellare verde/rosso (`TELL_ALEA_POSITIVE`/
  `TELL_ALEA_NEGATIVE`) non ha più senso con un esito sempre uguale e va
  sostituito da un **nuovo colore di particellare dedicato** (es. ambra/oro)
  sullo stesso meccanismo già usato da Aleo/Lollo/Migi — non l'icona del
  calice, che resta separata dal tell (vedi Decisioni).
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
- [ ] Durante Brilla, a intervalli periodici la direzione di movimento
      effettiva devia per un istante da quella voluta dal giocatore (deriva
      sull'input, non rumore continuo): percettibile e correggibile, mai una
      perdita di controllo totale.
- [ ] Trascorsa Brilla, la barra Sobrietà si azzera completamente e
      ricomincia il proprio ciclo in modo deterministico: nessuna dipendenza
      da RNG in nessun punto del nuovo meccanismo, nessuna quota residua
      portata al ciclo successivo.
- [ ] La barra Sobrietà è visibile nella safe area (in alto a sinistra,
      senza sovrapporsi a `HealthPanel`/`ExperiencePanel` già presenti in
      quella fascia, [scenes/ui/hud.tscn](../../../scenes/ui/hud.tscn) righe
      113-170) e riflette in tempo reale il livello di riempimento tramite
      l'icona del calice di PS-104, senza ulteriore riuso come tell.
- [ ] `docs/characters.md` (sezione Alea) e `passive_title`/
      `passive_description`/`passive_parameters` di `data/friends/alea.tres`
      riflettono la nuova passiva; il ruolo di Alea passa da "Rischio,
      fortuna e mischia" a **"Caos, vino e piroette"** (confermato dal
      proprietario, vedi Decisioni).
- [ ] Il tell "in Brilla" usa un nuovo colore di particellare dedicato
      (non il vecchio verde/rosso, non l'icona del calice), sullo stesso
      meccanismo già in uso per Aleo/Lollo/Migi.
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
- **2026-09-05 — Instabilità di movimento: deriva periodica sull'input.**
  Il proprietario ha scelto questa opzione fra tre proposte (deriva
  periodica, overshoot sulla velocità, rumore continuo sulla direzione):
  a intervalli la direzione effettiva di movimento devia per un istante da
  quella voluta, e va corretta — resta un evento periodico e gestibile, non
  un tremore costante né una perdita di controllo.
- **2026-09-05 — Il calice non raddoppia come tell di stato.** Confermato in
  coordinamento con [PS-104](./PS-104-icona-calice-sobrieta-alea.md):
  l'icona resta solo l'indicatore HUD. Il tell "in Brilla" introduce un
  nuovo colore di particellare dedicato (es. ambra/oro), sullo stesso
  meccanismo già usato da Aleo/Lollo/Migi, al posto del vecchio
  verde/rosso.
- **2026-09-05 — La barra si azzera completamente dopo Brilla.** Confermato
  dal proprietario: nessuna quota residua portata al ciclo successivo, ciclo
  pulito e facile da imparare a leggere.
- **2026-09-05 — Il ruolo di Alea diventa "Caos, vino e piroette".**
  Confermato dal proprietario, in sostituzione di "Rischio, fortuna e
  mischia": la fortuna esce dal meccanismo, il nuovo ruolo riflette il
  ciclo Sobrietà/Brilla (il vino) e la mischia ravvicinata invariata
  (le piroette, "Gran Piroetta"). Aggiorna `docs/characters.md` insieme
  alla nuova passiva.

## Documenti sincronizzati

- [ ] `docs/characters.md`: sezione Alea — nuova passiva e nuovo ruolo
      "Caos, vino e piroette" (sostituisce "Rischio, fortuna e mischia").
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
