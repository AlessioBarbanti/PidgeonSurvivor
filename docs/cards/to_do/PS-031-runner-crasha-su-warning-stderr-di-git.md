---
id: PS-031
titolo: Il runner crasha su un warning stderr di git invece di continuare
tipo: fix
area: tooling
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-30
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
[PS-022](../to_do/PS-022-b15-target-registrati-in-piu-suite-completa.md): un
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

- [ ] Un warning innocuo su stderr di `git diff --name-only HEAD --` (o di
      `git ls-files --others --exclude-standard`) con exit code `0` non
      interrompe l'esecuzione del runner.
- [ ] Un fallimento reale di uno di questi due comandi (exit code diverso da
      zero) continua a essere riportato come errore chiaro, non silenziato.
- [ ] Il fix copre `Get-ChangedRepositoryPaths` e qualunque altra chiamata
      dello script allo stesso pattern (`& git ... 2>$null` sotto
      `$ErrorActionPreference = 'Stop'`), se ne esistono altre con lo stesso
      rischio.
- [ ] Riprodotto il caso originale (un file tracked con line ending CRLF in
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

- [ ] Runtime Windows: non richiesto, è un fix di tooling.
- [ ] Validazione statica APK: non richiesta.
- [ ] Runtime fisico Pixel 9: non richiesto.
- [ ] Controllo percettivo richiesto: no.

## Decisioni

- **2026-08-30 — Card separata da PS-022.** Il crash è emerso mentre si
  verificava PS-022, ma è un problema del runner indipendente da quella
  diagnosi; PS-022 lo ha solo aggirato normalizzando un file, senza toccare
  lo script.

## Documenti sincronizzati

- [ ] Nessuno atteso: è un dettaglio di robustezza del runner, non un
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
stati trovati sei file card (`PS-024`..`PS-029` in `docs/cards/to_do/`) non
presenti nella tabella di [docs/cards/README.md](../README.md). Non è stato
verificato se sono card valide dimenticate nella board o file da altre fonti;
segnalato al proprietario, non corretto qui perché fuori ambito.
