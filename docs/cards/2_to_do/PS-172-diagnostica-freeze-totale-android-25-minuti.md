---
id: PS-172
titolo: Diagnostica il freeze totale su Android a ~25 minuti di run
tipo: chore
area: piattaforma
stato: PRONTO
priorita: alta
dipende_da: []
origine: playtest esterno 2026-09-11 — feedback Magno
creato: 2026-09-13
aggiornato: 2026-09-13
---

# PS-172 — Diagnostica il freeze totale su Android a ~25 minuti di run

## Contesto

Magno ha segnalato che, giocando su Android, il gioco si è bloccato
completamente attorno al minuto 25 di run: schermata ferma, nessun input più
funzionante. Non è un crash (il processo non è tornato a home/desktop) né un
semplice calo di frame rate: il gioco ha smesso di rispondere. `EnemySpawner`
ha già un tetto (`spawn_profile.max_alive_enemies`) sui nemici vivi
contemporaneamente, quindi il freeze non è necessariamente spiegabile con una
crescita illimitata del conteggio nemici; restano da verificare altre
sorgenti che potrebbero accumularsi nel tempo indipendentemente da quel cap
— proiettili/telegraph dei tiratori, VFX ed eventi d'ondata, la crescita
senza tetto della pressione oltre `late_run_curve_full_seconds` (PS-126) — e
se il comportamento sia specifico di Android o riproducibile anche su
Windows.

## Comportamento atteso

La causa radice del freeze viene identificata e documentata con evidenza
reale (log/profiling), non per ipotesi. Se la correzione è piccola e sicura
viene applicata direttamente qui; se richiede un intervento più ampio o
rischioso, questa card si ferma alla diagnosi e apre una card fix dedicata
con l'evidenza raccolta.

## Criteri di accettazione

- [ ] Causa radice del freeze identificata e documentata in questa card
      (memory leak, ANR per operazione bloccante sul thread principale,
      valore non finito/overflow in una curva che cresce senza tetto,
      accumulo di nodi/segnali/timer non ripuliti, o altro), con log a
      supporto.
- [ ] Riprodotto almeno un caso controllato che raggiunge o supera i 25
      minuti di tempo logico su un device Android reale, con `adb logcat`
      raccolto nella finestra del blocco.
- [ ] Verificato e documentato se il freeze si riproduce anche su Windows con
      una run equivalente, per isolare se il problema è specifico della
      piattaforma Android o del runtime di gioco in generale.
- [ ] Se la causa è isolabile con una correzione piccola e sicura, viene
      applicata in questa card e verificata con una run reale che supera i
      30 minuti senza freeze.
- [ ] Se la causa richiede una correzione più ampia o rischiosa, viene aperta
      una card fix dedicata con l'evidenza raccolta invece di allargare
      questa diagnosi.
- [ ] Non viene introdotta alcuna tolleranza artificiale (es. terminare la
      run forzatamente a tempo, ridurre densità/pressione "per sicurezza")
      come sostituto della diagnosi reale.

## Ambito

- Nessuna modifica runtime finché la causa non è identificata; solo dopo la
  diagnosi, l'eventuale fix minimo tocca il sistema realmente coinvolto.
- Sospetti principali da verificare: `scripts/game/enemy_spawner.gd` (cap
  `max_alive_enemies` e pulizia dei nemici morti), `scripts/actors/ranged_enemy.gd`
  e `scripts/bosses/boss_projectile.gd` (proiettili/telegraph non ripuliti),
  `scripts/game/wave_event_scheduler.gd` (eventi accumulati), la curva senza
  tetto di PS-126, VFX/particellari di late-run.
- Non modificare bilanciamento (HP/danno/densità) come tentativo di aggirare
  il sintomo senza averne capito la causa.

## Verifica

- Da definire dopo la diagnosi. Se la causa è nel codice di gioco e richiede
  una correzione, servirà un GUT dedicato `tests/unit/test_ps172_*.gd` per il
  contratto individuato (o per la card fix separata che ne eredita
  l'evidenza).
- Profilo minimo prima della chiusura: `Relevant`, se viene applicata una
  correzione in questa card.

## Gate manuali

- [ ] Runtime Windows (percorso: run equivalente ≥ 25 minuti, per verificare
      se il freeze è specifico Android)
- [ ] Validazione statica APK: non richiesta per la sola diagnosi
- [ ] Runtime fisico Android (percorso: run reale fino ad almeno 25–30 minuti
      con `adb logcat` attivo; gate obbligatorio e non sostituibile da uno
      smoke o da un profiling desktop)
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-09-13 — Segnalazione raccolta separatamente dal resto del playtest
  del 2026-09-11.** Il finding "freeze a 25 minuti" è emerso in una
  conversazione successiva, non nella prima trascrizione; resta comunque
  evidenza dello stesso playtest esterno (Magno).
- **2026-09-13 — Diagnosi prima della correzione.** Nessun fix speculativo:
  non si tocca bilanciamento, cap di spawn o densità come tentativo di
  mascherare il sintomo prima di averne capito la causa.
- **2026-09-13 — Un device Android reale resta indispensabile.** Coerente con
  la sezione «Onestà dei gate» di `CLAUDE.md`: se il device non è disponibile
  il gate resta apertamente dichiarato, non sostituito da un'ispezione
  indiretta.

## Documenti sincronizzati

- [ ] `docs/systems-difficulty.md`, solo se la diagnosi rivela un contratto di
      pulizia/lifecycle mancante da documentare (es. un tetto da introdurre
      su una curva oggi senza limite).

## Note

Segnalazione verbale del proprietario (2026-09-13), raccolta da conversazione
di playtest del 2026-09-11 con Magno: freeze totale (non crash, non solo
framerate basso) su Android, attorno al minuto 25 di run. Device esatto non
specificato.
