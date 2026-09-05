---
id: PS-101
titolo: Racconta la fame dietro agli Evil e la redenzione di Barb
tipo: feat
area: gameplay
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-09-05
aggiornato: 2026-09-05
---

# PS-101 — Racconta la fame dietro agli Evil e la redenzione di Barb

## Contesto

Il gioco non spiega mai perché un amico diventi `Evil <Nome>`, né perché
sconfiggerlo con la Specialità di Barb lo faccia tornare come prima. Il
contratto esiste già ma è vuoto:

- `BossDefinition` ([scripts/bosses/boss_definition.gd](../../../scripts/bosses/boss_definition.gd))
  espone un campo `quote` con gate di approvazione (`quote_approved`,
  `get_safe_quote()`, righe 14-16 e 56-60), ma oggi vale solo per
  `data/bosses/first_boss.tres`, dove è ancora il placeholder non approvato
  `"Citazione personale in attesa di approvazione."` — nemmeno il Piccione
  Malvagio ha una battuta vera.
- `BossEncounter.resolve_variant()` ([scripts/bosses/boss_encounter.gd:184-201](../../../scripts/bosses/boss_encounter.gd))
  duplica quel `BossDefinition` per costruire la variante Evil (`evil_definition
  := baseline.duplicate(true)`), quindi ogni `Evil <Nome>` mostra la stessa
  citazione del Piccione Malvagio: `get_safe_quote()` non fa mai il branch per
  amico, a differenza di `get_safe_title()` (riga 63-66) e `get_safe_portrait()`
  (riga 69-72), che invece risolvono `friend_profile` quando
  `is_evil_variant()` è vero.
- `FriendDefinition` ([scripts/content/friend_definition.gd](../../../scripts/content/friend_definition.gd))
  ha già un gruppo `Evil Counterpart` con `evil_display_name` (riga 47) e
  `evil_portrait` (riga 51): manca il campo gemello per una citazione propria.
- `BarbRewardOverlay` ([scripts/ui/barb_reward_overlay.gd](../../../scripts/ui/barb_reward_overlay.gd))
  mostra solo `"LE SPECIALITÀ DI BARB"` / `"IL PREMIO DI BARB"` (righe 341-346),
  senza mai nominare quale amico è stato appena salvato — anche se
  `BossEncounter.get_last_defeated_title()` (già presente, riga 204-205) lo sa
  già e oggi non è letto da nessuna UI.

Il proprietario vuole un aggancio narrativo semplice, coerente col tono
leggero e col tema griglia del gioco (sottotitolo "It's grilling time!"): gli
amici diventano malvagi perché hanno **fame**, non per cattiveria. Il Player
li affronta per fermarli, non per punirli. Una volta sconfitti, la Specialità
di Barb li sfama e li fa tornare amici come prima. Vuole anche una riga
ricorrente, tipo morale, che richiami "la fame fa fare cose orribili".

## Comportamento atteso

- Ogni `Evil <Nome>` (Alea, Aleo, Bea, Lollo, Magno, Marghe, Migi, Zat) mostra
  nella Boss Intro una citazione propria, scritta in prima persona, che lega
  la sua trasformazione alla fame in modo coerente col personaggio (non un
  testo intercambiabile fra profili).
- Anche il Piccione Malvagio (baseline, nessun `friend_profile`) ha una
  citazione propria approvata, sullo stesso registro fame/griglia — oggi è
  l'unico placeholder rimasto attivo in produzione.
- Il Barb Reward mostrato dopo la vittoria nomina l'amico appena sconfitto e
  comunica che è salvo/tornato buono grazie al pasto di Barb — non più un
  titolo generico e anonimo.
- Da qualche parte nel ciclo Boss (intro, reward, o entrambi — decisione di
  resolver, vedi Decisioni) compare una riga ricorrente riconoscibile che
  richiama "la fame fa fare cose orribili", con la stessa formula ogni volta
  invece di essere riscritta caso per caso.
- Nessun testo introduce violenza, crudeltà o un tono cupo: la fame resta un
  espediente giocoso, mai un evento drammatico.

## Criteri di accettazione

- [ ] `FriendDefinition` ha un campo `evil_quote` (più eventuale gate di
      approvazione, sulla falsariga di `quote`/`quote_approved` di
      `BossDefinition`) per ciascuno degli otto profili in `data/friends/*.tres`.
- [ ] `BossDefinition.get_safe_quote()` fa il branch su `is_evil_variant()` e
      `friend_profile` esattamente come già fa `get_safe_title()`, risolvendo
      la citazione dell'amico quando disponibile e restando sul fallback
      sicuro altrimenti (nessuna texture o stringa nulla visibile).
- [ ] Le otto citazioni Evil sono scritte, distinte l'una dall'altra, e
      nominano o alludono alla fame in modo riconoscibile dal personaggio
      (es. legata al suo ruolo/passiva), non intercambiabili fra profili.
- [ ] `data/bosses/first_boss.tres` ha una citazione scritta e
      `quote_approved = true`: il Piccione Malvagio non mostra più il
      placeholder in produzione.
