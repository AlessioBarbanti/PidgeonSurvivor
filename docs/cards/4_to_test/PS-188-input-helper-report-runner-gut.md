---
id: PS-188
titolo: Includi gli helper nella verifica GUT e conta i test falliti correttamente
tipo: fix
area: tooling
stato: IN VERIFICA
priorita: media
dipende_da: []
origine: Audit autonomo dei test richiesto dal proprietario
creato: 2026-09-16
aggiornato: 2026-09-17
---

# PS-188 — Includi gli helper nella verifica GUT e conta i test falliti correttamente

## Contesto

`gameplay_test.gd` serve oltre cento test ma le sue modifiche sono escluse
da `Relevant` e dall'hash della cache. Una verifica verde puo' quindi essere
riutilizzata dopo una modifica all'helper. Durante PS-175 il runner ha inoltre
stampato `32/3 test falliti`: GUT conta le asserzioni fallite nell'attributo
`testsuite.failures`, mentre i casi di test falliti erano uno su tre.

## Comportamento atteso

Una modifica all'helper seleziona i consumatori e invalida la cache GUT.
I conteggi riportati descrivono casi di test e mantengono rossi errori,
report mancanti e fallimenti, indipendentemente dal numero di asserzioni.

## Criteri di accettazione

- [x] `Relevant` pianifica tutti i test che ereditano `GutGameplayTest`.
- [x] Una modifica all'helper invalida un risultato precedentemente in cache.
- [x] Un caso con piu' asserzioni fallite conta come un solo test fallito.
- [x] Contratto PowerShell e Full verdi; errori motore restano fallimenti.

## Ambito

Runner, libreria del report GUT, mappa delle regressioni, test del tooling e
`docs/verification-workflow.md`. Nessun cambiamento al framework GUT vendorizzato.

## Verifica

`tests/tooling/_milestone_runner_contract.ps1`, prova cache prima/dopo modifica
temporanea all'helper, parsing del report reale PS-175 e Full senza cache.

## Gate manuali

Windows runtime, APK e Pixel 9: non pertinenti per modifiche al tooling.
Revisione del branch prima dell'integrazione.

## Decisioni

- **2026-09-17 — Integrazione su checkout pulito.** Il contratto del runner
  ha riprodotto un errore di binding su `Find-RelevantSmokes -Paths @()`:
  il parametro obbligatorio rifiutava la lista vuota. Accettare esplicitamente
  la collezione vuota conserva zero regressioni quando Git non trova modifiche.
  Aggiunta una prova delle funzioni reali, indipendente dallo stato dirty del
  checkout; il contratto CRLF esistente verifica anche il percorso Git reale.

- **2026-09-16 — Confine esplicito.** Gli helper GDScript sotto
  `tests/unit/helpers/` sono input di verifica. La mappa resta la fonte delle
  regressioni; un contratto controlla che copra tutti i consumatori della base.
- **2026-09-16 — Leggi i casi, non le asserzioni.** Il parsing JUnit vive
  nella libreria gia' usata dal runner, testabile senza avviare Godot.

## Documenti sincronizzati

- [x] `docs/verification-workflow.md` e mappa delle regressioni.

## Note

Report che riproduce il conteggio errato: `20260916-010332-PS-175/gut-focused.junit.xml`
in `%TEMP%/il-gioco-verification` (tre casi, uno rosso, 32 asserzioni fallite).

Evidenze 2026-09-16:

- `MILESTONE_RUNNER_CONTRACT_OK`: selezione di tutti i 130 consumatori,
  parsing di un caso con 32 assert rossi, conteggio pending, report vuoti,
  troncati e incoerenti respinti.
- Cache reale su `test_gameplay_fixture.gd`: prima `PASS`
  (`20260916-081207-PS-188`), poi `CACHED` (`20260916-081223-PS-188`),
  dopo una modifica temporanea all'helper di nuovo `PASS` con Godot avviato
  (`20260916-081225-PS-188`). Contenuto originale ripristinato subito dopo.
- Il report rosso reale PS-175 conservato nei log non viene riscritto;
  la sonda PowerShell ne riproduce la struttura per verificare 1/3, non 32/3.


Verifica finale 2026-09-16: cinque esecuzioni consecutive di Full con
-NoCache e un solo processo GUT: 150 script / 469 test verdi per esecuzione,
toolchain e project smoke verdi. Nessun SCRIPT ERROR, FATAL EXCEPTION,
SMOKE_FAIL o CONTRACT_FAIL. Log in %TEMP%/il-gioco-verification:
20260916-081407-PS-188, 20260916-081639-PS-188, 20260916-081909-PS-188,
20260916-082143-PS-188, 20260916-082416-PS-188.

Stato IN VERIFICA per la revisione del branch refactor/test-cleaning-2026-09-16.

Diagnostica di shutdown gia' presente nella baseline Full: 11 RID texture,
26 RID shaped text, 8 RID font, 232 ObjectDB e 68 risorse ancora in uso,
oltre alle pagine Variant PagedAllocator. Conteggi invariati nei cinque
passaggi; non si dichiara eliminata questa diagnostica preesistente.

Verifica aggiuntiva sul risultato finale del branch, dopo PS-178:
`20260916-150244-PS-188` Full senza cache, 151 script / 474 casi nello
stesso processo GUT, nessun fallimento o pending e nessun marker di errore.
Release `20260916-145813-PS-178`: 474 casi, smoke Windows e APK statico
verdi; Android fisico aperto. Le misure del lag e i relativi limiti restano
nella card PS-178, distinta dalle correzioni delle fixture e del runner.
