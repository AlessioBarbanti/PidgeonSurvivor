---
id: PS-122
titolo: Il contorno di ricarica in background deve sempre ripartire da un cerchio pieno
tipo: fix
area: gameplay
stato: IN VERIFICA
priorita: media
dipende_da: [PS-120]
origine: segnalazione del proprietario 2026-09-07 (test su device, Lollo)
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-122 — Il contorno di ricarica in background deve sempre ripartire da un cerchio pieno

## Contesto

Il proprietario ha confermato su device la parte funzionale di
[PS-120](./PS-120-fix-ricarica-cariche-abilita-e-indicatore-hud.md) (cariche
multiple, contorno invece della maschera scura), ma ha segnalato:
"il contorno, appena lanciavo un'abilità iniziava già caricato circa al 90%,
mi piacerebbe però che la ricarica partisse sempre dall'inizio del cerchio,
non solo dall'ultima parte". Notato su Lollo con più ranghi sia di Bis alla
Griglia (`ability_charge_stacking`) sia di Ravviva la Brace!
(`active_ability_cooldown_multiplier`).

Causa: `AbilityController.get_cooldown_remaining()`/`get_cooldown_total()`
(che PS-120 riusava per pilotare il contorno) riflettono la carica **più
vicina** al completamento (`_index_of_soonest_charge()`) — la domanda
"quando posso lanciare di nuovo". Con più cariche in ricarica
contemporaneamente (rapida sequenza di lanci), il timer più vicino al
completamento è spesso uno **vecchio**, quasi finito da un lancio
precedente — non quello appena creato dal lancio corrente. Il contorno
quindi si agganciava a qualunque timer risultasse più vicino in quel
momento, apparendo "già carico" appena lanciata l'abilità invece di
ripartire da un cerchio pieno.

## Comportamento atteso

Ogni volta che si consuma una carica, il contorno di ricarica in background
riparte da un cerchio pieno e si restringe verso zero in modo continuo,
indipendentemente da quante altre cariche stiano già ricaricando.

## Criteri di accettazione

- [x] `AbilityController` espone `get_time_until_full_remaining()`/
      `get_time_until_full_total()`, basati sulla carica **più lontana**
      dal completamento (`_index_of_furthest_charge()`) — "quanto manca per
      essere di nuovo a cariche piene", non "quando posso lanciare di
      nuovo" (quello resta `get_cooldown_remaining()`/`get_cooldown_total()`,
      invariati, usati dalla maschera scura di blocco).
- [x] Il contorno (`TouchAbilityButton`) usa questi nuovi valori
      (`get_recharge_fraction()`), non più `get_cooldown_fraction()`: dato
      che ogni nuovo consumo crea un timer fresco con la durata piena, quel
      timer è sempre il più lontano dal completamento, quindi il contorno
      riparte sempre da un cerchio pieno a ogni lancio.
- [x] La maschera scura di blocco (zero cariche) resta invariata: continua a
      usare `get_cooldown_remaining()`/`get_cooldown_total()` (la carica più
      vicina, "quando torno lanciabile").
- [x] Nuovo test che riproduce lo scenario: due lanci ravvicinati con la
      prima carica a metà ricarica al momento del secondo lancio — il
      contorno deve mostrare il progresso del secondo lancio (appena
      iniziato), non quello del primo (già a metà).

## Ambito

- `scripts/abilities/ability_controller.gd`: nuovi
  `get_time_until_full_remaining()`/`get_time_until_full_total()`/
  `_index_of_furthest_charge()`.
- `scripts/ui/touch_ability_button.gd`: `set_charge_state()` guadagna due
  parametri opzionali, `_draw()` usa `get_recharge_fraction()` per il
  contorno.
- `scripts/ui/hud.gd`: `_on_ability_charges_changed()`/
  `_refresh_ability_state()` passano i nuovi valori al pulsante.