- [ ] `BarbRewardOverlay` mostra, oltre al titolo esistente, il nome
      dell'amico appena salvato (letto da
      `BossEncounter.get_last_defeated_title()` o equivalente) e una frase che
      lo dichiara tornato buono grazie a Barb.
- [ ] Quando il Boss sconfitto è il Piccione Malvagio (nessun `friend_profile`,
      niente da "salvare"), `BarbRewardOverlay` non mostra un testo di
      redenzione incoerente (nessun amico rotto o placeholder vuoto).
- [ ] Compare almeno una volta per ciclo Boss (intro e/o reward) la riga
      ricorrente sul tema "la fame fa fare cose orribili", con testo fisso
      riutilizzato in ogni occorrenza.
- [ ] Nessuna citazione o riga di redenzione supera lo spazio disponibile nel
      proprio label senza troncarsi in modo illeggibile (stesso vincolo di
      auto-wrap già gestito da `BossUI`, righe 16-17 e 52 del sorgente).

## Ambito

- `scripts/content/friend_definition.gd` e `data/friends/*.tres`: nuovo campo
  citazione Evil per profilo.
- `scripts/bosses/boss_definition.gd`: branch di `get_safe_quote()`.
- `data/bosses/first_boss.tres`: citazione e approvazione del Piccione
  Malvagio.
- `scripts/ui/barb_reward_overlay.gd` e
  [scenes/ui/barb_reward_overlay.tscn](../../../scenes/ui/barb_reward_overlay.tscn):
  riga di redenzione con il nome dell'amico salvato.
- `docs/characters.md` ed `docs/enemies-bosses.md`: sincronizzare il risultato
  narrativo finale (non il processo di scrittura).

Non toccare:

- `BossEncounter.resolve_variant()` oltre a leggere il nuovo campo — RNG,
  soglie e selezione del profilo restano quelli di PS-006/PS-037;
- il layout e la cornice della Boss Intro e del Barb Reward (quello è
  [PS-102](./PS-102-cornice-dedicata-boss-intro.md)/PS-103, non questa card);
- `effect_id`, statistiche, Signature e ogni altro contratto meccanico dei
  profili Evil.

## Verifica

- Smoke: `tests/unit/test_ps101_evil_hunger_narrative.gd` → marker
  `EVIL_HUNGER_NARRATIVE_SMOKE_OK` — verifica che `get_safe_quote()` risolva
  una citazione diversa per almeno due profili Evil distinti, che il
  Piccione Malvagio non mostri più il placeholder, e che `BarbRewardOverlay`
  esponga il nome dell'amico salvato dopo `boss_defeated`.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: intro Boss di almeno due profili
      Evil diversi + Barb Reward dopo la vittoria)
- [ ] Controllo percettivo richiesto: no — è testo, non arte nuova; resta
      comunque da leggere ad alta voce prima di approvarlo, vedi Decisioni

## Decisioni

- **2026-09-05 — La fame è l'unica causa della trasformazione, mai
  cattiveria innata.** Il proprietario ha chiesto esplicitamente un tono
  leggero e giocoso, coerente col resto del gioco: nessun testo deve
  suggerire crudeltà, violenza reale o un evento oscuro.
- **Aperto per il resolver — dove va la riga ricorrente sulla fame.** Il
  proprietario ha chiesto una frase-morale riconoscibile ma non ha deciso se
  vada nella Boss Intro (prima dello scontro, come premessa), nel Barb
  Reward (dopo, come morale della favola) o in entrambe in forme diverse.
  Default proposto se non diversamente indicato: nel Barb Reward, subito
  dopo la riga di redenzione, perché chiude il cerchio "aveva fame → ora è
  salvo" nello stesso momento in cui il giocatore la legge.
- **Aperto per il resolver — testo esatto delle otto citazioni Evil e della
  riga di redenzione.** Il proprietario non ha fornito i testi finali; vanno
  proposti in bozza e approvati prima di marcare `quote_approved = true`,
  sullo stesso principio già applicato ai nomi delle Specialità in PS-078.

## Documenti sincronizzati

- [ ] `docs/characters.md`: aggiungere la citazione/lore fame per ciascuno
      degli otto profili, se il proprietario conferma che vada lì.
- [ ] `docs/enemies-bosses.md`: sezione "Boss Intro: identità individuale"
      aggiornata con il contratto della citazione per amico.

## Note

Questa card è indipendente dal redesign visivo del pannello
([PS-102](./PS-102-cornice-dedicata-boss-intro.md)/PS-103): tocca solo dati e
copy, non frame o layout. Le due linee di lavoro possono procedere in
parallelo e chiudersi in qualunque ordine.

Non è una card `tipo: art`: non richiede delega a `game-art-designer`. Una
volta scritte le otto citazioni e la riga di redenzione, il proprietario può
invocare manualmente `revisore-design-ux` per verificare che il nuovo testo
comunichi davvero "fame → scontro → redenzione" a chi gioca per la prima
volta, invece di restare un dettaglio di lore che nessuno legge — non è
invocazione automatica di `card-risolvi`, va richiesta esplicitamente se il
proprietario la ritiene utile.
