---
id: PS-120
titolo: Correggi il tetto di ricarica delle cariche abilità e distingui l'indicatore HUD di ricarica in background
tipo: fix
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: [PS-094]
origine: segnalazione del proprietario 2026-09-07 (test su device, Bis alla Griglia)
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-120 — Correggi il tetto di ricarica delle cariche abilità e distingui l'indicatore HUD di ricarica in background

## Contesto

Il proprietario ha segnalato, testando [PS-094](./PS-094-specialita-cariche-abilita-attiva.md)
su device: "prima di tutto averne una o averne zero fa la stessa cosa, in più
le cariche non si caricano oltre l'uno, in più vorrei che la ricarica fosse
visibile anche mentre stiamo caricando la seconda abilità, magari solo con un
outline piuttosto che con l'icona standard che deve rimanere solo quando stai
caricando da zero a 1".

Due bug distinti, con una causa comune di sensazione ("la Specialità non fa
nulla"):

**1. Le cariche non superano mai il valore che avevano nel momento esatto
dello sblocco o del cambio di rango (bug funzionale).**
`AbilityController.set_charge_configuration()` (`scripts/abilities/ability_controller.gd`)
alza il tetto (`_max_charges`) quando si sblocca la Specialità o si sale di
rango, ma se il personaggio non era a cariche piene in quel momento
(scenario comune: l'abilità è spesso in ricarica durante un level-up in
combattimento), la nuova capacità non riceve mai un proprio timer di
ricarica. Le cariche si ricaricano solo consumando e riaspettando quelle già
"in volo" da prima: il valore disponibile non può mai superare quello che
avevano al momento esatto dello sblocco/rango, per il resto della run. Con
`max_charges` spesso sbloccato mentre l'abilità è in cooldown (`available=0`),
il tetto pratico osservato è "0 o 1", indistinguibile dal comportamento base
senza la Specialità — da qui "averne una o zero fa la stessa cosa".

**2. L'indicatore HUD non distingue "bloccato" da "utilizzabile, con
ricarica in corso in background" (bug di leggibilità).**
`TouchAbilityButton._draw()` (`scripts/ui/touch_ability_button.gd`) mostra la
maschera scura + anello arancio + conto alla rovescia ogni volta che esiste
un timer di ricarica attivo, **anche quando `available_charges > 0`** (cioè
l'abilità è comunque lanciabile perché resta almeno una carica pronta). Il
pulsante appare quindi identico sia a "zero cariche, non posso lanciare" sia
a "una carica pronta, un'altra sta ricaricando in background" — la stessa
ambiguità visiva lamentata al punto 1.

## Comportamento atteso

Le cariche aggiunte da uno sblocco o da un salto di rango raggiungono sempre
il nuovo tetto, indipendentemente da quante cariche fossero disponibili in
quel momento. Il pulsante abilità mostra la maschera scura con conto alla
rovescia **solo** quando zero cariche sono disponibili (l'abilità non è
lanciabile); quando almeno una carica è disponibile ma un'altra sta
ricaricando in background, mostra solo un contorno sottile, senza coprire
l'icona né impedirne la lettura.

## Criteri di accettazione

- [x] `AbilityController.set_charge_configuration()` apre un timer di
      ricarica dedicato per ogni nuovo slot di capacità aggiunto quando il
      personaggio non era a cariche piene nel momento dello sblocco/rango:
      le cariche disponibili raggiungono sempre il nuovo tetto, non restano
      bloccate al valore del momento dello sblocco.
- [x] Il comportamento a cariche piene resta invariato: se il personaggio era
      pieno, il nuovo tetto viene concesso subito pieno (nessuna attesa
      indebita), come già garantito da PS-094.
- [x] `TouchAbilityButton` mostra la maschera scura + anello arancio + conto
      alla rovescia solo quando `available_charges == 0`. Quando
      `available_charges > 0` e un'altra carica sta ricaricando, mostra un
      contorno (arco), senza maschera scura né testo, senza disabilitare il
      pulsante.
- [x] Nuovo test che riproduce esattamente lo scenario segnalato: consumare
      una carica, lasciarla a metà ricarica (non piena), salire di rango
      (tetto più alto), e verificare che le cariche disponibili raggiungano
      comunque il nuovo tetto aspettando abbastanza.
- [x] Verificato che le nuove assert falliscono genuinamente col codice
      pre-fix (non solo che il test passa col fix).

## Ambito

- `scripts/abilities/ability_controller.gd`: `set_charge_configuration()`.
- `scripts/ui/touch_ability_button.gd`: `_draw()`, nuova
  `_draw_recharge_outline()`, nuovo getter `is_recharging_extra_capacity()`.
- `tests/unit/test_ps094_ability_charge_stacking.gd`: nuovo test dedicato +
  assert aggiuntive sul pulsante nel test principale.

Non toccare:

- il modello a cooldown singolo (`max_charges == 1`, nessuna Specialità
  equipaggiata): bit-per-bit invariato, verificato dal test esistente.
- `scripts/progression/upgrade_effect_registry.gd`: il calcolo di
  `max_charges`/`cooldown_multiplier` per rango era già corretto (PS-094);
  il bug era solo nell'applicazione lato `AbilityController`.
- il numero mostrato sul pulsante (PS-094: solo il valore corrente, mai il
  tetto massimo) — invariato, questa card tocca solo l'anello/maschera.

## Verifica

- Smoke: `tests/unit/test_ps094_ability_charge_stacking.gd` → nuova funzione
  `test_charge_capacity_growth_while_recharging_still_reaches_new_maximum`
  → marker `ABILITY_CHARGE_CAPACITY_GROWTH_SMOKE_OK`; assert aggiuntive nel
  test principale (`button.is_recharging_extra_capacity()`,
  `button.has_circular_cooldown()`, `button.disabled`) → marker esistente
  `ABILITY_CHARGE_STACKING_SMOKE_OK`.
- **Prova di regressione genuina**: verificato che la nuova assert sulla
  ricarica fallisce (`2` invece di `3`) ripristinando temporaneamente
  `set_charge_configuration()` pre-fix (`git stash`), poi ripristinato il fix
  e riconfermato verde.
- Eseguito: Focused 1/1 PASS, Relevant 37/37 PASS, nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Profilo minimo prima della chiusura: `Relevant`. ✅

## Gate manuali

- [ ] **Aperto** — Runtime Windows: non eseguito.
- [x] Validazione statica APK: superata dal workflow CI
      (`android-debug-release.yml`, run 34118188873, 2026-09-07) sull'APK
      contenente questo fix.
- [x] Runtime fisico Pixel 9 (parte funzionale): confermato dal proprietario
      in conversazione (2026-09-07) — run con Lollo, cariche che salgono
      oltre 1 salendo di rango ("tirare la passiva ogni 3-4 secondi").
      **Resta aperta la parte percettiva**: non confermato se il contorno di
      ricarica in background sia stato effettivamente notato/distinto dalla
      maschera scura di blocco.
- [ ] **Aperto** — Controllo percettivo richiesto: sì — il nuovo contorno di
      ricarica deve restare leggibile e distinguibile sia dall'anello dorato
      "pronto" sia dalla maschera scura di blocco, a dimensione reale. Non
      ancora confermato esplicitamente dal proprietario.

## Decisioni

- **2026-09-07 — Timer dedicato per la capacità aggiunta, non un ricalcolo
  retroattivo.** Alternativa scartata: ricalcolare tutte le cariche mancanti
  da zero a ogni cambio di configurazione. Scartata perché romperebbe
  l'indipendenza delle cariche già in ricarica (PS-094: "le cariche già in
  ricarica non cambiano durata a ritroso"). Aggiungere un timer solo per il
  nuovo slot, con la durata corrente, preserva quell'invariante e risolve il
  bug con la modifica più piccola possibile.
- **2026-09-07 — Contorno come arco di progresso, non solo un bordo
  statico.** Il proprietario ha chiesto che "la ricarica fosse visibile":
  un bordo fisso comunicherebbe solo "sta succedendo qualcosa", non quanto
  manca. L'arco riusa la stessa semantica di avanzamento della maschera
  scura esistente (si restringe verso zero), solo con un trattamento visivo
  più leggero (contorno sottile, colore ciano per non confondersi con
  arancio=bloccato o oro=pronto).
- **2026-09-07 — Confermata su device reale solo la parte funzionale.** Il
  proprietario ha giocato con Lollo dopo l'aggiornamento dell'APK (release
  `android-debug-latest`, workflow run 34118188873) e confermato le cariche
  multiple in gioco ("cariche abilità maxate", "tirare la passiva ogni 3-4
  secondi è divertente"). Non ha confermato esplicitamente di aver notato
  il contorno di ricarica in background: il gate percettivo resta aperto
  finché non arriva quella conferma specifica.

## Documenti sincronizzati

- [ ] Nessuno: la card PS-094 già descrive il modello a cariche nella card
      stessa; questi erano bug di implementazione, non un contratto da
      aggiornare nei documenti durevoli.

## Note

Entrambi i bug erano invisibili ai test automatici di PS-094 perché quel
test manteneva sempre le cariche piene prima di ogni cambio di rango
(`ability._process(9999.0)` prima di ogni `_grant_and_select`) e non
verificava mai lo stato del pulsante durante una ricarica in background con
cariche già disponibili — esattamente lo scenario più comune in una run
reale (level-up mentre l'abilità è in cooldown).