- `tests/unit/test_ps094_ability_charge_stacking.gd`: nuovo test dedicato.
- Corretti nello stesso passaggio: alcuni commenti in
  `ability_controller.gd`/`touch_ability_button.gd`/questo stesso test
  citavano erroneamente "PS-119" invece di "PS-120" (il fix delle cariche
  che non ricaricavano oltre 1, non il fix dello spawn del Boss) —
  refuso di battitura tra card consecutive nella stessa sessione.

Non toccare:

- `get_cooldown_remaining()`/`get_cooldown_total()`/`is_cooldown_ready()`:
  semantica "quando posso lanciare di nuovo" invariata, usata dalla
  maschera di blocco e da `try_activate()`.
- il numero di cariche mostrato (PS-094/PS-120): invariato.

## Verifica

- Smoke: `tests/unit/test_ps094_ability_charge_stacking.gd` → nuova
  `test_recharge_outline_always_restarts_from_full_after_each_cast` →
  marker `RECHARGE_OUTLINE_RESTART_SMOKE_OK`.
- **Prova di regressione genuina**: ripristinato temporaneamente il codice
  pre-fix (`git stash`) — il test fallisce alla **compilazione** (i nuovi
  metodi non esistono ancora), una prova più forte di una singola
  asserzione. Ripristinato il fix e riconfermato verde.
- Eseguito: Focused 1/1 PASS (3/3 funzioni di test), Relevant 34/34 PASS,
  nessun `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Profilo minimo prima della chiusura: `Relevant`. ✅

## Gate manuali

- [ ] **Aperto** — Runtime Windows: non eseguito.
- [ ] **Aperto** — Validazione statica APK: non ancora eseguita su un APK
      contenente questo fix specifico.
- [ ] **Aperto** — Runtime fisico Pixel 9: lancia l'abilità più volte in
      rapida sequenza con più cariche disponibili e verifica che il
      contorno riparta sempre da un cerchio pieno a ogni lancio, mai da un
      punto già avanzato. Nessun device collegato in questa sessione — è
      esattamente il gate che il proprietario ha già esercitato riportando
      il comportamento originale.
- [ ] **Aperto** — Controllo percettivo richiesto: sì — stesso gate rimasto
      aperto su PS-120, ora più mirato: il contorno deve visibilmente
      ripartire da pieno a ogni lancio.

## Decisioni

- **2026-09-07 — Due nozioni distinte di "quanto manca", non una sola
  corretta genericamente.** `get_cooldown_remaining()` (la più vicina) resta
  la scelta giusta per "posso lanciare di nuovo?" — un blocco totale deve
  contare alla rovescia verso la prima carica utile, non verso l'ultima.
  Il contorno risponde invece a una domanda diversa ("quanto manca per
  essere di nuovo a piena capacità?"), per cui la carica più lontana è la
  scelta corretta. Introdurre un secondo getter dedicato, invece di
  riadattare il significato dei due esistenti, evita di rompere
  `try_activate()`/la maschera di blocco per sistemare il contorno.
- **2026-09-07 — Chiarito con il proprietario, nessuna modifica al codice.**
  Il proprietario temeva che "tempo alla piena ricarica" potesse significare
  un giro cumulativo più lungo del cooldown di una singola carica. Confermato
  con un esempio numerico (cooldown 2s, cariche in parallelo non in
  sequenza) che ogni giro del contorno dura esattamente il cooldown di una
  carica, mai di più: l'implementazione già scritta soddisfa il requisito
  così come chiarito. Il proprietario ha confermato ("no va bene, avevo
  capito male io").

## Documenti sincronizzati

- [ ] Nessuno: comportamento HUD, nessun contratto di prodotto/architettura
      da aggiornare.

## Note

Trovato interamente tramite un secondo giro di feedback del proprietario su
PS-120 già in `IN VERIFICA` — non una segnalazione nuova e scollegata, ma un
affinamento della stessa funzionalità dopo il primo test su device reale.
