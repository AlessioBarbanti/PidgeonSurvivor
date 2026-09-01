---
id: PS-031
titolo: Il runner crasha su un warning stderr di git invece di continuare
tipo: fix
area: tooling
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-09-01
---

# PS-031 — Il runner crasha su un warning stderr di git invece di continuare

## Contesto

`tools/run-milestone-checks.ps1` ha `$ErrorActionPreference = 'Stop'` in
testa. `Get-ChangedRepositoryPaths` (usata dal profilo `Relevant` per leggere
le modifiche tracked/untracked) chiama `& git -C $repoRoot diff --name-only
HEAD -- 2>$null`. Su PowerShell 5.1, reindirizzare lo stderr di un comando
nativo lo trasforma in un `NativeCommandError` che imposta `$?` a `$false`
**anche quando l'exit code reale del processo è `0`**; sotto
`$ErrorActionPreference = 'Stop'` questo diventa un'eccezione terminante, non
un `$LASTEXITCODE` non zero che il controllo successivo saprebbe gestire.

Il caso concreto: `git diff` stampa su stderr un avviso innocuo quando un
file nel working tree ha line ending non normalizzati rispetto a
`.gitattributes` (`eol=lf`), es. `warning: in the working copy of
'<file>', CRLF will be replaced by LF the next time Git touches it`. Con
quell'avviso presente, il runner si ferma con un errore di script invece di
produrre un esito `PASS`/`FAIL` leggibile — anche se `git diff` è
tecnicamente riuscito.

Scoperto il 2026-08-30 lavorando su
[PS-022](../5_completed/PS-022-b15-target-registrati-in-piu-suite-completa.md): un
file card era rimasto con CRLF dopo un `git mv`, e la prima invocazione del
runner in quella sessione è crashata. Aggirato per quella sessione
normalizzando manualmente il file a LF, senza toccare lo script.

## Comportamento atteso

Un warning su stderr di un comando git che termina con exit code `0` non
deve mai far fallire in modo opaco `run-milestone-checks.ps1`. Il runner
prosegue e produce il proprio esito compatto (`PASS`/`FAIL`/`CACHED`) come se
il warning non ci fosse; un vero fallimento di git (`exit code` diverso da
zero) resta invece un errore riportato chiaramente.

## Criteri di accettazione

- [x] Un warning innocuo su stderr di `git diff --name-only HEAD --` (o di
      `git ls-files --others --exclude-standard`) con exit code `0` non
      interrompe l'esecuzione del runner.
- [x] Un fallimento reale di uno di questi due comandi (exit code diverso da
      zero) continua a essere riportato come errore chiaro, non silenziato.
- [x] Il fix copre `Get-ChangedRepositoryPaths` e qualunque altra chiamata
      dello script allo stesso pattern (`& git ... 2>$null` sotto
      `$ErrorActionPreference = 'Stop'`), se ne esistono altre con lo stesso
      rischio.
- [x] Riprodotto il caso originale (un file tracked con line ending CRLF in
      un repo con `eol=lf`) e verificato che con il fix il runner non crasha
      più su quel warning.

## Ambito

- `tools/run-milestone-checks.ps1`, in particolare `Get-ChangedRepositoryPaths`
  e ogni altra chiamata a processi esterni con lo stesso pattern di redirect.
- Non modificare il comportamento di selezione dei test per i profili
  `Focused`/`Relevant`/`Full` al di fuori della gestione dell'errore.
- Non disattivare `$ErrorActionPreference = 'Stop'` globalmente: la
  correzione va mirata alle chiamate a processi esterni che già oggi possono
  emettere warning legittimi su stderr.

## Verifica

- I test del runner vivono in `tests/tooling/_milestone_runner_contract.ps1`
  (funzioni pure, senza Godot) — è il posto naturale per un test che
  simula un warning su stderr con exit code `0` e verifica che la selezione
  dei percorsi modificati non sollevi un'eccezione.
- Profilo minimo prima della chiusura: `Relevant`, eseguito almeno una volta
  in un working tree con un file deliberatamente CRLF per riprodurre il caso
  originale.

## Gate manuali

- [x] Runtime Windows: non richiesto, è un fix di tooling.
- [x] Validazione statica APK: non richiesta.
- [x] Runtime fisico Pixel 9: non richiesto.
- [x] Controllo percettivo richiesto: no.

## Decisioni

