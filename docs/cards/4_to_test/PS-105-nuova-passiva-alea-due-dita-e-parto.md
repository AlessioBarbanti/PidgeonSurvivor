---
id: PS-105
titolo: Sostituisci la passiva di Alea con Due Dita e Parto
tipo: feat
area: gameplay
stato: IN VERIFICA
priorita: media
dipende_da: []
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
- La passiva espone il livello di riempimento della barra Sobrietà tramite un
  segnale/metodo pubblico di `FriendPassiveController`
  (`alea_sobriety_changed(fill_ratio: float)`), cosicché una card di
  integrazione separata ([PS-106](./PS-106-integra-icona-calice-sobrieta-alea-hud.md))
  possa cablarlo a un'icona a calice di vino rosso in HUD (asset di
  [PS-104](./PS-104-icona-calice-sobrieta-alea.md)). Questa card non tocca
  `hud.tscn`/`hud.gd`: si ferma a esporre il valore (vedi Decisioni).
- Il vecchio tell particellare verde/rosso (`TELL_ALEA_POSITIVE`/
  `TELL_ALEA_NEGATIVE`) non ha più senso con un esito sempre uguale e va
  sostituito da un **nuovo colore di particellare dedicato** (es. ambra/oro)
  sullo stesso meccanismo già usato da Aleo/Lollo/Migi — non l'icona del
  calice, che resta separata dal tell (vedi Decisioni).
- Nessun esito è più casuale: stessa durata di accumulo, stessa soglia,
  stessa durata di Brilla, ogni volta (a parità di bilanciamento scelto),
  cosicché il giocatore possa anticipare il momento in cui Alea "parte".

## Criteri di accettazione

- [x] `alea_eagle_never_misses` (RNG, luck-per-kill, tell positivo/negativo)
      è rimosso dalla passiva di Alea: nessun residuo di `_alea_luck_bonus`,
      `_charge_alea_luck()`, `random_effect_started`/`luck_charge_changed`
      per questo profilo. Verificato: grep pulito su tutti i simboli rimossi
      in `friend_passive_controller.gd`.
- [x] Alea accumula una quota Sobrietà nel tempo, in `RUNNING`, che si
      azzera/congela coerentemente con pausa, level-up, Boss intro e
      restart (stesso contratto già rispettato dalle altre passive a
      soglia, es. Guarigione Ritardata di Zat). Verificato:
      `test_ps105_alea_sobriety_cycle.gd`.
- [x] Al raggiungimento della soglia, Alea entra in Brilla per 5-6 secondi
      con un aumento misurabile di cadenza di fuoco e velocità di
      movimento, poi torna esattamente ai valori base. Verificato:
      `test_ps105_alea_sobriety_cycle.gd`, `test_b17a_complete_roster_abilities.gd`.
- [x] Durante Brilla, a intervalli periodici la direzione di movimento
      effettiva devia per un istante da quella voluta dal giocatore (deriva
      sull'input, non rumore continuo): percettibile e correggibile, mai una
      perdita di controllo totale. Verificato automaticamente (rotazione
      applicata/rimossa in `Player`); il "si sente giusto" resta il
      controllo percettivo su device (vedi Gate manuali).
- [x] Trascorsa Brilla, la barra Sobrietà si azzera completamente e
      ricomincia il proprio ciclo in modo deterministico: nessuna dipendenza
      da RNG in nessun punto del nuovo meccanismo, nessuna quota residua
      portata al ciclo successivo. Verificato: confronto fra due seed
      diversi con timeline identica (nessun `_rng` nel percorso Alea).
- [x] `FriendPassiveController` espone il livello di riempimento della barra
      Sobrietà tramite un segnale pubblico (`alea_sobriety_changed(fill_ratio:
      float)`, 0.0-1.0), aggiornato ad ogni variazione: il cablaggio in HUD
      con l'icona di PS-104 è [PS-106](./PS-106-integra-icona-calice-sobrieta-alea-hud.md),
      non questa card.
- [x] `docs/characters.md` (sezione Alea) e `passive_title`/
      `passive_description`/`passive_parameters` di `data/friends/alea.tres`
      riflettono la nuova passiva; il ruolo di Alea passa da "Rischio,
      fortuna e mischia" a **"Caos, vino e piroette"** (confermato dal
      proprietario, vedi Decisioni). `passive_description` è testo scritto dal
      resolver in questa sessione, non approvato verbatim dal proprietario
      (vedi Decisioni) — a differenza di ruolo e `passive_title`, che sono
      testo verbatim del proprietario.
