---
id: PS-099
titolo: Sostituisci il particellare di Lollo e Aleo con aura di potenziamento e tell termico
tipo: ux
area: arte
stato: IN VERIFICA
priorita: media
dipende_da: [PS-098]
origine: PS-079
creato: 2026-09-05
aggiornato: 2026-09-07
---

# PS-099 — Sostituisci il particellare di Lollo e Aleo con aura di potenziamento e tell termico

## Contesto

Oggi Aleo, Lollo, Alea e Migi condividono lo stesso tell di fase: cinque
particelle sospese sopra la testa, distinte solo dal colore
([PS-079](../5_completed/PS-079-particellare-tell-stato-personaggi.md),
[passive_state_particles.gd](../../../scripts/vfx/passive_state_particles.gd)).
Il meccanismo ha chiuso tutti i gate, incluso quello percettivo, dopo che
[PS-001](../6_rejected/PS-001-tell-di-stato-senza-snaturare-lo-sprite.md) e
[PS-029](../6_rejected/PS-029-rendi-tell-stato-personaggi-piu-visibili.md)
erano stati bocciati per il ricalco della silhouette. Non è quindi un difetto da
riparare: è una resa volutamente neutra che il proprietario vuole ora
sostituire, per due personaggi su quattro, con un tell che gli appartenga.

