---
id: PS-086
titolo: La cattura dell'output del runner strozza l'esecuzione dei test
tipo: fix
area: tooling
stato: IN VERIFICA
priorita: alta
dipende_da: []
origine:
creato: 2026-09-04
aggiornato: 2026-09-04
---

# PS-086 — La cattura dell'output del runner strozza l'esecuzione dei test

## Contesto

La suite `Full` non finiva: andava in timeout dopo 30 minuti avendo eseguito
77 file su 99. La causa non erano i test né l'avvio di Godot, ma
`Invoke-CapturedProcess` in `tools/lib/process-capture.ps1`: drenava stdout del
processo figlio riga per riga da PowerShell, e Godot restava bloccato in
scrittura fra un giro di lettura e l'altro. Misurato sullo stesso file GUT,
stessa macchina: **3,7 s** con output rediretto su file, **55,9 s** letto dalla
pipe. Il tempo di un test dipendeva da come lo si guardava.

Quella lentezza nascondeva altro: cinque test erano rossi da tempo e tre erano
fragili in modo latente, invisibili perché la suite non arrivava mai in fondo.

## Comportamento atteso

La suite completa gira in meno di un minuto e mezzo e resta interamente verde,
con lo stesso esito indipendentemente dal numero di processi usati per
eseguirla. Un rosso torna a significare una regressione vera.

## Criteri di accettazione

- [x] Il profilo `Full` completa senza timeout e riporta 100 PASS / 0 FAIL.
      *70,5 s con `-ParallelJobs 1`, 27,0 s con `-ParallelJobs 6`.*
- [x] Il tempo di un file di test non dipende da come viene catturato l'output:
      la stessa esecuzione misurata con redirezione su file e attraverso il
      runner dà lo stesso ordine di grandezza.
- [x] `tests/tooling/_process_capture_contract.ps1` e
      `tests/tooling/_milestone_runner_contract.ps1` restano verdi: marker di
      completamento, timeout, terminazione dell'albero di processi e riga di
      avanzamento continuano a funzionare.
- [x] `-ParallelJobs <N>` divide i file GUT fra N processi Godot concorrenti e
      produce lo stesso esito del percorso sequenziale, cache inclusa.
- [x] Nessun test è stato rimosso o indebolito per far tornare il verde: le
      asserzioni cadute sono state ricondotte al contratto che dichiarano.

## Ambito

- `tools/lib/process-capture.ps1`: cattura su file invece che da pipe;
  `Invoke-CapturedProcessGroup` per eseguire più processi con un solo ciclo di
  sorveglianza.
- `tools/run-milestone-checks.ps1`: parametro `-ParallelJobs`, sharding dei
  file GUT, isolamento di `user://` per shard via `APPDATA`.
- `tests/unit/helpers/gameplay_test.gd`: `wait_for_transitions()`.
- Cinque test con aspettative scadute e due con dipendenza dall'ordine di
  esecuzione (elenco in Decisioni).

Non toccati: il contratto degli stati del runner (`PASS`/`FAIL`/`CACHED`/
`TIMEOUT`), la distinzione fra test rosso e fallimento di batch, la cache per
categoria, l'autorità di `RunController`, il flusso dei modali, i registry
degli effetti. Nessuna modifica al runtime di gioco.

## Verifica

- Test: `tests/tooling/_process_capture_contract.ps1`,
  `tests/tooling/_milestone_runner_contract.ps1` (funzioni pure, senza Godot).
- Profilo minimo prima della chiusura: `Full`, che è anche l'oggetto della
  card.

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-086 -Profile Full -NoCache -ParallelJobs 6
```

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: ...)
- [ ] Controllo percettivo richiesto: no

Nessun gate di piattaforma è pertinente: la modifica riguarda lo strumento di
verifica e i test, non il runtime del gioco né la sua presentazione.

## Decisioni

- **2026-09-04 — La cattura passa da file, non da pipe.** Drenare stdout dal
  padre in PowerShell bloccava il figlio in scrittura. I file temporanei
  vengono letti in modo incrementale, così marker e avanzamento restano
  disponibili mentre il processo è vivo senza attendere un EOF che con un
  nipote detached può non arrivare mai.
- **2026-09-04 — Gli shard sono processi diretti, non job PowerShell.** Un job
  costava ~1,5 s di avvio ciascuno, pagati in sequenza prima che partisse un
  test, e i suoi host competevano per la CPU al punto da far fallire
  `test_b18v_hardening_performance` ad alto parallelismo.
- **2026-09-04 — `-ParallelJobs 6` è il valore consigliato.** Misurato su 6
  core fisici: 1 → 70,5 s, 6 → 27,0 s, oltre è piatto dentro il rumore. Il
  residuo non è più nei test (~10 s sono lo step toolchain).
- **2026-09-04 — Le fixture di combattimento non dipendono più dal
  bilanciamento.** PS-076 ha abbassato gli HP dei nemici e il colpo «non
  letale» da 10 danni scritto in `test_b13_signature_upgrades`,
  `test_b18b_visual_identity` e `test_b18r_visual_timing` è diventato letale.
  I nemici di prova ricevono ora una vita propria: i test misurano il danno
  applicato e il knockback, non il bilanciamento del momento.
- **2026-09-04 — B27 verifica un'invariante, non una costante di layout.**
  PS-047 ha compattato le carte e l'icona è passata da 192 a 106 px.
  `test_b27_upgrade_icon_refresh` ora richiede icona quadrata e identica su
  ogni viewport, che è ciò che si romperebbe davvero; il nuovo assetto ha già
  il suo test in `test_ps047_upgrade_card_hierarchy`.
- **2026-09-04 — `test_b54_tutorial_flow` allineato a PS-049.** Cercava ancora
  i placeholder `fake_tutorial_*.png` sostituiti dalle illustrazioni
  definitive.
- **2026-09-04 — Due test dipendevano dall'ordine di esecuzione.**
  `test_b18w_character_select_refinement` misurava il layout a metà del tween
  di entrata (con i frame rallentati l'animazione finiva «per caso» dentro
  l'attesa) e, insieme a `test_ps069_character_select_bust_portrait`,
  ereditava la viewport lasciata dal file precedente. Ora attendono le
  transizioni e fissano la viewport da sé.
- **Costruisce su:** PS-023, che ha reso il runner leggibile e non bloccante e
  ha introdotto proprio il layer di cattura corretto qui.
- **Non sostituisce PS-070:** resta aperta, è la stessa categoria (aspettativa
  di test scaduta) su un file diverso, `test_b17_friend_content`.

## Documenti sincronizzati

- [x] `docs/verification-workflow.md`: perché la cattura passa da file,
      sezione «Esecuzione parallela», dipendenza dall'ordine di esecuzione.
- [ ] `prd.md` o `CLAUDE.md`: non pertinente, nessun contratto di prodotto o
      architettura cambia.

## Note

`docs/test-timing-report.md` conserva la cronaca della diagnosi, comprese le
ipotesi scartate con la misura che le ha chiuse: istanziare la scena di gioco
costa 77-140 ms e non 12 s, non c'è accumulo di nodi fra i test, l'avvio di
Godot pesa 16-20 s per processo, e `--fixed-fps` non serviva. Le prime due
sezioni di quel documento misurano un artefatto del metodo e sono marcate come
tali.