- **2026-08-30 — Card separata da PS-022.** Il crash è emerso mentre si
  verificava PS-022, ma è un problema del runner indipendente da quella
  diagnosi; PS-022 lo ha solo aggirato normalizzando un file, senza toccare
  lo script.
- **2026-09-01 — `Invoke-GitLines` come unico punto d'ingresso.** Le quattro
  chiamate a processi esterni con il pattern a rischio
  (`Get-ChangedRepositoryPaths` ×2, `Get-RepositoryRuntimeFiles` ×2) sono
  state fatte convergere su un helper condiviso che abbassa
  `$ErrorActionPreference` a `Continue` solo per la durata della chiamata
  nativa (ripristinandolo subito dopo in un `finally`), lascia il `2>$null`
  invariato e decide solo in base a `$LASTEXITCODE`. Scartata l'idea di
  disattivare `$ErrorActionPreference = 'Stop'` globalmente: avrebbe
  nascosto anche errori legittimi altrove nello script, contro il vincolo
  esplicito in "Ambito".
- **2026-09-01 — Riproduzione automatizzata in `_milestone_runner_contract.ps1`.**
  Il test sporca temporaneamente `docs/cards/_TEMPLATE.md` con CRLF (poi lo
  ripristina in un `finally`), verifica che il warning compaia davvero su
  stderr e poi invoca il runner reale (senza `-ChangedPath`, così passa da
  `Get-ChangedRepositoryPaths`) aspettandosi exit `0`. Nota emersa in corso
  d'opera: con contenuto altrimenti identico, `git diff --name-only` non
  elenca il file fra i changed path (git normalizza il CRLF prima del
  confronto) pur emettendo comunque il warning: è esattamente lo scenario
  del bug originale, quindi il test verifica l'assenza di crash sul plan
  invece di una comparsa nei changed path.
- **2026-09-01 — Verifica del fallimento reale.** Confermato a mano in
  PowerShell che un comando git realmente fallito (`git show` su un ref
  inesistente) restituisce `$LASTEXITCODE` diverso da zero anche con
  `$ErrorActionPreference = 'Continue'` durante la chiamata: il throw
  esistente su `$LASTEXITCODE -ne 0` resta quindi corretto e non è stato
  aggiunto un fixture end-to-end dedicato per questo ramo (comporterebbe
  corrompere temporaneamente lo stato del repo di test).

## Documenti sincronizzati

- [x] Nessuno atteso: è un dettaglio di robustezza del runner, non un
      contratto di prodotto o di architettura.

## Note

Indizio concreto per chi riprende: la chiamata sospetta è

```powershell
$tracked = @(& git -C $repoRoot diff --name-only HEAD -- 2>$null)
if ($LASTEXITCODE -ne 0) {
    throw 'git diff --name-only HEAD fallito durante la selezione dei test.'
}
```

in `tools/run-milestone-checks.ps1` (circa riga 218), con un pattern
gemello poco sotto per `git ls-files --others --exclude-standard`. Il
`2>$null` da solo non basta a impedire che PowerShell 5.1 sollevi un
`NativeCommandError` quando `$ErrorActionPreference = 'Stop'` è attivo:
serve isolare la cattura di stderr (es. eseguire il comando con
`-ErrorAction SilentlyContinue` sul cmdlet che lo invoca, o catturare
l'output con `2>&1` in una variabile e ispezionarlo esplicitamente invece di
lasciarlo propagare come eccezione) e decidere in base al solo
`$LASTEXITCODE`, non alla presenza di testo su stderr.

Osservazione collaterale, non in ambito qui: durante la stessa sessione sono
stati trovati sei file card (`PS-024`..`PS-029` in `docs/cards/2_to_do/`) non
presenti nella tabella di [docs/cards/README.md](../README.md). Non è stato
verificato se sono card valide dimenticate nella board o file da altre fonti;
segnalato al proprietario, non corretto qui perché fuori ambito.

Evidenza di chiusura (2026-09-01):

```powershell
.\tests\tooling\_milestone_runner_contract.ps1
# MILESTONE_RUNNER_CONTRACT_OK
```

include ora anche la riproduzione automatica del caso CRLF originale (sporca
`docs/cards/_TEMPLATE.md` con CRLF, verifica il warning su stderr, invoca il
runner reale senza `-ChangedPath` e si aspetta exit `0`, poi ripristina il
file in un `finally`). Verificato inoltre a mano, fuori dal test, che un
comando git realmente fallito (`git show` su un ref inesistente) restituisce
comunque `$LASTEXITCODE` diverso da zero con lo stesso pattern.