PS-079 aveva già registrato entrambe le premesse di questa card: la scelta di
distinguere le fasi "solo per colore, non anche per comportamento" era
esplicitamente reversibile ("si riconsidererà solo se il gate percettivo lo
segnala"), e le sue Note lasciavano aperto che la prima resa non fosse la
definitiva. Questa card esercita quella riserva su Lollo e Aleo.

[PS-098](../4_to_test/PS-098-genera-aura-potenziamento-e-tell-termici.md) produce i cinque
asset; questa card li porta a schermo.

## Comportamento atteso

Quando Lollo entra in iperfocus, gli si accende attorno un'aura di potenziamento
dietro alla sagoma, che sparisce quando la fase finisce. Aleo ha sempre sotto i
piedi un'aura arancio o azzurra secondo la modalità termica corrente, e a ogni
passaggio caldo↔freddo compare per un istante un termometro (rosso `+` o azzurro
`−`) che annuncia il cambio, poi svanisce.

Alea e Migi restano esattamente com'erano: il particellare di PS-079 continua a
essere il loro tell.

## Criteri di accettazione

- [x] Durante l'iperfocus di Lollo l'aura è visibile dietro allo sprite; alla
      fine della fase sparisce entro un frame logico.
- [x] Durante la fase distratta di Lollo **non** viene presentato alcun tell di
      stato: né aura, né particellare, né altro. Scelta esplicita del
      proprietario, vedi Decisioni.
- [x] L'aura di Lollo non disegna mai sopra la sagoma del personaggio e non ne
      ricalca il profilo: resta dietro, con la propria forma (`z_index` sotto
      quello di `CharacterSprite`, non un `show_behind_parent` su un figlio).
- [x] Aleo mostra a terra, sotto i piedi, l'aura arancio in modalità calda e
      quella azzurra in modalità fredda, per tutta la durata della modalità.
- [x] L'aura a terra di Aleo resta sotto al personaggio nell'ordine di disegno:
      il corpo non viene mai coperto dall'aura.
- [x] A ogni passaggio caldo↔freddo di Aleo compare il termometro corrispondente
      (rosso `+` verso il caldo, azzurro `−` verso il freddo) e svanisce da solo
      dopo una durata dichiarata in
      [presentation_timings.gd](../../../scripts/vfx/presentation_timings.gd)
      (`THERMAL_TRANSITION_ANNOUNCE_SECONDS`).
- [x] Il termometro non è persistente: passata la sua finestra non resta nulla a
      schermo oltre all'aura a terra.
- [x] Né Lollo né Aleo usano più `PassiveStateParticles`; Alea e Migi continuano
      a usarlo con lo stesso comportamento di oggi, colori compresi.
- [x] Il flash da danno mantiene la precedenza su tutti e tre i nuovi tell,
      come già garantito da PS-079 per il particellare.
- [x] I nuovi tell avanzano solo in `RunController.RUNNING`: pausa, modali,
      `BOOT` e stati terminali li nascondono senza perdere la fase da
      ripresentare alla ripresa.
- [x] Restart e cambio personaggio azzerano ogni tell residuo e riportano la
      passiva alla propria fase iniziale (Aleo riparte caldo, Lollo in
      iperfocus).
- [x] Il cambio resta puramente presentazionale: durate delle fasi, soglia
      termica, bonus/malus dell'iperfocus, statistiche, cooldown e collisioni
      restano invariati bit per bit — verificato dal fatto che
      `test_ps105_alea_sobriety_cycle.gd` e le asserzioni di meccanica già
      presenti in `test_b44_state_tells.gd` restano verdi senza modifiche.
- [x] Il numero di nodi e di disegni per frame resta compatibile con
      `PerformanceProfile` su mobile: garanzia strutturale (tre nodi fissi sul
      solo `Player`, non scalano con il numero di nemici), non misurata con un
      profiling dedicato.
- [x] `test_b44_state_tells.gd`, `test_ps029_state_tell_visibility.gd` e
      `test_ps079_state_tell_particles.gd` sono **aggiornati** al nuovo
      contratto, non aggirati né cancellati: dove oggi asseriscono
      `get_passive_state_tell_color()` per Lollo e Aleo, devono asserire il
      canale che quei due personaggi usano davvero dopo questa card, e le
      asserzioni su Alea e Migi devono restare invariate e verdi.

## Ambito

- Nuovi VFX in [scripts/vfx/](../../../scripts/vfx/): `hyperfocus_aura.gd`,
  `thermal_ground_aura.gd`, `thermal_transition_announcer.gd` — sullo schema
  di `PassiveStateParticles`/`ThunderChargeAura` (nodi **fratelli** di
  `CharacterSprite` sotto `Player`, non figli).
- [scenes/actors/player.tscn](../../../scenes/actors/player.tscn) — i tre
  nuovi nodi accanto a `PassiveStateParticles`/`ThunderChargeAura`, che
  restano per Alea e Migi.
- [scripts/actors/player.gd](../../../scripts/actors/player.gd) — punti di
  aggancio e osservabilità per lo smoke, sullo schema di
  `set_passive_state_tell` / `is_passive_state_tell_effectively_visible`
  introdotti da PS-079.
- [scripts/content/friend_passive_controller.gd](../../../scripts/content/friend_passive_controller.gd)
  — `_refresh_lollo_hyperfocus_aura()`/`_refresh_aleo_thermal_tell()`
  instradano la fase di Lollo e Aleo sul nuovo canale invece che sul colore
  del particellare; `_advance_lollo_hyperfocus`/`_advance_aleo_thermostat`
  restano il punto unico di verità della fase.
- [scripts/vfx/presentation_timings.gd](../../../scripts/vfx/presentation_timings.gd)
  — nuova costante `THERMAL_TRANSITION_ANNOUNCE_SECONDS`.
- [tools/milestone-test-map.json](../../../tools/milestone-test-map.json) — i
  nuovi file registrati nelle regole che legano `friend_passive_controller.gd`,
  `passive_state_particles.gd`, `scripts/vfx/*` e `player.gd`/`player.tscn`
  agli smoke dell'area.
- I cinque asset prodotti da PS-098, sotto `assets/art/vfx/state_tells/`.
- `docs/characters.md` — descrizioni pubbliche del tell di Aleo e Lollo
  riscritte.

Da **non** toccare:

- durata e casualità delle fasi di Lollo, soglia termica e modificatori di Aleo,
  e qualunque altro valore di bilanciamento: qui cambia solo come la fase viene
  comunicata, non che cosa fa;
- il tell di Alea e Migi, `PassiveStateParticles` incluso: resta il loro
  meccanismo e non va rimosso;
- l'autorità di `RunController` su stato, tempo logico, pausa, modali e restart;
- il flusso `welcome → (tutorial) → selezione → run → pausa`;
- i registry degli effetti (`AbilityEffectRegistry`, `UpgradeEffectRegistry`) e
  i dati `.tres`, che non devono contenere logica di presentazione;
- gli sprite approvati del cast ([characters.md](../../characters.md)).

## Verifica

- Smoke: `tests/unit/test_ps099_state_tell_aura.gd` → marker
  `STATE_TELL_AURA_SMOKE_OK` — presenza dell'aura solo durante l'iperfocus e
  sua assenza in distrazione, aura a terra corretta per le due modalità di
  Aleo, comparsa e scadenza del termometro alla transizione, precedenza del
  flash da danno su tutti e tre i nuovi tell, avanzamento solo in `RUNNING`,
  reset su restart e cambio personaggio, e persistenza invariata del
  particellare per Alea e Migi. 7/7 verdi.
- Suite aggiornate: `test_b44_state_tells.gd`, `test_ps029_state_tell_visibility.gd`,
  `test_ps079_state_tell_particles.gd` — riscritte sul nuovo canale,
  invariate su Alea/Migi.
- Profilo eseguito: `Relevant` (30/30) e `Full` (110/110 + toolchain), nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION` nei log.
- Verifica visiva non bloccante: cattura reale (gameplay headed, non
  screenshot statico) di Lollo in iperfocus/distrazione e Aleo caldo/freddo
  con termometro — aura dietro la sagoma, aura a terra sotto i piedi,
  termometro leggibile nella posizione attesa, nessuna sovrapposizione
  indebita. Non sostituisce il controllo percettivo del proprietario
  richiesto sotto.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run con Lollo fino ad almeno un ciclo
      iperfocus→distrazione→iperfocus; run con Aleo attraversando la soglia HP
      in entrambe le direzioni; una fase densa per ciascuno)
- [ ] Controllo percettivo richiesto: **sì** — l'aura deve leggersi come un
      potenziamento e non come un effetto ambientale, e il termometro deve
      essere leggibile nell'istante in cui compare. Dato lo storico (B44,
      PS-001 e PS-029 tutti bocciati o superati), non dichiarare `COMPLETATO`
      senza che il proprietario l'abbia visto in gioco.

## Decisioni

- **2026-09-05 — L'aura copre solo l'iperfocus; la fase distratta resta senza
  tell.** Scelta esplicita del proprietario. Conseguenza voluta: l'aura diventa
  il segnale di "sono potenziato", e la sua assenza è il segnale della
  distrazione. Conseguenza da mettere in conto: chi guarda lo schermo senza aver
  visto la transizione non distingue "Lollo distratto" da "Lollo senza fase
  attiva", cosa che il particellare a due colori permetteva. Questa decisione
  **sostituisce** per il solo Lollo il requisito di PS-029/PS-079 secondo cui le
  due fasi opposte devono essere entrambe dichiarate e distinguibili fra loro;
  per Aleo, Alea e Migi quel requisito resta in vigore.
- **2026-09-05 — Il termometro di Aleo annuncia il cambio e svanisce.** Scelta
  esplicita del proprietario fra annuncio transitorio, badge permanente e
  annuncio ripetuto. A tenere lo stato è l'aura a terra, che è persistente: il
  termometro serve a far notare il *passaggio*, che è il momento in cui il
  giocatore deve cambiare comportamento. Evita anche di aggiungere un elemento
  fisso in più a schermo per tutta la run.
- **2026-09-05 — Alea e Migi restano sul particellare di PS-079.** Il
  proprietario ha chiesto un tell dedicato per Lollo e Aleo, non l'uniformità
  del roster; PS-029 aveva già stabilito che i personaggi non vanno
  necessariamente uniformati allo stesso effetto grafico. `PassiveStateParticles`
  quindi non si rimuove: si smette di usarlo per due personaggi su quattro.
- **2026-09-05 — Card di integrazione separata dalla generazione.** Contratto di
  board PS-090: PS-098 si ferma a master, derivati, manifest e art review; il
  cablaggio (nodi, scena, controller, timing, test) vive qui. L'integrazione non
  è "banale a sufficienza" per l'eccezione ammessa: introduce tre nuovi VFX, un
  nuovo instradamento della fase e la riscrittura di tre suite esistenti.
- **2026-09-07 — Ogni testura si disegna come rettangolo quadrato pieno
  (`draw_texture_rect` sull'intera canvas), non con un ritaglio a misura del
  contenuto.** I cinque derivati sono canvas quadrate con bordi trasparenti
  generosi (vincolo di `process-ability-vfx.ps1`): stirare l'intera canvas su
  un rettangolo scelto (quadrato per l'aura di iperfocus/il termometro, largo
  per l'aura a terra) evita di introdurre un secondo passaggio di crop e
  lascia alla stessa arte la propria proporzione interna.
- **2026-09-07 — Dimensioni e offset (`DISPLAY_SIZE`/`CENTER_OFFSET`/
  `FOOT_OFFSET`/`ANCHOR_OFFSET` nei tre script) sono stime da provino, non
  misure pixel-perfette**, verificate con una cattura reale ma non con
  l'occhio del proprietario. Restano il candidato più naturale da rifinire nel
  controllo percettivo, se la resa dal vivo suggerisse un aggiustamento fine.
- **2026-09-07 — Tremolio applicato ad alfa/scala per l'aura di Lollo, solo
  alfa per l'aura a terra di Aleo.** L'iperfocus è un potenziamento attivo e
  merita un respiro più marcato; l'aura a terra è più uno stato persistente
  di sfondo — un tremolio minimo evita che sembri un adesivo statico senza
  competere visivamente con l'azione.
- **2026-09-07 — Il termometro usa `PresentationTimings.one_shot_opacity`
  invece di una dissolvenza propria.** Stesso helper già usato per gli accenti
  transitori del progetto (`COSPLAY_ACCENT_SECONDS`, ecc.): fade-in/fade-out
  coerenti con il resto della UI invece di un'altra curva inventata ad hoc.
- **Sostituisce:** l'implementazione di PS-079 per il solo Aleo e il solo Lollo,
  non il suo obiettivo originale (B44) né il suo meccanismo per gli altri due
  personaggi.

## Documenti sincronizzati

- [x] `docs/characters.md`: le descrizioni pubbliche del tell di Aleo e Lollo
      sono state riscritte per riflettere aura a terra + termometro e aura di
      potenziamento invece del particellare.
- [ ] Nota `*-verification.md`, se i gate Windows/Android producono evidenze.

## Note

Punti di attenzione noti, da PS-079 e dalla lettura del codice corrente,
confermati durante l'implementazione:

- `PassiveStateParticles` vive come **fratello** di `CharacterSprite` proprio
  per restare staccato dal profilo per costruzione; i nuovi nodi sono agganciati
  allo stesso modo (`z_index` inferiore per l'aura di Lollo/l'aura a terra di
  Aleo, non un `show_behind_parent` su un figlio).
- PS-079 espone la precedenza del flash da danno tramite un getter dedicato
  (`is_passive_state_tell_effectively_visible()`) invece di leggere pixel: lo
  stesso schema (`is_*_effectively_visible()`) è stato ripetuto sui tre nuovi
  tell.
- Il Player ha scala fissa 1,65 su texture 32×32 (più `visual_scale_multiplier`
  per personaggio): l'aura a terra e le altre due sono dimensionate su quella
  scala di riferimento, non su un valore inventato — confermato in una cattura
  reale, non solo per calcolo.
- Durante l'implementazione è emerso un bug reale scoperto dallo smoke stesso,
  non da ispezione a priori: `TextureProgressBar`/simili non c'entrano qui, ma
  il debug della verifica visiva ha rivelato che il fade-in del termometro
  (`one_shot_opacity`) restituisce alfa 0 esattamente all'istante del trigger
  per costruzione — comportamento corretto, non un difetto, ma da tenere a
  mente per chi debugga questi tell manualmente frame per frame.
