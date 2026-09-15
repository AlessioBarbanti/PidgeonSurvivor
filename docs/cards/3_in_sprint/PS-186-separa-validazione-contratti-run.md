---
id: PS-186
titolo: Separa la validazione dei contratti dall'orchestrazione della run
tipo: chore
area: tooling
stato: IN CORSO
priorita: media
dipende_da: []
origine: Richiesta autonoma di code cleaning del 2026-09-15
creato: 2026-09-15
aggiornato: 2026-09-15
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
- [ ] Project smoke, regressioni e Full eseguiti con ispezione dei log.

## Ambito

`scripts/game/movement_slice.gd`, `scripts/app/run_contract_validator.gd`, test,
mappa regressioni e documentazione architetturale. Nessun cambio alle scene,
all'ordine di configure(), al modello scene-local, ai modali o al bilanciamento.

## Verifica

- Test: `tests/unit/test_ps186_run_contract_validator.gd`.
- Profilo finale Full e smoke del progetto/eseguibile Windows.

## Gate manuali

- [ ] Runtime Windows esportato.
- [ ] Validazione statica APK corrente.
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