- [x] Il tell "in Brilla" usa un nuovo colore di particellare dedicato
      (non il vecchio verde/rosso, non l'icona del calice), sullo stesso
      meccanismo già in uso per Aleo/Lollo/Migi. Verificato:
      `test_ps029_state_tell_visibility.gd`, `test_ps079_state_tell_particles.gd`.
- [x] La Signature Evil Alea ("Gran Piroetta", abilità attiva) resta
      invariata: questa card tocca solo la passiva, non l'attiva né il Boss.
      Non toccato nessun file relativo; `test_b17a_complete_roster_abilities.gd`
      continua a verificare l'attiva di Alea senza modifiche.

## Ambito

- `scripts/content/friend_passive_controller.gd`: rimozione del ramo Alea
  esistente, nuova logica Sobrietà/Brilla.
- `data/friends/alea.tres`: `passive_title`, `passive_description`,
  `passive_parameters`, `role`, `tags`.
- `docs/characters.md`: sezione Alea.
- `scripts/actors/player.gd`: nuovo hook `set_movement_drift_rotation()`/
  `get_movement_drift_rotation()`, character-agnostico (stesso pattern di
  `set_momentum_trail_enabled()`), non previsto nell'ambito originale della
  card ma necessario per il criterio di deriva sull'input (vedi Decisioni).

Non toccare:

- `scenes/ui/hud.tscn` / `scripts/ui/hud.gd`: il cablaggio dell'icona in HUD
  è [PS-106](./PS-106-integra-icona-calice-sobrieta-alea-hud.md), non questa
  card;
- `active_ability_id`/`active_ability_title` di Alea ("Gran Piroetta") e la
  Signature Evil Alea — restano quelli attuali;
- le altre sette passive del cast e i rispettivi tell;
- `BossEncounter`/`BossDefinition` e il contratto Boss Intro (PS-051).

## Verifica

- Smoke: `tests/unit/test_ps105_alea_sobriety_cycle.gd` → marker
  `ALEA_SOBRIETY_CYCLE_SMOKE_OK` — verifica accumulo deterministico della
  quota Sobrietà, congelamento fuori da `RUNNING`, trigger automatico di
  Brilla alla soglia con moltiplicatori applicati/rimossi correttamente,
  deriva periodica sull'input percettibile e correggibile, azzeramento
  completo dopo Brilla, nessuna divergenza fra due seed diversi (nessuna
  dipendenza da RNG), e reset a restart/cambio personaggio.
- Aggiornati per la nuova API: `test_ps079_state_tell_particles.gd`,
  `test_ps029_state_tell_visibility.gd` (Alea non è più una coppia di
  colori), `test_b18u_cast_sprites.gd` (nuovo `passive_id`),
  `test_b17a_complete_roster_abilities.gd` (caso Alea in
  `_assert_passive`), `test_b42_measurable_passives.gd` (rimossa
  `test_alea_luck()`, superata da questa card — coverage spostata qui).
- Eseguito in sandbox Linux (headless, Godot 4.7.1): focalizzato
  `test_ps105_alea_sobriety_cycle.gd` (5/5, 58 assert), unione dei test
  rilevanti da entrambe le regole di `milestone-test-map.json` toccate
  (`scripts/actors/player.gd`/`data/friends/*` e
  `scripts/content/friend_passive_controller.gd`, 96/96, 3036 assert), e
  suite `Full` (325/325, 23994 assert). Nessun `SCRIPT ERROR`/`FATAL
  EXCEPTION` nei log.
- Regressione trovata e corretta durante la verifica:
  `test_ps069_character_select_bust_portrait.gd` si aspetta che la colonna
  Passiva/Abilità del selettore personaggi mantenga la stessa misura per
  ogni Friend; la prima stesura di `passive_description` (156 caratteri,
  più lunga di ogni altro profilo) faceva crescere la colonna di Alea.
  Accorciata a 116 caratteri (sotto il massimo esistente di Lollo, 136).
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
- **2026-09-05 — Scorporato il cablaggio HUD in
  [PS-106](./PS-106-integra-icona-calice-sobrieta-alea-hud.md).** Il
  proprietario ha scelto questa opzione fra tre proposte (lavorare la card
  intera lasciando aperto il criterio HUD, scorporarla, aspettare PS-104):
  un solo criterio su nove dipendeva dall'asset di PS-104, quindi lo
  scorporo sblocca subito il resto della passiva, stessa forma già usata per
  PS-102/PS-103. `dipende_da` passa da `[PS-104]` a `[]`.
- **2026-09-05 — Numeri di bilanciamento: default da resolver, non ancora
  approvati dal proprietario.** Durata di accumulo, soglia e moltiplicatori
  di cadenza/movimento durante Brilla non erano specificati (solo la durata
  di Brilla, 5-6s, era data); il proprietario ha chiesto di scegliere
  default ragionevoli e segnarli qui come aperti a bilanciamento successivo:
  accumulo lineare fino a soglia in **48 secondi**, moltiplicatore cadenza
  di fuoco **1.35×**, moltiplicatore velocità di movimento **1.30×** durante
  Brilla (6 secondi, estremo superiore della finestra data), deriva
  sull'input ogni **1.6 secondi** con deviazione di **35°** per **0.35
  secondi** poi correggibile. Nessuno di questi numeri è approvato dal
  proprietario: sono scelte del resolver, buon candidato per
  `analista-bilanciamento` (invocazione solo manuale) prima o dopo il
  playtest.
- **2026-09-05 — Estensione dell'ambito a `scripts/actors/player.gd`.** Il
  criterio "deriva periodica sull'input" richiede deviare la direzione
  effettiva di movimento, che solo `Player._physics_process()` calcola:
  `FriendPassiveController` non ha un hook per farlo. Aggiunto
  `set_movement_drift_rotation()`/`get_movement_drift_rotation()`,
  character-agnostico (stesso pattern già in uso per
  `set_momentum_trail_enabled()` di Magno): il Player resta ignaro di quale
  personaggio sia equipaggiato, è la passiva a pilotarlo. Non era nell'Ambito
  originale della card (scritta prima di leggere il codice di movimento), ma
  è l'unico modo di soddisfare un criterio già approvato, non un allargamento
  del comportamento richiesto.
- **2026-09-05 — Verso della deriva deterministico, non casuale.** Il
  criterio "nessuna dipendenza da RNG in nessun punto del nuovo meccanismo"
  è stato interpretato in senso stretto: il verso (sinistra/destra) di ogni
  impulso di deriva alterna in modo deterministico (flip di segno), non
  tramite `_rng`. Verificato confrontando due run con seed diversi: stessa
  timeline esatta.
- **2026-09-05 — `passive_description` è testo del resolver, non del
  proprietario.** A differenza di `role` ("Caos, vino e piroette.") e
  `passive_title` ("Due Dita e Parto"), che sono testo verbatim confermato
  dal proprietario in questa sessione, la descrizione della passiva è stata
  scritta da questa sessione per riflettere il meccanismo confermato. Resta
  sotto lo stesso `content_approved = true` già in vigore per Alea dal
  17/08/2026 (che copre identità/ruolo/passiva come blocco unico, senza un
  campo di approvazione dedicato alla sola descrizione): il proprietario
  dovrebbe rivederla, non è equivalente a un'approvazione esplicita del
  testo specifico.
- **2026-09-05 — Prima stesura di `passive_description` accorciata da 156 a
  116 caratteri.** Vedi Verifica: rompeva la misura fissa della colonna
  Passiva/Abilità nel selettore personaggi (`test_ps069`). Non cambia il
  contenuto, solo la sua lunghezza.

## Documenti sincronizzati

- [x] `docs/characters.md`: sezione Alea — nuova passiva e nuovo ruolo
      "Caos, vino e piroette" (sostituisce "Rischio, fortuna e mischia").
      Aggiornata anche la riga sugli scarti base (B47/PS-087) che citava
      "il rischio del ruolo", ormai obsoleta.
- [x] `docs/prd.md` §3.4 — riga dei "Parametri runtime B17A" di Alea
      riscritta con i nuovi parametri Sobrietà/Brilla/deriva.

## Note

Il cablaggio HUD dell'icona del calice (asset di
[PS-104](./PS-104-icona-calice-sobrieta-alea.md)) è
[PS-106](./PS-106-integra-icona-calice-sobrieta-alea-hud.md), non questa
card: questa card espone solo il segnale/metodo che PS-106 consumerà.

Buon candidato per l'agente `analista-bilanciamento` (invocazione solo
manuale, su richiesta esplicita del proprietario): la durata dell'accumulo,
la soglia, la durata di Brilla e i moltiplicatori di cadenza/movimento sono
default da resolver (vedi Decisioni), esattamente il tipo di numeri che
quell'agente sa mettere in prospettiva contro il resto del bilanciamento del
cast.

Disallineamento cosmetico non risolto da questa card: il file icona della
passiva resta `assets/art/icons/passives/generated/alea_eagle_never_misses.png`
(nome legato al vecchio `passive_id`); rinominarlo è un tocco d'arte fuori
ambito qui (nessuna generazione richiesta, solo un rename+manifest). Buon
candidato per una card `chore`/`art` minore separata, se il proprietario la
ritiene utile.
