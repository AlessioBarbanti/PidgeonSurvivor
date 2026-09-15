---
id: PS-186
titolo: Separa la validazione dei contratti dall'orchestrazione della run
tipo: chore
area: tooling
stato: IN VERIFICA
priorita: media
dipende_da: []
origine: Richiesta autonoma di code cleaning del 2026-09-15
creato: 2026-09-15
aggiornato: 2026-09-16
---

# PS-186 — Separa la validazione dei contratti dall'orchestrazione della run

## Contesto

`movement_slice.gd` orchestra il gioco ma contiene anche una funzione di oltre
800 righe per verificare dati, wiring, grafica e toolchain della scena. Questa
responsabilità rende difficile navigare le transizioni runtime e verificare
singoli errori di configurazione senza emettere errori motore.

## Comportamento atteso

Gli stessi controlli partono nello stesso punto del lifecycle; mantengono
messaggi, marker, ordine e risultato. L'orchestratore delega la diagnostica
a un validatore senza stato persistente, con controlli raggruppati per dominio.

## Criteri di accettazione

- [x] Validazione estratta da MovementSlice e suddivisa per responsabilità.
- [x] Raccolta degli errori separata dalla stampa del risultato.
- [x] Nessun controllo, messaggio diagnostico o marker preesistente eliminato.
- [x] Un test verifica la scena valida e più guasti indipendenti con ripristino;
      validare non modifica seed, tempo, ranghi, segnali o ownership della scena.
- [x] Project smoke, regressioni e Full eseguiti con ispezione dei log.

## Ambito

`scripts/game/movement_slice.gd`, `scripts/app/run_contract_validator.gd`, test,
mappa regressioni e documentazione architetturale. Nessun cambio alle scene,
all'ordine di configure(), al modello scene-local, ai modali o al bilanciamento.

## Verifica

- Test: `tests/unit/test_ps186_run_contract_validator.gd`.
- Profilo finale Full e smoke del progetto/eseguibile Windows.

## Gate manuali

- [x] Runtime Windows esportato: export e smoke automatico di avvio.
- [x] Validazione statica APK corrente.
- [ ] Runtime fisico Pixel 9: avvio, selezione, run, pausa e restart.
- Controllo percettivo dedicato: non richiesto; presentazione invariata.

## Decisioni

- **2026-09-15 — Estrarre la diagnostica, mantenere la composizione.**
  MovementSlice resta il punto esplicito di wiring. Sostituirlo con event bus,
  singleton o container DI nasconderebbe le dipendenze senza risolvere il problema.
- **2026-09-15 — Preservare i contratti storici verificati.** Le verifiche
  restano operative: eliminarle come presunto codice morto perderebbe la
  diagnostica degli eseguibili esportati.

## Documenti sincronizzati

- [x] `CLAUDE.md` e `docs/verification-workflow.md`: confine della diagnostica.
- [x] `tools/milestone-test-map.json`: regressioni del validatore.

## Note

- Trasferite tutte le 241 aggiunte di errore e tutti i 42 marker, nello stesso
  ordine. Il controllo meccanico della trasformazione verifica che ogni blocco
  originale sia trasferito esattamente una volta. 21 funzioni per dominio;
  nessuna nuova dipendenza da autoload o stato persistente.
- `movement_slice.gd` passa da 2252 a 1413 righe includendo PS-185: flusso
  runtime e configurazione restano nello stesso script, la diagnostica è
  consultabile separatamente. Non è una riduzione del numero totale di righe:
  le funzioni diagnostiche dichiarano esplicitamente le dipendenze lette.
- `Relevant -FocusedSmoke tests/unit/test_ps186_run_contract_validator.gd
  -RefreshEditor -NoCache`: 38/38 step verdi (refresh, 3 test mirati in uno
  script, 36 script di regressione), log `20260915-231824-PS-186` sotto
  `%TEMP%/il-gioco-verification`.
- `tests/tooling/_milestone_runner_contract.ps1`: `MILESTONE_RUNNER_CONTRACT_OK`.
- Scartati: suddivisione indiscriminata di RunController (ownership e transizioni
  già coese); gerarchia comune per drop XP e salute (credito frazionario e RNG
  richiedono politiche differenti); rimozione della telemetria PS-123/124/126
  e del debug B22 senza prova che non servano più alle verifiche fisiche.

### Verifica finale del branch (2026-09-15/16)

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-186 -Profile Release `
  -KeepGoing -NoCache -ExportTimeoutSeconds 300
.\tools\run-milestone-checks.ps1 -Milestone PS-186 -Profile Custom `
  -RunToolchain -RunProjectSmoke -NoCache
```

- Release: log `%TEMP%/il-gioco-verification/20260915-232036-PS-186`.
  3/3 test focused e 473/474 test di regressione: **476/477 test**, 150/151
  script verdi. Il solo fallimento è
  `test_ps158_mature_build_anti_afk.gd::test_killing_the_shooter_after_it_fires_does_not_cancel_the_projectile`,
  identico alla baseline `fff4dcb` e già tracciato da PS-177. Non modificato
  né escluso dalla suite. Il profilo completo resta **FAIL**.
- Toolchain del primo Release fermata dal template Gradle locale assente nel
  nuovo worktree; l'export Android lo ha generato. Ripetizione successiva
  **PASS 2/2 step**, log `20260916-003326-PS-186`: test focused, toolchain e
  project smoke eseguiti; nessun marker di errore GDScript o contratto.
- Windows: export **PASS**, eseguibile **PASS** con `SMOKE_OK` e tutti i 42
  marker di contratto. Log runtime senza errori; non è una prova manuale della UI.
  L'exporter stampa `Cannot set object script` dopo `savepack`: riprodotto
  identico anche esportando `fff4dcb` in un secondo worktree temporaneo, log
  `20260916-003441-PS-186` (refresh, export e runtime 3/3 step verdi).
  È una diagnostica preesistente dell'export, non un errore runtime introdotto
  dal refactoring; resta da investigare separatamente.
- Android: export **RECOVERED**, processo terminato dal runner dopo il marker
  di completamento; ispezione statica **PASS**, APK 73.433.055 byte,
  `com.ilgioco.pidgeonsurvivor`, API 31/36, sola `arm64-v8a`, firma v2 valida,
  launcher `com.godot.game.GodotAppLauncher`.
  SHA-256: `28b0472082b5750e6ec1cc260914200df2fb58106071b783815f0cbf09806aa2`.
- Runtime Android **APERTO**: `OPEN_ADB_SERVER_NOT_RUNNING`; nessuna installazione,
  prova touch/lifecycle o verifica fisica dichiarata.
- Nei batch GUT non compaiono `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL`
  o `CONTRACT_FAIL`. Restano diagnostiche di teardown già presenti nella baseline:
  RID texture/font/text e risorse trattenute all'uscita (ObjectDB 232 baseline,
  235 finale; risorse 68 baseline, 70 finale). Il batch focused dei nuovi test
  non produce queste diagnostiche; non si dichiara risolto il teardown globale.
- Audit statico contro `fff4dcb`: `VALIDATOR_SEMANTIC_AUDIT_OK
  statements_lines=764 errors=241 markers=42`, dopo normalizzazione dei soli
  alias delle dipendenze e suddivisione in funzioni.
- Gate di merge ancora aperti: review del branch, fallimento Full preesistente
  PS-177 e percorso fisico Pixel 9. Nessun merge o push eseguito.
